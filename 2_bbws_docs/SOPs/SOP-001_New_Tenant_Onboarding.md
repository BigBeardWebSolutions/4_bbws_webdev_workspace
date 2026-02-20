# SOP-001: New Tenant Onboarding

**Version:** 1.0
**Effective Date:** 2026-01-18
**Department:** Customer Success
**Approved By:** Operations Manager

---

## 1. Purpose

This Standard Operating Procedure defines the steps for onboarding new tenants to the Site Builder platform, ensuring a consistent and high-quality customer experience from purchase to first site creation.

---

## 2. Scope

This SOP applies to:
- All new tenant accounts created via the `/buy` checkout flow
- Manual tenant provisioning by support staff
- Enterprise onboarding with custom setup

---

## 3. Definitions

| Term | Definition |
|------|------------|
| Tenant | An organization/customer with a Site Builder account |
| User | An individual with login access to a tenant |
| Provisioning | The automated creation of tenant resources |
| Onboarding | The process of getting a new tenant productive |

---

## 4. Responsibilities

| Role | Responsibility |
|------|----------------|
| System | Automated provisioning, welcome email |
| Customer Success | Manual follow-up, onboarding call (Enterprise) |
| Support | Resolve provisioning issues, manual setup |
| User | Complete onboarding, create first site |

---

## 5. Procedure

### 5.1 Automated Onboarding (Standard)

#### Step 1: Payment Confirmation
| Actor | System |
|-------|--------|
| Trigger | PayFast ITN received |
| Action | Validate payment, trigger provisioning |
| Output | Order marked as COMPLETE |
| Time | < 5 seconds |

#### Step 2: Tenant Provisioning
| Actor | Provisioning Lambda |
|-------|---------------------|
| Action | Create tenant record, Cognito user |
| Output | Tenant ID, User ID |
| Time | < 10 seconds |

#### Step 3: Welcome Email
| Actor | Email Service |
|-------|---------------|
| Template | `tenant-welcome` |
| Contains | Login link, temporary password (if new), getting started guide |
| Time | < 30 seconds |

#### Step 4: First Login
| Actor | User |
|-------|------|
| Action | Click login link, set password (if new) |
| Output | Authenticated session |

#### Step 5: Onboarding Tour
| Actor | Site Builder App |
|-------|------------------|
| Trigger | First login detected |
| Action | Display interactive tour |
| Steps | Welcome → Chat Panel → Preview → Deploy |
| Duration | ~2 minutes |

#### Step 6: First Site Creation
| Actor | User |
|-------|------|
| Action | Enter prompt, generate first landing page |
| Success Criteria | HTML rendered in preview panel |

---

### 5.2 Manual Onboarding (Support-Assisted)

Use this procedure when automated provisioning fails.

#### Prerequisites Checklist
- [ ] Payment confirmation (transaction ID)
- [ ] Customer email address
- [ ] Selected plan
- [ ] Customer name/company

#### Step 1: Verify Payment
```
1. Log into PayFast dashboard
2. Search for transaction ID
3. Confirm status = COMPLETE
4. Note: amount, email, date
```

#### Step 2: Check Existing Records
```
1. Search DynamoDB `tenants` table by email
2. Search Cognito User Pool by email
3. If records exist, skip to Step 5
```

#### Step 3: Create Cognito User
```
AWS Console > Cognito > User Pools > site-builder-{env}
1. Click "Create user"
2. Email: [customer email]
3. Check "Send invitation"
4. Temporary password: [generate secure]
5. Attributes:
   - custom:tenant_id = [will set after tenant creation]
   - custom:roles = tenant_admin
6. Click "Create user"
7. Note the user sub (user ID)
```

#### Step 4: Create Tenant Record
```
AWS Console > DynamoDB > Tables > tenants
1. Click "Create item"
2. Enter:
   - tenant_id: ten_[generate UUID]
   - owner_user_id: [user sub from Step 3]
   - plan: [professional/enterprise]
   - status: active
   - limits: [based on plan]
   - billing.transaction_id: [from payment]
   - billing.invoice_number: INV-[generate]
   - created_at: [current ISO timestamp]
3. Save
```

#### Step 5: Update Cognito User Attributes
```
AWS Console > Cognito > User Pools > Users > [user]
1. Edit attributes
2. Set custom:tenant_id = [tenant_id from Step 4]
3. Save
```

#### Step 6: Create User Record
```
AWS Console > DynamoDB > Tables > users
1. Click "Create item"
2. Enter:
   - user_id: [same as Cognito sub]
   - tenant_id: [from Step 4]
   - email: [customer email]
   - role: tenant_admin
   - status: active
   - created_at: [current ISO timestamp]
3. Save
```

#### Step 7: Send Welcome Email
```
1. Use email template: manual-welcome
2. Include:
   - Login URL
   - Temporary password (if set)
   - Support contact
3. Send via support ticketing system
```

#### Step 8: Document in Ticket
```
1. Record all created IDs
2. Note any issues encountered
3. Set ticket to "Resolved"
4. Schedule 24-hour follow-up
```

---

### 5.3 Enterprise Onboarding

Additional steps for Enterprise tier:

#### Pre-Onboarding Call
| Duration | 30 minutes |
|----------|------------|
| Attendees | Customer champion, CS manager |
| Agenda | Requirements, timeline, brand guidelines |

#### Custom Setup
| Task | Owner | Timeline |
|------|-------|----------|
| SSO/SAML configuration | Engineering | 2-3 days |
| Custom domain setup | Operations | 1-2 days |
| Brand guidelines import | CS | 1 day |
| User bulk import | CS | 1 day |

#### Training Session
| Duration | 1 hour |
|----------|--------|
| Format | Video call, screen share |
| Content | Platform overview, best practices, Q&A |
| Recording | Provided to customer |

#### Success Check-in
| Timing | 7 days post-onboarding |
|--------|------------------------|
| Purpose | Verify adoption, address issues |
| Outcome | Document feedback, adjust if needed |

---

## 6. Quality Checklist

Before marking onboarding complete, verify:

- [ ] Tenant can log in successfully
- [ ] Tenant sees correct plan/limits
- [ ] Tenant can generate a test page
- [ ] Welcome email was received
- [ ] Onboarding tour completed (or skipped)
- [ ] No errors in account

---

## 7. Troubleshooting

| Issue | Resolution | Reference |
|-------|------------|-----------|
| User cannot login | See RB-001 | /runbooks/RB-001 |
| No welcome email | Resend via Cognito | SOP-001, Step 3 |
| Wrong plan assigned | Update tenant record | Manual procedure |
| Cognito user locked | Reset via admin console | Cognito docs |

---

## 8. Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Auto-provision success rate | > 99% | Daily automated report |
| Time to first login | < 1 hour | Average across all tenants |
| Onboarding tour completion | > 70% | Analytics dashboard |
| First site within 24 hours | > 50% | Engagement metrics |

---

## 9. Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-18 | Customer Success | Initial version |

---

## 10. Related Documents

| Document | Link |
|----------|------|
| BP-001 | /business_process/BP-001_Tenant_Provisioning.md |
| RB-001 | /runbooks/RB-001_Tenant_Provisioning.md |
| BP-006 | /business_process/BP-006_Payment_to_SiteBuilder_Handoff.md |
