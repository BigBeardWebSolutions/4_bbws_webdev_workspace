# SOP-003: Production Deployment Checklist

**Version:** 1.0
**Effective Date:** 2026-01-18
**Department:** Operations
**Approved By:** Engineering Manager

---

## 1. Purpose

This SOP provides the checklist for deploying generated sites to production, ensuring all quality and security requirements are met.

---

## 2. Pre-Deployment Checklist

### 2.1 Quality Requirements
- [ ] Brand score >= 8.0
- [ ] Staging deployment successful
- [ ] Preview reviewed and approved by user
- [ ] No security scan failures
- [ ] Performance meets targets

### 2.2 Authorization
- [ ] User has `tenant_admin` role OR
- [ ] User has explicit deploy permission
- [ ] Deployment not already in progress

### 2.3 Technical Readiness
- [ ] S3 bucket accessible
- [ ] CloudFront distribution healthy
- [ ] Previous version available for rollback

---

## 3. Deployment Steps

| Step | Action | Verification |
|------|--------|--------------|
| 1 | Copy files to production S3 path | S3 HEAD request succeeds |
| 2 | Update metadata file | Metadata readable |
| 3 | Invalidate CloudFront cache | Invalidation ID received |
| 4 | Health check new URL | HTTP 200 response |
| 5 | Update deployment record | Status = COMPLETED |
| 6 | Send notification | Email delivered |

---

## 4. Rollback Procedure

**Trigger:** Health check fails or user requests rollback

| Step | Action |
|------|--------|
| 1 | Retrieve previous version metadata |
| 2 | Copy previous files to current path |
| 3 | Invalidate CloudFront |
| 4 | Verify rollback successful |
| 5 | Update deployment status to ROLLED_BACK |
| 6 | Notify user |

---

## 5. Post-Deployment

- [ ] Verify site accessible at production URL
- [ ] Check CloudFront cache status
- [ ] Monitor for errors (15 minutes)
- [ ] Close deployment ticket

---

## 6. Related Documents

| Document | Link |
|----------|------|
| BP-003 | /business_process/BP-003_Site_Deployment.md |
| RB-003 | /runbooks/RB-003_Deployment_Failure.md |
