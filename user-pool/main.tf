# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "infraweave-webserver-${var.environment}"

  deletion_protection = "ACTIVE"

  # MFA applies to direct Cognito sign-ins. SAML-federated users (Identity
  # Center) authenticate at the IdP, so MFA enforcement happens there.
  mfa_configuration = "ON"

  software_token_mfa_configuration {
    enabled = true
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = "0"
      max_length = "2048"
    }
  }

  tags = {
    Environment = var.environment
  }

  region = var.region

  lifecycle {
    ignore_changes = [schema]
  }

}


# Cognito User Pool Domain
# Suffix is a deterministic hash of the account ID — keeps the prefix globally
# unique within the region without exposing the AWS account number publicly.
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "infraweave-webserver-${var.environment}-${substr(sha256(var.account_id), 0, 12)}"
  user_pool_id = aws_cognito_user_pool.main.id

  region = var.region
}


# Note: IAM Identity Center application is managed manually in the AWS console
# The SAML identity provider below connects Cognito to your manually configured Identity Center app

# IAM Identity Center SAML Identity Provider for Cognito
resource "aws_cognito_identity_provider" "identity_center" {
  count = var.identity_center_enabled && var.identity_center_metadata_url != "" ? 1 : 0

  user_pool_id  = aws_cognito_user_pool.main.id
  provider_name = "IdentityCenter"
  provider_type = "SAML"

  provider_details = {
    MetadataURL = var.identity_center_metadata_url
  }

  attribute_mapping = {
    email    = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
    username = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
  }


  region = var.region
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "main" {
  name         = "infraweave-webserver-client-${var.environment}"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = false

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  callback_urls                        = var.cognito_callback_urls
  logout_urls                          = var.cognito_logout_urls

  supported_identity_providers = var.identity_center_enabled && var.identity_center_metadata_url != "" ? concat(["COGNITO"], [aws_cognito_identity_provider.identity_center[0].provider_name]) : ["COGNITO"]

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]
  prevent_user_existence_errors = "ENABLED"

  region = var.region

  depends_on = [aws_cognito_identity_provider.identity_center]
}
