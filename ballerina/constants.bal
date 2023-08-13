// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

const string AWS_HOST = "amazonaws.com";
const string AWS_SERVICE = "email";
const string DEFAULT_REGION = "us-east-1";
const string URI = "/v2/email/";

const string UTF_8 = "UTF-8";
const string UNSIGNED_PAYLOAD = "UNSIGNED-PAYLOAD";
const string SERVICE_NAME = "ses";
const string HOST = "host";
const string CONTENT_TYPE = "content-type";
const string APPLICATION_JSON = "application/json";
const string X_AMZ_DATE = "x-amz-date";
const string AWS4_REQUEST = "aws4_request";
const string AWS4_HMAC_SHA256 = "AWS4-HMAC-SHA256";
const string CREDENTIAL = "Credential";
const string SIGNED_HEADER = "SignedHeaders";
const string SIGNATURE = "Signature";
const string AWS4 = "AWS4";
const string CONTACT_LISTS = "contact-lists";
const string CONTACTS = "contacts";
const string CUSTOM_VERIFICATION_EMAIL_TEMPLATES = "custom-verification-email-templates";
const string TEMPLATES = "templates";
const string IDENTITIES = "identities";
const string ISO8601_BASIC_DATE_FORMAT = "yyyyMMdd'T'HHmmss'Z'";
const string SHORT_DATE_FORMAT = "yyyyMMdd";
const string ENCODED_SLASH = "%2F";
const string SLASH = "/";
const string EMPTY_STRING = "";
const string NEW_LINE = "\n";
const string COLON = ":";
const string SEMICOLON = ";";
const string EQUAL = "=";
const string SPACE = " ";
const string COMMA = ",";
const string DOT = ".";
const string Z = "Z";

// Constants to refer the headers.
const string HEADER_CONTENT_TYPE = "Content-Type";
const string HEADER_X_AMZ_CONTENT_SHA256 = "X-Amz-Content-Sha256";
const string HEADER_X_AMZ_DATE = "X-Amz-Date";
const string HEADER_HOST = "Host";
const string HEADER_AUTHORIZATION= "Authorization";

// HTTP verbs.
const string GET = "GET";
const string POST = "POST";
const string PUT = "PUT";
const string DELETE = "DELETE";
const string TRUE = "TRUE";
const string FALSE = "FALSE";
const string HTTPS = "https://";

# Error messages.
const string EMPTY_VALUES_FOR_CREDENTIALS_ERROR_MSG = "Empty values set for accessKeyId or secretAccessKey credential";
const string DATE_STRING_GENERATION_ERROR_MSG = "Error occured while generating date strings.";
const string CANONICAL_URI_GENERATION_ERROR_MSG = "Error occured while generating canonical URI.";
const string CANONICAL_QUERY_STRING_GENERATION_ERROR_MSG = "Error occured while generating canonical query string.";

const string GENERATE_SIGNED_REQUEST_HEADERS_FAILED_MSG = "Error occurred while generating signed request headers.";

public enum SubscriptionStatus {
    OPT_IN , OPT_OUT
}

public enum IdentityType {
    EMAIL_ADDRESS, DOMAIN, MANAGED_DOMAIN
}

public enum SigningAttributesOrigin {
    AWS_SES, EXTERNAL
}

public enum DkimAttributesStatus {
    PENDING, SUCCESS, FAILED, TEMPORARY_FAILURE, NOT_STARTED
}

public enum BehaviorOnMxFailure {
    USE_DEFAULT_VALUE, REJECT_MESSAGE
}
