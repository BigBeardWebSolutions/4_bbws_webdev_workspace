# BP-006: Payment to Site Builder Handoff Process

**Version:** 1.0
**Effective Date:** 2026-01-18
**Process Owner:** Product Development
**Last Review:** 2026-01-18

---

## 1. Process Overview

### 1.1 Purpose
This document describes the end-to-end handoff process from successful payment on the `/buy` checkout flow to authenticated access in the Site Builder application. This is the critical integration point between the commerce and product platforms.

### 1.2 Scope
- Payment success page display
- Tenant provisioning trigger
- User authentication
- Site Builder entry point
- Onboarding experience

### 1.3 Key Stakeholders
| Stakeholder | Role |
|-------------|------|
| Customer | Completes payment, receives access |
| Payment System | Processes payment, triggers ITN |
| Provisioning Service | Creates tenant and user |
| Authentication Service | Issues credentials, manages login |
| Site Builder App | Receives authenticated user |

---

## 2. Complete Handoff Flow

```
┌──────────────────────────────────────────────────────────────────────────┐
│                PAYMENT TO SITE BUILDER HANDOFF PROCESS                    │
│                              BP-006                                       │
└──────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                         PAYMENT FLOW                                     │
│                    (dev.kimmyai.io/buy/)                                 │
└─────────────────────────────────────────────────────────────────────────┘
           │
           ▼
    ┌─────────────┐
    │  PayFast    │
    │  Payment    │
    │  Complete   │
    └──────┬──────┘
           │
     ┌─────┴─────────────────────────────────────┐
     │                                           │
     ▼                                           ▼
┌─────────────────┐                    ┌─────────────────┐
│  ITN CALLBACK   │                    │  USER REDIRECT  │
│  (Server-side)  │                    │  (Browser)      │
│                 │                    │                 │
│  PayFast →      │                    │  PayFast →      │
│  api.kimmyai.io │                    │  /buy/payment/  │
│  /orders/itn    │                    │  success        │
└────────┬────────┘                    └────────┬────────┘
         │                                      │
         ▼                                      │
┌─────────────────┐                             │
│  VALIDATE       │                             │
│  PAYMENT        │                             │
│  (Lambda)       │                             │
└────────┬────────┘                             │
         │                                      │
         ▼                                      │
┌─────────────────┐                             │
│  PROVISION      │     Async                   │
│  TENANT         │◀────(SQS)────────────────── │ Trigger
│  (BP-001)       │                             │
└────────┬────────┘                             │
         │                                      │
         ├──────────────────────────────────────┤
         │                                      │
         ▼                                      ▼
┌─────────────────┐                    ┌─────────────────┐
│  CREATE         │                    │  SUCCESS PAGE   │
│  COGNITO USER   │                    │  DISPLAYED      │
│  (if new)       │                    │                 │
└────────┬────────┘                    │  Shows:         │
         │                             │  • Trans ID     │
         │                             │  • Invoice #    │
         │                             │  • Email sent   │
         ▼                             │  confirmation   │
┌─────────────────┐                    │                 │
│  CREATE         │                    │  [Start         │
│  TENANT RECORD  │                    │   Building]     │
│  (DynamoDB)     │                    │   Button        │
└────────┬────────┘                    └────────┬────────┘
         │                                      │
         ▼                                      │
┌─────────────────┐                             │
│  SEND WELCOME   │                             │
│  EMAIL          │                             │
│  (with temp pwd │                             │
│   if new user)  │                             │
└────────┬────────┘                             │
         │                                      │
         └──────────────────┬───────────────────┘
                            │
                            │ User clicks "Start Building"
                            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      AUTHENTICATION GATE                                 │
│                   (dev.kimmyai.io/auth/login)                           │
└─────────────────────────────────────────────────────────────────────────┘
                            │
                      ┌─────┴─────┐
                      │           │
                      ▼           ▼
               ┌───────────┐ ┌───────────┐
               │ EXISTING  │ │   NEW     │
               │ USER      │ │   USER    │
               │           │ │           │
               │ Enter     │ │ Enter     │
               │ password  │ │ temp pwd  │
               └─────┬─────┘ └─────┬─────┘
                     │             │
                     │             ▼
                     │      ┌───────────┐
                     │      │ SET NEW   │
                     │      │ PASSWORD  │
                     │      │ (forced)  │
                     │      └─────┬─────┘
                     │             │
                     └──────┬──────┘
                            │
                            ▼
                     ┌───────────┐
                     │ COGNITO   │
                     │ ISSUES    │
                     │ JWT TOKEN │
                     └─────┬─────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        SITE BUILDER                                      │
│              (api.dev.kimmyai.io/site_builder/)                         │
└─────────────────────────────────────────────────────────────────────────┘
                            │
                      ┌─────┴─────┐
                      │           │
                      ▼           ▼
               ┌───────────┐ ┌───────────┐
               │ FIRST     │ │ RETURNING │
               │ TIME USER │ │ USER      │
               └─────┬─────┘ └─────┬─────┘
                     │             │
                     ▼             │
               ┌───────────┐       │
               │ ONBOARDING│       │
               │ TOUR      │       │
               │           │       │
               │ 1. Welcome│       │
               │ 2. Chat   │       │
               │ 3. Preview│       │
               │ 4. Deploy │       │
               └─────┬─────┘       │
                     │             │
                     └──────┬──────┘
                            │
                            ▼
                     ┌───────────┐
                     │ DASHBOARD │
                     │           │
                     │ Ready to  │
                     │ create    │
                     │ first site│
                     └───────────┘
```

---

## 3. URL Flow

### 3.1 URL Sequence
| Step | URL | Domain |
|------|-----|--------|
| 1. Pricing | `/buy/` | dev.kimmyai.io |
| 2. Checkout | `/buy/checkout` | dev.kimmyai.io |
| 3. PayFast | `sandbox.payfast.co.za/...` | PayFast |
| 4. Success | `/buy/payment/success?txn=...` | dev.kimmyai.io |
| 5. Login | `/auth/login` | dev.kimmyai.io |
| 6. Dashboard | `/page_builder` | dev.kimmyai.io |
| 7. API | `/site_builder/*` | api.dev.kimmyai.io |

### 3.2 Query Parameters on Success Page
```
/buy/payment/success?
  transaction_id=TXN-123456
  &invoice_number=INV-123456
  &pf_payment_id=2953133
  &status=COMPLETE
```

---

## 4. Data Passed Between Systems

### 4.1 Payment → Provisioning (ITN)
```json
{
  "pf_payment_id": "2953133",
  "payment_status": "COMPLETE",
  "item_name": "Professional Plan",
  "amount_gross": "5000.00",
  "email_address": "user@example.com",
  "name_first": "John",
  "name_last": "Doe",
  "custom_str1": "TXN-123456",
  "custom_str2": "INV-123456",
  "signature": "abc123..."
}
```

### 4.2 Success Page → Site Builder (Session)
```javascript
// Stored in sessionStorage on success page
sessionStorage.setItem('purchase_context', JSON.stringify({
  transactionId: 'TXN-123456',
  invoiceNumber: 'INV-123456',
  plan: 'professional',
  email: 'user@example.com',
  isNewUser: true
}));

// Retrieved by Site Builder after login
const context = JSON.parse(sessionStorage.getItem('purchase_context'));
```

### 4.3 JWT Claims (After Login)
```json
{
  "sub": "user-uuid",
  "email": "user@example.com",
  "custom:tenant_id": "ten_abc123",
  "custom:roles": "tenant_admin",
  "custom:plan": "professional"
}
```

---

## 5. Timing Considerations

### 5.1 Race Condition Handling
```
PROBLEM: User might click "Start Building" before provisioning completes

SOLUTION: Polling mechanism on login

  1. User clicks "Start Building"
  2. Redirect to login page
  3. User enters credentials
  4. Before issuing JWT, check if tenant exists
  5. IF tenant not ready:
       - Show "Setting up your account..." spinner
       - Poll every 2 seconds for max 30 seconds
       - When tenant ready, issue JWT and continue
  6. IF timeout:
       - Show friendly error
       - "Your account is being set up. Check email for confirmation."
       - Provide support contact
```

### 5.2 Expected Timing
| Step | Expected Duration | Max Duration |
|------|-------------------|--------------|
| PayFast redirect | < 1s | 3s |
| ITN processing | < 2s | 10s |
| Tenant provisioning | < 5s | 30s |
| Welcome email | < 10s | 60s |
| Login (existing user) | < 2s | 5s |
| Login (new user + password change) | < 30s | 120s |

---

## 6. Error Scenarios

### 6.1 Error Handling Matrix
| Scenario | User Sees | Backend Action |
|----------|-----------|----------------|
| Payment failed | Error page with retry | Log, no provisioning |
| ITN validation failed | Success page, delayed email | Alert ops, manual check |
| Provisioning failed | Login shows "setting up" | Retry 3x, then alert |
| Email send failed | Can still login | Retry via SQS, log warning |
| User already exists | Normal login | Skip user creation |
| Invalid temp password | "Request new password" link | Resend via Cognito |

### 6.2 Recovery Actions
```
ON provisioning failure after payment:
  1. Log error with full context
  2. Send alert to operations team
  3. User can retry login (triggers re-check)
  4. Manual provisioning available via admin portal
  5. Refund process if not recoverable
```

---

## 7. Onboarding Experience

### 7.1 First-Time User Tour
| Step | Component | Description |
|------|-----------|-------------|
| 1 | Welcome Modal | "Welcome to Site Builder! Let's create your first landing page." |
| 2 | Chat Panel Highlight | "Describe what you want, and AI will generate it." |
| 3 | Preview Panel Highlight | "See your page come to life in real-time." |
| 4 | Deploy Button Highlight | "When ready, deploy with one click." |
| 5 | Complete | "You're all set! Start creating." |

### 7.2 Onboarding State
```json
{
  "user_id": "user_abc123",
  "onboarding": {
    "completed": false,
    "current_step": 0,
    "started_at": "2026-01-18T10:00:00Z",
    "completed_at": null,
    "skipped": false
  }
}
```

---

## 8. Monitoring & Alerts

### 8.1 Key Metrics
| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| Handoff Success Rate | % of payments leading to active users | < 95% |
| Time to First Login | Time from payment to first login | > 24 hours |
| Provisioning Failures | Failed tenant creations | > 1% |
| Onboarding Completion | % completing tour | < 50% (warning) |

### 8.2 Dashboard
- Real-time payment-to-activation funnel
- Average time at each stage
- Drop-off points analysis
- Error rate by step

---

## 9. Related Documents

| Document | Type | Location |
|----------|------|----------|
| BP-001 | Business Process | /business_process/BP-001_Tenant_Provisioning.md |
| BP-005 | Business Process | /business_process/BP-005_User_Authentication.md |
| Payment Flow | LLD | /LLDs/2_LLD_payments_integration/ |
| Site Builder Frontend | LLD | /LLDs/3.1.1_LLD_Site_Builder_Frontend.md |

---

## 10. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-18 | Product Team | Initial version |
