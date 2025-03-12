
output "api_gateway_endpoint" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

output "webhook_endpoint" {
  description = "The API Gateway endpoint for the webhook"
  value       = aws_apigatewayv2_stage.api_stage.invoke_url
}
