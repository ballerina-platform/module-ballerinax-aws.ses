# Manage a contact list

This example runs a newsletter list end to end:

1. Creates a contact list with a topic, whose default subscription status is `OPT_OUT` — so a contact who has
   expressed no preference is not mailed.
2. Subscribes two contacts, one opted in to the topic and one opted out.
3. Lists only the opted-in contacts. The filter is applied by Amazon SES, so an opted-out reader never reaches the
   loop, and the auto-paginating stream fetches each page as the previous one is consumed.
4. Sends the newsletter with `listManagementOptions` set, which puts a working unsubscribe link in the message. A
   recipient who uses it is opted out on this list with no further code.

Credentials come from the **default AWS credential provider chain** rather than from configuration, so the example
runs unchanged on a developer machine with `~/.aws/credentials` and on EC2, ECS, and EKS with an instance or task
role.

## Prerequisites

1. An AWS account with Amazon SES, and credentials resolvable from the environment with `ses:SendEmail` and the
   contact list permissions. See the [setup guide](../../ballerina/README.md#setup-guide).
2. A **verified email identity** to send from.

## Configuration

Create a `Config.toml` in the example directory:

```toml
region = "us-east-1"
senderEmail = "<VERIFIED_SENDER_ADDRESS>"
```

Credentials are not configured here — make them available to the default provider chain, for example by running
`aws configure`, by exporting `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`, or by attaching an instance or task
role.

## Run the example

```bash
bal run
```
