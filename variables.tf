
variable "environment" {
  type = string
  description = "Environment, e.g. dev, test, prod"
}

variable "region" {
  type = string
  description = "AWS region"
}

variable "central_account_id" {
  type    = string
  default = null
}

variable "organization_id" {
  type = string
  nullable = false
}