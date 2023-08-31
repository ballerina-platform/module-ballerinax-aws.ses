## Overview
The Ballerina AWS SES connector provides the capability to programatically handle [AWS SES](https://aws.amazon.com/ses/) related operations.

This module supports [Amazon SES REST API v2](https://docs.aws.amazon.com/ses/latest/APIReference-V2/Welcome.html).
 
## Prerequisites
Before using this connector in your Ballerina application, complete the following:
1. Create an [AWS account](https://portal.aws.amazon.com/billing/signup?nc2=h_ct&src=default&redirect_url=https%3A%2F%2Faws.amazon.com%2Fregistration-confirmation#/start)
2. [Obtain tokens](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)

## Quickstart
To use the AWS SES connector in your Ballerina application, update the .bal file as follows:

### Step 1: Import connector
Import the `ballerinax/aws.ses` module into the Ballerina project.
```ballerina
import ballerinax/aws.ses;
```

### Step 2: Create a new connector instance
Create an `ses:ConnectionConfig` with the tokens obtained, and initialize the connector with it.
```ballerina
ses:ConnectionConfig amazonSesConfig = {
    awsCredentials: {
        accessKeyId: "<ACCESS_KEY_ID>",
        secretAccessKey: "<SECRET_ACCESS_KEY>"
    }
};

ses:Client amazonSesClient = check new(amazonSesConfig);
```

### Step 3: Invoke connector operation
1. Now you can use the operations available within the connector. Note that they are in the form of remote operations.  
Following is an example on how to create an email identity using the connector.

    ```ballerina

    public function main() returns error? {
        string emailIdentity = "<Your_Email_Identity>"; // Email address or Domain can be used.

        EmailIdentityCreationRequest request = {
            EmailIdentity: emailIdentity
        };

        EmailIdentity response =  check amazonSesClient->createEmailIdentity(request);
    }
    ```
2. Use `bal run` command to compile and run the Ballerina program.

**[You can find a list of samples here](https://github.com/ballerina-platform/module-ballerinax-aws.ses/tree/master/ses/samples)**
