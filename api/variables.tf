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

variable "is_primary_region" {
  type = bool
}

variable "user_pool_id" {
  type        = string
  description = "The ID of the Cognito User Pool"
  default     = ""
}

variable "cognito_domain" {
  type        = string
  description = "The Cognito domain (e.g., your-domain.auth.us-west-2.amazoncognito.com)"
  default     = ""
}

variable "cognito_client_id" {
  type        = string
  description = "The Cognito User Pool Client ID"
  default     = ""
}

variable "ecs_cluster" {
  type        = string
  description = "The ECS cluster name"
  default     = ""
}
