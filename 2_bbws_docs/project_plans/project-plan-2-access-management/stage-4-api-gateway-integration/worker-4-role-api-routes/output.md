# Role Service API Routes - Configuration

**Worker ID**: worker-4-role-api-routes
**Stage**: Stage 4 - API Gateway Integration
**Project**: project-plan-2-access-management
**Status**: COMPLETE
**Date**: 2026-01-23

---

## Table of Contents

1. [Endpoint Summary](#1-endpoint-summary)
2. [OpenAPI 3.0 Specification](#2-openapi-30-specification)
3. [Terraform Route Configuration](#3-terraform-route-configuration)
4. [Request/Response JSON Schemas](#4-requestresponse-json-schemas)
5. [CORS Configuration](#5-cors-configuration)
6. [Lambda Integration Details](#6-lambda-integration-details)
7. [Validation Rules](#7-validation-rules)

---

## 1. Endpoint Summary

### Platform Roles (2 - Read Only)

| Method | Path | Lambda Function | Description |
|--------|------|-----------------|-------------|
| GET | /v1/platform/roles | list_platform_roles | List all platform roles |
| GET | /v1/platform/roles/{roleId} | get_platform_role | Get a specific platform role |

### Organisation Roles (6)

| Method | Path | Lambda Function | Description |
|--------|------|-----------------|-------------|
| POST | /v1/orgs/{orgId}/roles | create_org_role | Create a new organisation role |
| GET | /v1/orgs/{orgId}/roles | list_org_roles | List organisation roles |
| GET | /v1/orgs/{orgId}/roles/{roleId} | get_org_role | Get a specific organisation role |
| PUT | /v1/orgs/{orgId}/roles/{roleId} | update_org_role | Update an organisation role |
| DELETE | /v1/orgs/{orgId}/roles/{roleId} | delete_org_role | Delete an organisation role |
| POST | /v1/orgs/{orgId}/roles/seed | seed_org_roles | Seed default roles for organisation |

**Total**: 8 Endpoints

---

## 2. OpenAPI 3.0 Specification

```yaml
# role-service.yaml
# OpenAPI 3.0 specification for Role Service API
# File: api-specs/role-service.yaml

openapi: "3.0.3"

info:
  title: BBWS Role Service API
  description: |
    API for managing platform and organisation roles in the BBWS Access Management system.

    Platform roles are system-defined and read-only.
    Organisation roles can be customized by organisation administrators.
  version: "1.0.0"
  contact:
    name: BBWS Platform Team
    email: platform@bbws.io

servers:
  - url: https://api-dev.aipagebuilder.bbws.io
    description: Development environment
  - url: https://api-sit.aipagebuilder.bbws.io
    description: SIT environment
  - url: https://api.aipagebuilder.bbws.io
    description: Production environment

tags:
  - name: Platform Roles
    description: System-defined platform roles (read-only)
  - name: Organisation Roles
    description: Customizable organisation-scoped roles

security:
  - BearerAuth: []

paths:
  # ============================================
  # PLATFORM ROLES (Read-Only)
  # ============================================
  /v1/platform/roles:
    get:
      operationId: listPlatformRoles
      summary: List all platform roles
      description: |
        Retrieve a paginated list of all system-defined platform roles.
        Platform roles are read-only and apply at the platform level.
      tags:
        - Platform Roles
      parameters:
        - $ref: '#/components/parameters/PageSize'
        - $ref: '#/components/parameters/StartAt'
        - $ref: '#/components/parameters/RequestId'
      responses:
        '200':
          $ref: '#/components/responses/RoleListResponse'
        '401':
          $ref: '#/components/responses/UnauthorizedError'
        '403':
          $ref: '#/components/responses/ForbiddenError'
        '500':
          $ref: '#/components/responses/InternalServerError'
      x-amazon-apigateway-integration:
        type: aws_proxy
        httpMethod: POST
        uri:
          Fn::Sub: arn:aws:apigateway:${AWS::Region}:lambda:path/2015-03-31/functions/${ListPlatformRolesFunction.Arn}/invocations
        passthroughBehavior: when_no_match
      x-amazon-apigateway-auth:
        type: custom
        authorizerId:
          Ref: LambdaAuthorizer

  /v1/platform/roles/{roleId}:
    get:
      operationId: getPlatformRole
      summary: Get a platform role by ID
      description: |
        Retrieve details of a specific platform role including its assigned permissions.
      tags:
        - Platform Roles
      parameters:
        - $ref: '#/components/parameters/RoleId'
        - $ref: '#/components/parameters/RequestId'
      responses:
        '200':
          $ref: '#/components/responses/RoleResponse'
        '401':
          $ref: '#/components/responses/UnauthorizedError'
        '403':
          $ref: '#/components/responses/ForbiddenError'
        '404':
          $ref: '#/components/responses/NotFoundError'
        '500':
          $ref: '#/components/responses/InternalServerError'
      x-amazon-apigateway-integration:
        type: aws_proxy
        httpMethod: POST
        uri:
          Fn::Sub: arn:aws:apigateway:${AWS::Region}:lambda:path/2015-03-31/functions/${GetPlatformRoleFunction.Arn}/invocations
        passthroughBehavior: when_no_match
      x-amazon-apigateway-auth:
        type: custom
        authorizerId:
          Ref: LambdaAuthorizer

  # ============================================
  # ORGANISATION ROLES
  # ============================================
  /v1/orgs/{orgId}/roles:
    post:
      operationId: createOrgRole
      summary: Create a new organisation role
      description: |
        Create a custom role within an organisation with specified permissions.
        Requires role:create permission.
      tags:
        - Organisation Roles
      parameters:
        - $ref: '#/components/parameters/OrgId'
        - $ref: '#/components/parameters/RequestId'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateRoleRequest'
            examples:
              basicRole:
                summary: Basic role creation
                value:
                  name: "CONTENT_MANAGER"
                  displayName: "Content Manager"
                  description: "Manages content across team sites"
                  scope: "ORGANISATION"
                  permissions:
                    - "site:read"
                    - "site:update"
                  priority: 50
      responses:
        '201':
          $ref: '#/components/responses/RoleCreatedResponse'
        '400':
          $ref: '#/components/responses/BadRequestError'
        '401':
          $ref: '#/components/responses/UnauthorizedError'
        '403':
          $ref: '#/components/responses/ForbiddenError'
        '409':
          $ref: '#/components/responses/ConflictError'
        '500':
          $ref: '#/components/responses/InternalServerError'
      x-amazon-apigateway-integration:
        type: aws_proxy
        httpMethod: POST
        uri:
          Fn::Sub: arn:aws:apigateway:${AWS::Region}:lambda:path/2015-03-31/functions/${CreateOrgRoleFunction.Arn}/invocations
        passthroughBehavior: when_no_match
      x-amazon-apigateway-auth:
        type: custom
        authorizerId:
          Ref: LambdaAuthorizer

    get:
      operationId: listOrgRoles
      summary: List organisation roles
      description: |
        Retrieve a paginated list of roles for the specified organisation.
        Supports filtering by scope and active status.
      tags:
        - Organisation Roles
      parameters:
        - $ref: '#/components/parameters/OrgId'
        - $ref: '#/components/parameters/Scope'
        - $ref: '#/components/parameters/IncludeInactive'
        - $ref: '#/components/parameters/PageSize'
        - $ref: '#/components/parameters/StartAt'
        - $ref: '#/components/parameters/RequestId'
      responses:
        '200':
          $ref: '#/components/responses/RoleListResponse'
        '401':
          $ref: '#/components/responses/UnauthorizedError'
        '403':
          $ref: '#/components/responses/ForbiddenError'
        '500':
          $ref: '#/components/responses/InternalServerError'
      x-amazon-apigateway-integration:
        type: aws_proxy
        httpMethod: POST
        uri:
          Fn::Sub: arn:aws:apigateway:${AWS::Region}:lambda:path/2015-03-31/functions/${ListOrgRolesFunction.Arn}/invocations
        passthroughBehavior: when_no_match
      x-amazon-apigateway-auth:
        type: custom
        authorizerId:
          Ref: LambdaAuthorizer

  /v1/orgs/{orgId}/roles/{roleId}:
    get:
      operationId: getOrgRole
      summary: Get an organisation role by ID
      description: |
        Retrieve details of a specific organisation role including permissions and user count.
      tags:
        - Organisation Roles
      parameters:
        - $ref: '#/components/parameters/OrgId'
        - $ref: '#/components/parameters/RoleId'
        - $ref: '#/components/parameters/RequestId'
      responses:
        '200':
          $ref: '#/components/responses/RoleResponse'
        '401':
          $ref: '#/components/responses/UnauthorizedError'
        '403':
          $ref: '#/components/responses/ForbiddenError'
        '404':
          $ref: '#/components/responses/NotFoundError'
        '500':
          $ref: '#/components/responses/InternalServerError'
      x-amazon-apigateway-integration:
        type: aws_proxy
        httpMethod: POST
        uri:
          Fn::Sub: arn:aws:apigateway:${AWS::Region}:lambda:path/2015-03-31/functions/${GetOrgRoleFunction.Arn}/invocations
        passthroughBehavior: when_no_match
      x-amazon-apigateway-auth:
        type: custom
        authorizerId:
          Ref: LambdaAuthorizer

    put:
      operationId: updateOrgRole
      summary: Update an organisation role
      description: |
        Update properties of an existing organisation role.
        System roles cannot be modified. Requires role:update permission.
      tags:
        - Organisation Roles
      parameters:
        - $ref: '#/components/parameters/OrgId'
        - $ref: '#/components/parameters/RoleId'
        - $ref: '#/components/parameters/RequestId'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UpdateRoleRequest'
            examples:
              updateDisplayName:
                summary: Update display name
                value:
                  displayName: "Senior Content Manager"
              updatePermissions:
                summary: Update permissions
                value:
                  permissions:
                    - "site:read"
                    - "site:update"
                    - "site:publish"
      responses:
        '200':
          $ref: '#/components/responses/RoleResponse'
        '400':
          $ref: '#/components/responses/BadRequestError'
        '401':
          $ref: '#/components/responses/UnauthorizedError'
        '403':
          $ref: '#/components/responses/ForbiddenError'
        '404':
          $ref: '#/components/responses/NotFoundError'
        '409':
          $ref: '#/components/responses/ConflictError'
        '500':
          $ref: '#/components/responses/InternalServerError'
      x-amazon-apigateway-integration:
        type: aws_proxy
        httpMethod: POST
        uri:
          Fn::Sub: arn:aws:apigateway:${AWS::Region}:lambda:path/2015-03-31/functions/${UpdateOrgRoleFunction.Arn}/invocations
        passthroughBehavior: when_no_match
      x-amazon-apigateway-auth:
        type: custom
        authorizerId:
          Ref: LambdaAuthorizer

    delete:
      operationId: deleteOrgRole
      summary: Delete an organisation role
      description: |
        Delete an organisation role. System roles cannot be deleted.
        Roles with assigned users cannot be deleted until users are reassigned.
        Requires role:delete permission.
      tags:
        - Organisation Roles
      parameters:
        - $ref: '#/components/parameters/OrgId'
        - $ref: '#/components/parameters/RoleId'
        - $ref: '#/components/parameters/RequestId'
      responses:
        '204':
          description: Role successfully deleted
        '400':
          $ref: '#/components/responses/BadRequestError'
        '401':
          $ref: '#/components/responses/UnauthorizedError'
        '403':
          $ref: '#/components/responses/ForbiddenError'
        '404':
          $ref: '#/components/responses/NotFoundError'
        '500':
          $ref: '#/components/responses/InternalServerError'
      x-amazon-apigateway-integration:
        type: aws_proxy
        httpMethod: POST
        uri:
          Fn::Sub: arn:aws:apigateway:${AWS::Region}:lambda:path/2015-03-31/functions/${DeleteOrgRoleFunction.Arn}/invocations
        passthroughBehavior: when_no_match
      x-amazon-apigateway-auth:
        type: custom
        authorizerId:
          Ref: LambdaAuthorizer

  /v1/orgs/{orgId}/roles/seed:
    post:
      operationId: seedOrgRoles
      summary: Seed default roles for organisation
      description: |
        Initialize default roles for a new organisation.
        Creates standard roles: ORG_ADMIN, ORG_MANAGER, SITE_ADMIN, SITE_EDITOR, SITE_VIEWER.
        Typically called during organisation onboarding.
        Requires role:create permission.
      tags:
        - Organisation Roles
      parameters:
        - $ref: '#/components/parameters/OrgId'
        - $ref: '#/components/parameters/RequestId'
      requestBody:
        required: false
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/SeedRolesRequest'
            examples:
              defaultSeed:
                summary: Seed with default roles
                value:
                  skipExisting: true
              customSeed:
                summary: Seed specific roles
                value:
                  roleNames:
                    - "ORG_ADMIN"
                    - "SITE_ADMIN"
                  skipExisting: true
      responses:
        '200':
          $ref: '#/components/responses/SeedRolesResponse'
        '400':
          $ref: '#/components/responses/BadRequestError'
        '401':
          $ref: '#/components/responses/UnauthorizedError'
        '403':
          $ref: '#/components/responses/ForbiddenError'
        '409':
          $ref: '#/components/responses/ConflictError'
        '500':
          $ref: '#/components/responses/InternalServerError'
      x-amazon-apigateway-integration:
        type: aws_proxy
        httpMethod: POST
        uri:
          Fn::Sub: arn:aws:apigateway:${AWS::Region}:lambda:path/2015-03-31/functions/${SeedOrgRolesFunction.Arn}/invocations
        passthroughBehavior: when_no_match
      x-amazon-apigateway-auth:
        type: custom
        authorizerId:
          Ref: LambdaAuthorizer

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: JWT token from Cognito authentication

  parameters:
    OrgId:
      name: orgId
      in: path
      required: true
      description: Organisation unique identifier
      schema:
        type: string
        pattern: '^org-[a-f0-9-]{36}$'
        example: org-550e8400-e29b-41d4-a716-446655440000

    RoleId:
      name: roleId
      in: path
      required: true
      description: Role unique identifier
      schema:
        type: string
        pattern: '^role-[a-f0-9-]{36}$|^role-[a-z-]+-[0-9]{3}$'
        example: role-550e8400-e29b-41d4-a716-446655440000

    Scope:
      name: scope
      in: query
      required: false
      description: Filter roles by scope
      schema:
        type: string
        enum:
          - PLATFORM
          - ORGANISATION
          - TEAM

    IncludeInactive:
      name: includeInactive
      in: query
      required: false
      description: Include inactive roles in results
      schema:
        type: boolean
        default: false

    PageSize:
      name: pageSize
      in: query
      required: false
      description: Number of items per page (1-100)
      schema:
        type: integer
        minimum: 1
        maximum: 100
        default: 50

    StartAt:
      name: startAt
      in: query
      required: false
      description: Pagination cursor from previous response
      schema:
        type: string
        example: role-550e8400-e29b-41d4-a716-446655440001

    RequestId:
      name: X-Request-ID
      in: header
      required: false
      description: Unique request identifier for tracing
      schema:
        type: string
        format: uuid
        example: 550e8400-e29b-41d4-a716-446655440000

  schemas:
    # ==========================================
    # Request Schemas
    # ==========================================
    CreateRoleRequest:
      type: object
      required:
        - name
        - displayName
        - permissions
      properties:
        name:
          type: string
          minLength: 2
          maxLength: 50
          pattern: '^[A-Z][A-Z0-9_]*$'
          description: Role code name (uppercase with underscores)
          example: CONTENT_MANAGER
        displayName:
          type: string
          minLength: 2
          maxLength: 100
          description: Human-readable role name
          example: Content Manager
        description:
          type: string
          maxLength: 500
          description: Role description
          example: Manages content across team sites
        scope:
          type: string
          enum:
            - ORGANISATION
            - TEAM
          default: ORGANISATION
          description: Scope at which the role applies
        permissions:
          type: array
          items:
            type: string
            pattern: '^[a-z]+:[a-z]+$'
          minItems: 1
          description: List of permission IDs to assign
          example:
            - site:read
            - site:update
        priority:
          type: integer
          minimum: 1
          maximum: 999
          default: 100
          description: Role priority for ordering (lower = higher priority)

    UpdateRoleRequest:
      type: object
      minProperties: 1
      properties:
        displayName:
          type: string
          minLength: 2
          maxLength: 100
          description: Human-readable role name
        description:
          type: string
          maxLength: 500
          description: Role description
        scope:
          type: string
          enum:
            - ORGANISATION
            - TEAM
          description: Scope at which the role applies
        permissions:
          type: array
          items:
            type: string
            pattern: '^[a-z]+:[a-z]+$'
          minItems: 1
          description: List of permission IDs to assign
        priority:
          type: integer
          minimum: 1
          maximum: 999
          description: Role priority for ordering
        active:
          type: boolean
          description: Whether the role is active

    SeedRolesRequest:
      type: object
      properties:
        roleNames:
          type: array
          items:
            type: string
            enum:
              - ORG_ADMIN
              - ORG_MANAGER
              - SITE_ADMIN
              - SITE_EDITOR
              - SITE_VIEWER
          description: Specific roles to seed (defaults to all)
        skipExisting:
          type: boolean
          default: true
          description: Skip roles that already exist

    # ==========================================
    # Response Schemas
    # ==========================================
    Role:
      type: object
      properties:
        id:
          type: string
          description: Unique role identifier
          example: role-550e8400-e29b-41d4-a716-446655440000
        name:
          type: string
          description: Role code name
          example: SITE_ADMIN
        displayName:
          type: string
          description: Human-readable role name
          example: Site Administrator
        description:
          type: string
          description: Role description
          example: Full site management within team scope
        organisationId:
          type: string
          nullable: true
          description: Organisation ID (null for platform roles)
          example: org-550e8400-e29b-41d4-a716-446655440000
        scope:
          type: string
          enum:
            - PLATFORM
            - ORGANISATION
            - TEAM
          description: Scope at which the role applies
        permissions:
          type: array
          items:
            $ref: '#/components/schemas/PermissionSummary'
          description: Permissions assigned to this role
        isSystem:
          type: boolean
          description: Whether this is a system-defined role (cannot be modified)
        isDefault:
          type: boolean
          description: Whether this is a default role (created on org setup)
        priority:
          type: integer
          description: Role priority for ordering
          example: 3
        userCount:
          type: integer
          description: Number of users with this role assigned
          example: 15
        active:
          type: boolean
          description: Whether the role is active
        dateCreated:
          type: string
          format: date-time
          description: ISO 8601 timestamp of creation
          example: "2026-01-15T10:30:00Z"
        dateLastUpdated:
          type: string
          format: date-time
          description: ISO 8601 timestamp of last update
          example: "2026-01-20T14:45:00Z"
        _links:
          $ref: '#/components/schemas/RoleLinks'

    PermissionSummary:
      type: object
      properties:
        id:
          type: string
          description: Permission identifier
          example: site:read
        name:
          type: string
          description: Permission display name
          example: Read Sites
        resource:
          type: string
          description: Resource type
          example: site
        action:
          type: string
          description: Action type
          example: read

    RoleLinks:
      type: object
      properties:
        self:
          $ref: '#/components/schemas/Link'
        permissions:
          $ref: '#/components/schemas/Link'
        users:
          $ref: '#/components/schemas/Link'
        update:
          $ref: '#/components/schemas/Link'
        delete:
          $ref: '#/components/schemas/Link'

    Link:
      type: object
      properties:
        href:
          type: string
          format: uri
          example: /v1/orgs/org-123/roles/role-456
        method:
          type: string
          enum: [GET, POST, PUT, DELETE]
          example: GET

    RoleList:
      type: object
      properties:
        items:
          type: array
          items:
            $ref: '#/components/schemas/Role'
        startAt:
          type: string
          nullable: true
          description: Pagination cursor for next page
        moreAvailable:
          type: boolean
          description: Whether more items are available
        count:
          type: integer
          description: Number of items in current page
        _links:
          type: object
          properties:
            self:
              $ref: '#/components/schemas/Link'
            next:
              $ref: '#/components/schemas/Link'
            create:
              $ref: '#/components/schemas/Link'

    SeedRolesResult:
      type: object
      properties:
        created:
          type: array
          items:
            type: string
          description: List of role names that were created
          example:
            - ORG_ADMIN
            - SITE_ADMIN
        skipped:
          type: array
          items:
            type: string
          description: List of role names that already existed
          example:
            - SITE_EDITOR
        failed:
          type: array
          items:
            type: object
            properties:
              name:
                type: string
              error:
                type: string
          description: List of roles that failed to create
        totalCreated:
          type: integer
          description: Total number of roles created
          example: 2
        _links:
          type: object
          properties:
            roles:
              $ref: '#/components/schemas/Link'

    # ==========================================
    # Error Schemas
    # ==========================================
    Error:
      type: object
      required:
        - errorCode
        - message
      properties:
        errorCode:
          type: string
          description: Machine-readable error code
          example: ROLE_NOT_FOUND
        message:
          type: string
          description: Human-readable error message
          example: Role not found
        details:
          type: object
          additionalProperties: true
          description: Additional error details
        requestId:
          type: string
          description: Request ID for tracing
          example: 550e8400-e29b-41d4-a716-446655440000

    ValidationError:
      allOf:
        - $ref: '#/components/schemas/Error'
        - type: object
          properties:
            errors:
              type: array
              items:
                type: object
                properties:
                  field:
                    type: string
                    example: name
                  message:
                    type: string
                    example: Role name must match pattern ^[A-Z][A-Z0-9_]*$

  responses:
    RoleResponse:
      description: Single role response
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Role'
          example:
            id: role-550e8400-e29b-41d4-a716-446655440000
            name: SITE_ADMIN
            displayName: Site Administrator
            description: Full site management within team scope
            organisationId: org-550e8400-e29b-41d4-a716-446655440001
            scope: TEAM
            permissions:
              - id: "site:create"
                name: Create Sites
                resource: site
                action: create
              - id: "site:read"
                name: Read Sites
                resource: site
                action: read
            isSystem: false
            isDefault: true
            priority: 3
            userCount: 15
            active: true
            dateCreated: "2026-01-15T10:30:00Z"
            dateLastUpdated: "2026-01-20T14:45:00Z"
            _links:
              self:
                href: /v1/orgs/org-550e8400-e29b-41d4-a716-446655440001/roles/role-550e8400-e29b-41d4-a716-446655440000
                method: GET

    RoleCreatedResponse:
      description: Role created successfully
      headers:
        Location:
          description: URL of the created role
          schema:
            type: string
            format: uri
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Role'

    RoleListResponse:
      description: Paginated list of roles
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/RoleList'
          example:
            items:
              - id: role-001
                name: ORG_ADMIN
                displayName: Organisation Admin
                scope: ORGANISATION
                isSystem: false
                isDefault: true
                userCount: 2
                active: true
            startAt: null
            moreAvailable: false
            count: 1
            _links:
              self:
                href: /v1/orgs/org-123/roles
                method: GET

    SeedRolesResponse:
      description: Seed roles result
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/SeedRolesResult'
          example:
            created:
              - ORG_ADMIN
              - ORG_MANAGER
              - SITE_ADMIN
            skipped: []
            failed: []
            totalCreated: 3
            _links:
              roles:
                href: /v1/orgs/org-123/roles
                method: GET

    BadRequestError:
      description: Bad request - validation failed
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ValidationError'
          example:
            errorCode: VALIDATION_ERROR
            message: Request validation failed
            errors:
              - field: name
                message: Role name must match pattern ^[A-Z][A-Z0-9_]*$

    UnauthorizedError:
      description: Authentication required
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            errorCode: UNAUTHORIZED
            message: Authentication required

    ForbiddenError:
      description: Access denied
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            errorCode: FORBIDDEN
            message: Insufficient permissions for this operation

    NotFoundError:
      description: Resource not found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            errorCode: ROLE_NOT_FOUND
            message: "Role not found: role-550e8400-e29b-41d4-a716-446655440000"

    ConflictError:
      description: Resource conflict
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            errorCode: DUPLICATE_ROLE_NAME
            message: "Role name 'CONTENT_MANAGER' already exists in organisation"

    InternalServerError:
      description: Internal server error
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            errorCode: INTERNAL_ERROR
            message: An unexpected error occurred
```

---

## 3. Terraform Route Configuration

### 3.1 Main Route Configuration

```hcl
# terraform/modules/api-gateway/routes/role_routes.tf
# Role Service API Gateway Routes

# ============================================
# Local Variables
# ============================================
locals {
  role_service_name = "role-service"

  # Lambda function name prefix
  lambda_prefix = "bbws-access-${var.environment}"

  # API Gateway base path
  api_base_path = "v1"
}

# ============================================
# PLATFORM ROLE ROUTES (Read-Only)
# ============================================

# GET /v1/platform/roles - List Platform Roles
resource "aws_apigatewayv2_route" "list_platform_roles" {
  api_id    = var.api_gateway_id
  route_key = "GET /${local.api_base_path}/platform/roles"

  target             = "integrations/${aws_apigatewayv2_integration.list_platform_roles.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = var.authorizer_id

  request_models = {
    "application/json" = aws_apigatewayv2_model.empty_request.id
  }
}

resource "aws_apigatewayv2_integration" "list_platform_roles" {
  api_id           = var.api_gateway_id
  integration_type = "AWS_PROXY"

  integration_uri    = data.aws_lambda_function.list_platform_roles.invoke_arn
  integration_method = "POST"

  payload_format_version = "2.0"
  timeout_milliseconds   = 30000

  description = "Integration for listing platform roles"
}

resource "aws_lambda_permission" "list_platform_roles" {
  statement_id  = "AllowAPIGatewayInvoke-ListPlatformRoles"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.list_platform_roles.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.api_gateway_execution_arn}/*/*/platform/roles"
}

# GET /v1/platform/roles/{roleId} - Get Platform Role
resource "aws_apigatewayv2_route" "get_platform_role" {
  api_id    = var.api_gateway_id
  route_key = "GET /${local.api_base_path}/platform/roles/{roleId}"

  target             = "integrations/${aws_apigatewayv2_integration.get_platform_role.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = var.authorizer_id

  request_models = {
    "application/json" = aws_apigatewayv2_model.empty_request.id
  }
}

resource "aws_apigatewayv2_integration" "get_platform_role" {
  api_id           = var.api_gateway_id
  integration_type = "AWS_PROXY"

  integration_uri    = data.aws_lambda_function.get_platform_role.invoke_arn
  integration_method = "POST"

  payload_format_version = "2.0"
  timeout_milliseconds   = 30000

  description = "Integration for getting a platform role"
}

resource "aws_lambda_permission" "get_platform_role" {
  statement_id  = "AllowAPIGatewayInvoke-GetPlatformRole"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.get_platform_role.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.api_gateway_execution_arn}/*/*/platform/roles/*"
}

# ============================================
# ORGANISATION ROLE ROUTES
# ============================================

# POST /v1/orgs/{orgId}/roles - Create Organisation Role
resource "aws_apigatewayv2_route" "create_org_role" {
  api_id    = var.api_gateway_id
  route_key = "POST /${local.api_base_path}/orgs/{orgId}/roles"

  target             = "integrations/${aws_apigatewayv2_integration.create_org_role.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = var.authorizer_id

  request_models = {
    "application/json" = aws_apigatewayv2_model.create_role_request.id
  }
}

resource "aws_apigatewayv2_integration" "create_org_role" {
  api_id           = var.api_gateway_id
  integration_type = "AWS_PROXY"

  integration_uri    = data.aws_lambda_function.create_org_role.invoke_arn
  integration_method = "POST"

  payload_format_version = "2.0"
  timeout_milliseconds   = 30000

  description = "Integration for creating organisation roles"
}

resource "aws_lambda_permission" "create_org_role" {
  statement_id  = "AllowAPIGatewayInvoke-CreateOrgRole"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.create_org_role.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.api_gateway_execution_arn}/*/*/orgs/*/roles"
}

# GET /v1/orgs/{orgId}/roles - List Organisation Roles
resource "aws_apigatewayv2_route" "list_org_roles" {
  api_id    = var.api_gateway_id
  route_key = "GET /${local.api_base_path}/orgs/{orgId}/roles"

  target             = "integrations/${aws_apigatewayv2_integration.list_org_roles.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = var.authorizer_id

  request_models = {
    "application/json" = aws_apigatewayv2_model.empty_request.id
  }
}

resource "aws_apigatewayv2_integration" "list_org_roles" {
  api_id           = var.api_gateway_id
  integration_type = "AWS_PROXY"

  integration_uri    = data.aws_lambda_function.list_org_roles.invoke_arn
  integration_method = "POST"

  payload_format_version = "2.0"
  timeout_milliseconds   = 30000

  description = "Integration for listing organisation roles"
}

resource "aws_lambda_permission" "list_org_roles" {
  statement_id  = "AllowAPIGatewayInvoke-ListOrgRoles"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.list_org_roles.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.api_gateway_execution_arn}/*/*/orgs/*/roles"
}

# GET /v1/orgs/{orgId}/roles/{roleId} - Get Organisation Role
resource "aws_apigatewayv2_route" "get_org_role" {
  api_id    = var.api_gateway_id
  route_key = "GET /${local.api_base_path}/orgs/{orgId}/roles/{roleId}"

  target             = "integrations/${aws_apigatewayv2_integration.get_org_role.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = var.authorizer_id

  request_models = {
    "application/json" = aws_apigatewayv2_model.empty_request.id
  }
}

resource "aws_apigatewayv2_integration" "get_org_role" {
  api_id           = var.api_gateway_id
  integration_type = "AWS_PROXY"

  integration_uri    = data.aws_lambda_function.get_org_role.invoke_arn
  integration_method = "POST"

  payload_format_version = "2.0"
  timeout_milliseconds   = 30000

  description = "Integration for getting an organisation role"
}

resource "aws_lambda_permission" "get_org_role" {
  statement_id  = "AllowAPIGatewayInvoke-GetOrgRole"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.get_org_role.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.api_gateway_execution_arn}/*/*/orgs/*/roles/*"
}

# PUT /v1/orgs/{orgId}/roles/{roleId} - Update Organisation Role
resource "aws_apigatewayv2_route" "update_org_role" {
  api_id    = var.api_gateway_id
  route_key = "PUT /${local.api_base_path}/orgs/{orgId}/roles/{roleId}"

  target             = "integrations/${aws_apigatewayv2_integration.update_org_role.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = var.authorizer_id

  request_models = {
    "application/json" = aws_apigatewayv2_model.update_role_request.id
  }
}

resource "aws_apigatewayv2_integration" "update_org_role" {
  api_id           = var.api_gateway_id
  integration_type = "AWS_PROXY"

  integration_uri    = data.aws_lambda_function.update_org_role.invoke_arn
  integration_method = "POST"

  payload_format_version = "2.0"
  timeout_milliseconds   = 30000

  description = "Integration for updating an organisation role"
}

resource "aws_lambda_permission" "update_org_role" {
  statement_id  = "AllowAPIGatewayInvoke-UpdateOrgRole"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.update_org_role.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.api_gateway_execution_arn}/*/*/orgs/*/roles/*"
}

# DELETE /v1/orgs/{orgId}/roles/{roleId} - Delete Organisation Role
resource "aws_apigatewayv2_route" "delete_org_role" {
  api_id    = var.api_gateway_id
  route_key = "DELETE /${local.api_base_path}/orgs/{orgId}/roles/{roleId}"

  target             = "integrations/${aws_apigatewayv2_integration.delete_org_role.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = var.authorizer_id
}

resource "aws_apigatewayv2_integration" "delete_org_role" {
  api_id           = var.api_gateway_id
  integration_type = "AWS_PROXY"

  integration_uri    = data.aws_lambda_function.delete_org_role.invoke_arn
  integration_method = "POST"

  payload_format_version = "2.0"
  timeout_milliseconds   = 30000

  description = "Integration for deleting an organisation role"
}

resource "aws_lambda_permission" "delete_org_role" {
  statement_id  = "AllowAPIGatewayInvoke-DeleteOrgRole"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.delete_org_role.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.api_gateway_execution_arn}/*/*/orgs/*/roles/*"
}

# POST /v1/orgs/{orgId}/roles/seed - Seed Organisation Roles
resource "aws_apigatewayv2_route" "seed_org_roles" {
  api_id    = var.api_gateway_id
  route_key = "POST /${local.api_base_path}/orgs/{orgId}/roles/seed"

  target             = "integrations/${aws_apigatewayv2_integration.seed_org_roles.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = var.authorizer_id

  request_models = {
    "application/json" = aws_apigatewayv2_model.seed_roles_request.id
  }
}

resource "aws_apigatewayv2_integration" "seed_org_roles" {
  api_id           = var.api_gateway_id
  integration_type = "AWS_PROXY"

  integration_uri    = data.aws_lambda_function.seed_org_roles.invoke_arn
  integration_method = "POST"

  payload_format_version = "2.0"
  timeout_milliseconds   = 30000

  description = "Integration for seeding organisation default roles"
}

resource "aws_lambda_permission" "seed_org_roles" {
  statement_id  = "AllowAPIGatewayInvoke-SeedOrgRoles"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.seed_org_roles.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.api_gateway_execution_arn}/*/*/orgs/*/roles/seed"
}

# ============================================
# CORS OPTIONS ROUTES
# ============================================

# OPTIONS /v1/platform/roles
resource "aws_apigatewayv2_route" "options_platform_roles" {
  api_id    = var.api_gateway_id
  route_key = "OPTIONS /${local.api_base_path}/platform/roles"

  target = "integrations/${aws_apigatewayv2_integration.cors_integration.id}"
}

# OPTIONS /v1/platform/roles/{roleId}
resource "aws_apigatewayv2_route" "options_platform_role" {
  api_id    = var.api_gateway_id
  route_key = "OPTIONS /${local.api_base_path}/platform/roles/{roleId}"

  target = "integrations/${aws_apigatewayv2_integration.cors_integration.id}"
}

# OPTIONS /v1/orgs/{orgId}/roles
resource "aws_apigatewayv2_route" "options_org_roles" {
  api_id    = var.api_gateway_id
  route_key = "OPTIONS /${local.api_base_path}/orgs/{orgId}/roles"

  target = "integrations/${aws_apigatewayv2_integration.cors_integration.id}"
}

# OPTIONS /v1/orgs/{orgId}/roles/{roleId}
resource "aws_apigatewayv2_route" "options_org_role" {
  api_id    = var.api_gateway_id
  route_key = "OPTIONS /${local.api_base_path}/orgs/{orgId}/roles/{roleId}"

  target = "integrations/${aws_apigatewayv2_integration.cors_integration.id}"
}

# OPTIONS /v1/orgs/{orgId}/roles/seed
resource "aws_apigatewayv2_route" "options_org_roles_seed" {
  api_id    = var.api_gateway_id
  route_key = "OPTIONS /${local.api_base_path}/orgs/{orgId}/roles/seed"

  target = "integrations/${aws_apigatewayv2_integration.cors_integration.id}"
}

# ============================================
# DATA SOURCES - Lambda Functions
# ============================================

data "aws_lambda_function" "list_platform_roles" {
  function_name = "${local.lambda_prefix}-role-list-platform"
}

data "aws_lambda_function" "get_platform_role" {
  function_name = "${local.lambda_prefix}-role-get-platform"
}

data "aws_lambda_function" "create_org_role" {
  function_name = "${local.lambda_prefix}-role-create-org"
}

data "aws_lambda_function" "list_org_roles" {
  function_name = "${local.lambda_prefix}-role-list-org"
}

data "aws_lambda_function" "get_org_role" {
  function_name = "${local.lambda_prefix}-role-get-org"
}

data "aws_lambda_function" "update_org_role" {
  function_name = "${local.lambda_prefix}-role-update-org"
}

data "aws_lambda_function" "delete_org_role" {
  function_name = "${local.lambda_prefix}-role-delete-org"
}

data "aws_lambda_function" "seed_org_roles" {
  function_name = "${local.lambda_prefix}-role-seed-org"
}
```

### 3.2 Request Models Configuration

```hcl
# terraform/modules/api-gateway/routes/role_models.tf
# Request/Response Models for Role Service

# ============================================
# REQUEST MODELS
# ============================================

resource "aws_apigatewayv2_model" "create_role_request" {
  api_id       = var.api_gateway_id
  content_type = "application/json"
  name         = "CreateRoleRequest"
  description  = "Request model for creating a role"

  schema = jsonencode({
    "$schema"   = "http://json-schema.org/draft-07/schema#"
    type        = "object"
    required    = ["name", "displayName", "permissions"]
    properties  = {
      name = {
        type      = "string"
        minLength = 2
        maxLength = 50
        pattern   = "^[A-Z][A-Z0-9_]*$"
      }
      displayName = {
        type      = "string"
        minLength = 2
        maxLength = 100
      }
      description = {
        type      = "string"
        maxLength = 500
      }
      scope = {
        type = "string"
        enum = ["ORGANISATION", "TEAM"]
      }
      permissions = {
        type     = "array"
        items    = { type = "string", pattern = "^[a-z]+:[a-z]+$" }
        minItems = 1
      }
      priority = {
        type    = "integer"
        minimum = 1
        maximum = 999
      }
    }
    additionalProperties = false
  })
}

resource "aws_apigatewayv2_model" "update_role_request" {
  api_id       = var.api_gateway_id
  content_type = "application/json"
  name         = "UpdateRoleRequest"
  description  = "Request model for updating a role"

  schema = jsonencode({
    "$schema"   = "http://json-schema.org/draft-07/schema#"
    type        = "object"
    minProperties = 1
    properties  = {
      displayName = {
        type      = "string"
        minLength = 2
        maxLength = 100
      }
      description = {
        type      = "string"
        maxLength = 500
      }
      scope = {
        type = "string"
        enum = ["ORGANISATION", "TEAM"]
      }
      permissions = {
        type     = "array"
        items    = { type = "string", pattern = "^[a-z]+:[a-z]+$" }
        minItems = 1
      }
      priority = {
        type    = "integer"
        minimum = 1
        maximum = 999
      }
      active = {
        type = "boolean"
      }
    }
    additionalProperties = false
  })
}

resource "aws_apigatewayv2_model" "seed_roles_request" {
  api_id       = var.api_gateway_id
  content_type = "application/json"
  name         = "SeedRolesRequest"
  description  = "Request model for seeding default roles"

  schema = jsonencode({
    "$schema"   = "http://json-schema.org/draft-07/schema#"
    type        = "object"
    properties  = {
      roleNames = {
        type  = "array"
        items = {
          type = "string"
          enum = ["ORG_ADMIN", "ORG_MANAGER", "SITE_ADMIN", "SITE_EDITOR", "SITE_VIEWER"]
        }
      }
      skipExisting = {
        type    = "boolean"
        default = true
      }
    }
    additionalProperties = false
  })
}

resource "aws_apigatewayv2_model" "empty_request" {
  api_id       = var.api_gateway_id
  content_type = "application/json"
  name         = "EmptyRequest"
  description  = "Empty request model for GET requests"

  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-07/schema#"
    type      = "object"
  })
}

# ============================================
# RESPONSE MODELS
# ============================================

resource "aws_apigatewayv2_model" "role_response" {
  api_id       = var.api_gateway_id
  content_type = "application/json"
  name         = "RoleResponse"
  description  = "Response model for a single role"

  schema = jsonencode({
    "$schema"  = "http://json-schema.org/draft-07/schema#"
    type       = "object"
    properties = {
      id            = { type = "string" }
      name          = { type = "string" }
      displayName   = { type = "string" }
      description   = { type = "string" }
      organisationId = { type = ["string", "null"] }
      scope         = { type = "string", enum = ["PLATFORM", "ORGANISATION", "TEAM"] }
      permissions   = {
        type  = "array"
        items = {
          type       = "object"
          properties = {
            id       = { type = "string" }
            name     = { type = "string" }
            resource = { type = "string" }
            action   = { type = "string" }
          }
        }
      }
      isSystem        = { type = "boolean" }
      isDefault       = { type = "boolean" }
      priority        = { type = "integer" }
      userCount       = { type = "integer" }
      active          = { type = "boolean" }
      dateCreated     = { type = "string", format = "date-time" }
      dateLastUpdated = { type = "string", format = "date-time" }
      _links          = { type = "object" }
    }
  })
}

resource "aws_apigatewayv2_model" "role_list_response" {
  api_id       = var.api_gateway_id
  content_type = "application/json"
  name         = "RoleListResponse"
  description  = "Response model for paginated role list"

  schema = jsonencode({
    "$schema"  = "http://json-schema.org/draft-07/schema#"
    type       = "object"
    properties = {
      items = {
        type  = "array"
        items = { "$ref" = "#/definitions/Role" }
      }
      startAt       = { type = ["string", "null"] }
      moreAvailable = { type = "boolean" }
      count         = { type = "integer" }
      _links        = { type = "object" }
    }
    definitions = {
      Role = {
        type       = "object"
        properties = {
          id            = { type = "string" }
          name          = { type = "string" }
          displayName   = { type = "string" }
          scope         = { type = "string" }
          isSystem      = { type = "boolean" }
          isDefault     = { type = "boolean" }
          userCount     = { type = "integer" }
          active        = { type = "boolean" }
        }
      }
    }
  })
}

resource "aws_apigatewayv2_model" "seed_roles_response" {
  api_id       = var.api_gateway_id
  content_type = "application/json"
  name         = "SeedRolesResponse"
  description  = "Response model for seed roles operation"

  schema = jsonencode({
    "$schema"  = "http://json-schema.org/draft-07/schema#"
    type       = "object"
    properties = {
      created = {
        type  = "array"
        items = { type = "string" }
      }
      skipped = {
        type  = "array"
        items = { type = "string" }
      }
      failed = {
        type  = "array"
        items = {
          type       = "object"
          properties = {
            name  = { type = "string" }
            error = { type = "string" }
          }
        }
      }
      totalCreated = { type = "integer" }
      _links       = { type = "object" }
    }
  })
}

resource "aws_apigatewayv2_model" "error_response" {
  api_id       = var.api_gateway_id
  content_type = "application/json"
  name         = "RoleErrorResponse"
  description  = "Standard error response model"

  schema = jsonencode({
    "$schema"  = "http://json-schema.org/draft-07/schema#"
    type       = "object"
    required   = ["errorCode", "message"]
    properties = {
      errorCode = { type = "string" }
      message   = { type = "string" }
      details   = { type = "object" }
      requestId = { type = "string" }
      errors    = {
        type  = "array"
        items = {
          type       = "object"
          properties = {
            field   = { type = "string" }
            message = { type = "string" }
          }
        }
      }
    }
  })
}
```

### 3.3 Variables Configuration

```hcl
# terraform/modules/api-gateway/routes/role_variables.tf
# Variables for Role Service Routes

variable "api_gateway_id" {
  description = "API Gateway ID"
  type        = string
}

variable "api_gateway_execution_arn" {
  description = "API Gateway execution ARN for Lambda permissions"
  type        = string
}

variable "authorizer_id" {
  description = "Lambda authorizer ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, sit, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "sit", "prod"], var.environment)
    error_message = "Environment must be one of: dev, sit, prod."
  }
}

variable "cors_allowed_origins" {
  description = "CORS allowed origins"
  type        = list(string)
  default     = ["*"]
}

variable "cors_allowed_methods" {
  description = "CORS allowed methods"
  type        = list(string)
  default     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
}

variable "cors_allowed_headers" {
  description = "CORS allowed headers"
  type        = list(string)
  default     = ["Content-Type", "Authorization", "X-Request-ID"]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
```

### 3.4 Outputs Configuration

```hcl
# terraform/modules/api-gateway/routes/role_outputs.tf
# Outputs for Role Service Routes

output "role_route_ids" {
  description = "Map of role route IDs"
  value = {
    list_platform_roles = aws_apigatewayv2_route.list_platform_roles.id
    get_platform_role   = aws_apigatewayv2_route.get_platform_role.id
    create_org_role     = aws_apigatewayv2_route.create_org_role.id
    list_org_roles      = aws_apigatewayv2_route.list_org_roles.id
    get_org_role        = aws_apigatewayv2_route.get_org_role.id
    update_org_role     = aws_apigatewayv2_route.update_org_role.id
    delete_org_role     = aws_apigatewayv2_route.delete_org_role.id
    seed_org_roles      = aws_apigatewayv2_route.seed_org_roles.id
  }
}

output "role_integration_ids" {
  description = "Map of role integration IDs"
  value = {
    list_platform_roles = aws_apigatewayv2_integration.list_platform_roles.id
    get_platform_role   = aws_apigatewayv2_integration.get_platform_role.id
    create_org_role     = aws_apigatewayv2_integration.create_org_role.id
    list_org_roles      = aws_apigatewayv2_integration.list_org_roles.id
    get_org_role        = aws_apigatewayv2_integration.get_org_role.id
    update_org_role     = aws_apigatewayv2_integration.update_org_role.id
    delete_org_role     = aws_apigatewayv2_integration.delete_org_role.id
    seed_org_roles      = aws_apigatewayv2_integration.seed_org_roles.id
  }
}

output "role_endpoints" {
  description = "List of role API endpoints"
  value = [
    "GET /v1/platform/roles",
    "GET /v1/platform/roles/{roleId}",
    "POST /v1/orgs/{orgId}/roles",
    "GET /v1/orgs/{orgId}/roles",
    "GET /v1/orgs/{orgId}/roles/{roleId}",
    "PUT /v1/orgs/{orgId}/roles/{roleId}",
    "DELETE /v1/orgs/{orgId}/roles/{roleId}",
    "POST /v1/orgs/{orgId}/roles/seed"
  ]
}

output "role_route_count" {
  description = "Total number of role routes configured"
  value       = 8
}
```

---

## 4. Request/Response JSON Schemas

### 4.1 Create Role Request Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://api.aipagebuilder.bbws.io/schemas/create-role-request.json",
  "title": "CreateRoleRequest",
  "description": "Request body for creating a new organisation role",
  "type": "object",
  "required": ["name", "displayName", "permissions"],
  "properties": {
    "name": {
      "type": "string",
      "description": "Role code name (uppercase with underscores)",
      "minLength": 2,
      "maxLength": 50,
      "pattern": "^[A-Z][A-Z0-9_]*$",
      "examples": ["CONTENT_MANAGER", "SITE_REVIEWER"]
    },
    "displayName": {
      "type": "string",
      "description": "Human-readable role name",
      "minLength": 2,
      "maxLength": 100,
      "examples": ["Content Manager", "Site Reviewer"]
    },
    "description": {
      "type": "string",
      "description": "Role description",
      "maxLength": 500,
      "default": "",
      "examples": ["Manages content across team sites"]
    },
    "scope": {
      "type": "string",
      "description": "Scope at which the role applies",
      "enum": ["ORGANISATION", "TEAM"],
      "default": "ORGANISATION"
    },
    "permissions": {
      "type": "array",
      "description": "List of permission IDs to assign",
      "items": {
        "type": "string",
        "pattern": "^[a-z]+:[a-z]+$"
      },
      "minItems": 1,
      "uniqueItems": true,
      "examples": [["site:read", "site:update"]]
    },
    "priority": {
      "type": "integer",
      "description": "Role priority (lower = higher priority)",
      "minimum": 1,
      "maximum": 999,
      "default": 100
    }
  },
  "additionalProperties": false
}
```

### 4.2 Update Role Request Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://api.aipagebuilder.bbws.io/schemas/update-role-request.json",
  "title": "UpdateRoleRequest",
  "description": "Request body for updating an existing role",
  "type": "object",
  "minProperties": 1,
  "properties": {
    "displayName": {
      "type": "string",
      "description": "Human-readable role name",
      "minLength": 2,
      "maxLength": 100
    },
    "description": {
      "type": "string",
      "description": "Role description",
      "maxLength": 500
    },
    "scope": {
      "type": "string",
      "description": "Scope at which the role applies",
      "enum": ["ORGANISATION", "TEAM"]
    },
    "permissions": {
      "type": "array",
      "description": "List of permission IDs to assign",
      "items": {
        "type": "string",
        "pattern": "^[a-z]+:[a-z]+$"
      },
      "minItems": 1,
      "uniqueItems": true
    },
    "priority": {
      "type": "integer",
      "description": "Role priority",
      "minimum": 1,
      "maximum": 999
    },
    "active": {
      "type": "boolean",
      "description": "Whether the role is active"
    }
  },
  "additionalProperties": false
}
```

### 4.3 Seed Roles Request Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://api.aipagebuilder.bbws.io/schemas/seed-roles-request.json",
  "title": "SeedRolesRequest",
  "description": "Request body for seeding default organisation roles",
  "type": "object",
  "properties": {
    "roleNames": {
      "type": "array",
      "description": "Specific roles to seed (defaults to all)",
      "items": {
        "type": "string",
        "enum": ["ORG_ADMIN", "ORG_MANAGER", "SITE_ADMIN", "SITE_EDITOR", "SITE_VIEWER"]
      },
      "uniqueItems": true
    },
    "skipExisting": {
      "type": "boolean",
      "description": "Skip roles that already exist",
      "default": true
    }
  },
  "additionalProperties": false
}
```

### 4.4 Role Response Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://api.aipagebuilder.bbws.io/schemas/role-response.json",
  "title": "RoleResponse",
  "description": "Response schema for a single role",
  "type": "object",
  "required": ["id", "name", "displayName", "scope", "permissions", "isSystem", "isDefault", "priority", "userCount", "active", "dateCreated", "dateLastUpdated"],
  "properties": {
    "id": {
      "type": "string",
      "description": "Unique role identifier",
      "pattern": "^role-[a-f0-9-]{36}$|^role-[a-z-]+-[0-9]{3}$",
      "examples": ["role-550e8400-e29b-41d4-a716-446655440000"]
    },
    "name": {
      "type": "string",
      "description": "Role code name",
      "examples": ["SITE_ADMIN"]
    },
    "displayName": {
      "type": "string",
      "description": "Human-readable role name",
      "examples": ["Site Administrator"]
    },
    "description": {
      "type": "string",
      "description": "Role description",
      "examples": ["Full site management within team scope"]
    },
    "organisationId": {
      "type": ["string", "null"],
      "description": "Organisation ID (null for platform roles)",
      "pattern": "^org-[a-f0-9-]{36}$"
    },
    "scope": {
      "type": "string",
      "description": "Scope at which the role applies",
      "enum": ["PLATFORM", "ORGANISATION", "TEAM"]
    },
    "permissions": {
      "type": "array",
      "description": "Permissions assigned to this role",
      "items": {
        "$ref": "#/definitions/PermissionSummary"
      }
    },
    "isSystem": {
      "type": "boolean",
      "description": "Whether this is a system-defined role"
    },
    "isDefault": {
      "type": "boolean",
      "description": "Whether this is a default role"
    },
    "priority": {
      "type": "integer",
      "description": "Role priority for ordering",
      "minimum": 1,
      "maximum": 999
    },
    "userCount": {
      "type": "integer",
      "description": "Number of users with this role assigned",
      "minimum": 0
    },
    "active": {
      "type": "boolean",
      "description": "Whether the role is active"
    },
    "dateCreated": {
      "type": "string",
      "format": "date-time",
      "description": "ISO 8601 timestamp of creation"
    },
    "dateLastUpdated": {
      "type": "string",
      "format": "date-time",
      "description": "ISO 8601 timestamp of last update"
    },
    "_links": {
      "$ref": "#/definitions/RoleLinks"
    }
  },
  "definitions": {
    "PermissionSummary": {
      "type": "object",
      "required": ["id", "name", "resource", "action"],
      "properties": {
        "id": {
          "type": "string",
          "description": "Permission identifier"
        },
        "name": {
          "type": "string",
          "description": "Permission display name"
        },
        "resource": {
          "type": "string",
          "description": "Resource type"
        },
        "action": {
          "type": "string",
          "description": "Action type"
        }
      }
    },
    "RoleLinks": {
      "type": "object",
      "properties": {
        "self": { "$ref": "#/definitions/Link" },
        "permissions": { "$ref": "#/definitions/Link" },
        "users": { "$ref": "#/definitions/Link" },
        "update": { "$ref": "#/definitions/Link" },
        "delete": { "$ref": "#/definitions/Link" }
      }
    },
    "Link": {
      "type": "object",
      "properties": {
        "href": {
          "type": "string",
          "format": "uri"
        },
        "method": {
          "type": "string",
          "enum": ["GET", "POST", "PUT", "DELETE"]
        }
      }
    }
  }
}
```

### 4.5 Role List Response Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://api.aipagebuilder.bbws.io/schemas/role-list-response.json",
  "title": "RoleListResponse",
  "description": "Response schema for paginated role list",
  "type": "object",
  "required": ["items", "moreAvailable", "count"],
  "properties": {
    "items": {
      "type": "array",
      "description": "List of roles",
      "items": {
        "$ref": "role-response.json"
      }
    },
    "startAt": {
      "type": ["string", "null"],
      "description": "Pagination cursor for next page"
    },
    "moreAvailable": {
      "type": "boolean",
      "description": "Whether more items are available"
    },
    "count": {
      "type": "integer",
      "description": "Number of items in current page",
      "minimum": 0
    },
    "_links": {
      "type": "object",
      "properties": {
        "self": { "$ref": "#/definitions/Link" },
        "next": { "$ref": "#/definitions/Link" },
        "create": { "$ref": "#/definitions/Link" }
      }
    }
  },
  "definitions": {
    "Link": {
      "type": "object",
      "properties": {
        "href": { "type": "string", "format": "uri" },
        "method": { "type": "string", "enum": ["GET", "POST", "PUT", "DELETE"] }
      }
    }
  }
}
```

### 4.6 Seed Roles Response Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://api.aipagebuilder.bbws.io/schemas/seed-roles-response.json",
  "title": "SeedRolesResponse",
  "description": "Response schema for seed roles operation",
  "type": "object",
  "required": ["created", "skipped", "failed", "totalCreated"],
  "properties": {
    "created": {
      "type": "array",
      "description": "List of role names that were created",
      "items": { "type": "string" }
    },
    "skipped": {
      "type": "array",
      "description": "List of role names that already existed",
      "items": { "type": "string" }
    },
    "failed": {
      "type": "array",
      "description": "List of roles that failed to create",
      "items": {
        "type": "object",
        "properties": {
          "name": { "type": "string" },
          "error": { "type": "string" }
        }
      }
    },
    "totalCreated": {
      "type": "integer",
      "description": "Total number of roles created",
      "minimum": 0
    },
    "_links": {
      "type": "object",
      "properties": {
        "roles": {
          "type": "object",
          "properties": {
            "href": { "type": "string", "format": "uri" },
            "method": { "type": "string" }
          }
        }
      }
    }
  }
}
```

### 4.7 Error Response Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://api.aipagebuilder.bbws.io/schemas/error-response.json",
  "title": "ErrorResponse",
  "description": "Standard error response schema",
  "type": "object",
  "required": ["errorCode", "message"],
  "properties": {
    "errorCode": {
      "type": "string",
      "description": "Machine-readable error code",
      "enum": [
        "VALIDATION_ERROR",
        "UNAUTHORIZED",
        "FORBIDDEN",
        "ROLE_NOT_FOUND",
        "DUPLICATE_ROLE_NAME",
        "ROLE_IN_USE",
        "INVALID_PERMISSION",
        "CANNOT_MODIFY_SYSTEM_ROLE",
        "UNAUTHORIZED_ORG_ACCESS",
        "INTERNAL_ERROR"
      ]
    },
    "message": {
      "type": "string",
      "description": "Human-readable error message"
    },
    "details": {
      "type": "object",
      "description": "Additional error details",
      "additionalProperties": true
    },
    "requestId": {
      "type": "string",
      "description": "Request ID for tracing"
    },
    "errors": {
      "type": "array",
      "description": "Validation errors (for VALIDATION_ERROR)",
      "items": {
        "type": "object",
        "properties": {
          "field": { "type": "string" },
          "message": { "type": "string" }
        }
      }
    }
  }
}
```

---

## 5. CORS Configuration

### 5.1 CORS Integration (Terraform)

```hcl
# terraform/modules/api-gateway/cors.tf
# CORS Configuration for Role Service Routes

# ============================================
# CORS INTEGRATION
# ============================================

resource "aws_apigatewayv2_integration" "cors_integration" {
  api_id           = var.api_gateway_id
  integration_type = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }

  template_selection_expression = "200"

  description = "CORS preflight response integration"
}

# ============================================
# CORS RESPONSE CONFIGURATION
# ============================================

resource "aws_apigatewayv2_integration_response" "cors_response" {
  api_id                   = var.api_gateway_id
  integration_id           = aws_apigatewayv2_integration.cors_integration.id
  integration_response_key = "default"

  response_templates = {
    "application/json" = ""
  }
}

# ============================================
# API GATEWAY CORS CONFIGURATION
# ============================================

resource "aws_apigatewayv2_api" "access_management" {
  # ... existing configuration ...

  cors_configuration {
    allow_origins = var.cors_allowed_origins
    allow_methods = var.cors_allowed_methods
    allow_headers = var.cors_allowed_headers
    expose_headers = [
      "X-Request-ID",
      "X-Correlation-ID",
      "Location"
    ]
    max_age         = 86400  # 24 hours
    allow_credentials = false
  }
}
```

### 5.2 CORS Headers Configuration

```yaml
# CORS Configuration Summary

cors_configuration:
  allow_origins:
    - "*"  # Or specific origins for production
    # - "https://app.aipagebuilder.bbws.io"
    # - "https://admin.aipagebuilder.bbws.io"

  allow_methods:
    - GET
    - POST
    - PUT
    - DELETE
    - OPTIONS

  allow_headers:
    - Content-Type
    - Authorization
    - X-Request-ID
    - X-Correlation-ID
    - Accept
    - Accept-Language

  expose_headers:
    - X-Request-ID
    - X-Correlation-ID
    - Location
    - ETag

  max_age: 86400  # 24 hours cache for preflight

  allow_credentials: false
```

### 5.3 Environment-Specific CORS Origins

```hcl
# terraform/environments/dev/cors.tfvars
cors_allowed_origins = [
  "http://localhost:3000",
  "http://localhost:5173",
  "https://dev.aipagebuilder.bbws.io",
  "https://admin-dev.aipagebuilder.bbws.io"
]

# terraform/environments/sit/cors.tfvars
cors_allowed_origins = [
  "https://sit.aipagebuilder.bbws.io",
  "https://admin-sit.aipagebuilder.bbws.io"
]

# terraform/environments/prod/cors.tfvars
cors_allowed_origins = [
  "https://app.aipagebuilder.bbws.io",
  "https://admin.aipagebuilder.bbws.io",
  "https://aipagebuilder.bbws.io"
]
```

---

## 6. Lambda Integration Details

### 6.1 Lambda Function Mapping

| Endpoint | Lambda Function Name | Handler |
|----------|---------------------|---------|
| GET /v1/platform/roles | bbws-access-{env}-role-list-platform | handlers.platform.list_platform_roles.handler |
| GET /v1/platform/roles/{roleId} | bbws-access-{env}-role-get-platform | handlers.platform.get_platform_role.handler |
| POST /v1/orgs/{orgId}/roles | bbws-access-{env}-role-create-org | handlers.organisation.create_role.handler |
| GET /v1/orgs/{orgId}/roles | bbws-access-{env}-role-list-org | handlers.organisation.list_roles.handler |
| GET /v1/orgs/{orgId}/roles/{roleId} | bbws-access-{env}-role-get-org | handlers.organisation.get_role.handler |
| PUT /v1/orgs/{orgId}/roles/{roleId} | bbws-access-{env}-role-update-org | handlers.organisation.update_role.handler |
| DELETE /v1/orgs/{orgId}/roles/{roleId} | bbws-access-{env}-role-delete-org | handlers.organisation.delete_role.handler |
| POST /v1/orgs/{orgId}/roles/seed | bbws-access-{env}-role-seed-org | handlers.organisation.seed_roles.handler |

### 6.2 Authorizer Context Variables

```json
{
  "userId": "user-550e8400-e29b-41d4-a716-446655440000",
  "orgId": "org-550e8400-e29b-41d4-a716-446655440001",
  "email": "user@example.com",
  "teamIds": "[\"team-001\", \"team-002\"]",
  "permissions": "[\"role:create\", \"role:read\", \"role:update\", \"role:delete\"]",
  "roles": "[\"ORG_ADMIN\"]"
}
```

### 6.3 Required Permissions by Endpoint

| Endpoint | Required Permission | Notes |
|----------|-------------------|-------|
| GET /v1/platform/roles | role:read | Any authenticated user |
| GET /v1/platform/roles/{roleId} | role:read | Any authenticated user |
| POST /v1/orgs/{orgId}/roles | role:create | Org admin only |
| GET /v1/orgs/{orgId}/roles | role:read | Same org users |
| GET /v1/orgs/{orgId}/roles/{roleId} | role:read | Same org users |
| PUT /v1/orgs/{orgId}/roles/{roleId} | role:update | Org admin only |
| DELETE /v1/orgs/{orgId}/roles/{roleId} | role:delete | Org admin only |
| POST /v1/orgs/{orgId}/roles/seed | role:create | Org admin only |

---

## 7. Validation Rules

### 7.1 Path Parameter Validation

| Parameter | Pattern | Example |
|-----------|---------|---------|
| orgId | `^org-[a-f0-9-]{36}$` | org-550e8400-e29b-41d4-a716-446655440000 |
| roleId | `^role-[a-f0-9-]{36}$\|^role-[a-z-]+-[0-9]{3}$` | role-550e8400-e29b-41d4-a716-446655440000 |

### 7.2 Query Parameter Validation

| Parameter | Type | Range | Default |
|-----------|------|-------|---------|
| pageSize | integer | 1-100 | 50 |
| startAt | string | UUID format | null |
| scope | enum | PLATFORM, ORGANISATION, TEAM | null |
| includeInactive | boolean | true/false | false |

### 7.3 Request Body Validation

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| name | string | Yes (create) | 2-50 chars, pattern: `^[A-Z][A-Z0-9_]*$` |
| displayName | string | Yes (create) | 2-100 chars |
| description | string | No | 0-500 chars |
| scope | enum | No | ORGANISATION or TEAM |
| permissions | array | Yes (create) | Min 1 item, unique, pattern: `^[a-z]+:[a-z]+$` |
| priority | integer | No | 1-999 |
| active | boolean | No (update only) | true/false |

---

## Success Criteria Checklist

- [x] All 8 routes configured
  - [x] GET /v1/platform/roles
  - [x] GET /v1/platform/roles/{roleId}
  - [x] POST /v1/orgs/{orgId}/roles
  - [x] GET /v1/orgs/{orgId}/roles
  - [x] GET /v1/orgs/{orgId}/roles/{roleId}
  - [x] PUT /v1/orgs/{orgId}/roles/{roleId}
  - [x] DELETE /v1/orgs/{orgId}/roles/{roleId}
  - [x] POST /v1/orgs/{orgId}/roles/seed
- [x] Platform routes under /v1/platform
- [x] Org routes under /v1/orgs/{orgId}
- [x] Lambda authorizer attached to all endpoints
- [x] OpenAPI 3.0 spec complete
- [x] Terraform route configuration complete
- [x] Request/response JSON schemas documented
- [x] CORS configuration complete
- [x] Lambda integration details documented
- [x] Validation rules documented

---

**Worker**: worker-4-role-api-routes
**Status**: COMPLETE
**Completed**: 2026-01-23
