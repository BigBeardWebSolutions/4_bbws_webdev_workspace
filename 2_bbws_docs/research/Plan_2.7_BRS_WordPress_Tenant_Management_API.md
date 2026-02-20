# Comprehensive Plan for BRS 2.7: WordPress Tenant Management API

**Version**: 1.0
**Created**: 2026-01-05
**Target Document**: `BRS/2.7_BRS_WordPress_Tenant_Management_API.md`
**Status**: Plan Ready for Review

---

## 1. Executive Summary

### 1.1 What is the WordPress Tenant Management API?

The **WordPress Tenant Management API** is the **infrastructure provisioning layer** of the BBWS multi-tenant WordPress hosting platform. It is responsible for orchestrating the creation, management, and destruction of all AWS infrastructure resources required to run a dedicated WordPress instance for each tenant.

This API serves as the critical bridge between:
- **Logical tenant entities** (organizations, users, metadata stored in DynamoDB)
- **Physical AWS infrastructure** (ECS services, EFS access points, RDS databases, ALB rules, Cognito User Pools)

### 1.2 How It Differs From Other APIs

| API | Responsibility | Infrastructure Involvement |
|-----|----------------|---------------------------|
| **Tenant API (BRS 2.5)** | Organization CRUD, user assignments | **None** - purely DynamoDB operations |
| **WordPress API (BRS 2.6)** | Site content, templates, plugins | **None** - WordPress-level operations |
| **WordPress Tenant Management API (This BRS)** | Provision/deprovision ALL AWS resources | **Full** - ECS, EFS, RDS, ALB, Cognito |

### 1.3 Business Value

| Value Proposition | Benefit |
|-------------------|---------|
| Infrastructure Automation | Reduces provisioning from 2+ hours manual to < 15 minutes automated |
| Multi-Tenant Isolation | Ensures complete resource isolation between tenants |
| Lifecycle Management | Handles creation, suspension, scaling, and clean deprovisioning |
| Cognito Integration | Per-tenant User Pools with WordPress SSO |
| Cost Optimization | Right-sized resources per tenant with auto-scaling |

### 1.4 Key Stakeholders

- **Platform Operators**: Primary users who provision infrastructure for new tenants
- **DevOps Engineers**: Manage underlying infrastructure, troubleshoot issues
- **Security Engineers**: Ensure proper isolation and security configurations
- **Tenant API**: System consumer that triggers provisioning after tenant creation

### 1.5 Why a Separate BRS is Needed

The WordPress Tenant Management API has distinct:
- **Actors**: System-to-system (Tenant API triggers it) vs human operators
- **Resources**: AWS infrastructure vs application data
- **State Management**: Complex state machines with rollback requirements
- **Timeframes**: Long-running operations (minutes) vs instant responses
- **Error Handling**: Infrastructure failures require rollback strategies

---

## 2. Scope Definition

### 2.1 In Scope

| Category | Components |
|----------|------------|
| **ECS Provisioning** | Task definitions, ECS services, auto-scaling policies, health checks |
| **EFS Management** | Access point creation per tenant, mount configurations, backups |
| **RDS Database** | Per-tenant database creation, MySQL user provisioning |
| **ALB Configuration** | Target groups, listener rules, path-based routing |
| **Cognito User Pool** | Per-tenant User Pool, App Client, domain setup, groups |
| **Cognito-WordPress Integration** | MiniOrange plugin configuration, OAuth endpoints |
| **Secrets Management** | Database credentials, Cognito secrets in Secrets Manager |
| **Lifecycle Operations** | Suspend, resume, scale, update container version |
| **Deprovisioning** | Complete resource cleanup, database archival, orphan detection |
| **Monitoring** | Health checks, CloudWatch metrics, resource status tracking |

### 2.2 Out of Scope

| Category | Handled By |
|----------|------------|
| Tenant organization management | Tenant API (BRS 2.5) |
| Site content management | WordPress API (BRS 2.6) |
| User authentication flows | Cognito (direct user interaction) |
| WordPress plugin management | WordPress API |
| Billing and payments | Customer Portal / Order API |

---

## 3. Actors and Personas

### 3.1 Primary Actors

| Actor | Type | Description |
|-------|------|-------------|
| **Platform Operator** | Human | Provisions and manages WordPress infrastructure |
| **DevOps Engineer** | Human | Manages underlying infrastructure, troubleshoots |
| **Tenant API (System)** | System | Triggers provisioning after tenant creation |
| **CloudWatch (System)** | System | Triggers auto-scaling, health check failures |

### 3.2 Persona Details

**Platform Operator - Sarah**
- Responsible for onboarding new customer tenants
- Uses CLI scripts to provision WordPress instances
- Monitors provisioning status and troubleshoots failures

**DevOps Engineer - Mike**
- Manages Terraform infrastructure modules
- Investigates provisioning failures at AWS level
- Updates container images for WordPress updates

---

## 4. Infrastructure Components

### 4.1 ECS Fargate

| Component | Configuration |
|-----------|--------------|
| Cluster | `bbws-cluster` (shared) |
| Task CPU | 512 (0.5 vCPU) per tenant |
| Task Memory | 1024 MB (1 GB) per tenant |
| Desired Count | 2 tasks (multi-AZ) |
| Auto-scaling | Min 2, Max 10, CPU 70%, Memory 80% |
| Platform Version | Fargate 1.4.0+ (required for EFS) |

**Service Naming**: `tenant-{tenantId}-wordpress`

### 4.2 EFS (Elastic File System)

| Component | Configuration |
|-----------|--------------|
| Filesystem | Shared EFS with encryption |
| Access Point | One per tenant |
| Mount Path | `/var/www/html/wp-content` |
| Throughput Mode | Elastic |

**Access Point Naming**: `tenant-{tenantId}-wp-content`

### 4.3 RDS (MySQL)

| Component | Configuration |
|-----------|--------------|
| Instance | Shared RDS MySQL |
| Database per tenant | `tenant_{tenantId}_db` |
| User per tenant | `tenant_{tenantId}_user` |
| Credentials | Secrets Manager |

### 4.4 ALB (Application Load Balancer)

| Component | Configuration |
|-----------|--------------|
| Target Group | One per tenant |
| Listener Rule | Path-based routing |
| Health Check Path | `/` |

**Target Group Naming**: `tenant-{tenantId}-tg`

### 4.5 Cognito

| Component | Configuration |
|-----------|--------------|
| User Pool | Per-tenant |
| App Client | Per-tenant with client secret |
| Domain | `bbws-tenant-{id}-{env}.auth.af-south-1.amazoncognito.com` |
| Groups | Admin, Operator, Viewer |
| MFA | Optional (TOTP) |

---

## 5. Epics and User Stories

### Epic 1: WordPress Infrastructure Provisioning

**Epic ID**: EPIC-WPTM-001
**Description**: Provision complete WordPress infrastructure for a tenant

#### US-WPTM-001: Provision WordPress Instance

**User Story:**
> As a Platform Operator,
> I want to provision a complete WordPress infrastructure for a tenant,
> So that the customer has an isolated, running WordPress instance.

**Pre-conditions:**
- Tenant exists in DynamoDB with status `PENDING_PROVISIONING`
- Shared infrastructure is available (VPC, ECS cluster, RDS, EFS)
- Operator has appropriate IAM permissions

**Positive Scenario: Successful Provisioning**

1. Operator executes: `python provision_wordpress.py --tenant-id tenant-1`
2. API validates tenant exists and is in `PENDING_PROVISIONING` status
3. API creates EFS access point for tenant
4. API creates MySQL database and user in shared RDS
5. API stores database credentials in Secrets Manager
6. API registers ECS task definition with tenant-specific config
7. API creates ECS service with 2 tasks
8. API creates ALB target group and listener rule
9. API waits for service to stabilize (max 10 minutes)
10. API updates tenant status to `ACTIVE`
11. API publishes `WORDPRESS_PROVISIONED` event to SQS
12. API returns success with resource ARNs

**Negative Scenario: ECS Service Fails to Stabilize**

1. Provisioning starts successfully
2. ECS tasks fail health checks repeatedly
3. API detects stabilization timeout after 10 minutes
4. API initiates rollback: removes ALB rule, ECS service, EFS access point
5. API sets tenant status to `PROVISIONING_FAILED`
6. API logs failure details for investigation
7. API returns error with rollback confirmation

**Acceptance Criteria:**
- [ ] Complete provisioning in < 15 minutes
- [ ] All resources tagged with `bbws:tenant-id`
- [ ] Rollback completes on any failure
- [ ] ECS service has 2 running tasks across 2 AZs
- [ ] WordPress accessible via ALB path
- [ ] Database credentials in Secrets Manager
- [ ] Error messages MUST be clear and actionable

---

#### US-WPTM-002: Configure ECS Service

**User Story:**
> As the WordPress Tenant Management API,
> I want to create an ECS service for a tenant,
> So that WordPress containers are running with proper isolation.

**Configuration Details:**
```json
{
  "family": "tenant-{tenantId}-wordpress",
  "cpu": "512",
  "memory": "1024",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "secrets": [
    {"name": "WORDPRESS_DB_USER", "valueFrom": "{secret-arn}:username::"},
    {"name": "WORDPRESS_DB_PASSWORD", "valueFrom": "{secret-arn}:password::"}
  ]
}
```

**Acceptance Criteria:**
- [ ] Task definition uses Fargate 1.4.0+
- [ ] EFS volume mounted at `/var/www/html/wp-content`
- [ ] Secrets injected from Secrets Manager
- [ ] Health check configured with 60s start period
- [ ] Deployment circuit breaker enabled

---

#### US-WPTM-003: Create EFS Access Point

**Acceptance Criteria:**
- [ ] Access point creates directory at `/tenant-{tenantId}`
- [ ] POSIX user set to www-data (33:33)
- [ ] Access point tagged with tenant-id
- [ ] IAM authorization enabled

---

#### US-WPTM-004: Create Tenant Database

**Acceptance Criteria:**
- [ ] Database created with UTF8MB4
- [ ] User has privileges only to their database
- [ ] Password meets complexity requirements (16+ chars)
- [ ] Credentials stored in Secrets Manager

---

#### US-WPTM-005: Configure ALB Routing

**Acceptance Criteria:**
- [ ] Target group registered with ECS service
- [ ] Listener rule with unique priority
- [ ] Health checks passing
- [ ] Deregistration delay set to 30 seconds

---

### Epic 2: Infrastructure Lifecycle Management

**Epic ID**: EPIC-WPTM-002

#### US-WPTM-006: Suspend WordPress Instance

**User Story:**
> As a Platform Operator,
> I want to suspend a tenant's WordPress instance,
> So that resources are freed while preserving data.

**Acceptance Criteria:**
- [ ] ECS desired count set to 0
- [ ] Data preserved (EFS, RDS)
- [ ] Tenant status updated to `SUSPENDED`
- [ ] Resume operation restores service

---

#### US-WPTM-007: Resume WordPress Instance

**Acceptance Criteria:**
- [ ] Service resumes within 5 minutes
- [ ] WordPress data intact
- [ ] ALB routing restored
- [ ] Auto-scaling policies active

---

#### US-WPTM-008: Scale WordPress Resources

**Acceptance Criteria:**
- [ ] Horizontal scaling: min 2, max 10 tasks
- [ ] Vertical scaling: task definition version increment
- [ ] Zero-downtime deployment
- [ ] Cost impact calculated

---

#### US-WPTM-009: Update Container Version

**Acceptance Criteria:**
- [ ] Rolling deployment with zero downtime
- [ ] Automatic rollback on failure
- [ ] Audit log of version change
- [ ] WordPress version tracked

---

### Epic 3: Cognito-WordPress Integration

**Epic ID**: EPIC-WPTM-003

#### US-WPTM-010: Create Cognito User Pool

**Acceptance Criteria:**
- [ ] User Pool created with unique name
- [ ] Password policy enforced
- [ ] MFA optional (TOTP)
- [ ] Email verification enabled

---

#### US-WPTM-011: Configure Cognito App Client

**Acceptance Criteria:**
- [ ] Client secret generated
- [ ] Secret stored in Secrets Manager
- [ ] OAuth code flow enabled
- [ ] Callback URLs configured for WordPress

---

#### US-WPTM-012: Set Up WordPress OAuth Plugin

**Acceptance Criteria:**
- [ ] MiniOrange plugin activated
- [ ] Cognito endpoints configured
- [ ] Test authentication succeeds
- [ ] Role mapping configured

---

### Epic 4: Deprovisioning

**Epic ID**: EPIC-WPTM-004

#### US-WPTM-013: Deprovision WordPress Instance

**User Story:**
> As a Platform Operator,
> I want to completely deprovision a tenant's WordPress infrastructure,
> So that all resources are removed when a customer leaves.

**Deprovisioning Sequence:**
1. Update tenant status to `PENDING_DEPROVISIONING`
2. Remove ALB listener rule
3. Delete ALB target group
4. Stop and delete ECS service
5. Wait for tasks to terminate
6. Delete EFS access point
7. Archive or drop MySQL database
8. Delete Secrets Manager secret
9. Delete Cognito User Pool
10. Update tenant status to `DEPROVISIONED`

**Acceptance Criteria:**
- [ ] All resources removed (verified by tag scan)
- [ ] Database archived before deletion (configurable)
- [ ] No orphaned resources
- [ ] Deprovisioning completes in < 10 minutes
- [ ] Audit event logged

---

#### US-WPTM-014: Archive Tenant Data Before Deletion

**Acceptance Criteria:**
- [ ] RDS snapshot created before drop
- [ ] EFS backup to S3
- [ ] 90-day retention policy
- [ ] Archives tagged for lifecycle

---

## 6. API Endpoints

### 6.1 Provisioning Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/tenants/{tenantId}/wordpress/provision` | Provision infrastructure |
| GET | `/tenants/{tenantId}/wordpress/status` | Get provisioning status |
| DELETE | `/tenants/{tenantId}/wordpress` | Deprovision all |

### 6.2 Resource Management Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| PUT | `/tenants/{tenantId}/wordpress/scale` | Scale resources |
| PUT | `/tenants/{tenantId}/wordpress/suspend` | Suspend instance |
| PUT | `/tenants/{tenantId}/wordpress/resume` | Resume instance |

### 6.3 Cognito Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/tenants/{tenantId}/cognito/provision` | Provision Cognito |
| GET | `/tenants/{tenantId}/cognito/status` | Get Cognito status |
| DELETE | `/tenants/{tenantId}/cognito` | Delete User Pool |

---

## 7. State Machines

### 7.1 Provisioning State Machine

```
PENDING_PROVISIONING
         |
         v
  PROVISIONING_EFS
         |
         v
  PROVISIONING_RDS
         |
         v
  PROVISIONING_ECS
         |
         v
   CONFIGURING_ALB
         |
         v
PROVISIONING_COGNITO
         |
         v
       ACTIVE
```

**Failure at any step triggers rollback to PROVISIONING_FAILED**

### 7.2 Deprovisioning State Machine

```
      ACTIVE
         |
         v
PENDING_DEPROVISIONING
         |
         v
    REMOVING_ALB
         |
         v
    REMOVING_ECS
         |
         v
    REMOVING_EFS
         |
         v
   ARCHIVING_RDS
         |
         v
  REMOVING_COGNITO
         |
         v
   DEPROVISIONED
```

---

## 8. Data Models

### 8.1 WordPressProvisioningStatus

```python
class ProvisioningState(Enum):
    PENDING_PROVISIONING = "PENDING_PROVISIONING"
    PROVISIONING_EFS = "PROVISIONING_EFS"
    PROVISIONING_RDS = "PROVISIONING_RDS"
    PROVISIONING_ECS = "PROVISIONING_ECS"
    CONFIGURING_ALB = "CONFIGURING_ALB"
    PROVISIONING_COGNITO = "PROVISIONING_COGNITO"
    CONFIGURING_WORDPRESS = "CONFIGURING_WORDPRESS"
    ACTIVE = "ACTIVE"
    SUSPENDED = "SUSPENDED"
    PENDING_DEPROVISIONING = "PENDING_DEPROVISIONING"
    DEPROVISIONED = "DEPROVISIONED"
    FAILED = "FAILED"
```

### 8.2 TenantResources

```python
@dataclass
class TenantResources:
    ecs_service_arn: Optional[str] = None
    ecs_task_definition_arn: Optional[str] = None
    efs_access_point_id: Optional[str] = None
    database_name: Optional[str] = None
    database_secret_arn: Optional[str] = None
    alb_target_group_arn: Optional[str] = None
    alb_listener_rule_arn: Optional[str] = None
    cognito_user_pool_id: Optional[str] = None
    cognito_app_client_id: Optional[str] = None
```

---

## 9. Business Rules

### 9.1 Provisioning Rules

| Rule ID | Rule |
|---------|------|
| BR-PROV-001 | Tenant must be in `PENDING_PROVISIONING` status |
| BR-PROV-002 | Minimum 2 ECS tasks across 2 AZs |
| BR-PROV-003 | All resources tagged with tenant-id |
| BR-PROV-004 | Database names follow `tenant_{id}_db` pattern |
| BR-PROV-005 | Provisioning must complete within 15 minutes |
| BR-PROV-006 | Failed provisioning must rollback all resources |

### 9.2 Resource Naming Conventions

| Resource | Pattern |
|----------|---------|
| ECS Service | `tenant-{tenantId}-wordpress` |
| Task Definition | `tenant-{tenantId}-wordpress` |
| EFS Access Point | `tenant-{tenantId}-wp-content` |
| Database | `tenant_{tenantId}_db` |
| DB User | `tenant_{tenantId}_user` |
| Secret | `bbws/{env}/tenant-{tenantId}/db` |
| Target Group | `tenant-{tenantId}-tg` |
| Cognito Pool | `bbws-tenant-{tenantId}-user-pool` |

### 9.3 Resource Limits Per Tenant

| Resource | Default | Maximum |
|----------|---------|---------|
| ECS Tasks | 2 | 10 |
| Task vCPU | 0.5 | 2 |
| Task Memory | 1 GB | 4 GB |
| EFS Storage | Unlimited | Unlimited |
| Database Size | 5 GB | 100 GB |

### 9.4 Timeout Policies

| Operation | Timeout |
|-----------|---------|
| EFS Access Point Creation | 60 seconds |
| Database Creation | 120 seconds |
| ECS Service Stabilization | 600 seconds |
| ALB Rule Configuration | 60 seconds |
| Cognito User Pool Creation | 120 seconds |
| Deprovisioning (total) | 600 seconds |

---

## 10. Non-Functional Requirements

### 10.1 Performance

| Metric | Target |
|--------|--------|
| Provisioning time | < 15 minutes |
| Deprovisioning time | < 10 minutes |
| API response time | < 500ms |
| ECS service stabilization | < 5 minutes |

### 10.2 Availability

| Metric | Target |
|--------|--------|
| API availability | 99.9% |
| Provisioning success rate | > 99% |
| ECS service availability | 99.9% per tenant |

### 10.3 Resource Isolation Guarantees

| Resource | Isolation Level | Implementation |
|----------|-----------------|----------------|
| Compute | Container | Fargate microVM |
| Storage | Access Point | EFS access points |
| Database | Logical | Separate databases |
| Network | Security Group | Per-tier SGs |
| Identity | User Pool | Per-tenant Cognito |

### 10.4 Security Requirements

- All credentials in Secrets Manager
- TLS 1.2+ for all connections
- Database encryption at rest (KMS)
- EFS encryption at rest (KMS)
- IAM roles with least privilege

---

## 11. Error Handling and Recovery

### 11.1 Rollback Procedures

```python
def rollback_provisioning(tenant_id: str, resources: TenantResources):
    """Rollback in reverse order of creation"""

    # 1. Remove ALB configuration
    if resources.alb_listener_rule_arn:
        delete_listener_rule(resources.alb_listener_rule_arn)
    if resources.alb_target_group_arn:
        delete_target_group(resources.alb_target_group_arn)

    # 2. Remove ECS service
    if resources.ecs_service_arn:
        delete_service(resources.ecs_service_arn, force=True)
        wait_for_service_deletion()

    # 3. Remove EFS access point
    if resources.efs_access_point_id:
        delete_access_point(resources.efs_access_point_id)

    # 4. Remove database and user
    if resources.database_name:
        drop_database(resources.database_name)
        drop_user(f"tenant_{tenant_id}_user")

    # 5. Remove secrets
    if resources.database_secret_arn:
        delete_secret(resources.database_secret_arn)

    # 6. Update tenant status
    update_tenant_status(tenant_id, "PROVISIONING_FAILED")
```

### 11.2 Orphan Resource Detection

Daily scheduled job:
1. Scan all resources with `bbws:tenant-id` tag
2. Compare with DynamoDB tenant records
3. Flag resources without matching active tenant
4. Alert operations team for manual review

### 11.3 Dead Letter Queue

- All SQS queues have DLQ configured
- 3 receive attempts before DLQ
- DLQ messages retained 14 days
- CloudWatch alarm on DLQ depth > 0

---

## 12. Monitoring and Observability

### 12.1 CloudWatch Metrics

| Metric | Namespace | Alarm Threshold |
|--------|-----------|-----------------|
| ProvisioningDuration | BBWS/WordPress | > 15 minutes |
| ProvisioningSuccess | BBWS/WordPress | < 95% success |
| ECSTaskCount | AWS/ECS | < desiredCount |
| ECSCPUUtilization | AWS/ECS | > 90% |

### 12.2 Alerts

| Alert | Condition | Severity |
|-------|-----------|----------|
| Provisioning Failure | Any failure | High |
| Provisioning Timeout | > 20 minutes | High |
| ECS Tasks Unhealthy | Running < desired | Critical |
| DLQ Message | DLQ depth > 0 | Medium |
| Orphan Resources | Detected orphans | Low |

---

## 13. Document Sections Outline

```
1. Introduction
   1.1 Purpose
   1.2 Scope (In/Out)
   1.3 System Overview
   1.4 Use Case Diagrams

2. Stakeholders

3. API Definitions
   3.1 Provisioning Endpoints
   3.2 Lifecycle Management Endpoints
   3.3 Cognito Endpoints

4. Epic 1: WordPress Infrastructure Provisioning
   - US-WPTM-001 to US-WPTM-005

5. Epic 2: Infrastructure Lifecycle Management
   - US-WPTM-006 to US-WPTM-009

6. Epic 3: Cognito-WordPress Integration
   - US-WPTM-010 to US-WPTM-012

7. Epic 4: Deprovisioning
   - US-WPTM-013 to US-WPTM-014

8. State Machines
   8.1 Provisioning State Machine
   8.2 Deprovisioning State Machine

9. Non-Functional Requirements

10. Security

11. Monitoring and Observability

12. Error Handling and Recovery

13. Constraints

14. Assumptions and Risks

15. Glossary

16. Appendices
    A. Sample CLI Commands
    B. Terraform Modules
    C. IAM Policies
```

---

## 14. Effort Estimate

| Aspect | Assessment |
|--------|------------|
| **Complexity** | HIGH - Multiple AWS service integrations, state machines |
| **Estimated Pages** | 60-80 pages |
| **Story Points** | 40+ story points across 4 epics |
| **User Stories** | 14 user stories |
| **Risk Level** | Medium-High (infrastructure automation) |

**Recommended Approach:**
1. Complete Epic 1 (Provisioning) first - foundation
2. Epic 2 (Lifecycle) in parallel with testing Epic 1
3. Epic 3 (Cognito) can be done in parallel
4. Epic 4 (Deprovisioning) after all others stable

---

## 15. Open Questions

| ID | Question | Priority |
|----|----------|----------|
| OQ-001 | Should Cognito provisioning be synchronous or async? | High |
| OQ-002 | What is the database retention period for archived data? | High |
| OQ-003 | Support tenant migration between environments? | Medium |
| OQ-004 | Maximum concurrent provisioning operations? | Medium |
| OQ-005 | WordPress version pinned per tenant or platform-wide? | Low |
| OQ-006 | How should DR failover handle in-progress provisioning? | High |

---

## 16. References

| Document | Path |
|----------|------|
| Tenant_Management_LLD.md | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/Tenant_Management_LLD.md` |
| Cognito_Tenant_Pools_LLD.md | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/Cognito_Tenant_Pools_LLD.md` |
| Container_LLD.md | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/Container_LLD.md` |
| VPC_LLD.md | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/VPC_LLD.md` |
| 2.0_BBWS_ECS_WordPress_HLD.md | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.0_BBWS_ECS_WordPress_HLD.md` |
| 2.0_BRS_ECS_WordPress.md | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/BRS/2.0_BRS_ECS_WordPress.md` |
| 2.1_BRS_Customer_Portal_Public.md | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/BRS/2.1_BRS_Customer_Portal_Public.md` |

---

**End of Plan**
