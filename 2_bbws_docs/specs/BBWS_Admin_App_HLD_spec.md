# HLD Specification: BBWS Multi-Tenant WordPress Admin Application

**Document Type**: High-Level Design Specification
**System Name**: BBWS Admin App (Multi-Tenant WordPress Administration Portal)
**Architecture Style**: Serverless Web Application
**Author**: Tebogo Tseka
**Date**: 2025-12-13
**Status**: Specification - Ready for HLD Creation

---

## 1. System Overview

### 1.1 Purpose

Create a serverless web application that provides BBWS administrators with full administrative control over WordPress tenants across all three environments (DEV, SIT, PROD). The application enables:

- Complete tenant lifecycle management (create, configure, monitor, promote, deprovision)
- Multi-environment tenant promotion workflows (DEV → SIT → PROD)
- DNS and SSL certificate management (Route53, ACM)
- CloudFront distribution management per tenant
- Cognito User Pool management per tenant
- Real-time monitoring and health checks
- Audit logging and compliance reporting

### 1.2 Target Users

**Primary Users**:
- **BBWS Platform Administrators**: Full system access, can create/delete tenants, manage infrastructure
- **BBWS Operators**: Tenant operations, monitoring, troubleshooting, promotion workflows
- **BBWS DevOps Engineers**: Infrastructure deployment, CI/CD pipeline management

**Access Levels**:
- **Super Admin**: All operations across all environments including PROD deletion
- **Admin**: Tenant creation, configuration, promotion, monitoring (no PROD deletion)
- **Operator**: Read-only access to tenant status, logs, metrics
- **Viewer**: Dashboard viewing only, no modifications

### 1.3 Business Context

**Problem Statement**:
- Current tenant management requires manual AWS CLI commands and Terraform scripts
- No centralized view of tenant status across environments
- Tenant promotion (DEV → SIT → PROD) is manual and error-prone
- DNS and certificate management is scattered across AWS console
- No audit trail for tenant operations

**Solution**:
A serverless web application that consolidates all tenant management operations into a single, intuitive interface with:
- One-click tenant provisioning
- Automated promotion workflows with validation gates
- Centralized DNS and certificate management
- Real-time tenant health monitoring
- Complete audit logging for compliance

---

## 2. Architecture Requirements

### 2.1 Architecture Style

**Primary Pattern**: Serverless Microservices with Event-Driven Architecture

**Key Characteristics**:
- Serverless compute (AWS Lambda)
- API-driven (Amazon API Gateway)
- Event-driven workflows (Amazon EventBridge, SQS)
- Managed services (DynamoDB, S3, Cognito, Secrets Manager)
- Infrastructure as Code (Terraform)
- Multi-account orchestration (cross-account IAM roles)

### 2.2 Technology Stack

**Frontend**:
- Framework: React 18+ with TypeScript
- UI Library: Material-UI (MUI) or Tailwind CSS
- State Management: React Query + Zustand
- Build Tool: Vite
- Hosting: Amazon S3 + CloudFront (static site)
- Authentication: AWS Amplify + Cognito

**Backend**:
- Compute: AWS Lambda (Python 3.11+)
- API: Amazon API Gateway (REST or HTTP API)
- Database: Amazon DynamoDB (single table design)
- File Storage: Amazon S3
- Secrets: AWS Secrets Manager
- Authentication: Amazon Cognito User Pools
- Authorization: Cognito Groups + IAM policies

**Infrastructure**:
- IaC: Terraform
- CI/CD: GitHub Actions or AWS CodePipeline
- Monitoring: CloudWatch, X-Ray
- Logging: CloudWatch Logs with structured logging

**AWS Services**:
- ECS (tenant container management)
- RDS (tenant database queries)
- EFS (tenant file storage)
- Route53 (DNS management)
- ACM (certificate management)
- CloudFront (CDN management)
- EventBridge (workflow orchestration)
- SQS (async task queuing)
- SNS (notifications)
- Step Functions (complex workflows)

### 2.3 Multi-Account Architecture

**Deployment Model**:
- Admin App hosted in **PROD account (093646564004)**
- Cross-account IAM roles for DEV/SIT access
- Single admin app instance manages all three environments

**Cross-Account Access**:
```
Admin App (PROD)
├── AssumeRole → DEV Account (536580886816) → Tenant Operations
├── AssumeRole → SIT Account (815856636111) → Tenant Operations
└── Direct Access → PROD Account (093646564004) → Tenant Operations
```

**IAM Role Structure**:
- `BBWS-Admin-DevOps-Role` (in DEV account) - assumable by Admin App Lambda
- `BBWS-Admin-DevOps-Role` (in SIT account) - assumable by Admin App Lambda
- Admin App Lambda uses default execution role in PROD

---

## 3. Functional Requirements

### 3.1 Core Features

#### F-001: User Authentication and Authorization
- Login via Cognito User Pool (MFA required for Super Admin)
- Role-based access control (Super Admin, Admin, Operator, Viewer)
- Session management with JWT tokens
- Automatic logout after 30 minutes inactivity
- Audit logging for all login attempts

#### F-002: Tenant Dashboard
- List all tenants across all environments (tabbed view: DEV, SIT, PROD)
- Tenant status indicators (Healthy, Degraded, Down, Provisioning, Deprovisioning)
- Quick filters (by status, environment, organization, creation date)
- Search by tenant ID, domain name, organization
- Sortable columns (name, status, environment, created date, last modified)
- Tenant health metrics (uptime, response time, error rate)

#### F-003: Tenant Creation Wizard
**Multi-step wizard**:
1. Basic Information (tenant ID, display name, organization)
2. Environment Selection (DEV, SIT, PROD)
3. Domain Configuration (subdomain, DNS validation)
4. Resource Sizing (CPU, memory, storage based on environment)
5. Cognito Configuration (MFA settings, password policy)
6. WordPress Configuration (admin email, site title, tagline)
7. Review and Confirm

**Provisioning Process**:
- Validate tenant ID uniqueness
- Validate subdomain availability
- Create DynamoDB tenant record
- Trigger Lambda provisioning workflow:
  * Create RDS database and user
  * Create EFS access point
  * Create ECS task definition and service
  * Create ALB target group and listener rule
  * Create Route53 DNS record
  * Create CloudFront distribution
  * Request ACM certificate (with DNS validation)
  * Create Cognito User Pool (via provision_cognito.py)
  * Store all credentials in Secrets Manager
  * Initialize WordPress installation
- Display real-time provisioning progress
- Send email notification on completion

#### F-004: Tenant Details View
**Information Tabs**:
- **Overview**: Status, URLs, creation date, last updated, resource IDs
- **Infrastructure**: ECS tasks, RDS database, EFS storage, ALB targets
- **DNS & CDN**: Route53 records, CloudFront distribution, ACM certificate status
- **Authentication**: Cognito User Pool details, user count, MFA status
- **Monitoring**: Health checks, uptime, response times, error logs
- **Configuration**: WordPress settings, environment variables, resource limits
- **Audit Log**: All operations performed on this tenant

**Actions**:
- Start/Stop tenant (stop ECS tasks)
- Restart tenant (rolling restart)
- Scale tenant (adjust task count, CPU, memory)
- View logs (CloudWatch Logs Insights queries)
- Access WordPress admin (secure link generation)
- SSH/Exec into container (via ECS Exec)
- Backup tenant (manual backup trigger)
- Delete tenant (with confirmation, PROD requires Super Admin)

#### F-005: Multi-Environment Tenant Promotion
**Promotion Workflow (DEV → SIT → PROD)**:

**Step 1: Pre-Promotion Validation**:
- Verify tenant is healthy in source environment
- Verify tenant domain exists and is accessible
- Run WordPress integrity check
- Verify database backup exists and is recent (<24 hours)
- Verify EFS backup exists
- Check for WordPress plugin/theme updates needed
- Validate ACM certificate is active
- Security scan (outdated plugins, vulnerabilities)

**Step 2: Promotion Plan Generation**:
- Display what will be promoted:
  * Database dump (size, table count)
  * EFS content (file count, size)
  * WordPress configuration (plugins, themes, settings)
  * Cognito User Pool configuration
  * CloudFront distribution settings
  * DNS records
- Estimate promotion time
- Calculate resource costs in target environment
- Show required approvals

**Step 3: Approval Gate**:
- Admin approval required for SIT → PROD
- Auto-approve for DEV → SIT (if health checks pass)
- Super Admin approval for any PROD promotion
- Email notification to approvers
- Approval history tracking

**Step 4: Promotion Execution**:
- Create snapshot of source tenant (rollback point)
- Provision target environment infrastructure (if not exists)
- Export database from source environment via mysqldump
- Upload database dump to S3 (cross-region if needed)
- Sync EFS content to S3
- Import database to target environment RDS
- Sync S3 content to target environment EFS
- Update wp-config.php with target environment URLs
- Create target environment Cognito User Pool
- Clone CloudFront distribution settings
- Update DNS records (blue/green switch or new subdomain)
- Wait for ACM certificate validation (if new)
- Run smoke tests on target environment
- Mark promotion complete

**Step 5: Post-Promotion Validation**:
- Verify tenant accessible in target environment
- Run health checks (database, EFS, containers, DNS)
- Verify WordPress login works
- Check page load times
- Verify Cognito authentication works
- Generate promotion report

**Step 6: Rollback** (if validation fails):
- Restore source environment from snapshot
- Deprovision failed target environment resources
- Notify administrators
- Log rollback reason

#### F-006: DNS and Certificate Management
**Route53 Management**:
- List all hosted zones (DEV: wpdev.kimmyai.io, SIT: wpsit.kimmyai.io, PROD: wp.kimmyai.io)
- Create tenant subdomain A/ALIAS records
- Update DNS records (blue/green deployments)
- Delete DNS records (with confirmation)
- View DNS propagation status
- Test DNS resolution from multiple locations
- Manage NS delegation records (PROD → DEV/SIT)

**ACM Certificate Management**:
- Request wildcard certificate per environment (*.wpdev.kimmyai.io, *.wpsit.kimmyai.io, *.wp.kimmyai.io)
- Request tenant-specific certificate (optional)
- View certificate status (Pending, Issued, Expired, Revoked)
- Auto-renew certificates (monitor expiry, trigger renewal)
- Associate certificates with CloudFront distributions
- Manage certificate DNS validation records

**CloudFront Management**:
- List all distributions per environment
- Create distribution for new tenant
- Update distribution settings (cache behaviors, origins)
- Invalidate cache (all files or specific paths)
- View cache hit ratio and performance metrics
- Enable/disable distributions
- Associate ACM certificates with distributions
- Configure custom error pages

#### F-007: Cognito User Pool Management
**Per-Tenant Cognito Pools**:
- List all Cognito User Pools per environment
- Create User Pool for tenant (via provision_cognito.py integration)
- View User Pool details (users, groups, settings)
- Configure password policy per tenant
- Enable/disable MFA per tenant
- Add OIDC providers (Google, Azure AD)
- Manage app clients and callback URLs
- Delete User Pool when deprovisioning tenant

**User Management**:
- List users in tenant User Pool
- Create admin user for tenant
- Reset user password
- Enable/disable user account
- Assign user to groups (Admin, Editor, Author)
- View user login history
- Send password reset email

#### F-008: Monitoring and Alerting
**Real-Time Monitoring**:
- Tenant health dashboard (uptime, availability, response time)
- ECS task status (running, stopped, failed)
- RDS database metrics (connections, CPU, storage)
- EFS storage usage and IOPS
- ALB target health (healthy/unhealthy count)
- CloudFront cache hit ratio and bandwidth
- Cognito authentication metrics (logins, failures)

**Alerts and Notifications**:
- Tenant down alert (email, SMS via SNS)
- High error rate alert (>5% 5xx errors)
- Certificate expiry warning (30 days, 7 days, 1 day)
- Resource utilization alert (CPU >80%, memory >80%, disk >80%)
- Failed promotion alert
- Security alert (multiple failed login attempts, suspicious activity)

**CloudWatch Dashboards**:
- Per-tenant dashboard (auto-generated)
- Environment overview dashboard (all tenants in DEV/SIT/PROD)
- Cost dashboard (per-tenant spending)
- Performance dashboard (latency, throughput)

#### F-009: Backup and Disaster Recovery
**Automated Backups**:
- Daily RDS snapshots (cross-region replication)
- Hourly EFS backups (AWS Backup)
- Backup retention: 7 days (DEV), 14 days (SIT), 30 days (PROD)
- Backup verification (automated restore tests in DEV)

**Manual Backups**:
- On-demand snapshot (before major changes)
- Export backup to S3 (for archival)
- Download backup (encrypted ZIP)

**Restore Operations**:
- Restore tenant from backup (point-in-time)
- Clone tenant from backup (create new tenant)
- Cross-environment restore (SIT backup → DEV)
- Restore wizard (select backup, target environment, confirmation)

**Disaster Recovery**:
- DR failover to eu-west-1 (automated via Route53 health checks)
- DR failback to af-south-1 (manual approval required)
- DR testing workflow (validate backups in DR region)
- DR runbook (step-by-step procedures)

#### F-010: Audit Logging and Compliance
**Audit Trail**:
- Log all user actions (create, update, delete, view)
- Log all API calls with request/response
- Log all AWS service interactions
- Store logs in S3 (encrypted, immutable)
- Retain logs for 7 years (compliance requirement)

**Audit Reports**:
- User activity report (who did what, when)
- Tenant lifecycle report (creation, modifications, deletion)
- Promotion history report (DEV → SIT → PROD timeline)
- Access report (who accessed which tenants)
- Compliance report (security scans, certificate status, backup status)

**Security Logging**:
- Failed login attempts (track suspicious activity)
- Privilege escalation attempts
- Unauthorized access attempts
- Data export operations (PII/sensitive data)
- Configuration changes (security groups, IAM roles)

#### F-011: Cost Management
**Cost Tracking**:
- Per-tenant cost breakdown (ECS, RDS, EFS, CloudFront, Route53)
- Environment-level cost aggregation
- Cost trends (daily, weekly, monthly)
- Cost anomaly detection (unexpected spikes)
- Cost forecasting (based on historical data)

**Cost Optimization**:
- Identify idle tenants (no traffic for >7 days)
- Recommend right-sizing (overprovisioned resources)
- Identify unused CloudFront distributions
- Recommend reserved capacity (RDS, EFS)
- Spot instance recommendations (if applicable)

**Budgets and Alerts**:
- Set per-tenant budget limits
- Set environment budget limits
- Alert when approaching budget (80%, 90%, 100%)
- Auto-stop tenants exceeding budget (configurable)

#### F-012: Terraform Integration
**Infrastructure as Code**:
- Generate Terraform configuration for tenant
- Apply Terraform plan via API
- View Terraform state
- Import existing tenant to Terraform
- Export tenant Terraform configuration
- Terraform drift detection (actual vs. desired state)

**GitOps Workflow**:
- Commit Terraform changes to Git repository
- Trigger CI/CD pipeline for infrastructure deployment
- Review Terraform plan before apply
- Automatic rollback on failure

#### F-013: WordPress Management Integration
**WordPress Operations** (via Content Management Agent):
- Install WordPress plugins (from preset list)
- Update WordPress core, plugins, themes
- Configure WordPress settings (site URL, permalinks)
- Manage WordPress users and roles
- Import/export WordPress content
- Run WordPress database optimization
- Clear WordPress cache

**WordPress Health Checks**:
- Check WordPress core integrity
- Scan for outdated plugins/themes
- Check for known vulnerabilities
- Verify database connection
- Check file permissions
- Test email delivery (SMTP)

---

## 4. Non-Functional Requirements

### 4.1 Performance

| Metric | Target | Measurement |
|--------|--------|-------------|
| Page Load Time | <2 seconds | 95th percentile |
| API Response Time | <500ms | 95th percentile |
| Tenant Provisioning | <15 minutes | 95th percentile |
| Tenant Promotion (DEV→SIT) | <30 minutes | 95th percentile |
| Dashboard Refresh | <3 seconds | Real-time updates |
| Search Results | <1 second | 95th percentile |

### 4.2 Scalability

| Dimension | Target | Notes |
|-----------|--------|-------|
| Concurrent Users | 50 administrators | Expected peak |
| Tenants per Environment | 100 tenants | Initial capacity, scalable to 1000+ |
| API Requests/Second | 100 RPS | Lambda auto-scales |
| Database Throughput | 1000 WCU, 1000 RCU | DynamoDB on-demand scaling |

### 4.3 Availability

| Component | SLA | Downtime Budget (monthly) |
|-----------|-----|---------------------------|
| Admin App Frontend | 99.9% | 43.2 minutes |
| Admin App Backend (API) | 99.9% | 43.2 minutes |
| Tenant Operations | 99.9% | 43.2 minutes |
| Monitoring Dashboard | 99.5% | 3.6 hours |

### 4.4 Security

**Authentication**:
- Multi-factor authentication (MFA) required for Super Admin
- Password policy: 12+ chars, complexity requirements, no reuse of last 5 passwords
- Session timeout: 30 minutes idle, 8 hours absolute
- IP whitelisting for admin access (optional)

**Authorization**:
- Role-based access control (RBAC) via Cognito Groups
- Least privilege principle (users get minimum permissions needed)
- Separation of duties (no single user can create and approve promotions)

**Data Protection**:
- All data encrypted at rest (DynamoDB, S3, EFS, RDS)
- All data encrypted in transit (TLS 1.3)
- Secrets stored in AWS Secrets Manager (automatic rotation)
- PII data masked in logs and audit trails

**Compliance**:
- GDPR compliance (data residency in af-south-1, data export capability)
- Audit logging (7-year retention for compliance)
- Access controls (who can see what data)
- Data deletion workflows (right to be forgotten)

### 4.5 Disaster Recovery

**RTO (Recovery Time Objective)**: 4 hours
**RPO (Recovery Point Objective)**: 1 hour

**DR Strategy**:
- Admin App: Multi-region deployment (primary: af-south-1, DR: eu-west-1)
- Database: Cross-region DynamoDB replication
- Backups: Cross-region S3 replication
- DNS: Route53 health-check-based failover
- Runbook: Documented DR procedures with automated scripts

### 4.6 Cost

**Target Monthly Cost** (for 50 tenants):
- Admin App Infrastructure: ~$100/month
- DynamoDB: ~$50/month (on-demand)
- Lambda: ~$30/month (estimated)
- API Gateway: ~$20/month
- CloudFront (admin app): ~$10/month
- Cognito: ~$5/month
- Secrets Manager: ~$10/month
- CloudWatch: ~$20/month
- **Total**: ~$245/month for admin app infrastructure

**Per-Tenant Operational Costs** (via tenant infrastructure, not admin app):
- Calculated and displayed in Cost Management dashboard

---

## 5. User Stories and Epics

### Epic 1: User Authentication and Access Control

**US-001**: As a BBWS Administrator, I want to log in to the Admin App with MFA so that my account is secure.

**US-002**: As a Super Admin, I want to assign roles to users (Admin, Operator, Viewer) so that access is controlled.

**US-003**: As an Administrator, I want my session to timeout after 30 minutes of inactivity so that unauthorized access is prevented.

### Epic 2: Tenant Dashboard and Discovery

**US-004**: As an Administrator, I want to view all tenants across all environments in a dashboard so that I can see the overall platform status.

**US-005**: As an Administrator, I want to filter tenants by status, environment, or organization so that I can quickly find specific tenants.

**US-006**: As an Administrator, I want to search for tenants by domain name so that I can locate customer sites quickly.

### Epic 3: Tenant Provisioning

**US-007**: As an Administrator, I want to provision a new tenant through a wizard so that I don't have to use AWS CLI.

**US-008**: As an Administrator, I want to see real-time provisioning progress so that I know when the tenant is ready.

**US-009**: As an Administrator, I want to receive an email when tenant provisioning completes so that I can notify the customer.

### Epic 4: Tenant Management

**US-010**: As an Administrator, I want to view detailed tenant information (infrastructure, DNS, monitoring) so that I can troubleshoot issues.

**US-011**: As an Administrator, I want to restart a tenant so that I can apply configuration changes.

**US-012**: As an Administrator, I want to scale a tenant (increase CPU/memory) so that I can handle increased traffic.

**US-013**: As an Administrator, I want to delete a tenant so that I can clean up resources when customer leaves.

### Epic 5: Multi-Environment Promotion

**US-014**: As an Administrator, I want to promote a tenant from DEV to SIT so that I can test in a production-like environment.

**US-015**: As a Super Admin, I want to approve promotions to PROD so that only validated tenants reach production.

**US-016**: As an Administrator, I want to see a promotion plan (what will be migrated) before executing so that I can validate the promotion.

**US-017**: As an Administrator, I want to rollback a failed promotion so that the source environment is not affected.

### Epic 6: DNS and Certificate Management

**US-018**: As an Administrator, I want to create DNS records for tenants so that they are accessible via custom domains.

**US-019**: As an Administrator, I want to request and manage ACM certificates so that tenants have HTTPS.

**US-020**: As an Administrator, I want to view certificate expiry dates so that I can renew certificates before they expire.

### Epic 7: Monitoring and Alerting

**US-021**: As an Administrator, I want to see real-time tenant health status so that I can detect issues proactively.

**US-022**: As an Administrator, I want to receive alerts when a tenant goes down so that I can respond quickly.

**US-023**: As an Administrator, I want to view CloudWatch logs for a tenant so that I can troubleshoot errors.

### Epic 8: Backup and Recovery

**US-024**: As an Administrator, I want to trigger a manual backup before making major changes so that I can rollback if needed.

**US-025**: As an Administrator, I want to restore a tenant from backup so that I can recover from data loss.

**US-026**: As an Administrator, I want to verify that backups are working so that I can trust the DR process.

### Epic 9: Audit and Compliance

**US-027**: As a Compliance Officer, I want to view an audit trail of all operations so that I can ensure compliance.

**US-028**: As an Administrator, I want to generate compliance reports so that I can provide to auditors.

**US-029**: As a Security Engineer, I want to view security logs (failed logins, access attempts) so that I can detect threats.

### Epic 10: Cost Management

**US-030**: As a FinOps Engineer, I want to view per-tenant costs so that I can identify expensive tenants.

**US-031**: As an Administrator, I want to set budget alerts per tenant so that I can control spending.

**US-032**: As an Administrator, I want to identify idle tenants so that I can deprovision unused resources.

---

## 6. Component Architecture

### 6.1 Frontend Components

**React Application Structure**:
```
src/
├── components/
│   ├── Dashboard/
│   │   ├── TenantDashboard.tsx
│   │   ├── EnvironmentTabs.tsx
│   │   ├── TenantCard.tsx
│   │   └── StatusIndicator.tsx
│   ├── TenantWizard/
│   │   ├── CreateTenantWizard.tsx
│   │   ├── BasicInfoStep.tsx
│   │   ├── EnvironmentStep.tsx
│   │   ├── DomainConfigStep.tsx
│   │   ├── ResourceSizingStep.tsx
│   │   ├── CognitoConfigStep.tsx
│   │   ├── WordPressConfigStep.tsx
│   │   └── ReviewStep.tsx
│   ├── TenantDetails/
│   │   ├── TenantDetailsView.tsx
│   │   ├── OverviewTab.tsx
│   │   ├── InfrastructureTab.tsx
│   │   ├── DNSTab.tsx
│   │   ├── AuthenticationTab.tsx
│   │   ├── MonitoringTab.tsx
│   │   └── AuditLogTab.tsx
│   ├── Promotion/
│   │   ├── PromotionWizard.tsx
│   │   ├── PreValidation.tsx
│   │   ├── PromotionPlan.tsx
│   │   ├── ApprovalGate.tsx
│   │   ├── ExecutionProgress.tsx
│   │   └── PostValidation.tsx
│   ├── DNS/
│   │   ├── Route53Manager.tsx
│   │   ├── ACMCertificateManager.tsx
│   │   └── CloudFrontManager.tsx
│   ├── Monitoring/
│   │   ├── TenantHealthDashboard.tsx
│   │   ├── AlertsPanel.tsx
│   │   └── LogsViewer.tsx
│   ├── Auth/
│   │   ├── Login.tsx
│   │   ├── MFAChallenge.tsx
│   │   └── PrivateRoute.tsx
│   └── Common/
│       ├── Layout.tsx
│       ├── Navigation.tsx
│       ├── LoadingSpinner.tsx
│       └── ErrorBoundary.tsx
├── services/
│   ├── api.ts (API client with axios/fetch)
│   ├── auth.ts (Cognito integration)
│   ├── tenantService.ts
│   ├── promotionService.ts
│   ├── dnsService.ts
│   └── monitoringService.ts
├── hooks/
│   ├── useTenants.ts
│   ├── usePromotion.ts
│   ├── useAuth.ts
│   └── useAlerts.ts
├── store/
│   ├── authStore.ts (Zustand)
│   └── tenantStore.ts (Zustand)
├── utils/
│   ├── formatters.ts
│   ├── validators.ts
│   └── constants.ts
└── App.tsx
```

### 6.2 Backend Components (Lambda Functions)

**Microservices Architecture**:

1. **Tenant Management Service**:
   - `createTenant` - Provisions new tenant
   - `getTenant` - Retrieves tenant details
   - `listTenants` - Lists all tenants (with filters)
   - `updateTenant` - Updates tenant configuration
   - `deleteTenant` - Deprovisions tenant
   - `scaleTenant` - Adjusts tenant resources

2. **Promotion Service**:
   - `validatePromotion` - Pre-promotion validation
   - `generatePromotionPlan` - Creates promotion plan
   - `executePromotion` - Runs promotion workflow (Step Functions)
   - `rollbackPromotion` - Reverses failed promotion
   - `getPromotionStatus` - Checks promotion progress

3. **DNS and Certificate Service**:
   - `createDNSRecord` - Creates Route53 record
   - `deleteDNSRecord` - Removes Route53 record
   - `requestCertificate` - Requests ACM certificate
   - `getCertificateStatus` - Checks certificate validation status
   - `createCloudFrontDistribution` - Provisions CloudFront
   - `invalidateCache` - Invalidates CloudFront cache

4. **Cognito Management Service**:
   - `createUserPool` - Creates Cognito User Pool (calls provision_cognito.py)
   - `listUserPools` - Lists all User Pools
   - `getUserPoolUsers` - Lists users in pool
   - `createUser` - Creates user in pool
   - `deleteUserPool` - Removes User Pool

5. **Monitoring Service**:
   - `getTenantHealth` - Retrieves health metrics
   - `getCloudWatchLogs` - Queries logs
   - `getMetrics` - Retrieves CloudWatch metrics
   - `createAlert` - Sets up CloudWatch alarm
   - `getAlerts` - Lists active alerts

6. **Backup and Recovery Service**:
   - `createBackup` - Triggers manual backup
   - `listBackups` - Lists available backups
   - `restoreBackup` - Restores tenant from backup
   - `verifyBackup` - Tests backup integrity

7. **Audit Service**:
   - `logEvent` - Writes audit event
   - `queryAuditLog` - Searches audit trail
   - `generateComplianceReport` - Creates compliance report

8. **Cost Management Service**:
   - `getTenantCost` - Retrieves per-tenant costs
   - `getEnvironmentCost` - Aggregates environment costs
   - `detectAnomalies` - Identifies cost spikes
   - `generateCostReport` - Creates cost report

### 6.3 Data Models (DynamoDB Single Table Design)

**Table Name**: `BBWS-Admin-Data`

**Primary Key**: PK (Partition Key), SK (Sort Key)

**Entity Types**:

1. **Tenant Metadata**:
   - PK: `TENANT#{tenant_id}`
   - SK: `METADATA`
   - Attributes: tenant_name, organization, environment, status, created_at, updated_at, created_by

2. **Tenant Infrastructure**:
   - PK: `TENANT#{tenant_id}`
   - SK: `INFRA#{resource_type}` (e.g., INFRA#ECS, INFRA#RDS, INFRA#EFS)
   - Attributes: resource_id, arn, status, configuration

3. **Tenant DNS**:
   - PK: `TENANT#{tenant_id}`
   - SK: `DNS#{record_type}` (e.g., DNS#A, DNS#CNAME)
   - Attributes: domain, hosted_zone_id, record_value, ttl

4. **Tenant Cognito**:
   - PK: `TENANT#{tenant_id}`
   - SK: `COGNITO`
   - Attributes: user_pool_id, app_client_id, domain, user_count

5. **Promotion History**:
   - PK: `TENANT#{tenant_id}`
   - SK: `PROMOTION#{timestamp}`
   - Attributes: source_env, target_env, status, started_by, duration, rollback_reason

6. **Audit Events**:
   - PK: `AUDIT#{date}` (e.g., AUDIT#2025-12-13)
   - SK: `EVENT#{timestamp}#{user_id}`
   - Attributes: action, tenant_id, resource, user_id, ip_address, result

7. **User Sessions**:
   - PK: `USER#{user_id}`
   - SK: `SESSION#{session_id}`
   - Attributes: login_time, last_activity, ip_address, mfa_verified

**Global Secondary Indexes**:

1. **GSI1 - EnvironmentIndex**:
   - PK: `environment` (DEV, SIT, PROD)
   - SK: `status#{created_at}`
   - Use case: List all tenants in environment sorted by creation date

2. **GSI2 - StatusIndex**:
   - PK: `status` (Healthy, Degraded, Down, Provisioning)
   - SK: `tenant_id`
   - Use case: Find all unhealthy tenants

3. **GSI3 - OrganizationIndex**:
   - PK: `organization`
   - SK: `tenant_id`
   - Use case: List all tenants for an organization

---

## 7. Integration Points

### 7.1 AWS Services Integration

| Service | Purpose | Integration Method |
|---------|---------|-------------------|
| ECS | Tenant container management | AWS SDK (boto3), ECS API |
| RDS | Tenant database operations | AWS SDK, MySQL client via ECS Exec |
| EFS | Tenant file storage | AWS SDK, EFS API |
| Route53 | DNS record management | AWS SDK, Route53 API |
| ACM | Certificate management | AWS SDK, ACM API |
| CloudFront | CDN management | AWS SDK, CloudFront API |
| Cognito | Tenant auth, admin app auth | AWS SDK, Cognito API, Amplify SDK |
| Secrets Manager | Credential storage | AWS SDK, Secrets Manager API |
| CloudWatch | Monitoring, logging | AWS SDK, CloudWatch Logs Insights API |
| EventBridge | Workflow orchestration | Event-driven triggers, rules |
| Step Functions | Complex workflows (promotion) | State machine definitions |
| S3 | Backup storage, static hosting | AWS SDK, S3 API |
| SNS | Notifications (email, SMS) | AWS SDK, SNS API |
| SQS | Async task queuing | AWS SDK, SQS API |

### 7.2 External Tools Integration

| Tool | Purpose | Integration Method |
|------|---------|-------------------|
| provision_cognito.py | Cognito provisioning | Lambda exec or ECS task |
| Terraform | Infrastructure as Code | Terraform Cloud API or CLI exec |
| GitHub | GitOps repository | GitHub API, webhooks |
| WordPress | Tenant management | WP-CLI via ECS Exec, WP REST API |

### 7.3 Cross-Account Access

**IAM Assume Role Pattern**:

```python
# Lambda assumes role in target account
sts = boto3.client('sts')
assumed_role = sts.assume_role(
    RoleArn=f'arn:aws:iam::{target_account_id}:role/BBWS-Admin-DevOps-Role',
    RoleSessionName='AdminAppSession'
)

# Use temporary credentials
ecs = boto3.client(
    'ecs',
    aws_access_key_id=assumed_role['Credentials']['AccessKeyId'],
    aws_secret_access_key=assumed_role['Credentials']['SecretAccessKey'],
    aws_session_token=assumed_role['Credentials']['SessionToken']
)
```

---

## 8. Security Architecture

### 8.1 Authentication Flow

```
User → Cognito Hosted UI → MFA Challenge → JWT Token → API Gateway → Lambda
```

**Token Validation**:
- API Gateway validates JWT signature
- Lambda verifies Cognito group membership
- Lambda checks session is active (not expired)

### 8.2 Authorization Matrix

| Role | Create Tenant | Promote DEV→SIT | Promote SIT→PROD | Delete PROD Tenant | View Logs | View Costs |
|------|--------------|-----------------|------------------|-------------------|-----------|------------|
| Super Admin | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Admin | ✅ | ✅ | ⚠️ (requires approval) | ❌ | ✅ | ✅ |
| Operator | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Viewer | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |

### 8.3 Data Encryption

**At Rest**:
- DynamoDB: KMS encryption enabled
- S3: SSE-S3 or SSE-KMS
- RDS: KMS encryption
- EFS: KMS encryption
- Secrets Manager: KMS encryption

**In Transit**:
- All API calls: HTTPS (TLS 1.3)
- CloudFront to origin: HTTPS only
- RDS connections: TLS
- Inter-service: AWS PrivateLink where applicable

---

## 9. Deployment Architecture

### 9.1 Environment Strategy

| Environment | Purpose | Deployment Trigger |
|-------------|---------|-------------------|
| DEV | Development, testing | On commit to `develop` branch |
| SIT | Pre-production testing | On commit to `staging` branch |
| PROD | Production admin app | On tag creation (e.g., `v1.0.0`) |

### 9.2 CI/CD Pipeline

**GitHub Actions Workflow**:
```yaml
name: Deploy Admin App

on:
  push:
    branches: [develop, staging]
    tags: ['v*']

jobs:
  test:
    - Run unit tests
    - Run integration tests
    - Security scan (Snyk, Trivy)
    - Lint code (ESLint, Black)

  build:
    - Build React app (npm run build)
    - Package Lambda functions (zip)
    - Run Terraform validate

  deploy:
    - Deploy frontend to S3
    - Invalidate CloudFront cache
    - Deploy Lambda functions
    - Run Terraform apply
    - Run smoke tests
    - Notify on success/failure
```

### 9.3 Infrastructure Deployment

**Terraform Modules**:
- `modules/frontend` - S3, CloudFront for React app
- `modules/api` - API Gateway, Lambda functions
- `modules/database` - DynamoDB tables
- `modules/auth` - Cognito User Pool for admin app
- `modules/monitoring` - CloudWatch dashboards, alarms
- `modules/iam` - Cross-account roles, policies

---

## 10. Success Criteria

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Tenant Provisioning Success Rate | >95% | DynamoDB audit log |
| Promotion Success Rate (DEV→SIT) | >95% | Promotion history table |
| Promotion Success Rate (SIT→PROD) | >98% | Promotion history table |
| Admin User Adoption | 100% of admins | Cognito User Pool count |
| Average Time to Provision Tenant | <15 minutes | CloudWatch metrics |
| Average Time to Promote (DEV→SIT) | <30 minutes | Step Functions execution time |
| System Uptime | >99.9% | CloudWatch alarms |
| User Satisfaction | >4.5/5 | User survey |

---

## 11. Risks and Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Cross-account role misconfiguration | High | Medium | Automated IAM policy validation, least privilege |
| Promotion failure causing data loss | Critical | Low | Pre-promotion snapshots, rollback capability |
| Unauthorized access to admin app | Critical | Low | MFA enforcement, IP whitelisting, audit logging |
| Cost overrun from unused tenants | Medium | Medium | Idle tenant detection, budget alerts |
| Certificate expiry causing outages | High | Low | Automated renewal, expiry alerts (30/7/1 days) |
| DynamoDB throttling during peak | Medium | Low | On-demand capacity mode, provisioned backup |
| Lambda cold start latency | Low | Medium | Provisioned concurrency for critical functions |

---

## 12. Open Questions (TBCs)

| TBC ID | Question | Owner | Decision Required |
|--------|----------|-------|-------------------|
| TBC-001 | Use React or Next.js for frontend? | Frontend Team | By 2025-12-20 |
| TBC-002 | Use API Gateway REST or HTTP API? | Backend Team | By 2025-12-20 |
| TBC-003 | Use Step Functions or custom orchestration for promotion? | DevOps | By 2025-12-22 |
| TBC-004 | IP whitelist required for admin access? | Security | By 2025-12-25 |
| TBC-005 | Multi-region deployment for admin app? | Architecture | By 2026-01-05 |
| TBC-006 | Real-time updates via WebSockets or polling? | Frontend Team | By 2025-12-20 |
| TBC-007 | Custom domain for admin app (admin.bbws.io)? | DNS | By 2025-12-25 |
| TBC-008 | Terraform Cloud or self-hosted Terraform? | DevOps | By 2025-12-22 |

---

## 13. Next Steps

1. **Review and Approval** (2025-12-15):
   - Stakeholder review of this specification
   - Address TBCs and open questions
   - Get sign-off from Security, DevOps, Product Owner

2. **HLD Creation** (2025-12-16 - 2025-12-18):
   - Use this spec to create full HLD document
   - Include detailed component diagrams
   - Create sequence diagrams for key workflows
   - Document API specifications

3. **Prototype** (2025-12-19 - 2025-12-23):
   - Build basic React app with tenant dashboard
   - Create sample Lambda functions for tenant CRUD
   - Test cross-account IAM role assumption
   - Validate DynamoDB data model

4. **LLD Creation** (2025-12-26 - 2026-01-05):
   - Create LLDs for each microservice
   - Document API contracts (OpenAPI)
   - Define database schemas
   - Create Terraform module specifications

5. **Implementation** (2026-01-06 onwards):
   - Sprint 1: Authentication, Dashboard, Tenant List
   - Sprint 2: Tenant Creation Wizard
   - Sprint 3: Tenant Details View, Operations
   - Sprint 4: Promotion Workflows
   - Sprint 5: DNS and Certificate Management
   - Sprint 6: Monitoring and Alerting
   - Sprint 7: Backup and Recovery
   - Sprint 8: Audit and Compliance
   - Sprint 9: Cost Management
   - Sprint 10: Testing, Documentation, Launch

---

## 14. References

- Parent HLD: `BBWS_ECS_WordPress_HLD.md`
- Related LLDs: All LLDs in `HLDs/LLDs/` folder
- Tenant Manager Agent: `tenant_manager.md`
- ECS Cluster Manager Agent: `ecs_cluster_manager.md`
- Content Management Agent: `content_manager.md`
- Cognito Investigation: `cognito_multi_tenant_investigation.md`
- AWS Well-Architected Framework: https://aws.amazon.com/architecture/well-architected/

---

**End of Specification**

This specification is ready for HLD creation using the Agentic Architect HLD agent.
