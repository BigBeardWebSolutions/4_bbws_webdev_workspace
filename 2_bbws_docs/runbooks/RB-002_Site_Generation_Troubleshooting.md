# RB-002: Site Generation Troubleshooting Runbook

**Version:** 1.0
**Last Updated:** 2026-01-18
**Owner:** Platform Operations
**Severity Classification:** P2 (High)

---

## 1. Purpose

This runbook provides step-by-step instructions for troubleshooting site generation failures, slow generation times, and quality issues in the AI-powered Site Builder.

---

## 2. Prerequisites

### 2.1 Access Required
- [ ] AWS Console access (eu-west-1)
- [ ] CloudWatch Logs access
- [ ] Bedrock console access
- [ ] DynamoDB read access
- [ ] S3 bucket access

### 2.2 Key Resources
| Resource | Name |
|----------|------|
| Generation Lambda | site-builder-dev-page-generator |
| Validation Lambda | site-builder-dev-brand-validator |
| DynamoDB Table | generations |
| S3 Bucket | site-builder-dev-assets-{account} |
| Bedrock Model | anthropic.claude-sonnet-4-5-20250514-v1:0 |

---

## 3. Common Issues

### 3.1 Issue Matrix

| Issue | Symptom | Likely Cause | Severity |
|-------|---------|--------------|----------|
| Generation timeout | Spinner forever, no response | Bedrock timeout | P2 |
| Empty response | No HTML generated | Prompt issue | P3 |
| Low brand score | Score < 6.0 | Content mismatch | P3 |
| Quota exceeded | 429 error | Plan limit reached | P4 |
| S3 write failure | Generation lost | Permission/quota | P2 |

---

## 4. Diagnostic Commands

### 4.1 Check Generation Status
```bash
# Get generation record by ID
aws dynamodb get-item \
  --table-name generations \
  --key '{"generation_id": {"S": "gen_XXXXX"}}' \
  --region eu-west-1 | jq '.'

# List recent generations for a tenant
aws dynamodb query \
  --table-name generations \
  --index-name tenant-index \
  --key-condition-expression "tenant_id = :tid" \
  --expression-attribute-values '{":tid": {"S": "ten_XXXXX"}}' \
  --scan-index-forward false \
  --limit 10 \
  --region eu-west-1 | jq '.Items[] | {id: .generation_id.S, status: .status.S, created: .created_at.S}'
```

### 4.2 Check Lambda Logs
```bash
# Page Generator errors
aws logs filter-log-events \
  --log-group-name "/aws/lambda/site-builder-dev-page-generator" \
  --filter-pattern "ERROR" \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --region eu-west-1 | jq '.events[] | {time: .timestamp, message: .message}'

# Search for specific generation
aws logs filter-log-events \
  --log-group-name "/aws/lambda/site-builder-dev-page-generator" \
  --filter-pattern "gen_XXXXX" \
  --region eu-west-1
```

### 4.3 Check Bedrock Metrics
```bash
# Invocation errors
aws cloudwatch get-metric-statistics \
  --namespace AWS/Bedrock \
  --metric-name InvocationErrors \
  --dimensions Name=ModelId,Value=anthropic.claude-sonnet-4-5-20250514-v1:0 \
  --start-time $(date -d '1 hour ago' -u +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Sum \
  --region eu-west-1

# Latency
aws cloudwatch get-metric-statistics \
  --namespace AWS/Bedrock \
  --metric-name InvocationLatency \
  --dimensions Name=ModelId,Value=anthropic.claude-sonnet-4-5-20250514-v1:0 \
  --start-time $(date -d '1 hour ago' -u +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Average,p99 \
  --region eu-west-1
```

---

## 5. Resolution Procedures

### 5.1 Scenario: Generation Timeout

**Symptoms:** User sees spinner for >60 seconds, then error

**Diagnosis:**
```bash
# Check Lambda duration
aws logs filter-log-events \
  --log-group-name "/aws/lambda/site-builder-dev-page-generator" \
  --filter-pattern "REPORT RequestId" \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --region eu-west-1 | grep -o 'Duration: [0-9.]* ms' | tail -10

# Check for Bedrock throttling
aws logs filter-log-events \
  --log-group-name "/aws/lambda/site-builder-dev-page-generator" \
  --filter-pattern "ThrottlingException" \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --region eu-west-1
```

**Resolution:**
1. If throttling: Request quota increase from AWS
2. If consistent timeouts: Check Bedrock service health
3. Temporary fix: Reduce prompt complexity

```bash
# Check Bedrock service health
aws health describe-events \
  --filter "services=bedrock,eventStatusCodes=open" \
  --region us-east-1
```

---

### 5.2 Scenario: Generation Stuck in PENDING/GENERATING

**Symptoms:** Generation record shows non-terminal status for >5 minutes

**Diagnosis:**
```bash
# Get stuck generations
aws dynamodb scan \
  --table-name generations \
  --filter-expression "#s IN (:p, :g) AND created_at < :time" \
  --expression-attribute-names '{"#s": "status"}' \
  --expression-attribute-values '{
    ":p": {"S": "PENDING"},
    ":g": {"S": "GENERATING"},
    ":time": {"S": "2026-01-18T12:00:00Z"}
  }' \
  --region eu-west-1 | jq '.Items[] | {id: .generation_id.S, status: .status.S}'
```

**Resolution:**
```bash
# Mark as failed
aws dynamodb update-item \
  --table-name generations \
  --key '{"generation_id": {"S": "gen_XXXXX"}}' \
  --update-expression "SET #s = :failed, error_message = :msg, updated_at = :now" \
  --expression-attribute-names '{"#s": "status"}' \
  --expression-attribute-values '{
    ":failed": {"S": "FAILED"},
    ":msg": {"S": "Generation timed out - marked failed by operations"},
    ":now": {"S": "2026-01-18T15:00:00Z"}
  }' \
  --region eu-west-1

# Notify user to retry
```

---

### 5.3 Scenario: Low Brand Score

**Symptoms:** Generated content has score < 6.0, user cannot deploy

**Diagnosis:**
```bash
# Get validation details
aws dynamodb get-item \
  --table-name generations \
  --key '{"generation_id": {"S": "gen_XXXXX"}}' \
  --projection-expression "brand_score, validation_issues" \
  --region eu-west-1 | jq '.'
```

**Resolution:**
1. Review validation issues in the response
2. Check if brand guidelines are configured for tenant
3. Suggest refinement prompts to user

```bash
# Check tenant brand guidelines
aws dynamodb get-item \
  --table-name tenants \
  --key '{"tenant_id": {"S": "ten_XXXXX"}}' \
  --projection-expression "brand_guidelines" \
  --region eu-west-1 | jq '.Item.brand_guidelines'
```

---

### 5.4 Scenario: Quota Exceeded (429 Error)

**Symptoms:** User sees "Monthly generation limit reached"

**Diagnosis:**
```bash
# Check current usage
aws dynamodb get-item \
  --table-name tenants \
  --key '{"tenant_id": {"S": "ten_XXXXX"}}' \
  --projection-expression "#u.generations_this_month, #l.max_generations_per_month" \
  --expression-attribute-names '{"#u": "usage", "#l": "limits"}' \
  --region eu-west-1 | jq '.'
```

**Resolution:**
1. Confirm quota is legitimately reached
2. If error, reset counter:
   ```bash
   aws dynamodb update-item \
     --table-name tenants \
     --key '{"tenant_id": {"S": "ten_XXXXX"}}' \
     --update-expression "SET #u.generations_this_month = :zero" \
     --expression-attribute-names '{"#u": "usage"}' \
     --expression-attribute-values '{":zero": {"N": "0"}}' \
     --region eu-west-1
   ```
3. If legitimate, suggest plan upgrade

---

### 5.5 Scenario: S3 Write Failure

**Symptoms:** Generation completes but content not saved

**Diagnosis:**
```bash
# Check S3 for content
aws s3 ls s3://site-builder-dev-assets-ACCOUNT/tenants/ten_XXXXX/sites/ --recursive

# Check Lambda IAM permissions
aws lambda get-function-configuration \
  --function-name site-builder-dev-page-generator \
  --query 'Role' \
  --region eu-west-1
```

**Resolution:**
```bash
# If permission issue, verify IAM policy
aws iam get-role-policy \
  --role-name site-builder-dev-lambda-execution-role \
  --policy-name s3-access

# Manual recovery: Re-save content from DynamoDB to S3
# (requires custom script)
```

---

## 6. Performance Troubleshooting

### 6.1 Slow Generation Times
```bash
# Check average duration over last hour
aws logs insights query \
  --log-group-name "/aws/lambda/site-builder-dev-page-generator" \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, @duration | stats avg(@duration), p95(@duration), max(@duration)' \
  --region eu-west-1
```

### 6.2 Streaming Issues
If SSE streaming is not working:
1. Check API Gateway stage logs
2. Verify Lambda response format
3. Check client-side EventSource handling

---

## 7. Verification Checklist

After resolving any issue:

- [ ] Generation record shows correct status
- [ ] Content exists in S3
- [ ] User can view content in preview
- [ ] Brand score is populated
- [ ] Usage counter incremented correctly
- [ ] No errors in Lambda logs

---

## 8. Escalation

| Condition | Escalate To |
|-----------|-------------|
| Bedrock service outage | AWS Support |
| >10 failures in 1 hour | Engineering Lead |
| Security concern | Security Team |

---

## 9. Related Documents

| Document | Link |
|----------|------|
| BP-002 | /business_process/BP-002_Site_Generation.md |
| SOP-002 | /SOPs/SOP-002_Site_Generation_QA.md |
