# Worker 2 Output: Invitation API Routes Configuration

**Worker ID**: worker-2-invitation-api-routes
**Stage**: Stage 4 - API Gateway Integration
**Project**: project-plan-2-access-management
**Status**: COMPLETE
**Date**: 2026-01-23

---

## Executive Summary

This document provides complete API Gateway configuration for the Invitation Service with 8 endpoints:
- **5 Authenticated endpoints** (with Lambda Authorizer)
- **3 Public endpoints** (NO authorizer - for invitation acceptance flow)

---

## Table of Contents

1. [Endpoint Summary](#1-endpoint-summary)
2. [OpenAPI 3.0 Specification](#2-openapi-30-specification)
3. [Terraform Route Configuration](#3-terraform-route-configuration)
4. [Request/Response JSON Schemas](#4-requestresponse-json-schemas)
5. [CORS Configuration](#5-cors-configuration)
6. [Success Criteria Verification](#6-success-criteria-verification)

---

## 1. Endpoint Summary

### Authenticated Endpoints (5) - WITH Authorizer

| # | Method | Path | Lambda Handler | Permission Required |
|---|--------|------|----------------|---------------------|
| 1 | POST | /v1/orgs/{orgId}/invitations | create_invitation | invitation:create |
| 2 | GET | /v1/orgs/{orgId}/invitations | list_invitations | invitation:read |
| 3 | GET | /v1/orgs/{orgId}/invitations/{invitationId} | get_invitation | invitation:read |
| 4 | DELETE | /v1/orgs/{orgId}/invitations/{invitationId} | cancel_invitation | invitation:revoke |
| 5 | POST | /v1/orgs/{orgId}/invitations/{invitationId}/resend | resend_invitation | invitation:create |

### Public Endpoints (3) - NO Authorizer

| # | Method | Path | Lambda Handler | Notes |
|---|--------|------|----------------|-------|
| 6 | GET | /v1/invitations/{token} | get_invitation_by_token | View invitation details |
| 7 | POST | /v1/invitations/accept | accept_invitation | Accept and register |
| 8 | POST | /v1/invitations/{token}/decline | decline_invitation | Decline invitation |

---

## 2. OpenAPI 3.0 Specification

### File: `api-specs/invitation-service.yaml`

```yaml
openapi: 3.0.3
info:
  title: BBWS Invitation Service API
  description: |
    Invitation Service API for the BBWS Multi-Tenant Access Management System.

    This service manages user invitations to organisations with:
    - 5 authenticated endpoints (organisation admin operations)
    - 3 public endpoints (invitation acceptance flow)

    ## Authentication
    Authenticated endpoints require a valid JWT Bearer token.
    Public endpoints do NOT require authentication.

    ## Invitation Lifecycle
    - PENDING -> ACCEPTED (user accepts)
    - PENDING -> DECLINED (user declines)
    - PENDING -> CANCELLED (admin cancels)
    - PENDING -> EXPIRED (TTL expires)
  version: 1.0.0
  contact:
    name: BBWS Platform Team
    email: platform@bbws.co.za
  license:
    name: Proprietary
    url: https://bbws.co.za/license

servers:
  - url: https://api.dev.bbws.co.za
    description: DEV Environment
  - url: https://api.sit.bbws.co.za
    description: SIT Environment
  - url: https://api.bbws.co.za
    description: PROD Environment

tags:
  - name: Invitations (Admin)
    description: Organisation admin invitation management
  - name: Invitations (Public)
    description: Public invitation acceptance endpoints

paths:
  # ============================================================
  # AUTHENTICATED ENDPOINTS (WITH AUTHORIZER)
  # ============================================================

  /v1/orgs/{orgId}/invitations:
    post:
      tags:
        - Invitations (Admin)
      operationId: createInvitation
      summary: Create a new invitation
      description: |
        Create a new invitation to join the organisation.

        Requires `invitation:create` permission.

        The invitation will:
        - Send an email to the invitee
        - Expire after 7 days
        - Can be resent up to 3 times
      security:
        - bearerAuth: []
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
        - $ref: '#/components/parameters/RequestId'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateInvitationRequest'
            examples:
              withTeam:
                summary: Invitation with team assignment
                value:
                  email: "john.doe@example.com"
                  roleId: "role-team-member"
                  teamId: "team-engineering"
                  message: "Welcome to the team! We look forward to working with you."
              withoutTeam:
                summary: Invitation without team
                value:
                  email: "jane.doe@example.com"
                  roleId: "role-org-admin"
      responses:
        '201':
          description: Invitation created successfully
          headers:
            X-Request-ID:
              $ref: '#/components/headers/X-Request-ID'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/InvitationResponse'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '409':
          description: Conflict - Duplicate invitation or user already member
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
              examples:
                duplicateInvitation:
                  value:
                    errorCode: "DUPLICATE_INVITATION"
                    message: "Pending invitation already exists for john.doe@example.com"
                    details:
                      email: "john.doe@example.com"
                      organisationId: "org-550e8400"
                userAlreadyMember:
                  value:
                    errorCode: "USER_ALREADY_MEMBER"
                    message: "User john.doe@example.com is already a member of this organisation"
        '500':
          $ref: '#/components/responses/InternalServerError'

    get:
      tags:
        - Invitations (Admin)
      operationId: listInvitations
      summary: List invitations for organisation
      description: |
        Retrieve all invitations for the organisation with optional filters.

        Requires `invitation:read` permission.

        Results are paginated and sorted by creation date (newest first).
      security:
        - bearerAuth: []
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
        - $ref: '#/components/parameters/RequestId'
        - name: status
          in: query
          description: Filter by invitation status
          schema:
            type: string
            enum: [PENDING, ACCEPTED, DECLINED, EXPIRED, CANCELLED]
        - name: email
          in: query
          description: Filter by invitee email (partial match)
          schema:
            type: string
            format: email
        - name: teamId
          in: query
          description: Filter by team assignment
          schema:
            type: string
        - name: limit
          in: query
          description: Maximum number of results to return
          schema:
            type: integer
            minimum: 1
            maximum: 100
            default: 20
        - name: nextToken
          in: query
          description: Pagination token from previous response
          schema:
            type: string
      responses:
        '200':
          description: List of invitations
          headers:
            X-Request-ID:
              $ref: '#/components/headers/X-Request-ID'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/InvitationListResponse'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '500':
          $ref: '#/components/responses/InternalServerError'

  /v1/orgs/{orgId}/invitations/{invitationId}:
    get:
      tags:
        - Invitations (Admin)
      operationId: getInvitation
      summary: Get invitation details
      description: |
        Retrieve detailed information about a specific invitation.

        Requires `invitation:read` permission.
      security:
        - bearerAuth: []
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
        - $ref: '#/components/parameters/InvitationIdPath'
        - $ref: '#/components/parameters/RequestId'
      responses:
        '200':
          description: Invitation details
          headers:
            X-Request-ID:
              $ref: '#/components/headers/X-Request-ID'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/InvitationResponse'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '404':
          $ref: '#/components/responses/NotFound'
        '500':
          $ref: '#/components/responses/InternalServerError'

    delete:
      tags:
        - Invitations (Admin)
      operationId: cancelInvitation
      summary: Cancel/revoke an invitation
      description: |
        Cancel a pending invitation. Only pending invitations can be cancelled.

        Requires `invitation:revoke` permission.

        This is a soft delete - the invitation record is preserved for audit purposes.
      security:
        - bearerAuth: []
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
        - $ref: '#/components/parameters/InvitationIdPath'
        - $ref: '#/components/parameters/RequestId'
      responses:
        '204':
          description: Invitation cancelled successfully
          headers:
            X-Request-ID:
              $ref: '#/components/headers/X-Request-ID'
        '400':
          description: Bad Request - Invalid state transition
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
              example:
                errorCode: "INVALID_STATE"
                message: "Cannot cancel invitation in status ACCEPTED"
                details:
                  currentStatus: "ACCEPTED"
                  attemptedAction: "cancel"
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '404':
          $ref: '#/components/responses/NotFound'
        '500':
          $ref: '#/components/responses/InternalServerError'

  /v1/orgs/{orgId}/invitations/{invitationId}/resend:
    post:
      tags:
        - Invitations (Admin)
      operationId: resendInvitation
      summary: Resend invitation email
      description: |
        Resend the invitation email with a new token and extended expiry.

        Requires `invitation:create` permission.

        Limitations:
        - Maximum 3 resends per invitation
        - Only PENDING invitations can be resent
        - Extends expiry by 7 days from current time
      security:
        - bearerAuth: []
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
        - $ref: '#/components/parameters/InvitationIdPath'
        - $ref: '#/components/parameters/RequestId'
      responses:
        '200':
          description: Invitation resent successfully
          headers:
            X-Request-ID:
              $ref: '#/components/headers/X-Request-ID'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/InvitationResponse'
        '400':
          description: Bad Request - Invalid state or resend limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
              examples:
                invalidState:
                  value:
                    errorCode: "INVALID_STATE"
                    message: "Cannot resend invitation in status ACCEPTED"
                resendLimit:
                  value:
                    errorCode: "RESEND_LIMIT_EXCEEDED"
                    message: "Maximum resend limit (3) exceeded"
                    details:
                      invitationId: "inv-123"
                      resendCount: 3
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '404':
          $ref: '#/components/responses/NotFound'
        '500':
          $ref: '#/components/responses/InternalServerError'

  # ============================================================
  # PUBLIC ENDPOINTS (NO AUTHORIZER)
  # ============================================================

  /v1/invitations/{token}:
    get:
      tags:
        - Invitations (Public)
      operationId: getInvitationByToken
      summary: Get public invitation details
      description: |
        Retrieve public invitation details using the invitation token.

        **NO AUTHENTICATION REQUIRED**

        Returns limited information suitable for the invitation acceptance page:
        - Organisation name
        - Role being assigned
        - Team being assigned (if any)
        - Inviter name
        - Personal message
        - Expiry status
        - Whether password is required (new user registration)
      security: []  # NO AUTHENTICATION
      parameters:
        - $ref: '#/components/parameters/TokenPath'
        - $ref: '#/components/parameters/RequestId'
      responses:
        '200':
          description: Public invitation details
          headers:
            X-Request-ID:
              $ref: '#/components/headers/X-Request-ID'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/InvitationPublicResponse'
        '404':
          description: Invitation not found or invalid token
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
              example:
                errorCode: "NOT_FOUND"
                message: "Invitation not found"
        '410':
          description: Invitation has expired
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
              example:
                errorCode: "EXPIRED"
                message: "Invitation has expired"
                details:
                  expiresAt: "2026-01-16T00:00:00Z"
        '500':
          $ref: '#/components/responses/InternalServerError'

  /v1/invitations/accept:
    post:
      tags:
        - Invitations (Public)
      operationId: acceptInvitation
      summary: Accept an invitation
      description: |
        Accept an invitation and join the organisation.

        **NO AUTHENTICATION REQUIRED**

        For new users:
        - Creates a Cognito user account
        - Requires firstName, lastName, and password

        For existing users:
        - Adds user to the organisation
        - firstName, lastName, and password are ignored

        Returns:
        - User ID
        - Organisation details
        - Role and team assignments
        - List of permissions
      security: []  # NO AUTHENTICATION
      parameters:
        - $ref: '#/components/parameters/RequestId'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/AcceptInvitationRequest'
            examples:
              newUser:
                summary: New user registration
                value:
                  token: "inv_abc123xyz789..."
                  firstName: "John"
                  lastName: "Doe"
                  password: "SecureP@ssw0rd!"
              existingUser:
                summary: Existing user joining org
                value:
                  token: "inv_abc123xyz789..."
      responses:
        '200':
          description: Invitation accepted successfully
          headers:
            X-Request-ID:
              $ref: '#/components/headers/X-Request-ID'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/AcceptInvitationResponse'
        '400':
          description: Bad Request - Validation error or invalid state
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
              examples:
                passwordRequired:
                  value:
                    errorCode: "PASSWORD_REQUIRED"
                    message: "Password is required for new user registration"
                invalidPassword:
                  value:
                    errorCode: "INVALID_PASSWORD"
                    message: "Password must contain at least one uppercase letter"
                alreadyUsed:
                  value:
                    errorCode: "ALREADY_USED"
                    message: "Invitation has already been accepted"
        '404':
          $ref: '#/components/responses/NotFound'
        '410':
          description: Invitation has expired
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '500':
          $ref: '#/components/responses/InternalServerError'

  /v1/invitations/{token}/decline:
    post:
      tags:
        - Invitations (Public)
      operationId: declineInvitation
      summary: Decline an invitation
      description: |
        Decline an invitation to join the organisation.

        **NO AUTHENTICATION REQUIRED**

        The invitee can optionally provide a reason for declining.
      security: []  # NO AUTHENTICATION
      parameters:
        - $ref: '#/components/parameters/TokenPath'
        - $ref: '#/components/parameters/RequestId'
      requestBody:
        required: false
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/DeclineInvitationRequest'
            example:
              reason: "I've accepted a position at another company."
      responses:
        '200':
          description: Invitation declined successfully
          headers:
            X-Request-ID:
              $ref: '#/components/headers/X-Request-ID'
          content:
            application/json:
              schema:
                type: object
                properties:
                  message:
                    type: string
                    example: "Invitation declined successfully"
                  status:
                    type: string
                    enum: [DECLINED]
        '400':
          description: Bad Request - Invalid state
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '404':
          $ref: '#/components/responses/NotFound'
        '410':
          description: Invitation has expired
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '500':
          $ref: '#/components/responses/InternalServerError'

components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: |
        JWT access token from Cognito.

        Format: `Bearer <token>`

        The token must contain:
        - `sub` - User ID
        - `custom:organisation_id` - Organisation ID

  parameters:
    OrgIdPath:
      name: orgId
      in: path
      required: true
      description: Organisation UUID
      schema:
        type: string
        format: uuid
        pattern: '^org-[a-f0-9-]{36}$'
      example: "org-550e8400-e29b-41d4-a716-446655440000"

    InvitationIdPath:
      name: invitationId
      in: path
      required: true
      description: Invitation UUID
      schema:
        type: string
        pattern: '^inv-[a-f0-9-]{36}$'
      example: "inv-770e8400-e29b-41d4-a716-446655440001"

    TokenPath:
      name: token
      in: path
      required: true
      description: Invitation token (URL-safe base64)
      schema:
        type: string
        minLength: 32
        maxLength: 128
      example: "inv_abc123xyz789def456ghi012jkl345mno678pqr901"

    RequestId:
      name: X-Request-ID
      in: header
      required: false
      description: Request correlation ID for tracing
      schema:
        type: string
        format: uuid
      example: "req-123e4567-e89b-12d3-a456-426614174000"

  headers:
    X-Request-ID:
      description: Request correlation ID
      schema:
        type: string
        format: uuid

  schemas:
    # ==================== REQUEST SCHEMAS ====================

    CreateInvitationRequest:
      type: object
      required:
        - email
        - roleId
      properties:
        email:
          type: string
          format: email
          description: Email address of the invitee
          maxLength: 255
          example: "john.doe@example.com"
        roleId:
          type: string
          description: Role to assign to the invitee
          example: "role-team-member"
        teamId:
          type: string
          description: Team to assign the invitee to (optional)
          example: "team-engineering"
        message:
          type: string
          description: Personal message to include in the invitation email
          maxLength: 500
          example: "Welcome to the team! We look forward to working with you."

    AcceptInvitationRequest:
      type: object
      required:
        - token
      properties:
        token:
          type: string
          description: Invitation token from the invitation URL
          minLength: 32
          maxLength: 128
          example: "inv_abc123xyz789..."
        firstName:
          type: string
          description: First name (required for new users)
          minLength: 1
          maxLength: 50
          example: "John"
        lastName:
          type: string
          description: Last name (required for new users)
          minLength: 1
          maxLength: 50
          example: "Doe"
        password:
          type: string
          format: password
          description: |
            Password (required for new users).

            Requirements:
            - 8-128 characters
            - At least one uppercase letter
            - At least one lowercase letter
            - At least one digit
            - At least one special character (!@#$%^&*()_+-=[]{}|;:,.<>?)
          minLength: 8
          maxLength: 128
          example: "SecureP@ssw0rd!"

    DeclineInvitationRequest:
      type: object
      properties:
        reason:
          type: string
          description: Optional reason for declining
          maxLength: 500
          example: "I've accepted a position at another company."

    # ==================== RESPONSE SCHEMAS ====================

    InvitationResponse:
      type: object
      properties:
        id:
          type: string
          description: Invitation ID
          example: "inv-770e8400-e29b-41d4-a716-446655440001"
        email:
          type: string
          format: email
          description: Invitee email address
          example: "john.doe@example.com"
        organisationId:
          type: string
          description: Organisation ID
          example: "org-550e8400-e29b-41d4-a716-446655440000"
        organisationName:
          type: string
          description: Organisation name
          example: "Acme Corporation"
        roleId:
          type: string
          description: Assigned role ID
          example: "role-team-member"
        roleName:
          type: string
          description: Assigned role name
          example: "Team Member"
        teamId:
          type: string
          nullable: true
          description: Assigned team ID (if any)
          example: "team-engineering"
        teamName:
          type: string
          nullable: true
          description: Assigned team name (if any)
          example: "Engineering"
        message:
          type: string
          nullable: true
          description: Personal message from inviter
        status:
          type: string
          enum: [PENDING, ACCEPTED, DECLINED, EXPIRED, CANCELLED]
          description: Current invitation status
          example: "PENDING"
        expiresAt:
          type: string
          format: date-time
          description: Invitation expiry timestamp
          example: "2026-01-30T00:00:00Z"
        resendCount:
          type: integer
          minimum: 0
          maximum: 3
          description: Number of times invitation has been resent
          example: 0
        active:
          type: boolean
          description: Whether invitation is active (not soft-deleted)
          example: true
        dateCreated:
          type: string
          format: date-time
          description: Creation timestamp
          example: "2026-01-23T10:30:00Z"
        createdBy:
          type: string
          description: Email of user who created the invitation
          example: "admin@example.com"
        acceptedAt:
          type: string
          format: date-time
          nullable: true
          description: Acceptance timestamp (if accepted)
        declinedAt:
          type: string
          format: date-time
          nullable: true
          description: Decline timestamp (if declined)
        declineReason:
          type: string
          nullable: true
          description: Reason for declining (if declined)
        _links:
          $ref: '#/components/schemas/HATEOASLinks'

    InvitationListResponse:
      type: object
      properties:
        items:
          type: array
          items:
            $ref: '#/components/schemas/InvitationResponse'
        count:
          type: integer
          description: Number of items in this response
          example: 10
        nextToken:
          type: string
          nullable: true
          description: Pagination token for next page
        _links:
          $ref: '#/components/schemas/HATEOASLinks'

    InvitationPublicResponse:
      type: object
      description: Public view of invitation (limited info)
      properties:
        organisationName:
          type: string
          description: Name of the organisation
          example: "Acme Corporation"
        roleName:
          type: string
          description: Name of the role being assigned
          example: "Team Member"
        teamName:
          type: string
          nullable: true
          description: Name of the team (if any)
          example: "Engineering"
        inviterName:
          type: string
          description: Name of the person who sent the invitation
          example: "Jane Admin"
        message:
          type: string
          nullable: true
          description: Personal message from the inviter
        expiresAt:
          type: string
          format: date-time
          description: When the invitation expires
          example: "2026-01-30T00:00:00Z"
        isExpired:
          type: boolean
          description: Whether the invitation has expired
          example: false
        requiresPassword:
          type: boolean
          description: |
            Whether password is required to accept.
            True if the invitee email does not have an existing Cognito account.
          example: true

    AcceptInvitationResponse:
      type: object
      properties:
        userId:
          type: string
          description: The user's ID (Cognito sub)
          example: "user-770e8400-e29b-41d4-a716-446655440003"
        organisationId:
          type: string
          description: Organisation the user joined
          example: "org-550e8400-e29b-41d4-a716-446655440000"
        organisationName:
          type: string
          description: Name of the organisation
          example: "Acme Corporation"
        roleId:
          type: string
          description: Role assigned to the user
          example: "role-team-member"
        roleName:
          type: string
          description: Name of the assigned role
          example: "Team Member"
        teamId:
          type: string
          nullable: true
          description: Team the user was added to (if any)
          example: "team-engineering"
        teamName:
          type: string
          nullable: true
          description: Name of the team
          example: "Engineering"
        permissions:
          type: array
          items:
            type: string
          description: List of permissions granted through the role
          example: ["site:read", "site:update", "team:read"]
        isNewUser:
          type: boolean
          description: Whether a new Cognito account was created
          example: true

    # ==================== COMMON SCHEMAS ====================

    HATEOASLinks:
      type: object
      additionalProperties:
        type: object
        properties:
          href:
            type: string
            format: uri
          method:
            type: string
            enum: [GET, POST, PUT, DELETE, PATCH]
      example:
        self:
          href: "/v1/orgs/org-123/invitations/inv-456"
          method: "GET"
        resend:
          href: "/v1/orgs/org-123/invitations/inv-456/resend"
          method: "POST"
        cancel:
          href: "/v1/orgs/org-123/invitations/inv-456"
          method: "DELETE"

    ErrorResponse:
      type: object
      required:
        - errorCode
        - message
      properties:
        errorCode:
          type: string
          description: Machine-readable error code
          example: "NOT_FOUND"
        message:
          type: string
          description: Human-readable error message
          example: "Invitation not found"
        details:
          type: object
          additionalProperties: true
          description: Additional error details
        requestId:
          type: string
          description: Request ID for support reference
          example: "req-123e4567-e89b-12d3-a456-426614174000"

  responses:
    BadRequest:
      description: Bad Request - Invalid input
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            errorCode: "VALIDATION_ERROR"
            message: "Invalid email format"

    Unauthorized:
      description: Unauthorized - Missing or invalid token
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            errorCode: "UNAUTHORIZED"
            message: "Authentication required"

    Forbidden:
      description: Forbidden - Insufficient permissions
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            errorCode: "FORBIDDEN"
            message: "Permission denied: requires invitation:create"

    NotFound:
      description: Not Found - Resource does not exist
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            errorCode: "NOT_FOUND"
            message: "Invitation not found"

    InternalServerError:
      description: Internal Server Error
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            errorCode: "INTERNAL_ERROR"
            message: "An unexpected error occurred"
            requestId: "req-123e4567-e89b-12d3-a456-426614174000"
```

---

## 3. Terraform Route Configuration

### File: `terraform/modules/api-gateway/routes/invitation_routes.tf`

```hcl
# =============================================================================
# INVITATION SERVICE API ROUTES
# =============================================================================
# Configures API Gateway routes for Invitation Service (8 endpoints)
# - 5 authenticated endpoints WITH Lambda Authorizer
# - 3 public endpoints WITHOUT authorizer
# =============================================================================

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "api_id" {
  description = "API Gateway REST API ID"
  type        = string
}

variable "root_resource_id" {
  description = "API Gateway root resource ID"
  type        = string
}

variable "authorizer_id" {
  description = "Lambda Authorizer ID"
  type        = string
}

variable "invitation_lambda_arn" {
  description = "Map of Lambda ARNs for invitation handlers"
  type = object({
    create_invitation       = string
    list_invitations        = string
    get_invitation          = string
    cancel_invitation       = string
    resend_invitation       = string
    get_invitation_by_token = string
    accept_invitation       = string
    decline_invitation      = string
  })
}

variable "invitation_lambda_invoke_arn" {
  description = "Map of Lambda invoke ARNs for invitation handlers"
  type = object({
    create_invitation       = string
    list_invitations        = string
    get_invitation          = string
    cancel_invitation       = string
    resend_invitation       = string
    get_invitation_by_token = string
    accept_invitation       = string
    decline_invitation      = string
  })
}

variable "environment" {
  description = "Environment name (dev, sit, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "af-south-1"
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

locals {
  cors_headers = {
    "Access-Control-Allow-Origin"  = "'*'"
    "Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Request-ID'"
  }

  common_tags = {
    Service     = "invitation-service"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# =============================================================================
# AUTHENTICATED ROUTES (WITH AUTHORIZER)
# =============================================================================

# -----------------------------------------------------------------------------
# Resource: /v1
# -----------------------------------------------------------------------------

resource "aws_api_gateway_resource" "v1" {
  rest_api_id = var.api_id
  parent_id   = var.root_resource_id
  path_part   = "v1"
}

# -----------------------------------------------------------------------------
# Resource: /v1/orgs
# -----------------------------------------------------------------------------

resource "aws_api_gateway_resource" "orgs" {
  rest_api_id = var.api_id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "orgs"
}

# -----------------------------------------------------------------------------
# Resource: /v1/orgs/{orgId}
# -----------------------------------------------------------------------------

resource "aws_api_gateway_resource" "org_id" {
  rest_api_id = var.api_id
  parent_id   = aws_api_gateway_resource.orgs.id
  path_part   = "{orgId}"
}

# -----------------------------------------------------------------------------
# Resource: /v1/orgs/{orgId}/invitations
# -----------------------------------------------------------------------------

resource "aws_api_gateway_resource" "org_invitations" {
  rest_api_id = var.api_id
  parent_id   = aws_api_gateway_resource.org_id.id
  path_part   = "invitations"
}

# -----------------------------------------------------------------------------
# POST /v1/orgs/{orgId}/invitations - Create Invitation (Authenticated)
# -----------------------------------------------------------------------------

resource "aws_api_gateway_method" "create_invitation" {
  rest_api_id   = var.api_id
  resource_id   = aws_api_gateway_resource.org_invitations.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = var.authorizer_id

  request_parameters = {
    "method.request.path.orgId"             = true
    "method.request.header.X-Request-ID"    = false
    "method.request.header.Content-Type"    = true
  }

  request_validator_id = aws_api_gateway_request_validator.invitation_body_validator.id
}

resource "aws_api_gateway_integration" "create_invitation" {
  rest_api_id             = var.api_id
  resource_id             = aws_api_gateway_resource.org_invitations.id
  http_method             = aws_api_gateway_method.create_invitation.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.invitation_lambda_invoke_arn.create_invitation
}

# -----------------------------------------------------------------------------
# GET /v1/orgs/{orgId}/invitations - List Invitations (Authenticated)
# -----------------------------------------------------------------------------

resource "aws_api_gateway_method" "list_invitations" {
  rest_api_id   = var.api_id
  resource_id   = aws_api_gateway_resource.org_invitations.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = var.authorizer_id

  request_parameters = {
    "method.request.path.orgId"             = true
    "method.request.header.X-Request-ID"    = false
    "method.request.querystring.status"     = false
    "method.request.querystring.email"      = false
    "method.request.querystring.teamId"     = false
    "method.request.querystring.limit"      = false
    "method.request.querystring.nextToken"  = false
  }
}

resource "aws_api_gateway_integration" "list_invitations" {
  rest_api_id             = var.api_id
  resource_id             = aws_api_gateway_resource.org_invitations.id
  http_method             = aws_api_gateway_method.list_invitations.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.invitation_lambda_invoke_arn.list_invitations
}

# -----------------------------------------------------------------------------
# OPTIONS /v1/orgs/{orgId}/invitations - CORS Preflight
# -----------------------------------------------------------------------------

resource "aws_api_gateway_method" "org_invitations_options" {
  rest_api_id   = var.api_id
  resource_id   = aws_api_gateway_resource.org_invitations.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "org_invitations_options" {
  rest_api_id = var.api_id
  resource_id = aws_api_gateway_resource.org_invitations.id
  http_method = aws_api_gateway_method.org_invitations_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

resource "aws_api_gateway_method_response" "org_invitations_options" {
  rest_api_id = var.api_id
  resource_id = aws_api_gateway_resource.org_invitations.id
  http_method = aws_api_gateway_method.org_invitations_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "org_invitations_options" {
  rest_api_id = var.api_id
  resource_id = aws_api_gateway_resource.org_invitations.id
  http_method = aws_api_gateway_method.org_invitations_options.http_method
  status_code = aws_api_gateway_method_response.org_invitations_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = local.cors_headers["Access-Control-Allow-Headers"]
    "method.response.header.Access-Control-Allow-Methods" = local.cors_headers["Access-Control-Allow-Methods"]
    "method.response.header.Access-Control-Allow-Origin"  = local.cors_headers["Access-Control-Allow-Origin"]
  }
}

# -----------------------------------------------------------------------------
# Resource: /v1/orgs/{orgId}/invitations/{invitationId}
# -----------------------------------------------------------------------------

resource "aws_api_gateway_resource" "org_invitation_id" {
  rest_api_id = var.api_id
  parent_id   = aws_api_gateway_resource.org_invitations.id
  path_part   = "{invitationId}"
}

# -----------------------------------------------------------------------------
# GET /v1/orgs/{orgId}/invitations/{invitationId} - Get Invitation (Authenticated)
# -----------------------------------------------------------------------------

resource "aws_api_gateway_method" "get_invitation" {
  rest_api_id   = var.api_id
  resource_id   = aws_api_gateway_resource.org_invitation_id.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = var.authorizer_id

  request_parameters = {
    "method.request.path.orgId"          = true
    "method.request.path.invitationId"   = true
    "method.request.header.X-Request-ID" = false
  }
}

resource "aws_api_gateway_integration" "get_invitation" {
  rest_api_id             = var.api_id
  resource_id             = aws_api_gateway_resource.org_invitation_id.id
  http_method             = aws_api_gateway_method.get_invitation.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.invitation_lambda_invoke_arn.get_invitation
}

# -----------------------------------------------------------------------------
# DELETE /v1/orgs/{orgId}/invitations/{invitationId} - Cancel Invitation (Authenticated)
# -----------------------------------------------------------------------------

resource "aws_api_gateway_method" "cancel_invitation" {
  rest_api_id   = var.api_id
  resource_id   = aws_api_gateway_resource.org_invitation_id.id
  http_method   = "DELETE"
  authorization = "CUSTOM"
  authorizer_id = var.authorizer_id

  request_parameters = {
    "method.request.path.orgId"          = true
    "method.request.path.invitationId"   = true
    "method.request.header.X-Request-ID" = false
  }
}

resource "aws_api_gateway_integration" "cancel_invitation" {
  rest_api_id             = var.api_id
  resource_id             = aws_api_gateway_resource.org_invitation_id.id
  http_method             = aws_api_gateway_method.cancel_invitation.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.invitation_lambda_invoke_arn.cancel_invitation
}

# -----------------------------------------------------------------------------
# OPTIONS /v1/orgs/{orgId}/invitations/{invitationId} - CORS Preflight
# -----------------------------------------------------------------------------

resource "aws_api_gateway_method" "org_invitation_id_options" {
  rest_api_id   = var.api_id
  resource_id   = aws_api_gateway_resource.org_invitation_id.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "org_invitation_id_options" {
  rest_api_id = var.api_id
  resource_id = aws_api_gateway_resource.org_invitation_id.id
  http_method = aws_api_gateway_method.org_invitation_id_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

resource "aws_api_gateway_method_response" "org_invitation_id_options" {
  rest_api_id = var.api_id
  resource_id = aws_api_gateway_resource.org_invitation_id.id
  http_method = aws_api_gateway_method.org_invitation_id_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "org_invitation_id_options" {
  rest_api_id = var.api_id
  resource_id = aws_api_gateway_resource.org_invitation_id.id
  http_method = aws_api_gateway_method.org_invitation_id_options.http_method
  status_code = aws_api_gateway_method_response.org_invitation_id_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = local.cors_headers["Access-Control-Allow-Headers"]
    "method.response.header.Access-Control-Allow-Methods" = local.cors_headers["Access-Control-Allow-Methods"]
    "method.response.header.Access-Control-Allow-Origin"  = local.cors_headers["Access-Control-Allow-Origin"]
  }
}

# -----------------------------------------------------------------------------
# Resource: /v1/orgs/{orgId}/invitations/{invitationId}/resend
# -----------------------------------------------------------------------------

resource "aws_api_gateway_resource" "org_invitation_resend" {
  rest_api_id = var.api_id
  parent_id   = aws_api_gateway_resource.org_invitation_id.id
  path_part   = "resend"
}

# -----------------------------------------------------------------------------
# POST /v1/orgs/{orgId}/invitations/{invitationId}/resend - Resend Invitation (Authenticated)
# -----------------------------------------------------------------------------

resource "aws_api_gateway_method" "resend_invitation" {
  rest_api_id   = var.api_id
  resource_id   = aws_api_gateway_resource.org_invitation_resend.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = var.authorizer_id

  request_parameters = {
    "method.request.path.orgId"          = true
    "method.request.path.invitationId"   = true
    "method.request.header.X-Request-ID" = false
  }
}

resource "aws_api_gateway_integration" "resend_invitation" {
  rest_api_id             = var.api_id
  resource_id             = aws_api_gateway_resource.org_invitation_resend.id
  http_method             = aws_api_gateway_method.resend_invitation.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.invitation_lambda_invoke_arn.resend_invitation
}

# -----------------------------------------------------------------------------
# OPTIONS /v1/orgs/{orgId}/invitations/{invitationId}/resend - CORS Preflight
# -----------------------------------------------------------------------------

resource "aws_api_gateway_method" "org_invitation_resend_options" {
  rest_api_id   = var.api_id
  resource_id   = aws_api_gateway_resource.org_invitation_resend.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "org_invitation_resend_options" {
  rest_api_id = var.api_id
  resource_id = aws_api_gateway_resource.org_invitation_resend.id
  http_method = aws_api_gateway_method.org_invitation_resend_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

resource "aws_api_gateway_method_response" "org_invitation_resend_options" {
  rest_api_id = var.api_id
  resource_id = aws_api_gateway_resource.org_invitation_resend.id
  http_method = aws_api_gateway_method.org_invitation_resend_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "org_invitation_resend_options" {
  rest_api_id = var.api_id
  resource_id = aws_api_gateway_resource.org_invitation_resend.id
  http_method = aws_api_gateway_method.org_invitation_resend_options.http_method
  status_code = aws_api_gateway_method_response.org_invitation_resend_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = local.cors_headers["Access-Control-Allow-Headers"]
    "method.response.header.Access-Control-Allow-Methods" = local.cors_headers["Access-Control-Allow-Methods"]
    "method.response.header.Access-Control-Allow-Origin"  = local.cors_headers["Access-Control-Allow-Origin"]
  }
}

# =============================================================================
# PUBLIC ROUTES (NO AUTHORIZER)
# =============================================================================

# -----------------------------------------------------------------------------
# Resource: /v1/invitations (Public)
# -----------------------------------------------------------------------------

resource "aws_api_gateway_resource" "public_invitations" {
  rest_api_id = var.api_id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "invitations"
}

# -----------------------------------------------------------------------------
# Resource: /v1/invitations/{token}
# -----------------------------------------------------------------------------

resource "aws_api_gateway_resource" "public_invitation_token" {
  rest_api_id = var.api_id
  parent_id   = aws_api_gateway_resource.public_invitations.id
  path_part   = "{token}"
}

# -----------------------------------------------------------------------------
# GET /v1/invitations/{token} - Get Public Invitation (NO AUTH)
# -----------------------------------------------------------------------------

resource "aws_api_gateway_method" "get_invitation_by_token" {
  rest_api_id   = var.api_id
  resource_id   = aws_api_gateway_resource.public_invitation_token.id
  http_method   = "GET"
  authorization = "NONE"  # NO AUTHORIZER - PUBLIC ENDPOINT

  request_parameters = {
    "method.request.path.token"          = true
    "method.request.header.X-Request-ID" = false
  }
}

resource "aws_api_gateway_integration" "get_invitation_by_token" {
  rest_api_id             = var.api_id
  resource_id             = aws_api_gateway_resource.public_invitation_token.id
  http_method             = aws_api_gateway_method.get_invitation_by_token.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.invitation_lambda_invoke_arn.get_invitation_by_token
}

# -----------------------------------------------------------------------------
# OPTIONS /v1/invitations/{token} - CORS Preflight
# -----------------------------------------------------------------------------

resource "aws_api_gateway_method" "public_invitation_token_options" {
  rest_api_id   = var.api_id
  resource_id   = aws_api_gateway_resource.public_invitation_token.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "public_invitation_token_options" {
  rest_api_id = var.api_id
  resource_id = aws_api_gateway_resource.public_invitation_token.id
  http_method = aws_api_gateway_method.public_invitation_token_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

resource "aws_api_gateway_method_response" "public_invitation_token_options" {
  rest_api_id = var.api_id
  resource_id = aws_api_gateway_resource.public_invitation_token.id
  http_method = aws_api_gateway_method.public_invitation_token_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "public_invitation_token_options" {
  rest_api_id = var.api_id
  resource_id = aws_api_gateway_resource.public_invitation_token.id
  http_method = aws_api_gateway_method.public_invitation_token_options.http_method
  status_code = aws_api_gateway_method_response.public_invitation_token_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = local.cors_headers["Access-Control-Allow-Headers"]
    "method.response.header.Access-Control-Allow-Methods" = local.cors_headers["Access-Control-Allow-Methods"]
    "method.response.header.Access-Control-Allow-Origin"  = local.cors_headers["Access-Control-Allow-Origin"]
  }
}

# -----------------------------------------------------------------------------
# Resource: /v1/invitations/accept
# -----------------------------------------------------------------------------

resource "aws_api_gateway_resource" "public_invitation_accept" {
  rest_api_id = var.api_id
  parent_id   = aws_api_gateway_resource.public_invitations.id
  path_part   = "accept"
}

# -----------------------------------------------------------------------------
# POST /v1/invitations/accept - Accept Invitation (NO AUTH)
# -----------------------------------------------------------------------------

resource "aws_api_gateway_method" "accept_invitation" {
  rest_api_id   = var.api_id
  resource_id   = aws_api_gateway_resource.public_invitation_accept.id
  http_method   = "POST"
  authorization = "NONE"  # NO AUTHORIZER - PUBLIC ENDPOINT

  request_parameters = {
    "method.request.header.X-Request-ID" = false
    "method.request.header.Content-Type" = true
  }

  request_validator_id = aws_api_gateway_request_validator.invitation_body_validator.id
}

resource "aws_api_gateway_integration" "accept_invitation" {
  rest_api_id             = var.api_id
  resource_id             = aws_api_gateway_resource.public_invitation_accept.id
  http_method             = aws_api_gateway_method.accept_invitation.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.invitation_lambda_invoke_arn.accept_invitation
}

# -----------------------------------------------------------------------------
# OPTIONS /v1/invitations/accept - CORS Preflight
# -----------------------------------------------------------------------------

resource "aws_api_gateway_method" "public_invitation_accept_options" {
  rest_api_id   = var.api_id
  resource_id   = aws_api_gateway_resource.public_invitation_accept.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "public_invitation_accept_options" {
  rest_api_id = var.api_id
  resource_id = aws_api_gateway_resource.public_invitation_accept.id
  http_method = aws_api_gateway_method.public_invitation_accept_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

resource "aws_api_gateway_method_response" "public_invitation_accept_options" {
  rest_api_id = var.api_id
  resource_id = aws_api_gateway_resource.public_invitation_accept.id
  http_method = aws_api_gateway_method.public_invitation_accept_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "public_invitation_accept_options" {
  rest_api_id = var.api_id
  resource_id = aws_api_gateway_resource.public_invitation_accept.id
  http_method = aws_api_gateway_method.public_invitation_accept_options.http_method
  status_code = aws_api_gateway_method_response.public_invitation_accept_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = local.cors_headers["Access-Control-Allow-Headers"]
    "method.response.header.Access-Control-Allow-Methods" = local.cors_headers["Access-Control-Allow-Methods"]
    "method.response.header.Access-Control-Allow-Origin"  = local.cors_headers["Access-Control-Allow-Origin"]
  }
}

# -----------------------------------------------------------------------------
# Resource: /v1/invitations/{token}/decline
# -----------------------------------------------------------------------------

resource "aws_api_gateway_resource" "public_invitation_decline" {
  rest_api_id = var.api_id
  parent_id   = aws_api_gateway_resource.public_invitation_token.id
  path_part   = "decline"
}

# -----------------------------------------------------------------------------
# POST /v1/invitations/{token}/decline - Decline Invitation (NO AUTH)
# -----------------------------------------------------------------------------

resource "aws_api_gateway_method" "decline_invitation" {
  rest_api_id   = var.api_id
  resource_id   = aws_api_gateway_resource.public_invitation_decline.id
  http_method   = "POST"
  authorization = "NONE"  # NO AUTHORIZER - PUBLIC ENDPOINT

  request_parameters = {
    "method.request.path.token"          = true
    "method.request.header.X-Request-ID" = false
  }
}

resource "aws_api_gateway_integration" "decline_invitation" {
  rest_api_id             = var.api_id
  resource_id             = aws_api_gateway_resource.public_invitation_decline.id
  http_method             = aws_api_gateway_method.decline_invitation.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.invitation_lambda_invoke_arn.decline_invitation
}

# -----------------------------------------------------------------------------
# OPTIONS /v1/invitations/{token}/decline - CORS Preflight
# -----------------------------------------------------------------------------

resource "aws_api_gateway_method" "public_invitation_decline_options" {
  rest_api_id   = var.api_id
  resource_id   = aws_api_gateway_resource.public_invitation_decline.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "public_invitation_decline_options" {
  rest_api_id = var.api_id
  resource_id = aws_api_gateway_resource.public_invitation_decline.id
  http_method = aws_api_gateway_method.public_invitation_decline_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

resource "aws_api_gateway_method_response" "public_invitation_decline_options" {
  rest_api_id = var.api_id
  resource_id = aws_api_gateway_resource.public_invitation_decline.id
  http_method = aws_api_gateway_method.public_invitation_decline_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "public_invitation_decline_options" {
  rest_api_id = var.api_id
  resource_id = aws_api_gateway_resource.public_invitation_decline.id
  http_method = aws_api_gateway_method.public_invitation_decline_options.http_method
  status_code = aws_api_gateway_method_response.public_invitation_decline_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = local.cors_headers["Access-Control-Allow-Headers"]
    "method.response.header.Access-Control-Allow-Methods" = local.cors_headers["Access-Control-Allow-Methods"]
    "method.response.header.Access-Control-Allow-Origin"  = local.cors_headers["Access-Control-Allow-Origin"]
  }
}

# =============================================================================
# REQUEST VALIDATORS
# =============================================================================

resource "aws_api_gateway_request_validator" "invitation_body_validator" {
  rest_api_id                 = var.api_id
  name                        = "invitation-body-validator"
  validate_request_body       = true
  validate_request_parameters = true
}

# =============================================================================
# REQUEST MODELS
# =============================================================================

resource "aws_api_gateway_model" "create_invitation_request" {
  rest_api_id  = var.api_id
  name         = "CreateInvitationRequest"
  description  = "Create invitation request body"
  content_type = "application/json"

  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#"
    type      = "object"
    required  = ["email", "roleId"]
    properties = {
      email = {
        type      = "string"
        format    = "email"
        maxLength = 255
      }
      roleId = {
        type      = "string"
        minLength = 1
      }
      teamId = {
        type = "string"
      }
      message = {
        type      = "string"
        maxLength = 500
      }
    }
    additionalProperties = false
  })
}

resource "aws_api_gateway_model" "accept_invitation_request" {
  rest_api_id  = var.api_id
  name         = "AcceptInvitationRequest"
  description  = "Accept invitation request body"
  content_type = "application/json"

  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#"
    type      = "object"
    required  = ["token"]
    properties = {
      token = {
        type      = "string"
        minLength = 32
        maxLength = 128
      }
      firstName = {
        type      = "string"
        minLength = 1
        maxLength = 50
      }
      lastName = {
        type      = "string"
        minLength = 1
        maxLength = 50
      }
      password = {
        type      = "string"
        minLength = 8
        maxLength = 128
      }
    }
    additionalProperties = false
  })
}

resource "aws_api_gateway_model" "decline_invitation_request" {
  rest_api_id  = var.api_id
  name         = "DeclineInvitationRequest"
  description  = "Decline invitation request body"
  content_type = "application/json"

  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#"
    type      = "object"
    properties = {
      reason = {
        type      = "string"
        maxLength = 500
      }
    }
    additionalProperties = false
  })
}

# =============================================================================
# LAMBDA PERMISSIONS
# =============================================================================

resource "aws_lambda_permission" "create_invitation" {
  statement_id  = "AllowAPIGatewayInvoke-CreateInvitation"
  action        = "lambda:InvokeFunction"
  function_name = var.invitation_lambda_arn.create_invitation
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${var.account_id}:${var.api_id}/*/${aws_api_gateway_method.create_invitation.http_method}${aws_api_gateway_resource.org_invitations.path}"
}

resource "aws_lambda_permission" "list_invitations" {
  statement_id  = "AllowAPIGatewayInvoke-ListInvitations"
  action        = "lambda:InvokeFunction"
  function_name = var.invitation_lambda_arn.list_invitations
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${var.account_id}:${var.api_id}/*/${aws_api_gateway_method.list_invitations.http_method}${aws_api_gateway_resource.org_invitations.path}"
}

resource "aws_lambda_permission" "get_invitation" {
  statement_id  = "AllowAPIGatewayInvoke-GetInvitation"
  action        = "lambda:InvokeFunction"
  function_name = var.invitation_lambda_arn.get_invitation
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${var.account_id}:${var.api_id}/*/${aws_api_gateway_method.get_invitation.http_method}${aws_api_gateway_resource.org_invitation_id.path}"
}

resource "aws_lambda_permission" "cancel_invitation" {
  statement_id  = "AllowAPIGatewayInvoke-CancelInvitation"
  action        = "lambda:InvokeFunction"
  function_name = var.invitation_lambda_arn.cancel_invitation
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${var.account_id}:${var.api_id}/*/${aws_api_gateway_method.cancel_invitation.http_method}${aws_api_gateway_resource.org_invitation_id.path}"
}

resource "aws_lambda_permission" "resend_invitation" {
  statement_id  = "AllowAPIGatewayInvoke-ResendInvitation"
  action        = "lambda:InvokeFunction"
  function_name = var.invitation_lambda_arn.resend_invitation
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${var.account_id}:${var.api_id}/*/${aws_api_gateway_method.resend_invitation.http_method}${aws_api_gateway_resource.org_invitation_resend.path}"
}

resource "aws_lambda_permission" "get_invitation_by_token" {
  statement_id  = "AllowAPIGatewayInvoke-GetInvitationByToken"
  action        = "lambda:InvokeFunction"
  function_name = var.invitation_lambda_arn.get_invitation_by_token
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${var.account_id}:${var.api_id}/*/${aws_api_gateway_method.get_invitation_by_token.http_method}${aws_api_gateway_resource.public_invitation_token.path}"
}

resource "aws_lambda_permission" "accept_invitation" {
  statement_id  = "AllowAPIGatewayInvoke-AcceptInvitation"
  action        = "lambda:InvokeFunction"
  function_name = var.invitation_lambda_arn.accept_invitation
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${var.account_id}:${var.api_id}/*/${aws_api_gateway_method.accept_invitation.http_method}${aws_api_gateway_resource.public_invitation_accept.path}"
}

resource "aws_lambda_permission" "decline_invitation" {
  statement_id  = "AllowAPIGatewayInvoke-DeclineInvitation"
  action        = "lambda:InvokeFunction"
  function_name = var.invitation_lambda_arn.decline_invitation
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${var.account_id}:${var.api_id}/*/${aws_api_gateway_method.decline_invitation.http_method}${aws_api_gateway_resource.public_invitation_decline.path}"
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "invitation_routes" {
  description = "Invitation service API routes"
  value = {
    authenticated = {
      create_invitation  = "${aws_api_gateway_resource.org_invitations.path}"
      list_invitations   = "${aws_api_gateway_resource.org_invitations.path}"
      get_invitation     = "${aws_api_gateway_resource.org_invitation_id.path}"
      cancel_invitation  = "${aws_api_gateway_resource.org_invitation_id.path}"
      resend_invitation  = "${aws_api_gateway_resource.org_invitation_resend.path}"
    }
    public = {
      get_by_token       = "${aws_api_gateway_resource.public_invitation_token.path}"
      accept             = "${aws_api_gateway_resource.public_invitation_accept.path}"
      decline            = "${aws_api_gateway_resource.public_invitation_decline.path}"
    }
  }
}

output "invitation_resource_ids" {
  description = "API Gateway resource IDs for invitation endpoints"
  value = {
    org_invitations        = aws_api_gateway_resource.org_invitations.id
    org_invitation_id      = aws_api_gateway_resource.org_invitation_id.id
    org_invitation_resend  = aws_api_gateway_resource.org_invitation_resend.id
    public_invitations     = aws_api_gateway_resource.public_invitations.id
    public_invitation_token = aws_api_gateway_resource.public_invitation_token.id
    public_invitation_accept = aws_api_gateway_resource.public_invitation_accept.id
    public_invitation_decline = aws_api_gateway_resource.public_invitation_decline.id
  }
}
```

---

## 4. Request/Response JSON Schemas

### 4.1 Create Invitation Request Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "CreateInvitationRequest",
  "title": "Create Invitation Request",
  "type": "object",
  "required": ["email", "roleId"],
  "properties": {
    "email": {
      "type": "string",
      "format": "email",
      "maxLength": 255,
      "description": "Email address of the invitee"
    },
    "roleId": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100,
      "description": "Role to assign to the invitee"
    },
    "teamId": {
      "type": "string",
      "maxLength": 100,
      "description": "Optional team to assign the invitee to"
    },
    "message": {
      "type": "string",
      "maxLength": 500,
      "description": "Optional personal message for the invitation email"
    }
  },
  "additionalProperties": false
}
```

### 4.2 Accept Invitation Request Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "AcceptInvitationRequest",
  "title": "Accept Invitation Request",
  "type": "object",
  "required": ["token"],
  "properties": {
    "token": {
      "type": "string",
      "minLength": 32,
      "maxLength": 128,
      "description": "Invitation token from the invitation URL"
    },
    "firstName": {
      "type": "string",
      "minLength": 1,
      "maxLength": 50,
      "description": "First name (required for new users)"
    },
    "lastName": {
      "type": "string",
      "minLength": 1,
      "maxLength": 50,
      "description": "Last name (required for new users)"
    },
    "password": {
      "type": "string",
      "minLength": 8,
      "maxLength": 128,
      "description": "Password (required for new users)"
    }
  },
  "additionalProperties": false
}
```

### 4.3 Decline Invitation Request Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "DeclineInvitationRequest",
  "title": "Decline Invitation Request",
  "type": "object",
  "properties": {
    "reason": {
      "type": "string",
      "maxLength": 500,
      "description": "Optional reason for declining the invitation"
    }
  },
  "additionalProperties": false
}
```

### 4.4 Invitation Response Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "InvitationResponse",
  "title": "Invitation Response",
  "type": "object",
  "required": ["id", "email", "organisationId", "roleId", "status", "expiresAt", "dateCreated"],
  "properties": {
    "id": {
      "type": "string",
      "pattern": "^inv-[a-f0-9-]{36}$",
      "description": "Invitation ID"
    },
    "email": {
      "type": "string",
      "format": "email",
      "description": "Invitee email address"
    },
    "organisationId": {
      "type": "string",
      "description": "Organisation ID"
    },
    "organisationName": {
      "type": "string",
      "description": "Organisation name"
    },
    "roleId": {
      "type": "string",
      "description": "Assigned role ID"
    },
    "roleName": {
      "type": "string",
      "description": "Assigned role name"
    },
    "teamId": {
      "type": ["string", "null"],
      "description": "Assigned team ID (if any)"
    },
    "teamName": {
      "type": ["string", "null"],
      "description": "Assigned team name (if any)"
    },
    "message": {
      "type": ["string", "null"],
      "description": "Personal message from inviter"
    },
    "status": {
      "type": "string",
      "enum": ["PENDING", "ACCEPTED", "DECLINED", "EXPIRED", "CANCELLED"],
      "description": "Invitation status"
    },
    "expiresAt": {
      "type": "string",
      "format": "date-time",
      "description": "Invitation expiry timestamp"
    },
    "resendCount": {
      "type": "integer",
      "minimum": 0,
      "maximum": 3,
      "description": "Number of times invitation has been resent"
    },
    "active": {
      "type": "boolean",
      "description": "Whether invitation is active (not soft-deleted)"
    },
    "dateCreated": {
      "type": "string",
      "format": "date-time",
      "description": "Creation timestamp"
    },
    "createdBy": {
      "type": "string",
      "description": "Email of user who created the invitation"
    },
    "acceptedAt": {
      "type": ["string", "null"],
      "format": "date-time",
      "description": "Acceptance timestamp (if accepted)"
    },
    "declinedAt": {
      "type": ["string", "null"],
      "format": "date-time",
      "description": "Decline timestamp (if declined)"
    },
    "declineReason": {
      "type": ["string", "null"],
      "description": "Reason for declining (if declined)"
    },
    "_links": {
      "type": "object",
      "description": "HATEOAS links"
    }
  }
}
```

### 4.5 Invitation Public Response Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "InvitationPublicResponse",
  "title": "Invitation Public Response",
  "type": "object",
  "required": ["organisationName", "roleName", "inviterName", "expiresAt", "isExpired", "requiresPassword"],
  "properties": {
    "organisationName": {
      "type": "string",
      "description": "Name of the organisation"
    },
    "roleName": {
      "type": "string",
      "description": "Name of the role being assigned"
    },
    "teamName": {
      "type": ["string", "null"],
      "description": "Name of the team (if any)"
    },
    "inviterName": {
      "type": "string",
      "description": "Name of the person who sent the invitation"
    },
    "message": {
      "type": ["string", "null"],
      "description": "Personal message from the inviter"
    },
    "expiresAt": {
      "type": "string",
      "format": "date-time",
      "description": "When the invitation expires"
    },
    "isExpired": {
      "type": "boolean",
      "description": "Whether the invitation has expired"
    },
    "requiresPassword": {
      "type": "boolean",
      "description": "Whether password is required for new user registration"
    }
  }
}
```

### 4.6 Accept Invitation Response Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "AcceptInvitationResponse",
  "title": "Accept Invitation Response",
  "type": "object",
  "required": ["userId", "organisationId", "organisationName", "roleId", "roleName", "permissions", "isNewUser"],
  "properties": {
    "userId": {
      "type": "string",
      "description": "The user's ID (Cognito sub)"
    },
    "organisationId": {
      "type": "string",
      "description": "Organisation the user joined"
    },
    "organisationName": {
      "type": "string",
      "description": "Name of the organisation"
    },
    "roleId": {
      "type": "string",
      "description": "Role assigned to the user"
    },
    "roleName": {
      "type": "string",
      "description": "Name of the assigned role"
    },
    "teamId": {
      "type": ["string", "null"],
      "description": "Team the user was added to (if any)"
    },
    "teamName": {
      "type": ["string", "null"],
      "description": "Name of the team"
    },
    "permissions": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "description": "List of permissions granted through the role"
    },
    "isNewUser": {
      "type": "boolean",
      "description": "Whether a new Cognito account was created"
    }
  }
}
```

### 4.7 Error Response Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "ErrorResponse",
  "title": "Error Response",
  "type": "object",
  "required": ["errorCode", "message"],
  "properties": {
    "errorCode": {
      "type": "string",
      "description": "Machine-readable error code",
      "enum": [
        "VALIDATION_ERROR",
        "NOT_FOUND",
        "UNAUTHORIZED",
        "FORBIDDEN",
        "EXPIRED",
        "ALREADY_USED",
        "DUPLICATE_INVITATION",
        "USER_ALREADY_MEMBER",
        "INVALID_ROLE",
        "INVALID_TEAM",
        "INVALID_STATE",
        "RESEND_LIMIT_EXCEEDED",
        "PASSWORD_REQUIRED",
        "INVALID_PASSWORD",
        "INTERNAL_ERROR"
      ]
    },
    "message": {
      "type": "string",
      "description": "Human-readable error message"
    },
    "details": {
      "type": "object",
      "description": "Additional error details"
    },
    "requestId": {
      "type": "string",
      "description": "Request ID for support reference"
    }
  }
}
```

---

## 5. CORS Configuration

### 5.1 CORS Headers

All endpoints support the following CORS headers:

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization, X-Request-ID
```

### 5.2 OPTIONS Method Configuration

Every endpoint resource has an OPTIONS method configured with:

1. **Authorization**: NONE (no authentication required for preflight)
2. **Integration Type**: MOCK
3. **Response Headers**: All CORS headers returned with 200 status

### 5.3 CORS Configuration Summary

| Resource Path | OPTIONS Method | CORS Headers |
|---------------|----------------|--------------|
| /v1/orgs/{orgId}/invitations | Configured | All headers |
| /v1/orgs/{orgId}/invitations/{invitationId} | Configured | All headers |
| /v1/orgs/{orgId}/invitations/{invitationId}/resend | Configured | All headers |
| /v1/invitations/{token} | Configured | All headers |
| /v1/invitations/accept | Configured | All headers |
| /v1/invitations/{token}/decline | Configured | All headers |

---

## 6. Success Criteria Verification

| Criteria | Status | Notes |
|----------|--------|-------|
| All 8 routes configured | COMPLETE | 5 authenticated + 3 public routes |
| 5 routes with authorizer | COMPLETE | All org-scoped routes use CUSTOM authorizer |
| 3 public routes without authorizer | COMPLETE | Token-based routes use NONE authorization |
| CORS enabled | COMPLETE | OPTIONS method on all resources |
| OpenAPI spec complete | COMPLETE | Full OpenAPI 3.0.3 specification |
| Request validation enabled | COMPLETE | Body and parameter validators configured |
| Lambda integrations configured | COMPLETE | AWS_PROXY integrations for all handlers |
| Lambda permissions configured | COMPLETE | API Gateway invoke permissions granted |

---

## 7. Route Summary Table

| # | Method | Path | Authorization | Lambda Handler |
|---|--------|------|---------------|----------------|
| 1 | POST | /v1/orgs/{orgId}/invitations | CUSTOM | create_invitation |
| 2 | GET | /v1/orgs/{orgId}/invitations | CUSTOM | list_invitations |
| 3 | GET | /v1/orgs/{orgId}/invitations/{invitationId} | CUSTOM | get_invitation |
| 4 | DELETE | /v1/orgs/{orgId}/invitations/{invitationId} | CUSTOM | cancel_invitation |
| 5 | POST | /v1/orgs/{orgId}/invitations/{invitationId}/resend | CUSTOM | resend_invitation |
| 6 | GET | /v1/invitations/{token} | **NONE** | get_invitation_by_token |
| 7 | POST | /v1/invitations/accept | **NONE** | accept_invitation |
| 8 | POST | /v1/invitations/{token}/decline | **NONE** | decline_invitation |

---

**End of Output Document**
