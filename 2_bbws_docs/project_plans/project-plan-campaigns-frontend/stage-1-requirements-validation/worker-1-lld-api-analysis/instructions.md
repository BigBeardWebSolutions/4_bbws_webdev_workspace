# Worker Instructions: LLD API Analysis

**Worker ID**: worker-1-lld-api-analysis
**Stage**: Stage 1 - Requirements Validation
**Project**: project-plan-campaigns-frontend

---

## Task

Analyze the Campaigns Lambda LLD document and extract complete API specifications including endpoints, request/response formats, status codes, and business rules for frontend implementation.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.3_LLD_Campaigns_Lambda.md`

**Supporting Inputs**:
- Campaign types reference: `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/src/types/campaign.ts`

---

## Deliverables

Create `output.md` with the following sections:

### 1. API Endpoints Summary

Document all API endpoints:
- HTTP method and path
- Purpose
- Authentication requirements
- Request parameters

### 2. Request Formats

For each endpoint:
- Query parameters
- Path parameters
- Request body schema (if applicable)

### 3. Response Formats

For each endpoint:
- Success response structure
- Error response structures
- HTTP status codes

### 4. Data Models

Extract:
- Campaign entity fields
- Campaign status enum values
- Campaign response format
- Campaign list response format

### 5. Business Rules

Document:
- Campaign status calculation logic
- Price calculation (discount application)
- Campaign validity rules
- Soft delete behavior

### 6. Frontend Integration Requirements

Identify:
- Required API calls
- Response handling
- Error scenarios to handle
- Caching strategy

---

## Expected Output Format

```markdown
# LLD API Analysis Output

## 1. API Endpoints Summary

### GET /v1.0/campaigns
- **Purpose**: List all active campaigns
- **Authentication**: None (public)
- **Response**: 200 OK with campaign array

### GET /v1.0/campaigns/{code}
- **Purpose**: Get campaign by code
- **Authentication**: None (public)
- **Path Parameters**: `code` (string, required)
- **Response**: 200 OK with campaign object

## 2. Request Formats

### GET /v1.0/campaigns
No request body. Optional query parameters:
- `status`: Filter by status (DRAFT, ACTIVE, EXPIRED)

### GET /v1.0/campaigns/{code}
No request body. Path parameter:
- `code`: Campaign code (e.g., "SUMMER2025")

## 3. Response Formats

### List Campaigns Response (200 OK)
```json
{
  "campaigns": [...],
  "count": number
}
```

### Get Campaign Response (200 OK)
```json
{
  "campaign": {...}
}
```

### Error Response (404/500)
```json
{
  "error": "string",
  "message": "string"
}
```

## 4. Data Models

### Campaign Entity
| Field | Type | Description |
|-------|------|-------------|
| code | string | Unique identifier |
| name | string | Display name |
| productId | string | Associated product |
| discountPercent | number | Discount (0-100) |
| listPrice | number | Original price |
| price | number | Discounted price |
| status | string | DRAFT/ACTIVE/EXPIRED |
| fromDate | string | Start date (ISO) |
| toDate | string | End date (ISO) |
| isValid | boolean | Currently valid |

## 5. Business Rules

- Status is calculated based on current date
- Price = listPrice * (1 - discountPercent/100)
- isValid = true only when status is ACTIVE
- Only active=true campaigns returned

## 6. Frontend Integration Requirements

- Fetch campaigns on page load
- Apply campaign discount to pricing display
- Handle 404 for invalid campaign codes
- Cache campaigns for 5 minutes
- Fallback to no-discount display on API error
```

---

## Success Criteria

- [ ] All API endpoints documented
- [ ] Request formats complete
- [ ] Response formats with examples
- [ ] All data model fields listed
- [ ] Business rules extracted
- [ ] Frontend integration needs identified
- [ ] Output.md created with all sections

---

## Execution Steps

1. Read LLD Section 6 (REST API Operations)
2. Extract endpoint specifications
3. Document request/response formats
4. Read LLD Section 5 (Data Models)
5. Extract campaign entity structure
6. Read LLD Section 8 (NFRs) for performance targets
7. Note business rules from validation sections
8. Identify frontend integration requirements
9. Create output.md with all sections
10. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-18
