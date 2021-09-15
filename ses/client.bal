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

import ballerina/http;

# The Ballerina AWS SES connector provides the capability to access AWS Simple Email Service related operations.
# This connector lets you to to send email messages to your customers.
#
# + awsSesClient - Connector HTTP endpoint
# + accessKey - AWS SES access key ID
# + secretKey - AWS SES secret access key
# + securityToken - AWS SES Security token
# + region - AWS SES Region
# + host - AWS SES host name
@display {label: "Amazon SES Client", iconPath: "resources/aws.ses.svg"}
public isolated client class Client {

    private final http:Client awsSesClient;
    private final string accessKey;
    private final string secretKey;
    private final string? securityToken;
    private final string region;
    private final string host;
    
    # Initializes the connector. During initialization you have to pass access key id and secret access key
    # Create an AWS account and obtain tokens following [this guide]
    # (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html).
    #
    # + amazonSesconfiguration - The configurations to be used when initializing the client
    # + httpConfig - HTTP Configuration
    # + return - `http:Error` in case of failure to initialize or `null` if successfully initialized
    public isolated function init(ConnectionConfig amazonSesconfiguration, http:ClientConfiguration httpConfig = {}) 
                                  returns error? {
        self.accessKey = amazonSesconfiguration.awsCredentials.accessKeyId;
        self.secretKey = amazonSesconfiguration.awsCredentials.secretAccessKey;
        self.securityToken = amazonSesconfiguration.awsCredentials?.securityToken;
        self.region = amazonSesconfiguration.region;
        self.host = AWS_SERVICE + DOT + self.region + DOT+ AWS_HOST;
        string endpoint = HTTPS + self.host;
        self.awsSesClient = check new (endpoint, httpConfig);
    }

    # Creates a contact list.
    #
    # + contactListCreationRequest - The request payload to create contact list
    # + return - An error on failure or else `()`
    @display {label: "Create Contact List"}
    remote isolated function createContactList(@display {label: "Contact List To Create"}
                                               ContactListCreationRequest contactListCreationRequest)
                                               returns error? {
        string requestUri = URI + CONTACT_LISTS;
        json payload = check contactListCreationRequest.cloneWithType(json);
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey, self.secretKey,
                                                                         self.region, POST, requestUri, payload); 
        http:Response httpResponse = check self.awsSesClient->post(requestUri, payload, signedRequestHeaders);                                                                   
        check handleHttpResponse(httpResponse);
    }

    # Updates contact list metadata. This operation does a complete replacement.
    #
    # + contactListName - The name of the contact list
    # + updateContactListRequest - The request payload to update the contact list
    # + return - An error on failure or else `()`
    @display {label: "Update Contact List"}
    remote isolated function updateContactList(@display {label: "Contact List Name"} string contactListName,
                                               @display {label: "Contact List To Update"}
                                               ContactList updateContactListRequest) returns error? {
        string requestUri = URI + CONTACT_LISTS + SLASH + contactListName;
        json payload = check updateContactListRequest.cloneWithType(json);
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey, self.secretKey,
                                                                         self.region, PUT, requestUri, payload);
        http:Response httpResponse = check self.awsSesClient-> put(requestUri, payload, signedRequestHeaders);
        check handleHttpResponse(httpResponse);
    }

    # Returns contact list metadata. It does not return any information about the contacts present in the list.
    #
    # + contactListName - The name of the contact list
    # + return - An aws.ses:ContactList record on success else an error
    @display {label: "Get Contact List"}
    remote isolated function getContactList(@display {label: "Contact List Name"} string contactListName) 
                                            returns @display {label: "Contact List"} ContactList|error {
        string requestUri = URI + CONTACT_LISTS + SLASH + contactListName;
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey, self.secretKey,
                                                                         self.region, GET, requestUri, EMPTY_STRING);
        ContactList response = check self.awsSesClient-> get(requestUri, signedRequestHeaders);
        return response;
    }

    # Lists all of the contact lists available.
    # + return - An aws.ses:ContactLists record on success else an error 
    @display {label: "List Contact Lists"}
    remote isolated function listContactLists() returns @display {label: "All Contact Lists"} ContactLists|error{
        string requestUri = URI + CONTACT_LISTS;
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey, self.secretKey,
                                                                         self.region, GET,requestUri,EMPTY_STRING);
        ContactLists response = check self.awsSesClient->get(requestUri, signedRequestHeaders);
        return response;
    }

    # Deletes a contact list and all of the contacts on that list.
    #
    # + contactListName - The name of the contact list
    # + return - An error on failure or else `()`
    @display {label: "Delete Contact List"}
    remote isolated function deleteContactList(@display {label: "Contact List Name"} string contactListName)
                                               returns error? {
        string requestUri = URI + CONTACT_LISTS + SLASH + contactListName;
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey, self.secretKey,
                                                                         self.region, DELETE, requestUri, EMPTY_STRING);
        http:Response httpResponse = check self.awsSesClient-> delete(requestUri, headers= signedRequestHeaders);
        check handleHttpResponse(httpResponse);      
    }

    # Creates a contact, which is an end-user who is receiving the email, and adds them to a contact list.
    #
    # + contactListName - The name of the contact list
    # + contactCreationRequest - The request payload to create contact
    # + return - An error on failure or else `()`
    @display {label: "Create Contact"}
    remote isolated function createContact(@display {label: "Contact List Name"} string contactListName,
                                           @display {label: "Request To Create Contact"}
                                           ContactCreationRequest contactCreationRequest) returns error? {
        string requestUri = URI + CONTACT_LISTS + SLASH + contactListName + SLASH + CONTACTS;
        json payload = check contactCreationRequest.cloneWithType(json);
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey, self.secretKey,
                                                                         self.region, POST, requestUri, payload);    
        http:Response httpResponse = check self.awsSesClient->post(requestUri, payload, signedRequestHeaders);                                                                   
        check handleHttpResponse(httpResponse);
    }

    # Updates a contact's preferences for a list. It is not necessary to specify all existing topic preferences in
    # the TopicPreferences object, just the ones that need updating.
    #
    # + contactListName - The name of the contact list
    # + emailAddress - The contact's email addres
    # + contactUpdateRequest - The request payload to update the contact
    # + return - An error on failure or else `()`
    @display {label: "Update Contact"}
    remote isolated function updateContact(@display {label: "Contact List Name"} string contactListName,
                                           @display {label: "Email Address"} string emailAddress, 
                                           @display {label: "Request To Update Contact"}
                                           ContactUpdateRequest contactUpdateRequest) returns error? {
        string requestUri = URI + CONTACT_LISTS + SLASH + contactListName + SLASH + CONTACTS + SLASH + emailAddress;
        json payload = check contactUpdateRequest.cloneWithType(json);
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey, self.secretKey,
                                                                         self.region, PUT, requestUri, payload);    
        http:Response httpResponse = check self.awsSesClient->put(requestUri, payload, signedRequestHeaders);                                                                   
        check handleHttpResponse(httpResponse);
    }

    # Returns a contact from a contact list.
    #
    # + contactListName - The name of the contact list
    # + emailAddress - The contact's email addres
    # + return - An aws.ses:Contact record on success else an error
    @display {label: "Get Contact"}
    remote isolated function getContact(@display {label: "Contact List Name"} string contactListName,
                                        @display {label: "Email Address"} string emailAddress)
                                        returns @display {label: "Contact"} Contact| error {
        string requestUri = URI + CONTACT_LISTS + SLASH + contactListName + SLASH + CONTACTS + SLASH + emailAddress;
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey, self.secretKey,
                                                                         self.region, GET, requestUri, EMPTY_STRING);
        Contact response = check self.awsSesClient->get(requestUri, signedRequestHeaders);
        return response;
    }

    # Lists the contacts present in a speciﬁc contact list.
    #
    # + contactListName - The name of the contact list
    # + return - An aws.ses:Contacts record on success else an error
    @display {label: "List Contacts"}
    remote isolated function listContacts(@display {label: "Contact List Name"} string contactListName)
                                          returns @display {label: "All Contacts"} Contacts| error {
        string requestUri = URI + CONTACT_LISTS + SLASH + contactListName + SLASH + CONTACTS;
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey, self.secretKey,
                                                                      self.region, GET, requestUri,
                                                                      EMPTY_STRING);
        Contacts response = check self.awsSesClient->get(requestUri, signedRequestHeaders);
        return response;
    }

    # Removes a contact from a contact list.
    #
    # + contactListName - The name of the contact list
    # + emailAddress - The contact's email addres
    # + return - An error on failure or else `()`
    @display {label: "Delete Contact"}
    remote isolated function deleteContact(@display {label: "Contact List Name"} string contactListName,
                                           @display {label: "Email Address"} string emailAddress)
                                           returns error? {
        string requestUri = URI + CONTACT_LISTS + SLASH + contactListName + SLASH + CONTACTS + SLASH + emailAddress;
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey, self.secretKey,
                                                                         self.region, DELETE, requestUri, EMPTY_STRING);
        http:Response httpResponse = check self.awsSesClient-> delete(requestUri, headers= signedRequestHeaders);
        check handleHttpResponse(httpResponse);      
    }


    # Creates a new custom veriﬁcation email template.
    #
    # + emailTemplate - The request payload to create custom verification email template
    # + return - An error on failure or else `()`
    @display {label: "Create Custom Veriﬁcation Email Template"}
    remote isolated function createCustomVeriﬁcationEmailTemplate(@display {label: "Custom Veriﬁcation Email Template"}
                                                                  CustomVeriﬁcationEmailTemplate emailTemplate)
                                                                  returns error? {
        string requestUri = URI + CUSTOM_VERIFICATION_EMAIL_TEMPLATES;
        json payload = check emailTemplate.cloneWithType(json);
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey, self.secretKey,
                                                                         self.region, POST, requestUri, payload);
        http:Response httpResponse = check self.awsSesClient->post(requestUri, payload, signedRequestHeaders);
        check handleHttpResponse(httpResponse);
    }

    # Updates an existing custom veriﬁcation email template.
    #
    # + templateName - The name of the custom veriﬁcation email template that you want to update
    # + emailTemplateUpdateRequest - The request payload to update custom verification email template
    # + return - An error on failure or else `()`
    @display {label: "Update Custom Veriﬁcation Email Template"}
    remote isolated function updateCustomVeriﬁcationEmailTemplate(@display {label: "Template Name"}                                                                  
                             string templateName, @display {label: "Custom Veriﬁcation Email Template"}
                             CustomVeriﬁcationEmailUpdate emailTemplateUpdateRequest) returns error? {
        string requestUri = URI + CUSTOM_VERIFICATION_EMAIL_TEMPLATES + SLASH + templateName;
        json payload = check emailTemplateUpdateRequest.cloneWithType(json);
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey, self.secretKey,
                                                                         self.region, PUT, requestUri, payload);
        http:Response httpResponse = check self.awsSesClient->put(requestUri, payload, signedRequestHeaders);
        check handleHttpResponse(httpResponse);
    }

    # Returns the custom email veriﬁcation template for the template name you specify.
    #
    # + templateName - The name of the custom veriﬁcation email template that you want to retrieve
    # + return - An aws.ses:CustomVeriﬁcationEmailTemplate record on success else an error
    @display {label: "Get Custom Veriﬁcation Email Template"}
    remote isolated function getCustomVeriﬁcationEmailTemplate(@display {label: "Template Name"} string templateName) 
                             returns @display {label: "Custom Veriﬁcation Email Template"} 
                             CustomVeriﬁcationEmailTemplate|error {
        string requestUri = URI + CUSTOM_VERIFICATION_EMAIL_TEMPLATES + SLASH + templateName;
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey,
                                                                       self.secretKey, self.region, GET,
                                                                       requestUri, EMPTY_STRING);
        CustomVeriﬁcationEmailTemplate response = check self.awsSesClient->get(requestUri, signedRequestHeaders);
        return response;    
    }

    # Lists the existing custom veriﬁcation email templates for your account in the current AWS Region.
    # + return - An aws.ses:CustomVerificationTempListPage record on success else an error
    @display {label: "List Custom Veriﬁcation Email Templates"}
    remote isolated function listCustomVeriﬁcationEmailTemplates()
                                                    returns @display {label: "All Custom Veriﬁcation Email Templates"}
                                                    CustomVerificationTempListPage|error{
        string requestUri = URI + CUSTOM_VERIFICATION_EMAIL_TEMPLATES;

        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey,
                                                                       self.secretKey, self.region, GET,
                                                                       requestUri, EMPTY_STRING);
        CustomVerificationTempListPage response = check self.awsSesClient->get(requestUri, signedRequestHeaders);
        return response;
    }

    # Deletes an existing custom veriﬁcation email template.
    #
    # + templateName - The name of the custom veriﬁcation email template that you want to delete
    # + return - An error on failure or else `()`
    @display {label: "Delete Custom Veriﬁcation Email Template"}
    remote isolated function deleteCustomVeriﬁcationEmailTemplate(@display {label: "Template Name"} string templateName)
                                                                  returns error? {
        string requestUri = URI + CUSTOM_VERIFICATION_EMAIL_TEMPLATES + SLASH + templateName;

        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey,
                                                                       self.secretKey, self.region, DELETE,
                                                                       requestUri, EMPTY_STRING);

        http:Response httpResponse = check self.awsSesClient->delete(requestUri, headers=signedRequestHeaders);
        check handleHttpResponse(httpResponse);
    }


    # Creates an email template. Email templates enable you to send personalized email to one or more destinations in a
    # single API operation.
    #
    # + emailTemplateCreationRequest - The request payload to create email template
    # + return - An error on failure or else `()`
    @display {label: "Create Email Template"}
    remote isolated function createEmailTemplate(@display {label: "Email Template"}
                                                 EmailTemplate emailTemplateCreationRequest) returns error?{
        string requestUri = URI + TEMPLATES;
        json payload = check emailTemplateCreationRequest.cloneWithType(json);
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey, self.secretKey, 
                                                                      self.region, POST, requestUri, payload);
        http:Response httpResponse = check self.awsSesClient->post(requestUri, payload, signedRequestHeaders);
        check handleHttpResponse(httpResponse);
    }

    # Updates an email template. Email templates enable you to send personalized email to one or more destinations in a
    # single API operation.
    #
    # + templateName - The name of the template
    # + emailTemplateUpdateRequest - The request payload to update email template
    # + return - An error on failure or else `()`
    @display {label: "Update Email Template"}
    remote isolated function updateEmailTemplate(@display {label: "Template Name"} string templateName,
                                                 @display {label: "Email Template Update Request"}
                                                 EmailTemplateUpdateRequest emailTemplateUpdateRequest) returns error?{
        string requestUri = URI + TEMPLATES + SLASH + templateName;
        json payload = check emailTemplateUpdateRequest.cloneWithType(json);
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey, self.secretKey,
                                                                         self.region, PUT, requestUri, payload);
        http:Response httpResponse = check self.awsSesClient->put(requestUri, payload, signedRequestHeaders);
        check handleHttpResponse(httpResponse);
    }

    # Displays the template object (which includes the subject line, HTML part and text part) for the template you
    # specify.
    #
    # + templateName - The name of the template
    # + return - An aws.ses:EmailTemplate record on success else an error
    @display {label: "Get Email Template"}
    remote isolated function getEmailTemplate(@display {label: "Template Name"} string templateName)
                                              returns @display {label: "Email Template"} EmailTemplate|error {
        string requestUri = URI + TEMPLATES + SLASH + templateName;
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey,
                                                                       self.secretKey, self.region, GET,
                                                                       requestUri, EMPTY_STRING);
        EmailTemplate response = check self.awsSesClient->get(requestUri, signedRequestHeaders);
        return response;
    }

    # Lists the email templates present in your Amazon SES account in the current AWS Region.
    # + return - An aws.ses:EmailTemplateListPage record on success else an error
    @display {label: "List Email Templates"}
    remote isolated function listEmailTemplates() returns @display {label: "All Email Templates"} 
                                                EmailTemplateListPage|error{
        string requestUri = URI + TEMPLATES;
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey,
                                                                       self.secretKey, self.region, GET,
                                                                       requestUri, EMPTY_STRING);
        EmailTemplateListPage response = check self.awsSesClient->get(requestUri, signedRequestHeaders);
        return response;  
    }

    # Deletes an email template.
    #
    # + templateName - The name of the template to be deleted
    # + return - An error on failure or else `()`
    @display {label: "Delete Email Template"}
    remote isolated function deleteEmailTemplate(@display {label: "Template Name"} string templateName) returns error?{
        string requestUri = URI + TEMPLATES + SLASH + templateName;
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey,
                                                                       self.secretKey, self.region, DELETE,
                                                                       requestUri, EMPTY_STRING);
        http:Response httpResponse = check self.awsSesClient->delete(requestUri, headers=signedRequestHeaders);
        check handleHttpResponse(httpResponse);
    }

    # Starts the process of verifying an email identity. An identity is an email address or domain that you use when
    # you send email. Before you can use an identity to send email, you ﬁrst have to verify it.
    #
    # + emailIdentityCreationRequest - The request payload to create email identity
    # + return - An aws.ses:EmailIdentity on success else an error
    @display {label: "Create Email Identity"}
    remote isolated function createEmailIdentity(@display {label: "Email Identity Creation Request"}
                                                 EmailIdentityCreationRequest emailIdentityCreationRequest) 
                                                 returns @display {label: "Email Identity Creation Response"}
                                                 EmailIdentity|error{
        string requestUri = URI + IDENTITIES;
        json payload = check emailIdentityCreationRequest.cloneWithType(json);
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey, self.secretKey, 
                                                                      self.region, POST, requestUri, payload);
        EmailIdentity response = check self.awsSesClient->post(requestUri, payload, signedRequestHeaders);
        return response;
    }

    # Provides information about a speciﬁc identity, including the identity's veriﬁcation status, sending authorization
    # policies, its DKIM authentication status, and its custom Mail-From settings.
    #
    # + emailIdentity - The email identity
    # + return - An aws.ses:EmailIdentityInfo record on success else an error
    @display {label: "Get Email Identity"}
    remote isolated function getEmailIdentity(@display {label: "Email Identity"} string emailIdentity) returns 
                                              @display {label: "Email Identity Information"} EmailIdentityInfo| error {
        string requestUri = URI + IDENTITIES + SLASH + emailIdentity;
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey,
                                                                       self.secretKey, self.region, GET,
                                                                       requestUri, EMPTY_STRING);
        EmailIdentityInfo response = check self.awsSesClient->get(requestUri, signedRequestHeaders);
        return response;        
    }

    # Returns a list of all of the email identities that are associated with your AWS account. An identity can be
    # either an email address or a domain. This operation returns identities that are veriﬁed as well as those that
    # aren't. This operation returns identities that are associated with Amazon SES and Amazon Pinpoint.
    # + return - An aws.ses:EmailIdentitiesListPage record on success else an error
    @display {label: "List Email Identities"}
    remote isolated function listEmailIdentities() returns @display {label: "All Email Identitities"}
                                                 EmailIdentitiesListPage|error{
        string requestUri = URI + IDENTITIES;

        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey,
                                                                       self.secretKey, self.region, GET,
                                                                       requestUri, EMPTY_STRING);

        EmailIdentitiesListPage response = check self.awsSesClient->get(requestUri, signedRequestHeaders);
        return response;  
    }

    # Deletes an email identity. An identity can be either an email address or a domain name.
    #
    # + emailIdentity - The identity (that is, the email address or domain) to delete
    # + return - An error on failure or else `()`
    @display {label: "Delete Email Identity"}
    remote isolated function deleteEmailIdentity(@display {label: "Email Identity"} string emailIdentity)
                                                returns error? {
        string requestUri = URI + IDENTITIES + SLASH + emailIdentity;
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey,
                                                                       self.secretKey, self.region, DELETE,
                                                                       requestUri, EMPTY_STRING);
        http:Response httpResponse = check self.awsSesClient->delete(requestUri, headers=signedRequestHeaders);
        check handleHttpResponse(httpResponse);
    }

    # Sends an email message. You can use the Amazon SES API v2 to send the following types of messages:
    # • Simple – A standard email message. When you create this type of message, you specify the sender, the recipient,
    #   and the message body, and Amazon SES assembles the message for you.
    # • Raw – A raw, MIME-formatted email message. When you send this type of email, you have to specify all of the
    #   message headers, as well as the message body. You can use this message type to send messages that contain
    #   attachments. The message that you specify has to be a valid MIME message.
    # • Templated – A message that contains personalization tags. When you send this type of email, Amazon SES API v2 
    #   automatically replaces the tags with values that you specify.
    #
    # + requestPayload - The request payload to send email
    # + return - An aws.ses:MessageSentResponse record on success else an error
    @display {label: "Send Email"}
    remote isolated function sendEmail(@display {label: "Request Payload To Send Email"} EmailRequest requestPayload)
                                       returns @display {label: "Message Sent Response"} MessageSentResponse| error {
        string requestUri = URI + "outbound-emails";
        json payload = check requestPayload.cloneWithType(json);
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey, self.secretKey,
                                                                         self.region, POST, requestUri, payload);                                                       
        MessageSentResponse response = check self.awsSesClient->post(requestUri,payload, signedRequestHeaders);
        return response;
    }

    # Adds an email address to the list of identities for your Amazon SES account in the current AWS Region and
    # attempts to verify it. As a result of executing this operation, a customized veriﬁcation email is sent to the
    # speciﬁed address. To use this operation, you must ﬁrst create a custom veriﬁcation email template.
    #
    # + requestPayload - The request payload to send custom verification email
    # + return - An aws.ses:MessageSentResponse record on success else an error
    @display {label: "Send Custom Veriﬁcation Email"}
    remote isolated function sendCustomVeriﬁcationEmail(@display {label: "Request Payload To Send Email"} 
                                                        CustomVeriﬁcationEmailRequest requestPayload)
                                                        returns @display {label: "Message Sent Response"}
                                                        MessageSentResponse| error {
        string requestUri = URI + "outbound-custom-verification-emails";
        json payload = check requestPayload.cloneWithType(json);
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey, self.secretKey,
                                                                      self.region, POST, requestUri, payload);    
        MessageSentResponse response = check self.awsSesClient->post(requestUri, payload, signedRequestHeaders);
        return response;
    }

    # Composes an email message to multiple destinations.
    #
    # + requestPayload - The request payload to send bulk email
    # + return - An aws.ses:BulkEmailResponse record on success else an error
    @display {label: "Send Bulk Email"}
    remote isolated function sendBulkEmail(@display {label: "Request Payload To Send Bulk Email"}
                                           BulkEmailRequest requestPayload)
                                           returns @display {label: "Message Sent Response"} BulkEmailResponse| error {
        string requestUri = URI + "outbound-bulk-emails";
        json payload = check requestPayload.cloneWithType(json);
        map<string> signedRequestHeaders = check getSignedRequestHeaders(self.host, self.accessKey, self.secretKey,
                                                                      self.region, POST, requestUri, payload);    
        BulkEmailResponse response = check self.awsSesClient->post(requestUri, payload, signedRequestHeaders);
        return response;
    }
    
}
