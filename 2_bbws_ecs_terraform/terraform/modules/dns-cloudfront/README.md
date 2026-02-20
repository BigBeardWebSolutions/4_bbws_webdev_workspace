# DNS-CloudFront Module

Terraform module for creating Route53 DNS records that point to CloudFront distribution for tenant domains.

## Features

- **Route53 A Record**: IPv4 alias to CloudFront distribution
- **Route53 AAAA Record**: Optional IPv6 alias to CloudFront distribution
- **Automatic CloudFront Zone ID**: Uses AWS's global CloudFront zone ID (Z2FDTNDATAQYW2)
- **Health Check Support**: Optional target health evaluation

## Resources Created

1. **Route53 A Record** - Alias record pointing to CloudFront (IPv4)
2. **Route53 AAAA Record** (Optional) - Alias record pointing to CloudFront (IPv6)

## Usage

### Basic Example

```hcl
module "goldencrust_dns" {
  source = "../../modules/dns-cloudfront"

  # Tenant Identity
  tenant_name = "goldencrust"
  environment = "sit"
  domain_name = "goldencrust.wpsit.kimmyai.io"

  # Route53 Configuration
  route53_zone_id = "Z07406882WSFMSDQTX1HR"  # wpsit.kimmyai.io zone

  # CloudFront Configuration
  cloudfront_domain_name = "d1a2b3c4d5e6f7.cloudfront.net"

  # Optional: Disable IPv6
  create_ipv6_record = false

  tags = {
    Project = "BBWS"
    ManagedBy = "Terraform"
  }
}
```

### Full Tenant Deployment (ECS + Database + DNS)

```hcl
# Phase 1: ECS Infrastructure
module "goldencrust_tenant" {
  source = "../../modules/ecs-tenant"

  tenant_name  = "goldencrust"
  environment  = "sit"
  domain_name  = "goldencrust.wpsit.kimmyai.io"
  alb_priority = 140

  # ... other required variables
}

# Phase 2: Database Creation
module "goldencrust_database" {
  source = "../../modules/database"

  tenant_name          = "goldencrust"
  environment          = "sit"
  tenant_db_secret_arn = module.goldencrust_tenant.db_secret_arn
  aws_region           = "eu-west-1"
  aws_profile          = "Tebogo-sit"

  depends_on = [module.goldencrust_tenant]
}

# Phase 3: DNS Configuration (after testing)
module "goldencrust_dns" {
  source = "../../modules/dns-cloudfront"

  tenant_name            = "goldencrust"
  environment            = "sit"
  domain_name            = "goldencrust.wpsit.kimmyai.io"
  route53_zone_id        = "Z07406882WSFMSDQTX1HR"
  cloudfront_domain_name = "d1a2b3c4d5e6f7.cloudfront.net"

  # Only create DNS after service is verified healthy
  depends_on = [
    module.goldencrust_tenant,
    module.goldencrust_database
  ]
}
```

### Without IPv6 Support

```hcl
module "premierprop_dns" {
  source = "../../modules/dns-cloudfront"

  tenant_name            = "premierprop"
  environment            = "prod"
  domain_name            = "premierprop.wp.kimmyai.io"
  route53_zone_id        = "Z1234567890ABC"
  cloudfront_domain_name = "d9x8y7z6w5v4u3.cloudfront.net"

  # IPv4 only
  create_ipv6_record = false
}
```

### With Health Evaluation

```hcl
module "sunsetbistro_dns" {
  source = "../../modules/dns-cloudfront"

  tenant_name            = "sunsetbistro"
  environment            = "sit"
  domain_name            = "sunsetbistro.wpsit.kimmyai.io"
  route53_zone_id        = "Z07406882WSFMSDQTX1HR"
  cloudfront_domain_name = "d1a2b3c4d5e6f7.cloudfront.net"

  # Enable health check evaluation
  evaluate_target_health = true
}
```

## Outputs

| Name | Description |
|------|-------------|
| a_record_name | FQDN of the A record (e.g., `goldencrust.wpsit.kimmyai.io`) |
| a_record_id | Route53 record ID |
| aaaa_record_name | FQDN of the AAAA record (null if disabled) |
| aaaa_record_id | Route53 record ID for AAAA (null if disabled) |
| tenant_url | Full HTTPS URL (e.g., `https://goldencrust.wpsit.kimmyai.io`) |
| domain_name | Configured domain name |
| cloudfront_domain | CloudFront distribution domain (passthrough) |

## Requirements

### Prerequisites

1. **Route53 Hosted Zone** - Must exist for parent domain
   - DEV: `wpdev.kimmyai.io` (Zone ID: TBD)
   - SIT: `wpsit.kimmyai.io` (Zone ID: Z07406882WSFMSDQTX1HR)
   - PROD: `wp.kimmyai.io` (Zone ID: TBD)

2. **CloudFront Distribution** - Must exist and be configured
   - Should have `*.{environment-domain}` as alternate domain name
   - Should have valid ACM certificate for HTTPS
   - Should be configured with ALB as origin

### IAM Permissions

The Terraform executor must have:
- `route53:ChangeResourceRecordSets` - Create/update DNS records
- `route53:GetHostedZone` - Read hosted zone information
- `route53:ListResourceRecordSets` - List existing records

## CloudFront Zone ID

CloudFront distributions always use the same hosted zone ID globally: **Z2FDTNDATAQYW2**

This is automatically set as the default value for `cloudfront_zone_id` and should not be changed.

## Domain Naming Convention

This module expects domains to follow the pattern:
- **DEV**: `{tenant}.wpdev.kimmyai.io`
- **SIT**: `{tenant}.wpsit.kimmyai.io`
- **PROD**: `{tenant}.wp.kimmyai.io`

The domain must:
1. Match the hosted zone (e.g., `goldencrust.wpsit.kimmyai.io` in `wpsit.kimmyai.io` zone)
2. Match the CloudFront alternate domain name configuration
3. Match the WordPress `WP_HOME` and `WP_SITEURL` settings (from ecs-tenant module)

## DNS Propagation

After DNS records are created:
- **Route53 Propagation**: Usually immediate (seconds)
- **Global DNS Propagation**: Can take up to 48 hours (typically much faster)
- **CloudFront Cache**: May need to be invalidated if domain was previously cached

Verify DNS with:
```bash
# Check Route53 directly
dig goldencrust.wpsit.kimmyai.io @ns-1234.awsdns-56.org

# Check global propagation
dig goldencrust.wpsit.kimmyai.io

# Test HTTPS access
curl -I https://goldencrust.wpsit.kimmyai.io
```

## IPv6 Support

By default, the module creates both A (IPv4) and AAAA (IPv6) records.

**Disable IPv6** if:
- CloudFront IPv6 is disabled
- You don't need IPv6 support
- You want to reduce DNS record count

```hcl
module "dns" {
  # ...
  create_ipv6_record = false
}
```

## Deployment Strategy

### Recommended: DNS Last

Deploy DNS records **after** verifying the tenant is working via ALB:

1. **Phase 1**: Deploy ECS infrastructure (ecs-tenant module)
2. **Phase 2**: Create database (database module)
3. **Phase 3a (DEV/SIT)**: Test via ALB direct access
   ```bash
   curl -H "Host: goldencrust.wpsit.kimmyai.io" http://sit-alb-123456.eu-west-1.elb.amazonaws.com/
   ```
4. **Phase 3b (Verified)**: Create DNS records (dns-cloudfront module)
5. **Phase 3c**: Test via CloudFront
   ```bash
   curl -I https://goldencrust.wpsit.kimmyai.io
   ```

This ensures you don't create public DNS records for a non-functional service.

### Alternative: DNS First (Not Recommended)

If you deploy DNS first, users may access a broken site during deployment.

## Troubleshooting

### DNS Record Not Resolving

```bash
# Check if record exists
aws route53 list-resource-record-sets \
  --hosted-zone-id Z07406882WSFMSDQTX1HR \
  --query "ResourceRecordSets[?Name=='goldencrust.wpsit.kimmyai.io.']" \
  --profile Tebogo-sit

# Check DNS propagation
dig goldencrust.wpsit.kimmyai.io
nslookup goldencrust.wpsit.kimmyai.io
```

### CloudFront 403 Forbidden

**Symptoms**: DNS resolves but CloudFront returns 403

**Causes**:
1. Domain not in CloudFront alternate domain names
2. ACM certificate doesn't cover the domain
3. CloudFront origin (ALB) is rejecting the request

**Solution**: Verify CloudFront configuration:
```bash
aws cloudfront get-distribution \
  --id E1234567890ABC \
  --profile Tebogo-sit
```

### SSL Certificate Mismatch

**Symptoms**: Browser SSL/TLS warning

**Causes**:
1. ACM certificate not attached to CloudFront
2. Certificate doesn't include wildcard or specific domain

**Solution**: Ensure ACM certificate in us-east-1 (for CloudFront) includes:
- `*.wpsit.kimmyai.io` (wildcard)
- OR specific domain: `goldencrust.wpsit.kimmyai.io`

### "Hosted Zone Not Found" Error

**Symptoms**: Terraform error about invalid zone ID

**Solution**: Verify zone ID:
```bash
aws route53 list-hosted-zones \
  --query "HostedZones[?Name=='wpsit.kimmyai.io.']" \
  --profile Tebogo-sit
```

## Deletion Behavior

When destroying this module:
1. DNS records are removed from Route53
2. DNS caches globally will expire (TTL-dependent)
3. CloudFront distribution is **not** affected (unchanged)

## Cost

Route53 DNS records cost:
- **Hosted Zone**: $0.50/month per zone (shared across tenants)
- **Standard Queries**: $0.40 per million queries (first 1 billion)
- **Alias Queries to CloudFront**: **FREE** ✅

This module uses alias records to CloudFront, so **no per-query charges** for DNS.

## Module Dependencies

This module is designed to be used in **Phase 3** of tenant deployment:

```
Phase 1: ecs-tenant
    ↓
Phase 2: database
    ↓ (verify health)
Phase 3: dns-cloudfront
```

## Inputs Reference

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| tenant_name | Tenant identifier | string | - | yes |
| environment | Environment (dev/sit/prod) | string | - | yes |
| domain_name | Full domain name | string | - | yes |
| route53_zone_id | Hosted zone ID | string | - | yes |
| cloudfront_domain_name | CloudFront domain | string | - | yes |
| cloudfront_zone_id | CloudFront zone ID | string | Z2FDTNDATAQYW2 | no |
| create_ipv6_record | Enable IPv6 (AAAA) | bool | true | no |
| evaluate_target_health | Health evaluation | bool | false | no |

## Related Documentation

- [Pipeline Design](../../../../2_bbws_agents/devops/design/TENANT_DEPLOYMENT_PIPELINE_DESIGN.md)
- [ECS Tenant Module](../ecs-tenant/README.md)
- [Database Module](../database/README.md)
- [AWS Route53 Alias Records](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-choosing-alias-non-alias.html)

## Version

- **Terraform**: >= 1.5.0
- **AWS Provider**: ~> 5.0
