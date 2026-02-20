# BBWS Multi-Tenant WordPress - Complete Lifecycle Guide

**Last Updated:** 2025-12-21
**Status:** Production-Ready (with known issues)

## Table of Contents

1. [Overview](#overview)
2. [Environment Architecture](#environment-architecture)
3. [Tenant Creation Process](#tenant-creation-process)
4. [Site Deployment](#site-deployment)
5. [DNS & CloudFront Configuration](#dns--cloudfront-configuration)
6. [Basic Auth Protection](#basic-auth-protection)
7. [Promotion Workflows](#promotion-workflows)
8. [Known Issues & Pitfalls](#known-issues--pitfalls)
9. [Automation Scripts](#automation-scripts)
10. [Troubleshooting Guide](#troubleshooting-guide)

---

## Overview

### System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         CloudFront (CDN)                         │
│  - *.wpdev.kimmyai.io (DEV)                                     │
│  - *.wpsit.kimmyai.io (SIT) + Basic Auth                       │
│  - *.wp.kimmyai.io (PROD) + Basic Auth                         │
└────────────────┬────────────────────────────────────────────────┘
                 │
┌────────────────┴────────────────────────────────────────────────┐
│                    Application Load Balancer                     │
│  - Host-based routing (ALB Listener Rules)                      │
│  - Health checks: / (200, 301, 302)                            │
└────────────────┬────────────────────────────────────────────────┘
                 │
┌────────────────┴────────────────────────────────────────────────┐
│                      ECS Fargate Services                        │
│  Per Tenant:                                                     │
│  - Task Definition (WordPress container)                        │
│  - Service (desired count: 1)                                   │
│  - Target Group                                                  │
└─────┬──────────────────────────────────┬────────────────────────┘
      │                                  │
┌─────┴─────────┐              ┌─────────┴──────────┐
│   RDS MySQL   │              │    EFS Storage     │
│ (Shared)      │              │  (Per-tenant AP)   │
│ - tenant DBs  │              │  - /wp-content     │
└───────────────┘              └────────────────────┘
```

### Environments

| Environment | Region     | AWS Account  | Domain Pattern              | Status  |
|-------------|------------|--------------|----------------------------|---------|
| DEV         | eu-west-1  | 536580886816 | {tenant}.wpdev.kimmyai.io | Active  |
| SIT         | eu-west-1  | 815856636111 | {tenant}.wpsit.kimmyai.io | Active  |
| PROD        | af-south-1 | 093646564004 | {tenant}.wp.kimmyai.io    | Planned |

### Technology Stack

- **Container Orchestration:** AWS ECS Fargate
- **Load Balancer:** Application Load Balancer (ALB)
- **Database:** RDS MySQL 8.0 (db.t3.micro)
- **File Storage:** EFS with per-tenant access points
- **CDN:** CloudFront with Lambda@Edge for Basic Auth
- **Secrets:** AWS Secrets Manager
- **IaC:** Terraform
- **CI/CD:** GitHub Actions
- **Container Image:** wordpress:latest (official)

---

## Environment Architecture

### DEV Environment (eu-west-1)

**Purpose:** Development and initial tenant testing

**Infrastructure:**
- ECS Cluster: `dev-cluster`
- RDS: `dev-mysql` (db.t3.micro)
- ALB: `dev-alb`
- EFS: `dev-efs`
- CloudFront: Distribution ID `E2XXXXXX`
- VPC: 10.1.0.0/16

**Current Tenants (13):**
1. tenant1 (tenant-1) - Demo tenant
2. tenant2 (tenant-2) - Demo tenant
3. goldencrust - Bakery demo
4. sunsetbistro - Restaurant demo
5. sterlinglaw - Law firm demo
6. ironpeak - Construction demo
7. premierprop - Real estate demo
8. lenslight - Photography demo
9. nexgentech - Tech startup demo
10. serenity - Spa/wellness demo
11. bloompetal - Florist demo
12. precisionauto - Auto repair demo
13. bbwstrustedservice - Service demo

### SIT Environment (eu-west-1)

**Purpose:** System Integration Testing before production

**Infrastructure:**
- ECS Cluster: `sit-cluster`
- RDS: `sit-mysql` (db.t3.micro, 7-day backup)
- ALB: `sit-alb`
- EFS: `sit-efs`
- CloudFront: Distribution with Basic Auth
- VPC: 10.2.0.0/16
- Basic Auth: Username `bbws-sit` (password in Secrets Manager)

**Current Status:**
- Base infrastructure: ✅ Deployed
- Tenants deployed: 1/13 (goldencrust fully working)
- Batch 1 partial: sunsetbistro (✅), sterlinglaw (⚠️ HTTP 500), tenant1 (⏳ starting)

### PROD Environment (af-south-1)

**Purpose:** Production workloads

**Status:** 🚧 Infrastructure ready, DR configured
**DR Strategy:** Multi-site active/active (Primary: af-south-1, DR: eu-west-1)

---

## Tenant Creation Process

### Prerequisites

1. **AWS SSO Login:**
   ```bash
   aws sso login --profile Tebogo-dev  # or Tebogo-sit, Tebogo-prod
   ```

2. **Required Information:**
   - Tenant name (lowercase, no special chars except dash)
   - ALB priority (unique, 10-260)
   - Target environment (dev/sit/prod)

### Step 1: Generate Terraform Configuration

**Script:** `utils/generate_sit_tenant_tf.sh` (needs to be created)

**Manual Process (Current):**

1. **Copy template from existing tenant:**
   ```bash
   cd /path/to/2_bbws_ecs_terraform/terraform

   # For SIT
   cp goldencrust.tf sit_newtenant.tf
   ```

2. **Update all occurrences:**
   ```bash
   # Replace tenant name throughout file
   sed -i '' 's/goldencrust/newtenant/g' sit_newtenant.tf

   # Update priority (find unique number)
   sed -i '' 's/priority     = 140/priority     = 270/' sit_newtenant.tf

   # Update domain
   sed -i '' 's/goldencrust.wpdev/newtenant.wpsit/g' sit_newtenant.tf
   ```

3. **Critical: Update resource names with sit_ prefix:**
   ```hcl
   # All resources must be prefixed with sit_ for SIT environment
   resource "random_password" "sit_newtenant_db" {
   resource "aws_secretsmanager_secret" "sit_newtenant_db" {
   resource "aws_efs_access_point" "sit_newtenant" {
   resource "aws_ecs_task_definition" "sit_newtenant" {
   resource "aws_lb_target_group" "sit_newtenant" {
   resource "aws_lb_listener_rule" "sit_newtenant" {
   resource "aws_ecs_service" "sit_newtenant" {
   ```

**⚠️ CRITICAL PITFALL:**
- Resource names MUST have environment prefix (sit_, prod_)
- Terraform will fail if resource names conflict with DEV
- Secret names use dashes: `sit-newtenant-db-credentials`
- Database names use underscores: `newtenant_db`

### Step 2: Create Database

**Option A: Manual Creation (Current Working Method)**

1. **Generate random password:**
   ```bash
   openssl rand -base64 18 | tr -d '/+=' | cut -c1-24
   ```

2. **Create Secrets Manager secret:**
   ```bash
   PASSWORD="<generated_password>"
   TENANT="newtenant"
   ENV="sit"

   aws secretsmanager create-secret \
     --name ${ENV}-${TENANT}-db-credentials \
     --description "Database credentials for ${TENANT}" \
     --secret-string "{\"username\":\"${TENANT}_user\",\"password\":\"$PASSWORD\",\"database\":\"${TENANT}_db\",\"host\":\"${ENV}-mysql.xxxxx.eu-west-1.rds.amazonaws.com\",\"port\":3306}" \
     --region eu-west-1 \
     --profile Tebogo-${ENV}
   ```

3. **Get RDS endpoint:**
   ```bash
   aws rds describe-db-instances \
     --db-instance-identifier sit-mysql \
     --region eu-west-1 \
     --profile Tebogo-sit \
     --query 'DBInstances[0].Endpoint.Address' \
     --output text
   ```

4. **Get RDS master credentials:**
   ```bash
   aws secretsmanager get-secret-value \
     --secret-id sit-rds-master-credentials \
     --region eu-west-1 \
     --profile Tebogo-sit \
     --query 'SecretString' \
     --output text | jq -r '.username, .password'
   ```

5. **Create database via ECS task:**
   ```bash
   # Create task override JSON
   cat > /tmp/create_${TENANT}_db.json <<EOF
   {
     "containerOverrides": [{
       "name": "mysql-client",
       "command": [
         "sh",
         "-c",
         "mysql -h <RDS_ENDPOINT> -u admin -p<MASTER_PASSWORD> <<'SQL'
   CREATE DATABASE IF NOT EXISTS ${TENANT}_db;
   CREATE USER IF NOT EXISTS '${TENANT}_user'@'%' IDENTIFIED BY '$PASSWORD';
   GRANT ALL PRIVILEGES ON ${TENANT}_db.* TO '${TENANT}_user'@'%';
   FLUSH PRIVILEGES;
   SELECT 'Database created successfully' AS status;
   SQL
   "
       ]
     }]
   }
   EOF

   # Run task
   aws ecs run-task \
     --cluster sit-cluster \
     --task-definition sit-generic-db-init:1 \
     --launch-type FARGATE \
     --network-configuration "awsvpcConfiguration={subnets=[subnet-09d1d2de85ae02264],securityGroups=[sg-01bca1fb9806ad397],assignPublicIp=DISABLED}" \
     --region eu-west-1 \
     --profile Tebogo-sit \
     --overrides file:///tmp/create_${TENANT}_db.json
   ```

6. **Verify database creation:**
   ```bash
   # Check task logs
   TASK_ARN=<from previous command>
   TASK_ID=$(echo $TASK_ARN | awk -F'/' '{print $NF}')

   aws logs get-log-events \
     --log-group-name /ecs/sit \
     --log-stream-name "db-init/mysql-client/${TASK_ID}" \
     --region eu-west-1 \
     --profile Tebogo-sit \
     --query 'events[*].message' \
     --output text
   ```

**Option B: Terraform (Planned - Not Working)**

Issue: Terraform null_resource provisioner requires local-exec which is unreliable

### Step 3: Create IAM Policies

**Create secret access policy:**

```bash
TENANT="newtenant"
SECRET_ARN=$(aws secretsmanager describe-secret \
  --secret-id sit-${TENANT}-db-credentials \
  --region eu-west-1 \
  --profile Tebogo-sit \
  --query 'ARN' \
  --output text)

cat > /tmp/${TENANT}-secrets-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["secretsmanager:GetSecretValue"],
    "Resource": [
      "${SECRET_ARN}",
      "${SECRET_ARN}*"
    ]
  }]
}
EOF

aws iam put-role-policy \
  --role-name sit-ecs-task-execution-role \
  --policy-name sit-ecs-secrets-access-${TENANT} \
  --policy-document file:///tmp/${TENANT}-secrets-policy.json \
  --region eu-west-1 \
  --profile Tebogo-sit
```

### Step 4: Deploy Infrastructure with Terraform

1. **Initialize Terraform:**
   ```bash
   cd /path/to/2_bbws_ecs_terraform/terraform

   AWS_PROFILE=Tebogo-sit terraform init \
     -backend-config=environments/sit/backend-sit.hcl

   terraform workspace select sit
   ```

2. **Import existing resources:**
   ```bash
   # Import secret
   terraform import \
     -var-file=environments/sit/sit.tfvars \
     aws_secretsmanager_secret.sit_${TENANT}_db \
     ${SECRET_ARN}
   ```

3. **Plan deployment:**
   ```bash
   terraform plan \
     -var-file=environments/sit/sit.tfvars \
     -target=aws_ecs_service.sit_${TENANT} \
     -out=sit-${TENANT}.tfplan
   ```

4. **Review plan output:**
   - Should create: ~7 resources per tenant
   - EFS access point
   - Task definition
   - Target group
   - Listener rule
   - ECS service
   - IAM policies (if in Terraform)

5. **Apply:**
   ```bash
   terraform apply sit-${TENANT}.tfplan
   ```

**⚠️ KNOWN ISSUE:**
- Terraform may try to create secrets that already exist
- Workaround: Import all existing resources first
- Better solution: Remove secret creation from Terraform, create manually

### Step 5: Verify Deployment

1. **Check ECS service status:**
   ```bash
   aws ecs describe-services \
     --cluster sit-cluster \
     --services sit-${TENANT}-service \
     --region eu-west-1 \
     --profile Tebogo-sit \
     --query 'services[0].[serviceName,status,desiredCount,runningCount]' \
     --output table
   ```

2. **Check target health:**
   ```bash
   TG_ARN=$(aws elbv2 describe-target-groups \
     --names sit-${TENANT}-tg \
     --region eu-west-1 \
     --profile Tebogo-sit \
     --query 'TargetGroups[0].TargetGroupArn' \
     --output text)

   aws elbv2 describe-target-health \
     --target-group-arn $TG_ARN \
     --region eu-west-1 \
     --profile Tebogo-sit
   ```

3. **Test HTTP endpoint:**
   ```bash
   curl -I http://${TENANT}.wpsit.kimmyai.io
   # Should return: HTTP/1.1 200 OK (or 301/302 for redirects)
   ```

4. **Check CloudWatch logs:**
   ```bash
   aws logs tail /ecs/sit \
     --since 5m \
     --filter-pattern "${TENANT}" \
     --format short \
     --region eu-west-1 \
     --profile Tebogo-sit
   ```

---

## Site Deployment

### WordPress Installation

1. **Access WordPress setup:**
   ```
   https://${TENANT}.wpsit.kimmyai.io/wp-admin/install.php
   ```

2. **Installation wizard:**
   - Site Title: Client's business name
   - Username: Create admin user
   - Password: Strong password
   - Email: Client's email
   - Search Engine Visibility: Discourage (for non-prod)

3. **Verify installation:**
   - Access /wp-admin
   - Check database connection
   - Upload test media file (verifies EFS)

### Content Migration (DEV → SIT)

**⚠️ NOT YET AUTOMATED**

**Manual Process:**

1. **Export from DEV:**
   ```bash
   # Via WordPress Tools → Export
   # OR via WP-CLI in container
   ```

2. **Database dump (if needed):**
   ```bash
   # Get DEV database credentials
   DEV_SECRET=$(aws secretsmanager get-secret-value \
     --secret-id dev-${TENANT}-db-credentials \
     --region eu-west-1 \
     --profile Tebogo-dev \
     --query 'SecretString' \
     --output text)

   # Dump via ECS task with mysqldump
   # (requires custom task definition with mysqldump)
   ```

3. **URL search-replace:**
   ```sql
   UPDATE wp_options
   SET option_value = REPLACE(option_value, 'wpdev.kimmyai.io', 'wpsit.kimmyai.io');

   UPDATE wp_posts
   SET post_content = REPLACE(post_content, 'wpdev.kimmyai.io', 'wpsit.kimmyai.io');

   UPDATE wp_posts
   SET guid = REPLACE(guid, 'wpdev.kimmyai.io', 'wpsit.kimmyai.io');
   ```

4. **wp-content migration:**
   ```bash
   # Via DataSync or manual EFS copy
   # NOT YET IMPLEMENTED
   ```

---

## DNS & CloudFront Configuration

### Current Setup

**CloudFront Distributions:**
- DEV: `E2XXXXXX` → dev-alb.eu-west-1.elb.amazonaws.com
- SIT: `EXXXXXXX` → sit-alb.eu-west-1.elb.amazonaws.com
- PROD: Not yet created

**DNS (Route53):**
- Zone: `kimmyai.io` (hosted in PROD account)
- Delegated subdomains:
  - `wpdev.kimmyai.io` → DEV CloudFront
  - `wpsit.kimmyai.io` → SIT CloudFront
  - `wp.kimmyai.io` → PROD CloudFront (planned)

### DNS Configuration Process

**⚠️ MANUAL PROCESS - NOT AUTOMATED**

1. **Verify CloudFront distribution:**
   ```bash
   aws cloudfront list-distributions \
     --region us-east-1 \
     --profile Tebogo-sit \
     --query 'DistributionList.Items[*].[Id,DomainName,Aliases]' \
     --output table
   ```

2. **Add tenant to CloudFront aliases:**
   - Currently: Wildcard `*.wpsit.kimmyai.io` handles all tenants
   - No per-tenant configuration needed
   - ACM certificate must cover wildcard

3. **Verify ACM certificate:**
   ```bash
   aws acm list-certificates \
     --region us-east-1 \
     --profile Tebogo-sit \
     --query 'CertificateSummaryList[*].[DomainName,CertificateArn]' \
     --output table
   ```

4. **Test DNS resolution:**
   ```bash
   dig ${TENANT}.wpsit.kimmyai.io
   nslookup ${TENANT}.wpsit.kimmyai.io
   ```

### CloudFront Cache Behavior

**Current Settings:**
- Default TTL: 0 (no caching for WordPress admin)
- Query strings: Forwarded
- Cookies: Forwarded (required for WordPress)
- Headers: Host, CloudFront-Forwarded-Proto

**⚠️ ISSUE:**
- No caching may impact performance
- **TODO:** Implement selective caching for static assets

---

## Basic Auth Protection

### SIT Environment Protection

**Mechanism:** Lambda@Edge function on CloudFront

**Current Status:** ✅ Working

**Configuration:**

1. **Lambda function:** `BasicAuthFunction`
   - Region: us-east-1 (required for Lambda@Edge)
   - Runtime: Node.js
   - Attached to CloudFront viewer request

2. **Credentials:**
   ```
   Username: bbws-sit
   Password: <stored in sit-basic-auth-password secret>
   ```

3. **Testing:**
   ```bash
   # Without auth
   curl -I https://${TENANT}.wpsit.kimmyai.io
   # Returns: HTTP/1.1 401 Unauthorized

   # With auth
   curl -I -u "bbws-sit:PASSWORD" https://${TENANT}.wpsit.kimmyai.io
   # Returns: HTTP/1.1 200 OK
   ```

### PROD Environment Protection

**Status:** 🚧 Planned

**TODO:**
- Create Lambda@Edge function for PROD
- Store credentials in prod-basic-auth-password secret
- Attach to PROD CloudFront distribution

---

## Promotion Workflows

### DEV → SIT Promotion

**Current Status:** ⚠️ Manual process, partial automation

**GitHub Actions Workflow:** NOT YET IMPLEMENTED

**Manual Process (Current):**

1. **Create SIT Terraform files:**
   ```bash
   ./utils/generate_sit_tenant_tf.sh ${TENANT} ${PRIORITY}
   ```

2. **Create database:**
   - Follow "Step 2: Create Database" above

3. **Apply Terraform:**
   ```bash
   cd terraform
   terraform apply -var-file=environments/sit/sit.tfvars \
     -target=aws_ecs_service.sit_${TENANT}
   ```

4. **Migrate content (manual):**
   - Database export/import
   - URL search-replace
   - wp-content copy

5. **Verify deployment:**
   - Service health
   - Target health
   - HTTP endpoint
   - WordPress admin access

**Proposed GitHub Actions Workflow:**

```yaml
name: Promote Tenant to SIT

on:
  workflow_dispatch:
    inputs:
      tenant_name:
        description: 'Tenant name to promote'
        required: true
      alb_priority:
        description: 'ALB listener rule priority'
        required: true

jobs:
  promote-to-sit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::815856636111:role/github-actions-role
          aws-region: eu-west-1

      - name: Generate SIT Terraform config
        run: |
          ./utils/generate_sit_tenant_tf.sh ${{ inputs.tenant_name }} ${{ inputs.alb_priority }}

      - name: Create database
        run: |
          ./utils/create_sit_database.sh ${{ inputs.tenant_name }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2

      - name: Terraform Init
        run: |
          cd terraform
          terraform init -backend-config=environments/sit/backend-sit.hcl

      - name: Terraform Apply
        run: |
          cd terraform
          terraform apply -var-file=environments/sit/sit.tfvars \
            -target=aws_ecs_service.sit_${{ inputs.tenant_name }} \
            -auto-approve

      - name: Verify deployment
        run: |
          ./utils/verify_deployment.sh sit ${{ inputs.tenant_name }}

      - name: Commit Terraform changes
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add terraform/sit_${{ inputs.tenant_name }}.tf
          git commit -m "feat: promote ${{ inputs.tenant_name }} to SIT"
          git push
```

**Required Secrets:**
- `AWS_ASSUME_ROLE_ARN_SIT`
- `SIT_RDS_MASTER_PASSWORD` (or use Secrets Manager)

### SIT → PROD Promotion

**Status:** 🚧 NOT YET IMPLEMENTED

**Prerequisites:**
1. PROD infrastructure must be deployed
2. GitHub Actions workflow for PROD
3. Approval gates in workflow
4. Automated testing in SIT

**Proposed Workflow:**

```yaml
name: Promote Tenant to PROD

on:
  workflow_dispatch:
    inputs:
      tenant_name:
        description: 'Tenant name to promote to PROD'
        required: true

jobs:
  validate-sit:
    runs-on: ubuntu-latest
    steps:
      - name: Run SIT validation tests
        run: |
          ./utils/validate_sit_tenant.sh ${{ inputs.tenant_name }}

  promote-to-prod:
    needs: validate-sit
    runs-on: ubuntu-latest
    environment: production  # Requires manual approval
    steps:
      - name: Promote to PROD
        # Similar to SIT promotion but with PROD configs
```

---

## Known Issues & Pitfalls

### 1. Terraform State Management Issues

**Issue:** Terraform tries to create resources that already exist

**Symptom:**
```
Error: creating Secrets Manager Secret (sit-tenant-db-credentials):
ResourceExistsException: The operation failed because the secret already exists.
```

**Root Cause:**
- Manual resource creation not tracked in Terraform state
- Secrets created via AWS CLI bypass Terraform

**Workaround:**
```bash
# Import existing resources
terraform import aws_secretsmanager_secret.sit_${TENANT}_db <SECRET_ARN>
terraform import aws_lb_target_group.sit_${TENANT} <TG_ARN>
```

**Permanent Fix:**
- Option A: Remove secret creation from Terraform (RECOMMENDED)
- Option B: Always use Terraform for all resources
- Option C: Implement drift detection

### 2. Resource Naming Conflicts (DEV vs SIT)

**Issue:** Duplicate resource names between environments

**Symptom:**
```
Error: Duplicate resource "random_password" configuration
A random_password resource named "tenant_2_db" was already declared
```

**Root Cause:**
- DEV tenant files (tenant1.tf, tenant2.tf) exist in same directory as SIT files
- Terraform evaluates all *.tf files
- Resource names must be unique across all files

**Solution:**
- Prefix all SIT resources with `sit_`
- Example: `resource "aws_ecs_service" "sit_tenant1"` not `"tenant1"`
- Ensure consistent naming: sit-tenant-1 (dashes) vs sit_tenant_1 (underscores)

**Naming Convention:**
- Terraform resource names: `sit_tenant_1` (underscores)
- AWS resource names: `sit-tenant-1` (dashes)
- Database names: `tenant_1_db` (underscores)
- Secret names: `sit-tenant1-db-credentials` (dashes, NO underscore between sit and tenant)

### 3. IAM Secret Permissions

**Issue:** ECS tasks can't access secrets

**Symptom:**
```
ResourceInitializationError: unable to pull secrets or registry auth
AccessDeniedException: User is not authorized to perform:
secretsmanager:GetSecretValue on resource
```

**Root Cause:**
- Each tenant secret needs explicit IAM permission
- `sit-ecs-task-execution-role` must allow GetSecretValue for specific secret ARNs
- Terraform-created secrets may have different ARNs than manually created

**Solution:**
```bash
# Create per-tenant IAM policy
aws iam put-role-policy \
  --role-name sit-ecs-task-execution-role \
  --policy-name sit-ecs-secrets-access-${TENANT} \
  --policy-document file://policy.json
```

**Prevention:**
- Automate IAM policy creation in tenant deployment script
- OR use wildcard permission: `sit-*-db-credentials*` (less secure)

### 4. WordPress wp-config.php Issues

**Issue:** WordPress returns HTTP 500 or "wp-config.php not found"

**Root Cause:**
- Custom ECR images don't auto-generate wp-config.php
- Official wordpress:latest image does

**Solution:**
```hcl
# In sit.tfvars
use_ecr_image       = false
wordpress_image     = "wordpress"
wordpress_image_tag = "latest"
```

**Prevention:**
- Always use official wordpress:latest for new deployments
- If custom image needed, ensure entrypoint creates wp-config.php

### 5. Database Connection Errors (HTTP 500)

**Issue:** WordPress shows HTTP 500, logs show database connection failures

**Possible Causes:**
1. Database not created: `Unknown database 'tenant_db'`
2. Wrong credentials: `Access denied for user 'tenant_user'`
3. Wrong hostname: DNS resolution failure
4. Security group: RDS security group doesn't allow ECS tasks

**Diagnosis:**
```bash
# Check task logs
aws logs tail /ecs/sit --since 10m --filter-pattern "${TENANT}" --format short

# Common errors:
# - SQLSTATE[HY000] [1049] Unknown database
# - SQLSTATE[HY000] [1045] Access denied
# - SQLSTATE[HY000] [2002] Connection timed out
```

**Solutions:**
- Verify database exists: `SHOW DATABASES LIKE '%tenant%';`
- Verify user exists: `SELECT User FROM mysql.user WHERE User LIKE '%tenant%';`
- Check RDS endpoint in secret matches actual RDS address
- Verify ECS security group has access to RDS security group

### 6. ALB Listener Rule Priority Conflicts

**Issue:**
```
Error: creating ELBv2 Listener Rule: Priority '140' is currently in use
```

**Solution:**
- Maintain priority allocation spreadsheet
- Check existing priorities:
  ```bash
  aws elbv2 describe-rules \
    --listener-arn <LISTENER_ARN> \
    --query 'Rules[*].[Priority,Conditions[0].Values[0]]' \
    --output table
  ```

**Current Allocations (SIT):**
- goldencrust: 140
- tenant1: 150
- tenant2: 160
- sunsetbistro: 170
- sterlinglaw: 180
- Next available: 190+

### 7. Target Health Check Failures

**Issue:** Targets show "unhealthy" or "draining"

**Common Reasons:**
1. **ResponseCodeMismatch:** WordPress returns 500 instead of 200
2. **Target.Timeout:** Health check timeout (>5s response)
3. **Target.FailedHealthChecks:** 3+ consecutive failures

**Health Check Settings:**
```hcl
health_check {
  enabled             = true
  healthy_threshold   = 2
  interval            = 30
  matcher             = "200,301,302"  # Accept redirects
  path                = "/"
  timeout             = 5
  unhealthy_threshold = 3
}
```

**Debugging:**
```bash
# Get target health details
aws elbv2 describe-target-health \
  --target-group-arn <TG_ARN> \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Reason,TargetHealth.Description]'

# Test health check path directly
TASK_IP=<from above>
curl -I http://$TASK_IP/
```

### 8. CloudFront Basic Auth Not Working

**Issue:** Can access site without credentials

**Causes:**
- Lambda@Edge not deployed
- Lambda not attached to correct CloudFront behavior
- Function not yet replicated to edge locations (can take 15-30 min)

**Verification:**
```bash
# Test without auth
curl -I https://${TENANT}.wpsit.kimmyai.io
# Should return: HTTP/1.1 401 Unauthorized

# Check CloudFront distribution
aws cloudfront get-distribution --id <DIST_ID> \
  --query 'Distribution.DistributionConfig.DefaultCacheBehavior.LambdaFunctionAssociations'
```

### 9. Slow Deployment Times

**Observation:** Full tenant deployment takes 30-45 minutes

**Breakdown:**
- Terraform plan: 1-2 min
- Terraform apply: 5-10 min
- RDS modifications: 1-3 min (if needed)
- ECS service creation: 2-3 min
- Task startup: 2-5 min
- Target health check: 1-2 min (2 consecutive successes @ 30s interval)
- Manual steps (secrets, DB, IAM): 10-20 min

**Optimization:**
- Parallelize database creation and Terraform apply
- Pre-create IAM policies as part of base infrastructure
- Use faster RDS instance class for non-prod

### 10. Missing Automation Scripts

**Critical Gaps:**
- ❌ `generate_sit_tenant_tf.sh` - partially implemented
- ❌ `create_sit_database.sh` - not implemented
- ❌ `migrate_tenant_content.sh` - not implemented
- ❌ `verify_deployment.sh` - not implemented
- ✅ `health_check_sit.sh` - exists
- ✅ `get_tenant_urls.sh` - exists

---

## Automation Scripts

### Priority 1: Core Tenant Deployment

#### 1. generate_tenant_tf.sh

**Status:** 🚧 NEEDS CREATION

**Purpose:** Generate environment-specific Terraform configuration from template

```bash
#!/bin/bash
# File: utils/generate_tenant_tf.sh

set -e

TENANT=$1
PRIORITY=$2
ENV=$3  # dev, sit, prod

if [[ -z "$TENANT" || -z "$PRIORITY" || -z "$ENV" ]]; then
  echo "Usage: $0 <tenant_name> <alb_priority> <environment>"
  exit 1
fi

TERRAFORM_DIR="../2_bbws_ecs_terraform/terraform"
TEMPLATE_FILE="${TERRAFORM_DIR}/goldencrust.tf"
OUTPUT_FILE="${TERRAFORM_DIR}/${ENV}_${TENANT}.tf"

# Check if tenant already exists
if [[ -f "$OUTPUT_FILE" ]]; then
  echo "Error: $OUTPUT_FILE already exists"
  exit 1
fi

# Generate from template
cp "$TEMPLATE_FILE" "$OUTPUT_FILE"

# Replace tenant name
sed -i '' "s/goldencrust/${TENANT}/g" "$OUTPUT_FILE"

# Update priority
sed -i '' "s/priority     = 140/priority     = ${PRIORITY}/" "$OUTPUT_FILE"

# Update domain based on environment
case $ENV in
  dev)
    DOMAIN="wpdev.kimmyai.io"
    ;;
  sit)
    DOMAIN="wpsit.kimmyai.io"
    ;;
  prod)
    DOMAIN="wp.kimmyai.io"
    ;;
esac

sed -i '' "s/wpdev.kimmyai.io/${DOMAIN}/g" "$OUTPUT_FILE"
sed -i '' "s/wpsit.kimmyai.io/${DOMAIN}/g" "$OUTPUT_FILE"

# Update resource names with environment prefix
sed -i '' "s/resource \"random_password\" \"${TENANT}_db\"/resource \"random_password\" \"${ENV}_${TENANT}_db\"/" "$OUTPUT_FILE"
sed -i '' "s/resource \"aws_secretsmanager_secret\" \"${TENANT}_db\"/resource \"aws_secretsmanager_secret\" \"${ENV}_${TENANT}_db\"/" "$OUTPUT_FILE"
sed -i '' "s/resource \"aws_efs_access_point\" \"${TENANT}\"/resource \"aws_efs_access_point\" \"${ENV}_${TENANT}\"/" "$OUTPUT_FILE"
sed -i '' "s/resource \"aws_ecs_task_definition\" \"${TENANT}\"/resource \"aws_ecs_task_definition\" \"${ENV}_${TENANT}\"/" "$OUTPUT_FILE"
sed -i '' "s/resource \"aws_lb_target_group\" \"${TENANT}\"/resource \"aws_lb_target_group\" \"${ENV}_${TENANT}\"/" "$OUTPUT_FILE"
sed -i '' "s/resource \"aws_lb_listener_rule\" \"${TENANT}\"/resource \"aws_lb_listener_rule\" \"${ENV}_${TENANT}\"/" "$OUTPUT_FILE"
sed -i '' "s/resource \"aws_ecs_service\" \"${TENANT}\"/resource \"aws_ecs_service\" \"${ENV}_${TENANT}\"/" "$OUTPUT_FILE"

# Update all resource references
sed -i '' "s/aws_secretsmanager_secret.${TENANT}_db/aws_secretsmanager_secret.${ENV}_${TENANT}_db/g" "$OUTPUT_FILE"
sed -i '' "s/aws_efs_access_point.${TENANT}/aws_efs_access_point.${ENV}_${TENANT}/g" "$OUTPUT_FILE"
sed -i '' "s/aws_ecs_task_definition.${TENANT}/aws_ecs_task_definition.${ENV}_${TENANT}/g" "$OUTPUT_FILE"
sed -i '' "s/aws_lb_target_group.${TENANT}/aws_lb_target_group.${ENV}_${TENANT}/g" "$OUTPUT_FILE"
sed -i '' "s/aws_lb_listener_rule.${TENANT}/aws_lb_listener_rule.${ENV}_${TENANT}/g" "$OUTPUT_FILE"

echo "✅ Generated: $OUTPUT_FILE"
echo "Next steps:"
echo "  1. Review the generated file"
echo "  2. Run: ./create_database.sh ${TENANT} ${ENV}"
echo "  3. Run: terraform apply -var-file=environments/${ENV}/${ENV}.tfvars -target=aws_ecs_service.${ENV}_${TENANT}"
```

#### 2. create_database.sh

**Status:** 🚧 NEEDS CREATION

```bash
#!/bin/bash
# File: utils/create_database.sh

set -e

TENANT=$1
ENV=$2

if [[ -z "$TENANT" || -z "$ENV" ]]; then
  echo "Usage: $0 <tenant_name> <environment>"
  exit 1
fi

# Get AWS profile
case $ENV in
  dev) PROFILE="Tebogo-dev" ;;
  sit) PROFILE="Tebogo-sit" ;;
  prod) PROFILE="Tebogo-prod" ;;
esac

REGION="eu-west-1"
if [[ "$ENV" == "prod" ]]; then
  REGION="af-south-1"
fi

# Generate password
PASSWORD=$(openssl rand -base64 18 | tr -d '/+=' | cut -c1-24)
echo "Generated password: $PASSWORD"
echo "$PASSWORD" > /tmp/${TENANT}_password.txt

# Get RDS endpoint
RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier ${ENV}-mysql \
  --region $REGION \
  --profile $PROFILE \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

echo "RDS Endpoint: $RDS_ENDPOINT"

# Create secret
aws secretsmanager create-secret \
  --name ${ENV}-${TENANT}-db-credentials \
  --description "Database credentials for ${TENANT}" \
  --secret-string "{\"username\":\"${TENANT}_user\",\"password\":\"$PASSWORD\",\"database\":\"${TENANT}_db\",\"host\":\"$RDS_ENDPOINT\",\"port\":3306}" \
  --region $REGION \
  --profile $PROFILE

SECRET_ARN=$(aws secretsmanager describe-secret \
  --secret-id ${ENV}-${TENANT}-db-credentials \
  --region $REGION \
  --profile $PROFILE \
  --query 'ARN' \
  --output text)

echo "✅ Secret created: $SECRET_ARN"

# Get RDS master credentials
MASTER_CREDS=$(aws secretsmanager get-secret-value \
  --secret-id ${ENV}-rds-master-credentials \
  --region $REGION \
  --profile $PROFILE \
  --query 'SecretString' \
  --output text)

MASTER_USER=$(echo $MASTER_CREDS | jq -r '.username')
MASTER_PASS=$(echo $MASTER_CREDS | jq -r '.password')

# Create task override for database creation
cat > /tmp/create_${TENANT}_db.json <<EOF
{
  "containerOverrides": [{
    "name": "mysql-client",
    "command": [
      "sh",
      "-c",
      "mysql -h ${RDS_ENDPOINT} -u ${MASTER_USER} -p${MASTER_PASS} <<'SQL'
CREATE DATABASE IF NOT EXISTS ${TENANT}_db;
CREATE USER IF NOT EXISTS '${TENANT}_user'@'%' IDENTIFIED BY '${PASSWORD}';
GRANT ALL PRIVILEGES ON ${TENANT}_db.* TO '${TENANT}_user'@'%';
FLUSH PRIVILEGES;
SELECT 'Database ${TENANT}_db created successfully' AS status;
SQL
"
    ]
  }]
}
EOF

# Get subnet and security group
SUBNET=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=${ENV}-private-subnet-*" \
  --region $REGION \
  --profile $PROFILE \
  --query 'Subnets[0].SubnetId' \
  --output text)

SG=$(aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=${ENV}-ecs-tasks-sg" \
  --region $REGION \
  --profile $PROFILE \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

# Run database creation task
TASK_ARN=$(aws ecs run-task \
  --cluster ${ENV}-cluster \
  --task-definition ${ENV}-generic-db-init:1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET],securityGroups=[$SG],assignPublicIp=DISABLED}" \
  --region $REGION \
  --profile $PROFILE \
  --overrides file:///tmp/create_${TENANT}_db.json \
  --query 'tasks[0].taskArn' \
  --output text)

echo "Database creation task: $TASK_ARN"
TASK_ID=$(echo $TASK_ARN | awk -F'/' '{print $NF}')

# Wait for task to complete
echo "Waiting for database creation..."
aws ecs wait tasks-stopped \
  --cluster ${ENV}-cluster \
  --tasks $TASK_ARN \
  --region $REGION \
  --profile $PROFILE

# Check logs
aws logs get-log-events \
  --log-group-name /ecs/${ENV} \
  --log-stream-name "db-init/mysql-client/${TASK_ID}" \
  --region $REGION \
  --profile $PROFILE \
  --query 'events[*].message' \
  --output text

echo "✅ Database created"
echo "Next step: Create IAM policy"
echo "  ./create_iam_policy.sh ${TENANT} ${ENV} ${SECRET_ARN}"
```

#### 3. create_iam_policy.sh

```bash
#!/bin/bash
# File: utils/create_iam_policy.sh

set -e

TENANT=$1
ENV=$2
SECRET_ARN=$3

if [[ -z "$TENANT" || -z "$ENV" ]]; then
  echo "Usage: $0 <tenant_name> <environment> [secret_arn]"
  exit 1
fi

case $ENV in
  dev) PROFILE="Tebogo-dev"; REGION="eu-west-1" ;;
  sit) PROFILE="Tebogo-sit"; REGION="eu-west-1" ;;
  prod) PROFILE="Tebogo-prod"; REGION="af-south-1" ;;
esac

# Get secret ARN if not provided
if [[ -z "$SECRET_ARN" ]]; then
  SECRET_ARN=$(aws secretsmanager describe-secret \
    --secret-id ${ENV}-${TENANT}-db-credentials \
    --region $REGION \
    --profile $PROFILE \
    --query 'ARN' \
    --output text)
fi

# Create policy document
cat > /tmp/${TENANT}-secrets-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["secretsmanager:GetSecretValue"],
    "Resource": [
      "${SECRET_ARN}",
      "${SECRET_ARN}*"
    ]
  }]
}
EOF

# Apply policy
aws iam put-role-policy \
  --role-name ${ENV}-ecs-task-execution-role \
  --policy-name ${ENV}-ecs-secrets-access-${TENANT} \
  --policy-document file:///tmp/${TENANT}-secrets-policy.json \
  --region $REGION \
  --profile $PROFILE

echo "✅ IAM policy created"
echo "Policy name: ${ENV}-ecs-secrets-access-${TENANT}"
echo "Attached to: ${ENV}-ecs-task-execution-role"
```

#### 4. deploy_tenant.sh (Master Script)

```bash
#!/bin/bash
# File: utils/deploy_tenant.sh
# Master script that orchestrates full tenant deployment

set -e

TENANT=$1
ENV=$2
PRIORITY=$3

if [[ -z "$TENANT" || -z "$ENV" || -z "$PRIORITY" ]]; then
  echo "Usage: $0 <tenant_name> <environment> <alb_priority>"
  echo "Example: $0 myclient sit 190"
  exit 1
fi

echo "========================================="
echo "Deploying tenant: $TENANT"
echo "Environment: $ENV"
echo "ALB Priority: $PRIORITY"
echo "========================================="

# Step 1: Generate Terraform config
echo ""
echo "[1/5] Generating Terraform configuration..."
./generate_tenant_tf.sh $TENANT $PRIORITY $ENV

# Step 2: Create database
echo ""
echo "[2/5] Creating database..."
./create_database.sh $TENANT $ENV

# Get secret ARN for next step
case $ENV in
  dev) PROFILE="Tebogo-dev"; REGION="eu-west-1" ;;
  sit) PROFILE="Tebogo-sit"; REGION="eu-west-1" ;;
  prod) PROFILE="Tebogo-prod"; REGION="af-south-1" ;;
esac

SECRET_ARN=$(aws secretsmanager describe-secret \
  --secret-id ${ENV}-${TENANT}-db-credentials \
  --region $REGION \
  --profile $PROFILE \
  --query 'ARN' \
  --output text)

# Step 3: Create IAM policy
echo ""
echo "[3/5] Creating IAM policies..."
./create_iam_policy.sh $TENANT $ENV $SECRET_ARN

# Step 4: Apply Terraform
echo ""
echo "[4/5] Deploying infrastructure with Terraform..."
cd ../2_bbws_ecs_terraform/terraform

terraform init -backend-config=environments/${ENV}/backend-${ENV}.hcl
terraform workspace select $ENV

terraform apply \
  -var-file=environments/${ENV}/${ENV}.tfvars \
  -target=aws_ecs_service.${ENV}_${TENANT} \
  -auto-approve

cd ../../2_bbws_agents/utils

# Step 5: Verify deployment
echo ""
echo "[5/5] Verifying deployment..."
./verify_deployment.sh $TENANT $ENV

echo ""
echo "========================================="
echo "✅ Deployment complete!"
echo "Tenant URL: https://${TENANT}.wp${ENV}.kimmyai.io"
echo "========================================="
```

### Priority 2: Verification & Testing

#### 5. verify_deployment.sh

```bash
#!/bin/bash
# File: utils/verify_deployment.sh

TENANT=$1
ENV=$2

if [[ -z "$TENANT" || -z "$ENV" ]]; then
  echo "Usage: $0 <tenant_name> <environment>"
  exit 1
fi

case $ENV in
  dev) PROFILE="Tebogo-dev"; REGION="eu-west-1"; DOMAIN="wpdev" ;;
  sit) PROFILE="Tebogo-sit"; REGION="eu-west-1"; DOMAIN="wpsit" ;;
  prod) PROFILE="Tebogo-prod"; REGION="af-south-1"; DOMAIN="wp" ;;
esac

echo "Verifying deployment for ${TENANT} in ${ENV}..."

# Check 1: ECS Service
echo ""
echo "[1/5] Checking ECS service..."
SERVICE_STATUS=$(aws ecs describe-services \
  --cluster ${ENV}-cluster \
  --services ${ENV}-${TENANT}-service \
  --region $REGION \
  --profile $PROFILE \
  --query 'services[0].[status,desiredCount,runningCount]' \
  --output text)

echo "Service status: $SERVICE_STATUS"

# Check 2: Target Health
echo ""
echo "[2/5] Checking target health..."
TG_ARN=$(aws elbv2 describe-target-groups \
  --names ${ENV}-${TENANT}-tg \
  --region $REGION \
  --profile $PROFILE \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

TARGET_HEALTH=$(aws elbv2 describe-target-health \
  --target-group-arn $TG_ARN \
  --region $REGION \
  --profile $PROFILE \
  --query 'TargetHealthDescriptions[*].[TargetHealth.State]' \
  --output text)

echo "Target health: $TARGET_HEALTH"

# Check 3: HTTP Endpoint
echo ""
echo "[3/5] Testing HTTP endpoint..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://${TENANT}.${DOMAIN}.kimmyai.io)
echo "HTTP response code: $HTTP_CODE"

# Check 4: CloudWatch Logs
echo ""
echo "[4/5] Checking recent logs..."
aws logs tail /ecs/${ENV} \
  --since 2m \
  --filter-pattern "${TENANT}" \
  --format short \
  --region $REGION \
  --profile $PROFILE \
  | tail -10

# Check 5: Secret Access
echo ""
echo "[5/5] Verifying secret exists..."
aws secretsmanager describe-secret \
  --secret-id ${ENV}-${TENANT}-db-credentials \
  --region $REGION \
  --profile $PROFILE \
  --query '[Name,ARN]' \
  --output table

# Summary
echo ""
echo "========================================="
if [[ "$HTTP_CODE" == "200" && "$TARGET_HEALTH" == "healthy" ]]; then
  echo "✅ All checks passed!"
  echo "Site URL: https://${TENANT}.${DOMAIN}.kimmyai.io"
else
  echo "⚠️  Some checks failed. Review output above."
fi
echo "========================================="
```

### Priority 3: Content Migration

#### 6. migrate_tenant_content.sh

**Status:** 🚧 NOT YET IMPLEMENTED

```bash
#!/bin/bash
# File: utils/migrate_tenant_content.sh
# Migrates database and wp-content from DEV to SIT

# TODO: Implement
# - Export database from DEV
# - Search/replace URLs
# - Import to SIT
# - Copy wp-content via EFS or S3
```

---

## Python Utilities

### Overview

The BBWS platform includes comprehensive Python utilities for tenant provisioning, migration, export/import, cost analysis, and testing. These scripts are distributed across multiple repositories and provide sophisticated automation capabilities.

**Primary Repositories:**
1. **2_bbws_agents** - Migration and cost analysis utilities
2. **2_bbws_tenant_provisioner** - Full tenant provisioning suite
3. **2_bbws_ecs_terraform** - Infrastructure migration tools
4. **2_bbws_ecs_tests** - Tenant isolation testing

### Tenant Management Scripts (2_bbws_tenant_provisioner)

#### 1. provision_tenant.py - Single Tenant Provisioner

**Location:** `/Users/tebogotseka/Documents/agentic_work/2_bbws_tenant_provisioner/src/provisioner/provision_tenant.py`

**Purpose:** Provision a complete WordPress tenant stack with all required AWS resources.

**Features:**
- Auto-discovery mode (reads infrastructure from config module)
- Manual mode (all parameters specified explicitly)
- Creates: Database, Secrets Manager entry, EFS access point, ECS task definition, ALB target group, listener rule, ECS service
- Supports both Docker Hub wordpress:latest and custom ECR images
- PyMySQL-based database creation
- Comprehensive error handling

**Usage:**

```bash
# Auto-discovery mode (recommended)
python provision_tenant.py --tenant-id goldencrust --env dev

# With custom ECR image
python provision_tenant.py --tenant-id goldencrust --env dev --use-ecr-image

# Manual mode (all parameters specified)
python provision_tenant.py --tenant-id goldencrust --region eu-west-1 \
  --cluster-name dev-cluster --rds-endpoint dev-mysql.xxx.rds.amazonaws.com \
  --rds-master-secret arn:aws:secretsmanager:... \
  --efs-id fs-xxxxx --alb-arn arn:aws:elasticloadbalancing:... \
  --alb-listener-arn arn:aws:elasticloadbalancing:... \
  --vpc-id vpc-xxxxx --subnet-ids subnet-xxx,subnet-yyy \
  --security-group-id sg-xxxxx --priority 20
```

**Provisioning Steps (Automated):**
1. Retrieve RDS master credentials from Secrets Manager
2. Create tenant database `tenant_{id}_db` with user `tenant_{id}_user`
3. Create Secrets Manager secret for tenant credentials
4. Create EFS access point at `/{tenant_id}` (uid:33, gid:33)
5. Register ECS task definition with WordPress container
6. Create ALB target group for health checks
7. Create ALB listener rule with host-based routing
8. Create ECS service (1 task, Fargate)

---

#### 2. provision_tenants.py - Batch Tenant Provisioner

**Location:** `/Users/tebogotseka/Documents/agentic_work/2_bbws_tenant_provisioner/src/provisioner/provision_tenants.py`

**Purpose:** Provision multiple WordPress tenants in batch using tenant_configs.py definitions.

**Features:**
- Provisions all tenants defined in TENANTS configuration
- Infrastructure auto-discovery
- Database initialization via ECS task (flexible db-init task definition)
- IAM policy automation (secrets + EFS access)
- Parallel-ready (manual delay between tenants)

**Usage:**

```bash
# List all available tenants
python provision_tenants.py --list

# Provision single tenant
python provision_tenants.py --tenant goldencrust --environment dev

# Provision all tenants
python provision_tenants.py --all --environment dev
```

**Tenant Configuration (from tenant_configs.py):**
- goldencrust, sunsetbistro, sterlinglaw, ironpeak, premierprop
- lenslight, nexgentech, serenity, bloompetal, precisionauto

---

#### 3. export_tenant.py - Tenant Export Utility

**Location:** `/Users/tebogotseka/Documents/agentic_work/2_bbws_tenant_provisioner/src/provisioner/export_tenant.py`

**Purpose:** Export tenant data (database, secrets, EFS metadata) for promotion to another environment.

**Features:**
- Database export via mysqldump with compression
- Secrets Manager metadata export
- EFS path metadata (manual copy instructions)
- Creates manifest JSON for import process
- Supports all environments (dev/sit/prod)

**Usage:**

```bash
# Export tenant from DEV
python export_tenant.py --env dev --tenant-id tenant-1 \
  --output-dir /tmp/tenant-exports

# Outputs:
# - tenant-1_database.sql.gz
# - tenant-1_secrets.json
# - tenant-1_manifest.json
```

**Export Process:**
1. Fetch RDS credentials from Secrets Manager
2. Export database using `mysqldump --single-transaction`
3. Compress SQL dump with gzip
4. Export EFS metadata (manual copy instructions)
5. Export secrets metadata (password excluded)
6. Create manifest file with all export details

---

#### 4. import_tenant.py - Tenant Import Utility

**Location:** `/Users/tebogotseka/Documents/agentic_work/2_bbws_tenant_provisioner/src/provisioner/import_tenant.py`

**Purpose:** Import tenant data to target environment (SIT/PROD) from export manifest.

**Features:**
- Two-phase import (provision then import data)
- Database restoration from SQL dump
- WordPress URL configuration updates
- Skip options for each phase
- Comprehensive error handling

**Usage:**

```bash
# Phase 1: Provision infrastructure (then manual completion)
python import_tenant.py --env sit \
  --manifest /tmp/tenant-exports/tenant-1_manifest.json \
  --priority 20

# Phase 2: Import data (after infrastructure ready)
python import_tenant.py --env sit \
  --manifest /tmp/tenant-exports/tenant-1_manifest.json \
  --skip-provision

# Skip specific steps
python import_tenant.py --env sit \
  --manifest /tmp/tenant-exports/tenant-1_manifest.json \
  --skip-provision --skip-database --skip-efs
```

**Import Process:**
1. Load manifest and validate
2. Provision infrastructure (or skip if done)
3. Import database from compressed SQL dump
4. Provide EFS content restore instructions
5. Update WordPress siteurl and home options

---

#### 5. init_tenant_db.py - Database Initialization

**Location:** `/Users/tebogotseka/Documents/agentic_work/2_bbws_tenant_provisioner/src/provisioner/init_tenant_db.py`

**Purpose:** Manual database initialization for tenants in RDS MySQL.

**Features:**
- PyMySQL-based database creation
- Creates database with utf8mb4 charset
- Creates user with full privileges
- Verification checks
- JSON credential input

**Usage:**

```bash
python init_tenant_db.py \
  '{"username":"admin","password":"pass","host":"db.amazonaws.com"}' \
  '{"database":"tenant_1_db","username":"tenant_1_user","password":"pass","host":"db.amazonaws.com"}'
```

---

#### 6. tenant_configs.py - Tenant Configuration Registry

**Location:** `/Users/tebogotseka/Documents/agentic_work/2_bbws_tenant_provisioner/src/provisioner/tenant_configs.py`

**Purpose:** Centralized tenant configuration and environment settings.

**Contents:**
- **TENANTS array:** 10 tenant definitions (id, name, industry, tagline, priority)
- **ENV_CONFIG dict:** Environment-specific settings (AWS account, region, profile, ECS resources)
- **Helper functions:** `get_tenant_by_id()`, `get_all_tenant_ids()`

**Tenant List:**
1. goldencrust (priority 30) - Bakery & Cafe
2. sunsetbistro (31) - Restaurant
3. sterlinglaw (32) - Law Firm
4. ironpeak (33) - Gym & Fitness
5. premierprop (34) - Real Estate
6. lenslight (35) - Photography
7. nexgentech (36) - IT Consulting
8. serenity (37) - Spa & Wellness
9. bloompetal (38) - Florist
10. precisionauto (39) - Auto Services

---

### Migration Scripts (2_bbws_agents)

#### 7. tenant_migration.py - Advanced Migration with Rollback

**Location:** `/Users/tebogotseka/Documents/agentic_work/2_bbws_agents/utils/tenant_migration.py`

**Purpose:** General-purpose WordPress tenant migration between configurations with automatic rollback on failure.

**Features:**
- Multi-step migration with validation
- Automatic rollback on failure
- State tracking and logging
- Dry-run mode for testing
- Batch migration support
- Environment-agnostic (dev/sit/prod)

**Usage:**

```bash
# Migrate single tenant
python3 tenant_migration.py migrate \
  --tenant goldencrust \
  --from-config old_config.json \
  --to-config new_config.json

# Migrate multiple tenants (batch)
python3 tenant_migration.py migrate-batch \
  --tenants tenant1,tenant2,tenant3 \
  --from-config dev_config.json \
  --to-config sit_config.json

# Rollback a migration
python3 tenant_migration.py rollback \
  --migration-id migration-goldencrust-abc12345

# Dry run mode (test without executing)
python3 tenant_migration.py migrate \
  --tenant goldencrust \
  --from-config old.json \
  --to-config new.json \
  --dry-run
```

**Migration Steps:**
1. Validate prerequisites (ECS service, ALB listener, Route53 zone)
2. Backup current state for rollback
3. Update ALB listener rule host headers
4. Update ECS task definition with new environment variables
5. Update ECS service with new task definition
6. Update Route53 DNS records
7. Verify migration success (service health, ALB target health)

**State Tracking:**
- Migration ID saved to `/tmp/{migration-id}.json`
- Includes: status, steps_completed, rollback_data, error_message
- Automatic rollback on any step failure

---

### Infrastructure Migration (2_bbws_ecs_terraform)

#### 8. migrate_tenant_to_wpdev.py - Domain Migration Script

**Location:** `/Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform/scripts/migrate_tenant_to_wpdev.py`

**Purpose:** Migrate WordPress tenants from nip.io wildcard DNS to wpdev.kimmyai.io subdomains.

**Features:**
- ALB listener rule updates (nip.io → wpdev.kimmyai.io)
- ECS task definition updates (WP_HOME, WP_SITEURL)
- HTTPS enforcement via FORCE_SSL_ADMIN
- Service redeployment with stability waiting
- Rollback capability
- Post-migration testing (DNS, CloudFront HTTPS, ALB HTTP)
- Detailed logging to `/tmp/migration_*_*.log`

**Usage:**

```bash
# Migrate tenant to wpdev.kimmyai.io
python3 migrate_tenant_to_wpdev.py --tenant sunsetbistro --priority 31

# Dry run (preview changes)
python3 migrate_tenant_to_wpdev.py --tenant sunsetbistro --priority 31 --dry-run

# Rollback to nip.io
python3 migrate_tenant_to_wpdev.py --tenant sunsetbistro --priority 31 --rollback
```

**Migration Process:**
1. Lookup ALB rule by priority
2. Update ALB rule to `{tenant}.wpdev.kimmyai.io`
3. Fetch current task definition
4. Update WordPress config with WP_HOME and WP_SITEURL
5. Register new task definition revision
6. Update ECS service and wait for stability (10 min max)
7. Test migration (DNS resolution, HTTPS, ALB)

**Rollback Process:**
1. Revert ALB rule to nip.io patterns
2. Remove WP_HOME and WP_SITEURL from task definition
3. Disable FORCE_SSL_ADMIN
4. Redeploy service

---

### Testing Scripts (2_bbws_ecs_tests)

#### 9. test_tenant_isolation.py - Tenant Isolation Test Suite

**Location:** `/Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_tests/tests/test_tenant_isolation.py`

**Purpose:** Automated testing of tenant isolation (database, EFS, network).

**Features:**
- Database isolation verification
- EFS access point isolation tests
- Network security group validation
- Cross-tenant access prevention tests
- Pytest-compatible test suite

---

#### 10. tenant_configs.py - Test Tenant Configurations

**Location:** `/Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_tests/tests/tenant_configs.py`

**Purpose:** Tenant configuration data for integration tests.

---

### Cost Analysis Scripts (2_bbws_agents/cost)

These scripts are documented separately but included for reference:

**analyze_costs.py** - 7-day cost analysis across DEV/SIT/PROD
**service_breakdown.py** - Detailed AWS service cost breakdown
**lambda_cost_reporter.py** - Lambda function for automated cost reporting via SNS

See the original Python Utilities section for detailed cost script documentation.

---

### Complete Python Script Index

| # | Script | Repository | Purpose |
|---|--------|------------|---------|
| 1 | provision_tenant.py | 2_bbws_tenant_provisioner | Single tenant provisioning |
| 2 | provision_tenants.py | 2_bbws_tenant_provisioner | Batch tenant provisioning |
| 3 | export_tenant.py | 2_bbws_tenant_provisioner | Export tenant for promotion |
| 4 | import_tenant.py | 2_bbws_tenant_provisioner | Import tenant to new env |
| 5 | init_tenant_db.py | 2_bbws_tenant_provisioner | Manual database initialization |
| 6 | tenant_configs.py | 2_bbws_tenant_provisioner | Tenant configuration registry |
| 7 | tenant_migration.py | 2_bbws_agents | Advanced migration with rollback |
| 8 | migrate_tenant_to_wpdev.py | 2_bbws_ecs_terraform | Domain migration (nip.io → wpdev) |
| 9 | test_tenant_isolation.py | 2_bbws_ecs_tests | Tenant isolation testing |
| 10 | tenant_configs.py (test) | 2_bbws_ecs_tests | Test configurations |

---

### Python Environment Setup

**Prerequisites:**

```bash
# Install Python 3.11+
python3 --version

# Create virtual environment
cd /path/to/2_bbws_agents
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install boto3 botocore pymysql
pip install python-json-logger
pip install tabulate

# Or from requirements.txt (if exists)
pip install -r requirements.txt
```

**AWS Credentials:**

All Python scripts use boto3 and respect AWS CLI profiles:

```python
# Uses AWS_PROFILE environment variable or --profile flag
import boto3
session = boto3.Session(profile_name='Tebogo-sit')
```

### Best Practices

**When to use Python vs Bash:**

**Use Python for:**
- Complex logic with multiple conditions
- Data transformation and analysis
- API interactions requiring retry logic
- State management and tracking
- Cost analysis and reporting
- Multi-step migrations with rollback
- Tenant provisioning (database creation, resource orchestration)

**Use Bash for:**
- Simple AWS CLI orchestration
- Quick scripts and one-liners
- CI/CD pipeline steps
- File operations
- Environment-specific configurations
- Terraform wrapper scripts

**Recommended Workflow Patterns:**

```bash
# Pattern 1: Provision + Verify (Python + Bash)
python3 provision_tenant.py --tenant-id goldencrust --env sit --priority 140
./verify_deployment.sh goldencrust sit

# Pattern 2: Export/Import (Python only)
python3 export_tenant.py --env dev --tenant-id goldencrust --output-dir /tmp/exports
python3 import_tenant.py --env sit --manifest /tmp/exports/goldencrust_manifest.json

# Pattern 3: Deploy + Migrate (Bash + Python)
./deploy_tenant.sh myclient sit 150
python3 tenant_migration.py migrate --tenant myclient --from-config dev.json --to-config sit.json

# Pattern 4: Batch Deploy (Python batch + Bash verify)
python3 provision_tenants.py --all --environment sit
for tenant in goldencrust sunsetbistro sterlinglaw; do
  ./verify_deployment.sh $tenant sit
done
```

---

**Note:** The sections below contain additional documentation for cost analysis scripts and legacy migration utilities that complement the tenant management scripts documented above.

---

```json
{
  "environment": "sit",
  "aws_profile": "Tebogo-sit",
  "region": "eu-west-1",
  "tenant": "goldencrust",
  "alb": {
    "listener_arn": "arn:aws:elasticloadbalancing:...",
    "target_group_arn": "arn:aws:elasticloadbalancing:...",
    "priority": 140
  },
  "ecs": {
    "cluster": "sit-cluster",
    "service": "sit-goldencrust-service",
    "task_definition": "sit-goldencrust:5"
  },
  "database": {
    "host": "sit-mysql.xxxxx.eu-west-1.rds.amazonaws.com",
    "name": "goldencrust_db",
    "secret_arn": "arn:aws:secretsmanager:..."
  },
  "dns": {
    "zone_id": "Z123456789",
    "record_name": "goldencrust.wpsit.kimmyai.io"
  }
}
```

**Migration Steps (Automated):**

1. **Pre-migration validation**
   - Verify source and target configs
   - Check AWS credentials
   - Validate resources exist

2. **ALB listener rule update**
   - Update priority if changed
   - Update host header routing
   - Validate health check settings

3. **ECS task definition update**
   - Update environment variables
   - Update secrets references
   - Update resource limits if needed

4. **DNS record update**
   - Create/update Route53 records
   - Wait for DNS propagation

5. **Post-migration validation**
   - Check service health
   - Verify target health
   - Test HTTP endpoint

6. **State tracking**
   - Save migration ID
   - Log all changes
   - Enable rollback capability

**Rollback Capability:**

The script maintains state in DynamoDB (if configured) or local JSON files, allowing automatic rollback:

```bash
# Automatic rollback if migration fails
python3 tenant_migration.py migrate \
  --tenant goldencrust \
  --from-config old.json \
  --to-config new.json \
  --auto-rollback

# Manual rollback
python3 tenant_migration.py rollback \
  --tenant goldencrust \
  --migration-id <id-from-migration-output>
```

**Status:** 🚧 Partially implemented
- Core migration logic: ✅ Complete
- Rollback support: ✅ Complete
- State tracking: ⚠️ File-based only (DynamoDB planned)
- Content migration: ❌ Not included (files only, no DB/wp-content)

### 2. Cost Analysis Scripts

**Purpose:** Analyze AWS costs across DEV, SIT, and PROD environments to identify optimization opportunities.

#### 2.1 Multi-Environment Cost Analysis

**File:** `cost/analyze_costs.py`

**Features:**
- 7-day cost analysis across all environments
- Service-level breakdown
- Daily cost trends
- Cost comparison between environments
- JSON export for further analysis

**Usage:**

```bash
cd /path/to/2_bbws_agents/cost

# Analyze all environments
python3 analyze_costs.py

# Output saved to: cost_analysis_YYYYMMDD_HHMMSS.json
```

**Sample Output:**

```
========================================
7-DAY COST ANALYSIS
Period: 2025-12-14 to 2025-12-21
========================================

DEV Environment (536580886816)
==============================
Total Cost: $45.23

Top Services:
  • Amazon Elastic Compute Cloud     $18.45  (40.8%)
  • Amazon Relational Database        $12.30  (27.2%)
  • Amazon EC2 Container Service      $8.75   (19.3%)
  • Amazon Elastic File System        $3.22   (7.1%)
  • Amazon Elastic Load Balancing     $2.51   (5.5%)

Daily Trend:
  2025-12-14: $6.15
  2025-12-15: $6.28
  2025-12-16: $6.41
  ...

SIT Environment (815856636111)
==============================
Total Cost: $12.67

...

PROD Environment (093646564004)
==============================
Total Cost: $0.00 (No resources deployed)

========================================
SUMMARY
========================================
Total 7-Day Cost: $57.90
Average Daily Cost: $8.27
Projected Monthly: $248.10
```

**Output File Structure:**

```json
{
  "period": {
    "start": "2025-12-14",
    "end": "2025-12-21"
  },
  "environments": {
    "dev": {
      "account_id": "536580886816",
      "total_cost": 45.23,
      "services": {
        "Amazon Elastic Compute Cloud": {
          "cost": 18.45,
          "percentage": 40.8,
          "daily": [...]
        }
      }
    }
  },
  "summary": {
    "total_cost": 57.90,
    "avg_daily": 8.27,
    "projected_monthly": 248.10
  }
}
```

#### 2.2 Service Usage Breakdown

**File:** `cost/service_breakdown.py`

**Features:**
- Detailed per-service analysis
- Daily cost trends
- Usage pattern identification
- Cost anomaly detection
- Optimization recommendations

**Usage:**

```bash
cd /path/to/2_bbws_agents/cost

# Analyze service usage patterns
python3 service_breakdown.py

# Output saved to: service_breakdown_YYYYMMDD_HHMMSS.json
```

**Sample Output:**

```
========================================
SERVICE USAGE BREAKDOWN
========================================

Amazon ECS (DEV)
================
Total Cost: $8.75
Days Active: 7/7
Average Daily: $1.25
Peak Daily: $1.42 (2025-12-18)
Trend: Increasing ↑

Usage Pattern:
  Mon-Fri: $1.35 avg (higher)
  Sat-Sun: $0.95 avg (lower)

Recommendation:
  ⚠️ Consider scaling down on weekends
  💡 Potential savings: ~$3.20/month

Amazon RDS (DEV)
================
Total Cost: $12.30
Days Active: 7/7
Average Daily: $1.76
Peak Daily: $1.76 (constant)
Trend: Stable →

Usage Pattern:
  Consistent 24/7 usage

Recommendation:
  ✅ Right-sized for workload
  💡 Consider Reserved Instance: Save 40%
```

#### 2.3 Lambda Cost Reporter

**File:** `cost/lambda_cost_reporter.py`

**Purpose:** AWS Lambda function for automated cost reporting (can be deployed to run on schedule)

**Features:**
- Scheduled cost analysis
- SNS/Email notifications
- CloudWatch metrics
- Configurable thresholds

**Deployment:**

```bash
# Package Lambda function
cd cost
zip -r lambda_cost_reporter.zip lambda_cost_reporter.py

# Deploy via AWS CLI (example)
aws lambda create-function \
  --function-name bbws-cost-reporter \
  --runtime python3.11 \
  --handler lambda_cost_reporter.handler \
  --zip-file fileb://lambda_cost_reporter.zip \
  --role arn:aws:iam::ACCOUNT:role/lambda-cost-reporter-role \
  --environment Variables="{THRESHOLD=100,SNS_TOPIC=arn:aws:sns:...}"
```

**EventBridge Schedule:**

```yaml
# Run daily at 8 AM UTC
Schedule: cron(0 8 * * ? *)
```

**Status:** 🚧 Script exists but not deployed

### 3. Integration with Deployment Scripts

The Python utilities complement the bash deployment scripts:

```bash
# Full tenant deployment with migration tracking
./deploy_tenant.sh myclient sit 190

# Then migrate content using Python utility
python3 tenant_migration.py migrate \
  --tenant myclient \
  --from-config dev_myclient.json \
  --to-config sit_myclient.json

# Verify costs after deployment
python3 cost/analyze_costs.py
```

### 4. Future Python Utilities (Planned)

**High Priority:**
- `database_migrator.py` - MySQL dump/restore with URL replacement
- `wp_content_sync.py` - EFS-to-EFS or S3-based content sync
- `health_monitor.py` - Continuous health monitoring with alerts
- `tenant_validator.py` - Pre/post deployment validation suite

**Medium Priority:**
- `cost_optimizer.py` - Automated cost optimization recommendations
- `backup_scheduler.py` - Automated backup orchestration
- `log_analyzer.py` - CloudWatch log analysis and error detection

**Low Priority:**
- `tenant_portal.py` - Flask/FastAPI self-service portal
- `metrics_dashboard.py` - Streamlit cost/performance dashboard

### 5. Python Environment Setup

**Prerequisites:**

```bash
# Install Python 3.11+
python3 --version

# Create virtual environment
cd /path/to/2_bbws_agents
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install boto3 botocore
pip install python-json-logger
pip install tabulate  # For formatted output

# Or from requirements.txt (if exists)
pip install -r requirements.txt
```

**AWS Credentials:**

All Python scripts use boto3 and respect AWS CLI profiles:

```python
# Uses AWS_PROFILE environment variable or --profile flag
import boto3
session = boto3.Session(profile_name='Tebogo-sit')
```

### 6. Best Practices

**When to use Python vs Bash:**

**Use Python for:**
- Complex logic with multiple conditions
- Data transformation and analysis
- API interactions requiring retry logic
- State management and tracking
- Cost analysis and reporting
- Multi-step migrations with rollback

**Use Bash for:**
- Simple AWS CLI orchestration
- Quick scripts and one-liners
- CI/CD pipeline steps
- File operations
- Environment-specific configurations

**Example Combined Workflow:**

```bash
#!/bin/bash
# deploy_and_migrate.sh - Combines bash and Python

# 1. Deploy infrastructure (bash)
./deploy_tenant.sh $TENANT $ENV $PRIORITY

# 2. Migrate content (Python)
python3 utils/tenant_migration.py migrate \
  --tenant $TENANT \
  --from-config configs/${TENANT}_dev.json \
  --to-config configs/${TENANT}_${ENV}.json

# 3. Verify deployment (bash)
./verify_deployment.sh $TENANT $ENV

# 4. Cost analysis (Python)
python3 cost/analyze_costs.py > /tmp/cost_report.txt
```

---

## Troubleshooting Guide

### Quick Diagnostics

```bash
# Check all tenant services
aws ecs list-services --cluster sit-cluster --region eu-west-1 --profile Tebogo-sit

# Check specific tenant
TENANT="goldencrust"
aws ecs describe-services \
  --cluster sit-cluster \
  --services sit-${TENANT}-service \
  --region eu-west-1 \
  --profile Tebogo-sit

# Check task status
aws ecs list-tasks \
  --cluster sit-cluster \
  --service-name sit-${TENANT}-service \
  --region eu-west-1 \
  --profile Tebogo-sit

# Get task details
TASK_ARN=<from above>
aws ecs describe-tasks \
  --cluster sit-cluster \
  --tasks $TASK_ARN \
  --region eu-west-1 \
  --profile Tebogo-sit

# Check logs
aws logs tail /ecs/sit --since 10m --filter-pattern "$TENANT" --format short

# Check target health
TG_ARN=$(aws elbv2 describe-target-groups --names sit-${TENANT}-tg --query 'TargetGroups[0].TargetGroupArn' --output text)
aws elbv2 describe-target-health --target-group-arn $TG_ARN

# Test endpoint
curl -I http://${TENANT}.wpsit.kimmyai.io
```

### Common Error Resolutions

| Error | Quick Fix |
|-------|-----------|
| HTTP 503 | No healthy targets → Check service running count |
| HTTP 500 | Database error → Check logs, verify DB exists |
| HTTP 401 | Basic Auth → Check CloudFront Lambda@Edge |
| ResourceInitializationError | Secret permissions → Create IAM policy |
| Target unhealthy | ResponseCodeMismatch → Check WordPress errors |
| Task won't start | Check task stopped reason in ECS console |

---

## Improvement Recommendations

### Short Term (1-2 weeks)

1. **Create All Automation Scripts**
   - Priority: generate_tenant_tf.sh, create_database.sh
   - Test with 2-3 tenants
   - Document edge cases

2. **Fix Terraform State Issues**
   - Remove secret creation from Terraform
   - Always create secrets manually first
   - Import before Terraform apply

3. **Standardize Resource Naming**
   - Update all DEV tenants to use environment prefix
   - Create naming convention guide
   - Enforce in code review

4. **Complete SIT Deployment**
   - Deploy remaining 12 tenants
   - Document any new issues
   - Validate all endpoints

### Medium Term (1-2 months)

5. **Implement GitHub Actions**
   - DEV → SIT promotion workflow
   - Automated testing in SIT
   - Manual approval gates

6. **Content Migration Automation**
   - Database export/import script
   - URL search-replace utility
   - wp-content sync via DataSync

7. **Monitoring & Alerting**
   - CloudWatch alarms for service health
   - SNS notifications for failures
   - Dashboard for all tenants

8. **PROD Deployment**
   - Deploy base PROD infrastructure
   - Test DR failover
   - Promote 1-2 pilot tenants

### Long Term (3-6 months)

9. **Self-Service Portal**
   - Web UI for tenant management
   - Automated WordPress installation
   - Client access to their instance

10. **Performance Optimization**
    - CloudFront caching strategy
    - RDS read replicas
    - ECS autoscaling

11. **Security Enhancements**
    - WAF rules on CloudFront
    - Database encryption at rest
    - Regular security audits

12. **Cost Optimization**
    - Right-size RDS instances
    - Reserved capacity for ECS
    - S3 lifecycle policies

---

## Appendix

### A. Current Tenant Inventory

#### DEV (13 tenants)
- All deployed and functional
- Using official wordpress:latest image
- No Basic Auth

#### SIT (4 tenants deployed, 9 pending)
✅ **Deployed:**
- goldencrust (fully working)
- sunsetbistro (HTTP 200)

⚠️ **Partial:**
- sterlinglaw (HTTP 500 - DB error)
- tenant1 (task starting)

📋 **Pending:**
- tenant2, ironpeak, premierprop, lenslight
- nexgentech, serenity, bloompetal, precisionauto
- bbwstrustedservice

### B. AWS Resource Inventory (SIT)

```
ECS Cluster: sit-cluster (4 services)
RDS: sit-mysql.cn6qqe8eu6b9.eu-west-1.rds.amazonaws.com
ALB: sit-alb-1234567890.eu-west-1.elb.amazonaws.com
CloudFront: d1234567890.cloudfront.net → *.wpsit.kimmyai.io
EFS: fs-0abcdef1234567890
VPC: vpc-0abc123 (10.2.0.0/16)
Subnets:
  - subnet-09d1d2de85ae02264 (private-1)
  - subnet-00e96b70ba19dffc5 (private-2)
Security Groups:
  - sg-01bca1fb9806ad397 (ecs-tasks)
  - sg-0xyz... (rds)
  - sg-0xyz... (alb)
```

### C. Useful AWS CLI Commands

```bash
# List all secrets
aws secretsmanager list-secrets --region eu-west-1 --profile Tebogo-sit

# List all target groups
aws elbv2 describe-target-groups --region eu-west-1 --profile Tebogo-sit

# List all ALB rules
LISTENER_ARN=<get from ALB>
aws elbv2 describe-rules --listener-arn $LISTENER_ARN --region eu-west-1 --profile Tebogo-sit

# List all ECS tasks
aws ecs list-tasks --cluster sit-cluster --region eu-west-1 --profile Tebogo-sit

# Get CloudFront distributions
aws cloudfront list-distributions --region us-east-1 --profile Tebogo-sit

# Get Route53 hosted zones
aws route53 list-hosted-zones --profile Tebogo-prod
```

### D. Contact & Support

**Repository:** 2_bbws_agents, 2_bbws_ecs_terraform
**Documentation:** This file + SIT_TENANT_DEPLOYMENT_RUNBOOK.md
**Logs:** CloudWatch /ecs/sit, /ecs/dev
**Issues:** Track in GitHub Issues

---

**End of Guide**
