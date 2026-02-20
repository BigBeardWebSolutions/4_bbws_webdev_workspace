# Phase 8: PROD Deployment Preparation

**Phase**: 8 of 10
**Duration**: 1 day (8 hours)
**Responsible**: DevOps Engineer + Technical Lead + Database Administrator
**Environment**: PROD
**Dependencies**: Phase 7 (UAT Sign-Off) must be complete
**Status**: ⏳ NOT STARTED

---

## Phase Objectives

- Provision tenant infrastructure in PROD environment (af-south-1)
- Configure production-grade settings (security, performance, monitoring)
- Create final backup of SIT environment
- Prepare rollback procedures and contingency plans
- Set up production monitoring and alerting
- Prepare go-live communication plan
- Conduct go-live readiness review
- Schedule DNS cutover window
- Prepare go-live runbook and checklists

---

## Prerequisites

- [ ] Phase 7 completed: UAT passed with client sign-off
- [ ] All P0 and P1 defects resolved in SIT
- [ ] PROD environment infrastructure validated (from Phase 1)
- [ ] AWS CLI configured with Tebogo-prod profile
- [ ] Production DNS registrar access (for aupairhive.com)
- [ ] Terraform scripts ready for PROD workspace
- [ ] Stakeholder communication plan prepared
- [ ] Go-live date and time confirmed with client
- [ ] On-call schedule established for go-live support

---

## Detailed Tasks

### Task 8.1: Provision Tenant Infrastructure in PROD

**Duration**: 2 hours
**Responsible**: DevOps Engineer

**Steps**:

1. **Set PROD environment variables**:
```bash
export AWS_PROFILE=Tebogo-prod
export AWS_REGION=af-south-1  # Primary PROD region
export ENVIRONMENT=prod
export TENANT_ID=aupairhive
export TARGET_DOMAIN=aupairhive.com
```

2. **Create isolated MySQL database in PROD**:
```bash
# Get PROD RDS endpoint (Cape Town region)
PROD_RDS_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier bbws-prod-mysql \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

# Get master credentials
PROD_MASTER_SECRET=$(aws secretsmanager get-secret-value \
    --secret-id bbws/prod/rds/master \
    --query SecretString --output text)

PROD_MASTER_USER=$(echo $PROD_MASTER_SECRET | jq -r '.username')
PROD_MASTER_PASS=$(echo $PROD_MASTER_SECRET | jq -r '.password')

# Create database and user with strong password
PROD_DB_PASS=$(openssl rand -base64 32)

mysql -h $PROD_RDS_ENDPOINT -u $PROD_MASTER_USER -p$PROD_MASTER_PASS <<EOSQL
CREATE DATABASE IF NOT EXISTS tenant_aupairhive_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'tenant_aupairhive_user'@'%'
    IDENTIFIED BY '$PROD_DB_PASS';

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

3. **Store credentials in Secrets Manager (PROD)**:
```bash
aws secretsmanager create-secret \
    --name bbws/prod/aupairhive/database \
    --description "Database credentials for tenant aupairhive in PROD" \
    --kms-key-id arn:aws:kms:af-south-1:093646564004:key/prod-key-id \
    --secret-string "{
        \"host\": \"$PROD_RDS_ENDPOINT\",
        \"port\": \"3306\",
        \"username\": \"tenant_aupairhive_user\",
        \"password\": \"$PROD_DB_PASS\",
        \"dbname\": \"tenant_aupairhive_db\",
        \"engine\": \"mysql\"
    }"

# Verify secret created
aws secretsmanager describe-secret --secret-id bbws/prod/aupairhive/database
```

4. **Create EFS access point for PROD**:
```bash
# Get PROD EFS file system ID (Cape Town)
PROD_EFS_ID=$(aws efs describe-file-systems \
    --query "FileSystems[?Tags[?Key=='Environment' && Value=='prod']].FileSystemId" \
    --output text)

# Create access point
aws efs create-access-point \
    --file-system-id $PROD_EFS_ID \
    --posix-user Uid=1001,Gid=1001 \
    --root-directory "Path=/tenant-aupairhive,CreationInfo={OwnerUid=1001,OwnerGid=1001,Permissions=755}" \
    --tags Key=Name,Value=aupairhive Key=Environment,Value=prod Key=Tenant,Value=aupairhive

# Get access point ID
PROD_AP_ID=$(aws efs describe-access-points \
    --file-system-id $PROD_EFS_ID \
    --query "AccessPoints[?Name=='aupairhive'].AccessPointId" \
    --output text)

echo "PROD EFS Access Point ID: $PROD_AP_ID"
```

5. **Register ECS task definition for PROD (optimized for production)**:
```bash
cat > aupairhive-prod-task.json <<EOF
{
  "family": "aupairhive-prod-task",
  "taskRoleArn": "arn:aws:iam::093646564004:role/ecsTaskRole",
  "executionRoleArn": "arn:aws:iam::093646564004:role/ecsTaskExecutionRole",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "1024",
  "memory": "2048",
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
        {"name": "WORDPRESS_DB_HOST", "value": "$PROD_RDS_ENDPOINT"},
        {"name": "WORDPRESS_DB_NAME", "value": "tenant_aupairhive_db"},
        {"name": "WORDPRESS_DB_USER", "value": "tenant_aupairhive_user"},
        {"name": "WORDPRESS_CONFIG_EXTRA", "value": "define('WP_ENVIRONMENT_TYPE', 'production'); define('DISALLOW_FILE_EDIT', true); define('WP_DEBUG', false);"}
      ],
      "secrets": [
        {
          "name": "WORDPRESS_DB_PASSWORD",
          "valueFrom": "bbws/prod/aupairhive/database:password::"
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
          "awslogs-group": "/ecs/aupairhive-prod",
          "awslogs-region": "af-south-1",
          "awslogs-stream-prefix": "wordpress"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost/wp-admin/install.php || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ],
  "volumes": [
    {
      "name": "wordpress-efs",
      "efsVolumeConfiguration": {
        "fileSystemId": "$PROD_EFS_ID",
        "transitEncryption": "ENABLED",
        "transitEncryptionPort": 2049,
        "authorizationConfig": {
          "accessPointId": "$PROD_AP_ID",
          "iam": "ENABLED"
        }
      }
    }
  ]
}
EOF

# Register task definition
aws ecs register-task-definition --cli-input-json file://aupairhive-prod-task.json
```

6. **Deploy ECS service in PROD with auto-scaling**:
```bash
aws ecs create-service \
    --cluster prod-cluster \
    --service-name aupairhive-prod-service \
    --task-definition aupairhive-prod-task \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={
        subnets=[subnet-xxxxx,subnet-yyyyy],
        securityGroups=[sg-xxxxx],
        assignPublicIp=DISABLED
    }" \
    --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:af-south-1:093646564004:targetgroup/aupairhive-prod-tg,containerName=wordpress,containerPort=80" \
    --health-check-grace-period-seconds 60

# Configure auto-scaling (2-4 tasks based on CPU)
aws application-autoscaling register-scalable-target \
    --service-namespace ecs \
    --resource-id service/prod-cluster/aupairhive-prod-service \
    --scalable-dimension ecs:service:DesiredCount \
    --min-capacity 2 \
    --max-capacity 4

aws application-autoscaling put-scaling-policy \
    --service-namespace ecs \
    --resource-id service/prod-cluster/aupairhive-prod-service \
    --scalable-dimension ecs:service:DesiredCount \
    --policy-name aupairhive-prod-cpu-scaling \
    --policy-type TargetTrackingScaling \
    --target-tracking-scaling-policy-configuration '{
        "TargetValue": 70.0,
        "PredefinedMetricSpecification": {
            "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
        },
        "ScaleInCooldown": 300,
        "ScaleOutCooldown": 60
    }'

# Wait for service to stabilize
aws ecs wait services-stable \
    --cluster prod-cluster \
    --services aupairhive-prod-service
```

**Verification**:
- [ ] PROD database created: tenant_aupairhive_db
- [ ] Database user created with strong 32-character password
- [ ] Credentials stored in Secrets Manager (PROD) with KMS encryption
- [ ] EFS access point created in af-south-1
- [ ] ECS task definition registered (1024 CPU, 2048 MB memory)
- [ ] ECS service deployed with 2 tasks
- [ ] Auto-scaling configured (2-4 tasks, CPU-based)

---

### Task 8.2: Create ALB Target Group and CloudFront Distribution (PROD)

**Duration**: 1.5 hours
**Responsible**: DevOps Engineer

**Steps**:

1. **Create ALB target group**:
```bash
PROD_ALB_ARN=$(aws elbv2 describe-load-balancers \
    --names prod-alb \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text)

PROD_VPC_ID=$(aws elbv2 describe-load-balancers \
    --names prod-alb \
    --query 'LoadBalancers[0].VpcId' \
    --output text)

# Create target group with health checks
PROD_TG_ARN=$(aws elbv2 create-target-group \
    --name aupairhive-prod-tg \
    --protocol HTTP \
    --port 80 \
    --vpc-id $PROD_VPC_ID \
    --target-type ip \
    --health-check-enabled \
    --health-check-protocol HTTP \
    --health-check-path /wp-admin/install.php \
    --health-check-interval-seconds 30 \
    --health-check-timeout-seconds 5 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 3 \
    --matcher HttpCode=200,302 \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)
```

2. **Create ALB listener rule** (HTTPS only):
```bash
# Get HTTPS listener ARN (Port 443)
PROD_LISTENER_ARN=$(aws elbv2 describe-listeners \
    --load-balancer-arn $PROD_ALB_ARN \
    --query 'Listeners[?Port==`443`].ListenerArn' \
    --output text)

# Create rule with priority
aws elbv2 create-rule \
    --listener-arn $PROD_LISTENER_ARN \
    --priority 20 \
    --conditions Field=host-header,Values=aupairhive.com,www.aupairhive.com \
    --actions Type=forward,TargetGroupArn=$PROD_TG_ARN
```

3. **Create CloudFront distribution for caching and CDN**:
```bash
cat > cloudfront-distribution.json <<EOF
{
  "CallerReference": "aupairhive-prod-$(date +%s)",
  "Comment": "Au Pair Hive PROD - CloudFront CDN",
  "Enabled": true,
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "ALB-aupairhive",
        "DomainName": "$(aws elbv2 describe-load-balancers --names prod-alb --query 'LoadBalancers[0].DNSName' --output text)",
        "CustomOriginConfig": {
          "HTTPPort": 80,
          "HTTPSPort": 443,
          "OriginProtocolPolicy": "https-only",
          "OriginSslProtocols": {
            "Quantity": 1,
            "Items": ["TLSv1.2"]
          }
        },
        "OriginShield": {
          "Enabled": true,
          "OriginShieldRegion": "af-south-1"
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "ALB-aupairhive",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 7,
      "Items": ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    },
    "Compress": true,
    "MinTTL": 0,
    "DefaultTTL": 3600,
    "MaxTTL": 86400,
    "ForwardedValues": {
      "QueryString": true,
      "Cookies": {"Forward": "all"},
      "Headers": {
        "Quantity": 3,
        "Items": ["Host", "CloudFront-Forwarded-Proto", "CloudFront-Is-Desktop-Viewer"]
      }
    }
  },
  "Aliases": {
    "Quantity": 2,
    "Items": ["aupairhive.com", "www.aupairhive.com"]
  },
  "ViewerCertificate": {
    "ACMCertificateArn": "arn:aws:acm:us-east-1:093646564004:certificate/your-cert-id",
    "SSLSupportMethod": "sni-only",
    "MinimumProtocolVersion": "TLSv1.2_2021"
  },
  "PriceClass": "PriceClass_100"
}
EOF

# Create distribution
aws cloudfront create-distribution --distribution-config file://cloudfront-distribution.json

# Get distribution ID and domain name
DISTRIBUTION_ID=$(aws cloudfront list-distributions \
    --query "DistributionList.Items[?Comment=='Au Pair Hive PROD - CloudFront CDN'].Id" \
    --output text)

CF_DOMAIN=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID \
    --query 'Distribution.DomainName' --output text)

echo "CloudFront Distribution: $CF_DOMAIN"
# Wait for distribution to deploy (15-20 minutes)
```

**Verification**:
- [ ] ALB target group created with health checks
- [ ] ALB HTTPS listener rule configured (port 443)
- [ ] CloudFront distribution created
- [ ] SSL certificate attached to CloudFront
- [ ] CloudFront aliases: aupairhive.com, www.aupairhive.com

---

### Task 8.3: Create Final Backup of SIT Environment

**Duration**: 1 hour
**Responsible**: Database Administrator

**Steps**:

1. **Create final SIT database backup**:
```bash
export AWS_PROFILE=Tebogo-sit

# Get SIT credentials
SIT_SECRET=$(aws secretsmanager get-secret-value \
    --secret-id bbws/sit/aupairhive/database \
    --query SecretString --output text)

SIT_HOST=$(echo $SIT_SECRET | jq -r '.host')
SIT_USER=$(echo $SIT_SECRET | jq -r '.username')
SIT_PASS=$(echo $SIT_SECRET | jq -r '.password')
SIT_DB=$(echo $SIT_SECRET | jq -r '.dbname')

# Create final backup with timestamp
BACKUP_FILE="aupairhive_sit_final_backup_$(date +%Y%m%d_%H%M%S).sql"

mysqldump -h $SIT_HOST -u $SIT_USER -p$SIT_PASS \
    --single-transaction \
    --quick \
    --lock-tables=false \
    --routines \
    --triggers \
    $SIT_DB > $BACKUP_FILE

# Compress backup
gzip $BACKUP_FILE

# Upload to S3 for safekeeping
aws s3 cp ${BACKUP_FILE}.gz s3://bbws-prod-backups/aupairhive/pre-prod-migration/

# Verify
aws s3 ls s3://bbws-prod-backups/aupairhive/pre-prod-migration/
```

2. **Create final SIT files backup**:
```bash
# Export SIT EFS files
aws ecs run-task \
    --cluster sit-cluster \
    --task-definition aupairhive-sit-task \
    --overrides '{
        "containerOverrides": [{
            "name": "wordpress",
            "command": ["sh", "-c", "tar czf /tmp/aupairhive-sit-files-final-$(date +%Y%m%d).tar.gz -C /var/www/html . && aws s3 cp /tmp/aupairhive-sit-files-final-*.tar.gz s3://bbws-prod-backups/aupairhive/pre-prod-migration/"]
        }]
    }' \
    --launch-type FARGATE

# Wait and verify
sleep 600
aws s3 ls s3://bbws-prod-backups/aupairhive/pre-prod-migration/
```

3. **Document backup details**:
```bash
cat > final_sit_backup_manifest.txt <<EOF
=== Final SIT Backup Manifest ===
Date: $(date)

Database Backup:
- File: aupairhive_sit_final_backup_YYYYMMDD_HHMMSS.sql.gz
- Location: s3://bbws-prod-backups/aupairhive/pre-prod-migration/
- Size: $(aws s3 ls s3://bbws-prod-backups/aupairhive/pre-prod-migration/ | grep sql.gz | awk '{print $3}') bytes
- SHA256: $(sha256sum ${BACKUP_FILE}.gz | awk '{print $1}')

Files Backup:
- File: aupairhive-sit-files-final-YYYYMMDD.tar.gz
- Location: s3://bbws-prod-backups/aupairhive/pre-prod-migration/
- Size: $(aws s3 ls s3://bbws-prod-backups/aupairhive/pre-prod-migration/ | grep files | awk '{print $3}') bytes

Purpose: Final pre-production backup for rollback if needed
Retention: 90 days
EOF
```

**Verification**:
- [ ] SIT database backup created and compressed
- [ ] SIT files backup created
- [ ] Backups uploaded to S3 (bbws-prod-backups)
- [ ] Backup checksums documented
- [ ] Backup manifest created

---

### Task 8.4: Configure Production Monitoring and Alerting

**Duration**: 2 hours
**Responsible**: DevOps Engineer

**Steps**:

1. **Create CloudWatch Dashboard for PROD**:
```bash
cat > cloudwatch-dashboard.json <<EOF
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "title": "ECS Service - Running Tasks",
        "metrics": [
          ["AWS/ECS", "CPUUtilization", {"stat": "Average"}],
          [".", "MemoryUtilization", {"stat": "Average"}]
        ],
        "region": "af-south-1",
        "period": 300
      }
    },
    {
      "type": "metric",
      "properties": {
        "title": "ALB Target Health",
        "metrics": [
          ["AWS/ApplicationELB", "HealthyHostCount", {"stat": "Average"}],
          [".", "UnHealthyHostCount", {"stat": "Average"}]
        ],
        "region": "af-south-1"
      }
    },
    {
      "type": "metric",
      "properties": {
        "title": "RDS Database Performance",
        "metrics": [
          ["AWS/RDS", "CPUUtilization", {"stat": "Average"}],
          [".", "DatabaseConnections", {"stat": "Sum"}],
          [".", "FreeStorageSpace", {"stat": "Average"}]
        ],
        "region": "af-south-1"
      }
    },
    {
      "type": "metric",
      "properties": {
        "title": "CloudFront Requests",
        "metrics": [
          ["AWS/CloudFront", "Requests", {"stat": "Sum"}],
          [".", "4xxErrorRate", {"stat": "Average"}],
          [".", "5xxErrorRate", {"stat": "Average"}]
        ],
        "region": "us-east-1"
      }
    }
  ]
}
EOF

aws cloudwatch put-dashboard \
    --dashboard-name AuPairHive-PROD \
    --dashboard-body file://cloudwatch-dashboard.json
```

2. **Create SNS topic for production alerts**:
```bash
# Create SNS topic
aws sns create-topic --name aupairhive-prod-alerts

# Get topic ARN
TOPIC_ARN=$(aws sns list-topics \
    --query "Topics[?contains(TopicArn, 'aupairhive-prod-alerts')].TopicArn" \
    --output text)

# Subscribe email addresses
aws sns subscribe \
    --topic-arn $TOPIC_ARN \
    --protocol email \
    --notification-endpoint devops@kimmyai.io

aws sns subscribe \
    --topic-arn $TOPIC_ARN \
    --protocol email \
    --notification-endpoint technical-lead@kimmyai.io

# Confirm subscriptions via email
```

3. **Create CloudWatch Alarms**:
```bash
# Alarm 1: ECS High CPU (>80%)
aws cloudwatch put-metric-alarm \
    --alarm-name aupairhive-prod-high-cpu \
    --alarm-description "ECS CPU utilization exceeds 80%" \
    --metric-name CPUUtilization \
    --namespace AWS/ECS \
    --statistic Average \
    --period 300 \
    --evaluation-periods 2 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=ServiceName,Value=aupairhive-prod-service Name=ClusterName,Value=prod-cluster \
    --alarm-actions $TOPIC_ARN

# Alarm 2: Unhealthy Targets
aws cloudwatch put-metric-alarm \
    --alarm-name aupairhive-prod-unhealthy-targets \
    --alarm-description "ALB has unhealthy targets" \
    --metric-name UnHealthyHostCount \
    --namespace AWS/ApplicationELB \
    --statistic Average \
    --period 60 \
    --evaluation-periods 2 \
    --threshold 1 \
    --comparison-operator GreaterThanOrEqualToThreshold \
    --dimensions Name=TargetGroup,Value=$PROD_TG_ARN Name=LoadBalancer,Value=$PROD_ALB_ARN \
    --alarm-actions $TOPIC_ARN

# Alarm 3: RDS High CPU (>70%)
aws cloudwatch put-metric-alarm \
    --alarm-name aupairhive-prod-rds-high-cpu \
    --alarm-description "RDS CPU exceeds 70%" \
    --metric-name CPUUtilization \
    --namespace AWS/RDS \
    --statistic Average \
    --period 300 \
    --evaluation-periods 2 \
    --threshold 70 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=DBInstanceIdentifier,Value=bbws-prod-mysql \
    --alarm-actions $TOPIC_ARN

# Alarm 4: CloudFront 5xx Error Rate (>1%)
aws cloudwatch put-metric-alarm \
    --alarm-name aupairhive-prod-cloudfront-5xx \
    --alarm-description "CloudFront 5xx error rate exceeds 1%" \
    --metric-name 5xxErrorRate \
    --namespace AWS/CloudFront \
    --statistic Average \
    --period 60 \
    --evaluation-periods 2 \
    --threshold 1 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=DistributionId,Value=$DISTRIBUTION_ID \
    --alarm-actions $TOPIC_ARN \
    --region us-east-1

# Alarm 5: Database Connection Count (>50)
aws cloudwatch put-metric-alarm \
    --alarm-name aupairhive-prod-db-connections \
    --alarm-description "Database connections exceed 50" \
    --metric-name DatabaseConnections \
    --namespace AWS/RDS \
    --statistic Average \
    --period 300 \
    --evaluation-periods 1 \
    --threshold 50 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=DBInstanceIdentifier,Value=bbws-prod-mysql \
    --alarm-actions $TOPIC_ARN
```

4. **Configure log retention**:
```bash
# Set CloudWatch Logs retention to 90 days
aws logs put-retention-policy \
    --log-group-name /ecs/aupairhive-prod \
    --retention-in-days 90
```

**Verification**:
- [ ] CloudWatch Dashboard created and viewable
- [ ] SNS topic created with email subscriptions
- [ ] Email subscriptions confirmed
- [ ] 5 CloudWatch alarms configured
- [ ] Alarms linked to SNS topic
- [ ] Log retention configured (90 days)

---

### Task 8.5: Prepare Rollback Procedures

**Duration**: 1 hour
**Responsible**: Technical Lead + DevOps Engineer

**Rollback Scenarios and Procedures**:

```bash
cat > prod_rollback_procedures.md <<'EOF'
# Production Rollback Procedures - Au Pair Hive

## Scenario 1: DNS Cutover Rollback (Within 1 Hour of Go-Live)

**When to Use**: Critical issues found immediately after DNS cutover, site completely down

**Steps**:
1. **Revert DNS to Xneelo**:
   ```bash
   # Update DNS records back to Xneelo nameservers
   # (Execute in DNS registrar console)
   # TTL: 300 seconds (5 minutes)
   ```

2. **Verify old site accessible**:
   ```bash
   curl -I http://aupairhive.com
   # Expected: Resolves to Xneelo servers
   ```

3. **Communicate to stakeholders**:
   - Send email to client and team
   - Update status page (if exists)

**RTO (Recovery Time Objective)**: 5-15 minutes

---

## Scenario 2: Application Rollback (Database Issues)

**When to Use**: Data corruption, migration issues, database performance problems

**Steps**:
1. **Stop PROD ECS service**:
   ```bash
   export AWS_PROFILE=Tebogo-prod
   aws ecs update-service \
       --cluster prod-cluster \
       --service aupairhive-prod-service \
       --desired-count 0
   ```

2. **Restore database from SIT backup**:
   ```bash
   # Drop corrupted database
   mysql -h $PROD_RDS_ENDPOINT -u admin -p -e "DROP DATABASE tenant_aupairhive_db;"

   # Recreate database
   mysql -h $PROD_RDS_ENDPOINT -u admin -p -e "CREATE DATABASE tenant_aupairhive_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

   # Restore from backup
   gunzip < aupairhive_sit_final_backup_*.sql.gz | mysql -h $PROD_RDS_ENDPOINT -u admin -p tenant_aupairhive_db

   # Verify
   mysql -h $PROD_RDS_ENDPOINT -u $PROD_USER -p$PROD_PASS tenant_aupairhive_db -e "SELECT COUNT(*) FROM wp_posts;"
   ```

3. **Restart ECS service**:
   ```bash
   aws ecs update-service \
       --cluster prod-cluster \
       --service aupairhive-prod-service \
       --desired-count 2
   ```

**RTO**: 15-30 minutes

---

## Scenario 3: Complete Rollback to Xneelo (Critical Failure)

**When to Use**: Multiple critical issues, migration fundamentally flawed, client requests abort

**Steps**:
1. **Immediate DNS reversion** (Scenario 1)
2. **Stop all PROD services**:
   ```bash
   aws ecs update-service --cluster prod-cluster --service aupairhive-prod-service --desired-count 0
   aws elbv2 delete-rule --rule-arn <rule-arn>
   ```

3. **Notify client of rollback**:
   - Email with root cause explanation
   - Propose new go-live date after fixing issues

4. **Post-rollback analysis**:
   - Document all issues encountered
   - Fix in DEV/SIT environments
   - Re-test before attempting PROD again

**RTO**: 5-15 minutes (DNS reversion)

---

## Rollback Decision Matrix

| Issue Severity | Timeframe | Action |
|----------------|-----------|--------|
| Critical (Site down, data loss) | Any time | Immediate DNS rollback |
| High (Major functionality broken) | <2 hours post-launch | Fix in place if possible, else rollback |
| High (Major functionality broken) | >2 hours post-launch | Fix in place (DNS propagated) |
| Medium (Minor issues) | Any time | Fix in place, monitor |
| Low (Cosmetic) | Any time | Document for post-launch fix |

---

## Rollback Authorization

**Only the following individuals can authorize PROD rollback**:
- Technical Lead
- Product Owner
- Client Stakeholder (for complete rollback)

**Rollback Communication**:
- Immediate: Phone call to Technical Lead and Product Owner
- Within 15 min: Email to stakeholders
- Within 1 hour: Post-mortem meeting scheduled
EOF
```

**Verification**:
- [ ] Rollback procedures documented
- [ ] Rollback scenarios identified
- [ ] Rollback decision matrix created
- [ ] Rollback authorization process defined
- [ ] Team trained on rollback procedures

---

### Task 8.6: Prepare Go-Live Runbook

**Duration**: 1.5 hours
**Responsible**: Technical Lead + DevOps Engineer

**Go-Live Runbook**:

```bash
cat > go_live_runbook.md <<'EOF'
# Go-Live Runbook - Au Pair Hive Migration
# Date: [SCHEDULED DATE]
# Downtime Window: [START TIME] - [END TIME] (2 hours max)

## Pre-Go-Live Checklist (T-24 hours)

- [ ] Final SIT backup completed and verified
- [ ] PROD infrastructure provisioned and tested
- [ ] Monitoring and alerting configured
- [ ] Rollback procedures reviewed with team
- [ ] On-call schedule confirmed
- [ ] Client notified of go-live window
- [ ] Xneelo hosting access confirmed
- [ ] DNS registrar access confirmed
- [ ] All team members available during cutover window

---

## Go-Live Timeline

### T-2 hours: Final Preparations

**Time**: [e.g., 22:00 SAST]
**Responsible**: Technical Lead

1. [ ] Announce go-live start to stakeholders
2. [ ] Join video conference/Slack war room
3. [ ] Verify all team members online
4. [ ] Final check: SIT environment stable
5. [ ] Final check: PROD infrastructure healthy

### T-1 hour: Data Freeze and Export

**Time**: [e.g., 23:00 SAST]
**Responsible**: Database Administrator

1. [ ] **Put Xneelo site in maintenance mode**:
   - Install "Coming Soon" plugin
   - Or create maintenance.html

2. [ ] **Export final database from Xneelo**:
   ```bash
   # Via cPanel phpMyAdmin
   # Export: Custom method, All tables, SQL format
   # Download: aupairhive_final_export_[DATETIME].sql
   ```

3. [ ] **Verify export file integrity**:
   ```bash
   ls -lh aupairhive_final_export_*.sql
   head -n 20 aupairhive_final_export_*.sql
   # Check for valid SQL statements
   ```

4. [ ] **Download final files from Xneelo** (if any changes since SIT):
   ```bash
   # Via FTP or cPanel File Manager
   # Download only wp-content/uploads/ if content added
   ```

### T-30 minutes: Import to PROD

**Time**: [e.g., 23:30 SAST]
**Responsible**: Database Administrator + DevOps Engineer

1. [ ] **Import database to PROD**:
   ```bash
   export AWS_PROFILE=Tebogo-prod

   # Run import script with PROD parameters
   ./import_database.sh \
       --environment prod \
       --tenant-id aupairhive \
       --sql-file aupairhive_final_export_*.sql \
       --source-url "https://aupairhive.com" \
       --target-url "https://aupairhive.com"

   # Note: Keep same domain (no URL replacement needed)
   ```

2. [ ] **Upload files to PROD EFS**:
   ```bash
   ./upload_wordpress_files.sh \
       --environment prod \
       --tenant-id aupairhive \
       --archive aupairhive_files.tar.gz
   ```

3. [ ] **Verify PROD site via CloudFront URL**:
   ```bash
   # Get CloudFront URL
   echo "Test URL: https://$CF_DOMAIN"

   # Add to /etc/hosts for testing:
   # [CloudFront IP] aupairhive.com

   # Test homepage
   curl -H "Host: aupairhive.com" https://$CF_DOMAIN
   ```

### T-15 minutes: Final Verification

**Time**: [e.g., 23:45 SAST]
**Responsible**: QA Engineer

1. [ ] **Smoke test PROD site** (via CloudFront URL):
   - [ ] Homepage loads
   - [ ] Admin login works
   - [ ] One form submission test
   - [ ] Premium licenses active

2. [ ] **Verify monitoring**:
   - [ ] ECS service: 2 tasks running
   - [ ] ALB targets: healthy
   - [ ] No errors in CloudWatch logs

### T-0: DNS Cutover

**Time**: [e.g., 00:00 SAST]
**Responsible**: DevOps Engineer

1. [ ] **Lower DNS TTL** (if not already done):
   - Set TTL to 300 seconds (5 minutes)
   - Wait for TTL to expire (check with `dig aupairhive.com`)

2. [ ] **Update DNS records**:
   ```
   Type: A (or CNAME)
   Host: aupairhive.com
   Value: [CloudFront Distribution Domain]
   TTL: 300

   Type: CNAME
   Host: www.aupairhive.com
   Value: [CloudFront Distribution Domain]
   TTL: 300
   ```

3. [ ] **Verify DNS propagation**:
   ```bash
   # Check every 30 seconds
   watch -n 30 "dig aupairhive.com +short"

   # Expected: CloudFront IP addresses
   ```

### T+5 minutes: Verification

**Time**: [e.g., 00:05 SAST]
**Responsible**: Entire Team

1. [ ] **Test public site access**:
   ```bash
   curl -I https://aupairhive.com
   # Expected: HTTP 200, X-Cache: Hit from cloudfront
   ```

2. [ ] **Team testing**:
   - [ ] Technical Lead: Homepage, admin panel
   - [ ] QA: Form submissions
   - [ ] DevOps: Monitoring dashboard
   - [ ] Client: Visual verification

3. [ ] **Check CloudWatch metrics**:
   - [ ] Requests coming in to CloudFront
   - [ ] No 5xx errors
   - [ ] ALB healthy targets = 2

### T+30 minutes: Go/No-Go Decision

**Time**: [e.g., 00:30 SAST]
**Responsible**: Technical Lead + Client

**Go Decision**: Site functional, no critical issues
- [ ] Announce go-live success
- [ ] Keep monitoring for 2 hours
- [ ] Proceed to post-launch monitoring

**No-Go Decision**: Critical issues found
- [ ] Execute Rollback Procedure (see prod_rollback_procedures.md)
- [ ] Notify stakeholders
- [ ] Schedule post-mortem

### T+2 hours: Stand Down

**Time**: [e.g., 02:00 SAST]
**Responsible**: Technical Lead

- [ ] Final check: No critical alerts
- [ ] Final check: Client satisfied
- [ ] Announce successful go-live completion
- [ ] Team can stand down from war room
- [ ] On-call engineer takes over monitoring

---

## Contact List

| Role | Name | Phone | Email |
|------|------|-------|-------|
| Technical Lead | [Name] | [Phone] | [Email] |
| DevOps Engineer | [Name] | [Phone] | [Email] |
| Database Admin | [Name] | [Phone] | [Email] |
| QA Engineer | [Name] | [Phone] | [Email] |
| Product Owner | [Name] | [Phone] | [Email] |
| Client Stakeholder | [Name] | [Phone] | [Email] |

## Communication Channels

- **War Room**: [Zoom/Teams link]
- **Slack Channel**: #aupairhive-golive
- **Email**: golive-team@kimmyai.io

## Escalation Path

1. Technical issues → DevOps Engineer → Technical Lead
2. Business decisions → Product Owner → Client
3. Rollback decision → Technical Lead + Product Owner + Client

---

## Post-Go-Live Actions (Next Day)

- [ ] Remove Xneelo maintenance mode (keep site as backup for 7 days)
- [ ] Update CloudWatch dashboard with first 24h metrics
- [ ] Send go-live success email to stakeholders
- [ ] Schedule post-launch review meeting
- [ ] Begin Phase 10: Post-Migration Monitoring
EOF
```

**Verification**:
- [ ] Go-live runbook created with detailed timeline
- [ ] All tasks have assigned owners
- [ ] Contact list populated
- [ ] Communication channels established
- [ ] Escalation path defined
- [ ] Go/No-Go decision criteria clear

---

## Verification Checklist

### Infrastructure Provisioning
- [ ] PROD database created with strong credentials
- [ ] Credentials stored in Secrets Manager (KMS encrypted)
- [ ] EFS access point created in af-south-1
- [ ] ECS task definition registered (1024 CPU, 2048 MB)
- [ ] ECS service deployed with 2 tasks
- [ ] Auto-scaling configured (2-4 tasks)
- [ ] ALB target group and HTTPS listener configured
- [ ] CloudFront distribution created with SSL

### Backup and DR
- [ ] Final SIT database backup created
- [ ] Final SIT files backup created
- [ ] Backups uploaded to S3 (bbws-prod-backups)
- [ ] Backup manifest documented

### Monitoring and Alerting
- [ ] CloudWatch Dashboard created
- [ ] SNS topic created with email subscriptions
- [ ] 5 CloudWatch alarms configured
- [ ] Log retention configured (90 days)

### Rollback Preparedness
- [ ] Rollback procedures documented
- [ ] Rollback scenarios identified
- [ ] Rollback authorization process defined
- [ ] Team trained on rollback procedures

### Go-Live Readiness
- [ ] Go-live runbook created
- [ ] Go-live timeline defined
- [ ] Contact list populated
- [ ] Communication channels established
- [ ] Go/No-Go criteria defined

---

## Success Criteria

- [ ] PROD infrastructure fully provisioned and tested
- [ ] Auto-scaling configured for high availability
- [ ] CloudFront CDN configured for performance
- [ ] Final SIT backups created and stored
- [ ] Monitoring and alerting operational
- [ ] Rollback procedures documented and understood
- [ ] Go-live runbook complete with timeline
- [ ] Team trained on go-live procedures
- [ ] Client notified of go-live schedule
- [ ] Ready for Phase 9 (DNS Cutover and Go-Live)

**Definition of Done**:
PROD environment fully prepared and tested. All backups created. Monitoring operational. Rollback procedures in place. Go-live runbook complete. Team ready for DNS cutover.

---

## Sign-Off

**Completed By**: _________________ Date: _________
**Verified By**: _________________ Date: _________
**PROD Infrastructure Ready**: [ ] YES [ ] NO
**Monitoring Operational**: [ ] YES [ ] NO
**Rollback Procedures Ready**: [ ] YES [ ] NO
**Go-Live Runbook Approved**: [ ] YES [ ] NO
**Ready for Phase 9**: [ ] YES [ ] NO

---

## Notes

**PROD Configuration**:
- Region: af-south-1 (Cape Town)
- ECS Tasks: 2 (auto-scale to 4)
- CPU/Memory: 1024/2048
- Database: Multi-AZ for HA
- CloudFront: Enabled with caching

**Go-Live Schedule**:
- Date: ______________
- Start Time: ______________
- Downtime Window: 2 hours max
- Team Availability: ______________

---

**Next Phase**: Proceed to **Phase 9**: `09_DNS_Cutover_and_GoLive.md`
