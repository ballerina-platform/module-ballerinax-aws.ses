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

import ballerina/io;
import ballerinax/aws.ses;

configurable string accessKeyId = ?;
configurable string secretAccessKey = ?;
configurable string region = ?;

// The "From" address has to be a verified identity in this account and region.
configurable string senderEmail = ?;
configurable string recipientEmail = ?;

// Sends an order confirmation three ways: as a one-off HTML message, through a stored template, and as a bulk send
// that reuses the template for many recipients without rebuilding its body each time.
public function main() returns error? {
    ses:Client ses = check new ({
        auth: {accessKeyId, secretAccessKey},
        region
    });

    // A one-off message. Supplying both an HTML and a text body lets each recipient's mail client pick the part it
    // can display.
    ses:SendEmailOutput direct = check ses->sendEmail({
        fromEmailAddress: senderEmail,
        destination: {toAddresses: [recipientEmail]},
        replyToAddresses: [senderEmail],
        content: {
            simple: {
                subject: {data: "Your order has shipped", charset: "UTF-8"},
                body: {
                    html: {
                        data: string `<html><body><h1>On its way</h1>
                            <p>Your order left our warehouse today.</p></body></html>`,
                        charset: "UTF-8"
                    },
                    text: {data: "On its way. Your order left our warehouse today.", charset: "UTF-8"}
                }
            }
        }
    });
    io:println("Sent the direct message: ", direct.messageId ?: "<no message id>");

    // A stored template, whose placeholders are filled per recipient.
    string templateName = "OrderShipped";
    check createTemplateIfAbsent(ses, templateName);

    ses:SendEmailOutput templated = check ses->sendEmail({
        fromEmailAddress: senderEmail,
        destination: {toAddresses: [recipientEmail]},
        content: {
            template: {
                templateName,
                templateData: {"name": "Alex", "orderId": "SO-4417"}.toJsonString()
            }
        }
    });
    io:println("Sent the templated message: ", templated.messageId ?: "<no message id>");

    // The same template sent to many recipients in one call. Each entry reports its own outcome, so a partial
    // failure is visible per recipient rather than failing the whole call.
    ses:SendBulkEmailOutput bulk = check ses->sendBulkEmail({
        fromEmailAddress: senderEmail,
        defaultContent: {template: {templateName, templateData: {"name": "there", "orderId": "unknown"}.toJsonString()}},
        bulkEmailEntries: [
            {
                destination: {toAddresses: [recipientEmail]},
                replacementEmailContent: {
                    replacementTemplate: {
                        replacementTemplateData: {"name": "Sam", "orderId": "SO-4418"}.toJsonString()
                    }
                }
            }
        ]
    });
    foreach ses:BulkEmailEntryResult result in bulk.bulkEmailEntryResults {
        io:println("Bulk entry ", result.status ?: "<no status>", ": ", result.messageId ?: result?.'error ?: "");
    }

    check ses.close();
}

// Creates the template on the first run, and leaves it alone afterwards.
function createTemplateIfAbsent(ses:Client ses, string templateName) returns error? {
    ses:EmailTemplateDetails|ses:Error existing = ses->getEmailTemplate(templateName);
    if existing is ses:EmailTemplateDetails {
        return;
    }
    check ses->createEmailTemplate({
        templateName,
        templateContent: {
            subject: "Order {{orderId}} has shipped",
            html: "<html><body><p>Hello {{name}}, order {{orderId}} is on its way.</p></body></html>",
            text: "Hello {{name}}, order {{orderId}} is on its way."
        }
    });
    io:println("Created the template: ", templateName);
}
