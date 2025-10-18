
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
    "arn:aws:iam::*:role/*AWSReservedSSO_AdministratorAccess_*",
  ]
}
