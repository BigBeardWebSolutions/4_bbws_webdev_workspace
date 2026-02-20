# Worker Output: Audit API Routes Configuration

**Worker ID**: worker-5-audit-api-routes
**Stage**: Stage 4 - API Gateway Integration
**Project**: project-plan-2-access-management
**Created**: 2026-01-23
**Status**: COMPLETE

---

## Executive Summary

This document provides complete API Gateway configuration for the Audit Service with 5 endpoints. All endpoints are org-scoped and require Lambda authorizer authentication with appropriate permissions for audit log access.

---

## 1. OpenAPI 3.0 Specification

```yaml
openapi: 3.0.3
info:
  title: BBWS Audit Service API
  version: 1.0.0
  description: |
    Audit log query and export service for BBWS Access Management.
    Provides comprehensive audit trail for security monitoring, compliance, and troubleshooting.
  contact:
    name: BBWS Platform Team
    email: platform@bbws.io
  license:
    name: Proprietary
    url: https://bbws.io/license

servers:
  - url: https://api.bbws.io/v1
    description: Production (af-south-1)
  - url: https://sit.api.bbws.io/v1
    description: SIT Environment
  - url: https://dev.api.bbws.io/v1
    description: Development Environment

tags:
  - name: Audit
    description: Audit log query and export operations

paths:
  /orgs/{orgId}/audit:
    get:
      summary: Query organisation audit logs
      description: |
        Retrieve paginated audit events for the specified organisation.
        Supports filtering by date range, event type, and user.
        Results are sorted by timestamp in descending order (most recent first).
      operationId: queryOrgAudit
      tags:
        - Audit
      security:
        - LambdaAuthorizer: []
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
        - $ref: '#/components/parameters/DateFrom'
        - $ref: '#/components/parameters/DateTo'
        - $ref: '#/components/parameters/EventType'
        - $ref: '#/components/parameters/PageSize'
        - $ref: '#/components/parameters/StartAt'
        - $ref: '#/components/parameters/UserId'
        - $ref: '#/components/parameters/ResourceType'
      responses:
        '200':
          description: Paginated list of audit events
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/AuditListResponse'
              examples:
                success:
                  $ref: '#/components/examples/AuditListExample'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '500':
          $ref: '#/components/responses/InternalError'
      x-amazon-apigateway-integration:
        type: aws_proxy
        httpMethod: POST
        uri: arn:aws:apigateway:${aws_region}:lambda:path/2015-03-31/functions/${query_org_audit_lambda_arn}/invocations
        passthroughBehavior: when_no_match
        timeoutInMillis: 29000

  /orgs/{orgId}/audit/users/{userId}:
    get:
      summary: Query user-specific audit logs
      description: |
        Retrieve audit events for a specific user within the organisation.
        Shows all actions performed by the specified user.
      operationId: queryUserAudit
      tags:
        - Audit
      security:
        - LambdaAuthorizer: []
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
        - $ref: '#/components/parameters/UserIdPath'
        - $ref: '#/components/parameters/DateFrom'
        - $ref: '#/components/parameters/DateTo'
        - $ref: '#/components/parameters/EventType'
        - $ref: '#/components/parameters/PageSize'
        - $ref: '#/components/parameters/StartAt'
      responses:
        '200':
          description: Paginated list of user audit events
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/AuditListResponse'
              examples:
                success:
                  $ref: '#/components/examples/UserAuditExample'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '404':
          $ref: '#/components/responses/NotFound'
        '500':
          $ref: '#/components/responses/InternalError'
      x-amazon-apigateway-integration:
        type: aws_proxy
        httpMethod: POST
        uri: arn:aws:apigateway:${aws_region}:lambda:path/2015-03-31/functions/${query_user_audit_lambda_arn}/invocations
        passthroughBehavior: when_no_match
        timeoutInMillis: 29000

  /orgs/{orgId}/audit/resources/{type}/{resourceId}:
    get:
      summary: Query resource-specific audit logs
      description: |
        Retrieve audit events for a specific resource within the organisation.
        Shows all actions performed on the specified resource.
      operationId: queryResourceAudit
      tags:
        - Audit
      security:
        - LambdaAuthorizer: []
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
        - $ref: '#/components/parameters/ResourceTypePath'
        - $ref: '#/components/parameters/ResourceIdPath'
        - $ref: '#/components/parameters/DateFrom'
        - $ref: '#/components/parameters/DateTo'
        - $ref: '#/components/parameters/EventType'
        - $ref: '#/components/parameters/PageSize'
        - $ref: '#/components/parameters/StartAt'
      responses:
        '200':
          description: Paginated list of resource audit events
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/AuditListResponse'
              examples:
                success:
                  $ref: '#/components/examples/ResourceAuditExample'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '404':
          $ref: '#/components/responses/NotFound'
        '500':
          $ref: '#/components/responses/InternalError'
      x-amazon-apigateway-integration:
        type: aws_proxy
        httpMethod: POST
        uri: arn:aws:apigateway:${aws_region}:lambda:path/2015-03-31/functions/${query_resource_audit_lambda_arn}/invocations
        passthroughBehavior: when_no_match
        timeoutInMillis: 29000

  /orgs/{orgId}/audit/summary:
    get:
      summary: Get audit summary statistics
      description: |
        Retrieve aggregated audit statistics for the organisation.
        Includes counts by event type, user activity, and daily trends.
      operationId: getAuditSummary
      tags:
        - Audit
      security:
        - LambdaAuthorizer: []
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
        - $ref: '#/components/parameters/DateFrom'
        - $ref: '#/components/parameters/DateTo'
      responses:
        '200':
          description: Audit summary statistics
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/AuditSummaryResponse'
              examples:
                success:
                  $ref: '#/components/examples/AuditSummaryExample'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '500':
          $ref: '#/components/responses/InternalError'
      x-amazon-apigateway-integration:
        type: aws_proxy
        httpMethod: POST
        uri: arn:aws:apigateway:${aws_region}:lambda:path/2015-03-31/functions/${get_audit_summary_lambda_arn}/invocations
        passthroughBehavior: when_no_match
        timeoutInMillis: 29000

  /orgs/{orgId}/audit/export:
    post:
      summary: Export audit logs to S3
      description: |
        Initiate export of audit logs matching the specified criteria.
        Returns a presigned S3 URL for downloading the export file.
        Export is available in CSV or JSON format.
      operationId: exportAudit
      tags:
        - Audit
      security:
        - LambdaAuthorizer: []
      parameters:
        - $ref: '#/components/parameters/OrgIdPath'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ExportRequest'
            examples:
              csvExport:
                $ref: '#/components/examples/ExportRequestCsvExample'
              jsonExport:
                $ref: '#/components/examples/ExportRequestJsonExample'
      responses:
        '202':
          description: Export initiated successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ExportResponse'
              examples:
                success:
                  $ref: '#/components/examples/ExportResponseExample'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '422':
          $ref: '#/components/responses/UnprocessableEntity'
        '500':
          $ref: '#/components/responses/InternalError'
      x-amazon-apigateway-integration:
        type: aws_proxy
        httpMethod: POST
        uri: arn:aws:apigateway:${aws_region}:lambda:path/2015-03-31/functions/${export_audit_lambda_arn}/invocations
        passthroughBehavior: when_no_match
        timeoutInMillis: 29000

components:
  parameters:
    OrgIdPath:
      name: orgId
      in: path
      required: true
      description: Organisation unique identifier
      schema:
        type: string
        format: uuid
        pattern: '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      example: "550e8400-e29b-41d4-a716-446655440000"

    UserIdPath:
      name: userId
      in: path
      required: true
      description: User unique identifier
      schema:
        type: string
        format: uuid
        pattern: '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      example: "user-12345678-1234-1234-1234-123456789012"

    ResourceTypePath:
      name: type
      in: path
      required: true
      description: Resource type (e.g., role, team, permission, site, user)
      schema:
        type: string
        enum:
          - role
          - team
          - permission
          - site
          - user
          - invitation
          - organisation
      example: "role"

    ResourceIdPath:
      name: resourceId
      in: path
      required: true
      description: Resource unique identifier
      schema:
        type: string
        format: uuid
        pattern: '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      example: "res-12345678-1234-1234-1234-123456789012"

    DateFrom:
      name: dateFrom
      in: query
      required: true
      description: Start date for audit log query (ISO 8601 format)
      schema:
        type: string
        format: date-time
      example: "2026-01-01T00:00:00Z"

    DateTo:
      name: dateTo
      in: query
      required: true
      description: End date for audit log query (ISO 8601 format)
      schema:
        type: string
        format: date-time
      example: "2026-01-23T23:59:59Z"

    EventType:
      name: eventType
      in: query
      required: false
      description: Filter by event type
      schema:
        type: string
        enum:
          - AUTHORIZATION
          - PERMISSION_CHANGE
          - USER_MANAGEMENT
          - TEAM_MEMBERSHIP
          - ROLE_CHANGE
          - INVITATION
          - CONFIGURATION
      example: "AUTHORIZATION"

    PageSize:
      name: pageSize
      in: query
      required: false
      description: Number of items per page (default 50, max 100)
      schema:
        type: integer
        minimum: 1
        maximum: 100
        default: 50
      example: 50

    StartAt:
      name: startAt
      in: query
      required: false
      description: Pagination cursor for next page (from previous response)
      schema:
        type: string
        maxLength: 500
      example: "eyJQSyI6Ik9SRyMxMjMiLCJTSyI6IkVWRU5UIzIwMjYtMDEtMjNUMTQ6MzA6MDAuMDAwWiJ9"

    UserId:
      name: userId
      in: query
      required: false
      description: Filter by acting user ID
      schema:
        type: string
        format: uuid
      example: "user-12345678-1234-1234-1234-123456789012"

    ResourceType:
      name: resourceType
      in: query
      required: false
      description: Filter by resource type
      schema:
        type: string
        enum:
          - role
          - team
          - permission
          - site
          - user
          - invitation
          - organisation
      example: "team"

  schemas:
    AuditEvent:
      type: object
      required:
        - id
        - eventType
        - timestamp
        - userId
        - userEmail
        - organisationId
        - action
        - outcome
      properties:
        id:
          type: string
          format: uuid
          description: Unique event identifier
          example: "evt-12345678-1234-1234-1234-123456789012"
        eventType:
          type: string
          enum:
            - AUTHORIZATION
            - PERMISSION_CHANGE
            - USER_MANAGEMENT
            - TEAM_MEMBERSHIP
            - ROLE_CHANGE
            - INVITATION
            - CONFIGURATION
          description: Type of audit event
          example: "AUTHORIZATION"
        timestamp:
          type: string
          format: date-time
          description: When the event occurred
          example: "2026-01-23T14:30:00.123Z"
        userId:
          type: string
          format: uuid
          description: ID of the user who performed the action
          example: "user-12345678-1234-1234-1234-123456789012"
        userEmail:
          type: string
          format: email
          description: Email of the user who performed the action
          example: "john.doe@example.com"
        organisationId:
          type: string
          format: uuid
          description: Organisation context for the event
          example: "org-12345678-1234-1234-1234-123456789012"
        resourceType:
          type: string
          nullable: true
          description: Type of resource affected
          example: "role"
        resourceId:
          type: string
          format: uuid
          nullable: true
          description: ID of the resource affected
          example: "role-12345678-1234-1234-1234-123456789012"
        action:
          type: string
          description: Action performed (create, read, update, delete, assign, etc.)
          example: "update"
        outcome:
          type: string
          enum:
            - SUCCESS
            - FAILURE
            - DENIED
          description: Result of the action
          example: "SUCCESS"
        details:
          type: object
          additionalProperties: true
          description: Event-specific details (before/after state, etc.)
          example:
            before:
              name: "Old Role Name"
            after:
              name: "New Role Name"
        ipAddress:
          type: string
          nullable: true
          description: Client IP address
          example: "192.168.1.100"
        userAgent:
          type: string
          nullable: true
          description: Client user agent string
          example: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"
        requestId:
          type: string
          nullable: true
          description: API Gateway request ID for correlation
          example: "req-abc123def456"
        _links:
          $ref: '#/components/schemas/HATEOASLinks'

    AuditListResponse:
      type: object
      required:
        - items
        - count
        - moreAvailable
      properties:
        items:
          type: array
          items:
            $ref: '#/components/schemas/AuditEvent'
          description: List of audit events
        count:
          type: integer
          minimum: 0
          description: Number of items in current response
          example: 50
        moreAvailable:
          type: boolean
          description: Whether more results are available
          example: true
        startAt:
          type: string
          nullable: true
          description: Cursor for next page (null if no more pages)
          example: "eyJQSyI6Ik9SRyMxMjMiLCJTSyI6IkVWRU5UIzIwMjYtMDEtMjNUMTQ6MzA6MDAuMDAwWiJ9"
        _links:
          $ref: '#/components/schemas/HATEOASLinks'

    AuditSummaryResponse:
      type: object
      required:
        - totalEvents
        - authorizationEvents
        - permissionChanges
        - allowedRequests
        - deniedRequests
        - eventsByType
        - eventsByDay
      properties:
        totalEvents:
          type: integer
          minimum: 0
          description: Total number of audit events in the period
          example: 1250
        authorizationEvents:
          type: integer
          minimum: 0
          description: Number of authorization events
          example: 980
        permissionChanges:
          type: integer
          minimum: 0
          description: Number of permission change events
          example: 45
        allowedRequests:
          type: integer
          minimum: 0
          description: Number of successful authorizations
          example: 950
        deniedRequests:
          type: integer
          minimum: 0
          description: Number of denied authorizations
          example: 30
        eventsByType:
          type: object
          additionalProperties:
            type: integer
          description: Event count grouped by type
          example:
            AUTHORIZATION: 980
            PERMISSION_CHANGE: 45
            USER_MANAGEMENT: 25
            TEAM_MEMBERSHIP: 100
            ROLE_CHANGE: 50
            INVITATION: 30
            CONFIGURATION: 20
        eventsByUser:
          type: object
          additionalProperties:
            type: integer
          description: Event count grouped by user (top 10)
          example:
            "user-123": 250
            "user-456": 180
            "user-789": 120
        eventsByDay:
          type: object
          additionalProperties:
            type: integer
          description: Event count grouped by day
          example:
            "2026-01-21": 420
            "2026-01-22": 380
            "2026-01-23": 450
        period:
          type: object
          properties:
            startDate:
              type: string
              format: date-time
              example: "2026-01-01T00:00:00Z"
            endDate:
              type: string
              format: date-time
              example: "2026-01-23T23:59:59Z"
        _links:
          $ref: '#/components/schemas/HATEOASLinks'

    ExportRequest:
      type: object
      required:
        - dateRange
      properties:
        dateRange:
          $ref: '#/components/schemas/DateRange'
        eventType:
          type: string
          enum:
            - AUTHORIZATION
            - PERMISSION_CHANGE
            - USER_MANAGEMENT
            - TEAM_MEMBERSHIP
            - ROLE_CHANGE
            - INVITATION
            - CONFIGURATION
          nullable: true
          description: Filter by event type (optional)
        userId:
          type: string
          format: uuid
          nullable: true
          description: Filter by user ID (optional)
        resourceType:
          type: string
          nullable: true
          description: Filter by resource type (optional)
        format:
          type: string
          enum:
            - csv
            - json
          default: csv
          description: Export file format

    DateRange:
      type: object
      required:
        - startDate
        - endDate
      properties:
        startDate:
          type: string
          format: date-time
          description: Start of date range
          example: "2026-01-01T00:00:00Z"
        endDate:
          type: string
          format: date-time
          description: End of date range
          example: "2026-01-23T23:59:59Z"

    ExportResponse:
      type: object
      required:
        - exportId
        - status
        - recordCount
      properties:
        exportId:
          type: string
          format: uuid
          description: Unique export job identifier
          example: "exp-12345678-1234-1234-1234-123456789012"
        status:
          type: string
          enum:
            - PENDING
            - PROCESSING
            - COMPLETED
            - FAILED
          description: Export job status
          example: "COMPLETED"
        s3Key:
          type: string
          nullable: true
          description: S3 object key for the export file
          example: "exports/org-123/2026/01/23/exp-12345678.csv"
        downloadUrl:
          type: string
          format: uri
          nullable: true
          description: Presigned URL to download the export (expires in 24h)
          example: "https://bbws-audit-exports.s3.af-south-1.amazonaws.com/..."
        expiresAt:
          type: string
          format: date-time
          nullable: true
          description: When the download URL expires
          example: "2026-01-24T14:30:00Z"
        recordCount:
          type: integer
          minimum: 0
          description: Number of records in the export
          example: 1250
        _links:
          $ref: '#/components/schemas/HATEOASLinks'

    HATEOASLinks:
      type: object
      properties:
        self:
          $ref: '#/components/schemas/Link'
        next:
          $ref: '#/components/schemas/Link'
        prev:
          $ref: '#/components/schemas/Link'
        organisation:
          $ref: '#/components/schemas/Link'
        user:
          $ref: '#/components/schemas/Link'
        export:
          $ref: '#/components/schemas/Link'

    Link:
      type: object
      properties:
        href:
          type: string
          format: uri
        method:
          type: string
          enum: [GET, POST, PUT, DELETE, PATCH]

    ErrorResponse:
      type: object
      required:
        - error
        - message
        - requestId
      properties:
        error:
          type: string
          description: Error code
          example: "VALIDATION_ERROR"
        message:
          type: string
          description: Human-readable error message
          example: "dateFrom must be before dateTo"
        requestId:
          type: string
          description: Request ID for troubleshooting
          example: "req-abc123def456"
        details:
          type: array
          items:
            type: object
            properties:
              field:
                type: string
              message:
                type: string
          description: Field-level validation errors

  responses:
    BadRequest:
      description: Invalid request parameters
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            error: "VALIDATION_ERROR"
            message: "Invalid request parameters"
            requestId: "req-abc123def456"
            details:
              - field: "dateFrom"
                message: "Must be a valid ISO 8601 date-time"

    Unauthorized:
      description: Missing or invalid authentication
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            error: "UNAUTHORIZED"
            message: "Authentication required"
            requestId: "req-abc123def456"

    Forbidden:
      description: Insufficient permissions
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            error: "FORBIDDEN"
            message: "audit:read permission required for this organisation"
            requestId: "req-abc123def456"

    NotFound:
      description: Resource not found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            error: "NOT_FOUND"
            message: "User not found in this organisation"
            requestId: "req-abc123def456"

    UnprocessableEntity:
      description: Request validation failed
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            error: "UNPROCESSABLE_ENTITY"
            message: "Date range cannot exceed 90 days for export"
            requestId: "req-abc123def456"

    InternalError:
      description: Internal server error
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            error: "INTERNAL_ERROR"
            message: "An unexpected error occurred"
            requestId: "req-abc123def456"

  examples:
    AuditListExample:
      summary: Audit list response
      value:
        items:
          - id: "evt-12345678-1234-1234-1234-123456789012"
            eventType: "AUTHORIZATION"
            timestamp: "2026-01-23T14:30:00.123Z"
            userId: "user-12345678-1234-1234-1234-123456789012"
            userEmail: "john.doe@example.com"
            organisationId: "org-12345678-1234-1234-1234-123456789012"
            action: "access"
            outcome: "SUCCESS"
            details:
              method: "GET"
              path: "/v1/orgs/org-123/sites"
              requiredPermission: "site:read"
            ipAddress: "192.168.1.100"
            requestId: "req-abc123"
            _links:
              self:
                href: "/v1/orgs/org-123/audit/evt-12345678"
                method: "GET"
        count: 1
        moreAvailable: true
        startAt: "eyJQSyI6Ik9SRyMxMjMiLCJTSyI6IkVWRU5UIzIwMjYtMDEtMjNUMTQ6MzA6MDAuMDAwWiJ9"
        _links:
          self:
            href: "/v1/orgs/org-123/audit?dateFrom=2026-01-01T00:00:00Z&dateTo=2026-01-23T23:59:59Z"
            method: "GET"
          next:
            href: "/v1/orgs/org-123/audit?dateFrom=2026-01-01T00:00:00Z&dateTo=2026-01-23T23:59:59Z&startAt=eyJQSyI6..."
            method: "GET"

    UserAuditExample:
      summary: User audit response
      value:
        items:
          - id: "evt-user-action-001"
            eventType: "PERMISSION_CHANGE"
            timestamp: "2026-01-23T10:15:00.456Z"
            userId: "user-12345678-1234-1234-1234-123456789012"
            userEmail: "john.doe@example.com"
            organisationId: "org-12345678-1234-1234-1234-123456789012"
            resourceType: "role"
            resourceId: "role-editor-001"
            action: "assign"
            outcome: "SUCCESS"
            details:
              roleName: "SITE_EDITOR"
              assignedTo: "user-new-member"
            ipAddress: "192.168.1.100"
        count: 1
        moreAvailable: false
        startAt: null
        _links:
          self:
            href: "/v1/orgs/org-123/audit/users/user-123"
            method: "GET"
          user:
            href: "/v1/orgs/org-123/users/user-123"
            method: "GET"

    ResourceAuditExample:
      summary: Resource audit response
      value:
        items:
          - id: "evt-resource-action-001"
            eventType: "ROLE_CHANGE"
            timestamp: "2026-01-23T09:00:00.789Z"
            userId: "admin-12345678"
            userEmail: "admin@example.com"
            organisationId: "org-12345678-1234-1234-1234-123456789012"
            resourceType: "role"
            resourceId: "role-editor-001"
            action: "update"
            outcome: "SUCCESS"
            details:
              before:
                permissions: ["site:read", "site:update"]
              after:
                permissions: ["site:read", "site:update", "site:publish"]
              added: ["site:publish"]
            ipAddress: "10.0.0.50"
        count: 1
        moreAvailable: false
        startAt: null

    AuditSummaryExample:
      summary: Audit summary response
      value:
        totalEvents: 1250
        authorizationEvents: 980
        permissionChanges: 45
        allowedRequests: 950
        deniedRequests: 30
        eventsByType:
          AUTHORIZATION: 980
          PERMISSION_CHANGE: 45
          USER_MANAGEMENT: 25
          TEAM_MEMBERSHIP: 100
          ROLE_CHANGE: 50
          INVITATION: 30
          CONFIGURATION: 20
        eventsByUser:
          "user-admin-001": 250
          "user-editor-002": 180
          "user-viewer-003": 120
        eventsByDay:
          "2026-01-21": 420
          "2026-01-22": 380
          "2026-01-23": 450
        period:
          startDate: "2026-01-01T00:00:00Z"
          endDate: "2026-01-23T23:59:59Z"
        _links:
          self:
            href: "/v1/orgs/org-123/audit/summary"
            method: "GET"
          export:
            href: "/v1/orgs/org-123/audit/export"
            method: "POST"

    ExportRequestCsvExample:
      summary: CSV export request
      value:
        dateRange:
          startDate: "2026-01-01T00:00:00Z"
          endDate: "2026-01-23T23:59:59Z"
        eventType: "AUTHORIZATION"
        format: "csv"

    ExportRequestJsonExample:
      summary: JSON export request
      value:
        dateRange:
          startDate: "2026-01-01T00:00:00Z"
          endDate: "2026-01-23T23:59:59Z"
        format: "json"

    ExportResponseExample:
      summary: Export response
      value:
        exportId: "exp-12345678-1234-1234-1234-123456789012"
        status: "COMPLETED"
        s3Key: "exports/org-123/2026/01/23/exp-12345678.csv"
        downloadUrl: "https://bbws-audit-exports.s3.af-south-1.amazonaws.com/exports/org-123/2026/01/23/exp-12345678.csv?X-Amz-Algorithm=..."
        expiresAt: "2026-01-24T14:30:00Z"
        recordCount: 980
        _links:
          self:
            href: "/v1/orgs/org-123/audit/export/exp-12345678"
            method: "GET"

  securitySchemes:
    LambdaAuthorizer:
      type: apiKey
      name: Authorization
      in: header
      description: |
        JWT Bearer token validated by Lambda Authorizer.
        Required permissions: audit:read for query endpoints, audit:export for export endpoint.
      x-amazon-apigateway-authtype: custom
      x-amazon-apigateway-authorizer:
        type: request
        authorizerUri: arn:aws:apigateway:${aws_region}:lambda:path/2015-03-31/functions/${authorizer_lambda_arn}/invocations
        authorizerResultTtlInSeconds: 300
        identitySource: method.request.header.Authorization

security:
  - LambdaAuthorizer: []

x-amazon-apigateway-cors:
  allowOrigins:
    - "*"
  allowMethods:
    - GET
    - POST
    - OPTIONS
  allowHeaders:
    - Content-Type
    - Authorization
    - X-Request-ID
    - X-Amz-Date
    - X-Api-Key
  maxAge: 3600
```

---

## 2. Terraform Route Configuration

```hcl
# =============================================================================
# File: terraform/modules/api-gateway/routes/audit_routes.tf
# Description: API Gateway routes for Audit Service
# =============================================================================

# -----------------------------------------------------------------------------
# Local Variables
# -----------------------------------------------------------------------------
locals {
  audit_service_name = "audit"
  audit_base_path    = "/v1/orgs/{orgId}/audit"

  audit_routes = {
    query_org_audit = {
      method      = "GET"
      path        = "/v1/orgs/{orgId}/audit"
      lambda_name = "query_org_audit"
      description = "Query organisation audit logs"
    }
    query_user_audit = {
      method      = "GET"
      path        = "/v1/orgs/{orgId}/audit/users/{userId}"
      lambda_name = "query_user_audit"
      description = "Query user-specific audit logs"
    }
    query_resource_audit = {
      method      = "GET"
      path        = "/v1/orgs/{orgId}/audit/resources/{type}/{resourceId}"
      lambda_name = "query_resource_audit"
      description = "Query resource-specific audit logs"
    }
    get_audit_summary = {
      method      = "GET"
      path        = "/v1/orgs/{orgId}/audit/summary"
      lambda_name = "get_audit_summary"
      description = "Get audit summary statistics"
    }
    export_audit = {
      method      = "POST"
      path        = "/v1/orgs/{orgId}/audit/export"
      lambda_name = "export_audit"
      description = "Export audit logs to S3"
    }
  }

  # Common tags for all resources
  common_tags = {
    Project     = "BBWS"
    Component   = "AuditService"
    Environment = var.environment
    ManagedBy   = "Terraform"
    CostCenter  = "BBWS-ACCESS"
  }
}

# -----------------------------------------------------------------------------
# API Gateway Routes
# -----------------------------------------------------------------------------

# Route: GET /v1/orgs/{orgId}/audit
resource "aws_apigatewayv2_route" "query_org_audit" {
  api_id             = var.api_gateway_id
  route_key          = "GET /v1/orgs/{orgId}/audit"
  target             = "integrations/${aws_apigatewayv2_integration.query_org_audit.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = var.authorizer_id

  # Request parameter validation
  request_parameter {
    request_parameter_key = "route.request.querystring.dateFrom"
    required              = true
  }

  request_parameter {
    request_parameter_key = "route.request.querystring.dateTo"
    required              = true
  }
}

resource "aws_apigatewayv2_integration" "query_org_audit" {
  api_id                 = var.api_gateway_id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_arns["query_org_audit"]
  integration_method     = "POST"
  payload_format_version = "2.0"
  timeout_milliseconds   = 29000

  description = "Integration for query_org_audit Lambda"
}

# Route: GET /v1/orgs/{orgId}/audit/users/{userId}
resource "aws_apigatewayv2_route" "query_user_audit" {
  api_id             = var.api_gateway_id
  route_key          = "GET /v1/orgs/{orgId}/audit/users/{userId}"
  target             = "integrations/${aws_apigatewayv2_integration.query_user_audit.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = var.authorizer_id

  request_parameter {
    request_parameter_key = "route.request.querystring.dateFrom"
    required              = true
  }

  request_parameter {
    request_parameter_key = "route.request.querystring.dateTo"
    required              = true
  }
}

resource "aws_apigatewayv2_integration" "query_user_audit" {
  api_id                 = var.api_gateway_id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_arns["query_user_audit"]
  integration_method     = "POST"
  payload_format_version = "2.0"
  timeout_milliseconds   = 29000

  description = "Integration for query_user_audit Lambda"
}

# Route: GET /v1/orgs/{orgId}/audit/resources/{type}/{resourceId}
resource "aws_apigatewayv2_route" "query_resource_audit" {
  api_id             = var.api_gateway_id
  route_key          = "GET /v1/orgs/{orgId}/audit/resources/{type}/{resourceId}"
  target             = "integrations/${aws_apigatewayv2_integration.query_resource_audit.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = var.authorizer_id

  request_parameter {
    request_parameter_key = "route.request.querystring.dateFrom"
    required              = true
  }

  request_parameter {
    request_parameter_key = "route.request.querystring.dateTo"
    required              = true
  }
}

resource "aws_apigatewayv2_integration" "query_resource_audit" {
  api_id                 = var.api_gateway_id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_arns["query_resource_audit"]
  integration_method     = "POST"
  payload_format_version = "2.0"
  timeout_milliseconds   = 29000

  description = "Integration for query_resource_audit Lambda"
}

# Route: GET /v1/orgs/{orgId}/audit/summary
resource "aws_apigatewayv2_route" "get_audit_summary" {
  api_id             = var.api_gateway_id
  route_key          = "GET /v1/orgs/{orgId}/audit/summary"
  target             = "integrations/${aws_apigatewayv2_integration.get_audit_summary.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = var.authorizer_id

  request_parameter {
    request_parameter_key = "route.request.querystring.dateFrom"
    required              = true
  }

  request_parameter {
    request_parameter_key = "route.request.querystring.dateTo"
    required              = true
  }
}

resource "aws_apigatewayv2_integration" "get_audit_summary" {
  api_id                 = var.api_gateway_id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_arns["get_audit_summary"]
  integration_method     = "POST"
  payload_format_version = "2.0"
  timeout_milliseconds   = 29000

  description = "Integration for get_audit_summary Lambda"
}

# Route: POST /v1/orgs/{orgId}/audit/export
resource "aws_apigatewayv2_route" "export_audit" {
  api_id             = var.api_gateway_id
  route_key          = "POST /v1/orgs/{orgId}/audit/export"
  target             = "integrations/${aws_apigatewayv2_integration.export_audit.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = var.authorizer_id
}

resource "aws_apigatewayv2_integration" "export_audit" {
  api_id                 = var.api_gateway_id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_arns["export_audit"]
  integration_method     = "POST"
  payload_format_version = "2.0"
  timeout_milliseconds   = 29000

  description = "Integration for export_audit Lambda"
}

# -----------------------------------------------------------------------------
# Lambda Permissions for API Gateway Invocation
# -----------------------------------------------------------------------------

resource "aws_lambda_permission" "query_org_audit" {
  statement_id  = "AllowAPIGatewayInvoke-QueryOrgAudit"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_names["query_org_audit"]
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*/orgs/*/audit"
}

resource "aws_lambda_permission" "query_user_audit" {
  statement_id  = "AllowAPIGatewayInvoke-QueryUserAudit"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_names["query_user_audit"]
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*/orgs/*/audit/users/*"
}

resource "aws_lambda_permission" "query_resource_audit" {
  statement_id  = "AllowAPIGatewayInvoke-QueryResourceAudit"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_names["query_resource_audit"]
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*/orgs/*/audit/resources/*/*"
}

resource "aws_lambda_permission" "get_audit_summary" {
  statement_id  = "AllowAPIGatewayInvoke-GetAuditSummary"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_names["get_audit_summary"]
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*/orgs/*/audit/summary"
}

resource "aws_lambda_permission" "export_audit" {
  statement_id  = "AllowAPIGatewayInvoke-ExportAudit"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_names["export_audit"]
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*/orgs/*/audit/export"
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "api_gateway_id" {
  description = "API Gateway ID"
  type        = string
}

variable "api_gateway_execution_arn" {
  description = "API Gateway execution ARN"
  type        = string
}

variable "authorizer_id" {
  description = "Lambda Authorizer ID"
  type        = string
}

variable "lambda_arns" {
  description = "Map of Lambda function ARNs"
  type        = map(string)
}

variable "lambda_function_names" {
  description = "Map of Lambda function names"
  type        = map(string)
}

variable "environment" {
  description = "Environment name (dev, sit, prod)"
  type        = string
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "audit_route_ids" {
  description = "Map of audit route IDs"
  value = {
    query_org_audit      = aws_apigatewayv2_route.query_org_audit.id
    query_user_audit     = aws_apigatewayv2_route.query_user_audit.id
    query_resource_audit = aws_apigatewayv2_route.query_resource_audit.id
    get_audit_summary    = aws_apigatewayv2_route.get_audit_summary.id
    export_audit         = aws_apigatewayv2_route.export_audit.id
  }
}

output "audit_integration_ids" {
  description = "Map of audit integration IDs"
  value = {
    query_org_audit      = aws_apigatewayv2_integration.query_org_audit.id
    query_user_audit     = aws_apigatewayv2_integration.query_user_audit.id
    query_resource_audit = aws_apigatewayv2_integration.query_resource_audit.id
    get_audit_summary    = aws_apigatewayv2_integration.get_audit_summary.id
    export_audit         = aws_apigatewayv2_integration.export_audit.id
  }
}
```

---

## 3. Query Parameter Schemas

### 3.1 Parameter Definitions

| Parameter | Type | Required | Description | Validation |
|-----------|------|----------|-------------|------------|
| `dateFrom` | string (date-time) | Yes | Start date for query range | ISO 8601 format, must be before `dateTo` |
| `dateTo` | string (date-time) | Yes | End date for query range | ISO 8601 format, must be after `dateFrom`, max 90 days range |
| `eventType` | string (enum) | No | Filter by event type | One of: AUTHORIZATION, PERMISSION_CHANGE, USER_MANAGEMENT, TEAM_MEMBERSHIP, ROLE_CHANGE, INVITATION, CONFIGURATION |
| `pageSize` | integer | No | Results per page | Min: 1, Max: 100, Default: 50 |
| `startAt` | string | No | Pagination cursor | Base64 encoded DynamoDB LastEvaluatedKey |
| `userId` | string (uuid) | No | Filter by acting user | Valid UUID format |
| `resourceType` | string (enum) | No | Filter by resource type | One of: role, team, permission, site, user, invitation, organisation |

### 3.2 Validation Rules

```python
# Query Parameter Validation Schema
from pydantic import BaseModel, Field, validator
from typing import Optional
from datetime import datetime, timedelta
from enum import Enum

class EventTypeEnum(str, Enum):
    AUTHORIZATION = "AUTHORIZATION"
    PERMISSION_CHANGE = "PERMISSION_CHANGE"
    USER_MANAGEMENT = "USER_MANAGEMENT"
    TEAM_MEMBERSHIP = "TEAM_MEMBERSHIP"
    ROLE_CHANGE = "ROLE_CHANGE"
    INVITATION = "INVITATION"
    CONFIGURATION = "CONFIGURATION"

class ResourceTypeEnum(str, Enum):
    ROLE = "role"
    TEAM = "team"
    PERMISSION = "permission"
    SITE = "site"
    USER = "user"
    INVITATION = "invitation"
    ORGANISATION = "organisation"

class AuditQueryParams(BaseModel):
    """Query parameters for audit endpoints."""

    date_from: datetime = Field(..., alias="dateFrom")
    date_to: datetime = Field(..., alias="dateTo")
    event_type: Optional[EventTypeEnum] = Field(None, alias="eventType")
    page_size: int = Field(50, ge=1, le=100, alias="pageSize")
    start_at: Optional[str] = Field(None, alias="startAt", max_length=500)
    user_id: Optional[str] = Field(None, alias="userId")
    resource_type: Optional[ResourceTypeEnum] = Field(None, alias="resourceType")

    @validator('date_to')
    def validate_date_range(cls, date_to, values):
        date_from = values.get('date_from')
        if date_from and date_to:
            if date_to <= date_from:
                raise ValueError("dateTo must be after dateFrom")
            if (date_to - date_from) > timedelta(days=90):
                raise ValueError("Date range cannot exceed 90 days")
        return date_to

    @validator('start_at')
    def validate_pagination_cursor(cls, v):
        if v:
            try:
                import base64
                base64.b64decode(v)
            except Exception:
                raise ValueError("Invalid pagination cursor format")
        return v

    class Config:
        populate_by_name = True
```

### 3.3 JSON Schema for Request Validation

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "AuditQueryParameters",
  "type": "object",
  "required": ["dateFrom", "dateTo"],
  "properties": {
    "dateFrom": {
      "type": "string",
      "format": "date-time",
      "description": "Start date for query range (ISO 8601)"
    },
    "dateTo": {
      "type": "string",
      "format": "date-time",
      "description": "End date for query range (ISO 8601)"
    },
    "eventType": {
      "type": "string",
      "enum": [
        "AUTHORIZATION",
        "PERMISSION_CHANGE",
        "USER_MANAGEMENT",
        "TEAM_MEMBERSHIP",
        "ROLE_CHANGE",
        "INVITATION",
        "CONFIGURATION"
      ]
    },
    "pageSize": {
      "type": "integer",
      "minimum": 1,
      "maximum": 100,
      "default": 50
    },
    "startAt": {
      "type": "string",
      "maxLength": 500,
      "description": "Base64 encoded pagination cursor"
    },
    "userId": {
      "type": "string",
      "format": "uuid"
    },
    "resourceType": {
      "type": "string",
      "enum": ["role", "team", "permission", "site", "user", "invitation", "organisation"]
    }
  }
}
```

---

## 4. Request/Response JSON Schemas

### 4.1 Export Request Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ExportRequest",
  "type": "object",
  "required": ["dateRange"],
  "properties": {
    "dateRange": {
      "type": "object",
      "required": ["startDate", "endDate"],
      "properties": {
        "startDate": {
          "type": "string",
          "format": "date-time",
          "description": "Start of date range"
        },
        "endDate": {
          "type": "string",
          "format": "date-time",
          "description": "End of date range"
        }
      }
    },
    "eventType": {
      "type": "string",
      "enum": [
        "AUTHORIZATION",
        "PERMISSION_CHANGE",
        "USER_MANAGEMENT",
        "TEAM_MEMBERSHIP",
        "ROLE_CHANGE",
        "INVITATION",
        "CONFIGURATION"
      ],
      "description": "Filter by event type (optional)"
    },
    "userId": {
      "type": "string",
      "format": "uuid",
      "description": "Filter by user ID (optional)"
    },
    "resourceType": {
      "type": "string",
      "enum": ["role", "team", "permission", "site", "user", "invitation", "organisation"],
      "description": "Filter by resource type (optional)"
    },
    "format": {
      "type": "string",
      "enum": ["csv", "json"],
      "default": "csv",
      "description": "Export file format"
    }
  }
}
```

### 4.2 Audit Event Response Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "AuditEvent",
  "type": "object",
  "required": ["id", "eventType", "timestamp", "userId", "userEmail", "organisationId", "action", "outcome"],
  "properties": {
    "id": {
      "type": "string",
      "format": "uuid",
      "description": "Unique event identifier"
    },
    "eventType": {
      "type": "string",
      "enum": [
        "AUTHORIZATION",
        "PERMISSION_CHANGE",
        "USER_MANAGEMENT",
        "TEAM_MEMBERSHIP",
        "ROLE_CHANGE",
        "INVITATION",
        "CONFIGURATION"
      ]
    },
    "timestamp": {
      "type": "string",
      "format": "date-time"
    },
    "userId": {
      "type": "string",
      "format": "uuid"
    },
    "userEmail": {
      "type": "string",
      "format": "email"
    },
    "organisationId": {
      "type": "string",
      "format": "uuid"
    },
    "resourceType": {
      "type": ["string", "null"]
    },
    "resourceId": {
      "type": ["string", "null"],
      "format": "uuid"
    },
    "action": {
      "type": "string",
      "description": "Action performed"
    },
    "outcome": {
      "type": "string",
      "enum": ["SUCCESS", "FAILURE", "DENIED"]
    },
    "details": {
      "type": "object",
      "additionalProperties": true
    },
    "ipAddress": {
      "type": ["string", "null"]
    },
    "userAgent": {
      "type": ["string", "null"]
    },
    "requestId": {
      "type": ["string", "null"]
    },
    "_links": {
      "type": "object",
      "properties": {
        "self": {
          "$ref": "#/definitions/Link"
        },
        "organisation": {
          "$ref": "#/definitions/Link"
        },
        "user": {
          "$ref": "#/definitions/Link"
        }
      }
    }
  },
  "definitions": {
    "Link": {
      "type": "object",
      "properties": {
        "href": {
          "type": "string",
          "format": "uri"
        },
        "method": {
          "type": "string",
          "enum": ["GET", "POST", "PUT", "DELETE", "PATCH"]
        }
      }
    }
  }
}
```

### 4.3 Audit List Response Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "AuditListResponse",
  "type": "object",
  "required": ["items", "count", "moreAvailable"],
  "properties": {
    "items": {
      "type": "array",
      "items": {
        "$ref": "#/definitions/AuditEvent"
      }
    },
    "count": {
      "type": "integer",
      "minimum": 0
    },
    "moreAvailable": {
      "type": "boolean"
    },
    "startAt": {
      "type": ["string", "null"],
      "description": "Cursor for next page"
    },
    "_links": {
      "type": "object",
      "properties": {
        "self": {
          "$ref": "#/definitions/Link"
        },
        "next": {
          "$ref": "#/definitions/Link"
        },
        "prev": {
          "$ref": "#/definitions/Link"
        }
      }
    }
  }
}
```

### 4.4 Audit Summary Response Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "AuditSummaryResponse",
  "type": "object",
  "required": ["totalEvents", "authorizationEvents", "permissionChanges", "allowedRequests", "deniedRequests", "eventsByType", "eventsByDay"],
  "properties": {
    "totalEvents": {
      "type": "integer",
      "minimum": 0
    },
    "authorizationEvents": {
      "type": "integer",
      "minimum": 0
    },
    "permissionChanges": {
      "type": "integer",
      "minimum": 0
    },
    "allowedRequests": {
      "type": "integer",
      "minimum": 0
    },
    "deniedRequests": {
      "type": "integer",
      "minimum": 0
    },
    "eventsByType": {
      "type": "object",
      "additionalProperties": {
        "type": "integer"
      }
    },
    "eventsByUser": {
      "type": "object",
      "additionalProperties": {
        "type": "integer"
      }
    },
    "eventsByDay": {
      "type": "object",
      "additionalProperties": {
        "type": "integer"
      }
    },
    "period": {
      "type": "object",
      "properties": {
        "startDate": {
          "type": "string",
          "format": "date-time"
        },
        "endDate": {
          "type": "string",
          "format": "date-time"
        }
      }
    },
    "_links": {
      "type": "object"
    }
  }
}
```

### 4.5 Export Response Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ExportResponse",
  "type": "object",
  "required": ["exportId", "status", "recordCount"],
  "properties": {
    "exportId": {
      "type": "string",
      "format": "uuid"
    },
    "status": {
      "type": "string",
      "enum": ["PENDING", "PROCESSING", "COMPLETED", "FAILED"]
    },
    "s3Key": {
      "type": ["string", "null"]
    },
    "downloadUrl": {
      "type": ["string", "null"],
      "format": "uri"
    },
    "expiresAt": {
      "type": ["string", "null"],
      "format": "date-time"
    },
    "recordCount": {
      "type": "integer",
      "minimum": 0
    },
    "_links": {
      "type": "object"
    }
  }
}
```

---

## 5. CORS Configuration

### 5.1 API Gateway CORS Settings

```hcl
# =============================================================================
# File: terraform/modules/api-gateway/cors.tf
# Description: CORS configuration for API Gateway
# =============================================================================

# CORS configuration for HTTP API
resource "aws_apigatewayv2_api" "main" {
  # ... other configuration ...

  cors_configuration {
    allow_credentials = false
    allow_headers     = [
      "Content-Type",
      "Authorization",
      "X-Request-ID",
      "X-Amz-Date",
      "X-Api-Key",
      "X-Amz-Security-Token"
    ]
    allow_methods     = [
      "GET",
      "POST",
      "PUT",
      "DELETE",
      "OPTIONS"
    ]
    allow_origins     = var.cors_allowed_origins
    expose_headers    = [
      "X-Request-ID",
      "X-Amz-Request-Id"
    ]
    max_age           = 3600
  }
}

# Variables for CORS
variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
}
```

### 5.2 Environment-Specific CORS Origins

```hcl
# terraform/environments/dev.tfvars
cors_allowed_origins = [
  "http://localhost:3000",
  "http://localhost:5173",
  "https://dev.bbws.io",
  "https://dev-portal.bbws.io"
]

# terraform/environments/sit.tfvars
cors_allowed_origins = [
  "https://sit.bbws.io",
  "https://sit-portal.bbws.io"
]

# terraform/environments/prod.tfvars
cors_allowed_origins = [
  "https://bbws.io",
  "https://portal.bbws.io",
  "https://www.bbws.io"
]
```

### 5.3 Lambda Response Headers

```python
# Lambda response builder with CORS headers
def build_response(status_code: int, body: dict, request_id: str = None) -> dict:
    """Build API Gateway response with CORS headers."""

    response = {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Request-ID",
            "Access-Control-Expose-Headers": "X-Request-ID",
            "Cache-Control": "no-store, no-cache, must-revalidate",
        },
        "body": json.dumps(body, default=str)
    }

    if request_id:
        response["headers"]["X-Request-ID"] = request_id

    return response
```

---

## 6. Route Summary Table

| # | Method | Path | Lambda | Authorizer | Required Params |
|---|--------|------|--------|------------|-----------------|
| 1 | GET | /v1/orgs/{orgId}/audit | query_org_audit | Yes | dateFrom, dateTo |
| 2 | GET | /v1/orgs/{orgId}/audit/users/{userId} | query_user_audit | Yes | dateFrom, dateTo |
| 3 | GET | /v1/orgs/{orgId}/audit/resources/{type}/{resourceId} | query_resource_audit | Yes | dateFrom, dateTo |
| 4 | GET | /v1/orgs/{orgId}/audit/summary | get_audit_summary | Yes | dateFrom, dateTo |
| 5 | POST | /v1/orgs/{orgId}/audit/export | export_audit | Yes | Request body |

---

## 7. Required Permissions

### 7.1 Permission Matrix

| Endpoint | Required Permission | Description |
|----------|---------------------|-------------|
| GET /audit | `audit:read` | Query organisation audit logs |
| GET /audit/users/{userId} | `audit:read` | Query user-specific audit logs |
| GET /audit/resources/{type}/{resourceId} | `audit:read` | Query resource-specific audit logs |
| GET /audit/summary | `audit:read` | Get audit summary statistics |
| POST /audit/export | `audit:export` | Export audit logs to S3 |

### 7.2 Lambda Authorizer Context

The Lambda authorizer must provide the following context for audit endpoints:

```json
{
  "userId": "user-123",
  "orgId": "org-456",
  "permissions": ["audit:read", "audit:export"],
  "roles": ["ORG_ADMIN", "SECURITY_OFFICER"],
  "email": "admin@example.com"
}
```

---

## 8. Validation Rules

### 8.1 Path Parameter Validation

| Parameter | Format | Example |
|-----------|--------|---------|
| orgId | UUID v4 | 550e8400-e29b-41d4-a716-446655440000 |
| userId | UUID v4 | user-12345678-1234-1234-1234-123456789012 |
| type | Enum | role, team, permission, site, user, invitation, organisation |
| resourceId | UUID v4 | res-12345678-1234-1234-1234-123456789012 |

### 8.2 Query Parameter Validation

| Validation | Rule |
|------------|------|
| Date range | `dateTo` must be after `dateFrom` |
| Max range | Cannot exceed 90 days |
| Page size | Between 1 and 100 |
| Cursor | Valid Base64 encoded string |

### 8.3 Request Body Validation (Export)

| Validation | Rule |
|------------|------|
| Date range required | `dateRange.startDate` and `dateRange.endDate` are mandatory |
| Max export range | Cannot exceed 90 days |
| Format | Must be "csv" or "json" |

---

## 9. Integration Testing Checklist

- [ ] GET /v1/orgs/{orgId}/audit returns paginated results
- [ ] GET /v1/orgs/{orgId}/audit with eventType filter works
- [ ] GET /v1/orgs/{orgId}/audit pagination works correctly
- [ ] GET /v1/orgs/{orgId}/audit/users/{userId} returns user-specific events
- [ ] GET /v1/orgs/{orgId}/audit/resources/{type}/{resourceId} returns resource events
- [ ] GET /v1/orgs/{orgId}/audit/summary returns aggregated statistics
- [ ] POST /v1/orgs/{orgId}/audit/export creates export and returns download URL
- [ ] All endpoints return 401 without valid token
- [ ] All endpoints return 403 without required permissions
- [ ] All endpoints return 400 for invalid date range
- [ ] CORS headers present in all responses
- [ ] X-Request-ID header returned for tracing

---

## 10. Success Criteria Checklist

- [x] All 5 routes configured
- [x] Query parameters documented
- [x] Lambda authorizer attached
- [x] CORS enabled
- [x] OpenAPI spec complete
- [x] Terraform configuration complete
- [x] Request/response schemas defined
- [x] Validation rules documented
- [x] Permission matrix defined

---

**Worker Status**: COMPLETE
**Output Created**: 2026-01-23
**Next Step**: Rename work.state.PENDING to work.state.COMPLETE
