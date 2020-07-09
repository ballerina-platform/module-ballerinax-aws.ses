// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

// import ballerina/io;
// import ballerina/lang.'xml as xmllib;

xmlns "http://ses.amazonaws.com/doc/2010-12-01/" as ns;

function xmlToEmailDestinationStatuses(xml response) returns EmailDestinationStatus[]|Error {
    xml msgStatus = response/<ns:SendBulkTemplatedEmailResult>/<ns:Status>;
    EmailDestinationStatus[] emailDestinationStatuses = [];
        int i = 0;
        foreach var b in msgStatus.elements() {
            if (b is xml) {
                EmailDestinationStatus|error emailDestinationStatus = xmlToEmailDestinationStatus(b.elements());
                if (emailDestinationStatus is EmailDestinationStatus) {
                    emailDestinationStatuses[i] = emailDestinationStatus;
                } else {
                    return Error("Error while generating email destination status.", emailDestinationStatus);
                }
                i = i + 1;
            }
        }
        return emailDestinationStatuses;
}

function xmlToEmailDestinationStatus(xml message) returns EmailDestinationStatus|error {
    EmailDestinationStatus emailDestinationStatus = {
        errorDescription: (message/<ns:member>/<ns:Error>/*).toString(),
        messageId:(message/<ns:member>/<ns:MessageId>/*).toString(),
        status:(message/<ns:member>/<ns:Status>/*).toString()
    };
    return emailDestinationStatus;
}
