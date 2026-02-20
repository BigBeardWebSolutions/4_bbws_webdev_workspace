# BRS Reverse Engineering Plan: Buy Codebase

**Version**: 1.0
**Created**: 2026-01-05
**Source Codebase**: `2_1_bbws_web_public/buy`
**Target Document**: `BRS/2.1_BRS_Customer_Portal_Public.md`
**Status**: Plan Ready for Execution

---

## 1. Objective

Reverse engineer the Buy module codebase to extract implemented business requirements and validate/update the Business Requirements Specification (BRS).

### 1.1 Goals

1. **Code-to-Requirement Mapping**: Map implemented features to BRS requirements
2. **Undocumented Features**: Identify features implemented but not in BRS
3. **Gap Identification**: Find BRS requirements not implemented
4. **Technical Constraints**: Extract implementation-driven business rules
5. **Test Coverage**: Map tests to requirements for validation

---

## 2. Codebase Analysis Overview

### 2.1 Directory Structure

```
buy/
├── src/
│   ├── App.tsx                      # Main app, routing logic
│   ├── components/
│   │   ├── checkout/
│   │   │   ├── CheckoutPage.tsx     # Checkout container
│   │   │   ├── CustomerForm.tsx     # Customer details form
│   │   │   ├── FormField.tsx        # Reusable input field
│   │   │   └── OrderSummary.tsx     # Order summary display
│   │   ├── pricing/
│   │   │   ├── PricingPage.tsx      # Product listing
│   │   │   ├── PricingCard.tsx      # Individual product card
│   │   │   └── PricingFeature.tsx   # Feature list item
│   │   └── layout/
│   │       ├── PageLayout.tsx       # Layout wrapper
│   │       └── Navigation.tsx       # Navigation bar
│   ├── services/
│   │   ├── orderApi.ts              # Order submission
│   │   └── productApi.ts            # Product fetching
│   ├── config/
│   │   └── index.ts                 # Environment config
│   ├── types/
│   │   ├── api.ts                   # API types
│   │   ├── form.ts                  # Form types
│   │   ├── product.ts               # Product types
│   │   └── index.ts                 # Type exports
│   ├── utils/
│   │   └── validation.ts            # Form validation
│   └── test/
│       ├── integration/
│       │   └── userFlows.test.tsx   # E2E user flows
│       └── setup.ts                 # Test setup
├── .env.development                  # Dev environment
├── .env.sit                          # SIT environment
├── .env.production                   # Prod environment
└── package.json                      # Dependencies
```

### 2.2 Key Files for Analysis

| File | Analysis Purpose | Priority |
|------|-----------------|----------|
| `App.tsx` | Main routing, state management | High |
| `CheckoutPage.tsx` | Checkout flow logic | High |
| `CustomerForm.tsx` | Form fields, UX | High |
| `validation.ts` | Business validation rules | High |
| `orderApi.ts` | API integration, transformations | High |
| `config/index.ts` | Environment handling | Medium |
| `types/*.ts` | Data models | Medium |
| `*.test.tsx` | Test scenarios = requirements | High |

---

## 3. Reverse Engineering Phases

### Phase 1: Component Feature Extraction (Priority: High)

**Objective**: Extract features from each React component

#### 3.1.1 App.tsx Analysis

**Current Implementation**:
```typescript
// Extracted features from App.tsx
- State: products, isLoading, selectedPlan, showCheckout
- Actions: handleSelectPlan, handleBackToPricing
- API: fetchProducts on mount with fallback
```

**BRS Requirements to Extract**:
| Feature | User Story Mapping | Status |
|---------|-------------------|--------|
| Load products on mount | EPIC1-US2 | Verify |
| Fallback to local data | Resilience requirement | Document |
| Plan selection flow | EPIC2-US1 | Verify |
| Back navigation | Navigation requirement | Document |

#### 3.1.2 PricingPage/PricingCard Analysis

**Files**: `PricingPage.tsx`, `PricingCard.tsx`, `PricingFeature.tsx`

**Features to Extract**:
- Product display format
- Price formatting (ZAR)
- Feature list display
- "Popular" badge logic
- "Buy Now" CTA behavior

#### 3.1.3 CheckoutPage Analysis

**File**: `CheckoutPage.tsx`

**Features to Extract**:
- Form state management
- Validation on blur
- Submit flow
- Success/error handling
- Redirect after success

#### 3.1.4 CustomerForm Analysis

**File**: `CustomerForm.tsx`

**Features to Extract**:
- Field definitions
- Required vs optional fields
- Input types (text, email, tel, textarea)
- Error display pattern

### Phase 2: Validation Rules Extraction (Priority: High)

**File**: `utils/validation.ts`

**Objective**: Extract all validation rules as business rules

| Field | Validation Rule | BRS Mapping |
|-------|----------------|-------------|
| fullName | Required, min 2 chars | BR-VAL-001 |
| email | Required, valid format | BR-VAL-002 |
| phone | Required, E.164 format | BR-VAL-003 |
| address | Required, min 5 chars | BR-VAL-004 |
| city | Required, min 2 chars | BR-VAL-005 |
| postalCode | Required, 4-10 chars | BR-VAL-006 |
| company | Optional | BR-VAL-007 |
| notes | Optional, max 500 chars | BR-VAL-008 |

**Tasks**:
1. Read `validation.ts` fully
2. Document each validation function
3. Extract regex patterns
4. Map to BRS business rules

### Phase 3: API Integration Analysis (Priority: High)

**File**: `services/orderApi.ts`

**Objective**: Extract API requirements and data transformations

#### 3.3.1 Data Transformation Rules

```typescript
// Frontend → Backend Mapping (from orderApi.ts)
{
  fullName → firstName + lastName (split on space)
  email → customerEmail (lowercase, trimmed)
  phone → primaryPhone
  address → billingAddress.street
  city → billingAddress.city
  postalCode → billingAddress.postalCode
  country → billingAddress.country (default: "ZA")
}
```

**BRS Requirements**:
| Transformation | Business Rule | Impact |
|----------------|--------------|--------|
| Name splitting | BR-DATA-001 | Customers with single names |
| Email lowercase | BR-DATA-002 | Case-insensitive matching |
| Default country ZA | BR-DATA-003 | South African default |

#### 3.3.2 Error Handling

**Extract from orderApi.ts**:
- Backend field → Frontend field mapping
- Error message transformation
- Validation error handling (OrderValidationError)
- Network error handling
- Timeout handling (configurable)

#### 3.3.3 Retry Logic

**Extract**:
- Retry count per environment
- Exponential backoff formula
- Non-retryable errors

### Phase 4: Configuration Analysis (Priority: Medium)

**File**: `config/index.ts`

**Objective**: Extract environment-specific requirements

| Config | DEV | SIT | PROD | BRS Mapping |
|--------|-----|-----|------|-------------|
| API Base URL | api.dev.kimmyai.io | api.sit.kimmyai.io | api.kimmyai.io | ENV-001 |
| Timeout | 10s | 15s | 15s | NFR-PERF-005 |
| Retries | 2 | 3 | 3 | NFR-RESIL-001 |
| Debug Mode | Configurable | Configurable | Disabled | OPS-001 |

### Phase 5: Type Definitions Analysis (Priority: Medium)

**Files**: `types/*.ts`

**Objective**: Extract data model requirements

#### 3.5.1 Form Types (form.ts)

```typescript
interface CustomerFormData {
  fullName: string;    // Required
  email: string;       // Required
  phone: string;       // Required
  company: string;     // Optional
  address: string;     // Required
  city: string;        // Required
  postalCode: string;  // Required
  notes: string;       // Optional
}
```

#### 3.5.2 Product Types (product.ts)

**Extract**:
- PricingPlan structure
- Required vs optional fields
- Price representation

#### 3.5.3 API Types (api.ts)

**Extract**:
- OrderPayload structure
- OrderResponse structure
- Error response structure
- Environment types

### Phase 6: Test Cases as Requirements (Priority: High)

**Files**: `*.test.tsx`, `userFlows.test.tsx`

**Objective**: Extract test scenarios as acceptance criteria

| Test File | Test Case | BRS Requirement |
|-----------|-----------|-----------------|
| PricingPage.test.tsx | Displays all products | EPIC1-US2-AC1 |
| PricingCard.test.tsx | Shows price in ZAR | EPIC1-US2-AC2 |
| CustomerForm.test.tsx | Validates email format | BR-VAL-002-AC1 |
| CheckoutPage.test.tsx | Shows error on invalid | EPIC2-US1-AC3 |
| userFlows.test.tsx | Complete purchase flow | EPIC2-US1-E2E |

**Tasks**:
1. Read all test files
2. Extract test descriptions
3. Map to acceptance criteria
4. Identify missing tests

### Phase 7: Environment Files Analysis (Priority: Medium)

**Files**: `.env.development`, `.env.sit`, `.env.production`

**Objective**: Extract environment-specific configurations

| Variable | Purpose | BRS Mapping |
|----------|---------|-------------|
| VITE_ENV | Environment identifier | ENV-001 |
| VITE_API_BASE_URL | API base URL | ENV-002 |
| VITE_ORDER_API_KEY | API authentication | SEC-001 |
| VITE_PRODUCT_API_KEY | API authentication | SEC-002 |
| VITE_DEBUG_MODE | Debug logging | OPS-001 |

---

## 4. Analysis Templates

### 4.1 Component Analysis Template

```markdown
## Component: [ComponentName]

**File**: `src/components/[path]/[file].tsx`
**Purpose**: [What this component does]

### Props
| Prop | Type | Required | Description |
|------|------|----------|-------------|
| propName | type | Yes/No | Description |

### State
| State | Type | Purpose |
|-------|------|---------|
| stateName | type | What it tracks |

### User Actions
| Action | Handler | Outcome |
|--------|---------|---------|
| Click X | handleX | What happens |

### BRS Mapping
| Feature | BRS Requirement | Status |
|---------|-----------------|--------|
| Feature | EPIC-US# | Verified/Missing |
```

### 4.2 API Service Analysis Template

```markdown
## Service: [ServiceName]

**File**: `src/services/[file].ts`
**Purpose**: [What this service does]

### Endpoints
| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | /path | Create order |

### Data Transformations
| Frontend Field | Backend Field | Transformation |
|----------------|---------------|----------------|
| fieldA | fieldB | How transformed |

### Error Handling
| Error Type | Handling | User Message |
|------------|----------|--------------|
| 400 | Field error | "Fix field X" |

### BRS Mapping
| Function | BRS Requirement | Status |
|----------|-----------------|--------|
| submitOrder | EPIC2-US2 | Verified |
```

---

## 5. Deliverables

### 5.1 Code-to-Requirement Mapping Document

| Code Location | Feature | BRS Requirement | Status |
|--------------|---------|-----------------|--------|
| App.tsx:16-21 | Product loading | EPIC1-US2 | Mapped |
| validation.ts:10 | Email validation | BR-VAL-002 | Mapped |
| orderApi.ts:287 | Name splitting | BR-DATA-001 | New |

### 5.2 Undocumented Features Report

| Feature | Code Location | Proposed BRS Addition |
|---------|--------------|----------------------|
| Fallback to local products | App.tsx:29-31 | Add resilience requirement |
| Exponential backoff | orderApi.ts:109-112 | Add retry policy NFR |
| Field sanitization | orderApi.ts:62-70 | Add security requirement |

### 5.3 Missing Implementation Report

| BRS Requirement | Expected | Actual | Gap |
|-----------------|----------|--------|-----|
| EPIC2-US2 (PayFast) | Payment processing | Not implemented | Payment integration needed |
| EPIC5-US3 (PDF Invoice) | PDF generation | Not implemented | Lambda needed |

### 5.4 Test Coverage Gap Analysis

| Requirement | Test Exists | Test Location | Coverage |
|-------------|-------------|---------------|----------|
| EPIC1-US2 | Yes | PricingPage.test.tsx | Full |
| EPIC2-US1 | Partial | userFlows.test.tsx | Missing error cases |
| BR-VAL-002 | Yes | validation.test.ts | Full |

---

## 6. Execution Timeline

| Phase | Activity | Effort | Output |
|-------|----------|--------|--------|
| 1 | Component Feature Extraction | 3 hours | Feature list |
| 2 | Validation Rules Extraction | 1 hour | Business rules |
| 3 | API Integration Analysis | 2 hours | API requirements |
| 4 | Configuration Analysis | 1 hour | Environment requirements |
| 5 | Type Definitions Analysis | 1 hour | Data model requirements |
| 6 | Test Cases Analysis | 2 hours | Acceptance criteria |
| 7 | Environment Files Analysis | 0.5 hours | Config requirements |
| 8 | Documentation | 2 hours | All deliverables |

**Total Estimated Effort**: 12.5 hours

---

## 7. Tools Required

| Tool | Purpose |
|------|---------|
| VS Code | Code navigation |
| TypeScript LSP | Type analysis |
| grep/ripgrep | Pattern search |
| Mermaid | Diagram generation |
| Markdown | Documentation |

---

## 8. Success Criteria

1. All components analyzed and documented
2. All validation rules extracted with regex patterns
3. API integrations mapped to requirements
4. Test cases linked to acceptance criteria
5. Undocumented features reported
6. Missing implementations identified
7. BRS update recommendations provided

---

## 9. Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Code changes during analysis | Use specific commit hash |
| Missing context | Cross-reference with LLD |
| Undocumented behavior | Flag for clarification |
| Complex logic | Add code comments |

---

## 10. Appendix: Key Code Patterns to Look For

### 10.1 State Management Patterns

```typescript
// Look for useState, useReducer
const [state, setState] = useState<Type>(initial);
```

### 10.2 API Call Patterns

```typescript
// Look for fetch, axios calls
const response = await fetch(url, { method: 'POST', ... });
```

### 10.3 Validation Patterns

```typescript
// Look for regex, validators
const isValid = /pattern/.test(value);
```

### 10.4 Error Handling Patterns

```typescript
// Look for try/catch, error states
try { ... } catch (error) { setError(error); }
```

### 10.5 Navigation Patterns

```typescript
// Look for route changes, redirects
navigate('/path');
setShowPage(true);
```

---

**End of Plan**
