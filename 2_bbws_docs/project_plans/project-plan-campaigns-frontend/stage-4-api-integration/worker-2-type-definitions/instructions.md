# Worker Instructions: Type Definitions

**Worker ID**: worker-2-type-definitions
**Stage**: Stage 4 - API Integration
**Project**: project-plan-campaigns-frontend

---

## Task

Validate and extend TypeScript type definitions to match the LLD API response schemas. Ensure all campaign-related types are complete and properly exported.

---

## Inputs

**Primary Inputs**:
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/src/types/campaign.ts`
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/src/types/index.ts`

**Reference**:
- LLD Section 5: Data Models
- LLD Section 6: Response Schemas
- Stage 1 worker-1 output (API Analysis)

---

## Deliverables

Create `output.md` documenting:

### 1. Current Type Analysis

Review existing types and compare with LLD requirements.

### 2. Campaign Types

Validate/create:
- `CampaignStatus` enum/type
- `Campaign` interface
- `CampaignResponse` interface
- `CampaignListResponse` interface

### 3. Extended Types

Types for frontend use:
- `AppliedCampaign` (with savingsAmount)
- `PlanWithCampaign` (plan + campaign context)

### 4. API Error Types

Create if missing:
- `ApiError` interface
- `CampaignNotFoundError`

---

## Expected Output Format

```markdown
# Type Definitions Output

## 1. Current Type Analysis

### Existing Types in campaign.ts
| Type | Present | Matches LLD |
|------|---------|-------------|
| CampaignStatus | Yes | Verify values |
| Campaign | Yes | Verify fields |
| CampaignListResponse | Yes | Verify structure |
| CampaignResponse | Yes | Verify structure |
| AppliedCampaign | Yes | Verify fields |
| PlanWithCampaign | Yes | Verify fields |

### Missing Types
- [ ] termsAndConditions field in Campaign
- [ ] specialConditions field in Campaign
- [ ] API error types

## 2. Campaign Types

### CampaignStatus
```typescript
/**
 * Campaign status values
 * - DRAFT: Campaign not yet active (fromDate in future)
 * - ACTIVE: Campaign currently valid
 * - EXPIRED: Campaign ended (toDate in past)
 */
export type CampaignStatus = 'DRAFT' | 'ACTIVE' | 'EXPIRED';
```

### Campaign Interface
```typescript
/**
 * Campaign entity from Campaign API
 * Matches LLD Section 5.2 response schema
 */
export interface Campaign {
  /** Unique campaign code (e.g., "SUMMER2025") */
  code: string;

  /** Campaign display name */
  name: string;

  /** Product ID this campaign applies to */
  productId: string;

  /** Discount percentage (0-100) */
  discountPercent: number;

  /** Original list price before discount */
  listPrice: number;

  /** Calculated discounted price */
  price: number;

  /** Terms and conditions text */
  termsAndConditions?: string;

  /** Campaign status (DRAFT, ACTIVE, EXPIRED) */
  status: CampaignStatus;

  /** Start date (ISO 8601) */
  fromDate: string;

  /** End date (ISO 8601) */
  toDate: string;

  /** Additional conditions (optional) */
  specialConditions?: string;

  /** Whether campaign is currently valid */
  isValid: boolean;
}
```

### CampaignListResponse
```typescript
/**
 * Response from GET /v1.0/campaigns
 */
export interface CampaignListResponse {
  /** Array of campaigns */
  campaigns: Campaign[];

  /** Total count */
  count: number;
}
```

### CampaignResponse
```typescript
/**
 * Response from GET /v1.0/campaigns/{code}
 */
export interface CampaignResponse {
  /** Campaign data */
  campaign: Campaign;
}
```

## 3. Extended Types

### AppliedCampaign
```typescript
/**
 * Campaign with calculated savings
 * Used when displaying campaign on pricing card
 */
export interface AppliedCampaign extends Campaign {
  /** Calculated savings amount (listPrice - price) */
  savingsAmount: number;
}
```

### PlanWithCampaign
```typescript
/**
 * Pricing plan combined with optional campaign
 * Used in checkout flow
 */
export interface PlanWithCampaign {
  /** Original pricing plan ID */
  planId: string;

  /** Applied campaign (null if none) */
  campaign: Campaign | null;

  /** Original price (plan.priceNumeric) */
  originalPrice: number;

  /** Final price (with discount if applicable) */
  finalPrice: number;

  /** Whether discount is applied */
  hasDiscount: boolean;

  /** Discount percentage (0 if no campaign) */
  discountPercent: number;
}
```

## 4. API Error Types

### ApiError
```typescript
/**
 * Standard API error response
 */
export interface ApiError {
  /** Error type */
  error: string;

  /** Human-readable message */
  message: string;

  /** HTTP status code */
  statusCode?: number;
}
```

### Type Guards
```typescript
/**
 * Type guard for Campaign
 */
export const isCampaign = (obj: unknown): obj is Campaign => {
  return (
    typeof obj === 'object' &&
    obj !== null &&
    'code' in obj &&
    'discountPercent' in obj &&
    'isValid' in obj
  );
};
```

## 5. Index Export

### types/index.ts
```typescript
// Campaign types
export type { Campaign, CampaignStatus, CampaignListResponse, CampaignResponse } from './campaign';
export type { AppliedCampaign, PlanWithCampaign } from './campaign';
export { isCampaign } from './campaign';

// Product types
export type { PricingPlan } from './product';

// Form types
export type { CustomerForm, FormField } from './form';

// API types
export type { ApiError } from './api';
```

## 6. Validation Checklist

- [ ] All LLD fields present in Campaign
- [ ] Types match API response exactly
- [ ] Optional fields marked correctly
- [ ] JSDoc comments complete
- [ ] Types exported from index.ts
- [ ] Type guards provided
```

---

## Success Criteria

- [ ] All campaign types validated
- [ ] Types match LLD specification
- [ ] Extended types documented
- [ ] API error types created
- [ ] Type guards implemented
- [ ] Exports consolidated
- [ ] Output.md created with all sections

---

## Execution Steps

1. Read current campaign.ts
2. Compare with LLD Section 5.2
3. Identify missing/incorrect fields
4. Document required updates
5. Review extended types
6. Document error types
7. Verify index.ts exports
8. Create output.md with all sections
9. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-18
