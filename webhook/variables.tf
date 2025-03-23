
variable "webhook_image_uri" {
  type = string
}

variable "config_table_name" {
  type = string
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

variable "infraweave_env" {
  type = string
}

variable "region" {
  type = string
}

variable "enable_webhook_processor_endpoint" {
  type = bool
}
