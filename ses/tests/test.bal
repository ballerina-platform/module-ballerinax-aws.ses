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

import ballerina/log;
import ballerina/os;
import ballerina/test;

configurable string accessKeyId = os:getEnv("ACCESS_KEY_ID");
configurable string secretAccessKey = os:getEnv("SECRET_ACCESS_KEY");
configurable string senderEmail = os:getEnv("SENDER_EMAIL");
configurable string receiverEmail = os:getEnv("RECEIVER_EMAIL");
configurable string emailIdentity = os:getEnv("EMAIL_IDENTITY");

ConnectionConfig amazonSesConfig = {
    awsCredentials: {
        accessKeyId: accessKeyId,
        secretAccessKey: secretAccessKey
    }
};

final string contactListName = "TestContactList";
final string contactName = "test.contact@gmail.com";
final string customVerificationTemplateName = "CustomVerificationTest";
final string emailTemplateName = "EmailTemplateTest";


Client amazonSesClient = check new(amazonSesConfig);

@test:Config {}
function testCreateContactList() returns error? {
    log:printInfo("Testing CreateContactList");
    ContactListCreationRequest request = {
        ContactListName: contactListName,
        Tags: [
            {
                Key: "Test Tag",
                Value: "Test Value"
            }
        ]
    };
    check amazonSesClient-> createContactList(request);
}

@test:Config {
    dependsOn: [testCreateContactList]
}
function testUpdateContactList() returns error? {
    log:printInfo("Testing UpdateContactList");
    ContactList request = {
        Description: "Updated Description",
        Topics: [
            {
               DefaultSubscriptionStatus : "OPT_OUT",
               TopicName: "Test_Topic" ,
               DisplayName : "Test Topic"
            }
        ]
    };
    check amazonSesClient-> updateContactList(contactListName, request);
}

@test:Config {
    dependsOn: [testUpdateContactList]
}
function testGetContactList() returns error? {
    log:printInfo("Testing GetContactList");
    ContactList response =  check amazonSesClient-> getContactList(contactListName);
    test:assertEquals(response?.ContactListName, contactListName, "Expected contact-list is not obtained");
}

@test:Config {
    dependsOn: [testGetContactList]
}
function testListContactLists() returns error? {
    log:printInfo("Testing ListContactLists");
    _ =  check amazonSesClient->listContactLists();
}

@test:Config {
    dependsOn: [testUpdateContactList]
}
function testCreateContact() returns error? {
    log:printInfo("Testing CreateContact");
    ContactCreationRequest request = {
        EmailAddress: contactName,
        TopicPreferences: [
            {
                SubscriptionStatus: "OPT_OUT",
                TopicName: "Test_Topic"
            }
        ]
    };
    check amazonSesClient-> createContact(contactListName, request);
}

@test:Config {
    dependsOn: [testCreateContact]
}
function testUpdateContact() returns error? {
    log:printInfo("Testing CreateContact");
    ContactUpdateRequest request = {
        TopicPreferences: [
            {
                SubscriptionStatus: "OPT_IN",
                TopicName: "Test_Topic"
            }
        ]
    };
    check amazonSesClient-> updateContact(contactListName, contactName, request);
}

@test:Config {
    dependsOn: [testUpdateContact]
}
function testGetContact() returns error? {
    log:printInfo("Testing GetContact");
    Contact response =  check amazonSesClient-> getContact(contactListName, contactName);
    test:assertEquals(response?.EmailAddress, contactName, "Expected contact is not obtained");
}

@test:Config {
    dependsOn: [testGetContact]
}
function testListContacts() returns error? {
    log:printInfo("Testing ListContacts");
    _ = check amazonSesClient-> listContacts(contactListName);
}

@test:Config {
    dependsOn: [testListContacts]
}
function testDeleteContact() returns error? {
    log:printInfo("Testing DeleteContact");
    check amazonSesClient-> deleteContact(contactListName, contactName);
}

@test:Config {}
function testCreateCustomVeriﬁcationEmailTemplate() returns error? {
    log:printInfo("Testing CreateCustomVeriﬁcationEmailTemplate");
    CustomVeriﬁcationEmailTemplate request = {
        FailureRedirectionURL: "https://www.example.com/verifyfailure",
        FromEmailAddress: senderEmail,
        SuccessRedirectionURL: "https://www.example.com/verifysuccess",
        TemplateContent: "Custom verification template Testing",
        TemplateName: customVerificationTemplateName,
        TemplateSubject: "Custom Verification Test"
    };
    check amazonSesClient->createCustomVeriﬁcationEmailTemplate(request);
}

@test:Config {
    dependsOn: [testCreateCustomVeriﬁcationEmailTemplate]
}
function testGetCustomVeriﬁcationEmailTemplate() returns error? {
    log:printInfo("Testing GetCustomVeriﬁcationEmailTemplate");
    CustomVeriﬁcationEmailTemplate response =  check amazonSesClient->getCustomVeriﬁcationEmailTemplate(customVerificationTemplateName);
    test:assertEquals(response.TemplateName, customVerificationTemplateName, "Expected template is not obtained");
}

@test:Config {
    dependsOn: [testGetCustomVeriﬁcationEmailTemplate]
}

function testUpdateCustomVeriﬁcationEmailTemplate() returns error? {
    log:printInfo("Testing UpdateCustomVeriﬁcationEmailTemplate");
    CustomVeriﬁcationEmailUpdate request = {
        FailureRedirectionURL: "https://www.example.com/verifyfailure",
        FromEmailAddress: senderEmail,
        SuccessRedirectionURL: "https://www.example.com/verifysuccess",
        TemplateContent: "This to just test Update.",
        TemplateSubject: "Custom Verification Test Update"
    };
    check amazonSesClient->updateCustomVeriﬁcationEmailTemplate(customVerificationTemplateName, request);
}

@test:Config {
    dependsOn: [testUpdateCustomVeriﬁcationEmailTemplate]
}

function testListCustomVeriﬁcationEmailTemplates() returns error? {
    log:printInfo("Testing ListCustomVeriﬁcationEmailTemplates");
    _ = check amazonSesClient->listCustomVeriﬁcationEmailTemplates();
}

@test:Config {
    dependsOn: [testListCustomVeriﬁcationEmailTemplates]
}
function testDeleteCustomVeriﬁcationEmailTemplate() returns error? {
    log:printInfo("Testing DeleteCustomVeriﬁcationEmailTemplate");
    check amazonSesClient->deleteCustomVeriﬁcationEmailTemplate(customVerificationTemplateName);
}

@test:Config {}
function testCreateEmailTemplate() returns error? {
    log:printInfo("Testing CreateEmailTemplate");
    EmailTemplate request = {
        TemplateContent: {
            Subject: "TemplateEmail",
            Text: "This is a sample email sent from AWS SES using a template"
        },
        TemplateName: emailTemplateName
    };
    check amazonSesClient->createEmailTemplate(request);
}

@test:Config {
    dependsOn: [testCreateEmailTemplate]
}
function testGetEmailTemplate() returns error? {
    log:printInfo("Testing GetEmailTemplate");
    EmailTemplate response = check amazonSesClient->getEmailTemplate(emailTemplateName);
    test:assertEquals(response.TemplateName, emailTemplateName, "Expected template is not obtained.");
}

@test:Config {
    dependsOn: [testGetEmailTemplate]
}

function testUpdateEmailTemplate() returns error? {
    log:printInfo("Testing UpdateEmailTemplate");
    EmailTemplateUpdateRequest request = {
        TemplateContent: {
            Subject: "UpdatedTemplateEmail",
            Text: "This is an updated sample email template"
        }
    };
    check amazonSesClient->updateEmailTemplate(emailTemplateName, request);
}

@test:Config {
    dependsOn: [testUpdateEmailTemplate]
}

function testListEmailTemplates() returns error? {
    log:printInfo("Testing ListEmailTemplates");
    _ = check amazonSesClient->listEmailTemplates();
}

@test:Config {}
function testCreateEmailIdentity() returns error? {
    log:printInfo("Testing CreateEmailIdentity");
    EmailIdentityCreationRequest request = {
        EmailIdentity: emailIdentity
    };
    EmailIdentity response = check amazonSesClient->createEmailIdentity(request);
    log:printInfo(response?.IdentityType.toString());
}

@test:Config {
  dependsOn: [testCreateEmailIdentity]
}
function testGetEmailIdentity() returns error? {
    log:printInfo("Testing GetEmailIdentity");
    _ = check amazonSesClient->getEmailIdentity(emailIdentity);
}

@test:Config {
  dependsOn: [testGetEmailIdentity]
}
function testListEmailIdentities() returns error? {
    log:printInfo("Testing ListEmailIdentities");
    _ = check amazonSesClient->listEmailIdentities();
}

@test:Config {
  dependsOn: [testListEmailIdentities]
}
function testDeleteEmailIdentity() returns error? {
    log:printInfo("Testing DeleteEmailIdentity");
    check amazonSesClient->deleteEmailIdentity(emailIdentity);
}

@test:Config {}
function testSendEmail() returns error? {
    log:printInfo("Testing Send Email");
    EmailRequest req ={
        Content: {
            Simple: {
                Body: {
                    Text: {
                        Charset: "UTF-8",
                        Data: "This is a testing email."
                    }
                },
                Subject: {
                    Charset: "UTF-8",
                    Data: "Testing Email Subject"
                }
            }
        },
        Destination: {
            ToAddresses: [receiverEmail]
        },
        FromEmailAddress: senderEmail
    };
    MessageSentResponse response =  check amazonSesClient->sendEmail(req);
    log:printInfo(response?.MessageId.toString());
}

@test:Config {
    dependsOn: [testCreateEmailTemplate]
}
function testSendCustomVeriﬁcationEmail() {
    log:printInfo("Testing Send CustomVeriﬁcationEmail");
    CustomVeriﬁcationEmailRequest req ={
        EmailAddress: receiverEmail,
        TemplateName: emailTemplateName
    };
    MessageSentResponse|error response =  amazonSesClient->sendCustomVeriﬁcationEmail(req);
    if response is MessageSentResponse {
        log:printInfo(response?.MessageId.toString());
    }
}

@test:Config {}
function testSendBulkEmail() {
    log:printInfo("Testing Send BulkEmail");
    BulkEmailRequest req ={
        BulkEmailEntries: [
            {
                Destination: {
                    ToAddresses: [emailIdentity, receiverEmail]
                }
            }
        ],
        DefaultContent: {
            Template: {
                TemplateName: emailTemplateName
            }
        }
    };
    MessageSentResponse|error response =  amazonSesClient->sendBulkEmail(req);
    if response is MessageSentResponse {
        log:printInfo(response?.MessageId.toString());
    }
}

@test:AfterSuite {}
function testDeleteEmailTemplate() returns error? {
    log:printInfo("Testing DeleteEmailTemplate");
    check amazonSesClient->deleteEmailTemplate(emailTemplateName);
}

@test:AfterSuite {}
function testDeleteContactList() returns error? {
    log:printInfo("Testing DeleteContactList");
    check amazonSesClient-> deleteContactList(contactListName);
}
