# terraform-aws-infraweave-central

Alpha version, expect changes to happen

<!-- BEGIN_TF_DOCS -->

<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_all_regions"></a> [all\_regions](#input\_all\_regions) | List of all regions that forms the InfraWeave platform | `list(string)` | n/a | yes |
| <a name="input_all_workload_projects"></a> [all\_workload\_projects](#input\_all\_workload\_projects) | List of workload project names to project id + regions, github\_repos should to be set when `enable_webhook_processor` is true | <pre>list(<br/>    object({<br/>      project_id          = string<br/>      name                = string<br/>      description         = string<br/>      regions             = list(string)<br/>      github_repos_deploy = list(string)<br/>      github_repos_oidc   = list(string)<br/>    })<br/>  )</pre> | n/a | yes |
| <a name="input_auth_config"></a> [auth\_config](#input\_auth\_config) | OIDC authentication configuration for the web API. Works with any JWT-compatible provider (Cognito, Okta, Auth0, etc.) | <pre>object({<br/>    issuer_url   = string           # Full OIDC issuer URL (e.g., https://cognito-idp.us-west-2.amazonaws.com/us-west-2_xxx, https://dev-123.okta.com/oauth2/default)<br/>    client_id    = string           # OIDC client/application ID (audience for JWT validation)<br/>    domain       = optional(string) # Auth domain for frontend login redirects (e.g., myapp.auth.us-west-2.amazoncognito.com, dev-123.okta.com)<br/>    user_pool_id = optional(string) # Cognito User Pool ID — only needed when using Cognito for admin API operations<br/>  })</pre> | `null` | no |
| <a name="input_cors_allow_origins"></a> [cors\_allow\_origins](#input\_cors\_allow\_origins) | List of allowed origins for the web API CORS configuration. Must be explicit origins (e.g. https://app.example.com); "*" is rejected because it is unsafe combined with the Authorization header. | `list(string)` | <pre>[<br/>  "http://localhost:3000"<br/>]</pre> | no |
| <a name="input_create_github_oidc_provider"></a> [create\_github\_oidc\_provider](#input\_create\_github\_oidc\_provider) | n/a | `bool` | `true` | no |
| <a name="input_enable_api_gw"></a> [enable\_api\_gw](#input\_enable\_api\_gw) | Enable the web API Gateway with JWT authentication. Requires auth\_config to be set. | `bool` | `true` | no |
| <a name="input_enable_observability"></a> [enable\_observability](#input\_enable\_observability) | Enable CloudWatch cross-account observability with OAM sink and dashboard | `bool` | `true` | no |
| <a name="input_enable_waf"></a> [enable\_waf](#input\_enable\_waf) | Attach an AWS WAFv2 web ACL (managed rules + per-IP rate limit) to the web API Gateway. Disabled by default to avoid the ~$5/Web ACL + ~$1/rule monthly cost per region; enable for production. | `bool` | `false` | no |
| <a name="input_enable_webhook_processor"></a> [enable\_webhook\_processor](#input\_enable\_webhook\_processor) | Create a webhook processor for the region, should be enabled in all regions if enabled in primary | `bool` | `false` | no |
| <a name="input_enable_webhook_processor_endpoint"></a> [enable\_webhook\_processor\_endpoint](#input\_enable\_webhook\_processor\_endpoint) | Create a public webhook endpoint for the region for GitHub application or Gitlab Webhook integration. Only needed for primary, however, it can be enabled in secondary regions as well if you need redundancy. Messages will be routed to the correct region based on the project\_map anyway. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment for InfraWeave, e.g. dev, test, prod | `string` | n/a | yes |
| <a name="input_is_primary_region"></a> [is\_primary\_region](#input\_is\_primary\_region) | Whether this region is the primary region for global resources such as roles and OIDC provider | `bool` | `false` | no |
| <a name="input_oidc_allowed_github_repos"></a> [oidc\_allowed\_github\_repos](#input\_oidc\_allowed\_github\_repos) | List of allowed GitHub repositories in format ["SomeOrg/repo", "AnotherOrg/another-repo"] for access to the platform | `list(string)` | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_terraform_state_additional_role_arns"></a> [terraform\_state\_additional\_role\_arns](#input\_terraform\_state\_additional\_role\_arns) | Additional IAM role ARN patterns to allow access to the Terraform state bucket of its own account id within the same organization | `list(string)` | <pre>[<br/>  "arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_AdministratorAccess_*"<br/>]</pre> | no |
| <a name="input_waf_rate_limit_per_ip"></a> [waf\_rate\_limit\_per\_ip](#input\_waf\_rate\_limit\_per\_ip) | WAF rate-based rule limit: max requests per 5-minute window per source IP before blocking. Only used when enable\_waf is true. | `number` | `2000` | no |
| <a name="input_workload_account_ids"></a> [workload\_account\_ids](#input\_workload\_account\_ids) | List of workload account IDs to share the observability sink with. Defaults to extracting from all\_workload\_projects if not provided. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_observability_sink_arn"></a> [observability\_sink\_arn](#output\_observability\_sink\_arn) | ARN of the CloudWatch Observability Access Manager sink |
| <a name="output_observability_sink_id"></a> [observability\_sink\_id](#output\_observability\_sink\_id) | ID of the CloudWatch Observability Access Manager sink |
| <a name="output_oidc_role_arn"></a> [oidc\_role\_arn](#output\_oidc\_role\_arn) | n/a |
| <a name="output_webhook_endpoint"></a> [webhook\_endpoint](#output\_webhook\_endpoint) | n/a |
| <a name="output_webserver_api_gateway_url"></a> [webserver\_api\_gateway\_url](#output\_webserver\_api\_gateway\_url) | API Gateway URL for frontend |
| <a name="output_webserver_auth_client_id"></a> [webserver\_auth\_client\_id](#output\_webserver\_auth\_client\_id) | OIDC client ID |
| <a name="output_webserver_auth_domain"></a> [webserver\_auth\_domain](#output\_webserver\_auth\_domain) | Auth domain for frontend login |
| <a name="output_webserver_auth_issuer_url"></a> [webserver\_auth\_issuer\_url](#output\_webserver\_auth\_issuer\_url) | OIDC issuer URL |
| <a name="output_webserver_frontend_config"></a> [webserver\_frontend\_config](#output\_webserver\_frontend\_config) | Frontend environment variables for React app configuration |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.77.0 |

# Examples

Please check out the [how it is used in the bootstrap](https://github.com/infraweave-io/aws-bootstrap/blob/main/central.tf) repository for up-to-date examples if you need a custom solution.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_dashboard.observability](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_dynamodb_resource_policy.change_records](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_resource_policy) | resource |
| [aws_dynamodb_resource_policy.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_resource_policy) | resource |
| [aws_dynamodb_resource_policy.deployments](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_resource_policy) | resource |
| [aws_dynamodb_resource_policy.events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_resource_policy) | resource |
| [aws_dynamodb_resource_policy.modules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_resource_policy) | resource |
| [aws_dynamodb_resource_policy.policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_resource_policy) | resource |
| [aws_dynamodb_resource_policy.terraform_locks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_resource_policy) | resource |
| [aws_dynamodb_table.change_records](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_dynamodb_table.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_dynamodb_table.deployments](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_dynamodb_table.events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_dynamodb_table.modules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_dynamodb_table.policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_dynamodb_table.terraform_locks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_dynamodb_table_item.all_projects](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table_item) | resource |
| [aws_dynamodb_table_item.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table_item) | resource |
| [aws_kms_alias.central_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.central](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_oam_sink.central](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/oam_sink) | resource |
| [aws_oam_sink_policy.central](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/oam_sink_policy) | resource |
| [aws_s3_bucket.change_records_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.modules_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.policies_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.providers_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.it_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_policy.change_records_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.modules_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.policies_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.providers_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.change_records_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.modules_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.policies_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.providers_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.change_records](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.modules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.providers_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.change_records_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.modules_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.policies_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.providers_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.versioning_example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_ssm_parameter.change_records_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.dynamodb_events_table_name](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.modules_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.modules_table_name](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.policies_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_organizations_organization.current_org](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
