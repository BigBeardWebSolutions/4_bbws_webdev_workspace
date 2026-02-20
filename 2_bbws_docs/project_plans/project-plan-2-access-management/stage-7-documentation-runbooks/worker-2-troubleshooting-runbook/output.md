# Access Management - Troubleshooting Runbook

**Document ID**: RUNBOOK-ACCESS-TROUBLESHOOT-001
**Version**: 1.0
**Last Updated**: 2026-01-25
**Owner**: Support Team
**Review Frequency**: Monthly

---

## 1. Overview

### 1.1 Purpose
This runbook provides troubleshooting procedures for common issues in the Access Management system.

### 1.2 Scope
- Authorization failures
- Permission denied errors
- Team isolation issues
- Invitation email failures
- Audit logging gaps
- Performance issues
- Lambda/DynamoDB/API Gateway troubleshooting

### 1.3 Audience
- Support Engineers
- DevOps Engineers
- On-call Engineers

---

## 2. Quick Reference - Error Codes

| Error Code | Description | Quick Fix |
|------------|-------------|-----------|
| 401 | Unauthorized - Invalid/expired token | Refresh JWT token |
| 403 | Forbidden - Insufficient permissions | Check user roles/permissions |
| 404 | Resource not found | Verify resource ID exists |
| 409 | Conflict - Resource already exists | Use different identifier |
| 429 | Rate limited | Wait and retry with backoff |
| 500 | Internal server error | Check Lambda logs |
| 502 | Bad gateway | Check Lambda timeout/memory |
| 503 | Service unavailable | Check DynamoDB throttling |

---

## 3. Authorization Failures

### 3.1 Invalid Token (401)

**Symptoms**:
- API returns `401 Unauthorized`
- Error message: "Invalid token" or "Token expired"

**Diagnostic Steps**:

```bash
# 1. Decode JWT token (without verification)
echo "$TOKEN" | cut -d'.' -f2 | base64 -d 2>/dev/null | jq .

# 2. Check token expiration
echo "$TOKEN" | cut -d'.' -f2 | base64 -d 2>/dev/null | jq '.exp | . - now | if . < 0 then "EXPIRED" else "Valid for \(./60 | floor) minutes" end'

# 3. Check Authorizer logs
aws logs filter-log-events \
  --log-group-name "/aws/lambda/bbws-access-$ENV-lambda-authorizer" \
  --start-time $(date -d '15 minutes ago' +%s000) \
  --filter-pattern "ERROR" \
  --query 'events[*].message'
```

**Resolution**:
1. If token expired: Client must refresh the token via Cognito
2. If token malformed: Check client token handling
3. If issuer mismatch: Verify Cognito pool configuration

### 3.2 Permission Denied (403)

**Symptoms**:
- API returns `403 Forbidden`
- User has valid token but cannot perform action

**Diagnostic Steps**:

```bash
# 1. Get user's roles
aws dynamodb query \
  --table-name bbws-access-$ENV-ddb-access-management \
  --key-condition-expression "PK = :pk" \
  --expression-attribute-values '{":pk": {"S": "USER#<user_id>"}}' \
  --query 'Items[?begins_with(SK, `ROLE#`)]'

# 2. Get role permissions
aws dynamodb query \
  --table-name bbws-access-$ENV-ddb-access-management \
  --key-condition-expression "PK = :pk" \
  --expression-attribute-values '{":pk": {"S": "ROLE#<role_id>"}}' \
  --query 'Items[0].permissions'

# 3. Check authorizer context in logs
aws logs filter-log-events \
  --log-group-name "/aws/lambda/bbws-access-$ENV-lambda-authorizer" \
  --start-time $(date -d '5 minutes ago' +%s000) \
  --filter-pattern "userId=$USER_ID" \
  --query 'events[*].message'
```

**Resolution**:
1. Verify user has required role assigned
2. Verify role includes required permission
3. Check for permission wildcards (`site:*`, `*:*`)
4. Verify team membership if team-scoped resource

### 3.3 Authorizer Timeout

**Symptoms**:
- Intermittent 500 errors
- Authorizer duration exceeds 10 seconds

**Diagnostic Steps**:

```bash
# Check authorizer duration metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=bbws-access-$ENV-lambda-authorizer \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Average Maximum p95

# Check cold starts
aws logs filter-log-events \
  --log-group-name "/aws/lambda/bbws-access-$ENV-lambda-authorizer" \
  --start-time $(date -d '1 hour ago' +%s000) \
  --filter-pattern "INIT_START"
```

**Resolution**:
1. If cold starts frequent: Enable provisioned concurrency
2. If JWKS fetch slow: Check Cognito endpoint health
3. If DynamoDB slow: Check throttling metrics

---

## 4. Permission Service Issues

### 4.1 Permission Not Found

**Symptoms**:
- `404 Not Found` when accessing permission
- Permission visible in one request, missing in next

**Diagnostic Steps**:

```bash
# Query permission directly
aws dynamodb get-item \
  --table-name bbws-access-$ENV-ddb-access-management \
  --key '{"PK": {"S": "PERMISSION#<permission_id>"}, "SK": {"S": "METADATA"}}'

# Check if soft-deleted
aws dynamodb get-item \
  --table-name bbws-access-$ENV-ddb-access-management \
  --key '{"PK": {"S": "PERMISSION#<permission_id>"}, "SK": {"S": "METADATA"}}' \
  --query 'Item.deleted_at'
```

**Resolution**:
1. If item missing: Permission was hard-deleted
2. If soft-deleted: Restore or create new permission
3. If consistency issue: Wait for eventual consistency (typically < 1 second)

### 4.2 Cannot Delete System Permission

**Symptoms**:
- `403 Forbidden` when deleting permission
- Error: "Cannot delete system permission"

**Resolution**:
System permissions (is_system=true) are protected. They can only be modified by platform administrators with `permission:admin` permission.

---

## 5. Team Service Issues

### 5.1 Team Isolation Violation

**Symptoms**:
- User can access resources from another team
- Cross-team data leakage

**Diagnostic Steps**:

```bash
# 1. Verify user's team memberships
aws dynamodb query \
  --table-name bbws-access-$ENV-ddb-access-management \
  --index-name GSI1 \
  --key-condition-expression "GSI1PK = :pk" \
  --expression-attribute-values '{":pk": {"S": "USER_TEAMS#<user_id>"}}' \
  --query 'Items[*].team_id'

# 2. Check resource's team ownership
aws dynamodb get-item \
  --table-name bbws-access-$ENV-ddb-access-management \
  --key '{"PK": {"S": "RESOURCE#<resource_id>"}, "SK": {"S": "METADATA"}}' \
  --query 'Item.team_id'

# 3. Check authorizer context
# Look for teamIds in auth context passed to Lambda
```

**Resolution**:
1. Remove user from unauthorized team
2. Verify authorizer is correctly populating teamIds
3. Check Lambda function is enforcing team scope

### 5.2 Cannot Remove Last Team Lead

**Symptoms**:
- `409 Conflict` when removing team member
- Error: "Cannot remove last team lead"

**Resolution**:
This is expected behavior. Before removing the last team lead:
1. Assign another member as team lead
2. Then remove the original team lead

```bash
# Update another member to team lead
curl -X PATCH "$API_URL/teams/<team_id>/members/<member_id>" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"team_role": "TEAM_LEAD"}'
```

---

## 6. Invitation Service Issues

### 6.1 Invitation Email Not Received

**Symptoms**:
- User reports not receiving invitation email
- Invitation status is PENDING

**Diagnostic Steps**:

```bash
# 1. Check SES sending statistics
aws ses get-send-statistics --region $AWS_REGION

# 2. Check SES bounce/complaint notifications
aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:$AWS_REGION:$ACCOUNT_ID:bbws-access-$ENV-ses-bounces

# 3. Check Lambda logs for send errors
aws logs filter-log-events \
  --log-group-name "/aws/lambda/bbws-access-$ENV-lambda-invitation-create" \
  --start-time $(date -d '1 hour ago' +%s000) \
  --filter-pattern "ERROR send email"
```

**Resolution**:
1. Check spam/junk folder
2. Verify email address is correct
3. Check if email is on bounce list
4. Resend invitation:

```bash
curl -X POST "$API_URL/invitations/<invitation_id>/resend" \
  -H "Authorization: Bearer $TOKEN"
```

### 6.2 Invitation Token Invalid

**Symptoms**:
- User clicks invitation link but gets "Invalid token"
- Token was valid previously

**Diagnostic Steps**:

```bash
# Check invitation status
aws dynamodb get-item \
  --table-name bbws-access-$ENV-ddb-access-management \
  --key '{"PK": {"S": "INVITATION#<invitation_id>"}, "SK": {"S": "METADATA"}}' \
  --query 'Item.[status, expires_at, token]'
```

**Resolution**:
| Status | Action |
|--------|--------|
| EXPIRED | Create new invitation |
| ACCEPTED | User already joined |
| CANCELLED | Create new invitation |
| DECLINED | Contact user, create new if needed |

---

## 7. Audit Service Issues

### 7.1 Missing Audit Logs

**Symptoms**:
- Expected audit events not appearing
- Gaps in audit trail

**Diagnostic Steps**:

```bash
# 1. Check audit Lambda invocations
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=bbws-access-$ENV-lambda-audit-log \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Sum

# 2. Check for errors
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=bbws-access-$ENV-lambda-audit-log \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Sum

# 3. Check DLQ for failed messages
aws sqs get-queue-attributes \
  --queue-url https://sqs.$AWS_REGION.amazonaws.com/$ACCOUNT_ID/bbws-access-$ENV-audit-dlq \
  --attribute-names ApproximateNumberOfMessages
```

**Resolution**:
1. If DLQ has messages: Process failed events manually
2. If Lambda errors: Check logs and fix issue
3. If no invocations: Check if calling service is sending audit events

### 7.2 Audit Export Fails

**Symptoms**:
- Export request returns 500 error
- Export times out

**Diagnostic Steps**:

```bash
# Check export Lambda logs
aws logs filter-log-events \
  --log-group-name "/aws/lambda/bbws-access-$ENV-lambda-audit-export" \
  --start-time $(date -d '30 minutes ago' +%s000) \
  --filter-pattern "ERROR"
```

**Resolution**:
1. For large exports: Use pagination or date range filters
2. For timeout: Increase Lambda timeout or use async export
3. For S3 permission issues: Check IAM role

---

## 8. DynamoDB Issues

### 8.1 Throttling

**Symptoms**:
- Intermittent 503 errors
- `ProvisionedThroughputExceededException` in logs

**Diagnostic Steps**:

```bash
# Check throttling metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ReadThrottledRequests \
  --dimensions Name=TableName,Value=bbws-access-$ENV-ddb-access-management \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum

# Check consumed capacity
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedReadCapacityUnits \
  --dimensions Name=TableName,Value=bbws-access-$ENV-ddb-access-management \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum
```

**Resolution**:
1. Table uses on-demand capacity - should auto-scale
2. If hot partition: Review access patterns
3. If GSI throttling: Check GSI capacity
4. Implement exponential backoff in clients

### 8.2 Consistency Issues

**Symptoms**:
- Write succeeds but immediate read returns old data
- Intermittent data inconsistency

**Resolution**:
DynamoDB uses eventual consistency by default. For strong consistency:

```python
# Use ConsistentRead=True for critical reads
response = table.get_item(
    Key={'PK': pk, 'SK': sk},
    ConsistentRead=True
)
```

Note: Strong consistency is 2x cost and only works in same region.

---

## 9. Lambda Issues

### 9.1 Cold Start Latency

**Symptoms**:
- First request after idle period is slow (> 5 seconds)
- Intermittent high latency

**Diagnostic Steps**:

```bash
# Check INIT_START frequency
aws logs filter-log-events \
  --log-group-name "/aws/lambda/bbws-access-$ENV-lambda-<function>" \
  --start-time $(date -d '1 hour ago' +%s000) \
  --filter-pattern "INIT_START" \
  --query 'events | length(@)'

# Check provisioned concurrency (PROD)
aws lambda get-provisioned-concurrency-config \
  --function-name bbws-access-$ENV-lambda-authorizer \
  --qualifier live
```

**Resolution**:
1. Enable provisioned concurrency for critical functions
2. Use Lambda SnapStart (if using Java)
3. Reduce package size
4. Optimize initialization code

### 9.2 Out of Memory

**Symptoms**:
- Lambda returns 502 Bad Gateway
- "Runtime exited" in logs

**Diagnostic Steps**:

```bash
# Check memory usage
aws logs filter-log-events \
  --log-group-name "/aws/lambda/bbws-access-$ENV-lambda-<function>" \
  --start-time $(date -d '30 minutes ago' +%s000) \
  --filter-pattern "Max Memory Used"
```

**Resolution**:
1. Increase memory allocation
2. Optimize code to reduce memory usage
3. Implement pagination for large data sets

---

## 10. API Gateway Issues

### 10.1 Rate Limiting (429)

**Symptoms**:
- `429 Too Many Requests` response
- Occurs during traffic spikes

**Diagnostic Steps**:

```bash
# Check current throttle settings
aws apigateway get-stage \
  --rest-api-id <api-id> \
  --stage-name $ENV \
  --query 'methodSettings.*.{throttlingBurstLimit,throttlingRateLimit}'

# Check 429 count
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name Count \
  --dimensions Name=ApiName,Value=bbws-access-$ENV-apigw Name=Stage,Value=$ENV \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum
```

**Resolution**:
1. Implement client-side retry with exponential backoff
2. Review and optimize API usage patterns
3. Request throttle limit increase if legitimate

---

## 11. Performance Troubleshooting

### 11.1 High Latency Investigation

```bash
# 1. Check API Gateway latency
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name Latency \
  --dimensions Name=ApiName,Value=bbws-access-$ENV-apigw \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Average p95 p99

# 2. Check Lambda duration by function
for func in permission invitation team role audit; do
  echo "=== $func ==="
  aws cloudwatch get-metric-statistics \
    --namespace AWS/Lambda \
    --metric-name Duration \
    --dimensions Name=FunctionName,Value=bbws-access-$ENV-lambda-$func-* \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 300 \
    --statistics Average p95
done

# 3. Check DynamoDB latency
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name SuccessfulRequestLatency \
  --dimensions Name=TableName,Value=bbws-access-$ENV-ddb-access-management Name=Operation,Value=Query \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Average
```

---

## 12. Log Analysis Commands

### 12.1 Common Log Queries

```bash
# Find all errors in last hour
aws logs filter-log-events \
  --log-group-name "/aws/lambda/bbws-access-$ENV-lambda-*" \
  --start-time $(date -d '1 hour ago' +%s000) \
  --filter-pattern "ERROR"

# Find specific user's requests
aws logs filter-log-events \
  --log-group-name "/aws/lambda/bbws-access-$ENV-lambda-*" \
  --start-time $(date -d '1 hour ago' +%s000) \
  --filter-pattern "{ $.userId = \"user_12345\" }"

# Find slow requests (> 5 seconds)
aws logs filter-log-events \
  --log-group-name "/aws/lambda/bbws-access-$ENV-lambda-*" \
  --start-time $(date -d '1 hour ago' +%s000) \
  --filter-pattern "{ $.duration > 5000 }"
```

### 12.2 CloudWatch Insights Queries

```sql
-- Error rate by function
fields @timestamp, @message
| filter @message like /ERROR/
| stats count() by bin(5m)

-- P95 latency by service
fields @timestamp, @duration
| filter ispresent(@duration)
| stats pct(@duration, 95) as p95 by bin(5m)

-- Top errors
fields @timestamp, @message
| filter @message like /ERROR/
| parse @message /ERROR.*: (?<error>.+)/
| stats count() by error
| sort count desc
| limit 10
```

---

## 13. Contacts & Escalation

| Issue Type | First Contact | Escalation |
|------------|---------------|------------|
| Authorization | Support Team | Security Team |
| Performance | DevOps | Platform Team |
| Data Issues | Support Team | Database Team |
| Integration | Support Team | Integration Team |

### Escalation Criteria
- P1: Service completely unavailable - Immediate escalation
- P2: Significant degradation (> 50% errors) - 15 min escalation
- P3: Minor issues - 1 hour escalation
- P4: Cosmetic/minor - Next business day

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-25 | Support Team | Initial version |
