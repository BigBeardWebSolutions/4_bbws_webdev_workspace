# SIT Tenant Deployment Runbook

**Version:** 1.0
**Date:** 2025-12-21
**Environment:** SIT (eu-west-1)
**Status:** In Progress - Pilot Deployment (goldencrust)

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Deployment Steps](#deployment-steps)
4. [Issues Encountered & Solutions](#issues-encountered--solutions)
5. [Validation](#validation)
6. [Rollback](#rollback)
7. [Next Steps](#next-steps)

---

## Overview

This runbook documents the process of deploying WordPress tenants from DEV to SIT environment using AWS ECS Fargate, RDS MySQL, EFS, and ALB.

### Architecture Components

- **ECS Cluster:** sit-cluster
- **RDS Instance:** sit-mysql.cn6qqe8eu6b9.eu-west-1.rds.amazonaws.com
- **EFS Filesystem:** fs-0be15624e203bf94a
- **ALB:** sit-alb (fde5d67ceb73e219)
- **VPC:** 10.2.0.0/16 (Private subnets: subnet-09d1d2de85ae02264, subnet-00e96b70ba19dffc5)
- **Domain:** *.wpsit.kimmyai.io

---

## Prerequisites

### 1. AWS SSO Authentication

**Issue:** Terraform S3 backend doesn't support newer `sso_session` format.

**Solution:** Convert `~/.aws/config` to legacy SSO format:

```ini
[profile Tebogo-sit]
sso_start_url = https://d-9367a8daf2.awsapps.com/start/#
sso_region = eu-west-1
sso_account_id = 815856636111
sso_role_name = AWSAdministratorAccess
region = eu-west-1
# REMOVED: sso_session = AWSAdministratorAccess
```

**Validation:**
```bash
aws sso login --profile Tebogo-sit
terraform init -backend-config=environments/sit/backend-sit.hcl
```

### 2. Required Secrets

- `sit-rds-master-credentials` - RDS admin credentials (exists)
- `sit-{tenant}-db-credentials` - Per-tenant database credentials (create per tenant)

### 3. IAM Permissions

The `sit-ecs-task-execution-role` must have inline policies for each tenant's secrets:

**Policy Name Pattern:** `sit-ecs-secrets-access-{tenant}`

**Policy Content:**
```json
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Action": ["secretsmanager:GetSecretValue"],
        "Resource": [
            "arn:aws:secretsmanager:eu-west-1:815856636111:secret:sit-{tenant}-db-credentials-*"
        ]
    }]
}
```

---

## Deployment Steps

### Step 1: Create Tenant Secret

```bash
# Generate random password
TENANT_PASS=$(openssl rand -base64 18 | tr -d '/+=')
echo "Password: $TENANT_PASS" > /tmp/{tenant}_password.txt

# Create secret JSON
cat > /tmp/{tenant}_secret.json << EOF
{
  "username": "{tenant}_user",
  "password": "$TENANT_PASS",
  "database": "{tenant}_db",
  "host": "sit-mysql.cn6qqe8eu6b9.eu-west-1.rds.amazonaws.com",
  "port": 3306
}
EOF

# Create secret in AWS
AWS_PROFILE=Tebogo-sit aws secretsmanager create-secret \
  --name sit-{tenant}-db-credentials \
  --description "Database credentials for {tenant} tenant" \
  --secret-string file:///tmp/{tenant}_secret.json \
  --region eu-west-1 \
  --tags Key=Environment,Value=sit Key=Tenant,Value={tenant}
```

### Step 2: Update IAM Policy for Secret Access

```bash
# Create IAM policy
cat > /tmp/{tenant}-secrets-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Action": ["secretsmanager:GetSecretValue"],
        "Resource": [
            "arn:aws:secretsmanager:eu-west-1:815856636111:secret:sit-{tenant}-db-credentials-*"
        ]
    }]
}
EOF

# Apply policy to execution role
AWS_PROFILE=Tebogo-sit aws iam put-role-policy \
  --role-name sit-ecs-task-execution-role \
  --policy-name sit-ecs-secrets-access-{tenant} \
  --policy-document file:///tmp/{tenant}-secrets-policy.json
```

### Step 3: Create Database and User

**Issue:** The existing `sit-db-init` task definition is hardcoded for tenant-1 and cannot be used for other tenants.

**Solution:** Use generic MySQL client task definition.

#### 3a. Register Generic DB Init Task (One-time)

```bash
cat > /tmp/generic-db-init-task.json << 'EOF'
{
  "family": "sit-generic-db-init",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::815856636111:role/sit-ecs-task-execution-role",
  "containerDefinitions": [{
    "name": "mysql-client",
    "image": "mysql:8.0",
    "essential": true,
    "command": ["sh", "-c", "echo 'Ready'"],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/sit",
        "awslogs-region": "eu-west-1",
        "awslogs-stream-prefix": "db-init"
      }
    }
  }]
}
EOF

AWS_PROFILE=Tebogo-sit aws ecs register-task-definition \
  --cli-input-json file:///tmp/generic-db-init-task.json \
  --region eu-west-1
```

#### 3b. Create Database for Tenant

```bash
# Get credentials
MASTER_CREDS=$(AWS_PROFILE=Tebogo-sit aws secretsmanager get-secret-value \
  --secret-id sit-rds-master-credentials \
  --region eu-west-1 \
  --query 'SecretString' \
  --output text)

MASTER_USER=$(echo "$MASTER_CREDS" | jq -r '.username')
MASTER_PASS=$(echo "$MASTER_CREDS" | jq -r '.password')
TENANT_PASS=$(cat /tmp/{tenant}_password.txt)
RDS_HOST="sit-mysql.cn6qqe8eu6b9.eu-west-1.rds.amazonaws.com"

# Create task override
cat > /tmp/create_{tenant}_db.json << EOF
{
  "containerOverrides": [{
    "name": "mysql-client",
    "command": [
      "sh", "-c",
      "mysql -h $RDS_HOST -u $MASTER_USER -p'$MASTER_PASS' -e \"CREATE DATABASE IF NOT EXISTS {tenant}_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; CREATE USER IF NOT EXISTS '{tenant}_user'@'%' IDENTIFIED BY '$TENANT_PASS'; GRANT ALL PRIVILEGES ON {tenant}_db.* TO '{tenant}_user'@'%'; FLUSH PRIVILEGES; SHOW DATABASES LIKE '{tenant}_db';\""
    ]
  }]
}
EOF

# Run database creation task
TASK_ARN=$(AWS_PROFILE=Tebogo-sit aws ecs run-task \
  --cluster sit-cluster \
  --task-definition sit-generic-db-init:1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-09d1d2de85ae02264],securityGroups=[sg-01bca1fb9806ad397],assignPublicIp=DISABLED}" \
  --region eu-west-1 \
  --overrides file:///tmp/create_{tenant}_db.json \
  --query 'tasks[0].taskArn' \
  --output text)

# Wait for completion
AWS_PROFILE=Tebogo-sit aws ecs wait tasks-stopped \
  --cluster sit-cluster \
  --tasks $TASK_ARN \
  --region eu-west-1

# Check exit code
AWS_PROFILE=Tebogo-sit aws ecs describe-tasks \
  --cluster sit-cluster \
  --tasks $TASK_ARN \
  --region eu-west-1 \
  --query 'tasks[0].containers[0].exitCode'
```

**Expected Result:** Exit code 0

### Step 4: Create ECS Task Definition, Target Group, Listener Rule, and Service

**Option A: Using Terraform (if state is managed)**

```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform/terraform

# Generate Terraform file
./utils/generate_sit_tenant_tf.sh {tenant} {alb_priority}

# Deploy
terraform plan -var-file=environments/sit/sit.tfvars -target=aws_ecs_service.sit_{tenant}
terraform apply -target=aws_ecs_service.sit_{tenant}
```

**Option B: Using AWS CLI (current approach)**

See `/tmp/deploy_goldencrust_sit.sh` for reference.

Key components:
1. Register ECS task definition
2. Create ALB target group
3. Create ALB listener rule
4. Create ECS service

**Goldencrust Deployment Details:**
- Task Definition: `sit-goldencrust:3`
- Target Group: `sit-goldencrust-tg` (arn:...targetgroup/sit-goldencrust-tg/df19514b27127969)
- Listener Rule: Priority 140, Host: `goldencrust.wpsit.kimmyai.io`
- Service: `sit-goldencrust-service`
- EFS Access Point: `fsap-068c55acd83456a5f`

---

## Issues Encountered & Solutions

### Issue 1: Terraform SSO Authentication Failure

**Error:**
```
Error: SSOProviderInvalidToken: the SSO session has expired or is invalid
```

**Root Cause:** Terraform S3 backend doesn't fully support newer AWS config `sso_session` format.

**Solution:** Convert to legacy SSO format (see Prerequisites section).

**Status:** ✅ RESOLVED

---

### Issue 2: Terraform Wants to Create Existing Infrastructure

**Error:** Terraform plan shows 57+ resources to create (cluster, ALB, RDS, VPC, etc.) that already exist in SIT.

**Root Cause:** Existing SIT infrastructure was deployed outside Terraform and not in Terraform state.

**Solution:** Used AWS CLI deployment approach (Option B) instead of Terraform for pilot deployment.

**Status:** ✅ WORKAROUND IMPLEMENTED

**Future Action:** Import existing SIT infrastructure into Terraform state or rebuild with Terraform for consistency.

---

### Issue 3: ECS Task Execution Role Missing Secret Permissions

**Error:**
```
ResourceInitializationError: unable to pull secrets or registry auth: ... AccessDeniedException: ... is not authorized to perform: secretsmanager:GetSecretValue on resource: sit-{tenant}-db-credentials
```

**Root Cause:** IAM policy for `sit-ecs-task-execution-role` didn't include permissions for new tenant secret.

**Solution:** Create inline IAM policy for each tenant (see Step 2).

**Status:** ✅ RESOLVED (goldencrust)

**Automation Needed:** Create utility script to automatically add IAM policy when creating tenant secrets.

---

### Issue 4: sit-db-init Task Definition Hardcoded for tenant-1

**Error:**
```
ResourceInitializationError: ... failed to fetch secret sit-tenant-1-db-credentials ...
```

**Root Cause:** The `sit-db-init` task definition has hardcoded secret references to `sit-tenant-1-db-credentials`, making it unusable for other tenants.

**Solution:** Created generic `sit-generic-db-init` task definition that accepts command overrides without secret dependencies.

**Status:** ✅ WORKAROUND IMPLEMENTED

**Future Action:** Redesign database initialization approach:
- Option 1: Create parameterized db-init task that uses environment variables instead of hardcoded secrets
- Option 2: Use AWS RDS Data API for database creation (requires enabling Data API on RDS)
- Option 3: Keep generic MySQL client task definition as standard

---

### Issue 5: WordPress Health Checks Failing (HTTP 500)

**Error:** ALB target health check returns HTTP 500, causing ECS to stop tasks.

**Symptoms:**
- Task starts successfully
- Container runs
- ALB reports `Target.ResponseCodeMismatch` with HTTP 500
- Service stops task after repeated health check failures
- Service shows 0 running tasks despite desired count of 1

**Status:** ⚠️ IN PROGRESS

**Investigation Steps:**
1. Check WordPress error logs in CloudWatch: `/ecs/sit` → `goldencrust/wordpress/*`
2. Verify database connectivity from container
3. Check WordPress configuration (WP_HOME, WP_SITEURL)
4. Verify EFS mount is accessible

**Possible Causes:**
- WordPress can't connect to database (credentials mismatch)
- EFS permissions issue (uid/gid 33 for www-data)
- WordPress configuration error (WP_HOME/WP_SITEURL mismatch)
- Missing WordPress database tables (fresh database needs setup)

**Next Troubleshooting Steps:**
```bash
# 1. Get latest task ARN (even if stopped)
TASK_ARN=$(AWS_PROFILE=Tebogo-sit aws ecs list-tasks \
  --cluster sit-cluster \
  --family sit-goldencrust \
  --desired-status STOPPED \
  --region eu-west-1 \
  --query 'taskArns[0]' \
  --output text)

# 2. Get CloudWatch logs
LOG_STREAM=$(AWS_PROFILE=Tebogo-sit aws logs describe-log-streams \
  --log-group-name /ecs/sit \
  --log-stream-name-prefix goldencrust/wordpress \
  --region eu-west-1 \
  --query 'logStreams[-1].logStreamName' \
  --output text)

# 3. View logs
AWS_PROFILE=Tebogo-sit aws logs filter-log-events \
  --log-group-name /ecs/sit \
  --log-stream-names "$LOG_STREAM" \
  --region eu-west-1 \
  --start-time $(date -u -v-10M +%s000)

# 4. Test database connection manually
# (Requires exec into container or use mysql client task)

# 5. Check EFS mount
# (Requires exec into container)

# 6. Test HTTP endpoint directly
curl -v -u "bbws-sit:PASSWORD" http://goldencrust.wpsit.kimmyai.io
```

---

## Validation

### Service Health

```bash
AWS_PROFILE=Tebogo-sit aws ecs describe-services \
  --cluster sit-cluster \
  --services sit-{tenant}-service \
  --region eu-west-1 \
  --query 'services[0].{Status:status,DesiredCount:desiredCount,RunningCount:runningCount}'
```

**Expected:** Status=ACTIVE, RunningCount=DesiredCount

### Target Health

```bash
TG_ARN="<target-group-arn>"
AWS_PROFILE=Tebogo-sit aws elbv2 describe-target-health \
  --target-group-arn $TG_ARN \
  --region eu-west-1 \
  --query 'TargetHealthDescriptions[].{IP:Target.Id,Health:TargetHealth.State}'
```

**Expected:** Health=healthy

### HTTP Access

```bash
curl -I -u "bbws-sit:PASSWORD" https://{tenant}.wpsit.kimmyai.io
```

**Expected:** HTTP 200 or 302 (WordPress redirect)

### Database Verification

```bash
# List databases
./utils/list_databases.sh sit

# Verify tenant credentials
./utils/get_tenant_credentials.sh {tenant} sit
```

---

## Rollback

### Delete Service

```bash
AWS_PROFILE=Tebogo-sit aws ecs update-service \
  --cluster sit-cluster \
  --service sit-{tenant}-service \
  --desired-count 0 \
  --region eu-west-1

AWS_PROFILE=Tebogo-sit aws ecs delete-service \
  --cluster sit-cluster \
  --service sit-{tenant}-service \
  --region eu-west-1 \
  --force
```

### Delete ALB Resources

```bash
# Delete listener rule
AWS_PROFILE=Tebogo-sit aws elbv2 delete-rule \
  --rule-arn <rule-arn> \
  --region eu-west-1

# Delete target group
AWS_PROFILE=Tebogo-sit aws elbv2 delete-target-group \
  --target-group-arn <tg-arn> \
  --region eu-west-1
```

### Delete Database and Secret

```bash
# Drop database (use generic db-init task with DROP DATABASE command)

# Delete secret
AWS_PROFILE=Tebogo-sit aws secretsmanager delete-secret \
  --secret-id sit-{tenant}-db-credentials \
  --force-delete-without-recovery \
  --region eu-west-1
```

### Delete IAM Policy

```bash
AWS_PROFILE=Tebogo-sit aws iam delete-role-policy \
  --role-name sit-ecs-task-execution-role \
  --policy-name sit-ecs-secrets-access-{tenant}
```

---

## Next Steps

### For goldencrust Pilot

1. ⚠️ **RESOLVE:** WordPress health check failures (HTTP 500)
   - Check CloudWatch logs for exact error
   - Verify database connectivity
   - Check EFS permissions
   - Verify WordPress configuration

2. Once healthy:
   - Monitor for 24-48 hours
   - Test WordPress admin access
   - Verify content persistence (EFS)
   - Check CloudFront access with Basic Auth

### For Remaining 12 Tenants

1. **Fix Infrastructure Issues:**
   - Redesign db-init approach (remove tenant-1 hardcoding)
   - Create automation script for IAM policy updates
   - Consider Terraform state import for consistency

2. **Batch Deployment:**
   - Batch 1: tenant1, tenant2, sunsetbistro, sterlinglaw (4 tenants)
   - Batch 2: ironpeak, premierprop, lenslight, nexgentech (4 tenants)
   - Batch 3: serenity, bloompetal, precisionauto, bbwstrustedservice (4 tenants)

3. **Documentation:**
   - Update this runbook with health check resolution
   - Create troubleshooting playbook
   - Document lessons learned

---

## Appendix

### Goldencrust Pilot - Resource ARNs

```
Secret: arn:aws:secretsmanager:eu-west-1:815856636111:secret:sit-goldencrust-db-credentials-4ggyNQ
Database: goldencrust_db on sit-mysql.cn6qqe8eu6b9.eu-west-1.rds.amazonaws.com
User: goldencrust_user
Password: sdryzBsVuju6C8JpdvC1dlW (stored in secret)
EFS Access Point: fsap-068c55acd83456a5f
Task Definition: arn:aws:ecs:eu-west-1:815856636111:task-definition/sit-goldencrust:3
Target Group: arn:aws:elasticloadbalancing:eu-west-1:815856636111:targetgroup/sit-goldencrust-tg/df19514b27127969
Listener Rule: Priority 140, Host: goldencrust.wpsit.kimmyai.io
Service: sit-goldencrust-service
```

### Region Configuration

| Environment | AWS Account | Region |
|-------------|-------------|--------|
| DEV | 536580886816 | eu-west-1 |
| SIT | 815856636111 | eu-west-1 |
| PROD | 093646564004 | af-south-1 |

### Key Lessons Learned

1. **Terraform SSO Compatibility:** Always use legacy SSO format for Terraform S3 backend
2. **State Management:** Ensure Terraform state reflects reality before planning deployments
3. **IAM Automation:** Tenant secret permissions must be added to execution role immediately after secret creation
4. **Task Definition Design:** Avoid hardcoding tenant-specific values in reusable task definitions
5. **Health Check Debugging:** Always check CloudWatch logs first when containers fail health checks

---

**Document History:**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-12-21 | Claude | Initial runbook created during goldencrust pilot deployment |

