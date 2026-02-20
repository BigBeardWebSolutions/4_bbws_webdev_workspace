# Phase 1: Core APIs

**Status**: ✅ DEV DEPLOYED (Phase 1a: 100%, Phase 1b: 90%)
**Last Updated**: 2026-01-26

---

## Overview

Phase 1 delivers the core backend APIs for WordPress instance and site management. This phase can run partially in parallel after Phase 0 foundation is complete.

---

## DEV Environment URLs

| Component | URL | Status |
|-----------|-----|--------|
| Instance Management API | `https://o158f3j653.execute-api.eu-west-1.amazonaws.com` | ✅ Live |
| Site Management API | `https://en6tdna9z4.execute-api.eu-west-1.amazonaws.com` | ✅ Live |

---

## Releases in This Phase

| Release | Name | BRS | Status | Progress |
|---------|------|-----|--------|----------|
| R1.1 | Instance Management API | 2.7 | ✅ DEV Deployed | 100% |
| R1.2 | Site Management API | 2.6 | ✅ DEV Deployed (2026-01-25) | 90% |
| R1.3 | Subscription & Billing | 2.1.11 | LLDs Complete | 30% |
| R1.4 | Buy User Journey | 2.2 | ✅ Backend DEV Deployed | 85% |

---

## Dependencies

```
Phase 1 (Core APIs)
├── Phase 1a: Instance Management
│   └── R1.1 Instance Management API (BRS 2.7)
│       └── Depends on: R1.0 Tenant API ✅
│
├── Phase 1b: Site Management
│   └── R1.2 Site Management API (BRS 2.6)
│       └── Depends on: R1.0 Tenant API ✅
│
├── Dependency: Subscription & Billing
│   └── R1.3 Subscription & Billing (BRS 2.1.11)
│       └── Depends on: R1.0 Tenant API ✅
│
└── Buy User Journey (Frontend + Backend)
    └── R1.4 Buy User Journey (BRS 2.2)
        └── Depends on: R1.0 Tenant API ✅, R1.3 Subscription ⏳
```

---

## Key Deliverables

### R1.1 - Instance Management API
- WordPress instance provisioning (ECS/EFS/RDS)
- Instance health monitoring
- DynamoDB state tracking
- Cross-account management (DEV/SIT/PROD)

### R1.2 - Site Management API
- WordPress site CRUD operations
- Template marketplace
- Plugin management
- Environment promotion workflows

### R1.3 - Subscription & Billing
- Subscription plan management
- Payment processing (PayFast)
- Invoice generation
- Billing automation

### R1.4 - Buy User Journey
- Public pricing page with campaign discounts
- Checkout flow with customer form
- Order submission API integration
- PayFast payment gateway
- Payment success/cancel pages

---

## Parallel Execution Strategy

```
Week 1-6:  ├── R1.1 Instance API (Phase 1a) ──────────────► DEV
Week 1-8:  ├── R1.2 Site API (Phase 1b) ──────────────────► DEV
Week 3-8:  ├── R1.3 Subscription (Dependency) ────────────► DEV
Week 4-9:  └── R1.4 Buy User Journey (Frontend) ──────────► DEV
```

---

## Downstream Impact

| Phase | Releases Waiting | Dependency Type |
|-------|------------------|-----------------|
| Phase 2 | R2.0 Customer Portal | Site API + Subscription |
| Phase 3a | R2.1 Admin App | Instance API |
| Phase 3b | R2.2 Admin Portal | All APIs |

---

## Release Plans

- [R1.1_Instance_Management_API.md](./R1.1_Instance_Management_API.md)
- [R1.2_Site_Management_API.md](./R1.2_Site_Management_API.md)
- [R1.3_Subscription_Billing.md](./R1.3_Subscription_Billing.md)
- [R1.4_Buy_User_Journey.md](./R1.4_Buy_User_Journey.md)

---

*Phase 1a and 1b can run in parallel, maximizing development efficiency.*
