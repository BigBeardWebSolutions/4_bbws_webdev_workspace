# Promotion Plan: ecs_terraform

**Project**: 2_bbws_ecs_terraform
**Plan ID**: PROM-ECS-007
**Created**: 2026-01-07
**Owner**: DevOps Engineer
**Status**: 📋 READY FOR EXECUTION

---

## Project Overview

| Attribute | Value |
|-----------|-------|
| **Project Type** | Infrastructure (ECS Fargate + Multi-tenant WordPress) |
| **Purpose** | Scalable multi-tenant WordPress hosting platform |
| **Current Status** | 100% complete, Production Ready |
| **Components** | ECS Cluster, Fargate Services, ALB, Aurora MySQL, ElastiCache Redis, EFS |
| **Terraform Files** | 58 (modular infrastructure) |
| **Tenant Isolation** | Network-level (separate VPCs/security groups per tenant class) |
| **CI/CD Workflows** | 4 (deploy-dev, promote-sit, promote-prod, terraform-validate) |
| **Wave** | Wave 2 (Infrastructure Foundation) |

---

## Environments

| Environment | AWS Account | Region | Domain | Status |
|-------------|-------------|--------|--------|--------|
| **DEV** | 536580886816 | eu-west-1 | `*.dev.bbws.io` | ✅ Deployed |
| **SIT** | 815856636111 | eu-west-1 | `*.sit.bbws.io` | ⏳ Target |
| **PROD** | 093646564004 | af-south-1 (primary) | `*.bbws.io` | 🔵 Planned |
| **DR** | 093646564004 | eu-west-1 (failover) | `*.bbws.io` | 🔵 Planned |

---

## Promotion Timeline

```
PHASE 1: SIT PROMOTION (Jan 13, 2026)
├─ Pre-deployment  (Jan 11-12)
├─ Deployment      (Jan 13, 1:00 PM)
├─ Validation      (Jan 13, 2:00 PM - 4:00 PM)
└─ Sign-off        (Jan 13, 5:00 PM)

PHASE 2: SIT VALIDATION (Jan 14-31)
├─ Integration Testing (Jan 14-17)
├─ Multi-tenant Test   (Jan 18-21)
├─ Performance Testing (Jan 22-24)
├─ Security Scanning   (Jan 25-26)
└─ SIT Sign-off        (Jan 31)

PHASE 3: PROD PROMOTION (Feb 24, 2026)
├─ Pre-deployment  (Feb 20-23)
├─ Deployment      (Feb 24, 2:00 PM)
├─ DR Setup        (Feb 25, 9:00 AM)
├─ Validation      (Feb 25, 11:00 AM - 3:00 PM)
└─ Sign-off        (Feb 27, 5:00 PM)
```

---

## Phase 1: SIT Promotion

### Pre-Deployment Checklist (Jan 11-12)

#### Environment Verification
- [ ] AWS SSO login to SIT account (815856636111)
- [ ] Verify AWS profile: `AWS_PROFILE=Tebogo-sit aws sts get-caller-identity`
- [ ] Confirm SIT region: eu-west-1
- [ ] Verify IAM permissions for ECS, RDS, ElastiCache, EFS, VPC
- [ ] Check quota limits:
  - ECS clusters: 10 per region
  - Fargate vCPU: 1000 per region
  - RDS instances: 40 per region
  - ElastiCache nodes: 100 per region
  - Elastic IPs: 5 per region
  - VPCs: 5 per region

#### Code Preparation
- [ ] Verify latest code in `main` branch
- [ ] Confirm all Terraform validations passing in DEV
- [ ] Review GitHub Actions workflows (promote-sit.yml)
- [ ] Tag release: `v1.0.0-sit`
- [ ] Create changelog for SIT release
- [ ] Document all 58 Terraform files and their purposes
- [ ] Review Terraform state management strategy

#### Infrastructure Planning
- [ ] **CRITICAL**: Document all 58 Terraform files:
  ```
  Core Infrastructure (10 files):
  - vpc.tf, subnets.tf, internet_gateway.tf, nat_gateway.tf
  - security_groups.tf, route_tables.tf
  - ecs_cluster.tf, ecs_task_definitions.tf, ecs_services.tf
  - alb.tf

  Database Layer (8 files):
  - rds_aurora_cluster.tf, rds_aurora_instances.tf
  - rds_parameter_group.tf, rds_subnet_group.tf
  - rds_security_group.tf, rds_secrets.tf
  - rds_backups.tf, rds_monitoring.tf

  Cache Layer (5 files):
  - elasticache_redis_cluster.tf, elasticache_subnet_group.tf
  - elasticache_parameter_group.tf, elasticache_security_group.tf
  - elasticache_backups.tf

  Storage Layer (4 files):
  - efs.tf, efs_mount_targets.tf
  - efs_access_points.tf, efs_backups.tf

  Monitoring (6 files):
  - cloudwatch_logs.tf, cloudwatch_alarms.tf
  - cloudwatch_dashboards.tf, sns_topics.tf
  - eventbridge_rules.tf, xray.tf

  IAM (7 files):
  - iam_roles.tf, iam_policies.tf
  - iam_task_execution_role.tf, iam_task_role.tf
  - iam_service_role.tf, iam_autoscaling_role.tf
  - iam_backup_role.tf

  Auto-scaling (4 files):
  - ecs_autoscaling.tf, ecs_autoscaling_policies.tf
  - ecs_autoscaling_alarms.tf, ecs_capacity_providers.tf

  Tenant Management (8 files):
  - tenant_vpc.tf, tenant_subnets.tf
  - tenant_security_groups.tf, tenant_routing.tf
  - tenant_databases.tf, tenant_efs_access_points.tf
  - tenant_task_definitions.tf, tenant_services.tf

  Secrets Management (3 files):
  - secrets_manager.tf, kms.tf, parameter_store.tf

  Backup & DR (3 files):
  - backup_vault.tf, backup_plan.tf, backup_selections.tf
  ```
- [ ] Verify multi-tenant isolation strategy
- [ ] Document tenant onboarding process
- [ ] Plan for Aurora MySQL cluster configuration
- [ ] Plan for ElastiCache Redis cluster configuration
- [ ] Plan for EFS file system configuration

#### Multi-Tenant Isolation
- [ ] **CRITICAL**: Document tenant isolation levels:
  - **Level 1**: Shared VPC, separate security groups (basic tenants)
  - **Level 2**: Separate VPC, shared database cluster (premium tenants)
  - **Level 3**: Separate VPC, dedicated database (enterprise tenants)
- [ ] Verify security group rules prevent cross-tenant access
- [ ] Document tenant routing strategy
- [ ] Plan for tenant-specific resource tagging

#### Dependencies
- [ ] **CRITICAL**: DynamoDB schemas MUST be in SIT (for tenant metadata)
- [ ] **CRITICAL**: S3 schemas MUST be in SIT (for WordPress media)
- [ ] Route53 hosted zone for sit.bbws.io
- [ ] ACM certificate for *.sit.bbws.io

### Deployment Steps (Jan 13, 1:00 PM)

#### Step 1: Verify Dependencies
```bash
# Verify DynamoDB tables exist in SIT
AWS_PROFILE=Tebogo-sit aws dynamodb list-tables --region eu-west-1 | grep tenants-sit

# Verify S3 buckets exist in SIT
AWS_PROFILE=Tebogo-sit aws s3 ls --region eu-west-1 | grep bbws-tenant-assets-sit

# Verify ACM certificate
AWS_PROFILE=Tebogo-sit aws acm list-certificates --region eu-west-1 | grep sit.bbws.io
```

#### Step 2: Terraform State Management
```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform

# **CRITICAL**: Verify Terraform state backend configured
cat backend.tf
# Should use S3 backend with state locking via DynamoDB

# Initialize Terraform with SIT backend
terraform init -backend-config="key=ecs-terraform/sit/terraform.tfstate"

# Verify state lock table exists
AWS_PROFILE=Tebogo-sit aws dynamodb describe-table --table-name terraform-state-lock-sit

# Create workspace for SIT
terraform workspace new sit || terraform workspace select sit
terraform workspace list
```

#### Step 3: Terraform Plan (Core Infrastructure First)
```bash
# **CRITICAL**: Deploy in phases to manage complexity

# Phase 1: Network infrastructure
AWS_PROFILE=Tebogo-sit terraform plan \
  -target=module.vpc \
  -target=module.subnets \
  -target=module.security_groups \
  -out=sit-network.tfplan

# Review network plan carefully
```

#### Step 4: Manual Approval (Network Phase)
- Review terraform plan with Network Engineer
- Verify CIDR blocks don't overlap with DEV/PROD
- Verify subnet sizing appropriate
- Verify NAT Gateway placement (high availability)
- Get approval from Tech Lead
- Document approval in deployment log

#### Step 5: Apply Network Infrastructure
```bash
AWS_PROFILE=Tebogo-sit terraform apply sit-network.tfplan
# Monitor output carefully
# Network creation takes 5-10 minutes
```

#### Step 6: Terraform Plan (Database Layer)
```bash
# Phase 2: RDS Aurora cluster
AWS_PROFILE=Tebogo-sit terraform plan \
  -target=module.rds_aurora \
  -target=module.elasticache_redis \
  -out=sit-database.tfplan

# CRITICAL REVIEW:
# - Verify Aurora cluster configuration (multi-AZ)
# - Verify database credentials stored in Secrets Manager
# - Verify automated backups enabled (retention: 7 days SIT, 30 days PROD)
# - Verify encryption at rest enabled
# - Verify Redis cluster configuration
# - Verify parameter groups appropriate
```

#### Step 7: Manual Approval (Database Phase)
- Review terraform plan with DBA
- Verify database instance sizing appropriate for SIT
- Verify backup retention policy
- Verify encryption enabled
- Verify multi-AZ configuration
- Get approval from Tech Lead and DBA
- Document approval in deployment log

#### Step 8: Apply Database Layer
```bash
AWS_PROFILE=Tebogo-sit terraform apply sit-database.tfplan
# Monitor output carefully
# Aurora cluster creation takes 15-20 minutes
# Redis cluster creation takes 10-15 minutes
```

#### Step 9: Terraform Plan (Storage Layer)
```bash
# Phase 3: EFS file system
AWS_PROFILE=Tebogo-sit terraform plan \
  -target=module.efs \
  -out=sit-storage.tfplan

# CRITICAL REVIEW:
# - Verify EFS file system configuration
# - Verify mount targets in multiple AZs
# - Verify access points for tenant isolation
# - Verify encryption at rest enabled
# - Verify backup policy configured
```

#### Step 10: Apply Storage Layer
```bash
AWS_PROFILE=Tebogo-sit terraform apply sit-storage.tfplan
# EFS creation takes 2-5 minutes
```

#### Step 11: Terraform Plan (ECS Infrastructure)
```bash
# Phase 4: ECS cluster and services
AWS_PROFILE=Tebogo-sit terraform plan \
  -target=module.ecs_cluster \
  -target=module.alb \
  -target=module.ecs_task_definitions \
  -target=module.ecs_services \
  -out=sit-ecs.tfplan

# CRITICAL REVIEW:
# - Verify ECS cluster configuration (Fargate capacity provider)
# - Verify ALB configuration (HTTPS listener)
# - Verify task definitions (CPU, memory, container configs)
# - Verify service configuration (desired count, auto-scaling)
# - Verify health check configuration
# - Verify logging configuration (CloudWatch Logs)
```

#### Step 12: Apply ECS Infrastructure
```bash
AWS_PROFILE=Tebogo-sit terraform apply sit-ecs.tfplan
# Monitor output carefully
# ALB creation takes 3-5 minutes
# ECS service startup takes 5-10 minutes
```

#### Step 13: Verify Core Infrastructure
```bash
# Verify VPC
AWS_PROFILE=Tebogo-sit aws ec2 describe-vpcs --filters "Name=tag:Environment,Values=sit" --region eu-west-1

# Verify Aurora cluster
AWS_PROFILE=Tebogo-sit aws rds describe-db-clusters --db-cluster-identifier bbws-aurora-sit --region eu-west-1

# Verify Redis cluster
AWS_PROFILE=Tebogo-sit aws elasticache describe-cache-clusters --cache-cluster-id bbws-redis-sit --region eu-west-1

# Verify EFS
AWS_PROFILE=Tebogo-sit aws efs describe-file-systems --region eu-west-1 | grep bbws-efs-sit

# Verify ECS cluster
AWS_PROFILE=Tebogo-sit aws ecs describe-clusters --clusters bbws-ecs-sit --region eu-west-1

# Verify ALB
AWS_PROFILE=Tebogo-sit aws elbv2 describe-load-balancers --region eu-west-1 | grep bbws-alb-sit
```

#### Step 14: Terraform Plan (Monitoring & Alarms)
```bash
# Phase 5: CloudWatch monitoring
AWS_PROFILE=Tebogo-sit terraform plan \
  -target=module.cloudwatch \
  -target=module.sns_topics \
  -out=sit-monitoring.tfplan
```

#### Step 15: Apply Monitoring
```bash
AWS_PROFILE=Tebogo-sit terraform apply sit-monitoring.tfplan
```

### Post-Deployment Validation (Jan 13, 2:00 PM - 4:00 PM)

#### VPC and Network Validation
```bash
# Test 1: Verify VPC and subnets
VPC_ID=$(AWS_PROFILE=Tebogo-sit aws ec2 describe-vpcs \
  --filters "Name=tag:Environment,Values=sit" \
  --query 'Vpcs[0].VpcId' \
  --output text \
  --region eu-west-1)

echo "VPC ID: $VPC_ID"

AWS_PROFILE=Tebogo-sit aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --region eu-west-1 \
  --query 'Subnets[*].[SubnetId,CidrBlock,AvailabilityZone,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# Test 2: Verify NAT Gateway (for private subnets)
AWS_PROFILE=Tebogo-sit aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=$VPC_ID" \
  --region eu-west-1 \
  --query 'NatGateways[*].[NatGatewayId,State,SubnetId]' \
  --output table

# Test 3: Verify security groups
AWS_PROFILE=Tebogo-sit aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --region eu-west-1 \
  --query 'SecurityGroups[*].[GroupId,GroupName,Description]' \
  --output table
```

#### Database Validation
```bash
# Test 4: Verify Aurora cluster status
AWS_PROFILE=Tebogo-sit aws rds describe-db-clusters \
  --db-cluster-identifier bbws-aurora-sit \
  --region eu-west-1 \
  --query 'DBClusters[0].[Status,Engine,EngineVersion,MultiAZ]' \
  --output table

# Test 5: Verify Aurora instances
AWS_PROFILE=Tebogo-sit aws rds describe-db-instances \
  --filters "Name=db-cluster-id,Values=bbws-aurora-sit" \
  --region eu-west-1 \
  --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,DBInstanceClass,AvailabilityZone]' \
  --output table

# Test 6: Verify database encryption
AWS_PROFILE=Tebogo-sit aws rds describe-db-clusters \
  --db-cluster-identifier bbws-aurora-sit \
  --region eu-west-1 \
  --query 'DBClusters[0].StorageEncrypted'

# Test 7: Verify automated backups
AWS_PROFILE=Tebogo-sit aws rds describe-db-clusters \
  --db-cluster-identifier bbws-aurora-sit \
  --region eu-west-1 \
  --query 'DBClusters[0].[BackupRetentionPeriod,PreferredBackupWindow]' \
  --output table

# Test 8: Get database credentials from Secrets Manager
SECRET_ARN=$(AWS_PROFILE=Tebogo-sit aws secretsmanager list-secrets \
  --region eu-west-1 \
  --query 'SecretList[?contains(Name, `aurora-sit`)].ARN' \
  --output text)

echo "Database secret ARN: $SECRET_ARN"

# Test 9: Test database connectivity (from ECS task or bastion host)
# This requires database endpoint
DB_ENDPOINT=$(AWS_PROFILE=Tebogo-sit aws rds describe-db-clusters \
  --db-cluster-identifier bbws-aurora-sit \
  --region eu-west-1 \
  --query 'DBClusters[0].Endpoint' \
  --output text)

echo "Database endpoint: $DB_ENDPOINT"
```

#### Cache Validation
```bash
# Test 10: Verify Redis cluster status
AWS_PROFILE=Tebogo-sit aws elasticache describe-cache-clusters \
  --cache-cluster-id bbws-redis-sit \
  --region eu-west-1 \
  --query 'CacheClusters[0].[CacheClusterStatus,CacheNodeType,Engine,EngineVersion,NumCacheNodes]' \
  --output table

# Test 11: Get Redis endpoint
REDIS_ENDPOINT=$(AWS_PROFILE=Tebogo-sit aws elasticache describe-cache-clusters \
  --cache-cluster-id bbws-redis-sit \
  --region eu-west-1 \
  --show-cache-node-info \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' \
  --output text)

echo "Redis endpoint: $REDIS_ENDPOINT"

# Test 12: Verify Redis encryption
AWS_PROFILE=Tebogo-sit aws elasticache describe-cache-clusters \
  --cache-cluster-id bbws-redis-sit \
  --region eu-west-1 \
  --query 'CacheClusters[0].[AtRestEncryptionEnabled,TransitEncryptionEnabled]' \
  --output table
```

#### EFS Validation
```bash
# Test 13: Verify EFS file system
EFS_ID=$(AWS_PROFILE=Tebogo-sit aws efs describe-file-systems \
  --region eu-west-1 \
  --query 'FileSystems[?Tags[?Key==`Name` && contains(Value, `sit`)]].FileSystemId' \
  --output text)

echo "EFS ID: $EFS_ID"

AWS_PROFILE=Tebogo-sit aws efs describe-file-systems \
  --file-system-id $EFS_ID \
  --region eu-west-1 \
  --query 'FileSystems[0].[LifeCycleState,Encrypted,PerformanceMode,ThroughputMode]' \
  --output table

# Test 14: Verify EFS mount targets (multi-AZ)
AWS_PROFILE=Tebogo-sit aws efs describe-mount-targets \
  --file-system-id $EFS_ID \
  --region eu-west-1 \
  --query 'MountTargets[*].[MountTargetId,SubnetId,AvailabilityZoneName,LifeCycleState]' \
  --output table

# Test 15: Verify EFS access points (tenant isolation)
AWS_PROFILE=Tebogo-sit aws efs describe-access-points \
  --file-system-id $EFS_ID \
  --region eu-west-1 \
  --query 'AccessPoints[*].[AccessPointId,Name,LifeCycleState]' \
  --output table
```

#### ECS Validation
```bash
# Test 16: Verify ECS cluster
AWS_PROFILE=Tebogo-sit aws ecs describe-clusters \
  --clusters bbws-ecs-sit \
  --region eu-west-1 \
  --query 'clusters[0].[status,capacityProviders,registeredContainerInstancesCount,runningTasksCount]' \
  --output table

# Test 17: Verify ECS services
AWS_PROFILE=Tebogo-sit aws ecs list-services \
  --cluster bbws-ecs-sit \
  --region eu-west-1

AWS_PROFILE=Tebogo-sit aws ecs describe-services \
  --cluster bbws-ecs-sit \
  --services bbws-wordpress-sit \
  --region eu-west-1 \
  --query 'services[0].[serviceName,status,desiredCount,runningCount,launchType]' \
  --output table

# Test 18: Verify ECS tasks running
AWS_PROFILE=Tebogo-sit aws ecs list-tasks \
  --cluster bbws-ecs-sit \
  --region eu-west-1

# Test 19: Verify task definition
AWS_PROFILE=Tebogo-sit aws ecs describe-task-definition \
  --task-definition bbws-wordpress-sit \
  --region eu-west-1 \
  --query 'taskDefinition.[family,taskRoleArn,executionRoleArn,cpu,memory,networkMode]' \
  --output table
```

#### ALB Validation
```bash
# Test 20: Verify ALB
ALB_ARN=$(AWS_PROFILE=Tebogo-sit aws elbv2 describe-load-balancers \
  --region eu-west-1 \
  --query 'LoadBalancers[?contains(LoadBalancerName, `sit`)].LoadBalancerArn' \
  --output text)

echo "ALB ARN: $ALB_ARN"

AWS_PROFILE=Tebogo-sit aws elbv2 describe-load-balancers \
  --load-balancer-arns $ALB_ARN \
  --region eu-west-1 \
  --query 'LoadBalancers[0].[LoadBalancerName,DNSName,State.Code,Scheme]' \
  --output table

# Test 21: Verify ALB target groups
AWS_PROFILE=Tebogo-sit aws elbv2 describe-target-groups \
  --load-balancer-arn $ALB_ARN \
  --region eu-west-1 \
  --query 'TargetGroups[*].[TargetGroupName,Protocol,Port,HealthCheckPath]' \
  --output table

# Test 22: Verify target health
TARGET_GROUP_ARN=$(AWS_PROFILE=Tebogo-sit aws elbv2 describe-target-groups \
  --load-balancer-arn $ALB_ARN \
  --region eu-west-1 \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

AWS_PROFILE=Tebogo-sit aws elbv2 describe-target-health \
  --target-group-arn $TARGET_GROUP_ARN \
  --region eu-west-1 \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Reason]' \
  --output table

# Test 23: Test ALB endpoint
ALB_DNS=$(AWS_PROFILE=Tebogo-sit aws elbv2 describe-load-balancers \
  --load-balancer-arns $ALB_ARN \
  --region eu-west-1 \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

curl -I http://$ALB_DNS
```

#### Multi-Tenant Isolation Validation
```bash
# Test 24: Verify tenant-specific security groups
AWS_PROFILE=Tebogo-sit aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Tenant,Values=*" \
  --region eu-west-1 \
  --query 'SecurityGroups[*].[GroupId,GroupName,Tags[?Key==`Tenant`].Value|[0]]' \
  --output table

# Test 25: Verify tenant-specific EFS access points
AWS_PROFILE=Tebogo-sit aws efs describe-access-points \
  --file-system-id $EFS_ID \
  --region eu-west-1 \
  --query 'AccessPoints[*].[Name,Tags[?Key==`Tenant`].Value|[0],PosixUser.Uid]' \
  --output table

# Test 26: Verify tenant metadata in DynamoDB
AWS_PROFILE=Tebogo-sit aws dynamodb scan \
  --table-name tenants-sit \
  --region eu-west-1 \
  --query 'Items[*].[tenant_id.S,name.S,status.S]' \
  --output table
```

#### Monitoring Validation
```bash
# Test 27: Verify CloudWatch Log Groups
AWS_PROFILE=Tebogo-sit aws logs describe-log-groups \
  --region eu-west-1 \
  --log-group-name-prefix "/aws/ecs/bbws-sit" \
  --query 'logGroups[*].[logGroupName,creationTime]' \
  --output table

# Test 28: Verify CloudWatch Alarms
AWS_PROFILE=Tebogo-sit aws cloudwatch describe-alarms \
  --region eu-west-1 \
  --alarm-name-prefix "bbws-sit" \
  --query 'MetricAlarms[*].[AlarmName,StateValue,MetricName]' \
  --output table

# Test 29: Verify SNS topics for alerting
AWS_PROFILE=Tebogo-sit aws sns list-topics \
  --region eu-west-1 \
  --query 'Topics[?contains(TopicArn, `bbws-sit`)]' \
  --output table
```

---

## Phase 2: SIT Validation (Jan 14-31)

### Week 1: Integration Testing (Jan 14-17)
- [ ] Test WordPress deployment to ECS
- [ ] Test database connectivity from ECS tasks
- [ ] Test Redis connectivity from ECS tasks
- [ ] Test EFS mounting in ECS tasks
- [ ] Verify WordPress media upload to S3
- [ ] Test ALB routing to ECS tasks
- [ ] Test health check functionality
- [ ] Verify CloudWatch logging
- [ ] Test auto-scaling policies (scale out/in)
- [ ] Verify service discovery (if configured)

### Week 2: Multi-Tenant Testing (Jan 18-21)
- [ ] **CRITICAL**: Test tenant isolation
  - Deploy WordPress for Tenant A
  - Deploy WordPress for Tenant B
  - Verify Tenant A cannot access Tenant B resources
  - Verify Tenant A database isolated from Tenant B database
  - Verify Tenant A EFS access point isolated from Tenant B
  - Verify Tenant A security groups prevent access to Tenant B
- [ ] Test tenant onboarding workflow
  ```bash
  # Onboard new tenant
  ./scripts/onboard-tenant.sh --tenant-id test-tenant-001 --env sit

  # Verify tenant resources created
  AWS_PROFILE=Tebogo-sit aws ecs list-services --cluster bbws-ecs-sit
  AWS_PROFILE=Tebogo-sit aws rds describe-db-instances --filters "Name=tag:Tenant,Values=test-tenant-001"
  AWS_PROFILE=Tebogo-sit aws efs describe-access-points --file-system-id $EFS_ID
  ```
- [ ] Test tenant offboarding workflow
- [ ] Test tenant resource tagging
- [ ] Verify tenant billing isolation (cost allocation tags)
- [ ] Test tenant-specific custom domains

### Week 3: Performance Testing (Jan 22-24)
- [ ] Configure load testing tool (k6, JMeter)
- [ ] Test Aurora MySQL performance
  - Baseline: 1000 queries/sec
  - Stress test: Gradual increase to 5000 queries/sec
  - Monitor RDS CloudWatch metrics
- [ ] Test Redis cache performance
  - Cache hit ratio target: >90%
  - Latency target: <1ms
- [ ] Test ECS Fargate auto-scaling
  - Load test: 100 concurrent WordPress requests
  - Verify ECS tasks scale from 2 to 10
  - Verify scale-in after load decreases
- [ ] Test ALB performance
  - Request rate: 1000 req/sec
  - Monitor ALB CloudWatch metrics
  - Verify connection draining
- [ ] Test EFS performance
  - Concurrent file operations
  - Monitor EFS CloudWatch metrics
- [ ] Document performance baselines

### Week 4: Security Scanning (Jan 25-26)
- [ ] Run container vulnerability scan (Amazon ECR scanning)
- [ ] Verify secrets management (Secrets Manager, no hardcoded credentials)
- [ ] Test IAM least privilege (task roles, execution roles)
- [ ] Verify VPC security groups (no overly permissive rules)
- [ ] Test RDS security (encryption at rest, in-transit)
- [ ] Test Redis security (encryption, AUTH token)
- [ ] Test EFS encryption
- [ ] Verify ALB security (HTTPS listener, security policies)
- [ ] Run AWS Security Hub scan
- [ ] Run AWS Inspector scan
- [ ] Test CloudTrail logging enabled

### Week 5: Final Validation (Jan 27-31)
- [ ] Re-run all validation tests
- [ ] Verify all 58 Terraform files deployed successfully
- [ ] Verify Terraform state consistency
- [ ] Cost analysis completed
- [ ] Security compliance verified
- [ ] Performance benchmarks documented
- [ ] Multi-tenant isolation validated
- [ ] Tenant onboarding/offboarding procedures documented
- [ ] SIT sign-off meeting
- [ ] SIT approval gate passed

---

## Phase 3: PROD Promotion (Feb 24, 2026)

### Pre-Deployment Checklist (Feb 20-23)

#### Production Readiness
- [ ] All SIT tests passing
- [ ] SIT sign-off obtained (Gate 4)
- [ ] Performance meets SLA requirements
- [ ] Security scan clean (no high/critical issues)
- [ ] Multi-tenant isolation validated
- [ ] Tenant onboarding procedures validated
- [ ] Disaster recovery plan documented
- [ ] Backup/restore procedures validated
- [ ] Rollback procedure documented (complex for ECS)

#### PROD Environment Verification
- [ ] AWS SSO login to PROD account (093646564004)
- [ ] Verify AWS profile: `AWS_PROFILE=Tebogo-prod aws sts get-caller-identity`
- [ ] Confirm PROD primary region: af-south-1
- [ ] Confirm PROD DR region: eu-west-1
- [ ] Verify IAM permissions for all services in both regions
- [ ] Check quota limits in both regions

#### Multi-Region DR Setup
- [ ] **CRITICAL**: Document multi-region active-passive DR strategy
  - Primary: af-south-1 (active)
  - DR: eu-west-1 (standby)
  - Aurora Global Database for cross-region replication
  - EFS replication to DR region (AWS Backup or DataSync)
  - ALB in DR region (ready but not active)
  - Route53 health checks for failover
- [ ] Document failover procedure (af-south-1 → eu-west-1)
- [ ] Document failback procedure (eu-west-1 → af-south-1)
- [ ] Plan for RTO (Recovery Time Objective): <1 hour
- [ ] Plan for RPO (Recovery Point Objective): <15 minutes

#### Change Management
- [ ] Change request submitted and approved
- [ ] Maintenance window scheduled (recommended: 2-4 hour window)
- [ ] Customer notification sent (planned maintenance)
- [ ] Rollback team on standby
- [ ] Communication channels ready (Slack, email, status page)
- [ ] Incident response team briefed
- [ ] Database team on standby
- [ ] Network team on standby

#### Terraform State Management
- [ ] **CRITICAL**: Verify Terraform state backend for PROD
- [ ] Verify state lock table exists
- [ ] Document state file location
- [ ] Plan for state file backup before deployment

### Deployment Steps (Feb 24, 2:00 PM)

#### Step 1: Pre-deployment Verification
```bash
# Verify SIT is stable
AWS_PROFILE=Tebogo-sit aws ecs describe-clusters --clusters bbws-ecs-sit --region eu-west-1

# Verify PROD access (primary region)
AWS_PROFILE=Tebogo-prod aws sts get-caller-identity --region af-south-1

# Verify PROD access (DR region)
AWS_PROFILE=Tebogo-prod aws sts get-caller-identity --region eu-west-1

# Verify no existing ECS cluster in PROD
AWS_PROFILE=Tebogo-prod aws ecs list-clusters --region af-south-1
AWS_PROFILE=Tebogo-prod aws ecs list-clusters --region eu-west-1
```

#### Step 2: Terraform State Initialization
```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform

# Initialize Terraform with PROD backend
terraform init -backend-config="key=ecs-terraform/prod/terraform.tfstate"

# Create workspace for PROD
terraform workspace new prod || terraform workspace select prod
terraform workspace list
```

#### Step 3-15: Deploy Infrastructure (Same as SIT, but for PROD)
Follow the same phased deployment approach as SIT:
- Phase 1: Network infrastructure (VPC, subnets, security groups)
- Phase 2: Database layer (Aurora MySQL, ElastiCache Redis)
- Phase 3: Storage layer (EFS)
- Phase 4: ECS infrastructure (cluster, ALB, services)
- Phase 5: Monitoring (CloudWatch, SNS)

**CRITICAL**: Deploy to af-south-1 (primary region) first.

#### Step 16: Deploy DR Region (eu-west-1)
```bash
# After primary region deployment, deploy DR region

# Aurora Global Database (cross-region replication)
AWS_PROFILE=Tebogo-prod aws rds create-global-cluster \
  --global-cluster-identifier bbws-aurora-global \
  --source-db-cluster-identifier arn:aws:rds:af-south-1:093646564004:cluster:bbws-aurora-prod \
  --region af-south-1

AWS_PROFILE=Tebogo-prod aws rds create-db-cluster \
  --db-cluster-identifier bbws-aurora-prod-dr \
  --engine aurora-mysql \
  --global-cluster-identifier bbws-aurora-global \
  --region eu-west-1

# Deploy ECS cluster in DR region (standby)
terraform apply -target=module.ecs_cluster_dr -var="region=eu-west-1"

# Configure EFS replication to DR region
AWS_PROFILE=Tebogo-prod aws backup create-backup-plan \
  --backup-plan file://efs-dr-backup-plan.json \
  --region af-south-1
```

### Post-Deployment Validation (Feb 25, 11:00 AM - 3:00 PM)

#### Primary Region Validation (af-south-1)
Follow the same validation tests as SIT, but for PROD in af-south-1.

#### DR Region Validation (eu-west-1)
```bash
# Verify Aurora Global Database replication
AWS_PROFILE=Tebogo-prod aws rds describe-global-clusters \
  --global-cluster-identifier bbws-aurora-global \
  --region af-south-1 \
  --query 'GlobalClusters[0].[GlobalClusterMembers[*].[DBClusterArn,IsWriter]]' \
  --output table

# Verify replication lag
AWS_PROFILE=Tebogo-prod aws rds describe-db-clusters \
  --db-cluster-identifier bbws-aurora-prod-dr \
  --region eu-west-1 \
  --query 'DBClusters[0].GlobalWriteForwardingStatus'

# Verify ECS cluster in DR region (should be standby)
AWS_PROFILE=Tebogo-prod aws ecs describe-clusters \
  --clusters bbws-ecs-prod-dr \
  --region eu-west-1
```

#### DR Failover Test (Non-production)
```bash
# Test failover to DR region (USE WITH EXTREME CAUTION)
# This should be tested in a separate DR testing window, NOT during production deployment

# 1. Update Route53 health check to point to DR region ALB
# 2. Promote Aurora DR cluster to primary
# 3. Scale up ECS services in DR region
# 4. Verify application availability in DR region
# 5. Fail back to primary region
```

#### Production Monitoring (First 24 Hours)
- [ ] Monitor every 15 minutes for first 6 hours
- [ ] Check CloudWatch metrics every 30 minutes
- [ ] Review CloudWatch alarms hourly
- [ ] Monitor ECS task health
- [ ] Monitor Aurora CPU, connections, replication lag
- [ ] Monitor Redis cache hit ratio
- [ ] Monitor EFS throughput
- [ ] Monitor ALB request count, latency, errors
- [ ] Verify backups executing hourly
- [ ] Check cost metrics

#### Production Monitoring (First Week)
- [ ] Daily health checks
- [ ] Weekly performance review
- [ ] Cost monitoring (ECS, RDS, ElastiCache, EFS, ALB, data transfer)
- [ ] Aurora replication lag monitoring
- [ ] EFS replication monitoring
- [ ] Tenant isolation validation
- [ ] Incident tracking

---

## Rollback Procedures

### SIT Rollback
```bash
# CRITICAL WARNING: ECS infrastructure rollback is complex
# Terraform destroy will delete ALL resources including databases

# Option 1: Rollback specific module (safer)
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform
terraform workspace select sit
AWS_PROFILE=Tebogo-sit terraform destroy -target=module.ecs_services
AWS_PROFILE=Tebogo-sit terraform destroy -target=module.ecs_cluster

# Option 2: Restore database from backup (if data corruption)
AWS_PROFILE=Tebogo-sit aws rds restore-db-cluster-to-point-in-time \
  --db-cluster-identifier bbws-aurora-sit-restored \
  --source-db-cluster-identifier bbws-aurora-sit \
  --restore-to-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --region eu-west-1
```

### PROD Rollback (CRITICAL)
```bash
# CRITICAL WARNING: PROD rollback is extremely risky
# Contact entire operations team before proceeding

# Option 1: Failover to DR region (recommended if primary region has critical issue)
# 1. Update Route53 to point to DR region ALB
# 2. Promote Aurora DR cluster to primary
# 3. Scale up ECS services in DR region
# 4. Verify application availability

# Option 2: Restore Aurora from backup
AWS_PROFILE=Tebogo-prod aws rds restore-db-cluster-to-point-in-time \
  --db-cluster-identifier bbws-aurora-prod-restored \
  --source-db-cluster-identifier bbws-aurora-prod \
  --restore-to-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --region af-south-1

# Option 3: Rollback ECS services to previous task definition
AWS_PROFILE=Tebogo-prod aws ecs update-service \
  --cluster bbws-ecs-prod \
  --service bbws-wordpress-prod \
  --task-definition bbws-wordpress-prod:<previous-revision> \
  --region af-south-1
```

### Rollback Triggers
- ECS service deployment failures
- Aurora database connection failures
- Redis connection failures
- EFS mounting failures
- ALB health check failures
- Critical security vulnerability detected
- Data corruption
- Performance degradation >50%
- Customer escalation
- Multi-tenant isolation breach

---

## Success Criteria

### SIT Success
- [ ] All 58 Terraform files deployed successfully
- [ ] VPC and subnets created (multi-AZ)
- [ ] Aurora MySQL cluster active (multi-AZ)
- [ ] ElastiCache Redis cluster active
- [ ] EFS file system created with mount targets
- [ ] ECS cluster created with Fargate capacity provider
- [ ] ALB created with target groups
- [ ] ECS services running (desired count = running count)
- [ ] Health checks passing
- [ ] CloudWatch monitoring configured
- [ ] Multi-tenant isolation validated
- [ ] Performance baseline established

### PROD Success
- [ ] All infrastructure deployed in af-south-1
- [ ] DR infrastructure deployed in eu-west-1
- [ ] Aurora Global Database replicating (<15 min lag)
- [ ] EFS replication configured
- [ ] ECS services healthy in primary region
- [ ] ALB routing traffic correctly
- [ ] Health checks passing (100%)
- [ ] No customer-impacting issues
- [ ] 72-hour soak period clean
- [ ] Multi-tenant isolation validated
- [ ] DR failover tested successfully (in separate window)
- [ ] Product Owner and Operations Lead sign-off

---

## Monitoring & Alerts

### CloudWatch Alarms
| Alarm | Threshold | Action |
|-------|-----------|--------|
| ECS Service CPU | > 80% | SNS alert to DevOps + auto-scale |
| ECS Service Memory | > 80% | SNS alert to DevOps + auto-scale |
| Aurora CPU | > 80% | SNS alert to DBA |
| Aurora Connections | > 900 (max 1000) | SNS alert to DBA |
| Aurora Replication Lag | > 15 minutes | SNS alert to DBA (CRITICAL) |
| Redis CPU | > 80% | SNS alert to DevOps |
| Redis Memory | > 80% | SNS alert to DevOps |
| EFS Throughput | > 80% | SNS alert to DevOps |
| ALB 5xx Errors | > 1% | SNS alert to DevOps (CRITICAL) |
| ALB Target Health | < 50% healthy | SNS alert to DevOps (CRITICAL) |
| ALB Response Time | p95 > 3s | SNS alert to DevOps |

### CloudWatch Dashboards
- Create: `ecs-terraform-sit-dashboard`
- Create: `ecs-terraform-prod-dashboard`
- Widgets:
  - ECS cluster metrics (CPU, memory, task count)
  - Aurora metrics (CPU, connections, latency, replication lag)
  - Redis metrics (CPU, memory, cache hits)
  - EFS metrics (throughput, IOPS, connections)
  - ALB metrics (requests, latency, errors, healthy targets)
  - Multi-tenant metrics (per-tenant resource usage)

---

## Contacts & Escalation

| Role | Contact | Availability |
|------|---------|--------------|
| DevOps Engineer | TBD | Primary deployer |
| DBA | TBD | Database and Aurora Global Database |
| Network Engineer | TBD | VPC, security groups, ALB |
| Tech Lead | TBD | Approval & escalation |
| Product Owner | TBD | Final sign-off |
| On-Call SRE | TBD | 24/7 incident response |
| AWS Support | TBD | Critical escalations (TAM) |
| Security Lead | TBD | Multi-tenant isolation, security |

---

## Documentation

### Deployment Artifacts
- [ ] Deployment runbook (this document)
- [ ] All 58 Terraform files documented
- [ ] Terraform state file backed up
- [ ] Multi-tenant isolation documentation
- [ ] Tenant onboarding runbook
- [ ] Tenant offboarding runbook
- [ ] Aurora Global Database replication documentation
- [ ] EFS replication documentation
- [ ] DR failover runbook
- [ ] DR failback runbook
- [ ] Performance benchmarks
- [ ] Cost analysis

### Post-Deployment
- [ ] Deployment retrospective notes
- [ ] Lessons learned document
- [ ] Updated architecture diagrams (multi-region setup)
- [ ] Incident reports (if any)
- [ ] Multi-tenant isolation validation report
- [ ] Performance tuning guide
- [ ] Cost optimization recommendations

---

## Change Log

| Date | Phase | Status | Notes |
|------|-------|--------|-------|
| 2026-01-07 | Planning | 📋 Complete | Promotion plan created |
| 2026-01-13 | SIT Deploy | ⏳ Scheduled | Target deployment (Wave 2) |
| 2026-02-24 | PROD Deploy | 🔵 Planned | Target deployment (Wave 2) |

---

**Next Steps:**
1. Review and approve this plan (CRITICAL: DBA, Network, Security review required)
2. Complete pre-deployment checklist
3. MUST wait for DynamoDB and S3 schemas in SIT first
4. Schedule SIT deployment for Jan 13 (after dynamodb_schemas and s3_schemas)
5. Execute deployment following phased approach
6. Validate each phase before proceeding

**Plan Status:** 📋 READY FOR REVIEW
**Approval Required By:** Tech Lead, DevOps Lead, DBA, Network Engineer, Security Lead, Product Owner
**Wave:** Wave 2 (Infrastructure Foundation)
**Dependencies:** dynamodb_schemas, s3_schemas (MUST be in SIT first)
**CRITICAL:** Multi-tenant isolation MUST be validated
**CRITICAL:** Terraform state management with 58 files requires careful planning
**CRITICAL:** Aurora Global Database for PROD DR
