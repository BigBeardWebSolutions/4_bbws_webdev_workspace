# Worker Instructions: Environment & Region Configuration Validation

**Worker ID**: worker-4-environment-region-validation
**Stage**: Stage 1 - Requirements & Analysis
**Project**: project-plan-4 (Marketing Lambda Implementation)

---

## Task Description

Validate environment configurations (DEV, SIT, PROD), verify AWS regions are correct (af-south-1), validate DynamoDB table references, and create an environment configuration matrix for all three environments.

---

## Inputs

- Global CLAUDE.md: Environment and region standards
- Project CLAUDE.md (LLDs/): Environment configuration requirements
- Marketing Lambda LLD: Infrastructure requirements

---

## Deliverables

- `output.md` containing:
  1. Environment Configuration Matrix
  2. Region Validation
  3. DynamoDB Table Validation
  4. AWS Account Validation
  5. Environment Variables Matrix
  6. Deployment Flow Validation
  7. Recommendations

---

## Expected Output Format

```markdown
# Environment & Region Configuration Validation Output

## 1. Environment Configuration Matrix

| Environment | AWS Account | Region | Status | Purpose |
|-------------|-------------|--------|--------|---------|
| **DEV** | 536580886816 | eu-west-1 | ✅ Valid | Development and testing |
| **SIT** | 815856636111 | eu-west-1 | ✅ Valid | System Integration Testing |
| **PROD** | 093646564004 | af-south-1 | ✅ Valid | Production (Primary: af-south-1, DR: eu-west-1) |

### Validation Results
- **Total Environments**: 3
- **Region Strategy**: ✅ DEV/SIT in eu-west-1, PROD in af-south-1
- **Account IDs**: ✅ All valid and distinct
- **Compliance**: ✅ Meets multi-environment requirement

## 2. Region Validation

### Region Strategy

| Environment | Primary Region | Failover Region | Rationale |
|-------------|---------------|-----------------|-----------|
| DEV | eu-west-1 (Ireland) | N/A | Cost optimization, lower latency to dev team |
| SIT | eu-west-1 (Ireland) | N/A | Cost optimization, consistency with DEV |
| PROD | af-south-1 (Cape Town) | eu-west-1 (Ireland) | Production in Africa, DR in Europe |

### Region Validation

| Environment | Region | Validation | Notes |
|-------------|--------|------------|-------|
| DEV | eu-west-1 | ✅ Correct | Europe (Ireland) - Cost-effective for development |
| SIT | eu-west-1 | ✅ Correct | Europe (Ireland) - Consistency with DEV |
| PROD | af-south-1 | ✅ Correct | Africa (Cape Town) - Primary production region |

### Disaster Recovery (PROD Only)

| Component | Primary | Failover | DR Strategy |
|-----------|---------|----------|-------------|
| DynamoDB | af-south-1 | eu-west-1 | Cross-region replication |
| S3 | af-south-1 | eu-west-1 | Cross-region replication |
| Lambda | af-south-1 | N/A | Serverless - multi-site active/active |

**DR Strategy Compliance**: ✅ Aligns with multi-site active/active DR strategy
**Region Strategy**: ✅ DEV/SIT use eu-west-1 for cost optimization, PROD uses af-south-1 for production workloads

## 3. DynamoDB Table Validation

### Table Naming Convention

| Environment | Table Name | Pattern | Validation |
|-------------|------------|---------|------------|
| DEV | bbws-cpp-dev | bbws-cpp-{env} | ✅ Valid |
| SIT | bbws-cpp-sit | bbws-cpp-{env} | ✅ Valid |
| PROD | bbws-cpp-prod | bbws-cpp-{env} | ✅ Valid |

### DynamoDB Configuration Requirements

| Requirement | DEV | SIT | PROD | Notes |
|-------------|-----|-----|------|-------|
| Capacity Mode | On-demand | On-demand | On-demand | ✅ Required per CLAUDE.md |
| PITR | Enabled | Enabled | Enabled | ✅ Point-in-time recovery |
| Encryption | AWS managed | AWS managed | AWS managed | ✅ At rest encryption |
| Backup Strategy | Hourly | Hourly | Hourly + cross-region | ✅ DR compliance |
| Cross-region Replication | No | No | Yes (eu-west-1) | ✅ PROD only |

## 4. AWS Account Validation

### Account Details

| Environment | Account ID | Account Alias | Validation |
|-------------|-----------|---------------|------------|
| DEV | 536580886816 | bbws-dev | ✅ Verified |
| SIT | 815856636111 | bbws-sit | ✅ Verified |
| PROD | 093646564004 | bbws-prod | ✅ Verified |

### IAM Roles Required

| Role | Environment | Purpose |
|------|-------------|---------|
| `marketing-lambda-execution-role-dev` | DEV | Lambda execution role |
| `marketing-lambda-execution-role-sit` | SIT | Lambda execution role |
| `marketing-lambda-execution-role-prod` | PROD | Lambda execution role |
| `github-actions-deploy-role-dev` | DEV | GitHub Actions OIDC role |
| `github-actions-deploy-role-sit` | SIT | GitHub Actions OIDC role |
| `github-actions-deploy-role-prod` | PROD | GitHub Actions OIDC role |

## 5. Environment Variables Matrix

### Lambda Environment Variables

| Variable | DEV | SIT | PROD | Description |
|----------|-----|-----|------|-------------|
| `DYNAMODB_TABLE_NAME` | bbws-cpp-dev | bbws-cpp-sit | bbws-cpp-prod | DynamoDB table reference |
| `AWS_REGION` | eu-west-1 | eu-west-1 | af-south-1 | AWS region |
| `LOG_LEVEL` | DEBUG | INFO | WARN | Logging level |
| `ENVIRONMENT` | dev | sit | prod | Environment identifier |
| `CACHE_TTL` | 300 | 300 | 300 | Cache TTL (5 min) |

### Terraform Variables

| Variable | DEV | SIT | PROD | Source |
|----------|-----|-----|------|--------|
| `aws_account_id` | 536580886816 | 815856636111 | 093646564004 | terraform.tfvars |
| `aws_region` | eu-west-1 | eu-west-1 | af-south-1 | terraform.tfvars |
| `environment` | dev | sit | prod | terraform.tfvars |
| `dynamodb_table_name` | bbws-cpp-dev | bbws-cpp-sit | bbws-cpp-prod | terraform.tfvars |
| `lambda_memory` | 256 | 256 | 256 | terraform.tfvars |
| `lambda_timeout` | 30 | 30 | 30 | terraform.tfvars |

**Parameterization**: ✅ All values parameterized, no hardcoding

## 6. Deployment Flow Validation

### Deployment Flow

```
Commit to main
  ↓
Validation (lint, test, scan)
  ↓
Terraform Plan → [Approval] → Deploy DEV (auto)
  ↓
Integration Tests
  ↓
[Manual Trigger + Approval] → Promote to SIT
  ↓
Integration Tests
  ↓
[Manual Trigger + Approval] → Promote to PROD
  ↓
Integration Tests + Monitoring
```

### Approval Gates

| Gate | Environment | Required Approvers | Automation |
|------|-------------|-------------------|------------|
| Gate 1 | DEV | Terraform plan approval | Manual |
| Gate 2 | SIT Promotion | Tech Lead, DevOps Lead | Manual |
| Gate 3 | PROD Promotion | Tech Lead, Product Owner, Operations Lead | Manual |

**Compliance**: ✅ Human approval required for SIT and PROD per CLAUDE.md

## 7. Compliance Checklist

### Global CLAUDE.md Requirements
- [x] Three environments configured (DEV, SIT, PROD)
- [x] Primary region is af-south-1 for all environments
- [x] Parameterized configurations (no hardcoding)
- [x] DEV auto-deploy on merge to main
- [x] Human approval for SIT and PROD
- [x] Deployment flow: DEV→SIT→PROD
- [x] DynamoDB on-demand capacity
- [x] Disaster recovery: Multi-site active/active (PROD)
- [x] Cross-region replication for PROD (af-south-1 → eu-west-1)
- [x] Hourly DynamoDB backups

### Project CLAUDE.md Requirements
- [x] Separate Terraform modules per service
- [x] Environment-specific terraform.tfvars
- [x] S3 backend with DynamoDB locking
- [x] GitHub Actions workflows for each environment
- [x] Approval gates before promotion

## 8. Recommendations

1. **Verify AWS Account Access**: Confirm access to all three AWS accounts before deployment
2. **Setup OIDC for GitHub Actions**: Configure OIDC trust relationship for secure deployments
3. **Create IAM Roles**: Ensure Lambda execution roles exist in all environments
4. **Enable PITR**: Verify Point-in-Time Recovery is enabled for all DynamoDB tables
5. **Configure Cross-Region Replication**: Set up DynamoDB and S3 replication for PROD (af-south-1 → eu-west-1)
6. **Setup CloudWatch Dashboards**: Create environment-specific monitoring dashboards
7. **Configure SNS Topics**: Set up SNS topics for alerting in each environment

## 9. Validation Summary

- **Environments**: ✅ 3/3 configured correctly
- **Regions**: ✅ All use af-south-1 (primary)
- **DynamoDB Tables**: ✅ Naming convention valid
- **AWS Accounts**: ✅ All verified and distinct
- **Parameterization**: ✅ All configs parameterized
- **Deployment Flow**: ✅ Compliant with standards
- **DR Strategy**: ✅ Multi-site active/active for PROD
- **Overall Status**: ✅ Ready for implementation
```

---

## Success Criteria

- [ ] All 3 environments validated (DEV, SIT, PROD)
- [ ] AWS account IDs verified for each environment
- [ ] Region af-south-1 confirmed for all environments
- [ ] DynamoDB table names validated
- [ ] Environment variables matrix created
- [ ] Terraform variables documented
- [ ] Deployment flow validated
- [ ] DR strategy verified for PROD
- [ ] Compliance checklist completed
- [ ] Recommendations provided
- [ ] Output.md created with all sections

---

## Execution Steps

1. Read global CLAUDE.md for environment standards
2. Read project CLAUDE.md (LLDs/) for specific requirements
3. Validate environment configuration matrix
4. Verify AWS account IDs for DEV, SIT, PROD
5. Confirm region (af-south-1) for all environments
6. Validate DynamoDB table naming convention
7. Document Lambda environment variables per environment
8. Document Terraform variables per environment
9. Validate deployment flow and approval gates
10. Verify DR strategy compliance
11. Create compliance checklist
12. Provide recommendations
13. Create output.md with all findings
14. Update work.state to COMPLETE

---

## Reference Standards

### From Global CLAUDE.md
- Three environments: DEV (536580886816), SIT (815856636111), PROD (093646564004)
- Regions: DEV/SIT use eu-west-1, PROD uses af-south-1
- Failover region: eu-west-1 (PROD DR only)
- DR strategy: Multi-site active/active
- Deployment flow: DEV→SIT→PROD
- Human approval for SIT and PROD

### From Project CLAUDE.md (LLDs/)
- DynamoDB on-demand capacity mode
- Separate Terraform modules
- Parameterized configurations
- S3 backend with DynamoDB locking
- Environment-specific terraform.tfvars

---

**Created**: 2025-12-30
