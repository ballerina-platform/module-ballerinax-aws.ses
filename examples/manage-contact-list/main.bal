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
import ballerinax/aws.auth;
import ballerinax/aws.ses;

configurable string region = ?;
configurable string senderEmail = ?;

// Runs a newsletter list end to end: create the list with a topic, subscribe a few contacts, send only to the ones
// opted in, and let the unsubscribe link maintain the list.
//
// Credentials come from the default AWS provider chain rather than from configuration, so this runs unchanged on a
// developer machine with `~/.aws/credentials`, and on EC2, ECS, and EKS with an instance or task role.
public function main() returns error? {
    ses:Client ses = check new ({
        auth: auth:DEFAULT_CREDENTIALS,
        region
    });

    string listName = "ProductNewsletter";
    string topicName = "product-updates";

    check createListIfAbsent(ses, listName, topicName);

    // Subscribe two readers, one opted in and one opted out.
    check upsertContact(ses, listName, "reader.one@example.com", topicName, ses:OPT_IN);
    check upsertContact(ses, listName, "reader.two@example.com", topicName, ses:OPT_OUT);

    // Only the opted-in contacts should receive the newsletter. The filter is applied by the service, so an
    // opted-out reader never reaches this loop.
    stream<ses:Contact, ses:Error?> subscribers = ses->listContacts(listName, {
        filter: {
            filteredStatus: ses:OPT_IN,
            topicFilter: {topicName, useDefaultIfPreferenceUnavailable: true}
        },
        pageSize: 50
    });

    int sent = 0;
    check from ses:Contact subscriber in subscribers
        do {
            string address = subscriber.emailAddress ?: "";
            if address == "" {
                return;
            }
            ses:SendEmailOutput result = check ses->sendEmail({
                fromEmailAddress: senderEmail,
                destination: {toAddresses: [address]},
                // Naming the list and topic puts a working unsubscribe link in the message, and a recipient who
                // uses it is opted out on this list without any further code.
                listManagementOptions: {contactListName: listName, topicName},
                content: {
                    simple: {
                        subject: {data: "This month in product", charset: "UTF-8"},
                        body: {
                            html: {
                                data: "<html><body><p>Here is what shipped this month.</p></body></html>",
                                charset: "UTF-8"
                            }
                        }
                    }
                }
            });
            sent += 1;
            io:println("Sent to ", address, ": ", result.messageId ?: "<no message id>");
        };
    io:println("Sent the newsletter to ", sent, " subscriber(s).");

    check ses.close();
}

// Creates the contact list on the first run, and leaves it alone afterwards.
function createListIfAbsent(ses:Client ses, string listName, string topicName) returns error? {
    ses:ContactListDetails|ses:Error existing = ses->getContactList(listName);
    if existing is ses:ContactListDetails {
        io:println("Using the existing contact list: ", listName);
        return;
    }
    check ses->createContactList({
        contactListName: listName,
        description: "Monthly product newsletter",
        topics: [
            {
                topicName,
                displayName: "Product updates",
                description: "News about product releases",
                // A contact who has expressed no preference is treated as opted out.
                defaultSubscriptionStatus: ses:OPT_OUT
            }
        ]
    });
    io:println("Created the contact list: ", listName);
}

// Adds a contact, or updates their topic preference when they are already on the list.
function upsertContact(ses:Client ses, string listName, string emailAddress, string topicName,
        ses:SubscriptionStatus status) returns error? {
    ses:TopicPreference[] preferences = [{topicName, subscriptionStatus: status}];
    ses:Error? created = ses->createContact(listName, {emailAddress, topicPreferences: preferences});
    if created is () {
        io:println("Subscribed ", emailAddress, " as ", status);
        return;
    }
    // Already on the list: update the preference instead.
    check ses->updateContact(listName, emailAddress, {topicPreferences: preferences});
    io:println("Updated ", emailAddress, " to ", status);
}
