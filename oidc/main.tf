
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.77.0"
    }
  }
}

data "aws_organizations_organization" "current_org" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# OIDC Provider (GLOBAL)

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "oidc_role" {
  name = "infraweave-oidc-role-${var.infraweave_env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = [
            aws_iam_openid_connect_provider.github.arn,
          ]
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          "StringLike" = {
            "token.actions.githubusercontent.com:sub" = [
              for repo in var.oidc_allowed_github_repos : "repo:${repo}:*"
            ],
          }
          "StringEquals" = {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com",
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "invoke_lambda_with_oidc" {
  name = "InvokeLambdaWithOIDC"
  role = aws_iam_role.oidc_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "lambda:InvokeFunction",
        Resource = "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:infraweave-api-${var.infraweave_env}"
      }
    ]
  })
}
