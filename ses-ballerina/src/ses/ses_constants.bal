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

const SES_SERVICE_NAME = "email";
const SES_SMTP_SERVICE_NAME = "email-smtp";

const AMAZON_HOST = "amazonaws.com";
const ISO8601_BASIC_DATE_FORMAT = "yyyyMMdd'T'HHmmss'Z'";
const SHORT_DATE_FORMAT = "yyyyMMdd";
const UTF_8 = "UTF-8";
const AWS4 = "AWS4";
const POST = "POST";

const string STATUS_CODE = "status code";
const string COLON_SYMBOL = ":";
const string SEMICOLON_SYMBOL = ";";
const string WHITE_SPACE = " ";
const string MESSAGE = "message";
const string SES_VERSION = "2010-12-01";
const string ACTION_CREATE_TEMPLATE = "CreateTemplate";
const string ACTION_SEND_BULK_TEMPLATED_EMAIL = "SendBulkTemplatedEmail";
const string ACTION_VERIFY_EMAIL_IDENTITY = "VerifyEmailIdentity";

const string TEMPLATE_PARAM_REPLACEMENT_TEMPLATE_DATA = "replacementTemplateData";
const string TEMPLATE_PARAM_REPLACEMENT_TAGS = "replacementTags";
const string TEMPLATE_PARAM_DESTINATION = "destination";

const string PAYLOAD_PARAM_ACTION = "Action";
const string PAYLOAD_PARAM_VERSION = "Version";
const string PAYLOAD_PARAM_SOURCE = "Source";
const string PAYLOAD_PARAM_TEMPLATE = "Template";
const string PAYLOAD_PARAM_RETURN_PATH = "ReturnPath";
const string PAYLOAD_PARAM_DEFAULT_TEMPLATE_DATA = "DefaultTemplateData";
const string PAYLOAD_PARAM_EMAIL_ADDRESS = "EmailAddress";
