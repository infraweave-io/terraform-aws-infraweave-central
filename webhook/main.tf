terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.77.0"
    }
  }
}

locals {
  # Transform the raw data into DynamoDB's JSON format
  p = jsondecode(var.project_map)
  transformed_project_map = {
    PK = { S = local.p.id }
    data = {
      M = { for key, value in local.p.data :
        key => { M = { for subkey, subvalue in value : subkey => { S = subvalue } } }
      }
    }
  }

}

data "aws_organizations_organization" "current_org" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "endpoint" {
  count  = var.enable_webhook_processor_endpoint ? 1 : 0
  source = "./endpoint"

  region         = var.region
  infraweave_env = var.infraweave_env

  validator_lambda_invoke_arn    = aws_lambda_function.validator_github_webhook_handler.invoke_arn
  validator_lambda_function_name = aws_lambda_function.validator_github_webhook_handler.function_name

  providers = {
    aws = aws
  }
}

# VALIDATOR
resource "aws_iam_role" "validator_lambda_role" {
  name = "webhook-validator-lambda-role-${var.region}-${var.infraweave_env}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "validator_lambda_basic_execution" {
  role       = aws_iam_role.validator_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "validator_invoke_api_lambda_policy" {
  name        = "validator-invoke-api-lambda-policy-${var.region}-${var.infraweave_env}"
  description = "Policy that allows invoking the api-lambda function in the same region and account"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowPublishingToSNSForProcessing"
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:infraweave-api-${var.infraweave_env}"
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter"
        ],
        Resource = [
          aws_ssm_parameter.github_webhook_secret.arn
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt"
        ],
        Resource = [
          "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:alias/aws/ssm"
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "validator_attach_invoke_api_lambda" {
  role       = aws_iam_role.validator_lambda_role.name
  policy_arn = aws_iam_policy.validator_invoke_api_lambda_policy.arn
}

# Using parameter store as a secure way to store the secret
# Limitations: throughput per second is 40 requests per second (can be increased which adds cost, otherwise its free)
# This is used to validate webhook requests from GitHub
resource "aws_ssm_parameter" "github_webhook_secret" {
  name        = "/infraweave/infraweave-${var.infraweave_env}/github-webhook-secret"
  description = "GitHub webhook secret for the webhook lambda"
  value       = "your-github-webhook-secret"
  type        = "SecureString"
  tier        = "Standard" # Standard tier is free, change to Advanced if you need more throughput (recreates the parameter)

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "github_webhook_private_key" {
  name        = "/infraweave/infraweave-${var.infraweave_env}/github-webhook-private-key"
  description = "GitHub webhook private key for the webhook lambda"
  value       = "your-github-webhook-private-key"
  type        = "SecureString"
  tier        = "Standard" # Standard tier is free, change to Advanced if you need more throughput (recreates the parameter)

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_dynamodb_table_item" "config" {
  table_name = var.config_table_name
  hash_key   = "PK"
  item       = jsonencode(local.transformed_project_map)
}

resource "aws_lambda_function" "validator_github_webhook_handler" {
  function_name = "gitops-validator-${var.infraweave_env}"
  role          = aws_iam_role.validator_lambda_role.arn

  timeout      = 10
  image_uri    = var.webhook_image_uri
  package_type = "Image"

  architectures = ["arm64"]

  environment {
    variables = {
      PROVIDER                          = "aws"
      RUN_MODE                          = "VALIDATOR"
      INFRAWEAVE_ENV                    = var.infraweave_env
      RUST_BACKTRACE                    = "1"
      GITHUB_SECRET_PARAMETER_STORE_KEY = aws_ssm_parameter.github_webhook_secret.name
      # DEBUG                             = "true"
      # LOG_LEVEL                         = "info"
    }
  }
}

### PROCESSOR
resource "aws_iam_role" "processor_lambda_role" {
  name = "github-webhook-lambda-role-${var.region}-${var.infraweave_env}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "processor_lambda_basic_execution" {
  role       = aws_iam_role.processor_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "processor_invoke_api_lambda_policy" {
  name        = "invoke-api-lambda-policy-${var.region}-${var.infraweave_env}"
  description = "Policy that allows invoking the api-lambda function in the same region and account"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowInvokeFunctionInWorkloadAccountToLaunchRunnerInAnyRegion"
        Effect   = "Allow",
        Action   = "lambda:InvokeFunction",
        Resource = "arn:aws:lambda:*:*:function:infraweave-api-${var.infraweave_env}"
      },
      {
        Effect   = "Allow",
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"],
        Resource = aws_sqs_queue.webhook_queue.arn
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter"
        ],
        Resource = [
          aws_ssm_parameter.github_webhook_private_key.arn
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt"
        ],
        Resource = [
          "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:alias/aws/ssm"
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "processor_attach_invoke_api_lambda" {
  role       = aws_iam_role.processor_lambda_role.name
  policy_arn = aws_iam_policy.processor_invoke_api_lambda_policy.arn
}

resource "aws_lambda_function" "processor_github_webhook_handler" {
  function_name = "gitops-processor-${var.infraweave_env}"
  role          = aws_iam_role.processor_lambda_role.arn

  timeout      = 300
  image_uri    = var.webhook_image_uri
  package_type = "Image"

  architectures = ["arm64"]

  environment {
    variables = {
      PROVIDER       = "aws"
      # DEBUG          = "true"
      # LOG_LEVEL      = "info"
      RUN_MODE       = "PROCESSOR"
      INFRAWEAVE_ENV = var.infraweave_env
      RUST_BACKTRACE = "1"
      GITHUB_PRIVATE_KEY_PARAMETER_STORE_KEY = aws_ssm_parameter.github_webhook_private_key.name
    }
  }
}

resource "aws_sns_topic" "webhook_topic" {
  name = "infraweave-${var.infraweave_env}"
}

resource "aws_sqs_queue" "webhook_queue" {
  name                       = "infraweave-${var.infraweave_env}-webhook"
  visibility_timeout_seconds = 80
}

resource "aws_sns_topic_subscription" "webhook_subscription" {
  topic_arn = aws_sns_topic.webhook_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.webhook_queue.arn
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    sid       = "AllowApiFunctionToPublish"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.webhook_topic.arn]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [data.aws_organizations_organization.current_org.id]
    }

    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::*:role/infraweave_api_role-${var.region}-${var.infraweave_env}"]
    }
  }
}

resource "aws_sns_topic_policy" "webhook_topic_policy" {
  arn    = aws_sns_topic.webhook_topic.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sqs_policy" {
  statement {
    sid       = "AllowSNSToSendMessages"
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.webhook_queue.arn]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.webhook_topic.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "webhook_queue_policy" {
  queue_url = aws_sqs_queue.webhook_queue.id
  policy    = data.aws_iam_policy_document.sqs_policy.json
}

resource "aws_lambda_event_source_mapping" "sqs_to_lambda" {
  event_source_arn = aws_sqs_queue.webhook_queue.arn
  function_name    = aws_lambda_function.processor_github_webhook_handler.arn
  batch_size       = 1 # number of messages per batch
}
