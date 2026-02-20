# BBWS Promotion Plans - Wave 1 & Wave 2

**Created**: 2026-01-07
**Status**: Ready for Execution

---

## Overview

This directory contains comprehensive promotion plans for deploying BBWS microservices and infrastructure from DEV → SIT → PROD, following the BBWS SDLC process (Stage 9: Route53/Domain Mapping and Stage 10: Deploy & Test).

---

## Promotion Plans

### Wave 1: Core API Services (Jan 10 SIT, Feb 21 PROD)

| # | Plan | Project | Type | Test Coverage | Status |
|---|------|---------|------|---------------|--------|
| 01 | [campaigns_lambda](./01_campaigns_lambda_promotion.md) | 2_bbws_campaigns_lambda | API Lambda | 99.43% | ✅ Template |
| 02 | [order_lambda](./02_order_lambda_promotion.md) | 2_bbws_order_lambda | API Lambda (11 handlers) | 85% | ✅ Complete |
| 03 | [product_lambda](./03_product_lambda_promotion.md) | 2_bbws_product_lambda | API Lambda | 88% | ✅ Complete |

**Dependencies**: Requires Wave 2 infrastructure (DynamoDB, S3) in SIT before promotion.

---

### Wave 2: Infrastructure Foundation (Jan 13 SIT, Feb 24 PROD)

| # | Plan | Project | Type | Components | Status |
|---|------|---------|------|------------|--------|
| 04 | [dynamodb_schemas](./04_dynamodb_schemas_promotion.md) | 2_1_bbws_dynamodb_schemas | Infrastructure | 5 tables, 8 GSIs | ✅ Complete |
| 05 | [s3_schemas](./05_s3_schemas_promotion.md) | 2_1_bbws_s3_schemas | Infrastructure | 6 buckets, 12 templates | ✅ Complete |
| 06 | [backend_public](./06_backend_public_promotion.md) | 2_1_bbws_backend_public | Infrastructure | S3 + CloudFront + Lambda@Edge | ✅ Complete |
| 07 | [ecs_terraform](./07_ecs_terraform_promotion.md) | 2_bbws_ecs_terraform | Infrastructure | ECS + Aurora + Redis + EFS | ✅ Complete |

**Critical**: Wave 2 MUST be deployed to SIT before Wave 1 can be promoted.

---

## Timeline Summary

```
WAVE 2 (Infrastructure) - Jan 13, 2026
├─ 9:00 AM  - DynamoDB schemas (BLOCKING)
├─ 10:00 AM - S3 schemas (BLOCKING)
├─ 11:00 AM - Backend public (depends on DynamoDB + S3)
└─ 1:00 PM  - ECS terraform (depends on DynamoDB + S3)

WAVE 1 (API Services) - Jan 10, 2026
├─ 10:00 AM - campaigns_lambda
├─ 10:30 AM - product_lambda
└─ 11:00 AM - order_lambda

NOTE: Wave 1 deployment MUST wait for Wave 2 to complete in SIT
ACTUAL TIMELINE: Deploy Wave 2 on Jan 13, then Wave 1 on Jan 14+
```

---

## Production Timeline

```
WAVE 2 (Infrastructure) - Feb 24, 2026
├─ 8:00 AM  - DynamoDB schemas (primary + DR)
├─ 9:00 AM  - S3 schemas (primary + DR)
├─ 10:00 AM - Backend public (CloudFront + Lambda@Edge)
└─ 2:00 PM  - ECS terraform (ECS + Aurora + Redis + EFS)

WAVE 1 (API Services) - Feb 21, 2026
├─ 9:00 AM  - campaigns_lambda
├─ 9:30 AM  - product_lambda
└─ 10:00 AM - order_lambda
```

---

## Critical Dependencies

### Wave 1 Depends On Wave 2
- **campaigns_lambda** → dynamodb_schemas (campaigns table), s3_schemas (templates)
- **order_lambda** → dynamodb_schemas (orders table), s3_schemas (orders bucket), product_lambda
- **product_lambda** → dynamodb_schemas (products table), s3_schemas (product-images)

### Wave 2 Internal Dependencies
- **backend_public** → dynamodb_schemas (tenant metadata), s3_schemas (frontend bucket)
- **ecs_terraform** → dynamodb_schemas (tenant metadata), s3_schemas (tenant-assets)

---

## Key Features Across All Plans

### Common Structure
Each plan includes:
- Project overview with current metrics
- Environment table (DEV/SIT/PROD)
- 3-phase timeline (SIT Promotion, SIT Validation, PROD Promotion)
- Pre-deployment checklists
- Detailed deployment steps with bash commands
- Post-deployment validation (smoke tests, monitoring, integration tests)
- Rollback procedures
- Success criteria
- Monitoring & alerts setup
- Contacts & escalation
- Documentation artifacts
- Change log table

### Project-Specific Characteristics

#### API Lambda Plans (01-03)
- Lambda handler validation
- API Gateway integration
- Event-driven workflows (order_lambda)
- Blue/green deployment with traffic shifting
- Lambda alias management

#### Infrastructure Plans (04-07)
- Multi-region DR setup (PROD only)
- Point-in-time recovery (PITR) validation
- Backup/restore procedures
- Cross-region replication testing
- Multi-tenant isolation (ecs_terraform)
- State management (58 Terraform files for ECS)

---

## CRITICAL WARNINGS

### DynamoDB Schemas (Plan 04)
- ⚠️ Table deletion is irreversible
- ⚠️ On-demand capacity mode MUST be used
- ⚠️ PITR MUST be enabled before any data
- ⚠️ Cross-region replication for PROD DR

### S3 Schemas (Plan 05)
- ⚠️ ALL buckets MUST block public access
- ⚠️ Versioning MUST be enabled
- ⚠️ Cross-region replication for PROD DR
- ⚠️ Bucket deletion requires emptying first

### Backend Public (Plan 06)
- ⚠️ Lambda@Edge MUST be in us-east-1
- ⚠️ CloudFront deployment takes 15-30 minutes
- ⚠️ S3 bucket MUST block public access (CloudFront OAI only)
- ⚠️ Cache invalidation after deployments

### ECS Terraform (Plan 07)
- ⚠️ 58 Terraform files - careful state management
- ⚠️ Multi-tenant isolation MUST be validated
- ⚠️ Aurora Global Database for PROD DR
- ⚠️ Phased deployment (network → database → storage → ECS → monitoring)

---

## Approval Matrix

| Plan | Requires Approval From |
|------|------------------------|
| 01-03 (Lambda) | Tech Lead, DevOps Lead |
| 04 (DynamoDB) | Tech Lead, DevOps Lead, DBA, FinOps Lead |
| 05 (S3) | Tech Lead, DevOps Lead, Security Lead, FinOps Lead |
| 06 (Backend) | Tech Lead, DevOps Lead, Security Lead, Frontend Lead |
| 07 (ECS) | Tech Lead, DevOps Lead, DBA, Network Engineer, Security Lead, Product Owner |

---

## Success Metrics

### SIT Promotion Success (All Plans)
- ✅ Zero deployment errors
- ✅ All smoke tests passing
- ✅ Integration tests 100% pass rate
- ✅ No critical/high severity bugs
- ✅ Monitoring dashboards operational
- ✅ Performance baseline established

### PROD Promotion Success (All Plans)
- ✅ Zero-downtime deployment
- ✅ All health checks green
- ✅ Error rate < 0.1%
- ✅ Response times within SLA
- ✅ 72-hour soak period clean
- ✅ No customer-impacting issues
- ✅ Product Owner sign-off

---

## Rollback Considerations

### Lambda Services (01-03)
- ✅ Fast rollback (alias switch)
- ✅ Blue/green deployment minimizes risk
- ⏱️ Rollback time: <5 minutes

### Infrastructure (04-07)
- ⚠️ Complex rollback (potential data loss)
- ⚠️ DynamoDB: Restore from PITR or backup
- ⚠️ S3: Restore from versioned objects
- ⚠️ ECS: Rollback task definitions, restore databases
- ⏱️ Rollback time: 15-60 minutes

---

## Cost Estimates

### Wave 1 (API Lambda)
- **campaigns_lambda**: $50-100/month (SIT), $200-500/month (PROD)
- **order_lambda**: $100-200/month (SIT), $500-1000/month (PROD)
- **product_lambda**: $75-150/month (SIT), $300-700/month (PROD)

### Wave 2 (Infrastructure)
- **dynamodb_schemas**: $100-300/month (SIT), $500-2000/month (PROD)
- **s3_schemas**: $50-150/month (SIT), $200-800/month (PROD)
- **backend_public**: $100-300/month (SIT), $500-2000/month (PROD)
- **ecs_terraform**: $500-1500/month (SIT), $3000-10000/month (PROD)

**Total Estimated Monthly Cost**:
- SIT: $975-2700/month
- PROD: $5200-17000/month

---

## Next Actions

1. **Review all 6 plans** with respective teams
2. **Get approvals** from required stakeholders
3. **Schedule Wave 2 deployment** for Jan 13, 2026
4. **Schedule Wave 1 deployment** for Jan 14+, 2026 (after Wave 2 validates)
5. **Prepare rollback teams** for both waves
6. **Set up monitoring dashboards** before deployments
7. **Test rollback procedures** in DEV before SIT promotion

---

## Contact & Support

For questions or issues with these promotion plans:
- **DevOps Lead**: TBD
- **Tech Lead**: TBD
- **Product Owner**: TBD

---

**Document Status**: ✅ Complete
**Last Updated**: 2026-01-07
**Version**: 1.0.0
