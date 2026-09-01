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

// Every Amazon SES list operation pages the same way: the request carries an optional continuation token, and the
// response carries the next one until the last page, which omits it. That shape is captured once in `Page`, and each
// iterator below differs only in the element type it yields.

# One page of a paginated list operation.
type Page record {|
    # The items on this page
    anydata[] items;
    # The continuation token of the following page, absent on the last page
    string? nextToken;
|};

# Fetches a single page of a list operation, starting at the given continuation token.
type PageFetcher isolated function (string? nextToken) returns Page|Error;

# Walks the pages of a list operation, fetching the next one only once the current one is exhausted.
class PageWalker {
    private final PageFetcher fetchPage;
    private anydata[] currentPage = [];
    private int index = 0;
    private string? nextToken = ();
    private boolean exhausted = false;

    isolated function init(PageFetcher fetchPage) {
        self.fetchPage = fetchPage;
    }

    # Returns the next item of the result set, or `()` once every page has been consumed.
    #
    # + return - The next item, `()` at the end of the result set, or an `Error` if a page cannot be fetched
    isolated function nextItem() returns anydata|Error? {
        // Keep fetching until a page yields an item or the result set is exhausted. A page can legitimately come
        // back empty while still carrying a continuation token, so the emptiness of one page must not be mistaken
        // for the end of the result set — nor may an empty page be indexed into.
        while self.index >= self.currentPage.length() {
            if self.exhausted {
                return;
            }
            Page page = check self.fetchPage(self.nextToken);
            self.currentPage = page.items;
            self.index = 0;
            self.nextToken = page.nextToken;
            // An absent continuation token means this was the final page.
            self.exhausted = page.nextToken !is string;
        }
        anydata item = self.currentPage[self.index];
        self.index += 1;
        return item;
    }
}

# Iterates over every contact list of the result set.
class ContactListIterator {
    private final PageWalker walker;

    isolated function init(PageFetcher fetchPage) {
        self.walker = new (fetchPage);
    }

    public isolated function next() returns record {|ContactList value;|}|Error? {
        anydata? item = check self.walker.nextItem();
        if item is () {
            return;
        }
        ContactList|error value = item.ensureType();
        if value is error {
            return error ResponseHandlingError(
                    string `Error occurred while processing the ListContactLists response: ${value.message()}`, value);
        }
        return {value};
    }
}

# Iterates over every contact of the result set.
class ContactIterator {
    private final PageWalker walker;

    isolated function init(PageFetcher fetchPage) {
        self.walker = new (fetchPage);
    }

    public isolated function next() returns record {|Contact value;|}|Error? {
        anydata? item = check self.walker.nextItem();
        if item is () {
            return;
        }
        Contact|error value = item.ensureType();
        if value is error {
            return error ResponseHandlingError(
                    string `Error occurred while processing the ListContacts response: ${value.message()}`, value);
        }
        return {value};
    }
}

# Iterates over every email template of the result set.
class EmailTemplateIterator {
    private final PageWalker walker;

    isolated function init(PageFetcher fetchPage) {
        self.walker = new (fetchPage);
    }

    public isolated function next() returns record {|EmailTemplateMetadata value;|}|Error? {
        anydata? item = check self.walker.nextItem();
        if item is () {
            return;
        }
        EmailTemplateMetadata|error value = item.ensureType();
        if value is error {
            return error ResponseHandlingError(
                    string `Error occurred while processing the ListEmailTemplates response: ${value.message()}`,
                    value);
        }
        return {value};
    }
}

# Iterates over every custom verification email template of the result set.
class CustomVerificationEmailTemplateIterator {
    private final PageWalker walker;

    isolated function init(PageFetcher fetchPage) {
        self.walker = new (fetchPage);
    }

    public isolated function next() returns record {|CustomVerificationEmailTemplateMetadata value;|}|Error? {
        anydata? item = check self.walker.nextItem();
        if item is () {
            return;
        }
        CustomVerificationEmailTemplateMetadata|error value = item.ensureType();
        if value is error {
            return error ResponseHandlingError(
                    string `Error occurred while processing the ListCustomVerificationEmailTemplates response: ${
                    value.message()}`, value);
        }
        return {value};
    }
}

# Iterates over every email identity of the result set.
class EmailIdentityIterator {
    private final PageWalker walker;

    isolated function init(PageFetcher fetchPage) {
        self.walker = new (fetchPage);
    }

    public isolated function next() returns record {|IdentityInfo value;|}|Error? {
        anydata? item = check self.walker.nextItem();
        if item is () {
            return;
        }
        IdentityInfo|error value = item.ensureType();
        if value is error {
            return error ResponseHandlingError(
                    string `Error occurred while processing the ListEmailIdentities response: ${value.message()}`,
                    value);
        }
        return {value};
    }
}
