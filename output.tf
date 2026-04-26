output "webserver_frontend_config" {
  description = "Frontend environment variables for React app configuration"
  value = var.enable_api_gw ? try({
    REACT_APP_AWS_REGION      = var.region
    REACT_APP_AUTH_ISSUER_URL = module.api_gw[0].auth_issuer_url
    REACT_APP_AUTH_CLIENT_ID  = module.api_gw[0].auth_client_id
    REACT_APP_AUTH_DOMAIN     = module.api_gw[0].auth_domain
    REACT_APP_API_GATEWAY_URL = module.api_gw[0].api_gateway_url
  }, null) : null
}

output "webserver_auth_issuer_url" {
  description = "OIDC issuer URL"
  value       = var.enable_api_gw ? try(module.api_gw[0].auth_issuer_url, null) : null
}

output "webserver_auth_client_id" {
  description = "OIDC client ID"
  value       = var.enable_api_gw ? try(module.api_gw[0].auth_client_id, null) : null
}

output "webserver_auth_domain" {
  description = "Auth domain for frontend login"
  value       = var.enable_api_gw ? try(module.api_gw[0].auth_domain, null) : null
}

output "webserver_api_gateway_url" {
  description = "API Gateway URL for frontend"
  value       = var.enable_api_gw ? try(module.api_gw[0].api_gateway_url, null) : null
}
