locals {
  function_name               = "infraweave-api-${var.environment}"
  webserver_api_function_name = "infraweave-central-api-${var.environment}"
}

resource "aws_lambda_function" "api" {
  function_name = local.function_name
  runtime       = "python3.12"
  handler       = "lambda.handler"

  tracing_config {
    mode = "Active"
  }

  timeout = 35 # Uploads for providers can take a while

  filename = "${path.module}/lambda_function_payload.zip"
  role     = "arn:aws:iam::${var.account_id}:role/infraweave_api_role-${var.environment}"

  source_code_hash = filebase64sha256("${path.module}/lambda_function_payload.zip")

  environment {
    variables = {
      DYNAMODB_EVENTS_TABLE_NAME         = var.events_table_name
      DYNAMODB_MODULES_TABLE_NAME        = var.modules_table_name
      DYNAMODB_DEPLOYMENTS_TABLE_NAME    = var.deployments_table_name
      DYNAMODB_POLICIES_TABLE_NAME       = var.policies_table_name
      DYNAMODB_CHANGE_RECORDS_TABLE_NAME = var.change_records_table_name
      DYNAMODB_CONFIG_TABLE_NAME         = var.config_table_name
      MODULE_S3_BUCKET                   = var.modules_s3_bucket
      POLICY_S3_BUCKET                   = var.policies_s3_bucket
      CHANGE_RECORD_S3_BUCKET            = var.change_records_s3_bucket
      PROVIDERS_S3_BUCKET                = var.providers_s3_bucket
      REGION                             = var.region
      ENVIRONMENT                        = var.environment
      CENTRAL_ACCOUNT_ID                 = var.central_account_id
      CURRENT_ACCOUNT_ID                 = var.account_id
      NOTIFICATION_TOPIC_ARN             = var.notification_topic_arn
    }
  }

  region = var.region
}

resource "aws_lambda_function" "webserver-api" {
  function_name = local.webserver_api_function_name
  package_type  = "Image"
  image_uri     = "infraweave/internal-api" # TODO: use ECR image
  architectures = ["arm64"]

  tracing_config {
    mode = "Active"
  }

  memory_size = 128

  timeout = 35

  role = "arn:aws:iam::${var.account_id}:role/infraweave_api_role-${var.environment}"

  environment {
    variables = {
      DYNAMODB_EVENTS_TABLE_NAME         = var.events_table_name
      DYNAMODB_MODULES_TABLE_NAME        = var.modules_table_name
      DYNAMODB_DEPLOYMENTS_TABLE_NAME    = var.deployments_table_name
      DYNAMODB_POLICIES_TABLE_NAME       = var.policies_table_name
      DYNAMODB_CHANGE_RECORDS_TABLE_NAME = var.change_records_table_name
      DYNAMODB_CONFIG_TABLE_NAME         = var.config_table_name
      MODULE_S3_BUCKET                   = var.modules_s3_bucket
      POLICY_S3_BUCKET                   = var.policies_s3_bucket
      CHANGE_RECORD_S3_BUCKET            = var.change_records_s3_bucket
      PROVIDERS_S3_BUCKET                = var.providers_s3_bucket
      REGION                             = var.region
      ENVIRONMENT                        = var.environment
      CENTRAL_ACCOUNT_ID                 = var.central_account_id
      CURRENT_ACCOUNT_ID                 = var.account_id
      NOTIFICATION_TOPIC_ARN             = var.notification_topic_arn
      AWS_XRAY_CONTEXT_MISSING           = "LOG_ERROR"
      RUST_LOG                           = "info"

      ECS_CLUSTER                 = "terraform-ecs-cluster-${var.environment}"
      OIDC_CLIENT_ID              = var.cognito_client_id
      OIDC_ISSUER_URL             = var.cognito_domain
      OTEL_EXPORTER_OTLP_ENDPOINT = "https://otlp.${var.region}.amazonaws.com/v1/traces"
      OTEL_SERVICE_NAME           = "internal-api"
    }
  }

  region = var.region
}


data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_policy_document" {

  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [var.notification_topic_arn]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
    ]
    resources = [
      "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/lambda/${local.function_name}:*"
    ]
  }

  statement {
    actions = [
      "s3:GetObject",  # for pre-signed URLs
      "s3:PutObject",  # to upload modules,
      "s3:ListBucket", # to list modules (for downloading to check diff using cli)
    ]
    resources = [
      "arn:aws:s3:::tf-modules-${var.central_account_id}-*-${var.environment}",
      "arn:aws:s3:::tf-modules-${var.central_account_id}-*-${var.environment}/*",
      "arn:aws:s3:::tf-policies-${var.central_account_id}-*-${var.environment}",
      "arn:aws:s3:::tf-policies-${var.central_account_id}-*-${var.environment}/*",
      "arn:aws:s3:::tf-change-records-${var.central_account_id}-*-${var.environment}",
      "arn:aws:s3:::tf-change-records-${var.central_account_id}-*-${var.environment}/*",
      "arn:aws:s3:::tf-providers-${var.central_account_id}-*-${var.environment}",
      "arn:aws:s3:::tf-providers-${var.central_account_id}-*-${var.environment}/*",
    ]
  }

  statement {
    sid = "KMSAccess"
    actions = [
      "kms:Decrypt",
    ]
    resources = [
      "arn:aws:kms:*:${var.central_account_id}:*"
    ]
  }

  statement {
    sid = "DeploymentsAccess"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:TransactWriteItems",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
    ]
    resources = [
      "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${var.deployments_table_name}",
    ]

    # condition {
    #   test     = "StringLike"
    #   variable = "dynamodb:LeadingKeys"
    #   values   = [
    #     "DEPLOYMENT#${var.account_id}::${var.region}::*",
    #     "PLAN#${var.account_id}::${var.region}::*",
    #     "DEPENDENT#${var.account_id}::${var.region}::*"
    #   ]
    # }
  }


  statement {
    sid = "DeploymentsAccessDeletedIndex"
    actions = [
      "dynamodb:Query",
    ]
    resources = [
      "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${var.deployments_table_name}/index/DeletedIndex",
      "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${var.deployments_table_name}/index/ModuleIndex",
    ]

    # condition {
    #   test     = "StringEquals"
    #   variable = "dynamodb:LeadingKeys"
    #   values   = [
    #     "0"
    #   ]
    # }

    # condition {
    #   test     = "ForAllValues:StringEquals"
    #   variable = "dynamodb:LeadingKeys"
    #   values   = [
    #     "0|DEPLOYMENT#${var.account_id}::${var.region}",
    #     "0|PLAN#${var.account_id}::${var.region}"
    #   ]
    # }
  }

  statement {
    sid = "EventAccess"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:TransactWriteItems",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
    ]
    resources = ["arn:aws:dynamodb:*:*:table/Events-${var.central_account_id}-*-${var.environment}"]

    # condition {
    #   test     = "StringLike"
    #   variable = "dynamodb:LeadingKeys"
    #   values   = [
    #     "EVENT#${var.account_id}::${var.region}::*",
    #   ]
    # }
  }

  statement {
    sid = "ChangeRecordAccess"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:TransactWriteItems",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
    ]
    resources = ["arn:aws:dynamodb:*:*:table/ChangeRecords-${var.central_account_id}-*-${var.environment}"]

    # condition {
    #   test     = "StringLike"
    #   variable = "dynamodb:LeadingKeys"
    #   values   = [
    #     "PLAN#${var.account_id}::${var.region}::*",
    #     "APPLY#${var.account_id}::${var.region}::*",
    #     "DESTROY#${var.account_id}::${var.region}::*",
    #     "UNKNOWN#${var.account_id}::${var.region}::*",
    #   ]
    # }
  }

  statement {
    sid = "ModuleAccess"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:TransactWriteItems",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
    ]
    resources = [
      "arn:aws:dynamodb:*:*:table/Modules-${var.central_account_id}-*-${var.environment}"
    ]

    # condition {
    #   test     = "StringLike"
    #   variable = "dynamodb:LeadingKeys"
    #   values   = [
    #     "*",
    #   ]
    # }
  }

  statement {
    sid = "PolicyAccess"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:TransactWriteItems",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
    ]
    resources = [
      "arn:aws:dynamodb:*:*:table/Policies-${var.central_account_id}-*-${var.environment}"
    ]

    # condition {
    #   test     = "StringLike"
    #   variable = "dynamodb:LeadingKeys"
    #   values   = [
    #     "*",
    #   ]
    # }
  }

  statement {
    sid = "AssumeWorkloadLogReadRole"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::*:role/infraweave_api_read_log-${var.environment}"
    ]
  }

  statement {
    sid = "AssumeWorkloadExecuteRunnerRole"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::*:role/infraweave_api_execute_runner-${var.environment}"
    ]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  count = var.is_primary_region ? 1 : 0

  name               = "infraweave_api_role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_policy" "lambda_policy" {
  count = var.is_primary_region ? 1 : 0

  name        = "infraweave_api_access_policy-${var.environment}"
  description = "IAM policy for Lambda to launch CodeBuild and access CloudWatch Logs"
  policy      = data.aws_iam_policy_document.lambda_policy_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  count = var.is_primary_region ? 1 : 0

  role       = aws_iam_role.iam_for_lambda[0].name
  policy_arn = aws_iam_policy.lambda_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "lambda_xray_policy" {
  count = var.is_primary_region ? 1 : 0

  role       = aws_iam_role.iam_for_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/lambda_function_payload.zip"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_otlp" {
  count = var.is_primary_region ? 1 : 0

  role       = aws_iam_role.iam_for_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
