# Event Handler Lambda Deployment Runbook

**Service**: ECS Event Handler Lambda
**Repository**: https://github.com/BigBeardWebSolutions/2_bbws_tenants_event_handler
**Last Updated**: 2025-01-25
**Version**: 1.0

---

## 1. Overview

The ECS Event Handler Lambda processes EventBridge events from Amazon ECS and synchronizes service state changes to DynamoDB. This enables real-time tracking of tenant WordPress instance provisioning status.

### Architecture Flow

```
EventBridge (ECS Events) --> Lambda (Event Handler) --> DynamoDB (Tenant State)
                                   |
                                   v
                         CloudWatch (Metrics/Logs)
                                   |
                                   v
                             SQS (Dead-Letter Queue)
```

### Event Processing

The handler subscribes to two EventBridge rule patterns:
1. **ECS Service Action** - Service state changes (steady state, task impaired, etc.)
2. **ECS Deployment State Change** - Deployment lifecycle events

### Event Type to DynamoDB Status Mapping

| ECS Event | DynamoDB Status | Description |
|-----------|-----------------|-------------|
| SERVICE_STEADY_STATE | ACTIVE | Service is healthy and running |
| SERVICE_TASK_START_IMPAIRED | FAILED | Tasks failing to start |
| SERVICE_DESIRED_COUNT_UPDATED | SCALING | Service is scaling |
| SERVICE_DELETED | DEPROVISIONED | Service has been deleted |
| DEPLOYMENT_COMPLETED | ACTIVE | Deployment successful |
| DEPLOYMENT_FAILED | FAILED | Deployment failed |
| DEPLOYMENT_IN_PROGRESS | PROVISIONING | Deployment is running |
| DEPLOYMENT_ROLLBACK_STARTED | ROLLING_BACK | Rollback initiated |
| DEPLOYMENT_ROLLBACK_COMPLETED | ACTIVE | Rollback complete |

### Reference Documentation

- **LLD**: 2.7 Section 10.4 and 12.4 - ECS Event Handler Design
- **SAM Template**: `template.yaml`

---

## 2. Prerequisites

### Required Access

| Access Type | DEV | SIT | PROD |
|-------------|-----|-----|------|
| GitHub Repository | Read/Write | Read/Write | Read |
| AWS Console | Full | Limited | Read-Only |
| AWS CLI | Configured | Configured | Configured |

### Tools Required

| Tool | Minimum Version | Installation |
|------|-----------------|--------------|
| AWS CLI | 2.x | `brew install awscli` |
| AWS SAM CLI | 1.100+ | `brew install aws-sam-cli` |
| Python | 3.12 | `brew install python@3.12` |
| Docker | Latest | For SAM build container |

### Infrastructure Prerequisites

| Resource | DEV | SIT | PROD |
|----------|-----|-----|------|
| DynamoDB Table | `bbws-tenants-dev` | `bbws-tenants-sit` | `bbws-tenants-prod` |
| ECS Cluster | `bbws-cluster-dev` | `bbws-cluster-sit` | `bbws-cluster-prod` |
| CloudWatch Log Group | `/aws/lambda/bbws-ecs-event-handler-dev` | `/aws/lambda/bbws-ecs-event-handler-sit` | `/aws/lambda/bbws-ecs-event-handler-prod` |
| GitHub OIDC Role | `bbws-github-actions-role-dev` | `bbws-github-actions-role-sit` | `bbws-github-actions-role-prod` |

### AWS Account Information

| Environment | AWS Account ID | Region | IAM Role |
|-------------|---------------|--------|----------|
| DEV | 536580886816 | af-south-1 | `bbws-github-actions-role-dev` |
| SIT | 815856636111 | af-south-1 | `bbws-github-actions-role-sit` |
| PROD | 093646564004 | af-south-1 | `bbws-github-actions-role-prod` |

---

## 3. Pre-Deployment Checklist

### Code Quality Gates

- [ ] All unit tests pass (`pytest tests/unit/`)
- [ ] All integration tests pass (`pytest tests/integration/`)
- [ ] Code coverage >= 80%
- [ ] Linting passes (flake8, black, mypy)
- [ ] No security vulnerabilities (bandit scan)

### Infrastructure Verification

```bash
# Set environment variables
export AWS_REGION="af-south-1"
export ENVIRONMENT="dev"  # or sit, prod
export AWS_ACCOUNT_ID="536580886816"  # Update per environment

# Verify DynamoDB table exists
aws dynamodb describe-table \
  --table-name bbws-tenants-${ENVIRONMENT} \
  --region ${AWS_REGION}

# Verify ECS cluster exists
aws ecs describe-clusters \
  --clusters bbws-cluster-${ENVIRONMENT} \
  --region ${AWS_REGION}

# Verify CloudWatch log group exists (or will be created)
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/lambda/bbws-ecs-event-handler-${ENVIRONMENT}" \
  --region ${AWS_REGION}
```

### EventBridge Rule Verification

```bash
# List existing EventBridge rules for ECS events
aws events list-rules \
  --region ${AWS_REGION} \
  --query "Rules[?contains(Name, 'ecs-event-handler')]" \
  --output table
```

---

## 4. DEV Deployment Steps

### Method 1: Automated Deployment (Recommended)

DEV deployments are automatically triggered on push to the `main` branch.

```bash
# 1. Commit and push changes to main branch
git add .
git commit -m "feat: your feature description"
git push origin main

# 2. Monitor deployment in GitHub Actions
# URL: https://github.com/BigBeardWebSolutions/2_bbws_tenants_event_handler/actions
# Workflow: "Deploy to DEV"

# 3. Expected workflow stages:
#    - Quality Gates (~3-5 min)
#    - SAM Build (~2-3 min)
#    - Deploy to DEV (~3-5 min)
#    - Post-Deployment Verification (~2 min)
```

### Method 2: Manual Workflow Trigger

```bash
# Navigate to GitHub Actions and manually trigger "Deploy to DEV" workflow
# URL: https://github.com/BigBeardWebSolutions/2_bbws_tenants_event_handler/actions/workflows/deploy-dev.yml

# Optional: Skip quality gates (emergency only)
# Input: skip_tests = true
```

### Method 3: Local SAM Deployment (DEV Only)

```bash
# 1. Navigate to repository
cd /path/to/2_bbws_tenants_event_handler

# 2. Configure AWS credentials for DEV
export AWS_PROFILE=bbws-dev  # Or use aws configure

# 3. Build SAM application
sam build --use-container --build-image public.ecr.aws/sam/build-python3.12

# 4. Deploy to DEV
sam deploy \
  --stack-name bbws-ecs-event-handler-dev \
  --region af-south-1 \
  --no-confirm-changeset \
  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides Environment=dev \
  --tags \
    "bbws:project=BBWS-Phase-2.1-ECS" \
    "bbws:component=ecs-event-handler" \
    "bbws:environment=dev" \
    "bbws:managed-by=sam-local"

# 5. Verify stack outputs
aws cloudformation describe-stacks \
  --stack-name bbws-ecs-event-handler-dev \
  --region af-south-1 \
  --query 'Stacks[0].Outputs' \
  --output table
```

---

## 5. Verification Steps

### Verify Lambda Function

```bash
export AWS_REGION="af-south-1"
export ENVIRONMENT="dev"

# Check Lambda function exists and is active
aws lambda get-function \
  --function-name bbws-ecs-event-handler-${ENVIRONMENT} \
  --region ${AWS_REGION} \
  --query 'Configuration.{Name:FunctionName,Runtime:Runtime,State:State,LastModified:LastModified}' \
  --output table
```

### Verify EventBridge Rules

```bash
# List EventBridge rules created by SAM
aws events list-rules \
  --region ${AWS_REGION} \
  --query "Rules[?contains(Name, 'ecs-event-handler')]" \
  --output table

# Verify rule targets
RULE_NAME=$(aws events list-rules \
  --region ${AWS_REGION} \
  --query "Rules[?contains(Name, 'ecs-event-handler')].Name | [0]" \
  --output text)

aws events list-targets-by-rule \
  --rule ${RULE_NAME} \
  --region ${AWS_REGION} \
  --output table
```

### Test Event Processing

```bash
# Invoke Lambda with test ECS event
TEST_EVENT='{
  "version": "0",
  "id": "test-event-id",
  "detail-type": "ECS Service Action",
  "source": "aws.ecs",
  "account": "'"${AWS_ACCOUNT_ID}"'",
  "time": "2025-01-25T12:00:00Z",
  "region": "'"${AWS_REGION}"'",
  "resources": [],
  "detail": {
    "eventType": "INFO",
    "eventName": "SERVICE_STEADY_STATE",
    "clusterArn": "arn:aws:ecs:'"${AWS_REGION}"':'"${AWS_ACCOUNT_ID}"':cluster/bbws-cluster-'"${ENVIRONMENT}"'",
    "serviceName": "test-verification-service",
    "tags": [
      {"key": "bbws:tenant-id", "value": "test-tenant-123"},
      {"key": "bbws:environment", "value": "'"${ENVIRONMENT}"'"}
    ]
  }
}'

aws lambda invoke \
  --function-name bbws-ecs-event-handler-${ENVIRONMENT} \
  --payload "$(echo "$TEST_EVENT" | base64)" \
  --cli-binary-format raw-in-base64-out \
  --region ${AWS_REGION} \
  response.json

cat response.json
```

### Check CloudWatch Logs

```bash
# Tail recent logs
aws logs tail /aws/lambda/bbws-ecs-event-handler-${ENVIRONMENT} \
  --follow \
  --region ${AWS_REGION}

# Query for errors in last hour
aws logs filter-log-events \
  --log-group-name /aws/lambda/bbws-ecs-event-handler-${ENVIRONMENT} \
  --start-time $(($(date +%s) - 3600))000 \
  --filter-pattern "ERROR" \
  --region ${AWS_REGION}
```

### Check CloudWatch Metrics

```bash
# Check error count in last hour
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=bbws-ecs-event-handler-${ENVIRONMENT} \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum \
  --region ${AWS_REGION}

# Check invocation count
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=bbws-ecs-event-handler-${ENVIRONMENT} \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum \
  --region ${AWS_REGION}
```

---

## 6. SIT Promotion Steps

SIT promotion is a manual process requiring DEV stability verification.

### Pre-Promotion Checks

```bash
# 1. Verify DEV is stable (check errors in last hour)
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=bbws-ecs-event-handler-dev \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum \
  --region af-south-1

# 2. Verify DEV code SHA matches expected version
aws lambda get-function-configuration \
  --function-name bbws-ecs-event-handler-dev \
  --region af-south-1 \
  --query 'CodeSha256'
```

### Promotion via GitHub Actions

1. Navigate to GitHub Actions:
   ```
   https://github.com/BigBeardWebSolutions/2_bbws_tenants_event_handler/actions/workflows/promote-to-sit.yml
   ```

2. Click "Run workflow"

3. Optionally specify DEV stack version to promote

4. Click "Run workflow" to start

5. **Wait for GitHub Environment approval** (if configured)

6. Monitor workflow progress:
   - Pre-flight Checks (~2 min)
   - SAM Build (~3 min)
   - Deploy to SIT (~3-5 min)
   - Post-Deployment Verification (~2 min)

### Post-SIT Promotion Verification

```bash
export AWS_REGION="af-south-1"
export ENVIRONMENT="sit"
export AWS_ACCOUNT_ID="815856636111"

# Verify Lambda deployed
aws lambda get-function \
  --function-name bbws-ecs-event-handler-sit \
  --region ${AWS_REGION} \
  --query 'Configuration.{Name:FunctionName,State:State,LastModified:LastModified}' \
  --output table

# Run test invocation
# (Use test event from Section 5)
```

---

## 7. PROD Promotion Steps

**CRITICAL**: PROD deployments require:
- All quality gates to pass
- Manual GitHub Environment approval
- Maintenance window confirmation
- SIT stability verification (24-hour lookback)

### Pre-PROD Checks

```bash
# 1. Verify SIT stability (24-hour lookback)
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=bbws-ecs-event-handler-sit \
  --start-time $(date -u -v-24H +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 86400 \
  --statistics Sum \
  --region af-south-1

# 2. Check for throttles
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Throttles \
  --dimensions Name=FunctionName,Value=bbws-ecs-event-handler-sit \
  --start-time $(date -u -v-24H +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 86400 \
  --statistics Sum \
  --region af-south-1
```

### Promotion via GitHub Actions

1. Navigate to GitHub Actions:
   ```
   https://github.com/BigBeardWebSolutions/2_bbws_tenants_event_handler/actions/workflows/promote-to-prod.yml
   ```

2. Click "Run workflow"

3. **REQUIRED**: Check "Confirm deployment during approved maintenance window"

4. Click "Run workflow" to start

5. **Wait for GitHub Environment approval** (required for PROD)

6. Monitor workflow progress with enhanced verification (5-minute error monitoring)

### PROD Deployment Restrictions

- **PROD is read-only for routine operations**
- Deployments only during approved maintenance windows
- Requires explicit approval in GitHub Environment protection rules
- 24-hour SIT stability requirement (max 5 errors)
- Zero throttle tolerance

### Post-PROD Verification

```bash
export AWS_REGION="af-south-1"
export ENVIRONMENT="prod"
export AWS_ACCOUNT_ID="093646564004"

# Verify Lambda deployed
aws lambda get-function \
  --function-name bbws-ecs-event-handler-prod \
  --region ${AWS_REGION} \
  --query 'Configuration.{Name:FunctionName,State:State,LastModified:LastModified}' \
  --output table

# Monitor CloudWatch alarms
aws cloudwatch describe-alarms \
  --alarm-name-prefix "bbws-ecs-event-handler-prod" \
  --region ${AWS_REGION} \
  --output table

# Monitor for 24 hours post-deployment
```

---

## 8. Post-Deployment Verification

### Complete Verification Checklist

| Check | Command/Action | Expected Result |
|-------|----------------|-----------------|
| Lambda exists | `aws lambda get-function` | State: Active |
| EventBridge rules | `aws events list-rules` | 2 rules (Service Action, Deployment) |
| Test invocation | Lambda invoke with test event | Status: success or ignored |
| CloudWatch logs | Tail log group | No ERROR entries |
| CloudWatch metrics | Get Errors metric | Sum = 0 |
| DLQ empty | Check SQS queue | ApproximateNumberOfMessages = 0 |

### End-to-End Event Flow Test

```bash
# 1. Trigger a real ECS event (DEV only)
# Option A: Scale a service
aws ecs update-service \
  --cluster bbws-cluster-dev \
  --service your-test-service \
  --desired-count 2 \
  --region af-south-1

# 2. Wait 30 seconds for event propagation

# 3. Check CloudWatch logs for event processing
aws logs filter-log-events \
  --log-group-name /aws/lambda/bbws-ecs-event-handler-dev \
  --start-time $(($(date +%s) - 300))000 \
  --region af-south-1

# 4. Verify DynamoDB state updated
aws dynamodb get-item \
  --table-name bbws-tenants-dev \
  --key '{"tenant_id": {"S": "your-tenant-id"}}' \
  --region af-south-1
```

---

## 9. Rollback Triggers

### Automatic Rollback Criteria

Rollback should be initiated when:

| Condition | Threshold | Action |
|-----------|-----------|--------|
| Error rate spike | > 10 errors/hour (DEV/SIT), > 5 errors/hour (PROD) | Rollback |
| Throttling | Any throttles detected | Rollback |
| DLQ messages | > 10 messages in DLQ | Investigate, potential rollback |
| Event processing delay | Events not processed within 5 minutes | Investigate |

### Manual Rollback via GitHub Actions

1. Navigate to GitHub Actions:
   ```
   https://github.com/BigBeardWebSolutions/2_bbws_tenants_event_handler/actions/workflows/rollback.yml
   ```

2. Click "Run workflow"

3. Select environment (dev/sit/prod)

4. Optionally specify target version (leave empty for previous version)

5. **REQUIRED**: Enter reason for rollback

6. Click "Run workflow"

### Manual Rollback via AWS CLI

```bash
export AWS_REGION="af-south-1"
export ENVIRONMENT="dev"  # or sit, prod
export FUNCTION_NAME="bbws-ecs-event-handler-${ENVIRONMENT}"

# 1. List available versions
aws lambda list-versions-by-function \
  --function-name ${FUNCTION_NAME} \
  --region ${AWS_REGION} \
  --query 'Versions[].{Version:Version,LastModified:LastModified}' \
  --output table

# 2. List backup aliases
aws lambda list-aliases \
  --function-name ${FUNCTION_NAME} \
  --region ${AWS_REGION} \
  --query 'Aliases[?starts_with(Name, `backup-`)].{Name:Name,Version:FunctionVersion}' \
  --output table

# 3. Update alias to previous version
TARGET_VERSION="<version-number>"

aws lambda update-alias \
  --function-name ${FUNCTION_NAME} \
  --name latest-${ENVIRONMENT} \
  --function-version ${TARGET_VERSION} \
  --description "Manual rollback on $(date -u +%Y-%m-%d)" \
  --region ${AWS_REGION}

# 4. Verify rollback
aws lambda get-alias \
  --function-name ${FUNCTION_NAME} \
  --name latest-${ENVIRONMENT} \
  --region ${AWS_REGION}
```

### CloudFormation Stack Rollback

```bash
# Rollback to previous stack state
aws cloudformation rollback-stack \
  --stack-name bbws-ecs-event-handler-${ENVIRONMENT} \
  --region ${AWS_REGION}

# Monitor rollback progress
aws cloudformation describe-stack-events \
  --stack-name bbws-ecs-event-handler-${ENVIRONMENT} \
  --region ${AWS_REGION} \
  --query 'StackEvents[0:5]' \
  --output table
```

---

## 10. Event Troubleshooting

### Dead-Letter Queue (DLQ) Monitoring

```bash
export AWS_REGION="af-south-1"
export ENVIRONMENT="dev"

# Check DLQ message count
aws sqs get-queue-attributes \
  --queue-url "https://sqs.${AWS_REGION}.amazonaws.com/${AWS_ACCOUNT_ID}/bbws-ecs-events-dlq-${ENVIRONMENT}" \
  --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible \
  --region ${AWS_REGION}

# Receive and inspect DLQ messages
aws sqs receive-message \
  --queue-url "https://sqs.${AWS_REGION}.amazonaws.com/${AWS_ACCOUNT_ID}/bbws-ecs-events-dlq-${ENVIRONMENT}" \
  --max-number-of-messages 5 \
  --region ${AWS_REGION}
```

### Common Issues and Solutions

#### Issue: Events Not Being Processed

**Symptoms**: ECS events not updating DynamoDB state

**Diagnosis**:
```bash
# 1. Check EventBridge rule is enabled
aws events describe-rule \
  --name <rule-name> \
  --region ${AWS_REGION}

# 2. Check Lambda invocation metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=bbws-ecs-event-handler-${ENVIRONMENT} \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --region ${AWS_REGION}

# 3. Check event pattern matches cluster ARN
aws events list-rules \
  --region ${AWS_REGION} \
  --query "Rules[?contains(Name, 'ecs-event-handler')].{Name:Name,EventPattern:EventPattern}" \
  --output json
```

**Solutions**:
- Verify EventBridge rule pattern includes correct cluster ARN
- Check Lambda has correct IAM permissions
- Verify DynamoDB table name in environment variables

#### Issue: Missing Tenant ID

**Symptoms**: Events logged with "No bbws:tenant-id tag found"

**Diagnosis**:
```bash
# Check ECS service tags
aws ecs describe-services \
  --cluster bbws-cluster-${ENVIRONMENT} \
  --services <service-name> \
  --region ${AWS_REGION} \
  --query 'services[0].tags'
```

**Solution**:
- Add `bbws:tenant-id` tag to ECS service
- Add `bbws:environment` tag matching Lambda environment

#### Issue: Environment Mismatch

**Symptoms**: Events logged with "Environment mismatch"

**Diagnosis**:
```bash
# Check Lambda environment variable
aws lambda get-function-configuration \
  --function-name bbws-ecs-event-handler-${ENVIRONMENT} \
  --region ${AWS_REGION} \
  --query 'Environment.Variables.ENVIRONMENT'

# Check ECS service environment tag
aws ecs describe-services \
  --cluster bbws-cluster-${ENVIRONMENT} \
  --services <service-name> \
  --region ${AWS_REGION} \
  --query 'services[0].tags[?key==`bbws:environment`].value'
```

**Solution**:
- Ensure ECS service `bbws:environment` tag matches Lambda ENVIRONMENT variable

#### Issue: DynamoDB Update Failures

**Symptoms**: "Failed to update tenant state" errors in logs

**Diagnosis**:
```bash
# Check DynamoDB table exists
aws dynamodb describe-table \
  --table-name bbws-tenants-${ENVIRONMENT} \
  --region ${AWS_REGION}

# Check Lambda IAM role has DynamoDB permissions
aws lambda get-function \
  --function-name bbws-ecs-event-handler-${ENVIRONMENT} \
  --region ${AWS_REGION} \
  --query 'Configuration.Role'
```

**Solution**:
- Verify DynamoDB table exists with correct name
- Check Lambda execution role has `dynamodb:UpdateItem` permission

#### Issue: High DLQ Message Count

**Symptoms**: Many messages in dead-letter queue

**Diagnosis**:
```bash
# Sample DLQ messages
aws sqs receive-message \
  --queue-url "https://sqs.${AWS_REGION}.amazonaws.com/${AWS_ACCOUNT_ID}/bbws-ecs-events-dlq-${ENVIRONMENT}" \
  --max-number-of-messages 5 \
  --attribute-names All \
  --message-attribute-names All \
  --region ${AWS_REGION}
```

**Solutions**:
- Check Lambda error logs for root cause
- Fix Lambda code and redeploy
- Replay DLQ messages after fix (see below)

### Replay DLQ Messages

```bash
# Move messages from DLQ back to main processing
# (Requires custom script or AWS Lambda DLQ redrive)

# Option 1: Use AWS Console SQS DLQ redrive feature

# Option 2: Manual replay
aws sqs receive-message \
  --queue-url "https://sqs.${AWS_REGION}.amazonaws.com/${AWS_ACCOUNT_ID}/bbws-ecs-events-dlq-${ENVIRONMENT}" \
  --max-number-of-messages 10 \
  --region ${AWS_REGION} \
  --output json > dlq_messages.json

# Process each message through Lambda
# (Parse dlq_messages.json and invoke Lambda for each)
```

---

## 11. GitHub Actions Workflows Reference

| Workflow | File | Trigger | Purpose |
|----------|------|---------|---------|
| Quality Gates | `quality-gates.yml` | Called by other workflows | Lint, test, coverage |
| Deploy to DEV | `deploy-dev.yml` | Push to main, manual | Automatic DEV deployment |
| Promote to SIT | `promote-to-sit.yml` | Manual | Promote from DEV to SIT |
| Promote to PROD | `promote-to-prod.yml` | Manual | Promote from SIT to PROD |
| Rollback | `rollback.yml` | Manual | Emergency rollback any env |

### Workflow URLs

- DEV Deploy: `https://github.com/BigBeardWebSolutions/2_bbws_tenants_event_handler/actions/workflows/deploy-dev.yml`
- SIT Promote: `https://github.com/BigBeardWebSolutions/2_bbws_tenants_event_handler/actions/workflows/promote-to-sit.yml`
- PROD Promote: `https://github.com/BigBeardWebSolutions/2_bbws_tenants_event_handler/actions/workflows/promote-to-prod.yml`
- Rollback: `https://github.com/BigBeardWebSolutions/2_bbws_tenants_event_handler/actions/workflows/rollback.yml`

---

## 12. Related Documentation

| Document | Location |
|----------|----------|
| LLD 2.7 Event Handler | `/2_bbws_docs/LLDs/2.7_LLD_Tenant_Instances_Lambda.md` |
| Product Lambda Deployment | `/2_bbws_docs/runbooks/product_lambda_deployment.md` |
| Tenant Provisioning Runbook | `/2_bbws_docs/runbooks/RB-001_Tenant_Provisioning.md` |
| CI/CD Guide | `/2_bbws_docs/runbooks/product_lambda_cicd_guide.md` |

---

## 13. Support Contacts

| Role | Contact |
|------|---------|
| Platform Team | platform@bigbeardweb.com |
| On-Call Engineer | See PagerDuty |
| AWS Support | Support Console |

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-01-25 | Worker 6-3 | Initial version |

---

**Status**: Active
**Review Cycle**: Quarterly
