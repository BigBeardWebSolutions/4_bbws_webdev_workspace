# Stage 8: Documentation

**Stage ID**: stage-8-documentation
**Parent Project**: Site Builder Bedrock Generation API (project-plan-2)
**Status**: PENDING
**Created**: 2026-01-15

---

## Stage Overview

**Objective**: Create operational runbooks, API documentation, and troubleshooting guides.

**Dependencies**: Stage 7 complete

**Deliverables**:
1. Deployment runbook
2. Troubleshooting runbook
3. Rollback runbook
4. API documentation

**Expected Duration**:
- Agentic: 30-45 minutes
- Manual: 2-3 days

---

## Workers

| Worker | Name | Status | Description |
|--------|------|--------|-------------|
| 1 | Deployment Runbook | PENDING | Deployment runbook for DEV/SIT/PROD |
| 2 | Troubleshooting Runbook | PENDING | Troubleshooting guide for common issues |
| 3 | Rollback Runbook | PENDING | Rollback procedures runbook |
| 4 | API Documentation | PENDING | Comprehensive API documentation |

---

## Worker Definitions

### Worker 1: Deployment Runbook

**Objective**: Create comprehensive deployment runbook for Site Builder Generation API across all environments.

**Input Files**:
- `.github/workflows/terraform-apply.yml`
- `.github/workflows/lambda-deploy.yml`
- `.github/workflows/promotion.yml`

**Tasks**:
1. Document pre-deployment checklist
2. Document DEV deployment steps
3. Document SIT promotion process
4. Document PROD promotion process
5. Document post-deployment verification
6. Document environment-specific configurations

**Output Requirements**:
- Create: `docs/runbooks/deployment_runbook.md`

**Runbook Structure**:
```markdown
# Deployment Runbook - Site Builder Generation API

## Document Information
| Field | Value |
|-------|-------|
| Version | 1.0 |
| Last Updated | 2026-01-XX |
| Owner | DevOps Team |
| Review Frequency | Monthly |

---

## 1. Overview

This runbook provides step-by-step procedures for deploying the Site Builder Generation API to DEV, SIT, and PROD environments.

### 1.1 Service Components
- 7 Lambda functions (page_generator, logo_creator, etc.)
- API Gateway REST API
- DynamoDB tables (2)
- S3 buckets (2)

### 1.2 Environment URLs
| Environment | API URL | Region |
|-------------|---------|--------|
| DEV | https://api.dev.kimmyai.io | eu-west-1 |
| SIT | https://api.sit.kimmyai.io | eu-west-1 |
| PROD | https://api.kimmyai.io | af-south-1 |

---

## 2. Pre-Deployment Checklist

### 2.1 Code Readiness
- [ ] All unit tests passing (>= 80% coverage)
- [ ] Code review approved
- [ ] Integration tests passing
- [ ] No critical security vulnerabilities

### 2.2 Infrastructure Readiness
- [ ] Terraform plan reviewed
- [ ] No destructive changes without approval
- [ ] IAM permissions verified

### 2.3 Approvals
- [ ] Tech Lead approval (DEV)
- [ ] Tech Lead + DevOps Lead (SIT)
- [ ] Tech Lead + DevOps Lead + Product Owner (PROD)

---

## 3. DEV Deployment

### 3.1 Automated Deployment (Preferred)

**Trigger**: Push to `main` branch or manual workflow dispatch

```bash
# Via GitHub Actions UI
1. Navigate to Actions > Lambda Deployment
2. Click "Run workflow"
3. Select environment: dev
4. Click "Run workflow"
```

### 3.2 Manual Deployment (Emergency)

```bash
# 1. Configure AWS credentials
aws configure --profile dev

# 2. Navigate to terraform directory
cd terraform/environments/dev

# 3. Initialize Terraform
terraform init

# 4. Plan changes
terraform plan -out=tfplan

# 5. Apply changes (after review)
terraform apply tfplan

# 6. Deploy Lambda functions
cd ../../../src/lambdas
for fn in page_generator logo_creator background_creator theme_selector layout_agent brand_validator generation_state; do
  cd $fn
  pip install -r requirements.txt -t .
  zip -r ${fn}.zip .
  aws lambda update-function-code \
    --function-name ${fn}-dev \
    --zip-file fileb://${fn}.zip \
    --profile dev
  cd ..
done
```

### 3.3 Verification

```bash
# Test Lambda functions
aws lambda invoke --function-name page_generator-dev --payload '{"test":true}' response.json

# Check CloudWatch logs
aws logs tail /aws/lambda/page_generator-dev --follow

# Test API endpoint
curl -X POST https://api.dev.kimmyai.io/v1/sites/test/generation \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{"prompt": "test"}'
```

---

## 4. SIT Promotion

### 4.1 Prerequisites
- [ ] DEV deployment successful
- [ ] DEV integration tests passing
- [ ] Change request approved

### 4.2 Promotion Steps

```bash
# Via GitHub Actions
1. Navigate to Actions > Environment Promotion
2. Select source_environment: dev
3. Select target_environment: sit
4. Click "Run workflow"
5. Wait for approval (DevOps Lead required)
6. Monitor deployment
```

### 4.3 Verification

```bash
# Run integration tests against SIT
pytest tests/integration/ --env=sit

# Verify API health
curl https://api.sit.kimmyai.io/health
```

---

## 5. PROD Promotion

### 5.1 Prerequisites
- [ ] SIT deployment successful
- [ ] SIT integration tests passing
- [ ] UAT sign-off obtained
- [ ] Change request approved
- [ ] Rollback plan documented
- [ ] On-call team notified

### 5.2 Promotion Steps

```bash
# Via GitHub Actions
1. Navigate to Actions > Environment Promotion
2. Select source_environment: sit
3. Select target_environment: prod
4. Click "Run workflow"
5. Wait for approval:
   - Tech Lead approval
   - DevOps Lead approval
   - Product Owner approval
6. Monitor deployment closely
```

### 5.3 Verification

```bash
# Run smoke tests
pytest tests/smoke/ --env=prod

# Verify API health
curl https://api.kimmyai.io/health

# Monitor CloudWatch dashboard
# Dashboard: site-builder-generation-api-prod
```

### 5.4 Post-Deployment
- [ ] Verify CloudWatch metrics normal
- [ ] Verify no error alarms
- [ ] Update deployment log
- [ ] Notify stakeholders

---

## 6. Contacts

| Role | Name | Contact |
|------|------|---------|
| DevOps Lead | TBD | tbd@example.com |
| Tech Lead | TBD | tbd@example.com |
| On-Call | TBD | tbd@example.com |

---

## 7. Related Documents
- [Rollback Runbook](./rollback_runbook.md)
- [Troubleshooting Runbook](./troubleshooting_runbook.md)
- [API Documentation](./api_documentation.md)
```

**Success Criteria**:
- Complete deployment steps for all environments
- Pre-deployment checklists included
- Verification steps documented
- Emergency procedures included

---

### Worker 2: Troubleshooting Runbook

**Objective**: Create troubleshooting guide for common issues with the Generation API.

**Input Files**:
- `terraform/modules/monitoring/main.tf`
- `src/lambdas/` (Lambda function code)

**Tasks**:
1. Document common error scenarios
2. Document CloudWatch log analysis
3. Document Lambda troubleshooting
4. Document DynamoDB troubleshooting
5. Document Bedrock troubleshooting
6. Document escalation procedures

**Output Requirements**:
- Create: `docs/runbooks/troubleshooting_runbook.md`

**Runbook Structure**:
```markdown
# Troubleshooting Runbook - Site Builder Generation API

## Document Information
| Field | Value |
|-------|-------|
| Version | 1.0 |
| Last Updated | 2026-01-XX |
| Owner | DevOps Team |

---

## 1. Quick Reference

### 1.1 Key CloudWatch Log Groups
| Service | Log Group |
|---------|-----------|
| Page Generator | /aws/lambda/page_generator-{env} |
| Logo Creator | /aws/lambda/logo_creator-{env} |
| Brand Validator | /aws/lambda/brand_validator-{env} |
| API Gateway | /aws/apigateway/site-builder-{env} |

### 1.2 Key Metrics
| Metric | Alarm Threshold | Action |
|--------|-----------------|--------|
| Lambda Errors | > 5 in 5 min | Check logs, escalate |
| Lambda Duration | > 55s | Check Bedrock latency |
| DynamoDB Throttle | > 0 | Check capacity |
| 5XX Errors | > 10 in 1 min | Check Lambda health |

---

## 2. Common Issues

### 2.1 Generation Timeout (TTLT > 60s)

**Symptoms**:
- Users report page generation "stuck"
- CloudWatch shows Lambda duration > 55s
- SSE stream stops without completion

**Diagnosis**:
```bash
# Check Lambda duration
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=page_generator-{env} \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Average Maximum

# Check Bedrock latency
aws logs filter-log-events \
  --log-group-name /aws/lambda/page_generator-{env} \
  --filter-pattern "bedrock invoke" \
  --start-time $(date -u -d '1 hour ago' +%s)000
```

**Resolution**:
1. If Bedrock is slow: Monitor Bedrock service status
2. If prompt is too complex: Suggest simpler prompt to user
3. If consistent: Increase Lambda timeout or optimize prompt

---

### 2.2 Brand Score Always Low

**Symptoms**:
- Users report brand scores < 8.0 consistently
- Validation failures blocking deployment

**Diagnosis**:
```bash
# Check recent brand scores
aws logs filter-log-events \
  --log-group-name /aws/lambda/brand_validator-{env} \
  --filter-pattern "brandScore" \
  --limit 50
```

**Resolution**:
1. Check if brand assets are configured correctly
2. Verify color palette matches brand guidelines
3. Check if templates have been updated recently
4. Review scoring algorithm weights

---

### 2.3 Image Generation Fails (Logo/Background)

**Symptoms**:
- Logo/background generation returns error
- S3 upload fails
- Empty image URLs returned

**Diagnosis**:
```bash
# Check Stable Diffusion errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/logo_creator-{env} \
  --filter-pattern "ERROR" \
  --start-time $(date -u -d '1 hour ago' +%s)000

# Check S3 upload errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/logo_creator-{env} \
  --filter-pattern "s3 upload" \
  --limit 20
```

**Resolution**:
1. If Bedrock error: Check model availability
2. If S3 error: Check IAM permissions
3. If content policy: Prompt may violate content policy

---

### 2.4 SSE Stream Disconnects

**Symptoms**:
- Frontend shows "connection lost"
- Partial generation received
- No completion event

**Diagnosis**:
```bash
# Check API Gateway logs
aws logs filter-log-events \
  --log-group-name /aws/apigateway/site-builder-{env} \
  --filter-pattern "disconnect" \
  --start-time $(date -u -d '1 hour ago' +%s)000

# Check Lambda invocation errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/page_generator-{env} \
  --filter-pattern "Task timed out" \
  --limit 20
```

**Resolution**:
1. If timeout: Increase Lambda timeout
2. If network: Check CloudFront/WAF rules
3. If client: Check frontend reconnection logic

---

### 2.5 DynamoDB Throttling

**Symptoms**:
- CloudWatch alarm: DynamoDB throttle
- State management fails
- Generation status not updating

**Diagnosis**:
```bash
# Check throttle events
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ThrottledRequests \
  --dimensions Name=TableName,Value=site-builder-generation-{env} \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum
```

**Resolution**:
1. DynamoDB is on-demand - throttling should be rare
2. If consistent throttling: Check for hot partitions
3. Review access patterns for inefficient queries

---

## 3. Escalation Procedures

### 3.1 Escalation Matrix
| Severity | Response Time | Escalation To |
|----------|---------------|---------------|
| Critical (PROD down) | 15 min | On-Call + Tech Lead |
| High (Feature broken) | 1 hour | DevOps Lead |
| Medium (Degraded) | 4 hours | DevOps Team |
| Low (Minor issue) | 24 hours | Support Queue |

### 3.2 Contact Information
| Role | Contact |
|------|---------|
| On-Call | [PagerDuty] |
| DevOps Lead | tbd@example.com |
| Tech Lead | tbd@example.com |

---

## 4. Useful Commands

```bash
# View recent Lambda errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/{function}-{env} \
  --filter-pattern "ERROR" \
  --start-time $(date -u -d '1 hour ago' +%s)000

# Test Lambda invocation
aws lambda invoke \
  --function-name {function}-{env} \
  --payload '{"test": true}' \
  response.json

# View DynamoDB table
aws dynamodb scan \
  --table-name site-builder-generation-{env} \
  --limit 10

# List S3 objects
aws s3 ls s3://site-builder-assets-{env}/ --recursive
```
```

**Success Criteria**:
- Common issues documented
- Diagnosis steps clear
- Resolution steps actionable
- Escalation procedures defined

---

### Worker 3: Rollback Runbook

**Objective**: Create rollback procedures runbook for emergency recovery.

**Input Files**:
- `.github/workflows/rollback.yml`
- `terraform/` (Terraform configurations)

**Tasks**:
1. Document rollback decision criteria
2. Document Lambda rollback steps
3. Document Terraform rollback steps
4. Document DynamoDB recovery
5. Document verification steps
6. Document post-rollback actions

**Output Requirements**:
- Create: `docs/runbooks/rollback_runbook.md`

**Runbook Structure**:
```markdown
# Rollback Runbook - Site Builder Generation API

## Document Information
| Field | Value |
|-------|-------|
| Version | 1.0 |
| Last Updated | 2026-01-XX |
| Owner | DevOps Team |

---

## 1. When to Rollback

### 1.1 Rollback Triggers
- [ ] Production error rate > 10%
- [ ] Critical functionality broken
- [ ] Security vulnerability discovered
- [ ] Performance degradation > 50%

### 1.2 Decision Authority
| Environment | Authority |
|-------------|-----------|
| DEV | Developer |
| SIT | DevOps Lead |
| PROD | Tech Lead + DevOps Lead |

---

## 2. Rollback Options

### 2.1 Lambda Only
- Rolls back Lambda function code
- Keeps infrastructure unchanged
- Fastest rollback option

### 2.2 Terraform Only
- Rolls back infrastructure changes
- Keeps Lambda code unchanged
- Use for infrastructure issues

### 2.3 Full Rollback
- Rolls back both Lambda and Terraform
- Complete reversion
- Use for major issues

---

## 3. Lambda Rollback Procedure

### 3.1 Automated Rollback (Preferred)

```bash
# Via GitHub Actions
1. Navigate to Actions > Rollback
2. Select environment: {env}
3. Select rollback_type: lambda_only
4. Select function: {function_name} or "all"
5. Select target_version: "previous" or specific version
6. Click "Run workflow"
7. Monitor rollback progress
```

### 3.2 Manual Rollback

```bash
# 1. List available versions
aws lambda list-versions-by-function \
  --function-name {function}-{env} \
  --query 'Versions[*].[Version,Description]'

# 2. Update alias to previous version
aws lambda update-alias \
  --function-name {function}-{env} \
  --name live \
  --function-version {previous_version}

# 3. Verify rollback
aws lambda invoke \
  --function-name {function}-{env}:live \
  --payload '{"test": true}' \
  response.json
```

---

## 4. Terraform Rollback Procedure

### 4.1 Automated Rollback

```bash
# Via GitHub Actions
1. Navigate to Actions > Rollback
2. Select environment: {env}
3. Select rollback_type: terraform_only
4. Click "Run workflow"
5. Wait for approval (if required)
6. Monitor rollback progress
```

### 4.2 Manual Rollback

```bash
# 1. Navigate to terraform directory
cd terraform/environments/{env}

# 2. Check out previous commit
git log --oneline -10
git checkout {previous_commit}

# 3. Initialize Terraform
terraform init

# 4. Plan rollback
terraform plan

# 5. Apply rollback
terraform apply
```

---

## 5. DynamoDB Recovery

### 5.1 Point-in-Time Recovery

```bash
# Restore table to specific point in time
aws dynamodb restore-table-to-point-in-time \
  --source-table-name site-builder-generation-{env} \
  --target-table-name site-builder-generation-{env}-restored \
  --use-latest-restorable-time

# OR restore to specific time
aws dynamodb restore-table-to-point-in-time \
  --source-table-name site-builder-generation-{env} \
  --target-table-name site-builder-generation-{env}-restored \
  --restore-date-time 2026-01-15T10:00:00Z
```

---

## 6. Post-Rollback Verification

```bash
# 1. Test API health
curl https://api.{env}.kimmyai.io/health

# 2. Run smoke tests
pytest tests/smoke/ --env={env}

# 3. Check CloudWatch for errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/page_generator-{env} \
  --filter-pattern "ERROR" \
  --start-time $(date -u -d '10 minutes ago' +%s)000

# 4. Monitor CloudWatch dashboard
# Dashboard: site-builder-generation-api-{env}
```

---

## 7. Post-Rollback Actions

- [ ] Document rollback reason
- [ ] Create incident report
- [ ] Notify stakeholders
- [ ] Schedule post-mortem
- [ ] Plan fix and re-deployment
```

**Success Criteria**:
- Clear rollback criteria
- Step-by-step procedures
- Both automated and manual options
- Verification steps included

---

### Worker 4: API Documentation

**Objective**: Create comprehensive API documentation for developers and consumers.

**Input Files**:
- `openapi/generation-api.yaml`
- `openapi/agents-api.yaml`
- `openapi/validation-api.yaml`

**Tasks**:
1. Document API overview
2. Document authentication
3. Document all endpoints with examples
4. Document error codes
5. Document rate limits
6. Document SDKs/code samples

**Output Requirements**:
- Create: `docs/api_documentation.md`

**Documentation Structure**:
```markdown
# API Documentation - Site Builder Generation API

## Overview

The Site Builder Generation API provides AI-powered landing page generation capabilities using AWS Bedrock (Claude Sonnet 4.5 and Stable Diffusion XL).

### Base URLs

| Environment | Base URL |
|-------------|----------|
| DEV | https://api.dev.kimmyai.io/v1 |
| SIT | https://api.sit.kimmyai.io/v1 |
| PROD | https://api.kimmyai.io/v1 |

---

## Authentication

All API requests require JWT authentication via Cognito.

### Headers

```
Authorization: Bearer {jwt_token}
X-Tenant-Id: {tenant_id}
Content-Type: application/json
```

### Obtaining a Token

```bash
# Via AWS Cognito
aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id {client_id} \
  --auth-parameters USERNAME={email},PASSWORD={password}
```

---

## Endpoints

### Page Generation

#### POST /sites/{tenant_id}/generation

Generate a landing page with streaming response.

**Request**:
```json
{
  "prompt": "Create a summer sale landing page with hero section and product grid",
  "templateId": "ecommerce-sale",
  "brandAssets": {
    "primaryColor": "#0066CC",
    "secondaryColor": "#FF6600",
    "logo": "s3://assets/logo.png"
  }
}
```

**Response (SSE Stream)**:
```
data: {"type": "progress", "progress": 0, "message": "Starting generation..."}
data: {"type": "chunk", "content": "<!DOCTYPE html>..."}
data: {"type": "chunk", "content": "<head>..."}
...
data: {"type": "complete", "generationId": "gen-123", "brandScore": 8.5}
```

**cURL Example**:
```bash
curl -X POST \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "X-Tenant-Id: my-tenant" \
  -H "Accept: text/event-stream" \
  "https://api.dev.kimmyai.io/v1/sites/my-tenant/generation" \
  -d '{"prompt": "Create a landing page"}'
```

---

### Logo Generation

#### POST /agents/logo

Generate logo options using Stable Diffusion XL.

**Request**:
```json
{
  "prompt": "Modern tech company logo with abstract shapes",
  "style": "modern",
  "colors": ["#0066CC", "#FFFFFF"],
  "count": 4
}
```

**Response**:
```json
{
  "type": "logo",
  "results": [
    {
      "id": "logo-1",
      "url": "https://cdn.../logo-1.png",
      "preview": "data:image/png;base64,..."
    }
  ]
}
```

---

### Brand Validation

#### GET /sites/{site_id}/validate

Validate brand compliance and security.

**Response**:
```json
{
  "brandScore": 8.5,
  "securityPassed": true,
  "performanceMs": 1200,
  "accessibilityPassed": true,
  "issues": [
    {
      "category": "brand",
      "severity": "warning",
      "message": "Secondary color contrast is 4.2:1",
      "suggestion": "Increase contrast to 4.5:1 for WCAG AA"
    }
  ]
}
```

---

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| VALIDATION_ERROR | 400 | Invalid request payload |
| UNAUTHORIZED | 401 | Invalid or missing JWT token |
| FORBIDDEN | 403 | Insufficient permissions |
| NOT_FOUND | 404 | Resource not found |
| RATE_LIMITED | 429 | Too many requests |
| GENERATION_FAILED | 500 | AI generation error |
| SERVICE_UNAVAILABLE | 503 | Bedrock service unavailable |

---

## Rate Limits

| Endpoint | Limit |
|----------|-------|
| Generation | 10 req/min per tenant |
| Agents | 20 req/min per tenant |
| Validation | 60 req/min per tenant |

---

## Code Samples

### Python

```python
import httpx

async def generate_page(prompt: str, token: str, tenant_id: str):
    async with httpx.AsyncClient() as client:
        async with client.stream(
            "POST",
            "https://api.dev.kimmyai.io/v1/sites/{tenant_id}/generation",
            json={"prompt": prompt},
            headers={
                "Authorization": f"Bearer {token}",
                "X-Tenant-Id": tenant_id,
                "Accept": "text/event-stream"
            }
        ) as response:
            async for line in response.aiter_lines():
                if line.startswith("data:"):
                    print(line)
```

### JavaScript

```javascript
async function generatePage(prompt, token, tenantId) {
  const response = await fetch(
    `https://api.dev.kimmyai.io/v1/sites/${tenantId}/generation`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'X-Tenant-Id': tenantId,
        'Accept': 'text/event-stream'
      },
      body: JSON.stringify({ prompt })
    }
  );

  const reader = response.body.getReader();
  const decoder = new TextDecoder();

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    console.log(decoder.decode(value));
  }
}
```
```

**Success Criteria**:
- All endpoints documented
- Request/response examples provided
- Error codes documented
- Code samples in multiple languages

---

## Stage Completion Criteria

The stage is considered **COMPLETE** when:

1. All 4 workers have completed their outputs
2. Deployment runbook created
3. Troubleshooting runbook created
4. Rollback runbook created
5. API documentation complete
6. Documentation reviewed for accuracy

---

## Approval Gate (Gate 5)

**After this stage**: Gate 5 approval required (Final approval)

**Approvers**:
- Product Owner
- Tech Lead
- Operations Lead

**Approval Criteria**:
- All documentation complete
- Runbooks actionable
- API documentation accurate
- Project ready for handover

---

**Stage Owner**: Agentic Project Manager
**Created**: 2026-01-15
**Next Action**: Wait for Stage 7 completion
