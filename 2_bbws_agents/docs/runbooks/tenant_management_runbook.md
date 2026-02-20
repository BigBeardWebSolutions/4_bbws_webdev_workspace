# Tenant Management Runbook

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-16 | Platform Team | Initial version |

---

## Prerequisites

### AWS CLI Configuration

Ensure AWS SSO is configured for all environments:

```bash
# Verify profiles are configured
cat ~/.aws/config | grep -A 5 "profile Tebogo"

# Login to each environment
aws sso login --profile Tebogo-dev
aws sso login --profile Tebogo-sit
aws sso login --profile Tebogo-prod

# Verify access
aws --profile Tebogo-dev sts get-caller-identity   # Expected: 536580886816
aws --profile Tebogo-sit sts get-caller-identity   # Expected: 815856636111
aws --profile Tebogo-prod sts get-caller-identity  # Expected: 093646564004
```

### Environment Variables

```bash
# Set environment (dev, sit, or prod)
export ENV=dev
export AWS_PROFILE=Tebogo-${ENV}
export AWS_REGION=eu-west-1  # af-south-1 for PROD
```

---

## 1. CREATE - Tenant Provisioning

### 1.1 Generate Tenant ID

```bash
# Generate a unique 12-digit tenant ID
TENANT_ID=$(date +%s%N | cut -c1-12)
echo "Tenant ID: $TENANT_ID"
```

### 1.2 Create Database and User

```bash
# Get RDS master credentials
MASTER_CREDS=$(aws --profile $AWS_PROFILE secretsmanager get-secret-value \
  --secret-id "${ENV}-rds-master-credentials" \
  --region $AWS_REGION \
  --query 'SecretString' --output text)

RDS_HOST=$(echo $MASTER_CREDS | jq -r '.host' | cut -d: -f1)
RDS_USER=$(echo $MASTER_CREDS | jq -r '.username')
RDS_PASS=$(echo $MASTER_CREDS | jq -r '.password')

# Create database and user (via bastion or ECS task)
mysql -h $RDS_HOST -u $RDS_USER -p$RDS_PASS <<EOF
CREATE DATABASE IF NOT EXISTS ${TENANT_ID}_db;
CREATE USER IF NOT EXISTS '${TENANT_ID}_user'@'%' IDENTIFIED BY '$(openssl rand -base64 24)';
GRANT ALL PRIVILEGES ON ${TENANT_ID}_db.* TO '${TENANT_ID}_user'@'%';
FLUSH PRIVILEGES;
EOF
```

### 1.3 Create Secrets Manager Secret

```bash
# Generate secure password
DB_PASSWORD=$(openssl rand -base64 24)

# Create secret
aws --profile $AWS_PROFILE secretsmanager create-secret \
  --name "${ENV}-${TENANT_ID}-db-credentials" \
  --secret-string "{\"username\":\"${TENANT_ID}_user\",\"password\":\"$DB_PASSWORD\",\"host\":\"$RDS_HOST\",\"port\":3306,\"database\":\"${TENANT_ID}_db\"}" \
  --region $AWS_REGION
```

### 1.4 Create EFS Access Point

```bash
# Get EFS ID
EFS_ID=$(aws --profile $AWS_PROFILE efs describe-file-systems \
  --region $AWS_REGION \
  --query "FileSystems[?contains(Name, '${ENV}')].FileSystemId" \
  --output text | head -1)

# Create access point
aws --profile $AWS_PROFILE efs create-access-point \
  --file-system-id $EFS_ID \
  --posix-user "Uid=33,Gid=33" \
  --root-directory "Path=/wordpress/${TENANT_ID},CreationInfo={OwnerUid=33,OwnerGid=33,Permissions=755}" \
  --tags "Key=Name,Value=${ENV}-${TENANT_ID}-ap" \
  --region $AWS_REGION
```

### 1.5 Register Task Definition

```bash
# Create task definition JSON
cat > /tmp/task-def.json <<EOF
{
  "family": "${ENV}-${TENANT_ID}",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::$(aws --profile $AWS_PROFILE sts get-caller-identity --query 'Account' --output text):role/${ENV}-ecs-task-execution-role",
  "taskRoleArn": "arn:aws:iam::$(aws --profile $AWS_PROFILE sts get-caller-identity --query 'Account' --output text):role/${ENV}-ecs-task-role",
  "containerDefinitions": [
    {
      "name": "wordpress",
      "image": "your-ecr-repo/wordpress:latest",
      "essential": true,
      "portMappings": [{"containerPort": 80, "protocol": "tcp"}],
      "secrets": [
        {"name": "DB_CREDENTIALS", "valueFrom": "arn:aws:secretsmanager:${AWS_REGION}:$(aws --profile $AWS_PROFILE sts get-caller-identity --query 'Account' --output text):secret:${ENV}-${TENANT_ID}-db-credentials"}
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/${ENV}-${TENANT_ID}",
          "awslogs-region": "${AWS_REGION}",
          "awslogs-stream-prefix": "wordpress"
        }
      }
    }
  ]
}
EOF

# Register task definition
aws --profile $AWS_PROFILE ecs register-task-definition \
  --cli-input-json file:///tmp/task-def.json \
  --region $AWS_REGION
```

### 1.6 Create ALB Target Group

```bash
# Get VPC ID
VPC_ID=$(aws --profile $AWS_PROFILE ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=*${ENV}*" \
  --query 'Vpcs[0].VpcId' --output text \
  --region $AWS_REGION)

# Create target group
aws --profile $AWS_PROFILE elbv2 create-target-group \
  --name "${ENV}-${TENANT_ID}-tg" \
  --protocol HTTP \
  --port 80 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --health-check-path "/wp-admin/install.php" \
  --health-check-interval-seconds 30 \
  --region $AWS_REGION
```

### 1.7 Create ALB Listener Rule

```bash
# Get listener ARN
LISTENER_ARN=$(aws --profile $AWS_PROFILE elbv2 describe-listeners \
  --load-balancer-arn $(aws --profile $AWS_PROFILE elbv2 describe-load-balancers \
    --query "LoadBalancers[?contains(LoadBalancerName, '${ENV}')].LoadBalancerArn" \
    --output text --region $AWS_REGION) \
  --query "Listeners[?Port==\`443\` || Port==\`80\`].ListenerArn" \
  --output text --region $AWS_REGION | head -1)

# Get target group ARN
TG_ARN=$(aws --profile $AWS_PROFILE elbv2 describe-target-groups \
  --names "${ENV}-${TENANT_ID}-tg" \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text --region $AWS_REGION)

# Create listener rule
aws --profile $AWS_PROFILE elbv2 create-rule \
  --listener-arn $LISTENER_ARN \
  --conditions "Field=host-header,Values=${TENANT_ID}.${DOMAIN}" \
  --actions "Type=forward,TargetGroupArn=$TG_ARN" \
  --priority $(shuf -i 1-50000 -n 1) \
  --region $AWS_REGION
```

### 1.8 Create ECS Service

```bash
# Get cluster name, subnets, and security group
CLUSTER="${ENV}-cluster"
SUBNETS=$(aws --profile $AWS_PROFILE ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=*private*" \
  --query 'Subnets[*].SubnetId' --output text --region $AWS_REGION | tr '\t' ',')
SG=$(aws --profile $AWS_PROFILE ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=*ecs*" \
  --query 'SecurityGroups[0].GroupId' --output text --region $AWS_REGION)

# Create service
aws --profile $AWS_PROFILE ecs create-service \
  --cluster $CLUSTER \
  --service-name "${ENV}-${TENANT_ID}-service" \
  --task-definition "${ENV}-${TENANT_ID}" \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SG],assignPublicIp=DISABLED}" \
  --load-balancers "targetGroupArn=$TG_ARN,containerName=wordpress,containerPort=80" \
  --region $AWS_REGION
```

---

## 2. READ - Tenant Querying

### 2.1 List All Tenants

```bash
# List all ECS services (tenants)
aws --profile $AWS_PROFILE ecs list-services \
  --cluster ${ENV}-cluster \
  --query 'serviceArns[*]' \
  --output text --region $AWS_REGION | tr '\t' '\n' | xargs -I {} basename {}
```

### 2.2 Get Tenant Details

```bash
TENANT_ID="your-tenant-id"

# Get ECS service details
aws --profile $AWS_PROFILE ecs describe-services \
  --cluster ${ENV}-cluster \
  --services "${ENV}-${TENANT_ID}-service" \
  --region $AWS_REGION

# Get target group health
TG_ARN=$(aws --profile $AWS_PROFILE elbv2 describe-target-groups \
  --names "${ENV}-${TENANT_ID}-tg" \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text --region $AWS_REGION)

aws --profile $AWS_PROFILE elbv2 describe-target-health \
  --target-group-arn $TG_ARN \
  --region $AWS_REGION
```

### 2.3 View Tenant Logs

```bash
# Get recent logs
aws --profile $AWS_PROFILE logs tail "/ecs/${ENV}-${TENANT_ID}" \
  --since 1h \
  --region $AWS_REGION
```

### 2.4 Check Tenant Resources Across Environments

```bash
TENANT_ID="your-tenant-id"

echo "=== Checking tenant: $TENANT_ID ==="

for profile in Tebogo-dev Tebogo-sit Tebogo-prod; do
  ENV_NAME=$(echo $profile | cut -d- -f2)
  REGION="eu-west-1"
  [[ "$profile" == "Tebogo-prod" ]] && REGION="af-south-1"

  echo -e "\n--- $ENV_NAME ($profile) ---"

  # Check ECS service
  aws --profile $profile ecs describe-services \
    --cluster ${ENV_NAME}-cluster \
    --services "${ENV_NAME}-${TENANT_ID}-service" \
    --query 'services[0].status' \
    --output text --region $REGION 2>/dev/null || echo "Service not found"
done
```

---

## 3. UPDATE - Tenant Modification

### 3.1 Scale Tenant Resources

```bash
TENANT_ID="your-tenant-id"
NEW_CPU="512"
NEW_MEMORY="1024"
DESIRED_COUNT="2"

# Update task definition with new resources
# (Create new revision with updated CPU/memory)

# Update service desired count
aws --profile $AWS_PROFILE ecs update-service \
  --cluster ${ENV}-cluster \
  --service "${ENV}-${TENANT_ID}-service" \
  --desired-count $DESIRED_COUNT \
  --region $AWS_REGION
```

### 3.2 Update Container Image

```bash
TENANT_ID="your-tenant-id"
NEW_IMAGE="your-ecr-repo/wordpress:new-version"

# Get current task definition
TASK_DEF=$(aws --profile $AWS_PROFILE ecs describe-task-definition \
  --task-definition "${ENV}-${TENANT_ID}" \
  --region $AWS_REGION)

# Update image and register new revision
# ... (modify JSON and register)

# Update service to use new task definition
aws --profile $AWS_PROFILE ecs update-service \
  --cluster ${ENV}-cluster \
  --service "${ENV}-${TENANT_ID}-service" \
  --task-definition "${ENV}-${TENANT_ID}" \
  --region $AWS_REGION
```

### 3.3 Force New Deployment

```bash
TENANT_ID="your-tenant-id"

aws --profile $AWS_PROFILE ecs update-service \
  --cluster ${ENV}-cluster \
  --service "${ENV}-${TENANT_ID}-service" \
  --force-new-deployment \
  --region $AWS_REGION
```

---

## 4. DELETE - Tenant Deprovisioning

### 4.1 Pre-Deletion Checklist

```bash
TENANT_ID="your-tenant-id"

echo "=== Pre-Deletion Checklist for: $TENANT_ID ==="
echo ""
echo "[ ] Tenant owner notified"
echo "[ ] Data backup completed (if required)"
echo "[ ] Billing finalized"
echo "[ ] Approval obtained (PROD requires typed confirmation)"
echo ""
read -p "Continue with deletion? (yes/no): " CONFIRM
[[ "$CONFIRM" != "yes" ]] && exit 1
```

### 4.2 Delete ECS Service

```bash
TENANT_ID="your-tenant-id"

# Scale down to 0
aws --profile $AWS_PROFILE ecs update-service \
  --cluster ${ENV}-cluster \
  --service "${ENV}-${TENANT_ID}-service" \
  --desired-count 0 \
  --region $AWS_REGION

# Delete service
aws --profile $AWS_PROFILE ecs delete-service \
  --cluster ${ENV}-cluster \
  --service "${ENV}-${TENANT_ID}-service" \
  --force \
  --region $AWS_REGION
```

### 4.3 Delete ALB Resources

```bash
TENANT_ID="your-tenant-id"

# Get listener ARN
LISTENER_ARN=$(aws --profile $AWS_PROFILE elbv2 describe-listeners \
  --load-balancer-arn $(aws --profile $AWS_PROFILE elbv2 describe-load-balancers \
    --query "LoadBalancers[?contains(LoadBalancerName, '${ENV}')].LoadBalancerArn" \
    --output text --region $AWS_REGION) \
  --query "Listeners[?Port==\`443\` || Port==\`80\`].ListenerArn" \
  --output text --region $AWS_REGION | head -1)

# Find and delete listener rule
RULE_ARN=$(aws --profile $AWS_PROFILE elbv2 describe-rules \
  --listener-arn $LISTENER_ARN \
  --query "Rules[?Conditions[0].Values[0]=='${TENANT_ID}.${DOMAIN}'].RuleArn" \
  --output text --region $AWS_REGION)

aws --profile $AWS_PROFILE elbv2 delete-rule \
  --rule-arn $RULE_ARN \
  --region $AWS_REGION

# Delete target group
TG_ARN=$(aws --profile $AWS_PROFILE elbv2 describe-target-groups \
  --names "${ENV}-${TENANT_ID}-tg" \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text --region $AWS_REGION)

aws --profile $AWS_PROFILE elbv2 delete-target-group \
  --target-group-arn $TG_ARN \
  --region $AWS_REGION
```

### 4.4 Delete Secrets Manager Secret

```bash
TENANT_ID="your-tenant-id"

aws --profile $AWS_PROFILE secretsmanager delete-secret \
  --secret-id "${ENV}-${TENANT_ID}-db-credentials" \
  --force-delete-without-recovery \
  --region $AWS_REGION
```

### 4.5 Deregister Task Definition

```bash
TENANT_ID="your-tenant-id"

# Get latest task definition ARN
TASK_DEF_ARN=$(aws --profile $AWS_PROFILE ecs list-task-definitions \
  --family-prefix "${ENV}-${TENANT_ID}" \
  --query 'taskDefinitionArns[-1]' \
  --output text --region $AWS_REGION)

# Deregister
aws --profile $AWS_PROFILE ecs deregister-task-definition \
  --task-definition $TASK_DEF_ARN \
  --region $AWS_REGION
```

### 4.6 Delete EFS Access Point

```bash
TENANT_ID="your-tenant-id"

# Get EFS ID
EFS_ID=$(aws --profile $AWS_PROFILE efs describe-file-systems \
  --region $AWS_REGION \
  --query "FileSystems[?contains(Name, '${ENV}')].FileSystemId" \
  --output text | head -1)

# Find and delete access points
aws --profile $AWS_PROFILE efs describe-access-points \
  --file-system-id $EFS_ID \
  --region $AWS_REGION \
  --query "AccessPoints[?contains(Name, '${TENANT_ID}')].[AccessPointId,Name]" \
  --output text | while read AP_ID AP_NAME; do
    echo "Deleting: $AP_ID ($AP_NAME)"
    aws --profile $AWS_PROFILE efs delete-access-point \
      --access-point-id $AP_ID \
      --region $AWS_REGION
done
```

### 4.7 Delete Database and User

```bash
TENANT_ID="your-tenant-id"

# Get RDS master credentials
MASTER_CREDS=$(aws --profile $AWS_PROFILE secretsmanager get-secret-value \
  --secret-id "${ENV}-rds-master-credentials" \
  --region $AWS_REGION \
  --query 'SecretString' --output text)

RDS_HOST=$(echo $MASTER_CREDS | jq -r '.host' | cut -d: -f1)
RDS_USER=$(echo $MASTER_CREDS | jq -r '.username')
RDS_PASS=$(echo $MASTER_CREDS | jq -r '.password')

# Drop database and user (via bastion or ECS task)
mysql -h $RDS_HOST -u $RDS_USER -p$RDS_PASS <<EOF
DROP DATABASE IF EXISTS ${TENANT_ID}_db;
DROP USER IF EXISTS '${TENANT_ID}_user'@'%';
FLUSH PRIVILEGES;
EOF
```

### 4.8 Database Cleanup via ECS Task

For environments without bastion access:

```bash
TENANT_ID="your-tenant-id"

# Run cleanup task
aws --profile $AWS_PROFILE ecs run-task \
  --cluster ${ENV}-cluster \
  --task-definition ${ENV}-generic-db-init:1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SG],assignPublicIp=DISABLED}" \
  --overrides "{
    \"containerOverrides\": [{
      \"name\": \"mysql-client\",
      \"command\": [\"sh\", \"-c\", \"mysql -h $RDS_HOST -u $RDS_USER -p$RDS_PASS -e \\\"DROP DATABASE IF EXISTS ${TENANT_ID}_db; DROP USER IF EXISTS '${TENANT_ID}_user'@'%'; FLUSH PRIVILEGES;\\\"\"]
    }]
  }" \
  --region $AWS_REGION
```

---

## 5. Bulk Operations

### 5.1 Delete Multiple Tenants

```bash
# Define tenants to delete
TENANTS="tenant1 tenant2 tenant3"

for TENANT_ID in $TENANTS; do
  echo "=== Deleting: $TENANT_ID ==="

  # Scale down and delete ECS service
  aws --profile $AWS_PROFILE ecs update-service \
    --cluster ${ENV}-cluster \
    --service "${ENV}-${TENANT_ID}-service" \
    --desired-count 0 \
    --region $AWS_REGION 2>/dev/null

  aws --profile $AWS_PROFILE ecs delete-service \
    --cluster ${ENV}-cluster \
    --service "${ENV}-${TENANT_ID}-service" \
    --force \
    --region $AWS_REGION 2>/dev/null

  # Delete secret
  aws --profile $AWS_PROFILE secretsmanager delete-secret \
    --secret-id "${ENV}-${TENANT_ID}-db-credentials" \
    --force-delete-without-recovery \
    --region $AWS_REGION 2>/dev/null

  echo "Completed: $TENANT_ID"
done
```

### 5.2 Delete Tenant Across All Environments

```bash
TENANT_ID="your-tenant-id"

for PROFILE in Tebogo-dev Tebogo-sit Tebogo-prod; do
  ENV_NAME=$(echo $PROFILE | cut -d- -f2)
  REGION="eu-west-1"
  [[ "$PROFILE" == "Tebogo-prod" ]] && REGION="af-south-1"

  echo "=== Deleting from: $ENV_NAME ==="

  # Delete ECS service
  aws --profile $PROFILE ecs update-service \
    --cluster ${ENV_NAME}-cluster \
    --service "${ENV_NAME}-${TENANT_ID}-service" \
    --desired-count 0 \
    --region $REGION 2>/dev/null

  aws --profile $PROFILE ecs delete-service \
    --cluster ${ENV_NAME}-cluster \
    --service "${ENV_NAME}-${TENANT_ID}-service" \
    --force \
    --region $REGION 2>/dev/null

  # Delete secret
  aws --profile $PROFILE secretsmanager delete-secret \
    --secret-id "${ENV_NAME}-${TENANT_ID}-db-credentials" \
    --force-delete-without-recovery \
    --region $REGION 2>/dev/null

  echo "Completed: $ENV_NAME"
done
```

---

## 6. Verification Commands

### 6.1 Verify Tenant Deletion

```bash
TENANT_ID="your-tenant-id"

echo "=== Verification for: $TENANT_ID ==="

# Check ECS service
echo -n "ECS Service: "
aws --profile $AWS_PROFILE ecs describe-services \
  --cluster ${ENV}-cluster \
  --services "${ENV}-${TENANT_ID}-service" \
  --query 'services[0].status' \
  --output text --region $AWS_REGION 2>/dev/null || echo "Not found (GOOD)"

# Check target group
echo -n "Target Group: "
aws --profile $AWS_PROFILE elbv2 describe-target-groups \
  --names "${ENV}-${TENANT_ID}-tg" \
  --query 'TargetGroups[0].TargetGroupName' \
  --output text --region $AWS_REGION 2>/dev/null || echo "Not found (GOOD)"

# Check secret
echo -n "Secret: "
aws --profile $AWS_PROFILE secretsmanager describe-secret \
  --secret-id "${ENV}-${TENANT_ID}-db-credentials" \
  --query 'Name' \
  --output text --region $AWS_REGION 2>/dev/null || echo "Not found (GOOD)"
```

---

## Related Documents

- [Tenant Management SOP](./tenant_management_sop.md)
- [Tenant Management Playbook](./tenant_management_playbook.md)
