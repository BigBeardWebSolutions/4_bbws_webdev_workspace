# Worker 3-1: S3 Bucket & CloudFront Distribution

**Worker ID**: worker-1-s3-cloudfront
**Stage**: Stage 3 - Infrastructure Code Development
**Status**: PENDING
**Agent**: DevOps Engineer Agent
**Repository**: `2_1_bbws_infrastructure`

---

## Objective

Create Terraform modules for S3 origin bucket and CloudFront CDN distribution with Origin Access Control (OAC) for secure access. S3 bucket will host React build artifacts, and CloudFront will serve content globally with caching.

---

## Prerequisites

- ✅ Stage 2 complete (Frontend built and ready in `2_1_bbws_web_public/dist/`)
- ✅ Gate 2 approved
- AWS CLI configured with appropriate credentials
- Terraform 1.6+ installed

---

## Input Documents

1. **Frontend Requirements**: `../stage-1-requirements-design/worker-1-frontend-requirements/output.md`
   - Section 9: CloudFront configuration requirements
   - Section 10: Caching strategy

2. **DNS & Security Requirements**: `../stage-1-requirements-design/worker-3-dns-security/output.md`
   - S3 security requirements
   - CloudFront security headers

---

## Tasks

### 1. Create S3 Website Module

**Directory**: `modules/s3-website/`

#### 1.1 Main Configuration (`main.tf`)

```hcl
# modules/s3-website/main.tf

resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name

  tags = merge(
    var.tags,
    {
      Name        = var.bucket_name
      Environment = var.environment
      Purpose     = "Static website hosting"
    }
  )
}

# Block all public access (required - use OAC instead)
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle rules (optional - clean up old versions)
resource "aws_s3_bucket_lifecycle_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Bucket policy for CloudFront OAC access
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAC"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = var.cloudfront_distribution_arn
          }
        }
      }
    ]
  })
}
```

#### 1.2 Variables (`variables.tf`)

```hcl
# modules/s3-website/variables.tf

variable "bucket_name" {
  description = "Name of the S3 bucket for website hosting"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, sit, prod)"
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution for OAC policy"
  type        = string
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
```

#### 1.3 Outputs (`outputs.tf`)

```hcl
# modules/s3-website/outputs.tf

output "bucket_id" {
  description = "The ID of the S3 bucket"
  value       = aws_s3_bucket.website.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.website.arn
}

output "bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket"
  value       = aws_s3_bucket.website.bucket_regional_domain_name
}

output "bucket_domain_name" {
  description = "The domain name of the S3 bucket"
  value       = aws_s3_bucket.website.bucket_domain_name
}
```

---

### 2. Create CloudFront Distribution Module

**Directory**: `modules/cloudfront/`

#### 2.1 Main Configuration (`main.tf`)

```hcl
# modules/cloudfront/main.tf

# CloudFront Origin Access Control (OAC)
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "${var.environment}-${var.domain_name}-oac"
  description                       = "OAC for S3 bucket ${var.s3_bucket_id}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.environment} - ${var.domain_name} - React website"
  default_root_object = "index.html"
  price_class         = var.price_class
  aliases             = var.aliases

  # S3 Origin
  origin {
    domain_name              = var.s3_bucket_regional_domain_name
    origin_id                = "S3-${var.s3_bucket_id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  # Default cache behavior
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.s3_bucket_id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600   # 1 hour
    max_ttl                = 86400  # 24 hours
    compress               = true

    # Lambda@Edge association (if provided)
    dynamic "lambda_function_association" {
      for_each = var.lambda_edge_function_arn != "" ? [1] : []
      content {
        event_type   = "viewer-request"
        lambda_arn   = var.lambda_edge_function_arn
        include_body = false
      }
    }
  }

  # SPA routing: Serve index.html for 404 errors
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
    error_caching_min_ttl = 0
  }

  # Restrictions (none for now, can add geo-restrictions later)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL/TLS certificate
  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-${var.domain_name}"
      Environment = var.environment
    }
  )
}
```

#### 2.2 Variables (`variables.tf`)

```hcl
# modules/cloudfront/variables.tf

variable "environment" {
  description = "Environment name (dev, sit, prod)"
  type        = string
}

variable "domain_name" {
  description = "Primary domain name for CloudFront"
  type        = string
}

variable "s3_bucket_id" {
  description = "ID of the S3 bucket (origin)"
  type        = string
}

variable "s3_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate (must be in us-east-1)"
  type        = string
}

variable "aliases" {
  description = "Alternate domain names (CNAMEs) for the distribution"
  type        = list(string)
}

variable "price_class" {
  description = "CloudFront price class (PriceClass_100, PriceClass_200, PriceClass_All)"
  type        = string
  default     = "PriceClass_100"
}

variable "lambda_edge_function_arn" {
  description = "ARN of Lambda@Edge function for Basic Auth (optional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
```

#### 2.3 Outputs (`outputs.tf`)

```hcl
# modules/cloudfront/outputs.tf

output "distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.id
}

output "distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.arn
}

output "distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "distribution_hosted_zone_id" {
  description = "Route 53 zone ID of CloudFront distribution (for alias records)"
  value       = aws_cloudfront_distribution.website.hosted_zone_id
}

output "oac_id" {
  description = "ID of the Origin Access Control"
  value       = aws_cloudfront_origin_access_control.s3_oac.id
}
```

---

### 3. Create Module README Files

#### 3.1 S3 Module README

**File**: `modules/s3-website/README.md`

```markdown
# S3 Website Module

Terraform module for creating an S3 bucket for static website hosting with CloudFront OAC access.

## Features

- S3 bucket with versioning enabled
- Server-side encryption (AES256)
- Block all public access (OAC used instead)
- Bucket policy for CloudFront OAC
- Lifecycle rules for old version cleanup

## Usage

\`\`\`hcl
module "s3_website" {
  source = "../../modules/s3-website"

  bucket_name                  = "dev-kimmyai-web-public"
  environment                  = "dev"
  cloudfront_distribution_arn  = module.cloudfront.distribution_arn

  tags = {
    Project = "Buy Page"
  }
}
\`\`\`

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| bucket_name | Name of S3 bucket | string | yes |
| environment | Environment (dev/sit/prod) | string | yes |
| cloudfront_distribution_arn | CloudFront distribution ARN | string | yes |
| tags | Additional tags | map(string) | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | S3 bucket ID |
| bucket_arn | S3 bucket ARN |
| bucket_regional_domain_name | Regional domain name |
| bucket_domain_name | Bucket domain name |
```

#### 3.2 CloudFront Module README

**File**: `modules/cloudfront/README.md`

```markdown
# CloudFront Distribution Module

Terraform module for creating a CloudFront distribution with S3 origin and OAC.

## Features

- CloudFront distribution with custom domain
- Origin Access Control (OAC) for S3
- SPA routing (404 → index.html)
- HTTPS redirect
- TLS 1.2+ only
- Lambda@Edge integration (optional)
- Gzip compression enabled

## Usage

\`\`\`hcl
module "cloudfront" {
  source = "../../modules/cloudfront"

  environment                     = "dev"
  domain_name                     = "dev.kimmyai.io"
  s3_bucket_id                    = module.s3_website.bucket_id
  s3_bucket_regional_domain_name  = module.s3_website.bucket_regional_domain_name
  acm_certificate_arn             = module.acm.certificate_arn
  aliases                         = ["dev.kimmyai.io"]
  price_class                     = "PriceClass_100"
  lambda_edge_function_arn        = module.lambda_edge.function_arn  # Optional

  tags = {
    Project = "Buy Page"
  }
}
\`\`\`

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| environment | Environment | string | yes |
| domain_name | Primary domain | string | yes |
| s3_bucket_id | S3 bucket ID | string | yes |
| s3_bucket_regional_domain_name | S3 regional domain | string | yes |
| acm_certificate_arn | ACM certificate ARN | string | yes |
| aliases | Alternate domain names | list(string) | yes |
| price_class | Price class | string | no (default: PriceClass_100) |
| lambda_edge_function_arn | Lambda@Edge ARN | string | no |
| tags | Additional tags | map(string) | no |

## Outputs

| Name | Description |
|------|-------------|
| distribution_id | CloudFront distribution ID |
| distribution_arn | CloudFront distribution ARN |
| distribution_domain_name | CloudFront domain name |
| distribution_hosted_zone_id | Route 53 zone ID |
| oac_id | Origin Access Control ID |
```

---

## Deliverables

### S3 Website Module
- [x] `modules/s3-website/main.tf` - S3 bucket resources
- [x] `modules/s3-website/variables.tf` - Module variables
- [x] `modules/s3-website/outputs.tf` - Module outputs
- [x] `modules/s3-website/README.md` - Module documentation

### CloudFront Module
- [x] `modules/cloudfront/main.tf` - CloudFront distribution
- [x] `modules/cloudfront/variables.tf` - Module variables
- [x] `modules/cloudfront/outputs.tf` - Module outputs
- [x] `modules/cloudfront/README.md` - Module documentation

---

## Success Criteria

- [ ] S3 bucket module created with all security features
- [ ] CloudFront module created with OAC support
- [ ] All public access blocked on S3 bucket
- [ ] CloudFront configured for SPA routing (404 → index.html)
- [ ] Terraform code passes `terraform validate`
- [ ] Terraform code formatted (`terraform fmt`)
- [ ] Module README files complete
- [ ] output.md created with implementation summary

---

## Testing

### Validation

```bash
# Navigate to module directory
cd modules/s3-website
terraform validate
terraform fmt -check

cd ../cloudfront
terraform validate
terraform fmt -check
```

### Integration Test (After Root Module Created)

```bash
# In environment directory (e.g., environments/dev)
terraform init
terraform plan

# Expected resources:
# - aws_s3_bucket.website
# - aws_s3_bucket_public_access_block.website
# - aws_s3_bucket_versioning.website
# - aws_s3_bucket_server_side_encryption_configuration.website
# - aws_s3_bucket_lifecycle_configuration.website
# - aws_s3_bucket_policy.website
# - aws_cloudfront_origin_access_control.s3_oac
# - aws_cloudfront_distribution.website
```

---

## Security Considerations

**S3 Bucket Security**:
- ✅ Block all public access
- ✅ Server-side encryption enabled
- ✅ Versioning enabled
- ✅ Bucket policy restricts access to CloudFront OAC only

**CloudFront Security**:
- ✅ HTTPS redirect (viewer_protocol_policy = "redirect-to-https")
- ✅ TLS 1.2+ only (minimum_protocol_version = "TLSv1.2_2021")
- ✅ OAC (modern, secure alternative to OAI)
- ✅ Gzip compression enabled

---

## Dependencies

**Required Before This Worker**:
- ACM certificate ARN (Worker 3-3) - Can be added later
- Lambda@Edge ARN (Worker 3-4) - Optional, can be added later

**Circular Dependency Handling**:
- S3 bucket policy requires CloudFront distribution ARN
- CloudFront distribution requires S3 bucket domain
- **Solution**: Create CloudFront first, then update S3 bucket policy

**Implementation**:
1. Create S3 bucket (without policy)
2. Create CloudFront distribution (references S3 bucket)
3. Update S3 bucket policy (references CloudFront ARN)

---

## Notes

- CloudFront global distribution takes 15-30 minutes to fully deploy
- Use Origin Access Control (OAC), not deprecated Origin Access Identity (OAI)
- Price classes:
  - `PriceClass_100`: North America + Europe (cheapest)
  - `PriceClass_200`: North America, Europe, Asia, Middle East, Africa
  - `PriceClass_All`: All CloudFront edge locations (most expensive)
- SPA routing via custom error responses (404/403 → /index.html)

---

**Created**: 2025-12-30
**Worker**: worker-1-s3-cloudfront
**Agent**: DevOps Engineer Agent
**Status**: PENDING
