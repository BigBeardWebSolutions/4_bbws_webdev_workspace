# Worker 6 Output: Authorizer Integration with API Gateway

**Worker ID**: worker-6-authorizer-integration
**Stage**: Stage 4 - API Gateway Integration
**Project**: project-plan-2-access-management
**Status**: COMPLETE
**Date**: 2026-01-23

---

## Executive Summary

This document provides the comprehensive configuration for integrating the Lambda Authorizer with API Gateway, including complete endpoint-permission mappings for all 41+ endpoints in the Access Management system. The configuration follows TOKEN-based authorization with a 300-second cache TTL, supports CORS headers in error responses, and defines public endpoints that bypass authentication.

---

## Table of Contents

1. [Authorizer Terraform Configuration](#1-authorizer-terraform-configuration)
2. [Complete Endpoint-Permission Mapping](#2-complete-endpoint-permission-mapping)
3. [Public Endpoints Configuration](#3-public-endpoints-configuration)
4. [Gateway Response Configuration](#4-gateway-response-configuration)
5. [Authorizer Context Usage](#5-authorizer-context-usage)
6. [Method Integration Configuration](#6-method-integration-configuration)
7. [Deployment Configuration](#7-deployment-configuration)
8. [Testing and Validation](#8-testing-and-validation)

---

## 1. Authorizer Terraform Configuration

### 1.1 Main Authorizer Resource

```hcl
################################################################################
# API Gateway Lambda Authorizer Configuration
# Type: TOKEN-based authorizer for JWT validation with Cognito integration
# Cache TTL: 300 seconds (5 minutes)
################################################################################

resource "aws_api_gateway_authorizer" "access_management" {
  name                             = "bbws-access-${var.environment}-authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.access_management.id
  authorizer_uri                   = aws_lambda_function.authorizer.invoke_arn
  authorizer_credentials           = aws_iam_role.api_gateway_authorizer_invocation.arn
  type                             = "TOKEN"
  identity_source                  = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 300

  # Validation regex for Bearer tokens
  identity_validation_expression = "^Bearer [-0-9a-zA-Z._]+$"
}
```

### 1.2 Lambda Permission for API Gateway Invocation

```hcl
resource "aws_lambda_permission" "api_gateway_invoke_authorizer" {
  statement_id  = "AllowAPIGatewayInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer.function_name
  principal     = "apigateway.amazonaws.com"

  # Restrict to specific API Gateway authorizer
  source_arn = "${aws_api_gateway_rest_api.access_management.execution_arn}/authorizers/${aws_api_gateway_authorizer.access_management.id}"
}
```

### 1.3 Variables for Authorizer Configuration

```hcl
variable "authorizer_cache_ttl" {
  description = "API Gateway authorizer result cache TTL in seconds"
  type        = number
  default     = 300  # 5 minutes

  validation {
    condition     = var.authorizer_cache_ttl >= 0 && var.authorizer_cache_ttl <= 3600
    error_message = "Authorizer cache TTL must be between 0 and 3600 seconds."
  }
}

variable "identity_validation_expression" {
  description = "Regex pattern to validate Authorization header format"
  type        = string
  default     = "^Bearer [-0-9a-zA-Z._]+$"
}
```

---

## 2. Complete Endpoint-Permission Mapping

### 2.1 Permission Service Endpoints (6 endpoints)

| # | HTTP Method | Endpoint Pattern | Required Permission | Lambda Handler | Notes |
|---|-------------|------------------|---------------------|----------------|-------|
| 1 | GET | /v1/platform/permissions | None (authenticated) | list_permissions | Read-only platform data |
| 2 | GET | /v1/platform/permissions/{permId} | None (authenticated) | get_permission | Read-only platform data |
| 3 | POST | /v1/permissions | permission:create | create_permission | Platform admin only |
| 4 | PUT | /v1/permissions/{permId} | permission:update | update_permission | Platform admin only |
| 5 | DELETE | /v1/permissions/{permId} | permission:delete | delete_permission | Platform admin only |
| 6 | POST | /v1/permissions/seed | permission:admin | seed_permissions | System initialization |

### 2.2 Role Service Endpoints (9 endpoints)

| # | HTTP Method | Endpoint Pattern | Required Permission | Lambda Handler | Notes |
|---|-------------|------------------|---------------------|----------------|-------|
| 7 | GET | /v1/platform/roles | None (authenticated) | list_platform_roles | Read-only platform data |
| 8 | GET | /v1/platform/roles/{roleId} | None (authenticated) | get_platform_role | Read-only platform data |
| 9 | GET | /v1/organisations/{orgId}/roles | role:read | list_org_roles | Org-scoped |
| 10 | GET | /v1/organisations/{orgId}/roles/{roleId} | role:read | get_org_role | Org-scoped |
| 11 | POST | /v1/organisations/{orgId}/roles | role:create | create_role | Org-scoped |
| 12 | PUT | /v1/organisations/{orgId}/roles/{roleId} | role:update | update_role | Org-scoped |
| 13 | PUT | /v1/organisations/{orgId}/roles/{roleId}/permissions | role:update | update_role_permissions | Permission assignment |
| 14 | DELETE | /v1/organisations/{orgId}/roles/{roleId} | role:delete | delete_role | Soft delete |
| 15 | POST | /v1/organisations/{orgId}/roles/seed | role:admin | seed_roles | Org initialization |

### 2.3 Team Service Endpoints (15 endpoints)

| # | HTTP Method | Endpoint Pattern | Required Permission | Lambda Handler | Notes |
|---|-------------|------------------|---------------------|----------------|-------|
| 16 | GET | /v1/organisations/{orgId}/teams | team:read | list_teams | List all teams |
| 17 | GET | /v1/organisations/{orgId}/teams/{teamId} | team:read | get_team | Get team details |
| 18 | POST | /v1/organisations/{orgId}/teams | team:create | create_team | Create new team |
| 19 | PUT | /v1/organisations/{orgId}/teams/{teamId} | team:update | update_team | Update team |
| 20 | DELETE | /v1/organisations/{orgId}/teams/{teamId} | team:delete | delete_team | Soft delete |
| 21 | GET | /v1/organisations/{orgId}/team-roles | team-role:read | list_team_roles | List team roles |
| 22 | GET | /v1/organisations/{orgId}/team-roles/{roleId} | team-role:read | get_team_role | Get team role |
| 23 | POST | /v1/organisations/{orgId}/team-roles | team-role:create | create_team_role | Create team role |
| 24 | PUT | /v1/organisations/{orgId}/team-roles/{roleId} | team-role:update | update_team_role | Update team role |
| 25 | DELETE | /v1/organisations/{orgId}/team-roles/{roleId} | team-role:delete | delete_team_role | Soft delete |
| 26 | GET | /v1/organisations/{orgId}/teams/{teamId}/members | team:member:read | list_members | List team members |
| 27 | GET | /v1/organisations/{orgId}/teams/{teamId}/members/{userId} | team:member:read | get_member | Get member details |
| 28 | POST | /v1/organisations/{orgId}/teams/{teamId}/members | team:member:add | add_member | Add team member |
| 29 | PUT | /v1/organisations/{orgId}/teams/{teamId}/members/{userId} | team:member:update | update_member | Update member role |
| 30 | DELETE | /v1/organisations/{orgId}/teams/{teamId}/members/{userId} | team:member:remove | remove_member | Remove from team |

### 2.4 User Service Endpoints (3 endpoints)

| # | HTTP Method | Endpoint Pattern | Required Permission | Lambda Handler | Notes |
|---|-------------|------------------|---------------------|----------------|-------|
| 31 | GET | /v1/organisations/{orgId}/users | user:read | list_users | List org users |
| 32 | GET | /v1/organisations/{orgId}/users/{userId} | user:read | get_user | Get user details |
| 33 | GET | /v1/organisations/{orgId}/users/{userId}/teams | user:read | get_user_teams | Get user's teams |

### 2.5 Invitation Service Endpoints (10 endpoints)

| # | HTTP Method | Endpoint Pattern | Required Permission | Lambda Handler | Notes |
|---|-------------|------------------|---------------------|----------------|-------|
| 34 | GET | /v1/organisations/{orgId}/invitations | invitation:read | list_invitations | List invitations |
| 35 | GET | /v1/organisations/{orgId}/invitations/{invId} | invitation:read | get_invitation | Get invitation details |
| 36 | POST | /v1/organisations/{orgId}/invitations | invitation:create | create_invitation | Create invitation |
| 37 | PUT | /v1/organisations/{orgId}/invitations/{invId} | invitation:update | update_invitation | Update invitation |
| 38 | DELETE | /v1/organisations/{orgId}/invitations/{invId} | invitation:revoke | revoke_invitation | Revoke invitation |
| 39 | POST | /v1/organisations/{orgId}/invitations/{invId}/resend | invitation:create | resend_invitation | Resend email |
| 40 | **GET** | **/v1/invitations/{token}** | **PUBLIC** | verify_invitation | **No auth required** |
| 41 | **POST** | **/v1/invitations/{token}/accept** | **PUBLIC** | accept_invitation | **No auth required** |
| 42 | **POST** | **/v1/invitations/{token}/decline** | **PUBLIC** | decline_invitation | **No auth required** |

### 2.6 Audit Service Endpoints (5 endpoints)

| # | HTTP Method | Endpoint Pattern | Required Permission | Lambda Handler | Notes |
|---|-------------|------------------|---------------------|----------------|-------|
| 43 | GET | /v1/organisations/{orgId}/audit | audit:read | list_audit_logs | List audit events |
| 44 | GET | /v1/organisations/{orgId}/audit/users/{userId} | audit:read | get_user_audit | User activity |
| 45 | GET | /v1/organisations/{orgId}/audit/resources/{type}/{id} | audit:read | get_resource_audit | Resource history |
| 46 | GET | /v1/organisations/{orgId}/audit/summary | audit:read | get_audit_summary | Audit summary |
| 47 | POST | /v1/organisations/{orgId}/audit/export | audit:export | export_audit | Export audit logs |

---

## 3. Public Endpoints Configuration

### 3.1 Public Endpoints List (No Authorizer Required)

The following endpoints are accessible without authentication. These are specifically for invitation acceptance workflow where users may not have an account yet.

| Endpoint | Purpose | Security Notes |
|----------|---------|----------------|
| GET /v1/invitations/{token} | Verify invitation token | Token is secure random UUID, expires after 7 days |
| POST /v1/invitations/{token}/accept | Accept invitation | Creates user account, validates token |
| POST /v1/invitations/{token}/decline | Decline invitation | Marks invitation as declined |

### 3.2 Terraform Configuration for Public Endpoints

```hcl
################################################################################
# Public Endpoint Methods (No Authorizer)
# These endpoints bypass authentication for invitation acceptance flow
################################################################################

# GET /v1/invitations/{token} - Verify invitation
resource "aws_api_gateway_method" "verify_invitation" {
  rest_api_id   = aws_api_gateway_rest_api.access_management.id
  resource_id   = aws_api_gateway_resource.invitation_token.id
  http_method   = "GET"
  authorization = "NONE"  # Public endpoint - no authorizer
}

# POST /v1/invitations/{token}/accept - Accept invitation
resource "aws_api_gateway_method" "accept_invitation" {
  rest_api_id   = aws_api_gateway_rest_api.access_management.id
  resource_id   = aws_api_gateway_resource.invitation_accept.id
  http_method   = "POST"
  authorization = "NONE"  # Public endpoint - no authorizer
}

# POST /v1/invitations/{token}/decline - Decline invitation
resource "aws_api_gateway_method" "decline_invitation" {
  rest_api_id   = aws_api_gateway_rest_api.access_management.id
  resource_id   = aws_api_gateway_resource.invitation_decline.id
  http_method   = "POST"
  authorization = "NONE"  # Public endpoint - no authorizer
}

#------------------------------------------------------------------------------
# Resource Definitions for Public Endpoints
#------------------------------------------------------------------------------
resource "aws_api_gateway_resource" "invitations_public" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "invitations"
}

resource "aws_api_gateway_resource" "invitation_token" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.invitations_public.id
  path_part   = "{token}"
}

resource "aws_api_gateway_resource" "invitation_accept" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.invitation_token.id
  path_part   = "accept"
}

resource "aws_api_gateway_resource" "invitation_decline" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  parent_id   = aws_api_gateway_resource.invitation_token.id
  path_part   = "decline"
}
```

### 3.3 Rate Limiting for Public Endpoints

```hcl
# Usage plan to prevent abuse of public endpoints
resource "aws_api_gateway_usage_plan" "public_endpoints" {
  name        = "bbws-access-${var.environment}-public-rate-limit"
  description = "Rate limiting for public invitation endpoints"

  api_stages {
    api_id = aws_api_gateway_rest_api.access_management.id
    stage  = aws_api_gateway_stage.access_management.stage_name
  }

  throttle_settings {
    burst_limit = 50   # Max concurrent requests
    rate_limit  = 100  # Requests per second
  }

  quota_settings {
    limit  = 10000  # Total requests per day
    period = "DAY"
  }
}
```

---

## 4. Gateway Response Configuration

### 4.1 401 Unauthorized Response

```hcl
resource "aws_api_gateway_gateway_response" "unauthorized" {
  rest_api_id   = aws_api_gateway_rest_api.access_management.id
  response_type = "UNAUTHORIZED"
  status_code   = "401"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'${var.cors_allowed_origin}'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Request-Id'"
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "gatewayresponse.header.WWW-Authenticate"             = "'Bearer realm=\"bbws-access-management\"'"
  }

  response_templates = {
    "application/json" = jsonencode({
      error = {
        code    = "UNAUTHORIZED"
        message = "Authentication required. Please provide a valid Bearer token."
        details = {
          type      = "AuthenticationError"
          timestamp = "$context.requestTime"
          requestId = "$context.requestId"
        }
      }
    })
  }
}
```

### 4.2 403 Forbidden Response

```hcl
resource "aws_api_gateway_gateway_response" "access_denied" {
  rest_api_id   = aws_api_gateway_rest_api.access_management.id
  response_type = "ACCESS_DENIED"
  status_code   = "403"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'${var.cors_allowed_origin}'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Request-Id'"
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
  }

  response_templates = {
    "application/json" = jsonencode({
      error = {
        code    = "FORBIDDEN"
        message = "Access denied. You do not have permission to perform this action."
        details = {
          type      = "AuthorizationError"
          timestamp = "$context.requestTime"
          requestId = "$context.requestId"
        }
      }
    })
  }
}
```

### 4.3 Expired Token Response

```hcl
resource "aws_api_gateway_gateway_response" "expired_token" {
  rest_api_id   = aws_api_gateway_rest_api.access_management.id
  response_type = "AUTHORIZER_FAILURE"
  status_code   = "401"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'${var.cors_allowed_origin}'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Request-Id'"
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "gatewayresponse.header.WWW-Authenticate"             = "'Bearer realm=\"bbws-access-management\", error=\"invalid_token\", error_description=\"Token has expired\"'"
  }

  response_templates = {
    "application/json" = jsonencode({
      error = {
        code    = "TOKEN_EXPIRED"
        message = "The authentication token has expired. Please refresh your token."
        details = {
          type      = "AuthenticationError"
          timestamp = "$context.requestTime"
          requestId = "$context.requestId"
        }
      }
    })
  }
}
```

### 4.4 Invalid Token Response

```hcl
resource "aws_api_gateway_gateway_response" "invalid_token" {
  rest_api_id   = aws_api_gateway_rest_api.access_management.id
  response_type = "AUTHORIZER_CONFIGURATION_ERROR"
  status_code   = "401"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'${var.cors_allowed_origin}'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Request-Id'"
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "gatewayresponse.header.WWW-Authenticate"             = "'Bearer realm=\"bbws-access-management\", error=\"invalid_token\"'"
  }

  response_templates = {
    "application/json" = jsonencode({
      error = {
        code    = "INVALID_TOKEN"
        message = "The authentication token is invalid."
        details = {
          type      = "AuthenticationError"
          timestamp = "$context.requestTime"
          requestId = "$context.requestId"
        }
      }
    })
  }
}
```

### 4.5 Missing Authentication Header Response

```hcl
resource "aws_api_gateway_gateway_response" "missing_auth_header" {
  rest_api_id   = aws_api_gateway_rest_api.access_management.id
  response_type = "MISSING_AUTHENTICATION_TOKEN"
  status_code   = "401"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'${var.cors_allowed_origin}'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Request-Id'"
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "gatewayresponse.header.WWW-Authenticate"             = "'Bearer realm=\"bbws-access-management\"'"
  }

  response_templates = {
    "application/json" = jsonencode({
      error = {
        code    = "MISSING_TOKEN"
        message = "Authorization header is missing. Please provide a Bearer token."
        details = {
          type      = "AuthenticationError"
          timestamp = "$context.requestTime"
          requestId = "$context.requestId"
        }
      }
    })
  }
}
```

### 4.6 Complete Gateway Response Module

```hcl
################################################################################
# Gateway Responses Module
# File: terraform/modules/api-gateway-responses/main.tf
################################################################################

variable "rest_api_id" {
  description = "API Gateway REST API ID"
  type        = string
}

variable "cors_allowed_origin" {
  description = "CORS allowed origin (use * for dev, specific domain for prod)"
  type        = string
  default     = "*"
}

variable "environment" {
  description = "Environment (dev, sit, prod)"
  type        = string
}

locals {
  # CORS origin - use specific domain in production
  cors_origin = var.environment == "prod" ? "https://app.bbws.io" : var.cors_allowed_origin

  # Common CORS headers
  cors_headers = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'${local.cors_origin}'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Request-Id,X-Correlation-Id'"
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,PATCH,OPTIONS'"
  }
}

# 401 Unauthorized
resource "aws_api_gateway_gateway_response" "unauthorized" {
  rest_api_id   = var.rest_api_id
  response_type = "UNAUTHORIZED"
  status_code   = "401"

  response_parameters = merge(local.cors_headers, {
    "gatewayresponse.header.WWW-Authenticate" = "'Bearer realm=\"bbws-access-management\"'"
  })

  response_templates = {
    "application/json" = jsonencode({
      error = {
        code      = "UNAUTHORIZED"
        message   = "Authentication required"
        requestId = "$context.requestId"
      }
    })
  }
}

# 403 Access Denied
resource "aws_api_gateway_gateway_response" "access_denied" {
  rest_api_id   = var.rest_api_id
  response_type = "ACCESS_DENIED"
  status_code   = "403"

  response_parameters = local.cors_headers

  response_templates = {
    "application/json" = jsonencode({
      error = {
        code      = "FORBIDDEN"
        message   = "Insufficient permissions"
        requestId = "$context.requestId"
      }
    })
  }
}

# Authorizer Failure (token issues)
resource "aws_api_gateway_gateway_response" "authorizer_failure" {
  rest_api_id   = var.rest_api_id
  response_type = "AUTHORIZER_FAILURE"
  status_code   = "401"

  response_parameters = merge(local.cors_headers, {
    "gatewayresponse.header.WWW-Authenticate" = "'Bearer error=\"invalid_token\"'"
  })

  response_templates = {
    "application/json" = jsonencode({
      error = {
        code      = "INVALID_TOKEN"
        message   = "Token validation failed"
        requestId = "$context.requestId"
      }
    })
  }
}

# Missing Authentication Token
resource "aws_api_gateway_gateway_response" "missing_auth_token" {
  rest_api_id   = var.rest_api_id
  response_type = "MISSING_AUTHENTICATION_TOKEN"
  status_code   = "401"

  response_parameters = merge(local.cors_headers, {
    "gatewayresponse.header.WWW-Authenticate" = "'Bearer realm=\"bbws-access-management\"'"
  })

  response_templates = {
    "application/json" = jsonencode({
      error = {
        code      = "MISSING_TOKEN"
        message   = "Authorization header required"
        requestId = "$context.requestId"
      }
    })
  }
}

# Bad Request Body
resource "aws_api_gateway_gateway_response" "bad_request_body" {
  rest_api_id   = var.rest_api_id
  response_type = "BAD_REQUEST_BODY"
  status_code   = "400"

  response_parameters = local.cors_headers

  response_templates = {
    "application/json" = jsonencode({
      error = {
        code      = "BAD_REQUEST"
        message   = "Invalid request body"
        details   = "$context.error.validationErrorString"
        requestId = "$context.requestId"
      }
    })
  }
}

# Throttling
resource "aws_api_gateway_gateway_response" "throttled" {
  rest_api_id   = var.rest_api_id
  response_type = "THROTTLED"
  status_code   = "429"

  response_parameters = merge(local.cors_headers, {
    "gatewayresponse.header.Retry-After" = "'60'"
  })

  response_templates = {
    "application/json" = jsonencode({
      error = {
        code      = "RATE_LIMIT_EXCEEDED"
        message   = "Too many requests. Please retry after 60 seconds."
        requestId = "$context.requestId"
      }
    })
  }
}

# Default 4XX
resource "aws_api_gateway_gateway_response" "default_4xx" {
  rest_api_id   = var.rest_api_id
  response_type = "DEFAULT_4XX"

  response_parameters = local.cors_headers

  response_templates = {
    "application/json" = jsonencode({
      error = {
        code      = "CLIENT_ERROR"
        message   = "$context.error.message"
        requestId = "$context.requestId"
      }
    })
  }
}

# Default 5XX
resource "aws_api_gateway_gateway_response" "default_5xx" {
  rest_api_id   = var.rest_api_id
  response_type = "DEFAULT_5XX"

  response_parameters = local.cors_headers

  response_templates = {
    "application/json" = jsonencode({
      error = {
        code      = "SERVER_ERROR"
        message   = "Internal server error"
        requestId = "$context.requestId"
      }
    })
  }
}
```

---

## 5. Authorizer Context Usage

### 5.1 Context Data Structure

The Lambda Authorizer passes the following context to backend Lambda functions via `event.requestContext.authorizer`:

```json
{
  "userId": "user-770e8400-e29b-41d4-a716-446655440003",
  "email": "john.doe@example.com",
  "orgId": "org-550e8400-e29b-41d4-a716-446655440000",
  "teamIds": "team-001,team-002,team-003",
  "permissions": "site:read,site:update,team:read,team:member:add",
  "roleIds": "role-team-lead,role-operator"
}
```

### 5.2 Backend Lambda Context Access (Python)

```python
"""
Example: Accessing authorizer context in backend Lambda functions.
File: lambda/common/auth_context.py
"""
from dataclasses import dataclass
from typing import List, Optional


@dataclass
class AuthContext:
    """Parsed authorization context from API Gateway."""
    user_id: str
    email: str
    org_id: str
    team_ids: List[str]
    permissions: List[str]
    role_ids: List[str]

    @classmethod
    def from_event(cls, event: dict) -> Optional["AuthContext"]:
        """Extract auth context from API Gateway event.

        Args:
            event: API Gateway Lambda proxy integration event.

        Returns:
            AuthContext if present, None for public endpoints.
        """
        # Get authorizer context
        authorizer = event.get("requestContext", {}).get("authorizer", {})

        # Check if context exists (public endpoints won't have it)
        if not authorizer or "userId" not in authorizer:
            return None

        # Parse comma-separated values to lists
        team_ids = authorizer.get("teamIds", "")
        permissions = authorizer.get("permissions", "")
        role_ids = authorizer.get("roleIds", "")

        return cls(
            user_id=authorizer.get("userId", ""),
            email=authorizer.get("email", ""),
            org_id=authorizer.get("orgId", ""),
            team_ids=[t.strip() for t in team_ids.split(",") if t.strip()],
            permissions=[p.strip() for p in permissions.split(",") if p.strip()],
            role_ids=[r.strip() for r in role_ids.split(",") if r.strip()]
        )

    def has_permission(self, permission: str) -> bool:
        """Check if user has a specific permission.

        Supports wildcard permissions (e.g., site:* matches site:read).

        Args:
            permission: Permission string to check.

        Returns:
            True if user has the permission.
        """
        # Exact match
        if permission in self.permissions:
            return True

        # Wildcard match (resource:*)
        resource = permission.split(":")[0]
        if f"{resource}:*" in self.permissions:
            return True

        # Super admin
        if "*:*" in self.permissions:
            return True

        return False

    def is_team_member(self, team_id: str) -> bool:
        """Check if user is a member of a specific team.

        Args:
            team_id: Team ID to check.

        Returns:
            True if user is a member of the team.
        """
        return team_id in self.team_ids

    def can_access_resource(self, resource_team_id: Optional[str]) -> bool:
        """Check if user can access a resource based on team membership.

        Args:
            resource_team_id: Team ID associated with the resource.

        Returns:
            True if user can access the resource.
        """
        # If resource has no team restriction, allow access
        if not resource_team_id:
            return True

        # Check team membership
        return self.is_team_member(resource_team_id)
```

### 5.3 Backend Lambda Handler Example

```python
"""
Example: Using auth context in a Lambda handler.
File: lambda/site_service/handlers/list_sites.py
"""
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext
from common.auth_context import AuthContext
from common.responses import api_response, error_response

logger = Logger(service="site-service")


def lambda_handler(event: dict, context: LambdaContext) -> dict:
    """Handle GET /v1/organisations/{orgId}/sites request.

    Filters sites based on user's team memberships.
    """
    # Extract auth context
    auth = AuthContext.from_event(event)
    if not auth:
        return error_response(401, "UNAUTHORIZED", "Authentication required")

    # Verify user belongs to the requested organisation
    path_params = event.get("pathParameters", {})
    requested_org_id = path_params.get("orgId")

    if requested_org_id != auth.org_id:
        logger.warning("Organisation mismatch", extra={
            "user_org": auth.org_id,
            "requested_org": requested_org_id
        })
        return error_response(403, "FORBIDDEN", "Access to this organisation denied")

    # Permission check (already done by authorizer, but can add additional checks)
    if not auth.has_permission("site:read"):
        return error_response(403, "FORBIDDEN", "Insufficient permissions")

    logger.info("Listing sites", extra={
        "user_id": auth.user_id,
        "org_id": auth.org_id,
        "team_ids": auth.team_ids
    })

    # Query sites and filter by user's teams
    # Sites are filtered to only show those the user has access to
    sites = site_repository.list_sites(
        org_id=auth.org_id,
        team_ids=auth.team_ids  # Filter by teams user belongs to
    )

    return api_response(200, {
        "sites": sites,
        "count": len(sites)
    })
```

### 5.4 Authorizer Context Fields Reference

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `userId` | string | Cognito user ID (sub) | `user-770e8400-e29b-41d4-a716-446655440003` |
| `email` | string | User's email address | `john.doe@example.com` |
| `orgId` | string | User's organisation ID | `org-550e8400-e29b-41d4-a716-446655440000` |
| `teamIds` | string | Comma-separated team IDs | `team-001,team-002,team-003` |
| `permissions` | string | Comma-separated permissions | `site:read,site:update,team:read` |
| `roleIds` | string | Comma-separated role IDs | `role-team-lead,role-operator` |

---

## 6. Method Integration Configuration

### 6.1 Protected Endpoint Template

```hcl
################################################################################
# Template for Protected Endpoints (with Authorizer)
################################################################################

# Example: GET /v1/organisations/{orgId}/sites
resource "aws_api_gateway_method" "list_sites" {
  rest_api_id   = aws_api_gateway_rest_api.access_management.id
  resource_id   = aws_api_gateway_resource.org_sites.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.access_management.id

  # Optional: Request parameters
  request_parameters = {
    "method.request.header.Authorization" = true  # Required header
  }
}

resource "aws_api_gateway_integration" "list_sites" {
  rest_api_id             = aws_api_gateway_rest_api.access_management.id
  resource_id             = aws_api_gateway_resource.org_sites.id
  http_method             = aws_api_gateway_method.list_sites.http_method
  integration_http_method = "POST"  # Lambda always uses POST
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.list_sites.invoke_arn
}

# Lambda permission
resource "aws_lambda_permission" "list_sites" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_sites.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.access_management.execution_arn}/*/*"
}
```

### 6.2 CORS Configuration for Endpoints

```hcl
# OPTIONS method for CORS preflight
resource "aws_api_gateway_method" "sites_options" {
  rest_api_id   = aws_api_gateway_rest_api.access_management.id
  resource_id   = aws_api_gateway_resource.org_sites.id
  http_method   = "OPTIONS"
  authorization = "NONE"  # CORS preflight must not use authorizer
}

resource "aws_api_gateway_integration" "sites_options" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.org_sites.id
  http_method = aws_api_gateway_method.sites_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_method_response" "sites_options_200" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.org_sites.id
  http_method = aws_api_gateway_method.sites_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "sites_options" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.org_sites.id
  http_method = aws_api_gateway_method.sites_options.http_method
  status_code = aws_api_gateway_method_response.sites_options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Request-Id'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'${var.cors_allowed_origin}'"
  }
}
```

---

## 7. Deployment Configuration

### 7.1 Stage Variables by Environment

```hcl
resource "aws_api_gateway_stage" "access_management" {
  deployment_id = aws_api_gateway_deployment.access_management.id
  rest_api_id   = aws_api_gateway_rest_api.access_management.id
  stage_name    = var.environment

  variables = {
    environment         = var.environment
    authorizer_cache_ttl = tostring(var.authorizer_cache_ttl)
    cors_origin         = var.environment == "prod" ? "https://app.bbws.io" : "*"
    log_level           = var.environment == "prod" ? "INFO" : "DEBUG"
  }

  # Enable logging
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_access.arn
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
      authorizerStatus  = "$context.authorizer.status"
      authLatency       = "$context.authorizer.latency"
      integrationLatency = "$context.integrationLatency"
    })
  }

  # Throttling settings
  dynamic "throttle_settings" {
    for_each = var.environment == "prod" ? [] : [1]
    content {
      burst_limit = 500
      rate_limit  = 1000
    }
  }

  tags = {
    Name        = "bbws-access-${var.environment}-api-stage"
    Environment = var.environment
    Service     = "access-management"
  }
}
```

### 7.2 Cache Configuration by Environment

| Environment | Cache TTL | Description |
|-------------|-----------|-------------|
| DEV | 0 | No caching for easier debugging |
| SIT | 60 | 1-minute cache for testing |
| PROD | 300 | 5-minute cache for performance |

```hcl
variable "authorizer_cache_ttl_by_env" {
  description = "Authorizer cache TTL by environment"
  type        = map(number)
  default = {
    dev  = 0    # No caching in dev
    sit  = 60   # 1 minute in SIT
    prod = 300  # 5 minutes in PROD
  }
}

locals {
  authorizer_cache_ttl = lookup(var.authorizer_cache_ttl_by_env, var.environment, 300)
}
```

---

## 8. Testing and Validation

### 8.1 Authorizer Integration Test Cases

| Test Case | Expected Result | Validation |
|-----------|-----------------|------------|
| Valid token, authorized endpoint | 200 OK with context | Check response body and headers |
| Valid token, unauthorized endpoint | 403 Forbidden | Check error response format |
| Expired token | 401 Unauthorized | Check WWW-Authenticate header |
| Invalid token signature | 401 Unauthorized | Check error message |
| Missing Authorization header | 401 Unauthorized | Check WWW-Authenticate header |
| Malformed Bearer token | 401 Unauthorized | Check identity validation |
| Public endpoint without token | 200 OK | Verify no auth required |
| Cross-org access attempt | 403 Forbidden | Verify org isolation |
| CORS preflight request | 200 OK with CORS headers | Check CORS headers present |

### 8.2 Test Script (Bash)

```bash
#!/bin/bash
# File: scripts/test-authorizer.sh
# Test authorizer integration with API Gateway

API_URL="${API_URL:-https://api.dev.bbws.io/v1}"
VALID_TOKEN="${TEST_TOKEN:-}"

echo "Testing Authorizer Integration..."
echo "================================"

# Test 1: Missing token
echo -e "\n1. Test missing Authorization header..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/platform/permissions")
if [ "$RESPONSE" == "401" ]; then
    echo "   PASS: Got 401 for missing token"
else
    echo "   FAIL: Expected 401, got $RESPONSE"
fi

# Test 2: Invalid token format
echo -e "\n2. Test invalid token format..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: InvalidFormat" \
    "$API_URL/platform/permissions")
if [ "$RESPONSE" == "401" ]; then
    echo "   PASS: Got 401 for invalid format"
else
    echo "   FAIL: Expected 401, got $RESPONSE"
fi

# Test 3: Valid token (if provided)
if [ -n "$VALID_TOKEN" ]; then
    echo -e "\n3. Test valid token..."
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $VALID_TOKEN" \
        "$API_URL/platform/permissions")
    if [ "$RESPONSE" == "200" ]; then
        echo "   PASS: Got 200 for valid token"
    else
        echo "   FAIL: Expected 200, got $RESPONSE"
    fi
fi

# Test 4: Public endpoint (no auth)
echo -e "\n4. Test public endpoint without token..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    "$API_URL/invitations/test-token-12345")
# Note: Will get 404 if token doesn't exist, not 401
if [ "$RESPONSE" == "404" ] || [ "$RESPONSE" == "200" ]; then
    echo "   PASS: Public endpoint accessible (got $RESPONSE)"
else
    echo "   FAIL: Expected 200 or 404, got $RESPONSE"
fi

# Test 5: CORS headers on error response
echo -e "\n5. Test CORS headers on 401 response..."
HEADERS=$(curl -s -I "$API_URL/platform/permissions" 2>&1)
if echo "$HEADERS" | grep -q "Access-Control-Allow-Origin"; then
    echo "   PASS: CORS headers present on error response"
else
    echo "   FAIL: CORS headers missing on error response"
fi

echo -e "\n================================"
echo "Authorizer integration tests complete"
```

### 8.3 Validation Commands

```bash
# Validate authorizer configuration
terraform plan -target=aws_api_gateway_authorizer.access_management

# Test authorizer Lambda directly
aws lambda invoke \
    --function-name bbws-access-dev-lambda-authorizer \
    --payload '{"type":"TOKEN","authorizationToken":"Bearer <token>","methodArn":"arn:aws:execute-api:af-south-1:536580886816:api-id/dev/GET/v1/platform/permissions"}' \
    response.json

# Check API Gateway authorizer cache
aws apigateway flush-authorizer-cache \
    --rest-api-id <api-id> \
    --stage-name dev \
    --authorizer-id <authorizer-id>
```

---

## 9. Success Criteria Checklist

| Criteria | Status | Notes |
|----------|--------|-------|
| TOKEN authorizer configured | COMPLETE | 300s cache TTL |
| Identity source: Authorization header | COMPLETE | Bearer token format |
| All 47 endpoints mapped | COMPLETE | See Section 2 |
| Public endpoints configured (3) | COMPLETE | Invitation flow |
| 401 response with CORS headers | COMPLETE | See Section 4.1 |
| 403 response with CORS headers | COMPLETE | See Section 4.2 |
| Authorizer context documented | COMPLETE | See Section 5 |
| Backend Lambda context access | COMPLETE | Python example provided |
| Gateway responses configured | COMPLETE | 6 response types |
| Environment-specific cache TTL | COMPLETE | 0/60/300 by env |

---

## 10. References

- **Stage 2 Input**: worker-4-cognito-integration-module/output.md
- **Stage 3 Input**: worker-5-authorizer-service-lambda/output.md
- **AWS Documentation**: [API Gateway Lambda Authorizers](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html)
- **AWS Documentation**: [Gateway Responses](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-gatewayResponse-definition.html)
- **AWS Documentation**: [API Gateway Context Variables](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-mapping-template-reference.html)

---

**End of Output Document**
