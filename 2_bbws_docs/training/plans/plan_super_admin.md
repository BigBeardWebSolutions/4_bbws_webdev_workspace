# Super Admin Training Plan

**Parent Plan**: [master_plan.md](./master_plan.md)
**Target Role**: Platform Super Admin
**Total Duration**: ~18 hours
**Status**: PENDING

---

## Overview

The Super Admin training module covers comprehensive cluster-level operations including infrastructure provisioning, validation, security, performance, disaster recovery, cost management, and operational validation through practical exercises.

---

## Submodule SA-01: Cluster Creation and Infrastructure

**Duration**: 2 hours
**Status**: PENDING

### Learning Objectives
- Understand multi-tenant ECS Fargate architecture
- Deploy cluster infrastructure using Terraform
- Validate all cluster components are operational

### Prerequisites
- AWS CLI configured for DEV environment
- Terraform v1.0+ installed
- Understanding of VPC, ECS, RDS, EFS, ALB concepts

### Practical Exercises

#### Exercise SA-01-1: Environment Validation
```bash
# Step 1: Verify AWS credentials
AWS_PROFILE=Tebogo-dev aws sts get-caller-identity

# Expected output includes:
# Account: "536580886816"

# Step 2: Verify region
AWS_PROFILE=Tebogo-dev aws configure get region
# Expected: af-south-1 or eu-west-1
```

#### Exercise SA-01-2: Terraform Initialization
```bash
cd terraform/

# Step 1: Initialize Terraform
terraform init

# Step 2: Review plan
terraform plan -var="environment=dev"

# Step 3: Document resource count
# Expected: ~40-60 resources to create
```

#### Exercise SA-01-3: Cluster Deployment
```bash
# Step 1: Apply Terraform (with approval)
terraform apply -var="environment=dev"

# Step 2: Capture outputs
terraform output > ../training/outputs_dev.txt

# Step 3: Validate outputs include:
# - vpc_id
# - ecs_cluster_name
# - rds_endpoint
# - efs_id
# - alb_dns_name
```

### Validation Checklist
- [ ] AWS credentials verified for correct account
- [ ] Terraform init completed successfully
- [ ] Terraform plan shows expected resources
- [ ] Terraform apply completed without errors
- [ ] All outputs captured and documented

### Screenshot Requirements
1. `aws sts get-caller-identity` output
2. Terraform plan summary
3. Terraform apply complete message
4. Terraform outputs

---

## Submodule SA-02: Cluster Validation and Health Checks

**Duration**: 1 hour
**Status**: PENDING

### Learning Objectives
- Validate all cluster components are healthy
- Understand health check mechanisms
- Generate cluster health reports

### Practical Exercises

#### Exercise SA-02-1: ECS Cluster Validation
```bash
AWS_PROFILE=Tebogo-dev aws ecs describe-clusters \
  --clusters $(terraform output -raw ecs_cluster_name) \
  --region eu-west-1

# Expected: status = "ACTIVE"
```

#### Exercise SA-02-2: RDS Health Check
```bash
AWS_PROFILE=Tebogo-dev aws rds describe-db-instances \
  --db-instance-identifier sit-mysql \
  --query 'DBInstances[0].DBInstanceStatus' \
  --region eu-west-1

# Expected: "available"
```

#### Exercise SA-02-3: EFS Health Check
```bash
AWS_PROFILE=Tebogo-dev aws efs describe-file-systems \
  --file-system-id $(terraform output -raw efs_id) \
  --query 'FileSystems[0].LifeCycleState' \
  --region eu-west-1

# Expected: "available"
```

#### Exercise SA-02-4: ALB Health Check
```bash
# Get ALB target group health
AWS_PROFILE=Tebogo-dev aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw alb_target_group_arn) \
  --region eu-west-1
```

### Validation Checklist
- [ ] ECS cluster status is ACTIVE
- [ ] RDS instance status is available
- [ ] EFS filesystem status is available
- [ ] ALB has healthy targets (if tenants deployed)
- [ ] All security groups have expected rules

---

## Submodule SA-03: Security Configuration and Hardening

**Duration**: 2 hours
**Status**: PENDING

### Learning Objectives
- Review and validate security group configurations
- Understand IAM role permissions
- Verify encryption settings
- Audit Secrets Manager usage

### Practical Exercises

#### Exercise SA-03-1: Security Group Audit
```bash
# List all security groups in VPC
AWS_PROFILE=Tebogo-dev aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)" \
  --query 'SecurityGroups[*].[GroupId,GroupName,Description]' \
  --output table \
  --region eu-west-1
```

#### Exercise SA-03-2: Verify ECS to RDS Connectivity Rules
```bash
# Check security group rules for database access
AWS_PROFILE=Tebogo-dev aws ec2 describe-security-group-rules \
  --filters "Name=group-id,Values=$(terraform output -raw rds_security_group_id)" \
  --region eu-west-1
```

#### Exercise SA-03-3: Encryption Verification
```bash
# Verify RDS encryption
AWS_PROFILE=Tebogo-dev aws rds describe-db-instances \
  --db-instance-identifier sit-mysql \
  --query 'DBInstances[0].StorageEncrypted' \
  --region eu-west-1
# Expected: true

# Verify EFS encryption
AWS_PROFILE=Tebogo-dev aws efs describe-file-systems \
  --file-system-id $(terraform output -raw efs_id) \
  --query 'FileSystems[0].Encrypted' \
  --region eu-west-1
# Expected: true
```

#### Exercise SA-03-4: Secrets Manager Audit
```bash
# List all secrets
AWS_PROFILE=Tebogo-dev aws secretsmanager list-secrets \
  --query 'SecretList[*].[Name,CreatedDate]' \
  --output table \
  --region eu-west-1
```

### Security Hardening Checklist
- [ ] RDS not publicly accessible
- [ ] EFS encrypted at rest
- [ ] RDS storage encrypted
- [ ] Security groups follow least privilege
- [ ] No hardcoded credentials in Terraform
- [ ] Secrets stored in Secrets Manager
- [ ] VPC flow logs enabled (optional)

---

## Submodule SA-04: Performance Monitoring and Tuning

**Duration**: 1.5 hours
**Status**: PENDING

### Learning Objectives
- Monitor ECS task performance metrics
- Analyze RDS performance
- Understand CloudWatch metrics
- Tune resource allocations

### Practical Exercises

#### Exercise SA-04-1: ECS Container Metrics
```bash
# Get ECS service metrics
AWS_PROFILE=Tebogo-dev aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ClusterName,Value=$(terraform output -raw ecs_cluster_name) \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Average \
  --region eu-west-1
```

#### Exercise SA-04-2: RDS Performance Insights
```bash
# Get RDS CPU utilization
AWS_PROFILE=Tebogo-dev aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=sit-mysql \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Average \
  --region eu-west-1
```

#### Exercise SA-04-3: EFS Throughput Analysis
```bash
# Get EFS throughput
AWS_PROFILE=Tebogo-dev aws cloudwatch get-metric-statistics \
  --namespace AWS/EFS \
  --metric-name TotalIOBytes \
  --dimensions Name=FileSystemId,Value=$(terraform output -raw efs_id) \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Sum \
  --region eu-west-1
```

### Performance Targets

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| ECS CPU | <70% avg | >80% |
| ECS Memory | <80% avg | >90% |
| RDS CPU | <60% avg | >70% |
| RDS Connections | <80% of max | >90% |
| EFS Burst Credits | >50% | <20% |

---

## Submodule SA-05: Disaster Recovery Operations

**Duration**: 2 hours
**Status**: PENDING

### Learning Objectives
- Understand DR architecture (Active-Passive)
- Check DR readiness and replication status
- Practice failover assessment (not execution)
- Understand failback procedures

### Practical Exercises

#### Exercise SA-05-1: DR Status Check
```bash
# Check S3 cross-region replication status
AWS_PROFILE=Tebogo-dev aws s3api get-bucket-replication \
  --bucket bbws-backups-dev \
  --region eu-west-1 2>/dev/null || echo "No replication configured"

# Check DynamoDB global tables (if configured)
AWS_PROFILE=Tebogo-dev aws dynamodb describe-global-table \
  --global-table-name tenant-state \
  --region eu-west-1 2>/dev/null || echo "No global table configured"
```

#### Exercise SA-05-2: Route53 Health Check Status
```bash
# List health checks
AWS_PROFILE=Tebogo-dev aws route53 list-health-checks \
  --query 'HealthChecks[*].[Id,HealthCheckConfig.FullyQualifiedDomainName,HealthCheckConfig.Type]' \
  --output table
```

#### Exercise SA-05-3: DR Readiness Assessment
```bash
# Check primary region resources
echo "=== Primary Region (af-south-1) Status ==="
AWS_PROFILE=Tebogo-dev aws ecs describe-clusters \
  --clusters sit-cluster \
  --query 'clusters[0].status' \
  --region af-south-1 2>/dev/null || echo "Not available"

# Check DR region resources
echo "=== DR Region (eu-west-1) Status ==="
AWS_PROFILE=Tebogo-dev aws ecs describe-clusters \
  --clusters sit-cluster \
  --query 'clusters[0].status' \
  --region eu-west-1 2>/dev/null || echo "Not available"
```

### DR Runbook Summary

| Phase | Action | Owner | Est. Time |
|-------|--------|-------|-----------|
| Detection | Monitor alerts for region failure | Monitoring | 0-5 min |
| Assessment | Check DR readiness, replication lag | Super Admin | 5-10 min |
| Decision | Approve failover (incident ticket) | Management | 10-30 min |
| Failover | Execute failover playbook | Super Admin | 30-60 min |
| Validation | Verify all tenants accessible | Tenant Admin | 30-60 min |
| Communication | Notify stakeholders | All | Ongoing |

---

## Submodule SA-06: Cost Management and Budgets

**Duration**: 1.5 hours
**Status**: PENDING

### Learning Objectives
- Generate cost reports by service
- Create and manage AWS Budgets
- Configure budget alerts
- Understand cost allocation tags

### Practical Exercises

#### Exercise SA-06-1: 30-Day Cost Breakdown
```bash
# Get costs by service for last 30 days
AWS_PROFILE=Tebogo-dev aws ce get-cost-and-usage \
  --time-period Start=$(date -v-30d +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE \
  --region us-east-1
```

#### Exercise SA-06-2: Budget Status Check
```bash
# List all budgets
AWS_PROFILE=Tebogo-dev aws budgets describe-budgets \
  --account-id 536580886816 \
  --query 'Budgets[*].[BudgetName,BudgetLimit.Amount,CalculatedSpend.ActualSpend.Amount]' \
  --output table
```

#### Exercise SA-06-3: Cost Allocation by Tenant
```bash
# Get costs by tenant_id tag
AWS_PROFILE=Tebogo-dev aws ce get-cost-and-usage \
  --time-period Start=$(date -v-7d +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=TAG,Key=tenant_id \
  --region us-east-1
```

### Budget Configuration Reference

| Environment | Monthly Budget | Alert Thresholds |
|-------------|---------------|------------------|
| DEV | $200 | 50%, 80%, 100% |
| SIT | $400 | 80%, 100% |
| PROD | $1,000 | 80%, 90%, 100%, 110% |

---

## Submodule SA-07: Operations Validation - Adding Tenants

**Duration**: 1 hour
**Status**: PENDING

### Learning Objectives
- Add a new tenant to the cluster
- Configure tenant DNS subdomain
- Validate tenant accessibility

### Practical Exercises

#### Exercise SA-07-1: Add Tenant with DNS
```bash
# Step 1: Create tenant database via ECS task
# (Reference tenant provisioning script)

# Step 2: Create EFS access point for tenant
AWS_PROFILE=Tebogo-sit aws efs create-access-point \
  --file-system-id fs-xxx \
  --posix-user Uid=1001,Gid=1001 \
  --root-directory "Path=/tenant-test,CreationInfo={OwnerUid=1001,OwnerGid=1001,Permissions=755}" \
  --tags Key=tenant_id,Value=tenant-test \
  --region eu-west-1

# Step 3: Create DNS record
AWS_PROFILE=Tebogo-sit aws route53 change-resource-record-sets \
  --hosted-zone-id Z0XXXXXXXXX \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "tenant-test.wpsit.kimmyai.io",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "dxxxxxxxxx.cloudfront.net",
          "EvaluateTargetHealth": false
        }
      }
    }]
  }'
```

#### Exercise SA-07-2: Validate Tenant DNS
```bash
# Test DNS resolution
dig tenant-test.wpsit.kimmyai.io

# Test HTTP access
curl -I https://tenant-test.wpsit.kimmyai.io/wp-admin/
```

### Validation Checklist
- [ ] Tenant database created
- [ ] EFS access point created
- [ ] ECS service deployed
- [ ] ALB target group healthy
- [ ] DNS record resolving
- [ ] HTTPS accessible

---

## Submodule SA-08: Operations Validation - Bulk Tenant Operations

**Duration**: 1.5 hours
**Status**: PENDING

### Learning Objectives
- Add multiple tenants (10+) programmatically
- Validate bulk deployment
- Monitor resource usage during bulk operations

### Practical Exercises

#### Exercise SA-08-1: Add 10 Tenants
```bash
# Using provisioning script
for i in {1..10}; do
  python3 scripts/provision_tenant.py \
    --tenant-id tenant-$i \
    --environment sit \
    --priority $((100 + i))
done
```

#### Exercise SA-08-2: Validate All 10 Tenants
```bash
# List all ECS services
AWS_PROFILE=Tebogo-sit aws ecs list-services \
  --cluster sit-cluster \
  --region eu-west-1

# Check all services running
AWS_PROFILE=Tebogo-sit aws ecs describe-services \
  --cluster sit-cluster \
  --services $(aws ecs list-services --cluster sit-cluster --query 'serviceArns[]' --output text) \
  --query 'services[*].[serviceName,runningCount,desiredCount]' \
  --output table \
  --region eu-west-1
```

#### Exercise SA-08-3: Resource Usage Check
```bash
# Check RDS connections
AWS_PROFILE=Tebogo-sit aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=sit-mysql \
  --start-time $(date -u -v-15M +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Maximum \
  --region eu-west-1
```

---

## Submodule SA-09: Stress Testing and Load Validation

**Duration**: 2 hours
**Status**: PENDING

### Learning Objectives
- Perform load testing on tenant sites
- Monitor system behavior under stress
- Identify performance bottlenecks
- Validate resource limits

### Practical Exercises

#### Exercise SA-09-1: Simple Load Test with Apache Bench
```bash
# Install Apache Bench (if not available)
# macOS: brew install httpd
# Linux: apt install apache2-utils

# Run load test - 100 requests, 10 concurrent
ab -n 100 -c 10 https://tenant-1.wpsit.kimmyai.io/

# Run sustained load test - 1000 requests, 50 concurrent
ab -n 1000 -c 50 -k https://tenant-1.wpsit.kimmyai.io/
```

#### Exercise SA-09-2: Monitor During Stress
```bash
# In separate terminal, watch ECS metrics
watch -n 5 "AWS_PROFILE=Tebogo-sit aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ClusterName,Value=sit-cluster \
  --start-time \$(date -u -v-5M +%Y-%m-%dT%H:%M:%SZ) \
  --end-time \$(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Average \
  --region eu-west-1 \
  --query 'Datapoints[0].Average'"
```

#### Exercise SA-09-3: Identify Bottlenecks
```bash
# Check RDS Performance
AWS_PROFILE=Tebogo-sit aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=sit-mysql \
  --start-time $(date -u -v-15M +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Maximum \
  --region eu-west-1

# Check ALB request count
AWS_PROFILE=Tebogo-sit aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name RequestCount \
  --dimensions Name=LoadBalancer,Value=app/sit-alb/xxxxxxxxx \
  --start-time $(date -u -v-15M +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum \
  --region eu-west-1
```

---

## Submodule SA-10: Autoscaling Configuration and Validation

**Duration**: 1.5 hours
**Status**: PENDING

### Learning Objectives
- Configure ECS service autoscaling
- Test autoscaling triggers
- Validate scale-out and scale-in behavior

### Practical Exercises

#### Exercise SA-10-1: Review Current Autoscaling Configuration
```bash
# Check if autoscaling is configured
AWS_PROFILE=Tebogo-sit aws application-autoscaling describe-scalable-targets \
  --service-namespace ecs \
  --region eu-west-1

# Check scaling policies
AWS_PROFILE=Tebogo-sit aws application-autoscaling describe-scaling-policies \
  --service-namespace ecs \
  --region eu-west-1
```

#### Exercise SA-10-2: Configure Autoscaling (if not exists)
```bash
# Register scalable target
AWS_PROFILE=Tebogo-sit aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id service/sit-cluster/tenant-1-service \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 1 \
  --max-capacity 5 \
  --region eu-west-1

# Create scale-out policy (CPU > 70%)
AWS_PROFILE=Tebogo-sit aws application-autoscaling put-scaling-policy \
  --service-namespace ecs \
  --resource-id service/sit-cluster/tenant-1-service \
  --scalable-dimension ecs:service:DesiredCount \
  --policy-name cpu-scale-out \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{
    "TargetValue": 70.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
    },
    "ScaleOutCooldown": 60,
    "ScaleInCooldown": 300
  }' \
  --region eu-west-1
```

#### Exercise SA-10-3: Trigger and Validate Autoscaling
```bash
# Generate load to trigger scale-out
ab -n 5000 -c 100 -k https://tenant-1.wpsit.kimmyai.io/

# Watch task count change
watch -n 10 "AWS_PROFILE=Tebogo-sit aws ecs describe-services \
  --cluster sit-cluster \
  --services tenant-1-service \
  --query 'services[0].[runningCount,desiredCount]' \
  --output text \
  --region eu-west-1"
```

---

## Submodule SA-11: Per-Tenant Budget Actions and Cost Tracking

**Duration**: 1.5 hours
**Status**: PENDING

### Learning Objectives
- Configure per-tenant cost tracking with tags
- Set up tenant-specific budgets
- Configure budget actions for cost control
- Generate tenant cost allocation reports

### Practical Exercises

#### Exercise SA-11-1: Verify Tenant Tagging
```bash
# Check ECS service tags
AWS_PROFILE=Tebogo-sit aws ecs list-tags-for-resource \
  --resource-arn arn:aws:ecs:eu-west-1:815856636111:service/sit-cluster/tenant-1-service \
  --region eu-west-1

# Expected: tenant_id tag present
```

#### Exercise SA-11-2: Create Per-Tenant Budget
```bash
# Create budget for specific tenant
AWS_PROFILE=Tebogo-sit aws budgets create-budget \
  --account-id 815856636111 \
  --budget '{
    "BudgetName": "tenant-1-monthly-budget",
    "BudgetLimit": {
      "Amount": "50",
      "Unit": "USD"
    },
    "CostFilters": {
      "TagKeyValue": ["user:tenant_id$tenant-1"]
    },
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }' \
  --notifications-with-subscribers '[{
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 80,
      "ThresholdType": "PERCENTAGE"
    },
    "Subscribers": [{
      "SubscriptionType": "EMAIL",
      "Address": "admin@bigbeard.co.za"
    }]
  }]'
```

#### Exercise SA-11-3: Generate Tenant Cost Report
```bash
# Get costs grouped by tenant_id for last 30 days
AWS_PROFILE=Tebogo-sit aws ce get-cost-and-usage \
  --time-period Start=$(date -v-30d +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=TAG,Key=tenant_id \
  --region us-east-1 \
  --output json | jq '.ResultsByTime[0].Groups[] | {tenant: .Keys[0], cost: .Metrics.UnblendedCost.Amount}'
```

#### Exercise SA-11-4: Budget Action for Overspending
```bash
# Create budget action to stop resources when 100% exceeded
AWS_PROFILE=Tebogo-sit aws budgets create-budget-action \
  --account-id 815856636111 \
  --budget-name "tenant-1-monthly-budget" \
  --notification-type ACTUAL \
  --action-type "RUN_SSM_DOCUMENTS" \
  --action-threshold ActionThresholdType=PERCENTAGE,ActionThresholdValue=100 \
  --definition 'SsmActionDefinition={ActionSubType=STOP_EC2_INSTANCES,Region=eu-west-1,InstanceIds=[]}' \
  --execution-role-arn "arn:aws:iam::815856636111:role/BudgetActionRole" \
  --approval-model AUTOMATIC
```

### Cost Tracking Best Practices

| Practice | Implementation |
|----------|----------------|
| Tag All Resources | Apply `tenant_id` tag to all tenant-specific resources |
| Enable Cost Allocation Tags | Activate `tenant_id` in Cost Explorer |
| Monthly Chargeback Reports | Generate per-tenant cost reports monthly |
| Budget Alerts | 80%, 90%, 100% thresholds per tenant |
| Shared Cost Allocation | Split RDS, ALB costs proportionally |

---

## Completion Criteria

To complete the Super Admin training module:

1. Complete all 11 submodules (SA-01 to SA-11)
2. Submit screenshots for each exercise
3. Pass the Super Admin Knowledge Check Quiz (80%+)
4. Complete at least one full cluster creation in DEV
5. Successfully add and validate at least 5 tenants
6. Generate at least one cost report with tenant breakdown

---

## Next Steps

After completing Super Admin training:
1. Take the [Super Admin Quiz](../super_admin/quiz_super_admin.md)
2. Practice in SIT environment
3. Shadow PROD operations (read-only)
4. Complete Tenant Admin training for full certification

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-16 | Initial Super Admin training plan |
