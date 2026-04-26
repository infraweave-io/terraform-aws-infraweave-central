variable "environment" {
  type        = string
  description = "Environment name"
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "identity_center_enabled" {
  description = "Enable IAM Identity Center SAML integration"
  type        = bool
  default     = false
}

variable "identity_center_metadata_url" {
  description = "IAM Identity Center SAML metadata URL"
  type        = string
  default     = ""
}

variable "cognito_callback_urls" {
  description = "List of allowed callback URLs for Cognito"
  type        = list(string)
  default     = ["https://localhost:3000/callback"]
}

variable "cognito_logout_urls" {
  description = "List of allowed logout URLs for Cognito"
  type        = list(string)
  default     = ["https://localhost:3000/logout"]
}
