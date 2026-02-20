# Stage W3: WordPress Deployment

**Parent Plan**: [BBWS SDLC Main Plan](./main-plan.md)
**Stage**: W3 of W4 (WordPress Track)
**Status**: PENDING
**Last Updated**: 2026-01-01

---

## Objective

Deploy generated static WordPress sites to S3/CloudFront with tenant-specific domains and proper isolation.

---

## Agent & Skill Assignment

| Role | Agent | Skill |
|------|-------|-------|
| **Primary** | DevOps_Engineer_Agent | `github_oidc_cicd.skill.md` |
| **Support** | DevOps_Engineer_Agent | `s3_cloudfront.skill.md` |

---

## Workers

| # | Worker | Task | Status | Output |
|---|--------|------|--------|--------|
| 1 | worker-1-s3-setup | Create S3 bucket with tenant isolation | PENDING | S3 bucket |
| 2 | worker-2-cloudfront | Configure CloudFront distribution | PENDING | CloudFront |
| 3 | worker-3-domain-mapping | Set up tenant domain mapping | PENDING | Route53 |

---

## Worker Instructions

### Worker 1: S3 Bucket Setup

**Objective**: Create S3 bucket with tenant isolation

**Multi-Tenant S3 Structure**:
```
s3://bbws-sites-{env}/
├── tenant-001/
│   ├── site-001/
│   │   ├── index.html
│   │   └── assets/
│   └── site-002/
│       ├── index.html
│       └── assets/
├── tenant-002/
│   └── site-001/
└── ...
```

**Terraform Configuration**:
```hcl
# S3 bucket for all tenant sites
resource "aws_s3_bucket" "sites" {
  bucket = "bbws-sites-${var.environment}"
}

# Block public access
resource "aws_s3_bucket_public_access_block" "sites" {
  bucket = aws_s3_bucket.sites.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy for CloudFront OAI
resource "aws_s3_bucket_policy" "sites" {
  bucket = aws_s3_bucket.sites.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontOAI"
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.sites.iam_arn
        }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.sites.arn}/*"
      }
    ]
  })
}
```

**Quality Criteria**:
- [ ] S3 bucket created
- [ ] Public access blocked
- [ ] Tenant prefixes isolated
- [ ] CloudFront OAI policy set

---

### Worker 2: CloudFront Configuration

**Objective**: Set up CloudFront for tenant sites

**CloudFront with Wildcard Domain**:
```hcl
# CloudFront OAI
resource "aws_cloudfront_origin_access_identity" "sites" {
  comment = "OAI for BBWS tenant sites"
}

# CloudFront distribution with behaviors for each tenant
resource "aws_cloudfront_distribution" "sites" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = ["*.sites.${var.environment}.kimmyai.io"]
  price_class         = "PriceClass_100"

  origin {
    domain_name = aws_s3_bucket.sites.bucket_regional_domain_name
    origin_id   = "S3-sites"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.sites.cloudfront_access_identity_path
    }
  }

  # Lambda@Edge for tenant routing
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-sites"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = aws_lambda_function.tenant_router.qualified_arn
      include_body = false
    }

    forwarded_values {
      query_string = false
      headers      = ["Host"]
      cookies {
        forward = "none"
      }
    }
  }

  # Custom error page for SPA routing
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  viewer_certificate {
    acm_certificate_arn      = var.wildcard_cert_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}
```

**Lambda@Edge Tenant Router**:
```javascript
// lambda/tenant-router/index.js
exports.handler = async (event) => {
  const request = event.Records[0].cf.request;
  const host = request.headers.host[0].value;

  // Extract tenant from subdomain
  // Format: {tenant}.sites.{env}.kimmyai.io
  const tenantMatch = host.match(/^([^.]+)\.sites\./);

  if (tenantMatch) {
    const tenant = tenantMatch[1];
    // Route to tenant prefix in S3
    request.uri = `/${tenant}${request.uri}`;
  }

  return request;
};
```

**Quality Criteria**:
- [ ] CloudFront distribution created
- [ ] Wildcard SSL certificate configured
- [ ] Lambda@Edge router deployed
- [ ] Caching optimized

---

### Worker 3: Domain Mapping

**Objective**: Configure Route53 for tenant subdomains

**Route53 Configuration**:
```hcl
# Wildcard record for tenant sites
resource "aws_route53_record" "tenant_sites" {
  zone_id = var.route53_zone_id
  name    = "*.sites.${var.environment}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.sites.domain_name
    zone_id                = aws_cloudfront_distribution.sites.hosted_zone_id
    evaluate_target_health = false
  }
}
```

**Domain Pattern**:
| Environment | Pattern | Example |
|-------------|---------|---------|
| DEV | `{tenant}.sites.dev.kimmyai.io` | `acme.sites.dev.kimmyai.io` |
| SIT | `{tenant}.sites.sit.kimmyai.io` | `acme.sites.sit.kimmyai.io` |
| PROD | `{tenant}.sites.kimmyai.io` | `acme.sites.kimmyai.io` |

**Quality Criteria**:
- [ ] Wildcard DNS record created
- [ ] DNS resolves correctly
- [ ] SSL works for all subdomains
- [ ] Tenant isolation verified

---

## Stage Outputs

| Output | Description | Location |
|--------|-------------|----------|
| S3 bucket | Multi-tenant site storage | `bbws-sites-{env}` |
| CloudFront | CDN distribution | CloudFront ID |
| Route53 | Wildcard DNS record | Route53 |
| Lambda@Edge | Tenant router | Lambda |

---

## Success Criteria

- [ ] All 3 workers completed
- [ ] Sites accessible via tenant domains
- [ ] SSL working for all sites
- [ ] Tenant isolation verified

---

## Dependencies

**Depends On**: Stage W2 (AI Generation)
**Blocks**: Stage W4 (WordPress Testing)

**External Dependencies**:
- ACM wildcard certificate
- Route53 hosted zone

---

## Estimated Duration

| Activity | Agentic | Manual |
|----------|---------|--------|
| S3 setup | 10 min | 1 hour |
| CloudFront | 15 min | 2 hours |
| Domain mapping | 10 min | 1 hour |
| **Total** | **35 min** | **4 hours** |

---

**Navigation**: [<- Stage W2](./stage-w2-ai-generation.md) | [Main Plan](./main-plan.md) | [Stage W4 ->](./stage-w4-testing.md)
