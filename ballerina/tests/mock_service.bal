// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
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

const int MOCK_PORT = 21098;
const string MOCK_ENDPOINT = "http://localhost:21098";

# What the mock recorded about the request it last served, so that tests can assert on what the connector actually
# put on the wire — the signature, the content type, the encoded path, and the payload.
type RecordedRequest record {|
    # The HTTP method
    string method = "";
    # The raw request target, percent-encoding and query string included, exactly as the connector sent it
    string rawPath = "";
    # The `Authorization` header, carrying the SigV4 signature
    string authorization = "";
    # The `content-type` header, empty when the request carried none
    string contentType = "";
    # The request body, empty when the request carried none
    string payload = "";
    # How many requests the mock has served since the last reset
    int callCount = 0;
|};

# The mock's state, held as one record because a `lock` statement may access only one isolated module-level variable.
isolated RecordedRequest lastRequest = {};

# Records what the connector sent, so that a test can assert on it.
#
# + request - The request the mock is serving
isolated function recordRequest(http:Request request) {
    string authorization = "";
    string|error authHeader = request.getHeader("Authorization");
    if authHeader is string {
        authorization = authHeader;
    }
    string contentType = request.getContentType();
    string payload = "";
    string|error body = request.getTextPayload();
    if body is string {
        payload = body;
    }
    lock {
        int previous = lastRequest.callCount;
        lastRequest = {
            method: request.method,
            rawPath: request.rawPath,
            authorization: authorization,
            contentType: contentType,
            payload: payload,
            callCount: previous + 1
        };
    }
}

# Returns a copy of the last recorded request.
#
# + return - What the mock recorded about the request it last served
isolated function getLastRequest() returns RecordedRequest {
    lock {
        return lastRequest.clone();
    }
}

# Clears the recorded request and the call count, so that a test can count the calls one operation makes.
isolated function resetMock() {
    lock {
        lastRequest = {};
    }
}

# The paging fixtures. `listContactLists` is served in three pages, the second of which is empty but still carries a
# continuation token — a shape the service does produce, and the one that used to make the connector panic.
#
# + nextToken - The continuation token the connector asked for, absent for the first page
# + return - The page of contact lists
isolated function contactListPage(string? nextToken) returns json {
    match nextToken {
        () => {
            return {
                "ContactLists": [{"ContactListName": "list-one", "LastUpdatedTimestamp": 1735689600}],
                "NextToken": "page-2"
            };
        }
        "page-2" => {
            return {"ContactLists": [], "NextToken": "page-3"};
        }
        _ => {
            return {"ContactLists": [{"ContactListName": "list-two", "LastUpdatedTimestamp": 1735776000}]};
        }
    }
}

isolated service / on new http:Listener(MOCK_PORT) {

    # Serves every Amazon SES operation the tests exercise. A single catch-all resource is used rather than one
    # resource per path, so that the mock sees the request target exactly as the connector encoded it.
    #
    # + request - The request the connector sent
    # + path - The path segments of the request
    # + return - The mocked response
    isolated resource function 'default [string... path](http:Request request) returns http:Response|error {
        recordRequest(request);
        string route = string:'join("/", ...path);
        string method = request.method;
        http:Response response = new;

        // Anything outside the SES API v2 base path is a mistake on the connector's side, not a fixture gap.
        if !route.startsWith("v2/email") {
            response.statusCode = http:STATUS_NOT_FOUND;
            response.setJsonPayload({"message": "Unexpected base path"});
            return response;
        }
        string operation = route.substring("v2/email".length());
        if operation.startsWith("/") {
            operation = operation.substring(1);
        }

        json payload = {};
        int status = http:STATUS_OK;
        string errorType = "";

        if operation == "contact-lists" && method == "GET" {
            payload = contactListPage(request.getQueryParamValue("NextToken"));
        } else if operation == "contact-lists" && method == "POST" {
            payload = {};
        } else if operation.startsWith("contact-lists/") && operation.endsWith("/contacts/list") {
            payload = {"Contacts": [{"EmailAddress": "reader@example.com", "UnsubscribeAll": false}]};
        } else if operation.startsWith("contact-lists/") && operation.endsWith("/contacts") {
            payload = {};
        } else if operation.startsWith("contact-lists/") && operation.includes("/contacts/") {
            // A single contact: read, replaced, or removed.
            payload = method == "GET" ? {
                    "EmailAddress": "reader@example.com",
                    "ContactListName": "ballerina-ses-test-list",
                    "UnsubscribeAll": false,
                    "TopicPreferences": [{"TopicName": "updates", "SubscriptionStatus": "OPT_IN"}],
                    "CreatedTimestamp": 1735689600
                } : {};
        } else if operation.startsWith("contact-lists/") {
            // A single contact list: read, replaced, or removed.
            payload = method == "GET" ? {
                    "ContactListName": "ballerina-ses-test-list",
                    "Description": "A list used by the Ballerina connector tests",
                    "Topics": [
                        {
                            "TopicName": "updates",
                            "DisplayName": "Product updates",
                            "DefaultSubscriptionStatus": "OPT_IN"
                        }
                    ],
                    "CreatedTimestamp": 1735689600,
                    "LastUpdatedTimestamp": 1735776000
                } : {};
        } else if operation == "templates" && method == "GET" {
            payload = {
                "TemplatesMetadata": [{"TemplateName": "BallerinaSesTestTemplate", "CreatedTimestamp": 1735689600}]
            };
        } else if operation == "templates" && method == "POST" {
            payload = {};
        } else if operation.startsWith("templates/") {
            payload = method == "GET" ? {
                    "TemplateName": "BallerinaSesTestTemplate",
                    "TemplateContent": {
                        "Subject": "Your order {{orderId}} has shipped",
                        "Html": "<html><body><p>On its way.</p></body></html>",
                        "Text": "On its way."
                    }
                } : {};
        } else if operation == "custom-verification-email-templates" && method == "GET" {
            payload = {
                "CustomVerificationEmailTemplates": [
                    {
                        "TemplateName": "BallerinaSesTestVerification",
                        "FromEmailAddress": "sender@example.com",
                        "TemplateSubject": "Please confirm your email address",
                        "SuccessRedirectionURL": "https://example.com/verified",
                        "FailureRedirectionURL": "https://example.com/not-verified"
                    }
                ]
            };
        } else if operation == "custom-verification-email-templates" && method == "POST" {
            payload = {};
        } else if operation.startsWith("custom-verification-email-templates/") {
            payload = method == "GET" ? {
                    "TemplateName": "BallerinaSesTestVerification",
                    "FromEmailAddress": "sender@example.com",
                    "TemplateSubject": "Please confirm your email address",
                    "TemplateContent": "<html><body><p>Confirm your address.</p></body></html>",
                    "SuccessRedirectionURL": "https://example.com/verified",
                    "FailureRedirectionURL": "https://example.com/not-verified"
                } : {};
        } else if operation == "identities" && method == "GET" {
            payload = {
                "EmailIdentities": [
                    {
                        "IdentityName": "sender@example.com",
                        "IdentityType": "EMAIL_ADDRESS",
                        "SendingEnabled": true,
                        "VerificationStatus": "SUCCESS"
                    }
                ]
            };
        } else if operation == "identities" && method == "POST" {
            payload = {
                "IdentityType": "EMAIL_ADDRESS",
                "VerifiedForSendingStatus": false,
                "DkimAttributes": {"SigningEnabled": false, "Status": "NOT_STARTED"}
            };
        } else if operation.startsWith("identities/") {
            if method == "GET" && operation.endsWith("unknown@example.com") {
                // The one negative path: an identity that does not exist. Amazon SES reports the exception in the
                // `x-amzn-errortype` header, decorated the way the protocol permits, and its description in the body.
                status = http:STATUS_NOT_FOUND;
                errorType = "aws.sesv2#NotFoundException:https://internal.amazon.com/coral";
                payload = {"message": "Email identity unknown@example.com not found."};
            } else {
                payload = method == "GET" ? {
                        "IdentityType": "EMAIL_ADDRESS",
                        "VerificationStatus": "SUCCESS",
                        "VerifiedForSendingStatus": true,
                        "FeedbackForwardingStatus": true,
                        "DkimAttributes": {"SigningEnabled": true, "Status": "SUCCESS", "Tokens": ["token-one"]}
                    } : {};
            }
        } else if operation == "outbound-emails" || operation == "outbound-custom-verification-emails" {
            payload = {"MessageId": "0100018f-mock-message-id"};
        } else if operation == "outbound-bulk-emails" {
            payload = {
                "BulkEmailEntryResults": [{"Status": "SUCCESS", "MessageId": "0100018f-mock-bulk-id"}]
            };
        } else {
            status = http:STATUS_NOT_FOUND;
            payload = {"message": string `No fixture for ${method} ${operation}`};
        }

        response.statusCode = status;
        response.setHeader("x-amzn-RequestId", "mock-request-id");
        if errorType != "" {
            response.setHeader("x-amzn-errortype", errorType);
        }
        response.setJsonPayload(payload);
        return response;
    }
}
