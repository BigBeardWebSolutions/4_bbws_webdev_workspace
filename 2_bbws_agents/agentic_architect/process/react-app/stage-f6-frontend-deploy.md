# Stage F6: Frontend Deployment & Promotion

**Parent Plan**: [React App SDLC](./main-plan.md)
**Stage**: F6 of 6
**Status**: PENDING
**Last Updated**: 2026-01-01

---

## Objective

Deploy the React application to S3/CloudFront across all environments (DEV -> SIT -> PROD) with CI/CD automation.

---

## Agent & Skill Assignment

| Role | Agent | Skill |
|------|-------|-------|
| **Primary** | DevOps_Engineer_Agent | `github_oidc_cicd.skill.md` |
| **Support** | SDET_Engineer_Agent | `website_testing.skill.md` |

---

## Workers

| # | Worker | Task | Status | Output |
|---|--------|------|--------|--------|
| 1 | worker-1-terraform-infra | Create S3/CloudFront infrastructure | PENDING | `terraform/` |
| 2 | worker-2-cicd-workflows | Create GitHub Actions workflows | PENDING | `.github/workflows/` |
| 3 | worker-3-deploy-verify | Deploy and verify in DEV | PENDING | Deployment logs |

---

## Worker Instructions

### Worker 1: Terraform Infrastructure

**Objective**: Create S3 bucket and CloudFront distribution

**Infrastructure Components**:
| Resource | Purpose |
|----------|---------|
| S3 Bucket | Static file hosting |
| CloudFront Distribution | CDN with SSL |
| Route53 Record | Custom domain |
| ACM Certificate | SSL certificate |
| OAI | Origin Access Identity |

**Terraform Configuration**:
```hcl
# terraform/main.tf

# S3 bucket for static hosting
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${var.environment}"
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

# Block public access (CloudFront only)
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront OAI
resource "aws_cloudfront_origin_access_identity" "frontend" {
  comment = "OAI for ${var.project_name} frontend"
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.domain_name]
  price_class         = "PriceClass_100"

  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.frontend.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.frontend.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.frontend.id}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # Handle SPA routing
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# Route53 record
resource "aws_route53_record" "frontend" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}
```

**Environment Variables**:
```hcl
# terraform/environments/dev.tfvars
environment     = "dev"
domain_name     = "app.dev.kimmyai.io"
project_name    = "bbws"

# terraform/environments/sit.tfvars
environment     = "sit"
domain_name     = "app.sit.kimmyai.io"
project_name    = "bbws"

# terraform/environments/prod.tfvars
environment     = "prod"
domain_name     = "app.kimmyai.io"
project_name    = "bbws"
```

**Quality Criteria**:
- [ ] S3 bucket created with block public access
- [ ] CloudFront distribution working
- [ ] Custom domain configured
- [ ] SSL certificate valid

---

### Worker 2: CI/CD Workflows

**Objective**: Create GitHub Actions for deployment

**Workflow Files**:
```yaml
# .github/workflows/deploy-frontend-dev.yml
name: Deploy Frontend to DEV

on:
  push:
    branches: [main]
    paths:
      - 'src/**'
      - 'public/**'
      - 'package.json'
  workflow_dispatch:

env:
  AWS_REGION: eu-west-1
  ENVIRONMENT: dev

permissions:
  id-token: write
  contents: read

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    environment: dev

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test

      - name: Build for DEV
        run: npm run build:dev

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::536580886816:role/github-actions-oidc
          aws-region: ${{ env.AWS_REGION }}

      - name: Deploy to S3
        run: |
          aws s3 sync dist/ s3://bbws-frontend-dev \
            --delete \
            --cache-control "max-age=31536000,public" \
            --exclude "index.html"

          aws s3 cp dist/index.html s3://bbws-frontend-dev/index.html \
            --cache-control "no-cache,no-store,must-revalidate"

      - name: Invalidate CloudFront
        run: |
          aws cloudfront create-invalidation \
            --distribution-id ${{ vars.CLOUDFRONT_DISTRIBUTION_ID }} \
            --paths "/*"

      - name: Verify deployment
        run: |
          sleep 30
          curl -sSf https://app.dev.kimmyai.io > /dev/null
          echo "Deployment verified!"
```

```yaml
# .github/workflows/deploy-frontend-sit.yml
name: Deploy Frontend to SIT

on:
  workflow_dispatch:
    inputs:
      confirm:
        description: 'Type "deploy" to confirm'
        required: true

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: Validate confirmation
        if: github.event.inputs.confirm != 'deploy'
        run: |
          echo "Confirmation required. Type 'deploy' to proceed."
          exit 1

  deploy:
    needs: validate
    runs-on: ubuntu-latest
    environment: sit
    # Similar steps to dev but with sit-specific variables
```

```yaml
# .github/workflows/deploy-frontend-prod.yml
name: Deploy Frontend to PROD

on:
  workflow_dispatch:
    inputs:
      confirm:
        description: 'Type "deploy-to-production" to confirm'
        required: true
      reason:
        description: 'Reason for deployment'
        required: true

# Similar structure with production-specific safeguards
```

**Quality Criteria**:
- [ ] DEV auto-deploys on push to main
- [ ] SIT requires manual trigger + confirmation
- [ ] PROD requires manual trigger + strict confirmation
- [ ] CloudFront invalidation automated

---

### Worker 3: Deployment Verification

**Objective**: Deploy to DEV and verify functionality

**Verification Steps**:
```bash
# 1. Verify deployment
curl -I https://app.dev.kimmyai.io

# 2. Check SSL certificate
echo | openssl s_client -connect app.dev.kimmyai.io:443 2>/dev/null | openssl x509 -noout -dates

# 3. Run E2E smoke tests
npm run test:e2e

# 4. Check performance
npx lighthouse https://app.dev.kimmyai.io --output=html --output-path=./lighthouse-report.html
```

**Verification Checklist**:
- [ ] Site accessible via custom domain
- [ ] SSL certificate valid
- [ ] All pages load correctly
- [ ] API calls working
- [ ] No console errors
- [ ] Performance metrics acceptable (LCP < 2.5s)

**Quality Criteria**:
- [ ] DEV deployment successful
- [ ] All smoke tests passing
- [ ] Performance metrics met
- [ ] Ready for SIT promotion

---

## Stage Outputs

| Output | Description | Location |
|--------|-------------|----------|
| Terraform | Infrastructure code | `terraform/` |
| CI/CD workflows | GitHub Actions | `.github/workflows/` |
| Deployment | Live application | `https://app.dev.kimmyai.io` |

---

## Approval Gate 4 (Final)

**Location**: After this stage
**Approvers**: Product Owner, Operations Lead
**Criteria**:
- [ ] Frontend deployed to DEV
- [ ] All E2E tests passing
- [ ] Performance metrics met
- [ ] Full stack (Backend + Frontend) working together
- [ ] Ready for SIT promotion

---

## Success Criteria

- [ ] All 3 workers completed
- [ ] Frontend deployed to DEV
- [ ] CI/CD pipelines working
- [ ] Custom domain accessible
- [ ] Gate 4 approval obtained

---

## Dependencies

**Depends On**: Stage F5 (API Integration)
**Blocks**: None (final frontend stage)

---

## Environment URLs

| Environment | URL | Status |
|-------------|-----|--------|
| DEV | `https://app.dev.kimmyai.io` | Auto-deploy |
| SIT | `https://app.sit.kimmyai.io` | Manual |
| PROD | `https://app.kimmyai.io` | Manual + Approval |

---

## Estimated Duration

| Activity | Agentic | Manual |
|----------|---------|--------|
| Terraform infra | 30 min | 3 hours |
| CI/CD workflows | 20 min | 2 hours |
| Deploy & verify | 15 min | 1 hour |
| **Total** | **1 hour** | **6 hours** |

---

**Navigation**: [<- Stage F5](./stage-f5-api-integration.md) | [Main Plan](./main-plan.md)
