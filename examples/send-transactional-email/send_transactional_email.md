# Send a transactional email

This example sends an order confirmation three ways, which together cover the shapes most applications need:

1. **A one-off message** — an HTML body with a plain-text alternative, assembled by Amazon SES from the subject and
   body given in the request.
2. **A stored template** — created on the first run, then referenced by name with per-message values substituted into
   its placeholders.
3. **A bulk send** — the same template delivered to many recipients in one call, each with its own replacement
   values, and each reporting its own outcome so a partial failure is visible per recipient.

## Prerequisites

1. An AWS account with Amazon SES, and an IAM user with `ses:SendEmail`, `ses:SendBulkEmail`, `ses:GetEmailTemplate`,
   and `ses:CreateEmailTemplate` permissions. See the [setup guide](../../ballerina/README.md#setup-guide).
2. A **verified email identity** to send from. A new account is in the Amazon SES sandbox, where the recipient has to
   be verified too — verify both addresses, or request production access.

## Configuration

Create a `Config.toml` in the example directory:

```toml
accessKeyId = "<AWS_ACCESS_KEY_ID>"
secretAccessKey = "<AWS_SECRET_ACCESS_KEY>"
region = "us-east-1"
senderEmail = "<VERIFIED_SENDER_ADDRESS>"
recipientEmail = "<RECIPIENT_ADDRESS>"
```

## Run the example

```bash
bal run
```
