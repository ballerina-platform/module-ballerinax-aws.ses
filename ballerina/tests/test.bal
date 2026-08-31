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

import ballerina/data.jsondata;
import ballerina/test;
import ballerinax/aws;
import ballerinax/aws.auth;

@test:Config {groups: ["dataBinding"]}
isolated function testRequestUsesWireFieldNames() {
    CreateContactListInput request = {
        contactListName: "Newsletter",
        description: "Weekly product news",
        topics: [
            {
                topicName: "updates",
                displayName: "Product updates",
                defaultSubscriptionStatus: OPT_IN
            }
        ]
    };
    json payload = jsondata:toJson(request);
    // The Ballerina fields are camelCase, but the wire names Amazon SES expects are PascalCase.
    test:assertEquals(payload, {
        "ContactListName": "Newsletter",
        "Description": "Weekly product news",
        "Topics": [
            {
                "TopicName": "updates",
                "DisplayName": "Product updates",
                "DefaultSubscriptionStatus": "OPT_IN"
            }
        ]
    });
}

@test:Config {groups: ["dataBinding"]}
isolated function testSendEmailRequestBinding() {
    SendEmailInput request = {
        fromEmailAddress: "sender@example.com",
        destination: {toAddresses: ["recipient@example.com"], ccAddresses: ["cc@example.com"]},
        replyToAddresses: ["reply@example.com"],
        configurationSetName: "default-set",
        content: {
            simple: {
                subject: {data: "Your order has shipped", charset: "UTF-8"},
                body: {
                    html: {data: "<html><body><p>On its way.</p></body></html>"},
                    text: {data: "On its way."}
                }
            }
        }
    };
    map<json> payload = <map<json>>jsondata:toJson(request);
    test:assertEquals(payload["FromEmailAddress"], "sender@example.com");
    test:assertEquals(payload["ReplyToAddresses"], ["reply@example.com"]);
    test:assertEquals(payload["ConfigurationSetName"], "default-set");
    map<json> destination = <map<json>>payload["Destination"];
    test:assertEquals(destination["ToAddresses"], ["recipient@example.com"]);
    test:assertEquals(destination["CcAddresses"], ["cc@example.com"]);
    // An HTML body is reachable at last — 2.x could only send plain text.
    map<json> content = <map<json>>payload["Content"];
    map<json> simple = <map<json>>content["Simple"];
    map<json> body = <map<json>>simple["Body"];
    map<json> html = <map<json>>body["Html"];
    test:assertEquals(html["Data"], "<html><body><p>On its way.</p></body></html>");
}

@test:Config {groups: ["dataBinding"]}
isolated function testResponseBinding() returns error? {
    json response = {
        "ContactListName": "Newsletter",
        "Description": "Weekly product news",
        "Topics": [
            {
                "TopicName": "updates",
                "DisplayName": "Product updates",
                "DefaultSubscriptionStatus": "OPT_OUT",
                "Description": "Product release notes"
            }
        ],
        "CreatedTimestamp": 1735689600,
        "LastUpdatedTimestamp": 1735776000
    };
    ContactListDetails details = check jsondata:parseAsType(response);
    test:assertEquals(details.contactListName, "Newsletter");
    test:assertEquals(details.createdTimestamp, <decimal>1735689600);
    Topic[] topics = check details.topics.ensureType();
    test:assertEquals(topics[0].topicName, "updates");
    test:assertEquals(topics[0].defaultSubscriptionStatus, OPT_OUT);
    test:assertEquals(topics[0].description, "Product release notes");
}

@test:Config {groups: ["dataBinding"]}
isolated function testIdentityResponseBinding() returns error? {
    json response = {
        "IdentityType": "DOMAIN",
        "VerificationStatus": "SUCCESS",
        "VerifiedForSendingStatus": true,
        "FeedbackForwardingStatus": true,
        "DkimAttributes": {
            "SigningEnabled": true,
            "Status": "SUCCESS",
            "SigningAttributesOrigin": "AWS_SES",
            "CurrentSigningKeyLength": "RSA_2048_BIT",
            "Tokens": ["token-one", "token-two"]
        },
        "MailFromAttributes": {
            "MailFromDomain": "mail.example.com",
            "MailFromDomainStatus": "SUCCESS",
            "BehaviorOnMxFailure": "USE_DEFAULT_VALUE"
        },
        "Policies": {"policy-one": "{\"Version\":\"2012-10-17\"}"}
    };
    EmailIdentityDetails identity = check jsondata:parseAsType(response);
    test:assertEquals(identity.identityType, DOMAIN);
    test:assertEquals(identity.verificationStatus, SUCCESS);
    DkimAttributes dkim = check identity.dkimAttributes.ensureType();
    test:assertEquals(dkim.status, SUCCESS);
    test:assertEquals(dkim.currentSigningKeyLength, RSA_2048_BIT);
    test:assertEquals(dkim.tokens, ["token-one", "token-two"]);
    MailFromAttributes mailFrom = check identity.mailFromAttributes.ensureType();
    test:assertEquals(mailFrom.behaviorOnMxFailure, USE_DEFAULT_VALUE);
    map<string> policies = check identity.policies.ensureType();
    test:assertEquals(policies["policy-one"], "{\"Version\":\"2012-10-17\"}");
}

// ---------------------------------------------------------------------------
// Percent-encoding — the half of the signature that is computed on this side
// ---------------------------------------------------------------------------

@test:Config {groups: ["dataBinding"]}
isolated function testEncodeValueLeavesUnreservedCharacters() {
    test:assertEquals(encodeValue("BallerinaSesTestTemplate"), "BallerinaSesTestTemplate");
    test:assertEquals(encodeValue("a-b_c.d~e"), "a-b_c.d~e");
}

@test:Config {groups: ["dataBinding"]}
isolated function testEncodeValueEncodesReservedCharacters() {
    // `+` in an email address is the case that matters: left as-is, the service would read it as a space.
    test:assertEquals(encodeValue("reader+tag@example.com"), "reader%2Btag%40example.com");
    test:assertEquals(encodeValue("a b"), "a%20b");
    test:assertEquals(encodeValue("a/b"), "a%2Fb");
}

@test:Config {groups: ["dataBinding"]}
isolated function testEncodePathPreservesSeparators() {
    test:assertEquals(encodePath("/v2/email/contact-lists/my list"), "/v2/email/contact-lists/my%20list");
    test:assertEquals(encodePath("/v2/email/identities/reader+tag@example.com"),
            "/v2/email/identities/reader%2Btag%40example.com");
}

@test:Config {groups: ["dataBinding"]}
isolated function testEncodeQuery() {
    test:assertEquals(encodeQuery({}), "");
    test:assertEquals(encodeQuery({"PageSize": "10"}), "?PageSize=10");
    test:assertEquals(encodeQuery({"NextToken": "a+b/c"}), "?NextToken=a%2Bb%2Fc");
}

@test:Config {groups: ["dataBinding"]}
isolated function testShapeNameStripsProtocolDecorations() {
    // `restJson1` permits the reported error type to be decorated; only the shape name is of use to a caller.
    test:assertEquals(shapeName("NotFoundException"), "NotFoundException");
    test:assertEquals(shapeName("aws.sesv2#NotFoundException"), "NotFoundException");
    test:assertEquals(shapeName("aws.sesv2#NotFoundException:https://internal/"), "NotFoundException");
    test:assertEquals(shapeName("NotFoundException:https://internal/"), "NotFoundException");
}

@test:Config {groups: ["dataBinding"]}
isolated function testPaginationParamsOmitUnsetValues() {
    test:assertEquals(paginationParams((), ()), {});
    test:assertEquals(paginationParams("token", ()), {"NextToken": "token"});
    test:assertEquals(paginationParams((), 25), {"PageSize": "25"});
    test:assertEquals(paginationParams("token", 25), {"NextToken": "token", "PageSize": "25"});
}

// ---------------------------------------------------------------------------
// Operations — run against the mock by default, against the live API when configured
// ---------------------------------------------------------------------------

@test:Config {groups: ["operations"]}
function testGetContactList() returns error? {
    ContactListDetails details = check ses->getContactList(MOCK_CONTACT_LIST_NAME);
    test:assertTrue(details.contactListName is string);
}

@test:Config {groups: ["operations"]}
function testListContactListsPagesThrough() returns error? {
    stream<ContactList, Error?> contactLists = ses->listContactLists();
    int count = 0;
    check from ContactList _ in contactLists
        do {
            count += 1;
        };
    test:assertTrue(count >= 1, "expected at least one contact list");
}

@test:Config {groups: ["operations"]}
function testListEmailIdentities() returns error? {
    stream<IdentityInfo, Error?> identities = ses->listEmailIdentities({pageSize: 10});
    IdentityInfo[] found = [];
    check from IdentityInfo identity in identities
        do {
            found.push(identity);
        };
    test:assertTrue(found.length() >= 1, "expected at least one email identity");
    test:assertTrue(found[0].identityName is string);
}

@test:Config {groups: ["operations"]}
function testListEmailTemplates() returns error? {
    stream<EmailTemplateMetadata, Error?> templates = ses->listEmailTemplates();
    EmailTemplateMetadata[] found = [];
    check from EmailTemplateMetadata template in templates
        do {
            found.push(template);
        };
    test:assertTrue(found.length() >= 1, "expected at least one email template");
}

@test:Config {groups: ["operations"]}
function testGetEmailIdentity() returns error? {
    EmailIdentityDetails identity = check ses->getEmailIdentity(MOCK_SENDER_EMAIL);
    test:assertTrue(identity.verificationStatus is VerificationStatus);
}

@test:Config {groups: ["operations"]}
function testGetEmailTemplate() returns error? {
    EmailTemplateDetails template = check ses->getEmailTemplate(MOCK_TEMPLATE_NAME);
    EmailTemplateContent content = check template.templateContent.ensureType();
    test:assertTrue(content.subject is string);
}

@test:Config {groups: ["operations"]}
function testGetCustomVerificationEmailTemplate() returns error? {
    CustomVerificationEmailTemplateDetails template =
        check ses->getCustomVerificationEmailTemplate(MOCK_VERIFICATION_TEMPLATE_NAME);
    test:assertTrue(template.fromEmailAddress is string);
}

@test:Config {groups: ["operations"]}
function testSendEmail() returns error? {
    SendEmailOutput result = check ses->sendEmail({
        fromEmailAddress: MOCK_SENDER_EMAIL,
        destination: {toAddresses: [MOCK_RECIPIENT_EMAIL]},
        content: {
            simple: {
                subject: {data: "Ballerina SES connector test"},
                body: {
                    html: {data: "<html><body><p>Sent by the Ballerina SES connector tests.</p></body></html>"},
                    text: {data: "Sent by the Ballerina SES connector tests."}
                }
            }
        }
    });
    test:assertTrue(result.messageId is string);
}

@test:Config {groups: ["operations"]}
function testSendBulkEmail() returns error? {
    SendBulkEmailOutput result = check ses->sendBulkEmail({
        fromEmailAddress: MOCK_SENDER_EMAIL,
        defaultContent: {
            template: {templateName: MOCK_TEMPLATE_NAME, templateData: "{\"orderId\":\"1\"}"}
        },
        bulkEmailEntries: [{destination: {toAddresses: [MOCK_RECIPIENT_EMAIL]}}]
    });
    test:assertTrue(result.bulkEmailEntryResults.length() >= 1);
}

// ---------------------------------------------------------------------------
// Mock-only — what only the mock can observe about the request on the wire
// ---------------------------------------------------------------------------

@test:Config {groups: ["mock"]}
function testRequestIsSignedWithSigV4() returns error? {
    _ = check ses->getContactList(MOCK_CONTACT_LIST_NAME);
    RecordedRequest request = getLastRequest();
    test:assertTrue(request.authorization.startsWith("AWS4-HMAC-SHA256 "),
            string `expected a SigV4 Authorization header, found: ${request.authorization}`);
    // The credential scope names the signing service, which for SES is `ses` even though the endpoint is `email`.
    test:assertTrue(request.authorization.includes("/ses/aws4_request"),
            "expected the credential scope to name the `ses` signing service");
    test:assertTrue(request.authorization.includes("SignedHeaders="));
    test:assertTrue(request.authorization.includes("Signature="));
}

@test:Config {groups: ["mock"]}
function testGetRequestCarriesNoContentType() returns error? {
    _ = check ses->getContactList(MOCK_CONTACT_LIST_NAME);
    RecordedRequest request = getLastRequest();
    test:assertEquals(request.method, "GET");
    // A `content-type` that was not signed would break the signature, so a body-less request must not carry one.
    test:assertEquals(request.contentType, "");
    test:assertEquals(request.payload, "");
}

@test:Config {groups: ["mock"]}
function testPostRequestCarriesJsonContentType() returns error? {
    check ses->createContactList({contactListName: MOCK_CONTACT_LIST_NAME, description: "test"});
    RecordedRequest request = getLastRequest();
    test:assertEquals(request.method, "POST");
    test:assertEquals(request.contentType, "application/json");
    test:assertEquals(request.rawPath, "/v2/email/contact-lists");
    test:assertEquals(request.payload,
            string `{"ContactListName":"${MOCK_CONTACT_LIST_NAME}", "Description":"test"}`);
}

@test:Config {groups: ["mock"]}
function testPathParametersArePercentEncoded() returns error? {
    // An email address carries `@`, and may carry `+` — both have to be encoded, or the signature will not match
    // the request the service receives.
    _ = check ses->getContact(MOCK_CONTACT_LIST_NAME, MOCK_CONTACT_EMAIL);
    RecordedRequest request = getLastRequest();
    test:assertEquals(request.rawPath, string `/v2/email/contact-lists/${MOCK_CONTACT_LIST_NAME}` +
            "/contacts/reader%2Bballerina%40example.com");
}

@test:Config {groups: ["mock"]}
function testListContactsUsesPostToListSubResource() returns error? {
    stream<Contact, Error?> contacts = ses->listContacts(MOCK_CONTACT_LIST_NAME, {
        filter: {filteredStatus: OPT_IN}
    });
    Contact[] found = [];
    check from Contact contact in contacts
        do {
            found.push(contact);
        };
    RecordedRequest request = getLastRequest();
    // `ListContacts` is the one list operation that is a POST with a body; 2.x sent a GET, which SES rejects.
    test:assertEquals(request.method, "POST");
    test:assertEquals(request.rawPath, string `/v2/email/contact-lists/${MOCK_CONTACT_LIST_NAME}/contacts/list`);
    test:assertTrue(request.payload.includes("\"Filter\""));
    test:assertTrue(request.payload.includes("\"FilteredStatus\":\"OPT_IN\""));
    test:assertEquals(found.length(), 1);
    test:assertEquals(found[0].emailAddress, MOCK_RECIPIENT_EMAIL);
}

@test:Config {groups: ["mock"]}
function testListPaginatesAcrossPagesIncludingAnEmptyOne() returns error? {
    resetMock();
    stream<ContactList, Error?> contactLists = ses->listContactLists();
    string[] names = [];
    check from ContactList contactList in contactLists
        do {
            names.push(contactList.contactListName ?: "");
        };
    // Three pages are served, the second empty but still carrying a continuation token. An empty page must neither
    // end the iteration nor be indexed into.
    test:assertEquals(names, ["list-one", "list-two"]);
    test:assertEquals(getLastRequest().callCount, 3);
}

@test:Config {groups: ["mock"]}
function testPageSizeIsSentAsAQueryParameter() returns error? {
    stream<EmailTemplateMetadata, Error?> templates = ses->listEmailTemplates({pageSize: 7});
    check from EmailTemplateMetadata _ in templates
        do {
        };
    test:assertEquals(getLastRequest().rawPath, "/v2/email/templates?PageSize=7");
}

@test:Config {groups: ["mock"]}
function testDeleteUsesDeleteMethod() returns error? {
    check ses->deleteEmailTemplate(MOCK_TEMPLATE_NAME);
    RecordedRequest request = getLastRequest();
    test:assertEquals(request.method, "DELETE");
    test:assertEquals(request.rawPath, string `/v2/email/templates/${MOCK_TEMPLATE_NAME}`);
}

@test:Config {groups: ["mock"]}
function testSendEmailPostsToOutboundEmails() returns error? {
    _ = check ses->sendEmail({
        fromEmailAddress: MOCK_SENDER_EMAIL,
        destination: {toAddresses: [MOCK_RECIPIENT_EMAIL]},
        content: {simple: {subject: {data: "Hello"}, body: {text: {data: "Hello"}}}}
    });
    RecordedRequest request = getLastRequest();
    test:assertEquals(request.rawPath, "/v2/email/outbound-emails");
    test:assertTrue(request.payload.includes("\"Simple\""));
    test:assertTrue(request.payload.includes("\"Text\""));
}

@test:Config {groups: ["mock"]}
function testServiceFailureIsMappedToError() {
    EmailIdentityDetails|Error result = ses->getEmailIdentity("unknown@example.com");
    if result is EmailIdentityDetails {
        test:assertFail("expected the operation to fail with a 404");
    }
    test:assertEquals(result.message(), "The Amazon SES operation failed with status 404");
    aws:ErrorDetails detail = result.detail();
    test:assertEquals(detail.httpStatusCode, 404);
    test:assertEquals(detail.requestId, "mock-request-id");
    // `restJson1` reports the exception in the `x-amzn-errortype` header and its description in the body, so both
    // reach the caller as typed detail rather than as a blob to substring-match.
    test:assertEquals(detail.errorCode, "NotFoundException");
    test:assertEquals(detail.errorMessage, "Email identity unknown@example.com not found.");
}

@test:Config {groups: ["mock"]}
function testInitAcceptsAPlainRegionString() returns error? {
    // `region` is `aws:Region|string`, so a region the enum does not yet know about still works.
    Client sesClient = check new ({
        auth: {accessKeyId: MOCK_ACCESS_KEY_ID, secretAccessKey: MOCK_SECRET_ACCESS_KEY},
        region: "us-west-2",
        endpoint: {customEndpoint: MOCK_ENDPOINT}
    });
    _ = check sesClient->getContactList(MOCK_CONTACT_LIST_NAME);
    test:assertTrue(getLastRequest().authorization.includes("/us-west-2/ses/aws4_request"),
            "the credential scope must name the region the client was configured with");
    check sesClient.close();
}

@test:Config {groups: ["mock"]}
function testInitWithDefaultCredentialsChain() returns error? {
    // The default provider chain resolves at init, so an environment with no credentials reports it here rather
    // than at the first request.
    Client|error result = new ({
        auth: auth:DEFAULT_CREDENTIALS,
        region: aws:US_EAST_1,
        endpoint: {customEndpoint: MOCK_ENDPOINT}
    });
    if result is error {
        test:assertTrue(result.message().includes("credential") || result.message().includes("Credential"),
                string `an init failure here must be a credential resolution failure, found: ${result.message()}`);
        return;
    }
    // Where the environment does supply credentials, the chain resolves and the provider's refresh threads have to
    // be released — the suite's `AfterSuite` only closes the shared client, not this one.
    check result.close();
}

@test:Config {groups: ["mock"]}
function testCloseReleasesTheCredentialProvider() returns error? {
    Client sesClient = check newMockClient();
    check sesClient.close();
}

@test:Config {groups: ["live"], enable: isLiveServer}
function testLiveListEmailIdentities() returns error? {
    Client sesClient = check newLiveClient();
    stream<IdentityInfo, Error?> identities = sesClient->listEmailIdentities({pageSize: 10});
    int count = 0;
    check from IdentityInfo identity in identities
        do {
            test:assertTrue(identity.identityName is string);
            count += 1;
        };
    test:assertTrue(count >= 1, "the account is expected to have at least one email identity");
    check sesClient.close();
}

@test:Config {groups: ["live"], enable: isLiveServer}
function testLiveSendEmail() returns error? {
    Client sesClient = check newLiveClient();
    SendEmailOutput result = check sesClient->sendEmail({
        fromEmailAddress: senderEmail,
        destination: {toAddresses: [recipientEmail]},
        content: {
            simple: {
                subject: {data: "Ballerina SES connector test", charset: "UTF-8"},
                body: {
                    html: {data: "<html><body><p>Sent by the Ballerina SES connector tests.</p></body></html>"},
                    text: {data: "Sent by the Ballerina SES connector tests."}
                }
            }
        }
    });
    test:assertTrue(result.messageId is string, "Amazon SES must return a message id for an accepted message");
    check sesClient.close();
}
