# Worker Instructions: API Testing

**Worker ID**: worker-1-api-testing
**Stage**: Stage 5 - Verification
**Project**: project-plan-4

---

## Task Description

Test all 4 newly deployed API endpoints in the DEV environment to verify they function correctly. Validate request/response formats, HATEOAS links, error handling, and performance.

---

## Inputs

**Deployment Output**:
- `stage-4-deployment/worker-2-dev-deployment/output.md`
- API Gateway URL from deployment

**Environment**:
- DEV Account: 536580886816
- Region: af-south-1

**Authentication**:
- Cognito User Pool for DEV environment
- Valid JWT token required for API calls

---

## Deliverables

### 1. API Test Results Report

Create `output.md` with:
- Test results for each endpoint
- Response time metrics
- HATEOAS validation results
- Error handling verification
- Screenshots/curl outputs

### 2. Test Evidence

Save actual API responses for documentation.

---

## Test Plan

### Pre-Test Setup

```bash
# Set API base URL from Stage 4 deployment
export API_BASE_URL="https://xxx.execute-api.af-south-1.amazonaws.com/dev"

# Get Cognito token (replace with actual auth flow)
export TOKEN="eyJ..."

# Set common headers
export AUTH_HEADER="Authorization: Bearer ${TOKEN}"
export CONTENT_TYPE="Content-Type: application/json"
```

### Test Data Setup

First, create a test site to use for subsequent tests:

```bash
# Create test site
curl -X POST "${API_BASE_URL}/v1.0/tenants/test-tenant-api/sites" \
  -H "${AUTH_HEADER}" \
  -H "${CONTENT_TYPE}" \
  -d '{
    "siteName": "API Test Site",
    "subdomain": "api-test-site",
    "environment": "DEV"
  }'

# Save the returned siteId for subsequent tests
export SITE_ID="<returned-site-id>"
```

---

## Test Cases

### Test 1: GET Single Site

**Endpoint**: GET `/v1.0/tenants/{tenantId}/sites/{siteId}`

```bash
# Test 1.1: Successful retrieval
curl -X GET "${API_BASE_URL}/v1.0/tenants/test-tenant-api/sites/${SITE_ID}" \
  -H "${AUTH_HEADER}" \
  -H "${CONTENT_TYPE}" \
  -w "\n\nHTTP Status: %{http_code}\nResponse Time: %{time_total}s\n"
```

**Expected**: 200 OK

**Verify**:
- [ ] Status code is 200
- [ ] Response contains siteId, tenantId, siteName
- [ ] Response contains _links with self, tenant, plugins
- [ ] Response time < 500ms

```bash
# Test 1.2: Site not found
curl -X GET "${API_BASE_URL}/v1.0/tenants/test-tenant-api/sites/nonexistent-site" \
  -H "${AUTH_HEADER}" \
  -H "${CONTENT_TYPE}" \
  -w "\n\nHTTP Status: %{http_code}\n"
```

**Expected**: 404 Not Found with error code SITE_002

```bash
# Test 1.3: Missing path parameter
curl -X GET "${API_BASE_URL}/v1.0/tenants/test-tenant-api/sites/" \
  -H "${AUTH_HEADER}" \
  -H "${CONTENT_TYPE}" \
  -w "\n\nHTTP Status: %{http_code}\n"
```

**Expected**: 400 Bad Request or 404

---

### Test 2: LIST Sites

**Endpoint**: GET `/v1.0/tenants/{tenantId}/sites`

```bash
# Test 2.1: List all sites for tenant
curl -X GET "${API_BASE_URL}/v1.0/tenants/test-tenant-api/sites" \
  -H "${AUTH_HEADER}" \
  -H "${CONTENT_TYPE}" \
  -w "\n\nHTTP Status: %{http_code}\nResponse Time: %{time_total}s\n"
```

**Expected**: 200 OK

**Verify**:
- [ ] Status code is 200
- [ ] Response contains items array
- [ ] Response contains count
- [ ] Response contains moreAvailable boolean
- [ ] Each item has _links.self

```bash
# Test 2.2: List with pagination
curl -X GET "${API_BASE_URL}/v1.0/tenants/test-tenant-api/sites?pageSize=5" \
  -H "${AUTH_HEADER}" \
  -H "${CONTENT_TYPE}" \
  -w "\n\nHTTP Status: %{http_code}\n"
```

**Expected**: 200 OK with max 5 items

```bash
# Test 2.3: Empty tenant (no sites)
curl -X GET "${API_BASE_URL}/v1.0/tenants/empty-tenant/sites" \
  -H "${AUTH_HEADER}" \
  -H "${CONTENT_TYPE}" \
  -w "\n\nHTTP Status: %{http_code}\n"
```

**Expected**: 200 OK with empty items array

---

### Test 3: UPDATE Site

**Endpoint**: PUT `/v1.0/tenants/{tenantId}/sites/{siteId}`

**Note**: Site must be in ACTIVE status for updates. May need to wait for provisioning to complete or use a pre-existing ACTIVE site.

```bash
# Test 3.1: Successful update
curl -X PUT "${API_BASE_URL}/v1.0/tenants/test-tenant-api/sites/${SITE_ID}" \
  -H "${AUTH_HEADER}" \
  -H "${CONTENT_TYPE}" \
  -d '{
    "siteName": "Updated API Test Site"
  }' \
  -w "\n\nHTTP Status: %{http_code}\nResponse Time: %{time_total}s\n"
```

**Expected**: 200 OK

**Verify**:
- [ ] Status code is 200
- [ ] Response contains updated siteName
- [ ] Response contains message "Site updated successfully"
- [ ] Response contains _links

```bash
# Test 3.2: Update non-existent site
curl -X PUT "${API_BASE_URL}/v1.0/tenants/test-tenant-api/sites/nonexistent" \
  -H "${AUTH_HEADER}" \
  -H "${CONTENT_TYPE}" \
  -d '{"siteName": "Test"}' \
  -w "\n\nHTTP Status: %{http_code}\n"
```

**Expected**: 404 Not Found with error code SITE_002

```bash
# Test 3.3: Invalid request body
curl -X PUT "${API_BASE_URL}/v1.0/tenants/test-tenant-api/sites/${SITE_ID}" \
  -H "${AUTH_HEADER}" \
  -H "${CONTENT_TYPE}" \
  -d 'invalid json' \
  -w "\n\nHTTP Status: %{http_code}\n"
```

**Expected**: 400 Bad Request

---

### Test 4: DELETE Site

**Endpoint**: DELETE `/v1.0/tenants/{tenantId}/sites/{siteId}`

```bash
# Test 4.1: Successful deletion (soft delete)
curl -X DELETE "${API_BASE_URL}/v1.0/tenants/test-tenant-api/sites/${SITE_ID}" \
  -H "${AUTH_HEADER}" \
  -H "${CONTENT_TYPE}" \
  -w "\n\nHTTP Status: %{http_code}\nResponse Time: %{time_total}s\n"
```

**Expected**: 200 OK

**Verify**:
- [ ] Status code is 200
- [ ] Response contains status "DEPROVISIONING"
- [ ] Response contains message about deletion initiated
- [ ] Response contains _links.tenant and _links.sites

```bash
# Test 4.2: Delete non-existent site
curl -X DELETE "${API_BASE_URL}/v1.0/tenants/test-tenant-api/sites/nonexistent" \
  -H "${AUTH_HEADER}" \
  -H "${CONTENT_TYPE}" \
  -w "\n\nHTTP Status: %{http_code}\n"
```

**Expected**: 404 Not Found with error code SITE_002

```bash
# Test 4.3: Delete already deleted site
curl -X DELETE "${API_BASE_URL}/v1.0/tenants/test-tenant-api/sites/${SITE_ID}" \
  -H "${AUTH_HEADER}" \
  -H "${CONTENT_TYPE}" \
  -w "\n\nHTTP Status: %{http_code}\n"
```

**Expected**: 404 Not Found (site in DEPROVISIONING status may not be accessible)

---

## HATEOAS Validation

For each successful response, verify HATEOAS links:

### GET Site Response
```json
{
  "_links": {
    "self": {"href": "/v1.0/tenants/{tenantId}/sites/{siteId}"},
    "tenant": {"href": "/v1.0/tenants/{tenantId}"},
    "plugins": {"href": "/v1.0/tenants/{tenantId}/sites/{siteId}/plugins"},
    "health": {"href": "/v1.0/tenants/{tenantId}/sites/{siteId}/health"}
  }
}
```

### LIST Sites Response
```json
{
  "_links": {
    "self": {"href": "/v1.0/tenants/{tenantId}/sites?pageSize=20"},
    "tenant": {"href": "/v1.0/tenants/{tenantId}"},
    "next": {"href": "/v1.0/tenants/{tenantId}/sites?pageSize=20&startAt={token}"}
  }
}
```

---

## Performance Metrics

| Endpoint | Target Response Time | Actual |
|----------|---------------------|--------|
| GET Site | < 500ms | TBD |
| LIST Sites | < 1000ms | TBD |
| UPDATE Site | < 500ms | TBD |
| DELETE Site | < 500ms | TBD |

---

## Test Results Summary Template

```markdown
# API Testing Results

## Summary

| Endpoint | Tests Passed | Tests Failed | Status |
|----------|--------------|--------------|--------|
| GET /sites/{siteId} | 3/3 | 0 | PASS |
| GET /sites | 3/3 | 0 | PASS |
| PUT /sites/{siteId} | 3/3 | 0 | PASS |
| DELETE /sites/{siteId} | 3/3 | 0 | PASS |

## Detailed Results

### GET Single Site

| Test Case | Status | Response Time | Notes |
|-----------|--------|---------------|-------|
| Successful retrieval | PASS | 245ms | - |
| Site not found | PASS | 120ms | Error code SITE_002 |
| Missing parameter | PASS | 95ms | 400 returned |

(Continue for each endpoint...)

## HATEOAS Validation

- [x] All responses contain _links
- [x] Self links are correct
- [x] Related resource links are valid

## Performance

All endpoints met the <500ms target response time.

## Issues Found

None

## Recommendations

None
```

---

## Success Criteria

- [ ] All 4 endpoints return expected success responses
- [ ] All error scenarios return proper error codes
- [ ] HATEOAS links are present and correct
- [ ] Response times meet targets (<500ms)
- [ ] Authentication is enforced
- [ ] Test results documented in output.md

---

## Execution Steps

1. Get API Gateway URL from Stage 4 deployment
2. Obtain valid Cognito JWT token for DEV
3. Create test data (test site)
4. Execute all test cases
5. Record response times
6. Validate HATEOAS structures
7. Document all results in output.md
8. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
