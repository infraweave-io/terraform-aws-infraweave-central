
output "api_gateway_url" {
  description = "HTTP API Gateway invoke URL"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "auth_issuer_url" {
  description = "OIDC issuer URL used for JWT validation"
  value       = var.auth_issuer_url
}

output "auth_client_id" {
  description = "OIDC client ID (audience)"
  value       = var.auth_client_id
}

output "auth_domain" {
  description = "Auth domain for frontend login redirects"
  value       = var.auth_domain
}

output "frontend_config" {
  description = "Environment variables for frontend configuration"
  value = {
    REACT_APP_AWS_REGION      = var.region
    REACT_APP_AUTH_ISSUER_URL = var.auth_issuer_url
    REACT_APP_AUTH_CLIENT_ID  = var.auth_client_id
    REACT_APP_AUTH_DOMAIN     = var.auth_domain
    REACT_APP_API_GATEWAY_URL = aws_apigatewayv2_stage.default.invoke_url
  }
}
