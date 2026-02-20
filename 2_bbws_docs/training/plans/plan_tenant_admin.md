# Tenant Admin Training Plan

**Parent Plan**: [master_plan.md](./master_plan.md)
**Target Role**: Tenant Operations Team, NOC Staff, Support Engineers
**Total Duration**: ~12 hours
**Status**: PENDING

---

## Overview

The Tenant Admin training module covers tenant lifecycle management including CRUD operations, suspension/resumption, problem diagnosis, performance monitoring, security management, reset/recovery procedures, and critically, hijack detection and response.

---

## Submodule TA-01: Tenant CRUD Operations

**Duration**: 1.5 hours
**Status**: PENDING

### Learning Objectives
- Create new tenant resources
- Read/query tenant information
- Update tenant configurations
- Delete tenant resources (soft and hard delete)

### Prerequisites
- AWS CLI configured
- Understanding of ECS services, EFS access points
- Access to Secrets Manager

### Practical Exercises

#### Exercise TA-01-1: Create Tenant (C)
```bash
# Step 1: Create tenant database
# Run ECS task to create database
AWS_PROFILE=Tebogo-sit aws ecs run-task \
  --cluster sit-cluster \
  --task-definition sit-db-init \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=DISABLED}" \
  --overrides '{
    "containerOverrides": [{
      "name": "db-init",
      "environment": [
        {"name": "DB_NAME", "value": "tenant_newclient"},
        {"name": "TENANT_ID", "value": "tenant-newclient"}
      ]
    }]
  }' \
  --region eu-west-1

# Step 2: Create EFS access point
AWS_PROFILE=Tebogo-sit aws efs create-access-point \
  --file-system-id fs-xxx \
  --posix-user Uid=1001,Gid=1001 \
  --root-directory "Path=/tenant-newclient,CreationInfo={OwnerUid=1001,OwnerGid=1001,Permissions=755}" \
  --tags Key=tenant_id,Value=tenant-newclient Key=Environment,Value=sit \
  --region eu-west-1

# Step 3: Create ECS service (use task definition)
# Step 4: Create ALB target group
# Step 5: Create listener rule
```

#### Exercise TA-01-2: Read Tenant Information (R)
```bash
# List all tenants (ECS services)
AWS_PROFILE=Tebogo-sit aws ecs list-services \
  --cluster sit-cluster \
  --region eu-west-1

# Get specific tenant details
AWS_PROFILE=Tebogo-sit aws ecs describe-services \
  --cluster sit-cluster \
  --services tenant-1-service \
  --query 'services[0].{
    Name: serviceName,
    Status: status,
    Running: runningCount,
    Desired: desiredCount,
    CPU: deploymentConfiguration.minimumHealthyPercent
  }' \
  --region eu-west-1

# Get tenant database info
AWS_PROFILE=Tebogo-sit aws secretsmanager get-secret-value \
  --secret-id sit-tenant-1-db-credentials \
  --query 'SecretString' \
  --region eu-west-1
```

#### Exercise TA-01-3: Update Tenant (U)
```bash
# Update tenant service (change desired count)
AWS_PROFILE=Tebogo-sit aws ecs update-service \
  --cluster sit-cluster \
  --service tenant-1-service \
  --desired-count 2 \
  --region eu-west-1

# Update tenant tags
AWS_PROFILE=Tebogo-sit aws ecs tag-resource \
  --resource-arn arn:aws:ecs:eu-west-1:815856636111:service/sit-cluster/tenant-1-service \
  --tags key=billing_contact,value=client@example.com \
  --region eu-west-1

# Update task definition (memory/CPU)
# (Requires creating new task definition revision)
```

#### Exercise TA-01-4: Delete Tenant (D)
```bash
# SOFT DELETE: Stop tenant service (set desired count to 0)
AWS_PROFILE=Tebogo-sit aws ecs update-service \
  --cluster sit-cluster \
  --service tenant-1-service \
  --desired-count 0 \
  --region eu-west-1

# HARD DELETE: Remove all tenant resources
# WARNING: Destructive operation - requires confirmation

# Step 1: Delete ECS service
AWS_PROFILE=Tebogo-sit aws ecs delete-service \
  --cluster sit-cluster \
  --service tenant-1-service \
  --force \
  --region eu-west-1

# Step 2: Delete EFS access point
AWS_PROFILE=Tebogo-sit aws efs delete-access-point \
  --access-point-id fsap-xxx \
  --region eu-west-1

# Step 3: Delete database (via ECS task)
# Step 4: Delete secrets
# Step 5: Delete ALB target group and listener rule
# Step 6: Delete DNS record
```

### Validation Checklist
- [ ] Can create all tenant resources
- [ ] Can query tenant status and details
- [ ] Can update tenant configurations
- [ ] Understands soft vs hard delete
- [ ] Follows approval process for deletions

---

## Submodule TA-02: Tenant Suspension and Resumption

**Duration**: 1 hour
**Status**: PENDING

### Learning Objectives
- Suspend tenant operations (multiple methods)
- Resume suspended tenants
- Understand suspension states
- Configure suspension notifications

### Practical Exercises

#### Exercise TA-02-1: Suspension Methods

**Method 1: Service-Level Suspension (Recommended)**
```bash
# Suspend by setting desired count to 0
AWS_PROFILE=Tebogo-sit aws ecs update-service \
  --cluster sit-cluster \
  --service tenant-1-service \
  --desired-count 0 \
  --region eu-west-1

# Verify suspension
AWS_PROFILE=Tebogo-sit aws ecs describe-services \
  --cluster sit-cluster \
  --services tenant-1-service \
  --query 'services[0].{Running: runningCount, Desired: desiredCount}' \
  --region eu-west-1
# Expected: Running: 0, Desired: 0
```

**Method 2: DNS-Level Suspension (Maintenance Page)**
```bash
# Point DNS to maintenance page
AWS_PROFILE=Tebogo-sit aws route53 change-resource-record-sets \
  --hosted-zone-id Z0XXXXXXXXX \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "tenant-1.wpsit.kimmyai.io",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "maintenance.bbws.io",
          "EvaluateTargetHealth": false
        }
      }
    }]
  }'
```

**Method 3: ALB-Level Suspension (Block Traffic)**
```bash
# Modify ALB listener rule to return 503
AWS_PROFILE=Tebogo-sit aws elbv2 modify-rule \
  --rule-arn arn:aws:elasticloadbalancing:eu-west-1:815856636111:listener-rule/app/sit-alb/xxx/xxx/xxx \
  --actions Type=fixed-response,FixedResponseConfig="{ContentType='text/html',StatusCode='503',MessageBody='<h1>Service Temporarily Unavailable</h1>'}"
```

#### Exercise TA-02-2: Resume Suspended Tenant
```bash
# Resume service-level suspension
AWS_PROFILE=Tebogo-sit aws ecs update-service \
  --cluster sit-cluster \
  --service tenant-1-service \
  --desired-count 1 \
  --region eu-west-1

# Wait for task to start
AWS_PROFILE=Tebogo-sit aws ecs wait services-stable \
  --cluster sit-cluster \
  --services tenant-1-service \
  --region eu-west-1

# Verify tenant is running
curl -I https://tenant-1.wpsit.kimmyai.io/
```

#### Exercise TA-02-3: Suspension State Management
```bash
# Add suspension tag for tracking
AWS_PROFILE=Tebogo-sit aws ecs tag-resource \
  --resource-arn arn:aws:ecs:eu-west-1:815856636111:service/sit-cluster/tenant-1-service \
  --tags key=suspended,value=true key=suspension_reason,value=non-payment key=suspension_date,value=$(date +%Y-%m-%d) \
  --region eu-west-1

# Query suspended tenants
AWS_PROFILE=Tebogo-sit aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=suspended,Values=true \
  --resource-type-filters ecs:service \
  --region eu-west-1
```

### Suspension Workflow

| State | ECS Running | DNS | ALB | User Experience |
|-------|-------------|-----|-----|-----------------|
| Active | 1+ | Active | Forward | Normal access |
| Soft Suspended | 0 | Active | Forward | 503 error |
| Maintenance | 1+ | Redirect | Forward | Maintenance page |
| Hard Suspended | 0 | Redirect | Block | Maintenance page |
| Deleted | N/A | Removed | Removed | NXDOMAIN |

---

## Submodule TA-03: Problem Diagnosis and Resolution

**Duration**: 2 hours
**Status**: PENDING

### Learning Objectives
- Diagnose common tenant problems
- Use CloudWatch logs effectively
- Resolve connectivity issues
- Troubleshoot WordPress-specific issues

### Practical Exercises

#### Exercise TA-03-1: Task Failure Diagnosis
```bash
# Check ECS service events
AWS_PROFILE=Tebogo-sit aws ecs describe-services \
  --cluster sit-cluster \
  --services tenant-1-service \
  --query 'services[0].events[0:5]' \
  --region eu-west-1

# Check stopped tasks for error
AWS_PROFILE=Tebogo-sit aws ecs list-tasks \
  --cluster sit-cluster \
  --family tenant-1-task \
  --desired-status STOPPED \
  --region eu-west-1

# Get stop reason
AWS_PROFILE=Tebogo-sit aws ecs describe-tasks \
  --cluster sit-cluster \
  --tasks <task-arn> \
  --query 'tasks[0].{StopCode: stopCode, StopReason: stoppedReason, Containers: containers[*].{Name: name, ExitCode: exitCode, Reason: reason}}' \
  --region eu-west-1
```

#### Exercise TA-03-2: CloudWatch Log Analysis
```bash
# Get recent error logs
AWS_PROFILE=Tebogo-sit aws logs filter-log-events \
  --log-group-name /ecs/sit \
  --log-stream-name-prefix tenant-1 \
  --filter-pattern "ERROR" \
  --start-time $(date -v-1H +%s000) \
  --region eu-west-1

# Get PHP fatal errors
AWS_PROFILE=Tebogo-sit aws logs filter-log-events \
  --log-group-name /ecs/sit \
  --log-stream-name-prefix tenant-1 \
  --filter-pattern "Fatal error" \
  --start-time $(date -v-1H +%s000) \
  --region eu-west-1
```

#### Exercise TA-03-3: Database Connectivity Test
```bash
# Run MySQL connectivity test via ECS task
AWS_PROFILE=Tebogo-sit aws ecs run-task \
  --cluster sit-cluster \
  --task-definition sit-db-init \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx]}" \
  --overrides '{
    "containerOverrides": [{
      "name": "db-init",
      "command": ["mysql", "-h", "sit-mysql.xxx.eu-west-1.rds.amazonaws.com", "-u", "admin", "-p", "-e", "SHOW DATABASES;"]
    }]
  }' \
  --region eu-west-1
```

#### Exercise TA-03-4: ALB Health Check Troubleshooting
```bash
# Check target health
AWS_PROFILE=Tebogo-sit aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:eu-west-1:815856636111:targetgroup/tenant-1-tg/xxx \
  --region eu-west-1

# Common health check failures:
# - unhealthy: Target didn't respond to health check
# - timeout: Health check timed out
# - draining: Target is being deregistered
```

### Common Problems and Solutions

| Problem | Symptoms | Diagnosis Command | Resolution |
|---------|----------|-------------------|------------|
| Task won't start | STOPPED tasks, event errors | `ecs describe-tasks` | Check image, IAM, networking |
| Database connection | 502 errors, PHP errors | Check RDS status, security groups | Fix SG rules, verify credentials |
| EFS mount failure | Task startup fails | Check mount target status | Verify EFS security group |
| Out of memory | OOMKilled in task | `ecs describe-tasks` | Increase memory limit |
| Health check failing | 503 errors, unhealthy targets | `elbv2 describe-target-health` | Check health check path, timeout |

---

## Submodule TA-04: Tenant Performance Monitoring

**Duration**: 1.5 hours
**Status**: PENDING

### Learning Objectives
- Monitor tenant-specific metrics
- Create CloudWatch dashboards
- Set up tenant alerts
- Analyze performance trends

### Practical Exercises

#### Exercise TA-04-1: Tenant CPU/Memory Metrics
```bash
# Get tenant ECS task metrics
AWS_PROFILE=Tebogo-sit aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ClusterName,Value=sit-cluster Name=ServiceName,Value=tenant-1-service \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Average Maximum \
  --region eu-west-1

# Memory utilization
AWS_PROFILE=Tebogo-sit aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name MemoryUtilization \
  --dimensions Name=ClusterName,Value=sit-cluster Name=ServiceName,Value=tenant-1-service \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Average Maximum \
  --region eu-west-1
```

#### Exercise TA-04-2: Tenant Request Metrics
```bash
# ALB request count per tenant (via target group)
AWS_PROFILE=Tebogo-sit aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name RequestCountPerTarget \
  --dimensions Name=TargetGroup,Value=targetgroup/tenant-1-tg/xxx \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Sum \
  --region eu-west-1

# Response time
AWS_PROFILE=Tebogo-sit aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --dimensions Name=TargetGroup,Value=targetgroup/tenant-1-tg/xxx \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Average p99 \
  --region eu-west-1
```

#### Exercise TA-04-3: Create Tenant Alert
```bash
# Create alarm for high CPU
AWS_PROFILE=Tebogo-sit aws cloudwatch put-metric-alarm \
  --alarm-name tenant-1-high-cpu \
  --alarm-description "Tenant-1 CPU above 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --dimensions Name=ClusterName,Value=sit-cluster Name=ServiceName,Value=tenant-1-service \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:eu-west-1:815856636111:bbws-ops-alerts \
  --region eu-west-1
```

### Tenant Performance Thresholds

| Metric | Good | Warning | Critical |
|--------|------|---------|----------|
| CPU Utilization | <60% | 60-80% | >80% |
| Memory Utilization | <70% | 70-85% | >85% |
| Response Time (p99) | <500ms | 500ms-1s | >1s |
| Error Rate | <1% | 1-5% | >5% |

---

## Submodule TA-05: Tenant Security Management

**Duration**: 1.5 hours
**Status**: PENDING

### Learning Objectives
- Audit tenant security configurations
- Manage tenant credentials
- Review tenant access logs
- Implement security controls

### Practical Exercises

#### Exercise TA-05-1: Credential Rotation
```bash
# Get current credentials
AWS_PROFILE=Tebogo-sit aws secretsmanager get-secret-value \
  --secret-id sit-tenant-1-db-credentials \
  --query 'SecretString' \
  --region eu-west-1

# Rotate credentials
AWS_PROFILE=Tebogo-sit aws secretsmanager rotate-secret \
  --secret-id sit-tenant-1-db-credentials \
  --rotation-lambda-arn arn:aws:lambda:eu-west-1:815856636111:function:SecretsManagerMySQLRotation \
  --region eu-west-1

# Force new task deployment to pick up new credentials
AWS_PROFILE=Tebogo-sit aws ecs update-service \
  --cluster sit-cluster \
  --service tenant-1-service \
  --force-new-deployment \
  --region eu-west-1
```

#### Exercise TA-05-2: Security Group Audit
```bash
# Get tenant task security groups
TASK_ARN=$(AWS_PROFILE=Tebogo-sit aws ecs list-tasks --cluster sit-cluster --service-name tenant-1-service --query 'taskArns[0]' --output text --region eu-west-1)

AWS_PROFILE=Tebogo-sit aws ecs describe-tasks \
  --cluster sit-cluster \
  --tasks $TASK_ARN \
  --query 'tasks[0].attachments[0].details[?name==`securityGroups`].value' \
  --region eu-west-1

# Review security group rules
AWS_PROFILE=Tebogo-sit aws ec2 describe-security-group-rules \
  --filters "Name=group-id,Values=sg-xxx" \
  --region eu-west-1
```

#### Exercise TA-05-3: Access Log Analysis
```bash
# Get ALB access logs from S3
AWS_PROFILE=Tebogo-sit aws s3 ls s3://bbws-alb-logs-sit/AWSLogs/815856636111/elasticloadbalancing/eu-west-1/$(date +%Y/%m/%d)/

# Download and analyze specific log
AWS_PROFILE=Tebogo-sit aws s3 cp s3://bbws-alb-logs-sit/AWSLogs/815856636111/elasticloadbalancing/eu-west-1/$(date +%Y/%m/%d)/xxx.log.gz ./

# Parse for tenant access
zcat xxx.log.gz | grep "tenant-1.wpsit.kimmyai.io" | head -20
```

---

## Submodule TA-06: Tenant Reset and Recovery

**Duration**: 1 hour
**Status**: PENDING

### Learning Objectives
- Reset tenant to clean state
- Recover from database corruption
- Restore from backups
- Re-initialize WordPress

### Practical Exercises

#### Exercise TA-06-1: Soft Reset (Container Restart)
```bash
# Force new deployment (restarts containers)
AWS_PROFILE=Tebogo-sit aws ecs update-service \
  --cluster sit-cluster \
  --service tenant-1-service \
  --force-new-deployment \
  --region eu-west-1

# Wait for deployment to complete
AWS_PROFILE=Tebogo-sit aws ecs wait services-stable \
  --cluster sit-cluster \
  --services tenant-1-service \
  --region eu-west-1
```

#### Exercise TA-06-2: Database Reset
```bash
# Step 1: Backup current database first
AWS_PROFILE=Tebogo-sit aws ecs run-task \
  --cluster sit-cluster \
  --task-definition sit-db-backup \
  --overrides '{
    "containerOverrides": [{
      "name": "db-backup",
      "environment": [
        {"name": "DB_NAME", "value": "tenant_1_db"},
        {"name": "S3_BUCKET", "value": "bbws-backups-sit"},
        {"name": "BACKUP_PREFIX", "value": "pre-reset"}
      ]
    }]
  }' \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx]}" \
  --region eu-west-1

# Step 2: Drop and recreate database
# WARNING: This deletes all data!
AWS_PROFILE=Tebogo-sit aws ecs run-task \
  --cluster sit-cluster \
  --task-definition sit-db-init \
  --overrides '{
    "containerOverrides": [{
      "name": "db-init",
      "command": ["sh", "-c", "mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -e \"DROP DATABASE IF EXISTS tenant_1_db; CREATE DATABASE tenant_1_db;\""]
    }]
  }' \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx]}" \
  --region eu-west-1
```

#### Exercise TA-06-3: Restore from S3 Backup
```bash
# List available backups
AWS_PROFILE=Tebogo-sit aws s3 ls s3://bbws-backups-sit/tenant-1/

# Restore specific backup
AWS_PROFILE=Tebogo-sit aws ecs run-task \
  --cluster sit-cluster \
  --task-definition sit-db-restore \
  --overrides '{
    "containerOverrides": [{
      "name": "db-restore",
      "environment": [
        {"name": "DB_NAME", "value": "tenant_1_db"},
        {"name": "S3_BACKUP_PATH", "value": "s3://bbws-backups-sit/tenant-1/2025-12-15-backup.sql.gz"}
      ]
    }]
  }' \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx]}" \
  --region eu-west-1
```

---

## Submodule TA-07: Tenant Hijack Detection and Response

**Duration**: 2 hours
**Status**: PENDING

### Learning Objectives
- Understand tenant hijack scenarios
- Configure automated hijack detection
- Respond to hijack incidents
- Implement preventive controls

### Tenant Hijack Scenarios

| Scenario | Description | Detection Method |
|----------|-------------|------------------|
| Credential Theft | Attacker gains DB/WordPress credentials | Failed login patterns, unusual IPs |
| DNS Hijacking | DNS record modified maliciously | DNS monitoring, SOA checks |
| Session Hijacking | WordPress session stolen | Multiple concurrent sessions |
| Database Tampering | Unauthorized DB modifications | Integrity monitoring |
| File Modification | WordPress files changed | File integrity monitoring |
| Admin Account Creation | Unauthorized admin users | User count monitoring |

### Practical Exercises

#### Exercise TA-07-1: Configure Hijack Detection Metrics
```bash
# Create metric filter for failed logins
AWS_PROFILE=Tebogo-sit aws logs put-metric-filter \
  --log-group-name /ecs/sit \
  --filter-name tenant-1-failed-logins \
  --filter-pattern "[timestamp, action=\"login\", result=\"failed\", ...]" \
  --metric-transformations \
    metricName=FailedLogins,metricNamespace=BBWS/Security,metricValue=1,dimensions="{tenant_id=tenant-1}" \
  --region eu-west-1

# Create alarm for suspicious login activity
AWS_PROFILE=Tebogo-sit aws cloudwatch put-metric-alarm \
  --alarm-name tenant-1-suspicious-logins \
  --alarm-description "Multiple failed logins detected for tenant-1" \
  --metric-name FailedLogins \
  --namespace BBWS/Security \
  --dimensions Name=tenant_id,Value=tenant-1 \
  --statistic Sum \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --alarm-actions arn:aws:sns:eu-west-1:815856636111:bbws-security-alerts \
  --region eu-west-1
```

#### Exercise TA-07-2: DNS Hijack Detection
```bash
# Get current DNS record
CURRENT_TARGET=$(dig +short tenant-1.wpsit.kimmyai.io)

# Expected target (CloudFront distribution)
EXPECTED_TARGET="dxxxxxxxxx.cloudfront.net"

# Check for mismatch (potential hijack)
if [ "$CURRENT_TARGET" != "$EXPECTED_TARGET" ]; then
  echo "DNS HIJACK ALERT: Expected $EXPECTED_TARGET, got $CURRENT_TARGET"
  # Send alert
  AWS_PROFILE=Tebogo-sit aws sns publish \
    --topic-arn arn:aws:sns:eu-west-1:815856636111:bbws-security-alerts \
    --message "DNS Hijack detected for tenant-1.wpsit.kimmyai.io" \
    --subject "CRITICAL: DNS Hijack Alert" \
    --region eu-west-1
fi
```

#### Exercise TA-07-3: Database Integrity Check
```bash
# Check for unauthorized admin users
AWS_PROFILE=Tebogo-sit aws ecs run-task \
  --cluster sit-cluster \
  --task-definition sit-db-init \
  --overrides '{
    "containerOverrides": [{
      "name": "db-init",
      "command": ["sh", "-c", "mysql -h $DB_HOST -u $DB_USER -p$DB_PASS tenant_1_db -e \"SELECT user_login, user_email, user_registered FROM wp_users WHERE ID IN (SELECT user_id FROM wp_usermeta WHERE meta_key = '\''wp_capabilities'\'' AND meta_value LIKE '\''%administrator%'\'');\""]
    }]
  }' \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx]}" \
  --region eu-west-1

# Compare admin count with expected
```

#### Exercise TA-07-4: Hijack Response Playbook
```bash
# STEP 1: ISOLATE - Immediately suspend tenant
AWS_PROFILE=Tebogo-sit aws ecs update-service \
  --cluster sit-cluster \
  --service tenant-1-service \
  --desired-count 0 \
  --region eu-west-1

# STEP 2: CAPTURE - Snapshot current state for forensics
# Snapshot EFS
AWS_PROFILE=Tebogo-sit aws backup start-backup-job \
  --backup-vault-name bbws-forensics-vault \
  --resource-arn arn:aws:elasticfilesystem:eu-west-1:815856636111:file-system/fs-xxx \
  --iam-role-arn arn:aws:iam::815856636111:role/AWSBackupRole \
  --region eu-west-1

# Database snapshot (if not using shared RDS)
# Or backup specific tenant database

# STEP 3: INVESTIGATE - Review logs
AWS_PROFILE=Tebogo-sit aws logs filter-log-events \
  --log-group-name /ecs/sit \
  --log-stream-name-prefix tenant-1 \
  --start-time $(date -v-24H +%s000) \
  --filter-pattern "login" \
  --region eu-west-1

# STEP 4: REMEDIATE - Reset credentials and restore
# Rotate all credentials
AWS_PROFILE=Tebogo-sit aws secretsmanager update-secret \
  --secret-id sit-tenant-1-db-credentials \
  --secret-string '{"username":"wp_tenant_1","password":"NEW_SECURE_PASSWORD"}' \
  --region eu-west-1

# STEP 5: RESTORE - Restore from clean backup
# (See TA-06 restore procedures)

# STEP 6: RESUME - After verification, resume tenant
AWS_PROFILE=Tebogo-sit aws ecs update-service \
  --cluster sit-cluster \
  --service tenant-1-service \
  --desired-count 1 \
  --region eu-west-1
```

### Hijack Detection Automation Script
```python
#!/usr/bin/env python3
"""
Tenant Hijack Auto-Detection Script
Run this as a scheduled Lambda or cron job
"""

import boto3
import subprocess

def check_dns_integrity(tenant_id, expected_target):
    """Check if DNS points to expected target"""
    result = subprocess.run(
        ['dig', '+short', f'{tenant_id}.wpsit.kimmyai.io'],
        capture_output=True, text=True
    )
    actual = result.stdout.strip()
    if actual != expected_target:
        return {'status': 'ALERT', 'expected': expected_target, 'actual': actual}
    return {'status': 'OK'}

def check_admin_count(tenant_id, expected_count):
    """Check if admin user count matches expected"""
    # Execute via ECS task or RDS proxy
    # Compare count with expected
    pass

def check_file_integrity(tenant_id, expected_hash):
    """Check WordPress core file integrity"""
    # Compare wp-includes checksums
    pass

def main():
    tenants = ['tenant-1', 'tenant-2', 'tenant-3']

    for tenant in tenants:
        # DNS check
        dns_result = check_dns_integrity(tenant, 'dxxxxxxxxx.cloudfront.net')
        if dns_result['status'] == 'ALERT':
            send_alert(f"DNS Hijack: {tenant}", dns_result)

        # Add more checks...

if __name__ == '__main__':
    main()
```

### Hijack Prevention Checklist
- [ ] Enable CloudTrail for all API calls
- [ ] Enable VPC Flow Logs
- [ ] Configure IAM policies with least privilege
- [ ] Enable MFA for all admin accounts
- [ ] Implement credential rotation schedule
- [ ] Configure WAF rules on CloudFront
- [ ] Enable Route53 DNSSEC (if supported)
- [ ] Monitor DNS changes in real-time
- [ ] Implement file integrity monitoring
- [ ] Regular security audits

---

## Submodule TA-08: Multi-Environment Tenant Promotion

**Duration**: 1.5 hours
**Status**: PENDING

### Learning Objectives
- Promote tenant from DEV to SIT
- Promote tenant from SIT to PROD
- Validate promoted tenant
- Handle promotion rollbacks

### Practical Exercises

#### Exercise TA-08-1: Export Tenant from DEV
```bash
# Step 1: Export database
AWS_PROFILE=Tebogo-dev aws ecs run-task \
  --cluster dev-cluster \
  --task-definition dev-db-backup \
  --overrides '{
    "containerOverrides": [{
      "name": "db-backup",
      "environment": [
        {"name": "DB_NAME", "value": "tenant_1_db"},
        {"name": "S3_BUCKET", "value": "bbws-promotion-staging"},
        {"name": "BACKUP_PREFIX", "value": "tenant-1-dev-to-sit"}
      ]
    }]
  }' \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx]}" \
  --region eu-west-1

# Step 2: Export EFS files
# (Use DataSync or S3 sync)

# Step 3: Export configuration
AWS_PROFILE=Tebogo-dev aws secretsmanager get-secret-value \
  --secret-id dev-tenant-1-config \
  --query 'SecretString' \
  --region eu-west-1 > tenant-1-config.json
```

#### Exercise TA-08-2: Import Tenant to SIT
```bash
# Step 1: Create tenant infrastructure in SIT
# (Use Tenant Manager provisioning)

# Step 2: Import database
AWS_PROFILE=Tebogo-sit aws ecs run-task \
  --cluster sit-cluster \
  --task-definition sit-db-restore \
  --overrides '{
    "containerOverrides": [{
      "name": "db-restore",
      "environment": [
        {"name": "DB_NAME", "value": "tenant_1_db"},
        {"name": "S3_BACKUP_PATH", "value": "s3://bbws-promotion-staging/tenant-1-dev-to-sit.sql.gz"}
      ]
    }]
  }' \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx]}" \
  --region eu-west-1

# Step 3: Update URLs in database
# Search-replace DEV URLs with SIT URLs
# wpdev.kimmyai.io -> wpsit.kimmyai.io

# Step 4: Sync EFS files
# Step 5: Update configuration
```

#### Exercise TA-08-3: Validate Promoted Tenant
```bash
# Verify service is running
AWS_PROFILE=Tebogo-sit aws ecs describe-services \
  --cluster sit-cluster \
  --services tenant-1-service \
  --query 'services[0].runningCount' \
  --region eu-west-1

# Verify DNS
dig tenant-1.wpsit.kimmyai.io

# Verify site loads
curl -I https://tenant-1.wpsit.kimmyai.io/

# Verify WordPress admin
curl -I https://tenant-1.wpsit.kimmyai.io/wp-admin/
```

---

## Completion Criteria

To complete the Tenant Admin training module:

1. Complete all 8 submodules (TA-01 to TA-08)
2. Submit screenshots for each exercise
3. Pass the Tenant Admin Knowledge Check Quiz (80%+)
4. Successfully complete CRUD operations on 3+ tenants
5. Successfully suspend and resume a tenant
6. Successfully execute hijack detection script

---

## Next Steps

After completing Tenant Admin training:
1. Take the [Tenant Admin Quiz](../tenant_admin/quiz_tenant_admin.md)
2. Practice incident response procedures
3. Shadow PROD tenant operations
4. Consider Content Manager training for full stack knowledge

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-16 | Initial Tenant Admin training plan |
