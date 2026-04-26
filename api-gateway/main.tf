# HTTP API (API Gateway v2)
resource "aws_apigatewayv2_api" "main" {
  name          = "infraweave-webserver-api-${var.environment}"
  protocol_type = "HTTP"
  description   = "HTTP API Gateway for Infraweave"

  cors_configuration {
    allow_origins  = var.cors_allow_origins
    allow_methods  = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
    allow_headers  = ["content-type", "authorization"]
    max_age        = 300
    expose_headers = ["X-Trace-Id"]
  }

  region = var.region
}

# JWT Authorizer
resource "aws_apigatewayv2_authorizer" "jwt" {
  api_id           = aws_apigatewayv2_api.main.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "jwt-authorizer"

  jwt_configuration {
    audience = [var.auth_client_id]
    issuer   = var.auth_issuer_url
  }

  region = var.region
}

# Lambda Integration - connects to the existing API Lambda
resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = "arn:aws:lambda:${var.region}:${var.account_id}:function:${var.api_lambda_function_name}"

  payload_format_version = "2.0"

  region = var.region
}

# GET /api/v1/modules Route with Authorization
resource "aws_apigatewayv2_route" "modules_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/modules"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/modules Route without Authorization (for CORS preflight)
resource "aws_apigatewayv2_route" "modules_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/modules"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# GET /api/v1/providers Route with Authorization
resource "aws_apigatewayv2_route" "providers_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/providers"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/providers Route without Authorization (for CORS preflight)
resource "aws_apigatewayv2_route" "providers_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/providers"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# GET /api/v1/provider/{track}/{provider_name}/{provider_version} Route with Authorization
resource "aws_apigatewayv2_route" "provider_version_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/provider/{track}/{provider_name}/{provider_version}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/provider/{track}/{provider_name}/{provider_version} Route without Authorization
resource "aws_apigatewayv2_route" "provider_version_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/provider/{track}/{provider_name}/{provider_version}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# GET /api/v1/provider/{track}/{provider_name}/{provider_version}/download Route with Authorization
resource "aws_apigatewayv2_route" "provider_download_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/provider/{track}/{provider_name}/{provider_version}/download"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/provider/{track}/{provider_name}/{provider_version}/download Route without Authorization
resource "aws_apigatewayv2_route" "provider_download_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/provider/{track}/{provider_name}/{provider_version}/download"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# POST /api/v1/module/publish Route with JWT Authorization
resource "aws_apigatewayv2_route" "module_publish_post" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /api/v1/module/publish"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/module/publish Route without Authorization (for CORS preflight)
resource "aws_apigatewayv2_route" "module_publish_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/module/publish"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# PUT /api/v1/module/{track}/{module}/{version}/deprecate Route with AWS_IAM Authorization (for internal/CLI access)
resource "aws_apigatewayv2_route" "module_deprecate_put" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "PUT /api/v1/module/{track}/{module}/{version}/deprecate"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "AWS_IAM"

  region = var.region
}

# OPTIONS /api/v1/module/{track}/{module}/{version}/deprecate Route without Authorization (for CORS preflight)
resource "aws_apigatewayv2_route" "module_deprecate_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/module/{track}/{module}/{version}/deprecate"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# GET /api/v1/module/publish/{job_id} Route with AWS_IAM Authorization (for internal/CLI access) - uses API Lambda for read-only status check
resource "aws_apigatewayv2_route" "module_publish_status_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/module/publish/{job_id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "AWS_IAM"

  region = var.region
}

# OPTIONS /api/v1/module/publish/{job_id} Route without Authorization (for CORS preflight)
resource "aws_apigatewayv2_route" "module_publish_status_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/module/publish/{job_id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# GET /api/v1/projects Route with Authorization
resource "aws_apigatewayv2_route" "projects_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/projects"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/projects Route without Authorization (for CORS preflight)
resource "aws_apigatewayv2_route" "projects_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/projects"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# GET /api/v1/stacks Route with Authorization
resource "aws_apigatewayv2_route" "stacks_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/stacks"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/stacks Route without Authorization
resource "aws_apigatewayv2_route" "stacks_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/stacks"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# GET /api/v1/deployments/{project}/{region} Route with Authorization
resource "aws_apigatewayv2_route" "deployments_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/deployments/{project}/{region}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/deployments/{project}/{region} Route without Authorization
resource "aws_apigatewayv2_route" "deployments_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/deployments/{project}/{region}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# GET /api/v1/deployments/module/{project}/{region}/{module} Route with Authorization
resource "aws_apigatewayv2_route" "deployments_module_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/deployments/module/{project}/{region}/{module}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/deployments/module/{project}/{region}/{module} Route without Authorization
resource "aws_apigatewayv2_route" "deployments_module_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/deployments/module/{project}/{region}/{module}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# GET /api/v1/deployment/{project}/{region}/{proxy+} Route with Authorization (greedy for environment/deployment_id with slashes)
resource "aws_apigatewayv2_route" "deployment_describe_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/deployment/{project}/{region}/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/deployment/{project}/{region}/{proxy+} Route without Authorization
resource "aws_apigatewayv2_route" "deployment_describe_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/deployment/{project}/{region}/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# GET /api/v1/events/{project}/{region}/{proxy+} Route with Authorization (greedy for environment/deployment_id with slashes)
resource "aws_apigatewayv2_route" "events_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/events/{project}/{region}/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/events/{project}/{region}/{proxy+} Route without Authorization
resource "aws_apigatewayv2_route" "events_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/events/{project}/{region}/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# GET /api/v1/change_record/{project}/{region}/{proxy+} Route with Authorization (greedy for environment/deployment_id/job_id/change_type with slashes)
resource "aws_apigatewayv2_route" "change_record_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/change_record/{project}/{region}/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/change_record/{project}/{region}/{proxy+} Route without Authorization
resource "aws_apigatewayv2_route" "change_record_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/change_record/{project}/{region}/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# GET /api/v1/logs/{project}/{region}/{job_id} Route with Authorization
resource "aws_apigatewayv2_route" "logs_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/logs/{project}/{region}/{job_id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/logs/{project}/{region}/{job_id} Route without Authorization
resource "aws_apigatewayv2_route" "logs_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/logs/{project}/{region}/{job_id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# GET /api/v1/module/{track}/{module_name}/{module_version} Route with Authorization
resource "aws_apigatewayv2_route" "module_version_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/module/{track}/{module_name}/{module_version}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/module/{track}/{module_name}/{module_version} Route without Authorization
resource "aws_apigatewayv2_route" "module_version_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/module/{track}/{module_name}/{module_version}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# GET /api/v1/module/{track}/{module_name}/{module_version}/download Route with Authorization
resource "aws_apigatewayv2_route" "module_download_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/module/{track}/{module_name}/{module_version}/download"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/module/{track}/{module_name}/{module_version}/download Route without Authorization
resource "aws_apigatewayv2_route" "module_download_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/module/{track}/{module_name}/{module_version}/download"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# GET /api/v1/stack/{track}/{stack_name}/{stack_version} Route with Authorization
resource "aws_apigatewayv2_route" "stack_version_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/stack/{track}/{stack_name}/{stack_version}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/stack/{track}/{stack_name}/{stack_version} Route without Authorization
resource "aws_apigatewayv2_route" "stack_version_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/stack/{track}/{stack_name}/{stack_version}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# GET /api/v1/stack/{track}/{stack_name}/{stack_version}/download Route with Authorization
resource "aws_apigatewayv2_route" "stack_download_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/stack/{track}/{stack_name}/{stack_version}/download"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/stack/{track}/{stack_name}/{stack_version}/download Route without Authorization
resource "aws_apigatewayv2_route" "stack_download_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/stack/{track}/{stack_name}/{stack_version}/download"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# GET /api/v1/policy/{environment}/{policy_name}/{policy_version} Route with Authorization
resource "aws_apigatewayv2_route" "policy_version_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/policy/{environment}/{policy_name}/{policy_version}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/policy/{environment}/{policy_name}/{policy_version} Route without Authorization
resource "aws_apigatewayv2_route" "policy_version_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/policy/{environment}/{policy_name}/{policy_version}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# GET /api/v1/modules/versions/{track}/{module} Route with Authorization
resource "aws_apigatewayv2_route" "module_versions_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/modules/versions/{track}/{module}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/modules/versions/{track}/{module} Route without Authorization
resource "aws_apigatewayv2_route" "module_versions_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/modules/versions/{track}/{module}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# GET /api/v1/stacks/versions/{track}/{stack} Route with Authorization
resource "aws_apigatewayv2_route" "stack_versions_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/stacks/versions/{track}/{stack}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/stacks/versions/{track}/{stack} Route without Authorization
resource "aws_apigatewayv2_route" "stack_versions_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/stacks/versions/{track}/{stack}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# GET /api/v1/policies/{environment} Route with Authorization
resource "aws_apigatewayv2_route" "policies_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/policies/{environment}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/policies/{environment} Route without Authorization
resource "aws_apigatewayv2_route" "policies_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/policies/{environment}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# POST /api/v1/auth/token Route with AWS_IAM Authorization
resource "aws_apigatewayv2_route" "auth_token_post" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /api/v1/auth/token"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "AWS_IAM"

  region = var.region
}

# OPTIONS /api/v1/auth/token Route without Authorization (for CORS preflight)
resource "aws_apigatewayv2_route" "auth_token_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/auth/token"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# GET /api/v1/change_record_graph/{project}/{region}/{proxy+} Route with Authorization
resource "aws_apigatewayv2_route" "change_record_graph_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/change_record_graph/{project}/{region}/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/change_record_graph/{project}/{region}/{proxy+} Route without Authorization
resource "aws_apigatewayv2_route" "change_record_graph_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/change_record_graph/{project}/{region}/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# GET /api/v1/deployment_graph/{project}/{region}/{proxy+} Route with Authorization
resource "aws_apigatewayv2_route" "deployment_graph_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/deployment_graph/{project}/{region}/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/deployment_graph/{project}/{region}/{proxy+} Route without Authorization
resource "aws_apigatewayv2_route" "deployment_graph_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/deployment_graph/{project}/{region}/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# GET /api/v1/meta Route without Authorization
resource "aws_apigatewayv2_route" "meta_get" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /api/v1/meta"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# OPTIONS /api/v1/meta Route without Authorization (for CORS preflight)
resource "aws_apigatewayv2_route" "meta_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/meta"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# POST /api/v1/provider/download Route with JWT Authorization
resource "aws_apigatewayv2_route" "provider_download_post" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /api/v1/provider/download"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# OPTIONS /api/v1/provider/download Route without Authorization (for CORS preflight)
resource "aws_apigatewayv2_route" "provider_download_post_options" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /api/v1/provider/download"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"

  region = var.region
}

# Default Route with Authorization
resource "aws_apigatewayv2_route" "default" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "$default"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id

  region = var.region
}

# API Stage
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      ip                      = "$context.identity.sourceIp"
      userAgent               = "$context.identity.userAgent"
      requestTime             = "$context.requestTime"
      httpMethod              = "$context.httpMethod"
      routeKey                = "$context.routeKey"
      path                    = "$context.path"
      status                  = "$context.status"
      protocol                = "$context.protocol"
      responseLength          = "$context.responseLength"
      responseLatency         = "$context.responseLatency"
      integrationStatus       = "$context.integrationStatus"
      integrationErrorMessage = "$context.integrationErrorMessage"
      authorizerError         = "$context.authorizer.error"
      errorMessage            = "$context.error.message"
      errorResponseType       = "$context.error.responseType"
    })
  }

  default_route_settings {
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
  }

  region = var.region
}

# CloudWatch Log Group for API Gateway
# trivy:ignore:AVD-AWS-0017 Access logs contain only request metadata (IP, path, status, latency); AWS-managed encryption at rest is sufficient.
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/infraweave-webserver-${var.environment}"
  retention_in_days = 30

  region = var.region
}

# Lambda Permission for HTTP API
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.api_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"

  region = var.region
}

# WAFv2 Web ACL for the HTTP API
resource "aws_wafv2_web_acl" "api" {
  count = var.enable_waf ? 1 : 0

  name        = "infraweave-webserver-${var.environment}"
  description = "WAF for Infraweave web API (${var.environment})"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimitPerIP"
    priority = 10

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit_per_ip
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitPerIP"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "infraweave-webserver-${var.environment}"
    sampled_requests_enabled   = true
  }

  region = var.region
}

resource "aws_wafv2_web_acl_association" "api" {
  count = var.enable_waf ? 1 : 0

  resource_arn = aws_apigatewayv2_stage.default.arn
  web_acl_arn  = aws_wafv2_web_acl.api[0].arn

  region = var.region
}
