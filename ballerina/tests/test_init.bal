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

import ballerina/os;
import ballerina/test;
import ballerinax/aws;
import ballerinax/aws.auth;

configurable boolean isLiveServer = os:getEnv("IS_LIVE_SERVER") == "true";

configurable string accessKeyId = os:getEnv("BALLERINA_AWS_TEST_ACCESS_KEY_ID");
configurable string secretAccessKey = os:getEnv("BALLERINA_AWS_TEST_SECRET_ACCESS_KEY");

// The identity a live run sends from, which has to be verified in the account, and the address it sends to.
configurable string senderEmail = os:getEnv("BALLERINA_AWS_SES_TEST_SENDER_EMAIL");
configurable string recipientEmail = os:getEnv("BALLERINA_AWS_SES_TEST_RECIPIENT_EMAIL");

final readonly & aws:Region awsRegion = aws:US_EAST_1;

final readonly & auth:StaticAuthConfig liveAuth = {accessKeyId, secretAccessKey};

final Client ses = check newMockClient();

isolated function newLiveClient() returns Client|error => new ({region: awsRegion, auth: liveAuth});

@test:AfterSuite
function releaseClient() returns error? {
    check ses.close();
}
