# Worker 1-1: LLD API Analysis Output

**Worker ID**: Worker 1-1
**Task**: LLD API Analysis for Campaigns Frontend
**Status**: COMPLETE
**Source Document**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.3_LLD_Campaigns_Lambda.md`
**Created**: 2026-01-18

---

## 1. API Endpoints Summary

### 1.1 Public Endpoints (No Authentication Required)

| Method | Endpoint | Purpose | Auth |
|--------|----------|---------|------|
| GET | `/v1.0/campaigns` | List all active campaigns | None (public) |
| GET | `/v1.0/campaigns/{code}` | Get campaign by unique code | None (public) |

### 1.2 Admin Endpoints (Authentication Required - Future)

| Method | Endpoint | Purpose | Auth |
|--------|----------|---------|------|
| POST | `/v1.0/campaigns` | Create new campaign | Admin role |
| PUT | `/v1.0/campaigns/{code}` | Update existing campaign | Admin role |
| DELETE | `/v1.0/campaigns/{code}` | Soft delete campaign | Admin role |

**Note**: For the pricing page frontend, only the GET endpoints are required.

---

## 2. Request Formats

### 2.1 GET /v1.0/campaigns (List Campaigns)

**Query Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| status | string | No | Filter by status (DRAFT, ACTIVE, EXPIRED) |

**Request Headers**:
```
Accept: application/json
```

**Example Request**:
```http
GET /v1.0/campaigns HTTP/1.1
Host: api.kimmyai.io
Accept: application/json
```

**Example with Status Filter**:
```http
GET /v1.0/campaigns?status=ACTIVE HTTP/1.1
Host: api.kimmyai.io
Accept: application/json
```

### 2.2 GET /v1.0/campaigns/{code} (Get Campaign by Code)

**Path Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| code | string | Yes | Unique campaign code (e.g., SUMMER2025) |

**Request Headers**:
```
Accept: application/json
```

**Example Request**:
```http
GET /v1.0/campaigns/SUMMER2025 HTTP/1.1
Host: api.kimmyai.io
Accept: application/json
```

---

## 3. Response Formats

### 3.1 List Campaigns Response (200 OK)

```json
{
  "campaigns": [
    {
      "code": "SUMMER2025",
      "name": "Summer Sale 2025",
      "productId": "PROD-002",
      "discountPercent": 20,
      "listPrice": 1500.00,
      "price": 1200.00,
      "termsAndConditions": "Valid for new customers only.",
      "status": "ACTIVE",
      "fromDate": "2025-06-01T00:00:00Z",
      "toDate": "2025-08-31T23:59:59Z",
      "specialConditions": "Minimum purchase of R500 required",
      "isValid": true
    },
    {
      "code": "NEWYEAR2025",
      "name": "New Year Special",
      "productId": "PROD-001",
      "discountPercent": 15,
      "listPrice": 95.00,
      "price": 80.75,
      "termsAndConditions": "Limited time offer.",
      "status": "ACTIVE",
      "fromDate": "2025-01-01T00:00:00Z",
      "toDate": "2025-01-31T23:59:59Z",
      "specialConditions": null,
      "isValid": true
    }
  ],
  "count": 2
}
```

### 3.2 Get Campaign Response (200 OK)

```json
{
  "campaign": {
    "code": "SUMMER2025",
    "name": "Summer Sale 2025",
    "productId": "PROD-002",
    "discountPercent": 20,
    "listPrice": 1500.00,
    "price": 1200.00,
    "termsAndConditions": "Valid for new customers only. Cannot be combined with other offers.",
    "status": "ACTIVE",
    "fromDate": "2025-06-01T00:00:00Z",
    "toDate": "2025-08-31T23:59:59Z",
    "specialConditions": "Minimum purchase of R500 required",
    "isValid": true
  }
}
```

### 3.3 Error Response Structures

#### 404 Not Found (Campaign)
```json
{
  "error": "Campaign not found",
  "message": "Campaign with code SUMMER2025 does not exist or is inactive"
}
```

#### 400 Bad Request (Invalid Campaign Code)
```json
{
  "error": "Invalid request",
  "message": "Campaign code is required"
}
```

#### 500 Internal Server Error
```json
{
  "error": "Internal server error",
  "message": "An unexpected error occurred"
}
```

#### 503 Service Unavailable
```json
{
  "error": "Service unavailable",
  "message": "DynamoDB is temporarily unavailable"
}
```

### 3.4 HTTP Status Codes Summary

| Status Code | Description | When Returned |
|-------------|-------------|---------------|
| 200 OK | Success | GET requests successful |
| 400 Bad Request | Invalid request | Missing/invalid campaign code |
| 404 Not Found | Resource not found | Campaign code doesn't exist or inactive |
| 500 Internal Server Error | Server error | Unexpected errors |
| 503 Service Unavailable | Service down | DynamoDB unavailable |

---

## 4. Data Models

### 4.1 Campaign Entity Fields

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| code | string | Yes | Unique campaign code | "SUMMER2025" |
| name | string | Yes | Campaign display name | "Summer Sale 2025" |
| productId | string | Yes | Associated product ID | "PROD-002" |
| discountPercent | integer | Yes | Discount percentage (0-100) | 20 |
| listPrice | number | Yes | Original price before discount | 1500.00 |
| price | number | Yes | Calculated discounted price | 1200.00 |
| termsAndConditions | string | Yes | Campaign terms and conditions | "Valid for new customers only." |
| status | CampaignStatus | Yes | Campaign state | "ACTIVE" |
| fromDate | string (ISO 8601) | Yes | Start date | "2025-06-01T00:00:00Z" |
| toDate | string (ISO 8601) | Yes | End date | "2025-08-31T23:59:59Z" |
| specialConditions | string | null | No | Additional conditions | "Minimum purchase of R500 required" |
| isValid | boolean | Yes | Whether campaign is currently valid | true |

### 4.2 CampaignStatus Enum Values

```typescript
enum CampaignStatus {
  DRAFT = "DRAFT",    // Campaign scheduled for future (fromDate > now)
  ACTIVE = "ACTIVE",  // Campaign currently valid (fromDate <= now <= toDate)
  EXPIRED = "EXPIRED" // Campaign ended (toDate < now)
}
```

### 4.3 TypeScript Interface Definitions

```typescript
// Campaign response from single campaign endpoint
interface CampaignResponse {
  code: string;
  name: string;
  productId: string;
  discountPercent: number;
  listPrice: number;
  price: number;
  termsAndConditions: string;
  status: CampaignStatus;
  fromDate: string;  // ISO 8601
  toDate: string;    // ISO 8601
  specialConditions: string | null;
  isValid: boolean;
}

// Response wrapper for single campaign
interface GetCampaignResponse {
  campaign: CampaignResponse;
}

// Response wrapper for campaign list
interface ListCampaignsResponse {
  campaigns: CampaignResponse[];
  count: number;
}

// Error response structure
interface ApiErrorResponse {
  error: string;
  message: string;
}
```

### 4.4 JSON Schema for Campaign Response

```json
{
  "type": "object",
  "properties": {
    "code": {"type": "string"},
    "name": {"type": "string"},
    "productId": {"type": "string"},
    "discountPercent": {"type": "integer", "minimum": 0, "maximum": 100},
    "listPrice": {"type": "number"},
    "price": {"type": "number"},
    "termsAndConditions": {"type": "string"},
    "status": {"type": "string", "enum": ["DRAFT", "ACTIVE", "EXPIRED"]},
    "fromDate": {"type": "string", "format": "date-time"},
    "toDate": {"type": "string", "format": "date-time"},
    "specialConditions": {"type": "string", "nullable": true},
    "isValid": {"type": "boolean"}
  },
  "required": ["code", "name", "productId", "discountPercent", "listPrice", "price", "termsAndConditions", "status", "fromDate", "toDate", "isValid"]
}
```

---

## 5. Business Rules

### 5.1 Status Calculation Logic

Status is **dynamically calculated** based on current date:

```typescript
function calculateStatus(fromDate: Date, toDate: Date): CampaignStatus {
  const now = new Date();

  if (now < fromDate) {
    return CampaignStatus.DRAFT;    // Future campaign
  } else if (now >= fromDate && now <= toDate) {
    return CampaignStatus.ACTIVE;   // Current campaign
  } else {
    return CampaignStatus.EXPIRED;  // Past campaign
  }
}
```

### 5.2 Price Calculation Formula

```typescript
function calculatePrice(listPrice: number, discountPercent: number): number {
  return listPrice * (1 - discountPercent / 100);
}

// Examples:
// listPrice: 1500.00, discountPercent: 20 => price: 1200.00
// listPrice: 95.00, discountPercent: 15 => price: 80.75
// listPrice: 3500.00, discountPercent: 25 => price: 2625.00
```

### 5.3 Campaign Validity Rules

1. **Active Flag**: Only campaigns with `active=true` are returned in API responses
2. **isValid Calculation**: `isValid = true` only when `status === "ACTIVE"`
3. **Soft Delete**: Inactive campaigns (active=false) return 404 on individual GET
4. **Date Validation**: `toDate` must be after `fromDate`
5. **Sort Order**: Campaigns are returned sorted by `fromDate` (newest first)
6. **Empty List**: Returns empty array `{ campaigns: [], count: 0 }` if no active campaigns

### 5.4 Discount Percent Constraints

- Minimum: 0 (no discount)
- Maximum: 100 (free)
- Type: Integer (no decimal discounts)

---

## 6. Frontend Integration Requirements

### 6.1 Required API Calls for Pricing Page

#### Primary Call: List All Active Campaigns
```typescript
// Fetch all campaigns for pricing page display
async function fetchCampaigns(): Promise<ListCampaignsResponse> {
  const response = await fetch('https://api.kimmyai.io/v1.0/campaigns', {
    method: 'GET',
    headers: {
      'Accept': 'application/json'
    }
  });

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }

  return response.json();
}
```

#### Secondary Call: Get Single Campaign (for detail view)
```typescript
// Fetch specific campaign by code
async function fetchCampaign(code: string): Promise<GetCampaignResponse> {
  const response = await fetch(`https://api.kimmyai.io/v1.0/campaigns/${code}`, {
    method: 'GET',
    headers: {
      'Accept': 'application/json'
    }
  });

  if (response.status === 404) {
    throw new Error('Campaign not found');
  }

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }

  return response.json();
}
```

### 6.2 Response Handling Requirements

#### Success Handling
```typescript
// Example success handler
function handleCampaignsSuccess(data: ListCampaignsResponse): void {
  // Filter to only show valid campaigns if needed
  const validCampaigns = data.campaigns.filter(c => c.isValid);

  // Sort by discount (highest first) or price (lowest first)
  const sortedByDiscount = [...validCampaigns].sort(
    (a, b) => b.discountPercent - a.discountPercent
  );

  // Display on pricing page
  renderPricingCards(sortedByDiscount);
}
```

#### Error Handling
```typescript
// Comprehensive error handler
function handleApiError(error: Response | Error): void {
  if (error instanceof Response) {
    switch (error.status) {
      case 400:
        console.error('Invalid request');
        break;
      case 404:
        console.error('Campaign not found');
        break;
      case 500:
        console.error('Server error - please try again later');
        break;
      case 503:
        console.error('Service temporarily unavailable');
        break;
      default:
        console.error(`Unexpected error: ${error.status}`);
    }
  } else {
    console.error('Network error:', error.message);
  }
}
```

### 6.3 Error Scenarios to Handle

| Scenario | Status Code | User Message | Action |
|----------|-------------|--------------|--------|
| Network offline | - | "Unable to connect. Check your internet." | Show retry button |
| API timeout | - | "Request timed out. Please try again." | Auto-retry with backoff |
| Campaign not found | 404 | "This offer is no longer available." | Redirect to campaigns list |
| Invalid code format | 400 | "Invalid campaign link." | Show error page |
| Server error | 500 | "Something went wrong. Please try again." | Show retry button |
| Service unavailable | 503 | "Service is temporarily unavailable." | Show maintenance message |
| Empty campaign list | 200 | "No special offers available at this time." | Show empty state |

### 6.4 Caching Strategy

**CloudFront Cache Configuration**:
- **Cache TTL**: 5 minutes (300 seconds)
- **Cache Key**: Full URL path
- **Cache Invalidation**: On campaign create/update/delete (admin operations)

**Frontend Caching Recommendations**:

```typescript
// React Query / TanStack Query configuration
const campaignsQueryConfig = {
  staleTime: 5 * 60 * 1000,      // 5 minutes - matches CloudFront
  cacheTime: 30 * 60 * 1000,     // 30 minutes in memory
  refetchOnWindowFocus: false,   // Rely on staleTime
  retry: 3,                       // Retry failed requests
  retryDelay: (attemptIndex: number) => Math.min(1000 * 2 ** attemptIndex, 30000)
};

// Usage with React Query
const { data, error, isLoading } = useQuery({
  queryKey: ['campaigns'],
  queryFn: fetchCampaigns,
  ...campaignsQueryConfig
});
```

**SWR Configuration**:
```typescript
// SWR configuration
const swrConfig = {
  revalidateOnFocus: false,
  revalidateOnReconnect: true,
  refreshInterval: 5 * 60 * 1000,  // 5 minutes
  dedupingInterval: 60 * 1000,     // 1 minute deduplication
  errorRetryCount: 3,
  errorRetryInterval: 5000
};
```

### 6.5 Mock Data for Development

```typescript
// Mock campaigns for local development
export const MOCK_CAMPAIGNS: ListCampaignsResponse = {
  campaigns: [
    {
      code: "SUMMER2025",
      name: "Summer Sale 2025",
      productId: "PROD-002",
      discountPercent: 20,
      listPrice: 1500.00,
      price: 1200.00,
      termsAndConditions: "Valid for new customers only. Cannot be combined with other offers.",
      status: "ACTIVE",
      fromDate: "2025-06-01T00:00:00Z",
      toDate: "2025-08-31T23:59:59Z",
      specialConditions: "Minimum purchase of R500 required",
      isValid: true
    },
    {
      code: "NEWYEAR2025",
      name: "New Year Special",
      productId: "PROD-001",
      discountPercent: 15,
      listPrice: 95.00,
      price: 80.75,
      termsAndConditions: "Limited time offer.",
      status: "ACTIVE",
      fromDate: "2025-01-01T00:00:00Z",
      toDate: "2025-01-31T23:59:59Z",
      specialConditions: null,
      isValid: true
    },
    {
      code: "WINTER2025",
      name: "Winter Warmup Sale",
      productId: "PROD-003",
      discountPercent: 25,
      listPrice: 3500.00,
      price: 2625.00,
      termsAndConditions: "Valid for all customers. One use per customer.",
      status: "DRAFT",
      fromDate: "2025-07-01T00:00:00Z",
      toDate: "2025-08-31T23:59:59Z",
      specialConditions: "Cannot be combined with loyalty discounts",
      isValid: false
    },
    {
      code: "BLACKFRIDAY2024",
      name: "Black Friday 2024",
      productId: "PROD-001",
      discountPercent: 50,
      listPrice: 200.00,
      price: 100.00,
      termsAndConditions: "One day only. While stocks last.",
      status: "EXPIRED",
      fromDate: "2024-11-29T00:00:00Z",
      toDate: "2024-11-29T23:59:59Z",
      specialConditions: null,
      isValid: false
    }
  ],
  count: 4
};

// Mock API service for development
export const mockCampaignApi = {
  async listCampaigns(): Promise<ListCampaignsResponse> {
    // Simulate network delay
    await new Promise(resolve => setTimeout(resolve, 500));

    // Return only active campaigns (as the real API does)
    const activeCampaigns = MOCK_CAMPAIGNS.campaigns.filter(c => c.isValid);
    return {
      campaigns: activeCampaigns,
      count: activeCampaigns.length
    };
  },

  async getCampaign(code: string): Promise<GetCampaignResponse> {
    await new Promise(resolve => setTimeout(resolve, 300));

    const campaign = MOCK_CAMPAIGNS.campaigns.find(c => c.code === code);
    if (!campaign || !campaign.isValid) {
      throw new Error('Campaign not found');
    }

    return { campaign };
  }
};
```

### 6.6 Environment-Specific API URLs

```typescript
// Environment configuration
const API_BASE_URLS = {
  development: 'http://localhost:3000/v1.0',  // Local mock server
  dev: 'https://api-dev.kimmyai.io/v1.0',     // DEV environment
  sit: 'https://api-sit.kimmyai.io/v1.0',     // SIT environment
  prod: 'https://api.kimmyai.io/v1.0'         // Production
};

// Get base URL from environment
const getApiBaseUrl = (): string => {
  const env = import.meta.env.VITE_ENV || 'development';
  return API_BASE_URLS[env as keyof typeof API_BASE_URLS] || API_BASE_URLS.development;
};
```

---

## 7. Performance Targets

| Metric | Target | Notes |
|--------|--------|-------|
| List campaigns latency (p95) | < 300ms | Includes CloudFront cache |
| Get campaign latency (p95) | < 100ms | Direct DynamoDB lookup |
| Cache hit ratio | > 90% | CloudFront caching |
| Cold start | < 500ms | arm64 architecture |

---

## 8. Security Considerations

1. **CORS**: API Gateway configured for web client origins
2. **Rate Limiting**: 100 requests/second for public endpoints
3. **No PII**: Campaign data contains no personal information
4. **Input Validation**: Campaign codes validated against pattern `^[A-Z0-9_-]+$`
5. **Request Size Limit**: 10KB maximum request body

---

## Summary

For the Campaigns Frontend pricing page implementation:

1. **Primary Endpoint**: `GET /v1.0/campaigns` - Lists all active campaigns
2. **Detail Endpoint**: `GET /v1.0/campaigns/{code}` - Gets single campaign details
3. **No Authentication**: Both public endpoints require no auth
4. **Key Fields**: `price`, `listPrice`, `discountPercent`, `status`, `isValid`
5. **Cache Strategy**: 5-minute cache with React Query/SWR
6. **Mock Data**: Available for local development without API dependency

---

**Worker Status**: COMPLETE
**Output Validated**: Yes
**Next Worker**: Worker 1-2 (Existing Code Audit)
