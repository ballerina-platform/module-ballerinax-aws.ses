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
import ballerina/http;
import ballerinax/aws;
import ballerinax/aws.auth;

# Represents the configurations required to initialize the Amazon SES client.
@display {label: "Connection Config"}
public type ConnectionConfig record {|
    # Authentication configuration: any standard credential source supported by
    # AWS — static credentials, an AWS profile, STS assume-role,
    # web identity (OIDC), IAM Identity Center (SSO), an external credential
    # process, or the default credential provider chain
    auth:AuthConfig auth;
    # AWS region: an `aws:Region` enum member or a plain region
    # string (e.g., `"us-east-1"`) for regions not yet in the enum
    aws:Region|string region;
    # Optional endpoint options: FIPS/dualstack variants, or a custom
    # endpoint override (e.g. LocalStack, VPC interface endpoints)
    aws:EndpointConfig endpoint?;
    # The HTTP version understood by the client
    http:HttpVersion httpVersion = http:HTTP_2_0;
    # Configurations related to HTTP/1.x protocol
    http:ClientHttp1Settings http1Settings = {};
    # Configurations related to HTTP/2 protocol
    http:ClientHttp2Settings http2Settings = {};
    # The maximum time to wait (in seconds) for a response before closing the connection
    decimal timeout = 30;
    # The choice of setting `forwarded`/`x-forwarded` header
    string forwarded = "disable";
    # Configurations associated with Redirection
    http:FollowRedirects followRedirects?;
    # Configurations associated with request pooling
    http:PoolConfiguration poolConfig?;
    # HTTP caching related configurations
    http:CacheConfig cache = {};
    # Specifies the way of handling compression (`accept-encoding`) header
    http:Compression compression = http:COMPRESSION_AUTO;
    # Configurations associated with the behaviour of the Circuit Breaker
    http:CircuitBreakerConfig circuitBreaker?;
    # Configurations associated with retrying
    http:RetryConfig retryConfig?;
    # Configurations associated with cookies
    http:CookieConfig cookieConfig?;
    # Configurations associated with inbound response size limits
    http:ResponseLimitConfigs responseLimits = {};
    # SSL/TLS-related options
    http:ClientSecureSocket secureSocket?;
    # Proxy server related options
    http:ProxyConfig proxy?;
    # Provides settings related to client socket configuration
    http:ClientSocketConfig socketConfig = {};
    # Enables the inbound payload validation functionality which provided by the constraint package. Enabled by default
    boolean validation = true;
    # Enables relaxed data binding on the client side. When enabled, `nil` values are treated as optional,
    # and absent fields are handled as `nilable` types. Enabled by default
    boolean laxDataBinding = true;
|};

# Represents a key-value pair associated with an Amazon SES resource.
public type Tag record {
    # One part of a key-value pair that defines a tag, between 1 and 128 characters long
    @jsondata:Name {value: "Key"}
    string key;
    # The optional part of a key-value pair that defines a tag, up to 256 characters long
    @jsondata:Name {value: "Value"}
    string value;
};

# Represents the name and value of a tag applied to an email.
public type MessageTag record {
    # The name of the message tag
    @jsondata:Name {value: "Name"}
    string name;
    # The value of the message tag
    @jsondata:Name {value: "Value"}
    string value;
};

# Represents a contact's preference for being opted in to or out of a topic.
public enum SubscriptionStatus {
    # The contact is subscribed to the topic
    OPT_IN,
    # The contact is unsubscribed from the topic
    OPT_OUT
}

# Represents the type of an email identity.
public enum IdentityType {
    # The identity is a single email address
    EMAIL_ADDRESS,
    # The identity is a domain
    DOMAIN,
    # A domain managed on your behalf. Note: this identity type is not supported
    MANAGED_DOMAIN
}

# Represents the verification status of an email identity.
public enum VerificationStatus {
    # The verification process was initiated, but Amazon SES has not yet verified the identity
    PENDING,
    # The verification process completed successfully
    SUCCESS,
    # The verification process failed
    FAILED,
    # A temporary issue is preventing Amazon SES from determining the verification status
    TEMPORARY_FAILURE,
    # The verification process has not been initiated for the identity
    NOT_STARTED
}

# Represents an interest group, theme, or label within a contact list.
public type Topic record {
    # The name of the topic
    @jsondata:Name {value: "TopicName"}
    string topicName;
    # The name of the topic the contact will see
    @jsondata:Name {value: "DisplayName"}
    string displayName;
    # The subscription status applied to a contact that has not noted a preference for this topic
    @jsondata:Name {value: "DefaultSubscriptionStatus"}
    SubscriptionStatus defaultSubscriptionStatus;
    # A description of what the topic is about, which the contact will see
    @jsondata:Name {value: "Description"}
    string description?;
};

# Represents a contact's preference for being opted in to or out of a topic.
public type TopicPreference record {
    # The name of the topic
    @jsondata:Name {value: "TopicName"}
    string topicName;
    # The contact's subscription status to the topic
    @jsondata:Name {value: "SubscriptionStatus"}
    SubscriptionStatus subscriptionStatus;
};

# Represents the fields of a `createContactList` request.
public type CreateContactListInput record {|
    # The name of the contact list
    @jsondata:Name {value: "ContactListName"}
    string contactListName;
    # A description of what the contact list is about
    @jsondata:Name {value: "Description"}
    string description?;
    # The topics of the contact list
    @jsondata:Name {value: "Topics"}
    Topic[] topics?;
    # The tags to associate with the contact list
    @jsondata:Name {value: "Tags"}
    Tag[] tags?;
|};

# Represents the fields of an `updateContactList` request. This operation does a complete replacement of the
# description and the topics.
public type UpdateContactListInput record {|
    # A description of what the contact list is about
    @jsondata:Name {value: "Description"}
    string description?;
    # The topics of the contact list
    @jsondata:Name {value: "Topics"}
    Topic[] topics?;
|};

# Represents the metadata of a contact list, as returned by `getContactList`.
public type ContactListDetails record {
    # The name of the contact list
    @jsondata:Name {value: "ContactListName"}
    string contactListName?;
    # A description of what the contact list is about
    @jsondata:Name {value: "Description"}
    string description?;
    # The topics of the contact list
    @jsondata:Name {value: "Topics"}
    Topic[] topics?;
    # The tags associated with the contact list
    @jsondata:Name {value: "Tags"}
    Tag[] tags?;
    # A timestamp noting when the contact list was created, in UNIX epoch time format
    @jsondata:Name {value: "CreatedTimestamp"}
    decimal createdTimestamp?;
    # A timestamp noting the last time the contact list was updated, in UNIX epoch time format
    @jsondata:Name {value: "LastUpdatedTimestamp"}
    decimal lastUpdatedTimestamp?;
};

# Represents a contact list returned by `listContactLists`. Only the name and the update timestamp are listed; call
# `getContactList` for the description, the topics, and the tags.
public type ContactList record {
    # The name of the contact list
    @jsondata:Name {value: "ContactListName"}
    string contactListName?;
    # A timestamp noting the last time the contact list was updated, in UNIX epoch time format
    @jsondata:Name {value: "LastUpdatedTimestamp"}
    decimal lastUpdatedTimestamp?;
};

# Represents the fields of a `listContactLists` request.
public type ListContactListsInput record {|
    # The maximum number of contact lists a single page may carry
    int pageSize?;
|};

# Represents a single page of the `ListContactLists` response.
type ListContactListsOutput record {
    # The available contact lists
    @jsondata:Name {value: "ContactLists"}
    ContactList[] contactLists = [];
    # A token indicating that there might be additional contact lists to be listed
    @jsondata:Name {value: "NextToken"}
    string nextToken?;
};

# Represents the fields of a `createContact` request.
public type CreateContactInput record {|
    # The contact's email address
    @jsondata:Name {value: "EmailAddress"}
    string emailAddress;
    # The attribute data attached to the contact, as a JSON string
    @jsondata:Name {value: "AttributesData"}
    string attributesData?;
    # The contact's preferences for being opted in to or out of topics
    @jsondata:Name {value: "TopicPreferences"}
    TopicPreference[] topicPreferences?;
    # Whether the contact is unsubscribed from all of the contact list's topics
    @jsondata:Name {value: "UnsubscribeAll"}
    boolean unsubscribeAll?;
|};

# Represents the fields of an `updateContact` request. It is not necessary to specify every existing topic
# preference, only the ones that need updating.
public type UpdateContactInput record {|
    # The attribute data attached to the contact, as a JSON string
    @jsondata:Name {value: "AttributesData"}
    string attributesData?;
    # The contact's preferences for being opted in to or out of topics
    @jsondata:Name {value: "TopicPreferences"}
    TopicPreference[] topicPreferences?;
    # Whether the contact is unsubscribed from all of the contact list's topics
    @jsondata:Name {value: "UnsubscribeAll"}
    boolean unsubscribeAll?;
|};

# Represents a contact, as returned by `getContact`.
public type ContactDetails record {
    # The contact's email address
    @jsondata:Name {value: "EmailAddress"}
    string emailAddress?;
    # The name of the contact list to which the contact belongs
    @jsondata:Name {value: "ContactListName"}
    string contactListName?;
    # The attribute data attached to the contact, as a JSON string
    @jsondata:Name {value: "AttributesData"}
    string attributesData?;
    # The contact's preferences for being opted in to or out of topics
    @jsondata:Name {value: "TopicPreferences"}
    TopicPreference[] topicPreferences?;
    # The default topic preferences applied to the contact
    @jsondata:Name {value: "TopicDefaultPreferences"}
    TopicPreference[] topicDefaultPreferences?;
    # Whether the contact is unsubscribed from all of the contact list's topics
    @jsondata:Name {value: "UnsubscribeAll"}
    boolean unsubscribeAll?;
    # A timestamp noting when the contact was created, in UNIX epoch time format
    @jsondata:Name {value: "CreatedTimestamp"}
    decimal createdTimestamp?;
    # A timestamp noting the last time the contact was updated, in UNIX epoch time format
    @jsondata:Name {value: "LastUpdatedTimestamp"}
    decimal lastUpdatedTimestamp?;
};

# Represents a contact returned by `listContacts`. The attribute data and the contact list name are not listed; call
# `getContact` for those.
public type Contact record {
    # The contact's email address
    @jsondata:Name {value: "EmailAddress"}
    string emailAddress?;
    # The contact's preferences for being opted in to or out of topics
    @jsondata:Name {value: "TopicPreferences"}
    TopicPreference[] topicPreferences?;
    # The default topic preferences applied to the contact
    @jsondata:Name {value: "TopicDefaultPreferences"}
    TopicPreference[] topicDefaultPreferences?;
    # Whether the contact is unsubscribed from all of the contact list's topics
    @jsondata:Name {value: "UnsubscribeAll"}
    boolean unsubscribeAll?;
    # A timestamp noting the last time the contact was updated, in UNIX epoch time format
    @jsondata:Name {value: "LastUpdatedTimestamp"}
    decimal lastUpdatedTimestamp?;
};

# Represents the subscription status a contact must have for a topic to be included in a `listContacts` result.
public type TopicFilter record {
    # The name of the topic to filter on
    @jsondata:Name {value: "TopicName"}
    string topicName?;
    # Whether to apply the topic's default subscription status to contacts that have noted no preference for it
    @jsondata:Name {value: "UseDefaultIfPreferenceUnavailable"}
    boolean useDefaultIfPreferenceUnavailable?;
};

# Represents a filter applied to a `listContacts` request.
public type ListContactsFilter record {
    # Restricts the result to contacts with this subscription status
    @jsondata:Name {value: "FilteredStatus"}
    SubscriptionStatus filteredStatus?;
    # Restricts the result to contacts with a preference for a specific topic
    @jsondata:Name {value: "TopicFilter"}
    TopicFilter topicFilter?;
};

# Represents the fields of a `listContacts` request.
public type ListContactsInput record {|
    # A filter restricting which contacts are returned
    @jsondata:Name {value: "Filter"}
    ListContactsFilter filter?;
    # The maximum number of contacts a single page may carry
    @jsondata:Name {value: "PageSize"}
    int pageSize?;
|};

# Represents a single page of the `ListContacts` response.
type ListContactsOutput record {
    # The contacts present in the contact list
    @jsondata:Name {value: "Contacts"}
    Contact[] contacts = [];
    # A token indicating that there might be additional contacts to be listed
    @jsondata:Name {value: "NextToken"}
    string nextToken?;
};

# Represents the content of an email template, composed of a subject line, an HTML part, and a text-only part.
public type EmailTemplateContent record {
    # The subject line of the email
    @jsondata:Name {value: "Subject"}
    string subject?;
    # The HTML body of the email
    @jsondata:Name {value: "Html"}
    string html?;
    # The email body visible to recipients whose email clients do not display HTML
    @jsondata:Name {value: "Text"}
    string text?;
};

# Represents the fields of a `createEmailTemplate` request.
public type CreateEmailTemplateInput record {|
    # The name of the template
    @jsondata:Name {value: "TemplateName"}
    string templateName;
    # The content of the email template
    @jsondata:Name {value: "TemplateContent"}
    EmailTemplateContent templateContent;
|};

# Represents the fields of an `updateEmailTemplate` request.
public type UpdateEmailTemplateInput record {|
    # The content of the email template
    @jsondata:Name {value: "TemplateContent"}
    EmailTemplateContent templateContent;
|};

# Represents an email template, as returned by `getEmailTemplate`.
public type EmailTemplateDetails record {
    # The name of the template
    @jsondata:Name {value: "TemplateName"}
    string templateName?;
    # The content of the email template
    @jsondata:Name {value: "TemplateContent"}
    EmailTemplateContent templateContent?;
    # The tags associated with the email template
    @jsondata:Name {value: "Tags"}
    Tag[] tags?;
};

# Represents the name and creation timestamp of an email template, as returned by `listEmailTemplates`.
public type EmailTemplateMetadata record {
    # The name of the template
    @jsondata:Name {value: "TemplateName"}
    string templateName?;
    # A timestamp noting when the template was created, in UNIX epoch time format
    @jsondata:Name {value: "CreatedTimestamp"}
    decimal createdTimestamp?;
};

# Represents the fields of a `listEmailTemplates` request.
public type ListEmailTemplatesInput record {|
    # The maximum number of templates a single page may carry, between 1 and 100
    int pageSize?;
|};

# Represents a single page of the `ListEmailTemplates` response.
type ListEmailTemplatesOutput record {
    # The name and creation timestamp of each template in the account
    @jsondata:Name {value: "TemplatesMetadata"}
    EmailTemplateMetadata[] templatesMetadata = [];
    # A token indicating that there might be additional templates to be listed
    @jsondata:Name {value: "NextToken"}
    string nextToken?;
};

# Represents the fields of a `createCustomVerificationEmailTemplate` request.
public type CreateCustomVerificationEmailTemplateInput record {|
    # The name of the custom verification email template
    @jsondata:Name {value: "TemplateName"}
    string templateName;
    # The email address the custom verification email is sent from
    @jsondata:Name {value: "FromEmailAddress"}
    string fromEmailAddress;
    # The subject line of the custom verification email
    @jsondata:Name {value: "TemplateSubject"}
    string templateSubject;
    # The content of the custom verification email, as an HTML string
    @jsondata:Name {value: "TemplateContent"}
    string templateContent;
    # The URL the recipient is sent to if their address is successfully verified
    @jsondata:Name {value: "SuccessRedirectionURL"}
    string successRedirectionUrl;
    # The URL the recipient is sent to if their address is not successfully verified
    @jsondata:Name {value: "FailureRedirectionURL"}
    string failureRedirectionUrl;
|};

# Represents the fields of an `updateCustomVerificationEmailTemplate` request.
public type UpdateCustomVerificationEmailTemplateInput record {|
    # The email address the custom verification email is sent from
    @jsondata:Name {value: "FromEmailAddress"}
    string fromEmailAddress;
    # The subject line of the custom verification email
    @jsondata:Name {value: "TemplateSubject"}
    string templateSubject;
    # The content of the custom verification email, as an HTML string
    @jsondata:Name {value: "TemplateContent"}
    string templateContent;
    # The URL the recipient is sent to if their address is successfully verified
    @jsondata:Name {value: "SuccessRedirectionURL"}
    string successRedirectionUrl;
    # The URL the recipient is sent to if their address is not successfully verified
    @jsondata:Name {value: "FailureRedirectionURL"}
    string failureRedirectionUrl;
|};

# Represents a custom verification email template, as returned by `getCustomVerificationEmailTemplate`.
public type CustomVerificationEmailTemplateDetails record {
    # The name of the custom verification email template
    @jsondata:Name {value: "TemplateName"}
    string templateName?;
    # The email address the custom verification email is sent from
    @jsondata:Name {value: "FromEmailAddress"}
    string fromEmailAddress?;
    # The subject line of the custom verification email
    @jsondata:Name {value: "TemplateSubject"}
    string templateSubject?;
    # The content of the custom verification email, as an HTML string
    @jsondata:Name {value: "TemplateContent"}
    string templateContent?;
    # The URL the recipient is sent to if their address is successfully verified
    @jsondata:Name {value: "SuccessRedirectionURL"}
    string successRedirectionUrl?;
    # The URL the recipient is sent to if their address is not successfully verified
    @jsondata:Name {value: "FailureRedirectionURL"}
    string failureRedirectionUrl?;
    # The tags associated with the custom verification email template
    @jsondata:Name {value: "Tags"}
    Tag[] tags?;
};

# Represents a custom verification email template returned by `listCustomVerificationEmailTemplates`. The template
# content is not listed; call `getCustomVerificationEmailTemplate` for it.
public type CustomVerificationEmailTemplateMetadata record {
    # The name of the custom verification email template
    @jsondata:Name {value: "TemplateName"}
    string templateName?;
    # The email address the custom verification email is sent from
    @jsondata:Name {value: "FromEmailAddress"}
    string fromEmailAddress?;
    # The subject line of the custom verification email
    @jsondata:Name {value: "TemplateSubject"}
    string templateSubject?;
    # The URL the recipient is sent to if their address is successfully verified
    @jsondata:Name {value: "SuccessRedirectionURL"}
    string successRedirectionUrl?;
    # The URL the recipient is sent to if their address is not successfully verified
    @jsondata:Name {value: "FailureRedirectionURL"}
    string failureRedirectionUrl?;
};

# Represents the fields of a `listCustomVerificationEmailTemplates` request.
public type ListCustomVerificationEmailTemplatesInput record {|
    # The maximum number of templates a single page may carry, between 1 and 50
    int pageSize?;
|};

# Represents a single page of the `ListCustomVerificationEmailTemplates` response.
type ListCustomVerificationEmailTemplatesOutput record {
    # The custom verification email templates that exist in the account
    @jsondata:Name {value: "CustomVerificationEmailTemplates"}
    CustomVerificationEmailTemplateMetadata[] customVerificationEmailTemplates = [];
    # A token indicating that there might be additional templates to be listed
    @jsondata:Name {value: "NextToken"}
    string nextToken?;
};

# Represents how DKIM was configured for an identity.
public enum SigningAttributesOrigin {
    # DKIM was configured for the identity by Amazon SES (Easy DKIM)
    AWS_SES,
    # DKIM was configured for the identity by the identity owner (BYODKIM)
    EXTERNAL
}

# Represents the length of the DKIM signing key.
public enum SigningKeyLength {
    # An RSA key of 1024 bits
    RSA_1024_BIT,
    # An RSA key of 2048 bits
    RSA_2048_BIT
}

# Represents whether Amazon SES has located the DKIM records in the DNS configuration for a domain. Its values are
# the same as those of `VerificationStatus`.
public type DkimStatus VerificationStatus;

# Represents the status of a custom MAIL FROM domain. Its values are those of `VerificationStatus` except
# `NOT_STARTED`, which a MAIL FROM domain never reports.
public type MailFromDomainStatus VerificationStatus;

# Represents the action to take if the required MX record cannot be found when an email is sent.
public enum BehaviorOnMxFailure {
    # Amazon SES uses `amazonses.com` as the MAIL FROM domain
    USE_DEFAULT_VALUE,
    # Amazon SES returns a `MailFromDomainNotVerified` error and does not send the email
    REJECT_MESSAGE
}

# Represents the DKIM authentication status of an email identity.
public type DkimAttributes record {
    # How DKIM was configured for the identity
    @jsondata:Name {value: "SigningAttributesOrigin"}
    SigningAttributesOrigin signingAttributesOrigin?;
    # Whether the messages sent from the identity are signed using DKIM
    @jsondata:Name {value: "SigningEnabled"}
    boolean signingEnabled?;
    # Whether Amazon SES has located the DKIM records in the DNS configuration for the domain
    @jsondata:Name {value: "Status"}
    DkimStatus status?;
    # The tokens used in DKIM authentication, which are converted into CNAME records in the domain's DNS
    @jsondata:Name {value: "Tokens"}
    string[] tokens?;
    # The key length of the DKIM key pair in use
    @jsondata:Name {value: "CurrentSigningKeyLength"}
    SigningKeyLength currentSigningKeyLength?;
    # The key length of the future DKIM key pair to be generated
    @jsondata:Name {value: "NextSigningKeyLength"}
    SigningKeyLength nextSigningKeyLength?;
    # A timestamp noting when the DKIM key pair was generated, in UNIX epoch time format
    @jsondata:Name {value: "LastKeyGenerationTimestamp"}
    decimal lastKeyGenerationTimestamp?;
    # The hosted zone of the DKIM records, for identities configured through Route 53
    @jsondata:Name {value: "SigningHostedZone"}
    string signingHostedZone?;
};

# Represents the DKIM signing configuration to apply to an identity. Supply `domainSigningSelector` and
# `domainSigningPrivateKey` to use Bring Your Own DKIM (BYODKIM), or `nextSigningKeyLength` alone to configure the
# key length of Easy DKIM.
public type DkimSigningAttributes record {
    # A string identifying the public key in the domain's DNS configuration
    @jsondata:Name {value: "DomainSigningSelector"}
    string domainSigningSelector?;
    # The private key used to generate a DKIM signature, in PKCS#8 PEM form, base64 encoded
    @display {label: "", kind: "password"}
    @jsondata:Name {value: "DomainSigningPrivateKey"}
    string domainSigningPrivateKey?;
    # How DKIM is to be configured for the identity
    @jsondata:Name {value: "DomainSigningAttributesOrigin"}
    SigningAttributesOrigin domainSigningAttributesOrigin?;
    # The key length of the DKIM key pair to be generated for Easy DKIM
    @jsondata:Name {value: "NextSigningKeyLength"}
    SigningKeyLength nextSigningKeyLength?;
};

# Represents the custom MAIL FROM configuration of an email identity.
public type MailFromAttributes record {
    # The name of the domain the identity uses as its custom MAIL FROM domain
    @jsondata:Name {value: "MailFromDomain"}
    string mailFromDomain?;
    # The status of the MAIL FROM domain
    @jsondata:Name {value: "MailFromDomainStatus"}
    string mailFromDomainStatus?;
    # The action to take if the required MX record cannot be found when an email is sent
    @jsondata:Name {value: "BehaviorOnMxFailure"}
    BehaviorOnMxFailure behaviorOnMxFailure?;
};

# Represents the start-of-authority (SOA) record of a domain, reported when verification fails because of a DNS
# configuration problem.
public type SoaRecord record {
    # The primary name server of the domain
    @jsondata:Name {value: "PrimaryNameServer"}
    string primaryNameServer?;
    # The email address of the domain administrator
    @jsondata:Name {value: "AdminEmail"}
    string adminEmail?;
    # The serial number of the SOA record
    @jsondata:Name {value: "SerialNumber"}
    int serialNumber?;
};

# Represents additional information about the verification status of an identity.
public type VerificationInfo record {
    # The reason the verification failed
    @jsondata:Name {value: "ErrorType"}
    string errorType?;
    # A timestamp noting when the verification status was last checked, in UNIX epoch time format
    @jsondata:Name {value: "LastCheckedTimestamp"}
    decimal lastCheckedTimestamp?;
    # A timestamp noting when the identity was last successfully verified, in UNIX epoch time format
    @jsondata:Name {value: "LastSuccessTimestamp"}
    decimal lastSuccessTimestamp?;
    # The start-of-authority record of the domain
    @jsondata:Name {value: "SOARecord"}
    SoaRecord soaRecord?;
};

# Represents the fields of a `createEmailIdentity` request.
public type CreateEmailIdentityInput record {|
    # The email address or domain to verify
    @jsondata:Name {value: "EmailIdentity"}
    string emailIdentity;
    # The configuration set to use by default when sending from this identity
    @jsondata:Name {value: "ConfigurationSetName"}
    string configurationSetName?;
    # The DKIM signing configuration to apply. This may only be given for a domain identity, not an email address
    @jsondata:Name {value: "DkimSigningAttributes"}
    DkimSigningAttributes dkimSigningAttributes?;
    # The tags to associate with the email identity
    @jsondata:Name {value: "Tags"}
    Tag[] tags?;
|};

# Represents the result of a `createEmailIdentity` request.
public type CreateEmailIdentityOutput record {
    # The email identity type
    @jsondata:Name {value: "IdentityType"}
    IdentityType identityType?;
    # Whether the identity is verified, and so usable as a sending address
    @jsondata:Name {value: "VerifiedForSendingStatus"}
    boolean verifiedForSendingStatus?;
    # The DKIM attributes of the identity, carrying the tokens to add to the domain's DNS configuration
    @jsondata:Name {value: "DkimAttributes"}
    DkimAttributes dkimAttributes?;
};

# Represents an email identity, as returned by `getEmailIdentity`.
public type EmailIdentityDetails record {
    # The email identity type
    @jsondata:Name {value: "IdentityType"}
    IdentityType identityType?;
    # The verification status of the identity
    @jsondata:Name {value: "VerificationStatus"}
    VerificationStatus verificationStatus?;
    # Whether the identity is verified, and so usable as a sending address
    @jsondata:Name {value: "VerifiedForSendingStatus"}
    boolean verifiedForSendingStatus?;
    # Additional information about the verification status
    @jsondata:Name {value: "VerificationInfo"}
    VerificationInfo verificationInfo?;
    # The DKIM attributes of the identity
    @jsondata:Name {value: "DkimAttributes"}
    DkimAttributes dkimAttributes?;
    # The custom MAIL FROM configuration of the identity
    @jsondata:Name {value: "MailFromAttributes"}
    MailFromAttributes mailFromAttributes?;
    # The configuration set used by default when sending from this identity
    @jsondata:Name {value: "ConfigurationSetName"}
    string configurationSetName?;
    # Whether bounce and complaint notifications are forwarded by email
    @jsondata:Name {value: "FeedbackForwardingStatus"}
    boolean feedbackForwardingStatus?;
    # A map of sending authorization policy names to policies
    @jsondata:Name {value: "Policies"}
    map<string> policies?;
    # The tags associated with the email identity
    @jsondata:Name {value: "Tags"}
    Tag[] tags?;
};

# Represents an email identity returned by `listEmailIdentities`.
public type IdentityInfo record {
    # The address or domain of the identity
    @jsondata:Name {value: "IdentityName"}
    string identityName?;
    # The email identity type
    @jsondata:Name {value: "IdentityType"}
    IdentityType identityType?;
    # Whether email can be sent from the identity
    @jsondata:Name {value: "SendingEnabled"}
    boolean sendingEnabled?;
    # The verification status of the identity
    @jsondata:Name {value: "VerificationStatus"}
    VerificationStatus verificationStatus?;
};

# Represents the fields of a `listEmailIdentities` request.
public type ListEmailIdentitiesInput record {|
    # The maximum number of identities a single page may carry, up to 1000
    int pageSize?;
|};

# Represents a single page of the `ListEmailIdentities` response.
type ListEmailIdentitiesOutput record {
    # The email identities associated with the account
    @jsondata:Name {value: "EmailIdentities"}
    IdentityInfo[] emailIdentities = [];
    # A token indicating that there might be additional identities to be listed
    @jsondata:Name {value: "NextToken"}
    string nextToken?;
};

# Represents the recipients of an email message.
public type Destination record {
    # The email addresses of the "To" recipients
    @jsondata:Name {value: "ToAddresses"}
    string[] toAddresses?;
    # The email addresses of the "CC" (carbon copy) recipients
    @jsondata:Name {value: "CcAddresses"}
    string[] ccAddresses?;
    # The email addresses of the "BCC" (blind carbon copy) recipients
    @jsondata:Name {value: "BccAddresses"}
    string[] bccAddresses?;
};

# Represents a block of text in an email message, with the character set it is written in.
public type Content record {
    # The content of the message itself
    @jsondata:Name {value: "Data"}
    string data;
    # The character set of the content. Amazon SES uses 7-bit ASCII by default, so a character set has to be given
    # whenever the text includes characters outside the ASCII range — for example `UTF-8` or `ISO-8859-1`
    @jsondata:Name {value: "Charset"}
    string charset?;
};

# Represents the body of an email message. Supply the HTML part, the text part, or both — a message with both lets
# each recipient's email client pick the part it can display.
public type Body record {
    # The HTML body of the email
    @jsondata:Name {value: "Html"}
    Content html?;
    # The body visible to recipients whose email clients do not display HTML
    @jsondata:Name {value: "Text"}
    Content text?;
};

# Represents a custom header applied to an email message.
public type MessageHeader record {
    # The name of the header
    @jsondata:Name {value: "Name"}
    string name;
    # The value of the header
    @jsondata:Name {value: "Value"}
    string value;
};

# Represents a file attached to an email message.
public type Attachment record {
    # The file name of the attachment, as it appears to the recipient
    @jsondata:Name {value: "FileName"}
    string fileName;
    # The raw content of the attachment
    @jsondata:Name {value: "RawContent"}
    byte[] rawContent;
    # The MIME content type of the attachment
    @jsondata:Name {value: "ContentType"}
    string contentType?;
    # Whether the attachment is displayed inline or offered as a download
    @jsondata:Name {value: "ContentDisposition"}
    string contentDisposition?;
    # A description of the attachment
    @jsondata:Name {value: "ContentDescription"}
    string contentDescription?;
    # An identifier for the attachment, which an HTML body can reference with a `cid:` URL
    @jsondata:Name {value: "ContentId"}
    string contentId?;
    # The transfer encoding of the attachment
    @jsondata:Name {value: "ContentTransferEncoding"}
    string contentTransferEncoding?;
};

# Represents a standard email message, which Amazon SES assembles from its parts.
public type SimpleEmail record {
    # The subject line of the email
    @jsondata:Name {value: "Subject"}
    Content subject?;
    # The body of the message
    @jsondata:Name {value: "Body"}
    Body body?;
    # The custom headers to apply to the message
    @jsondata:Name {value: "Headers"}
    MessageHeader[] headers?;
    # The files to attach to the message
    @jsondata:Name {value: "Attachments"}
    Attachment[] attachments?;
};

# Represents a raw, MIME-formatted email message. The message has to be a valid MIME message, carrying all of its
# own headers as well as its body.
public type RawEmail record {
    # The raw MIME content of the message
    @jsondata:Name {value: "Data"}
    byte[] data;
};

# Represents a templated email message, whose personalization tags Amazon SES replaces with the supplied values.
public type TemplatedEmail record {
    # The name of the template to use
    @jsondata:Name {value: "TemplateName"}
    string templateName?;
    # The Amazon Resource Name (ARN) of the template to use
    @jsondata:Name {value: "TemplateArn"}
    string templateArn?;
    # The content of an inline template, used instead of a stored one
    @jsondata:Name {value: "TemplateContent"}
    EmailTemplateContent templateContent?;
    # The values for the template's message variables, as a JSON string
    @jsondata:Name {value: "TemplateData"}
    string templateData?;
    # The custom headers to apply to the message
    @jsondata:Name {value: "Headers"}
    MessageHeader[] headers?;
    # The files to attach to the message
    @jsondata:Name {value: "Attachments"}
    Attachment[] attachments?;
};

# Represents the body of an email message. Exactly one of `simple`, `raw`, or `template` is to be supplied.
public type EmailContent record {
    # A standard message, which Amazon SES assembles from the subject and body given here
    @jsondata:Name {value: "Simple"}
    SimpleEmail simple?;
    # A raw, MIME-formatted message
    @jsondata:Name {value: "Raw"}
    RawEmail raw?;
    # A templated message
    @jsondata:Name {value: "Template"}
    TemplatedEmail template?;
};

# Represents the contact list and topic an email belongs to, used when a recipient chooses to unsubscribe.
public type ListManagementOptions record {
    # The name of the contact list
    @jsondata:Name {value: "ContactListName"}
    string contactListName;
    # The name of the topic
    @jsondata:Name {value: "TopicName"}
    string topicName?;
};

# Represents the open and click tracking settings applied to a message.
public type TrackingOptions record {
    # Whether to track opens of the message
    @jsondata:Name {value: "OpenTrackingEnabled"}
    string openTrackingEnabled?;
    # Whether to track clicks of the links in the message
    @jsondata:Name {value: "ClickTrackingEnabled"}
    string clickTrackingEnabled?;
};

# Represents settings that override, for this message only, the ones that would otherwise apply to it.
public type ConfigurationOverrides record {
    # The open and click tracking settings to apply
    @jsondata:Name {value: "Tracking"}
    TrackingOptions tracking?;
};

# Represents the fields of a `sendEmail` request.
public type SendEmailInput record {|
    # The body of the message: a simple, a raw, or a templated message
    @jsondata:Name {value: "Content"}
    EmailContent content;
    # The recipients of the message
    @jsondata:Name {value: "Destination"}
    Destination destination?;
    # The email address to use as the "From" address. The address has to be a verified identity
    @jsondata:Name {value: "FromEmailAddress"}
    string fromEmailAddress?;
    # The ARN of the identity carrying the sending authorization policy that permits the use of `fromEmailAddress`
    @jsondata:Name {value: "FromEmailAddressIdentityArn"}
    string fromEmailAddressIdentityArn?;
    # The "Reply-to" addresses. A recipient replying to the message replies to each of these
    @jsondata:Name {value: "ReplyToAddresses"}
    string[] replyToAddresses?;
    # The address bounce and complaint notifications are sent to
    @jsondata:Name {value: "FeedbackForwardingEmailAddress"}
    string feedbackForwardingEmailAddress?;
    # The ARN of the identity carrying the sending authorization policy that permits the use of
    # `feedbackForwardingEmailAddress`
    @jsondata:Name {value: "FeedbackForwardingEmailAddressIdentityArn"}
    string feedbackForwardingEmailAddressIdentityArn?;
    # The name of the configuration set to use when sending the email
    @jsondata:Name {value: "ConfigurationSetName"}
    string configurationSetName?;
    # Settings overriding, for this message only, the ones that would otherwise apply
    @jsondata:Name {value: "ConfigurationOverrides"}
    ConfigurationOverrides configurationOverrides?;
    # The tags to apply to the email, so that sending events can be published against them
    @jsondata:Name {value: "EmailTags"}
    MessageTag[] emailTags?;
    # The contact list and topic the email belongs to, used when a recipient unsubscribes
    @jsondata:Name {value: "ListManagementOptions"}
    ListManagementOptions listManagementOptions?;
    # The ID of the multi-region endpoint to send through
    @jsondata:Name {value: "EndpointId"}
    string endpointId?;
    # The name of the tenant to send through. Every identity, configuration set, and template the request refers to
    # has to be associated with this tenant
    @jsondata:Name {value: "TenantName"}
    string tenantName?;
|};

# Represents the result of a `sendEmail` or a `sendCustomVerificationEmail` request.
public type SendEmailOutput record {
    # A unique identifier for the message, generated when the message is accepted. Amazon SES can accept a message
    # without going on to send it — for example when an attachment contains a virus
    @jsondata:Name {value: "MessageId"}
    string messageId?;
};

# Represents the fields of a `sendCustomVerificationEmail` request.
public type SendCustomVerificationEmailInput record {|
    # The email address to verify
    @jsondata:Name {value: "EmailAddress"}
    string emailAddress;
    # The name of the custom verification email template to use
    @jsondata:Name {value: "TemplateName"}
    string templateName;
    # The name of the configuration set to use when sending the verification email
    @jsondata:Name {value: "ConfigurationSetName"}
    string configurationSetName?;
|};

# Represents the template to use for a bulk email message.
public type BulkEmailContent record {
    # The template to use for every message in the request
    @jsondata:Name {value: "Template"}
    TemplatedEmail template?;
};

# Represents the template values that replace the defaults for one recipient of a bulk email.
public type ReplacementTemplate record {
    # The values for the template's message variables, as a JSON string
    @jsondata:Name {value: "ReplacementTemplateData"}
    string replacementTemplateData?;
};

# Represents the message content that replaces the default for one recipient of a bulk email.
public type ReplacementEmailContent record {
    # The template values for this recipient
    @jsondata:Name {value: "ReplacementTemplate"}
    ReplacementTemplate replacementTemplate?;
};

# Represents one recipient of a bulk email message.
public type BulkEmailEntry record {
    # The recipients of this message
    @jsondata:Name {value: "Destination"}
    Destination destination;
    # The message content replacing the default for this recipient
    @jsondata:Name {value: "ReplacementEmailContent"}
    ReplacementEmailContent replacementEmailContent?;
    # The headers replacing the default ones for this recipient
    @jsondata:Name {value: "ReplacementHeaders"}
    MessageHeader[] replacementHeaders?;
    # The tags replacing the default ones for this recipient
    @jsondata:Name {value: "ReplacementTags"}
    MessageTag[] replacementTags?;
};

# Represents the outcome of sending a bulk email message to one recipient.
public type BulkEmailEntryResult record {
    # The status of the message
    @jsondata:Name {value: "Status"}
    string status?;
    # A unique identifier for the message, generated when the message is accepted
    @jsondata:Name {value: "MessageId"}
    string messageId?;
    # A description of the error that prevented the message from being sent
    @jsondata:Name {value: "Error"}
    string 'error?;
};

# Represents the fields of a `sendBulkEmail` request.
public type SendBulkEmailInput record {|
    # One entry per intended recipient
    @jsondata:Name {value: "BulkEmailEntries"}
    BulkEmailEntry[] bulkEmailEntries;
    # The template used for every message in the request, unless a `BulkEmailEntry` replaces it
    @jsondata:Name {value: "DefaultContent"}
    BulkEmailContent defaultContent;
    # The email address to use as the "From" address. The address has to be a verified identity
    @jsondata:Name {value: "FromEmailAddress"}
    string fromEmailAddress?;
    # The ARN of the identity carrying the sending authorization policy that permits the use of `fromEmailAddress`
    @jsondata:Name {value: "FromEmailAddressIdentityArn"}
    string fromEmailAddressIdentityArn?;
    # The "Reply-to" addresses. A recipient replying to a message replies to each of these
    @jsondata:Name {value: "ReplyToAddresses"}
    string[] replyToAddresses?;
    # The address bounce and complaint notifications are sent to
    @jsondata:Name {value: "FeedbackForwardingEmailAddress"}
    string feedbackForwardingEmailAddress?;
    # The ARN of the identity carrying the sending authorization policy that permits the use of
    # `feedbackForwardingEmailAddress`
    @jsondata:Name {value: "FeedbackForwardingEmailAddressIdentityArn"}
    string feedbackForwardingEmailAddressIdentityArn?;
    # The name of the configuration set to use when sending the emails
    @jsondata:Name {value: "ConfigurationSetName"}
    string configurationSetName?;
    # Settings overriding, for these messages only, the ones that would otherwise apply
    @jsondata:Name {value: "ConfigurationOverrides"}
    ConfigurationOverrides configurationOverrides?;
    # The tags to apply to every email, unless a `BulkEmailEntry` replaces them
    @jsondata:Name {value: "DefaultEmailTags"}
    MessageTag[] defaultEmailTags?;
    # The ID of the multi-region endpoint to send through
    @jsondata:Name {value: "EndpointId"}
    string endpointId?;
    # The name of the tenant to send through. Every identity, configuration set, and template the request refers to
    # has to be associated with this tenant
    @jsondata:Name {value: "TenantName"}
    string tenantName?;
|};

# Represents the result of a `sendBulkEmail` request.
public type SendBulkEmailOutput record {
    # One result per intended recipient, in the order the entries were given. Check each one and retry the messages
    # that carry a failure status
    @jsondata:Name {value: "BulkEmailEntryResults"}
    BulkEmailEntryResult[] bulkEmailEntryResults = [];
};
