// Copyright (c) 2021, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerinax/aws;
import ballerinax/aws.auth;

# A request about to be signed and sent.
#
# The `path` and `queryParams` are held unencoded: the signer derives the canonical request from them, and
# `encodePath`/`encodeQuery` produce the percent-encoded forms that go on the wire. Keeping one unencoded source
# for both is what makes the signature agree with the request actually sent.
type SesRequest record {|
    # HTTP method
    string method;
    # Request path, unencoded
    string path;
    # Query parameters, unencoded
    map<string> queryParams = {};
    # JSON request body, absent for operations that send none
    json payload?;
|};

# Percent-encodes a value per RFC 3986, leaving only the unreserved characters as they are.
#
# This has to match `SdkHttpUtils.urlEncodeIgnoreSlashes`, which the shared signer applies to the path before
# canonicalizing it. The signer is configured with `DOUBLE_URL_ENCODE` for non-S3 services, so it encodes the
# already-encoded path a second time to build the canonical URI — which is correct only if what goes on the wire is
# this single-encoded form.
#
# + value - The raw value to encode
# + return - The percent-encoded value
isolated function encodeValue(string value) returns string {
    string encoded = "";
    foreach byte b in value.toBytes() {
        string:Char|error ch = string:fromCodePointInt(b);
        if ch is string:Char && UNRESERVED_CHARS.includes(ch) {
            encoded += ch;
        } else {
            encoded += string `%${b.toHexString().toUpperAscii().padZero(2)}`;
        }
    }
    return encoded;
}

# Encodes each segment of a path, preserving the separators.
#
# + path - The unencoded path
# + return - The path with every segment percent-encoded
isolated function encodePath(string path) returns string {
    string[] segments = from string segment in re `/`.split(path)
        select encodeValue(segment);
    return string:'join("/", ...segments);
}

# Renders query parameters as an encoded query string.
#
# + queryParams - The unencoded query parameters
# + return - The query string including its leading `?`, or `""` when there are no parameters
isolated function encodeQuery(map<string> queryParams) returns string {
    if queryParams.length() == 0 {
        return "";
    }
    string[] pairs = from [string, string] [name, value] in queryParams.entries()
        select string `${encodeValue(name)}=${encodeValue(value)}`;
    return string `?${string:'join("&", ...pairs)}`;
}

# Signs an operation request with AWS Signature Version 4 and returns the headers to set on it.
#
# + credentialProvider - Provider that resolves (and refreshes) the signing credentials
# + host - The endpoint host to sign against
# + region - The signing region
# + request - The operation request to sign
# + return - The headers to set on the outbound request, or an `Error` if the credentials cannot be resolved or the
# request cannot be signed
isolated function signRequest(auth:CredentialProvider credentialProvider, string host, aws:Region|string region,
        SesRequest request) returns map<string>|Error {
    auth:Credentials|auth:CredentialResolutionError credentials = credentialProvider.getCredentials();
    if credentials is auth:CredentialResolutionError {
        return error RequestGenerationError(
                string `Error occurred while resolving the AWS credentials: ${credentials.message()}`, credentials);
    }

    json? payload = request?.payload;
    // A body-less request signs an empty payload, and carries no `content-type` to sign — the header has to be
    // signed exactly when it is sent, or the signature will not match.
    string body = payload is () ? "" : payload.toJsonString();
    map<string> headersToSign = payload is () ? {} : {[CONTENT_TYPE_HEADER]: JSON_CONTENT_TYPE};

    map<string>|auth:SigningError signedHeaders = auth:getSignedHeaders({
        method: request.method,
        host: host,
        path: request.path,
        queryParams: request.queryParams,
        headers: headersToSign,
        payload: body.toBytes()
    }, credentials, region, SIGNING_SERVICE_NAME);
    if signedHeaders is auth:SigningError {
        return error RequestGenerationError(
                string `Error occurred while signing the request: ${signedHeaders.message()}`, signedHeaders);
    }
    return signedHeaders;
}

# Signs an operation request and sends it to the Amazon SES endpoint.
#
# + sesClient - The HTTP client pointing at the resolved SES endpoint
# + credentialProvider - Provider that resolves the signing credentials
# + host - The endpoint host to sign against
# + region - The signing region
# + request - The operation request to send
# + return - The JSON response payload, `()` when the service answers with no content, or an `Error`
isolated function sendRequest(http:Client sesClient, auth:CredentialProvider credentialProvider, string host,
        aws:Region|string region, SesRequest request) returns json|Error {
    map<string> signedHeaders = check signRequest(credentialProvider, host, region, request);
    string requestTarget = string `${encodePath(request.path)}${encodeQuery(request.queryParams)}`;
    json? payload = request?.payload;

    http:Response|http:ClientError response;
    if payload is () {
        // GET and DELETE send no body, so the signed headers travel on their own.
        if request.method == HTTP_GET {
            response = sesClient->get(requestTarget, signedHeaders);
        } else {
            response = sesClient->delete(requestTarget, headers = signedHeaders);
        }
    } else {
        // The body has to go out byte-for-byte as it was signed, with the same `content-type`, so it is set as text
        // rather than left to the client's JSON serialisation.
        http:Request httpRequest = new;
        httpRequest.setTextPayload(payload.toJsonString(), JSON_CONTENT_TYPE);
        foreach [string, string] [name, value] in signedHeaders.entries() {
            httpRequest.setHeader(name, value);
        }
        if request.method == HTTP_PUT {
            response = sesClient->put(requestTarget, httpRequest);
        } else {
            response = sesClient->post(requestTarget, httpRequest);
        }
    }

    if response is http:ClientError {
        return error Error(string `Error occurred while invoking the REST API: ${response.message()}`, response);
    }
    return handleResponse(response);
}

# Reads the response payload, turning a service failure into an `Error` carrying the `aws:ErrorDetails` the shared
# package defines. When the body cannot be read at all, the read failure becomes the error's cause.
#
# + response - The response received from the service
# + return - The JSON response payload, `()` when the response carries no content, or an `Error`
isolated function handleResponse(http:Response response) returns json|Error {
    int statusCode = response.statusCode;
    // The body is read as bytes rather than through `getJsonPayload`, so that an empty body and a body that is not
    // JSON are both readable — a failure response is not always the service's JSON error document.
    byte[]|http:ClientError rawBody = response.getBinaryPayload();
    if rawBody is http:ClientError {
        if isSuccess(statusCode) {
            return error ResponseHandlingError(
                    string `Error occurred while reading the response payload: ${rawBody.message()}`, rawBody);
        }
        return unreadableServiceError(response, rawBody);
    }
    string|error body = string:fromBytes(rawBody);

    if isSuccess(statusCode) {
        if body is error {
            return error ResponseHandlingError(
                    string `Error occurred while reading the response payload: ${body.message()}`, body);
        }
        // Several SES operations answer a success with no body at all.
        if body.trim() == "" {
            return;
        }
        json|error payload = body.fromJsonString();
        if payload is error {
            return error ResponseHandlingError(
                    string `Error occurred while parsing the response payload: ${payload.message()}`, payload);
        }
        return payload;
    }

    if body is error {
        return unreadableServiceError(response, body);
    }
    json|error errorBody = body.fromJsonString();
    json? errorDocument = errorBody is json ? errorBody : ();
    return serviceError(response, errorType(response, errorDocument), errorDescription(errorDocument, body));
}

# Reports whether the status is one Amazon SES answers a successful operation with.
#
# + statusCode - The response status code
# + return - Whether the operation succeeded
isolated function isSuccess(int statusCode) returns boolean {
    return statusCode == http:STATUS_OK || statusCode == http:STATUS_NO_CONTENT;
}

# Builds the error for a service failure whose body could not be read, so only the response identifies it.
#
# + response - The response received from the service
# + cause - The failure that prevented the body from being read
# + return - The error to raise
isolated function unreadableServiceError(http:Response response, error cause) returns Error {
    return error Error(failureMessage(response), cause, httpStatusCode = response.statusCode,
            httpStatusText = response.reasonPhrase, requestId = requestId(response));
}

# Builds the error for a service failure, populating whichever `aws:ErrorDetails` fields the response supplied.
#
# The detail record is closed, and a detail record cannot be spread into an error constructor, so the fields that
# may be absent are supplied through explicit branches.
#
# + response - The response received from the service
# + code - The error shape name Amazon SES reported, if any
# + description - The error message Amazon SES reported, if any
# + return - The error to raise
isolated function serviceError(http:Response response, string? code, string? description) returns Error {
    string message = failureMessage(response);
    int statusCode = response.statusCode;
    string statusText = response.reasonPhrase;
    string id = requestId(response);
    if code is string && description is string {
        return error Error(message, httpStatusCode = statusCode, httpStatusText = statusText, requestId = id,
                errorCode = code, errorMessage = description);
    }
    if code is string {
        return error Error(message, httpStatusCode = statusCode, httpStatusText = statusText, requestId = id,
                errorCode = code);
    }
    if description is string {
        return error Error(message, httpStatusCode = statusCode, httpStatusText = statusText, requestId = id,
                errorMessage = description);
    }
    return error Error(message, httpStatusCode = statusCode, httpStatusText = statusText, requestId = id);
}

# Renders the message of a service failure. The error code and the service's own description are carried in the
# error detail rather than here, so that the message stays stable across operations.
#
# + response - The response received from the service
# + return - The error message
isolated function failureMessage(http:Response response) returns string {
    return string `The Amazon SES operation failed with status ${response.statusCode}`;
}

# Reads the error shape name Amazon SES reported. The service speaks the `restJson1` protocol, which carries the
# name in the `x-amzn-errortype` header; a `__type` or a `code` field in the body is the accepted fallback.
#
# + response - The response received from the service
# + body - The response body parsed as JSON, or `()` when it is not JSON
# + return - The error shape name, or `()` when the response reports none
isolated function errorType(http:Response response, json? body) returns string? {
    string|error header = response.getHeader(ERROR_TYPE_HEADER);
    if header is string && header.trim() != "" {
        return shapeName(header);
    }
    if body is map<json> {
        json? declared = body[TYPE_FIELD] ?: body[CODE_FIELD];
        if declared is string && declared.trim() != "" {
            return shapeName(declared);
        }
    }
    return;
}

# Trims the decorations the protocol permits around an error shape name: everything from the first `:` onwards, and
# everything up to the first `#`. So `aws.protocoltests.restjson#FooError:https://internal/` reads as `FooError`.
#
# + value - The reported error type
# + return - The shape name alone
isolated function shapeName(string value) returns string {
    string name = value;
    int? colon = name.indexOf(":");
    if colon is int {
        name = name.substring(0, colon);
    }
    int? hash = name.indexOf("#");
    if hash is int {
        name = name.substring(hash + 1);
    }
    return name.trim();
}

# Reads the human-readable description Amazon SES reported. A body that is not the service's JSON error document —
# a proxy's HTML page, say — is surfaced as-is rather than dropped, since it is the only account of the failure.
#
# + body - The response body parsed as JSON, or `()` when it is not JSON
# + rawBody - The response body as text
# + return - The error description, or `()` when the response carries none
isolated function errorDescription(json? body, string rawBody) returns string? {
    if body is map<json> {
        json? described = body[MESSAGE_FIELD] ?: body[MESSAGE_FIELD_LEGACY];
        if described is string {
            return described;
        }
    }
    return rawBody.trim() == "" ? () : rawBody;
}

# Reads the request id AWS stamps on every response, so that a failure can be quoted to AWS support.
#
# + response - The response received from the service
# + return - The request id, or `""` when the response carries none
isolated function requestId(http:Response response) returns string {
    string|error id = response.getHeader(REQUEST_ID_HEADER);
    return id is string ? id : "";
}

# Adds the pagination parameters to a query parameter map, omitting the ones that are not set.
#
# + nextToken - The continuation token of the page to fetch
# + pageSize - The maximum number of results the page may carry
# + return - The query parameters for the page
isolated function paginationParams(string? nextToken, int? pageSize) returns map<string> {
    map<string> params = {};
    if nextToken is string {
        params[NEXT_TOKEN_PARAM] = nextToken;
    }
    if pageSize is int {
        params[PAGE_SIZE_PARAM] = pageSize.toString();
    }
    return params;
}
