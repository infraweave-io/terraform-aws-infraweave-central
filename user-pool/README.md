# user-pool

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | AWS Account ID | `string` | n/a | yes |
| <a name="input_cognito_callback_urls"></a> [cognito\_callback\_urls](#input\_cognito\_callback\_urls) | List of allowed callback URLs for Cognito | `list(string)` | <pre>[<br/>  "https://localhost:3000/callback"<br/>]</pre> | no |
| <a name="input_cognito_logout_urls"></a> [cognito\_logout\_urls](#input\_cognito\_logout\_urls) | List of allowed logout URLs for Cognito | `list(string)` | <pre>[<br/>  "https://localhost:3000/logout"<br/>]</pre> | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | n/a | yes |
| <a name="input_identity_center_enabled"></a> [identity\_center\_enabled](#input\_identity\_center\_enabled) | Enable IAM Identity Center SAML integration | `bool` | `false` | no |
| <a name="input_identity_center_metadata_url"></a> [identity\_center\_metadata\_url](#input\_identity\_center\_metadata\_url) | IAM Identity Center SAML metadata URL | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_issuer_url"></a> [issuer\_url](#output\_issuer\_url) | OIDC issuer URL used for JWT validation |
| <a name="output_user_pool_arn"></a> [user\_pool\_arn](#output\_user\_pool\_arn) | n/a |
| <a name="output_user_pool_client_id"></a> [user\_pool\_client\_id](#output\_user\_pool\_client\_id) | n/a |
| <a name="output_user_pool_domain"></a> [user\_pool\_domain](#output\_user\_pool\_domain) | n/a |
| <a name="output_user_pool_endpoint"></a> [user\_pool\_endpoint](#output\_user\_pool\_endpoint) | n/a |
| <a name="output_user_pool_id"></a> [user\_pool\_id](#output\_user\_pool\_id) | n/a |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

# Examples

Please check out the [how it is used in the bootstrap](https://github.com/infraweave-io/aws-bootstrap/blob/main/central.tf) repository for up-to-date examples if you need a custom solution.

## Resources

| Name | Type |
|------|------|
| [aws_cognito_identity_provider.identity_center](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_identity_provider) | resource |
| [aws_cognito_user_pool.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool) | resource |
| [aws_cognito_user_pool_client.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client) | resource |
| [aws_cognito_user_pool_domain.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_domain) | resource |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
