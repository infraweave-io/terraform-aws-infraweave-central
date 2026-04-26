
output "api_function_arn" {
  value = aws_lambda_function.api.arn
}

output "lambda_function_name" {
  value = aws_lambda_function.api.function_name
}

output "webserver_function_name" {
  value = aws_lambda_function.webserver-api.function_name
}

output "webserver_function_arn" {
  value = aws_lambda_function.webserver-api.arn
}
