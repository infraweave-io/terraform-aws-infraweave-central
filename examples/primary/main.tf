module "workload-project1-dev-us-west-2" {
  source = "git::https://github.com/infraweave-io/terraform-aws-infraweave-workload.git?ref=<VERSION>"

  region = "us-west-2"
  providers = {
    aws = aws.workload-project1-dev-us-west-2
  }

  environment        = local.environment
  central_account_id = local.central_account_id

  all_workload_projects = [ # Only to be set in the primary region of the workload account
    {
      project_id  = "111111111111"
      name        = "Workload Account"
      description = "Workload Account for testing"
      regions     = ["us-west-2", "eu-central-1"]
      github_repos_deploy = [
        "your-org/my-infra",
      ]
      github_repos_oidc = [
        "your-org/module-s3bucket",
        "your-org/module-vpc",
        # ...
      ]
    }
  ]
}
