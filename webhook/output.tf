
output "webhook_endpoint" {
  value = var.enable_webhook_processor_endpoint ? "${module.endpoint[0].api_gateway_endpoint}/webhook" : null
}
