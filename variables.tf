variable "environment" {
  type        = string
  description = "Environment for InfraWeave, e.g. dev, test, prod"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "enable_webhook_processor" {
  description = "Create a webhook processor for the region, should be enabled in all regions if enabled in primary"
  type        = bool
  default     = false
}

variable "enable_webhook_processor_endpoint" {
  description = "Create a public webhook endpoint for the region for GitHub application or Gitlab Webhook integration. Only needed for primary, however, it can be enabled in secondary regions as well if you need redundancy. Messages will be routed to the correct region based on the project_map anyway."
  type        = bool
  default     = false
}

variable "oidc_allowed_github_repos" {
  type        = list(string)
  description = "List of allowed GitHub repositories in format [\"SomeOrg/repo\", \"AnotherOrg/another-repo\"] for access to the platform"
  default     = []
}

variable "all_regions" {
  description = "List of all regions that forms the InfraWeave platform"
  type        = list(string)
}

variable "all_workload_projects" {
  description = "List of workload project names to project id + regions, github_repos should to be set when `enable_webhook_processor` is true"
  type = list(
    object({
      project_id          = string
      name                = string
      description         = string
      regions             = list(string)
      github_repos_deploy = list(string)
      github_repos_oidc   = list(string)
    })
  )
}

variable "create_github_oidc_provider" {
  type    = bool
  default = true
}

variable "terraform_state_additional_role_arns" {
  description = "Additional IAM role ARN patterns to allow access to the Terraform state bucket of its own account id within the same organization"
  type        = list(string)
  default = [
    "arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_AdministratorAccess_*",
  ]
}

variable "is_primary_region" {
  type        = bool
  default     = false
  description = "Whether this region is the primary region for global resources such as roles and OIDC provider"
}

variable "enable_observability" {
  type        = bool
  default     = true
  description = "Enable CloudWatch cross-account observability with OAM sink and dashboard"
}

variable "workload_account_ids" {
  type        = list(string)
  default     = []
  description = "List of workload account IDs to share the observability sink with. Defaults to extracting from all_workload_projects if not provided."
}

variable "enable_api_gw" {
  description = "Enable the web API Gateway with JWT authentication. Requires auth_config to be set."
  type        = bool
  default     = true
}

variable "enable_waf" {
  description = "Attach an AWS WAFv2 web ACL (managed rules + per-IP rate limit) to the web API Gateway. Disabled by default to avoid the ~$5/Web ACL + ~$1/rule monthly cost per region; enable for production."
  type        = bool
  default     = false
}

variable "waf_rate_limit_per_ip" {
  description = "WAF rate-based rule limit: max requests per 5-minute window per source IP before blocking. Only used when enable_waf is true."
  type        = number
  default     = 2000
}

variable "cors_allow_origins" {
  description = "List of allowed origins for the web API CORS configuration. Must be explicit origins (e.g. https://app.example.com); \"*\" is rejected because it is unsafe combined with the Authorization header."
  type        = list(string)
  default     = ["http://localhost:3000"]

  validation {
    condition     = length(var.cors_allow_origins) > 0 && !contains(var.cors_allow_origins, "*")
    error_message = "cors_allow_origins must contain at least one explicit origin and may not include \"*\"."
  }
}

variable "auth_config" {
  description = "OIDC authentication configuration for the web API. Works with any JWT-compatible provider (Cognito, Okta, Auth0, etc.)"
  type = object({
    issuer_url   = string           # Full OIDC issuer URL (e.g., https://cognito-idp.us-west-2.amazonaws.com/us-west-2_xxx, https://dev-123.okta.com/oauth2/default)
    client_id    = string           # OIDC client/application ID (audience for JWT validation)
    domain       = optional(string) # Auth domain for frontend login redirects (e.g., myapp.auth.us-west-2.amazoncognito.com, dev-123.okta.com)
    user_pool_id = optional(string) # Cognito User Pool ID — only needed when using Cognito for admin API operations
  })
  default = null
}




