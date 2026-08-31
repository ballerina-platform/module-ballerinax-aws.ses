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

import ballerina/os;
import ballerinax/aws;
import ballerinax/aws.auth;

// Credentials, shared with the other Ballerina AWS connectors so that one set of CI secrets drives all of them.
final string testAccessKeyId = os:getEnv("BALLERINA_AWS_TEST_ACCESS_KEY_ID");
final string testSecretAccessKey = os:getEnv("BALLERINA_AWS_TEST_SECRET_ACCESS_KEY");
final string testSessionToken = os:getEnv("BALLERINA_AWS_TEST_SESSION_TOKEN");
final string testRegionEnv = os:getEnv("BALLERINA_AWS_TEST_REGION");

// SES-specific resources. Sending mail needs a verified identity, so a live run has to be told which one to use.
final string testSenderEnv = os:getEnv("BALLERINA_AWS_SES_TEST_SENDER_EMAIL");
final string testRecipientEnv = os:getEnv("BALLERINA_AWS_SES_TEST_RECIPIENT_EMAIL");

# Live tests run only when the credentials and a verified sender are all present; otherwise the same tests run
# against the local mock, which needs nothing configured.
final boolean isLiveTestEnabled = testAccessKeyId != "" && testSecretAccessKey != "" && testSenderEnv != "";

// The fixture values. The mock echoes these back, so the assertions in `test.bal` hold in both modes.
final aws:Region|string testRegion = isLiveTestEnabled && testRegionEnv != "" ? testRegionEnv : aws:US_EAST_1;
final string testSenderEmail = isLiveTestEnabled ? testSenderEnv : "sender@example.com";
final string testRecipientEmail = isLiveTestEnabled && testRecipientEnv != "" ? testRecipientEnv
    : "recipient@example.com";
final string testContactListName = "ballerina-ses-test-list";
final string testContactEmail = "reader+ballerina@example.com";
final string testTemplateName = "BallerinaSesTestTemplate";
final string testVerificationTemplateName = "BallerinaSesTestVerification";

final Client ses = check initClient();

# Creates the client the tests run against: a live one when the environment supplies credentials, and one pointed at
# the local mock otherwise.
#
# + return - The client, or an `error` if it cannot be initialized
isolated function initClient() returns Client|error {
    if isLiveTestEnabled {
        auth:StaticAuthConfig credentials = testSessionToken == ""
            ? {accessKeyId: testAccessKeyId, secretAccessKey: testSecretAccessKey}
            : {accessKeyId: testAccessKeyId, secretAccessKey: testSecretAccessKey, sessionToken: testSessionToken};
        return new ({auth: credentials, region: testRegion});
    }
    return newMockClient();
}

# Creates a client pointed at the local mock service, through the connector's own endpoint override — the mock is
# reached the way a user would reach LocalStack, not through a test-only path inside the client.
#
# + return - The client, or an `error` if it cannot be initialized
isolated function newMockClient() returns Client|error {
    return new ({
        auth: {accessKeyId: "MOCK_ACCESS_KEY_ID", secretAccessKey: "MOCK_SECRET_ACCESS_KEY"},
        region: aws:US_EAST_1,
        endpoint: {customEndpoint: MOCK_ENDPOINT}
    });
}
