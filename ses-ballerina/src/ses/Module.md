## Module Overview

This module provides an implementation for sending emails via `AWS SES` API.

#### SES Client

The `ses:Client` is used to connect to the `AWS SES` server via both SMTP API and REST API to send emails behalf of the user.

First the required modules has to be imported and the configurations has to be given to create the SES Client.

```ballerina
import ballerina/log;
import ballerinax/aws.ses;

ses:Configuration configuration = {
    accessKey: "ACCESS_KEY_ID",
    secretKey: "SECRET_ACCESS_KEY",
    region: "REGION"
};

ses:Client sesClient = new(configuration);
```

A client can verify an email address to the `AWS SES` service as follows.

```ballerina 
error? response = sesClient->verifyEmailIdentity("notconfirmed@example.com");
if (response is error) {
    log:printError("Error while trying to verify email address." + response.message());
}
```

A client can send an email using SMTP API with an `Email` record. This email record is as same as the `email:Email` record in its structure. The code is as given as follows.

```ballerina 
ses:Email email = {
    to: ["to@example.com"],
    subject: "Sample AWS SES Email Subject",
    body: "Sample Email Body",
    'from: "from@example.com"
};
error? response = sesClient->sendEmail(email);
if (response is error) {
    log:printError("Error while sending an email." + response.message());
}
```

A client can create a template for emails in `AWS SES` as follows.

```ballerina 
ses:Template template = {
    templateName:"MyTemplate",
    subjectPart: "Greetings, {{name}}!",
    textPart: "Dear {{name}},\r\nYour favorite animal is {{favoriteanimal}}.",
    htmlPart: "<h1>Hello {{name}}</h1><p>Your favorite animal is {{favoriteanimal}}.</p>"
};
error? response = sesClient->createTemplate(template);
if (response is error) {
    log:printError("Error while trying to create a template." + response.message());
}
```

A client can send an email using an already created template via REST API as follows.

```ballerina 
map<string> defaultTemplateData = {name:"friend", favoriteanimal:"unknown"};
ses:BulkEmailDestination[] destinations = [
    {
        destination: {to:["to@example.com"]},
        replacementTemplateData: {name:"Donald", favoriteanimal:"duck"}
    },
    {
        destination: {cc:["cc@example.com"]},
        replacementTemplateData: {name:"Obama", favoriteanimal:"eagle"}
    }
];
string[] replyToAddresses = ["replyTo@example.com"];

ses:EmailDestinationStatus[]|ses:Error? response = sesClient->sendTemplatedEmail(defaultTemplateData, destinations,
    "from@example.com", templateName, replyToAddresses, "from@example.com");
if (response is ses:Error) {
    log:printError("Error while trying to send a templated email." + response.message());
}
```
