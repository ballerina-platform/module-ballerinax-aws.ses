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
import ballerina/log;
import ballerina/math;
import ballerina/system;
import ballerina/config;

Configuration configuration = {
    accessKey: getConfigValue("ACCESS_KEY_ID"),
    secretKey: getConfigValue("SECRET_ACCESS_KEY"),
    region: getConfigValue("REGION")
};

Client sesClient = new(configuration);
string fifoQueueResourcePath = "";
string standardQueueResourcePath = "";
string receivedReceiptHandler = "";
string standardQueueReceivedReceiptHandler = "";
string templateName = genRandomTemplateName();
string emailVerificatioAddress = getConfigValue("VERIFY_ADDRESS");
string emailSendFromAddress = getConfigValue("SEND_FROM_ADDRESS");
string emailSendToAddress = getConfigValue("SEND_TO_ADDRESS");
string templatedEmailSendFromAddress = getConfigValue("TEMPLATED_SEND_FROM_ADDRESS");
string templatedEmailSendToAddress = getConfigValue("TEMPLATED_SEND_TO_ADDRESS");
string templatedEmailSendCcAddress = getConfigValue("TEMPLATED_SEND_CC_ADDRESS");

@test:Config {
    groups: ["group1"]
}
function testVerifyEmailIdentity() {
    error? response = sesClient->verifyEmailIdentity(emailVerificatioAddress);
    if (response is error) {
        log:printError("Error while trying to verify email address." + response.message());
        test:assertTrue(false);
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
        log:printError("Error while sending an email." + response.message());
        test:assertTrue(false);
    }
}

@test:Config {
    dependsOn: ["testVerifyEmailIdentity"],
    groups: ["group2"]
}
function testCreateTemplate() {
    Template template = {
        TemplateName:templateName,
        SubjectPart: "Greetings, {{name}}!",
        TextPart: "Dear {{name}},\r\nYour favorite animal is {{favoriteanimal}}.",
        HtmlPart: "<h1>Hello {{name}}</h1><p>Your favorite animal is {{favoriteanimal}}.</p>"
    };
    error? response = sesClient->createTemplate(template);
    if (response is error) {
        log:printError("Error while trying to create a template." + response.message());
        test:assertTrue(false);
    }
}

@test:Config {
    dependsOn: ["testCreateTemplate"],
    groups: ["group2"]
}
function testSendTemplatedEmail() {
    string defaultTemplateData = "{ \"name\":\"friend\", \"favoriteanimal\":\"unknown\" }";
    BulkEmailDestination[] destinations = [
        {
            destination: {to:[templatedEmailSendToAddress]},
            replacementTemplateData: "{ \"name\":\"Donald\", \"favoriteanimal\":\"duck\" }"
        },
        {
            destination: {cc:[templatedEmailSendCcAddress]},
            replacementTemplateData: "{ \"name\":\"Obama\", \"favoriteanimal\":\"eagle\" }"
        }
    ];
    string[] replyToAddresses = [templatedEmailSendFromAddress];

    EmailDestinationStatus[]|Error? response = sesClient->sendTemplatedEmail(defaultTemplateData, destinations,
        templatedEmailSendFromAddress, templateName, replyToAddresses, templatedEmailSendFromAddress);
    if (response is Error) {
        log:printError("Error while trying to send a templated email." + response.message());
        test:assertTrue(false);
    }
}

function genRandomTemplateName() returns string {
    float randomNumFloat = math:random()*10000000;
    anydata randomNumInt = math:round(randomNumFloat);
    return "Template" + randomNumInt.toString();
}

function getConfigValue(string key) returns string {
    return (system:getEnv(key) != "") ? system:getEnv(key) : config:getAsString(key);
}
