# CloudFront Basic Auth Password Update

**Version:** 1.0
**Last Updated:** 2025-12-24
**Owner:** DevOps Team
**Applies To:** SIT, PROD environments

---

## Overview

This runbook provides instructions for updating the Basic Auth password used by CloudFront to protect WordPress sites in SIT and PROD environments.

## When to Use This Runbook

- Initial deployment shows "REPLACE_VIA_SECRETS" placeholder
- Password rotation (security policy)
- Suspected password compromise
- Basic Auth returning HTTP 401 with correct credentials

---

## Prerequisites

- AWS CLI configured with appropriate profile
- Access to CloudFront in the target environment
- jq installed for JSON processing

---

## Procedure

### Step 1: Generate Secure Password

```bash
# Generate 20-character random password (alphanumeric only)
NEW_PASSWORD=$(openssl rand -base64 16 | tr -d '/+=' | head -c 20)
echo "Generated password: $NEW_PASSWORD"

# IMPORTANT: Save this password securely!
# Store in: AWS Secrets Manager, password vault, or secure note
```

### Step 2: Create Updated CloudFront Function

```bash
# Set environment
ENVIRONMENT="sit"  # or "prod"

# Create base64-encoded Basic Auth header
BASIC_AUTH_HEADER=$(echo -n "bbws-${ENVIRONMENT}:${NEW_PASSWORD}" | base64)
echo "Basic Auth header: Basic ${BASIC_AUTH_HEADER}"

# Create updated function code
cat > /tmp/wp${ENVIRONMENT}-basic-auth-updated.js << EOF
function handler(event) {
    var request = event.request;
    var headers = request.headers;

    var authString = "Basic ${BASIC_AUTH_HEADER}";

    if (typeof headers.authorization === "undefined" || headers.authorization.value !== authString) {
        return {
            statusCode: 401,
            statusDescription: "Unauthorized",
            headers: {
                "www-authenticate": { value: "Basic realm=\\"BBWS WordPress ${ENVIRONMENT^^}\\"" }
            }
        };
    }

    return request;
}
EOF

# Review function code
cat /tmp/wp${ENVIRONMENT}-basic-auth-updated.js
```

### Step 3: Get Current Function ETag

```bash
# Get current ETag (required for update)
CURRENT_ETAG=$(aws cloudfront describe-function \
  --region us-east-1 \
  --name wp${ENVIRONMENT}-basic-auth \
  --query 'ETag' \
  --output text)

echo "Current ETag: $CURRENT_ETAG"
```

### Step 4: Update CloudFront Function

```bash
# Update function code
aws cloudfront update-function \
  --region us-east-1 \
  --name wp${ENVIRONMENT}-basic-auth \
  --function-config '{"Comment":"Basic Auth for '${ENVIRONMENT}' environment - Updated '$(date +%Y-%m-%d)'","Runtime":"cloudfront-js-2.0"}' \
  --function-code fileb:///tmp/wp${ENVIRONMENT}-basic-auth-updated.js \
  --if-match $CURRENT_ETAG

# Get new ETag
NEW_ETAG=$(aws cloudfront describe-function \
  --region us-east-1 \
  --name wp${ENVIRONMENT}-basic-auth \
  --query 'ETag' \
  --output text)

echo "New ETag: $NEW_ETAG"
```

### Step 5: Publish Function to LIVE

```bash
# Publish to LIVE stage
aws cloudfront publish-function \
  --region us-east-1 \
  --name wp${ENVIRONMENT}-basic-auth \
  --if-match $NEW_ETAG

# Monitor publish status
aws cloudfront describe-function \
  --region us-east-1 \
  --name wp${ENVIRONMENT}-basic-auth \
  --stage LIVE \
  --query 'FunctionSummary.Status' \
  --output text
```

**Expected Output:** `IN_PROGRESS` then `DEPLOYED` (wait ~30 seconds)

### Step 6: Wait for CloudFront Propagation

```bash
# CloudFront edge locations take time to update
echo "Waiting for CloudFront propagation (30-60 seconds)..."
sleep 45
```

### Step 7: Test New Password

```bash
# Get a test tenant URL
TEST_TENANT="goldencrust"  # or any deployed tenant

# Test with new password
curl -I -u "bbws-${ENVIRONMENT}:${NEW_PASSWORD}" \
  https://${TEST_TENANT}.wp${ENVIRONMENT}.kimmyai.io/

# Expected: HTTP/2 302 (redirect to WordPress)
# If HTTP/2 401: Password not updated yet or incorrect
```

### Step 8: Store Password Securely

#### Option A: AWS Secrets Manager (Recommended)

```bash
# Store in Secrets Manager
aws secretsmanager create-secret \
  --region eu-west-1 \
  --name ${ENVIRONMENT}-cloudfront-basic-auth \
  --description "CloudFront Basic Auth credentials for ${ENVIRONMENT} environment" \
  --secret-string "{\"username\":\"bbws-${ENVIRONMENT}\",\"password\":\"${NEW_PASSWORD}\"}" \
  --tags '[{"Key":"Environment","Value":"'${ENVIRONMENT}'"},{"Key":"Purpose","Value":"CloudFront Basic Auth"}]'

# Or update if already exists
aws secretsmanager update-secret \
  --region eu-west-1 \
  --secret-id ${ENVIRONMENT}-cloudfront-basic-auth \
  --secret-string "{\"username\":\"bbws-${ENVIRONMENT}\",\"password\":\"${NEW_PASSWORD}\"}"
```

#### Option B: Document in Secure Location

Create entry in password vault or secure document:

```
Environment: ${ENVIRONMENT}
Service: CloudFront Basic Auth
Username: bbws-${ENVIRONMENT}
Password: ${NEW_PASSWORD}
Updated: $(date)
Updated By: $(whoami)
CloudFront Function: wp${ENVIRONMENT}-basic-auth
```

### Step 9: Update Documentation

Update tenant access documentation with new password:

```bash
# Update access documentation
sed -i '' "s/Password: .*/Password: ${NEW_PASSWORD}/" \
  /path/to/${ENVIRONMENT}-access-credentials.md
```

### Step 10: Notify Team

Send notification to team:

```
Subject: CloudFront Basic Auth Password Updated - ${ENVIRONMENT}

The CloudFront Basic Auth password for the ${ENVIRONMENT} environment has been updated.

New Credentials:
- Username: bbws-${ENVIRONMENT}
- Password: [See Secrets Manager: ${ENVIRONMENT}-cloudfront-basic-auth]

Updated: $(date)
Updated By: [Your Name]

All WordPress sites in ${ENVIRONMENT} now require the new password for HTTPS access.

Test: curl -u "bbws-${ENVIRONMENT}:NEW_PASSWORD" https://goldencrust.wp${ENVIRONMENT}.kimmyai.io/
```

---

## Verification Checklist

- [ ] Password generated and saved securely
- [ ] CloudFront function updated
- [ ] Function published to LIVE
- [ ] CloudFront propagation complete (45+ seconds)
- [ ] New password tested successfully
- [ ] Old password no longer works
- [ ] Password stored in Secrets Manager
- [ ] Documentation updated
- [ ] Team notified

---

## Troubleshooting

### Issue: HTTP 401 After Update

**Cause:** CloudFront edge locations not yet updated

**Fix:** Wait 60 seconds, test again. CloudFront has edge locations worldwide that need time to sync.

### Issue: Function Update Fails (Conflict Error)

**Cause:** ETag mismatch (function was modified since you retrieved ETag)

**Fix:**
```bash
# Get latest ETag and retry
CURRENT_ETAG=$(aws cloudfront describe-function --name wp${ENVIRONMENT}-basic-auth --query 'ETag' --output text)
# Re-run Step 4
```

### Issue: Old Password Still Works

**Cause:** Function not published to LIVE stage

**Fix:**
```bash
# Check function stage
aws cloudfront describe-function \
  --name wp${ENVIRONMENT}-basic-auth \
  --stage LIVE \
  --query 'FunctionSummary.{Name:Name,Status:Status,LastModified:LastModifiedTime}'

# If Status != "DEPLOYED", republish
NEW_ETAG=$(aws cloudfront describe-function --name wp${ENVIRONMENT}-basic-auth --query 'ETag' --output text)
aws cloudfront publish-function --name wp${ENVIRONMENT}-basic-auth --if-match $NEW_ETAG
```

---

## Rollback

### Rollback to Previous Password

```bash
# Get previous function version
aws cloudfront describe-function \
  --name wp${ENVIRONMENT}-basic-auth \
  --stage LIVE \
  /tmp/previous-function.js

# Extract previous password from function code
grep "Basic" /tmp/previous-function.js | grep -oP 'Basic \K[^"]+' | base64 -d
# Format: bbws-${ENVIRONMENT}:OLD_PASSWORD

# Use the old password and repeat Steps 2-7
```

---

## Automation (Future Enhancement)

**Recommended:** Automate password rotation using Lambda + Secrets Manager rotation:

```python
# Lambda function to rotate CloudFront Basic Auth password
def rotate_cloudfront_password(event, context):
    # 1. Generate new password
    # 2. Update CloudFront function
    # 3. Publish to LIVE
    # 4. Store in Secrets Manager
    # 5. Send SNS notification
```

---

## Security Best Practices

1. **Rotate passwords quarterly** or after any suspected compromise
2. **Use Secrets Manager** for password storage (not documentation)
3. **Audit access** to CloudFront functions regularly
4. **Monitor failed auth attempts** via CloudFront logs
5. **Never commit passwords** to Git repositories
6. **Use strong passwords** (20+ characters, alphanumeric)

---

## Related Documents

- `01-TENANT-DEPLOYMENT.md` - Main deployment runbook
- `05-TROUBLESHOOTING-GUIDE.md` - Comprehensive troubleshooting

---

**END OF RUNBOOK**
