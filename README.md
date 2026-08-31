# Ballerina Amazon SES Connector

[![Build](https://github.com/ballerina-platform/module-ballerinax-aws.ses/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-aws.ses/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/ballerina-platform/module-ballerinax-aws.ses/branch/master/graph/badge.svg)](https://codecov.io/gh/ballerina-platform/module-ballerinax-aws.ses)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-aws.ses.svg)](https://github.com/ballerina-platform/module-ballerinax-aws.ses/commits/master)
[![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-library/module/aws.ses.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-library/labels/module%2Faws.ses)

## Overview

The `ballerinax/aws.ses` package offers APIs to connect and interact with the [Amazon SES API v2](https://docs.aws.amazon.com/ses/latest/APIReference-V2/Welcome.html) endpoints, covering email sending, email identities, contact lists and contacts, email templates, and custom verification email templates.

## Setup guide

### Verify an email identity

Amazon SES only sends from an address or domain you have proved you own. In the [Amazon SES console](https://console.aws.amazon.com/ses/), open **Identities** > **Create identity** and verify either:

| Identity type | What to verify | When to use it |
|---|---|---|
| Email address | A single address, confirmed by following a link Amazon SES emails to it | Getting started, and low-volume senders |
| Domain | A domain, confirmed by adding the DKIM CNAME records Amazon SES returns to your DNS | Production sending, and sending from many addresses at one domain |

This connector can do the same thing: `createEmailIdentity` starts the verification and returns the DKIM tokens to add to your DNS.

> **Note:** A new account is in the Amazon SES **sandbox**, where mail can only be sent to verified addresses and the sending quota is low. Request production access from **Account dashboard** > **Request production access** before sending to arbitrary recipients.

### Obtain IAM user credentials

To create an IAM user and generate an access key, follow the [obtaining IAM user credentials](https://central.ballerina.io/ballerinax/aws/latest#obtaining-iam-user-credentials) guide.

Attach the Amazon SES permissions your application needs. Sending mail and reading the account's identities, lists, and templates requires:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ses:SendEmail",
                "ses:SendBulkEmail",
                "ses:SendCustomVerificationEmail"
            ],
            "Resource": "arn:aws:ses:<REGION>:<ACCOUNT_ID>:identity/<VERIFIED_IDENTITY>"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ses:GetEmailIdentity",
                "ses:ListEmailIdentities",
                "ses:GetContactList",
                "ses:ListContactLists",
                "ses:ListContacts",
                "ses:GetContact",
                "ses:GetEmailTemplate",
                "ses:ListEmailTemplates",
                "ses:GetCustomVerificationEmailTemplate",
                "ses:ListCustomVerificationEmailTemplates"
            ],
            "Resource": "*"
        }
    ]
}
```

> **Note:** The list and template actions cannot be scoped to an identity ARN — AWS denies them when the resource is anything other than `*`. Add the matching `Create*`, `Update*`, and `Delete*` actions only if your application manages these resources rather than just reading them.

## Quickstart

To use the `aws.ses` connector in your Ballerina project, modify the `.bal` file as follows:

### Step 1: Import the connector

Import `ballerinax/aws` & `ballerinax/aws.ses` packages into your Ballerina project.

```ballerina
import ballerinax/aws;
import ballerinax/aws.ses;
```

### Step 2: Instantiate a new connector

Create a new `ses:Client` by providing the region and authentication configurations.

```ballerina
configurable string accessKeyId = ?;
configurable string secretAccessKey = ?;

ses:Client ses = check new ({
    region: aws:US_EAST_1,
    auth: {
        accessKeyId,
        secretAccessKey
    }
});
```

### Step 3: Invoke the connector operation

Send an email from a verified identity, then list the contacts already on the `Newsletter` contact list — `sendEmail` does not add its recipient to a list.

```ballerina
import ballerina/io;

public function main() returns error? {
    // The "From" address has to be a verified identity in this account and region. Supplying both an HTML and a
    // text body lets each recipient's mail client pick the part it can display.
    ses:SendEmailOutput result = check ses->sendEmail({
        fromEmailAddress: "sender@example.com",
        destination: {toAddresses: ["recipient@example.com"]},
        content: {
            simple: {
                subject: {data: "Your order has shipped", charset: "UTF-8"},
                body: {
                    html: {data: "<html><body><p>It is on its way.</p></body></html>", charset: "UTF-8"},
                    text: {data: "It is on its way.", charset: "UTF-8"}
                }
            }
        }
    });
    io:println("Message accepted: ", result.messageId);

    // Every list operation returns an auto-paginating stream; the next page is fetched only once this one is
    // consumed.
    stream<ses:Contact, ses:Error?> contacts = ses->listContacts("Newsletter", {
        filter: {filteredStatus: ses:OPT_IN}
    });

    check from ses:Contact contact in contacts
        do {
            io:println(contact.emailAddress);
        };

    // Releases the credential provider's refresh threads and any STS/SSO connections it opened.
    check ses.close();
}
```

### Step 4: Run the Ballerina application

Use the following command to compile and run the Ballerina program.

```bash
bal run
```

### Alternative authentication methods

#### Profile-based authentication

You can use AWS profile-based authentication as an alternative to static credentials.

```ballerina
ses:Client ses = check new ({
    region: aws:US_EAST_1,
    auth: {
        profileName: "myAwsProfile",
        credentialsFilePath: "/path/to/custom/credentials"
    }
});
```

#### Default credential provider chain

Resolves credentials automatically from the AWS SDK's default chain. This is the recommended option when the application runs on AWS infrastructure, since no long-lived credentials need to be stored with the application — and the only supported one where long-term access keys are unavailable (EC2 instance roles, ECS task roles, EKS Pod Identity/IRSA).

```ballerina
import ballerinax/aws.auth;

ses:Client ses = check new ({
    region: aws:US_EAST_1,
    auth: auth:DEFAULT_CREDENTIALS
});
```

> **Note:** Beyond the three options above, the `auth` field also accepts `auth:AssumeRoleConfig` (STS assume-role), `auth:WebIdentityConfig` (web identity / OIDC), `auth:SsoAuthConfig` (IAM Identity Center), and `auth:ProcessAuthConfig` (external credential process). See the [`Ballerina AWS`](https://central.ballerina.io/ballerinax/aws/latest) documentation for details.

## Examples

The `aws.ses` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-aws.ses/tree/master/examples).

1. [Send a transactional email](https://github.com/ballerina-platform/module-ballerinax-aws.ses/tree/master/examples/send-transactional-email)
   This example shows how to send an order confirmation as a one-off HTML message, through a stored template, and as a bulk send with per-recipient replacement values.

2. [Manage a contact list](https://github.com/ballerina-platform/module-ballerinax-aws.ses/tree/master/examples/manage-contact-list)
   This example shows how to run a newsletter list end to end: create the list and its topic, subscribe contacts, send only to the ones opted in, and let the unsubscribe link maintain the list. It runs on the default credential provider chain, so it works unchanged on EC2, ECS, and EKS.
## Build from the source

### Prerequisites

1. Download and install Java SE Development Kit (JDK) version 21. You can download it from either of the following sources:

    * [Oracle JDK](https://www.oracle.com/java/technologies/downloads/)
    * [OpenJDK](https://adoptium.net/)

   > **Note:** After installation, remember to set the `JAVA_HOME` environment variable to the directory where JDK was installed.

2. Download and install [Ballerina Swan Lake](https://ballerina.io/).

3. Download and install [Docker](https://www.docker.com/get-started).

   > **Note**: Ensure that the Docker daemon is running before executing any tests.

### Build options

Execute the commands below to build from the source.

1. To build the package:
   ```bash
   ./gradlew clean build
   ```

2. To run the tests:
   ```bash
   ./gradlew clean test
   ```

3. To build the without the tests:
   ```bash
   ./gradlew clean build -x test
   ```

4. To debug package with a remote debugger:
   ```bash
   ./gradlew clean build -Pdebug=<port>
   ```

5. To debug with the Ballerina language:
   ```bash
   ./gradlew clean build -PbalJavaDebug=<port>
   ```

6. Publish the generated artifacts to the local Ballerina Central repository:
    ```bash
    ./gradlew clean build -PpublishToLocalCentral=true
    ```

7. Publish the generated artifacts to the Ballerina Central repository:
   ```bash
   ./gradlew clean build -PpublishToCentral=true
   ```

## Contribute to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links

* For more information go to the [`aws.ses` package](https://central.ballerina.io/ballerinax/aws.ses/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
