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

import ballerina/data.jsondata;
import ballerina/http;
import ballerinax/aws;
import ballerinax/aws.auth;

# The Ballerina Amazon SES connector provides the capability to send email and to manage the identities, contact
# lists, and templates an Amazon Simple Email Service account sends it with.
@display {label: "Amazon SES", iconPath: "icon.png"}
public isolated client class Client {
    private final http:Client sesClient;
    private final auth:CredentialProvider credentialProvider;
    private final aws:Region|string region;
    private final string host;

    # Initializes the connector.
    # ```ballerina
    # ses:Client ses = check new ({
    #     auth: {
    #         accessKeyId: "<AWS_ACCESS_KEY_ID>",
    #         secretAccessKey: "<AWS_SECRET_ACCESS_KEY>"
    #     },
    #     region: aws:US_EAST_1
    # });
    # ```
    #
    # + config - Configuration required to initialize the client
    # + return - An `error` on failure of initialization, or else `()`
    public isolated function init(ConnectionConfig config) returns error? {
        http:ClientConfiguration httpClientConfig = {httpVersion: config.httpVersion, http1Settings: config.http1Settings, http2Settings: config.http2Settings, timeout: config.timeout, forwarded: config.forwarded, followRedirects: config.followRedirects, poolConfig: config.poolConfig, cache: config.cache, compression: config.compression, circuitBreaker: config.circuitBreaker, retryConfig: config.retryConfig, cookieConfig: config.cookieConfig, responseLimits: config.responseLimits, secureSocket: config.secureSocket, proxy: config.proxy, socketConfig: config.socketConfig, validation: config.validation, laxDataBinding: config.laxDataBinding};
        self.region = config.region;
        aws:EndpointConfig endpointConfig = config.endpoint ?: {};
        self.host = aws:resolveEndpointHost(SERVICE_NAME, config.region, endpointConfig);
        string baseUrl = aws:resolveEndpoint(SERVICE_NAME, config.region, endpointConfig);
        self.sesClient = check new (baseUrl, httpClientConfig);
        self.credentialProvider = check new (config.auth);
    }

    # Creates a contact list.
    # ```ballerina
    # check ses->createContactList({contactListName: "Newsletter"});
    # ```
    #
    # + request - The details of the contact list to create
    # + return - An `Error` on failure, or else `()`
    @display {label: "Create Contact List"}
    remote isolated function createContactList(CreateContactListInput request) returns Error? {
        _ = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
            method: HTTP_POST,
            path: CONTACT_LISTS_PATH,
            payload: jsondata:toJson(request)
        });
    }

    # Updates the metadata of a contact list. This operation does a complete replacement of the description and the
    # topics.
    # ```ballerina
    # check ses->updateContactList("Newsletter", {description: "Weekly product news"});
    # ```
    #
    # + contactListName - The name of the contact list
    # + request - The details to replace the contact list's metadata with
    # + return - An `Error` on failure, or else `()`
    @display {label: "Update Contact List"}
    remote isolated function updateContactList(@display {label: "Contact List Name"} string contactListName,
            UpdateContactListInput request) returns Error? {
        _ = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
            method: HTTP_PUT,
            path: string `${CONTACT_LISTS_PATH}/${contactListName}`,
            payload: jsondata:toJson(request)
        });
    }

    # Returns the metadata of a contact list. It does not return any information about the contacts in the list.
    # ```ballerina
    # ses:ContactListDetails contactList = check ses->getContactList("Newsletter");
    # ```
    #
    # + contactListName - The name of the contact list
    # + return - The contact list's metadata, or an `Error` on failure
    @display {label: "Get Contact List"}
    remote isolated function getContactList(@display {label: "Contact List Name"} string contactListName)
            returns ContactListDetails|Error {
        json response = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
            method: HTTP_GET,
            path: string `${CONTACT_LISTS_PATH}/${contactListName}`
        });
        ContactListDetails|jsondata:Error result = jsondata:parseAsType(response, PARSE_OPTIONS);
        if result is jsondata:Error {
            return error ResponseHandlingError(
                    string `Error occurred while processing the GetContactList response: ${result.message()}`, result);
        }
        return result;
    }

    # Lists the contact lists available to the account, fetching each page as the previous one is consumed.
    # ```ballerina
    # stream<ses:ContactList, ses:Error?> contactLists = ses->listContactLists();
    # ```
    #
    # + request - The details of the contact lists to list
    # + return - A stream of `ContactList` values, which completes once every page has been consumed
    @display {label: "List Contact Lists"}
    remote isolated function listContactLists(ListContactListsInput request = {})
            returns stream<ContactList, Error?> {
        final int? pageSize = request?.pageSize;
        ContactListIterator iterator = new (isolated function(string? nextToken) returns Page|Error {
            json response = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
                method: HTTP_GET,
                path: CONTACT_LISTS_PATH,
                queryParams: paginationParams(nextToken, pageSize)
            });
            ListContactListsOutput|jsondata:Error page = jsondata:parseAsType(response, PARSE_OPTIONS);
            if page is jsondata:Error {
                return error ResponseHandlingError(
                        string `Error occurred while processing the ListContactLists response: ${page.message()}`,
                        page);
            }
            return {items: page.contactLists, nextToken: page?.nextToken};
        });
        return new (iterator);
    }

    # Deletes a contact list and every contact on it.
    # ```ballerina
    # check ses->deleteContactList("Newsletter");
    # ```
    #
    # + contactListName - The name of the contact list
    # + return - An `Error` on failure, or else `()`
    @display {label: "Delete Contact List"}
    remote isolated function deleteContactList(@display {label: "Contact List Name"} string contactListName)
            returns Error? {
        _ = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
            method: HTTP_DELETE,
            path: string `${CONTACT_LISTS_PATH}/${contactListName}`
        });
    }

    # Creates a contact — an end user receiving the email — and adds them to a contact list.
    # ```ballerina
    # check ses->createContact("Newsletter", {emailAddress: "reader@example.com"});
    # ```
    #
    # + contactListName - The name of the contact list to add the contact to
    # + request - The details of the contact to create
    # + return - An `Error` on failure, or else `()`
    @display {label: "Create Contact"}
    remote isolated function createContact(@display {label: "Contact List Name"} string contactListName,
            CreateContactInput request) returns Error? {
        _ = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
            method: HTTP_POST,
            path: string `${CONTACT_LISTS_PATH}/${contactListName}/${CONTACTS_SEGMENT}`,
            payload: jsondata:toJson(request)
        });
    }

    # Updates a contact's preferences for a list. It is not necessary to specify every existing topic preference,
    # only the ones that need updating.
    # ```ballerina
    # check ses->updateContact("Newsletter", "reader@example.com", {unsubscribeAll: true});
    # ```
    #
    # + contactListName - The name of the contact list the contact belongs to
    # + emailAddress - The contact's email address
    # + request - The details to update the contact with
    # + return - An `Error` on failure, or else `()`
    @display {label: "Update Contact"}
    remote isolated function updateContact(@display {label: "Contact List Name"} string contactListName,
            @display {label: "Email Address"} string emailAddress, UpdateContactInput request) returns Error? {
        _ = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
            method: HTTP_PUT,
            path: string `${CONTACT_LISTS_PATH}/${contactListName}/${CONTACTS_SEGMENT}/${emailAddress}`,
            payload: jsondata:toJson(request)
        });
    }

    # Returns a contact from a contact list.
    # ```ballerina
    # ses:ContactDetails contact = check ses->getContact("Newsletter", "reader@example.com");
    # ```
    #
    # + contactListName - The name of the contact list the contact belongs to
    # + emailAddress - The contact's email address
    # + return - The contact, or an `Error` on failure
    @display {label: "Get Contact"}
    remote isolated function getContact(@display {label: "Contact List Name"} string contactListName,
            @display {label: "Email Address"} string emailAddress) returns ContactDetails|Error {
        json response = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
            method: HTTP_GET,
            path: string `${CONTACT_LISTS_PATH}/${contactListName}/${CONTACTS_SEGMENT}/${emailAddress}`
        });
        ContactDetails|jsondata:Error result = jsondata:parseAsType(response, PARSE_OPTIONS);
        if result is jsondata:Error {
            return error ResponseHandlingError(
                    string `Error occurred while processing the GetContact response: ${result.message()}`, result);
        }
        return result;
    }

    # Lists the contacts of a contact list, fetching each page as the previous one is consumed.
    # ```ballerina
    # stream<ses:Contact, ses:Error?> contacts = ses->listContacts("Newsletter", {
    #     filter: {filteredStatus: ses:OPT_IN}
    # });
    # ```
    #
    # + contactListName - The name of the contact list
    # + request - The details of the contacts to list
    # + return - A stream of `Contact` values, which completes once every page has been consumed
    @display {label: "List Contacts"}
    remote isolated function listContacts(@display {label: "Contact List Name"} string contactListName,
            ListContactsInput request = {}) returns stream<Contact, Error?> {
        // The request is serialized here rather than inside the closure: `jsondata:toJson` reads the
        // `@jsondata:Name` annotations from the declared type, and a `readonly &` intersection loses them, which
        // would put camelCase field names on the wire.
        final readonly & map<json> basePayload = (<map<json>>jsondata:toJson(request)).cloneReadOnly();
        ContactIterator iterator = new (isolated function(string? nextToken) returns Page|Error {
            // Unlike the other list operations, `ListContacts` is a POST that carries its pagination in the body.
            map<json> payload = basePayload.clone();
            if nextToken is string {
                payload[NEXT_TOKEN_PARAM] = nextToken;
            }
            json response = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
                method: HTTP_POST,
                path: string `${CONTACT_LISTS_PATH}/${contactListName}/${CONTACTS_SEGMENT}/${LIST_SEGMENT}`,
                payload: payload
            });
            ListContactsOutput|jsondata:Error page = jsondata:parseAsType(response, PARSE_OPTIONS);
            if page is jsondata:Error {
                return error ResponseHandlingError(
                        string `Error occurred while processing the ListContacts response: ${page.message()}`, page);
            }
            return {items: page.contacts, nextToken: page?.nextToken};
        });
        return new (iterator);
    }

    # Removes a contact from a contact list.
    # ```ballerina
    # check ses->deleteContact("Newsletter", "reader@example.com");
    # ```
    #
    # + contactListName - The name of the contact list the contact belongs to
    # + emailAddress - The contact's email address
    # + return - An `Error` on failure, or else `()`
    @display {label: "Delete Contact"}
    remote isolated function deleteContact(@display {label: "Contact List Name"} string contactListName,
            @display {label: "Email Address"} string emailAddress) returns Error? {
        _ = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
            method: HTTP_DELETE,
            path: string `${CONTACT_LISTS_PATH}/${contactListName}/${CONTACTS_SEGMENT}/${emailAddress}`
        });
    }

    # Creates a custom verification email template.
    # ```ballerina
    # check ses->createCustomVerificationEmailTemplate({
    #     templateName: "SupplierVerification",
    #     fromEmailAddress: "sender@example.com",
    #     templateSubject: "Please confirm your email address",
    #     templateContent: "<html><body><p>Confirm your address.</p></body></html>",
    #     successRedirectionUrl: "https://example.com/verified",
    #     failureRedirectionUrl: "https://example.com/not-verified"
    # });
    # ```
    #
    # + request - The details of the custom verification email template to create
    # + return - An `Error` on failure, or else `()`
    @display {label: "Create Custom Verification Email Template"}
    remote isolated function createCustomVerificationEmailTemplate(
            CreateCustomVerificationEmailTemplateInput request) returns Error? {
        _ = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
            method: HTTP_POST,
            path: CUSTOM_VERIFICATION_TEMPLATES_PATH,
            payload: jsondata:toJson(request)
        });
    }

    # Updates an existing custom verification email template.
    # ```ballerina
    # check ses->updateCustomVerificationEmailTemplate("SupplierVerification", {
    #     fromEmailAddress: "sender@example.com",
    #     templateSubject: "Confirm your email address",
    #     templateContent: "<html><body><p>Confirm your address.</p></body></html>",
    #     successRedirectionUrl: "https://example.com/verified",
    #     failureRedirectionUrl: "https://example.com/not-verified"
    # });
    # ```
    #
    # + templateName - The name of the custom verification email template to update
    # + request - The details to replace the template with
    # + return - An `Error` on failure, or else `()`
    @display {label: "Update Custom Verification Email Template"}
    remote isolated function updateCustomVerificationEmailTemplate(
            @display {label: "Template Name"} string templateName,
            UpdateCustomVerificationEmailTemplateInput request) returns Error? {
        _ = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
            method: HTTP_PUT,
            path: string `${CUSTOM_VERIFICATION_TEMPLATES_PATH}/${templateName}`,
            payload: jsondata:toJson(request)
        });
    }

    # Returns the custom verification email template of the given name.
    # ```ballerina
    # ses:CustomVerificationEmailTemplateDetails template =
    #     check ses->getCustomVerificationEmailTemplate("SupplierVerification");
    # ```
    #
    # + templateName - The name of the custom verification email template to retrieve
    # + return - The custom verification email template, or an `Error` on failure
    @display {label: "Get Custom Verification Email Template"}
    remote isolated function getCustomVerificationEmailTemplate(
            @display {label: "Template Name"} string templateName)
            returns CustomVerificationEmailTemplateDetails|Error {
        json response = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
            method: HTTP_GET,
            path: string `${CUSTOM_VERIFICATION_TEMPLATES_PATH}/${templateName}`
        });
        CustomVerificationEmailTemplateDetails|jsondata:Error result = jsondata:parseAsType(response, PARSE_OPTIONS);
        if result is jsondata:Error {
            return error ResponseHandlingError(
                    string `Error occurred while processing the GetCustomVerificationEmailTemplate response: ${
                    result.message()}`, result);
        }
        return result;
    }

    # Lists the custom verification email templates of the account in the current AWS Region, fetching each page as
    # the previous one is consumed.
    # ```ballerina
    # stream<ses:CustomVerificationEmailTemplateMetadata, ses:Error?> templates =
    #     ses->listCustomVerificationEmailTemplates();
    # ```
    #
    # + request - The details of the templates to list
    # + return - A stream of `CustomVerificationEmailTemplateMetadata` values, which completes once every page has
    # been consumed
    @display {label: "List Custom Verification Email Templates"}
    remote isolated function listCustomVerificationEmailTemplates(
            ListCustomVerificationEmailTemplatesInput request = {})
            returns stream<CustomVerificationEmailTemplateMetadata, Error?> {
        final int? pageSize = request?.pageSize;
        CustomVerificationEmailTemplateIterator iterator =
            new (isolated function(string? nextToken) returns Page|Error {
                json response = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
                    method: HTTP_GET,
                    path: CUSTOM_VERIFICATION_TEMPLATES_PATH,
                    queryParams: paginationParams(nextToken, pageSize)
                });
                ListCustomVerificationEmailTemplatesOutput|jsondata:Error page = jsondata:parseAsType(response, PARSE_OPTIONS);
                if page is jsondata:Error {
                    return error ResponseHandlingError(
                            string `Error occurred while processing the ListCustomVerificationEmailTemplates response: ${
                            page.message()}`, page);
                }
                return {items: page.customVerificationEmailTemplates, nextToken: page?.nextToken};
            });
        return new (iterator);
    }

    # Deletes an existing custom verification email template.
    # ```ballerina
    # check ses->deleteCustomVerificationEmailTemplate("SupplierVerification");
    # ```
    #
    # + templateName - The name of the custom verification email template to delete
    # + return - An `Error` on failure, or else `()`
    @display {label: "Delete Custom Verification Email Template"}
    remote isolated function deleteCustomVerificationEmailTemplate(
            @display {label: "Template Name"} string templateName) returns Error? {
        _ = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
            method: HTTP_DELETE,
            path: string `${CUSTOM_VERIFICATION_TEMPLATES_PATH}/${templateName}`
        });
    }

    # Creates an email template, which lets one API call send a personalized message to each of many destinations.
    # ```ballerina
    # check ses->createEmailTemplate({
    #     templateName: "OrderShipped",
    #     templateContent: {
    #         subject: "Your order {{orderId}} has shipped",
    #         html: "<html><body><p>Hello {{name}}, your order is on its way.</p></body></html>",
    #         text: "Hello {{name}}, your order is on its way."
    #     }
    # });
    # ```
    #
    # + request - The details of the email template to create
    # + return - An `Error` on failure, or else `()`
    @display {label: "Create Email Template"}
    remote isolated function createEmailTemplate(CreateEmailTemplateInput request) returns Error? {
        _ = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
            method: HTTP_POST,
            path: TEMPLATES_PATH,
            payload: jsondata:toJson(request)
        });
    }

    # Updates an email template. This operation does a complete replacement of the template's content.
    # ```ballerina
    # check ses->updateEmailTemplate("OrderShipped", {
    #     templateContent: {subject: "Your order is on its way", text: "Hello {{name}}."}
    # });
    # ```
    #
    # + templateName - The name of the template
    # + request - The content to replace the template's with
    # + return - An `Error` on failure, or else `()`
    @display {label: "Update Email Template"}
    remote isolated function updateEmailTemplate(@display {label: "Template Name"} string templateName,
            UpdateEmailTemplateInput request) returns Error? {
        _ = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
            method: HTTP_PUT,
            path: string `${TEMPLATES_PATH}/${templateName}`,
            payload: jsondata:toJson(request)
        });
    }

    # Returns the template of the given name, including its subject line, its HTML part, and its text part.
    # ```ballerina
    # ses:EmailTemplateDetails template = check ses->getEmailTemplate("OrderShipped");
    # ```
    #
    # + templateName - The name of the template
    # + return - The email template, or an `Error` on failure
    @display {label: "Get Email Template"}
    remote isolated function getEmailTemplate(@display {label: "Template Name"} string templateName)
            returns EmailTemplateDetails|Error {
        json response = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
            method: HTTP_GET,
            path: string `${TEMPLATES_PATH}/${templateName}`
        });
        EmailTemplateDetails|jsondata:Error result = jsondata:parseAsType(response, PARSE_OPTIONS);
        if result is jsondata:Error {
            return error ResponseHandlingError(
                    string `Error occurred while processing the GetEmailTemplate response: ${result.message()}`,
                    result);
        }
        return result;
    }

    # Lists the email templates of the account in the current AWS Region, fetching each page as the previous one is
    # consumed.
    # ```ballerina
    # stream<ses:EmailTemplateMetadata, ses:Error?> templates = ses->listEmailTemplates();
    # ```
    #
    # + request - The details of the templates to list
    # + return - A stream of `EmailTemplateMetadata` values, which completes once every page has been consumed
    @display {label: "List Email Templates"}
    remote isolated function listEmailTemplates(ListEmailTemplatesInput request = {})
            returns stream<EmailTemplateMetadata, Error?> {
        final int? pageSize = request?.pageSize;
        EmailTemplateIterator iterator = new (isolated function(string? nextToken) returns Page|Error {
            json response = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
                method: HTTP_GET,
                path: TEMPLATES_PATH,
                queryParams: paginationParams(nextToken, pageSize)
            });
            ListEmailTemplatesOutput|jsondata:Error page = jsondata:parseAsType(response, PARSE_OPTIONS);
            if page is jsondata:Error {
                return error ResponseHandlingError(
                        string `Error occurred while processing the ListEmailTemplates response: ${page.message()}`,
                        page);
            }
            return {items: page.templatesMetadata, nextToken: page?.nextToken};
        });
        return new (iterator);
    }

    # Deletes an email template.
    # ```ballerina
    # check ses->deleteEmailTemplate("OrderShipped");
    # ```
    #
    # + templateName - The name of the template to delete
    # + return - An `Error` on failure, or else `()`
    @display {label: "Delete Email Template"}
    remote isolated function deleteEmailTemplate(@display {label: "Template Name"} string templateName)
            returns Error? {
        _ = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
            method: HTTP_DELETE,
            path: string `${TEMPLATES_PATH}/${templateName}`
        });
    }

    # Starts the process of verifying an email identity — an email address or a domain that email is sent from. An
    # identity has to be verified before it can be used as a sending address. Verifying a domain without supplying
    # `dkimSigningAttributes` returns the DKIM tokens to add to the domain's DNS configuration.
    # ```ballerina
    # ses:CreateEmailIdentityOutput identity = check ses->createEmailIdentity({
    #     emailIdentity: "sender@example.com"
    # });
    # ```
    #
    # + request - The details of the email identity to create
    # + return - The identity's type, verification status, and DKIM attributes, or an `Error` on failure
    @display {label: "Create Email Identity"}
    remote isolated function createEmailIdentity(CreateEmailIdentityInput request)
            returns CreateEmailIdentityOutput|Error {
        json response = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
            method: HTTP_POST,
            path: IDENTITIES_PATH,
            payload: jsondata:toJson(request)
        });
        CreateEmailIdentityOutput|jsondata:Error result = jsondata:parseAsType(response, PARSE_OPTIONS);
        if result is jsondata:Error {
            return error ResponseHandlingError(
                    string `Error occurred while processing the CreateEmailIdentity response: ${result.message()}`,
                    result);
        }
        return result;
    }

    # Returns information about an identity, including its verification status, its sending authorization policies,
    # its DKIM authentication status, and its custom MAIL FROM settings.
    # ```ballerina
    # ses:EmailIdentityDetails identity = check ses->getEmailIdentity("sender@example.com");
    # ```
    #
    # + emailIdentity - The email address or domain of the identity
    # + return - The email identity, or an `Error` on failure
    @display {label: "Get Email Identity"}
    remote isolated function getEmailIdentity(@display {label: "Email Identity"} string emailIdentity)
            returns EmailIdentityDetails|Error {
        json response = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
            method: HTTP_GET,
            path: string `${IDENTITIES_PATH}/${emailIdentity}`
        });
        EmailIdentityDetails|jsondata:Error result = jsondata:parseAsType(response, PARSE_OPTIONS);
        if result is jsondata:Error {
            return error ResponseHandlingError(
                    string `Error occurred while processing the GetEmailIdentity response: ${result.message()}`,
                    result);
        }
        return result;
    }

    # Lists the email identities associated with the AWS account, verified and unverified alike, fetching each page
    # as the previous one is consumed.
    # ```ballerina
    # stream<ses:IdentityInfo, ses:Error?> identities = ses->listEmailIdentities();
    # ```
    #
    # + request - The details of the identities to list
    # + return - A stream of `IdentityInfo` values, which completes once every page has been consumed
    @display {label: "List Email Identities"}
    remote isolated function listEmailIdentities(ListEmailIdentitiesInput request = {})
            returns stream<IdentityInfo, Error?> {
        final int? pageSize = request?.pageSize;
        EmailIdentityIterator iterator = new (isolated function(string? nextToken) returns Page|Error {
            json response = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
                method: HTTP_GET,
                path: IDENTITIES_PATH,
                queryParams: paginationParams(nextToken, pageSize)
            });
            ListEmailIdentitiesOutput|jsondata:Error page = jsondata:parseAsType(response, PARSE_OPTIONS);
            if page is jsondata:Error {
                return error ResponseHandlingError(
                        string `Error occurred while processing the ListEmailIdentities response: ${page.message()}`,
                        page);
            }
            return {items: page.emailIdentities, nextToken: page?.nextToken};
        });
        return new (iterator);
    }

    # Deletes an email identity.
    # ```ballerina
    # check ses->deleteEmailIdentity("sender@example.com");
    # ```
    #
    # + emailIdentity - The email address or domain of the identity to delete
    # + return - An `Error` on failure, or else `()`
    @display {label: "Delete Email Identity"}
    remote isolated function deleteEmailIdentity(@display {label: "Email Identity"} string emailIdentity)
            returns Error? {
        _ = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
            method: HTTP_DELETE,
            path: string `${IDENTITIES_PATH}/${emailIdentity}`
        });
    }

    # Sends an email message. The message may be `simple` — a subject and a body that Amazon SES assembles — `raw`,
    # a MIME message carrying its own headers and any attachments, or `template`, whose personalization tags Amazon
    # SES replaces with the values supplied.
    # ```ballerina
    # ses:SendEmailOutput result = check ses->sendEmail({
    #     fromEmailAddress: "sender@example.com",
    #     destination: {toAddresses: ["recipient@example.com"]},
    #     content: {
    #         simple: {
    #             subject: {data: "Your order has shipped"},
    #             body: {html: {data: "<html><body><p>It is on its way.</p></body></html>"}}
    #         }
    #     }
    # });
    # ```
    #
    # + request - The details of the message to send
    # + return - The identifier of the accepted message, or an `Error` on failure
    @display {label: "Send Email"}
    remote isolated function sendEmail(SendEmailInput request) returns SendEmailOutput|Error {
        json response = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
            method: HTTP_POST,
            path: OUTBOUND_EMAILS_PATH,
            payload: jsondata:toJson(request)
        });
        SendEmailOutput|jsondata:Error result = jsondata:parseAsType(response, PARSE_OPTIONS);
        if result is jsondata:Error {
            return error ResponseHandlingError(
                    string `Error occurred while processing the SendEmail response: ${result.message()}`, result);
        }
        return result;
    }

    # Adds an email address to the account's identities and sends it a custom verification email. A custom
    # verification email template has to exist before this operation can be used.
    # ```ballerina
    # ses:SendEmailOutput result = check ses->sendCustomVerificationEmail({
    #     emailAddress: "supplier@example.com",
    #     templateName: "SupplierVerification"
    # });
    # ```
    #
    # + request - The details of the verification email to send
    # + return - The identifier of the accepted message, or an `Error` on failure
    @display {label: "Send Custom Verification Email"}
    remote isolated function sendCustomVerificationEmail(SendCustomVerificationEmailInput request)
            returns SendEmailOutput|Error {
        json response = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
            method: HTTP_POST,
            path: OUTBOUND_CUSTOM_VERIFICATION_EMAILS_PATH,
            payload: jsondata:toJson(request)
        });
        SendEmailOutput|jsondata:Error result = jsondata:parseAsType(response, PARSE_OPTIONS);
        if result is jsondata:Error {
            return error ResponseHandlingError(
                    string `Error occurred while processing the SendCustomVerificationEmail response: ${
                    result.message()}`, result);
        }
        return result;
    }

    # Composes a templated email message to many destinations. Each entry carries its own recipients and its own
    # replacement values; the result carries one outcome per entry, in the order the entries were given.
    # ```ballerina
    # ses:SendBulkEmailOutput result = check ses->sendBulkEmail({
    #     fromEmailAddress: "sender@example.com",
    #     defaultContent: {template: {templateName: "OrderShipped", templateData: "{\"name\":\"there\"}"}},
    #     bulkEmailEntries: [{destination: {toAddresses: ["recipient@example.com"]}}]
    # });
    # ```
    #
    # + request - The details of the messages to send
    # + return - One result per intended recipient, or an `Error` on failure
    @display {label: "Send Bulk Email"}
    remote isolated function sendBulkEmail(SendBulkEmailInput request) returns SendBulkEmailOutput|Error {
        json response = check sendRequest(self.sesClient, self.credentialProvider, self.host, self.region, {
            method: HTTP_POST,
            path: OUTBOUND_BULK_EMAILS_PATH,
            payload: jsondata:toJson(request)
        });
        SendBulkEmailOutput|jsondata:Error result = jsondata:parseAsType(response, PARSE_OPTIONS);
        if result is jsondata:Error {
            return error ResponseHandlingError(
                    string `Error occurred while processing the SendBulkEmail response: ${result.message()}`, result);
        }
        return result;
    }

    # Releases the resources held by the client: the credential provider's background refresh threads, and any HTTP
    # connections it opened to resolve credentials through STS or SSO. This is a normal method rather than a remote
    # method, since closing the client sends no request to Amazon SES.
    # ```ballerina
    # check ses.close();
    # ```
    #
    # + return - An `Error` on failure, or else `()`
    public isolated function close() returns Error? {
        auth:Error? result = self.credentialProvider.close();
        if result is auth:Error {
            return error Error(string `Error occurred while closing the credential provider: ${result.message()}`,
                    result);
        }
    }
}
