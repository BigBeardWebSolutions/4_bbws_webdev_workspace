# Worker 1-3: DNS & Security Requirements

**Worker ID**: worker-3-dns-security
**Stage**: Stage 1 - Requirements & Design Analysis
**Status**: PENDING
**Agent**: General Research Agent / DevOps Engineer Agent

---

## Objective

Define complete DNS mapping, SSL certificate, and Basic Auth security requirements for all environments.

---

## Input Documents

**Project Plan**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_agents/agentic_architect/.claude/plans/plan_2.md`

**Reference**:
- AWS Best Practices for CloudFront + Route 53
- ACM Certificate requirements
- Lambda@Edge Basic Auth patterns

---

## Tasks

### 1. Define DNS Architecture

**For Each Environment**:

**DEV**:
- Domain: `dev.kimmyai.io`
- Full URL: `https://dev.kimmyai.io/buy`
- DNS record type: A/ALIAS
- Points to: CloudFront distribution (DEV)

**SIT**:
- Domain: `sit.kimmyai.io`
- Full URL: `https://sit.kimmyai.io/buy`
- DNS record type: A/ALIAS
- Points to: CloudFront distribution (SIT)

**PROD**:
- Domain: `kimmyai.io`
- Full URL: `https://kimmyai.io/buy`
- DNS record type: A/ALIAS
- Points to: CloudFront distribution (PROD)

### 2. Route 53 Requirements

**Hosted Zone**:
- Zone name: `kimmyai.io`
- Check if hosted zone already exists
- Document hosted zone ID (if exists)

**DNS Records**:
```
# DEV subdomain
dev.kimmyai.io  →  ALIAS  →  CloudFront (dev)

# SIT subdomain
sit.kimmyai.io  →  ALIAS  →  CloudFront (sit)

# PROD apex/www
kimmyai.io      →  ALIAS  →  CloudFront (prod)
www.kimmyai.io  →  ALIAS  →  CloudFront (prod)
```

**DNS Validation**:
- TTL settings
- Health checks (if needed)
- Propagation time estimates

### 3. ACM Certificate Requirements

**Certificate Scope**:
- Primary domain: `kimmyai.io`
- Wildcard: `*.kimmyai.io`
- Region: `us-east-1` (required for CloudFront)

**Validation Method**:
- DNS validation (preferred)
- Validation records in Route 53

**Certificate Check**:
- Document process to check if certificate already exists
- Use AWS CLI: `aws acm list-certificates --region us-east-1`
- Terraform data source approach:
```hcl
data "aws_acm_certificate" "existing" {
  domain   = "kimmyai.io"
  statuses = ["ISSUED"]
  most_recent = true
}
```

**If Certificate Exists**:
- Use existing certificate ARN
- Skip creation, just reference

**If Certificate Doesn't Exist**:
- Create new certificate
- Add DNS validation records
- Wait for validation

### 4. Basic Auth Requirements

**Lambda@Edge Function**:
- Trigger: Viewer Request
- Runtime: Node.js 18.x
- Function: Validate Basic Auth credentials

**Authentication Flow**:
```
1. User requests https://dev.kimmyai.io/buy
2. CloudFront triggers Lambda@Edge
3. Lambda checks Authorization header
4. If valid → Allow request
5. If invalid → Return 401 with WWW-Authenticate header
```

**Credentials Management**:

**Option 1: Environment Variables**:
```javascript
const CREDENTIALS = {
  dev: { username: 'dev', password: 'devpassword' },
  sit: { username: 'sit', password: 'sitpassword' },
  prod: { username: 'prod', password: 'prodpassword' }
};
```

**Option 2: AWS Secrets Manager** (recommended):
- Store credentials in Secrets Manager
- Fetch at function initialization
- Cache for performance

**Environment-Specific Enable/Disable**:
- DEV: ENABLED
- SIT: ENABLED
- PROD: ENABLED (to be disabled before go-live)

**Terraform Variable**:
```hcl
variable "enable_basic_auth" {
  type = map(bool)
  default = {
    dev  = true
    sit  = true
    prod = true  # Manual change to false before go-live
  }
}
```

### 5. CloudFront Security Configuration

**General Settings**:
- HTTPS only (redirect HTTP to HTTPS)
- TLS 1.2 minimum
- Security headers

**Custom Domain Configuration**:
- Alternate domain names (CNAMEs)
- SSL certificate ARN
- SNI only (cost optimization)

**Cache Behavior**:
- Viewer Protocol Policy: Redirect HTTP to HTTPS
- Allowed HTTP Methods: GET, HEAD, OPTIONS
- Cache key and origin requests

**Lambda@Edge Association**:
- Event type: Viewer Request
- Lambda function ARN (with version)

### 6. Security Headers

**Implement via Lambda@Edge or CloudFront Functions**:
```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline';
Referrer-Policy: strict-origin-when-cross-origin
```

### 7. Deployment Sequence

**Correct Order**:
1. Check/Create Route 53 hosted zone
2. Check for existing ACM certificate
3. If no certificate → Create ACM certificate → Validate via DNS
4. Wait for certificate validation
5. Create/Update CloudFront distribution with certificate
6. Create/Update Route 53 DNS records pointing to CloudFront
7. Test DNS propagation
8. Deploy Lambda@Edge for Basic Auth
9. Test Basic Auth
10. Verify HTTPS and custom domain

### 8. Testing Requirements

**DNS Testing**:
```bash
# Test DNS resolution
nslookup dev.kimmyai.io
dig dev.kimmyai.io

# Test HTTPS
curl -I https://dev.kimmyai.io/buy
```

**Basic Auth Testing**:
```bash
# Without credentials (should fail)
curl https://dev.kimmyai.io/buy

# With credentials (should succeed)
curl -u dev:devpassword https://dev.kimmyai.io/buy
```

**SSL Certificate Testing**:
```bash
# Check certificate
openssl s_client -connect dev.kimmyai.io:443 -servername dev.kimmyai.io
```

---

## Deliverables

Create `output.md` with the following sections:

### 1. DNS Architecture Overview
- Diagram showing DNS flow for all environments
- DNS record specifications

### 2. Route 53 Configuration
- Hosted zone requirements
- DNS record details
- TTL settings

### 3. ACM Certificate Specification
- Certificate requirements
- Validation method
- Terraform check logic
- Creation workflow (if needed)

### 4. Basic Auth Implementation
- Lambda@Edge function specification
- Credentials management strategy
- Enable/disable configuration
- Code skeleton

### 5. CloudFront Security Configuration
- HTTPS enforcement
- Custom domain setup
- Lambda@Edge association
- Security headers

### 6. Deployment Sequence
- Step-by-step deployment order
- Dependencies between resources
- Validation checkpoints

### 7. Testing Procedures
- DNS testing commands
- Basic Auth testing
- SSL certificate verification
- End-to-end testing

### 8. Runbook Procedures
- How to disable Basic Auth in PROD
- How to update credentials
- How to troubleshoot DNS issues
- How to renew certificates

---

## Success Criteria

- [ ] DNS architecture defined for all environments
- [ ] Route 53 configuration documented
- [ ] ACM certificate requirements specified
- [ ] Certificate check process defined
- [ ] Basic Auth implementation detailed
- [ ] CloudFront security configuration defined
- [ ] Deployment sequence documented
- [ ] Testing procedures provided
- [ ] Output.md created with all sections

---

## Output Location

`/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-2/stage-1-requirements-design/worker-3-dns-security/output.md`

---

## Notes

- Ensure all three environments are properly specified
- Include Terraform code snippets for ACM certificate check
- Provide practical testing commands
- Document the process to disable PROD Basic Auth
- Consider DNS propagation time in deployment plan

---

**Created**: 2025-12-30
**Status**: PENDING
