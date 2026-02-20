# Worker Instructions: Documentation Update

**Worker ID**: worker-2-documentation-update
**Stage**: Stage 5 - Verification
**Project**: project-plan-4

---

## Task Description

Update all project documentation to reflect the 4 newly implemented API endpoints. This includes OpenAPI specifications, repository README, and ensuring the LLD document accurately reflects the implementation.

---

## Inputs

**API Test Results**:
- `worker-1-api-testing/output.md`

**Existing Documentation**:
- OpenAPI Spec: `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/openapi/sites-api.yaml`
- Repository README: `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/README.md`
- LLD Document: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.6_LLD_WordPress_Site_Management.md`

**Implementation Reference**:
- Handler implementations in `sites-service/src/handlers/sites/`

---

## Deliverables

### 1. Updated OpenAPI Specification

Update `openapi/sites-api.yaml` with:
- GET /sites/{siteId} endpoint
- GET /sites (list) endpoint
- PUT /sites/{siteId} endpoint
- DELETE /sites/{siteId} endpoint

### 2. Updated Repository README

Update README.md with:
- Complete endpoint documentation
- Example requests/responses
- Authentication requirements

### 3. Documentation Verification Report

Create `output.md` with:
- Changes made to each document
- Verification checklist

---

## OpenAPI Updates

### GET Site Endpoint

Add to `sites-api.yaml`:

```yaml
  /v1.0/tenants/{tenantId}/sites/{siteId}:
    get:
      summary: Get site details
      description: Retrieve detailed information about a specific site
      operationId: getSite
      tags:
        - Sites
      parameters:
        - name: tenantId
          in: path
          required: true
          schema:
            type: string
          description: Tenant identifier
        - name: siteId
          in: path
          required: true
          schema:
            type: string
          description: Site identifier
      responses:
        '200':
          description: Site details retrieved successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/GetSiteResponse'
        '404':
          description: Site not found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
      security:
        - bearerAuth: []
```

### LIST Sites Endpoint

```yaml
  /v1.0/tenants/{tenantId}/sites:
    get:
      summary: List tenant sites
      description: Retrieve a paginated list of sites for a tenant
      operationId: listSites
      tags:
        - Sites
      parameters:
        - name: tenantId
          in: path
          required: true
          schema:
            type: string
        - name: pageSize
          in: query
          schema:
            type: integer
            default: 20
            minimum: 1
            maximum: 100
        - name: startAt
          in: query
          schema:
            type: string
          description: Pagination token
      responses:
        '200':
          description: Sites listed successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ListSitesResponse'
      security:
        - bearerAuth: []
```

### UPDATE Site Endpoint

```yaml
    put:
      summary: Update site
      description: Update site configuration (name, template, etc.)
      operationId: updateSite
      tags:
        - Sites
      parameters:
        - name: tenantId
          in: path
          required: true
          schema:
            type: string
        - name: siteId
          in: path
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UpdateSiteRequest'
      responses:
        '200':
          description: Site updated successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UpdateSiteResponse'
        '404':
          description: Site not found
        '422':
          description: Site cannot be updated in current status
      security:
        - bearerAuth: []
```

### DELETE Site Endpoint

```yaml
    delete:
      summary: Delete site
      description: Soft delete a site (status changes to DEPROVISIONING)
      operationId: deleteSite
      tags:
        - Sites
      parameters:
        - name: tenantId
          in: path
          required: true
          schema:
            type: string
        - name: siteId
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Site deletion initiated
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/DeleteSiteResponse'
        '404':
          description: Site not found
      security:
        - bearerAuth: []
```

### New Schema Definitions

```yaml
components:
  schemas:
    GetSiteResponse:
      type: object
      properties:
        siteId:
          type: string
        tenantId:
          type: string
        siteName:
          type: string
        subdomain:
          type: string
        status:
          type: string
          enum: [PROVISIONING, ACTIVE, SUSPENDED, DEPROVISIONING, DELETED, FAILED]
        environment:
          type: string
          enum: [DEV, SIT, PROD]
        templateId:
          type: string
        wpSiteId:
          type: integer
        wordpressVersion:
          type: string
        phpVersion:
          type: string
        healthStatus:
          type: string
        createdAt:
          type: string
          format: date-time
        createdBy:
          type: string
        updatedAt:
          type: string
          format: date-time
        _links:
          $ref: '#/components/schemas/HATEOASLinks'

    ListSitesResponse:
      type: object
      properties:
        items:
          type: array
          items:
            $ref: '#/components/schemas/SiteSummary'
        count:
          type: integer
        moreAvailable:
          type: boolean
        nextToken:
          type: string
        _links:
          $ref: '#/components/schemas/HATEOASLinks'

    SiteSummary:
      type: object
      properties:
        siteId:
          type: string
        tenantId:
          type: string
        siteName:
          type: string
        subdomain:
          type: string
        status:
          type: string
        environment:
          type: string
        healthStatus:
          type: string
        createdAt:
          type: string
          format: date-time
        updatedAt:
          type: string
          format: date-time
        _links:
          $ref: '#/components/schemas/HATEOASLinks'

    UpdateSiteRequest:
      type: object
      properties:
        siteName:
          type: string
          minLength: 1
          maxLength: 100
        templateId:
          type: string
        configuration:
          type: object
          properties:
            wordpressVersion:
              type: string
            phpVersion:
              type: string

    UpdateSiteResponse:
      type: object
      properties:
        siteId:
          type: string
        tenantId:
          type: string
        siteName:
          type: string
        subdomain:
          type: string
        status:
          type: string
        environment:
          type: string
        templateId:
          type: string
        updatedAt:
          type: string
          format: date-time
        message:
          type: string
        _links:
          $ref: '#/components/schemas/HATEOASLinks'

    DeleteSiteResponse:
      type: object
      properties:
        siteId:
          type: string
        tenantId:
          type: string
        status:
          type: string
        message:
          type: string
        deletedAt:
          type: string
          format: date-time
        _links:
          $ref: '#/components/schemas/HATEOASLinks'
```

---

## README Updates

Add the following to README.md:

```markdown
## Sites API Endpoints

### GET Single Site

Retrieve detailed information about a specific site.

```bash
GET /v1.0/tenants/{tenantId}/sites/{siteId}

# Example
curl -X GET "https://api.example.com/v1.0/tenants/tenant-123/sites/site-456" \
  -H "Authorization: Bearer <token>"
```

**Response**: 200 OK
```json
{
  "siteId": "site-456",
  "tenantId": "tenant-123",
  "siteName": "My Business Site",
  "subdomain": "mybusiness",
  "status": "ACTIVE",
  "environment": "DEV",
  "_links": {
    "self": {"href": "/v1.0/tenants/tenant-123/sites/site-456"},
    "tenant": {"href": "/v1.0/tenants/tenant-123"},
    "plugins": {"href": "/v1.0/tenants/tenant-123/sites/site-456/plugins"}
  }
}
```

### LIST Sites

Retrieve a paginated list of sites for a tenant.

```bash
GET /v1.0/tenants/{tenantId}/sites?pageSize=20&startAt=<token>

# Example
curl -X GET "https://api.example.com/v1.0/tenants/tenant-123/sites?pageSize=10" \
  -H "Authorization: Bearer <token>"
```

**Response**: 200 OK
```json
{
  "items": [...],
  "count": 5,
  "moreAvailable": false,
  "_links": {
    "self": {"href": "/v1.0/tenants/tenant-123/sites?pageSize=10"}
  }
}
```

### UPDATE Site

Update a site's configuration (name, template, etc.).

```bash
PUT /v1.0/tenants/{tenantId}/sites/{siteId}

# Example
curl -X PUT "https://api.example.com/v1.0/tenants/tenant-123/sites/site-456" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"siteName": "Updated Site Name"}'
```

**Response**: 200 OK
```json
{
  "siteId": "site-456",
  "siteName": "Updated Site Name",
  "message": "Site updated successfully",
  "_links": {...}
}
```

### DELETE Site

Delete a site (soft delete - status changes to DEPROVISIONING).

```bash
DELETE /v1.0/tenants/{tenantId}/sites/{siteId}

# Example
curl -X DELETE "https://api.example.com/v1.0/tenants/tenant-123/sites/site-456" \
  -H "Authorization: Bearer <token>"
```

**Response**: 200 OK
```json
{
  "siteId": "site-456",
  "status": "DEPROVISIONING",
  "message": "Site deletion initiated",
  "_links": {...}
}
```
```

---

## Documentation Checklist

### OpenAPI Specification
- [ ] GET site endpoint documented
- [ ] LIST sites endpoint documented
- [ ] PUT site endpoint documented
- [ ] DELETE site endpoint documented
- [ ] All request schemas defined
- [ ] All response schemas defined
- [ ] Error responses documented
- [ ] Security requirements specified

### README
- [ ] All endpoints listed
- [ ] Example requests included
- [ ] Example responses included
- [ ] Authentication documented
- [ ] Error codes documented

### LLD Verification
- [ ] LLD Section 4.1 matches implementation
- [ ] LLD Section 3.6 SiteService methods match
- [ ] Error codes in LLD Section 12.1 match
- [ ] No LLD updates needed (or update if needed)

---

## Success Criteria

- [ ] OpenAPI spec updated with all 4 endpoints
- [ ] OpenAPI spec validates without errors
- [ ] README includes all endpoint documentation
- [ ] Examples are accurate and tested
- [ ] LLD verified against implementation
- [ ] All documentation changes committed

---

## Execution Steps

1. Review API test results from worker-1
2. Update OpenAPI spec with new endpoints
3. Validate OpenAPI spec
4. Update README with endpoint documentation
5. Verify LLD accuracy
6. Create output.md with changes summary
7. Update work.state to COMPLETE

---

## OpenAPI Validation

```bash
# Install openapi-spec-validator if needed
pip install openapi-spec-validator

# Validate updated spec
openapi-spec-validator openapi/sites-api.yaml
```

---

**Status**: PENDING
**Created**: 2026-01-23
