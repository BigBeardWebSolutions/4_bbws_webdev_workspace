# BP-004: Custom Domain Setup Process

**Version:** 1.0
**Effective Date:** 2026-01-18
**Process Owner:** Platform Operations
**Last Review:** 2026-01-18

---

## 1. Process Overview

### 1.1 Purpose
This document describes the business process for setting up custom domains for tenant sites. This allows tenants to serve their generated landing pages from their own domain (e.g., `www.mybusiness.com`) instead of the default shared domain.

### 1.2 Scope
- Tenant requests custom domain
- DNS validation via TXT record
- ACM certificate provisioning
- CloudFront alias configuration
- Route 53 / External DNS setup

### 1.3 Eligibility
| Plan | Custom Domain |
|------|---------------|
| Basic | Not available |
| Professional | 1 domain |
| Enterprise | Unlimited |

---

## 2. Process Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│                    CUSTOM DOMAIN SETUP PROCESS                            │
│                              BP-004                                       │
└──────────────────────────────────────────────────────────────────────────┘

    ┌─────────────┐
    │   START     │
    │  Tenant     │
    │  Requests   │
    │  Domain     │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐     ┌─────────────────────────────────────────────┐
    │  Validate   │     │ Checks:                                     │
    │  Request    │────▶│ • Plan allows custom domains                │
    │             │     │ • Domain quota not exceeded                 │
    │             │     │ • Domain format valid                       │
    │             │     │ • Domain not already in use                 │
    └──────┬──────┘     └─────────────────────────────────────────────┘
           │
           │ Valid
           ▼
    ┌─────────────┐
    │  Create     │
    │  Domain     │
    │  Record     │
    │  (PENDING)  │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐     ┌─────────────────────────────────────────────┐
    │  Generate   │     │ DNS Records for Tenant:                     │
    │  DNS        │────▶│                                             │
    │  Validation │     │ TXT _acme-challenge.www.mybusiness.com      │
    │  Records    │     │     Value: abc123xyz789...                  │
    │             │     │                                             │
    └──────┬──────┘     │ (Or CNAME for DNS validation)               │
           │            └─────────────────────────────────────────────┘
           │
           ▼
    ┌─────────────┐
    │  Display    │
    │  DNS        │
    │  Instructions│
    │  to Tenant  │
    └──────┬──────┘
           │
           │ Tenant adds DNS records
           ▼
    ┌─────────────────────────────────────────────────────────────────┐
    │                    WAITING FOR DNS                               │
    │                                                                  │
    │  Status: PENDING_VALIDATION                                     │
    │  Auto-check every 5 minutes for up to 72 hours                  │
    │                                                                  │
    └──────────────────────────────────────────────────────────────────┘
           │
           │ DNS validated
           ▼
    ┌─────────────┐
    │  Request    │
    │  ACM        │
    │  Certificate│
    └──────┬──────┘
           │
           ▼
    ┌─────────────────────────────────────────────────────────────────┐
    │                 ACM CERTIFICATE ISSUANCE                         │
    │                                                                  │
    │  Certificate for: www.mybusiness.com                            │
    │  Region: us-east-1 (required for CloudFront)                    │
    │  Validation: DNS                                                │
    │                                                                  │
    │  Wait time: 5-30 minutes typically                              │
    │                                                                  │
    └──────────────────────────────────────────────────────────────────┘
           │
           │ Certificate issued
           ▼
    ┌─────────────┐
    │  Update     │
    │  CloudFront │
    │  Distribution│
    │  Add Alias  │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐     ┌─────────────────────────────────────────────┐
    │  Generate   │     │ Final DNS Record:                           │
    │  Final DNS  │────▶│                                             │
    │  Record     │     │ CNAME www.mybusiness.com                    │
    │             │     │       d123abc.cloudfront.net                │
    │             │     │                                             │
    └──────┬──────┘     │ OR (for apex domain):                       │
           │            │ A www.mybusiness.com (ALIAS)                │
           │            │   d123abc.cloudfront.net                    │
           │            └─────────────────────────────────────────────┘
           ▼
    ┌─────────────┐
    │  Display    │
    │  Final DNS  │
    │  Instructions│
    └──────┬──────┘
           │
           │ Tenant updates DNS
           ▼
    ┌─────────────────────────────────────────────────────────────────┐
    │                    WAITING FOR CNAME                             │
    │                                                                  │
    │  Status: PENDING_DNS                                            │
    │  Auto-check every 5 minutes                                     │
    │                                                                  │
    └──────────────────────────────────────────────────────────────────┘
           │
           │ DNS propagated
           ▼
    ┌─────────────┐
    │  Update     │
    │  Status     │
    │  (ACTIVE)   │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐
    │  Send       │
    │  Confirmation│
    │  Email      │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐
    │    END      │
    │  Domain     │
    │  Active     │
    └─────────────┘
```

---

## 3. Domain States

```
┌──────────────────────────────────────────────────────────────────┐
│                    DOMAIN STATE MACHINE                           │
└──────────────────────────────────────────────────────────────────┘

  ┌─────────┐
  │ PENDING │ ─────────▶ Request submitted
  └────┬────┘
       │
       ▼
  ┌──────────────────┐
  │PENDING_VALIDATION│ ─────────▶ Waiting for DNS TXT record
  └────────┬─────────┘
           │
     ┌─────┴─────┐
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│VALIDATED│ │ FAILED  │ ─────────▶ Timeout (72 hours)
└────┬────┘ └─────────┘
     │
     ▼
┌───────────────┐
│CERT_REQUESTED │ ─────────▶ ACM certificate requested
└───────┬───────┘
        │
        ▼
┌───────────────┐
│  PENDING_DNS  │ ─────────▶ Waiting for CNAME
└───────┬───────┘
        │
  ┌─────┴─────┐
  │           │
  ▼           ▼
┌────────┐ ┌─────────┐
│ ACTIVE │ │ EXPIRED │
└────────┘ └─────────┘
```

---

## 4. DNS Records Required

### 4.1 Step 1: Domain Validation (TXT Record)
```
Type:  TXT
Name:  _acme-challenge.www.mybusiness.com
Value: [provided by system - random string]
TTL:   300
```

### 4.2 Step 2: Point Domain to CloudFront (CNAME)
```
Type:  CNAME
Name:  www.mybusiness.com
Value: d123abc.cloudfront.net
TTL:   300
```

### 4.3 Apex Domain (Optional - Route 53 only)
```
Type:  A (Alias)
Name:  mybusiness.com
Alias: d123abc.cloudfront.net
```

---

## 5. Data Model

### 5.1 Custom Domain Record
```json
{
  "domain_id": "dom_abc123",
  "tenant_id": "ten_xyz789",
  "site_id": "site_123456",
  "domain_name": "www.mybusiness.com",
  "status": "pending|pending_validation|validated|cert_requested|pending_dns|active|failed|expired",
  "validation": {
    "type": "dns",
    "record_name": "_acme-challenge.www.mybusiness.com",
    "record_value": "abc123xyz789...",
    "validated_at": null
  },
  "certificate": {
    "arn": "arn:aws:acm:us-east-1:...",
    "issued_at": null,
    "expires_at": null
  },
  "cloudfront": {
    "distribution_id": "E123ABC",
    "domain_name": "d123abc.cloudfront.net"
  },
  "created_at": "2026-01-18T10:00:00Z",
  "activated_at": null,
  "last_checked_at": "2026-01-18T10:05:00Z"
}
```

---

## 6. Validation Polling

### 6.1 Schedule
| Stage | Check Interval | Timeout |
|-------|---------------|---------|
| DNS Validation | Every 5 minutes | 72 hours |
| Certificate Issuance | Every 1 minute | 30 minutes |
| CNAME Propagation | Every 5 minutes | 48 hours |

### 6.2 Implementation
```python
# EventBridge rule triggers Lambda every 5 minutes
def check_pending_domains():
    domains = get_domains_by_status(['pending_validation', 'pending_dns'])

    for domain in domains:
        if is_timed_out(domain):
            update_status(domain, 'failed', 'Validation timeout')
            send_failure_notification(domain)
        elif validate_dns(domain):
            advance_to_next_stage(domain)
```

---

## 7. Error Handling

| Error | Cause | Resolution |
|-------|-------|------------|
| Domain already exists | Another tenant using domain | Contact support |
| Validation timeout | DNS not configured | Resend instructions, extend timeout |
| Certificate failed | ACM issue | Retry certificate request |
| CNAME not resolving | DNS not propagated | Wait, check DNS provider |

---

## 8. Security Considerations

- Validate domain ownership before issuing certificate
- Only allow domains not already in CloudFront
- Certificate must be in us-east-1 for CloudFront
- Monitor for certificate expiry (auto-renew with ACM)

---

## 9. User Communications

### 9.1 Email Templates
| Template | Trigger | Content |
|----------|---------|---------|
| domain-validation-instructions | Domain requested | DNS TXT record instructions |
| domain-cname-instructions | Certificate issued | Final CNAME instructions |
| domain-activated | Domain active | Confirmation, URL |
| domain-validation-reminder | 24h, 48h pending | Reminder to add DNS |
| domain-failed | Timeout | Failure notice, retry option |

---

## 10. Related Documents

| Document | Type | Location |
|----------|------|----------|
| RB-004 | Runbook | /runbooks/RB-004_Custom_Domain_Configuration.md |
| SOP-004 | SOP | /SOPs/SOP-004_Custom_Domain_Request_Handling.md |

---

## 11. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-18 | Platform Team | Initial version |
