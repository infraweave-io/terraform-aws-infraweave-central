output "user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.main.id
}

output "user_pool_arn" {
  value = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  value = aws_cognito_user_pool.main.endpoint
}

output "issuer_url" {
  description = "OIDC issuer URL used for JWT validation"
  value       = "https://${aws_cognito_user_pool.main.endpoint}"
}

output "user_pool_domain" {
  value = "${aws_cognito_user_pool_domain.main.domain}.auth.${var.region}.amazoncognito.com"
}
