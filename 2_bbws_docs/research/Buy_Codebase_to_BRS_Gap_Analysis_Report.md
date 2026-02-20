# Buy Codebase to BRS Gap Analysis Report

**Version**: 1.0
**Created**: 2026-01-05
**Source**: `2_1_bbws_web_public/buy/` codebase
**Target**: `BRS/2.1_BRS_Customer_Portal_Public.md` (v1.1)
**Status**: Analysis Complete

---

## Executive Summary

This report documents findings from reverse engineering the Buy module codebase to validate and enhance the Business Requirements Specification (BRS). The analysis identified **19 gaps** and **12 undocumented features** implemented in code but not specified in BRS.

### Key Findings

| Category | Items Found | Status |
|----------|-------------|--------|
| Component Features | 15 | 8 Documented, 7 Undocumented |
| Validation Rules | 10 | 0 in BRS (Critical Gap) |
| API Integrations | 2 | Partially documented |
| Test Scenarios | 5 | 0 mapped to BRS |
| Configuration | 9 | Not in BRS |
| Business Rules | 12 | 0 in BRS (Critical Gap) |

---

## Phase 1: Component Feature Extraction

### 1.1 App.tsx - Main Application

**File**: `src/App.tsx` (Lines 1-69)

| Feature | Implementation | BRS Coverage | Gap ID |
|---------|----------------|--------------|--------|
| Product loading on mount | `useEffect` → `fetchProducts()` | EPIC1-US2 (partial) | - |
| Loading state display | Spinner while loading | Not specified | GAP-FE-001 |
| Fallback to local data | `fetchProducts` handles errors | Not specified | GAP-FE-002 |
| Plan selection state | `useState<PricingPlan>` | EPIC2-US1 | - |
| Navigation between pages | `showCheckout` boolean | Not specified | GAP-FE-003 |

**Undocumented Feature**: Error handling fallback to local product data when API fails.

### 1.2 PricingPage.tsx - Product Listing

**File**: `src/components/pricing/PricingPage.tsx` (Lines 1-115)

| Feature | Implementation | BRS Coverage | Gap ID |
|---------|----------------|--------------|--------|
| Page title | "Transparent Pricing" | Not specified | GAP-FE-004 |
| Page subtitle | "Choose the perfect plan..." | Not specified | GAP-FE-004 |
| Hover state on cards | `hoveredPlan` state | Not specified | GAP-FE-005 |
| Responsive grid layout | Flexbox with wrap | Not specified | GAP-FE-006 |
| Footer note | "All prices in ZAR, excl VAT" | Not specified | GAP-FE-007 |
| Contact link | "Contact our team" | Not specified | GAP-FE-008 |

**Business Rule Extracted**: All prices displayed in ZAR, excluding VAT.

### 1.3 PricingCard.tsx - Product Display

**File**: `src/components/pricing/PricingCard.tsx` (Lines 1-187)

| Feature | Implementation | BRS Coverage | Gap ID |
|---------|----------------|--------------|--------|
| "Most Popular" badge | `plan.popular` condition | Not specified | GAP-FE-009 |
| Gradient border styling | `plan.gradient` condition | Not specified | GAP-FE-010 |
| Card hover animation | `translateY(-8px)` | Not specified | GAP-FE-011 |
| Price display (ZAR) | `R{price}` format | EPIC1-US2 (partial) | - |
| POA pricing support | `price === 'POA'` | Not specified | GAP-FE-012 |
| Feature list display | Map over `plan.features` | EPIC1-US2 | - |
| Buy button | Click handler | EPIC2-US1 | - |

**Business Rule Extracted**: "Professional" plan is marked as "Most Popular" with special gradient styling.

### 1.4 CheckoutPage.tsx - Order Processing

**File**: `src/components/checkout/CheckoutPage.tsx` (Lines 1-192)

| Feature | Implementation | BRS Coverage | Gap ID |
|---------|----------------|--------------|--------|
| Form state management | 8 fields in `useState` | EPIC2-US1 (partial) | - |
| Validation on blur | `handleFieldBlur` | Not specified | GAP-FE-013 |
| Submit with validation | `validateOrderForm` | Not specified | GAP-FE-014 |
| Backend submission | `submitOrderToBackend` | EPIC2-US1 | - |
| Success message display | "Order submitted..." | EPIC2-US3 (partial) | - |
| Form reset on success | 2-second delay | Not specified | GAP-FE-015 |
| Auto-redirect to pricing | 3-second delay after reset | Not specified | GAP-FE-016 |
| Field-specific errors | `OrderValidationError` | Not specified | GAP-FE-017 |

**Undocumented Feature**: Auto-redirect to pricing page 5 seconds after successful order.

### 1.5 CustomerForm.tsx - Form Fields

**File**: `src/components/checkout/CustomerForm.tsx` (Lines 1-257)

| Form Field | Type | Required | Placeholder | BRS Coverage |
|------------|------|----------|-------------|--------------|
| fullName | text | Yes | "John Doe" | Not specified |
| email | email | Yes | "john@example.com" | Mentioned |
| phone | tel | Yes | "+27821234567" | Not specified |
| company | text | No | "Acme Corp (Optional)" | Not specified |
| address | text | Yes | "123 Main Street" | Mentioned |
| city | text | Yes | "Cape Town" | Not specified |
| postalCode | text | Yes | "8001" | Not specified |
| notes | textarea | No | "Any special requirements?" | Not specified |

**Gap**: BRS mentions "email and billing address" but lacks field-level specifications.

### 1.6 OrderSummary.tsx - Order Display

**File**: `src/components/checkout/OrderSummary.tsx` (Lines 1-100)

| Feature | Implementation | BRS Coverage |
|---------|----------------|--------------|
| Plan name display | `plan.name` | EPIC2-US1 |
| Price display | `plan.price` | EPIC2-US1 |
| Period display | `plan.period` | Not specified |
| Description display | `plan.description` | Not specified |
| Gradient border for popular | `plan.gradient` | Not specified |

---

## Phase 2: Validation Rules Extraction

### 2.1 Validation Rules from validation.ts

**File**: `src/utils/validation.ts` (Lines 1-414)

| Rule ID | Field | Validation Logic | Error Message | BRS |
|---------|-------|------------------|---------------|-----|
| VAL-001 | fullName | Required | "Full name is required" | No |
| VAL-002 | fullName | Min 2 chars | "Full name must be at least 2 characters" | No |
| VAL-003 | fullName | Two words (first + last) | "Please enter your first and last name" | No |
| VAL-004 | fullName | Letters, spaces, hyphens, apostrophes only | "Full name can only contain letters..." | No |
| VAL-005 | email | Required | "Email is required" | No |
| VAL-006 | email | RFC 5322 format | "Please enter a valid email address" | No |
| VAL-007 | email | Max 254 chars | "Email address is too long" | No |
| VAL-008 | email | TLD typo detection | "Please check your email address for typos" | No |
| VAL-009 | phone | Required | "Phone number is required" | No |
| VAL-010 | phone | Min 10 digits | "Phone number is too short" | No |
| VAL-011 | phone | Max 15 digits | "Phone number is too long" | No |
| VAL-012 | phone | SA format (+27/0) or E.164 | "Please enter a valid phone number..." | No |
| VAL-013 | company | Optional, max 100 chars | "Company name must not exceed 100 characters" | No |
| VAL-014 | address | Optional, max 200 chars | "Address must not exceed 200 characters" | No |
| VAL-015 | city | Optional, max 100 chars | "City must not exceed 100 characters" | No |
| VAL-016 | postalCode | Optional, alphanumeric 3-10 chars | "Please enter a valid postal code" | No |
| VAL-017 | notes | Optional, max 500 chars | "Notes must not exceed 500 characters" | No |

### 2.2 Regex Patterns

```typescript
// From validation.ts
EMAIL_REGEX = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/
SA_PHONE_REGEX = /^(\+27|0)[6-8][0-9]{8}$/
INTL_PHONE_REGEX = /^\+[1-9]\d{6,14}$/
POSTAL_CODE_REGEX = /^[A-Z0-9]{3,10}(\s?[A-Z0-9]{0,4})?$/i
VALID_NAME_REGEX = /^[a-zA-Z\s\-']+$/
```

### 2.3 Common Email Typos Detected

```typescript
commonTypos = ['gmial.com', 'gmai.com', 'yahooo.com', 'hotmial.com']
```

**Critical Gap**: All 17 validation rules are implemented but NOT documented in BRS.

---

## Phase 3: API Integration Analysis

### 3.1 Order API (orderApi.ts)

**File**: `src/services/orderApi.ts` (Lines 1-436)

| Feature | Implementation | BRS Coverage |
|---------|----------------|--------------|
| Endpoint | `POST ${baseUrl}/orders/v1.0/orders` | Appendix B |
| Auth header | `X-Api-Key: ${apiKey}` | Not specified |
| Timeout | Configurable per environment | Not specified |
| Retries | Exponential backoff | Not specified |
| Input sanitization | XSS prevention | Not specified |

**Data Transformation** (Lines 287-329):

```typescript
// Frontend → Backend Mapping
fullName → firstName + lastName (split on space)
email → customerEmail (lowercase, trimmed)
phone → primaryPhone
address → billingAddress.street
city → billingAddress.city
postalCode → billingAddress.postalCode
country → billingAddress.country (default: "ZA")
```

**Undocumented Feature**: Name splitting logic - if only one word, used for both first and last name.

### 3.2 Product API (productApi.ts)

**File**: `src/services/productApi.ts` (Lines 1-302)

| Feature | Implementation | BRS Coverage |
|---------|----------------|--------------|
| Endpoint | `GET ${baseUrl}/v1.0/products` | Appendix B |
| Caching | 5-minute in-memory cache | Not specified |
| Fallback | Local product data | Not specified |
| Price formatting | ZAR with locale | Not specified |
| "Popular" logic | `name === 'Professional'` | Not specified |

**Undocumented Feature**: "Professional" plan automatically marked as popular.

### 3.3 Error Handling

| Error Type | Handler | User Message |
|------------|---------|--------------|
| Network timeout | AbortController | "Request timed out..." |
| 400 Validation | OrderValidationError | Field-specific message |
| 5xx Server | Generic error | Original error message |
| Fetch failure | TypeError check | "Unable to connect..." |

---

## Phase 4: Configuration Analysis

### 4.1 Environment Variables

**File**: `.env.development`, `.env.example`

| Variable | Purpose | BRS Coverage |
|----------|---------|--------------|
| VITE_ENV | Environment identifier | Not specified |
| VITE_API_BASE_URL | API base URL | Not specified |
| VITE_ORDER_API_KEY | Order API authentication | Not specified |
| VITE_PRODUCT_API_KEY | Product API authentication | Not specified |
| VITE_ORDER_API_ENDPOINT | Order endpoint path | Appendix B |
| VITE_PRODUCT_API_ENDPOINT | Product endpoint path | Appendix B |
| VITE_DEBUG_MODE | Debug logging | Not specified |
| VITE_USE_MOCK_API | Mock API toggle | Not specified |

### 4.2 Environment-Specific Settings

**From config/index.ts**:

| Environment | Timeout | Retries |
|-------------|---------|---------|
| development | 10s | 2 |
| sit | 15s | 3 |
| production | 15s | 3 |

**Gap**: Environment-specific settings not documented in BRS NFRs.

---

## Phase 5: Type Definitions Analysis

### 5.1 CustomerFormData (form.ts)

```typescript
interface CustomerFormData {
  fullName: string;    // Required
  email: string;       // Required
  phone: string;       // Required
  company: string;     // Optional
  address: string;     // Optional in code, Required in UI
  city: string;        // Optional in code, Required in UI
  postalCode: string;  // Optional
  notes: string;       // Optional
}
```

**Gap**: Code has address/city as optional but UI requires them.

### 5.2 PricingPlan (product.ts)

| Field | Type | Purpose | BRS |
|-------|------|---------|-----|
| id | string | Unique ID | Yes |
| productId | string | API alias | No |
| name | string | Display name | Yes |
| price | string | Display price | Yes |
| priceNumeric | number | Calculation price | No |
| currency | string | Currency code | No |
| period | string | Billing period | Yes |
| description | string | Product description | Yes |
| features | string[] | Feature list | Yes |
| popular | boolean | "Most Popular" flag | No |
| gradient | boolean | Styling flag | No |
| active | boolean | Availability | Yes |

---

## Phase 6: Test Cases as Requirements

### 6.1 Integration Test Scenarios (userFlows.test.tsx)

| Test ID | Scenario | Steps | BRS Mapping |
|---------|----------|-------|-------------|
| IT-001 | Complete Purchase Flow | Pricing → Checkout → Submit → Success | EPIC2-US1, US2, US3 |
| IT-002 | Form Validation Flow | Submit Empty → Errors → Fix → Submit | Not explicit in BRS |
| IT-003 | Navigation Flow | Pricing → Checkout → Back → Pricing | Not in BRS |
| IT-004 | Error Handling Flow | Submit → API Failure → Error Message | Not explicit in BRS |
| IT-005 | Field-Level Validation | Blur → Error → Fix → Error Cleared | Not in BRS |

### 6.2 Validation Test Scenarios (validation.test.ts)

| Test Category | Test Count | Coverage |
|---------------|------------|----------|
| validateRequired | 4 | Full |
| validateMinLength | 3 | Full |
| validateMaxLength | 3 | Full |
| validateEmail | 7 | Full |
| validatePhone | 9 | Full |
| validateFullName | 6 | Full |
| validatePostalCode | 4 | Full |
| validateOrderForm | 7 | Full |
| getFieldValidator | 5 | Full |

**Gap**: Test scenarios not mapped to BRS acceptance criteria.

---

## Phase 7: Environment Files Analysis

### 7.1 API URLs by Environment

| Environment | Base URL | Account |
|-------------|----------|---------|
| DEV | `https://api.dev.kimmyai.io` | 536580886816 |
| SIT | `https://api.sit.kimmyai.io` | TBD |
| PROD | `https://api.kimmyai.io` | 093646564004 |

### 7.2 Feature Flags

| Flag | DEV | SIT | PROD | Purpose |
|------|-----|-----|------|---------|
| DEBUG_MODE | true | false | false | Console logging |
| USE_MOCK_API | false | false | false | Mock responses |

---

## Consolidated Gap Summary

### Critical Gaps (12 items)

| Gap ID | Category | Description | Recommendation |
|--------|----------|-------------|----------------|
| GAP-VAL-ALL | Validation | 17 validation rules not in BRS | Add Business Rules section |
| GAP-FE-013 | UX | Validation on blur not specified | Add to UI requirements |
| GAP-FE-014 | UX | Form validation before submit | Add acceptance criteria |
| GAP-FE-002 | Resilience | Fallback to local data | Add NFR |
| GAP-API-001 | API | Data transformation rules | Add to API spec |
| GAP-API-002 | API | Retry with exponential backoff | Add to NFR |
| GAP-API-003 | API | Input sanitization | Add to security |
| GAP-CFG-001 | Config | Environment-specific timeouts | Add to NFR |

### High Priority Gaps (7 items)

| Gap ID | Category | Description | Recommendation |
|--------|----------|-------------|----------------|
| GAP-FE-001 | UX | Loading spinner | Add UI requirement |
| GAP-FE-009 | UI | "Most Popular" badge | Add product display rules |
| GAP-FE-015 | UX | Form reset timing (2s) | Add to success flow |
| GAP-FE-016 | UX | Auto-redirect timing (3s) | Add to success flow |
| GAP-TEST-001 | QA | Test → BRS traceability | Create test matrix |

---

## Undocumented Features Summary

| # | Feature | Location | Recommendation |
|---|---------|----------|----------------|
| 1 | API fallback to local products | productApi.ts:242-248 | Document as resilience feature |
| 2 | 5-minute product cache | productApi.ts:58-76 | Document as performance optimization |
| 3 | Name splitting logic | orderApi.ts:292-294 | Document data transformation |
| 4 | "Professional" auto-popular | productApi.ts:127 | Document product display rules |
| 5 | Email typo detection | validation.ts:162-169 | Document as UX enhancement |
| 6 | Phone normalization | validation.ts:179-183 | Document input processing |
| 7 | Form reset + auto-redirect | CheckoutPage.tsx:93-108 | Document success flow |
| 8 | Gradient styling for popular | PricingCard.tsx:44-48 | Document UI patterns |
| 9 | POA pricing support | PricingCard.tsx:105-106 | Document price display rules |
| 10 | Card hover animation | PricingCard.tsx:47 | Document micro-interactions |
| 11 | Validation on blur | CheckoutPage.tsx:54-65 | Document validation timing |
| 12 | Debug mode logging | config/index.ts:144-148 | Document operational features |

---

## Recommended BRS Updates

### 1. Add Business Rules Section with Validation Rules

```markdown
### 3.5.1 Form Field Validation Rules (BR-VAL)

| Rule ID | Field | Validation | Error Message |
|---------|-------|------------|---------------|
| BR-VAL-001 | fullName | Required, min 2 chars, two words, letters only | See table above |
| BR-VAL-002 | email | Required, RFC 5322, max 254 chars, typo check | See table above |
| BR-VAL-003 | phone | Required, SA (+27/0) or E.164 format | See table above |
| BR-VAL-004 | postalCode | Optional, alphanumeric 3-14 chars | See table above |
| BR-VAL-005 | company | Optional, max 100 chars | See table above |
| BR-VAL-006 | address | Required (UI), max 200 chars | See table above |
| BR-VAL-007 | city | Required (UI), max 100 chars | See table above |
| BR-VAL-008 | notes | Optional, max 500 chars | See table above |
```

### 2. Add Data Transformation Rules

```markdown
### 3.5.2 Data Transformation Rules (BR-DATA)

| Rule ID | Transformation | Logic |
|---------|----------------|-------|
| BR-DATA-001 | Name splitting | Split fullName on space → firstName + lastName |
| BR-DATA-002 | Email normalization | Trim and lowercase |
| BR-DATA-003 | Phone normalization | Remove spaces, dashes, parentheses |
| BR-DATA-004 | Default country | Set to "ZA" if not provided |
```

### 3. Add Product Display Rules

```markdown
### 3.5.3 Product Display Rules (BR-PROD)

| Rule ID | Rule | Implementation |
|---------|------|----------------|
| BR-PROD-001 | Popular badge | Show "Most Popular" when plan.popular=true |
| BR-PROD-002 | Gradient styling | Apply gradient border when plan.gradient=true |
| BR-PROD-003 | POA pricing | Display "POA" when price=0 |
| BR-PROD-004 | Currency format | Display "R{amount}" for ZAR |
```

### 4. Add Resilience Requirements to NFRs

```markdown
### 4.1.3 Resilience Requirements

| Requirement | Specification |
|-------------|---------------|
| API Timeout | DEV: 10s, SIT/PROD: 15s |
| Retry Policy | Exponential backoff (1s, 2s, 4s...) |
| Max Retries | DEV: 2, SIT/PROD: 3 |
| Fallback | Local product data on API failure |
| Caching | 5-minute in-memory product cache |
```

### 5. Add UX Timing Requirements

```markdown
### 4.1.4 UX Timing Requirements

| Action | Timing | Description |
|--------|--------|-------------|
| Form reset | 2 seconds | Reset form after successful order |
| Auto-redirect | 5 seconds | Redirect to pricing after success |
| Validation on blur | Immediate | Validate field when focus leaves |
| Loading spinner | Until hydration | Show while loading products |
```

---

## Traceability Matrix

### Code → BRS Mapping

| Code Location | Feature | BRS Reference | Status |
|---------------|---------|---------------|--------|
| App.tsx:24-38 | Product loading | EPIC1-US2 | Partial |
| PricingPage.tsx | Product display | EPIC1-US2 | Partial |
| CheckoutPage.tsx | Order form | EPIC2-US1 | Partial |
| validation.ts | All validation | Not in BRS | Gap |
| orderApi.ts | Order submission | EPIC2-US1 | Partial |
| productApi.ts | Product fetching | EPIC1-US2 | Partial |

### Test → BRS Mapping

| Test File | Test Scenario | BRS Reference | Status |
|-----------|---------------|---------------|--------|
| userFlows.test.tsx:34 | Complete Purchase | EPIC2-US1,2,3 | Partial |
| userFlows.test.tsx:121 | Form Validation | Not in BRS | Gap |
| userFlows.test.tsx:175 | Navigation | Not in BRS | Gap |
| userFlows.test.tsx:212 | Error Handling | Not in BRS | Gap |
| validation.test.ts | All validation | Not in BRS | Gap |

---

## Next Steps

1. **Immediate**: Add validation rules to BRS (Critical)
2. **Short-term**: Add data transformation rules (High)
3. **Short-term**: Add product display rules (High)
4. **Medium-term**: Add resilience requirements (Medium)
5. **Medium-term**: Create test traceability matrix (Medium)

---

**End of Report**
