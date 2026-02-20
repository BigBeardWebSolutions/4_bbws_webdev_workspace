# RB-001: Tenant Provisioning Runbook

**Version:** 1.0
**Last Updated:** 2026-01-18
**Owner:** Platform Operations
**Severity Classification:** P2 (High)

---

## 1. Purpose

This runbook provides step-by-step instructions for troubleshooting and resolving tenant provisioning failures in the Site Builder platform.

---

## 2. Prerequisites

### 2.1 Access Required
- [ ] AWS Console access (eu-west-1)
- [ ] DynamoDB read/write access
- [ ] CloudWatch Logs access
- [ ] Cognito User Pool admin access
- [ ] SES/Email service access

### 2.2 Tools Required
```bash
# AWS CLI configured
aws --version

# jq for JSON parsing
jq --version
```

---

## 3. Identifying the Issue

### 3.1 Symptoms
| Symptom | Likely Cause |
|---------|-------------|
| User cannot login after purchase | Provisioning incomplete |
| "Account not found" error | Cognito user not created |
| "Tenant not found" error | DynamoDB record missing |
| No welcome email received | SES delivery failed |

### 3.2 Quick Diagnosis
```bash
# Check if tenant exists
aws dynamodb get-item \
  --table-name tenants \
  --key '{"tenant_id": {"S": "ten_XXXXX"}}' \
  --region eu-west-1

# Check if user exists in Cognito
aws cognito-idp admin-get-user \
  --user-pool-id eu-west-1_XXXXX \
  --username "user@example.com" \
  --region eu-west-1

# Check provisioning Lambda logs
aws logs filter-log-events \
  --log-group-name "/aws/lambda/site-builder-dev-provisioning" \
  --filter-pattern "ERROR" \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --region eu-west-1
```

---

## 4. Resolution Procedures

### 4.1 Scenario: Provisioning Lambda Failed

**Symptoms:** Payment confirmed but no tenant record exists

**Steps:**
1. Find the transaction ID from support ticket or PayFast
2. Search CloudWatch Logs for the transaction:
   ```bash
   aws logs filter-log-events \
     --log-group-name "/aws/lambda/site-builder-dev-itn-handler" \
     --filter-pattern "TXN-123456" \
     --region eu-west-1
   ```
3. Check for errors in the provisioning Lambda:
   ```bash
   aws logs filter-log-events \
     --log-group-name "/aws/lambda/site-builder-dev-provisioning" \
     --filter-pattern "TXN-123456" \
     --region eu-west-1
   ```
4. If provisioning never triggered, check SQS DLQ:
   ```bash
   aws sqs receive-message \
     --queue-url https://sqs.eu-west-1.amazonaws.com/ACCOUNT/provisioning-dlq \
     --region eu-west-1
   ```

**Resolution:**
```bash
# Manually trigger provisioning (if ITN data available)
aws lambda invoke \
  --function-name site-builder-dev-provisioning \
  --payload '{"transactionId":"TXN-123456","email":"user@example.com","plan":"professional"}' \
  --region eu-west-1 \
  response.json

cat response.json
```

---

### 4.2 Scenario: Cognito User Creation Failed

**Symptoms:** Tenant record exists but user cannot login

**Steps:**
1. Verify tenant record exists:
   ```bash
   aws dynamodb get-item \
     --table-name tenants \
     --key '{"tenant_id": {"S": "ten_XXXXX"}}' \
     --region eu-west-1 | jq '.Item'
   ```
2. Check if Cognito user exists:
   ```bash
   aws cognito-idp admin-get-user \
     --user-pool-id eu-west-1_XXXXX \
     --username "user@example.com" \
     --region eu-west-1
   ```

**Resolution (Create missing user):**
```bash
# Create Cognito user
aws cognito-idp admin-create-user \
  --user-pool-id eu-west-1_XXXXX \
  --username "user@example.com" \
  --user-attributes \
    Name=email,Value="user@example.com" \
    Name=email_verified,Value=true \
    Name=custom:tenant_id,Value="ten_XXXXX" \
    Name=custom:roles,Value="tenant_admin" \
  --temporary-password "TempPass123!" \
  --message-action SUPPRESS \
  --region eu-west-1

# Create users table record
aws dynamodb put-item \
  --table-name users \
  --item '{
    "user_id": {"S": "user_XXXXX"},
    "tenant_id": {"S": "ten_XXXXX"},
    "email": {"S": "user@example.com"},
    "role": {"S": "tenant_admin"},
    "status": {"S": "active"},
    "created_at": {"S": "2026-01-18T00:00:00Z"}
  }' \
  --region eu-west-1

# Send password reset email
aws cognito-idp admin-reset-user-password \
  --user-pool-id eu-west-1_XXXXX \
  --username "user@example.com" \
  --region eu-west-1
```

---

### 4.3 Scenario: DynamoDB Write Failed

**Symptoms:** Cognito user exists but tenant record missing

**Steps:**
1. Check DynamoDB capacity/throttling:
   ```bash
   aws cloudwatch get-metric-statistics \
     --namespace AWS/DynamoDB \
     --metric-name ThrottledRequests \
     --dimensions Name=TableName,Value=tenants \
     --start-time $(date -d '1 hour ago' -u +%Y-%m-%dT%H:%M:%SZ) \
     --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
     --period 300 \
     --statistics Sum \
     --region eu-west-1
   ```

**Resolution (Create tenant record manually):**
```bash
# Get user's Cognito sub
COGNITO_SUB=$(aws cognito-idp admin-get-user \
  --user-pool-id eu-west-1_XXXXX \
  --username "user@example.com" \
  --query 'UserAttributes[?Name==`sub`].Value' \
  --output text \
  --region eu-west-1)

# Create tenant record
aws dynamodb put-item \
  --table-name tenants \
  --item '{
    "tenant_id": {"S": "ten_NEWID"},
    "owner_user_id": {"S": "'$COGNITO_SUB'"},
    "name": {"S": "User Tenant"},
    "plan": {"S": "professional"},
    "status": {"S": "active"},
    "limits": {"M": {
      "max_sites": {"N": "5"},
      "max_generations_per_month": {"N": "100"},
      "max_storage_mb": {"N": "500"},
      "custom_domain_allowed": {"BOOL": true}
    }},
    "usage": {"M": {
      "sites_count": {"N": "0"},
      "generations_this_month": {"N": "0"},
      "storage_used_mb": {"N": "0"}
    }},
    "storage_prefix": {"S": "tenants/ten_NEWID"},
    "billing": {"M": {
      "transaction_id": {"S": "TXN-123456"},
      "invoice_number": {"S": "INV-123456"}
    }},
    "created_at": {"S": "2026-01-18T00:00:00Z"},
    "updated_at": {"S": "2026-01-18T00:00:00Z"}
  }' \
  --region eu-west-1

# Update Cognito user with tenant_id
aws cognito-idp admin-update-user-attributes \
  --user-pool-id eu-west-1_XXXXX \
  --username "user@example.com" \
  --user-attributes Name=custom:tenant_id,Value=ten_NEWID \
  --region eu-west-1
```

---

### 4.4 Scenario: Welcome Email Not Received

**Symptoms:** User provisioned but didn't receive welcome email

**Steps:**
1. Check SES sending statistics:
   ```bash
   aws ses get-send-statistics --region eu-west-1
   ```
2. Check SES bounce/complaint notifications
3. Verify email address is valid

**Resolution:**
```bash
# Resend welcome email manually
aws ses send-email \
  --from "noreply@kimmyai.io" \
  --to "user@example.com" \
  --subject "Welcome to Site Builder" \
  --html "Your account is ready. Login at https://dev.kimmyai.io/auth/login" \
  --region eu-west-1

# Or reset password to trigger Cognito email
aws cognito-idp admin-reset-user-password \
  --user-pool-id eu-west-1_XXXXX \
  --username "user@example.com" \
  --region eu-west-1
```

---

## 5. Verification Steps

After any resolution, verify:

```bash
# 1. Tenant record exists and is active
aws dynamodb get-item \
  --table-name tenants \
  --key '{"tenant_id": {"S": "ten_XXXXX"}}' \
  --region eu-west-1 | jq '.Item.status.S'

# 2. User can authenticate
aws cognito-idp admin-initiate-auth \
  --user-pool-id eu-west-1_XXXXX \
  --client-id XXXXXXX \
  --auth-flow ADMIN_NO_SRP_AUTH \
  --auth-parameters USERNAME=user@example.com,PASSWORD=TempPass123! \
  --region eu-west-1

# 3. User has correct tenant_id in claims
# (Check JWT token claims after login)

# 4. Ask user to login and confirm access
```

---

## 6. Escalation

| Condition | Escalate To | Contact |
|-----------|------------|---------|
| Multiple failures (>3) | Engineering Lead | Slack #platform-alerts |
| Payment-related issue | Finance Team | finance@company.com |
| Security concern | Security Team | security@company.com |
| Cannot resolve in 1 hour | On-call Manager | PagerDuty |

---

## 7. Prevention

- Monitor provisioning Lambda error rate
- Alert on DLQ message count > 0
- Weekly audit of failed provisioning attempts
- Automated retry mechanism with exponential backoff

---

## 8. Related Documents

| Document | Link |
|----------|------|
| BP-001 | /business_process/BP-001_Tenant_Provisioning.md |
| SOP-001 | /SOPs/SOP-001_New_Tenant_Onboarding.md |
