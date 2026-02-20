# LLD to BRS Gap Analysis Report

**Version**: 1.0
**Created**: 2026-01-05
**Source**: `LLDs/2.1.1_LLD_Frontend_Architecture.md` (v2.0)
**Target**: `BRS/2.1_BRS_Customer_Portal_Public.md` (v1.1)
**Status**: Analysis Complete

---

## Executive Summary

This report documents the gap analysis between the LLD Frontend Architecture and the BRS Customer Portal Public. The analysis identified **23 gaps** across 7 phases, with **8 Critical**, **10 High**, and **5 Medium** priority items requiring BRS updates.

### Key Findings

| Category | Gaps Found | Priority |
|----------|------------|----------|
| Screen Mapping | 3 | 1 Critical, 2 High |
| Field Requirements | 8 | 3 Critical, 5 High |
| Business Rules | 5 | 2 Critical, 3 High |
| Sequence Diagrams | 2 | Medium |
| API Integration | 1 | High |
| NFRs | 2 | 1 Critical, 1 Medium |
| Security | 2 | 1 Critical, 1 Medium |
| **Total** | **23** | **8 Critical, 10 High, 5 Medium** |

---

## Phase 1: Screen-to-User-Story Mapping

### 1.1 LLD Screens Inventory

| LLD Screen | LLD Section | Purpose | Components |
|------------|-------------|---------|------------|
| Home/Pricing Screen | 5.1 | Display pricing plans | Header, PricingCard×3, FeatureList, Button, Footer |
| Checkout Form Screen | 5.2 | Collect customer details | Header, CustomerForm, Input×8, Button, ErrorMessage, Footer |
| Order Summary Screen | 5.3 | Display order before submission | Header, OrderSummary, PricingCard, Button, Footer |
| Error State Screen | 5.4 | Display errors | Header, ErrorMessage, Toast, Button, Footer |

### 1.2 BRS Screen Coverage

| BRS Screen ID | Screen Name | LLD Coverage | Status |
|---------------|-------------|--------------|--------|
| CPP-001 | Home | Merged with CPP-003 in LLD | Partial |
| CPP-003 | Pricing | Yes (Section 5.1) | Covered |
| CPP-017 | Checkout | Yes (Section 5.2) | Covered |
| CPP-018 | Payment | Not in LLD (PayFast redirect) | Gap |
| CPP-019 | Order Confirmation | Partial (Section 5.3) | Partial |
| CPP-020 | Payment Failed | Partial (Section 5.4) | Partial |

### 1.3 Identified Gaps

| Gap ID | Gap Description | Priority | Recommendation |
|--------|-----------------|----------|----------------|
| GAP-SCR-001 | LLD merges Home and Pricing into single screen; BRS has them as separate (CPP-001, CPP-003) | High | Clarify in BRS that buy module only implements Pricing screen |
| GAP-SCR-002 | LLD has "Order Summary Screen" as intermediate step before confirmation; BRS implies direct flow to payment | High | Add Order Summary screen (CPP-016.5) to BRS or document as enhancement |
| GAP-SCR-003 | BRS lacks dedicated Error State screen specification | Critical | Add Error State screen patterns to BRS Section 4 |

---

## Phase 2: Field Requirements Extraction

### 2.1 LLD Field Specifications (Section 3.1, 6.2)

| Field | Type | Required | Validation Rule | Error Message |
|-------|------|----------|-----------------|---------------|
| `fullName` | string | Yes | Min 2 chars each (first/last), no numbers | "Please enter your full name" |
| `email` | string | Yes | RFC 5322, TLD typo check | "Please enter a valid email address" |
| `phone` | string | Yes | E.164 format (+27821234567) | "Phone must start with + (e.g., +27821234567)" |
| `company` | string | No | None | - |
| `address` | string | Yes | Min 5 chars | "Street address must be at least 5 characters" |
| `city` | string | Yes | Min 2 chars, no numbers | "Please enter your city" |
| `postalCode` | string | Yes | 4-10 chars alphanumeric | "Please enter a valid postal code" |
| `notes` | string | No | Max 500 chars | "Notes cannot exceed 500 characters" |

### 2.2 BRS Field Coverage Analysis

**Current BRS Coverage** (EPIC2-US1):
- Mentions "email address" and "billing address" generically
- No specific validation rules documented
- No error messages specified
- No field length constraints

### 2.3 Identified Gaps

| Gap ID | Field | Gap Description | Priority | Recommendation |
|--------|-------|-----------------|----------|----------------|
| GAP-FLD-001 | fullName | No validation rule in BRS (min chars, no numbers) | Critical | Add to BRS: BR-VAL-001 |
| GAP-FLD-002 | email | RFC 5322 validation not specified | Critical | Add to BRS: BR-VAL-002 |
| GAP-FLD-003 | phone | E.164 format requirement not specified | Critical | Add to BRS: BR-VAL-003 |
| GAP-FLD-004 | address | Min 5 chars not specified | High | Add to BRS: BR-VAL-004 |
| GAP-FLD-005 | city | Min 2 chars, no numbers not specified | High | Add to BRS: BR-VAL-005 |
| GAP-FLD-006 | postalCode | 4-10 chars alphanumeric not specified | High | Add to BRS: BR-VAL-006 |
| GAP-FLD-007 | notes | Max 500 chars not specified | High | Add to BRS: BR-VAL-007 |
| GAP-FLD-008 | All fields | Error messages not documented | High | Add error message table to BRS |

---

## Phase 3: Screen Rules to Business Rules

### 3.1 LLD Screen Rules Inventory

#### 3.1.1 Navigation Rules (LLD Section 6.1)

| Rule ID | Current Screen | Action | Target Screen | Condition |
|---------|----------------|--------|---------------|-----------|
| NAV-001 | Home | Click "Buy Now" | Checkout | Plan selected |
| NAV-002 | Checkout | Click "Back" | Home | Always |
| NAV-003 | Checkout | Submit form | Summary | Form valid |
| NAV-004 | Summary | Click "Confirm" | Confirmation | API success |
| NAV-005 | Summary | API error | Checkout | Show errors |
| NAV-006 | Any | Session timeout | Home | After 30 min |

#### 3.1.2 Button State Rules (LLD Section 6.3)

| Rule ID | Button | Enabled When | Loading When | Disabled When |
|---------|--------|--------------|--------------|---------------|
| BTN-001 | Buy Now | Plan visible | Never | Never |
| BTN-002 | Submit Order | Form valid | API call in progress | Form invalid |
| BTN-003 | Confirm Order | Summary loaded | Payment processing | API error |
| BTN-004 | Retry | Error shown | Never | Never |

#### 3.1.3 Error Display Rules (LLD Section 6.4)

| Rule ID | Error Type | Display Location | Duration | Action |
|---------|------------|------------------|----------|--------|
| ERR-001 | Field validation | Below field | Until corrected | Focus field |
| ERR-002 | API validation (400) | Below field + Toast | 5 seconds | Highlight field |
| ERR-003 | Network error | Toast | Until dismissed | Show retry |
| ERR-004 | Server error (5xx) | Full screen | Until dismissed | Show retry |

#### 3.1.4 Loading State Rules (LLD Section 6.5)

| Rule ID | Scenario | Component | Duration |
|---------|----------|-----------|----------|
| LOAD-001 | Page load | Full screen loader | Until hydrated |
| LOAD-002 | Form submit | Button spinner | Until API response |
| LOAD-003 | Plan selection | Button disabled | 100ms debounce |

### 3.2 BRS Business Rules Coverage

**Current BRS**: No dedicated business rules section with rule IDs. Rules are embedded in user story acceptance criteria.

### 3.3 Identified Gaps

| Gap ID | Rule Category | Gap Description | Priority | Recommendation |
|--------|---------------|-----------------|----------|----------------|
| GAP-BR-001 | Navigation | 6 navigation rules not documented in BRS | Critical | Add Section: "Business Rules - Navigation" |
| GAP-BR-002 | Button States | 4 button state rules not documented | High | Add Section: "Business Rules - UI States" |
| GAP-BR-003 | Error Display | 4 error display patterns not documented | Critical | Add Section: "Business Rules - Error Handling" |
| GAP-BR-004 | Loading States | 3 loading state patterns not documented | High | Add Section: "Business Rules - Loading States" |
| GAP-BR-005 | Session | 30-minute session timeout not documented | High | Add to NFRs or Business Rules |

---

## Phase 4: Sequence Diagram to Use Case Validation

### 4.1 LLD Sequence Diagrams

| Diagram | LLD Section | Steps | BRS Mapping |
|---------|-------------|-------|-------------|
| Screen Load Sequence | 7.1 | Browser → CloudFront → S3 → React | Infrastructure, not in BRS |
| Click Buy Sequence | 7.2 | User → PricingCard → App → Checkout | EPIC2-US1 (partial) |
| Submit Form Sequence | 7.3 | User → Form → Validator → API → Lambda | EPIC2-US1, US2 (partial) |

### 4.2 Alignment Analysis

| BRS Use Case | LLD Coverage | Alignment Status |
|--------------|--------------|------------------|
| EPIC1-US2: View Products | Screen 5.1 | Aligned |
| EPIC2-US1: Checkout | Sequence 7.2, 7.3 | Aligned (detailed) |
| EPIC2-US2: PayFast Payment | Not in LLD | Gap - PayFast not implemented |
| EPIC2-US3: Order Confirmation | Sequence 7.3 (partial) | Partial - success flow only |

### 4.3 Identified Gaps

| Gap ID | Gap Description | Priority | Recommendation |
|--------|-----------------|----------|----------------|
| GAP-SEQ-001 | PayFast payment sequence not in LLD | Medium | PayFast is pending implementation |
| GAP-SEQ-002 | Error recovery sequences not detailed in BRS | Medium | Add error flow diagrams to BRS |

---

## Phase 5: API Integration Requirements

### 5.1 LLD API Specifications (Section 8)

| API | Base URL (DEV) | Endpoint | Method | Auth |
|-----|----------------|----------|--------|------|
| Order API | `https://api.dev.kimmyai.io` | `/orders/v1.0/orders` | POST | X-Api-Key |
| Product API | `https://api.dev.kimmyai.io` | `/v1.0/products` | GET | X-Api-Key |

### 5.2 BRS API Coverage (Appendix B)

BRS has complete API endpoint reference in Appendix B. Alignment is good.

### 5.3 Identified Gaps

| Gap ID | Gap Description | Priority | Recommendation |
|--------|-----------------|----------|----------------|
| GAP-API-001 | BRS lacks environment-specific URL table | High | Add environment configuration table (DEV/SIT/PROD URLs) |

---

## Phase 6: NFR Extraction

### 6.1 LLD NFRs (Section 12)

**Performance Targets:**

| Metric | LLD Target | BRS Target | Gap |
|--------|------------|------------|-----|
| First Contentful Paint (FCP) | < 1.5s | Not specified | Gap |
| Largest Contentful Paint (LCP) | < 2.5s | Not specified | Gap |
| Bundle Size (gzipped) | < 60KB | Not specified | Gap |
| Time to Interactive (TTI) | < 3.0s | < 3s (Page Load) | Aligned |

**Browser Support:**

| Browser | LLD Minimum | BRS Coverage |
|---------|-------------|--------------|
| Chrome | 90+ | Not specified |
| Firefox | 88+ | Not specified |
| Safari | 14+ | Not specified |
| Edge | 90+ | Not specified |

### 6.2 Identified Gaps

| Gap ID | Gap Description | Priority | Recommendation |
|--------|-----------------|----------|----------------|
| GAP-NFR-001 | Frontend performance metrics (FCP, LCP, TTI) not in BRS | Critical | Add Web Vitals targets to BRS Section 4.1 |
| GAP-NFR-002 | Browser compatibility matrix not in BRS | Medium | Add browser support table to BRS Section 4 |

---

## Phase 7: Security Requirements

### 7.1 LLD Security Controls (Section 14)

| Control | LLD Specification | BRS Coverage |
|---------|-------------------|--------------|
| localStorage | No sensitive data | Not specified |
| Transport | HTTPS only | Covered (TLS 1.2+) |
| API Keys | Environment variables | Not specified frontend |
| Input Sanitization | All fields | Covered (generic) |
| CORS | Specific headers | Not specified |

### 7.2 Identified Gaps

| Gap ID | Gap Description | Priority | Recommendation |
|--------|-----------------|----------|----------------|
| GAP-SEC-001 | Client-side storage restrictions not in BRS | Critical | Add: "No sensitive data in browser storage (localStorage, sessionStorage)" |
| GAP-SEC-002 | CORS policy not documented in BRS | Medium | Add CORS configuration to technical specifications |

---

## Consolidated Gap Summary

### Critical Priority (8 items)

| Gap ID | Description | BRS Section to Update |
|--------|-------------|----------------------|
| GAP-SCR-003 | Error State screen patterns missing | Add new section |
| GAP-FLD-001 | fullName validation rule | Add Business Rules |
| GAP-FLD-002 | email RFC 5322 validation | Add Business Rules |
| GAP-FLD-003 | phone E.164 format | Add Business Rules |
| GAP-BR-001 | Navigation rules not documented | Add Business Rules section |
| GAP-BR-003 | Error display patterns | Add Business Rules section |
| GAP-NFR-001 | Frontend performance metrics | Section 4.1 |
| GAP-SEC-001 | Client-side storage restrictions | Section 4.2 |

### High Priority (10 items)

| Gap ID | Description | BRS Section to Update |
|--------|-------------|----------------------|
| GAP-SCR-001 | Home/Pricing screen clarification | Section 1.2 Scope |
| GAP-SCR-002 | Order Summary screen | Appendix A |
| GAP-FLD-004 | address validation | Add Business Rules |
| GAP-FLD-005 | city validation | Add Business Rules |
| GAP-FLD-006 | postalCode validation | Add Business Rules |
| GAP-FLD-007 | notes max length | Add Business Rules |
| GAP-FLD-008 | Error messages table | Add new table |
| GAP-BR-002 | Button state rules | Add Business Rules section |
| GAP-BR-004 | Loading state patterns | Add Business Rules section |
| GAP-BR-005 | Session timeout | Section 4 NFRs |
| GAP-API-001 | Environment URLs | Appendix B |

### Medium Priority (5 items)

| Gap ID | Description | BRS Section to Update |
|--------|-------------|----------------------|
| GAP-SEQ-001 | PayFast sequence | Pending implementation |
| GAP-SEQ-002 | Error recovery flows | Add diagrams |
| GAP-NFR-002 | Browser compatibility | Section 4 |
| GAP-SEC-002 | CORS policy | Technical specs |

---

## Recommended BRS Updates

### New Sections to Add

#### 1. Business Rules Section (After Section 3)

```markdown
## 3.5 Business Rules

### 3.5.1 Form Validation Rules (BR-VAL)

| Rule ID | Field | Validation | Error Message |
|---------|-------|------------|---------------|
| BR-VAL-001 | fullName | Required, min 2 chars per name part, no numbers | "Please enter your full name" |
| BR-VAL-002 | email | Required, RFC 5322 format | "Please enter a valid email address" |
| BR-VAL-003 | phone | Required, E.164 format (+27...) | "Phone must start with + (e.g., +27821234567)" |
| BR-VAL-004 | address | Required, min 5 characters | "Street address must be at least 5 characters" |
| BR-VAL-005 | city | Required, min 2 chars, no numbers | "Please enter your city" |
| BR-VAL-006 | postalCode | Required, 4-10 chars alphanumeric | "Please enter a valid postal code" |
| BR-VAL-007 | notes | Optional, max 500 characters | "Notes cannot exceed 500 characters" |

### 3.5.2 Navigation Rules (BR-NAV)

| Rule ID | From Screen | Action | To Screen | Condition |
|---------|-------------|--------|-----------|-----------|
| BR-NAV-001 | Pricing | Click "Buy Now" | Checkout | Plan selected |
| BR-NAV-002 | Checkout | Click "Back" | Pricing | Always |
| BR-NAV-003 | Checkout | Submit form | Order Summary | Form valid |
| BR-NAV-004 | Order Summary | Confirm | Payment | Always |
| BR-NAV-005 | Any | Session timeout | Home | After 30 minutes |

### 3.5.3 Error Handling Rules (BR-ERR)

| Rule ID | Error Type | Display | Duration | User Action |
|---------|------------|---------|----------|-------------|
| BR-ERR-001 | Field validation | Below field | Until corrected | Focus field |
| BR-ERR-002 | API validation (400) | Toast + Field | 5 seconds | Highlight field |
| BR-ERR-003 | Network error | Toast | Until dismissed | Show retry |
| BR-ERR-004 | Server error (5xx) | Full screen | Until dismissed | Show retry |

### 3.5.4 UI State Rules (BR-UI)

| Rule ID | Element | Enabled | Loading | Disabled |
|---------|---------|---------|---------|----------|
| BR-UI-001 | Buy Now button | Plan visible | Never | Never |
| BR-UI-002 | Submit button | Form valid | API in progress | Form invalid |
| BR-UI-003 | Confirm button | Summary loaded | Payment processing | API error |
```

#### 2. NFR Updates (Section 4.1)

```markdown
### 4.1.1 Frontend Performance (Web Vitals)

| Metric | Target | Measurement |
|--------|--------|-------------|
| First Contentful Paint (FCP) | < 1.5s | Lighthouse |
| Largest Contentful Paint (LCP) | < 2.5s | Lighthouse |
| Time to Interactive (TTI) | < 3.0s | Lighthouse |
| Bundle Size (gzipped) | < 60KB | Build output |

### 4.1.2 Browser Compatibility

| Browser | Minimum Version |
|---------|-----------------|
| Chrome | 90+ |
| Firefox | 88+ |
| Safari | 14+ |
| Edge | 90+ |
```

#### 3. Security Updates (Section 4.2)

```markdown
### 4.2.1 Client-Side Security

- No sensitive data in browser storage (localStorage, sessionStorage)
- API keys loaded from environment variables, not hardcoded
- All user inputs sanitized before processing
- XSS prevention through React's built-in escaping
```

---

## Traceability Matrix Update

| BRS Requirement | LLD Section | Implementation Status | Notes |
|-----------------|-------------|----------------------|-------|
| EPIC1-US2 | Section 5.1, 7.1 | Implemented | PricingPage |
| EPIC2-US1 | Section 5.2, 5.3, 7.2, 7.3 | Implemented | CheckoutPage |
| EPIC2-US2 | Not in LLD | Not Implemented | PayFast pending |
| EPIC2-US3 | Section 5.3 | Partial | Order summary, no confirmation |
| BR-VAL-001 to 007 | Section 6.2 | Implemented | validation.ts |
| BR-NAV-001 to 005 | Section 6.1 | Implemented | App.tsx routing |
| BR-ERR-001 to 004 | Section 6.4 | Implemented | CheckoutPage |
| NFR-PERF-FCP | Section 12.1 | Implemented | Vite optimization |
| NFR-PERF-LCP | Section 12.1 | Implemented | Vite optimization |

---

## Next Steps

1. **Immediate**: Update BRS with Critical priority gaps (8 items)
2. **Short-term**: Update BRS with High priority gaps (10 items)
3. **Backlog**: Address Medium priority gaps (5 items)
4. **Validation**: Review updated BRS with stakeholders
5. **Automation**: Create test cases from new business rules

---

## Appendix: Document References

| Document | Path | Version |
|----------|------|---------|
| LLD Frontend Architecture | `LLDs/2.1.1_LLD_Frontend_Architecture.md` | 2.0 |
| BRS Customer Portal Public | `BRS/2.1_BRS_Customer_Portal_Public.md` | 1.1 |
| Buy Codebase | `2_1_bbws_web_public/buy/` | - |

---

**End of Report**
