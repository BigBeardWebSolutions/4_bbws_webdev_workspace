# Terraform Reusable Modules

This folder contains reusable Terraform modules for tenant infrastructure deployment.

## Available Modules

### 1. ecs-tenant (Phase 1)
**Purpose:** Deploy ECS infrastructure for a tenant

**Resources Created:**
- EFS Access Point (isolated wp-content storage)
- ECS Task Definition (WordPress container)
- ALB Target Group (health checks)
- ALB Listener Rule (host-based routing)
- ECS Service (Fargate service with 1 task)

**Usage:**
```hcl
module "ecs_tenant" {
  source = "../../modules/ecs-tenant"

  tenant_name              = "goldencrust"
  environment              = "sit"
  alb_priority             = 140
  efs_id                   = "fs-xxxxx"
  cluster_name             = "sit-cluster"
  # ... more variables
}
```

### 2. database (Phase 2)
**Purpose:** Create tenant database and credentials

**Resources Created:**
- Secrets Manager Secret (database credentials)
- MySQL Database (via Python script)
- MySQL User with privileges
- IAM Policy for secret access

**Usage:**
```hcl
module "database" {
  source = "../../modules/database"

  tenant_name           = "goldencrust"
  environment           = "sit"
  rds_master_secret_arn = "arn:aws:secretsmanager:..."
}
```

### 3. dns-cloudfront (Phase 3)
**Purpose:** Configure DNS and CloudFront for tenant

**Resources Created:**
- Route53 A Record (points to CloudFront)
- CloudFront Distribution updates (if needed)

**Usage:**
```hcl
module "dns_cloudfront" {
  source = "../../modules/dns-cloudfront"

  tenant_name        = "goldencrust"
  environment        = "sit"
  route53_zone_id    = "Z07406882WSFMSDQTX1HR"
  cloudfront_domain  = "d1234567890.cloudfront.net"
}
```

### 4. cognito-tenant (Phase 4)
**Purpose:** Per-tenant Cognito User Pool for WordPress authentication

**Resources Created:**
- Cognito User Pool (dedicated identity store per tenant)
- Cognito User Pool Domain (hosted UI prefix)
- Cognito User Pool Client (OAuth2 app client for WordPress)
- Cognito User Groups x3 (Admin, Operator, Viewer)
- Secrets Manager Secret (client credentials for WordPress plugin)

**Outputs:**
- `user_pool_id` - Cognito User Pool ID
- `user_pool_arn` - User Pool ARN
- `user_pool_domain` - Hosted UI domain URL
- `app_client_id` - App Client ID for WordPress plugin
- `cognito_secret_arn` - Secrets Manager ARN with client credentials
- `oauth_endpoints` - Map of authorize/token/userinfo/logout/jwks URLs

**Usage:**
```hcl
module "cognito_tenant" {
  source = "../../modules/cognito-tenant"

  tenant_name = "goldencrust"
  environment = "sit"
  domain_name = "goldencrust.wpsit.kimmyai.io"
}
```

**LLD Reference:** [Cognito_Tenant_Pools_LLD.md](../../../2_bbws_docs/LLDs/Cognito_Tenant_Pools_LLD.md)

## Module Development Guidelines

### File Structure
Each module should contain:
- `main.tf` - Main resource definitions
- `variables.tf` - Input variable declarations
- `outputs.tf` - Output value definitions
- `versions.tf` - Terraform version constraints
- `README.md` - Module documentation

### Naming Conventions
- Resources: `{resource_type}.{tenant|purpose}`
- Variables: Clear, descriptive names
- Outputs: Match resource attributes

### Best Practices
1. **Parameterize everything** - No hardcoded values
2. **Use variables** - All environment-specific values in variables
3. **Document thoroughly** - Explain purpose, inputs, outputs
4. **Version pinning** - Specify Terraform and provider versions
5. **Outputs** - Export ARNs and identifiers for other modules

## Testing Modules

```bash
# Test module in isolation
cd modules/ecs-tenant
terraform init
terraform plan -var-file=test.tfvars
```

## Related Documentation
- [Pipeline Design](../../../2_bbws_agents/devops/design/TENANT_DEPLOYMENT_PIPELINE_DESIGN.md)
- [Folder Structure](../../../2_bbws_agents/devops/design/FOLDER_STRUCTURE.md)
