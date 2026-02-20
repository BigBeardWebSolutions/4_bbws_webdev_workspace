# Phase 2: Customer Portal

**Status**: Not Started (Blocked by Phase 1b)

---

## Overview

Phase 2 delivers the Customer Portal (Private) - the authenticated React SPA where customers manage their entire WordPress hosting lifecycle.

---

## Releases in This Phase

| Release | Name | BRS | Status | Progress |
|---------|------|-----|--------|----------|
| R2.0 | Customer Portal (Private) | 2.2 | Not Started | 0% |

---

## Dependencies

```
Phase 2 (Customer Portal)
└── R2.0 Customer Portal (BRS 2.2)
    ├── Depends on: R1.0 Tenant API ✅
    ├── Depends on: R1.1 Instance API ✅
    ├── Depends on: R1.2 Site API ⏳ (In Progress)
    ├── Depends on: R1.3 Subscription ⏳ (In Progress)
    └── Depends on: R1.0.1 Access Mgmt ⏳ (In Progress)
```

---

## Epic Summary (65 User Stories)

| Epic | Name | Stories | Priority |
|------|------|---------|----------|
| 1 | User Registration & Email Verification | 10 | P0 |
| 2 | Invitation Response | 4 | P0 |
| 3 | Customer Authentication & Password Recovery | 11 | P0 |
| 4 | Dashboard & Account Management | 3 | P0 |
| 5 | Organisation & User Management | 8 | P0 |
| 6 | Tenant Management | 5 | P0 |
| 7 | Site Management | 13 | P0 |
| 8 | Billing & Subscriptions | 6 | P0 |
| 9 | Support Tickets | 4 | P0 |
| 10 | White-Label & Marketplace | 4 | P1 |

---

## Key Deliverables

### R2.0 - Customer Portal (Private)
- User registration and email verification
- Organisation and tenant management
- WordPress site management (create, promote, backup, restore)
- Subscription and billing management
- Support ticket creation and tracking
- Multi-environment visibility (DEV/SIT/PROD)

---

## Technology Stack

| Component | Technology |
|-----------|------------|
| Framework | React 18 + TypeScript + Vite |
| State Management | React Query + Context |
| Styling | Tailwind CSS |
| Authentication | AWS Cognito |
| Hosting | S3 + CloudFront |

---

## Screen Count

| Category | Screens |
|----------|---------|
| Authentication | 5 |
| Organisation | 4 |
| Tenant | 3 |
| Sites | 5 |
| Migration | 1 |
| Billing | 4 |
| Support | 3 |
| **Total** | **25** |

---

## Downstream Impact

| Phase | Releases Waiting | Dependency Type |
|-------|------------------|-----------------|
| Phase 3b | R2.2 Admin Portal | Portal patterns |

---

## Release Plans

- [R2.0_Customer_Portal_Private.md](./R2.0_Customer_Portal_Private.md)

---

*Phase 2 is blocked until R1.2 (Site API) and R1.3 (Subscription) are complete.*
