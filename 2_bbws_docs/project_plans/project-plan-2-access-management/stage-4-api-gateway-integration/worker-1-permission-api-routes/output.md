# Permission API Routes - API Gateway Integration Output

**Worker ID**: worker-1-permission-api-routes
**Stage**: Stage 4 - API Gateway Integration
**Project**: project-plan-2-access-management
**Created**: 2026-01-23
**Status**: COMPLETE

---

## Table of Contents

1. [Overview](#overview)
2. [OpenAPI 3.0 Specification](#openapi-30-specification)
3. [Terraform Route Configuration](#terraform-route-configuration)
4. [Request/Response JSON Schemas](#requestresponse-json-schemas)
5. [CORS Configuration](#cors-configuration)
6. [Lambda Proxy Integration Settings](#lambda-proxy-integration-settings)
7. [Success Criteria Checklist](#success-criteria-checklist)

---

## Overview

This document contains the complete API Gateway configuration for the Permission Service with 6 endpoints:

| # | Method | Path | Lambda | Auth | Description |
|---|--------|------|--------|------|-------------|
| 1 | GET | `/v1/permissions` | list_permissions | CUSTOM | List all permissions with pagination |
| 2 | GET | `/v1/permissions/{permissionId}` | get_permission | CUSTOM | Get single permission by ID |
| 3 | POST | `/v1/permissions` | create_permission | CUSTOM | Create a new permission |
| 4 | PUT | `/v1/permissions/{permissionId}` | update_permission | CUSTOM | Update an existing permission |
| 5 | DELETE | `/v1/permissions/{permissionId}` | delete_permission | CUSTOM | Soft delete a permission |
| 6 | POST | `/v1/permissions/seed` | seed_permissions | CUSTOM | Seed platform permissions |

---

## OpenAPI 3.0 Specification

### permission-service-openapi.yaml

```yaml
openapi: 3.0.3
info:
  title: BBWS Permission Service API
  description: |
    API for managing platform permissions in the BBWS Access Management System.
    Permissions define actions that can be performed on resources within the platform.
  version: 1.0.0
  contact:
    name: BBWS Platform Team
    email: platform-support@bbws.co.za
  license:
    name: Proprietary
    url: https://bbws.co.za/license

servers:
  - url: https://api.bbws-dev.co.za/v1
    description: Development environment
  - url: https://api.bbws-sit.co.za/v1
    description: SIT environment
  - url: https://api.bbws.co.za/v1
    description: Production environment

tags:
  - name: Permissions
    description: Permission management operations

paths:
  /permissions:
    get:
      operationId: listPermissions
      tags:
        - Permissions
      summary: List all permissions
      description: |
        Retrieves a paginated list of all platform permissions.
        Supports filtering by category and pagination using cursor-based pagination.
      security:
        - BearerAuth: []
        - LambdaAuthorizer: []
      parameters:
        - name: pageSize
          in: query
          description: Number of items per page (1-100)
          required: false
          schema:
            type: integer
            minimum: 1
            maximum: 100
            default: 50
        - name: startAt
          in: query
          description: Pagination cursor for next page
          required: false
          schema:
            type: string
        - name: category
          in: query
          description: Filter by permission category
          required: false
          schema:
            type: string
            enum:
              - SITE
              - TEAM
              - ORGANISATION
              - INVITATION
              - ROLE
              - AUDIT
      responses:
        '200':
          description: Successful response with paginated permissions
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/PaginatedPermissionResponse'
        '400':
          description: Bad request - Invalid query parameters
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '401':
          description: Unauthorized - Missing or invalid token
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '403':
          description: Forbidden - Insufficient permissions
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '500':
          description: Internal server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
      x-amazon-apigateway-integration:
        type: aws_proxy
        httpMethod: POST
        uri: arn:aws:apigateway:${aws_region}:lambda:path/2015-03-31/functions/${list_permissions_lambda_arn}/invocations
        passthroughBehavior: when_no_match
        contentHandling: CONVERT_TO_TEXT

    post:
      operationId: createPermission
      tags:
        - Permissions
      summary: Create a new permission
      description: |
        Creates a new platform permission. Requires platform admin privileges.
        Permission ID must be unique and in format 'resource:action'.
      security:
        - BearerAuth: []
        - LambdaAuthorizer: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreatePermissionRequest'
      responses:
        '201':
          description: Permission created successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/PermissionResponse'
        '400':
          description: Bad request - Invalid request body
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '401':
          description: Unauthorized - Missing or invalid token
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '403':
          description: Forbidden - Insufficient permissions
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '409':
          description: Conflict - Permission already exists
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '500':
          description: Internal server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
      x-amazon-apigateway-integration:
        type: aws_proxy
        httpMethod: POST
        uri: arn:aws:apigateway:${aws_region}:lambda:path/2015-03-31/functions/${create_permission_lambda_arn}/invocations
        passthroughBehavior: when_no_match
        contentHandling: CONVERT_TO_TEXT

  /permissions/{permissionId}:
    get:
      operationId: getPermission
      tags:
        - Permissions
      summary: Get a single permission
      description: Retrieves a single permission by its ID.
      security:
        - BearerAuth: []
        - LambdaAuthorizer: []
      parameters:
        - name: permissionId
          in: path
          description: Permission ID in format 'resource:action' (e.g., site:create)
          required: true
          schema:
            type: string
            pattern: '^[a-z]+:[a-z]+$'
      responses:
        '200':
          description: Successful response with permission details
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/PermissionResponse'
        '400':
          description: Bad request - Invalid permission ID format
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '401':
          description: Unauthorized - Missing or invalid token
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '403':
          description: Forbidden - Insufficient permissions
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '404':
          description: Permission not found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '500':
          description: Internal server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
      x-amazon-apigateway-integration:
        type: aws_proxy
        httpMethod: POST
        uri: arn:aws:apigateway:${aws_region}:lambda:path/2015-03-31/functions/${get_permission_lambda_arn}/invocations
        passthroughBehavior: when_no_match
        contentHandling: CONVERT_TO_TEXT

    put:
      operationId: updatePermission
      tags:
        - Permissions
      summary: Update a permission
      description: |
        Updates an existing permission. Only name, description, and active status can be modified.
        System permissions cannot be deleted, only deactivated.
      security:
        - BearerAuth: []
        - LambdaAuthorizer: []
      parameters:
        - name: permissionId
          in: path
          description: Permission ID in format 'resource:action'
          required: true
          schema:
            type: string
            pattern: '^[a-z]+:[a-z]+$'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UpdatePermissionRequest'
      responses:
        '200':
          description: Permission updated successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/PermissionResponse'
        '400':
          description: Bad request - Invalid request body
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '401':
          description: Unauthorized - Missing or invalid token
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '403':
          description: Forbidden - Insufficient permissions
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '404':
          description: Permission not found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '500':
          description: Internal server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
      x-amazon-apigateway-integration:
        type: aws_proxy
        httpMethod: POST
        uri: arn:aws:apigateway:${aws_region}:lambda:path/2015-03-31/functions/${update_permission_lambda_arn}/invocations
        passthroughBehavior: when_no_match
        contentHandling: CONVERT_TO_TEXT

    delete:
      operationId: deletePermission
      tags:
        - Permissions
      summary: Delete a permission
      description: |
        Soft deletes a permission by setting active=false.
        System permissions cannot be deleted, only deactivated via update.
      security:
        - BearerAuth: []
        - LambdaAuthorizer: []
      parameters:
        - name: permissionId
          in: path
          description: Permission ID in format 'resource:action'
          required: true
          schema:
            type: string
            pattern: '^[a-z]+:[a-z]+$'
      responses:
        '204':
          description: Permission deleted successfully (no content)
        '400':
          description: Bad request - Invalid permission ID format
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '401':
          description: Unauthorized - Missing or invalid token
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '403':
          description: Forbidden - Insufficient permissions or system permission
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '404':
          description: Permission not found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '500':
          description: Internal server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
      x-amazon-apigateway-integration:
        type: aws_proxy
        httpMethod: POST
        uri: arn:aws:apigateway:${aws_region}:lambda:path/2015-03-31/functions/${delete_permission_lambda_arn}/invocations
        passthroughBehavior: when_no_match
        contentHandling: CONVERT_TO_TEXT

  /permissions/seed:
    post:
      operationId: seedPermissions
      tags:
        - Permissions
      summary: Seed platform permissions
      description: |
        Seeds the platform with default permissions. This operation is idempotent.
        Existing permissions will not be modified.
        Requires platform super-admin privileges.
      security:
        - BearerAuth: []
        - LambdaAuthorizer: []
      requestBody:
        required: false
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/SeedPermissionsRequest'
      responses:
        '200':
          description: Permissions seeded successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/SeedPermissionsResponse'
        '401':
          description: Unauthorized - Missing or invalid token
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '403':
          description: Forbidden - Requires super-admin privileges
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '500':
          description: Internal server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
      x-amazon-apigateway-integration:
        type: aws_proxy
        httpMethod: POST
        uri: arn:aws:apigateway:${aws_region}:lambda:path/2015-03-31/functions/${seed_permissions_lambda_arn}/invocations
        passthroughBehavior: when_no_match
        contentHandling: CONVERT_TO_TEXT

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
    LambdaAuthorizer:
      type: apiKey
      name: Authorization
      in: header
      x-amazon-apigateway-authtype: custom
      x-amazon-apigateway-authorizer:
        type: token
        authorizerUri: arn:aws:apigateway:${aws_region}:lambda:path/2015-03-31/functions/${authorizer_lambda_arn}/invocations
        authorizerResultTtlInSeconds: 300
        identitySource: method.request.header.Authorization

  schemas:
    Permission:
      type: object
      required:
        - id
        - name
        - description
        - resource
        - action
        - category
        - active
        - dateCreated
      properties:
        id:
          type: string
          description: Permission ID in format resource:action
          example: "site:create"
        name:
          type: string
          description: Human-readable permission name
          minLength: 3
          maxLength: 100
          example: "Create Site"
        description:
          type: string
          description: Detailed description of the permission
          minLength: 10
          maxLength: 500
          example: "Allows creating new WordPress sites within a team"
        resource:
          type: string
          description: Resource type this permission applies to
          example: "site"
        action:
          type: string
          description: Action type this permission allows
          example: "create"
        category:
          type: string
          description: Permission category grouping
          enum:
            - SITE
            - TEAM
            - ORGANISATION
            - INVITATION
            - ROLE
            - AUDIT
          example: "SITE"
        isSystem:
          type: boolean
          description: Whether this is a system-defined permission
          example: true
        active:
          type: boolean
          description: Whether the permission is currently active
          example: true
        dateCreated:
          type: string
          format: date-time
          description: ISO 8601 timestamp of creation
          example: "2026-01-01T00:00:00Z"

    HATEOASLink:
      type: object
      required:
        - href
      properties:
        href:
          type: string
          description: URL of the linked resource
          example: "/v1/permissions/site:create"
        method:
          type: string
          description: HTTP method for the link
          enum: [GET, POST, PUT, DELETE, PATCH]
          example: "GET"
        body:
          type: object
          description: Optional request body template
          additionalProperties: true

    PermissionResponse:
      allOf:
        - $ref: '#/components/schemas/Permission'
        - type: object
          properties:
            _links:
              type: object
              description: HATEOAS links
              properties:
                self:
                  $ref: '#/components/schemas/HATEOASLink'
                update:
                  $ref: '#/components/schemas/HATEOASLink'
                delete:
                  $ref: '#/components/schemas/HATEOASLink'

    PaginatedPermissionResponse:
      type: object
      required:
        - items
        - count
        - moreAvailable
      properties:
        items:
          type: array
          items:
            $ref: '#/components/schemas/PermissionResponse'
          description: List of permissions
        startAt:
          type: string
          nullable: true
          description: Cursor for the next page
        moreAvailable:
          type: boolean
          description: Whether more items are available
        count:
          type: integer
          description: Number of items in current response
          example: 50
        _links:
          type: object
          description: HATEOAS links for pagination
          properties:
            self:
              $ref: '#/components/schemas/HATEOASLink'
            next:
              $ref: '#/components/schemas/HATEOASLink'

    CreatePermissionRequest:
      type: object
      required:
        - permissionId
        - name
        - description
        - resource
        - action
        - category
      properties:
        permissionId:
          type: string
          description: Unique permission ID in format resource:action
          pattern: '^[a-z]+:[a-z]+$'
          example: "site:create"
        name:
          type: string
          description: Human-readable permission name
          minLength: 3
          maxLength: 100
          example: "Create Site"
        description:
          type: string
          description: Detailed description of the permission
          minLength: 10
          maxLength: 500
          example: "Allows creating new WordPress sites within a team"
        resource:
          type: string
          description: Resource type
          minLength: 1
          maxLength: 50
          example: "site"
        action:
          type: string
          description: Action type
          minLength: 1
          maxLength: 50
          example: "create"
        category:
          type: string
          description: Permission category
          enum:
            - SITE
            - TEAM
            - ORGANISATION
            - INVITATION
            - ROLE
            - AUDIT
          example: "SITE"
        isSystem:
          type: boolean
          description: Whether this is a system permission
          default: false

    UpdatePermissionRequest:
      type: object
      minProperties: 1
      properties:
        name:
          type: string
          description: Updated permission name
          minLength: 3
          maxLength: 100
          example: "Create WordPress Site"
        description:
          type: string
          description: Updated permission description
          minLength: 10
          maxLength: 500
          example: "Allows creating new WordPress sites within a team or organisation"
        active:
          type: boolean
          description: Updated active status
          example: true

    SeedPermissionsRequest:
      type: object
      properties:
        overwrite:
          type: boolean
          description: Whether to overwrite existing permissions
          default: false
        categories:
          type: array
          items:
            type: string
            enum:
              - SITE
              - TEAM
              - ORGANISATION
              - INVITATION
              - ROLE
              - AUDIT
          description: Categories to seed (defaults to all)

    SeedPermissionsResponse:
      type: object
      required:
        - created
        - skipped
        - total
      properties:
        created:
          type: integer
          description: Number of permissions created
          example: 25
        skipped:
          type: integer
          description: Number of permissions skipped (already exist)
          example: 0
        total:
          type: integer
          description: Total number of default permissions
          example: 25
        permissions:
          type: array
          items:
            $ref: '#/components/schemas/PermissionResponse'
          description: List of created permissions
        _links:
          type: object
          properties:
            list:
              $ref: '#/components/schemas/HATEOASLink'

    ErrorResponse:
      type: object
      required:
        - errorCode
        - message
      properties:
        errorCode:
          type: string
          description: Machine-readable error code
          example: "PERMISSION_NOT_FOUND"
        message:
          type: string
          description: Human-readable error message
          example: "Permission not found: site:invalid"
        details:
          type: object
          description: Additional error details
          additionalProperties: true
        requestId:
          type: string
          description: Request ID for tracing
          example: "abc123-def456"
```

---

## Terraform Route Configuration

### terraform/modules/permission-api-routes/main.tf

```hcl
#------------------------------------------------------------------------------
# Permission Service API Routes - Terraform Configuration
# Description: API Gateway routes for Permission Service (6 endpoints)
#------------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

#==============================================================================
# LOCAL VARIABLES
#==============================================================================

locals {
  service_name = "permission"
  base_path    = "permissions"

  # Lambda function configurations
  lambda_functions = {
    list_permissions = {
      method          = "GET"
      path            = "permissions"
      resource_id     = aws_api_gateway_resource.permissions.id
      authorization   = "CUSTOM"
      validate_body   = false
      request_params  = {}
    }
    get_permission = {
      method          = "GET"
      path            = "permissions/{permissionId}"
      resource_id     = aws_api_gateway_resource.permissions_id.id
      authorization   = "CUSTOM"
      validate_body   = false
      request_params  = {
        "method.request.path.permissionId" = true
      }
    }
    create_permission = {
      method          = "POST"
      path            = "permissions"
      resource_id     = aws_api_gateway_resource.permissions.id
      authorization   = "CUSTOM"
      validate_body   = true
      request_params  = {}
    }
    update_permission = {
      method          = "PUT"
      path            = "permissions/{permissionId}"
      resource_id     = aws_api_gateway_resource.permissions_id.id
      authorization   = "CUSTOM"
      validate_body   = true
      request_params  = {
        "method.request.path.permissionId" = true
      }
    }
    delete_permission = {
      method          = "DELETE"
      path            = "permissions/{permissionId}"
      resource_id     = aws_api_gateway_resource.permissions_id.id
      authorization   = "CUSTOM"
      validate_body   = false
      request_params  = {
        "method.request.path.permissionId" = true
      }
    }
    seed_permissions = {
      method          = "POST"
      path            = "permissions/seed"
      resource_id     = aws_api_gateway_resource.permissions_seed.id
      authorization   = "CUSTOM"
      validate_body   = false
      request_params  = {}
    }
  }
}

#==============================================================================
# API GATEWAY RESOURCES
#==============================================================================

# /v1/permissions
resource "aws_api_gateway_resource" "permissions" {
  rest_api_id = var.rest_api_id
  parent_id   = var.v1_resource_id
  path_part   = "permissions"
}

# /v1/permissions/{permissionId}
resource "aws_api_gateway_resource" "permissions_id" {
  rest_api_id = var.rest_api_id
  parent_id   = aws_api_gateway_resource.permissions.id
  path_part   = "{permissionId}"
}

# /v1/permissions/seed
resource "aws_api_gateway_resource" "permissions_seed" {
  rest_api_id = var.rest_api_id
  parent_id   = aws_api_gateway_resource.permissions.id
  path_part   = "seed"
}

#==============================================================================
# REQUEST VALIDATORS
#==============================================================================

resource "aws_api_gateway_request_validator" "permission_body_validator" {
  name                        = "permission-body-validator"
  rest_api_id                 = var.rest_api_id
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_api_gateway_request_validator" "permission_params_validator" {
  name                        = "permission-params-validator"
  rest_api_id                 = var.rest_api_id
  validate_request_body       = false
  validate_request_parameters = true
}

#==============================================================================
# API GATEWAY METHODS
#==============================================================================

# GET /v1/permissions - List Permissions
resource "aws_api_gateway_method" "list_permissions" {
  rest_api_id          = var.rest_api_id
  resource_id          = aws_api_gateway_resource.permissions.id
  http_method          = "GET"
  authorization        = "CUSTOM"
  authorizer_id        = var.authorizer_id
  request_validator_id = aws_api_gateway_request_validator.permission_params_validator.id

  request_parameters = {
    "method.request.querystring.pageSize" = false
    "method.request.querystring.startAt"  = false
    "method.request.querystring.category" = false
  }
}

# GET /v1/permissions/{permissionId} - Get Permission
resource "aws_api_gateway_method" "get_permission" {
  rest_api_id          = var.rest_api_id
  resource_id          = aws_api_gateway_resource.permissions_id.id
  http_method          = "GET"
  authorization        = "CUSTOM"
  authorizer_id        = var.authorizer_id
  request_validator_id = aws_api_gateway_request_validator.permission_params_validator.id

  request_parameters = {
    "method.request.path.permissionId" = true
  }
}

# POST /v1/permissions - Create Permission
resource "aws_api_gateway_method" "create_permission" {
  rest_api_id          = var.rest_api_id
  resource_id          = aws_api_gateway_resource.permissions.id
  http_method          = "POST"
  authorization        = "CUSTOM"
  authorizer_id        = var.authorizer_id
  request_validator_id = aws_api_gateway_request_validator.permission_body_validator.id

  request_models = {
    "application/json" = aws_api_gateway_model.create_permission_request.name
  }
}

# PUT /v1/permissions/{permissionId} - Update Permission
resource "aws_api_gateway_method" "update_permission" {
  rest_api_id          = var.rest_api_id
  resource_id          = aws_api_gateway_resource.permissions_id.id
  http_method          = "PUT"
  authorization        = "CUSTOM"
  authorizer_id        = var.authorizer_id
  request_validator_id = aws_api_gateway_request_validator.permission_body_validator.id

  request_parameters = {
    "method.request.path.permissionId" = true
  }

  request_models = {
    "application/json" = aws_api_gateway_model.update_permission_request.name
  }
}

# DELETE /v1/permissions/{permissionId} - Delete Permission
resource "aws_api_gateway_method" "delete_permission" {
  rest_api_id          = var.rest_api_id
  resource_id          = aws_api_gateway_resource.permissions_id.id
  http_method          = "DELETE"
  authorization        = "CUSTOM"
  authorizer_id        = var.authorizer_id
  request_validator_id = aws_api_gateway_request_validator.permission_params_validator.id

  request_parameters = {
    "method.request.path.permissionId" = true
  }
}

# POST /v1/permissions/seed - Seed Permissions
resource "aws_api_gateway_method" "seed_permissions" {
  rest_api_id          = var.rest_api_id
  resource_id          = aws_api_gateway_resource.permissions_seed.id
  http_method          = "POST"
  authorization        = "CUSTOM"
  authorizer_id        = var.authorizer_id
}

#==============================================================================
# API GATEWAY INTEGRATIONS - Lambda Proxy
#==============================================================================

# GET /v1/permissions - List Permissions Integration
resource "aws_api_gateway_integration" "list_permissions" {
  rest_api_id             = var.rest_api_id
  resource_id             = aws_api_gateway_resource.permissions.id
  http_method             = aws_api_gateway_method.list_permissions.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arns.list_permissions

  # Timeout (29 seconds max for API Gateway)
  timeout_milliseconds = 29000
}

# GET /v1/permissions/{permissionId} - Get Permission Integration
resource "aws_api_gateway_integration" "get_permission" {
  rest_api_id             = var.rest_api_id
  resource_id             = aws_api_gateway_resource.permissions_id.id
  http_method             = aws_api_gateway_method.get_permission.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arns.get_permission

  timeout_milliseconds = 29000
}

# POST /v1/permissions - Create Permission Integration
resource "aws_api_gateway_integration" "create_permission" {
  rest_api_id             = var.rest_api_id
  resource_id             = aws_api_gateway_resource.permissions.id
  http_method             = aws_api_gateway_method.create_permission.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arns.create_permission

  timeout_milliseconds = 29000
}

# PUT /v1/permissions/{permissionId} - Update Permission Integration
resource "aws_api_gateway_integration" "update_permission" {
  rest_api_id             = var.rest_api_id
  resource_id             = aws_api_gateway_resource.permissions_id.id
  http_method             = aws_api_gateway_method.update_permission.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arns.update_permission

  timeout_milliseconds = 29000
}

# DELETE /v1/permissions/{permissionId} - Delete Permission Integration
resource "aws_api_gateway_integration" "delete_permission" {
  rest_api_id             = var.rest_api_id
  resource_id             = aws_api_gateway_resource.permissions_id.id
  http_method             = aws_api_gateway_method.delete_permission.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arns.delete_permission

  timeout_milliseconds = 29000
}

# POST /v1/permissions/seed - Seed Permissions Integration
resource "aws_api_gateway_integration" "seed_permissions" {
  rest_api_id             = var.rest_api_id
  resource_id             = aws_api_gateway_resource.permissions_seed.id
  http_method             = aws_api_gateway_method.seed_permissions.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arns.seed_permissions

  timeout_milliseconds = 29000
}

#==============================================================================
# LAMBDA PERMISSIONS FOR API GATEWAY
#==============================================================================

resource "aws_lambda_permission" "list_permissions" {
  statement_id  = "AllowAPIGatewayInvoke-ListPermissions-${var.environment}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_names.list_permissions
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.rest_api_execution_arn}/*/${aws_api_gateway_method.list_permissions.http_method}${aws_api_gateway_resource.permissions.path}"
}

resource "aws_lambda_permission" "get_permission" {
  statement_id  = "AllowAPIGatewayInvoke-GetPermission-${var.environment}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_names.get_permission
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.rest_api_execution_arn}/*/${aws_api_gateway_method.get_permission.http_method}${aws_api_gateway_resource.permissions_id.path}"
}

resource "aws_lambda_permission" "create_permission" {
  statement_id  = "AllowAPIGatewayInvoke-CreatePermission-${var.environment}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_names.create_permission
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.rest_api_execution_arn}/*/${aws_api_gateway_method.create_permission.http_method}${aws_api_gateway_resource.permissions.path}"
}

resource "aws_lambda_permission" "update_permission" {
  statement_id  = "AllowAPIGatewayInvoke-UpdatePermission-${var.environment}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_names.update_permission
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.rest_api_execution_arn}/*/${aws_api_gateway_method.update_permission.http_method}${aws_api_gateway_resource.permissions_id.path}"
}

resource "aws_lambda_permission" "delete_permission" {
  statement_id  = "AllowAPIGatewayInvoke-DeletePermission-${var.environment}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_names.delete_permission
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.rest_api_execution_arn}/*/${aws_api_gateway_method.delete_permission.http_method}${aws_api_gateway_resource.permissions_id.path}"
}

resource "aws_lambda_permission" "seed_permissions" {
  statement_id  = "AllowAPIGatewayInvoke-SeedPermissions-${var.environment}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_names.seed_permissions
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.rest_api_execution_arn}/*/${aws_api_gateway_method.seed_permissions.http_method}${aws_api_gateway_resource.permissions_seed.path}"
}
```

### terraform/modules/permission-api-routes/variables.tf

```hcl
#------------------------------------------------------------------------------
# Permission API Routes - Input Variables
#------------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (dev, sit, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "sit", "prod"], var.environment)
    error_message = "Environment must be one of: dev, sit, prod."
  }
}

variable "rest_api_id" {
  description = "The ID of the REST API"
  type        = string
}

variable "rest_api_execution_arn" {
  description = "The execution ARN of the REST API"
  type        = string
}

variable "v1_resource_id" {
  description = "The resource ID of the /v1 path"
  type        = string
}

variable "authorizer_id" {
  description = "The ID of the Lambda authorizer"
  type        = string
}

variable "lambda_invoke_arns" {
  description = "Map of Lambda invoke ARNs for Permission Service"
  type = object({
    list_permissions   = string
    get_permission     = string
    create_permission  = string
    update_permission  = string
    delete_permission  = string
    seed_permissions   = string
  })
}

variable "lambda_function_names" {
  description = "Map of Lambda function names for Permission Service"
  type = object({
    list_permissions   = string
    get_permission     = string
    create_permission  = string
    update_permission  = string
    delete_permission  = string
    seed_permissions   = string
  })
}

variable "cors_allowed_origins" {
  description = "Allowed origins for CORS"
  type        = string
  default     = "*"
}
```

### terraform/modules/permission-api-routes/outputs.tf

```hcl
#------------------------------------------------------------------------------
# Permission API Routes - Outputs
#------------------------------------------------------------------------------

output "resource_ids" {
  description = "Map of resource IDs created"
  value = {
    permissions      = aws_api_gateway_resource.permissions.id
    permissions_id   = aws_api_gateway_resource.permissions_id.id
    permissions_seed = aws_api_gateway_resource.permissions_seed.id
  }
}

output "resource_paths" {
  description = "Map of resource paths"
  value = {
    permissions      = aws_api_gateway_resource.permissions.path
    permissions_id   = aws_api_gateway_resource.permissions_id.path
    permissions_seed = aws_api_gateway_resource.permissions_seed.path
  }
}

output "method_ids" {
  description = "Map of method IDs created"
  value = {
    list_permissions   = aws_api_gateway_method.list_permissions.id
    get_permission     = aws_api_gateway_method.get_permission.id
    create_permission  = aws_api_gateway_method.create_permission.id
    update_permission  = aws_api_gateway_method.update_permission.id
    delete_permission  = aws_api_gateway_method.delete_permission.id
    seed_permissions   = aws_api_gateway_method.seed_permissions.id
  }
}

output "integration_ids" {
  description = "Map of integration IDs created"
  value = {
    list_permissions   = aws_api_gateway_integration.list_permissions.id
    get_permission     = aws_api_gateway_integration.get_permission.id
    create_permission  = aws_api_gateway_integration.create_permission.id
    update_permission  = aws_api_gateway_integration.update_permission.id
    delete_permission  = aws_api_gateway_integration.delete_permission.id
    seed_permissions   = aws_api_gateway_integration.seed_permissions.id
  }
}

output "endpoint_summary" {
  description = "Summary of all Permission Service endpoints"
  value = {
    list_permissions   = "GET /v1/permissions"
    get_permission     = "GET /v1/permissions/{permissionId}"
    create_permission  = "POST /v1/permissions"
    update_permission  = "PUT /v1/permissions/{permissionId}"
    delete_permission  = "DELETE /v1/permissions/{permissionId}"
    seed_permissions   = "POST /v1/permissions/seed"
  }
}
```

---

## Request/Response JSON Schemas

### terraform/modules/permission-api-routes/models.tf

```hcl
#------------------------------------------------------------------------------
# Permission API Routes - Request/Response Models
#------------------------------------------------------------------------------

#==============================================================================
# CREATE PERMISSION REQUEST MODEL
#==============================================================================

resource "aws_api_gateway_model" "create_permission_request" {
  rest_api_id  = var.rest_api_id
  name         = "CreatePermissionRequest"
  description  = "Request model for creating a permission"
  content_type = "application/json"

  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#"
    title     = "CreatePermissionRequest"
    type      = "object"
    required  = ["permissionId", "name", "description", "resource", "action", "category"]
    properties = {
      permissionId = {
        type        = "string"
        pattern     = "^[a-z]+:[a-z]+$"
        description = "Permission ID in format resource:action"
        minLength   = 3
        maxLength   = 100
      }
      name = {
        type        = "string"
        description = "Human-readable permission name"
        minLength   = 3
        maxLength   = 100
      }
      description = {
        type        = "string"
        description = "Permission description"
        minLength   = 10
        maxLength   = 500
      }
      resource = {
        type        = "string"
        description = "Resource type"
        minLength   = 1
        maxLength   = 50
      }
      action = {
        type        = "string"
        description = "Action type"
        minLength   = 1
        maxLength   = 50
      }
      category = {
        type        = "string"
        description = "Permission category"
        enum        = ["SITE", "TEAM", "ORGANISATION", "INVITATION", "ROLE", "AUDIT"]
      }
      isSystem = {
        type        = "boolean"
        description = "Whether this is a system permission"
        default     = false
      }
    }
  })
}

#==============================================================================
# UPDATE PERMISSION REQUEST MODEL
#==============================================================================

resource "aws_api_gateway_model" "update_permission_request" {
  rest_api_id  = var.rest_api_id
  name         = "UpdatePermissionRequest"
  description  = "Request model for updating a permission"
  content_type = "application/json"

  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#"
    title     = "UpdatePermissionRequest"
    type      = "object"
    minProperties = 1
    properties = {
      name = {
        type        = "string"
        description = "Updated permission name"
        minLength   = 3
        maxLength   = 100
      }
      description = {
        type        = "string"
        description = "Updated permission description"
        minLength   = 10
        maxLength   = 500
      }
      active = {
        type        = "boolean"
        description = "Updated active status"
      }
    }
  })
}

#==============================================================================
# PERMISSION RESPONSE MODEL
#==============================================================================

resource "aws_api_gateway_model" "permission_response" {
  rest_api_id  = var.rest_api_id
  name         = "PermissionResponse"
  description  = "Response model for a single permission"
  content_type = "application/json"

  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#"
    title     = "PermissionResponse"
    type      = "object"
    required  = ["id", "name", "description", "resource", "action", "category", "active", "dateCreated"]
    properties = {
      id = {
        type        = "string"
        description = "Permission ID"
      }
      name = {
        type        = "string"
        description = "Permission name"
      }
      description = {
        type        = "string"
        description = "Permission description"
      }
      resource = {
        type        = "string"
        description = "Resource type"
      }
      action = {
        type        = "string"
        description = "Action type"
      }
      category = {
        type        = "string"
        description = "Permission category"
      }
      isSystem = {
        type        = "boolean"
        description = "System permission flag"
      }
      active = {
        type        = "boolean"
        description = "Active status"
      }
      dateCreated = {
        type        = "string"
        format      = "date-time"
        description = "Creation timestamp"
      }
      _links = {
        type = "object"
        properties = {
          self = {
            type = "object"
            properties = {
              href   = { type = "string" }
              method = { type = "string" }
            }
          }
        }
      }
    }
  })
}

#==============================================================================
# PAGINATED PERMISSION RESPONSE MODEL
#==============================================================================

resource "aws_api_gateway_model" "paginated_permission_response" {
  rest_api_id  = var.rest_api_id
  name         = "PaginatedPermissionResponse"
  description  = "Response model for paginated permission list"
  content_type = "application/json"

  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#"
    title     = "PaginatedPermissionResponse"
    type      = "object"
    required  = ["items", "count", "moreAvailable"]
    properties = {
      items = {
        type  = "array"
        items = { "$ref" = "https://apigateway.amazonaws.com/restapis/${var.rest_api_id}/models/PermissionResponse" }
      }
      startAt = {
        type        = "string"
        description = "Pagination cursor"
      }
      moreAvailable = {
        type        = "boolean"
        description = "More items available flag"
      }
      count = {
        type        = "integer"
        description = "Number of items returned"
      }
      _links = {
        type = "object"
        properties = {
          self = {
            type = "object"
            properties = {
              href = { type = "string" }
            }
          }
          next = {
            type = "object"
            properties = {
              href = { type = "string" }
            }
          }
        }
      }
    }
  })
}

#==============================================================================
# ERROR RESPONSE MODEL
#==============================================================================

resource "aws_api_gateway_model" "error_response" {
  rest_api_id  = var.rest_api_id
  name         = "ErrorResponse"
  description  = "Standard error response model"
  content_type = "application/json"

  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#"
    title     = "ErrorResponse"
    type      = "object"
    required  = ["errorCode", "message"]
    properties = {
      errorCode = {
        type        = "string"
        description = "Machine-readable error code"
      }
      message = {
        type        = "string"
        description = "Human-readable error message"
      }
      details = {
        type        = "object"
        description = "Additional error details"
      }
      requestId = {
        type        = "string"
        description = "Request ID for tracing"
      }
    }
  })
}

#==============================================================================
# SEED PERMISSIONS RESPONSE MODEL
#==============================================================================

resource "aws_api_gateway_model" "seed_permissions_response" {
  rest_api_id  = var.rest_api_id
  name         = "SeedPermissionsResponse"
  description  = "Response model for seed permissions operation"
  content_type = "application/json"

  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#"
    title     = "SeedPermissionsResponse"
    type      = "object"
    required  = ["created", "skipped", "total"]
    properties = {
      created = {
        type        = "integer"
        description = "Number of permissions created"
      }
      skipped = {
        type        = "integer"
        description = "Number of permissions skipped"
      }
      total = {
        type        = "integer"
        description = "Total default permissions"
      }
      permissions = {
        type  = "array"
        items = { "$ref" = "https://apigateway.amazonaws.com/restapis/${var.rest_api_id}/models/PermissionResponse" }
      }
      _links = {
        type = "object"
        properties = {
          list = {
            type = "object"
            properties = {
              href = { type = "string" }
            }
          }
        }
      }
    }
  })
}
```

---

## CORS Configuration

### terraform/modules/permission-api-routes/cors.tf

```hcl
#------------------------------------------------------------------------------
# Permission API Routes - CORS Configuration
# Description: OPTIONS methods for CORS preflight requests
#------------------------------------------------------------------------------

#==============================================================================
# CORS CONFIGURATION LOCALS
#==============================================================================

locals {
  cors_headers = {
    allow_origin  = var.cors_allowed_origins
    allow_methods = "GET,POST,PUT,DELETE,OPTIONS"
    allow_headers = "Content-Type,Authorization,X-Request-ID,X-Amz-Date,X-Api-Key,X-Amz-Security-Token"
    max_age       = "7200"
  }

  # Resources that need CORS OPTIONS method
  cors_resources = {
    permissions      = aws_api_gateway_resource.permissions.id
    permissions_id   = aws_api_gateway_resource.permissions_id.id
    permissions_seed = aws_api_gateway_resource.permissions_seed.id
  }
}

#==============================================================================
# OPTIONS METHOD - /v1/permissions
#==============================================================================

resource "aws_api_gateway_method" "permissions_options" {
  rest_api_id   = var.rest_api_id
  resource_id   = aws_api_gateway_resource.permissions.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "permissions_options" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.permissions.id
  http_method = aws_api_gateway_method.permissions_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

resource "aws_api_gateway_method_response" "permissions_options" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.permissions.id
  http_method = aws_api_gateway_method.permissions_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Max-Age"       = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "permissions_options" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.permissions.id
  http_method = aws_api_gateway_method.permissions_options.http_method
  status_code = aws_api_gateway_method_response.permissions_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'${local.cors_headers.allow_headers}'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'${local.cors_headers.allow_origin}'"
    "method.response.header.Access-Control-Max-Age"       = "'${local.cors_headers.max_age}'"
  }
}

#==============================================================================
# OPTIONS METHOD - /v1/permissions/{permissionId}
#==============================================================================

resource "aws_api_gateway_method" "permissions_id_options" {
  rest_api_id   = var.rest_api_id
  resource_id   = aws_api_gateway_resource.permissions_id.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "permissions_id_options" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.permissions_id.id
  http_method = aws_api_gateway_method.permissions_id_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

resource "aws_api_gateway_method_response" "permissions_id_options" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.permissions_id.id
  http_method = aws_api_gateway_method.permissions_id_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Max-Age"       = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "permissions_id_options" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.permissions_id.id
  http_method = aws_api_gateway_method.permissions_id_options.http_method
  status_code = aws_api_gateway_method_response.permissions_id_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'${local.cors_headers.allow_headers}'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'${local.cors_headers.allow_origin}'"
    "method.response.header.Access-Control-Max-Age"       = "'${local.cors_headers.max_age}'"
  }
}

#==============================================================================
# OPTIONS METHOD - /v1/permissions/seed
#==============================================================================

resource "aws_api_gateway_method" "permissions_seed_options" {
  rest_api_id   = var.rest_api_id
  resource_id   = aws_api_gateway_resource.permissions_seed.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "permissions_seed_options" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.permissions_seed.id
  http_method = aws_api_gateway_method.permissions_seed_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

resource "aws_api_gateway_method_response" "permissions_seed_options" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.permissions_seed.id
  http_method = aws_api_gateway_method.permissions_seed_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Max-Age"       = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "permissions_seed_options" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.permissions_seed.id
  http_method = aws_api_gateway_method.permissions_seed_options.http_method
  status_code = aws_api_gateway_method_response.permissions_seed_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'${local.cors_headers.allow_headers}'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'${local.cors_headers.allow_origin}'"
    "method.response.header.Access-Control-Max-Age"       = "'${local.cors_headers.max_age}'"
  }
}
```

---

## Lambda Proxy Integration Settings

### Integration Configuration Details

```hcl
#------------------------------------------------------------------------------
# Lambda Proxy Integration Configuration
# Description: AWS_PROXY integration settings for all Permission Service endpoints
#------------------------------------------------------------------------------

# Integration Type: AWS_PROXY
# - API Gateway passes the entire request to Lambda as a structured event
# - Lambda returns a complete HTTP response
# - No request/response mapping templates needed

# Integration HTTP Method: POST
# - All Lambda invocations use POST regardless of the API method
# - This is an AWS requirement for Lambda proxy integrations

# Timeout: 29000ms (29 seconds)
# - API Gateway maximum timeout is 29 seconds
# - Lambda functions should complete within this window
# - Consider implementing dead letter queues for long-running operations

# Content Handling: CONVERT_TO_TEXT
# - Binary data will be base64 encoded
# - Text data passed as-is

#==============================================================================
# LAMBDA EVENT STRUCTURE (API Gateway Proxy)
#==============================================================================

# The Lambda function receives events in this format:
# {
#   "resource": "/v1/permissions/{permissionId}",
#   "path": "/v1/permissions/site:create",
#   "httpMethod": "GET",
#   "headers": {
#     "Authorization": "Bearer eyJhbGc...",
#     "Content-Type": "application/json",
#     "X-Request-ID": "abc123"
#   },
#   "queryStringParameters": {
#     "pageSize": "50",
#     "category": "SITE"
#   },
#   "pathParameters": {
#     "permissionId": "site:create"
#   },
#   "body": "{\"name\": \"...\"}",  # For POST/PUT requests
#   "isBase64Encoded": false,
#   "requestContext": {
#     "authorizer": {
#       "userId": "user123",
#       "email": "user@example.com",
#       "orgId": "org123",
#       "permissions": "site:create,site:read",
#       "teamIds": "team1,team2"
#     },
#     "requestId": "abc123-def456",
#     "stage": "dev"
#   }
# }

#==============================================================================
# LAMBDA RESPONSE STRUCTURE
#==============================================================================

# Lambda functions must return responses in this format:
# {
#   "statusCode": 200,
#   "headers": {
#     "Content-Type": "application/json",
#     "Access-Control-Allow-Origin": "*",
#     "X-Request-ID": "abc123"
#   },
#   "body": "{\"id\": \"site:create\", ...}",
#   "isBase64Encoded": false
# }

#==============================================================================
# AUTHORIZER CONTEXT
#==============================================================================

# The Lambda authorizer enriches requests with user context:
# - userId: Cognito user sub
# - email: User email address
# - orgId: User's organisation ID
# - permissions: Comma-separated list of permission IDs
# - teamIds: Comma-separated list of team IDs
# - roleIds: Comma-separated list of role IDs

# Lambda handlers access this via:
# event['requestContext']['authorizer']['userId']
```

### Sample Lambda Handler Pattern

```python
# Sample handler pattern for Permission Service Lambda functions

import json
from typing import Dict, Any
from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

logger = Logger()
tracer = Tracer()

@logger.inject_lambda_context
@tracer.capture_lambda_handler
def handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """
    Lambda handler for Permission Service endpoint.

    Args:
        event: API Gateway proxy event
        context: Lambda context

    Returns:
        API Gateway proxy response
    """
    try:
        # Extract request context from authorizer
        request_context = event.get('requestContext', {})
        authorizer_context = request_context.get('authorizer', {})

        user_id = authorizer_context.get('userId')
        user_permissions = authorizer_context.get('permissions', '').split(',')

        # Extract path parameters
        path_params = event.get('pathParameters', {}) or {}
        permission_id = path_params.get('permissionId')

        # Extract query parameters
        query_params = event.get('queryStringParameters', {}) or {}
        page_size = int(query_params.get('pageSize', 50))

        # Extract request body for POST/PUT
        body = None
        if event.get('body'):
            body = json.loads(event['body'])

        # Process request...
        result = process_request(permission_id, body, user_id, user_permissions)

        # Return success response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'X-Request-ID': request_context.get('requestId', '')
            },
            'body': json.dumps(result, default=str)
        }

    except ValidationError as e:
        return error_response(400, 'VALIDATION_ERROR', str(e))
    except NotFoundException as e:
        return error_response(404, 'NOT_FOUND', str(e))
    except ForbiddenException as e:
        return error_response(403, 'FORBIDDEN', str(e))
    except Exception as e:
        logger.exception("Unexpected error")
        return error_response(500, 'INTERNAL_ERROR', 'An unexpected error occurred')


def error_response(status_code: int, error_code: str, message: str) -> Dict[str, Any]:
    """Build error response."""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'errorCode': error_code,
            'message': message
        })
    }
```

---

## Endpoint Summary Table

| # | Method | Path | Resource ID Ref | Lambda | Auth | CORS |
|---|--------|------|-----------------|--------|------|------|
| 1 | GET | `/v1/permissions` | `aws_api_gateway_resource.permissions.id` | list_permissions | CUSTOM | Yes |
| 2 | GET | `/v1/permissions/{permissionId}` | `aws_api_gateway_resource.permissions_id.id` | get_permission | CUSTOM | Yes |
| 3 | POST | `/v1/permissions` | `aws_api_gateway_resource.permissions.id` | create_permission | CUSTOM | Yes |
| 4 | PUT | `/v1/permissions/{permissionId}` | `aws_api_gateway_resource.permissions_id.id` | update_permission | CUSTOM | Yes |
| 5 | DELETE | `/v1/permissions/{permissionId}` | `aws_api_gateway_resource.permissions_id.id` | delete_permission | CUSTOM | Yes |
| 6 | POST | `/v1/permissions/seed` | `aws_api_gateway_resource.permissions_seed.id` | seed_permissions | CUSTOM | Yes |

---

## Environment Configuration

### DEV Environment
```hcl
environment                = "dev"
cors_allowed_origins       = "http://localhost:3000,https://admin-dev.bbws.co.za"
authorizer_cache_ttl       = 0  # No caching for testing
```

### SIT Environment
```hcl
environment                = "sit"
cors_allowed_origins       = "https://admin-sit.bbws.co.za"
authorizer_cache_ttl       = 300  # 5 minute cache
```

### PROD Environment
```hcl
environment                = "prod"
cors_allowed_origins       = "https://admin.bbws.co.za"
authorizer_cache_ttl       = 300  # 5 minute cache
```

---

## Success Criteria Checklist

- [x] All 6 routes configured
  - [x] GET /v1/permissions (list)
  - [x] GET /v1/permissions/{permissionId} (get)
  - [x] POST /v1/permissions (create)
  - [x] PUT /v1/permissions/{permissionId} (update)
  - [x] DELETE /v1/permissions/{permissionId} (delete)
  - [x] POST /v1/permissions/seed (seed)
- [x] Lambda authorizer attached to all endpoints
- [x] Request validation enabled for POST/PUT methods
- [x] CORS configured with OPTIONS methods for all resources
- [x] OpenAPI 3.0 specification complete
- [x] Terraform route configuration complete
- [x] Request/response JSON schemas defined
- [x] Lambda proxy integration settings documented
- [x] Environment-specific configurations parameterized

---

## Files Created

```
terraform/modules/permission-api-routes/
├── main.tf           # API Gateway resources, methods, integrations
├── variables.tf      # Input variables
├── outputs.tf        # Output values
├── models.tf         # Request/response JSON schemas
└── cors.tf           # CORS OPTIONS methods configuration

openapi/
└── permission-service-openapi.yaml  # OpenAPI 3.0 specification
```

---

**Worker Status**: COMPLETE
**Completion Date**: 2026-01-23
**Output Location**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/project_plans/project-plan-2-access-management/stage-4-api-gateway-integration/worker-1-permission-api-routes/output.md`
