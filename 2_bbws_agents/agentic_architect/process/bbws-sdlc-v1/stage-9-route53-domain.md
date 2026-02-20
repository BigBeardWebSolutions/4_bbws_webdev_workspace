# Stage 9: Route53 / Custom Domain Mapping

**Parent Plan**: [BBWS SDLC Main Plan](./main-plan.md)
**Stage**: 9 of 10
**Status**: ⏳ PENDING
**Last Updated**: 2026-01-01

---

## Objective

Configure Route53 DNS records and API Gateway custom domain mapping to enable access via friendly URLs (e.g., `api.dev.kimmyai.io/v1.0/products`).

---

## Agent & Skill Assignment

| Role | Agent | Skill |
|------|-------|-------|
| **Primary** | DevOps_Engineer_Agent | `dns_environment_naming.skill.md` |
| **Support** | - | `aws_region_specification.skill.md` |

**Agent Path**: `agentic_architect/DevOps_Engineer_Agent.md`

---

## Architecture Pattern

The custom domain infrastructure follows a **provider/consumer** pattern:

```
┌─────────────────────────────────────────────────────────────────┐
│              SHARED INFRASTRUCTURE (2_1_bbws_api_infra)          │
│                                                                  │
│  ┌──────────────┐   ┌─────────────────┐   ┌──────────────────┐  │
│  │ Route53      │   │ ACM Certificate │   │ API Gateway      │  │
│  │ Hosted Zone  │──▶│ (Wildcard SSL)  │──▶│ Custom Domain    │  │
│  │ kimmyai.io   │   │ *.kimmyai.io    │   │ api.*.kimmyai.io │  │
│  └──────────────┘   └─────────────────┘   └──────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ data source reference
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              SERVICE REPOSITORY ({service}_lambda)               │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ API Gateway Base Path Mapping                             │   │
│  │                                                           │   │
│  │ api.dev.kimmyai.io/v1.0/products → Product Lambda API    │   │
│  │ api.dev.kimmyai.io/v1.0/orders   → Order Lambda API      │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Workers

| # | Worker | Task | Status | Output |
|---|--------|------|--------|--------|
| 1 | worker-1-custom-domain-reference | Reference shared custom domain | ⏳ PENDING | `terraform/custom_domain.tf` |
| 2 | worker-2-base-path-mapping | Create API Gateway base path mapping | ⏳ PENDING | `terraform/api_gateway.tf` |
| 3 | worker-3-domain-verification | Verify domain accessibility | ⏳ PENDING | Verification report |

---

## Worker Instructions

### Worker 1: Custom Domain Reference

**Objective**: Reference the shared custom domain from api-infra repository

**Inputs**:
- Shared infrastructure at `2_1_bbws_api_infra`
- Custom domain configuration

**Deliverables**:
- `terraform/custom_domain.tf`

**Implementation Pattern**:
```hcl
# custom_domain.tf

# Reference existing custom domain from shared infrastructure
data "aws_api_gateway_domain_name" "api" {
  domain_name = var.custom_domain_name
}

# Variable definition
variable "custom_domain_name" {
  description = "Custom domain for API Gateway"
  type        = string
}

# Outputs
output "custom_domain_name" {
  description = "The custom domain name"
  value       = data.aws_api_gateway_domain_name.api.domain_name
}

output "regional_domain_name" {
  description = "Regional domain name for Route53"
  value       = data.aws_api_gateway_domain_name.api.regional_domain_name
}
```

**Environment Values**:
```hcl
# dev.tfvars
custom_domain_name = "api.dev.kimmyai.io"

# sit.tfvars
custom_domain_name = "api.sit.kimmyai.io"

# prod.tfvars
custom_domain_name = "api.kimmyai.io"
```

**Quality Criteria**:
- [ ] Data source correctly references existing domain
- [ ] No duplicate domain creation
- [ ] Outputs exposed for verification

---

### Worker 2: Base Path Mapping

**Objective**: Map API Gateway to custom domain base path

**Inputs**:
- Custom domain reference from Worker 1
- API Gateway from Stage 7

**Deliverables**:
- Update `terraform/api_gateway.tf` with base path mapping

**Implementation Pattern**:
```hcl
# Base path mapping - connects service API to shared domain
resource "aws_api_gateway_base_path_mapping" "api" {
  api_id      = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.api.stage_name
  domain_name = data.aws_api_gateway_domain_name.api.domain_name
  base_path   = var.api_base_path  # "" for root, or "v1.0" for versioned

  depends_on = [
    aws_api_gateway_deployment.api,
    aws_api_gateway_stage.api,
  ]
}

# Variable
variable "api_base_path" {
  description = "Base path for API Gateway mapping"
  type        = string
  default     = ""  # Root path
}

# Output
output "api_custom_domain_url" {
  description = "Custom domain URL for the API"
  value       = "https://${var.custom_domain_name}/${var.api_base_path}"
}
```

**Quality Criteria**:
- [ ] Base path mapping created
- [ ] Depends on deployment/stage
- [ ] URL output correct

---

### Worker 3: Domain Verification

**Objective**: Verify custom domain is accessible

**Verification Steps**:
```bash
# 1. Verify DNS resolution
nslookup api.dev.kimmyai.io

# 2. Verify HTTPS certificate
curl -I https://api.dev.kimmyai.io

# 3. Test API endpoint
curl https://api.dev.kimmyai.io/v1.0/products

# 4. Run E2E tests via custom domain
pytest tests/e2e/ --env=dev -v
```

**Expected Results**:
- DNS resolves to API Gateway regional endpoint
- HTTPS returns valid certificate
- API returns expected response
- E2E tests pass

**Quality Criteria**:
- [ ] DNS resolves correctly
- [ ] SSL certificate valid
- [ ] API accessible via custom domain
- [ ] E2E tests passing

---

## Stage Outputs

| Output | Description | Location |
|--------|-------------|----------|
| Custom domain reference | Data source | `terraform/custom_domain.tf` |
| Base path mapping | API Gateway mapping | `terraform/api_gateway.tf` |
| Verification report | DNS/SSL/API tests | Logged |

---

## Approval Gate 3

**Location**: After this stage
**Approvers**: DevOps Lead, Tech Lead
**Criteria**:
- [ ] Infrastructure deployed successfully
- [ ] CI/CD pipelines working
- [ ] Custom domain accessible
- [ ] E2E tests passing via custom domain

---

## Custom Domain URLs

| Environment | URL |
|-------------|-----|
| DEV | `https://api.dev.kimmyai.io/v1.0/{resource}` |
| SIT | `https://api.sit.kimmyai.io/v1.0/{resource}` |
| PROD | `https://api.kimmyai.io/v1.0/{resource}` |

---

## Success Criteria

- [ ] All 3 workers completed
- [ ] Custom domain accessible in DEV
- [ ] API responds correctly
- [ ] E2E tests pass via custom domain
- [ ] Gate 3 approval obtained

---

## Dependencies

**Depends On**: Stage 8 (CI/CD Pipeline)
**Blocks**: Stage 10 (Deploy & Test)

**External Dependency**: Shared custom domain infrastructure at `2_1_bbws_api_infra`

---

## Estimated Duration

| Activity | Agentic | Manual |
|----------|---------|--------|
| Custom domain reference | 10 min | 20 min |
| Base path mapping | 10 min | 30 min |
| Verification | 10 min | 30 min |
| **Total** | **30 min** | **1.5 hours** |

---

## Reference Plans

| Plan | Location | Purpose |
|------|----------|---------|
| API Infrastructure | `2_1_bbws_api_infra/.claude/plans/api-custom-domain/` | Shared domain provider |
| Product Lambda Integration | `2_bbws_product_lambda/.claude/plans/custom-domain-integration/` | Example consumer |

---

**Navigation**: [← Stage 8](./stage-8-cicd-pipeline.md) | [Main Plan](./main-plan.md) | [Stage 10: Deploy →](./stage-10-deploy-test.md)
