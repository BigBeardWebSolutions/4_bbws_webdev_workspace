# BP-003: Site Deployment Process

**Version:** 1.0
**Effective Date:** 2026-01-18
**Process Owner:** Platform Operations
**Last Review:** 2026-01-18

---

## 1. Process Overview

### 1.1 Purpose
This document describes the business process for deploying generated landing pages from the Site Builder to staging and production environments. Static HTML/CSS sites are deployed to S3 with CloudFront distribution.

### 1.2 Scope
- Deploy to staging environment for preview
- Deploy to production after approval
- Configure CloudFront caching
- Optional custom domain setup (separate process BP-004)

### 1.3 Process Inputs
| Input | Source | Required |
|-------|--------|----------|
| Site ID | Site Builder | Yes |
| Version ID | Version selector | Yes |
| Target Environment | User selection | Yes |
| Brand Score | Validation service | Yes |

### 1.4 Process Outputs
| Output | Destination | Format |
|--------|-------------|--------|
| Deployed Site | S3 + CloudFront | Static files |
| Deployment URL | User interface | HTTPS URL |
| Deployment Record | DynamoDB | JSON |

---

## 2. Process Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│                       SITE DEPLOYMENT PROCESS                             │
│                              BP-003                                       │
└──────────────────────────────────────────────────────────────────────────┘

    ┌─────────────┐
    │   START     │
    │  User       │
    │  Clicks     │
    │  Deploy     │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐     ┌─────────────────────────────────────────────┐
    │  Check      │     │ Pre-Deployment Checks:                      │
    │  Eligibility│────▶│ • Brand score meets threshold               │
    │             │     │ • User has deploy permission                │
    │             │     │ • No deployment in progress                 │
    │             │     │ • Target environment valid                  │
    └──────┬──────┘     └─────────────────────────────────────────────┘
           │
           │ Eligible
           ▼
    ┌─────────────┐
    │  Create     │
    │  Deployment │
    │  Record     │
    │  (PENDING)  │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐
    │  Select     │
    │  Target     │
    │  Environment│
    └──────┬──────┘
           │
     ┌─────┴─────┐
     │           │
     ▼           ▼
┌─────────┐ ┌─────────────┐
│ STAGING │ │ PRODUCTION  │
└────┬────┘ └──────┬──────┘
     │             │
     │             ▼
     │      ┌─────────────┐
     │      │ Additional  │
     │      │ Checks:     │
     │      │ Score >= 8.0│
     │      │ Staging OK  │
     │      └──────┬──────┘
     │             │
     └──────┬──────┘
            │
            ▼
    ┌─────────────┐
    │  Update     │
    │  Status     │
    │  (DEPLOYING)│
    └──────┬──────┘
            │
            ▼
    ┌─────────────────────────────────────────────────────────────────┐
    │                      S3 DEPLOYMENT                               │
    │                                                                  │
    │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
    │  │  Copy HTML  │    │  Copy CSS   │    │  Copy       │         │
    │  │  to S3      │    │  to S3      │    │  Assets     │         │
    │  └─────────────┘    └─────────────┘    └─────────────┘         │
    │                                                                  │
    │  Target: s3://sites-bucket/{tenant}/{site}/{env}/               │
    │                                                                  │
    └──────────────────────────────────────────────────────────────────┘
            │
            ▼
    ┌─────────────────────────────────────────────────────────────────┐
    │                   CLOUDFRONT INVALIDATION                        │
    │                                                                  │
    │  Invalidate: /{tenant}/{site}/*                                 │
    │  Wait for completion (typically 30-60 seconds)                  │
    │                                                                  │
    └──────────────────────────────────────────────────────────────────┘
            │
            ▼
    ┌─────────────┐
    │  Health     │
    │  Check      │
    │  New URL    │
    └──────┬──────┘
            │
      ┌─────┴─────┐
      │           │
      ▼           ▼
┌─────────┐ ┌─────────┐
│ SUCCESS │ │  FAIL   │
└────┬────┘ └────┬────┘
     │           │
     │           ▼
     │    ┌─────────────┐
     │    │  Rollback   │
     │    │  to Previous│
     │    │  Version    │
     │    └──────┬──────┘
     │           │
     └─────┬─────┘
           │
           ▼
    ┌─────────────┐
    │  Update     │
    │  Deployment │
    │  Record     │
    │  (COMPLETED │
    │  or FAILED) │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐
    │  Send       │
    │  Notification│
    │  Email      │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐
    │    END      │
    │  URL        │
    │  Returned   │
    └─────────────┘
```

---

## 3. Deployment Environments

### 3.1 Environment Configuration

| Environment | S3 Path | CloudFront | URL Pattern |
|-------------|---------|------------|-------------|
| Staging | `/staging/` | Shared | `staging.sites.kimmyai.io/{tenant}/{site}/` |
| Production | `/prod/` | Shared | `sites.kimmyai.io/{tenant}/{site}/` |

### 3.2 Deployment Rules

| Condition | Staging | Production |
|-----------|---------|------------|
| Brand Score < 6.0 | Blocked | Blocked |
| Brand Score 6.0 - 7.9 | Allowed (warning) | Blocked |
| Brand Score 8.0 - 8.9 | Allowed | Allowed (recommendations shown) |
| Brand Score >= 9.0 | Allowed | Auto-approved |
| Previous staging deploy | Not required | Required |
| User role: viewer | Blocked | Blocked |
| User role: editor | Allowed | Blocked |
| User role: admin | Allowed | Allowed |

---

## 4. S3 Structure

```
s3://site-builder-sites-{env}/
│
├── {tenant_id}/
│   ├── {site_id}/
│   │   ├── staging/
│   │   │   ├── index.html
│   │   │   ├── styles.css
│   │   │   ├── assets/
│   │   │   │   ├── logo.png
│   │   │   │   └── images/
│   │   │   └── _metadata.json
│   │   │
│   │   └── prod/
│   │       ├── index.html
│   │       ├── styles.css
│   │       ├── assets/
│   │       └── _metadata.json
│   │
│   └── {another_site}/
│       └── ...
│
└── {another_tenant}/
    └── ...
```

### 4.1 Metadata File
```json
{
  "version_id": "ver_abc123",
  "deployed_at": "2026-01-18T14:30:00Z",
  "deployed_by": "user_xyz",
  "brand_score": 8.7,
  "previous_version": "ver_xyz789",
  "generation_id": "gen_123456"
}
```

---

## 5. CloudFront Configuration

### 5.1 Cache Behavior
| Path Pattern | TTL | Cache Policy |
|--------------|-----|--------------|
| `/*.html` | 5 minutes | Dynamic |
| `/*.css` | 1 hour | Versioned |
| `/assets/*` | 24 hours | Immutable |
| `/_metadata.json` | No cache | Origin only |

### 5.2 Invalidation Strategy
- Invalidate on every deployment
- Path pattern: `/{tenant}/{site}/{env}/*`
- Maximum 1000 invalidations per distribution per month (free tier)

---

## 6. Rollback Process

```
┌─────────────────────────────────────────────────────────────────┐
│                      ROLLBACK FLOW                               │
└─────────────────────────────────────────────────────────────────┘

  Trigger: Health check fails OR User requests rollback

  1. Retrieve previous version metadata
  2. Copy previous version files to current path
  3. Invalidate CloudFront cache
  4. Update deployment record (status: ROLLED_BACK)
  5. Notify user

  Auto-rollback triggers:
  - HTTP 500 on deployed URL
  - 404 on index.html
  - Response time > 5 seconds
```

---

## 7. Deployment States

```
  ┌─────────┐
  │ PENDING │ ─────▶ User initiates deployment
  └────┬────┘
       │
       ▼
  ┌───────────┐
  │ DEPLOYING │ ─────▶ Files being copied
  └─────┬─────┘
        │
  ┌─────┴─────┐
  │           │
  ▼           ▼
┌─────────┐ ┌────────┐
│COMPLETED│ │ FAILED │
└────┬────┘ └────┬───┘
     │           │
     ▼           │
┌───────────┐    │
│ROLLED_BACK│◀───┘
└───────────┘
```

---

## 8. Security Considerations

### 8.1 S3 Bucket Policy
- Block all public access on bucket
- CloudFront OAI for read access only
- No direct S3 URLs exposed

### 8.2 Content Security
- HTML sanitized before deployment
- No inline scripts allowed
- External resources from whitelist only

---

## 9. Monitoring

### 9.1 Metrics
| Metric | Alert Threshold |
|--------|-----------------|
| Deployment Duration | > 2 minutes |
| Deployment Failures | > 5% |
| Rollback Rate | > 10% |
| CloudFront 5xx Rate | > 1% |

### 9.2 Logs
- S3 access logs
- CloudFront access logs
- Deployment Lambda logs

---

## 10. Related Documents

| Document | Type | Location |
|----------|------|----------|
| RB-003 | Runbook | /runbooks/RB-003_Deployment_Failure.md |
| SOP-003 | SOP | /SOPs/SOP-003_Production_Deployment_Checklist.md |
| BP-004 | Business Process | /business_process/BP-004_Custom_Domain_Setup.md |

---

## 11. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-18 | Platform Team | Initial version |
