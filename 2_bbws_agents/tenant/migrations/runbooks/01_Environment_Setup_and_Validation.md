# Phase 1: Environment Setup and Validation

**Phase**: 1 of 10
**Duration**: 0.5 days (4 hours)
**Responsible**: DevOps Engineer + Technical Lead
**Environment**: All (DEV, SIT, PROD)
**Dependencies**: None (Entry point)
**Status**: ✅ COMPLETE

---

## Phase Objectives

- Verify all three AWS environments (DEV, SIT, PROD) are operational and ready
- Confirm BBWS platform infrastructure health in each environment
- Validate tenant provisioning capabilities
- Ensure all required AWS services are accessible
- Verify team has necessary access and credentials
- Establish baseline metrics for each environment

---

## Prerequisites

- [ ] AWS CLI installed and configured locally
- [ ] AWS credentials for all three environments (Tebogo-dev, Tebogo-sit, Tebogo-prod)
- [ ] Terraform installed (v1.6+)
- [ ] Git access to infrastructure repository
- [ ] Team member access verified (AWS IAM permissions)
- [ ] Network connectivity to AWS regions (eu-west-1, af-south-1)

---

## Detailed Tasks

### Task 1.1: Verify AWS Credentials and Access

**Duration**: 30 minutes
**Responsible**: DevOps Engineer

**Steps**:

1. **Verify DEV environment credentials**:
```bash
export AWS_PROFILE=Tebogo-dev
aws sts get-caller-identity
```

**Expected Output**:
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "536580886816",
    "Arn": "arn:aws:iam::536580886816:user/tebogo"
}
```

2. **Verify SIT environment credentials**:
```bash
export AWS_PROFILE=Tebogo-sit
aws sts get-caller-identity
```

**Expected Output**:
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "815856636111",
    "Arn": "arn:aws:iam::815856636111:user/tebogo"
}
```

3. **Verify PROD environment credentials**:
```bash
export AWS_PROFILE=Tebogo-prod
aws sts get-caller-identity
```

**Expected Output**:
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "093646564004",
    "Arn": "arn:aws:iam::093646564004:user/tebogo"
}
```

4. **Test AWS CLI permissions**:
```bash
# Test each environment
for ENV in Tebogo-dev Tebogo-sit Tebogo-prod; do
    export AWS_PROFILE=$ENV
    echo "Testing $ENV..."
    aws ecs list-clusters
    aws rds describe-db-instances --query 'DBInstances[*].DBInstanceIdentifier'
    aws efs describe-file-systems --query 'FileSystems[*].FileSystemId'
    aws route53 list-hosted-zones --query 'HostedZones[*].Name'
done
```

**Troubleshooting**:
- **Issue**: "Unable to locate credentials"
  - **Solution**: Configure AWS credentials in `~/.aws/credentials` or use `aws configure --profile [profile-name]`

- **Issue**: "An error occurred (AccessDenied)"
  - **Solution**: Verify IAM user has necessary permissions for ECS, RDS, EFS, Route53, Secrets Manager

**Verification**:
- [ ] DEV account ID confirmed: 536580886816
- [ ] SIT account ID confirmed: 815856636111
- [ ] PROD account ID confirmed: 093646564004
- [ ] All AWS CLI commands executed successfully in all environments

---

### Task 1.2: Validate ECS Cluster Infrastructure (All Environments)

**Duration**: 45 minutes
**Responsible**: DevOps Engineer

**Steps for Each Environment** (repeat for DEV, SIT, PROD):

1. **List ECS clusters**:
```bash
export AWS_PROFILE=Tebogo-dev  # or Tebogo-sit, Tebogo-prod
export AWS_REGION=eu-west-1     # or af-south-1 for PROD

aws ecs list-clusters
```

**Expected Output**: Should show cluster ARN (e.g., `arn:aws:ecs:eu-west-1:536580886816:cluster/dev-cluster`)

2. **Check cluster status**:
```bash
aws ecs describe-clusters --clusters dev-cluster  # or sit-cluster, prod-cluster
```

**Expected Output**:
```json
{
    "clusters": [
        {
            "clusterName": "dev-cluster",
            "status": "ACTIVE",
            "registeredContainerInstancesCount": 0,
            "runningTasksCount": X,
            "pendingTasksCount": 0,
            "activeServicesCount": X
        }
    ]
}
```

3. **Verify ECS task execution role**:
```bash
aws iam get-role --role-name ecsTaskExecutionRole
```

4. **Check available capacity** (if using EC2, skip if Fargate-only):
```bash
aws ecs describe-clusters --clusters dev-cluster --include CAPACITY_PROVIDERS
```

**Troubleshooting**:
- **Issue**: Cluster not found
  - **Solution**: Verify cluster name is correct for environment (dev-cluster, sit-cluster, prod-cluster)

- **Issue**: Cluster status is not ACTIVE
  - **Solution**: Contact DevOps team, cluster may need recreation

**Verification**:
- [ ] DEV cluster: dev-cluster is ACTIVE
- [ ] SIT cluster: sit-cluster is ACTIVE
- [ ] PROD cluster: prod-cluster is ACTIVE
- [ ] ECS task execution role exists in all environments

---

### Task 1.3: Validate RDS Database Instance

**Duration**: 30 minutes
**Responsible**: Database Administrator

**Steps for Each Environment**:

1. **List RDS instances**:
```bash
export AWS_PROFILE=Tebogo-dev
export AWS_REGION=eu-west-1

aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Engine,Endpoint.Address]' --output table
```

**Expected Output**: Should show shared RDS instance (e.g., `bbws-dev-mysql`)

2. **Check RDS instance status**:
```bash
aws rds describe-db-instances --db-instance-identifier bbws-dev-mysql
```

**Expected Output**:
```json
{
    "DBInstances": [
        {
            "DBInstanceIdentifier": "bbws-dev-mysql",
            "DBInstanceStatus": "available",
            "Engine": "mysql",
            "EngineVersion": "8.0.x",
            "DBInstanceClass": "db.t3.medium",
            "Endpoint": {
                "Address": "bbws-dev-mysql.xxxxxx.eu-west-1.rds.amazonaws.com",
                "Port": 3306
            }
        }
    ]
}
```

3. **Test database connectivity** (from local machine or EC2):
```bash
# Get master credentials from Secrets Manager
aws secretsmanager get-secret-value --secret-id bbws/dev/rds/master --query SecretString --output text

# Test connection (replace with actual credentials)
mysql -h bbws-dev-mysql.xxxxxx.eu-west-1.rds.amazonaws.com -u admin -p -e "SELECT 1;"
```

4. **Check available storage**:
```bash
aws rds describe-db-instances --db-instance-identifier bbws-dev-mysql \
    --query 'DBInstances[0].[AllocatedStorage,StorageType,MaxAllocatedStorage]'
```

**Troubleshooting**:
- **Issue**: RDS instance not available
  - **Solution**: Wait for instance to become available, or contact DevOps if in "failed" state

- **Issue**: Cannot connect to database
  - **Solution**: Check security groups allow connection from your IP or VPC

**Verification**:
- [ ] DEV RDS instance is "available"
- [ ] SIT RDS instance is "available"
- [ ] PROD RDS instance is "available"
- [ ] Database connectivity test passed in all environments
- [ ] Sufficient storage available (>20 GB free)

---

### Task 1.4: Validate EFS File System

**Duration**: 30 minutes
**Responsible**: DevOps Engineer

**Steps for Each Environment**:

1. **List EFS file systems**:
```bash
export AWS_PROFILE=Tebogo-dev
export AWS_REGION=eu-west-1

aws efs describe-file-systems --query 'FileSystems[*].[FileSystemId,Name,LifeCycleState,NumberOfMountTargets]' --output table
```

**Expected Output**: Should show EFS file system (e.g., `fs-0a8f874402e3b9381`)

2. **Check EFS status**:
```bash
aws efs describe-file-systems --file-system-id fs-xxxxxxxxx
```

**Expected Output**:
```json
{
    "FileSystems": [
        {
            "FileSystemId": "fs-xxxxxxxxx",
            "LifeCycleState": "available",
            "SizeInBytes": {
                "Value": 6144,
                "Timestamp": "2026-01-09T12:00:00Z"
            },
            "NumberOfMountTargets": 2
        }
    ]
}
```

3. **Verify EFS mount targets** (should be in multiple AZs):
```bash
aws efs describe-mount-targets --file-system-id fs-xxxxxxxxx
```

4. **Check existing access points**:
```bash
aws efs describe-access-points --file-system-id fs-xxxxxxxxx --query 'AccessPoints[*].[AccessPointId,Name,RootDirectory.Path]' --output table
```

**Troubleshooting**:
- **Issue**: EFS not in "available" state
  - **Solution**: Wait for EFS to become available, check AWS console for errors

- **Issue**: No mount targets
  - **Solution**: Create mount targets in VPC subnets used by ECS

**Verification**:
- [ ] DEV EFS is "available" with mount targets
- [ ] SIT EFS is "available" with mount targets
- [ ] PROD EFS is "available" with mount targets
- [ ] Mount targets exist in multiple AZs (high availability)

---

### Task 1.5: Validate ALB and Route53 Configuration

**Duration**: 30 minutes
**Responsible**: DevOps Engineer

**Steps for Each Environment**:

1. **List Application Load Balancers**:
```bash
export AWS_PROFILE=Tebogo-dev
export AWS_REGION=eu-west-1

aws elbv2 describe-load-balancers --query 'LoadBalancers[*].[LoadBalancerName,State.Code,DNSName]' --output table
```

**Expected Output**: Should show ALB (e.g., `dev-alb`)

2. **Check ALB listeners**:
```bash
# Get ALB ARN first
ALB_ARN=$(aws elbv2 describe-load-balancers --names dev-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text)

# List listeners
aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN
```

**Expected**: HTTP listener on port 80 (or HTTPS on 443)

3. **List Route53 hosted zones**:
```bash
aws route53 list-hosted-zones --query 'HostedZones[*].[Name,Id]' --output table
```

**Expected Output**:
- DEV: wpdev.kimmyai.io
- SIT: wpsit.kimmyai.io
- PROD: wp.kimmyai.io (or delegated zone)

4. **Verify CloudFront distribution** (if applicable):
```bash
aws cloudfront list-distributions --query 'DistributionList.Items[*].[Id,DomainName,Status]' --output table
```

**Troubleshooting**:
- **Issue**: ALB not found
  - **Solution**: Verify ALB name, may need to create for new environment

- **Issue**: Route53 zone not found
  - **Solution**: Create hosted zone or verify delegation

**Verification**:
- [ ] DEV ALB is "active" with HTTP listener
- [ ] SIT ALB is "active" with HTTP listener
- [ ] PROD ALB is "active" with HTTPS listener
- [ ] Route53 zones exist for wpdev, wpsit, wp domains
- [ ] CloudFront distributions exist (if used)

---

### Task 1.6: Validate Secrets Manager Configuration

**Duration**: 20 minutes
**Responsible**: DevOps Engineer

**Steps for Each Environment**:

1. **List existing secrets**:
```bash
export AWS_PROFILE=Tebogo-dev

aws secretsmanager list-secrets --query 'SecretList[*].[Name,Description]' --output table
```

**Expected**: Should see secrets for RDS master credentials

2. **Verify secret structure** (do not log values):
```bash
aws secretsmanager describe-secret --secret-id bbws/dev/rds/master
```

3. **Test secret retrieval** (verify format only):
```bash
aws secretsmanager get-secret-value --secret-id bbws/dev/rds/master --query SecretString --output text | jq 'keys'
```

**Expected keys**: `["host", "port", "username", "password", "dbname"]`

**Verification**:
- [ ] RDS master secret exists in all environments
- [ ] Secrets Manager accessible via AWS CLI
- [ ] Secret format is correct (JSON with required keys)

---

### Task 1.7: Validate Terraform State

**Duration**: 30 minutes
**Responsible**: DevOps Engineer

**Steps**:

1. **Check Terraform version**:
```bash
terraform version
```

**Expected**: v1.6.0 or higher

2. **Verify Terraform state backend**:
```bash
cd /path/to/terraform/infrastructure
cat backend.tf
```

**Expected**: S3 backend configured for state storage

3. **Initialize Terraform for each environment**:
```bash
# DEV
terraform workspace select dev || terraform workspace new dev
terraform init

# SIT
terraform workspace select sit || terraform workspace new sit
terraform init

# PROD
terraform workspace select prod || terraform workspace new prod
terraform init
```

4. **Verify state is accessible**:
```bash
terraform workspace select dev
terraform state list
```

**Expected**: Should show existing infrastructure resources

**Verification**:
- [ ] Terraform v1.6+ installed
- [ ] S3 backend configured and accessible
- [ ] Workspaces exist for dev, sit, prod
- [ ] State contains existing infrastructure

---

### Task 1.8: Baseline Performance Metrics

**Duration**: 20 minutes
**Responsible**: Technical Lead

**Steps for Each Environment**:

1. **Record current tenant count**:
```bash
export AWS_PROFILE=Tebogo-dev

# Count ECS services (proxy for tenant count)
aws ecs list-services --cluster dev-cluster --query 'serviceArns' | jq 'length'
```

2. **Record current resource utilization**:
```bash
# ECS cluster utilization
aws ecs describe-clusters --clusters dev-cluster --include STATISTICS

# RDS instance metrics (last hour)
aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name CPUUtilization \
    --dimensions Name=DBInstanceIdentifier,Value=bbws-dev-mysql \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 3600 \
    --statistics Average
```

3. **Document baseline metrics**:
Create file: `baseline_metrics_[ENV]_[DATE].txt`

```
Environment: DEV
Date: 2026-01-09
Tenant Count: X
ECS Services Running: X
RDS CPU Average: X%
RDS Storage Used: X GB
EFS Storage Used: X GB
```

**Verification**:
- [ ] Baseline metrics documented for all environments
- [ ] Current capacity confirmed to support new tenant

---

## Verification Checklist

### Environment Access
- [ ] AWS CLI configured for all 3 environments
- [ ] Account IDs verified (DEV: 536580886816, SIT: 815856636111, PROD: 093646564004)
- [ ] IAM permissions verified for ECS, RDS, EFS, Route53, Secrets Manager
- [ ] Network connectivity to AWS regions confirmed

### Infrastructure Components (All Environments)
- [ ] ECS clusters: ACTIVE status
- [ ] RDS instances: available status, connectivity tested
- [ ] EFS file systems: available status with mount targets
- [ ] ALB: active with listeners configured
- [ ] Route53: hosted zones exist for wpdev, wpsit, wp
- [ ] Secrets Manager: accessible, master secrets exist
- [ ] CloudFront: distributions exist (if applicable)

### Tools and Scripts
- [ ] Terraform v1.6+ installed
- [ ] Terraform state accessible for all workspaces
- [ ] Migration scripts available (import_database.sh, upload_wordpress_files.sh)
- [ ] Testing checklist available

### Documentation
- [ ] Baseline metrics documented
- [ ] Infrastructure diagram reviewed
- [ ] Access credentials documented securely

---

## Rollback Procedure

**This phase is read-only validation** - no changes are made, so no rollback is needed.

If validation fails:
1. Document specific failures
2. Escalate to DevOps team to resolve infrastructure issues
3. Do not proceed to Phase 2 until all checks pass

---

## Success Criteria

- [ ] All AWS environments (DEV, SIT, PROD) are accessible
- [ ] All infrastructure components are in healthy state
- [ ] Team has necessary access and credentials
- [ ] Terraform state is accessible and up-to-date
- [ ] Baseline metrics documented
- [ ] No blockers identified
- [ ] Ready to proceed to Phase 2 (Xneelo Export)

**Definition of Done**:
All verification checklist items are marked complete, and no critical infrastructure issues are identified.

---

## Sign-Off

**Completed By**: _________________ Date: _________
**Verified By**: _________________ Date: _________
**Issues Found**: _________
**Issues Resolved**: _________
**Ready for Phase 2**: [ ] YES [ ] NO

---

## Notes and Observations

[Space for team to document findings]

**Common Issues Encountered**:
-
-

**Recommendations for Next Time**:
-
-

---

**Next Phase**: Proceed to **Phase 2**: `02_Xneelo_Data_Export.md`
