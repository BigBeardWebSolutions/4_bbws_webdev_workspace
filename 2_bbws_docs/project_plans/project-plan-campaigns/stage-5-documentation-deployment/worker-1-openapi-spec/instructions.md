# Worker Instructions: OpenAPI Specification

**Worker ID**: worker-1-openapi-spec
**Stage**: Stage 5 - Documentation & Deployment
**Project**: project-plan-campaigns

---

## Task

Create OpenAPI 3.0 specification for the Campaign Management API.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.3_LLD_Campaigns_Lambda.md`

**Reference**:
- Section 6: REST API Operations

---

## Deliverables

### openapi/campaigns-api.yaml

```yaml
openapi: 3.0.3
info:
  title: Campaign Management API
  description: |
    API for managing promotional campaigns for the BBWS Customer Portal.
    Campaigns include discounts, date ranges, and terms for WordPress hosting packages.
  version: 1.0.0
  contact:
    name: Platform Team
    email: platform@kimmyai.io

servers:
  - url: https://api-dev.kimmyai.io/v1.0
    description: Development environment
  - url: https://api-sit.kimmyai.io/v1.0
    description: SIT environment
  - url: https://api.kimmyai.io/v1.0
    description: Production environment

tags:
  - name: Campaigns
    description: Campaign management operations

paths:
  /campaigns:
    get:
      summary: List all campaigns
      description: Retrieve all active campaigns available for viewing
      operationId: listCampaigns
      tags:
        - Campaigns
      parameters:
        - name: status
          in: query
          description: Filter by campaign status
          required: false
          schema:
            type: string
            enum: [DRAFT, ACTIVE, EXPIRED]
      responses:
        '200':
          description: List of campaigns
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/CampaignListResponse'
              example:
                campaigns:
                  - code: SUMMER2025
                    name: Summer Sale 2025
                    productId: PROD-002
                    discountPercent: 20
                    listPrice: 1500.00
                    price: 1200.00
                    termsAndConditions: Valid for new customers only.
                    status: ACTIVE
                    fromDate: '2025-06-01T00:00:00Z'
                    toDate: '2025-08-31T23:59:59Z'
                    isValid: true
                count: 1
        '500':
          $ref: '#/components/responses/InternalServerError'

    post:
      summary: Create a new campaign
      description: Create a new promotional campaign
      operationId: createCampaign
      tags:
        - Campaigns
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateCampaignRequest'
      responses:
        '201':
          description: Campaign created successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/CampaignResponse'
        '400':
          $ref: '#/components/responses/BadRequest'
        '500':
          $ref: '#/components/responses/InternalServerError'

  /campaigns/{code}:
    get:
      summary: Get campaign by code
      description: Retrieve a specific campaign by its unique code
      operationId: getCampaign
      tags:
        - Campaigns
      parameters:
        - $ref: '#/components/parameters/CampaignCode'
      responses:
        '200':
          description: Campaign details
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/CampaignResponse'
        '404':
          $ref: '#/components/responses/NotFound'
        '500':
          $ref: '#/components/responses/InternalServerError'

    put:
      summary: Update a campaign
      description: Update an existing campaign by its code
      operationId: updateCampaign
      tags:
        - Campaigns
      parameters:
        - $ref: '#/components/parameters/CampaignCode'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UpdateCampaignRequest'
      responses:
        '200':
          description: Campaign updated successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/CampaignResponse'
        '400':
          $ref: '#/components/responses/BadRequest'
        '404':
          $ref: '#/components/responses/NotFound'
        '500':
          $ref: '#/components/responses/InternalServerError'

    delete:
      summary: Delete a campaign
      description: Soft delete a campaign (sets active=false)
      operationId: deleteCampaign
      tags:
        - Campaigns
      parameters:
        - $ref: '#/components/parameters/CampaignCode'
      responses:
        '204':
          description: Campaign deleted successfully
        '404':
          $ref: '#/components/responses/NotFound'
        '500':
          $ref: '#/components/responses/InternalServerError'

components:
  parameters:
    CampaignCode:
      name: code
      in: path
      description: Unique campaign code
      required: true
      schema:
        type: string
        pattern: '^[A-Z0-9_-]+$'
        minLength: 3
        maxLength: 50
      example: SUMMER2025

  schemas:
    Campaign:
      type: object
      properties:
        code:
          type: string
          description: Unique campaign code
          example: SUMMER2025
        name:
          type: string
          description: Campaign display name
          example: Summer Sale 2025
        productId:
          type: string
          description: Associated product ID
          example: PROD-002
        discountPercent:
          type: integer
          minimum: 0
          maximum: 100
          description: Discount percentage
          example: 20
        listPrice:
          type: number
          format: decimal
          description: Original price before discount
          example: 1500.00
        price:
          type: number
          format: decimal
          description: Calculated discounted price
          example: 1200.00
        termsAndConditions:
          type: string
          description: Campaign terms and conditions
          example: Valid for new customers only.
        status:
          type: string
          enum: [DRAFT, ACTIVE, EXPIRED]
          description: Campaign status based on dates
          example: ACTIVE
        fromDate:
          type: string
          format: date-time
          description: Campaign start date
          example: '2025-06-01T00:00:00Z'
        toDate:
          type: string
          format: date-time
          description: Campaign end date
          example: '2025-08-31T23:59:59Z'
        specialConditions:
          type: string
          nullable: true
          description: Additional conditions
          example: Minimum purchase of R500 required
        isValid:
          type: boolean
          description: True if campaign is currently active
          example: true
      required:
        - code
        - name
        - productId
        - discountPercent
        - listPrice
        - price
        - termsAndConditions
        - status
        - fromDate
        - toDate
        - isValid

    CampaignListResponse:
      type: object
      properties:
        campaigns:
          type: array
          items:
            $ref: '#/components/schemas/Campaign'
        count:
          type: integer
          description: Total number of campaigns
          example: 1
      required:
        - campaigns
        - count

    CampaignResponse:
      type: object
      properties:
        campaign:
          $ref: '#/components/schemas/Campaign'
      required:
        - campaign

    CreateCampaignRequest:
      type: object
      properties:
        code:
          type: string
          pattern: '^[A-Z0-9_-]+$'
          minLength: 3
          maxLength: 50
          description: Unique campaign code (uppercase alphanumeric)
          example: WINTER2025
        name:
          type: string
          minLength: 3
          maxLength: 100
          description: Campaign display name
          example: Winter Sale 2025
        productId:
          type: string
          description: Associated product ID
          example: PROD-003
        discountPercent:
          type: integer
          minimum: 0
          maximum: 100
          description: Discount percentage
          example: 25
        listPrice:
          type: number
          format: decimal
          minimum: 0.01
          description: Original price before discount
          example: 3500.00
        termsAndConditions:
          type: string
          minLength: 10
          maxLength: 1000
          description: Campaign terms and conditions
          example: Valid for all customers. One use per customer.
        fromDate:
          type: string
          format: date-time
          description: Campaign start date (ISO 8601)
          example: '2025-07-01T00:00:00Z'
        toDate:
          type: string
          format: date-time
          description: Campaign end date (ISO 8601)
          example: '2025-08-31T23:59:59Z'
        specialConditions:
          type: string
          maxLength: 500
          nullable: true
          description: Additional conditions
          example: Cannot be combined with loyalty discounts
      required:
        - code
        - name
        - productId
        - discountPercent
        - listPrice
        - termsAndConditions
        - fromDate
        - toDate

    UpdateCampaignRequest:
      type: object
      properties:
        name:
          type: string
          minLength: 3
          maxLength: 100
        productId:
          type: string
        discountPercent:
          type: integer
          minimum: 0
          maximum: 100
        listPrice:
          type: number
          format: decimal
          minimum: 0.01
        termsAndConditions:
          type: string
          minLength: 10
          maxLength: 1000
        fromDate:
          type: string
          format: date-time
        toDate:
          type: string
          format: date-time
        specialConditions:
          type: string
          maxLength: 500
          nullable: true
        status:
          type: string
          enum: [DRAFT, ACTIVE, EXPIRED]
        active:
          type: boolean

    Error:
      type: object
      properties:
        error:
          type: string
          description: Error code
          example: ValidationError
        message:
          type: string
          description: Error message
          example: Validation failed
        errors:
          type: array
          items:
            type: string
          description: List of validation errors
      required:
        - error
        - message

  responses:
    BadRequest:
      description: Invalid request
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: ValidationError
            message: Validation failed
            errors:
              - 'code: must be at least 3 characters'

    NotFound:
      description: Campaign not found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: CampaignNotFound
            message: Campaign with code SUMMER2025 does not exist or is inactive

    InternalServerError:
      description: Internal server error
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: InternalServerError
            message: An unexpected error occurred
```

---

## Validation

After creating the spec, validate it using:

```bash
# Using swagger-cli
npx swagger-cli validate openapi/campaigns-api.yaml

# Using redocly
npx @redocly/cli lint openapi/campaigns-api.yaml
```

---

## Success Criteria

- [ ] OpenAPI 3.0 spec created
- [ ] All endpoints documented
- [ ] Request/response schemas defined
- [ ] Examples provided
- [ ] Spec validates successfully
- [ ] Multiple servers defined

---

## Execution Steps

1. Create openapi/ directory
2. Create campaigns-api.yaml
3. Define all endpoints
4. Define all schemas
5. Add examples
6. Validate spec
7. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
