# api

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | n/a | `string` | n/a | yes |
| <a name="input_api_lambda_function_name"></a> [api\_lambda\_function\_name](#input\_api\_lambda\_function\_name) | Name of the API Lambda function to invoke for backend operations | `string` | n/a | yes |
| <a name="input_auth_client_id"></a> [auth\_client\_id](#input\_auth\_client\_id) | OIDC client ID used as the JWT audience | `string` | n/a | yes |
| <a name="input_auth_domain"></a> [auth\_domain](#input\_auth\_domain) | Auth domain for frontend login redirects | `string` | `""` | no |
| <a name="input_auth_issuer_url"></a> [auth\_issuer\_url](#input\_auth\_issuer\_url) | OIDC issuer URL for JWT validation (e.g., https://cognito-idp.us-west-2.amazonaws.com/us-west-2_xxx) | `string` | n/a | yes |
| <a name="input_central_account_id"></a> [central\_account\_id](#input\_central\_account\_id) | n/a | `string` | n/a | yes |
| <a name="input_change_records_s3_bucket"></a> [change\_records\_s3\_bucket](#input\_change\_records\_s3\_bucket) | n/a | `string` | n/a | yes |
| <a name="input_change_records_table_name"></a> [change\_records\_table\_name](#input\_change\_records\_table\_name) | n/a | `string` | n/a | yes |
| <a name="input_config_table_name"></a> [config\_table\_name](#input\_config\_table\_name) | n/a | `string` | n/a | yes |
| <a name="input_cors_allow_origins"></a> [cors\_allow\_origins](#input\_cors\_allow\_origins) | List of allowed origins for CORS. Must be explicit origins; "*" is rejected because it is unsafe combined with the Authorization header. | `list(string)` | n/a | yes |
| <a name="input_deployments_table_name"></a> [deployments\_table\_name](#input\_deployments\_table\_name) | n/a | `string` | n/a | yes |
| <a name="input_enable_waf"></a> [enable\_waf](#input\_enable\_waf) | Attach an AWS WAFv2 web ACL (managed rules + per-IP rate limit) to the API Gateway stage. Disabled by default to avoid the ~$5/Web ACL + ~$1/rule monthly cost; enable for production. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | n/a | `string` | n/a | yes |
| <a name="input_events_table_name"></a> [events\_table\_name](#input\_events\_table\_name) | n/a | `string` | n/a | yes |
| <a name="input_identity_center_identity_store_id"></a> [identity\_center\_identity\_store\_id](#input\_identity\_center\_identity\_store\_id) | IAM Identity Center Identity Store ID (e.g., d-xxxxxxxxxx) | `string` | `""` | no |
| <a name="input_identity_center_instance_arn"></a> [identity\_center\_instance\_arn](#input\_identity\_center\_instance\_arn) | IAM Identity Center instance ARN (if in different region) | `string` | `""` | no |
| <a name="input_identity_center_region"></a> [identity\_center\_region](#input\_identity\_center\_region) | AWS region where IAM Identity Center is enabled | `string` | `""` | no |
| <a name="input_modules_s3_bucket"></a> [modules\_s3\_bucket](#input\_modules\_s3\_bucket) | n/a | `string` | n/a | yes |
| <a name="input_modules_table_name"></a> [modules\_table\_name](#input\_modules\_table\_name) | n/a | `string` | n/a | yes |
| <a name="input_notification_topic_arn"></a> [notification\_topic\_arn](#input\_notification\_topic\_arn) | n/a | `string` | n/a | yes |
| <a name="input_policies_s3_bucket"></a> [policies\_s3\_bucket](#input\_policies\_s3\_bucket) | n/a | `string` | n/a | yes |
| <a name="input_policies_table_name"></a> [policies\_table\_name](#input\_policies\_table\_name) | n/a | `string` | n/a | yes |
| <a name="input_providers_s3_bucket"></a> [providers\_s3\_bucket](#input\_providers\_s3\_bucket) | n/a | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | n/a | yes |
| <a name="input_user_pool_domain"></a> [user\_pool\_domain](#input\_user\_pool\_domain) | Deprecated: Use auth\_domain instead. | `string` | `""` | no |
| <a name="input_waf_rate_limit_per_ip"></a> [waf\_rate\_limit\_per\_ip](#input\_waf\_rate\_limit\_per\_ip) | WAF rate-based rule limit: max requests per 5-minute window per source IP before blocking. Only used when enable\_waf is true. | `number` | `2000` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_gateway_url"></a> [api\_gateway\_url](#output\_api\_gateway\_url) | HTTP API Gateway invoke URL |
| <a name="output_auth_client_id"></a> [auth\_client\_id](#output\_auth\_client\_id) | OIDC client ID (audience) |
| <a name="output_auth_domain"></a> [auth\_domain](#output\_auth\_domain) | Auth domain for frontend login redirects |
| <a name="output_auth_issuer_url"></a> [auth\_issuer\_url](#output\_auth\_issuer\_url) | OIDC issuer URL used for JWT validation |
| <a name="output_frontend_config"></a> [frontend\_config](#output\_frontend\_config) | Environment variables for frontend configuration |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

# Examples

Please check out the [how it is used in the bootstrap](https://github.com/infraweave-io/aws-bootstrap/blob/main/central.tf) repository for up-to-date examples if you need a custom solution.

## Resources

| Name | Type |
|------|------|
| [aws_apigatewayv2_api.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api) | resource |
| [aws_apigatewayv2_authorizer.jwt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_authorizer) | resource |
| [aws_apigatewayv2_integration.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_route.auth_token_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.auth_token_post](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.change_record_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.change_record_graph_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.change_record_graph_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.change_record_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.deployment_describe_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.deployment_describe_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.deployment_graph_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.deployment_graph_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.deployments_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.deployments_module_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.deployments_module_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.deployments_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.events_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.events_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.logs_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.logs_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.meta_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.meta_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.module_deprecate_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.module_deprecate_put](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.module_download_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.module_download_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.module_publish_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.module_publish_post](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.module_publish_status_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.module_publish_status_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.module_version_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.module_version_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.module_versions_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.module_versions_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.modules_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.modules_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.policies_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.policies_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.policy_version_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.policy_version_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.projects_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.projects_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.provider_download_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.provider_download_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.provider_download_post](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.provider_download_post_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.provider_version_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.provider_version_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.providers_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.providers_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.stack_download_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.stack_download_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.stack_version_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.stack_version_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.stack_versions_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.stack_versions_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.stacks_get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.stacks_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_stage.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_stage) | resource |
| [aws_cloudwatch_log_group.api_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_lambda_permission.api_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_wafv2_web_acl.api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | resource |
| [aws_wafv2_web_acl_association.api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
