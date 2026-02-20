# Worker 3-3: ACM Certificate Provisioning

**Worker ID**: worker-3-acm
**Stage**: Stage 3 - Infrastructure Code Development
**Status**: PENDING
**Agent**: DevOps Engineer Agent
**Repository**: `2_1_bbws_infrastructure`

---

## Objective

Create Terraform module for AWS Certificate Manager (ACM) SSL/TLS certificate with DNS validation. Certificate must be in **us-east-1** region (required for CloudFront).

---

## Prerequisites

- ✅ Route 53 hosted zone exists for `kimmyai.io`
- ✅ Permissions to create ACM certificates in us-east-1

---

## IMPORTANT: Region Requirement

**ACM certificates for CloudFront MUST be in us-east-1 region**, regardless of where other resources are deployed.

---

## Tasks

### 1. Create ACM Module

**Directory**: `modules/acm/`

#### 1.1 Main Configuration (`main.tf`)

```hcl
# modules/acm/main.tf

# ACM Certificate Request
resource "aws_acm_certificate" "cert" {
  provider = aws.us_east_1  # Must be us-east-1 for CloudFront

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name        = var.domain_name
      Environment = var.environment
    }
  )
}

# DNS Validation Records (created in Route 53)
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.hosted_zone_id
}

# Certificate Validation (waits for DNS propagation)
resource "aws_acm_certificate_validation" "cert" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "10m"  # Wait up to 10 minutes
  }
}
```

#### 1.2 Variables (`variables.tf`)

```hcl
# modules/acm/variables.tf

variable "domain_name" {
  description = "Primary domain name for the certificate"
  type        = string
}

variable "subject_alternative_names" {
  description = "Subject Alternative Names (SANs) for the certificate"
  type        = list(string)
  default     = []
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID for DNS validation"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, sit, prod)"
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
# modules/acm/outputs.tf

output "certificate_arn" {
  description = "ARN of the validated ACM certificate"
  value       = aws_acm_certificate_validation.cert.certificate_arn
}

output "certificate_domain_name" {
  description = "Domain name of the certificate"
  value       = aws_acm_certificate.cert.domain_name
}

output "certificate_status" {
  description = "Validation status of the certificate"
  value       = aws_acm_certificate.cert.status
}

output "domain_validation_options" {
  description = "Domain validation options (for debugging)"
  value       = aws_acm_certificate.cert.domain_validation_options
  sensitive   = true
}
```

#### 1.4 Provider Configuration Note

**Important**: Root module must configure `aws.us_east_1` provider alias.

Example (in root module):

```hcl
# Provider for us-east-1 (required for ACM + Lambda@Edge)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  # Use same credentials/profile as primary provider
  profile = var.aws_profile
}
```

---

### 2. Create Module README

**File**: `modules/acm/README.md`

```markdown
# ACM Certificate Module

Terraform module for creating ACM SSL/TLS certificates with DNS validation.

## Features

- ACM certificate in us-east-1 (required for CloudFront)
- DNS validation via Route 53
- Automatic validation record creation
- Waits for certificate validation

## Usage

\`\`\`hcl
module "acm" {
  source = "../../modules/acm"

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  domain_name               = "dev.kimmyai.io"
  subject_alternative_names = ["*.dev.kimmyai.io"]  # Optional wildcard
  hosted_zone_id            = "Z1234567890ABC"
  environment               = "dev"

  tags = {
    Project = "Buy Page"
  }
}
\`\`\`

## Certificate Validation

**DNS validation** is automatic via Route 53:
1. Terraform requests certificate
2. ACM provides DNS validation records
3. Terraform creates records in Route 53
4. ACM validates ownership
5. Certificate becomes ISSUED status

**Validation time**: Usually 2-10 minutes.

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| domain_name | Primary domain | string | yes |
| subject_alternative_names | SANs (wildcards) | list(string) | no |
| hosted_zone_id | Route 53 zone ID | string | yes |
| environment | Environment | string | yes |
| tags | Additional tags | map(string) | no |

## Outputs

| Name | Description |
|------|-------------|
| certificate_arn | ARN of validated certificate |
| certificate_domain_name | Domain name |
| certificate_status | Validation status |

## Important Notes

- **Region**: Must use us-east-1 for CloudFront
- **Validation**: DNS validation is automatic via Route 53
- **Lifecycle**: create_before_destroy ensures no downtime on renewal
- **Timeout**: 10 minutes for validation (configurable)

## Example Configurations

### DEV (Single domain)
\`\`\`hcl
domain_name               = "dev.kimmyai.io"
subject_alternative_names = []
\`\`\`

### PROD (Root + wildcard)
\`\`\`hcl
domain_name               = "kimmyai.io"
subject_alternative_names = ["*.kimmyai.io", "www.kimmyai.io"]
\`\`\`
```

---

## Deliverables

- [x] `modules/acm/main.tf` - ACM certificate with DNS validation
- [x] `modules/acm/variables.tf` - Module variables
- [x] `modules/acm/outputs.tf` - Module outputs
- [x] `modules/acm/README.md` - Documentation

---

## Success Criteria

- [ ] ACM module created with DNS validation
- [ ] Provider alias documented for us-east-1
- [ ] Terraform validates successfully
- [ ] Module README complete
- [ ] output.md created

---

## Testing

```bash
# Validate
cd modules/acm
terraform validate
terraform fmt -check

# After deployment, verify certificate
aws acm describe-certificate \
  --certificate-arn <certificate-arn> \
  --region us-east-1 \
  --profile Tebogo-dev

# Expected status: ISSUED
```

---

## Common Issues

**Issue 1**: Certificate stuck in "Pending Validation"
- **Cause**: DNS records not created or propagated
- **Fix**: Check Route 53 for CNAME validation records

**Issue 2**: "Certificate must be in us-east-1"
- **Cause**: Certificate created in wrong region
- **Fix**: Ensure provider alias `aws.us_east_1` used

**Issue 3**: Timeout waiting for validation
- **Cause**: DNS propagation slow
- **Fix**: Increase timeout in `aws_acm_certificate_validation` resource

---

**Created**: 2025-12-30
**Worker**: worker-3-acm
**Status**: PENDING
