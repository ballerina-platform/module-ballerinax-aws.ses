# Change Log
This file contains all the notable changes done to the Ballerina AWS SES package through the releases.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

This release revamps the connector's authentication and region configuration to use the shared
[`ballerinax/aws`](https://github.com/ballerina-platform/module-ballerinax-aws) package, so that all AWS
connectors share a single, consistent credential model. It also fixes the defects found in the shipped
operations — a `sendEmail` that could only send plain text, list operations that could not page, and six
API names that could not be typed on a standard keyboard.
([Revamp Connector Authentication Flow](https://github.com/wso2-enterprise/integration-engineering/issues/2105))

It contains breaking changes. See the "Migrating from 2.x" section below.

### Changed

- **[Breaking]** Credentials are now supplied through a single `ConnectionConfig.auth` field of type
  `auth:AuthConfig`, sourced from `ballerinax/aws.auth` instead of being defined locally by this package.
  In 2.x, credentials were passed as `awsCredentials`, which accepted static keys only. Every 2.x
  credential source remains supported, with six new ones added.
- **[Breaking]** The `ConnectionConfig.region` field type changed from `string` to `aws:Region|string`, and
  it is now required rather than defaulting to `us-east-1` — a default region silently sent mail from the
  wrong region's identities. The type change is a widening, so plain region strings continue to work.
- **[Breaking]** Record fields are now named in camelCase, with the Amazon SES wire name declared per field
  through `@jsondata:Name`. In 2.x the fields were spelled as the wire payload (`ContactListName`), which is
  not idiomatic Ballerina and gave no place to record the wire mapping.
- **[Breaking]** Every list operation returns an auto-paginating `stream<T, Error?>` rather than a single
  page record. In 2.x the page's `NextToken` was returned but could not be passed back, so no result beyond
  the first page was reachable.
- **[Breaking]** Operations now return the module's own `Error` type instead of the generic `error`.
- **[Breaking]** Fields that the API either returns or omits are now optional and non-nilable (`string s?`).
  In 2.x many were both optional and nilable (`string? s?`), though the API never returns null.
- Temporary credentials (STS assume-role, SSO, container and instance profiles) are now refreshed
  transparently by the credential provider, instead of the connector holding a single set of keys
  resolved at initialization time.
- The package now requires Ballerina distribution `2201.12.0` (was `2201.3.0`).

### Removed

- **[Breaking]** The `ConnectionConfig.awsCredentials` field, and the `AwsCredentials` and
  `AwsTemporaryCredentials` records it accepted, have been removed in favour of `ConnectionConfig.auth`.
- **[Breaking]** The page records `ContactLists`, `Contacts`, `EmailTemplateListPage`,
  `CustomVerificationTempListPage`, and `EmailIdentitiesListPage` have been removed; the list operations
  return streams.
- **[Breaking]** `EmailRequest`, `CustomVeriﬁcationEmailRequest`, `BulkEmailRequest`,
  `ContactListCreationRequest`, `ContactCreationRequest`, `ContactUpdateRequest`,
  `EmailIdentityCreationRequest`, `EmailTemplateUpdateRequest`, `CustomVeriﬁcationEmailUpdate`, and
  `CustomVeriﬁcationEmailTemplate` have been replaced by the `…Input` records named after their operations.
- **[Breaking]** `Message`, `Subject`, and the 2.x `Content` record have been replaced by `SimpleEmail`,
  `Content`, and `Body`, which model the API's actual `EmailContent` shape.

### Added

- Support for six additional AWS credential sources, available through `auth:AuthConfig`:
  - `auth:ProfileAuthConfig` — credentials read from a named profile in the shared credentials file.
  - `auth:AssumeRoleConfig` — temporary credentials obtained by assuming an IAM role via AWS STS.
  - `auth:WebIdentityConfig` — web identity (OIDC) federation, including IAM Roles for Service Accounts (IRSA).
  - `auth:SsoAuthConfig` — AWS IAM Identity Center (SSO).
  - `auth:ProcessAuthConfig` — credentials sourced from an external credential process.
  - `auth:DEFAULT_CREDENTIALS` — the AWS default credential provider chain.
- A new optional `ConnectionConfig.endpoint` field of type `aws:EndpointConfig`, for selecting FIPS or
  dualstack endpoint variants and for overriding the endpoint entirely (for example, LocalStack or VPC
  interface endpoints).
- A `Client.close()` method that releases the resources held by the credential provider (background
  refresh threads and any HTTP connections opened for STS/SSO). It is a normal method rather than a
  remote method, since closing the client does not send a request to Amazon SES.
- `RequestGenerationError` and `ResponseHandlingError`, distinct subtypes of `Error`, which mark the
  failures that occur either side of the service call: credentials that cannot be resolved or a request
  that cannot be signed, and a response that cannot be read or bound.
- Typed error details. `Error` is now `distinct error<aws:ErrorDetails>`, carrying the shared record the
  `ballerinax/aws` package defines, so a failure reads the same way here as in every other Ballerina AWS
  connector.
- Pagination inputs on every list operation: a `pageSize` on each `…Input` record, and a `filter` on
  `ListContactsInput` carrying the `ListContactsFilter`/`TopicFilter` the API accepts.

### Fixed

- Temporary credentials work. 2.x accepted a `securityToken` in `AwsTemporaryCredentials` and then never
  sent it, so every request made with temporary credentials was rejected as unauthorized. The session
  token is now part of the signature.
- `listContacts` reaches the service. 2.x sent `GET /v2/email/contact-lists/{name}/contacts`, which is not
  an Amazon SES operation; `ListContacts` is `POST …/contacts/list` with the filter and pagination in the
  request body.
- Path parameters are percent-encoded. 2.x put contact list names, template names, and email addresses into
  the request path unencoded while signing a separately-encoded form, so any value containing a character
  outside the RFC 3986 unreserved set — a `+` in an email address, a space in a list name — produced a
  signature mismatch.
- `sendEmail` exposes the fields it was missing: `replyToAddresses`, `configurationSetName`, `emailTags`,
  `feedbackForwardingEmailAddress`, the identity ARNs, `listManagementOptions`, `configurationOverrides`,
  `endpointId`, and `tenantName`.
- `createEmailIdentity` exposes `dkimSigningAttributes` (BYODKIM and Easy DKIM key length),
  `configurationSetName`, and `tags`, so an identity can be onboarded in one call.
- Service failures are now reported with their status code, request id, and response body, rather than an
  error whose message was the status code and payload concatenated with a colon.

### Migrating from 2.x

Add an `import ballerinax/aws;` alongside the existing SES import, and move the credential fields under `auth`:

```ballerina
// 2.x
import ballerinax/aws.ses;

ses:ConnectionConfig config = {
    awsCredentials: {accessKeyId, secretAccessKey},
    region: "us-east-1"
};
```

```ballerina
// 3.0.0
import ballerinax/aws;
import ballerinax/aws.ses;

ses:ConnectionConfig config = {
    auth: {accessKeyId, secretAccessKey},
    region: aws:US_EAST_1
};
```

Temporary credentials move from `securityToken` to `sessionToken` inside `auth` — and, unlike in 2.x, are
actually sent:

```ballerina
// 3.0.0
ses:ConnectionConfig config = {
    auth: {accessKeyId, secretAccessKey, sessionToken},
    region: aws:US_EAST_1
};
```

Deployments that should resolve credentials from the environment rather than from hardcoded keys can now
use the default credential provider chain:

```ballerina
// 3.0.0
import ballerinax/aws.auth;

ses:ConnectionConfig config = {
    auth: auth:DEFAULT_CREDENTIALS,
    region: aws:US_EAST_1
};
```

Record fields are camelCase. The wire names are unchanged, so only the Ballerina code moves:

```ballerina
// 2.x
ses:ContactListCreationRequest request = {
    ContactListName: "Newsletter",
    Description: "Weekly product news"
};
check ses->createContactList(request);
```

```ballerina
// 3.0.0
check ses->createContactList({
    contactListName: "Newsletter",
    description: "Weekly product news"
});
```

Sending mail now goes through `EmailContent`, which is what makes an HTML body reachable:

```ballerina
// 2.x — plain text only
ses:MessageSentResponse response = check ses->sendEmail({
    FromEmailAddress: sender,
    Destination: {ToAddresses: [recipient]},
    Content: {Simple: {Subject: {Charset: "UTF-8", Data: "Hello"}, Body: {Text: {Charset: "UTF-8", Data: "Hi"}}}}
});
```

```ballerina
// 3.0.0
ses:SendEmailOutput response = check ses->sendEmail({
    fromEmailAddress: sender,
    destination: {toAddresses: [recipient]},
    content: {
        simple: {
            subject: {data: "Hello", charset: "UTF-8"},
            body: {
                html: {data: "<html><body><p>Hi</p></body></html>", charset: "UTF-8"},
                text: {data: "Hi", charset: "UTF-8"}
            }
        }
    }
});
```

List operations return streams, and now reach past the first page:

```ballerina
// 2.x — only ever the first page
ses:ContactLists lists = check ses->listContactLists();
ses:ContactList[] contactLists = <ses:ContactList[]>lists.ContactLists;
```

```ballerina
// 3.0.0
stream<ses:ContactList, ses:Error?> contactLists = ses->listContactLists();
check from ses:ContactList contactList in contactLists
    do {
        io:println(contactList.contactListName);
    };
```

The six ligature names are spelled with `fi`:

```ballerina
// 2.x
check ses->createCustomVeriﬁcationEmailTemplate(template);
```

```ballerina
// 3.0.0
check ses->createCustomVerificationEmailTemplate(template);
```

Finally, release the client when the application is finished with it, so that the credential provider's
refresh threads and any STS/SSO connections are closed:

```ballerina
// 3.0.0
check ses.close();
```

## [2.0.0] - 2023-06-01

### Changed
- Migrated to the Amazon SES API v2.

## [1.0.0] - 2021-10-01

### Added
- Initial release of the AWS SES connector.
