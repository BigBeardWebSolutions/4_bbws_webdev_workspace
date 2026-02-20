# DNS Environment Naming Convention & Management Skill

## Purpose

This skill defines the DNS naming conventions for multi-tenant WordPress environments and provides comprehensive technical guidance for DNS management using Route 53, CloudFront, and ACM.

---

## Environment Domain Naming Convention

### Primary Domain Structure

**Base Domain**: `kimmyai.io`

| Environment | Domain Pattern | Example Tenant | Primary Use |
|-------------|---------------|----------------|-------------|
| **DEV** | `{tenant}.wpdev.kimmyai.io` | `goldencrust.wpdev.kimmyai.io` | Development/Testing |
| **SIT** | `{tenant}.wpsit.kimmyai.io` | `goldencrust.wpsit.kimmyai.io` | System Integration Testing |
| **PROD** | `{tenant}.wp.kimmyai.io` | `goldencrust.wp.kimmyai.io` | Production (Internal) |
| **PROD-Custom** | `{customer-domain}` | `bbwstrustedservice.co.za` | Production (Custom Domains) |

### Naming Rules

**1. Tenant Subdomain Pattern**:
```
{tenant-name}.wp{environment}.kimmyai.io
```

**2. Tenant Name Constraints**:
- Lowercase alphanumeric only
- Hyphens allowed (not at start/end)
- 3-63 characters
- Must be DNS-compliant
- Examples: `goldencrust`, `sunset-bistro`, `nexgen-tech`

**3. Environment Prefix**:
- DEV: `wpdev`
- SIT: `wpsit`
- PROD: `wp`
- DR: `wpdr` (disaster recovery)

**4. Full Domain Examples**:
```
Development:
  - goldencrust.wpdev.kimmyai.io
  - nexgentech.wpdev.kimmyai.io
  - serenity.wpdev.kimmyai.io

SIT:
  - goldencrust.wpsit.kimmyai.io
  - nexgentech.wpsit.kimmyai.io
  - serenity.wpsit.kimmyai.io

Production:
  - goldencrust.wp.kimmyai.io (internal)
  - bbwstrustedservice.co.za (custom)
  - acmecorp.com (custom)
```

---

## DNS Architecture

### CloudFront-Based HTTPS Termination

**Architecture Flow**:
```
┌─────────────────────────────────────────────────────────────────┐
│                         DNS Resolution                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
        User Request: https://goldencrust.wpdev.kimmyai.io
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  Route 53: *.wpdev.kimmyai.io → d123xyz.cloudfront.net (CNAME) │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│         CloudFront Distribution (HTTPS Termination)             │
│  • ACM Certificate: *.wpdev.kimmyai.io (us-east-1)             │
│  • TLS 1.2+ only                                                │
│  • SNI-only SSL support                                         │
│  • Redirect HTTP → HTTPS                                        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                     HTTP Backend (Port 80)
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│       Application Load Balancer (eu-west-1 or af-south-1)      │
│  • Host-header routing: goldencrust.wpdev.kimmyai.io           │
│  • Forwards to specific target group                            │
│  • HTTP only (CloudFront handles HTTPS)                         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    ECS Fargate Task (WordPress)                 │
│  • Receives HTTP with X-Forwarded-Proto: https                 │
│  • WP_HOME: https://goldencrust.wpdev.kimmyai.io               │
│  • WP_SITEURL: https://goldencrust.wpdev.kimmyai.io            │
└─────────────────────────────────────────────────────────────────┘
```

---

## Route 53 Configuration

### Hosted Zone Setup

**Prerequisite**: `kimmyai.io` hosted zone must exist.

**Verification**:
```bash
# Check hosted zone exists
aws route53 list-hosted-zones \
  --query 'HostedZones[?Name==`kimmyai.io.`]' \
  --output table

# Get hosted zone ID
ZONE_ID=$(aws route53 list-hosted-zones \
  --query 'HostedZones[?Name==`kimmyai.io.`].Id' \
  --output text | cut -d'/' -f3)

echo "Zone ID: $ZONE_ID"
```

### Wildcard CNAME Records

**Pattern**: `*.wp{env}.kimmyai.io` → CloudFront distribution

**Terraform Implementation**:
```hcl
# File: terraform/route53.tf

data "aws_route53_zone" "main" {
  name         = "kimmyai.io"
  private_zone = false
}

resource "aws_route53_record" "cloudfront_wildcard_dev" {
  count   = var.cloudfront_enabled && var.environment == "dev" ? 1 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "*.wpdev.kimmyai.io"
  type    = "CNAME"
  ttl     = 300  # 5 minutes

  records = [aws_cloudfront_distribution.main[0].domain_name]

  depends_on = [aws_cloudfront_distribution.main]
}

resource "aws_route53_record" "cloudfront_wildcard_sit" {
  count   = var.cloudfront_enabled && var.environment == "sit" ? 1 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "*.wpsit.kimmyai.io"
  type    = "CNAME"
  ttl     = 300

  records = [aws_cloudfront_distribution.main[0].domain_name]

  depends_on = [aws_cloudfront_distribution.main]
}

resource "aws_route53_record" "cloudfront_wildcard_prod" {
  count   = var.cloudfront_enabled && var.environment == "prod" ? 1 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "*.wp.kimmyai.io"
  type    = "CNAME"
  ttl     = 300

  records = [aws_cloudfront_distribution.main[0].domain_name]

  depends_on = [aws_cloudfront_distribution.main]
}
```

**Manual Creation (if needed)**:
```bash
# Get CloudFront distribution domain
CLOUDFRONT_DOMAIN=$(aws cloudfront list-distributions \
  --region us-east-1 \
  --query 'DistributionList.Items[?Comment==`DEV WordPress Multi-Tenant Distribution`].DomainName' \
  --output text)

# Create wildcard CNAME for DEV
aws route53 change-resource-record-sets \
  --hosted-zone-id "$ZONE_ID" \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "*.wpdev.kimmyai.io",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [{"Value": "'$CLOUDFRONT_DOMAIN'"}]
      }
    }]
  }'
```

### Custom Domain Records (Production)

**For custom tenant domains** (e.g., `bbwstrustedservice.co.za`):

**Option 1: ALIAS to CloudFront** (Recommended if kimmyai.io hosted zone):
```hcl
resource "aws_route53_record" "bbwstrustedservice_apex" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "bbwstrustedservice.co.za"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main[0].domain_name
    zone_id                = aws_cloudfront_distribution.main[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "bbwstrustedservice_www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.bbwstrustedservice.co.za"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main[0].domain_name
    zone_id                = aws_cloudfront_distribution.main[0].hosted_zone_id
    evaluate_target_health = false
  }
}
```

**Option 2: CNAME to CloudFront** (for subdomain only):
```hcl
resource "aws_route53_record" "bbwstrustedservice_cname" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.bbwstrustedservice.co.za"
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.main[0].domain_name]
}
```

---

## ACM Certificate Management

### Wildcard Certificate Configuration

**CRITICAL**: ACM certificates for CloudFront **MUST** be in `us-east-1` region.

**Terraform Implementation**:
```hcl
# File: terraform/cloudfront.tf

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

resource "aws_acm_certificate" "cloudfront" {
  provider = aws.us_east_1
  count    = var.cloudfront_enabled ? 1 : 0

  domain_name       = local.cloudfront_domain  # *.wpdev.kimmyai.io
  validation_method = "DNS"

  subject_alternative_names = []  # Wildcard covers all subdomains

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.environment}-cloudfront-cert"
    Environment = var.environment
  }
}
```

**Domain Patterns by Environment**:
```hcl
locals {
  cloudfront_domain = var.environment == "prod" ? "*.wp.kimmyai.io" : "*.wp${var.environment}.kimmyai.io"
}

# Results in:
# DEV: *.wpdev.kimmyai.io
# SIT: *.wpsit.kimmyai.io
# PROD: *.wp.kimmyai.io
```

### DNS Validation Records

**Automatic Validation with Terraform**:
```hcl
resource "aws_route53_record" "cert_validation" {
  for_each = var.cloudfront_enabled ? {
    for dvo in aws_acm_certificate.cloudfront[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  allow_overwrite = true
  zone_id         = data.aws_route53_zone.main.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider                = aws.us_east_1
  count                   = var.cloudfront_enabled ? 1 : 0
  certificate_arn         = aws_acm_certificate.cloudfront[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "10m"
  }
}
```

**Manual Validation (if Terraform fails)**:
```bash
# Get validation records from certificate
CERT_ARN=$(aws acm list-certificates \
  --region us-east-1 \
  --query 'CertificateSummaryList[?DomainName==`*.wpdev.kimmyai.io`].CertificateArn' \
  --output text)

aws acm describe-certificate \
  --certificate-arn "$CERT_ARN" \
  --region us-east-1 \
  --query 'Certificate.DomainValidationOptions[0].ResourceRecord' \
  --output json

# Create validation record in Route 53
aws route53 change-resource-record-sets \
  --hosted-zone-id "$ZONE_ID" \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "_abc123.wpdev.kimmyai.io",
        "Type": "CNAME",
        "TTL": 60,
        "ResourceRecords": [{"Value": "_def456.acm-validations.aws"}]
      }
    }]
  }'
```

### Certificate Validation Status

**Check validation progress**:
```bash
aws acm describe-certificate \
  --certificate-arn "$CERT_ARN" \
  --region us-east-1 \
  --query 'Certificate.{Status:Status,DomainValidationOptions:DomainValidationOptions[].{Domain:DomainName,ValidationStatus:ValidationStatus}}' \
  --output json
```

**Expected Output**:
```json
{
  "Status": "ISSUED",
  "DomainValidationOptions": [
    {
      "Domain": "*.wpdev.kimmyai.io",
      "ValidationStatus": "SUCCESS"
    }
  ]
}
```

---

## CloudFront Distribution Configuration

### Distribution Settings for Multi-Tenant

**Key Configuration**:
```hcl
resource "aws_cloudfront_distribution" "main" {
  count = var.cloudfront_enabled ? 1 : 0

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${upper(var.environment)} WordPress Multi-Tenant Distribution"
  default_root_object = ""
  price_class         = var.cloudfront_price_class
  http_version        = "http2and3"

  # Wildcard domain alias
  aliases = [local.cloudfront_domain]  # *.wpdev.kimmyai.io

  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = "${var.environment}-alb-origin"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only"  # ALB is HTTP only
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_read_timeout      = 60
      origin_keepalive_timeout = 60
    }

    custom_header {
      name  = "X-CloudFront-Secret"
      value = random_string.cloudfront_secret.result
    }
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.environment}-alb-origin"
    viewer_protocol_policy = "redirect-to-https"  # Force HTTPS

    forwarded_values {
      query_string = true
      headers      = ["Host", "CloudFront-Forwarded-Proto", "Authorization"]

      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.cloudfront[0].arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
    cloudfront_default_certificate = false
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}
```

### Host Header Forwarding

**CRITICAL**: CloudFront must forward the `Host` header to ALB for tenant routing.

```hcl
forwarded_values {
  query_string = true
  headers      = [
    "Host",                          # Required for ALB tenant routing
    "CloudFront-Forwarded-Proto",    # For WordPress HTTPS detection
    "Authorization"                   # For basic auth
  ]

  cookies {
    forward = "all"  # WordPress sessions require cookies
  }
}
```

---

## ALB Listener Rule Configuration

### Host-Based Routing Pattern

Each tenant gets a dedicated listener rule:

```hcl
# File: terraform/{tenant}.tf

resource "aws_lb_listener_rule" "goldencrust" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 40

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.goldencrust.arn
  }

  condition {
    host_header {
      values = ["goldencrust.wpdev.kimmyai.io"]  # Exact match
    }
  }

  tags = {
    Name        = "${var.environment}-goldencrust-rule"
    Environment = var.environment
    Tenant      = "goldencrust"
  }
}
```

### Priority Management

**Rule Priority Allocation**:
- 1-9: Reserved for system/platform routes
- 10-49: Generic tenants (tenant-1, tenant-2)
- 50-99: Named business tenants
- 100+: Default/fallback rules

**Best Practices**:
- Leave gaps (e.g., 10, 20, 30) for future insertions
- Document conflicts in comments
- Lower priority number = higher precedence

**Example Priority Assignment**:
```
10  - tenant-1 (first test tenant)
20  - tenant-2 (second test tenant)
40  - goldencrust
50  - bbwstrustedservice (production)
55  - serenity (adjusted to avoid conflict)
60  - ironpeak
70  - sterlinglaw
80  - precisionauto
90  - premierprop
105 - bloompetal (adjusted to avoid conflict)
110 - sunsetbistro
120 - lenslight
130 - nexgentech
200 - Default fallback rule
```

---

## WordPress Configuration for Custom Domains

### Environment Variables

**WORDPRESS_CONFIG_EXTRA** must define WP_HOME and WP_SITEURL:

```hcl
environment = [
  {
    name  = "WORDPRESS_CONFIG_EXTRA"
    value = <<-EOT
      /* HTTPS Detection for ALB/CloudFront */
      if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
          $_SERVER['HTTPS'] = 'on';
      }
      if (isset($_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO']) && $_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO'] === 'https') {
          $_SERVER['HTTPS'] = 'on';
      }

      /* Force HTTPS URLs - CRITICAL for correct redirects */
      define('FORCE_SSL_ADMIN', true);
      define('WP_HOME', 'https://goldencrust.wpdev.kimmyai.io');
      define('WP_SITEURL', 'https://goldencrust.wpdev.kimmyai.io');
    EOT
  }
]
```

**Why This is Required**:
- WordPress stores site URLs in the database (`wp_options` table)
- Environment variables **override** database values
- Prevents redirect loops when migrating between domains
- Ensures correct asset URLs (CSS, JS, images)

---

## DNS Propagation & Validation

### DNS Propagation Timeline

| Record Type | Typical Propagation | Maximum Wait |
|-------------|---------------------|--------------|
| CNAME | 5-30 minutes | 2 hours |
| A/ALIAS | 5-15 minutes | 1 hour |
| TXT (ACM validation) | 1-5 minutes | 30 minutes |

### DNS Validation Commands

**Check DNS Resolution**:
```bash
# Check wildcard CNAME
dig *.wpdev.kimmyai.io

# Check specific tenant
dig goldencrust.wpdev.kimmyai.io

# Check with specific DNS server (Google)
dig @8.8.8.8 goldencrust.wpdev.kimmyai.io

# Check full DNS chain
dig +trace goldencrust.wpdev.kimmyai.io
```

**Expected Output**:
```
goldencrust.wpdev.kimmyai.io. 300 IN CNAME d123xyz.cloudfront.net.
d123xyz.cloudfront.net. 60 IN A 54.192.1.1
d123xyz.cloudfront.net. 60 IN A 54.192.1.2
...
```

### SSL Certificate Validation

**Test SSL Handshake**:
```bash
# Basic SSL test
openssl s_client -connect goldencrust.wpdev.kimmyai.io:443 \
  -servername goldencrust.wpdev.kimmyai.io < /dev/null

# Verify certificate details
echo | openssl s_client -connect goldencrust.wpdev.kimmyai.io:443 \
  -servername goldencrust.wpdev.kimmyai.io 2>/dev/null | \
  openssl x509 -noout -subject -issuer -dates

# Check certificate chain
echo | openssl s_client -showcerts -connect goldencrust.wpdev.kimmyai.io:443 \
  -servername goldencrust.wpdev.kimmyai.io 2>/dev/null | \
  grep -E "s:|i:"
```

**Expected Output**:
```
subject=CN = *.wpdev.kimmyai.io
issuer=C = US, O = Amazon, CN = Amazon RSA 2048 M02
notBefore=Dec 20 00:00:00 2025 GMT
notAfter=Jan 18 23:59:59 2026 GMT
Verify return code: 0 (ok)
```

### Testing Site Accessibility

**Full Site Test**:
```bash
#!/bin/bash
# test-tenant-dns.sh

TENANT="${1:-goldencrust}"
ENV="${2:-dev}"
DOMAIN="${TENANT}.wp${ENV}.kimmyai.io"

echo "=== Testing $DOMAIN ==="

# 1. DNS Resolution
echo "1. DNS Resolution:"
dig +short "$DOMAIN"

# 2. SSL Certificate
echo "2. SSL Certificate:"
echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null | \
  grep "Verify return code"

# 3. HTTP Response
echo "3. HTTP Response:"
curl -I "https://$DOMAIN" -u "bbws:PASSWORD" 2>&1 | head -1

# 4. CloudFront Headers
echo "4. CloudFront Headers:"
curl -I "https://$DOMAIN" -u "bbws:PASSWORD" 2>&1 | grep -i "x-cache\|cloudfront"

# 5. WordPress Detection
echo "5. WordPress Detection:"
curl -s "https://$DOMAIN" -u "bbws:PASSWORD" | grep -i "wordpress" | head -1

echo "=== Test Complete ==="
```

---

## Multi-Environment DNS Strategy

### Environment Segregation

**DEV (wpdev.kimmyai.io)**:
- Purpose: Development, feature testing
- SSL: Required (via CloudFront)
- Access: Internal only (basic auth)
- DNS TTL: 300s (5 minutes) - allows quick changes
- CloudFront: Enabled with caching disabled

**SIT (wpsit.kimmyai.io)**:
- Purpose: Integration testing, pre-production validation
- SSL: Required (via CloudFront)
- Access: Internal only (basic auth)
- DNS TTL: 300s (5 minutes)
- CloudFront: Enabled with caching disabled

**PROD (wp.kimmyai.io + custom domains)**:
- Purpose: Production hosting
- SSL: Required (via CloudFront)
- Access: Public (no basic auth) or custom domain
- DNS TTL: 300s for internal, 3600s for custom domains
- CloudFront: Enabled with optimized caching

### DNS Migration Between Environments

**Promoting Tenant from DEV to SIT**:
1. Tenant exists in DEV: `goldencrust.wpdev.kimmyai.io`
2. Deploy to SIT infrastructure (same code, data copy)
3. DNS automatically works: `goldencrust.wpsit.kimmyai.io`
4. No DNS changes needed (wildcard covers it)

**Promoting Tenant from SIT to PROD**:

**Option 1: Internal Production Domain**:
```
goldencrust.wpsit.kimmyai.io → goldencrust.wp.kimmyai.io
```
- Automatic via wildcard CNAME
- Update ECS environment variables (WP_HOME/WP_SITEURL)

**Option 2: Custom Customer Domain**:
```
goldencrust.wpsit.kimmyai.io → goldencrust.com
```
- Create new ACM certificate for `goldencrust.com`
- Add domain to CloudFront aliases
- Create Route 53 ALIAS/CNAME records
- Update WordPress environment variables

---

## Troubleshooting Guide

### Common DNS Issues

**Issue 1: DNS Not Resolving**

**Symptoms**:
```bash
$ dig goldencrust.wpdev.kimmyai.io
; <<>> DiG 9.10.6 <<>> goldencrust.wpdev.kimmyai.io
;; ANSWER SECTION:
```

**Causes**:
- Wildcard CNAME not created
- Hosted zone incorrect
- DNS not propagated yet

**Solution**:
```bash
# Verify wildcard exists
aws route53 list-resource-record-sets \
  --hosted-zone-id "$ZONE_ID" \
  --query 'ResourceRecordSets[?Name==`*.wpdev.kimmyai.io.`]'

# If missing, create it
# (See Route 53 Configuration section)

# Wait for propagation (5-30 minutes)
watch -n 30 'dig +short goldencrust.wpdev.kimmyai.io'
```

---

**Issue 2: SSL Certificate Invalid**

**Symptoms**:
```
curl: (60) SSL certificate problem: unable to get local issuer certificate
```

**Causes**:
- Certificate not validated
- Wrong certificate attached to CloudFront
- Certificate in wrong region (not us-east-1)

**Solution**:
```bash
# Check certificate status
aws acm describe-certificate \
  --certificate-arn "$CERT_ARN" \
  --region us-east-1 \
  --query 'Certificate.Status'

# If PENDING_VALIDATION, add DNS validation records
# If FAILED, recreate certificate

# Verify CloudFront using correct certificate
aws cloudfront get-distribution-config \
  --id "$DIST_ID" \
  --query 'DistributionConfig.ViewerCertificate.ACMCertificateArn'
```

---

**Issue 3: CloudFront Not Forwarding Host Header**

**Symptoms**:
- Wrong tenant served
- ALB returns default/fallback response
- All tenants show same content

**Cause**: CloudFront not forwarding `Host` header to ALB

**Solution**:
```bash
# Check CloudFront cache behavior
aws cloudfront get-distribution-config \
  --id "$DIST_ID" \
  --query 'DistributionConfig.DefaultCacheBehavior.ForwardedValues.Headers'

# Should include: ["Host", "CloudFront-Forwarded-Proto", "Authorization"]

# Update Terraform configuration (see CloudFront section)
# Apply changes and invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id "$DIST_ID" \
  --paths "/*"
```

---

**Issue 4: WordPress Redirect Loop**

**Symptoms**:
```
curl -L https://goldencrust.wpdev.kimmyai.io
# Redirects infinitely between HTTP and HTTPS
```

**Cause**: WordPress not detecting HTTPS from CloudFront/ALB

**Solution**:
Update ECS task definition environment variables:
```hcl
{
  name  = "WORDPRESS_CONFIG_EXTRA"
  value = <<-EOT
    /* HTTPS Detection - CRITICAL FIX */
    if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
        $_SERVER['HTTPS'] = 'on';
    }
    if (isset($_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO']) && $_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO'] === 'https') {
        $_SERVER['HTTPS'] = 'on';
    }

    define('FORCE_SSL_ADMIN', true);
    define('WP_HOME', 'https://goldencrust.wpdev.kimmyai.io');
    define('WP_SITEURL', 'https://goldencrust.wpdev.kimmyai.io');
  EOT
}
```

---

**Issue 5: ALB Returns Wrong Tenant**

**Symptoms**:
- Request to `goldencrust.wpdev.kimmyai.io` serves `nexgentech` content

**Cause**: ALB listener rule misconfiguration or priority conflict

**Solution**:
```bash
# List all listener rules by priority
aws elbv2 describe-rules \
  --listener-arn "$LISTENER_ARN" \
  --region eu-west-1 \
  --query 'Rules[].{Priority:Priority,Hosts:Conditions[?Field==`host-header`].HostHeaderConfig.Values}' \
  --output table

# Look for:
# 1. Duplicate priorities
# 2. Overlapping host patterns
# 3. Incorrect host header values

# Fix in Terraform and re-apply
```

---

## DNS Security Best Practices

### DNSSEC

**Enable DNSSEC for kimmyai.io**:
```bash
# Enable DNSSEC signing
aws route53 enable-hosted-zone-dnssec \
  --hosted-zone-id "$ZONE_ID"

# Get DNSSEC status
aws route53 get-dnssec \
  --hosted-zone-id "$ZONE_ID"
```

### CAA Records

**Restrict certificate issuance to AWS ACM only**:
```hcl
resource "aws_route53_record" "caa" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "kimmyai.io"
  type    = "CAA"
  ttl     = 300

  records = [
    "0 issue \"amazon.com\"",
    "0 issuewild \"amazon.com\"",
    "0 iodef \"mailto:security@kimmyai.io\""
  ]
}
```

---

## Related Skills

- **aws_region_specification** - Region management for multi-environment DNS
- **terraform_manage** - Infrastructure as Code for DNS automation
- **deploy** - Deployment workflows with DNS validation

---

**Last Updated**: 2025-12-21
**Maintained By**: DevOps Agent
**Version**: 1.0
