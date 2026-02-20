# BRS Reverse Engineering Plan: LLD Frontend Architecture

**Version**: 1.0
**Created**: 2026-01-05
**Source Document**: `LLDs/2.1.1_LLD_Frontend_Architecture.md`
**Target Document**: `BRS/2.1_BRS_Customer_Portal_Public.md`
**Status**: Plan Ready for Execution

---

## 1. Objective

Reverse engineer the Low-Level Design (LLD) Frontend Architecture document to extract and validate Business Requirements Specifications (BRS) for the Customer Portal Public module.

### 1.1 Goals

1. **Gap Analysis**: Identify requirements in LLD not captured in BRS
2. **Validation**: Confirm BRS requirements are implemented in LLD
3. **Traceability**: Create mapping between LLD components and BRS user stories
4. **Enhancement**: Propose BRS updates based on LLD implementation details

---

## 2. Source Document Analysis

### 2.1 LLD Structure Overview

| Section | Content | BRS Relevance |
|---------|---------|---------------|
| 1. Introduction | Purpose, Component Overview | Scope validation |
| 2. Technology Stack | React 18, TypeScript, Vite | Non-functional requirements |
| 3. Field Mapping | Frontend → Backend mapping | Data requirements |
| 4. UI Component Diagram | Component hierarchy | Functional requirements |
| 5. Screens | UI screenshots | User interface requirements |
| 6. Screen Rules | Navigation, validation, states | Business rules |
| 7. Sequence Diagrams | User flows | Use case validation |
| 8. Dependency APIs | Endpoints, auth | Integration requirements |
| 9. Epic Overview | User stories | Traceability |
| 10. Data Models | TypeScript types | Data requirements |
| 11. Messaging | Toast notifications | UX requirements |
| 12. NFRs | Performance, browser support | Non-functional requirements |
| 13. Risks | Risk matrix | Risk requirements |
| 14. Security | Data protection, CORS | Security requirements |
| 15. Troubleshooting | Debug playbook | Operational requirements |

### 2.2 Key Components to Extract

```
LLD/2.1.1_LLD_Frontend_Architecture.md
├── Pages: HomePage, PricingPage, CheckoutPage, ConfirmationPage
├── Components: Header, Footer, PricingCard, CustomerForm, OrderSummary
├── Forms: CustomerFormData (8 fields)
├── Validations: Email, Phone (E.164), Address fields
├── APIs: Order API, Product API
└── NFRs: FCP < 1.5s, LCP < 2.5s, Bundle < 60KB
```

---

## 3. Reverse Engineering Phases

### Phase 1: Screen-to-User-Story Mapping (Priority: High)

**Objective**: Map each LLD screen to BRS user stories

| LLD Screen | Current BRS Coverage | Action Required |
|------------|---------------------|-----------------|
| Home/Pricing Screen | EPIC1-US2 (View products) | Verify alignment |
| Checkout Form Screen | EPIC2-US1 (Checkout without registering) | Verify field requirements |
| Order Summary Screen | EPIC2-US1 (Order confirmation) | Verify flow |
| Error State Screen | Not explicitly covered | Add error handling US |

**Tasks**:
1. Read LLD Section 5 (Screens)
2. Cross-reference with BRS Section 1.4 (Use Case Diagrams)
3. Document gaps in user story coverage
4. Propose new user stories if needed

### Phase 2: Field Requirements Extraction (Priority: High)

**Objective**: Extract data field requirements from LLD Section 3

| Frontend Field | LLD Validation | BRS Coverage | Action |
|----------------|---------------|--------------|--------|
| fullName | Min 2 chars, no numbers | Check if specified | Verify/Add |
| email | RFC 5322, TLD typo check | Check if specified | Verify/Add |
| phone | E.164 format (+27...) | Check if specified | Verify/Add |
| address | Min 5 chars | Check if specified | Verify/Add |
| city | Min 2 chars, no numbers | Check if specified | Verify/Add |
| postalCode | 4-10 chars alphanumeric | Check if specified | Verify/Add |
| company | Optional | Check if specified | Verify/Add |
| notes | Optional | Check if specified | Verify/Add |

**Tasks**:
1. Read LLD Section 3 (Field Mapping)
2. Read LLD Section 6.2 (Form Validation Rules)
3. Cross-reference with BRS functional requirements
4. Add missing field specifications to BRS

### Phase 3: Screen Rules to Business Rules (Priority: High)

**Objective**: Convert LLD screen rules to BRS business rules

| LLD Rule Category | Rule Example | BRS Mapping |
|-------------------|--------------|-------------|
| Navigation Rules | Click "Buy Now" → Checkout | BR-NAV-xxx |
| Validation Rules | Phone must start with + | BR-VAL-xxx |
| Button State Rules | Submit enabled when form valid | BR-UI-xxx |
| Error Display Rules | Field errors below field | BR-ERR-xxx |
| Loading State Rules | Full screen loader until hydrated | BR-UX-xxx |

**Tasks**:
1. Read LLD Section 6 (Screen Rules)
2. Document each rule with unique identifier
3. Create BRS business rules section or update existing
4. Link rules to user stories

### Phase 4: Sequence Diagram to Use Case Validation (Priority: Medium)

**Objective**: Validate BRS use cases against LLD sequence diagrams

| LLD Sequence | BRS Use Case | Validation Status |
|--------------|--------------|-------------------|
| Screen Load Sequence | UC1_1 (View home page) | To verify |
| Click Buy Sequence | UC2_1 (Checkout) | To verify |
| Submit Form Sequence | UC2_2 (Pay via PayFast) | To verify |

**Tasks**:
1. Read LLD Section 7 (Sequence Diagrams)
2. Trace each sequence step to BRS requirements
3. Identify gaps in BRS coverage
4. Document discrepancies

### Phase 5: API Integration Requirements (Priority: Medium)

**Objective**: Extract API requirements for BRS

| API | Endpoint | BRS Requirement |
|-----|----------|-----------------|
| Order API | POST /orders/v1.0/orders | Order creation |
| Product API | GET /v1.0/products | Product listing |

**Tasks**:
1. Read LLD Section 8 (Dependency APIs)
2. Document API requirements in BRS
3. Include authentication requirements (X-Api-Key)
4. Document environment-specific configurations

### Phase 6: NFR Extraction (Priority: Medium)

**Objective**: Extract non-functional requirements from LLD

| NFR Category | LLD Value | BRS Requirement |
|--------------|-----------|-----------------|
| Performance - FCP | < 1.5s | NFR-PERF-001 |
| Performance - LCP | < 2.5s | NFR-PERF-002 |
| Performance - Bundle | < 60KB (gzipped) | NFR-PERF-003 |
| Performance - TTI | < 3.0s | NFR-PERF-004 |
| Browser - Chrome | 90+ | NFR-COMPAT-001 |
| Browser - Firefox | 88+ | NFR-COMPAT-002 |
| Browser - Safari | 14+ | NFR-COMPAT-003 |
| Browser - Edge | 90+ | NFR-COMPAT-004 |

**Tasks**:
1. Read LLD Section 12 (NFRs)
2. Cross-reference with BRS non-functional requirements
3. Add missing NFRs to BRS
4. Ensure measurable criteria are specified

### Phase 7: Security Requirements (Priority: High)

**Objective**: Extract security requirements from LLD

| Security Aspect | LLD Specification | BRS Requirement |
|-----------------|-------------------|-----------------|
| Data Protection | No sensitive data in localStorage | SEC-001 |
| Transport | All API calls over HTTPS | SEC-002 |
| API Keys | From environment variables | SEC-003 |
| Input Validation | Sanitization on all fields | SEC-004 |
| CORS | Specific headers allowed | SEC-005 |

**Tasks**:
1. Read LLD Section 14 (Security)
2. Document each security control
3. Add to BRS security requirements
4. Link to compliance requirements if applicable

---

## 4. Deliverables

### 4.1 Gap Analysis Report

| Document Section | Gap Type | Description | Priority |
|-----------------|----------|-------------|----------|
| BRS User Stories | Missing | Error handling user story | High |
| BRS Field Specs | Incomplete | Validation rules not specified | High |
| BRS Business Rules | Missing | Screen navigation rules | Medium |
| BRS NFRs | Incomplete | Browser support not specified | Medium |

### 4.2 Traceability Matrix Update

| BRS Requirement | LLD Section | Implementation Status |
|-----------------|-------------|----------------------|
| EPIC1-US1 | Section 5.1 | Implemented |
| EPIC1-US2 | Section 5.1 | Implemented |
| EPIC2-US1 | Section 5.2, 5.3 | Implemented |
| EPIC2-US2 | Section 7.3 | Partially (PayFast pending) |

### 4.3 BRS Update Recommendations

1. **Section: Functional Requirements**
   - Add form field validation specifications
   - Add error handling requirements
   - Add loading state requirements

2. **Section: Business Rules**
   - Add navigation rules from LLD Section 6.1
   - Add validation rules from LLD Section 6.2
   - Add button state rules from LLD Section 6.3

3. **Section: Non-Functional Requirements**
   - Add performance targets from LLD Section 12
   - Add browser compatibility matrix

4. **Section: Security Requirements**
   - Add data protection requirements
   - Add input sanitization requirements

---

## 5. Execution Timeline

| Phase | Activity | Effort | Dependency |
|-------|----------|--------|------------|
| 1 | Screen-to-User-Story Mapping | 2 hours | None |
| 2 | Field Requirements Extraction | 2 hours | None |
| 3 | Screen Rules to Business Rules | 3 hours | Phase 1 |
| 4 | Sequence Diagram Validation | 2 hours | Phase 1 |
| 5 | API Integration Requirements | 1 hour | None |
| 6 | NFR Extraction | 1 hour | None |
| 7 | Security Requirements | 1 hour | None |
| 8 | Gap Analysis Report | 2 hours | All phases |
| 9 | BRS Update Recommendations | 2 hours | Phase 8 |

**Total Estimated Effort**: 16 hours

---

## 6. Tools & Templates

### 6.1 Gap Analysis Template

```markdown
## Gap: [GAP-ID]

**Source**: LLD Section X.Y
**Missing In**: BRS Section Z
**Description**: [What is missing]
**Impact**: [Why it matters]
**Recommendation**: [What to add to BRS]
**Priority**: [High/Medium/Low]
```

### 6.2 Traceability Template

```markdown
| Requirement ID | LLD Reference | Implementation | Status | Notes |
|---------------|---------------|----------------|--------|-------|
| REQ-001 | LLD 5.1 | PricingPage.tsx | Done | - |
```

---

## 7. Success Criteria

1. All LLD screens mapped to BRS user stories
2. All form fields have validation requirements in BRS
3. All navigation rules documented as business rules
4. NFRs have measurable criteria
5. Security requirements explicitly stated
6. Traceability matrix updated
7. Gap analysis report completed

---

**End of Plan**
