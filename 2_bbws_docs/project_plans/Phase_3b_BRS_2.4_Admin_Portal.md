# Phase 3b: BRS 2.4 - Admin Portal
## Project Plan

**Document ID**: PP-PHASE-3B-2.4
**Version**: 1.0
**Created**: 2026-01-16
**Status**: Draft
**Priority**: P1 - HIGH
**SDLC Track**: Frontend

---

## PROJECT STATUS

| Metric | Value |
|--------|-------|
| **Overall Status** | NOT STARTED |
| **Phase** | Phase 3b (Staff Console) |
| **Progress** | 0% |
| **Target Duration** | 8 weeks |
| **Dependencies** | Phase 2 (BRS 2.2 Customer Portal) |

---

## 1. Project Overview

### 1.1 Objective

Build the **Admin Portal** - the internal BBWS staff console for cross-tenant operations, campaign management, support ticket queue, SLA monitoring, and revenue analytics.

### 1.2 Key Features (MVP)

| Feature | Epic | Priority |
|---------|------|----------|
| Admin Authentication (MFA) | Epic 1 | P0 |
| Campaign Management | Epic 2 | P0 |
| Tenant Administration | Epic 3 | P0 |
| Organisation & Site Admin | Epic 4 | P0 |
| Subscription Administration | Epic 5 | P0 |
| Support Ticket Queue | Epic 6 | P0 |
| SLA Management | Epic 7 | P0 |
| Platform Administration | Epic 8 | P1 |

### 1.3 Staff Roles

| Role | Cognito Group | Permissions |
|------|---------------|-------------|
| super-admin | ADMIN_SUPER | Full platform access |
| admin | ADMIN | Tenant + support management |
| support-agent | ADMIN_SUPPORT | Ticket queue only |
| marketing | ADMIN_MARKETING | Campaigns only |
| viewer | ADMIN_VIEWER | Read-only access |

---

## 2. Stage Progress (Frontend Track)

| Stage | Status | Progress | Deliverable |
|-------|--------|----------|-------------|
| Stage F1 | UI/UX Design | ⏳ PENDING | 0% | Staff console wireframes |
| Stage F2 | Prototype | ⏳ PENDING | 0% | Interactive prototype |
| Stage F3 | React Mock API | ⏳ PENDING | 0% | Components with mocks |
| Stage F4 | Frontend Tests | ⏳ PENDING | 0% | Jest + RTL tests |
| Stage F5 | API Integration | ⏳ PENDING | 0% | Cross-tenant API integration |
| Stage F6 | Frontend Deploy | ⏳ PENDING | 0% | Internal deployment |

---

## 3. Screen Specifications

### 3.1 Admin Dashboard

```
┌─────────────────────────────────────────────────────────────────────────┐
│  BBWS Staff Portal    Dashboard  Campaigns  Tenants  Support  Reports  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Platform Overview                                     [Today ▼]         │
│                                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐│
│  │ Total        │  │ Active       │  │ MRR          │  │ SLA          ││
│  │ Customers    │  │ Sites        │  │              │  │ Breaches     ││
│  │    156       │  │    312       │  │  R45,200     │  │     2        ││
│  │  ↑ 12 new    │  │  ↑ 24 new    │  │  ↑ R3,200    │  │  ↓ 1        ││
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘│
│                                                                          │
│  Support Queue (Open)             Campaign Performance                   │
│  ─────────────────────            ────────────────────                   │
│  🔴 P1 Critical: 1                Summer Sale: 12% CTR                  │
│  🟡 P2 High: 5                    New Customer: 8% conversion           │
│  🟢 P3 Normal: 23                 Renewal Reminder: 45% open rate       │
│                                                                          │
│  [View All Tickets]               [View All Campaigns]                   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Campaign Management

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Campaigns                                        [+ Create Campaign]    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Status: [All ▼]  Type: [All ▼]  Date: [Last 30 days ▼]                 │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐│
│  │ Campaign Name     │ Type     │ Status  │ Sent  │ Opens │ Clicks    ││
│  ├─────────────────────────────────────────────────────────────────────┤│
│  │ Summer Sale 2026  │ Email    │ ● Active│ 1,234 │ 456   │ 148       ││
│  │ New Customer      │ Email    │ ● Active│ 567   │ 234   │ 45        ││
│  │ Renewal Reminder  │ Email    │ ○ Draft │ -     │ -     │ -         ││
│  │ Black Friday      │ SMS      │ ⏸ Paused│ 890   │ -     │ 23        ││
│  └─────────────────────────────────────────────────────────────────────┘│
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.3 Support Ticket Queue

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Support Queue                              Assigned to: [Me ▼] [All]   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Priority: [All ▼]  Status: [Open ▼]  SLA: [All ▼]                      │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐│
│  │ ID     │ Subject              │ Customer    │ Pri │ SLA    │ Agent  ││
│  ├─────────────────────────────────────────────────────────────────────┤│
│  │ #1234  │ Site down - urgent   │ ACME Corp   │ 🔴  │ ⚠️ 2h  │ -      ││
│  │ #1233  │ Cannot upload images │ Shop Inc    │ 🟡  │ ✓ 4h  │ John   ││
│  │ #1232  │ Billing question     │ Blog Co     │ 🟢  │ ✓ 8h  │ Jane   ││
│  │ #1231  │ Need plugin install  │ Tech Ltd    │ 🟢  │ ✓ 12h │ John   ││
│  └─────────────────────────────────────────────────────────────────────┘│
│                                                                          │
│  [Assign to Me]  [Escalate]  [Bulk Close]                               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.4 SLA Dashboard

```
┌─────────────────────────────────────────────────────────────────────────┐
│  SLA Monitoring                                          [This Week ▼]  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  SLA Compliance: 98.5%                                                   │
│  ════════════════════════════════════════════════════░░░░░░             │
│                                                                          │
│  Active Breaches (2)                                                     │
│  ─────────────────────                                                   │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐│
│  │ Customer     │ Type        │ Breach Time │ Status     │ Action      ││
│  ├─────────────────────────────────────────────────────────────────────┤│
│  │ ACME Corp    │ Uptime      │ 45 min ago  │ ⚠️ Active  │ [Ack] [View]││
│  │ Tech Ltd     │ Response    │ 2h ago      │ ⚠️ Active  │ [Ack] [View]││
│  └─────────────────────────────────────────────────────────────────────┘│
│                                                                          │
│  [Configure SLA Thresholds]  [View Breach History]                       │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Cross-Tenant Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     ADMIN PORTAL ARCHITECTURE                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Admin Portal (React)                                                   │
│        │                                                                 │
│        ▼                                                                 │
│   API Gateway (admin-api.kimmyai.io)                                     │
│        │                                                                 │
│        ▼                                                                 │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                    Admin API Microservices                       │   │
│   ├─────────────────────────────────────────────────────────────────┤   │
│   │                                                                  │   │
│   │   Campaign    Tenant     Organisation  Site      Subscription   │   │
│   │   Service     Admin      Admin         Admin     Admin          │   │
│   │                                                                  │   │
│   │   Ticket      SLA        User          Audit     Report         │   │
│   │   Queue       Monitor    Admin         Logger    Generator      │   │
│   │                                                                  │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│        │                                                                 │
│        ▼                                                                 │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                      DynamoDB (Cross-Tenant GSIs)                │   │
│   │                                                                  │   │
│   │   GSI: ALL_TENANTS     → List all tenants                       │   │
│   │   GSI: ALL_ORGS        → List all organisations                 │   │
│   │   GSI: ALL_SITES       → List all sites                         │   │
│   │   GSI: ALL_TICKETS     → Support queue                          │   │
│   │   GSI: ALL_CAMPAIGNS   → Campaign management                    │   │
│   │                                                                  │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 5. API Integration Points

| Service | API | Endpoints |
|---------|-----|-----------|
| Campaign Mgmt | Campaigns API | `/campaigns`, `/campaigns/{id}/offers`, `/campaigns/{id}/targets` |
| Tenant Admin | Tenant API (2.5) | `/admin/tenants` (cross-tenant) |
| Site Admin | Site API (2.6) | `/admin/sites` (cross-tenant) |
| Support Queue | Ticket API | `/admin/tickets`, `/tickets/{id}/assign` |
| SLA | SLA API | `/sla/config`, `/sla/breaches` |
| Audit | Audit API | `/audit/logs`, `/audit/query` |

---

## 6. Backend Services (11 microservices, 68 Lambda functions)

| # | Service | Functions | Description |
|---|---------|-----------|-------------|
| 1 | Admin Auth | 6 | MFA, session, admin user management |
| 2 | Campaign | 8 | CRUD campaigns, offers, targets |
| 3 | Tenant Admin | 6 | Cross-tenant operations |
| 4 | Organisation Admin | 5 | All organisations view |
| 5 | Site Admin | 7 | All sites, force actions |
| 6 | Subscription Admin | 6 | Revenue, failed payments |
| 7 | Ticket Queue | 8 | Assignment, escalation |
| 8 | SLA Monitor | 6 | Breach detection, config |
| 9 | User Admin | 5 | Staff user management |
| 10 | Audit Logger | 4 | Log query, compliance |
| 11 | Report Generator | 7 | Analytics, exports |

---

## 7. Repository Structure

```
2_bbws_admin_portal/
├── README.md
├── package.json
├── src/
│   ├── features/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── campaigns/
│   │   ├── tenants/
│   │   ├── organisations/
│   │   ├── sites/
│   │   ├── subscriptions/
│   │   ├── tickets/
│   │   ├── sla/
│   │   ├── users/
│   │   ├── audit/
│   │   └── reports/
│   ├── components/
│   └── services/
├── tests/
└── terraform/
```

---

## 8. Dependencies

### 8.1 Upstream Dependencies

| Dependency | Status | Owner |
|------------|--------|-------|
| BRS 2.5 Tenant API | REQUIRED | Phase 0 |
| BRS 2.6 Site API | REQUIRED | Phase 1b |
| BRS 2.2 Customer Portal patterns | REQUIRED | Phase 2 |
| Campaign Lambda | NEW | This phase |

### 8.2 API Development (This Phase)

New backend services to build:
- Campaign Management API
- SLA Monitoring API
- Audit Logger API
- Report Generator API

---

## 9. Release Management

### Release Information

| Attribute | Value |
|-----------|-------|
| **Release #** | R2.2 |
| **Release Date** | _______________ |
| **UAT Signoff Date** | _______________ |
| **Business Owner** | _______________ |

### Deliverables Checklist

| # | Deliverable | Status | Sign-off |
|---|-------------|--------|----------|
| 1 | `2_bbws_admin_portal/` repository - Code complete | ☐ | _______________ |
| 2 | Campaign management module - Functional | ☐ | _______________ |
| 3 | Support ticket queue - Functional | ☐ | _______________ |
| 4 | SLA monitoring dashboard - Functional | ☐ | _______________ |
| 5 | Cross-tenant visibility - Working | ☐ | _______________ |
| 6 | Revenue analytics - Functional | ☐ | _______________ |
| 7 | Audit logging - Integrated | ☐ | _______________ |
| 8 | Report generation - Functional | ☐ | _______________ |
| 9 | Unit tests - >70% coverage | ☐ | _______________ |
| 10 | E2E tests - All critical paths passing | ☐ | _______________ |

### Definition of Done

| # | Criteria | Status |
|---|----------|--------|
| 1 | All SDLC stages (F1-F6) completed | ☐ |
| 2 | All validation gates approved | ☐ |
| 3 | Campaign CRUD operations functional | ☐ |
| 4 | Ticket assignment and escalation working | ☐ |
| 5 | SLA breach detection operational | ☐ |
| 6 | Cross-tenant GSI queries verified | ☐ |
| 7 | Staff role permissions enforced (super-admin, admin, support-agent, marketing, viewer) | ☐ |
| 8 | DEV environment deployment successful | ☐ |
| 9 | SIT environment deployment successful | ☐ |
| 10 | UAT completed with sign-off | ☐ |
| 11 | PROD deployment approved (internal only) | ☐ |
| 12 | Campaign Management API deployed | ☐ |
| 13 | SLA Monitoring API deployed | ☐ |
| 14 | Audit Logger API deployed | ☐ |
| 15 | Report Generator API deployed | ☐ |

### Environment Promotion

| Environment | URL | Deployment Date | Verified By | Status |
|-------------|-----|-----------------|-------------|--------|
| DEV | `https://dev.staff.kimmyai.io` | _______________ | _______________ | ☐ Pending |
| SIT | `https://sit.staff.kimmyai.io` | _______________ | _______________ | ☐ Pending |
| PROD | `https://staff.kimmyai.io` | _______________ | _______________ | ☐ Pending |

---

## 10. Approval

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Product Owner | | | |
| Tech Lead | | | |
| Operations Lead | | | |
| Business Owner | | | |

---

*Phase 3b begins after Phase 2 (Customer Portal) is complete.*
*Includes backend API development for campaign/SLA/audit services.*
