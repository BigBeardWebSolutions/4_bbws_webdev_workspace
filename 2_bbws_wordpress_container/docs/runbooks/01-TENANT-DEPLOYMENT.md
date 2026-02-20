# Tenant Deployment Runbook

**Version:** 1.1
**Last Updated:** 2025-12-24
**Owner:** DevOps Team
**Environments:** DEV, SIT, PROD

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Deployment Steps](#deployment-steps)
4. [Validation](#validation)
5. [Post-Deployment](#post-deployment)
6. [Troubleshooting](#troubleshooting)
7. [Rollback](#rollback)
8. [Reference](#reference)

---

## Overview

This runbook provides step-by-step instructions for deploying a new WordPress tenant to the BBWS Multi-Tenant Platform.

### Architecture Overview

```
User Request
    ↓
Route53 DNS (*.wp{env}.kimmyai.io)
    ↓
CloudFront (SSL termination, Basic Auth, Caching, WAF)
    ↓
Application Load Balancer (Host-based routing)
    ↓
ECS Fargate Task (WordPress container)
    ↓
RDS MySQL (Shared instance, per-tenant database)
    ↓
EFS (Shared filesystem, per-tenant access point)
```

### Deployment Time

- **Target:** 15 minutes
- **Typical:** 20-30 minutes (first time)
- **With Issues:** 1-3 hours

---

## Prerequisites

### Required Tools

```bash
# Verify installations
terraform --version        # >= 1.5.0
aws --version             # >= 2.x
jq --version              # >= 1.6
git --version             # >= 2.x
```

### Required Access

- [ ] AWS SSO configured with appropriate profiles
  - DEV: `Tebogo-dev` (Account: 536580886816)
  - SIT: `Tebogo-sit` (Account: 815856636111)
  - PROD: `Tebogo-prod` (Account: 093646564004)
- [ ] GitHub repository access (2_bbws_ecs_terraform)
- [ ] Terraform state backend access (S3 + DynamoDB)

### Environment Selection

Determine target environment:
```bash
# Set environment variable
export ENVIRONMENT=sit  # or dev, prod
export AWS_PROFILE=Tebogo-${ENVIRONMENT}
export AWS_REGION=eu-west-1  # or af-south-1 for PROD
```

### Pre-Deployment Checklist

- [ ] Tenant name decided (lowercase, alphanumeric, no special chars)
- [ ] Domain name confirmed (e.g., `tenant-name.wpsit.kimmyai.io`)
- [ ] ALB priority allocated (check existing priorities first)
- [ ] Database credentials strategy confirmed
- [ ] Resource requirements defined (CPU, memory, desired count)

---

## Docker Image Management

### Building the WordPress Image

**CRITICAL:** Always use `Dockerfile.fixed` for production builds.

**Why Dockerfile.fixed?**
- `Dockerfile` contains buggy custom entrypoint wrapper that corrupts wp-config.php
- `Dockerfile.fixed` uses standard WordPress entrypoint without modifications
- Bug causes PHP parse errors and HTTP 500 responses
- See Issue 6 in Troubleshooting section for details

**Build Command:**
```bash
cd /path/to/2_bbws_wordpress_container/docker

# Build for linux/amd64 (AWS Fargate requirement)
docker buildx build \
  --platform linux/amd64 \
  -f Dockerfile.fixed \
  -t ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ENVIRONMENT}-wordpress:$(date +%Y%m%d-%H%M%S) \
  --load .

# Tag as latest (optional)
docker tag ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ENVIRONMENT}-wordpress:$(date +%Y%m%d-%H%M%S) \
  ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ENVIRONMENT}-wordpress:latest
```

**Push to ECR:**
```bash
# Login to ECR
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin \
  ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Push datestamp tag
docker push ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ENVIRONMENT}-wordpress:$(date +%Y%m%d-%H%M%S)

# Push latest tag (optional)
docker push ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ENVIRONMENT}-wordpress:latest
```

**Environment-Specific Details:**

| Environment | Account ID | Region | ECR Repository |
|-------------|------------|--------|----------------|
| DEV | 536580886816 | eu-west-1 | dev-wordpress |
| SIT | 815856636111 | eu-west-1 | sit-wordpress |
| PROD | 093646564004 | af-south-1 | prod-wordpress |

**Current State (as of 2025-12-24):**
- **DEV**: Using Docker Hub `wordpress:latest` (no custom image) ⚠️
- **SIT**: Using Docker Hub `wordpress:latest` (no custom image) ⚠️
- **PROD**: Using ECR `prod-wordpress:20251224-fixed` ✅

**Recommendation:** Standardize all environments on ECR images for consistency

### Validating Image Architecture

**Before deploying to PROD**, verify image supports linux/amd64:

```bash
# Inspect image manifest
docker buildx imagetools inspect \
  ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ENVIRONMENT}-wordpress:$(date +%Y%m%d-%H%M%S)

# Should show:
# Platform: linux/amd64
```

**Common Error:**
If built on Mac without `--platform linux/amd64`, ECS task will fail with:
```
CannotPullContainerError: pull image manifest has been retried 7 time(s):
image Manifest does not contain descriptor matching platform 'linux/amd64'
```

---

## Deployment Steps

### Step 1: Create Tenant Configuration

#### 1.1 Navigate to Terraform Directory

```bash
cd /path/to/2_bbws_ecs_terraform/terraform
```

#### 1.2 Create Tenant Directory

```bash
TENANT_NAME="your-tenant-name"  # e.g., bbwsmytestingdomain
mkdir -p tenants/${TENANT_NAME}
cd tenants/${TENANT_NAME}
```

#### 1.3 Copy Template Files

```bash
# Copy from existing tenant (e.g., goldencrust)
cp ../goldencrust/main.tf ./
cp ../goldencrust/variables.tf ./
cp ../goldencrust/outputs.tf ./
cp ../goldencrust/${ENVIRONMENT}.tfvars ./${ENVIRONMENT}.tfvars
```

#### 1.4 Update Configuration Files

**Edit `${ENVIRONMENT}.tfvars`:**

```hcl
# Tenant Identity
tenant_name  = "your-tenant-name"
environment  = "sit"  # or dev, prod
domain_name  = "your-tenant-name.wpsit.kimmyai.io"
alb_priority = XXX  # See priority allocation table

# AWS Configuration
aws_region  = "eu-west-1"  # or af-south-1 for PROD
aws_profile = "Tebogo-sit"

# ECS Configuration
wordpress_image = "815856636111.dkr.ecr.eu-west-1.amazonaws.com/sit-wordpress:latest"
task_cpu        = 256
task_memory     = 512
desired_count   = 1

# Health Check Configuration
health_check_path                = "/"
health_check_interval            = 30
health_check_healthy_threshold   = 2
health_check_unhealthy_threshold = 3

# Database Configuration
init_db_script_path = "../../../../2_bbws_agents/utils/init_tenant_db.py"
verify_database     = true

# DNS Configuration
create_dns_records = false  # SIT doesn't use per-tenant DNS

# Feature Flags
wordpress_debug = false  # Set true only in DEV
enable_ecs_exec = true

# Tags
tags = {
  Project     = "BBWS"
  Tenant      = "your-tenant-name"
  Environment = "sit"
  CostCenter  = "Engineering"
}
```

**Critical Fields to Update:**
- `tenant_name`
- `domain_name`
- `alb_priority` (MUST be unique - see Step 1.5)
- `wordpress_image` (match environment)
- `aws_region` and `aws_profile`

#### 1.5 Check ALB Priority Availability

**CRITICAL:** ALB listener rules are processed in priority order. Conflicts cause traffic routing failures.

```bash
# List existing priorities
aws elbv2 describe-load-balancers \
  --region ${AWS_REGION} \
  --names ${ENVIRONMENT}-alb \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text | xargs -I {} \
  aws elbv2 describe-listeners \
  --region ${AWS_REGION} \
  --load-balancer-arn {} \
  --query 'Listeners[?Port==`80`].ListenerArn' \
  --output text | xargs -I {} \
  aws elbv2 describe-rules \
  --region ${AWS_REGION} \
  --listener-arn {} \
  --query 'Rules[*].{Priority:Priority,Host:Conditions[?Field==`host-header`].Values|[0]|[0]}' \
  --output table
```

**Priority Allocation:**
- **DEV:** 10-99
- **SIT:** 100-199
- **PROD:** 200-299
- **Reserved:** `default` (catch-all at end)

**Common Priorities Used:**
- Check output above for used priorities
- Select next available priority in range
- Document in allocation spreadsheet

---

### Step 2: Initialize Terraform

#### 2.1 Initialize Backend

```bash
cd /path/to/2_bbws_ecs_terraform/terraform/tenants/${TENANT_NAME}

terraform init \
  -backend-config="bucket=bbws-terraform-state-${ENVIRONMENT}" \
  -backend-config="key=tenants/${TENANT_NAME}/${ENVIRONMENT}.tfstate" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="dynamodb_table=bbws-terraform-locks-${ENVIRONMENT}" \
  -backend-config="encrypt=true"
```

**Expected Output:**
```
Terraform has been successfully initialized!
```

#### 2.2 Validate Configuration

```bash
terraform validate
```

**Expected Output:**
```
Success! The configuration is valid.
```

---

### Step 3: Plan Deployment

#### 3.1 Generate Terraform Plan

```bash
terraform plan \
  -var-file=${ENVIRONMENT}.tfvars \
  -out=${TENANT_NAME}-${ENVIRONMENT}.tfplan
```

#### 3.2 Review Plan Output

**Expected Resources (approximately 10):**
- AWS Secrets Manager Secret (database credentials)
- EFS Access Point (tenant wp-content storage)
- ECS Task Definition
- ECS Service
- ALB Target Group
- ALB Listener Rule
- CloudWatch Log Group (if not exists)
- Security Group Rules (if needed)

**Critical Validations:**
- [ ] Secret name: `${ENVIRONMENT}-${TENANT_NAME}-db-credentials`
- [ ] EFS access point path: `/${TENANT_NAME}`
- [ ] Task definition family: `${ENVIRONMENT}-${TENANT_NAME}`
- [ ] Service name: `${ENVIRONMENT}-${TENANT_NAME}-service`
- [ ] Target group name: `${ENVIRONMENT}-${TENANT_NAME}-tg`
- [ ] Listener rule priority: Matches `.tfvars` value
- [ ] Listener rule host header: `${TENANT_NAME}.wp${ENVIRONMENT}.kimmyai.io`

**Red Flags:**
- ❌ Priority conflict with existing rule
- ❌ Security group changes (should be rare)
- ❌ VPC or subnet changes (should NEVER happen)
- ❌ Destroying existing resources

---

### Step 4: Apply Terraform

#### 4.1 Execute Plan

```bash
terraform apply ${TENANT_NAME}-${ENVIRONMENT}.tfplan
```

**Monitor Output:**
- Watch for any errors
- Note resource creation order
- Confirm all resources created successfully

**Expected Duration:** 2-5 minutes

#### 4.2 Verify Infrastructure Created

```bash
# Check ECS service
aws ecs describe-services \
  --region ${AWS_REGION} \
  --cluster ${ENVIRONMENT}-cluster \
  --services ${ENVIRONMENT}-${TENANT_NAME}-service \
  --query 'services[0].{Status:status,DesiredCount:desiredCount,RunningCount:runningCount}'

# Check target group
aws elbv2 describe-target-groups \
  --region ${AWS_REGION} \
  --names ${ENVIRONMENT}-${TENANT_NAME}-tg \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text

# Check secrets
aws secretsmanager describe-secret \
  --region ${AWS_REGION} \
  --secret-id ${ENVIRONMENT}-${TENANT_NAME}-db-credentials \
  --query 'Name' \
  --output text
```

---

### Step 5: Manual Post-Deployment Steps

⚠️ **CRITICAL:** These steps are NOT automated in Terraform and MUST be done manually.

#### 5.1 Grant IAM Permissions for Secrets Manager

**Why:** ECS task execution role needs permission to read the tenant's database credentials.

```bash
aws iam put-role-policy \
  --region ${AWS_REGION} \
  --role-name ${ENVIRONMENT}-ecs-task-execution-role \
  --policy-name ${ENVIRONMENT}-ecs-secrets-access-${TENANT_NAME} \
  --policy-document '{
    "Version": "2012-01-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": ["secretsmanager:GetSecretValue"],
        "Resource": [
          "arn:aws:secretsmanager:'${AWS_REGION}':'$(aws sts get-caller-identity --query Account --output text)':secret:'${ENVIRONMENT}'-'${TENANT_NAME}'-db-credentials-*"
        ]
      }
    ]
  }'
```

**Verify:**
```bash
aws iam get-role-policy \
  --role-name ${ENVIRONMENT}-ecs-task-execution-role \
  --policy-name ${ENVIRONMENT}-ecs-secrets-access-${TENANT_NAME}
```

#### 5.2 Force New ECS Deployment

**Why:** Existing tasks don't have the new IAM permissions. Force restart to apply them.

```bash
aws ecs update-service \
  --region ${AWS_REGION} \
  --cluster ${ENVIRONMENT}-cluster \
  --service ${ENVIRONMENT}-${TENANT_NAME}-service \
  --force-new-deployment
```

**Wait for new task to start:**
```bash
# Monitor deployment
watch -n 5 "aws ecs describe-services \
  --region ${AWS_REGION} \
  --cluster ${ENVIRONMENT}-cluster \
  --services ${ENVIRONMENT}-${TENANT_NAME}-service \
  --query 'services[0].deployments[*].{Status:status,DesiredCount:desiredCount,RunningCount:runningCount,PendingCount:pendingCount}' \
  --output table"
```

Press `Ctrl+C` when `runningCount == desiredCount` and `pendingCount == 0`.

#### 5.3 Verify DNS Configuration (SIT/PROD only)

**Check wildcard DNS points to CloudFront:**

```bash
# Should resolve to CloudFront IPs, NOT ALB IPs
dig +short ${TENANT_NAME}.wp${ENVIRONMENT}.kimmyai.io A

# Verify CloudFront domain
dig +short *.wp${ENVIRONMENT}.kimmyai.io CNAME
```

**Expected:** DNS resolves to CloudFront distribution IPs (3.x.x.x range)

**If pointing to ALB:** See Troubleshooting section "DNS Points to ALB Instead of CloudFront"

---

## Validation

### Automated Validation Script

```bash
# Run comprehensive validation
cd /path/to/2_bbws_agents/utils
./validate_tenant_deployment.sh ${TENANT_NAME} ${ENVIRONMENT}
```

### Manual Validation Steps

#### 6.1 Database Validation

```bash
# Retrieve database credentials
DB_SECRET=$(aws secretsmanager get-secret-value \
  --region ${AWS_REGION} \
  --secret-id ${ENVIRONMENT}-${TENANT_NAME}-db-credentials \
  --query SecretString \
  --output text)

DB_HOST=$(echo $DB_SECRET | jq -r .host)
DB_NAME=$(echo $DB_SECRET | jq -r .database)
DB_USER=$(echo $DB_SECRET | jq -r .username)
DB_PASS=$(echo $DB_SECRET | jq -r .password)

echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo "Host: $DB_HOST"
```

**Test database connectivity:**
```bash
# Run test query via ECS task
aws ecs run-task \
  --region ${AWS_REGION} \
  --cluster ${ENVIRONMENT}-cluster \
  --task-definition ${ENVIRONMENT}-db-init \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[SUBNET_ID],securityGroups=[SG_ID],assignPublicIp=DISABLED}" \
  --overrides "{
    \"containerOverrides\": [{
      \"name\": \"db-init\",
      \"command\": [
        \"sh\", \"-c\",
        \"mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -e 'SELECT \\\"Database accessible\\\" AS Status; USE $DB_NAME; SHOW TABLES;'\"
      ]
    }]
  }"
```

#### 6.2 ECS Service Health

```bash
# Check service status
aws ecs describe-services \
  --region ${AWS_REGION} \
  --cluster ${ENVIRONMENT}-cluster \
  --services ${ENVIRONMENT}-${TENANT_NAME}-service \
  --query 'services[0].{Status:status,Desired:desiredCount,Running:runningCount,Pending:pendingCount}' \
  --output table
```

**Expected:**
- Status: `ACTIVE`
- Running: equals Desired (usually 1)
- Pending: 0

#### 6.3 ALB Target Health

```bash
# Get target group ARN
TG_ARN=$(aws elbv2 describe-target-groups \
  --region ${AWS_REGION} \
  --names ${ENVIRONMENT}-${TENANT_NAME}-tg \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

# Check target health
aws elbv2 describe-target-health \
  --region ${AWS_REGION} \
  --target-group-arn $TG_ARN \
  --query 'TargetHealthDescriptions[*].{Target:Target.Id,Port:Target.Port,Health:TargetHealth.State}' \
  --output table
```

**Expected:** All targets show `healthy` state

#### 6.4 HTTP Access (via ALB)

```bash
# Get ALB DNS
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --region ${AWS_REGION} \
  --names ${ENVIRONMENT}-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

# Test HTTP access
curl -I -H "Host: ${TENANT_NAME}.wp${ENVIRONMENT}.kimmyai.io" http://${ALB_DNS}/
```

**Expected:**
```
HTTP/1.1 302 Found
Location: https://${TENANT_NAME}.wp${ENVIRONMENT}.kimmyai.io/wp-admin/install.php
```

**Troubleshooting:**
- `HTTP/1.1 500` → Check WordPress logs (see Troubleshooting section)
- `HTTP/1.1 503` → Target group has no healthy targets
- Connection timeout → Security group or subnet issue

#### 6.5 HTTPS Access (via CloudFront)

**Get Basic Auth credentials:**
```bash
# SIT/PROD use Basic Auth
# Username: bbws-${ENVIRONMENT}
# Password: Check CloudFront function or Secrets Manager
```

**Test HTTPS:**
```bash
curl -I -u "bbws-${ENVIRONMENT}:PASSWORD" https://${TENANT_NAME}.wp${ENVIRONMENT}.kimmyai.io/
```

**Expected:**
```
HTTP/2 302
Location: https://${TENANT_NAME}.wp${ENVIRONMENT}.kimmyai.io/wp-admin/install.php
```

**Troubleshooting:**
- `HTTP/2 401` → Basic Auth credentials incorrect
- `HTTP/2 500` → WordPress application error (check logs)
- Connection timeout → DNS or CloudFront issue
- SSL error → Certificate issue

#### 6.6 WordPress Installation Page

```bash
# Full page load test
curl -u "bbws-${ENVIRONMENT}:PASSWORD" https://${TENANT_NAME}.wp${ENVIRONMENT}.kimmyai.io/ | grep -i "WordPress.*Installation"
```

**Expected Output:**
```html
<title>WordPress › Installation</title>
```

---

## Post-Deployment

### 7.1 Document Deployment

Create entry in deployment log:

```bash
cat >> /path/to/deployment_log.md << EOF

## ${TENANT_NAME} - ${ENVIRONMENT}
- **Date:** $(date +%Y-%m-%d)
- **Deployed By:** $(whoami)
- **Environment:** ${ENVIRONMENT}
- **Domain:** ${TENANT_NAME}.wp${ENVIRONMENT}.kimmyai.io
- **ALB Priority:** [from tfvars]
- **Status:** ✅ Deployed Successfully
- **Issues:** None / [list any issues]
- **Time Taken:** [actual time]

EOF
```

### 7.2 Update Priority Allocation Spreadsheet

Add entry to ALB priority tracking document.

### 7.3 Notify Stakeholders

**Email/Slack Template:**
```
Subject: New Tenant Deployed - ${TENANT_NAME} (${ENVIRONMENT})

A new WordPress tenant has been successfully deployed:

Environment: ${ENVIRONMENT}
Tenant: ${TENANT_NAME}
URL: https://${TENANT_NAME}.wp${ENVIRONMENT}.kimmyai.io
Basic Auth: bbws-${ENVIRONMENT} / [password]

Status:
✅ Database created and accessible
✅ ECS service running (1/1 healthy)
✅ ALB target healthy
✅ HTTPS access working
✅ WordPress ready for installation

Next Steps:
1. Complete WordPress installation wizard
2. Configure themes/plugins as needed
3. Test functionality

Deployed by: [Your Name]
Date: $(date)
```

### 7.4 Create WordPress Admin Access

Access the WordPress installation wizard and complete setup:

1. Navigate to: `https://${TENANT_NAME}.wp${ENVIRONMENT}.kimmyai.io`
2. Enter Basic Auth credentials
3. Select language
4. Fill in WordPress setup:
   - Site Title
   - Admin Username
   - Admin Password
   - Admin Email
5. Click "Install WordPress"

**Store WordPress admin credentials securely** (Secrets Manager or password vault).

---

## Troubleshooting

### Issue 1: WordPress Returns "Error Establishing Database Connection"

**Symptoms:**
- HTTP 500 error
- WordPress error page: "Error establishing a database connection"

**Root Cause:**
- Task execution role missing Secrets Manager permissions
- Database credentials incorrect
- Network connectivity issue (security groups)

**Diagnosis:**
```bash
# Check task logs
aws logs tail /ecs/${ENVIRONMENT} \
  --region ${AWS_REGION} \
  --log-stream-names "${TENANT_NAME}/wordpress/*" \
  --since 5m \
  --format short

# Check if secrets are accessible
aws secretsmanager get-secret-value \
  --region ${AWS_REGION} \
  --secret-id ${ENVIRONMENT}-${TENANT_NAME}-db-credentials
```

**Fix:**
1. Verify IAM permissions (Step 5.1)
2. Force new deployment (Step 5.2)
3. Check security group allows ECS → RDS on port 3306

---

### Issue 2: Requests Don't Appear in Container Logs

**Symptoms:**
- External curl/browser requests return errors
- Container logs show health checks but not external traffic

**Root Cause:**
- ALB listener rule conflict (higher priority rule catching traffic)
- Host header mismatch

**Diagnosis:**
```bash
# List ALL listener rules
aws elbv2 describe-load-balancers \
  --region ${AWS_REGION} \
  --names ${ENVIRONMENT}-alb \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text | xargs -I {} \
  aws elbv2 describe-listeners \
  --region ${AWS_REGION} \
  --load-balancer-arn {} \
  --query 'Listeners[?Port==`80`].ListenerArn' \
  --output text | xargs -I {} \
  aws elbv2 describe-rules \
  --region ${AWS_REGION} \
  --listener-arn {} \
  --query 'Rules[*].{Priority:Priority,Conditions:Conditions}' \
  --output json
```

**Fix:**
1. Look for catch-all rules (path-pattern `/*` with no host header)
2. Delete or modify conflicting rules
3. Ensure tenant rule has correct priority

---

### Issue 3: HTTPS Connection Timeout

**Symptoms:**
- HTTP works but HTTPS times out
- `curl: (28) Connection timed out`

**Root Cause:**
- DNS pointing to ALB instead of CloudFront
- CloudFront distribution not configured

**Diagnosis:**
```bash
# Check DNS resolution
dig +short ${TENANT_NAME}.wp${ENVIRONMENT}.kimmyai.io A

# Should resolve to CloudFront IPs (3.x.x.x), not ALB IPs
```

**Fix:**
```bash
# Get CloudFront distribution domain
aws cloudfront list-distributions \
  --region us-east-1 \
  --query 'DistributionList.Items[?Aliases.Items[0]==`*.wp'${ENVIRONMENT}'.kimmyai.io`].DomainName' \
  --output text

# Update Route53 wildcard record
aws route53 change-resource-record-sets \
  --hosted-zone-id [ZONE_ID] \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "*.wp'${ENVIRONMENT}'.kimmyai.io",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "[CLOUDFRONT_DOMAIN]",
          "EvaluateTargetHealth": false
        }
      }
    }]
  }'
```

---

### Issue 4: HTTP 401 Unauthorized (CloudFront Basic Auth)

**Symptoms:**
- HTTPS returns HTTP 401
- Browser prompts for authentication

**Root Cause:**
- CloudFront Basic Auth function has placeholder password
- Credentials incorrect

**Diagnosis:**
```bash
# Download CloudFront function
aws cloudfront get-function \
  --name wp${ENVIRONMENT}-basic-auth \
  --stage LIVE \
  /tmp/basic-auth-function.js

# Decode password
grep "Basic" /tmp/basic-auth-function.js | grep -oP 'Basic \K[^"]+' | base64 -d
```

**Fix:**
See runbook: `02-CLOUDFRONT-BASIC-AUTH-UPDATE.md`

---

### Issue 5: Task Fails to Start (ResourceInitializationError)

**Symptoms:**
- ECS task status: `STOPPED`
- Stop reason: "ResourceInitializationError: unable to pull secrets"

**Root Cause:**
- Task execution role missing Secrets Manager permissions
- Secret doesn't exist
- Secret has no value

**Diagnosis:**
```bash
# Check secret exists and has value
aws secretsmanager get-secret-value \
  --region ${AWS_REGION} \
  --secret-id ${ENVIRONMENT}-${TENANT_NAME}-db-credentials

# Check task execution role permissions
aws iam get-role-policy \
  --role-name ${ENVIRONMENT}-ecs-task-execution-role \
  --policy-name ${ENVIRONMENT}-ecs-secrets-access-${TENANT_NAME}
```

**Fix:**
1. Execute Step 5.1 (Grant IAM permissions)
2. Verify secret exists and has valid JSON
3. Force new deployment

---

### Issue 6: HTTP 500 - PHP Parse Error in wp-config.php

**Symptoms:**
- HTTP 500 Internal Server Error
- Target health checks failing with `Target.ResponseCodeMismatch`
- Container logs show: `PHP Parse error: syntax error, unexpected token "<", expecting end of file in /var/www/html/wp-config.php on line 2`

**Root Cause:**
- WordPress Docker image built with buggy `docker-entrypoint-wrapper.sh`
- Custom entrypoint injects duplicate PHP opening tag into wp-config.php
- Bug location: `2_bbws_wordpress_container/docker/docker-entrypoint-wrapper.sh:16`

**Diagnosis:**
```bash
# Check container logs for PHP parse errors
aws logs tail /ecs/${ENVIRONMENT} \
  --region ${AWS_REGION} \
  --log-stream-names "${TENANT_NAME}/wordpress/*" \
  --since 10m \
  --format short | grep "PHP Parse error"

# Verify image being used
TASK_ARN=$(aws ecs list-tasks \
  --region ${AWS_REGION} \
  --cluster ${ENVIRONMENT}-cluster \
  --service ${ENVIRONMENT}-${TENANT_NAME}-service \
  --query 'taskArns[0]' \
  --output text)

aws ecs describe-tasks \
  --region ${AWS_REGION} \
  --cluster ${ENVIRONMENT}-cluster \
  --tasks $TASK_ARN \
  --query 'tasks[0].containers[0].{image:image,imageDigest:imageDigest}'

# Check if using corrupted image
# Old corrupted digest: sha256:43604b53a1d0a32d515507909b2dc68da6cfae217da1098b43c431d40b3712f3
# Fixed digest: sha256:760e4faa0db7d55acd427512f718466ca7625f4a4798e9827f54396bc367d646
```

**Fix:**
```bash
# 1. Rebuild WordPress image using Dockerfile.fixed (not Dockerfile)
cd /path/to/2_bbws_wordpress_container/docker

docker buildx build \
  --platform linux/amd64 \
  -f Dockerfile.fixed \
  -t ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ENVIRONMENT}-wordpress:$(date +%Y%m%d-%H%M%S) \
  --load .

# 2. Login and push to ECR
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin \
  ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

docker push ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ENVIRONMENT}-wordpress:$(date +%Y%m%d-%H%M%S)

# 3. Update task definition to use new image
# (Update containerDefinitions[0].image in task definition JSON)

# 4. Force new deployment
aws ecs update-service \
  --region ${AWS_REGION} \
  --cluster ${ENVIRONMENT}-cluster \
  --service ${ENVIRONMENT}-${TENANT_NAME}-service \
  --force-new-deployment
```

**Prevention:**
- **ALWAYS** use `Dockerfile.fixed` for production builds
- **NEVER** use `Dockerfile` (contains buggy entrypoint wrapper)
- Always build with `--platform linux/amd64` for AWS Fargate
- Test images in DEV/SIT before PROD deployment
- Add image validation to CI/CD pipeline

**Reference:**
- Incident: 2025-12-24 PROD wp-config.php corruption
- Fixed image: prod-wordpress:20251224-fixed
- Bug fix commit: [Add reference when merged]

---

## Rollback

### When to Rollback

- Deployment causes service outages
- Database corruption detected
- Security vulnerability introduced
- Unable to resolve issues within 1 hour

### Rollback Procedure

#### Option 1: Terraform Destroy (Complete Removal)

```bash
cd /path/to/2_bbws_ecs_terraform/terraform/tenants/${TENANT_NAME}

# Destroy all resources
terraform destroy -var-file=${ENVIRONMENT}.tfvars -auto-approve
```

**This will delete:**
- ECS service and tasks
- Target group
- ALB listener rule
- EFS access point
- Secrets Manager secret (with 7-day recovery window)

**This will NOT delete:**
- Database (manual deletion required)
- Database user (manual deletion required)

#### Option 2: Disable Service (Soft Rollback)

```bash
# Scale service to 0
aws ecs update-service \
  --region ${AWS_REGION} \
  --cluster ${ENVIRONMENT}-cluster \
  --service ${ENVIRONMENT}-${TENANT_NAME}-service \
  --desired-count 0

# Remove ALB listener rule
RULE_ARN=$(aws elbv2 describe-rules \
  --region ${AWS_REGION} \
  --listener-arn [LISTENER_ARN] \
  --query 'Rules[?Priority==`'${ALB_PRIORITY}'`].RuleArn' \
  --output text)

aws elbv2 delete-rule --rule-arn $RULE_ARN
```

**Advantage:** Can re-enable quickly if issue resolved

#### Manual Database Cleanup (if needed)

```bash
# Connect to RDS master
# Use db-init ECS task or mysql client

# Drop database and user
DROP DATABASE IF EXISTS ${TENANT_NAME}_db;
DROP USER IF EXISTS '${TENANT_NAME}_user'@'%';
FLUSH PRIVILEGES;
```

---

## Reference

### Environment Configurations

| Environment | Region | Account ID | VPC | ALB | RDS | CloudFront |
|-------------|--------|------------|-----|-----|-----|------------|
| DEV | eu-west-1 | 536580886816 | dev-vpc | dev-alb | dev-mysql | No |
| SIT | eu-west-1 | 815856636111 | sit-vpc | sit-alb | sit-mysql | Yes |
| PROD | af-south-1 | 093646564004 | prod-vpc | prod-alb | prod-mysql | Yes |

### AWS Profiles

```bash
# ~/.aws/config
[profile Tebogo-dev]
sso_start_url = [SSO_URL]
sso_region = eu-west-1
sso_account_id = 536580886816
sso_role_name = AdministratorAccess
region = eu-west-1

[profile Tebogo-sit]
sso_start_url = [SSO_URL]
sso_region = eu-west-1
sso_account_id = 815856636111
sso_role_name = AdministratorAccess
region = eu-west-1

[profile Tebogo-prod]
sso_start_url = [SSO_URL]
sso_region = af-south-1
sso_account_id = 093646564004
sso_role_name = AdministratorAccess
region = af-south-1
```

### Resource Naming Conventions

```
Format: ${ENVIRONMENT}-${TENANT_NAME}-${RESOURCE_TYPE}

Examples:
- sit-goldencrust-service
- sit-goldencrust-tg
- sit-goldencrust-db-credentials
- sit-goldencrust (task definition family)
```

### Important ARNs and IDs

**Execution Role:**
```
DEV:  arn:aws:iam::536580886816:role/dev-ecs-task-execution-role
SIT:  arn:aws:iam::815856636111:role/sit-ecs-task-execution-role
PROD: arn:aws:iam::093646564004:role/prod-ecs-task-execution-role
```

**CloudFront Hosted Zone:** `Z2FDTNDATAQYW2` (global constant)

### Support Contacts

- **DevOps Lead:** [Name/Email]
- **Platform Team:** [Slack Channel]
- **On-Call:** [PagerDuty/Phone]

### Related Documents

- `02-CLOUDFRONT-BASIC-AUTH-UPDATE.md` - Update Basic Auth password
- `03-ALB-PRIORITY-MANAGEMENT.md` - ALB priority allocation
- `04-DATABASE-MIGRATION.md` - Migrate tenant between environments
- `05-TROUBLESHOOTING-GUIDE.md` - Comprehensive troubleshooting

---

## Incident History

### 2025-12-24: PROD wp-config.php Corruption (Severity: Critical)

**Impact:**
- Services affected: goldencrust, bbwstrustedservice
- Duration: ~2 hours
- User impact: HTTP 500 errors for both services
- Availability: 2/4 PROD services down (50%)

**Root Cause:**
- Corrupted WordPress Docker image in ECR
- Bug in `docker-entrypoint-wrapper.sh:16` injecting duplicate PHP opening tag
- Caused PHP parse error in wp-config.php on line 2

**Timeline:**
- Initial detection: Manual health check revealed HTTP 500 responses
- Investigation: Identified PHP parse errors in container logs
- Database verification: Confirmed databases and credentials correct
- Image analysis: Discovered bug in custom entrypoint wrapper
- Resolution: Built fixed image using Dockerfile.fixed with linux/amd64 architecture
- Validation: All services returned to healthy state

**Resolution:**
1. Built new image using `Dockerfile.fixed` instead of `Dockerfile`
2. Compiled for linux/amd64 platform (AWS Fargate requirement)
3. Pushed to ECR as `prod-wordpress:20251224-fixed`
4. Created new task definitions: prod-goldencrust:2, prod-bbwstrustedservice:4
5. Force deployed both services
6. Verified all targets healthy

**Lessons Learned:**
- Always use `Dockerfile.fixed` for production builds
- Never use `Dockerfile` (contains buggy entrypoint wrapper)
- Build images for linux/amd64 architecture explicitly
- Test Docker images in DEV/SIT before PROD deployment
- Add image validation to CI/CD pipeline
- Document image inconsistencies across environments (DEV/SIT use Docker Hub, PROD uses ECR)

**Preventive Actions:**
- Updated runbook with Issue 6 troubleshooting section
- Added Docker Image Management section with build instructions
- Added image architecture validation steps
- Documented bug location and fixed image digest
- Recommended standardizing all environments on ECR images

**References:**
- Fixed image: `prod-wordpress:20251224-fixed`
- Fixed digest: `sha256:760e4faa0db7d55acd427512f718466ca7625f4a4798e9827f54396bc367d646`
- Corrupted digest: `sha256:43604b53a1d0a32d515507909b2dc68da6cfae217da1098b43c431d40b3712f3`
- Bug location: `2_bbws_wordpress_container/docker/docker-entrypoint-wrapper.sh:16`

---

## Changelog

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.1 | 2025-12-24 | DevOps Team | Added Issue 6 (wp-config.php corruption), Docker Image Management section, image architecture validation, and incident history from PROD investigation |
| 1.0 | 2025-12-24 | DevOps Team | Initial version based on bbwsmytestingdomain deployment |

---

## Appendix

### A. Quick Reference Commands

```bash
# Check service status
aws ecs describe-services --cluster ${ENVIRONMENT}-cluster --services ${ENVIRONMENT}-${TENANT_NAME}-service --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}'

# Check target health
TG_ARN=$(aws elbv2 describe-target-groups --names ${ENVIRONMENT}-${TENANT_NAME}-tg --query 'TargetGroups[0].TargetGroupArn' --output text)
aws elbv2 describe-target-health --target-group-arn $TG_ARN

# View logs (last 5 minutes)
aws logs tail /ecs/${ENVIRONMENT} --log-stream-names "${TENANT_NAME}/wordpress/*" --since 5m --follow

# Force new deployment
aws ecs update-service --cluster ${ENVIRONMENT}-cluster --service ${ENVIRONMENT}-${TENANT_NAME}-service --force-new-deployment

# Get database credentials
aws secretsmanager get-secret-value --secret-id ${ENVIRONMENT}-${TENANT_NAME}-db-credentials --query SecretString --output text | jq .
```

### B. Checklist Summary

**Pre-Deployment:**
- [ ] Tenant name decided
- [ ] ALB priority allocated
- [ ] AWS profile configured
- [ ] Terraform installed

**Deployment:**
- [ ] Tenant directory created
- [ ] tfvars updated
- [ ] ALB priority verified unique
- [ ] Terraform plan reviewed
- [ ] Terraform apply completed
- [ ] IAM permissions granted
- [ ] Service redeployed

**Validation:**
- [ ] Database accessible
- [ ] ECS service healthy
- [ ] ALB target healthy
- [ ] HTTP returns 302
- [ ] HTTPS returns 302
- [ ] WordPress installation page loads

**Post-Deployment:**
- [ ] Deployment documented
- [ ] Priority spreadsheet updated
- [ ] Stakeholders notified
- [ ] WordPress installed

---

**END OF RUNBOOK**
