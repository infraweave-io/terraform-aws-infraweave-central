variable "events_table_name" {
  type = string
}

variable "modules_table_name" {
  type = string
}

variable "deployments_table_name" {
  type = string
}

variable "policies_table_name" {
  type = string
}

variable "change_records_table_name" {
  type = string
}

variable "config_table_name" {
  type = string
}

variable "region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "modules_s3_bucket" {
  type = string
}

variable "policies_s3_bucket" {
  type = string
}

variable "change_records_s3_bucket" {
  type = string
}

variable "providers_s3_bucket" {
  type = string
}

variable "central_account_id" {
  type = string
}

variable "notification_topic_arn" {
  type = string
}

// variable "is_primary_region" removed


// variable "identity_center_enabled" removed

// variable "identity_center_metadata_url" removed


variable "auth_issuer_url" {
  description = "OIDC issuer URL for JWT validation (e.g., https://cognito-idp.us-west-2.amazonaws.com/us-west-2_xxx)"
  type        = string
}

variable "auth_client_id" {
  description = "OIDC client ID used as the JWT audience"
  type        = string
}

variable "auth_domain" {
  description = "Auth domain for frontend login redirects"
  type        = string
  default     = ""
}


variable "cors_allow_origins" {
  description = "List of allowed origins for CORS. Must be explicit origins; \"*\" is rejected because it is unsafe combined with the Authorization header."
  type        = list(string)

  validation {
    condition     = length(var.cors_allow_origins) > 0 && !contains(var.cors_allow_origins, "*")
    error_message = "cors_allow_origins must contain at least one explicit origin and may not include \"*\"."
  }
}

variable "identity_center_instance_arn" {
  description = "IAM Identity Center instance ARN (if in different region)"
  type        = string
  default     = ""
}

variable "identity_center_region" {
  description = "AWS region where IAM Identity Center is enabled"
  type        = string
  default     = ""
}

variable "identity_center_identity_store_id" {
  description = "IAM Identity Center Identity Store ID (e.g., d-xxxxxxxxxx)"
  type        = string
  default     = ""
}

variable "api_lambda_function_name" {
  description = "Name of the API Lambda function to invoke for backend operations"
  type        = string
}

variable "user_pool_domain" {
  description = "Deprecated: Use auth_domain instead."
  type        = string
  default     = ""
}

variable "enable_waf" {
  description = "Attach an AWS WAFv2 web ACL (managed rules + per-IP rate limit) to the API Gateway stage. Disabled by default to avoid the ~$5/Web ACL + ~$1/rule monthly cost; enable for production."
  type        = bool
  default     = false
}

variable "waf_rate_limit_per_ip" {
  description = "WAF rate-based rule limit: max requests per 5-minute window per source IP before blocking. Only used when enable_waf is true."
  type        = number
  default     = 2000

  validation {
    condition     = var.waf_rate_limit_per_ip >= 100 && var.waf_rate_limit_per_ip <= 2000000000
    error_message = "waf_rate_limit_per_ip must be between 100 and 2,000,000,000 (AWS WAF limits)."
  }
}
