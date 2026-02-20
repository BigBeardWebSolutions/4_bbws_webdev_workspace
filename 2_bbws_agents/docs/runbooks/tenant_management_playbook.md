# Tenant Management Playbook

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-16 | Platform Team | Initial version |

---

## 1. Decision Trees

### 1.1 Tenant Provisioning Decision Tree

```
START: New Tenant Request
    │
    ├─── Is tenant ID unique?
    │    ├─── NO → Generate new tenant ID
    │    └─── YES ↓
    │
    ├─── Is subdomain available?
    │    ├─── NO → Request alternative subdomain
    │    └─── YES ↓
    │
    ├─── Which environment?
    │    ├─── DEV → Proceed (no approval needed)
    │    ├─── SIT → Get Team Lead approval
    │    └─── PROD → Get DevOps Lead + Product Owner approval
    │
    ├─── All approvals obtained?
    │    ├─── NO → Wait for approvals
    │    └─── YES ↓
    │
    └─── Execute provisioning
         ├─── SUCCESS → Notify tenant owner
         └─── FAILURE → See Troubleshooting Section 3.1
```

### 1.2 Tenant Deletion Decision Tree

```
START: Tenant Deletion Request
    │
    ├─── Is tenant in PROD?
    │    ├─── YES → Require typed tenant name confirmation
    │    │         + DevOps Lead approval
    │    └─── NO ↓
    │
    ├─── Is data backup required?
    │    ├─── YES → Execute backup first
    │    └─── NO ↓
    │
    ├─── Has tenant owner been notified?
    │    ├─── NO → Notify and wait 24 hours
    │    └─── YES ↓
    │
    ├─── Delete across all environments?
    │    ├─── YES → Delete DEV → SIT → PROD
    │    └─── NO → Delete specified environment only
    │
    └─── Execute deletion in order:
         1. ECS Service
         2. ALB Listener Rule
         3. ALB Target Group
         4. Secrets Manager
         5. Task Definition
         6. EFS Access Point
         7. Database & User
         8. CloudWatch Logs (optional)
```

### 1.3 Environment Selection Decision Tree

```
START: Which environment to use?
    │
    ├─── Is this a new feature or test?
    │    └─── YES → Use DEV
    │
    ├─── Is this validated in DEV?
    │    ├─── NO → Test in DEV first
    │    └─── YES ↓
    │
    ├─── Is this for stakeholder demo?
    │    └─── YES → Use SIT
    │
    ├─── Is this production workload?
    │    ├─── NO → Use SIT for testing
    │    └─── YES → Use PROD (with approvals)
    │
    └─── Remember: DEV → SIT → PROD promotion flow
```

---

## 2. Common Scenarios

### 2.1 Scenario: Provision New Tenant for Client

**Trigger:** Client signs up for WordPress hosting

**Steps:**
1. Collect tenant information:
   - Company name
   - Subdomain preference
   - Contact email
   - Organization structure

2. Generate tenant ID:
   ```bash
   TENANT_ID=$(date +%s%N | cut -c1-12)
   ```

3. Provision in DEV first:
   ```bash
   ENV=dev ./provision_tenant.sh $TENANT_ID
   ```

4. Validate WordPress is accessible:
   ```
   https://{subdomain}.wpdev.kimmyai.io
   ```

5. Promote to SIT after validation:
   ```bash
   ENV=sit ./provision_tenant.sh $TENANT_ID
   ```

6. Promote to PROD with approvals:
   ```bash
   ENV=prod ./provision_tenant.sh $TENANT_ID
   ```

### 2.2 Scenario: Client Cancellation - Delete Tenant

**Trigger:** Client cancels subscription

**Steps:**
1. Verify cancellation is legitimate
2. Notify client of data deletion (7-day grace period)
3. Export data backup if requested
4. After grace period, delete in reverse order:
   - PROD first (if exists)
   - SIT second
   - DEV last

5. Verify deletion:
   ```bash
   ./verify_tenant_deleted.sh $TENANT_ID
   ```

### 2.3 Scenario: POC Cleanup - Bulk Delete

**Trigger:** POC period ends, cleanup test tenants

**Steps:**
1. List all POC tenants:
   ```bash
   aws --profile Tebogo-sit ecs list-services \
     --cluster sit-cluster --region eu-west-1 \
     --query 'serviceArns[*]' --output text | tr '\t' '\n'
   ```

2. Create deletion list
3. Get bulk deletion approval
4. Execute bulk delete script:
   ```bash
   for tenant in $POC_TENANTS; do
     ./delete_tenant.sh $tenant all
   done
   ```

5. Verify all resources cleaned up

### 2.4 Scenario: Tenant Resource Scaling

**Trigger:** Client needs more resources

**Steps:**
1. Assess current usage:
   ```bash
   aws --profile $AWS_PROFILE cloudwatch get-metric-statistics \
     --namespace ECS/ContainerInsights \
     --metric-name CpuUtilized \
     --dimensions Name=ServiceName,Value=${ENV}-${TENANT_ID}-service
   ```

2. Determine new resource requirements
3. Update task definition with new CPU/memory
4. Update service:
   ```bash
   aws --profile $AWS_PROFILE ecs update-service \
     --cluster ${ENV}-cluster \
     --service "${ENV}-${TENANT_ID}-service" \
     --task-definition "${ENV}-${TENANT_ID}:NEW_VERSION" \
     --desired-count $NEW_COUNT
   ```

---

## 3. Troubleshooting Guide

### 3.1 Provisioning Failures

#### Issue: Database Creation Failed

**Symptoms:**
- Error: "Database already exists"
- Error: "User already exists"

**Resolution:**
```bash
# Check if database/user exists
mysql -h $RDS_HOST -u admin -p -e "SHOW DATABASES LIKE '${TENANT_ID}%';"
mysql -h $RDS_HOST -u admin -p -e "SELECT user FROM mysql.user WHERE user LIKE '${TENANT_ID}%';"

# If exists but tenant doesn't, clean up orphaned resources:
mysql -h $RDS_HOST -u admin -p -e "DROP DATABASE IF EXISTS ${TENANT_ID}_db;"
mysql -h $RDS_HOST -u admin -p -e "DROP USER IF EXISTS '${TENANT_ID}_user'@'%';"

# Retry provisioning
```

#### Issue: ECS Service Won't Start

**Symptoms:**
- Service stuck in PROVISIONING
- Tasks fail to start

**Resolution:**
```bash
# Check stopped tasks for error
aws --profile $AWS_PROFILE ecs list-tasks \
  --cluster ${ENV}-cluster \
  --service-name "${ENV}-${TENANT_ID}-service" \
  --desired-status STOPPED \
  --region $AWS_REGION

# Get stopped reason
aws --profile $AWS_PROFILE ecs describe-tasks \
  --cluster ${ENV}-cluster \
  --tasks <TASK_ARN> \
  --query 'tasks[0].stoppedReason' \
  --region $AWS_REGION

# Common causes:
# 1. Secret not found → Check Secrets Manager
# 2. Image pull failed → Check ECR permissions
# 3. Network error → Check VPC/subnet/SG configuration
```

#### Issue: ALB Health Check Failing

**Symptoms:**
- Target group shows unhealthy targets
- 502/503 errors

**Resolution:**
```bash
# Check target health
aws --profile $AWS_PROFILE elbv2 describe-target-health \
  --target-group-arn $TG_ARN \
  --region $AWS_REGION

# Verify health check path exists
curl -I http://internal-alb/${TENANT_ID}/wp-admin/install.php

# Check security group allows ALB to reach ECS tasks
# Check task is listening on correct port
```

### 3.2 Deletion Failures

#### Issue: Cannot Delete ECS Service

**Symptoms:**
- Error: "Service is in DRAINING state"
- Service won't delete

**Resolution:**
```bash
# Wait for tasks to drain (up to 5 minutes)
aws --profile $AWS_PROFILE ecs wait services-stable \
  --cluster ${ENV}-cluster \
  --services "${ENV}-${TENANT_ID}-service" \
  --region $AWS_REGION

# Or force delete
aws --profile $AWS_PROFILE ecs delete-service \
  --cluster ${ENV}-cluster \
  --service "${ENV}-${TENANT_ID}-service" \
  --force \
  --region $AWS_REGION
```

#### Issue: Cannot Delete Target Group

**Symptoms:**
- Error: "Target group is in use by a listener rule"

**Resolution:**
```bash
# Delete listener rule first
LISTENER_ARN=$(aws --profile $AWS_PROFILE elbv2 describe-listeners ...)
aws --profile $AWS_PROFILE elbv2 describe-rules \
  --listener-arn $LISTENER_ARN \
  --query "Rules[?Actions[?TargetGroupArn=='$TG_ARN']].RuleArn" \
  --region $AWS_REGION

# Delete the rule
aws --profile $AWS_PROFILE elbv2 delete-rule --rule-arn $RULE_ARN

# Then delete target group
aws --profile $AWS_PROFILE elbv2 delete-target-group --target-group-arn $TG_ARN
```

#### Issue: Task Fails to Run for Database Cleanup

**Symptoms:**
- ResourceInitializationError
- Cannot pull secrets

**Resolution:**
```bash
# Check if referenced secrets exist
aws --profile $AWS_PROFILE secretsmanager describe-secret \
  --secret-id "${ENV}-${TENANT_ID}-db-credentials" \
  --region $AWS_REGION

# If secret was already deleted, use a task definition without secrets
# Example: ${ENV}-manual-db-create or ${ENV}-generic-db-init

# Verify task execution role has permissions
aws --profile $AWS_PROFILE iam get-role-policy \
  --role-name ${ENV}-ecs-task-execution-role \
  --policy-name secrets-access
```

### 3.3 Cross-Environment Issues

#### Issue: Tenant Exists in Some Environments But Not Others

**Symptoms:**
- Tenant works in DEV but not SIT
- Resources missing in one environment

**Resolution:**
```bash
# Audit tenant across all environments
./audit_tenant.sh $TENANT_ID

# Compare resources
for PROFILE in Tebogo-dev Tebogo-sit Tebogo-prod; do
  echo "=== $PROFILE ==="
  ENV=$(echo $PROFILE | cut -d- -f2)
  REGION="eu-west-1"
  [[ "$PROFILE" == "Tebogo-prod" ]] && REGION="af-south-1"

  echo -n "ECS: "
  aws --profile $PROFILE ecs describe-services \
    --cluster ${ENV}-cluster \
    --services "${ENV}-${TENANT_ID}-service" \
    --query 'services[0].status' --output text \
    --region $REGION 2>/dev/null || echo "MISSING"

  echo -n "TG: "
  aws --profile $PROFILE elbv2 describe-target-groups \
    --names "${ENV}-${TENANT_ID}-tg" \
    --query 'TargetGroups[0].TargetGroupName' --output text \
    --region $REGION 2>/dev/null || echo "MISSING"

  echo -n "Secret: "
  aws --profile $PROFILE secretsmanager describe-secret \
    --secret-id "${ENV}-${TENANT_ID}-db-credentials" \
    --query 'Name' --output text \
    --region $REGION 2>/dev/null || echo "MISSING"
done
```

#### Issue: AWS SSO Session Issues

**Symptoms:**
- All profiles return same account ID
- "Token has expired" errors

**Resolution:**
```bash
# Clear SSO cache
rm -rf ~/.aws/sso/cache/*

# Re-login to each profile
aws sso login --profile Tebogo-dev
aws sso login --profile Tebogo-sit
aws sso login --profile Tebogo-prod

# Verify correct accounts
aws --profile Tebogo-dev sts get-caller-identity   # 536580886816
aws --profile Tebogo-sit sts get-caller-identity   # 815856636111
aws --profile Tebogo-prod sts get-caller-identity  # 093646564004
```

---

## 4. Emergency Procedures

### 4.1 Emergency Tenant Shutdown

**Trigger:** Security incident or abuse detected

**Steps:**
1. Immediately scale to 0:
   ```bash
   aws --profile $AWS_PROFILE ecs update-service \
     --cluster ${ENV}-cluster \
     --service "${ENV}-${TENANT_ID}-service" \
     --desired-count 0 \
     --region $AWS_REGION
   ```

2. Remove ALB listener rule (blocks all traffic):
   ```bash
   aws --profile $AWS_PROFILE elbv2 delete-rule --rule-arn $RULE_ARN
   ```

3. Document incident
4. Notify security team
5. Preserve logs for investigation

### 4.2 Emergency Rollback

**Trigger:** Failed update caused outage

**Steps:**
1. Identify last working task definition:
   ```bash
   aws --profile $AWS_PROFILE ecs list-task-definitions \
     --family-prefix "${ENV}-${TENANT_ID}" \
     --sort DESC \
     --region $AWS_REGION
   ```

2. Rollback to previous version:
   ```bash
   aws --profile $AWS_PROFILE ecs update-service \
     --cluster ${ENV}-cluster \
     --service "${ENV}-${TENANT_ID}-service" \
     --task-definition "${ENV}-${TENANT_ID}:PREVIOUS_VERSION" \
     --region $AWS_REGION
   ```

3. Monitor service stability:
   ```bash
   aws --profile $AWS_PROFILE ecs wait services-stable \
     --cluster ${ENV}-cluster \
     --services "${ENV}-${TENANT_ID}-service" \
     --region $AWS_REGION
   ```

### 4.3 Orphaned Resource Cleanup

**Trigger:** Partial deletion left orphaned resources

**Steps:**
1. Audit all resource types:
   ```bash
   # Check each resource type
   echo "ECS Services:"
   aws --profile $AWS_PROFILE ecs list-services --cluster ${ENV}-cluster

   echo "Target Groups:"
   aws --profile $AWS_PROFILE elbv2 describe-target-groups \
     --query "TargetGroups[?contains(TargetGroupName, '${TENANT_ID}')]"

   echo "Secrets:"
   aws --profile $AWS_PROFILE secretsmanager list-secrets \
     --query "SecretList[?contains(Name, '${TENANT_ID}')]"

   echo "EFS Access Points:"
   aws --profile $AWS_PROFILE efs describe-access-points \
     --file-system-id $EFS_ID \
     --query "AccessPoints[?contains(Name, '${TENANT_ID}')]"
   ```

2. Delete each orphaned resource manually
3. Document for future prevention

---

## 5. Checklists

### 5.1 Pre-Provisioning Checklist

- [ ] Tenant ID generated and verified unique
- [ ] Subdomain validated (no conflicts)
- [ ] Contact email verified
- [ ] Organization structure defined
- [ ] Resource sizing determined (CPU, memory, storage)
- [ ] Approvals obtained (if SIT/PROD)
- [ ] AWS SSO session active

### 5.2 Post-Provisioning Checklist

- [ ] ECS service running (desired count met)
- [ ] Target group healthy
- [ ] DNS resolving correctly
- [ ] WordPress accessible via browser
- [ ] Database connection verified
- [ ] Secrets stored correctly
- [ ] Logs appearing in CloudWatch
- [ ] Tenant owner notified with access details

### 5.3 Pre-Deletion Checklist

- [ ] Deletion request verified legitimate
- [ ] Tenant owner notified
- [ ] Data backup completed (if required)
- [ ] Grace period elapsed
- [ ] Approvals obtained (PROD requires typed confirmation)
- [ ] Billing finalized
- [ ] All environments identified (DEV, SIT, PROD)

### 5.4 Post-Deletion Checklist

- [ ] ECS service deleted
- [ ] ALB listener rule deleted
- [ ] Target group deleted
- [ ] Secrets Manager secret deleted
- [ ] Task definition deregistered
- [ ] EFS access point deleted
- [ ] Database dropped
- [ ] Database user dropped
- [ ] CloudWatch logs archived/deleted
- [ ] DNS record removed (if applicable)
- [ ] Verification script passed

---

## 6. Quick Reference

### 6.1 Resource Naming Conventions

| Resource | Pattern | Example |
|----------|---------|---------|
| ECS Service | `{env}-{tenant_id}-service` | `dev-goldencrust-service` |
| Task Definition | `{env}-{tenant_id}` | `sit-manufacturing` |
| Target Group | `{env}-{tenant_id}-tg` | `prod-tenant-1-tg` |
| Secret | `{env}-{tenant_id}-db-credentials` | `dev-sterlinglaw-db-credentials` |
| EFS Access Point | `{env}-{tenant_id}-ap` | `sit-sunsetbistro-ap` |
| Database | `{tenant_id}_db` | `goldencrust_db` |
| DB User | `{tenant_id}_user` | `manufacturing_user` |

### 6.2 Deletion Order (CRITICAL)

Always delete in this order to avoid dependency errors:

1. **ECS Service** (scale to 0 first, then delete)
2. **ALB Listener Rule** (must delete before target group)
3. **ALB Target Group** (must delete after listener rule)
4. **Route53 Record** (if dedicated record exists)
5. **Task Definition** (deregister)
6. **EFS Access Point** (may have multiple)
7. **Database User** (revoke grants first)
8. **Database** (drop database)
9. **Secrets Manager Secret** (force delete)
10. **CloudWatch Log Group** (optional, can retain)

### 6.3 Environment-Specific Details

| Item | DEV | SIT | PROD |
|------|-----|-----|------|
| Account | 536580886816 | 815856636111 | 093646564004 |
| Region | eu-west-1 | eu-west-1 | af-south-1 |
| Profile | Tebogo-dev | Tebogo-sit | Tebogo-prod |
| Cluster | dev-cluster | sit-cluster | prod-cluster |
| Domain | wpdev.kimmyai.io | wpsit.kimmyai.io | wp.kimmyai.io |
| ALB | dev-alb | sit-alb | prod-alb |
| RDS | dev-mysql | sit-mysql | prod-mysql |
| EFS | dev-efs | sit-efs | prod-efs |

---

## Related Documents

- [Tenant Management SOP](./tenant_management_sop.md)
- [Tenant Management Runbook](./tenant_management_runbook.md)
- [Tenant Manager Agent](../tenant/agent.md)
