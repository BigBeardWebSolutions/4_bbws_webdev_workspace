# BBWS Platform - Release Plans

**Last Updated**: 2026-01-26
**Status**: Active Development

---

## Overview

This directory contains all release plans for the BBWS Platform, organized by phases with dependency projects.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     BBWS PLATFORM RELEASE OVERVIEW                          │
│                     Last Updated: 2026-01-26                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   Overall Progress: [████████████░░░░░░░░] 60%                              │
│                                                                              │
│   Phase 0 (Foundation):    [██████████] 100% ✅ DEPLOYED TO DEV             │
│     └─ R1.0   Tenant Mgmt: [██████████] 100% ✅ DEV DEPLOYED                │
│     └─ R1.0.1 Access Mgmt: [██████████] 100% ✅ DEV DEPLOYED (2026-01-25)   │
│   Phase 1a (Instance API): [██████████] 100% ✅ DEPLOYED TO DEV             │
│   Phase 1b (Site API):     [█████████░] 90%  ✅ DEV DEPLOYED (2026-01-25)   │
│   Phase 2 (Customer Portal): [░░░░░░░░░░] 0%   🟢 UNBLOCKED                 │
│   Phase 3a (Admin App):    [░░░░░░░░░░] 0%   ⏸️ Not Started                 │
│   Phase 3b (Admin Portal): [░░░░░░░░░░] 0%   ⏸️ Blocked                     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Release Schedule

| Release | Phase | BRS | Component | Status | Priority |
|---------|-------|-----|-----------|--------|----------|
| R1.0 | Phase 0 | 2.5 | Tenant Management API | ✅ DEV Deployed | P0 |
| R1.0.1 | Phase 0 | 2.8 | Access Management | ✅ DEV Deployed (2026-01-25) | P0 |
| R1.1 | Phase 1a | 2.7 | Instance Management API | ✅ DEV Deployed | P0 |
| R1.2 | Phase 1b | 2.6 | Site Management API | ✅ DEV Deployed (2026-01-25) | P0 |
| R1.3 | Phase 1 | 2.1.11 | Subscription & Billing | LLDs Complete | P0 |
| R1.4 | Phase 1 | 2.2 | Buy User Journey (Payments/Orders) | In Progress | P0 |
| R2.0 | Phase 2 | 2.2 | Customer Portal (Private) | 🟢 Unblocked | P0 |
| R2.1 | Phase 3a | 2.3 | Admin App | ⏸️ Not Started | P1 |
| R2.2 | Phase 3b | 2.4 | Admin Portal | ⏸️ Blocked | P1 |

---

## Phase Directory Structure

```
release_plans/
├── README.md (this file)
│
├── phase-0-foundation/
│   ├── README.md
│   ├── R1.0_Tenant_Management_API.md
│   └── R1.0.1_Access_Management.md
│
├── phase-1-core-apis/
│   ├── README.md
│   ├── R1.1_Instance_Management_API.md
│   ├── R1.2_Site_Management_API.md
│   ├── R1.3_Subscription_Billing.md
│   └── R1.4_Buy_User_Journey.md
│
├── phase-2-customer-portal/
│   ├── README.md
│   └── R2.0_Customer_Portal_Private.md
│
└── phase-3-admin-tools/
    ├── README.md
    ├── R2.1_Admin_App.md
    └── R2.2_Admin_Portal.md
```

---

## Dependency Graph

```
                    ┌─────────────────────┐
                    │ Phase 0: Foundation │
                    │ R1.0 Tenant API     │
                    │ R1.0.1 Access Mgmt  │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                │
   ┌─────────────────┐  ┌─────────────────┐    │
   │ Phase 1a        │  │ Phase 1b        │    │
   │ R1.1 Instance   │  │ R1.2 Site API   │    │
   │ API ✅          │  │ R1.3 Subscription│   │
   └────────┬────────┘  └────────┬────────┘    │
            │                    │             │
            ▼                    ▼             │
   ┌─────────────────┐  ┌─────────────────┐    │
   │ Phase 3a        │  │ Phase 2         │    │
   │ R2.1 Admin App  │  │ R2.0 Customer   │    │
   └─────────────────┘  │ Portal          │    │
                        └────────┬────────┘    │
                                 │             │
                                 ▼             │
                        ┌─────────────────┐    │
                        │ Phase 3b        │    │
                        │ R2.2 Admin      │    │
                        │ Portal          │    │
                        └─────────────────┘    │
```

---

## Quick Links

### Phase 0: Foundation
- [R1.0 - Tenant Management API](./phase-0-foundation/R1.0_Tenant_Management_API.md)
- [R1.0.1 - Access Management](./phase-0-foundation/R1.0.1_Access_Management.md)

### Phase 1: Core APIs
- [R1.1 - Instance Management API](./phase-1-core-apis/R1.1_Instance_Management_API.md)
- [R1.2 - Site Management API](./phase-1-core-apis/R1.2_Site_Management_API.md)
- [R1.3 - Subscription & Billing](./phase-1-core-apis/R1.3_Subscription_Billing.md)
- [R1.4 - Buy User Journey](./phase-1-core-apis/R1.4_Buy_User_Journey.md)

### Phase 2: Customer Portal
- [R2.0 - Customer Portal (Private)](./phase-2-customer-portal/R2.0_Customer_Portal_Private.md)

### Phase 3: Admin Tools
- [R2.1 - Admin App](./phase-3-admin-tools/R2.1_Admin_App.md)
- [R2.2 - Admin Portal](./phase-3-admin-tools/R2.2_Admin_Portal.md)

---

## Related Documents

| Document | Location | Purpose |
|----------|----------|---------|
| Master Release Plan | `/project_plans/MASTER_RELEASE_PLAN.md` | Overall release strategy |
| BRS Documents | `/BRS/` | Business requirements |
| HLD Documents | `/HLDs/` | High-level designs |
| LLD Documents | `/LLDs/` | Low-level designs |

---

## Environment URLs

| Environment | Customer Portal | Admin App | Admin Portal |
|-------------|-----------------|-----------|--------------|
| DEV | `dev.portal.kimmyai.io` | `admin-dev.kimmyai.io` | `portal-admin-dev.kimmyai.io` |
| SIT | `sit.portal.kimmyai.io` | `admin-sit.kimmyai.io` | `portal-admin-sit.kimmyai.io` |
| PROD | `portal.kimmyai.io` | `admin.kimmyai.io` | `portal-admin.kimmyai.io` |

---

*All releases follow the BBWS Full-Stack SDLC v3.0 process definition.*
