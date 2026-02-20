# Phase 3: DEV Environment Provisioning

**Phase**: 3 of 10
**Duration**: 0.5 days (4 hours) | **Actual**: 29 minutes
**Responsible**: Technical Lead
**Environment**: DEV
**Dependencies**: Phase 2 (Xneelo Export) Complete
**Status**: ✅ COMPLETE
**Completion Date**: 2026-01-09

---

## Phase Objectives

- Provision new tenant 'aupairhive' in DEV environment
- Create isolated MySQL database: tenant_aupairhive_db
- Deploy ECS Fargate service with WordPress container
- Create EFS access point for tenant files
- Configure ALB target group and host-based routing
- Create Route53 DNS record: aupairhive.wpdev.kimmyai.io
- Verify infrastructure health (all components operational)

---

## Prerequisites

- [ ] Phase 1 complete (Environment validation passed)
- [ ] Phase 2 complete (Backup package ready)
- [ ] AWS CLI configured for DEV environment (Tebogo-dev profile)
- [ ] Terraform initialized for DEV workspace
- [ ] Tenant Manager Agent documentation reviewed
- [ ] Migration scripts available in training/

---

## Detailed Tasks

### Task 3.1: Generate Unique Tenant ID

**Duration**: 10 minutes
**Responsible**: Technical Lead

**Steps**:

1. **Choose tenant ID format**:
   - Recommended: Use simple identifier "aupairhive" (lowercase, no spaces)
   - Alternative: 12-digit numeric ID (enterprise style)

2. **Verify uniqueness** (check no conflicts):
```bash
export AWS_PROFILE=Tebogo-dev
export AWS_REGION=eu-west-1

# Check if tenant already exists
aws ecs list-services --cluster dev-cluster | grep aupairhive

# Check if database exists
aws rds describe-db-instances --query 'DBInstances[*].DBInstanceIdentifier' | grep aupairhive
```

3. **Document tenant ID**:
```
Tenant Information
---
Tenant ID: aupairhive
Tenant Name: Au Pair Hive
Organization: Au Pair Hive
Primary Contact: [business owner email]
Environment: DEV
```

**Verification**:
- [ ] Tenant ID chosen and documented
- [ ] Verified no conflicts with existing tenants

---

### Task 3.2: Provision Tenant Database

**Duration**: 30 minutes
**Responsible**: Database Administrator + Technical Lead

**Steps**:

1. **Get RDS endpoint**:
```bash
export AWS_PROFILE=Tebogo-dev

RDS_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier bbws-dev-mysql \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

echo "RDS Endpoint: $RDS_ENDPOINT"
```

2. **Get master credentials from Secrets Manager**:
```bash
aws secretsmanager get-secret-value \
    --secret-id bbws/dev/rds/master \
    --query SecretString \
    --output text | jq -r '.password'
```

3. **Create tenant database and user**:
```bash
# Connect to RDS (via ECS task or bastion host in VPC)
mysql -h $RDS_ENDPOINT -u admin -p <<EOSQL
-- Create database
CREATE DATABASE IF NOT EXISTS tenant_aupairhive_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Create user with secure random password
CREATE USER IF NOT EXISTS 'tenant_aupairhive_user'@'%' 
    IDENTIFIED BY '$(openssl rand -base64 16)';

-- Grant privileges ONLY to tenant database
GRANT ALL PRIVILEGES ON tenant_aupairhive_db.* 
    TO 'tenant_aupairhive_user'@'%';

-- Flush privileges
FLUSH PRIVILEGES;

-- Verify grants
SHOW GRANTS FOR 'tenant_aupairhive_user'@'%';
EOSQL
```

4. **Store credentials in Secrets Manager**:
```bash
# Create secret with tenant database credentials
aws secretsmanager create-secret \
    --name bbws/dev/aupairhive/database \
    --description "Au Pair Hive tenant database credentials (DEV)" \
    --secret-string "{
        \"host\": \"$RDS_ENDPOINT\",
        \"port\": \"3306\",
        \"username\": \"tenant_aupairhive_user\",
        \"password\": \"<generated_password>\",
        \"dbname\": \"tenant_aupairhive_db\"
    }"
```

5. **Test database connection**:
```bash
# Retrieve credentials and test
mysql -h $RDS_ENDPOINT -u tenant_aupairhive_user -p tenant_aupairhive_db -e "SELECT 1;"
```

**Troubleshooting**:
- **Issue**: User already exists
  - **Solution**: Drop and recreate user, or use different username

- **Issue**: Cannot connect to RDS
  - **Solution**: Check security groups allow connection from your location/VPC

**Verification**:
- [ ] Database `tenant_aupairhive_db` created
- [ ] User `tenant_aupairhive_user` created with limited privileges
- [ ] Credentials stored in Secrets Manager
- [ ] Database connection test passed

---

### Task 3.3: Create EFS Access Point

**Duration**: 20 minutes
**Responsible**: DevOps Engineer

**Steps**:

1. **Get EFS file system ID**:
```bash
export AWS_PROFILE=Tebogo-dev

EFS_ID=$(aws efs describe-file-systems \
    --query 'FileSystems[0].FileSystemId' \
    --output text)

echo "EFS ID: $EFS_ID"
```

2. **Create EFS access point**:
```bash
aws efs create-access-point \
    --file-system-id $EFS_ID \
    --posix-user Uid=1001,Gid=1001 \
    --root-directory "Path=/tenant-aupairhive,CreationInfo={OwnerUid=1001,OwnerGid=1001,Permissions=755}" \
    --tags Key=Name,Value=aupairhive-dev Key=Environment,Value=dev
```

3. **Get access point ID**:
```bash
ACCESS_POINT_ID=$(aws efs describe-access-points \
    --file-system-id $EFS_ID \
    --query "AccessPoints[?RootDirectory.Path=='/tenant-aupairhive'].AccessPointId" \
    --output text)

echo "Access Point ID: $ACCESS_POINT_ID"
```

4. **Verify access point**:
```bash
aws efs describe-access-points --access-point-id $ACCESS_POINT_ID
```

**Verification**:
- [ ] EFS access point created
- [ ] Path: /tenant-aupairhive
- [ ] POSIX UID/GID: 1001/1001
- [ ] Access point ID documented

---

### Task 3.4: Create ECS Task Definition

**Duration**: 45 minutes
**Responsible**: Technical Lead

**Steps**:

1. **Create task definition JSON**:
```json
{
  "family": "aupairhive-dev-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::536580886816:role/ecsTaskExecutionRole",
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
        {
          "name": "WORDPRESS_DB_HOST",
          "value": "${RDS_ENDPOINT}"
        },
        {
          "name": "WORDPRESS_DB_NAME",
          "value": "tenant_aupairhive_db"
        }
      ],
      "secrets": [
        {
          "name": "WORDPRESS_DB_USER",
          "valueFrom": "bbws/dev/aupairhive/database:username::"
        },
        {
          "name": "WORDPRESS_DB_PASSWORD",
          "valueFrom": "bbws/dev/aupairhive/database:password::"
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
          "awslogs-group": "/ecs/dev/aupairhive",
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
        "fileSystemId": "${EFS_ID}",
        "transitEncryption": "ENABLED",
        "authorizationConfig": {
          "accessPointId": "${ACCESS_POINT_ID}"
        }
      }
    }
  ]
}
```

2. **Register task definition**:
```bash
aws ecs register-task-definition --cli-input-json file://aupairhive-task-def.json
```

3. **Get task definition ARN**:
```bash
TASK_DEF_ARN=$(aws ecs describe-task-definition \
    --task-definition aupairhive-dev-task \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)
```

**Verification**:
- [ ] Task definition registered
- [ ] Database credentials from Secrets Manager
- [ ] EFS volume mounted correctly
- [ ] CloudWatch logging configured

---

### Task 3.5: Create ALB Target Group

**Duration**: 20 minutes
**Responsible**: DevOps Engineer

**Steps**:

1. **Get VPC ID**:
```bash
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=bbws-dev-vpc" --query 'Vpcs[0].VpcId' --output text)
```

2. **Create target group**:
```bash
aws elbv2 create-target-group \
    --name aupairhive-dev-tg \
    --protocol HTTP \
    --port 80 \
    --vpc-id $VPC_ID \
    --target-type ip \
    --health-check-path / \
    --health-check-interval-seconds 30 \
    --health-check-timeout-seconds 5 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 3 \
    --tags Key=Name,Value=aupairhive-dev Key=Environment,Value=dev
```

3. **Get target group ARN**:
```bash
TG_ARN=$(aws elbv2 describe-target-groups \
    --names aupairhive-dev-tg \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)
```

**Verification**:
- [ ] Target group created
- [ ] Health check configured (path: /, interval: 30s)
- [ ] Target group ARN documented

---

### Task 3.6: Deploy ECS Service

**Duration**: 30 minutes
**Responsible**: Technical Lead

**Steps**:

1. **Get subnet IDs**:
```bash
SUBNET_IDS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Tier,Values=private" \
    --query 'Subnets[*].SubnetId' \
    --output text | tr '\t' ',')
```

2. **Get security group ID**:
```bash
SG_ID=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=ecs-tasks-sg" \
    --query 'SecurityGroups[0].GroupId' \
    --output text)
```

3. **Create ECS service**:
```bash
aws ecs create-service \
    --cluster dev-cluster \
    --service-name aupairhive-dev-service \
    --task-definition $TASK_DEF_ARN \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_IDS],securityGroups=[$SG_ID],assignPublicIp=DISABLED}" \
    --load-balancers "targetGroupArn=$TG_ARN,containerName=wordpress,containerPort=80" \
    --tags key=Name,value=aupairhive-dev key=Environment,value=dev
```

4. **Wait for service to stabilize**:
```bash
aws ecs wait services-stable --cluster dev-cluster --services aupairhive-dev-service
```

5. **Verify tasks running**:
```bash
aws ecs describe-services \
    --cluster dev-cluster \
    --services aupairhive-dev-service \
    --query 'services[0].[runningCount,desiredCount]'
```

**Verification**:
- [ ] ECS service created
- [ ] Desired count: 1, Running count: 1
- [ ] Tasks registered with target group
- [ ] Service stable (no restart loops)

---

### Task 3.7: Configure ALB Listener Rule

**Duration**: 15 minutes
**Responsible**: DevOps Engineer

**Steps**:

1. **Get ALB listener ARN**:
```bash
ALB_ARN=$(aws elbv2 describe-load-balancers \
    --names dev-alb \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text)

LISTENER_ARN=$(aws elbv2 describe-listeners \
    --load-balancer-arn $ALB_ARN \
    --query 'Listeners[?Port==`80`].ListenerArn' \
    --output text)
```

2. **Create listener rule** (host-based routing):
```bash
aws elbv2 create-rule \
    --listener-arn $LISTENER_ARN \
    --priority 10 \
    --conditions Field=host-header,Values=aupairhive.wpdev.kimmyai.io \
    --actions Type=forward,TargetGroupArn=$TG_ARN
```

3. **Verify rule created**:
```bash
aws elbv2 describe-rules --listener-arn $LISTENER_ARN
```

**Verification**:
- [ ] Listener rule created
- [ ] Host header: aupairhive.wpdev.kimmyai.io
- [ ] Forwards to aupairhive-dev-tg
- [ ] Rule priority set correctly

---

### Task 3.8: Create Route53 DNS Record

**Duration**: 15 minutes
**Responsible**: DevOps Engineer

**Steps**:

1. **Get Route53 hosted zone ID**:
```bash
ZONE_ID=$(aws route53 list-hosted-zones \
    --query 'HostedZones[?Name==`wpdev.kimmyai.io.`].Id' \
    --output text | cut -d'/' -f3)
```

2. **Get CloudFront or ALB DNS name**:
```bash
# If using CloudFront
CF_DOMAIN=$(aws cloudfront list-distributions \
    --query 'DistributionList.Items[?Aliases.Items[?contains(@, `wpdev`)]].DomainName' \
    --output text)

# Or use ALB directly
ALB_DNS=$(aws elbv2 describe-load-balancers \
    --names dev-alb \
    --query 'LoadBalancers[0].DNSName' \
    --output text)
```

3. **Create DNS record**:
```bash
cat > change-batch.json <<EOF
{
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "aupairhive.wpdev.kimmyai.io",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "${CF_DOMAIN:-$ALB_DNS}",
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}
EOF

aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch file://change-batch.json
```

4. **Verify DNS propagation**:
```bash
dig aupairhive.wpdev.kimmyai.io
# Or
nslookup aupairhive.wpdev.kimmyai.io
```

**Verification**:
- [ ] DNS record created
- [ ] Record type: A (ALIAS to CloudFront/ALB)
- [ ] DNS resolves correctly
- [ ] TTL appropriate (300s for dev)

---

### Task 3.9: Verify Infrastructure Health

**Duration**: 20 minutes
**Responsible**: Technical Lead

**Steps**:

1. **Check ECS service health**:
```bash
aws ecs describe-services \
    --cluster dev-cluster \
    --services aupairhive-dev-service \
    --query 'services[0].[serviceName,status,runningCount,desiredCount]'
```

2. **Check target health**:
```bash
aws elbv2 describe-target-health \
    --target-group-arn $TG_ARN
```

**Expected**: TargetHealth.State = "healthy"

3. **Check container logs**:
```bash
# Get task ARN
TASK_ARN=$(aws ecs list-tasks \
    --cluster dev-cluster \
    --service-name aupairhive-dev-service \
    --query 'taskArns[0]' \
    --output text)

# View logs
aws logs tail /ecs/dev/aupairhive --follow
```

4. **Test HTTP access**:
```bash
# Test via DNS
curl -I https://aupairhive.wpdev.kimmyai.io

# Expected: HTTP redirect or WordPress install page
```

5. **Verify database connectivity** (from container):
```bash
# Execute command in running container
aws ecs execute-command \
    --cluster dev-cluster \
    --task $TASK_ARN \
    --container wordpress \
    --interactive \
    --command "/bin/bash"

# Inside container:
mysql -h $WORDPRESS_DB_HOST -u $WORDPRESS_DB_USER -p$WORDPRESS_DB_PASSWORD -e "SELECT 1;"
```

**Verification**:
- [ ] ECS service status: ACTIVE
- [ ] Running tasks: 1/1
- [ ] Target health: healthy
- [ ] Container logs show no errors
- [ ] HTTP request returns response
- [ ] Database connection works

---

## Verification Checklist

### Infrastructure Components
- [ ] Tenant database created: tenant_aupairhive_db
- [ ] Database user created with limited privileges
- [ ] Credentials stored in Secrets Manager
- [ ] EFS access point created: /tenant-aupairhive
- [ ] ECS task definition registered
- [ ] ECS service deployed and running (1/1 tasks)
- [ ] ALB target group created
- [ ] Target health: healthy
- [ ] ALB listener rule configured (host-based routing)
- [ ] Route53 DNS record created: aupairhive.wpdev.kimmyai.io
- [ ] CloudWatch log group created: /ecs/dev/aupairhive

### Health Checks
- [ ] ECS service stable (no restart loops)
- [ ] Container logs show WordPress starting
- [ ] Database connection from container works
- [ ] EFS mounted successfully
- [ ] ALB health checks passing
- [ ] DNS resolves correctly
- [ ] HTTP request succeeds (200 or redirect)

### Documentation
- [ ] Tenant ID documented
- [ ] Infrastructure ARNs documented
- [ ] Tenant URL documented: https://aupairhive.wpdev.kimmyai.io

---

## Rollback Procedure

If provisioning fails:

1. **Delete ECS service**:
```bash
aws ecs update-service --cluster dev-cluster --service aupairhive-dev-service --desired-count 0
aws ecs delete-service --cluster dev-cluster --service aupairhive-dev-service
```

2. **Delete ALB resources**:
```bash
aws elbv2 delete-rule --rule-arn <rule-arn>
aws elbv2 delete-target-group --target-group-arn $TG_ARN
```

3. **Delete DNS record**:
```bash
# Change "CREATE" to "DELETE" in change-batch.json
aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch file://change-batch.json
```

4. **Delete EFS access point**:
```bash
aws efs delete-access-point --access-point-id $ACCESS_POINT_ID
```

5. **Drop database**:
```bash
mysql -h $RDS_ENDPOINT -u admin -p <<EOSQL
DROP USER 'tenant_aupairhive_user'@'%';
DROP DATABASE tenant_aupairhive_db;
EOSQL
```

6. **Delete secret**:
```bash
aws secretsmanager delete-secret --secret-id bbws/dev/aupairhive/database --force-delete-without-recovery
```

---

## Success Criteria

- [ ] Empty WordPress tenant accessible via https://aupairhive.wpdev.kimmyai.io
- [ ] WordPress installation screen displays (or redirect to wp-admin/install.php)
- [ ] All infrastructure components healthy
- [ ] Database connection verified
- [ ] EFS mount verified
- [ ] ALB routing correct (host header matches)
- [ ] DNS resolves correctly
- [ ] Container logs show no critical errors
- [ ] Ready for data import (Phase 4)

**Definition of Done**:
Tenant infrastructure fully provisioned in DEV environment, all health checks passing, and WordPress installation page accessible.

---

## Sign-Off

**Completed By**: _________________ Date: _________
**Verified By**: _________________ Date: _________
**Tenant URL**: https://aupairhive.wpdev.kimmyai.io
**Infrastructure Health**: ✅ All Green
**Ready for Phase 4**: [ ] YES [ ] NO

---

## Notes

[Document any issues encountered or deviations from plan]

---

**Next Phase**: Proceed to **Phase 4**: `04_Data_Import_and_Configuration_DEV.md`


---

## Phase 3 Completion

✅ **COMPLETE** - 2026-01-09

All infrastructure components provisioned successfully in 29 minutes:

- ✅ Database credentials stored in Secrets Manager
- ✅ EFS access point created (fsap-06a27a3eb66e029cf)
- ✅ ECS task definition registered (dev-aupairhive:1)
- ✅ ALB target group created and healthy
- ✅ ALB listener rule configured (priority 150)
- ✅ ECS service deployed and running (1/1 tasks)
- ✅ Route53 DNS record created and synced
- ✅ IAM permissions configured
- ✅ HTTP 200 response verified

**Infrastructure Access**:
- URL: http://aupairhive.wpdev.kimmyai.io/
- ECS Service: dev-aupairhive-service
- Task IP: 10.1.10.142

**Issues Resolved**:
1. RDS private subnet access - will use wp-cli for database operations
2. Secrets Manager permissions - IAM policy added for task execution role

**Next Phase**: Phase 4 - Data Import & Configuration DEV

See detailed completion report: `PHASE3_COMPLETION_SUMMARY.md`

