locals {
  central_account_id      = var.central_account_id
  organization_id = var.organization_id

  dynamodb_table_names = {
    events         = "Events-${local.central_account_id}-${var.region}-${var.environment}",
    modules        = "Modules-${local.central_account_id}-${var.region}-${var.environment}",
    policies       = "Policies-${local.central_account_id}-${var.region}-${var.environment}",
    change_records = "ChangeRecords-${local.central_account_id}-${var.region}-${var.environment}",
    deployments    = "Deployments-${local.central_account_id}-${var.region}-${var.environment}",
    tf_locks       = "TerraformStateDynamoDBLocks-${var.region}-${var.environment}",
  }

  bucket_names = {
    modules        = "tf-modules-${local.central_account_id}-${var.region}-${var.environment}",
    policies       = "tf-policies-${local.central_account_id}-${var.region}-${var.environment}",
    change_records = "tf-change-records-${local.central_account_id}-${var.region}-${var.environment}",
    tf_state       = "tf-state-${local.central_account_id}-${var.region}-${var.environment}",
  }

  notification_topic_arn = "arn:aws:sns:${var.region}:${var.central_account_id}:infraweave-${var.environment}"

  image_version = "v0.0.60-arm64"

  image = "l0j0u4o5/infraweave/gitops-aws:${local.image_version}"
  pull_through_ecr = "infraweave-ecr-public"
  webhook_image_uri = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${local.pull_through_ecr}/${local.image}"
}

module "webhook" {
  count = var.enable_webhook_processor ? 1 : 0

  source = "./webhook"
  
  infraweave_env = var.environment
  region         = var.region
  project_map = var.project_map
  enable_webhook_processor_endpoint = var.enable_webhook_processor_endpoint
  config_table_name = aws_dynamodb_resource_policy.config.id
  webhook_image_uri = local.webhook_image_uri

  providers = {
    aws = aws
  }
}

module "oidc" {
  count = var.enable_oidc_provider ? 1 : 0
  source = "./oidc"
  
  infraweave_env = var.environment
  allowed_github_repos = var.allowed_github_repos

  providers = {
    aws = aws
  }
}

output "webhook_endpoint" {
  value = var.enable_webhook_processor && var.enable_webhook_processor_endpoint ? "${module.webhook[0].webhook_endpoint}" : null
}

output "oidc_role_arn" {
    value = var.enable_oidc_provider ? module.oidc[0].oidc_role_arn : null
}

module "api" {
  source = "./api"

  environment               = var.environment
  region                    = var.region
  account_id                = local.central_account_id
  events_table_name         = resource.aws_dynamodb_table.events.name
  modules_table_name        = resource.aws_dynamodb_table.modules.name
  deployments_table_name    = resource.aws_dynamodb_table.deployments.name
  policies_table_name       = resource.aws_dynamodb_table.policies.name
  change_records_table_name = resource.aws_dynamodb_table.change_records.name
  config_table_name         = resource.aws_dynamodb_table.config.name
  modules_s3_bucket         = resource.aws_s3_bucket.modules_bucket.bucket
  policies_s3_bucket        = resource.aws_s3_bucket.policies_bucket.bucket
  change_records_s3_bucket  = resource.aws_s3_bucket.change_records_bucket.bucket
  subnet_id                 = resource.aws_subnet.public[0].id # TODO: use both subnets
  security_group_id         = resource.aws_security_group.ecs_sg.id
  central_account_id        = local.central_account_id
  notification_topic_arn    = local.notification_topic_arn
}

resource "aws_dynamodb_table" "events" {
  name         = local.dynamodb_table_names.events
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "PK_base_region"
    type = "S"
  }

  global_secondary_index {
    name            = "RegionIndex"
    hash_key        = "PK_base_region"
    range_key       = "SK"
    projection_type = "ALL"
  }

  tags = {
    Name = "EventsTable"
    # Environment = var.environment_tag
  }
}

resource "aws_dynamodb_resource_policy" "events" {
  resource_arn = aws_dynamodb_table.events.arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          # "dynamodb:DeleteItem",
          # "dynamodb:UpdateItem",
          "dynamodb:Query",
        ],
        Resource  = aws_dynamodb_table.events.arn,
        Principal = "*",
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = local.organization_id,
          },
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:role/infraweave_api_role-${var.region}-${var.environment}"
          }
          "ForAllValues:StringLike" = {
            "dynamodb:LeadingKeys" = [
              "EVENT#$${aws:PrincipalAccount}::${var.region}*",
            ]
          }
        }
      },
      {
        Effect = "Allow",
        Action = [
          # "dynamodb:PutItem",
          "dynamodb:GetItem",
          # "dynamodb:DeleteItem",
          # "dynamodb:UpdateItem",
          "dynamodb:Query",
        ],
        Resource  = [
          aws_dynamodb_table.events.arn,
          "${aws_dynamodb_table.events.arn}/index/RegionIndex",
        ],
        Principal = "*",
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = local.organization_id,
          },
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::${local.central_account_id}:role/infraweave_api_role-${var.region}-${var.environment}"
          }
          # StringLike = {
          #   "dynamodb:LeadingKeys" = "$${aws:PrincipalAccount}*"
          # }
        }
      },
    ]
  })
}

resource "aws_ssm_parameter" "dynamodb_events_table_name" {
  name  = "/infraweave/${var.region}/${var.environment}/dynamodb_events_table_name"
  type  = "String"
  value = resource.aws_dynamodb_table.events.name
}

resource "aws_dynamodb_table" "modules" {
  name         = local.dynamodb_table_names.modules
  billing_mode = "PAY_PER_REQUEST"

  # Primary Key: Partition Key (PK) and Sort Key (SK)
  hash_key  = "PK"
  range_key = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  tags = {
    Name = "ModulesTable"
    # Environment = var.environment_tag
  }
}

resource "aws_dynamodb_resource_policy" "modules" {
  resource_arn = aws_dynamodb_table.modules.arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          # "dynamodb:DeleteItem",
          # "dynamodb:UpdateItem",
          "dynamodb:Query",
        ],
        Resource  = aws_dynamodb_table.modules.arn,
        Principal = "*",
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = local.organization_id,
          },
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::${local.central_account_id}:role/infraweave_api_role-${var.region}-${var.environment}"
          }
          # StringLike = {
          #   "dynamodb:LeadingKeys" = "$${aws:PrincipalAccount}*"
          # }
        }
      },
      {
        Effect = "Allow",
        Action = [
          # "dynamodb:PutItem",
          "dynamodb:GetItem",
          # "dynamodb:DeleteItem",
          # "dynamodb:UpdateItem",
          "dynamodb:Query",
        ],
        Resource  = aws_dynamodb_table.modules.arn,
        Principal = "*",
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = local.organization_id,
          },
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:role/infraweave_api_role-${var.region}-${var.environment}"
          }
          # StringLike = {
          #   "dynamodb:LeadingKeys" = "$${aws:PrincipalAccount}*"
          # }
        }
      }
    ]
  })
}

resource "aws_ssm_parameter" "modules_table_name" {
  name  = "/infraweave/${var.region}/${var.environment}/modules_table_name"
  type  = "String"
  value = resource.aws_dynamodb_table.modules.name
}

resource "aws_dynamodb_table" "policies" {
  name         = local.dynamodb_table_names.policies
  billing_mode = "PAY_PER_REQUEST"

  # Primary Key: Partition Key (PK) and Sort Key (SK)
  hash_key  = "PK"
  range_key = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  tags = {
    Name = "PoliciesTable"
    # Environment = var.environment_tag
  }
}

resource "aws_dynamodb_resource_policy" "policies" {
  resource_arn = aws_dynamodb_table.policies.arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          # "dynamodb:DeleteItem",
          # "dynamodb:UpdateItem",
          "dynamodb:Query",
        ],
        Resource  = aws_dynamodb_table.policies.arn,
        Principal = "*",
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = local.organization_id,
          },
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::${local.central_account_id}:role/infraweave_api_role-${var.region}-${var.environment}"
          }
          # StringLike = {
          #   "dynamodb:LeadingKeys" = "$${aws:PrincipalAccount}*"
          # }
        }
      },
      {
        Effect = "Allow",
        Action = [
          # "dynamodb:PutItem",
          "dynamodb:GetItem",
          # "dynamodb:DeleteItem",
          # "dynamodb:UpdateItem",
          "dynamodb:Query",
        ],
        Resource  = aws_dynamodb_table.policies.arn,
        Principal = "*",
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = local.organization_id,
          },
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:role/infraweave_api_role-${var.region}-${var.environment}"
          }
          # StringLike = {
          #   "dynamodb:LeadingKeys" = "$${aws:PrincipalAccount}*"
          # }
        }
      }
    ]
  })
}

resource "aws_dynamodb_table" "change_records" {
  name         = local.dynamodb_table_names.change_records
  billing_mode = "PAY_PER_REQUEST"

  # Primary Key: Partition Key (PK) and Sort Key (SK)
  hash_key  = "PK"
  range_key = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  tags = {
    Name = "ChangeRecordsTable"
    # Environment = var.environment_tag
  }
}

resource "aws_dynamodb_resource_policy" "change_records" {
  resource_arn = aws_dynamodb_table.change_records.arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
        ],
        Resource  = aws_dynamodb_table.change_records.arn,
        Principal = "*",
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = local.organization_id,
          },
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:role/infraweave_api_role-${var.region}-${var.environment}"
          }
          "ForAllValues:StringLike" = {
            "dynamodb:LeadingKeys" = [
              "DESTROY#$${aws:PrincipalAccount}::${var.region}*",
              "APPLY#$${aws:PrincipalAccount}::${var.region}*",
              "PLAN#$${aws:PrincipalAccount}::${var.region}*",
            ]
          }
        }
      }
    ]
  })
}

resource "aws_dynamodb_table" "deployments" {
  name         = local.dynamodb_table_names.deployments
  billing_mode = "PAY_PER_REQUEST"

  # Primary Key: Partition Key (PK) and Sort Key (SK)
  hash_key  = "PK"
  range_key = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {           // Used in GSI for querying deleted items meanwhile querying for one single module + non-deleted items
    name = "deleted_PK" // Since we can't have multiple range keys, we need to combine the deleted flag and PK as a composite key (e.g. "0|DEPLOYMENT_ID#PROJECT_ID::REGION::ENVIRONMENT::DEPLOYMENT_ID")
    type = "S"
  }

  attribute {
    name = "deleted_PK_base" // Used in GSI for querying deleted items (has to include project_id + region for authorization purposes, e.g. "0|DEPLOYMENT_ID#PROJECT_ID::REGION")
    type = "S"
  }

  global_secondary_index {
    name            = "DeletedIndex"
    hash_key        = "deleted_PK_base"
    range_key       = "PK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "ModuleIndex"
    hash_key        = "module_PK_base"
    range_key       = "deleted_PK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "GlobalModuleIndex"
    hash_key        = "module"
    range_key       = "deleted_PK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "DriftCheckIndex"
    hash_key        = "deleted_SK_base"
    range_key       = "next_drift_check_epoch"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "ReverseIndex" # May look weird but need it for leading key condition in IAM policy
    hash_key        = "SK"
    range_key       = "PK"
    projection_type = "ALL"
  }

  attribute {
    name = "module"
    type = "S"
  }

  attribute {
    name = "module_PK_base"
    type = "S"
  }

  attribute {
    name = "deleted_SK_base"
    type = "S"
  }

  attribute {
    name = "next_drift_check_epoch"
    type = "N"
  }

  tags = {
    Name = "DeploymentsTable"
  }
}


resource "aws_dynamodb_resource_policy" "deployments" {
  resource_arn = aws_dynamodb_table.deployments.arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowReadWriteAccessInWorkloadAccount",
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
        ],
        Resource  = [
          aws_dynamodb_table.deployments.arn,
          "${aws_dynamodb_table.deployments.arn}/index/DeletedIndex",
          "${aws_dynamodb_table.deployments.arn}/index/ModuleIndex",
          "${aws_dynamodb_table.deployments.arn}/index/DriftCheckIndex",
          "${aws_dynamodb_table.deployments.arn}/index/ReverseIndex",
        ],
        Principal = "*",
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = local.organization_id,
          },
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:role/infraweave_api_role-${var.region}-${var.environment}"
          }
          "ForAllValues:StringLike" = {
            "dynamodb:LeadingKeys" = [
              "DEPLOYMENT#$${aws:PrincipalAccount}::${var.region}*",
              "DEPENDENT#$${aws:PrincipalAccount}::${var.region}*",
              "PLAN#$${aws:PrincipalAccount}::${var.region}*",
              "0|DEPLOYMENT#$${aws:PrincipalAccount}::${var.region}*", # For DeletedIndex
              "1|DEPLOYMENT#$${aws:PrincipalAccount}::${var.region}*", # For DeletedIndex
              "0|METADATA#$${aws:PrincipalAccount}::${var.region}*", # For DriftCheckIndex
              "MODULE#$${aws:PrincipalAccount}::${var.region}*", # For ModuleIndex
              "PROJECT#$${aws:PrincipalAccount}",
              "PROJECTS", // Allow listing all projects (TODO: review this if it's a good idea)
            ]
          }
        }
      },
      {
        Sid = "CentralFullReadAccess",
        Effect = "Allow",
        Action = [
          # "dynamodb:PutItem",
          "dynamodb:GetItem",
          # "dynamodb:DeleteItem",
          # "dynamodb:UpdateItem",
          "dynamodb:Query",
        ],
        Resource  = [
          aws_dynamodb_table.deployments.arn,
          "${aws_dynamodb_table.deployments.arn}/index/DeletedIndex",
          "${aws_dynamodb_table.deployments.arn}/index/ModuleIndex",
          "${aws_dynamodb_table.deployments.arn}/index/DriftCheckIndex",
        ],
        Principal = "*",
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = local.organization_id,
          },
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::${local.central_account_id}:role/infraweave_api_role-${var.region}-${var.environment}"
          }
          "ForAllValues:StringLike" = {
            "dynamodb:LeadingKeys" = [
              "DEPLOYMENT#*::${var.region}*",
              "DEPENDENT#*::${var.region}*",
              "PLAN#*::${var.region}*",
              "0|DEPLOYMENT#*::${var.region}*", # For DeletedIndex
              "1|DEPLOYMENT#*::${var.region}*", # For DeletedIndex
              "0|METADATA#*::${var.region}*", # For DriftCheckIndex
              "MODULE#*::${var.region}*", # For ModuleIndex
              "PROJECTS",
              "PROJECT#*",
            ]
          }
        }
      },
      {
        Sid = "CentralWriteModuleAndProjectAccess",
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          # "dynamodb:DeleteItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
        ],
        Resource  = [
          aws_dynamodb_table.deployments.arn,
          "${aws_dynamodb_table.deployments.arn}/index/DeletedIndex",
          "${aws_dynamodb_table.deployments.arn}/index/ModuleIndex",
          "${aws_dynamodb_table.deployments.arn}/index/DriftCheckIndex",
        ],
        Principal = "*",
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = local.organization_id,
          },
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::${local.central_account_id}:role/infraweave_api_role-${var.region}-${var.environment}"
          }
          "ForAllValues:StringLike" = {
            "dynamodb:LeadingKeys" = [
              "MODULE#*::${var.region}*", # For ModuleIndex
              "PROJECTS",
              "PROJECT#*",
            ]
          }
        }
      }
    ]
  })
}

resource "aws_dynamodb_table" "config" {
  name           = "Config-${var.central_account_id}-${var.region}-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "PK"

  attribute {
    name = "PK"
    type = "S"
  }
}

resource "aws_dynamodb_resource_policy" "config" {
  resource_arn = aws_dynamodb_table.config.arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
        ],
        Resource  = [
          aws_dynamodb_table.config.arn,
        ],
        Principal = "*",
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = local.organization_id,
          },
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::${local.central_account_id}:role/infraweave_api_role-${var.region}-${var.environment}",
          }
        }
      }
      # TODO: Add deny statement here for modifying the table
    ]
  })
}

resource "aws_s3_bucket" "modules_bucket" {
  # bucket_prefix = "modules-bucket-${var.region}-${var.environment}"
  bucket = local.bucket_names.modules

  force_destroy = true

  tags = {
    Name        = "ModulesBucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_policy" "modules_bucket" {
  bucket = aws_s3_bucket.modules_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowReadModulesForEveryone",
        Effect   = "Allow",
        Principal = "*",
        Action   = [
          "s3:GetObject",
          # "s3:PutObject",
          # "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.modules_bucket.arn}",       # Bucket-level actions
          "${aws_s3_bucket.modules_bucket.arn}/*"     # Object-level actions
        ],
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = local.organization_id
          },
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:role/infraweave_api_role-${var.region}-${var.environment}"
          }
        }
      },
      {
        Sid = "AllowWriteModulesForCentral",
        Effect   = "Allow",
        Principal = "*",
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          # "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.modules_bucket.arn}",       # Bucket-level actions
          "${aws_s3_bucket.modules_bucket.arn}/*"     # Object-level actions
        ],
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = local.organization_id
          },
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::${local.central_account_id}:role/infraweave_api_role-${var.region}-${var.environment}"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket" "policies_bucket" {
  # bucket_prefix = "policies-bucket-${var.region}-${var.environment}"
  bucket = local.bucket_names.policies

  force_destroy = true

  tags = {
    Name        = "PoliciesBucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_policy" "policies_bucket" {
  bucket = aws_s3_bucket.policies_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowReadPolicyForEveryone",
        Effect   = "Allow",
        Principal = "*",
        Action   = [
          "s3:GetObject",
          # "s3:PutObject",
          # "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.policies_bucket.arn}",       # Bucket-level actions
          "${aws_s3_bucket.policies_bucket.arn}/*"     # Object-level actions
        ],
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = local.organization_id
          },
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:role/infraweave_api_role-${var.region}-${var.environment}"
          }
        }
      },
      {
        Sid = "AllowWritePolicyForCentral",
        Effect   = "Allow",
        Principal = "*",
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          # "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.policies_bucket.arn}",       # Bucket-level actions
          "${aws_s3_bucket.policies_bucket.arn}/*"     # Object-level actions
        ],
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = local.organization_id
          },
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::${local.central_account_id}:role/infraweave_api_role-${var.region}-${var.environment}"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket" "change_records_bucket" {
  # bucket_prefix = "change-records-${var.region}-${var.environment}"
  bucket = local.bucket_names.change_records

  force_destroy = true

  tags = {
    Name        = "ChangeRecordsBucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_policy" "change_records_bucket" {
  bucket = aws_s3_bucket.change_records_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Principal = "*",
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          # "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.change_records_bucket.arn}",       # Bucket-level actions
          "${aws_s3_bucket.change_records_bucket.arn}/*"     # Object-level actions
        ],
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = local.organization_id
          },
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:role/infraweave_api_role-${var.region}-${var.environment}"
          }
        }
      }
    ]
  })
}


resource "aws_ssm_parameter" "modules_bucket" {
  name  = "/infraweave/${var.region}/${var.environment}/modules_bucket"
  type  = "String"
  value = resource.aws_s3_bucket.modules_bucket.bucket
}

resource "aws_ssm_parameter" "policies_bucket" {
  name  = "/infraweave/${var.region}/${var.environment}/policies_bucket"
  type  = "String"
  value = resource.aws_s3_bucket.policies_bucket.bucket
}

resource "aws_ssm_parameter" "change_records_bucket" {
  name  = "/infraweave/${var.region}/${var.environment}/change_records_bucket"
  type  = "String"
  value = resource.aws_s3_bucket.change_records_bucket.bucket
}



resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = element(["${var.region}a", "${var.region}b"], count.index)
  map_public_ip_on_launch = true
}

resource "aws_ssm_parameter" "ecs_subnet_id" {
  name  = "/infraweave/${var.region}/${var.environment}/ecs_subnet_id"
  type  = "String"
  value = resource.aws_subnet.public[0].id # TODO: use both subnets
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.main.id

  # No ingress rules

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 53
    to_port   = 53
    protocol  = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_caller_identity" "current" {}

# NOTE: Currently requires authenticated access to the registry

# resource "aws_ecr_repository" "pull_through_ecr" {
#   name = "infraweave"

#   image_tag_mutability = "MUTABLE"
#   image_scanning_configuration {
#     scan_on_push = true
#   }
# }

# resource "aws_ecr_pull_through_cache_rule" "rule" {
#   ecr_repository_prefix = "infraweave-io"
#   upstream_registry_url = "ghcr.io"
# }


resource "aws_s3_bucket" "terraform_state" {
  bucket = local.bucket_names.tf_state

  force_destroy = true

  tags = {
    Name = "TerraformStateBucket"
    # Environment = var.environment
    # Region      = var.region
  }
}

resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        # Bucket-level actions
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:ListBucket",
        Resource  = "${aws_s3_bucket.terraform_state.arn}",
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = local.organization_id
          },
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:role/ecs-infraweave-${var.region}-${var.environment}-service-role"
          }
        }
      },
      {
        # Object-level actions
        Effect    = "Allow",
        Principal = "*",
        Action    = [
          "s3:GetObject",
          "s3:PutObject",
          # "s3:DeleteObject"
        ],
        Resource  = "${aws_s3_bucket.terraform_state.arn}/$${aws:PrincipalAccount}/*",
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = local.organization_id
          },
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:role/ecs-infraweave-${var.region}-${var.environment}-service-role"
          },
        }
      }
    ]
  })
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_dynamodb_table" "terraform_locks" {
  name         = local.dynamodb_table_names.tf_locks
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # lifecycle {
  #   prevent_destroy = true
  # }

  tags = {
    Name = "TerraformStateLocks"
    # Environment = var.environment_tag
  }
}


resource "aws_dynamodb_resource_policy" "terraform_locks" {
  resource_arn = aws_dynamodb_table.terraform_locks.arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
        ],
        Resource  = [
          aws_dynamodb_table.terraform_locks.arn,
        ],
        Principal = "*",
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = local.organization_id,
          },
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:role/ecs-infraweave-${var.region}-${var.environment}-service-role"
          }
          "ForAllValues:StringLike" = {
            "dynamodb:LeadingKeys" = "${local.bucket_names.tf_state}/$${aws:PrincipalAccount}/*"
          }
        }
      }
    ]
  })
}
