// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/http;

# Handles the HTTP response.
#
# + httpResponse - Http response or error
# + return - If successful returns `json` response. Else returns error.
isolated function handleResponse(http:Response|error httpResponse) returns @untainted xml|Error {
    if (httpResponse is http:Response) {
        if (httpResponse.statusCode == http:STATUS_NO_CONTENT){
            //If status 204, then no response body. So returns json boolean true.
            return Error(NO_CONTENT_SET_WITH_RESPONSE_MSG);
        }
        var xmlResponse = httpResponse.getXmlPayload();
        if (xmlResponse is xml) {
            if (httpResponse.statusCode == http:STATUS_OK) {
                //If status is 200, request is successful. Returns resulting payload.
                return xmlResponse;
            } else {
                //If status is not 200 or 204, request is unsuccessful. Returns error.
                xmlns "http://ses.amazonaws.com/doc/2010-12-01/" as ns;
                string xmlResponseErrorCode = httpResponse.statusCode.toString();
                string responseErrorMessage = (xmlResponse/*).toString();
                string errorMsg = string `${STATUS_CODE}:${xmlResponseErrorCode}; ${MESSAGE}: ${responseErrorMessage}`;
                return Error(errorMsg);
            }
        } else {
            return Error(RESPONSE_PAYLOAD_IS_NOT_XML_MSG);
        }
    } else {
        return Error(ERROR_OCCURRED_WHILE_INVOKING_REST_API_MSG, httpResponse);
    }
}
