# Phase 2: BRS 2.2 - Customer Portal (Private)
## Project Plan

**Document ID**: PP-PHASE-2-2.2
**Version**: 1.0
**Created**: 2026-01-16
**Status**: Draft
**Priority**: P0 - CRITICAL
**SDLC Track**: Frontend

---

## PROJECT STATUS

| Metric | Value |
|--------|-------|
| **Overall Status** | NOT STARTED |
| **Phase** | Phase 2 (Customer Frontend) |
| **Progress** | 0% |
| **Target Duration** | 8 weeks |
| **Dependencies** | Phase 1b (BRS 2.6 Site API) |

---

## 1. Project Overview

### 1.1 Objective

Build the **Customer Portal (Private)** - the authenticated React SPA where customers manage their WordPress sites, subscriptions, billing, and support tickets.

### 1.2 Key Features (MVP)

| Feature | Epic | Priority |
|---------|------|----------|
| Customer Authentication | Epic 1 | P0 |
| Dashboard & Widgets | Epic 2 | P0 |
| Organisation Management | Epic 3 | P1 |
| Site Management | Epic 4 | P0 |
| Billing & Subscriptions | Epic 5 | P0 |
| Support Tickets | Epic 6 | P0 |

### 1.3 Technology Stack

| Component | Technology |
|-----------|------------|
| **Framework** | React 18 + TypeScript + Vite |
| **State Management** | React Query + Context |
| **Styling** | Tailwind CSS |
| **Authentication** | AWS Cognito Customer Pool |
| **Hosting** | S3 + CloudFront |
| **API Client** | Axios with JWT interceptor |

---

## 2. Project Tracking

### 2.1 Stage Progress (Frontend Track)

| Stage | Status | Progress | Deliverable |
|-------|--------|----------|-------------|
| Stage F1 | UI/UX Design | ⏳ PENDING | 0% | Wireframes, mockups |
| Stage F2 | Prototype | ⏳ PENDING | 0% | Interactive prototype |
| Stage F3 | React Mock API | ⏳ PENDING | 0% | Components with mocks |
| Stage F4 | Frontend Tests | ⏳ PENDING | 0% | Jest + RTL tests |
| Stage F5 | API Integration | ⏳ PENDING | 0% | Live API integration |
| Stage F6 | Frontend Deploy | ⏳ PENDING | 0% | S3/CloudFront deployment |

---

## 3. Stage Breakdown

### Stage F1: UI/UX Design (5 days)

**Agent**: UX Designer
**Workers**: 4

| Worker | Objective | Output |
|--------|-----------|--------|
| worker-1-user-research | Conduct user research & personas | `designs/research/` |
| worker-2-wireframes | Create wireframes for all screens | `designs/wireframes/` |
| worker-3-design-system | Define design system & components | `designs/system/` |
| worker-4-mockups | Create high-fidelity mockups | `designs/mockups/` |

**Screens to Design**:
- CP-001: Dashboard
- CP-010-014: Organisation management
- CP-020-024: Tenant management
- CP-030-039: Site management
- CP-050-055: Migration wizard
- CP-060-066: Billing & subscriptions
- CP-070-074: Support tickets

---

### Stage F2: Prototype (3 days)

**Agent**: Web Developer
**Workers**: 3

| Worker | Objective | Output |
|--------|-----------|--------|
| worker-1-navigation | Build navigation & routing | `src/App.tsx` |
| worker-2-layouts | Create page layouts | `src/layouts/` |
| worker-3-interactivity | Add interactive elements | `src/components/` |

---

### Stage F3: React Mock API (5 days)

**Agent**: Web Developer
**Workers**: 4

| Worker | Objective | Output |
|--------|-----------|--------|
| worker-1-auth-components | Auth pages (login, register, MFA) | `src/features/auth/` |
| worker-2-dashboard-components | Dashboard & widgets | `src/features/dashboard/` |
| worker-3-site-components | Site management CRUD | `src/features/sites/` |
| worker-4-billing-components | Billing & subscription pages | `src/features/billing/` |

**Mock Data**:
- MSW (Mock Service Worker) for API mocking
- Realistic tenant/site data
- Payment simulation

---

### Stage F4: Frontend Tests (4 days)

**Agent**: SDET Engineer
**Workers**: 4

| Worker | Objective | Output |
|--------|-----------|--------|
| worker-1-unit-tests | Component unit tests | `tests/unit/` |
| worker-2-integration-tests | Feature integration tests | `tests/integration/` |
| worker-3-e2e-tests | Cypress E2E tests | `tests/e2e/` |
| worker-4-accessibility | Accessibility testing | `tests/a11y/` |

**Coverage Target**: 70%+

**Validation Gate F1**: Frontend Review
- Approvers: Tech Lead, UX Lead
- Criteria: Tests passing, UI matches designs

---

### Stage F5: API Integration (4 days)

**Agent**: Web Developer
**Workers**: 4

| Worker | Objective | Output |
|--------|-----------|--------|
| worker-1-tenant-api | Integrate 2.5 Tenant API | API client updates |
| worker-2-site-api | Integrate 2.6 Site API | API client updates |
| worker-3-billing-api | Integrate billing APIs | PayFast integration |
| worker-4-auth-integration | Cognito integration | Auth flow complete |

**Validation Gate F2**: Integration Approval
- Approvers: Tech Lead, QA Lead
- Criteria: All APIs working, integration tests passing

---

### Stage F6: Frontend Deploy (3 days)

**Agent**: DevOps Engineer
**Workers**: 3

| Worker | Objective | Output |
|--------|-----------|--------|
| worker-1-s3-cloudfront | Configure S3 + CloudFront | Terraform modules |
| worker-2-cicd | GitHub Actions deployment | `.github/workflows/` |
| worker-3-deployment | Deploy to DEV | Live application |

**Deliverables**:
- DEV: `https://dev.portal.kimmyai.io`
- SIT: `https://sit.portal.kimmyai.io`
- PROD: `https://portal.kimmyai.io`

---

## 4. Screen Specifications

### 4.1 Dashboard (CP-001)

```
┌─────────────────────────────────────────────────────────────────────────┐
│  LOGO    Dashboard    Sites    Billing    Support    Profile    Logout  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Welcome, {User}!                                                        │
│                                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐│
│  │ Active Sites │  │ DEV Sites    │  │ This Month   │  │ Open Tickets ││
│  │     12       │  │     5        │  │   R2,450     │  │     3        ││
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘│
│                                                                          │
│  Recent Activity                        Quick Actions                    │
│  ─────────────                          ─────────────                    │
│  • Site "acme.com" promoted to PROD     [+ New Site]                    │
│  • Backup created for "shop.co"         [Create Ticket]                 │
│  • Invoice #1234 paid                   [View Billing]                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Site Management (CP-030)

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Sites                                              [+ Create New Site]  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Filter: [All ▼] [Active ▼]  Search: [________________] [🔍]            │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐│
│  │ Site Name        │ Domain           │ Status  │ Env  │ Actions     ││
│  ├─────────────────────────────────────────────────────────────────────┤│
│  │ ACME Corp        │ acme.com         │ ● Active│ PROD │ ⚙️ 📦 🗑️     ││
│  │ Shop Online      │ shop.co          │ ● Active│ DEV  │ ⚙️ 📦 ⬆️     ││
│  │ Blog Site        │ blog.example.com │ ○ Paused│ SIT  │ ⚙️ 📦 ▶️     ││
│  └─────────────────────────────────────────────────────────────────────┘│
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 5. API Integration Points

| API | BRS | Endpoints Used |
|-----|-----|----------------|
| Tenant API | 2.5 | `/tenants`, `/tenants/{id}/users`, `/tenants/{id}/hierarchy` |
| Site API | 2.6 | `/sites`, `/templates`, `/plugins`, `/promotions` |
| Billing API | 2.5 | `/subscriptions`, `/invoices`, `/payments` |
| Ticket API | 2.5 | `/tickets`, `/tickets/{id}/followups` |

---

## 6. Repository Structure

```
2_1_bbws_web_private/
├── README.md
├── package.json
├── vite.config.ts
├── tsconfig.json
├── tailwind.config.js
├── src/
│   ├── App.tsx
│   ├── main.tsx
│   ├── features/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── sites/
│   │   ├── billing/
│   │   ├── tickets/
│   │   └── settings/
│   ├── components/
│   │   ├── ui/
│   │   └── layout/
│   ├── hooks/
│   ├── services/
│   │   └── api/
│   └── utils/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── terraform/
│   ├── s3.tf
│   ├── cloudfront.tf
│   └── variables.tf
└── .github/
    └── workflows/
        ├── ci.yml
        ├── deploy-dev.yml
        ├── deploy-sit.yml
        └── deploy-prod.yml
```

---

## 7. Dependencies

### 7.1 Upstream Dependencies

| Dependency | Status | Owner |
|------------|--------|-------|
| BRS 2.5 Tenant API | REQUIRED | Phase 0 |
| BRS 2.6 Site API | REQUIRED | Phase 1b |
| Cognito Customer Pool | READY | DevOps |
| S3/CloudFront | READY | DevOps |

### 7.2 Downstream Dependents

| Dependent | Waiting For |
|-----------|-------------|
| BRS 2.4 Admin Portal | Customer Portal patterns |

---

## 8. Release Management

### Release Information

| Attribute | Value |
|-----------|-------|
| **Release #** | R2.0 |
| **Release Date** | _______________ |
| **UAT Signoff Date** | _______________ |
| **Business Owner** | _______________ |

### Deliverables Checklist

| # | Deliverable | Status | Sign-off |
|---|-------------|--------|----------|
| 1 | `2_1_bbws_web_private/` repository - Code complete | ☐ | _______________ |
| 2 | React SPA - Build passing | ☐ | _______________ |
| 3 | S3/CloudFront deployment - Configured | ☐ | _______________ |
| 4 | Cognito authentication - Integrated | ☐ | _______________ |
| 5 | Dashboard component - Functional | ☐ | _______________ |
| 6 | Site management UI - Functional | ☐ | _______________ |
| 7 | Billing integration - Functional | ☐ | _______________ |
| 8 | Support ticket UI - Functional | ☐ | _______________ |
| 9 | Unit tests - >70% coverage | ☐ | _______________ |
| 10 | E2E tests - All critical paths passing | ☐ | _______________ |

### Definition of Done

| # | Criteria | Status |
|---|----------|--------|
| 1 | All SDLC stages (F1-F6) completed | ☐ |
| 2 | All validation gates approved | ☐ |
| 3 | UI/UX design approved by stakeholders | ☐ |
| 4 | Accessibility compliance (WCAG 2.1 AA) | ☐ |
| 5 | Mobile responsive design verified | ☐ |
| 6 | API integration with 2.5 Tenant API complete | ☐ |
| 7 | API integration with 2.6 Site API complete | ☐ |
| 8 | Cross-browser testing passed (Chrome, Firefox, Safari, Edge) | ☐ |
| 9 | DEV environment deployment successful | ☐ |
| 10 | SIT environment deployment successful | ☐ |
| 11 | UAT completed with sign-off | ☐ |
| 12 | PROD deployment approved | ☐ |
| 13 | Analytics tracking configured | ☐ |
| 14 | Performance benchmarks met (LCP < 2.5s, FID < 100ms) | ☐ |
| 15 | Security scan passed (OWASP Top 10) | ☐ |

### Environment Promotion

| Environment | URL | Deployment Date | Verified By | Status |
|-------------|-----|-----------------|-------------|--------|
| DEV | `https://dev.portal.kimmyai.io` | _______________ | _______________ | ☐ Pending |
| SIT | `https://sit.portal.kimmyai.io` | _______________ | _______________ | ☐ Pending |
| PROD | `https://portal.kimmyai.io` | _______________ | _______________ | ☐ Pending |

---

## 9. Approval

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Product Owner | | | |
| Tech Lead | | | |
| UX Lead | | | |
| Business Owner | | | |

---

*Phase 2 begins after Phase 1b (Site API) is complete.*
