# Phase 6: SIT Environment Promotion

**Phase**: 6 of 10
**Duration**: 0.5 days (4 hours)
**Responsible**: DevOps Engineer + Database Administrator
**Environment**: SIT
**Dependencies**: Phase 5 (Testing and Validation DEV) must be complete with sign-off
**Status**: ⏳ NOT STARTED

---

## Phase Objectives

- Provision aupairhive tenant in SIT environment
- Promote database from DEV to SIT
- Promote WordPress files from DEV to SIT
- Configure SIT-specific settings (domain, credentials, environment variables)
- Verify infrastructure health in SIT
- Validate basic functionality before UAT
- Document SIT environment configuration

---

## Prerequisites

- [ ] Phase 5 completed: DEV testing passed with sign-off
- [ ] All P0 and P1 defects resolved in DEV
- [ ] DEV environment stable and functional
- [ ] SIT environment infrastructure validated (from Phase 1)
- [ ] AWS CLI configured with Tebogo-sit profile
- [ ] Terraform scripts ready for SIT workspace
- [ ] Database export from DEV available (or access to DEV RDS)
- [ ] WordPress files accessible from DEV EFS (or S3 staging)

---

## Detailed Tasks

### Task 6.1: Provision Tenant Infrastructure in SIT

**Duration**: 1 hour
**Responsible**: DevOps Engineer

**Steps**:

1. **Set SIT environment variables**:
```bash
export AWS_PROFILE=Tebogo-sit
export AWS_REGION=eu-west-1
export ENVIRONMENT=sit
export TENANT_ID=aupairhive
export TARGET_DOMAIN=aupairhive.wpsit.kimmyai.io
```

2. **Create isolated MySQL database in SIT**:
```bash
# Get SIT RDS endpoint
SIT_RDS_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier bbws-sit-mysql \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

# Get master credentials
SIT_MASTER_SECRET=$(aws secretsmanager get-secret-value \
    --secret-id bbws/sit/rds/master \
    --query SecretString --output text)

SIT_MASTER_USER=$(echo $SIT_MASTER_SECRET | jq -r '.username')
SIT_MASTER_PASS=$(echo $SIT_MASTER_SECRET | jq -r '.password')

# Create database and user
mysql -h $SIT_RDS_ENDPOINT -u $SIT_MASTER_USER -p$SIT_MASTER_PASS <<EOSQL
CREATE DATABASE IF NOT EXISTS tenant_aupairhive_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'tenant_aupairhive_user'@'%'
    IDENTIFIED BY '$(openssl rand -base64 16)';

GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER,
      CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, CREATE VIEW,
      SHOW VIEW, TRIGGER
    ON tenant_aupairhive_db.*
    TO 'tenant_aupairhive_user'@'%';

FLUSH PRIVILEGES;

-- Verify
SHOW DATABASES LIKE 'tenant_aupairhive_db';
SHOW GRANTS FOR 'tenant_aupairhive_user'@'%';
EOSQL
```

**Expected Output**: Database and user created successfully

3. **Store credentials in Secrets Manager (SIT)**:
```bash
# Get the password that was generated
DB_PASSWORD=$(mysql -h $SIT_RDS_ENDPOINT -u $SIT_MASTER_USER -p$SIT_MASTER_PASS -sse \
    "SELECT authentication_string FROM mysql.user WHERE user='tenant_aupairhive_user' LIMIT 1;")

# Create secret
aws secretsmanager create-secret \
    --name bbws/sit/aupairhive/database \
    --description "Database credentials for tenant aupairhive in SIT" \
    --secret-string "{
        \"host\": \"$SIT_RDS_ENDPOINT\",
        \"port\": \"3306\",
        \"username\": \"tenant_aupairhive_user\",
        \"password\": \"<ACTUAL_PASSWORD_HERE>\",
        \"dbname\": \"tenant_aupairhive_db\",
        \"engine\": \"mysql\"
    }"

# Verify secret created
aws secretsmanager describe-secret --secret-id bbws/sit/aupairhive/database
```

4. **Create EFS access point for SIT**:
```bash
# Get SIT EFS file system ID
SIT_EFS_ID=$(aws efs describe-file-systems \
    --query "FileSystems[?Tags[?Key=='Environment' && Value=='sit']].FileSystemId" \
    --output text)

# Create access point
aws efs create-access-point \
    --file-system-id $SIT_EFS_ID \
    --posix-user Uid=1001,Gid=1001 \
    --root-directory "Path=/tenant-aupairhive,CreationInfo={OwnerUid=1001,OwnerGid=1001,Permissions=755}" \
    --tags Key=Name,Value=aupairhive Key=Environment,Value=sit Key=Tenant,Value=aupairhive

# Get access point ID
AP_ID=$(aws efs describe-access-points \
    --file-system-id $SIT_EFS_ID \
    --query "AccessPoints[?Name=='aupairhive'].AccessPointId" \
    --output text)

echo "EFS Access Point ID: $AP_ID"
```

5. **Register ECS task definition for SIT**:
```bash
cat > aupairhive-sit-task.json <<EOF
{
  "family": "aupairhive-sit-task",
  "taskRoleArn": "arn:aws:iam::815856636111:role/ecsTaskRole",
  "executionRoleArn": "arn:aws:iam::815856636111:role/ecsTaskExecutionRole",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "containerDefinitions": [
    {
      "name": "wordpress",
      "image": "wordpress:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {"name": "WORDPRESS_DB_HOST", "value": "$SIT_RDS_ENDPOINT"},
        {"name": "WORDPRESS_DB_NAME", "value": "tenant_aupairhive_db"},
        {"name": "WORDPRESS_DB_USER", "value": "tenant_aupairhive_user"}
      ],
      "secrets": [
        {
          "name": "WORDPRESS_DB_PASSWORD",
          "valueFrom": "bbws/sit/aupairhive/database:password::"
        }
      ],
      "mountPoints": [
        {
          "sourceVolume": "wordpress-efs",
          "containerPath": "/var/www/html",
          "readOnly": false
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/aupairhive-sit",
          "awslogs-region": "eu-west-1",
          "awslogs-stream-prefix": "wordpress"
        }
      }
    }
  ],
  "volumes": [
    {
      "name": "wordpress-efs",
      "efsVolumeConfiguration": {
        "fileSystemId": "$SIT_EFS_ID",
        "transitEncryption": "ENABLED",
        "authorizationConfig": {
          "accessPointId": "$AP_ID",
          "iam": "ENABLED"
        }
      }
    }
  ]
}
EOF

# Register task definition
aws ecs register-task-definition --cli-input-json file://aupairhive-sit-task.json
```

6. **Deploy ECS service in SIT**:
```bash
aws ecs create-service \
    --cluster sit-cluster \
    --service-name aupairhive-sit-service \
    --task-definition aupairhive-sit-task \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={
        subnets=[subnet-xxxxx,subnet-yyyyy],
        securityGroups=[sg-xxxxx],
        assignPublicIp=ENABLED
    }" \
    --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:eu-west-1:815856636111:targetgroup/aupairhive-sit-tg,containerName=wordpress,containerPort=80"

# Wait for service to stabilize
aws ecs wait services-stable \
    --cluster sit-cluster \
    --services aupairhive-sit-service
```

**Verification**:
- [ ] SIT database created: tenant_aupairhive_db
- [ ] SIT database user created with limited privileges
- [ ] Credentials stored in Secrets Manager (SIT)
- [ ] EFS access point created
- [ ] ECS task definition registered
- [ ] ECS service deployed and running

---

### Task 6.2: Create ALB Target Group and Listener Rule (SIT)

**Duration**: 30 minutes
**Responsible**: DevOps Engineer

**Steps**:

1. **Get SIT ALB ARN**:
```bash
SIT_ALB_ARN=$(aws elbv2 describe-load-balancers \
    --names sit-alb \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text)

SIT_VPC_ID=$(aws elbv2 describe-load-balancers \
    --names sit-alb \
    --query 'LoadBalancers[0].VpcId' \
    --output text)
```

2. **Create target group**:
```bash
TG_ARN=$(aws elbv2 create-target-group \
    --name aupairhive-sit-tg \
    --protocol HTTP \
    --port 80 \
    --vpc-id $SIT_VPC_ID \
    --target-type ip \
    --health-check-enabled \
    --health-check-protocol HTTP \
    --health-check-path /wp-admin/install.php \
    --health-check-interval-seconds 30 \
    --health-check-timeout-seconds 5 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 3 \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

echo "Target Group ARN: $TG_ARN"
```

3. **Create ALB listener rule**:
```bash
# Get listener ARN (HTTP or HTTPS)
LISTENER_ARN=$(aws elbv2 describe-listeners \
    --load-balancer-arn $SIT_ALB_ARN \
    --query 'Listeners[?Port==`80`].ListenerArn' \
    --output text)

# Create rule
aws elbv2 create-rule \
    --listener-arn $LISTENER_ARN \
    --priority 10 \
    --conditions Field=host-header,Values=aupairhive.wpsit.kimmyai.io \
    --actions Type=forward,TargetGroupArn=$TG_ARN
```

**Verification**:
- [ ] Target group created
- [ ] Health check configured
- [ ] ALB listener rule created with host-header condition
- [ ] Rule priority set (no conflicts with existing rules)

---

### Task 6.3: Configure Route53 DNS for SIT

**Duration**: 20 minutes
**Responsible**: DevOps Engineer

**Steps**:

1. **Get SIT ALB DNS name**:
```bash
SIT_ALB_DNS=$(aws elbv2 describe-load-balancers \
    --names sit-alb \
    --query 'LoadBalancers[0].DNSName' \
    --output text)

SIT_ALB_ZONE=$(aws elbv2 describe-load-balancers \
    --names sit-alb \
    --query 'LoadBalancers[0].CanonicalHostedZoneId' \
    --output text)
```

2. **Create Route53 A record (ALIAS)**:
```bash
# Get hosted zone ID for wpsit.kimmyai.io
ZONE_ID=$(aws route53 list-hosted-zones \
    --query "HostedZones[?Name=='wpsit.kimmyai.io.'].Id" \
    --output text | cut -d'/' -f3)

# Create change batch
cat > route53-change-batch.json <<EOF
{
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "aupairhive.wpsit.kimmyai.io",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "$SIT_ALB_ZONE",
          "DNSName": "$SIT_ALB_DNS",
          "EvaluateTargetHealth": true
        }
      }
    }
  ]
}
EOF

# Apply change
aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch file://route53-change-batch.json

# Wait for DNS propagation (2-5 minutes)
sleep 180
```

3. **Verify DNS resolution**:
```bash
nslookup aupairhive.wpsit.kimmyai.io
dig aupairhive.wpsit.kimmyai.io

# Expected: Resolves to SIT ALB IP address
```

**Verification**:
- [ ] Route53 A record created
- [ ] DNS resolves to SIT ALB
- [ ] DNS propagation complete (may take 2-5 minutes)

---

### Task 6.4: Promote Database from DEV to SIT

**Duration**: 45 minutes
**Responsible**: Database Administrator

**Steps**:

1. **Export database from DEV**:
```bash
export AWS_PROFILE=Tebogo-dev

# Get DEV database credentials
DEV_SECRET=$(aws secretsmanager get-secret-value \
    --secret-id bbws/dev/aupairhive/database \
    --query SecretString --output text)

DEV_HOST=$(echo $DEV_SECRET | jq -r '.host')
DEV_USER=$(echo $DEV_SECRET | jq -r '.username')
DEV_PASS=$(echo $DEV_SECRET | jq -r '.password')
DEV_DB=$(echo $DEV_SECRET | jq -r '.dbname')

# Export database
mysqldump -h $DEV_HOST -u $DEV_USER -p$DEV_PASS \
    --single-transaction \
    --quick \
    --lock-tables=false \
    $DEV_DB > aupairhive_dev_export_$(date +%Y%m%d).sql

# Verify export
ls -lh aupairhive_dev_export_*.sql
```

2. **Perform URL replacement for SIT domain**:
```bash
# Copy export for SIT
cp aupairhive_dev_export_$(date +%Y%m%d).sql aupairhive_sit_import.sql

# Replace DEV URLs with SIT URLs
sed -i 's|https://aupairhive.wpdev.kimmyai.io|https://aupairhive.wpsit.kimmyai.io|g' aupairhive_sit_import.sql
sed -i 's|http://aupairhive.wpdev.kimmyai.io|https://aupairhive.wpsit.kimmyai.io|g' aupairhive_sit_import.sql

# Verify replacements
grep -c "wpsit.kimmyai.io" aupairhive_sit_import.sql
grep -c "wpdev.kimmyai.io" aupairhive_sit_import.sql
# Second grep should return 0
```

3. **Import database to SIT**:
```bash
export AWS_PROFILE=Tebogo-sit

# Get SIT database credentials
SIT_SECRET=$(aws secretsmanager get-secret-value \
    --secret-id bbws/sit/aupairhive/database \
    --query SecretString --output text)

SIT_HOST=$(echo $SIT_SECRET | jq -r '.host')
SIT_USER=$(echo $SIT_SECRET | jq -r '.username')
SIT_PASS=$(echo $SIT_SECRET | jq -r '.password')
SIT_DB=$(echo $SIT_SECRET | jq -r '.dbname')

# Import database
mysql -h $SIT_HOST -u $SIT_USER -p$SIT_PASS $SIT_DB < aupairhive_sit_import.sql

echo "Database import to SIT completed"
```

4. **Verify database import**:
```bash
# Check table count
mysql -h $SIT_HOST -u $SIT_USER -p$SIT_PASS $SIT_DB -e "SHOW TABLES;" | wc -l

# Check site URL
mysql -h $SIT_HOST -u $SIT_USER -p$SIT_PASS $SIT_DB -e \
    "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"

# Expected output:
# siteurl  | https://aupairhive.wpsit.kimmyai.io
# home     | https://aupairhive.wpsit.kimmyai.io

# Check row counts
mysql -h $SIT_HOST -u $SIT_USER -p$SIT_PASS $SIT_DB -e \
    "SELECT
        (SELECT COUNT(*) FROM wp_posts) as posts,
        (SELECT COUNT(*) FROM wp_users) as users,
        (SELECT COUNT(*) FROM wp_options) as options;"
```

**Verification**:
- [ ] Database exported from DEV
- [ ] URL replacement performed (DEV → SIT)
- [ ] Database imported to SIT
- [ ] Table count matches DEV
- [ ] Site URLs updated to SIT domain
- [ ] Row counts match DEV

---

### Task 6.5: Promote WordPress Files from DEV to SIT

**Duration**: 1 hour
**Responsible**: DevOps Engineer

**Steps**:

**Option A: Copy via S3 staging**:

```bash
# Export from DEV EFS to S3
export AWS_PROFILE=Tebogo-dev

aws ecs run-task \
    --cluster dev-cluster \
    --task-definition aupairhive-dev-task \
    --overrides '{
        "containerOverrides": [{
            "name": "wordpress",
            "command": ["sh", "-c", "tar czf /tmp/wordpress-files.tar.gz -C /var/www/html . && aws s3 cp /tmp/wordpress-files.tar.gz s3://bbws-cross-env-staging/aupairhive/"]
        }]
    }' \
    --launch-type FARGATE

# Wait for task to complete (5-10 minutes)
sleep 600

# Import to SIT EFS from S3
export AWS_PROFILE=Tebogo-sit

aws ecs run-task \
    --cluster sit-cluster \
    --task-definition aupairhive-sit-task \
    --overrides '{
        "containerOverrides": [{
            "name": "wordpress",
            "command": ["sh", "-c", "aws s3 cp s3://bbws-cross-env-staging/aupairhive/wordpress-files.tar.gz /tmp/ && tar xzf /tmp/wordpress-files.tar.gz -C /var/www/html && chown -R www-data:www-data /var/www/html"]
        }]
    }' \
    --launch-type FARGATE

# Wait for task to complete
sleep 600
```

**Option B: Direct EFS-to-EFS copy** (if both EFS accessible):

```bash
# Mount both EFS file systems on EC2 instance
# Copy files directly
# (More complex, requires EC2 with dual EFS mounts)
```

**Verification**:
- [ ] WordPress files copied from DEV to SIT
- [ ] File permissions correct (www-data:www-data)
- [ ] Critical directories exist (wp-content/themes, wp-content/plugins, wp-content/uploads)

---

### Task 6.6: Update wp-config.php for SIT

**Duration**: 30 minutes
**Responsible**: WordPress Developer

**Steps**:

1. **Access SIT container**:
```bash
export AWS_PROFILE=Tebogo-sit

TASK_ARN=$(aws ecs list-tasks \
    --cluster sit-cluster \
    --service-name aupairhive-sit-service \
    --query 'taskArns[0]' --output text)

aws ecs execute-command \
    --cluster sit-cluster \
    --task $TASK_ARN \
    --container wordpress \
    --interactive \
    --command "/bin/bash"
```

2. **Update wp-config.php**:
```bash
cd /var/www/html

# Backup original
cp wp-config.php wp-config.php.dev-backup

# Update environment-specific settings
cat > wp-config-sit-updates.php <<'EOPHP'
// ** SIT Environment Configuration ** //
define('WP_ENVIRONMENT_TYPE', 'staging');

// ** URL Configuration ** //
define('WP_HOME', 'https://aupairhive.wpsit.kimmyai.io');
define('WP_SITEURL', 'https://aupairhive.wpsit.kimmyai.io');

// ** Debug Settings (less verbose than DEV) ** //
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);
define('SCRIPT_DEBUG', false);

// ** Security ** //
define('DISALLOW_FILE_EDIT', true); // Disable file editing in SIT

// ** Search Engine Visibility ** //
// NOTE: Set in WordPress admin under Settings → Reading → Discourage search engines
EOPHP

# Merge with existing wp-config.php
# (Manual edit or use sed to replace specific sections)

chmod 600 wp-config.php
chown www-data:www-data wp-config.php
```

3. **Update robots.txt for SIT**:
```bash
cat > /var/www/html/robots.txt <<EOF
User-agent: *
Disallow: /

# SIT Environment - Block all search engines
EOF
```

4. **Restart ECS service** to pick up changes:
```bash
exit  # Exit container

aws ecs update-service \
    --cluster sit-cluster \
    --service aupairhive-sit-service \
    --force-new-deployment

# Wait for new task to start
aws ecs wait services-stable \
    --cluster sit-cluster \
    --services aupairhive-sit-service
```

**Verification**:
- [ ] wp-config.php updated with SIT domain
- [ ] WP_ENVIRONMENT_TYPE set to 'staging'
- [ ] WP_DEBUG enabled, WP_DEBUG_DISPLAY disabled
- [ ] DISALLOW_FILE_EDIT set to true
- [ ] robots.txt blocks search engines
- [ ] ECS service restarted

---

### Task 6.7: Verify SIT Infrastructure Health

**Duration**: 30 minutes
**Responsible**: DevOps Engineer + QA

**Steps**:

1. **Verify ECS service health**:
```bash
aws ecs describe-services \
    --cluster sit-cluster \
    --services aupairhive-sit-service \
    --query 'services[0].[runningCount,desiredCount,deployments[0].rolloutState]'

# Expected: [1, 1, "COMPLETED"]
```

2. **Verify ALB target health**:
```bash
aws elbv2 describe-target-health \
    --target-group-arn $TG_ARN \
    --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]'

# Expected: TargetHealth.State = "healthy"
```

3. **Test homepage loads**:
```bash
curl -I https://aupairhive.wpsit.kimmyai.io

# Expected: HTTP 200 OK
```

4. **Test WordPress admin access**:
```bash
curl -I https://aupairhive.wpsit.kimmyai.io/wp-admin

# Expected: HTTP 302 (redirect to login) or HTTP 200
```

5. **Check CloudWatch logs for errors**:
```bash
aws logs tail /ecs/aupairhive-sit --follow --since 5m

# Look for PHP errors or WordPress errors
# Should see normal WordPress startup logs
```

6. **Verify database connectivity from container**:
```bash
# Execute command in running container
aws ecs execute-command \
    --cluster sit-cluster \
    --task $TASK_ARN \
    --container wordpress \
    --interactive \
    --command "mysql -h \$WORDPRESS_DB_HOST -u \$WORDPRESS_DB_USER -p\$WORDPRESS_DB_PASSWORD -e 'SELECT 1;'"

# Expected: Returns 1
```

**Verification**:
- [ ] ECS service running with desired count
- [ ] ALB target health is "healthy"
- [ ] Homepage returns HTTP 200
- [ ] WordPress admin accessible
- [ ] No critical errors in CloudWatch logs
- [ ] Database connectivity confirmed

---

### Task 6.8: Basic Functional Validation in SIT

**Duration**: 30 minutes
**Responsible**: QA Engineer

**Smoke Test Checklist**:

1. **Homepage loads**:
- Navigate to: https://aupairhive.wpsit.kimmyai.io
- [ ] Page loads without errors
- [ ] Divi theme styling applied
- [ ] Images display correctly

2. **Admin login**:
- Navigate to: https://aupairhive.wpsit.kimmyai.io/wp-admin
- Login with admin credentials
- [ ] Login successful
- [ ] WordPress dashboard loads

3. **Verify site URL**:
- Go to: Settings → General
- [ ] WordPress Address (URL): https://aupairhive.wpsit.kimmyai.io
- [ ] Site Address (URL): https://aupairhive.wpsit.kimmyai.io

4. **Test one form**:
- Navigate to: Contact page
- Fill out and submit contact form
- [ ] Form submits successfully
- [ ] Entry recorded in Gravity Forms

5. **Verify premium licenses**:
- Go to: Divi → Theme Options → Updates
- [ ] Divi license status: Active
- Go to: Forms → Settings → License
- [ ] Gravity Forms license status: Active

**Smoke Test Results**:
```bash
cat > sit_smoke_test_results.txt <<EOF
=== SIT Smoke Test Results ===
Date: $(date)

Test                        | Status | Notes
----------------------------|--------|------------------
Homepage Load               | PASS   | Loads in 2.5s
Admin Login                 | PASS   | Login successful
Site URL Verification       | PASS   | Correct SIT domain
Form Submission             | PASS   | Contact form works
Divi License                | PASS   | Active
Gravity Forms License       | PASS   | Active

Overall SIT Promotion: SUCCESS
Ready for Phase 7 UAT: YES
EOF
```

**Verification**:
- [ ] All smoke tests passed
- [ ] No critical defects found
- [ ] Site functional on SIT domain
- [ ] Ready for comprehensive UAT (Phase 7)

---

## Verification Checklist

### Infrastructure Provisioning
- [ ] SIT database created and user configured
- [ ] Credentials stored in Secrets Manager (SIT)
- [ ] EFS access point created
- [ ] ECS task definition registered
- [ ] ECS service deployed and running
- [ ] ALB target group created with health checks
- [ ] ALB listener rule configured
- [ ] Route53 DNS record created

### Data Promotion
- [ ] Database exported from DEV
- [ ] URL replacement performed (DEV → SIT)
- [ ] Database imported to SIT successfully
- [ ] WordPress files copied from DEV to SIT
- [ ] File permissions set correctly

### Configuration
- [ ] wp-config.php updated for SIT environment
- [ ] WP_ENVIRONMENT_TYPE set to 'staging'
- [ ] robots.txt blocks search engines
- [ ] Site URLs updated to SIT domain

### Health Validation
- [ ] ECS service healthy (running count = desired count)
- [ ] ALB target health "healthy"
- [ ] Homepage loads successfully (HTTP 200)
- [ ] WordPress admin accessible
- [ ] Database connectivity confirmed
- [ ] No critical errors in logs

### Functional Validation
- [ ] Smoke tests passed (6/6)
- [ ] Premium licenses active
- [ ] Forms functional
- [ ] Site ready for UAT

---

## Rollback Procedure

If SIT promotion fails critically:

1. **Document failure** and root cause
2. **Stop ECS service**:
```bash
aws ecs update-service \
    --cluster sit-cluster \
    --service aupairhive-sit-service \
    --desired-count 0
```

3. **Delete Route53 DNS record**:
```bash
# Change "CREATE" to "DELETE" in route53-change-batch.json
aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch file://route53-change-batch-delete.json
```

4. **Drop SIT database**:
```bash
mysql -h $SIT_HOST -u $SIT_MASTER_USER -p$SIT_MASTER_PASS -e \
    "DROP DATABASE tenant_aupairhive_db;"
```

5. **Fix issue in DEV** and repeat Phase 6

---

## Success Criteria

- [ ] Tenant infrastructure provisioned in SIT
- [ ] Database promoted from DEV with URL updates
- [ ] WordPress files promoted from DEV
- [ ] wp-config.php configured for SIT environment
- [ ] DNS resolves to SIT environment
- [ ] ECS service running and healthy
- [ ] ALB target health passing
- [ ] Homepage loads successfully
- [ ] WordPress admin accessible
- [ ] Premium licenses active
- [ ] Smoke tests passed (6/6)
- [ ] No critical defects or errors
- [ ] Ready for Phase 7 (UAT and Performance Testing)

**Definition of Done**:
Au Pair Hive tenant successfully promoted from DEV to SIT with all infrastructure, database, and files migrated. Basic functionality validated and ready for comprehensive UAT.

---

## Sign-Off

**Completed By**: _________________ Date: _________
**Verified By**: _________________ Date: _________
**SIT Database Row Count**: _________
**SIT Files Size (GB)**: _________
**Smoke Tests Passed**: _________ / 6
**Ready for Phase 7**: [ ] YES [ ] NO

---

## Notes and Observations

[Space for team to document findings]

**Promotion Time**:
- Infrastructure Provisioning: _________
- Database Export/Import: _________
- File Copy: _________
- Total Time: _________

**Issues Encountered**:
-
-

**Differences from DEV**:
-
-

---

**Next Phase**: Proceed to **Phase 7**: `07_UAT_and_Performance_Testing_SIT.md`
