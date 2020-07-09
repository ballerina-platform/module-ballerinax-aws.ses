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

import ballerina/crypto;
import ballerina/email;
import ballerina/encoding;
import ballerina/http;
import ballerina/lang.array;
import ballerina/time;

# Initializes the AWS SES client based on the provided configurations.
public type Client client object {

    private string accessKey;
    private string secretKey;
    private string region;
    private string host;
    private http:Client clientEp;

    # Initializes the AWS SES client based on the provided configurations.
    #
    # + config - The configurations for the AWS SES client
    public function init(Configuration config) {
        self.accessKey = config.accessKey;
        self.secretKey = config.secretKey;
        self.region = config.region;
        self.host = SES_SERVICE_NAME + "." + self.region + "." + AMAZON_HOST;
        http:ClientSecureSocket? clientSecureSocket = config?.secureSocketConfig;
        if (clientSecureSocket is http:ClientSecureSocket) {
            self.clientEp = new("https://" + self.host, {secureSocket: clientSecureSocket});
        } else {
            self.clientEp = new("https://" + self.host, {});
        }
    }

    # Verifies the given email address by sending a verification email to it.
    # ```ballerina
    # ses:Error? result = sesClient->verifyEmailIdentity("a@bcd.com");
    # ```
    #
    # + emailAddress - The email address to be verified
    # + return - A `ses:Error` if an error occurred while the operation
    public remote function verifyEmailIdentity(string emailAddress) returns
            Error? {
        string endpoint = "/";
        string payload;
        map<string> parameters = {};
        parameters[PAYLOAD_PARAM_ACTION] = ACTION_VERIFY_EMAIL_IDENTITY;
        parameters[PAYLOAD_PARAM_VERSION] = SES_VERSION;
        parameters[PAYLOAD_PARAM_EMAIL_ADDRESS] = emailAddress;
        http:Request|error request = self.generatePOSTRequest(endpoint,
            self.buildPayload(parameters));
        if (request is http:Request) {
            var httpResponse = self.clientEp->post(endpoint, request);
            xml|error response = handleResponse(httpResponse);
            if (response is error){
                return Error("Error while veryfying the email address", response);
            }
        } else {
            return Error("Error while generating the POST request to verify email address", request);
        }        
    }

    # Sends the given email to the specified destination for simple scenarios.
    # For more information please visit,
    # https://docs.aws.amazon.com/ses/latest/APIReference/API_SendEmail.html
    # ```ballerina
    # string|ses:Error result = sesClient->sendEmail(msg);
    # ```
    #
    # + email - Email message with type email:Email
    # + return - The unique message identifier or else a `ses:Error` if the
    #            given email can't be sent
    public remote function sendEmail(Email email) returns Error? {
        string smtpPassword = self.getSmtpPassword();
        string smtpUsername = self.accessKey;
        int smtpPort = 587;
        string smtpPortString = smtpPort.toString();
        email:SmtpConfig smtpConfig = {
            port: smtpPort,
            enableSsl: false,
            properties: {
                "mail.transport.protocol":"smtp",
                "mail.smtp.port":smtpPortString,
                "mail.smtp.starttls.enable":"true", "mail.smtp.auth":"true"
            }
        };
        string awsSmtpHost = SES_SMTP_SERVICE_NAME + "." + self.region + "." + AMAZON_HOST;
        email:SmtpClient smtpClient = new (awsSmtpHost, smtpUsername, smtpPassword, smtpConfig);
        email:Error? response = smtpClient->send(email);
        if (response is email:Error) {
            return Error("Error while sending the email ", response);
        }
    }

    # Composes an email message to multiple destinations. The message body is
    # created using an email template. For more information please visit,
    # https://docs.aws.amazon.com/ses/latest/APIReference/API_SendBulkTemplatedEmail.html
    # ```ballerina
    # string|ses:Error result = 
    #   sesClient->sendTemplatedEmail(defaultTemplateData, destinations,
    #                                     "a@bcd.com", templateJson1);
    # ```
    #
    # + defaultTemplateData - A list of replacement values to apply to the
    #                         template when replacement data is not specified in
    #                         a Destination object. These values act as a
    #                         default or fallback option when no other data is
    #                         available. The template data is a JSON object,
    #                         typically consisting of key-value pairs in which
    #                         the keys correspond to replacement tags in the
    #                         email template
    # + destinations - One or more `Destination` objects. All of the recipients
    #                  in a `Destination` will receive the same version of the
    #                  email. You can specify up to 50 `Destination` objects
    #                  within a `destinations` array
    # + 'source - The email address that is sending the email. This email
    #             address must be either individually verified with Amazon SES, 
    #             or from a domain that has been verified with Amazon SES
    # + template - The template to use when sending this email
    # + replyToAddresses - The reply-to email address(es) for the message. If
    #                      the recipient replies to the message, each reply-to
    #                      address will receive the reply
    # + returnPath - The email address that bounces and complaints will be
    #                forwarded to when feedback forwarding is enabled. If the
    #                message cannot be delivered to the recipient, then an error
    #                message will be returned from the recipient's ISP; this
    #                message will then be forwarded to the email address
    #                specified by the `returnPath` parameter. The `returnPath`
    #                parameter is never overwritten. This email address must be
    #                either individually verified with Amazon SES, or from a
    #                domain that has been verified with Amazon SES
    # + return - `EmailDestinationStatus` for each destination or else a
    #            `ses:Error` if the given templated emails can't be sent
    public remote function sendTemplatedEmail(string defaultTemplateData,
            BulkEmailDestination[] destinations, string 'source,
            string template, string[]? replyToAddresses = (),
            string? returnPath = ()) returns EmailDestinationStatus[]|Error {
        string endpoint = "/";
        string payload;
        map<string> parameters = {};
        parameters[PAYLOAD_PARAM_ACTION] = ACTION_SEND_BULK_TEMPLATED_EMAIL;
        parameters[PAYLOAD_PARAM_VERSION] = SES_VERSION;
        string|error defaultTemplateDataString = encoding:encodeUriComponent(defaultTemplateData, UTF_8);
        string defaultTemplateDataStringParam = "";
        if (defaultTemplateDataString is error) {
            return Error("Error while encoding default template data.", defaultTemplateDataString);
        } else {
            defaultTemplateDataStringParam = defaultTemplateDataString;
        }
        parameters[PAYLOAD_PARAM_DEFAULT_TEMPLATE_DATA] = defaultTemplateDataStringParam;
        error? encodeError1 = self.addBulkEmailDestinationParams(parameters, destinations);
        if (encodeError1 is error) {
            return Error("Error while encoding email destination values.", encodeError1);
        }
        parameters[PAYLOAD_PARAM_SOURCE] = 'source;
        parameters[PAYLOAD_PARAM_TEMPLATE] = template;
        if (replyToAddresses is string[]) {
            error? encodeError2 = self.addReplyToAddressParams(parameters, replyToAddresses);
            if (encodeError2 is error) {
                return Error("Error while encoding replyTo address values.", encodeError2);
            }
        }
        if (returnPath is string) {
            parameters[PAYLOAD_PARAM_RETURN_PATH] = returnPath;
        }
        http:Request|error request = self.generatePOSTRequest(endpoint,
            self.buildPayload(parameters));
        if (request is http:Request) {
            var httpResponse = self.clientEp->post(endpoint, request);
            xml|error response = handleResponse(httpResponse);
            if (response is error){
                return Error("Error while sending the templated email.", response);
            } else {
                return xmlToEmailDestinationStatuses(response);
            }
        } else {
            return Error("Error while generating the POST request to send the templated email", request);
        }
    }

    # Creates an email template. Email templates enable you to send personalized
    # email to one or more destinations in a single API operation.
    # ```ballerina
    # ses:Error? result = sesClient->createTemplate(template1);
    # ```
    #
    # + template - The content of the email, composed of a subject line, an HTML
    #              part, and a text-only part
    # + return - A `ses:Error` if an error occurred while the operation
    public remote function createTemplate(Template template) returns Error? {
        string endpoint = "/";
        string payload;
        map<string> parameters = {};
        parameters[PAYLOAD_PARAM_ACTION] = ACTION_CREATE_TEMPLATE;
        parameters[PAYLOAD_PARAM_VERSION] = SES_VERSION;
        map<json>|error templateJson = template.cloneWithType(JsonMap);
        if (templateJson is error) {
            return Error("Error while cloning a template to a JSON map ", templateJson);
        } else {
            error? encodeError = self.addTemplateParams(parameters, templateJson);
            if (encodeError is error) {
                return Error("Error while encoding template values ", encodeError);
            }
            http:Request|error request = self.generatePOSTRequest(endpoint,
                self.buildPayload(parameters));
            if (request is http:Request) {
                var httpResponse = self.clientEp->post(endpoint, request);
                xml|error response = handleResponse(httpResponse);
                if (response is error){
                    return Error("Error while creating the template.", response);
                }
            } else {
                return Error("Error while generating the POST request to create the template.", request);
            }  
        }
    }

    private function getSmtpPassword() returns string {
        string secretKey = self.secretKey;
        string region = self.region;
        string date = "11111111";
        string serviceName = "ses";
        string terminal = "aws4_request";
        string message = "SendRawEmail";
        byte[] versionInBytes = base16 `04`;
        byte[] kTerminal = self.getSignatureKey(secretKey, date, region, serviceName);
        byte[] kMessage = self.sign(kTerminal, message);
        versionInBytes.push(...kMessage);
        return array:toBase64(versionInBytes);
    }

    private function addTemplateParams(map<string> parameters, map<json> templateParams) returns error? {
        foreach var [key, value] in templateParams.entries() {
            parameters["Template" + "." + <string>key] = check encoding:encodeUriComponent(<string>value, UTF_8);
        }
    }

    private function addBulkEmailDestinationParams(map<string> parameters, BulkEmailDestination[] bulkEmailDestinations)
            returns error? {
        int bulkEmailDestinationNumber = 1;
        foreach BulkEmailDestination bulkEmailDestination in bulkEmailDestinations {
            string bulkDestNumString = bulkEmailDestinationNumber.toString();
            foreach var [key, value] in bulkEmailDestination.entries() {
                string parameterName = <string>key;
                json parameterValue = value;
                if (parameterName == TEMPLATE_PARAM_REPLACEMENT_TEMPLATE_DATA) {
                    parameters["Destinations.member." + bulkDestNumString + ".ReplacementTemplateData"] = check encoding:encodeUriComponent(
                        <string>parameterValue, UTF_8);
                } else if ((parameterName == TEMPLATE_PARAM_REPLACEMENT_TAGS) && (parameterValue is MessageTag[])) {
                    check self.addReplacementTagsParams(parameters, parameterValue, bulkDestNumString);
                } else if (parameterName == TEMPLATE_PARAM_DESTINATION) {
                    check self.addDestinationParams(parameters, parameterValue, bulkDestNumString);
                } else {
                    return Error("Invalid parameter name, " + parameterName + " is given for BulkEmailDestination.");
                }
            }
            bulkEmailDestinationNumber = bulkEmailDestinationNumber + 1;
        }
    }

    private function addReplacementTagsParams(map<string> parameters, json[] replacementTags, string bulkDestNumString) returns error? {
        int i = 1;
        foreach json tag in replacementTags {
            string tagName = <string>tag.name;
            string tagValue = <string>tag.value;
            string tagNumber = i.toString();
            parameters["Destinations.member." + bulkDestNumString + ".ReplacementTags.member." + tagNumber + ".MessageTag.Name"] =
                check encoding:encodeUriComponent(tagName, UTF_8);
            parameters["Destinations.member." + bulkDestNumString + ".ReplacementTags.member." + tagNumber + ".MessageTag.Value"] =
                check encoding:encodeUriComponent(tagValue, UTF_8);
            i = i + 1;
        }
    }

    private function addDestinationParams(map<string> parameters, json destinations, string bulkDestNumString) returns error? {
        string[]? bcc = <string[]?>(check destinations?.bcc);
        string[]? cc = <string[]?>(check destinations?.cc);
        string[]? to = <string[]?>(check destinations?.to);
        if (bcc is string[]) {
            int i = 1;
            foreach var address in bcc {
                string addressNumber = i.toString();
                parameters["Destinations.member." + bulkDestNumString + ".Destination.BccAddresses.member." + addressNumber] =
                    check encoding:encodeUriComponent(<string>address, UTF_8);
                i = i + 1;
            }
        }
        if (cc is string[]) {
            int i = 1;
            foreach var address in cc {
                string addressNumber = i.toString();
                parameters["Destinations.member." + bulkDestNumString + ".Destination.CcAddresses.member." + addressNumber] =
                    check encoding:encodeUriComponent(<string>address, UTF_8);
                i = i + 1;
            }
        }
        if (to is string[]) {
            int i = 1;
            foreach var address in to {
                string addressNumber = i.toString();
                parameters["Destinations.member." + bulkDestNumString + ".Destination.ToAddresses.member." + addressNumber] =
                    check encoding:encodeUriComponent(<string>address, UTF_8);
                i = i + 1;
            }
        }
    }

    private function addReplyToAddressParams(map<string> parameters, string[] replyToAddresses) returns error? {
        int i = 1;
        foreach var address in replyToAddresses {
            string addressNumber = i.toString();
            parameters["ReplyToAddresses.member." + addressNumber] = check encoding:encodeUriComponent(<string>address, UTF_8);
            i = i + 1;
        }
    }

    private function buildPayload(map<string> parameters) returns string {
        string payload = "";
        int parameterNumber = 1;
        foreach var [key, value] in parameters.entries() {
            if (parameterNumber > 1) {
                payload = payload + "&";
            }
            payload = payload + key + "=" + value;
            parameterNumber = parameterNumber + 1;
        }
        return payload;
    }

    private function generatePOSTRequest(string canonicalUri, string payload)
            returns http:Request|Error {
        time:Time|error time = time:toTimeZone(time:currentTime(), "GMT");
        string|error amzDate;
        string|error dateStamp;
        if (time is time:Time) {
            amzDate = time:format(time, ISO8601_BASIC_DATE_FORMAT);
            dateStamp = time:format(time, SHORT_DATE_FORMAT);
            if (amzDate is string && dateStamp is string) {
                string contentType = "application/x-www-form-urlencoded";
                string requestParameters =  payload;
                string canonicalQuerystring = "";
                string canonicalHeaders = "content-type:" + contentType + "\n" + "host:" + self.host + "\n"
                    + "x-amz-date:" + amzDate + "\n";
                string signedHeaders = "content-type;host;x-amz-date";
                string payloadHash = array:toBase16(crypto:hashSha256(requestParameters.toBytes())).toLowerAscii();
                string canonicalRequest = POST + "\n" + canonicalUri + "\n" + canonicalQuerystring + "\n"
                    + canonicalHeaders + "\n" + signedHeaders + "\n" + payloadHash;
                string algorithm = "AWS4-HMAC-SHA256";
                string credentialScope = dateStamp + "/" + self.region + "/" + SES_SERVICE_NAME + "/" + "aws4_request";
                string stringToSign = algorithm + "\n" +  amzDate + "\n" +  credentialScope + "\n"
                    +  array:toBase16(crypto:hashSha256(canonicalRequest.toBytes())).toLowerAscii();
                byte[] signingKey = self.getSignatureKey(self.secretKey, dateStamp, self.region, SES_SERVICE_NAME);
                string signature = array:toBase16(crypto:hmacSha256(stringToSign
                    .toBytes(), signingKey)).toLowerAscii();
                string authorizationHeader = algorithm + " " + "Credential=" + self.accessKey + "/"
                    + credentialScope + ", " +  "SignedHeaders=" + signedHeaders + ", " + "Signature=" + signature;

                map<string> headers = {};
                headers["Content-Type"] = contentType;
                headers["X-Amz-Date"] = amzDate;
                headers["Authorization"] = authorizationHeader;

                string msgBody = requestParameters;
                http:Request request = new;
                request.setTextPayload(msgBody);
                foreach var [k,v] in headers.entries() {
                    request.setHeader(k, v);
                }
                return request;
            } else {
                if (amzDate is error) {
                    return Error("Error while generating the date.", amzDate);
                } else if (dateStamp is error) {
                    return Error("Error while generating the timestamp.", dateStamp);
                } else {
                    return Error("Error while creating date and time.");
                }
            }
        } else {
            return Error("Error while getting the current time.");
        }
    }  

    private function sign(byte[] key, string msg) returns byte[] {
        return crypto:hmacSha256(msg.toBytes(), key);
    }

    private function getSignatureKey(string secretKey, string datestamp, string region, string serviceName)  returns byte[] {
        string awskey = (AWS4 + secretKey);
        byte[] kDate = self.sign(awskey.toBytes(), datestamp);
        byte[] kRegion = self.sign(kDate, region);
        byte[] kService = self.sign(kRegion, serviceName);
        byte[] kSigning = self.sign(kService, "aws4_request");
        return kSigning;
    }

};

# Email message to be sent
public type Email email:Email;

type JsonMap map<json>;

# An array that contains one or more Destinations, as well as the tags and
# replacement data associated with each of those Destinations.
#
# + destination - Represents the destination of the message, consisting of To:,
#                 CC:, and BCC: fields.
# + replacementTags - A list of tags, in the form of name/value pairs, to apply
#                     to an email that you send
# + replacementTemplateData - A list of replacement values to apply to the
#                             template. This parameter is a JSON object,
#                             typically consisting of key-value pairs in which
#                             the keys correspond to replacement tags in the
#                             email template
public type BulkEmailDestination record {|
    Destination destination;
    MessageTag[] replacementTags?;
    string replacementTemplateData?;
|};

# An object that contains the response from the `sendTemplatedEmail` method.
#
# + errorDescription - A description of an error that prevented a message being
#                      sent using the `sendTemplatedEmail` operation
# + messageId - The unique message identifier returned from the
#               `sendTemplatedEmail` operation
# + status - The status of a message sent using the `sendTemplatedEmail`
#            operation
public type EmailDestinationStatus record {|
    string errorDescription?;
    string messageId?;
    string status?;
|};

# Contains the name and value of a tag.
#
# + name - The name of the tag. The name must only contain ASCII letters
#          (a-z, A-Z), numbers (0-9), underscores (_), or dashes (-) and should
#          contain less than 256 characters.
# + value - The value of the tag. The value must only contain ASCII letters
#          (a-z, A-Z), numbers (0-9), underscores (_), or dashes (-) and should
#          contain less than 256 characters.
public type MessageTag record {|
    string name;
    string value;
|};

# The content of the email, composed of a subject line, an HTML part, and a
# text-only part
#
# + HtmlPart - the HTML body of the email 
# + SubjectPart - the subject line of the email
# + TemplateName - the name of the template
# + TextPart - the email body that will be visible to recipients whose email
#              clients do not display HTML
public type Template record {
    string HtmlPart?;
    string SubjectPart?;
    string TemplateName;
    string TextPart?;
};

# Configuration provided for the client
#
# + accessKey - accessKey of AWS Account 
# + secretKey - secretKey of AWS Account
# + region - region of SES server
# + secureSocketConfig - HTTP client configuration for SSL
public type Configuration record {
    string accessKey;
    string secretKey;
    string region;
    http:ClientSecureSocket secureSocketConfig?;
};

# The destination for this email, composed of To:, CC:, and BCC: fields.
#
# + bcc - The recipients to place on the BCC: line of the message
# + cc - The recipients to place on the CC: line of the message
# + to - The recipients to place on the To: line of the message
public type Destination record {|
    string[] bcc?;
    string[] cc?;
    string[] to?;
|};

# Represents the message to be sent, composed of a subject and a body.
#
# + body - The message body
# + subject - The subject of the message: A short summary of the content, which 
#             will appear in the recipient's inbox
public type Message record {|
    Body body;
    Content subject;
|};

# Represents the body of the message. You can specify text, HTML, or both. If
# you use both, then the message should display correctly in the widest variety 
# of email clients.
#
# + html - The content of the message, in HTML format. Use this for email
#          clients that can process HTML. You can include clickable links,
#          formatted text, and much more in an HTML message
# + text - The content of the message, in text format. Use this for text-based
#          email clients, or clients on high-latency networks (such as mobile
#          devices)
public type Body record {|
    Content html?;
    Content text?;
|};

# Represents textual data, plus an optional character set specification. By
# default, the text must be 7-bit ASCII, due to the constraints of the SMTP
# protocol. If the text must contain any other characters, then you must also
# specify a character set. Examples include UTF-8, ISO-8859-1, and Shift_JIS.
#
# + charset - The character set of the content
# + data - The textual data of the content
public type Content record {|
    string charset?;
    string data;
|};
