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

import ballerinax/'client.config;

# Represents the AWS SES Connector configurations.
@display {label: "Connection Config"}
public type ConnectionConfig record {|
    *config:ConnectionConfig;
    never auth?;
    # AWS credentials
    AwsCredentials|AwsTemporaryCredentials awsCredentials;
    # AWS Region
    string region = DEFAULT_REGION;
|};

# Represents AWS credentials.
#
# + accessKeyId - AWS access key  
# + secretAccessKey - AWS secret key
public type AwsCredentials record {
    string accessKeyId;
    @display {
        label: "",
        kind: "password"
    }
    string secretAccessKey;
};

# Represents AWS temporary credentials.
#
# + accessKeyId - AWS access key  
# + secretAccessKey - AWS secret key  
# + securityToken - AWS secret token
public type AwsTemporaryCredentials record {
    string accessKeyId;
    @display {
        label: "",
        kind: "password"
    }
    string secretAccessKey;
    @display {
        label: "",
        kind: "password"
    }
    string securityToken;
};

//AWS SES related record fields are using Titlecase to support the record mapping.

# Represents the request to create contact list.
#
# + ContactListName - The name of the contact list
# + Description - A description of what the contact list is about  
# + Tags - The tags associated with a contact list
# + Topics - An interest group, theme, or label within a list
public type ContactListCreationRequest record {
    string ContactListName;
    string Description?;
    Tag[] Tags?;
    Topic[] Topics?;
};

# Represents tag.
#
# + Key - One part of a key-value pair that deﬁnes a tag. The maximum length of a tag key is 128 characters. The 
#         minimum length is 1 character.
# + Value - The optional part of a key-value pair that deﬁnes a tag. The maximum length of a tag value is 256 
#           characters. The minimum length is 0 characters. 
public type Tag record {
    string Key;
    string Value;
};

# Represents topic.
#
# + DefaultSubscriptionStatus - The default subscription status to be applied to a contact if the contact has not noted
#                               their preference for subscribing to a topic
# + Description - A description of what the topic is about, which the contact will see
# + DisplayName - The name of the topic the contact will see
# + TopicName - The name of the topic
public type Topic record {
    SubscriptionStatus DefaultSubscriptionStatus;
    string? Description?;
    string DisplayName;
    string TopicName;
};

# Represents the contact list.
#
# + ContactListName - The name of the contact list 
# + CreatedTimestamp - A timestamp noting when the contact list was created
# + Description - A description of what the contact list is about
# + LastUpdatedTimestamp - A timestamp noting the last time the contact list was updated
# + Tags - The tags associated with a contact list
# + Topics - An interest group, theme, or label within a list
public type ContactList record {
    string ContactListName?;
    decimal? CreatedTimestamp?;
    string? Description?;
    decimal? LastUpdatedTimestamp?;
    Tag[]? Tags?;
    Topic[]? Topics?;
};

# Represents the list of contact lists.
#
# + ContactLists - The available contact lists
# + NextToken - A string token indicating that there might be additional contact lists available to be listed
public type ContactLists record {
    ContactList[]? ContactLists;
    string? NextToken?;
};

# Represents the contact's preference for being opted-in to or opted-out of a topic.
#
# + SubscriptionStatus - The contact's subscription status to a topic which is either OPT_IN or OPT_OUT
# + TopicName - The name of the topic
public type TopicPreference record {
    SubscriptionStatus SubscriptionStatus;
    string TopicName;
};

# Represents the request payload to create contact.
#
# + EmailAddress - The contact's email address
public type ContactCreationRequest record {
    string EmailAddress;
    *ContactUpdateRequest;
};

# Represents the request payload to update contact.
#
# + AttributesData - The attribute data attached to a contact
# + TopicPreferences - The contact's preferences for being opted-in to or opted-out of topics
# + UnsubscribeAll - A boolean value status noting if the contact is unsubscribed from all contact list topics
public type ContactUpdateRequest record {
    string? AttributesData?;
    TopicPreference[]? TopicPreferences?;
    boolean UnsubscribeAll?;
};

# Represents the contact.
#
# + ContactListName - The name of the contact list to which the contact belongs
# + CreatedTimestamp - A timestamp noting when the contact was created
# + EmailAddress - The contact's email addres
# + LastUpdatedTimestamp - A timestamp noting the last time the contact's information was updated
# + TopicDefaultPreferences - The default topic preferences applied to the contact
public type Contact record {
    string? ContactListName?;
    decimal? CreatedTimestamp?;
    string? EmailAddress?;
    decimal? LastUpdatedTimestamp?;
    TopicPreference[]? TopicDefaultPreferences?;
    *ContactUpdateRequest;
};

# Represents the list of contacts
#
# + Contacts - The contacts present in a speciﬁc contact list
# + NextToken - A string token indicating that there might be additional contacts available to be listed
public type Contacts record {
    Contact[]? Contacts?;
    string? NextToken?;
};

# Represents an object that contains information about the tokens used for setting up Bring Your Own DKIM (BYODKIM).
#
# + DomainSigningPrivateKey - A private key that's used to generate a DKIM signature
# + DomainSigningSelector - A string that's used to identify a public key in the DNS conﬁguration for a domain
public type DkimSigningAttributes record {
    string DomainSigningPrivateKey;
    string DomainSigningSelector;
};

# Represents the request payload to create email identity.
#
# + EmailIdentity - The email address or domain to verify
# + ConfigurationSetName - The conﬁguration set to use by default when sending from this identity
# + DkimSigningAttributes - DKIM signing attributes
# + Tags - An array of objects that deﬁne the tags (keys and values) to associate with the email identity
public type EmailIdentityCreationRequest record {
    string EmailIdentity;
    string ConfigurationSetName?;
    DkimSigningAttributes DkimSigningAttributes?;
    Tag[] Tags?;
};

# Represents an object that contains information about the DKIM authentication status for an email identity.
#
# + SigningAttributesOrigin - A string that indicates how DKIM was conﬁgured for the identity
# + SigningEnabled - If the value is true, then the messages that you send from the identity are signed using DKIM. 
#                    If the value is false, then the messages that you send from the identity aren't DKIM-signed.
# + SigningKeyLength - Field Description  
# + Status - Describes whether or not Amazon SES has successfully located the DKIM records in the DNS records for the 
#            domain
# + Tokens - The tokens which are used in DKIM authentication
public type DkimAttributes record {
    SigningAttributesOrigin? SigningAttributesOrigin?;
    boolean? SigningEnabled?;
    int? SigningKeyLength?;
    DkimAttributesStatus? Status?;
    string[]? Tokens?;
};

# Represents the email identity
#
# + DkimAttributes - An object that contains information about the DKIM attributes for the identity
# + IdentityType - The email identity type. Note: the MANAGED_DOMAIN identity type is not supported.
# + VerifiedForSendingStatus - Speciﬁes whether or not the identity is veriﬁed
public type EmailIdentity record {
    DkimAttributes? DkimAttributes?;
    IdentityType? IdentityType?;
    boolean? VerifiedForSendingStatus?;
};

# Represents a list of attributes that are associated with a MAIL FROM domain.
#
# + BehaviorOnMxFailure - The action to take if the required MX record can't be found when you send an email
# + MailFromDomain - The name of a domain that an email identity uses as a custom MAIL FROM domain
# + MailFromDomainStatus - The status of the MAIL FROM domain
public type MailFromAttributes record {
    BehaviorOnMxFailure? BehaviorOnMxFailure;
    string? MailFromDomain;
    string? MailFromDomainStatus;
};

# Represents the information of email identity.
#
# + ConﬁgurationSetName - The conﬁguration set used by default when sending from this identity
# + FeedbackForwardingStatus - The feedback forwarding conﬁguration for the identity
# + MailFromAttributes - An object that contains information about the Mail-From attributes for the email identity
# + Policies - A map of policy names to policies
# + Tags - An array of objects that deﬁne the tags (keys and values) that are associated with the email identity
public type EmailIdentityInfo record {
    string? ConﬁgurationSetName?;
    *EmailIdentity;
    boolean? FeedbackForwardingStatus;
    MailFromAttributes? MailFromAttributes;
    map<string>? Policies?;
    Tag[]? Tags?;
};

# Represents the information of identity.
#
# + IdentityName - The address or domain of the identity
# + IdentityType - The email identity type. Note: the MANAGED_DOMAIN type is not supported for email identity types.
# + SendingEnabled - Indicates whether or not you can send email from the identity
public type IdentityInfo record {
    string? IdentityName?;
    IdentityType? IdentityType?;
    boolean? SendingEnabled?;
};

# Represents the list of email identities.
#
# + EmailIdentities - An array that includes all of the email identities associated with your AWS account
# + NextToken - A token that indicates that there are additional conﬁguration sets to list
public type EmailIdentitiesListPage record {
    IdentityInfo[] EmailIdentities?;
    string? NextToken?;
};

# Represents the content of the email, composed of a subject line, an HTML part, and a text-only part.
#
# + Html - The HTML body of the email
# + Subject - The subject line of the email
# + Text - The email body that will be visible to recipients whose email clients do not display HTML
public type EmailTemplateContent record {
    string? Html?;
    string? Subject?;
    string? Text?;
};

# Represents the email template.
#
# + TemplateContent - The content of the email template, composed of a subject line, an HTML part, and a text-only part
# + TemplateName - The name of the template
public type EmailTemplate record {
    EmailTemplateContent TemplateContent;
    string TemplateName;
};

# Represents the email template metadata.
#
# + CreatedTimestamp - A timestamp noting when the contact was created
# + TemplateName - The name of the template 
public type EmailTemplateMetadata record {
    decimal CreatedTimestamp?;
    string TemplateName?;
};

# Represents the list of email templates.
#
# + TemplatesMetadata - An array the contains the name and creation time stamp for each template in your Amazon SES
#                       account
# + NextToken - A token indicating that there are additional email templates available to be listed
public type EmailTemplateListPage record {
    EmailTemplateMetadata[] TemplatesMetadata?;
    string? NextToken?;
};

# Represents the request payload to update email template.
#
# + TemplateContent - The content of the email, composed of a subject line, an HTML part, and a text-only part
public type EmailTemplateUpdateRequest record {
    EmailTemplateContent TemplateContent;
};

# Represents the custom veriﬁcation email template.
#
# + TemplateContent - The content of the email, composed of a subject line, an HTML part, and a text-only part
public type CustomVeriﬁcationEmailTemplate record {
    *CustomVeriﬁcationEmailTemplateElement;
    string TemplateContent;   
};

# Represents the request payload to update custom veriﬁcation email template.
#
# + FailureRedirectionURL - The URL that the recipient of the veriﬁcation email is sent to if his or her address is not
#                           successfully veriﬁed
# + FromEmailAddress - The email address that the custom veriﬁcation email is sent from
# + SuccessRedirectionURL - The URL that the recipient of the veriﬁcation email is sent to if his or her address is
#                           successfully veriﬁed
# + TemplateContent - The content of the custom veriﬁcation email
# + TemplateSubject - The subject line of the custom veriﬁcation email
public type CustomVeriﬁcationEmailUpdate record {
    string FailureRedirectionURL;
    string FromEmailAddress;
    string SuccessRedirectionURL;
    string TemplateContent;
    string TemplateSubject;
};

# Represents the element of custom veriﬁcation email template.
#
# + FailureRedirectionURL - The URL that the recipient of the veriﬁcation email is sent to if his or her address is not
#                           successfully veriﬁed
# + FromEmailAddress - The email address that the custom veriﬁcation email is sent from
# + SuccessRedirectionURL - The URL that the recipient of the veriﬁcation email is sent to if his or her address is
#                           successfully veriﬁed
# + TemplateName - The name of the custom veriﬁcation email template
# + TemplateSubject - The subject line of the custom veriﬁcation email
public type CustomVeriﬁcationEmailTemplateElement record {
    string FailureRedirectionURL;
    string FromEmailAddress;
    string SuccessRedirectionURL;
    string TemplateName;
    string TemplateSubject;
};

# Represents the list of custom veriﬁcation email templates.
#
# + CustomVerificationEmailTemplates - A list of the custom veriﬁcation email templates that exist in your account
# + NextToken - A token indicating that there are additional custom veriﬁcation email templates available to be listed
public type CustomVerificationTempListPage record {
    CustomVeriﬁcationEmailTemplateElement[]? CustomVerificationEmailTemplates?;
    string? NextToken?;
};

# Represents the request payload to send email.
#
# + Content - An object that contains the body of the message. You can send either a Simple message Raw message or a
#             template Message.
# + Destination - An object that contains the recipients of the email message
# + FromEmailAddress - The email address to use as the "From" address for the email. The address that you specify has
#                      to be veriﬁed.
public type EmailRequest record {
    Content Content;
    Destination Destination;
    string FromEmailAddress;
};

# Represents the subject of the email.
#
# + Charset - The character set for the content. Because of the constraints of the SMTP protocol, Amazon SES uses 7-bit
#             ASCII by default. If the text includes characters outside of the ASCII range, you have to specify a
#             character set. For example, you could specify UTF-8, ISO-8859-1, or Shift_JIS.
# + Data - The content of the message itself
public type Subject record {
    string Charset;
    string Data;
};

# Represents the body of the email message.
#
# + Text - The text
public type Body record {
    Subject Text;
};

# Represents the email message that you're sending.
#
# + Body - The body of the message. You can specify an HTML version of the message, a text-only version of the message,
#          or both.
# + Subject - The subject line of the email
public type Message record {
    Body Body;
    Subject Subject;
};

# Represents the email message content.
#
# + Simple - The simple message content
public type Content record {
    Message Simple;
};

# Represents an object that describes the recipients for an email.
#
# + BccAddresses - An array that contains the email addresses of the "BCC" (blind carbon copy) recipients for the email
# + CcAddresses - An array that contains the email addresses of the "CC" (carbon copy) recipients for the email
# + ToAddresses - An array that contains the email addresses of the "To" recipients for the email
public type Destination record {
    string[] BccAddresses?;
    string[] CcAddresses?;
    string[] ToAddresses?;
};

# Represents the response after sent an email.
#
# + MessageId - A unique identiﬁer for the message that is generated when the message is accepted
public type MessageSentResponse record {
    string MessageId?;
};

# Represents the request payload to send custom veriﬁcation email.
#
# + EmailAddress - The email address to verify
# + TemplateName - The name of the custom veriﬁcation email template to use when sending the veriﬁcation email
# + ConfigurationSetName - Name of a conﬁguration set to use when sending the veriﬁcation email 
public type CustomVeriﬁcationEmailRequest record {
    string EmailAddress;
    string TemplateName;
    string ConfigurationSetName?;
};

# Represents an object that contains the body of the message. You can specify a template message.
#
# + Template - The template to use for the bulk email message
public type BulkEmailContent record {
    Template Template?;
};

# Represents the bulk email entry.
#
# + Destination - Represents the destination of the message, consisting of To:, CC:, and BCC: ﬁelds
# + ReplacementEmailContent - The ReplacementEmailContent associated with a BulkEmailEntry
# + ReplacementTags - A list of tags, in the form of name/value pairs, to apply to an email that you send using the 
#                     SendBulkTemplatedEmail operation
public type BulkEmailEntry record {
    Destination Destination;
    ReplacementEmailContent ReplacementEmailContent?;
    MessageTag[] ReplacementTags?;
};

# Represents the result of the SendBulkEmail operation of each speciﬁed BulkEmailEntry.
#
# + Error - A description of an error that prevented a message being sent using the SendBulkTemplatedEmail operation
# + MessageId - The unique message identiﬁer returned from the SendBulkTemplatedEmail operation
# + Status - The status of a message sent using the SendBulkTemplatedEmail operation
public type BulkEmailEntryResult record {
    string? Error?;
    string? MessageId?;
    string? Status?;
};

# Represents the request payload to send bulk email
#
# + BulkEmailEntries - The list of bulk email entry objects
# + ConfigurationSetName - The name of the conﬁguration set to use when sending the email
# + DefaultContent - An object that contains the body of the message. You can specify a template message.
# + DefaultEmailTags - A list of tags, in the form of name/value pairs, to apply to an email that you send using the 
#                      SendEmail operation
# + FeedbackForwardingEmailAddress - The address that you want bounce and complaint notiﬁcations to be sent to
# + FeedbackForwardingEmailAddressIdentityArn - This parameter is used only for sending authorization. It is the ARN of
#                                               the identity that is associated with the sending authorization policy
#                                               that permits you to use the email address speciﬁed in the 
#                                               FeedbackForwardingEmailAddress parameter.
# + FromEmailAddress - The email address to use as the "From" address for the email. The address that you specify has
#                      to be veriﬁed.
# + FromEmailAddressIdentityArn - This parameter is used only for sending authorization. It is the ARN of the identity
#                                 that is associated with the sending authorization policy that permits you to use the
#                                 email address speciﬁed in the FromEmailAddress parameter.
# + ReplyToAddresses - The "Reply-to" email addresses for the message. When the recipient replies to the message, each
#                      Reply-to address receives the reply.
public type BulkEmailRequest record {
    BulkEmailEntry[] BulkEmailEntries;
    string ConfigurationSetName?;
    BulkEmailContent DefaultContent;
    MessageTag[] DefaultEmailTags?;
    string FeedbackForwardingEmailAddress?;
    string FeedbackForwardingEmailAddressIdentityArn?;
    string FromEmailAddress?;
    string FromEmailAddressIdentityArn?;
    string[] ReplyToAddresses?;
};

# Represents an object that deﬁnes the email template to use for an email message, and the values to use for any
# message variables in that template.
#
# + TemplateArn - The Amazon Resource Name (ARN) of the template  
# + TemplateData - An object that deﬁnes the values to use for message variables in the template
# + TemplateName - The name of the template
public type Template record {
    string TemplateArn?;
    string TemplateData?;
    string TemplateName?;
};

# Represents the name and value of a tag that you apply to an email.
#
# + Name - The name of the message tag
# + Value - The value of the message tag
public type MessageTag record {
    string Name;
    string Value;
};

# Represents the response after sent bulk email.
#
# + BulkEmailEntryResults - The array of BulkEmailEntryResult objects
public type BulkEmailResponse record {
    BulkEmailEntryResult[]? BulkEmailEntryResults?;
};

# Represents the ReplaceEmailContent object to be used for a speciﬁc BulkEmailEntry.
#
# + ReplacementTemplate - The ReplacementTemplate associated with ReplacementEmailContent
public type ReplacementEmailContent record {
    ReplacementTemplate ReplacementTemplate?;
};

# Represents an object which contains ReplacementTemplateData to be used for a speciﬁc BulkEmailEntry.
#
# + ReplacementTemplateData - A list of replacement values to apply to the template. This parameter is a JSON object,
#                             typically consisting of key-value pairs in which the keys correspond to replacement tags
#                             in the email template.
public type ReplacementTemplate record {
    string ReplacementTemplateData?;
};
