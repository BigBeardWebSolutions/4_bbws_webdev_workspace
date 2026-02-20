# BBWS ECS Cluster Training Program - Master Plan

**Version**: 1.0
**Created**: 2025-12-16
**Status**: IN PROGRESS

---

## Executive Summary

This master plan defines comprehensive training materials for the BBWS Multi-Tenant WordPress ECS Cluster platform. Training is organized by role with practical, demonstrable exercises and knowledge check quizzes.

---

## Training Modules Overview

| Module | Target Role | Submodules | Status |
|--------|-------------|------------|--------|
| [Super Admin Training](./plan_super_admin.md) | Platform Super Admin | 11 | PENDING |
| [Tenant Admin Training](./plan_tenant_admin.md) | Tenant Operations | 8 | PENDING |
| [Content Manager Training](./plan_content_manager.md) | WordPress Content | 7 | PENDING |

---

## Training Philosophy

### Turn-by-Turn (TBT) Approach
- Each training module follows plan → stage → snapshot → confirm workflow
- Practical exercises with real AWS commands
- Screenshots and validation checkpoints
- Progressive skill building

### Environment Progression
1. **DEV** (536580886816): Initial learning and practice
2. **SIT** (815856636111): Testing and validation
3. **PROD** (093646564004): Read-only observation, supervised operations

---

## Module 1: Super Admin Training

**Target Audience**: Platform Administrators, DevOps Engineers, SRE Team

### Submodules

| ID | Submodule | Duration | Prerequisites |
|----|-----------|----------|---------------|
| SA-01 | Cluster Creation and Infrastructure | 2 hours | AWS CLI, Terraform basics |
| SA-02 | Cluster Validation and Health Checks | 1 hour | SA-01 |
| SA-03 | Security Configuration and Hardening | 2 hours | SA-02 |
| SA-04 | Performance Monitoring and Tuning | 1.5 hours | SA-02 |
| SA-05 | Disaster Recovery Operations | 2 hours | SA-02 |
| SA-06 | Cost Management and Budgets | 1.5 hours | SA-02 |
| SA-07 | Operations Validation - Adding Tenants | 1 hour | SA-02 |
| SA-08 | Operations Validation - Bulk Tenant Operations | 1.5 hours | SA-07 |
| SA-09 | Stress Testing and Load Validation | 2 hours | SA-08 |
| SA-10 | Autoscaling Configuration and Validation | 1.5 hours | SA-09 |
| SA-11 | Per-Tenant Budget Actions and Cost Tracking | 1.5 hours | SA-06, SA-07 |

**Total Duration**: ~18 hours

### Key Learning Outcomes
- Create and validate multi-tenant ECS Fargate clusters
- Configure security groups, IAM roles, and encryption
- Monitor performance and optimize resources
- Execute DR failover and failback procedures
- Manage budgets and cost allocation per tenant
- Stress test infrastructure and validate autoscaling
- Track costs using tenant_id tagging

---

## Module 2: Tenant Admin Training

**Target Audience**: Tenant Operations Team, NOC Staff, Support Engineers

### Submodules

| ID | Submodule | Duration | Prerequisites |
|----|-----------|----------|---------------|
| TA-01 | Tenant CRUD Operations | 1.5 hours | Cluster basics |
| TA-02 | Tenant Suspension and Resumption | 1 hour | TA-01 |
| TA-03 | Problem Diagnosis and Resolution | 2 hours | TA-01 |
| TA-04 | Tenant Performance Monitoring | 1.5 hours | TA-01 |
| TA-05 | Tenant Security Management | 1.5 hours | TA-01 |
| TA-06 | Tenant Reset and Recovery | 1 hour | TA-01, TA-02 |
| TA-07 | Tenant Hijack Detection and Response | 2 hours | TA-05 |
| TA-08 | Multi-Environment Tenant Promotion | 1.5 hours | TA-01 |

**Total Duration**: ~12 hours

### Key Learning Outcomes
- Create, read, update, delete tenant resources
- Suspend and resume tenant operations
- Diagnose and resolve tenant-specific issues
- Monitor tenant performance metrics
- Implement tenant security controls
- Detect and respond to tenant hijack attempts
- Promote tenants across environments (DEV → SIT → PROD)

---

## Module 3: Content Manager Training

**Target Audience**: WordPress Administrators, Content Teams, Site Managers

### Submodules

| ID | Submodule | Duration | Prerequisites |
|----|-----------|----------|---------------|
| CM-01 | WordPress Site Management Basics | 1.5 hours | WordPress basics |
| CM-02 | Data Import and Export Operations | 1.5 hours | CM-01 |
| CM-03 | Plugin Installation and Configuration | 2 hours | CM-01 |
| CM-04 | Theme Management and Customization | 1.5 hours | CM-01 |
| CM-05 | Database Backup and Recovery | 1.5 hours | CM-01 |
| CM-06 | Content Troubleshooting | 2 hours | CM-01 |
| CM-07 | Performance Optimization for Content | 1.5 hours | CM-01, CM-03 |

**Total Duration**: ~11.5 hours

### Key Learning Outcomes
- Manage WordPress sites across multi-tenant cluster
- Import/export site content and databases
- Install and configure standard BBWS plugins
- Customize themes for tenant sites
- Perform database backups and restores
- Troubleshoot common WordPress issues
- Optimize site performance

---

## Knowledge Check Quizzes

Each training module includes practical, demonstrable quizzes:

| Quiz | Module | Questions | Passing Score |
|------|--------|-----------|---------------|
| [Super Admin Quiz](../super_admin/quiz_super_admin.md) | SA-01 to SA-11 | 25 | 80% |
| [Tenant Admin Quiz](../tenant_admin/quiz_tenant_admin.md) | TA-01 to TA-08 | 20 | 80% |
| [Content Manager Quiz](../content_manager/quiz_content_manager.md) | CM-01 to CM-07 | 15 | 80% |

### Quiz Format
- Multiple choice and practical command exercises
- Real AWS CLI commands for validation
- Screenshot requirements for proof of completion
- Hands-on lab exercises with expected outputs

---

## Training Environment Setup

### Prerequisites

```bash
# AWS CLI Configuration
aws configure --profile Tebogo-dev
aws configure --profile Tebogo-sit
aws configure --profile Tebogo-prod

# Verify Access
AWS_PROFILE=Tebogo-dev aws sts get-caller-identity
AWS_PROFILE=Tebogo-sit aws sts get-caller-identity
AWS_PROFILE=Tebogo-prod aws sts get-caller-identity
```

### Required Tools
- AWS CLI v2.0+
- Terraform v1.0+
- Python 3.8+ with boto3
- MySQL client
- jq for JSON processing

### Account Access Requirements

| Environment | Account ID | Access Level |
|-------------|------------|--------------|
| DEV | 536580886816 | Full access for training |
| SIT | 815856636111 | Full access for validation |
| PROD | 093646564004 | Read-only for observation |

---

## Progress Tracking

### Completion Criteria

| Milestone | Requirements |
|-----------|--------------|
| Super Admin Certified | Complete SA-01 to SA-11 + Pass Quiz (80%+) |
| Tenant Admin Certified | Complete TA-01 to TA-08 + Pass Quiz (80%+) |
| Content Manager Certified | Complete CM-01 to CM-07 + Pass Quiz (80%+) |
| Platform Expert | All three certifications |

### Training Log Template

```markdown
## Training Progress - [Name]

| Date | Module | Status | Notes |
|------|--------|--------|-------|
| YYYY-MM-DD | SA-01 | COMPLETE | Screenshots attached |
| YYYY-MM-DD | SA-02 | IN PROGRESS | |
```

---

## Subplans Reference

- [plan_super_admin.md](./plan_super_admin.md) - Detailed Super Admin training plan
- [plan_tenant_admin.md](./plan_tenant_admin.md) - Detailed Tenant Admin training plan
- [plan_content_manager.md](./plan_content_manager.md) - Detailed Content Manager training plan

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-16 | Initial master plan |
