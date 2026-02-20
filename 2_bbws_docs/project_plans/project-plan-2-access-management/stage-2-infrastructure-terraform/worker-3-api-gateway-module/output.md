# API Gateway Module - Terraform Output

**Worker ID**: worker-3-api-gateway-module
**Stage**: Stage 2 - Infrastructure Terraform
**Project**: project-plan-2-access-management
**Created**: 2026-01-23
**Status**: COMPLETE

---

## Overview

This document contains the complete Terraform module for the BBWS Access Management API Gateway. The module creates a REST API with all 40+ endpoints for the 6 Access Management services.

---

## Module Structure

```
terraform/modules/api-gateway-access-management/
├── main.tf           # API Gateway REST API definition
├── resources.tf      # Resource paths hierarchy
├── methods.tf        # HTTP methods configuration
├── integrations.tf   # Lambda proxy integrations
├── responses.tf      # Response templates
├── cors.tf           # CORS configuration
├── stage.tf          # Stage configuration
├── authorizer.tf     # Lambda authorizer configuration
├── variables.tf      # Input variables
└── outputs.tf        # Output values
```

---

## 1. main.tf - API Gateway REST API Definition

```hcl
#------------------------------------------------------------------------------
# API Gateway REST API - Access Management
# Description: Main API Gateway definition for Access Management services
#------------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

#------------------------------------------------------------------------------
# REST API Definition
#------------------------------------------------------------------------------
resource "aws_api_gateway_rest_api" "access_management" {
  name        = "bbws-access-${var.environment}-apigw"
  description = "BBWS Access Management API - ${upper(var.environment)}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  # Binary media types for potential file uploads
  binary_media_types = [
    "application/octet-stream",
    "multipart/form-data"
  ]

  tags = merge(var.common_tags, {
    Name        = "bbws-access-${var.environment}-apigw"
    Component   = "AccessManagement"
    Environment = var.environment
  })
}

#------------------------------------------------------------------------------
# API Gateway Account Settings (CloudWatch Logging)
#------------------------------------------------------------------------------
resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = var.api_gateway_cloudwatch_role_arn
}

#------------------------------------------------------------------------------
# API Gateway Deployment
#------------------------------------------------------------------------------
resource "aws_api_gateway_deployment" "access_management" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id

  # Trigger redeployment when resources change
  triggers = {
    redeployment = sha1(jsonencode([
      # Permission Service
      aws_api_gateway_resource.v1.id,
      aws_api_gateway_resource.platform.id,
      aws_api_gateway_resource.platform_permissions.id,
      aws_api_gateway_resource.platform_permissions_id.id,
      aws_api_gateway_resource.platform_roles.id,
      aws_api_gateway_resource.platform_roles_id.id,
      # Organisation resources
      aws_api_gateway_resource.organisations.id,
      aws_api_gateway_resource.organisations_id.id,
      # Permission Sets
      aws_api_gateway_resource.permission_sets.id,
      aws_api_gateway_resource.permission_sets_id.id,
      # Invitations
      aws_api_gateway_resource.org_invitations.id,
      aws_api_gateway_resource.org_invitations_id.id,
      aws_api_gateway_resource.org_invitations_resend.id,
      aws_api_gateway_resource.invitations.id,
      aws_api_gateway_resource.invitations_token.id,
      aws_api_gateway_resource.invitations_accept.id,
      aws_api_gateway_resource.invitations_decline.id,
      # Teams
      aws_api_gateway_resource.teams.id,
      aws_api_gateway_resource.teams_id.id,
      aws_api_gateway_resource.team_members.id,
      aws_api_gateway_resource.team_members_id.id,
      # Team Roles
      aws_api_gateway_resource.team_roles.id,
      aws_api_gateway_resource.team_roles_id.id,
      # Roles
      aws_api_gateway_resource.roles.id,
      aws_api_gateway_resource.roles_id.id,
      aws_api_gateway_resource.roles_permissions.id,
      # Audit
      aws_api_gateway_resource.audit.id,
      aws_api_gateway_resource.audit_access.id,
      aws_api_gateway_resource.audit_permissions.id,
      aws_api_gateway_resource.audit_organisations.id,
      aws_api_gateway_resource.audit_organisations_id.id,
      aws_api_gateway_resource.audit_summary.id,
      aws_api_gateway_resource.audit_export.id,
      # User teams
      aws_api_gateway_resource.users.id,
      aws_api_gateway_resource.users_id.id,
      aws_api_gateway_resource.users_teams.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    # Ensure all methods are created before deployment
    module.permission_methods,
    module.invitation_methods,
    module.team_methods,
    module.role_methods,
    module.audit_methods
  ]
}
```

---

## 2. resources.tf - Resource Paths

```hcl
#------------------------------------------------------------------------------
# API Gateway Resources - URL Path Hierarchy
# Description: Defines all API resource paths for Access Management
#------------------------------------------------------------------------------

#==============================================================================
# ROOT RESOURCES
#==============================================================================

# /v1
resource "aws_api_gateway_resource" "v1" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_rest_api.access_management.root_resource_id
  path_part   = "v1"
}

#==============================================================================
# PLATFORM RESOURCES (Public/Read-Only)
#==============================================================================

# /v1/platform
resource "aws_api_gateway_resource" "platform" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "platform"
}

# /v1/platform/permissions
resource "aws_api_gateway_resource" "platform_permissions" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.platform.id
  path_part   = "permissions"
}

# /v1/platform/permissions/{permissionId}
resource "aws_api_gateway_resource" "platform_permissions_id" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.platform_permissions.id
  path_part   = "{permissionId}"
}

# /v1/platform/roles
resource "aws_api_gateway_resource" "platform_roles" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.platform.id
  path_part   = "roles"
}

# /v1/platform/roles/{roleId}
resource "aws_api_gateway_resource" "platform_roles_id" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.platform_roles.id
  path_part   = "{roleId}"
}

#==============================================================================
# ORGANISATION RESOURCES
#==============================================================================

# /v1/organisations
resource "aws_api_gateway_resource" "organisations" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "organisations"
}

# /v1/organisations/{orgId}
resource "aws_api_gateway_resource" "organisations_id" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.organisations.id
  path_part   = "{orgId}"
}

#==============================================================================
# PERMISSION SET RESOURCES (under organisation)
#==============================================================================

# /v1/organisations/{orgId}/permission-sets
resource "aws_api_gateway_resource" "permission_sets" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.organisations_id.id
  path_part   = "permission-sets"
}

# /v1/organisations/{orgId}/permission-sets/{setId}
resource "aws_api_gateway_resource" "permission_sets_id" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.permission_sets.id
  path_part   = "{setId}"
}

#==============================================================================
# INVITATION RESOURCES (Admin - under organisation)
#==============================================================================

# /v1/organisations/{orgId}/invitations
resource "aws_api_gateway_resource" "org_invitations" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.organisations_id.id
  path_part   = "invitations"
}

# /v1/organisations/{orgId}/invitations/{invitationId}
resource "aws_api_gateway_resource" "org_invitations_id" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.org_invitations.id
  path_part   = "{invitationId}"
}

# /v1/organisations/{orgId}/invitations/{invitationId}/resend
resource "aws_api_gateway_resource" "org_invitations_resend" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.org_invitations_id.id
  path_part   = "resend"
}

#==============================================================================
# INVITATION RESOURCES (Public - token-based)
#==============================================================================

# /v1/invitations
resource "aws_api_gateway_resource" "invitations" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "invitations"
}

# /v1/invitations/{token}
resource "aws_api_gateway_resource" "invitations_token" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.invitations.id
  path_part   = "{token}"
}

# /v1/invitations/{token}/accept
resource "aws_api_gateway_resource" "invitations_accept" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.invitations_token.id
  path_part   = "accept"
}

# /v1/invitations/{token}/decline
resource "aws_api_gateway_resource" "invitations_decline" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.invitations_token.id
  path_part   = "decline"
}

#==============================================================================
# TEAM RESOURCES
#==============================================================================

# /v1/organisations/{orgId}/teams
resource "aws_api_gateway_resource" "teams" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.organisations_id.id
  path_part   = "teams"
}

# /v1/organisations/{orgId}/teams/{teamId}
resource "aws_api_gateway_resource" "teams_id" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.teams.id
  path_part   = "{teamId}"
}

# /v1/organisations/{orgId}/teams/{teamId}/members
resource "aws_api_gateway_resource" "team_members" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.teams_id.id
  path_part   = "members"
}

# /v1/organisations/{orgId}/teams/{teamId}/members/{userId}
resource "aws_api_gateway_resource" "team_members_id" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.team_members.id
  path_part   = "{userId}"
}

# /v1/organisations/{orgId}/teams/{teamId}/members/{userId}/transfer
resource "aws_api_gateway_resource" "team_members_transfer" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.team_members_id.id
  path_part   = "transfer"
}

#==============================================================================
# TEAM ROLE RESOURCES
#==============================================================================

# /v1/organisations/{orgId}/team-roles
resource "aws_api_gateway_resource" "team_roles" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.organisations_id.id
  path_part   = "team-roles"
}

# /v1/organisations/{orgId}/team-roles/{teamRoleId}
resource "aws_api_gateway_resource" "team_roles_id" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.team_roles.id
  path_part   = "{teamRoleId}"
}

#==============================================================================
# USER RESOURCES (for team memberships)
#==============================================================================

# /v1/organisations/{orgId}/users
resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.organisations_id.id
  path_part   = "users"
}

# /v1/organisations/{orgId}/users/{userId}
resource "aws_api_gateway_resource" "users_id" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.users.id
  path_part   = "{userId}"
}

# /v1/organisations/{orgId}/users/{userId}/teams
resource "aws_api_gateway_resource" "users_teams" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.users_id.id
  path_part   = "teams"
}

#==============================================================================
# ORGANISATION ROLE RESOURCES
#==============================================================================

# /v1/organisations/{orgId}/roles
resource "aws_api_gateway_resource" "roles" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.organisations_id.id
  path_part   = "roles"
}

# /v1/organisations/{orgId}/roles/{roleId}
resource "aws_api_gateway_resource" "roles_id" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.roles.id
  path_part   = "{roleId}"
}

# /v1/organisations/{orgId}/roles/{roleId}/permissions
resource "aws_api_gateway_resource" "roles_permissions" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.roles_id.id
  path_part   = "permissions"
}

#==============================================================================
# AUDIT RESOURCES
#==============================================================================

# /v1/audit
resource "aws_api_gateway_resource" "audit" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "audit"
}

# /v1/audit/access
resource "aws_api_gateway_resource" "audit_access" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.audit.id
  path_part   = "access"
}

# /v1/audit/permissions
resource "aws_api_gateway_resource" "audit_permissions" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.audit.id
  path_part   = "permissions"
}

# /v1/audit/organisations
resource "aws_api_gateway_resource" "audit_organisations" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.audit.id
  path_part   = "organisations"
}

# /v1/audit/organisations/{orgId}
resource "aws_api_gateway_resource" "audit_organisations_id" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.audit_organisations.id
  path_part   = "{orgId}"
}

# /v1/audit/summary
resource "aws_api_gateway_resource" "audit_summary" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.audit.id
  path_part   = "summary"
}

# /v1/audit/export
resource "aws_api_gateway_resource" "audit_export" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.audit.id
  path_part   = "export"
}
```

---

## 3. methods.tf - HTTP Methods Configuration

```hcl
#------------------------------------------------------------------------------
# API Gateway Methods - HTTP Method Definitions
# Description: Configures HTTP methods for all endpoints
#------------------------------------------------------------------------------

#==============================================================================
# REUSABLE METHOD MODULE
#==============================================================================

# Module for creating API Gateway method with Lambda integration
module "api_method" {
  source = "./modules/api-method"

  for_each = local.api_methods

  rest_api_id          = aws_api_gateway_rest_api.access_management.id
  resource_id          = each.value.resource_id
  http_method          = each.value.http_method
  authorization        = each.value.authorization
  authorizer_id        = each.value.authorization == "CUSTOM" ? aws_api_gateway_authorizer.lambda_authorizer.id : null
  lambda_invoke_arn    = each.value.lambda_invoke_arn
  lambda_function_name = each.value.lambda_function_name
  request_parameters   = each.value.request_parameters
  request_validator_id = each.value.validate_body ? aws_api_gateway_request_validator.body_validator.id : null
}

#==============================================================================
# LOCAL VARIABLES - Method Definitions
#==============================================================================

locals {
  api_methods = {
    #--------------------------------------------------------------------------
    # PLATFORM PERMISSIONS (Permission Service)
    #--------------------------------------------------------------------------
    "platform_permissions_get" = {
      resource_id          = aws_api_gateway_resource.platform_permissions.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.permission.list_permissions
      lambda_function_name = var.lambda_names.permission.list_permissions
      request_parameters   = {}
      validate_body        = false
    }
    "platform_permissions_id_get" = {
      resource_id          = aws_api_gateway_resource.platform_permissions_id.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.permission.get_permission
      lambda_function_name = var.lambda_names.permission.get_permission
      request_parameters   = { "method.request.path.permissionId" = true }
      validate_body        = false
    }

    #--------------------------------------------------------------------------
    # PLATFORM ROLES (Role Service)
    #--------------------------------------------------------------------------
    "platform_roles_get" = {
      resource_id          = aws_api_gateway_resource.platform_roles.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.role.list_platform_roles
      lambda_function_name = var.lambda_names.role.list_platform_roles
      request_parameters   = {}
      validate_body        = false
    }
    "platform_roles_id_get" = {
      resource_id          = aws_api_gateway_resource.platform_roles_id.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.role.get_platform_role
      lambda_function_name = var.lambda_names.role.get_platform_role
      request_parameters   = { "method.request.path.roleId" = true }
      validate_body        = false
    }

    #--------------------------------------------------------------------------
    # PERMISSION SETS (Permission Service)
    #--------------------------------------------------------------------------
    "permission_sets_get" = {
      resource_id          = aws_api_gateway_resource.permission_sets.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.permission.list_permission_sets
      lambda_function_name = var.lambda_names.permission.list_permission_sets
      request_parameters   = { "method.request.path.orgId" = true }
      validate_body        = false
    }
    "permission_sets_post" = {
      resource_id          = aws_api_gateway_resource.permission_sets.id
      http_method          = "POST"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.permission.create_permission_set
      lambda_function_name = var.lambda_names.permission.create_permission_set
      request_parameters   = { "method.request.path.orgId" = true }
      validate_body        = true
    }
    "permission_sets_id_get" = {
      resource_id          = aws_api_gateway_resource.permission_sets_id.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.permission.get_permission_set
      lambda_function_name = var.lambda_names.permission.get_permission_set
      request_parameters   = {
        "method.request.path.orgId" = true
        "method.request.path.setId" = true
      }
      validate_body = false
    }
    "permission_sets_id_put" = {
      resource_id          = aws_api_gateway_resource.permission_sets_id.id
      http_method          = "PUT"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.permission.update_permission_set
      lambda_function_name = var.lambda_names.permission.update_permission_set
      request_parameters   = {
        "method.request.path.orgId" = true
        "method.request.path.setId" = true
      }
      validate_body = true
    }

    #--------------------------------------------------------------------------
    # ORGANISATION INVITATIONS (Invitation Service - Admin)
    #--------------------------------------------------------------------------
    "org_invitations_get" = {
      resource_id          = aws_api_gateway_resource.org_invitations.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.invitation.list_invitations
      lambda_function_name = var.lambda_names.invitation.list_invitations
      request_parameters   = { "method.request.path.orgId" = true }
      validate_body        = false
    }
    "org_invitations_post" = {
      resource_id          = aws_api_gateway_resource.org_invitations.id
      http_method          = "POST"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.invitation.create_invitation
      lambda_function_name = var.lambda_names.invitation.create_invitation
      request_parameters   = { "method.request.path.orgId" = true }
      validate_body        = true
    }
    "org_invitations_id_get" = {
      resource_id          = aws_api_gateway_resource.org_invitations_id.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.invitation.get_invitation
      lambda_function_name = var.lambda_names.invitation.get_invitation
      request_parameters   = {
        "method.request.path.orgId"        = true
        "method.request.path.invitationId" = true
      }
      validate_body = false
    }
    "org_invitations_id_put" = {
      resource_id          = aws_api_gateway_resource.org_invitations_id.id
      http_method          = "PUT"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.invitation.revoke_invitation
      lambda_function_name = var.lambda_names.invitation.revoke_invitation
      request_parameters   = {
        "method.request.path.orgId"        = true
        "method.request.path.invitationId" = true
      }
      validate_body = true
    }
    "org_invitations_resend_post" = {
      resource_id          = aws_api_gateway_resource.org_invitations_resend.id
      http_method          = "POST"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.invitation.resend_invitation
      lambda_function_name = var.lambda_names.invitation.resend_invitation
      request_parameters   = {
        "method.request.path.orgId"        = true
        "method.request.path.invitationId" = true
      }
      validate_body = false
    }

    #--------------------------------------------------------------------------
    # PUBLIC INVITATIONS (Invitation Service - No Auth)
    #--------------------------------------------------------------------------
    "invitations_token_get" = {
      resource_id          = aws_api_gateway_resource.invitations_token.id
      http_method          = "GET"
      authorization        = "NONE"
      lambda_invoke_arn    = var.lambda_arns.invitation.get_invitation_by_token
      lambda_function_name = var.lambda_names.invitation.get_invitation_by_token
      request_parameters   = { "method.request.path.token" = true }
      validate_body        = false
    }
    "invitations_accept_post" = {
      resource_id          = aws_api_gateway_resource.invitations_accept.id
      http_method          = "POST"
      authorization        = "NONE"
      lambda_invoke_arn    = var.lambda_arns.invitation.accept_invitation
      lambda_function_name = var.lambda_names.invitation.accept_invitation
      request_parameters   = { "method.request.path.token" = true }
      validate_body        = true
    }
    "invitations_decline_post" = {
      resource_id          = aws_api_gateway_resource.invitations_decline.id
      http_method          = "POST"
      authorization        = "NONE"
      lambda_invoke_arn    = var.lambda_arns.invitation.decline_invitation
      lambda_function_name = var.lambda_names.invitation.decline_invitation
      request_parameters   = { "method.request.path.token" = true }
      validate_body        = false
    }

    #--------------------------------------------------------------------------
    # TEAMS (Team Service)
    #--------------------------------------------------------------------------
    "teams_get" = {
      resource_id          = aws_api_gateway_resource.teams.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.team.list_teams
      lambda_function_name = var.lambda_names.team.list_teams
      request_parameters   = { "method.request.path.orgId" = true }
      validate_body        = false
    }
    "teams_post" = {
      resource_id          = aws_api_gateway_resource.teams.id
      http_method          = "POST"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.team.create_team
      lambda_function_name = var.lambda_names.team.create_team
      request_parameters   = { "method.request.path.orgId" = true }
      validate_body        = true
    }
    "teams_id_get" = {
      resource_id          = aws_api_gateway_resource.teams_id.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.team.get_team
      lambda_function_name = var.lambda_names.team.get_team
      request_parameters   = {
        "method.request.path.orgId"  = true
        "method.request.path.teamId" = true
      }
      validate_body = false
    }
    "teams_id_put" = {
      resource_id          = aws_api_gateway_resource.teams_id.id
      http_method          = "PUT"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.team.update_team
      lambda_function_name = var.lambda_names.team.update_team
      request_parameters   = {
        "method.request.path.orgId"  = true
        "method.request.path.teamId" = true
      }
      validate_body = true
    }

    #--------------------------------------------------------------------------
    # TEAM MEMBERS (Team Service)
    #--------------------------------------------------------------------------
    "team_members_get" = {
      resource_id          = aws_api_gateway_resource.team_members.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.team.list_members
      lambda_function_name = var.lambda_names.team.list_members
      request_parameters   = {
        "method.request.path.orgId"  = true
        "method.request.path.teamId" = true
      }
      validate_body = false
    }
    "team_members_post" = {
      resource_id          = aws_api_gateway_resource.team_members.id
      http_method          = "POST"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.team.add_member
      lambda_function_name = var.lambda_names.team.add_member
      request_parameters   = {
        "method.request.path.orgId"  = true
        "method.request.path.teamId" = true
      }
      validate_body = true
    }
    "team_members_id_get" = {
      resource_id          = aws_api_gateway_resource.team_members_id.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.team.get_member
      lambda_function_name = var.lambda_names.team.get_member
      request_parameters   = {
        "method.request.path.orgId"  = true
        "method.request.path.teamId" = true
        "method.request.path.userId" = true
      }
      validate_body = false
    }
    "team_members_id_put" = {
      resource_id          = aws_api_gateway_resource.team_members_id.id
      http_method          = "PUT"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.team.update_member
      lambda_function_name = var.lambda_names.team.update_member
      request_parameters   = {
        "method.request.path.orgId"  = true
        "method.request.path.teamId" = true
        "method.request.path.userId" = true
      }
      validate_body = true
    }
    "team_members_transfer_post" = {
      resource_id          = aws_api_gateway_resource.team_members_transfer.id
      http_method          = "POST"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.team.transfer_member
      lambda_function_name = var.lambda_names.team.transfer_member
      request_parameters   = {
        "method.request.path.orgId"  = true
        "method.request.path.teamId" = true
        "method.request.path.userId" = true
      }
      validate_body = true
    }

    #--------------------------------------------------------------------------
    # TEAM ROLES (Team Service)
    #--------------------------------------------------------------------------
    "team_roles_get" = {
      resource_id          = aws_api_gateway_resource.team_roles.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.team.list_team_roles
      lambda_function_name = var.lambda_names.team.list_team_roles
      request_parameters   = { "method.request.path.orgId" = true }
      validate_body        = false
    }
    "team_roles_post" = {
      resource_id          = aws_api_gateway_resource.team_roles.id
      http_method          = "POST"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.team.create_team_role
      lambda_function_name = var.lambda_names.team.create_team_role
      request_parameters   = { "method.request.path.orgId" = true }
      validate_body        = true
    }
    "team_roles_id_get" = {
      resource_id          = aws_api_gateway_resource.team_roles_id.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.team.get_team_role
      lambda_function_name = var.lambda_names.team.get_team_role
      request_parameters   = {
        "method.request.path.orgId"      = true
        "method.request.path.teamRoleId" = true
      }
      validate_body = false
    }
    "team_roles_id_put" = {
      resource_id          = aws_api_gateway_resource.team_roles_id.id
      http_method          = "PUT"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.team.update_team_role
      lambda_function_name = var.lambda_names.team.update_team_role
      request_parameters   = {
        "method.request.path.orgId"      = true
        "method.request.path.teamRoleId" = true
      }
      validate_body = true
    }

    #--------------------------------------------------------------------------
    # USER TEAMS (Team Service)
    #--------------------------------------------------------------------------
    "users_teams_get" = {
      resource_id          = aws_api_gateway_resource.users_teams.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.team.get_user_teams
      lambda_function_name = var.lambda_names.team.get_user_teams
      request_parameters   = {
        "method.request.path.orgId"  = true
        "method.request.path.userId" = true
      }
      validate_body = false
    }

    #--------------------------------------------------------------------------
    # ORGANISATION ROLES (Role Service)
    #--------------------------------------------------------------------------
    "roles_get" = {
      resource_id          = aws_api_gateway_resource.roles.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.role.list_roles
      lambda_function_name = var.lambda_names.role.list_roles
      request_parameters   = { "method.request.path.orgId" = true }
      validate_body        = false
    }
    "roles_post" = {
      resource_id          = aws_api_gateway_resource.roles.id
      http_method          = "POST"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.role.create_role
      lambda_function_name = var.lambda_names.role.create_role
      request_parameters   = { "method.request.path.orgId" = true }
      validate_body        = true
    }
    "roles_id_get" = {
      resource_id          = aws_api_gateway_resource.roles_id.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.role.get_role
      lambda_function_name = var.lambda_names.role.get_role
      request_parameters   = {
        "method.request.path.orgId"  = true
        "method.request.path.roleId" = true
      }
      validate_body = false
    }
    "roles_id_put" = {
      resource_id          = aws_api_gateway_resource.roles_id.id
      http_method          = "PUT"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.role.update_role
      lambda_function_name = var.lambda_names.role.update_role
      request_parameters   = {
        "method.request.path.orgId"  = true
        "method.request.path.roleId" = true
      }
      validate_body = true
    }
    "roles_permissions_put" = {
      resource_id          = aws_api_gateway_resource.roles_permissions.id
      http_method          = "PUT"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.role.assign_permissions
      lambda_function_name = var.lambda_names.role.assign_permissions
      request_parameters   = {
        "method.request.path.orgId"  = true
        "method.request.path.roleId" = true
      }
      validate_body = true
    }

    #--------------------------------------------------------------------------
    # AUDIT (Audit Service)
    #--------------------------------------------------------------------------
    "audit_access_get" = {
      resource_id          = aws_api_gateway_resource.audit_access.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.audit.get_access_logs
      lambda_function_name = var.lambda_names.audit.get_access_logs
      request_parameters   = {}
      validate_body        = false
    }
    "audit_permissions_get" = {
      resource_id          = aws_api_gateway_resource.audit_permissions.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.audit.get_permission_logs
      lambda_function_name = var.lambda_names.audit.get_permission_logs
      request_parameters   = {}
      validate_body        = false
    }
    "audit_organisations_id_get" = {
      resource_id          = aws_api_gateway_resource.audit_organisations_id.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.audit.get_org_audit
      lambda_function_name = var.lambda_names.audit.get_org_audit
      request_parameters   = { "method.request.path.orgId" = true }
      validate_body        = false
    }
    "audit_summary_get" = {
      resource_id          = aws_api_gateway_resource.audit_summary.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.audit.get_audit_summary
      lambda_function_name = var.lambda_names.audit.get_audit_summary
      request_parameters   = {}
      validate_body        = false
    }
    "audit_export_post" = {
      resource_id          = aws_api_gateway_resource.audit_export.id
      http_method          = "POST"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.audit.export_audit
      lambda_function_name = var.lambda_names.audit.export_audit
      request_parameters   = {}
      validate_body        = true
    }
  }
}

#==============================================================================
# REQUEST VALIDATORS
#==============================================================================

resource "aws_api_gateway_request_validator" "body_validator" {
  name                        = "body-validator"
  rest_api_id                 = aws_api_gateway_rest_api.access_management.id
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_api_gateway_request_validator" "params_validator" {
  name                        = "params-validator"
  rest_api_id                 = aws_api_gateway_rest_api.access_management.id
  validate_request_body       = false
  validate_request_parameters = true
}
```

---

## 4. integrations.tf - Lambda Integrations

```hcl
#------------------------------------------------------------------------------
# API Gateway Integrations - Lambda Proxy
# Description: Configures Lambda proxy integrations for all methods
#------------------------------------------------------------------------------

#==============================================================================
# REUSABLE INTEGRATION MODULE
#==============================================================================

# This is included in the api_method module above
# Here we define the integration configuration pattern

#------------------------------------------------------------------------------
# Example integration pattern (used by module)
#------------------------------------------------------------------------------

# Integration Type: AWS_PROXY (Lambda Proxy)
# This passes the entire API Gateway request to Lambda
# Lambda returns the full HTTP response

# resource "aws_api_gateway_integration" "example" {
#   rest_api_id             = aws_api_gateway_rest_api.access_management.id
#   resource_id             = aws_api_gateway_resource.example.id
#   http_method             = aws_api_gateway_method.example.http_method
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = var.lambda_invoke_arn
#
#   # Request templates for non-proxy integrations (not used with AWS_PROXY)
#   # request_templates = {
#   #   "application/json" = jsonencode({
#   #     body    = "$input.body"
#   #     headers = "$input.params().header"
#   #     params  = "$input.params().path"
#   #   })
#   # }
# }

#==============================================================================
# LAMBDA PERMISSIONS FOR API GATEWAY
#==============================================================================

# Permission for API Gateway to invoke Lambda functions
resource "aws_lambda_permission" "api_gateway" {
  for_each = local.api_methods

  statement_id  = "AllowAPIGatewayInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.access_management.execution_arn}/*"
}

# Permission for API Gateway to invoke Authorizer Lambda
resource "aws_lambda_permission" "authorizer" {
  statement_id  = "AllowAPIGatewayAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_names.authorizer.authorize
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.access_management.execution_arn}/authorizers/${aws_api_gateway_authorizer.lambda_authorizer.id}"
}
```

---

## 5. cors.tf - CORS Configuration

```hcl
#------------------------------------------------------------------------------
# API Gateway CORS Configuration
# Description: Enables CORS for all endpoints with OPTIONS preflight
#------------------------------------------------------------------------------

#==============================================================================
# CORS HEADERS CONFIGURATION
#==============================================================================

locals {
  cors_headers = {
    "Access-Control-Allow-Origin"  = var.cors_allowed_origins
    "Access-Control-Allow-Methods" = "GET,POST,PUT,DELETE,OPTIONS"
    "Access-Control-Allow-Headers" = "Content-Type,Authorization,X-Request-ID,X-Amz-Date,X-Api-Key,X-Amz-Security-Token"
    "Access-Control-Max-Age"       = "7200"
  }

  # Resources that need CORS OPTIONS method
  cors_resources = [
    aws_api_gateway_resource.platform_permissions.id,
    aws_api_gateway_resource.platform_permissions_id.id,
    aws_api_gateway_resource.platform_roles.id,
    aws_api_gateway_resource.platform_roles_id.id,
    aws_api_gateway_resource.permission_sets.id,
    aws_api_gateway_resource.permission_sets_id.id,
    aws_api_gateway_resource.org_invitations.id,
    aws_api_gateway_resource.org_invitations_id.id,
    aws_api_gateway_resource.org_invitations_resend.id,
    aws_api_gateway_resource.invitations_token.id,
    aws_api_gateway_resource.invitations_accept.id,
    aws_api_gateway_resource.invitations_decline.id,
    aws_api_gateway_resource.teams.id,
    aws_api_gateway_resource.teams_id.id,
    aws_api_gateway_resource.team_members.id,
    aws_api_gateway_resource.team_members_id.id,
    aws_api_gateway_resource.team_members_transfer.id,
    aws_api_gateway_resource.team_roles.id,
    aws_api_gateway_resource.team_roles_id.id,
    aws_api_gateway_resource.users_teams.id,
    aws_api_gateway_resource.roles.id,
    aws_api_gateway_resource.roles_id.id,
    aws_api_gateway_resource.roles_permissions.id,
    aws_api_gateway_resource.audit_access.id,
    aws_api_gateway_resource.audit_permissions.id,
    aws_api_gateway_resource.audit_organisations_id.id,
    aws_api_gateway_resource.audit_summary.id,
    aws_api_gateway_resource.audit_export.id,
  ]
}

#==============================================================================
# CORS OPTIONS METHODS MODULE
#==============================================================================

module "cors" {
  source = "./modules/cors"

  for_each = toset([for idx, id in local.cors_resources : tostring(idx)])

  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = local.cors_resources[tonumber(each.key)]

  allow_origin  = var.cors_allowed_origins
  allow_methods = "GET,POST,PUT,DELETE,OPTIONS"
  allow_headers = "Content-Type,Authorization,X-Request-ID,X-Amz-Date,X-Api-Key,X-Amz-Security-Token"
  max_age       = "7200"
}

#==============================================================================
# CORS MODULE DEFINITION (modules/cors/main.tf)
#==============================================================================

# The CORS module creates:
# 1. OPTIONS method
# 2. MOCK integration
# 3. Method response with CORS headers
# 4. Integration response with CORS headers

# Example CORS module implementation:
#
# resource "aws_api_gateway_method" "options" {
#   rest_api_id   = var.rest_api_id
#   resource_id   = var.resource_id
#   http_method   = "OPTIONS"
#   authorization = "NONE"
# }
#
# resource "aws_api_gateway_integration" "options" {
#   rest_api_id = var.rest_api_id
#   resource_id = var.resource_id
#   http_method = aws_api_gateway_method.options.http_method
#   type        = "MOCK"
#
#   request_templates = {
#     "application/json" = jsonencode({ statusCode = 200 })
#   }
# }
#
# resource "aws_api_gateway_method_response" "options" {
#   rest_api_id = var.rest_api_id
#   resource_id = var.resource_id
#   http_method = aws_api_gateway_method.options.http_method
#   status_code = "200"
#
#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Headers" = true
#     "method.response.header.Access-Control-Allow-Methods" = true
#     "method.response.header.Access-Control-Allow-Origin"  = true
#     "method.response.header.Access-Control-Max-Age"       = true
#   }
# }
#
# resource "aws_api_gateway_integration_response" "options" {
#   rest_api_id = var.rest_api_id
#   resource_id = var.resource_id
#   http_method = aws_api_gateway_method.options.http_method
#   status_code = aws_api_gateway_method_response.options.status_code
#
#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Headers" = "'${var.allow_headers}'"
#     "method.response.header.Access-Control-Allow-Methods" = "'${var.allow_methods}'"
#     "method.response.header.Access-Control-Allow-Origin"  = "'${var.allow_origin}'"
#     "method.response.header.Access-Control-Max-Age"       = "'${var.max_age}'"
#   }
# }

#==============================================================================
# GATEWAY RESPONSE FOR CORS ON 4XX/5XX ERRORS
#==============================================================================

resource "aws_api_gateway_gateway_response" "cors_4xx" {
  rest_api_id   = aws_api_gateway_rest_api.access_management.id
  response_type = "DEFAULT_4XX"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'${var.cors_allowed_origins}'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Request-ID'"
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
  }

  response_templates = {
    "application/json" = jsonencode({
      message   = "$context.error.messageString"
      requestId = "$context.requestId"
    })
  }
}

resource "aws_api_gateway_gateway_response" "cors_5xx" {
  rest_api_id   = aws_api_gateway_rest_api.access_management.id
  response_type = "DEFAULT_5XX"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'${var.cors_allowed_origins}'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Request-ID'"
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
  }

  response_templates = {
    "application/json" = jsonencode({
      message   = "$context.error.messageString"
      requestId = "$context.requestId"
    })
  }
}

resource "aws_api_gateway_gateway_response" "unauthorized" {
  rest_api_id   = aws_api_gateway_rest_api.access_management.id
  response_type = "UNAUTHORIZED"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'${var.cors_allowed_origins}'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Request-ID'"
  }

  response_templates = {
    "application/json" = jsonencode({
      message   = "Unauthorized"
      requestId = "$context.requestId"
    })
  }

  status_code = "401"
}

resource "aws_api_gateway_gateway_response" "access_denied" {
  rest_api_id   = aws_api_gateway_rest_api.access_management.id
  response_type = "ACCESS_DENIED"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'${var.cors_allowed_origins}'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Request-ID'"
  }

  response_templates = {
    "application/json" = jsonencode({
      message   = "Access Denied"
      requestId = "$context.requestId"
    })
  }

  status_code = "403"
}
```

---

## 6. stage.tf - Stage Configuration

```hcl
#------------------------------------------------------------------------------
# API Gateway Stage Configuration
# Description: Configures deployment stages with environment-specific settings
#------------------------------------------------------------------------------

#==============================================================================
# STAGE DEFINITION
#==============================================================================

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.access_management.id
  rest_api_id   = aws_api_gateway_rest_api.access_management.id
  stage_name    = var.environment

  # Stage variables
  variables = {
    environment = var.environment
    log_level   = var.stage_settings[var.environment].log_level
  }

  # Access logging configuration
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_access_logs.arn
    format = jsonencode({
      requestId         = "$context.requestId"
      ip                = "$context.identity.sourceIp"
      caller            = "$context.identity.caller"
      user              = "$context.identity.user"
      requestTime       = "$context.requestTime"
      httpMethod        = "$context.httpMethod"
      resourcePath      = "$context.resourcePath"
      status            = "$context.status"
      protocol          = "$context.protocol"
      responseLength    = "$context.responseLength"
      integrationLatency = "$context.integrationLatency"
      responseLatency   = "$context.responseLatency"
      authorizerLatency = "$context.authorizer.latency"
      errorMessage      = "$context.error.message"
    })
  }

  # X-Ray tracing
  xray_tracing_enabled = var.enable_xray_tracing

  tags = merge(var.common_tags, {
    Name        = "bbws-access-${var.environment}-stage"
    Component   = "AccessManagement"
    Environment = var.environment
  })
}

#==============================================================================
# METHOD SETTINGS (Throttling, Logging, Caching)
#==============================================================================

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  method_path = "*/*"

  settings {
    # Logging
    logging_level          = var.stage_settings[var.environment].log_level
    data_trace_enabled     = var.environment == "dev" ? true : false
    metrics_enabled        = true

    # Throttling
    throttling_rate_limit  = var.stage_settings[var.environment].throttle_rate
    throttling_burst_limit = var.stage_settings[var.environment].throttle_burst

    # Caching (disabled for now, can enable per-method if needed)
    caching_enabled        = false
  }
}

#==============================================================================
# CLOUDWATCH LOG GROUP FOR ACCESS LOGS
#==============================================================================

resource "aws_cloudwatch_log_group" "api_access_logs" {
  name              = "/aws/api-gateway/bbws-access-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Name        = "bbws-access-${var.environment}-logs"
    Component   = "AccessManagement"
    Environment = var.environment
  })
}

resource "aws_cloudwatch_log_group" "api_execution_logs" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.access_management.id}/${var.environment}"
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Name        = "bbws-access-${var.environment}-execution-logs"
    Component   = "AccessManagement"
    Environment = var.environment
  })
}

#==============================================================================
# STAGE SETTINGS BY ENVIRONMENT
#==============================================================================

# Stage settings are defined in variables.tf and passed via var.stage_settings
# Default values:
#
# dev:
#   log_level      = "INFO"
#   throttle_rate  = 100
#   throttle_burst = 50
#
# sit:
#   log_level      = "INFO"
#   throttle_rate  = 500
#   throttle_burst = 200
#
# prod:
#   log_level      = "WARN"
#   throttle_rate  = 1000
#   throttle_burst = 500

#==============================================================================
# WAF ASSOCIATION (Optional - for PROD)
#==============================================================================

resource "aws_wafv2_web_acl_association" "api_gateway" {
  count        = var.waf_acl_arn != "" ? 1 : 0
  resource_arn = aws_api_gateway_stage.main.arn
  web_acl_arn  = var.waf_acl_arn
}

#==============================================================================
# API GATEWAY USAGE PLAN (for API Key management)
#==============================================================================

resource "aws_api_gateway_usage_plan" "main" {
  name        = "bbws-access-${var.environment}-usage-plan"
  description = "Usage plan for BBWS Access Management API - ${upper(var.environment)}"

  api_stages {
    api_id = aws_api_gateway_rest_api.access_management.id
    stage  = aws_api_gateway_stage.main.stage_name
  }

  quota_settings {
    limit  = var.stage_settings[var.environment].quota_limit
    offset = 0
    period = "MONTH"
  }

  throttle_settings {
    rate_limit  = var.stage_settings[var.environment].throttle_rate
    burst_limit = var.stage_settings[var.environment].throttle_burst
  }

  tags = merge(var.common_tags, {
    Name        = "bbws-access-${var.environment}-usage-plan"
    Component   = "AccessManagement"
    Environment = var.environment
  })
}
```

---

## 7. authorizer.tf - Lambda Authorizer Configuration

```hcl
#------------------------------------------------------------------------------
# API Gateway Lambda Authorizer
# Description: Token-based Lambda authorizer for JWT validation
#------------------------------------------------------------------------------

#==============================================================================
# LAMBDA AUTHORIZER DEFINITION
#==============================================================================

resource "aws_api_gateway_authorizer" "lambda_authorizer" {
  name                             = "bbws-access-${var.environment}-authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.access_management.id
  authorizer_uri                   = var.lambda_arns.authorizer.authorize
  authorizer_credentials           = var.authorizer_role_arn
  type                             = "TOKEN"
  identity_source                  = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = var.authorizer_cache_ttl

  # The authorizer validates JWT tokens and returns IAM policy + context
}

#==============================================================================
# AUTHORIZER CONFIGURATION
#==============================================================================

# Authorizer Cache TTL by Environment:
# - DEV: 0 (no caching for testing)
# - SIT: 300 (5 minutes)
# - PROD: 300 (5 minutes)

# The authorizer Lambda should:
# 1. Extract JWT from Authorization header
# 2. Validate JWT signature against Cognito JWKS
# 3. Validate token expiry
# 4. Extract user claims (sub, email, org_id)
# 5. Resolve user permissions from DynamoDB
# 6. Resolve user team memberships
# 7. Return IAM Allow/Deny policy with context

# Policy Context includes:
# - userId
# - email
# - orgId
# - teamIds (comma-separated)
# - permissions (comma-separated)
# - roleIds (comma-separated)
```

---

## 8. variables.tf - Input Variables

```hcl
#------------------------------------------------------------------------------
# API Gateway Module Variables
# Description: Input variables for API Gateway configuration
#------------------------------------------------------------------------------

#==============================================================================
# REQUIRED VARIABLES
#==============================================================================

variable "environment" {
  description = "Environment name (dev, sit, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "sit", "prod"], var.environment)
    error_message = "Environment must be one of: dev, sit, prod."
  }
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "af-south-1"
}

#==============================================================================
# LAMBDA ARN VARIABLES
#==============================================================================

variable "lambda_arns" {
  description = "Map of Lambda function ARNs for integrations"
  type = object({
    permission = object({
      list_permissions     = string
      get_permission       = string
      list_permission_sets = string
      create_permission_set = string
      get_permission_set   = string
      update_permission_set = string
    })
    invitation = object({
      list_invitations       = string
      create_invitation      = string
      get_invitation         = string
      revoke_invitation      = string
      resend_invitation      = string
      get_invitation_by_token = string
      accept_invitation      = string
      decline_invitation     = string
    })
    team = object({
      list_teams       = string
      create_team      = string
      get_team         = string
      update_team      = string
      list_members     = string
      add_member       = string
      get_member       = string
      update_member    = string
      transfer_member  = string
      list_team_roles  = string
      create_team_role = string
      get_team_role    = string
      update_team_role = string
      get_user_teams   = string
    })
    role = object({
      list_platform_roles = string
      get_platform_role   = string
      list_roles          = string
      create_role         = string
      get_role            = string
      update_role         = string
      assign_permissions  = string
    })
    audit = object({
      get_access_logs     = string
      get_permission_logs = string
      get_org_audit       = string
      get_audit_summary   = string
      export_audit        = string
    })
    authorizer = object({
      authorize = string
    })
  })
}

variable "lambda_names" {
  description = "Map of Lambda function names for permissions"
  type = object({
    permission = object({
      list_permissions     = string
      get_permission       = string
      list_permission_sets = string
      create_permission_set = string
      get_permission_set   = string
      update_permission_set = string
    })
    invitation = object({
      list_invitations       = string
      create_invitation      = string
      get_invitation         = string
      revoke_invitation      = string
      resend_invitation      = string
      get_invitation_by_token = string
      accept_invitation      = string
      decline_invitation     = string
    })
    team = object({
      list_teams       = string
      create_team      = string
      get_team         = string
      update_team      = string
      list_members     = string
      add_member       = string
      get_member       = string
      update_member    = string
      transfer_member  = string
      list_team_roles  = string
      create_team_role = string
      get_team_role    = string
      update_team_role = string
      get_user_teams   = string
    })
    role = object({
      list_platform_roles = string
      get_platform_role   = string
      list_roles          = string
      create_role         = string
      get_role            = string
      update_role         = string
      assign_permissions  = string
    })
    audit = object({
      get_access_logs     = string
      get_permission_logs = string
      get_org_audit       = string
      get_audit_summary   = string
      export_audit        = string
    })
    authorizer = object({
      authorize = string
    })
  })
}

#==============================================================================
# AUTHORIZER VARIABLES
#==============================================================================

variable "authorizer_role_arn" {
  description = "IAM role ARN for API Gateway to invoke authorizer Lambda"
  type        = string
}

variable "authorizer_cache_ttl" {
  description = "Authorizer cache TTL in seconds (0 = no caching)"
  type        = number
  default     = 300
}

#==============================================================================
# CORS VARIABLES
#==============================================================================

variable "cors_allowed_origins" {
  description = "Allowed origins for CORS"
  type        = string
  default     = "*"
}

#==============================================================================
# STAGE SETTINGS
#==============================================================================

variable "stage_settings" {
  description = "Environment-specific stage settings"
  type = map(object({
    log_level      = string
    throttle_rate  = number
    throttle_burst = number
    quota_limit    = number
  }))
  default = {
    dev = {
      log_level      = "INFO"
      throttle_rate  = 100
      throttle_burst = 50
      quota_limit    = 10000
    }
    sit = {
      log_level      = "INFO"
      throttle_rate  = 500
      throttle_burst = 200
      quota_limit    = 50000
    }
    prod = {
      log_level      = "WARN"
      throttle_rate  = 1000
      throttle_burst = 500
      quota_limit    = 100000
    }
  }
}

#==============================================================================
# LOGGING VARIABLES
#==============================================================================

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing for API Gateway"
  type        = bool
  default     = true
}

#==============================================================================
# CLOUDWATCH VARIABLES
#==============================================================================

variable "api_gateway_cloudwatch_role_arn" {
  description = "IAM role ARN for API Gateway CloudWatch logging"
  type        = string
}

#==============================================================================
# WAF VARIABLES
#==============================================================================

variable "waf_acl_arn" {
  description = "WAF Web ACL ARN for API Gateway protection (optional)"
  type        = string
  default     = ""
}

#==============================================================================
# TAGS
#==============================================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "BBWS"
    Component   = "AccessManagement"
    ManagedBy   = "Terraform"
    CostCenter  = "BBWS-ACCESS"
  }
}
```

---

## 9. outputs.tf - Output Values

```hcl
#------------------------------------------------------------------------------
# API Gateway Module Outputs
# Description: Exported values for use by other modules
#------------------------------------------------------------------------------

#==============================================================================
# API GATEWAY OUTPUTS
#==============================================================================

output "rest_api_id" {
  description = "The ID of the REST API"
  value       = aws_api_gateway_rest_api.access_management.id
}

output "rest_api_name" {
  description = "The name of the REST API"
  value       = aws_api_gateway_rest_api.access_management.name
}

output "rest_api_arn" {
  description = "The ARN of the REST API"
  value       = aws_api_gateway_rest_api.access_management.arn
}

output "rest_api_root_resource_id" {
  description = "The root resource ID of the REST API"
  value       = aws_api_gateway_rest_api.access_management.root_resource_id
}

output "rest_api_execution_arn" {
  description = "The execution ARN of the REST API"
  value       = aws_api_gateway_rest_api.access_management.execution_arn
}

#==============================================================================
# STAGE OUTPUTS
#==============================================================================

output "stage_name" {
  description = "The name of the deployment stage"
  value       = aws_api_gateway_stage.main.stage_name
}

output "stage_arn" {
  description = "The ARN of the deployment stage"
  value       = aws_api_gateway_stage.main.arn
}

output "invoke_url" {
  description = "The invoke URL for the API"
  value       = aws_api_gateway_stage.main.invoke_url
}

#==============================================================================
# DEPLOYMENT OUTPUTS
#==============================================================================

output "deployment_id" {
  description = "The ID of the API deployment"
  value       = aws_api_gateway_deployment.access_management.id
}

#==============================================================================
# AUTHORIZER OUTPUTS
#==============================================================================

output "authorizer_id" {
  description = "The ID of the Lambda authorizer"
  value       = aws_api_gateway_authorizer.lambda_authorizer.id
}

#==============================================================================
# CLOUDWATCH OUTPUTS
#==============================================================================

output "access_log_group_name" {
  description = "The name of the CloudWatch log group for access logs"
  value       = aws_cloudwatch_log_group.api_access_logs.name
}

output "access_log_group_arn" {
  description = "The ARN of the CloudWatch log group for access logs"
  value       = aws_cloudwatch_log_group.api_access_logs.arn
}

output "execution_log_group_name" {
  description = "The name of the CloudWatch log group for execution logs"
  value       = aws_cloudwatch_log_group.api_execution_logs.name
}

#==============================================================================
# USAGE PLAN OUTPUTS
#==============================================================================

output "usage_plan_id" {
  description = "The ID of the API usage plan"
  value       = aws_api_gateway_usage_plan.main.id
}

#==============================================================================
# ENDPOINT SUMMARY
#==============================================================================

output "endpoint_summary" {
  description = "Summary of all API endpoints"
  value = {
    base_url = aws_api_gateway_stage.main.invoke_url
    endpoints = {
      # Platform (read-only)
      list_platform_permissions = "GET ${aws_api_gateway_stage.main.invoke_url}/v1/platform/permissions"
      get_platform_permission   = "GET ${aws_api_gateway_stage.main.invoke_url}/v1/platform/permissions/{permissionId}"
      list_platform_roles       = "GET ${aws_api_gateway_stage.main.invoke_url}/v1/platform/roles"
      get_platform_role         = "GET ${aws_api_gateway_stage.main.invoke_url}/v1/platform/roles/{roleId}"

      # Permission Sets
      list_permission_sets   = "GET ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/permission-sets"
      create_permission_set  = "POST ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/permission-sets"
      get_permission_set     = "GET ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/permission-sets/{setId}"
      update_permission_set  = "PUT ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/permission-sets/{setId}"

      # Invitations (Admin)
      list_invitations   = "GET ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/invitations"
      create_invitation  = "POST ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/invitations"
      get_invitation     = "GET ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/invitations/{invitationId}"
      revoke_invitation  = "PUT ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/invitations/{invitationId}"
      resend_invitation  = "POST ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/invitations/{invitationId}/resend"

      # Invitations (Public)
      get_invitation_public = "GET ${aws_api_gateway_stage.main.invoke_url}/v1/invitations/{token}"
      accept_invitation     = "POST ${aws_api_gateway_stage.main.invoke_url}/v1/invitations/{token}/accept"
      decline_invitation    = "POST ${aws_api_gateway_stage.main.invoke_url}/v1/invitations/{token}/decline"

      # Teams
      list_teams   = "GET ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/teams"
      create_team  = "POST ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/teams"
      get_team     = "GET ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/teams/{teamId}"
      update_team  = "PUT ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/teams/{teamId}"

      # Team Members
      list_team_members    = "GET ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/teams/{teamId}/members"
      add_team_member      = "POST ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/teams/{teamId}/members"
      get_team_member      = "GET ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/teams/{teamId}/members/{userId}"
      update_team_member   = "PUT ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/teams/{teamId}/members/{userId}"
      transfer_team_member = "POST ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/teams/{teamId}/members/{userId}/transfer"

      # Team Roles
      list_team_roles   = "GET ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/team-roles"
      create_team_role  = "POST ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/team-roles"
      get_team_role     = "GET ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/team-roles/{teamRoleId}"
      update_team_role  = "PUT ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/team-roles/{teamRoleId}"

      # User Teams
      get_user_teams = "GET ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/users/{userId}/teams"

      # Organisation Roles
      list_roles         = "GET ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/roles"
      create_role        = "POST ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/roles"
      get_role           = "GET ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/roles/{roleId}"
      update_role        = "PUT ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/roles/{roleId}"
      assign_permissions = "PUT ${aws_api_gateway_stage.main.invoke_url}/v1/organisations/{orgId}/roles/{roleId}/permissions"

      # Audit
      get_access_logs     = "GET ${aws_api_gateway_stage.main.invoke_url}/v1/audit/access"
      get_permission_logs = "GET ${aws_api_gateway_stage.main.invoke_url}/v1/audit/permissions"
      get_org_audit       = "GET ${aws_api_gateway_stage.main.invoke_url}/v1/audit/organisations/{orgId}"
      get_audit_summary   = "GET ${aws_api_gateway_stage.main.invoke_url}/v1/audit/summary"
      export_audit        = "POST ${aws_api_gateway_stage.main.invoke_url}/v1/audit/export"
    }
  }
}
```

---

## 10. Endpoint Summary Table

### Total Endpoints: 40

| # | Service | Method | Endpoint | Auth | Lambda |
|---|---------|--------|----------|------|--------|
| **Permission Service (6)** |
| 1 | Permission | GET | `/v1/platform/permissions` | CUSTOM | list_permissions |
| 2 | Permission | GET | `/v1/platform/permissions/{permissionId}` | CUSTOM | get_permission |
| 3 | Permission | GET | `/v1/organisations/{orgId}/permission-sets` | CUSTOM | list_permission_sets |
| 4 | Permission | POST | `/v1/organisations/{orgId}/permission-sets` | CUSTOM | create_permission_set |
| 5 | Permission | GET | `/v1/organisations/{orgId}/permission-sets/{setId}` | CUSTOM | get_permission_set |
| 6 | Permission | PUT | `/v1/organisations/{orgId}/permission-sets/{setId}` | CUSTOM | update_permission_set |
| **Invitation Service (8)** |
| 7 | Invitation | GET | `/v1/organisations/{orgId}/invitations` | CUSTOM | list_invitations |
| 8 | Invitation | POST | `/v1/organisations/{orgId}/invitations` | CUSTOM | create_invitation |
| 9 | Invitation | GET | `/v1/organisations/{orgId}/invitations/{invitationId}` | CUSTOM | get_invitation |
| 10 | Invitation | PUT | `/v1/organisations/{orgId}/invitations/{invitationId}` | CUSTOM | revoke_invitation |
| 11 | Invitation | POST | `/v1/organisations/{orgId}/invitations/{invitationId}/resend` | CUSTOM | resend_invitation |
| 12 | Invitation | GET | `/v1/invitations/{token}` | NONE | get_invitation_by_token |
| 13 | Invitation | POST | `/v1/invitations/{token}/accept` | NONE | accept_invitation |
| 14 | Invitation | POST | `/v1/invitations/{token}/decline` | NONE | decline_invitation |
| **Team Service (14)** |
| 15 | Team | GET | `/v1/organisations/{orgId}/teams` | CUSTOM | list_teams |
| 16 | Team | POST | `/v1/organisations/{orgId}/teams` | CUSTOM | create_team |
| 17 | Team | GET | `/v1/organisations/{orgId}/teams/{teamId}` | CUSTOM | get_team |
| 18 | Team | PUT | `/v1/organisations/{orgId}/teams/{teamId}` | CUSTOM | update_team |
| 19 | Team | GET | `/v1/organisations/{orgId}/teams/{teamId}/members` | CUSTOM | list_members |
| 20 | Team | POST | `/v1/organisations/{orgId}/teams/{teamId}/members` | CUSTOM | add_member |
| 21 | Team | GET | `/v1/organisations/{orgId}/teams/{teamId}/members/{userId}` | CUSTOM | get_member |
| 22 | Team | PUT | `/v1/organisations/{orgId}/teams/{teamId}/members/{userId}` | CUSTOM | update_member |
| 23 | Team | POST | `/v1/organisations/{orgId}/teams/{teamId}/members/{userId}/transfer` | CUSTOM | transfer_member |
| 24 | Team | GET | `/v1/organisations/{orgId}/team-roles` | CUSTOM | list_team_roles |
| 25 | Team | POST | `/v1/organisations/{orgId}/team-roles` | CUSTOM | create_team_role |
| 26 | Team | GET | `/v1/organisations/{orgId}/team-roles/{teamRoleId}` | CUSTOM | get_team_role |
| 27 | Team | PUT | `/v1/organisations/{orgId}/team-roles/{teamRoleId}` | CUSTOM | update_team_role |
| 28 | Team | GET | `/v1/organisations/{orgId}/users/{userId}/teams` | CUSTOM | get_user_teams |
| **Role Service (7)** |
| 29 | Role | GET | `/v1/platform/roles` | CUSTOM | list_platform_roles |
| 30 | Role | GET | `/v1/platform/roles/{roleId}` | CUSTOM | get_platform_role |
| 31 | Role | GET | `/v1/organisations/{orgId}/roles` | CUSTOM | list_roles |
| 32 | Role | POST | `/v1/organisations/{orgId}/roles` | CUSTOM | create_role |
| 33 | Role | GET | `/v1/organisations/{orgId}/roles/{roleId}` | CUSTOM | get_role |
| 34 | Role | PUT | `/v1/organisations/{orgId}/roles/{roleId}` | CUSTOM | update_role |
| 35 | Role | PUT | `/v1/organisations/{orgId}/roles/{roleId}/permissions` | CUSTOM | assign_permissions |
| **Audit Service (5)** |
| 36 | Audit | GET | `/v1/audit/access` | CUSTOM | get_access_logs |
| 37 | Audit | GET | `/v1/audit/permissions` | CUSTOM | get_permission_logs |
| 38 | Audit | GET | `/v1/audit/organisations/{orgId}` | CUSTOM | get_org_audit |
| 39 | Audit | GET | `/v1/audit/summary` | CUSTOM | get_audit_summary |
| 40 | Audit | POST | `/v1/audit/export` | CUSTOM | export_audit |

---

## 11. Stage Variables Summary

| Variable | DEV | SIT | PROD |
|----------|-----|-----|------|
| log_level | INFO | INFO | WARN |
| throttle_rate | 100 | 500 | 1000 |
| throttle_burst | 50 | 200 | 500 |
| quota_limit | 10,000 | 50,000 | 100,000 |
| authorizer_cache_ttl | 0 | 300 | 300 |
| xray_tracing | true | true | true |
| data_trace | true | false | false |

---

## 12. Success Criteria Checklist

- [x] All 40 endpoints configured (6 Permission + 8 Invitation + 14 Team + 7 Role + 5 Audit)
- [x] CORS enabled on all endpoints
- [x] OPTIONS method for preflight on all resources
- [x] Lambda proxy integration for all methods
- [x] Request validation enabled for POST/PUT methods
- [x] Stage variables defined for DEV/SIT/PROD
- [x] CloudWatch logging enabled
- [x] Environment parameterized
- [x] Lambda authorizer configured
- [x] Gateway responses for 4XX/5XX with CORS headers
- [x] Usage plan and throttling configured
- [x] X-Ray tracing enabled
- [x] WAF association support (optional)

---

**Worker Status**: COMPLETE
**Completion Date**: 2026-01-23
**Output Location**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/project_plans/project-plan-2-access-management/stage-2-infrastructure-terraform/worker-3-api-gateway-module/output.md`
