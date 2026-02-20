# Project Plan 2: Access Management (2.8) Implementation

**Project Status**: PENDING (Awaiting User Approval)
**Created**: 2026-01-23
**Total Stages**: 7
**Total Workers**: 42

---

## Project Overview

Implementation of the Access Management system for BBWS Multi-Tenant WordPress Hosting Platform. This includes 6 microservices:

| Service | LLD Reference | Lambda Functions |
|---------|---------------|------------------|
| Permission Service | 2.8.1 | 6 |
| Invitation Service | 2.8.2 | 7 |
| Team Service | 2.8.3 | 14 |
| Role Service | 2.8.4 | 8 |
| Authorizer Service | 2.8.5 | 1 |
| Audit Service | 2.8.6 | 5 |

**Total Lambda Functions**: 41

---

## Quick Start

### View Project Plan
```bash
cat README.md
```

### Check Project Status
```bash
find . -name "work.state.*" | sort
```

### Count Workers by Status
```bash
echo "PENDING: $(find . -name "work.state.PENDING" | grep worker | wc -l)"
echo "IN_PROGRESS: $(find . -name "work.state.IN_PROGRESS" | grep worker | wc -l)"
echo "COMPLETE: $(find . -name "work.state.COMPLETE" | grep worker | wc -l)"
```

---

## Project Structure

```
project-plan-2-access-management/
├── README.md                         ← This file
├── work.state.PENDING                ← Project-level state
├── WORKER_INSTRUCTIONS_TEMPLATE.md   ← Template for worker instructions
│
├── stage-1-lld-review-analysis/
│   ├── plan.md
│   ├── work.state.PENDING
│   ├── worker-1-permission-service-review/
│   ├── worker-2-invitation-service-review/
│   ├── worker-3-team-service-review/
│   ├── worker-4-role-service-review/
│   ├── worker-5-authorizer-service-review/
│   └── worker-6-audit-service-review/
│
├── stage-2-infrastructure-terraform/
│   ├── plan.md
│   ├── work.state.PENDING
│   ├── worker-1-dynamodb-tables-module/
│   ├── worker-2-lambda-iam-roles-module/
│   ├── worker-3-api-gateway-module/
│   ├── worker-4-cognito-integration-module/
│   ├── worker-5-s3-audit-storage-module/
│   └── worker-6-cloudwatch-monitoring-module/
│
├── stage-3-lambda-services-development/
│   ├── plan.md
│   ├── work.state.PENDING
│   ├── worker-1-permission-service-lambdas/
│   ├── worker-2-invitation-service-lambdas/
│   ├── worker-3-team-service-lambdas/
│   ├── worker-4-role-service-lambdas/
│   ├── worker-5-authorizer-service-lambda/
│   └── worker-6-audit-service-lambdas/
│
├── stage-4-api-gateway-integration/
│   ├── plan.md
│   ├── work.state.PENDING
│   ├── worker-1-permission-api-routes/
│   ├── worker-2-invitation-api-routes/
│   ├── worker-3-team-api-routes/
│   ├── worker-4-role-api-routes/
│   ├── worker-5-audit-api-routes/
│   └── worker-6-authorizer-integration/
│
├── stage-5-testing-validation/
│   ├── plan.md
│   ├── work.state.PENDING
│   ├── worker-1-unit-tests/
│   ├── worker-2-integration-tests/
│   ├── worker-3-api-contract-tests/
│   ├── worker-4-authorization-tests/
│   ├── worker-5-audit-compliance-tests/
│   └── worker-6-performance-tests/
│
├── stage-6-cicd-pipeline/
│   ├── plan.md
│   ├── work.state.PENDING
│   ├── worker-1-terraform-plan-workflow/
│   ├── worker-2-lambda-deploy-workflow/
│   ├── worker-3-test-automation-workflow/
│   ├── worker-4-environment-promotion-workflow/
│   ├── worker-5-rollback-workflow/
│   └── worker-6-monitoring-alerts-workflow/
│
└── stage-7-documentation-runbooks/
    ├── plan.md
    ├── work.state.PENDING
    ├── worker-1-deployment-runbook/
    ├── worker-2-troubleshooting-runbook/
    ├── worker-3-promotion-runbook/
    ├── worker-4-rollback-runbook/
    ├── worker-5-audit-compliance-runbook/
    └── worker-6-disaster-recovery-runbook/
```

---

## Stage Summary

| Stage | Name | Workers | Description |
|-------|------|---------|-------------|
| 1 | LLD Review & Analysis | 6 | Review all 6 LLDs for implementation readiness |
| 2 | Infrastructure Terraform | 6 | Create Terraform modules for all AWS resources |
| 3 | Lambda Services Development | 6 | Implement all 41 Lambda functions (TDD) |
| 4 | API Gateway Integration | 6 | Configure API routes and authorizer |
| 5 | Testing & Validation | 6 | Unit, integration, contract, and performance tests |
| 6 | CI/CD Pipeline | 6 | GitHub Actions workflows for DEV/SIT/PROD |
| 7 | Documentation & Runbooks | 6 | Operational runbooks and documentation |

---

## Execution Workflow

### 1. Approval Phase (Current)
- [ ] User reviews this README.md
- [ ] User reviews stage plans
- [ ] User provides approval ("go" / "approved")

### 2. Stage 1: LLD Review & Analysis
- [ ] Execute 6 workers in parallel
- [ ] Create stage-1 summary.md
- [ ] User approval (Gate 1)

### 3. Stage 2: Infrastructure Terraform
- [ ] Execute 6 workers in parallel
- [ ] Validate Terraform modules
- [ ] Create stage-2 summary.md
- [ ] User approval (Gate 2)

### 4. Stage 3: Lambda Services Development
- [ ] Execute 6 workers (TDD approach)
- [ ] All unit tests pass
- [ ] Create stage-3 summary.md
- [ ] User approval (Gate 3)

### 5. Stage 4: API Gateway Integration
- [ ] Execute 6 workers in parallel
- [ ] API routes configured
- [ ] Authorizer integrated
- [ ] Create stage-4 summary.md
- [ ] User approval (Gate 4)

### 6. Stage 5: Testing & Validation
- [ ] Execute 6 workers in parallel
- [ ] All test suites pass
- [ ] Create stage-5 summary.md
- [ ] User approval (Gate 5)

### 7. Stage 6: CI/CD Pipeline
- [ ] Execute 6 workers in parallel
- [ ] Workflows validated in DEV
- [ ] Create stage-6 summary.md
- [ ] User approval (Gate 6)

### 8. Stage 7: Documentation & Runbooks
- [ ] Execute 6 workers in parallel
- [ ] Create stage-7 summary.md
- [ ] User approval (Gate 7)

### 9. Project Completion
- [ ] Create project summary.md
- [ ] Deploy to DEV environment
- [ ] Update project work.state to COMPLETE
- [ ] Deliver all artifacts

---

## Key Design Decisions

### Architecture
- **Microservices**: 6 independent services with own Terraform modules
- **Single-Table Design**: DynamoDB with composite keys and GSIs
- **Lambda Authorizer**: JWT validation with permission/team resolution
- **RBAC Model**: Roles bundle permissions, additive model

### Data Isolation
- **Team Scoping**: Users only access data for their teams
- **Organisation Boundaries**: Strict org-level isolation
- **Audit Trail**: 7-year retention for compliance

### Infrastructure
- **Region**: DEV/SIT in eu-west-1, PROD in af-south-1 (failover eu-west-1)
- **DynamoDB**: On-demand capacity, PITR enabled
- **S3**: Audit archive with lifecycle policies (hot/warm/cold)

---

## Source Documents

| Document | Path |
|----------|------|
| BRS 2.8 | `/2_bbws_docs/BRS/2.8_BRS_Access_Management.md` |
| HLD 2.8 | `/2_bbws_docs/HLDs/2.8_HLD_Access_Management.md` |
| LLD 2.8.1 | `/2_bbws_docs/LLDs/2.8.1_LLD_Permission_Service.md` |
| LLD 2.8.2 | `/2_bbws_docs/LLDs/2.8.2_LLD_Invitation_Service.md` |
| LLD 2.8.3 | `/2_bbws_docs/LLDs/2.8.3_LLD_Team_Service.md` |
| LLD 2.8.4 | `/2_bbws_docs/LLDs/2.8.4_LLD_Role_Service.md` |
| LLD 2.8.5 | `/2_bbws_docs/LLDs/2.8.5_LLD_Authorizer_Service.md` |
| LLD 2.8.6 | `/2_bbws_docs/LLDs/2.8.6_LLD_Audit_Service.md` |

---

## State File Meanings

| File | Meaning |
|------|---------|
| `work.state.PENDING` | Work not started |
| `work.state.IN_PROGRESS` | Currently being worked on |
| `work.state.COMPLETE` | Work finished successfully |

---

## Environment Deployment Order

1. **DEV** (eu-west-1) - Development and initial testing
2. **SIT** (eu-west-1) - System integration testing / UAT
3. **PROD** (af-south-1) - Production with read-only modifications

**Note**: Defects must be fixed in DEV and promoted to SIT, then PROD.

---

## Naming Conventions

| Resource | Pattern | Example |
|----------|---------|---------|
| DynamoDB Table | `bbws-access-{env}-ddb-{table}` | `bbws-access-dev-ddb-permissions` |
| Lambda Function | `bbws-access-{env}-lambda-{service}-{action}` | `bbws-access-dev-lambda-permission-list` |
| IAM Role | `bbws-access-{env}-role-{service}` | `bbws-access-dev-role-permission-service` |
| S3 Bucket | `bbws-access-{env}-s3-{purpose}` | `bbws-access-dev-s3-audit-archive` |
| API Gateway | `bbws-access-{env}-apigw` | `bbws-access-dev-apigw` |

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Test Coverage | > 80% |
| Authorization Latency | < 100ms (P95) |
| API Response Time | < 500ms (P95) |
| Audit Log Completeness | 100% |
| Zero Security Vulnerabilities | OWASP Top 10 |

---

**Project Manager**: Agentic Project Manager
**Created**: 2026-01-23
**Last Updated**: 2026-01-23
