// Copyright (c) 2021, WSO2 LLC. (http://www.wso2.com).
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

import ballerina/data.jsondata;

// The endpoint prefix of the Amazon SES service, used to resolve the endpoint
// URL (e.g. `email.us-east-1.amazonaws.com`).
const string SERVICE_NAME = "email";

// The SigV4 signing name of the Amazon SES service, which differs from the
// endpoint prefix above.
const string SIGNING_SERVICE_NAME = "ses";

// Base path of the Amazon SES API v2.
const string BASE_PATH = "/v2/email";

const string CONTACT_LISTS_PATH = string `${BASE_PATH}/contact-lists`;
const string TEMPLATES_PATH = string `${BASE_PATH}/templates`;
const string CUSTOM_VERIFICATION_TEMPLATES_PATH = string `${BASE_PATH}/custom-verification-email-templates`;
const string IDENTITIES_PATH = string `${BASE_PATH}/identities`;
const string OUTBOUND_EMAILS_PATH = string `${BASE_PATH}/outbound-emails`;
const string OUTBOUND_CUSTOM_VERIFICATION_EMAILS_PATH = string `${BASE_PATH}/outbound-custom-verification-emails`;
const string OUTBOUND_BULK_EMAILS_PATH = string `${BASE_PATH}/outbound-bulk-emails`;

const string CONTACTS_SEGMENT = "contacts";
const string LIST_SEGMENT = "list";

const string HTTP_GET = "GET";
const string HTTP_POST = "POST";
const string HTTP_PUT = "PUT";
const string HTTP_DELETE = "DELETE";

// Amazon SES API v2 is a JSON REST API.
const string JSON_CONTENT_TYPE = "application/json";

const string CONTENT_TYPE_HEADER = "content-type";
const string REQUEST_ID_HEADER = "x-amzn-RequestId";

// Amazon SES speaks the `restJson1` protocol, which reports the error's shape name in this header, falling back to
// a `__type` or a `code` field in the body, and its description in a `message` or a `Message` field.
const string ERROR_TYPE_HEADER = "x-amzn-errortype";
const string TYPE_FIELD = "__type";
const string CODE_FIELD = "code";
const string MESSAGE_FIELD = "message";
const string MESSAGE_FIELD_LEGACY = "Message";

// Pagination parameters, which every SES list operation accepts as query
// parameters, except `ListContacts`, which takes them in the request body.
const string NEXT_TOKEN_PARAM = "NextToken";
const string PAGE_SIZE_PARAM = "PageSize";

// Projecting nil onto an absent optional field keeps the response records free of nilable types,
// which would otherwise have to spread to every optional field.
final jsondata:Options & readonly PARSE_OPTIONS = {allowDataProjection: {nilAsOptionalField: true}};

// The characters RFC 3986 calls unreserved. Everything else in a path segment
// or a query parameter is percent-encoded before it goes on the wire.
const string UNRESERVED_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~";
