# Team Service API Routes - Configuration Output

**Worker ID**: worker-3-team-api-routes
**Stage**: Stage 4 - API Gateway Integration
**Project**: project-plan-2-access-management
**Date**: 2026-01-23
**Status**: COMPLETE

---

## Executive Summary

This document contains the complete API Gateway configuration for the Team Service, including:
- OpenAPI 3.0 specification for all 14 endpoints
- Terraform route configuration with nested paths
- Request/response JSON schemas
- CORS configuration
- Path parameter validation
- Lambda authorizer integration

---

## Table of Contents

1. [API Route Summary](#1-api-route-summary)
2. [OpenAPI 3.0 Specification](#2-openapi-30-specification)
3. [Terraform Route Configuration](#3-terraform-route-configuration)
4. [Request/Response Schemas](#4-requestresponse-schemas)
5. [CORS Configuration](#5-cors-configuration)
6. [Success Criteria](#6-success-criteria)

---

## 1. API Route Summary

### Team Operations (4 endpoints)

| Method | Path | Lambda | Description |
|--------|------|--------|-------------|
| POST | /v1/orgs/{orgId}/teams | create_team | Create a new team |
| GET | /v1/orgs/{orgId}/teams | list_teams | List all teams in organisation |
| GET | /v1/orgs/{orgId}/teams/{teamId} | get_team | Get team by ID |
| PUT | /v1/orgs/{orgId}/teams/{teamId} | update_team | Update team details |

### Team Role Operations (5 endpoints)

| Method | Path | Lambda | Description |
|--------|------|--------|-------------|
| POST | /v1/orgs/{orgId}/team-roles | create_team_role | Create team role definition |
| GET | /v1/orgs/{orgId}/team-roles | list_team_roles | List team roles |
| GET | /v1/orgs/{orgId}/team-roles/{roleId} | get_team_role | Get team role by ID |
| PUT | /v1/orgs/{orgId}/team-roles/{roleId} | update_team_role | Update team role |
| DELETE | /v1/orgs/{orgId}/team-roles/{roleId} | delete_team_role | Delete team role |

### Member Operations (5 endpoints)

| Method | Path | Lambda | Description |
|--------|------|--------|-------------|
| POST | /v1/orgs/{orgId}/teams/{teamId}/members | add_member | Add member to team |
| GET | /v1/orgs/{orgId}/teams/{teamId}/members | list_members | List team members |
| GET | /v1/orgs/{orgId}/teams/{teamId}/members/{userId} | get_member | Get member details |
| PUT | /v1/orgs/{orgId}/teams/{teamId}/members/{userId} | update_member | Update member role |
| GET | /v1/orgs/{orgId}/users/{userId}/teams | get_user_teams | Get teams for user |

---

## 2. OpenAPI 3.0 Specification

### File: api-specs/team-service.yaml

```yaml
openapi: 3.0.3
info:
  title: BBWS Team Service API
  description: |
    API for managing teams, team roles, and team memberships within organisations.
    Part of the BBWS Access Management System.
  version: 1.0.0
  contact:
    name: BBWS Platform Team
    email: platform@bbws.co.za

servers:
  - url: https://api.{environment}.bbws.co.za/access
    description: BBWS Access Management API
    variables:
      environment:
        default: dev
        enum:
          - dev
          - sit
          - prod
        description: Deployment environment

security:
  - BearerAuth: []
  - LambdaAuthorizer: []

tags:
  - name: Teams
    description: Team management operations
  - name: Team Roles
    description: Team role definition operations
  - name: Team Members
    description: Team membership operations

paths:
  #============================================================================
  # TEAM OPERATIONS
  #============================================================================
  /v1/orgs/{orgId}/teams:
    post:
      operationId: createTeam
      summary: Create a new team
      description: |
        Creates a new team within the organisation. Requires MANAGE_TEAMS permission.
        The creator is automatically added as Team Lead.
      tags:
        - Teams
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
        - $ref: '#/components/parameters/RequestId'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateTeamRequest'
            examples:
              basicTeam:
                summary: Basic team creation
                value:
                  name: "Marketing Team"
                  description: "Digital marketing and campaigns"
              teamWithHierarchy:
                summary: Team with hierarchy placement
                value:
                  name: "Content Writers"
                  description: "Content creation team"
                  divisionId: "div-123"
                  groupId: "grp-456"
      responses:
        '201':
          description: Team created successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TeamResponse'
          headers:
            Location:
              description: URL of the created team
              schema:
                type: string
            X-Request-ID:
              $ref: '#/components/headers/XRequestId'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '409':
          $ref: '#/components/responses/Conflict'
        '500':
          $ref: '#/components/responses/InternalError'

    get:
      operationId: listTeams
      summary: List teams in organisation
      description: |
        Returns a paginated list of teams in the organisation.
        Users can only see teams they have access to.
      tags:
        - Teams
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
        - $ref: '#/components/parameters/RequestId'
        - $ref: '#/components/parameters/Limit'
        - $ref: '#/components/parameters/NextToken'
        - name: divisionId
          in: query
          description: Filter by division
          schema:
            type: string
            format: uuid
        - name: groupId
          in: query
          description: Filter by group
          schema:
            type: string
            format: uuid
        - name: active
          in: query
          description: Filter by active status
          schema:
            type: boolean
            default: true
        - name: search
          in: query
          description: Search by team name
          schema:
            type: string
            minLength: 2
            maxLength: 100
      responses:
        '200':
          description: List of teams
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TeamListResponse'
          headers:
            X-Request-ID:
              $ref: '#/components/headers/XRequestId'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '500':
          $ref: '#/components/responses/InternalError'

  /v1/orgs/{orgId}/teams/{teamId}:
    get:
      operationId: getTeam
      summary: Get team by ID
      description: |
        Returns detailed information about a specific team.
        Includes member count and site count.
      tags:
        - Teams
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
        - $ref: '#/components/parameters/TeamIdPath'
        - $ref: '#/components/parameters/RequestId'
      responses:
        '200':
          description: Team details
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TeamResponse'
          headers:
            X-Request-ID:
              $ref: '#/components/headers/XRequestId'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '404':
          $ref: '#/components/responses/NotFound'
        '500':
          $ref: '#/components/responses/InternalError'

    put:
      operationId: updateTeam
      summary: Update team details
      description: |
        Updates team information. Requires MANAGE_TEAMS permission or
        CAN_UPDATE_TEAM capability within the team.
      tags:
        - Teams
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
        - $ref: '#/components/parameters/TeamIdPath'
        - $ref: '#/components/parameters/RequestId'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UpdateTeamRequest'
            examples:
              updateName:
                summary: Update team name
                value:
                  name: "Marketing & Communications Team"
              updateStatus:
                summary: Deactivate team
                value:
                  active: false
      responses:
        '200':
          description: Team updated successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TeamResponse'
          headers:
            X-Request-ID:
              $ref: '#/components/headers/XRequestId'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '404':
          $ref: '#/components/responses/NotFound'
        '409':
          $ref: '#/components/responses/Conflict'
        '500':
          $ref: '#/components/responses/InternalError'

  #============================================================================
  # TEAM ROLE OPERATIONS
  #============================================================================
  /v1/orgs/{orgId}/team-roles:
    post:
      operationId: createTeamRole
      summary: Create a team role definition
      description: |
        Creates a new team role definition for the organisation.
        Requires MANAGE_ROLES permission.
      tags:
        - Team Roles
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
        - $ref: '#/components/parameters/RequestId'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateTeamRoleRequest'
            examples:
              contentEditor:
                summary: Content Editor role
                value:
                  name: "CONTENT_EDITOR"
                  displayName: "Content Editor"
                  description: "Can view and edit site content"
                  capabilities:
                    - "CAN_VIEW_SITES"
                    - "CAN_EDIT_SITES"
                  sortOrder: 30
              viewer:
                summary: Viewer role
                value:
                  name: "VIEWER"
                  displayName: "Viewer"
                  description: "Read-only access to team resources"
                  capabilities:
                    - "CAN_VIEW_MEMBERS"
                    - "CAN_VIEW_SITES"
                  sortOrder: 50
      responses:
        '201':
          description: Team role created successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TeamRoleResponse'
          headers:
            Location:
              description: URL of the created team role
              schema:
                type: string
            X-Request-ID:
              $ref: '#/components/headers/XRequestId'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '409':
          $ref: '#/components/responses/Conflict'
        '500':
          $ref: '#/components/responses/InternalError'

    get:
      operationId: listTeamRoles
      summary: List team roles
      description: |
        Returns all team role definitions for the organisation.
        Includes both default roles and custom roles.
      tags:
        - Team Roles
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
        - $ref: '#/components/parameters/RequestId'
        - name: active
          in: query
          description: Filter by active status
          schema:
            type: boolean
            default: true
        - name: includeDefault
          in: query
          description: Include default system roles
          schema:
            type: boolean
            default: true
      responses:
        '200':
          description: List of team roles
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TeamRoleListResponse'
          headers:
            X-Request-ID:
              $ref: '#/components/headers/XRequestId'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '500':
          $ref: '#/components/responses/InternalError'

  /v1/orgs/{orgId}/team-roles/{roleId}:
    get:
      operationId: getTeamRole
      summary: Get team role by ID
      description: Returns detailed information about a specific team role.
      tags:
        - Team Roles
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
        - $ref: '#/components/parameters/RoleIdPath'
        - $ref: '#/components/parameters/RequestId'
      responses:
        '200':
          description: Team role details
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TeamRoleResponse'
          headers:
            X-Request-ID:
              $ref: '#/components/headers/XRequestId'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '404':
          $ref: '#/components/responses/NotFound'
        '500':
          $ref: '#/components/responses/InternalError'

    put:
      operationId: updateTeamRole
      summary: Update team role
      description: |
        Updates a team role definition. Default system roles cannot be modified.
        Requires MANAGE_ROLES permission.
      tags:
        - Team Roles
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
        - $ref: '#/components/parameters/RoleIdPath'
        - $ref: '#/components/parameters/RequestId'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UpdateTeamRoleRequest'
            examples:
              updateCapabilities:
                summary: Add capability
                value:
                  capabilities:
                    - "CAN_VIEW_SITES"
                    - "CAN_EDIT_SITES"
                    - "CAN_VIEW_AUDIT"
              updateDisplayName:
                summary: Update display name
                value:
                  displayName: "Senior Content Editor"
      responses:
        '200':
          description: Team role updated successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TeamRoleResponse'
          headers:
            X-Request-ID:
              $ref: '#/components/headers/XRequestId'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '404':
          $ref: '#/components/responses/NotFound'
        '409':
          $ref: '#/components/responses/Conflict'
        '500':
          $ref: '#/components/responses/InternalError'

    delete:
      operationId: deleteTeamRole
      summary: Delete team role
      description: |
        Deletes a team role definition. Cannot delete default roles or roles
        currently assigned to members. Requires MANAGE_ROLES permission.
      tags:
        - Team Roles
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
        - $ref: '#/components/parameters/RoleIdPath'
        - $ref: '#/components/parameters/RequestId'
      responses:
        '204':
          description: Team role deleted successfully
          headers:
            X-Request-ID:
              $ref: '#/components/headers/XRequestId'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '404':
          $ref: '#/components/responses/NotFound'
        '409':
          description: Role is in use and cannot be deleted
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '500':
          $ref: '#/components/responses/InternalError'

  #============================================================================
  # TEAM MEMBER OPERATIONS
  #============================================================================
  /v1/orgs/{orgId}/teams/{teamId}/members:
    post:
      operationId: addTeamMember
      summary: Add member to team
      description: |
        Adds a user to a team with a specified team role.
        Requires CAN_MANAGE_MEMBERS capability or MANAGE_TEAMS permission.
        User must already exist in the organisation.
      tags:
        - Team Members
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
        - $ref: '#/components/parameters/TeamIdPath'
        - $ref: '#/components/parameters/RequestId'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/AddMemberRequest'
            examples:
              addAsEditor:
                summary: Add as content editor
                value:
                  userId: "usr-789012"
                  teamRoleId: "trl-345678"
              addAsViewer:
                summary: Add as viewer
                value:
                  userId: "usr-123456"
                  teamRoleId: "trl-viewer-default"
      responses:
        '201':
          description: Member added successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TeamMemberResponse'
          headers:
            Location:
              description: URL of the member resource
              schema:
                type: string
            X-Request-ID:
              $ref: '#/components/headers/XRequestId'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '404':
          $ref: '#/components/responses/NotFound'
        '409':
          description: User is already a member of the team
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '500':
          $ref: '#/components/responses/InternalError'

    get:
      operationId: listTeamMembers
      summary: List team members
      description: |
        Returns a paginated list of members in the team.
        Requires CAN_VIEW_MEMBERS capability or MANAGE_TEAMS permission.
      tags:
        - Team Members
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
        - $ref: '#/components/parameters/TeamIdPath'
        - $ref: '#/components/parameters/RequestId'
        - $ref: '#/components/parameters/Limit'
        - $ref: '#/components/parameters/NextToken'
        - name: teamRoleId
          in: query
          description: Filter by team role
          schema:
            type: string
            format: uuid
        - name: active
          in: query
          description: Filter by active status
          schema:
            type: boolean
            default: true
        - name: search
          in: query
          description: Search by member name or email
          schema:
            type: string
            minLength: 2
            maxLength: 100
      responses:
        '200':
          description: List of team members
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TeamMemberListResponse'
          headers:
            X-Request-ID:
              $ref: '#/components/headers/XRequestId'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '404':
          $ref: '#/components/responses/NotFound'
        '500':
          $ref: '#/components/responses/InternalError'

  /v1/orgs/{orgId}/teams/{teamId}/members/{userId}:
    get:
      operationId: getTeamMember
      summary: Get team member details
      description: |
        Returns detailed information about a team member.
        Requires CAN_VIEW_MEMBERS capability or MANAGE_TEAMS permission.
      tags:
        - Team Members
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
        - $ref: '#/components/parameters/TeamIdPath'
        - $ref: '#/components/parameters/UserIdPath'
        - $ref: '#/components/parameters/RequestId'
      responses:
        '200':
          description: Team member details
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TeamMemberResponse'
          headers:
            X-Request-ID:
              $ref: '#/components/headers/XRequestId'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '404':
          $ref: '#/components/responses/NotFound'
        '500':
          $ref: '#/components/responses/InternalError'

    put:
      operationId: updateTeamMember
      summary: Update team member role
      description: |
        Updates a team member's role or status.
        Requires CAN_MANAGE_MEMBERS capability or MANAGE_TEAMS permission.
      tags:
        - Team Members
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
        - $ref: '#/components/parameters/TeamIdPath'
        - $ref: '#/components/parameters/UserIdPath'
        - $ref: '#/components/parameters/RequestId'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UpdateMemberRequest'
            examples:
              changeRole:
                summary: Change team role
                value:
                  teamRoleId: "trl-lead-default"
              deactivate:
                summary: Deactivate member
                value:
                  active: false
      responses:
        '200':
          description: Team member updated successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TeamMemberResponse'
          headers:
            X-Request-ID:
              $ref: '#/components/headers/XRequestId'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '404':
          $ref: '#/components/responses/NotFound'
        '409':
          $ref: '#/components/responses/Conflict'
        '500':
          $ref: '#/components/responses/InternalError'

  #============================================================================
  # USER TEAMS OPERATION
  #============================================================================
  /v1/orgs/{orgId}/users/{userId}/teams:
    get:
      operationId: getUserTeams
      summary: Get teams for a user
      description: |
        Returns all teams that a user is a member of within the organisation.
        Users can view their own teams, admins can view any user's teams.
      tags:
        - Team Members
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
        - $ref: '#/components/parameters/UserIdPath'
        - $ref: '#/components/parameters/RequestId'
        - name: active
          in: query
          description: Filter by active membership status
          schema:
            type: boolean
            default: true
      responses:
        '200':
          description: List of user's teams
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserTeamsResponse'
          headers:
            X-Request-ID:
              $ref: '#/components/headers/XRequestId'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '404':
          $ref: '#/components/responses/NotFound'
        '500':
          $ref: '#/components/responses/InternalError'

#==============================================================================
# COMPONENTS
#==============================================================================
components:
  #----------------------------------------------------------------------------
  # SECURITY SCHEMES
  #----------------------------------------------------------------------------
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: JWT token from Cognito

    LambdaAuthorizer:
      type: apiKey
      in: header
      name: Authorization
      description: Custom Lambda authorizer validates JWT and returns permissions

  #----------------------------------------------------------------------------
  # PARAMETERS
  #----------------------------------------------------------------------------
  parameters:
    OrgIdPath:
      name: orgId
      in: path
      required: true
      description: Organisation ID
      schema:
        type: string
        format: uuid
        pattern: '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      example: "org-12345678-abcd-1234-efgh-123456789012"

    TeamIdPath:
      name: teamId
      in: path
      required: true
      description: Team ID
      schema:
        type: string
        format: uuid
        pattern: '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      example: "team-12345678-abcd-1234-efgh-123456789012"

    RoleIdPath:
      name: roleId
      in: path
      required: true
      description: Team Role Definition ID
      schema:
        type: string
        format: uuid
        pattern: '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      example: "trl-12345678-abcd-1234-efgh-123456789012"

    UserIdPath:
      name: userId
      in: path
      required: true
      description: User ID
      schema:
        type: string
        format: uuid
        pattern: '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      example: "usr-12345678-abcd-1234-efgh-123456789012"

    RequestId:
      name: X-Request-ID
      in: header
      required: false
      description: Unique request identifier for tracing
      schema:
        type: string
        format: uuid

    Limit:
      name: limit
      in: query
      required: false
      description: Maximum number of items to return
      schema:
        type: integer
        minimum: 1
        maximum: 100
        default: 20

    NextToken:
      name: nextToken
      in: query
      required: false
      description: Pagination token for next page
      schema:
        type: string
        maxLength: 1024

  #----------------------------------------------------------------------------
  # HEADERS
  #----------------------------------------------------------------------------
  headers:
    XRequestId:
      description: Unique request identifier for tracing
      schema:
        type: string
        format: uuid

  #----------------------------------------------------------------------------
  # SCHEMAS
  #----------------------------------------------------------------------------
  schemas:
    #--------------------------------------------------------------------------
    # TEAM SCHEMAS
    #--------------------------------------------------------------------------
    CreateTeamRequest:
      type: object
      required:
        - name
      properties:
        name:
          type: string
          minLength: 2
          maxLength: 100
          description: Team name (unique within organisation)
          example: "Marketing Team"
        description:
          type: string
          maxLength: 500
          description: Team description
          example: "Digital marketing and campaign management"
        divisionId:
          type: string
          format: uuid
          description: Division ID for hierarchy placement
        groupId:
          type: string
          format: uuid
          description: Group ID for hierarchy placement

    UpdateTeamRequest:
      type: object
      minProperties: 1
      properties:
        name:
          type: string
          minLength: 2
          maxLength: 100
          description: Team name
        description:
          type: string
          maxLength: 500
          description: Team description
        divisionId:
          type: string
          format: uuid
          nullable: true
          description: Division ID (null to remove)
        groupId:
          type: string
          format: uuid
          nullable: true
          description: Group ID (null to remove)
        active:
          type: boolean
          description: Team active status

    TeamResponse:
      type: object
      properties:
        id:
          type: string
          format: uuid
          description: Team ID
        teamId:
          type: string
          format: uuid
          description: Team ID (alias)
        name:
          type: string
          description: Team name
        description:
          type: string
          description: Team description
        organisationId:
          type: string
          format: uuid
          description: Organisation ID
        divisionId:
          type: string
          format: uuid
          nullable: true
          description: Division ID
        groupId:
          type: string
          format: uuid
          nullable: true
          description: Group ID
        memberCount:
          type: integer
          minimum: 0
          description: Number of active members
        siteCount:
          type: integer
          minimum: 0
          description: Number of WordPress sites
        active:
          type: boolean
          description: Team active status
        dateCreated:
          type: string
          format: date-time
          description: Creation timestamp
        dateLastUpdated:
          type: string
          format: date-time
          description: Last update timestamp
        createdBy:
          type: string
          description: User ID who created the team
        lastUpdatedBy:
          type: string
          description: User ID who last updated the team
        _links:
          $ref: '#/components/schemas/TeamLinks'

    TeamLinks:
      type: object
      properties:
        self:
          $ref: '#/components/schemas/Link'
        members:
          $ref: '#/components/schemas/Link'
        organisation:
          $ref: '#/components/schemas/Link'

    TeamListResponse:
      type: object
      properties:
        data:
          type: array
          items:
            $ref: '#/components/schemas/TeamResponse'
        pagination:
          $ref: '#/components/schemas/Pagination'
        _links:
          type: object
          properties:
            self:
              $ref: '#/components/schemas/Link'
            next:
              $ref: '#/components/schemas/Link'

    #--------------------------------------------------------------------------
    # TEAM ROLE SCHEMAS
    #--------------------------------------------------------------------------
    CreateTeamRoleRequest:
      type: object
      required:
        - name
        - displayName
        - capabilities
      properties:
        name:
          type: string
          pattern: '^[A-Z][A-Z0-9_]*$'
          minLength: 2
          maxLength: 50
          description: Role name (uppercase, underscores allowed)
          example: "CONTENT_EDITOR"
        displayName:
          type: string
          minLength: 2
          maxLength: 100
          description: Human-readable display name
          example: "Content Editor"
        description:
          type: string
          maxLength: 500
          description: Role description
          example: "Can view and edit site content"
        capabilities:
          type: array
          items:
            $ref: '#/components/schemas/TeamRoleCapability'
          minItems: 1
          description: List of capabilities granted by this role
        sortOrder:
          type: integer
          minimum: 0
          maximum: 1000
          default: 100
          description: Sort order for display

    UpdateTeamRoleRequest:
      type: object
      minProperties: 1
      properties:
        displayName:
          type: string
          minLength: 2
          maxLength: 100
          description: Human-readable display name
        description:
          type: string
          maxLength: 500
          description: Role description
        capabilities:
          type: array
          items:
            $ref: '#/components/schemas/TeamRoleCapability'
          minItems: 1
          description: List of capabilities
        sortOrder:
          type: integer
          minimum: 0
          maximum: 1000
          description: Sort order for display
        active:
          type: boolean
          description: Role active status

    TeamRoleCapability:
      type: string
      enum:
        - CAN_MANAGE_MEMBERS
        - CAN_UPDATE_TEAM
        - CAN_VIEW_MEMBERS
        - CAN_VIEW_SITES
        - CAN_EDIT_SITES
        - CAN_DELETE_SITES
        - CAN_VIEW_AUDIT
      description: |
        Valid team role capabilities:
        - CAN_MANAGE_MEMBERS: Add/remove team members, change roles
        - CAN_UPDATE_TEAM: Update team name, description
        - CAN_VIEW_MEMBERS: View team member list
        - CAN_VIEW_SITES: View WordPress sites
        - CAN_EDIT_SITES: Edit WordPress sites
        - CAN_DELETE_SITES: Delete WordPress sites
        - CAN_VIEW_AUDIT: View team audit logs

    TeamRoleResponse:
      type: object
      properties:
        id:
          type: string
          format: uuid
          description: Team role ID
        teamRoleId:
          type: string
          format: uuid
          description: Team role ID (alias)
        name:
          type: string
          description: Role name
        displayName:
          type: string
          description: Display name
        description:
          type: string
          description: Role description
        organisationId:
          type: string
          format: uuid
          description: Organisation ID
        capabilities:
          type: array
          items:
            $ref: '#/components/schemas/TeamRoleCapability'
          description: Granted capabilities
        isDefault:
          type: boolean
          description: Whether this is a system default role
        sortOrder:
          type: integer
          description: Sort order
        active:
          type: boolean
          description: Role active status
        dateCreated:
          type: string
          format: date-time
          description: Creation timestamp
        dateLastUpdated:
          type: string
          format: date-time
          description: Last update timestamp
        createdBy:
          type: string
          description: User ID who created the role
        lastUpdatedBy:
          type: string
          description: User ID who last updated the role
        _links:
          $ref: '#/components/schemas/TeamRoleLinks'

    TeamRoleLinks:
      type: object
      properties:
        self:
          $ref: '#/components/schemas/Link'
        organisation:
          $ref: '#/components/schemas/Link'

    TeamRoleListResponse:
      type: object
      properties:
        data:
          type: array
          items:
            $ref: '#/components/schemas/TeamRoleResponse'
        _links:
          type: object
          properties:
            self:
              $ref: '#/components/schemas/Link'

    #--------------------------------------------------------------------------
    # TEAM MEMBER SCHEMAS
    #--------------------------------------------------------------------------
    AddMemberRequest:
      type: object
      required:
        - userId
        - teamRoleId
      properties:
        userId:
          type: string
          format: uuid
          description: User ID to add
          example: "usr-12345678-abcd-1234-efgh-123456789012"
        teamRoleId:
          type: string
          format: uuid
          description: Team role to assign
          example: "trl-12345678-abcd-1234-efgh-123456789012"

    UpdateMemberRequest:
      type: object
      minProperties: 1
      properties:
        teamRoleId:
          type: string
          format: uuid
          description: New team role ID
        active:
          type: boolean
          description: Member active status

    TeamMemberResponse:
      type: object
      properties:
        organisationId:
          type: string
          format: uuid
          description: Organisation ID
        teamId:
          type: string
          format: uuid
          description: Team ID
        userId:
          type: string
          format: uuid
          description: User ID
        teamRoleId:
          type: string
          format: uuid
          description: Assigned team role ID
        teamRoleName:
          type: string
          description: Team role name
        userEmail:
          type: string
          format: email
          description: User email (denormalized)
        userFirstName:
          type: string
          description: User first name (denormalized)
        userLastName:
          type: string
          description: User last name (denormalized)
        joinedAt:
          type: string
          format: date-time
          description: When user joined the team
        addedBy:
          type: string
          description: User ID who added this member
        active:
          type: boolean
          description: Membership active status
        dateCreated:
          type: string
          format: date-time
          description: Record creation timestamp
        dateLastUpdated:
          type: string
          format: date-time
          description: Last update timestamp
        lastUpdatedBy:
          type: string
          description: User ID who last updated
        _links:
          $ref: '#/components/schemas/TeamMemberLinks'

    TeamMemberLinks:
      type: object
      properties:
        self:
          $ref: '#/components/schemas/Link'
        team:
          $ref: '#/components/schemas/Link'
        user:
          $ref: '#/components/schemas/Link'
        teamRole:
          $ref: '#/components/schemas/Link'

    TeamMemberListResponse:
      type: object
      properties:
        data:
          type: array
          items:
            $ref: '#/components/schemas/TeamMemberResponse'
        pagination:
          $ref: '#/components/schemas/Pagination'
        _links:
          type: object
          properties:
            self:
              $ref: '#/components/schemas/Link'
            next:
              $ref: '#/components/schemas/Link'

    UserTeamsResponse:
      type: object
      properties:
        data:
          type: array
          items:
            $ref: '#/components/schemas/UserTeamMembership'
        _links:
          type: object
          properties:
            self:
              $ref: '#/components/schemas/Link'

    UserTeamMembership:
      type: object
      properties:
        team:
          $ref: '#/components/schemas/TeamSummary'
        membership:
          $ref: '#/components/schemas/MembershipSummary'

    TeamSummary:
      type: object
      properties:
        id:
          type: string
          format: uuid
        name:
          type: string
        description:
          type: string
        active:
          type: boolean
        _links:
          type: object
          properties:
            self:
              $ref: '#/components/schemas/Link'

    MembershipSummary:
      type: object
      properties:
        teamRoleId:
          type: string
          format: uuid
        teamRoleName:
          type: string
        joinedAt:
          type: string
          format: date-time
        active:
          type: boolean

    #--------------------------------------------------------------------------
    # COMMON SCHEMAS
    #--------------------------------------------------------------------------
    Link:
      type: object
      properties:
        href:
          type: string
          format: uri

    Pagination:
      type: object
      properties:
        limit:
          type: integer
          description: Items per page
        nextToken:
          type: string
          nullable: true
          description: Token for next page (null if no more pages)
        totalCount:
          type: integer
          description: Total number of items (if available)

    ErrorResponse:
      type: object
      required:
        - error
        - message
      properties:
        error:
          type: string
          description: Error code
          example: "VALIDATION_ERROR"
        message:
          type: string
          description: Human-readable error message
          example: "Team name is required"
        details:
          type: array
          items:
            $ref: '#/components/schemas/ErrorDetail'
          description: Detailed validation errors
        requestId:
          type: string
          format: uuid
          description: Request ID for support

    ErrorDetail:
      type: object
      properties:
        field:
          type: string
          description: Field that caused the error
        message:
          type: string
          description: Error message for this field
        code:
          type: string
          description: Error code

  #----------------------------------------------------------------------------
  # RESPONSES
  #----------------------------------------------------------------------------
  responses:
    BadRequest:
      description: Invalid request
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          examples:
            validationError:
              summary: Validation error
              value:
                error: "VALIDATION_ERROR"
                message: "Request validation failed"
                details:
                  - field: "name"
                    message: "Name must be between 2 and 100 characters"
                    code: "INVALID_LENGTH"

    Unauthorized:
      description: Authentication required
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            error: "UNAUTHORIZED"
            message: "Authentication token is missing or invalid"

    Forbidden:
      description: Access denied
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            error: "FORBIDDEN"
            message: "You do not have permission to perform this action"

    NotFound:
      description: Resource not found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            error: "NOT_FOUND"
            message: "Team not found"

    Conflict:
      description: Resource conflict
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            error: "CONFLICT"
            message: "A team with this name already exists"

    InternalError:
      description: Internal server error
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            error: "INTERNAL_ERROR"
            message: "An unexpected error occurred"
            requestId: "req-12345678-abcd-1234-efgh-123456789012"
```

---

## 3. Terraform Route Configuration

### File: terraform/modules/api-gateway-access-management/team_routes.tf

```hcl
#------------------------------------------------------------------------------
# Team Service API Gateway Routes
# Description: Terraform configuration for Team Service endpoints (14 routes)
# Environment: Parameterised for dev/sit/prod deployment
#------------------------------------------------------------------------------

#==============================================================================
# LOCAL VARIABLES - TEAM SERVICE METHODS
#==============================================================================

locals {
  team_methods = {
    #--------------------------------------------------------------------------
    # TEAM OPERATIONS (4 endpoints)
    #--------------------------------------------------------------------------

    # POST /v1/organisations/{orgId}/teams - Create Team
    "teams_post" = {
      resource_id          = aws_api_gateway_resource.teams.id
      http_method          = "POST"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.team.create_team
      lambda_function_name = var.lambda_names.team.create_team
      request_parameters   = { "method.request.path.orgId" = true }
      validate_body        = true
    }

    # GET /v1/organisations/{orgId}/teams - List Teams
    "teams_get" = {
      resource_id          = aws_api_gateway_resource.teams.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.team.list_teams
      lambda_function_name = var.lambda_names.team.list_teams
      request_parameters   = {
        "method.request.path.orgId"          = true
        "method.request.querystring.limit"   = false
        "method.request.querystring.nextToken" = false
        "method.request.querystring.divisionId" = false
        "method.request.querystring.groupId" = false
        "method.request.querystring.active"  = false
        "method.request.querystring.search"  = false
      }
      validate_body = false
    }

    # GET /v1/organisations/{orgId}/teams/{teamId} - Get Team
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

    # PUT /v1/organisations/{orgId}/teams/{teamId} - Update Team
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
    # TEAM ROLE OPERATIONS (5 endpoints)
    #--------------------------------------------------------------------------

    # POST /v1/organisations/{orgId}/team-roles - Create Team Role
    "team_roles_post" = {
      resource_id          = aws_api_gateway_resource.team_roles.id
      http_method          = "POST"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.team.create_team_role
      lambda_function_name = var.lambda_names.team.create_team_role
      request_parameters   = { "method.request.path.orgId" = true }
      validate_body        = true
    }

    # GET /v1/organisations/{orgId}/team-roles - List Team Roles
    "team_roles_get" = {
      resource_id          = aws_api_gateway_resource.team_roles.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.team.list_team_roles
      lambda_function_name = var.lambda_names.team.list_team_roles
      request_parameters   = {
        "method.request.path.orgId"                = true
        "method.request.querystring.active"        = false
        "method.request.querystring.includeDefault" = false
      }
      validate_body = false
    }

    # GET /v1/organisations/{orgId}/team-roles/{teamRoleId} - Get Team Role
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

    # PUT /v1/organisations/{orgId}/team-roles/{teamRoleId} - Update Team Role
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

    # DELETE /v1/organisations/{orgId}/team-roles/{teamRoleId} - Delete Team Role
    "team_roles_id_delete" = {
      resource_id          = aws_api_gateway_resource.team_roles_id.id
      http_method          = "DELETE"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.team.delete_team_role
      lambda_function_name = var.lambda_names.team.delete_team_role
      request_parameters   = {
        "method.request.path.orgId"      = true
        "method.request.path.teamRoleId" = true
      }
      validate_body = false
    }

    #--------------------------------------------------------------------------
    # TEAM MEMBER OPERATIONS (5 endpoints)
    #--------------------------------------------------------------------------

    # POST /v1/organisations/{orgId}/teams/{teamId}/members - Add Member
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

    # GET /v1/organisations/{orgId}/teams/{teamId}/members - List Members
    "team_members_get" = {
      resource_id          = aws_api_gateway_resource.team_members.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.team.list_members
      lambda_function_name = var.lambda_names.team.list_members
      request_parameters   = {
        "method.request.path.orgId"            = true
        "method.request.path.teamId"           = true
        "method.request.querystring.limit"     = false
        "method.request.querystring.nextToken" = false
        "method.request.querystring.teamRoleId" = false
        "method.request.querystring.active"    = false
        "method.request.querystring.search"    = false
      }
      validate_body = false
    }

    # GET /v1/organisations/{orgId}/teams/{teamId}/members/{userId} - Get Member
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

    # PUT /v1/organisations/{orgId}/teams/{teamId}/members/{userId} - Update Member
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

    # GET /v1/organisations/{orgId}/users/{userId}/teams - Get User's Teams
    "users_teams_get" = {
      resource_id          = aws_api_gateway_resource.users_teams.id
      http_method          = "GET"
      authorization        = "CUSTOM"
      lambda_invoke_arn    = var.lambda_arns.team.get_user_teams
      lambda_function_name = var.lambda_names.team.get_user_teams
      request_parameters   = {
        "method.request.path.orgId"         = true
        "method.request.path.userId"        = true
        "method.request.querystring.active" = false
      }
      validate_body = false
    }
  }
}

#==============================================================================
# TEAM SERVICE METHODS MODULE
#==============================================================================

module "team_methods" {
  source = "./modules/api-method"

  for_each = local.team_methods

  rest_api_id          = aws_api_gateway_rest_api.access_management.id
  resource_id          = each.value.resource_id
  http_method          = each.value.http_method
  authorization        = each.value.authorization
  authorizer_id        = each.value.authorization == "CUSTOM" ? aws_api_gateway_authorizer.lambda_authorizer.id : null
  lambda_invoke_arn    = each.value.lambda_invoke_arn
  lambda_function_name = each.value.lambda_function_name
  request_parameters   = each.value.request_parameters
  request_validator_id = each.value.validate_body ? aws_api_gateway_request_validator.body_validator.id : null
  api_gateway_execution_arn = aws_api_gateway_rest_api.access_management.execution_arn
  environment          = var.environment
}

#==============================================================================
# LAMBDA PERMISSIONS FOR TEAM SERVICE
#==============================================================================

# Permission for API Gateway to invoke Team Lambda functions
resource "aws_lambda_permission" "team_api_gateway" {
  for_each = local.team_methods

  statement_id  = "AllowAPIGatewayInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.access_management.execution_arn}/*/${each.value.http_method}/*"
}
```

### File: terraform/modules/api-gateway-access-management/modules/api-method/main.tf

```hcl
#------------------------------------------------------------------------------
# API Method Module - Reusable Lambda Integration
# Description: Creates API Gateway method with Lambda proxy integration
#------------------------------------------------------------------------------

variable "rest_api_id" {
  description = "API Gateway REST API ID"
  type        = string
}

variable "resource_id" {
  description = "API Gateway resource ID"
  type        = string
}

variable "http_method" {
  description = "HTTP method (GET, POST, PUT, DELETE)"
  type        = string
}

variable "authorization" {
  description = "Authorization type (NONE, CUSTOM, COGNITO_USER_POOLS)"
  type        = string
  default     = "CUSTOM"
}

variable "authorizer_id" {
  description = "Authorizer ID (required if authorization is CUSTOM)"
  type        = string
  default     = null
}

variable "lambda_invoke_arn" {
  description = "Lambda function invoke ARN"
  type        = string
}

variable "lambda_function_name" {
  description = "Lambda function name"
  type        = string
}

variable "request_parameters" {
  description = "Map of request parameters"
  type        = map(bool)
  default     = {}
}

variable "request_validator_id" {
  description = "Request validator ID"
  type        = string
  default     = null
}

variable "api_gateway_execution_arn" {
  description = "API Gateway execution ARN for Lambda permissions"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, sit, prod)"
  type        = string
}

#------------------------------------------------------------------------------
# API GATEWAY METHOD
#------------------------------------------------------------------------------

resource "aws_api_gateway_method" "this" {
  rest_api_id          = var.rest_api_id
  resource_id          = var.resource_id
  http_method          = var.http_method
  authorization        = var.authorization
  authorizer_id        = var.authorizer_id
  request_parameters   = var.request_parameters
  request_validator_id = var.request_validator_id

  # API Key not required (using JWT auth)
  api_key_required = false
}

#------------------------------------------------------------------------------
# LAMBDA PROXY INTEGRATION
#------------------------------------------------------------------------------

resource "aws_api_gateway_integration" "this" {
  rest_api_id             = var.rest_api_id
  resource_id             = var.resource_id
  http_method             = aws_api_gateway_method.this.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn

  # Timeout configuration
  timeout_milliseconds = 29000  # API Gateway max is 29 seconds
}

#------------------------------------------------------------------------------
# METHOD RESPONSE
#------------------------------------------------------------------------------

resource "aws_api_gateway_method_response" "success" {
  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = aws_api_gateway_method.this.http_method
  status_code = var.http_method == "POST" ? "201" : var.http_method == "DELETE" ? "204" : "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.X-Request-ID"                 = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "error_400" {
  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = aws_api_gateway_method.this.http_method
  status_code = "400"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.X-Request-ID"                = true
  }

  response_models = {
    "application/json" = "Error"
  }
}

resource "aws_api_gateway_method_response" "error_401" {
  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = aws_api_gateway_method.this.http_method
  status_code = "401"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.X-Request-ID"                = true
  }
}

resource "aws_api_gateway_method_response" "error_403" {
  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = aws_api_gateway_method.this.http_method
  status_code = "403"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.X-Request-ID"                = true
  }
}

resource "aws_api_gateway_method_response" "error_404" {
  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = aws_api_gateway_method.this.http_method
  status_code = "404"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.X-Request-ID"                = true
  }
}

resource "aws_api_gateway_method_response" "error_500" {
  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = aws_api_gateway_method.this.http_method
  status_code = "500"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.X-Request-ID"                = true
  }
}

#------------------------------------------------------------------------------
# OUTPUTS
#------------------------------------------------------------------------------

output "method_id" {
  description = "API Gateway method ID"
  value       = aws_api_gateway_method.this.id
}

output "integration_id" {
  description = "API Gateway integration ID"
  value       = aws_api_gateway_integration.this.id
}
```

### File: terraform/modules/api-gateway-access-management/team_variables.tf

```hcl
#------------------------------------------------------------------------------
# Team Service Lambda Variables
# Description: Input variables for Team Service Lambda function ARNs and names
#------------------------------------------------------------------------------

variable "lambda_arns" {
  description = "Map of Lambda function ARNs by service"
  type = object({
    team = object({
      create_team       = string
      list_teams        = string
      get_team          = string
      update_team       = string
      create_team_role  = string
      list_team_roles   = string
      get_team_role     = string
      update_team_role  = string
      delete_team_role  = string
      add_member        = string
      list_members      = string
      get_member        = string
      update_member     = string
      get_user_teams    = string
    })
    # Other services...
  })
}

variable "lambda_names" {
  description = "Map of Lambda function names by service"
  type = object({
    team = object({
      create_team       = string
      list_teams        = string
      get_team          = string
      update_team       = string
      create_team_role  = string
      list_team_roles   = string
      get_team_role     = string
      update_team_role  = string
      delete_team_role  = string
      add_member        = string
      list_members      = string
      get_member        = string
      update_member     = string
      get_user_teams    = string
    })
    # Other services...
  })
}

#------------------------------------------------------------------------------
# LAMBDA FUNCTION NAMING CONVENTION
#------------------------------------------------------------------------------

# Lambda functions follow this naming pattern:
# bbws-access-{env}-team-{operation}
#
# Examples:
# - bbws-access-dev-team-create
# - bbws-access-dev-team-list
# - bbws-access-dev-team-get
# - bbws-access-dev-team-update
# - bbws-access-dev-team-role-create
# - bbws-access-dev-team-role-list
# - bbws-access-dev-team-role-get
# - bbws-access-dev-team-role-update
# - bbws-access-dev-team-role-delete
# - bbws-access-dev-team-member-add
# - bbws-access-dev-team-member-list
# - bbws-access-dev-team-member-get
# - bbws-access-dev-team-member-update
# - bbws-access-dev-team-user-teams
```

---

## 4. Request/Response Schemas

### 4.1 JSON Schema - Create Team Request

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://api.bbws.co.za/schemas/team/create-team-request.json",
  "title": "Create Team Request",
  "type": "object",
  "required": ["name"],
  "properties": {
    "name": {
      "type": "string",
      "minLength": 2,
      "maxLength": 100,
      "description": "Team name (unique within organisation)"
    },
    "description": {
      "type": "string",
      "maxLength": 500,
      "description": "Team description"
    },
    "divisionId": {
      "type": "string",
      "format": "uuid",
      "description": "Division ID for hierarchy placement"
    },
    "groupId": {
      "type": "string",
      "format": "uuid",
      "description": "Group ID for hierarchy placement"
    }
  },
  "additionalProperties": false
}
```

### 4.2 JSON Schema - Update Team Request

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://api.bbws.co.za/schemas/team/update-team-request.json",
  "title": "Update Team Request",
  "type": "object",
  "minProperties": 1,
  "properties": {
    "name": {
      "type": "string",
      "minLength": 2,
      "maxLength": 100,
      "description": "Team name"
    },
    "description": {
      "type": "string",
      "maxLength": 500,
      "description": "Team description"
    },
    "divisionId": {
      "type": ["string", "null"],
      "format": "uuid",
      "description": "Division ID (null to remove)"
    },
    "groupId": {
      "type": ["string", "null"],
      "format": "uuid",
      "description": "Group ID (null to remove)"
    },
    "active": {
      "type": "boolean",
      "description": "Team active status"
    }
  },
  "additionalProperties": false
}
```

### 4.3 JSON Schema - Create Team Role Request

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://api.bbws.co.za/schemas/team/create-team-role-request.json",
  "title": "Create Team Role Request",
  "type": "object",
  "required": ["name", "displayName", "capabilities"],
  "properties": {
    "name": {
      "type": "string",
      "pattern": "^[A-Z][A-Z0-9_]*$",
      "minLength": 2,
      "maxLength": 50,
      "description": "Role name (uppercase, underscores allowed)"
    },
    "displayName": {
      "type": "string",
      "minLength": 2,
      "maxLength": 100,
      "description": "Human-readable display name"
    },
    "description": {
      "type": "string",
      "maxLength": 500,
      "description": "Role description"
    },
    "capabilities": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": [
          "CAN_MANAGE_MEMBERS",
          "CAN_UPDATE_TEAM",
          "CAN_VIEW_MEMBERS",
          "CAN_VIEW_SITES",
          "CAN_EDIT_SITES",
          "CAN_DELETE_SITES",
          "CAN_VIEW_AUDIT"
        ]
      },
      "minItems": 1,
      "uniqueItems": true,
      "description": "List of capabilities granted by this role"
    },
    "sortOrder": {
      "type": "integer",
      "minimum": 0,
      "maximum": 1000,
      "default": 100,
      "description": "Sort order for display"
    }
  },
  "additionalProperties": false
}
```

### 4.4 JSON Schema - Update Team Role Request

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://api.bbws.co.za/schemas/team/update-team-role-request.json",
  "title": "Update Team Role Request",
  "type": "object",
  "minProperties": 1,
  "properties": {
    "displayName": {
      "type": "string",
      "minLength": 2,
      "maxLength": 100,
      "description": "Human-readable display name"
    },
    "description": {
      "type": "string",
      "maxLength": 500,
      "description": "Role description"
    },
    "capabilities": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": [
          "CAN_MANAGE_MEMBERS",
          "CAN_UPDATE_TEAM",
          "CAN_VIEW_MEMBERS",
          "CAN_VIEW_SITES",
          "CAN_EDIT_SITES",
          "CAN_DELETE_SITES",
          "CAN_VIEW_AUDIT"
        ]
      },
      "minItems": 1,
      "uniqueItems": true,
      "description": "List of capabilities"
    },
    "sortOrder": {
      "type": "integer",
      "minimum": 0,
      "maximum": 1000,
      "description": "Sort order for display"
    },
    "active": {
      "type": "boolean",
      "description": "Role active status"
    }
  },
  "additionalProperties": false
}
```

### 4.5 JSON Schema - Add Member Request

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://api.bbws.co.za/schemas/team/add-member-request.json",
  "title": "Add Team Member Request",
  "type": "object",
  "required": ["userId", "teamRoleId"],
  "properties": {
    "userId": {
      "type": "string",
      "format": "uuid",
      "description": "User ID to add to the team"
    },
    "teamRoleId": {
      "type": "string",
      "format": "uuid",
      "description": "Team role to assign to the member"
    }
  },
  "additionalProperties": false
}
```

### 4.6 JSON Schema - Update Member Request

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://api.bbws.co.za/schemas/team/update-member-request.json",
  "title": "Update Team Member Request",
  "type": "object",
  "minProperties": 1,
  "properties": {
    "teamRoleId": {
      "type": "string",
      "format": "uuid",
      "description": "New team role ID"
    },
    "active": {
      "type": "boolean",
      "description": "Member active status"
    }
  },
  "additionalProperties": false
}
```

### 4.7 JSON Schema - Team Response

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://api.bbws.co.za/schemas/team/team-response.json",
  "title": "Team Response",
  "type": "object",
  "properties": {
    "id": {
      "type": "string",
      "format": "uuid",
      "description": "Team ID"
    },
    "teamId": {
      "type": "string",
      "format": "uuid",
      "description": "Team ID (alias)"
    },
    "name": {
      "type": "string",
      "description": "Team name"
    },
    "description": {
      "type": "string",
      "description": "Team description"
    },
    "organisationId": {
      "type": "string",
      "format": "uuid",
      "description": "Organisation ID"
    },
    "divisionId": {
      "type": ["string", "null"],
      "format": "uuid",
      "description": "Division ID"
    },
    "groupId": {
      "type": ["string", "null"],
      "format": "uuid",
      "description": "Group ID"
    },
    "memberCount": {
      "type": "integer",
      "minimum": 0,
      "description": "Number of active members"
    },
    "siteCount": {
      "type": "integer",
      "minimum": 0,
      "description": "Number of WordPress sites"
    },
    "active": {
      "type": "boolean",
      "description": "Team active status"
    },
    "dateCreated": {
      "type": "string",
      "format": "date-time",
      "description": "Creation timestamp"
    },
    "dateLastUpdated": {
      "type": "string",
      "format": "date-time",
      "description": "Last update timestamp"
    },
    "createdBy": {
      "type": "string",
      "description": "User ID who created the team"
    },
    "lastUpdatedBy": {
      "type": "string",
      "description": "User ID who last updated the team"
    },
    "_links": {
      "type": "object",
      "properties": {
        "self": {
          "type": "object",
          "properties": {
            "href": { "type": "string", "format": "uri" }
          }
        },
        "members": {
          "type": "object",
          "properties": {
            "href": { "type": "string", "format": "uri" }
          }
        },
        "organisation": {
          "type": "object",
          "properties": {
            "href": { "type": "string", "format": "uri" }
          }
        }
      }
    }
  }
}
```

### 4.8 JSON Schema - Error Response

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://api.bbws.co.za/schemas/common/error-response.json",
  "title": "Error Response",
  "type": "object",
  "required": ["error", "message"],
  "properties": {
    "error": {
      "type": "string",
      "description": "Error code",
      "enum": [
        "VALIDATION_ERROR",
        "UNAUTHORIZED",
        "FORBIDDEN",
        "NOT_FOUND",
        "CONFLICT",
        "INTERNAL_ERROR"
      ]
    },
    "message": {
      "type": "string",
      "description": "Human-readable error message"
    },
    "details": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "field": {
            "type": "string",
            "description": "Field that caused the error"
          },
          "message": {
            "type": "string",
            "description": "Error message for this field"
          },
          "code": {
            "type": "string",
            "description": "Error code"
          }
        }
      },
      "description": "Detailed validation errors"
    },
    "requestId": {
      "type": "string",
      "format": "uuid",
      "description": "Request ID for support"
    }
  }
}
```

---

## 5. CORS Configuration

### File: terraform/modules/api-gateway-access-management/team_cors.tf

```hcl
#------------------------------------------------------------------------------
# CORS Configuration for Team Service Routes
# Description: OPTIONS methods for CORS preflight requests
#------------------------------------------------------------------------------

#==============================================================================
# CORS CONFIGURATION FOR TEAM ENDPOINTS
#==============================================================================

# CORS for /v1/organisations/{orgId}/teams
resource "aws_api_gateway_method" "teams_options" {
  rest_api_id   = aws_api_gateway_rest_api.access_management.id
  resource_id   = aws_api_gateway_resource.teams.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "teams_options" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.teams.id
  http_method = aws_api_gateway_method.teams_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

resource "aws_api_gateway_method_response" "teams_options" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.teams.id
  http_method = aws_api_gateway_method.teams_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Max-Age"       = true
  }
}

resource "aws_api_gateway_integration_response" "teams_options" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.teams.id
  http_method = aws_api_gateway_method.teams_options.http_method
  status_code = aws_api_gateway_method_response.teams_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Request-ID'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Max-Age"       = "'86400'"
  }
}

# CORS for /v1/organisations/{orgId}/teams/{teamId}
resource "aws_api_gateway_method" "teams_id_options" {
  rest_api_id   = aws_api_gateway_rest_api.access_management.id
  resource_id   = aws_api_gateway_resource.teams_id.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "teams_id_options" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.teams_id.id
  http_method = aws_api_gateway_method.teams_id_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

resource "aws_api_gateway_method_response" "teams_id_options" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.teams_id.id
  http_method = aws_api_gateway_method.teams_id_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Max-Age"       = true
  }
}

resource "aws_api_gateway_integration_response" "teams_id_options" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.teams_id.id
  http_method = aws_api_gateway_method.teams_id_options.http_method
  status_code = aws_api_gateway_method_response.teams_id_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Request-ID'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,PUT,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Max-Age"       = "'86400'"
  }
}

# CORS for /v1/organisations/{orgId}/team-roles
resource "aws_api_gateway_method" "team_roles_options" {
  rest_api_id   = aws_api_gateway_rest_api.access_management.id
  resource_id   = aws_api_gateway_resource.team_roles.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "team_roles_options" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.team_roles.id
  http_method = aws_api_gateway_method.team_roles_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

resource "aws_api_gateway_method_response" "team_roles_options" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.team_roles.id
  http_method = aws_api_gateway_method.team_roles_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Max-Age"       = true
  }
}

resource "aws_api_gateway_integration_response" "team_roles_options" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.team_roles.id
  http_method = aws_api_gateway_method.team_roles_options.http_method
  status_code = aws_api_gateway_method_response.team_roles_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Request-ID'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Max-Age"       = "'86400'"
  }
}

# CORS for /v1/organisations/{orgId}/team-roles/{teamRoleId}
resource "aws_api_gateway_method" "team_roles_id_options" {
  rest_api_id   = aws_api_gateway_rest_api.access_management.id
  resource_id   = aws_api_gateway_resource.team_roles_id.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "team_roles_id_options" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.team_roles_id.id
  http_method = aws_api_gateway_method.team_roles_id_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

resource "aws_api_gateway_method_response" "team_roles_id_options" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.team_roles_id.id
  http_method = aws_api_gateway_method.team_roles_id_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Max-Age"       = true
  }
}

resource "aws_api_gateway_integration_response" "team_roles_id_options" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.team_roles_id.id
  http_method = aws_api_gateway_method.team_roles_id_options.http_method
  status_code = aws_api_gateway_method_response.team_roles_id_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Request-ID'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Max-Age"       = "'86400'"
  }
}

# CORS for /v1/organisations/{orgId}/teams/{teamId}/members
resource "aws_api_gateway_method" "team_members_options" {
  rest_api_id   = aws_api_gateway_rest_api.access_management.id
  resource_id   = aws_api_gateway_resource.team_members.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "team_members_options" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.team_members.id
  http_method = aws_api_gateway_method.team_members_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

resource "aws_api_gateway_method_response" "team_members_options" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.team_members.id
  http_method = aws_api_gateway_method.team_members_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Max-Age"       = true
  }
}

resource "aws_api_gateway_integration_response" "team_members_options" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.team_members.id
  http_method = aws_api_gateway_method.team_members_options.http_method
  status_code = aws_api_gateway_method_response.team_members_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Request-ID'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Max-Age"       = "'86400'"
  }
}

# CORS for /v1/organisations/{orgId}/teams/{teamId}/members/{userId}
resource "aws_api_gateway_method" "team_members_id_options" {
  rest_api_id   = aws_api_gateway_rest_api.access_management.id
  resource_id   = aws_api_gateway_resource.team_members_id.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "team_members_id_options" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.team_members_id.id
  http_method = aws_api_gateway_method.team_members_id_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

resource "aws_api_gateway_method_response" "team_members_id_options" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.team_members_id.id
  http_method = aws_api_gateway_method.team_members_id_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Max-Age"       = true
  }
}

resource "aws_api_gateway_integration_response" "team_members_id_options" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.team_members_id.id
  http_method = aws_api_gateway_method.team_members_id_options.http_method
  status_code = aws_api_gateway_method_response.team_members_id_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Request-ID'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,PUT,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Max-Age"       = "'86400'"
  }
}

# CORS for /v1/organisations/{orgId}/users/{userId}/teams
resource "aws_api_gateway_method" "users_teams_options" {
  rest_api_id   = aws_api_gateway_rest_api.access_management.id
  resource_id   = aws_api_gateway_resource.users_teams.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "users_teams_options" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.users_teams.id
  http_method = aws_api_gateway_method.users_teams_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

resource "aws_api_gateway_method_response" "users_teams_options" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.users_teams.id
  http_method = aws_api_gateway_method.users_teams_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Max-Age"       = true
  }
}

resource "aws_api_gateway_integration_response" "users_teams_options" {
  rest_api_id = aws_api_gateway_rest_api.access_management.id
  resource_id = aws_api_gateway_resource.users_teams.id
  http_method = aws_api_gateway_method.users_teams_options.http_method
  status_code = aws_api_gateway_method_response.users_teams_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Request-ID'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Max-Age"       = "'86400'"
  }
}
```

### CORS Headers Summary

| Header | Value |
|--------|-------|
| Access-Control-Allow-Origin | * |
| Access-Control-Allow-Methods | GET, POST, PUT, DELETE, OPTIONS |
| Access-Control-Allow-Headers | Content-Type, Authorization, X-Request-ID |
| Access-Control-Max-Age | 86400 (24 hours) |

---

## 6. Success Criteria

### Checklist

| Criterion | Status |
|-----------|--------|
| All 14 routes configured | COMPLETE |
| Lambda authorizer attached to all routes | COMPLETE |
| Nested paths handled correctly | COMPLETE |
| CORS enabled on all endpoints | COMPLETE |
| OpenAPI 3.0 spec complete | COMPLETE |
| Request/response schemas defined | COMPLETE |
| Path parameter validation configured | COMPLETE |
| Query parameter validation configured | COMPLETE |
| Environment parameterisation (dev/sit/prod) | COMPLETE |

### Route Summary

| Category | Endpoints | Methods | Status |
|----------|-----------|---------|--------|
| Team Operations | 2 paths | 4 methods | COMPLETE |
| Team Role Operations | 2 paths | 5 methods | COMPLETE |
| Member Operations | 3 paths | 5 methods | COMPLETE |
| **Total** | **7 unique paths** | **14 methods** | **COMPLETE** |

### Files Delivered

| File | Description |
|------|-------------|
| api-specs/team-service.yaml | OpenAPI 3.0 specification |
| team_routes.tf | Terraform route configuration |
| team_cors.tf | CORS configuration |
| team_variables.tf | Lambda variable definitions |
| modules/api-method/main.tf | Reusable API method module |
| JSON schemas (8 files) | Request/response validation schemas |

---

**Worker Status**: COMPLETE
**Completed**: 2026-01-23
