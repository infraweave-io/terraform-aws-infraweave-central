
variable "oidc_allowed_github_repos" {
  type    = list(string)
  default = []
}

variable "infraweave_env" {
  type    = string
  default = "prod"
}

variable "create_github_oidc_provider" {
  type = bool
}
