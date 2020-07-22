// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/test;
import ballerina/math;
import ballerina/config;

Configuration configuration = {
    accessKey: config:getAsString("ACCESS_KEY_ID"),
    secretKey: config:getAsString("SECRET_ACCESS_KEY"),
    region: config:getAsString("REGION")
};

Client sesClient = new(configuration);
string fifoQueueResourcePath = "";
string standardQueueResourcePath = "";
string receivedReceiptHandler = "";
string standardQueueReceivedReceiptHandler = "";
string templateName = genRandomTemplateName();
string emailVerificatioAddress = config:getAsString("VERIFY_ADDRESS");
string emailSendFromAddress = config:getAsString("SEND_FROM_ADDRESS");
string emailSendToAddress = config:getAsString("SEND_TO_ADDRESS");
string templatedEmailSendFromAddress = config:getAsString("TEMPLATED_SEND_FROM_ADDRESS");
string templatedEmailSendToAddress = config:getAsString("TEMPLATED_SEND_TO_ADDRESS");
string templatedEmailSendCcAddress = config:getAsString("TEMPLATED_SEND_CC_ADDRESS");

@test:Config {
    groups: ["group1"]
}
function testVerifyEmailIdentity() {
    error? response = sesClient->verifyEmailIdentity(emailVerificatioAddress);
    if (response is error) {
        test:assertFail("Error while trying to verify email address." + response.message());
    }
}

@test:Config {
    dependsOn: ["testVerifyEmailIdentity"],
    groups: ["group1"]
}
function testSendEmail() {
    Email email = {
        to: [emailSendToAddress],
        subject: "Sample AWS SES Email Subject",
        body: "Sample Email Body",
        'from: emailSendFromAddress
    };
    error? response = sesClient->sendEmail(email);
    if (response is error) {
        test:assertFail("Error while sending an email." + response.message());
    }
}

@test:Config {
    dependsOn: ["testVerifyEmailIdentity"],
    groups: ["group2"]
}
function testCreateTemplate() {
    Template template = {
        templateName:templateName,
        subjectPart: "Greetings, {{name}}!",
        textPart: "Dear {{name}},\r\nYour favorite animal is {{favoriteanimal}}.",
        htmlPart: "<h1>Hello {{name}}</h1><p>Your favorite animal is {{favoriteanimal}}.</p>"
    };
    error? response = sesClient->createTemplate(template);
    if (response is error) {
        test:assertFail("Error while trying to create a template." + response.message());
    }
}

@test:Config {
    dependsOn: ["testCreateTemplate"],
    groups: ["group2"]
}
function testSendTemplatedEmail() {
    map<string> defaultTemplateData = {name:"friend", favoriteanimal:"unknown"};
    BulkEmailDestination[] destinations = [
        {
            destination: {to:[templatedEmailSendToAddress]},
            replacementTemplateData: {name:"Donald", favoriteanimal:"duck"}
        },
        {
            destination: {cc:[templatedEmailSendCcAddress]},
            replacementTemplateData: {name:"Obama", favoriteanimal:"eagle"}
        }
    ];
    string[] replyToAddresses = [templatedEmailSendFromAddress];

    EmailDestinationStatus[]|Error? response = sesClient->sendTemplatedEmail(templatedEmailSendFromAddress, templateName, destinations, defaultTemplateData,
        replyToAddresses, templatedEmailSendFromAddress);
    if (response is Error) {
        test:assertFail("Error while trying to send a templated email." + response.message());
    }
}

@test:Config {
    dependsOn: ["testSendTemplatedEmail"],
    groups: ["group2"]
}
function testDeleteTemplate() {
    error? response = sesClient->deleteTemplate(templateName);
    if (response is error) {
        test:assertFail("Error while trying to delete the template." + response.message());
    }
}

function genRandomTemplateName() returns string {
    float randomNumFloat = math:random() * 10000000;
    anydata randomNumInt = math:round(randomNumFloat);
    return "Template" + randomNumInt.toString();
}
