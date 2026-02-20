# Cognito Tenant Module - Outputs

#------------------------------------------------------------------------------
# User Pool
#------------------------------------------------------------------------------

output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.tenant.id
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.tenant.arn
}

output "user_pool_domain" {
  description = "Cognito Hosted UI domain URL"
  value       = "https://${aws_cognito_user_pool_domain.tenant.domain}.auth.${data.aws_region.current.id}.amazoncognito.com"
}

#------------------------------------------------------------------------------
# App Client
#------------------------------------------------------------------------------

output "app_client_id" {
  description = "WordPress OAuth app client ID"
  value       = aws_cognito_user_pool_client.wordpress.id
}

#------------------------------------------------------------------------------
# Secrets Manager
#------------------------------------------------------------------------------

output "cognito_secret_arn" {
  description = "ARN of the Secrets Manager secret containing client credentials"
  value       = aws_secretsmanager_secret.cognito_credentials.arn
}

#------------------------------------------------------------------------------
# OAuth Endpoints
#------------------------------------------------------------------------------

output "oauth_endpoints" {
  description = "OAuth 2.0 endpoint URLs for WordPress plugin configuration"
  value = {
    authorize = "https://${aws_cognito_user_pool_domain.tenant.domain}.auth.${data.aws_region.current.id}.amazoncognito.com/oauth2/authorize"
    token     = "https://${aws_cognito_user_pool_domain.tenant.domain}.auth.${data.aws_region.current.id}.amazoncognito.com/oauth2/token"
    userinfo  = "https://${aws_cognito_user_pool_domain.tenant.domain}.auth.${data.aws_region.current.id}.amazoncognito.com/oauth2/userInfo"
    logout    = "https://${aws_cognito_user_pool_domain.tenant.domain}.auth.${data.aws_region.current.id}.amazoncognito.com/logout"
    jwks      = "https://cognito-idp.${data.aws_region.current.id}.amazonaws.com/${aws_cognito_user_pool.tenant.id}/.well-known/jwks.json"
  }
}
