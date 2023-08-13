// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
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

import ballerina/crypto;
import ballerina/http;
import ballerina/jballerina.java;
import ballerina/lang.array;
import ballerina/regex;
import ballerina/time;
import ballerina/url;

isolated function getSignedRequestHeaders(string host, string accessKey, string secretKey, string region, string verb, 
                                          string uri, json requestPayload) returns map<string>|error {

    string content_type =APPLICATION_JSON;
    string canonicalUri = check getCanonicalURI(uri);
    string payload = requestPayload === EMPTY_STRING ? EMPTY_STRING : requestPayload.toJsonString();

    [int, decimal] & readonly currentTime = time:utcNow();
    string|error amzDate = utcToString(currentTime, ISO8601_BASIC_DATE_FORMAT);
    string|error dateStamp = utcToString(currentTime, SHORT_DATE_FORMAT);

    if (amzDate is string && dateStamp is string) {
        string canonicalQuerystring = EMPTY_STRING;

        string canonicalHeaders = CONTENT_TYPE + COLON + content_type + NEW_LINE +HOST + COLON + host + NEW_LINE + 
                                  X_AMZ_DATE + COLON + amzDate + NEW_LINE;

        string signedHeaders = CONTENT_TYPE + SEMICOLON + HOST + SEMICOLON + X_AMZ_DATE;

        string payloadHash = array:toBase16(crypto:hashSha256(payload.toBytes())).toLowerAscii();

        string canonicalRequest = verb + NEW_LINE + canonicalUri + NEW_LINE + canonicalQuerystring + NEW_LINE
                                  + canonicalHeaders + NEW_LINE + signedHeaders + NEW_LINE + payloadHash;

        string credentialScope = dateStamp + SLASH + region + SLASH + SERVICE_NAME 
                                 + SLASH + AWS4_REQUEST;
                  
        string stringToSign = AWS4_HMAC_SHA256 + NEW_LINE +  amzDate + NEW_LINE +  credentialScope + NEW_LINE
                              + array:toBase16(crypto:hashSha256(canonicalRequest.toBytes())).toLowerAscii();

        byte[] signingKey = check getSignatureKey(secretKey, dateStamp, region, SERVICE_NAME);

        string signature = array:toBase16(check crypto:hmacSha256(stringToSign.toBytes(), signingKey)).toLowerAscii();

        string authorizationHeader = AWS4_HMAC_SHA256 + SPACE + CREDENTIAL + EQUAL + accessKey + SLASH
                                     + credentialScope + COMMA + SPACE +  SIGNED_HEADER + EQUAL + signedHeaders
                                     + COMMA + SPACE + SIGNATURE + EQUAL + signature;

        map<string> headers = {};
        headers[HEADER_CONTENT_TYPE] = content_type;
        headers[HEADER_HOST] = host;
        headers[HEADER_X_AMZ_DATE] = amzDate;
        headers[HEADER_AUTHORIZATION] = authorizationHeader;
                
        return headers;
    } else {
        if (amzDate is error) {
            return error(GENERATE_SIGNED_REQUEST_HEADERS_FAILED_MSG, amzDate);
        } else if (dateStamp is error) {
            return error (GENERATE_SIGNED_REQUEST_HEADERS_FAILED_MSG, dateStamp);
        } else {
            return error (GENERATE_SIGNED_REQUEST_HEADERS_FAILED_MSG);
        }
    }
}

isolated function sign(byte[] key, string msg) returns byte[]|error {
        return check crypto:hmacSha256(msg.toBytes(), key);
}

isolated function getSignatureKey(string secretKey, string datestamp, string region, string serviceName)  
                                  returns byte[]|error {
        string awskey = (AWS4 + secretKey);
        byte[] kDate = check sign(awskey.toBytes(), datestamp);
        byte[] kRegion = check sign(kDate, region);
        byte[] kService = check sign(kRegion, serviceName);
        byte[] kSigning = check sign(kService, AWS4_REQUEST);
        return kSigning;
}

isolated function utcToString(time:Utc utc, string pattern) returns string|error {
    [int, decimal][epochSeconds, lastSecondFraction] = utc;
    int nanoAdjustments = (<int>lastSecondFraction * 1000000000);
    var instant = ofEpochSecond(epochSeconds, nanoAdjustments);
    var zoneId = getZoneId(java:fromString(Z));
    var zonedDateTime = atZone(instant, zoneId);
    var dateTimeFormatter = ofPattern(java:fromString(pattern));
    handle formatString = format(zonedDateTime, dateTimeFormatter);
    return formatString.toBalString();
}

isolated function getCanonicalURI(string requestURI) returns string|error {
    string value = check url:encode(requestURI, UTF_8);
    return regex:replaceAll(value, ENCODED_SLASH, SLASH);
}

isolated function handleHttpResponse(http:Response httpResponse) returns error? {
    int statusCode = httpResponse.statusCode;
    if (statusCode != http:STATUS_NO_CONTENT && statusCode != http:STATUS_OK) {
        json jsonPayload = check httpResponse.getJsonPayload();
        return error(statusCode.toString() + COLON + jsonPayload.toString() );
    }
}
