# Examples

The `ballerinax/aws.ses` connector provides practical examples illustrating usage in various scenarios.

1. [Send a transactional email](send-transactional-email) — sends an order confirmation as a one-off HTML message,
   through a stored template, and as a bulk send with per-recipient replacement values.
2. [Manage a contact list](manage-contact-list) — runs a newsletter list end to end: creates the list and its topic,
   subscribes contacts, sends only to the ones opted in, and lets the unsubscribe link maintain the list. Runs on the
   default AWS credential provider chain.

## Prerequisites

1. An AWS account with Amazon SES, and IAM user credentials. Follow the
   [setup guide](../ballerina/README.md#setup-guide) to create them and to attach the required permissions.
2. A **verified email identity** to send from. A new account is in the Amazon SES sandbox, where mail can only be
   sent to verified addresses — verify the recipient too, or request production access from the console.
3. A `Config.toml` in each example's directory. The keys differ per example, since one uses static credentials and
   the other the default credential provider chain:

   ```toml
   # send-transactional-email
   accessKeyId = "<AWS_ACCESS_KEY_ID>"
   secretAccessKey = "<AWS_SECRET_ACCESS_KEY>"
   region = "us-east-1"
   senderEmail = "<VERIFIED_SENDER_ADDRESS>"
   recipientEmail = "<RECIPIENT_ADDRESS>"
   ```

   ```toml
   # manage-contact-list
   region = "us-east-1"
   senderEmail = "<VERIFIED_SENDER_ADDRESS>"
   ```

## Running an example

Execute the following commands to build an example from the source:

* To build an example:

    ```bash
    bal build
    ```

* To run an example:

    ```bash
    bal run
    ```

## Building the examples with the local module

**Warning**: Because of the absence of support for reading local repositories for single Ballerina files, the
Bala of the module is manually written to the central repository as a workaround. Consequently, the bash script
may modify your local Ballerina repositories.

Execute the following commands to build all the examples against the changes you have made to the module locally:

* To build all the examples:

    ```bash
    ./build.sh build
    ```

* To run all the examples:

    ```bash
    ./build.sh run
    ```
