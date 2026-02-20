# Worker 3-2: Route 53 DNS Configuration

**Worker ID**: worker-2-route53
**Stage**: Stage 3 - Infrastructure Code Development
**Status**: PENDING
**Agent**: DevOps Engineer Agent
**Repository**: `2_1_bbws_infrastructure`

---

## Objective

Create Terraform module for Route 53 DNS records to point custom domain to CloudFront distribution. Configure A and AAAA records (IPv4 and IPv6) as aliases to CloudFront.

---

## Prerequisites

- ✅ Route 53 hosted zone for `kimmyai.io` exists
- ✅ Hosted zone ID known
- CloudFront distribution created (Worker 3-1)

---

## Tasks

### 1. Create Route 53 Module

**Directory**: `modules/route53/`

#### 1.1 Main Configuration (`main.tf`)

```hcl
# modules/route53/main.tf

# A record (IPv4) - Alias to CloudFront
resource "aws_route53_record" "website_a" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# AAAA record (IPv6) - Alias to CloudFront
resource "aws_route53_record" "website_aaaa" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}
```

#### 1.2 Variables (`variables.tf`)

```hcl
# modules/route53/variables.tf

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID for kimmyai.io"
  type        = string
}

variable "domain_name" {
  description = "Domain name to create (e.g., dev.kimmyai.io, kimmyai.io)"
  type        = string
}

variable "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  type        = string
}

variable "cloudfront_hosted_zone_id" {
  description = "CloudFront distribution hosted zone ID"
  type        = string
}
```

#### 1.3 Outputs (`outputs.tf`)

```hcl
# modules/route53/outputs.tf

output "a_record_name" {
  description = "FQDN of the A record"
  value       = aws_route53_record.website_a.fqdn
}

output "aaaa_record_name" {
  description = "FQDN of the AAAA record"
  value       = aws_route53_record.website_aaaa.fqdn
}

output "nameservers" {
  description = "Nameservers for the hosted zone (informational)"
  value       = "Check hosted zone ${var.hosted_zone_id} for NS records"
}
```

---

### 2. Create Module README

**File**: `modules/route53/README.md`

```markdown
# Route 53 DNS Module

Terraform module for creating Route 53 DNS records pointing to CloudFront distribution.

## Features

- A record (IPv4) alias to CloudFront
- AAAA record (IPv6) alias to CloudFront
- Uses alias records (no charge, better performance)

## Usage

\`\`\`hcl
module "route53" {
  source = "../../modules/route53"

  hosted_zone_id            = "Z1234567890ABC"
  domain_name               = "dev.kimmyai.io"
  cloudfront_domain_name    = module.cloudfront.distribution_domain_name
  cloudfront_hosted_zone_id = module.cloudfront.distribution_hosted_zone_id
}
\`\`\`

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| hosted_zone_id | Route 53 hosted zone ID | string | yes |
| domain_name | Domain name to create | string | yes |
| cloudfront_domain_name | CloudFront domain | string | yes |
| cloudfront_hosted_zone_id | CloudFront zone ID | string | yes |

## Outputs

| Name | Description |
|------|-------------|
| a_record_name | A record FQDN |
| aaaa_record_name | AAAA record FQDN |
| nameservers | Nameservers info |

## Notes

- Uses Route 53 alias records (free, better than CNAME)
- DNS propagation takes 5-60 minutes globally
- Verify with: `dig dev.kimmyai.io` or `nslookup dev.kimmyai.io`
```

---

## Deliverables

- [x] `modules/route53/main.tf` - DNS records
- [x] `modules/route53/variables.tf` - Module variables
- [x] `modules/route53/outputs.tf` - Module outputs
- [x] `modules/route53/README.md` - Documentation

---

## Success Criteria

- [ ] Route 53 module created with A and AAAA records
- [ ] Terraform validates successfully
- [ ] Module README complete
- [ ] output.md created

---

## Testing

```bash
# Validate
cd modules/route53
terraform validate
terraform fmt -check

# After deployment, verify DNS
dig dev.kimmyai.io
dig dev.kimmyai.io AAAA

# Expected: Points to CloudFront distribution
```

---

**Created**: 2025-12-30
**Worker**: worker-2-route53
**Status**: PENDING
