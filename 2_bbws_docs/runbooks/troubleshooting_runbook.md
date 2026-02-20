# BBWS Platform Troubleshooting Runbook

**Version**: 1.0
**Created**: 2026-01-25
**Status**: Active
**Owner**: Platform Operations
**Severity Classification**: All Levels (P1-P4)

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-25 | Platform Operations | Initial version - Comprehensive troubleshooting guide |

---

## 1. Overview

### 1.1 Purpose

This runbook provides step-by-step troubleshooting procedures for common issues across the BBWS Multi-Tenant WordPress Hosting Platform. It covers all serverless components including Lambda functions, DynamoDB, SQS/DLQ, EventBridge, and API Gateway.

### 1.2 Quick Reference

| Issue Category | Jump To |
|----------------|---------|
| API Gateway Issues | [Section 7](#7-api-gateway-troubleshooting) |
| Lambda Issues | [Section 8](#8-lambda-troubleshooting) |
| DynamoDB Issues | [Section 4](#4-dynamodb-troubleshooting) |
| SQS/DLQ Issues | [Section 5](#5-sqsdlq-troubleshooting) |
| EventBridge Issues | [Section 6](#6-eventbridge-troubleshooting) |
| Cross-Service Issues | [Section 9](#9-cross-service-issues) |
| Escalation Procedures | [Section 10](#10-escalation-procedures) |

### 1.3 Environment Details

| Environment | AWS Account | Region | Log Group Prefix |
|-------------|-------------|--------|------------------|
| DEV | 536580886816 | af-south-1 | /aws/lambda/bbws-* |
| SIT | 815856636111 | af-south-1 | /aws/lambda/bbws-* |
| PROD | 093646564004 | af-south-1 | /aws/lambda/bbws-* |

### 1.4 Services Covered

| Service | Repository | Description |
|---------|------------|-------------|
| Tenant Lambda | `2_bbws_tenants_instances_lambda` | Instance CRUD, status, scaling |
| Site Management Lambda | `2_bbws_wordpress_site_management_lambda` | Sites, Templates, Plugins APIs |
| Event Handler Lambda | `2_bbws_tenants_event_handler` | ECS state synchronization |
| DynamoDB Tables | N/A | On-demand mode for all tables |
| SQS Queues | N/A | Async processing with DLQs |
| EventBridge Rules | N/A | ECS event routing |

---

## 2. Common Issues Matrix

### 2.1 API and Gateway Issues

| Symptom | Possible Cause | Resolution | Priority |
|---------|----------------|------------|----------|
| 502 Bad Gateway | Lambda timeout | Increase timeout, check dependencies | P2 |
| 504 Gateway Timeout | Cold start or long processing | Add provisioned concurrency | P2 |
| 429 Too Many Requests | API Gateway throttling | Check and increase rate limits | P3 |
| 401 Unauthorized | Invalid or expired JWT | Verify Cognito token, refresh | P3 |
| 403 Forbidden | Missing IAM permissions | Check Lambda execution role | P2 |
| CORS Errors | Missing CORS headers | Configure API Gateway CORS | P3 |

### 2.2 Lambda Issues

| Symptom | Possible Cause | Resolution | Priority |
|---------|----------------|------------|----------|
| Lambda timeout | Long-running operation | Optimize code, increase timeout | P2 |
| Out of memory | Memory allocation too low | Increase Lambda memory | P2 |
| Permission denied | IAM role missing permissions | Update execution role | P2 |
| Import errors | Missing dependencies | Rebuild deployment package | P2 |
| Cold start latency | No provisioned concurrency | Enable provisioned concurrency | P3 |

### 2.3 DynamoDB Issues

| Symptom | Possible Cause | Resolution | Priority |
|---------|----------------|------------|----------|
| DynamoDB throttling | Burst capacity exceeded | Verify on-demand mode, check hot partitions | P2 |
| Item not found | Incorrect key format | Verify PK/SK patterns | P3 |
| Conditional check failed | Optimistic locking conflict | Retry with latest version | P3 |
| Scan timeout | Table too large for scan | Use Query with GSI instead | P3 |
| Replication lag | Global table sync delay | Wait or check DR region | P3 |

### 2.4 SQS/DLQ Issues

| Symptom | Possible Cause | Resolution | Priority |
|---------|----------------|------------|----------|
| Messages in DLQ | Processing failure | Check consumer logs, analyze message | P2 |
| Message stuck in queue | Consumer not processing | Check Lambda trigger, visibility timeout | P2 |
| Duplicate processing | At-least-once delivery | Implement idempotency | P3 |
| Queue backlog growing | Consumer too slow | Scale concurrency, optimize code | P2 |

### 2.5 EventBridge Issues

| Symptom | Possible Cause | Resolution | Priority |
|---------|----------------|------------|----------|
| Events not processed | Rule pattern mismatch | Verify event pattern, test rule | P2 |
| Lambda not invoked | Missing permissions | Check resource-based policy | P2 |
| Duplicate events | Retry on failure | Implement idempotent handler | P3 |
| State sync failure | tenant-event-handler error | Check Lambda logs, DynamoDB permissions | P2 |

### 2.6 Instance Management Issues

| Symptom | Possible Cause | Resolution | Priority |
|---------|----------------|------------|----------|
| Instance stuck in PROVISIONING | Terraform error | Check GitOps workflow, Terraform logs | P1 |
| Site creation stuck | SQS consumer error | Check DLQ, verify WordPress API | P1 |
| Scale operation failed | ECS service issue | Check ECS events, task health | P2 |
| Status not updating | EventBridge sync failure | Verify event handler Lambda | P2 |

---

## 3. CloudWatch Log Queries

### 3.1 Find Errors in Last Hour

```
fields @timestamp, @message, @logStream
| filter @message like /ERROR|Exception|error/
| sort @timestamp desc
| limit 100
```

### 3.2 Find Slow Requests (> 5 seconds)

```
fields @timestamp, @duration, @message, @requestId
| filter @type = "REPORT"
| filter @duration > 5000
| sort @duration desc
| limit 50
```

### 3.3 Find Lambda Timeouts

```
fields @timestamp, @message, @requestId, @logStream
| filter @message like /Task timed out/
| sort @timestamp desc
| limit 50
```

### 3.4 Find Memory Exhaustion

```
fields @timestamp, @message, @memorySize, @maxMemoryUsed
| filter @type = "REPORT"
| filter @maxMemoryUsed / @memorySize > 0.9
| sort @timestamp desc
| limit 50
```

### 3.5 Trace Request by Correlation ID

```
fields @timestamp, @message, @logStream
| filter correlationId = "<correlation-id>"
| sort @timestamp asc
| limit 500
```

### 3.6 Find Tenant-Specific Issues

```
fields @timestamp, @message, tenantId, action, status
| filter tenantId = "<tenant-id>"
| sort @timestamp desc
| limit 200
```

### 3.7 Find Failed API Requests

```
fields @timestamp, @message, statusCode, errorCode
| filter statusCode >= 400
| sort @timestamp desc
| limit 100
```

### 3.8 Track Site Creation Progress

```
fields @timestamp, @message, siteId, status
| filter siteId = "<site-id>"
| sort @timestamp asc
| limit 200
```

---

## 4. DynamoDB Troubleshooting

### 4.1 Check Table Mode and Capacity

```bash
# Verify table is on-demand
aws dynamodb describe-table \
  --table-name bbws-tenants-${ENV} \
  --query 'Table.BillingModeSummary' \
  --region af-south-1
```

**Expected Output**: `{"BillingMode": "PAY_PER_REQUEST"}`

### 4.2 Check Throttled Requests

```bash
# Check throttling metrics for last hour
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ThrottledRequests \
  --dimensions Name=TableName,Value=bbws-tenants-${ENV} \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Sum \
  --region af-south-1
```

### 4.3 Query Specific Item

```bash
# Get tenant by ID
aws dynamodb get-item \
  --table-name bbws-tenants-${ENV} \
  --key '{
    "PK": {"S": "TENANT#<tenant-id>"},
    "SK": {"S": "METADATA"}
  }' \
  --region af-south-1 | jq '.'
```

### 4.4 Query Instance State

```bash
# Get instance state for tenant
aws dynamodb get-item \
  --table-name ${ENV}-tenant-resources \
  --key '{
    "PK": {"S": "TENANT#<tenant-id>"},
    "SK": {"S": "INSTANCE"}
  }' \
  --region af-south-1 | jq '.'
```

### 4.5 List Stuck Operations

```bash
# Find operations stuck in non-terminal states
aws dynamodb scan \
  --table-name ${ENV}-tenant-resources \
  --filter-expression "provisioningState IN (:p1, :p2, :p3)" \
  --expression-attribute-values '{
    ":p1": {"S": "PROVISIONING"},
    ":p2": {"S": "COMMITTING"},
    ":p3": {"S": "WORKFLOW_RUNNING"}
  }' \
  --region af-south-1 | jq '.Items[] | {tenantId: .tenantId.S, state: .provisioningState.S, updatedAt: .updatedAt.S}'
```

### 4.6 Check Hot Partition

```bash
# Check consumed capacity by partition
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedReadCapacityUnits \
  --dimensions Name=TableName,Value=bbws-tenants-${ENV} \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Maximum \
  --region af-south-1
```

### 4.7 Manually Update Stuck State

```bash
# CAUTION: Only use when confirmed stuck and manual intervention required
aws dynamodb update-item \
  --table-name ${ENV}-tenant-resources \
  --key '{
    "PK": {"S": "TENANT#<tenant-id>"},
    "SK": {"S": "INSTANCE"}
  }' \
  --update-expression "SET provisioningState = :state, lastError = :error, updatedAt = :now" \
  --expression-attribute-values '{
    ":state": {"S": "FAILED"},
    ":error": {"S": "Manually marked as failed by operations"},
    ":now": {"S": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}
  }' \
  --region af-south-1
```

---

## 5. SQS/DLQ Troubleshooting

### 5.1 Check Queue Depth

```bash
# Check messages in queue
aws sqs get-queue-attributes \
  --queue-url https://sqs.af-south-1.amazonaws.com/${ACCOUNT}/bbws-wp-site-creation-${ENV} \
  --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible \
  --region af-south-1
```

### 5.2 Check DLQ for Failed Messages

```bash
# Check DLQ depth
aws sqs get-queue-attributes \
  --queue-url https://sqs.af-south-1.amazonaws.com/${ACCOUNT}/bbws-wp-site-operations-dlq-${ENV} \
  --attribute-names ApproximateNumberOfMessages \
  --region af-south-1

# Receive messages from DLQ for investigation
aws sqs receive-message \
  --queue-url https://sqs.af-south-1.amazonaws.com/${ACCOUNT}/bbws-wp-site-operations-dlq-${ENV} \
  --max-number-of-messages 5 \
  --region af-south-1 | jq '.Messages[] | {MessageId, Body: (.Body | fromjson)}'
```

### 5.3 Purge Queue (Emergency Only)

```bash
# CAUTION: This deletes ALL messages
aws sqs purge-queue \
  --queue-url https://sqs.af-south-1.amazonaws.com/${ACCOUNT}/bbws-wp-site-creation-${ENV} \
  --region af-south-1
```

### 5.4 Replay DLQ Messages

```bash
# Move messages from DLQ back to main queue
aws sqs start-message-move-task \
  --source-arn arn:aws:sqs:af-south-1:${ACCOUNT}:bbws-wp-site-operations-dlq-${ENV} \
  --destination-arn arn:aws:sqs:af-south-1:${ACCOUNT}:bbws-wp-site-creation-${ENV} \
  --region af-south-1
```

### 5.5 Monitor Queue Age

```bash
# Check age of oldest message
aws cloudwatch get-metric-statistics \
  --namespace AWS/SQS \
  --metric-name ApproximateAgeOfOldestMessage \
  --dimensions Name=QueueName,Value=bbws-wp-site-creation-${ENV} \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Maximum \
  --region af-south-1
```

### 5.6 Order Event Queues (SNS Fan-Out)

```bash
# Check all order processing queues
for queue in order-record order-pdf order-internal-notify order-customer-notify; do
  echo "=== Queue: bbws-${queue}-${ENV} ==="
  aws sqs get-queue-attributes \
    --queue-url https://sqs.af-south-1.amazonaws.com/${ACCOUNT}/bbws-${queue}-${ENV} \
    --attribute-names ApproximateNumberOfMessages \
    --region af-south-1
done
```

---

## 6. EventBridge Troubleshooting

### 6.1 Check Rule Status

```bash
# List EventBridge rules
aws events list-rules \
  --name-prefix bbws \
  --region af-south-1 | jq '.Rules[] | {Name, State, EventPattern}'
```

### 6.2 Check Rule Targets

```bash
# Get targets for ECS state sync rule
aws events list-targets-by-rule \
  --rule bbws-ecs-state-sync-rule-${ENV} \
  --region af-south-1
```

### 6.3 Check Rule Invocations

```bash
# Check if rule is being triggered
aws cloudwatch get-metric-statistics \
  --namespace AWS/Events \
  --metric-name Invocations \
  --dimensions Name=RuleName,Value=bbws-ecs-state-sync-rule-${ENV} \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Sum \
  --region af-south-1
```

### 6.4 Check Failed Invocations

```bash
# Check for failed invocations
aws cloudwatch get-metric-statistics \
  --namespace AWS/Events \
  --metric-name FailedInvocations \
  --dimensions Name=RuleName,Value=bbws-ecs-state-sync-rule-${ENV} \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Sum \
  --region af-south-1
```

### 6.5 Test Event Pattern Match

```bash
# Test if an event matches the rule pattern
aws events test-event-pattern \
  --event-pattern '{
    "source": ["aws.ecs"],
    "detail-type": ["ECS Service Action", "ECS Deployment State Change"],
    "detail": {
      "clusterArn": ["arn:aws:ecs:af-south-1:'${ACCOUNT}':cluster/bbws-cluster-'${ENV}'"]
    }
  }' \
  --event '{
    "source": "aws.ecs",
    "detail-type": "ECS Service Action",
    "detail": {
      "clusterArn": "arn:aws:ecs:af-south-1:'${ACCOUNT}':cluster/bbws-cluster-'${ENV}'",
      "eventType": "SERVICE_STEADY_STATE"
    }
  }' \
  --region af-south-1
```

### 6.6 Verify Lambda Permission for EventBridge

```bash
# Check if Lambda has permission to be invoked by EventBridge
aws lambda get-policy \
  --function-name tenant-event-handler-lambda \
  --region af-south-1 | jq '.Policy | fromjson | .Statement[] | select(.Principal.Service == "events.amazonaws.com")'
```

---

## 7. API Gateway Troubleshooting

### 7.1 Check API Gateway 5XX Errors

```bash
# Check 5XX error rate
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name 5XXError \
  --dimensions Name=ApiName,Value=bbws-api-${ENV} \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Sum \
  --region af-south-1
```

### 7.2 Check Latency

```bash
# Check API Gateway latency
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name Latency \
  --dimensions Name=ApiName,Value=bbws-api-${ENV} \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics p95 \
  --region af-south-1
```

### 7.3 Check Throttling

```bash
# Check API Gateway throttling
aws apigateway get-stage \
  --rest-api-id ${API_ID} \
  --stage-name ${ENV} \
  --query 'methodSettings' \
  --region af-south-1
```

### 7.4 Update Throttling Limits

```bash
# Increase rate limit if throttling
aws apigateway update-stage \
  --rest-api-id ${API_ID} \
  --stage-name ${ENV} \
  --patch-operations op=replace,path=/throttling/rateLimit,value=1000 \
  --region af-south-1
```

### 7.5 Verify Lambda Integration

```bash
# Check Lambda integration for a resource
aws apigateway get-integration \
  --rest-api-id ${API_ID} \
  --resource-id ${RESOURCE_ID} \
  --http-method GET \
  --region af-south-1
```

### 7.6 Redeploy API

```bash
# Force redeploy the API
aws apigateway create-deployment \
  --rest-api-id ${API_ID} \
  --stage-name ${ENV} \
  --region af-south-1
```

---

## 8. Lambda Troubleshooting

### 8.1 Check Lambda Errors

```bash
# Check Lambda error rate
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=bbws-tenant-create-${ENV} \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Sum \
  --region af-south-1
```

### 8.2 Check Lambda Duration

```bash
# Check function duration
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=bbws-tenant-create-${ENV} \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics p95 Maximum \
  --region af-south-1
```

### 8.3 View Recent Logs

```bash
# Tail Lambda logs
aws logs tail /aws/lambda/bbws-tenant-create-${ENV} --follow --region af-south-1

# Filter for errors
aws logs tail /aws/lambda/bbws-tenant-create-${ENV} \
  --filter-pattern "ERROR" \
  --since 1h \
  --region af-south-1
```

### 8.4 Check Lambda Configuration

```bash
# Get Lambda configuration
aws lambda get-function-configuration \
  --function-name bbws-tenant-create-${ENV} \
  --query '{Memory: MemorySize, Timeout: Timeout, Runtime: Runtime, Role: Role}' \
  --region af-south-1
```

### 8.5 Update Lambda Memory

```bash
# Increase memory allocation
aws lambda update-function-configuration \
  --function-name bbws-tenant-create-${ENV} \
  --memory-size 512 \
  --region af-south-1
```

### 8.6 Update Lambda Timeout

```bash
# Increase timeout
aws lambda update-function-configuration \
  --function-name bbws-tenant-create-${ENV} \
  --timeout 120 \
  --region af-south-1
```

### 8.7 Check Lambda Execution Role

```bash
# Get execution role
ROLE_NAME=$(aws lambda get-function-configuration \
  --function-name bbws-tenant-create-${ENV} \
  --query 'Role' \
  --output text \
  --region af-south-1 | cut -d'/' -f2)

# List role policies
aws iam list-attached-role-policies --role-name ${ROLE_NAME}
aws iam list-role-policies --role-name ${ROLE_NAME}
```

### 8.8 Manually Invoke Lambda

```bash
# Create test event
cat > /tmp/test-event.json <<EOF
{
  "httpMethod": "GET",
  "path": "/v1.0/tenants",
  "headers": {"Accept": "application/json"}
}
EOF

# Invoke function
aws lambda invoke \
  --function-name bbws-tenant-list-${ENV} \
  --payload file:///tmp/test-event.json \
  /tmp/response.json \
  --region af-south-1

# View response
cat /tmp/response.json | jq '.'
```

### 8.9 Enable Provisioned Concurrency

```bash
# Set provisioned concurrency to reduce cold starts
aws lambda put-provisioned-concurrency-config \
  --function-name bbws-tenant-create-${ENV} \
  --qualifier live \
  --provisioned-concurrent-executions 5 \
  --region af-south-1
```

---

## 9. Cross-Service Issues

### 9.1 Instance Stuck in PROVISIONING

**Symptoms**: Instance status remains PROVISIONING for > 15 minutes

**Diagnosis Steps**:

1. Check DynamoDB state:
```bash
aws dynamodb get-item \
  --table-name ${ENV}-tenant-resources \
  --key '{"PK": {"S": "TENANT#<tenant-id>"}, "SK": {"S": "INSTANCE"}}' \
  --region af-south-1 | jq '{state: .Item.provisioningState.S, workflowStatus: .Item.workflowStatus.S, lastError: .Item.lastError.S}'
```

2. Check GitHub workflow status (if workflowStatus is WORKFLOW_RUNNING):
```bash
# Check workflow run via GitHub CLI
gh run view <workflow-run-id> --repo your-org/2_bbws_tenants_instances_${ENV}
```

3. Check Terraform logs in GitHub Actions

4. Check ECS service events:
```bash
aws ecs describe-services \
  --cluster bbws-cluster-${ENV} \
  --services tenant-<tenant-id>-wordpress \
  --region af-south-1 | jq '.services[0].events[:5]'
```

**Resolution**:
- If workflow failed: Check GitHub Actions logs, fix issue, retry
- If ECS service stuck: Check container logs, security groups
- If timeout: Manually mark as FAILED and retry

### 9.2 Site Creation Stuck in PROVISIONING

**Symptoms**: Site status remains PROVISIONING, no progress

**Diagnosis Steps**:

1. Check DynamoDB site record:
```bash
aws dynamodb get-item \
  --table-name sites \
  --key '{"PK": {"S": "TENANT#<tenant-id>"}, "SK": {"S": "SITE#<site-id>"}}' \
  --region af-south-1 | jq '{status: .Item.status.S, createdAt: .Item.createdAt.S}'
```

2. Check SQS queue for pending message:
```bash
aws sqs get-queue-attributes \
  --queue-url https://sqs.af-south-1.amazonaws.com/${ACCOUNT}/bbws-wp-site-creation-${ENV} \
  --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible \
  --region af-south-1
```

3. Check DLQ for failed message:
```bash
aws sqs receive-message \
  --queue-url https://sqs.af-south-1.amazonaws.com/${ACCOUNT}/bbws-wp-site-operations-dlq-${ENV} \
  --max-number-of-messages 5 \
  --region af-south-1 | jq '.Messages[] | select(.Body | fromjson | .payload.siteId == "<site-id>")'
```

4. Check site creator Lambda logs:
```bash
aws logs filter-log-events \
  --log-group-name /aws/lambda/bbws-wp-site-creator-${ENV} \
  --filter-pattern "<site-id>" \
  --start-time $(date -d '2 hours ago' +%s000) \
  --region af-south-1
```

**Resolution**:
- If message in DLQ: Fix issue, replay message
- If WordPress API error: Check ALB, ECS task health
- If timeout: Increase Lambda timeout, optimize code

### 9.3 EventBridge State Sync Not Working

**Symptoms**: DynamoDB state not updating after ECS changes

**Diagnosis Steps**:

1. Check EventBridge rule:
```bash
aws events describe-rule \
  --name bbws-ecs-state-sync-rule-${ENV} \
  --region af-south-1 | jq '{State, EventPattern}'
```

2. Check rule invocations:
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Events \
  --metric-name Invocations \
  --dimensions Name=RuleName,Value=bbws-ecs-state-sync-rule-${ENV} \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Sum \
  --region af-south-1
```

3. Check tenant-event-handler-lambda logs:
```bash
aws logs tail /aws/lambda/tenant-event-handler-lambda \
  --filter-pattern "ERROR" \
  --since 1h \
  --region af-south-1
```

4. Check ECS service tags (must have bbws:tenant-id):
```bash
aws ecs describe-services \
  --cluster bbws-cluster-${ENV} \
  --services tenant-<tenant-id>-wordpress \
  --include TAGS \
  --region af-south-1 | jq '.services[0].tags'
```

**Resolution**:
- If rule disabled: Enable rule
- If tags missing: Update ECS service with required tags
- If Lambda error: Check permissions, fix code

### 9.4 WordPress API Connection Failures

**Symptoms**: 502/504 errors from WordPress API calls

**Diagnosis Steps**:

1. Check ALB health:
```bash
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn> \
  --region af-south-1
```

2. Check ECS task status:
```bash
aws ecs list-tasks \
  --cluster bbws-cluster-${ENV} \
  --service-name tenant-<tenant-id>-wordpress \
  --region af-south-1

aws ecs describe-tasks \
  --cluster bbws-cluster-${ENV} \
  --tasks <task-arn> \
  --region af-south-1 | jq '.tasks[0].lastStatus'
```

3. Check container logs:
```bash
aws logs tail /ecs/tenant-<tenant-id>-wordpress --since 30m --region af-south-1
```

4. Check security groups:
```bash
# Lambda SG should allow outbound to ALB
# ALB SG should allow inbound from Lambda
# ECS SG should allow inbound from ALB
```

**Resolution**:
- If ECS task unhealthy: Check container logs, restart service
- If security group issue: Update rules
- If ALB routing issue: Verify listener rules

---

## 10. Escalation Procedures

### 10.1 Escalation Matrix

| Severity | Response Time | Escalation Path | Notification |
|----------|---------------|-----------------|--------------|
| P1 - Critical | 15 minutes | On-call Engineer -> Tech Lead -> Engineering Manager | PagerDuty + Slack |
| P2 - High | 1 hour | On-call Engineer -> Tech Lead | Slack |
| P3 - Medium | 4 hours | Support Team -> Engineering | Email + Slack |
| P4 - Low | 24 hours | Support Team | Ticket |

### 10.2 P1 Criteria (Critical)

- Complete service outage
- Data loss or corruption
- Security breach
- >50% of users affected
- Payment processing failure

### 10.3 P2 Criteria (High)

- Partial service degradation
- Single tenant affected
- Instance provisioning failure
- Site creation failure affecting customers

### 10.4 Escalation Contacts

| Role | Contact | Hours |
|------|---------|-------|
| On-call Engineer | PagerDuty | 24/7 |
| Tech Lead | Slack @tech-lead | Business hours |
| Engineering Manager | Slack @eng-manager | Business hours |
| AWS Support | Console / Phone | 24/7 (Enterprise) |

### 10.5 AWS Support Escalation

For AWS service issues that require AWS intervention:

```bash
# Create support case
aws support create-case \
  --subject "BBWS - <issue description>" \
  --service-code amazon-<service> \
  --severity-code <normal|high|urgent|critical> \
  --communication-body "<detailed description>" \
  --cc-email-addresses ops@company.com
```

### 10.6 Post-Incident Review

After resolving P1/P2 incidents:
1. Document incident timeline
2. Identify root cause
3. Create action items for prevention
4. Update runbooks if needed
5. Schedule post-mortem meeting

---

## 11. Verification Checklist

After resolving any issue, verify:

- [ ] Service is responding to health checks
- [ ] CloudWatch alarms cleared
- [ ] No messages in DLQ
- [ ] Lambda error rate returned to baseline
- [ ] API latency within SLA
- [ ] DynamoDB state consistent
- [ ] EventBridge events flowing
- [ ] User can perform affected operation

---

## 12. Related Documents

| Document | Location |
|----------|----------|
| RB-001 Tenant Provisioning | `/runbooks/RB-001_Tenant_Provisioning.md` |
| RB-002 Site Generation | `/runbooks/RB-002_Site_Generation_Troubleshooting.md` |
| LLD 2.5 Tenant Management | `/LLDs/2.5_LLD_Tenant_Management.md` |
| LLD 2.6 WordPress Site Management | `/LLDs/2.6_LLD_WordPress_Site_Management.md` |
| LLD 2.7 WordPress Instance Management | `/LLDs/2.7_LLD_WordPress_Instance_Management.md` |
| LLD 2.1.12 Event Architecture | `/LLDs/2.1.12_LLD_Event_Architecture.md` |
| CPP Troubleshooting Runbook | `/LLDs/2.1.15_OPS_Troubleshooting_Runbook.md` |

---

## 13. Revision History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-01-25 | 1.0 | Platform Operations | Initial release |

---

**End of Document**
