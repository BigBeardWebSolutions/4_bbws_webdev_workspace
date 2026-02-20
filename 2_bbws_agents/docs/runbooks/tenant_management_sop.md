# Tenant Management Standard Operating Procedure (SOP)

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-16 | Platform Team | Initial version |

---

## 1. Purpose

This SOP defines the standard procedures for managing tenant lifecycle operations in the BBWS Multi-Tenant WordPress Hosting Platform across all environments (DEV, SIT, PROD).

---

## 2. Scope

This document covers:
- Tenant Creation (Provisioning)
- Tenant Read (Listing/Querying)
- Tenant Update (Modification)
- Tenant Delete (Deprovisioning)

---

## 3. Environment Overview

| Environment | AWS Account | Region | Cluster | Domain |
|-------------|-------------|--------|---------|--------|
| DEV | 536580886816 | eu-west-1 | dev-cluster | wpdev.kimmyai.io |
| SIT | 815856636111 | eu-west-1 | sit-cluster | wpsit.kimmyai.io |
| PROD | 093646564004 | af-south-1 | prod-cluster | wp.kimmyai.io |

### AWS Profiles

```bash
Tebogo-dev   # DEV environment
Tebogo-sit   # SIT environment
Tebogo-prod  # PROD environment
```

---

## 4. Roles and Responsibilities

| Role | Responsibilities |
|------|------------------|
| Platform Engineer | Execute tenant CRUD operations in DEV/SIT |
| DevOps Lead | Approve and execute PROD operations |
| Security Team | Review security-sensitive operations |
| Product Owner | Approve tenant provisioning requests |

---

## 5. Tenant Resources

Each tenant consists of the following AWS resources:

| Resource | Naming Convention | Purpose |
|----------|-------------------|---------|
| ECS Service | `{env}-{tenant_id}-service` | Container orchestration |
| Task Definition | `{env}-{tenant_id}` | Container configuration |
| ALB Target Group | `{env}-{tenant_id}-tg` | Load balancer routing |
| ALB Listener Rule | Host-based routing | DNS routing |
| Route53 Record | `{tenant_id}.{domain}` | DNS resolution |
| EFS Access Point | `{env}-{tenant_id}-ap` | Persistent storage |
| RDS Database | `{tenant_id}_db` | MySQL database |
| RDS User | `{tenant_id}_user` | Database credentials |
| Secrets Manager | `{env}-{tenant_id}-db-credentials` | Credential storage |
| CloudWatch Logs | `/ecs/{env}-{tenant_id}` | Application logs |

---

## 6. CRUD Operations Overview

### 6.1 CREATE - Tenant Provisioning

**Trigger:** Approved tenant provisioning request

**Environments:** DEV → SIT → PROD (promotion flow)

**Prerequisites:**
- [ ] Tenant ID generated (12-digit numeric)
- [ ] Subdomain validated (unique, valid characters)
- [ ] Contact email provided
- [ ] Organization details collected

**Approval Requirements:**
| Environment | Approval Required |
|-------------|-------------------|
| DEV | None |
| SIT | Team Lead |
| PROD | DevOps Lead + Product Owner |

### 6.2 READ - Tenant Querying

**Operations:**
- List all tenants in an environment
- Get tenant details (resources, status, health)
- View tenant logs
- Check tenant metrics

**Access:** Read-only operations require no approval

### 6.3 UPDATE - Tenant Modification

**Supported Updates:**
- Resource scaling (CPU, memory, task count)
- WordPress version upgrade
- PHP version change
- Container image update
- Configuration changes

**Approval Requirements:**
| Change Type | DEV | SIT | PROD |
|-------------|-----|-----|------|
| Scaling | None | None | Team Lead |
| Version Upgrade | None | Team Lead | DevOps Lead |
| Config Change | None | Team Lead | DevOps Lead |

### 6.4 DELETE - Tenant Deprovisioning

**Trigger:** Approved tenant deletion request

**Prerequisites:**
- [ ] Data backup completed (if required)
- [ ] Tenant owner notified
- [ ] Billing finalized

**Approval Requirements:**
| Environment | Approval Required |
|-------------|-------------------|
| DEV | Single confirmation |
| SIT | Single confirmation |
| PROD | **Type tenant name to confirm** + DevOps Lead approval |

---

## 7. Change Management

### 7.1 Environment Promotion Flow

```
DEV → SIT → PROD
```

- All changes MUST be tested in DEV first
- Defects MUST be fixed in DEV and promoted to SIT
- PROD deployments require SIT validation

### 7.2 Rollback Procedures

| Scenario | Action |
|----------|--------|
| Failed provisioning | Clean up partial resources |
| Failed update | Revert to previous task definition |
| Failed deletion | Document orphaned resources for manual cleanup |

---

## 8. Security Requirements

### 8.1 Credential Management
- Never hardcode credentials
- Use AWS Secrets Manager for all secrets
- Rotate credentials quarterly
- Use IAM roles, not access keys

### 8.2 Access Control
- PROD is **read-only** by default
- PROD modifications require explicit approval
- All operations are logged in CloudTrail
- Use least-privilege IAM policies

### 8.3 Data Protection
- Backup tenant data before deletion
- Encrypt data at rest (RDS, EFS, S3)
- Encrypt data in transit (TLS)
- No public S3 buckets

---

## 9. Monitoring and Alerting

### 9.1 Health Checks
- ECS service health status
- ALB target group health
- RDS connection status
- WordPress application health

### 9.2 Alerts
- Failed transactions
- Stuck transactions
- Error rate thresholds
- Resource utilization

---

## 10. Documentation Requirements

All tenant operations must be documented:
- Operation type and timestamp
- Operator identity
- Resources affected
- Outcome (success/failure)
- Issues encountered and resolution

---

## 11. Related Documents

- [Tenant Management Runbook](./tenant_management_runbook.md)
- [Tenant Management Playbook](./tenant_management_playbook.md)
- [Tenant Manager Agent Specification](../tenant/agent.md)
- [Disaster Recovery Procedures](../dr/)

---

## 12. Revision History

| Date | Version | Description |
|------|---------|-------------|
| 2026-01-16 | 1.0 | Initial SOP creation |
