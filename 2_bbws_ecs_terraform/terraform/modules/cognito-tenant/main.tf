# Cognito Tenant Module - Main Resources
# Creates per-tenant Cognito User Pool with RBAC groups and WordPress OAuth client

#------------------------------------------------------------------------------
# Data Sources
#------------------------------------------------------------------------------

data "aws_region" "current" {}

#------------------------------------------------------------------------------
# Cognito User Pool
#------------------------------------------------------------------------------

resource "aws_cognito_user_pool" "tenant" {
  name = "bbws-${var.tenant_name}-${var.environment}-user-pool"

  # Username configuration - sign in with email
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # Password policy (LLD Section 4.1)
  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  # MFA configuration - OPTIONAL with TOTP
  mfa_configuration = "OPTIONAL"

  software_token_mfa_configuration {
    enabled = true
  }

  # Custom attribute: tenant_id (immutable)
  schema {
    name                = "tenant_id"
    attribute_data_type = "String"
    mutable             = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  # Account recovery via verified email
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Username case insensitivity
  username_configuration {
    case_sensitive = false
  }

  tags = merge(
    {
      Name        = "bbws-${var.tenant_name}-${var.environment}-user-pool"
      Tenant      = var.tenant_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

#------------------------------------------------------------------------------
# Cognito User Pool Domain (Hosted UI prefix)
#------------------------------------------------------------------------------

resource "aws_cognito_user_pool_domain" "tenant" {
  domain       = "bbws-${var.tenant_name}-${var.environment}"
  user_pool_id = aws_cognito_user_pool.tenant.id
}

#------------------------------------------------------------------------------
# Cognito User Pool Client (WordPress OAuth)
#------------------------------------------------------------------------------

resource "aws_cognito_user_pool_client" "wordpress" {
  name         = "${var.tenant_name}-wordpress-client"
  user_pool_id = aws_cognito_user_pool.tenant.id

  # Generate client secret for server-side OAuth
  generate_secret = true

  # Token validity (LLD Section 4.2)
  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  # Explicit auth flows
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  # OAuth configuration (authorization code grant)
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  supported_identity_providers         = ["COGNITO"]

  # Callback and logout URLs for WordPress
  callback_urls = [
    "https://${var.domain_name}/wp-login.php",
    "https://${var.domain_name}/wp-admin/admin-ajax.php",
  ]

  logout_urls = [
    "https://${var.domain_name}/",
    "https://${var.domain_name}/wp-login.php?loggedout=true",
  ]

  # Security: prevent user existence errors
  prevent_user_existence_errors = "ENABLED"
}

#------------------------------------------------------------------------------
# Cognito User Groups (RBAC - LLD Section 4.3)
#------------------------------------------------------------------------------

resource "aws_cognito_user_group" "admin" {
  name         = "Admin"
  user_pool_id = aws_cognito_user_pool.tenant.id
  description  = "Full administrative access - create/delete users, manage plugins, modify content"
  precedence   = 1
}

resource "aws_cognito_user_group" "operator" {
  name         = "Operator"
  user_pool_id = aws_cognito_user_pool.tenant.id
  description  = "Operational access - manage content, view users, update plugins"
  precedence   = 2
}

resource "aws_cognito_user_group" "viewer" {
  name         = "Viewer"
  user_pool_id = aws_cognito_user_pool.tenant.id
  description  = "Read-only access - view content, view analytics"
  precedence   = 3
}

#------------------------------------------------------------------------------
# Secrets Manager - Store Client Credentials for WordPress Plugin
#------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "cognito_credentials" {
  name        = "bbws/${var.environment}/${var.tenant_name}/cognito"
  description = "Cognito app client credentials for ${var.tenant_name} WordPress integration"

  tags = merge(
    {
      Tenant      = var.tenant_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_secretsmanager_secret_version" "cognito_credentials" {
  secret_id = aws_secretsmanager_secret.cognito_credentials.id

  secret_string = jsonencode({
    user_pool_id = aws_cognito_user_pool.tenant.id
    client_id    = aws_cognito_user_pool_client.wordpress.id
    client_secret = aws_cognito_user_pool_client.wordpress.client_secret
    domain       = "bbws-${var.tenant_name}-${var.environment}"
    region       = data.aws_region.current.id
    domain_url   = "https://${aws_cognito_user_pool_domain.tenant.domain}.auth.${data.aws_region.current.id}.amazoncognito.com"
  })
}
