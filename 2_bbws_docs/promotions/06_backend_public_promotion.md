# Promotion Plan: backend_public

**Project**: 2_1_bbws_backend_public
**Plan ID**: PROM-BE-PUB-006
**Created**: 2026-01-07
**Owner**: DevOps Engineer
**Status**: 📋 READY FOR EXECUTION

---

## Project Overview

| Attribute | Value |
|-----------|-------|
| **Project Type** | Infrastructure (S3 + CloudFront + Lambda@Edge) |
| **Purpose** | Serverless static website hosting with CDN for Customer Portal |
| **Current Status** | 100% complete, Production Ready |
| **Components** | S3 website bucket, CloudFront distribution, Lambda@Edge functions |
| **Lambda@Edge Functions** | 4 (security headers, URL rewrites, auth, redirects) |
| **CI/CD Workflows** | 4 (deploy-dev, promote-sit, promote-prod, terraform-validate) |
| **Wave** | Wave 2 (Infrastructure Foundation) |

---

## Environments

| Environment | AWS Account | Region | Domain | Status |
|-------------|-------------|--------|--------|--------|
| **DEV** | 536580886816 | us-east-1 (CloudFront) | `dev.kimmyai.io` | ✅ Deployed |
| **SIT** | 815856636111 | us-east-1 (CloudFront) | `sit.kimmyai.io` | ⏳ Target |
| **PROD** | 093646564004 | us-east-1 (CloudFront) | `kimmyai.io` | 🔵 Planned |

**Note**: CloudFront and Lambda@Edge MUST be deployed in us-east-1 region regardless of S3 bucket location.

---

## Promotion Timeline

```
PHASE 1: SIT PROMOTION (Jan 13, 2026)
├─ Pre-deployment  (Jan 11-12)
├─ Deployment      (Jan 13, 11:00 AM)
├─ Validation      (Jan 13, 11:30 AM - 1:00 PM)
└─ Sign-off        (Jan 13, 4:00 PM)

PHASE 2: SIT VALIDATION (Jan 14-31)
├─ Integration Testing (Jan 14-17)
├─ CDN Testing         (Jan 18-20)
├─ Lambda@Edge Testing (Jan 21-22)
├─ Security Scanning   (Jan 23-24)
└─ SIT Sign-off        (Jan 31)

PHASE 3: PROD PROMOTION (Feb 24, 2026)
├─ Pre-deployment  (Feb 20-23)
├─ Deployment      (Feb 24, 10:00 AM)
├─ Validation      (Feb 24, 11:00 AM - 2:00 PM)
└─ Sign-off        (Feb 27, 4:00 PM)
```

---

## Phase 1: SIT Promotion

### Pre-Deployment Checklist (Jan 11-12)

#### Environment Verification
- [ ] AWS SSO login to SIT account (815856636111)
- [ ] Verify AWS profile: `AWS_PROFILE=Tebogo-sit aws sts get-caller-identity`
- [ ] **CRITICAL**: Confirm region is us-east-1 (required for Lambda@Edge)
- [ ] Verify Route53 hosted zone for `sit.kimmyai.io`
- [ ] Check SSL certificate in ACM for `sit.kimmyai.io` (MUST be in us-east-1)

#### Code Preparation
- [ ] Verify latest code in `main` branch
- [ ] Confirm all Terraform validations passing in DEV
- [ ] Review GitHub Actions workflows (promote-sit.yml)
- [ ] Tag release: `v1.0.0-sit`
- [ ] Create changelog for SIT release
- [ ] Build and test Lambda@Edge functions locally

#### Infrastructure Planning
- [ ] Document components to be created:
  - S3 bucket: `bbws-frontend-sit` (website hosting)
  - CloudFront distribution with custom domain `sit.kimmyai.io`
  - Lambda@Edge functions:
    - Security headers (viewer response)
    - URL rewrites (origin request)
    - Auth validation (viewer request)
    - Redirects (viewer request)
  - CloudFront Origin Access Identity (OAI)
  - S3 bucket policy (CloudFront access only)
- [ ] **CRITICAL**: Verify S3 bucket blocks public access (CloudFront OAI only)
- [ ] Confirm CloudFront SSL/TLS certificate configured
- [ ] Plan cache behaviors and TTLs
- [ ] Document Lambda@Edge execution roles

#### Dependencies
- [ ] **CRITICAL**: DynamoDB schemas MUST be in SIT (for auth Lambda@Edge)
- [ ] **CRITICAL**: S3 schemas MUST be in SIT
- [ ] Route53 hosted zone for sit.kimmyai.io
- [ ] ACM certificate for sit.kimmyai.io in us-east-1

### Deployment Steps (Jan 13, 11:00 AM)

#### Step 1: Verify Dependencies
```bash
# Verify DynamoDB tables exist in SIT
AWS_PROFILE=Tebogo-sit aws dynamodb list-tables --region eu-west-1 | grep -E "(campaigns|orders|products|tenants|users)-sit"

# Verify S3 buckets exist in SIT
AWS_PROFILE=Tebogo-sit aws s3 ls --region eu-west-1 | grep bbws

# Verify ACM certificate in us-east-1
AWS_PROFILE=Tebogo-sit aws acm list-certificates --region us-east-1 | grep sit.kimmyai.io
```

#### Step 2: Terraform Workspace Switch
```bash
cd /Users/tebogotseka/Documents/agentic_work/2_1_bbws_backend_public/terraform
terraform workspace select sit
terraform workspace list  # Verify 'sit' is selected
```

#### Step 3: Terraform Plan
```bash
AWS_PROFILE=Tebogo-sit terraform plan -out=sit.tfplan -var="region=us-east-1"
# CRITICAL REVIEW:
# - Verify S3 bucket will be created with public access blocked
# - Confirm CloudFront distribution configuration
# - Verify Origin Access Identity (OAI) configured
# - Check S3 bucket policy (CloudFront access only)
# - Verify Lambda@Edge functions will be deployed to us-east-1
# - Confirm SSL certificate ARN correct
# - Verify cache behaviors configured
# - Check custom domain mapping (sit.kimmyai.io)
# - Verify no existing resources will be destroyed
```

#### Step 4: Manual Approval
- Review terraform plan output line by line
- Verify no data-destructive operations
- **CRITICAL**: Confirm S3 bucket blocks public access
- Verify CloudFront OAI configured correctly
- Verify Lambda@Edge IAM roles have correct permissions
- Verify SSL certificate in us-east-1
- Get approval from Tech Lead and Security Lead
- Document approval in deployment log

#### Step 5: Deploy Lambda@Edge Functions First
```bash
# Lambda@Edge must be deployed before CloudFront distribution
cd /Users/tebogotseka/Documents/agentic_work/2_1_bbws_backend_public/lambda-edge

# Deploy each function to us-east-1
for function in security-headers url-rewrite auth-validation redirects; do
  cd $function
  npm install
  npm run build
  zip -r function.zip .

  AWS_PROFILE=Tebogo-sit aws lambda create-function \
    --function-name bbws-$function-sit \
    --runtime nodejs20.x \
    --role arn:aws:iam::815856636111:role/lambda-edge-execution-role-sit \
    --handler index.handler \
    --zip-file fileb://function.zip \
    --region us-east-1 \
    --publish

  # Note the version ARN (includes version number)
  VERSION_ARN=$(AWS_PROFILE=Tebogo-sit aws lambda list-versions-by-function \
    --function-name bbws-$function-sit \
    --region us-east-1 \
    --query 'Versions[-1].FunctionArn' \
    --output text)

  echo "$function: $VERSION_ARN"
  cd ..
done
```

#### Step 6: Terraform Apply
```bash
AWS_PROFILE=Tebogo-sit terraform apply sit.tfplan
# Monitor output carefully
# Note: CloudFront distribution creation takes 15-30 minutes
# Lambda@Edge association may take additional 5-10 minutes
```

#### Step 7: Wait for CloudFront Distribution
```bash
# Get distribution ID
DIST_ID=$(AWS_PROFILE=Tebogo-sit aws cloudfront list-distributions \
  --region us-east-1 \
  --query "DistributionList.Items[?Aliases.Items[0]=='sit.kimmyai.io'].Id" \
  --output text)

echo "Distribution ID: $DIST_ID"

# Wait for distribution to deploy (15-30 minutes)
AWS_PROFILE=Tebogo-sit aws cloudfront wait distribution-deployed \
  --id $DIST_ID \
  --region us-east-1

echo "CloudFront distribution deployed!"
```

#### Step 8: Update Route53
```bash
# Get CloudFront domain name
CF_DOMAIN=$(AWS_PROFILE=Tebogo-sit aws cloudfront get-distribution \
  --id $DIST_ID \
  --region us-east-1 \
  --query 'Distribution.DomainName' \
  --output text)

# Create Route53 alias record
AWS_PROFILE=Tebogo-sit aws route53 change-resource-record-sets \
  --hosted-zone-id <sit-hosted-zone-id> \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "sit.kimmyai.io",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "'$CF_DOMAIN'",
          "EvaluateTargetHealth": false
        }
      }
    }]
  }'
```

#### Step 9: Deploy Frontend Assets
```bash
# Build frontend (assuming React/Vue/Angular app)
cd /Users/tebogotseka/Documents/agentic_work/2_1_bbws_backend_public/frontend
npm install
npm run build:sit

# Upload to S3
AWS_PROFILE=Tebogo-sit aws s3 sync ./dist/ s3://bbws-frontend-sit/ \
  --delete \
  --cache-control "public, max-age=31536000, immutable" \
  --exclude "index.html"

# Upload index.html with no-cache (for SPA routing)
AWS_PROFILE=Tebogo-sit aws s3 cp ./dist/index.html s3://bbws-frontend-sit/index.html \
  --cache-control "no-cache, no-store, must-revalidate"

# Invalidate CloudFront cache
AWS_PROFILE=Tebogo-sit aws cloudfront create-invalidation \
  --distribution-id $DIST_ID \
  --paths "/*"
```

### Post-Deployment Validation (Jan 13, 11:30 AM - 1:00 PM)

#### DNS and SSL Validation
```bash
# Test 1: DNS resolution
nslookup sit.kimmyai.io
dig sit.kimmyai.io

# Test 2: HTTPS certificate
curl -I https://sit.kimmyai.io
openssl s_client -connect sit.kimmyai.io:443 -servername sit.kimmyai.io < /dev/null

# Test 3: Verify certificate details
echo | openssl s_client -connect sit.kimmyai.io:443 -servername sit.kimmyai.io 2>/dev/null | openssl x509 -noout -dates -subject
```

#### CloudFront Validation
```bash
# Test 4: Verify CloudFront response headers
curl -I https://sit.kimmyai.io

# Expected headers from Lambda@Edge security headers:
# - X-Content-Type-Options: nosniff
# - X-Frame-Options: DENY
# - X-XSS-Protection: 1; mode=block
# - Strict-Transport-Security: max-age=31536000; includeSubDomains
# - Content-Security-Policy: default-src 'self'

# Test 5: Verify CloudFront caching
curl -I https://sit.kimmyai.io/assets/logo.png
# Should see X-Cache: Hit from cloudfront on second request

# Test 6: Check CloudFront distribution status
AWS_PROFILE=Tebogo-sit aws cloudfront get-distribution \
  --id $DIST_ID \
  --region us-east-1 \
  --query 'Distribution.Status'
```

#### Lambda@Edge Validation
```bash
# Test 7: Verify Lambda@Edge functions associated
AWS_PROFILE=Tebogo-sit aws cloudfront get-distribution-config \
  --id $DIST_ID \
  --region us-east-1 \
  --query 'DistributionConfig.DefaultCacheBehavior.LambdaFunctionAssociations'

# Test 8: Check Lambda@Edge execution logs (in us-east-1)
# Note: Lambda@Edge logs appear in CloudWatch Logs in the region closest to execution
AWS_PROFILE=Tebogo-sit aws logs describe-log-groups \
  --region us-east-1 \
  --log-group-name-prefix "/aws/lambda/us-east-1.bbws-"

# Test 9: Verify auth validation Lambda@Edge
curl -I https://sit.kimmyai.io/protected-page
# Should return 401 or 403 without valid token

# Test 10: Verify URL rewrite Lambda@Edge
curl -I https://sit.kimmyai.io/products
# Should internally rewrite to /index.html for SPA routing
```

#### S3 Bucket Validation
```bash
# Test 11: Verify S3 bucket public access blocked
AWS_PROFILE=Tebogo-sit aws s3api get-public-access-block \
  --bucket bbws-frontend-sit \
  --region eu-west-1

# Test 12: Verify S3 bucket policy (CloudFront OAI only)
AWS_PROFILE=Tebogo-sit aws s3api get-bucket-policy \
  --bucket bbws-frontend-sit \
  --region eu-west-1

# Test 13: Verify direct S3 access blocked (should fail)
curl -I https://bbws-frontend-sit.s3.amazonaws.com/index.html
# Should return 403 Forbidden
```

#### Website Validation
```bash
# Test 14: Load homepage
curl -s https://sit.kimmyai.io | head -20

# Test 15: Verify assets loading
curl -I https://sit.kimmyai.io/assets/main.js
curl -I https://sit.kimmyai.io/assets/main.css
curl -I https://sit.kimmyai.io/assets/logo.png

# Test 16: Test SPA routing (should return index.html)
curl -s https://sit.kimmyai.io/products | head -10
curl -s https://sit.kimmyai.io/orders | head -10

# Test 17: Test 404 handling
curl -I https://sit.kimmyai.io/non-existent-page
```

#### Performance Validation
```bash
# Test 18: Measure page load time
time curl -s https://sit.kimmyai.io > /dev/null

# Test 19: Verify compression (gzip/brotli)
curl -H "Accept-Encoding: gzip" -I https://sit.kimmyai.io/assets/main.js
# Should see Content-Encoding: gzip

# Test 20: Test from multiple regions
for region in us-east-1 eu-west-1 ap-southeast-1; do
  echo "Testing from $region..."
  # Use VPN or cloud shell in different regions
done
```

#### Monitoring Setup
- [ ] Enable CloudFront access logs to S3
  ```bash
  AWS_PROFILE=Tebogo-sit aws cloudfront update-distribution \
    --id $DIST_ID \
    --region us-east-1 \
    --distribution-config-with-logging file://cf-logging-config.json
  ```
- [ ] Create CloudWatch dashboard for CloudFront metrics
- [ ] Create alarms for:
  - 4xx error rate > 5%
  - 5xx error rate > 1%
  - Origin latency > 1s
  - Cache hit ratio < 80%
  - Lambda@Edge errors > 0.1%
- [ ] Enable AWS WAF (Web Application Firewall) if configured

---

## Phase 2: SIT Validation (Jan 14-31)

### Week 1: Integration Testing (Jan 14-17)
- [ ] Test frontend integration with campaigns API
- [ ] Test frontend integration with order API
- [ ] Test frontend integration with product API
- [ ] Verify API calls through CloudFront
- [ ] Test CORS policies
- [ ] Test authentication flow (Cognito integration)
- [ ] Test protected routes (Lambda@Edge auth)
- [ ] Verify session management
- [ ] Test API error handling in frontend

### Week 2: CDN Testing (Jan 18-20)
- [ ] Test cache hit ratio (target >80%)
- [ ] Test cache invalidation
- [ ] Test TTL policies for different content types
- [ ] Verify compression (gzip/brotli)
- [ ] Test regional performance (multiple regions)
- [ ] Verify origin shield (if configured)
- [ ] Test failover scenarios
- [ ] Monitor CloudFront costs

### Week 3: Lambda@Edge Testing (Jan 21-22)
- [ ] Test security headers Lambda@Edge
  - Verify X-Content-Type-Options
  - Verify X-Frame-Options
  - Verify CSP headers
  - Verify HSTS headers
- [ ] Test URL rewrite Lambda@Edge
  - Verify SPA routing works
  - Test custom rewrites
- [ ] Test auth validation Lambda@Edge
  - Test with valid token
  - Test with expired token
  - Test without token
- [ ] Test redirects Lambda@Edge
  - Test HTTP to HTTPS redirect
  - Test www to non-www redirect
- [ ] Monitor Lambda@Edge execution times
- [ ] Verify Lambda@Edge logs

### Week 4: Security Scanning (Jan 23-24)
- [ ] Run OWASP ZAP security scan
- [ ] Test XSS protection
- [ ] Test clickjacking protection
- [ ] Test HTTPS enforcement
- [ ] Verify CSP policy effectiveness
- [ ] Test for sensitive data exposure
- [ ] Verify no source maps in production
- [ ] Test AWS WAF rules (if configured)
- [ ] Penetration testing (if required)

### Week 5: Final Validation (Jan 27-31)
- [ ] Re-run all validation tests
- [ ] Performance benchmarking
- [ ] Cost analysis (CloudFront, Lambda@Edge, S3, data transfer)
- [ ] User acceptance testing (UAT)
- [ ] Cross-browser testing (Chrome, Firefox, Safari, Edge)
- [ ] Mobile responsiveness testing
- [ ] Accessibility testing (WCAG compliance)
- [ ] SIT sign-off meeting
- [ ] SIT approval gate passed

---

## Phase 3: PROD Promotion (Feb 24, 2026)

### Pre-Deployment Checklist (Feb 20-23)

#### Production Readiness
- [ ] All SIT tests passing
- [ ] SIT sign-off obtained (Gate 4)
- [ ] Performance meets SLA requirements
- [ ] Security scan clean (no high/critical issues)
- [ ] User acceptance testing completed
- [ ] Rollback procedure documented
- [ ] CloudFront invalidation strategy documented

#### PROD Environment Verification
- [ ] AWS SSO login to PROD account (093646564004)
- [ ] Verify AWS profile: `AWS_PROFILE=Tebogo-prod aws sts get-caller-identity`
- [ ] **CRITICAL**: Confirm region is us-east-1 (required for Lambda@Edge)
- [ ] Verify Route53 hosted zone for `kimmyai.io`
- [ ] Check SSL certificate in ACM for `kimmyai.io` (MUST be in us-east-1)
- [ ] Verify wildcard certificate (*.kimmyai.io)

#### Multi-Region CDN Setup
- [ ] CloudFront automatically uses all edge locations globally
- [ ] Document monitoring for all regions
- [ ] Plan for regional failover (origin failover groups)

#### Change Management
- [ ] Change request submitted and approved
- [ ] Maintenance window scheduled (recommended)
- [ ] Customer notification sent
- [ ] Rollback team on standby
- [ ] Communication channels ready (Slack, email, status page)
- [ ] Incident response team briefed

#### Data Migration
- [ ] No data migration needed (new deployment)
- [ ] Plan for production content upload
- [ ] Verify no conflicting resources in PROD

### Deployment Steps (Feb 24, 10:00 AM)

#### Step 1: Pre-deployment Verification
```bash
# Verify SIT is stable
curl -I https://sit.kimmyai.io

# Verify PROD access
AWS_PROFILE=Tebogo-prod aws sts get-caller-identity --region us-east-1

# Verify ACM certificate
AWS_PROFILE=Tebogo-prod aws acm list-certificates --region us-east-1 | grep kimmyai.io

# Verify no existing CloudFront distribution for kimmyai.io
AWS_PROFILE=Tebogo-prod aws cloudfront list-distributions \
  --region us-east-1 \
  --query "DistributionList.Items[?contains(Aliases.Items[0], 'kimmyai.io')]"
```

#### Step 2: Terraform Workspace Switch
```bash
cd /Users/tebogotseka/Documents/agentic_work/2_1_bbws_backend_public/terraform
terraform workspace select prod
terraform workspace list  # Verify 'prod' is selected
```

#### Step 3: Terraform Plan (Production)
```bash
AWS_PROFILE=Tebogo-prod terraform plan -out=prod.tfplan -var="region=us-east-1"
# CRITICAL REVIEW:
# - Verify S3 bucket will be created with public access blocked
# - Confirm CloudFront distribution configuration
# - Verify Origin Access Identity (OAI) configured
# - Check S3 bucket policy (CloudFront access only)
# - Verify Lambda@Edge functions will be deployed to us-east-1
# - Confirm SSL certificate ARN correct
# - Verify cache behaviors configured
# - Check custom domain mapping (kimmyai.io)
# - Verify origin failover configured
# - Confirm WAF ACL associated (if configured)
# - Verify no existing resources will be destroyed
```

#### Step 4: Final Approval
- Review terraform plan with Product Owner and Security Lead
- Confirm change request approved
- **CRITICAL**: Confirm S3 bucket blocks public access
- Verify CloudFront OAI configured correctly
- Verify Lambda@Edge IAM roles have correct permissions
- Verify SSL certificate in us-east-1
- Get explicit "GO" from stakeholders
- Document all approvals

#### Step 5: Deploy Lambda@Edge Functions First
```bash
# Lambda@Edge must be deployed before CloudFront distribution
cd /Users/tebogotseka/Documents/agentic_work/2_1_bbws_backend_public/lambda-edge

# Deploy each function to us-east-1
for function in security-headers url-rewrite auth-validation redirects; do
  cd $function
  npm install --production
  npm run build
  zip -r function.zip .

  AWS_PROFILE=Tebogo-prod aws lambda create-function \
    --function-name bbws-$function-prod \
    --runtime nodejs20.x \
    --role arn:aws:iam::093646564004:role/lambda-edge-execution-role-prod \
    --handler index.handler \
    --zip-file fileb://function.zip \
    --region us-east-1 \
    --publish

  # Note the version ARN (includes version number)
  VERSION_ARN=$(AWS_PROFILE=Tebogo-prod aws lambda list-versions-by-function \
    --function-name bbws-$function-prod \
    --region us-east-1 \
    --query 'Versions[-1].FunctionArn' \
    --output text)

  echo "$function: $VERSION_ARN"
  cd ..
done
```

#### Step 6: Terraform Apply
```bash
AWS_PROFILE=Tebogo-prod terraform apply prod.tfplan
# Monitor output carefully
# Note: CloudFront distribution creation takes 15-30 minutes
# Lambda@Edge association may take additional 5-10 minutes
```

#### Step 7: Wait for CloudFront Distribution
```bash
# Get distribution ID
DIST_ID=$(AWS_PROFILE=Tebogo-prod aws cloudfront list-distributions \
  --region us-east-1 \
  --query "DistributionList.Items[?Aliases.Items[0]=='kimmyai.io'].Id" \
  --output text)

echo "Distribution ID: $DIST_ID"

# Wait for distribution to deploy (15-30 minutes)
AWS_PROFILE=Tebogo-prod aws cloudfront wait distribution-deployed \
  --id $DIST_ID \
  --region us-east-1

echo "CloudFront distribution deployed!"
```

#### Step 8: Update Route53
```bash
# Get CloudFront domain name
CF_DOMAIN=$(AWS_PROFILE=Tebogo-prod aws cloudfront get-distribution \
  --id $DIST_ID \
  --region us-east-1 \
  --query 'Distribution.DomainName' \
  --output text)

# Create Route53 alias record for apex domain
AWS_PROFILE=Tebogo-prod aws route53 change-resource-record-sets \
  --hosted-zone-id <prod-hosted-zone-id> \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "kimmyai.io",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "'$CF_DOMAIN'",
          "EvaluateTargetHealth": false
        }
      }
    }]
  }'

# Create Route53 alias record for www subdomain
AWS_PROFILE=Tebogo-prod aws route53 change-resource-record-sets \
  --hosted-zone-id <prod-hosted-zone-id> \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "www.kimmyai.io",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "'$CF_DOMAIN'",
          "EvaluateTargetHealth": false
        }
      }
    }]
  }'
```

#### Step 9: Deploy Frontend Assets
```bash
# Build frontend for production
cd /Users/tebogotseka/Documents/agentic_work/2_1_bbws_backend_public/frontend
npm install
npm run build:prod

# Upload to S3
AWS_PROFILE=Tebogo-prod aws s3 sync ./dist/ s3://bbws-frontend-prod/ \
  --delete \
  --cache-control "public, max-age=31536000, immutable" \
  --exclude "index.html"

# Upload index.html with no-cache (for SPA routing)
AWS_PROFILE=Tebogo-prod aws s3 cp ./dist/index.html s3://bbws-frontend-prod/index.html \
  --cache-control "no-cache, no-store, must-revalidate"

# Invalidate CloudFront cache
AWS_PROFILE=Tebogo-prod aws cloudfront create-invalidation \
  --distribution-id $DIST_ID \
  --paths "/*"
```

### Post-Deployment Validation (Feb 24, 11:00 AM - 2:00 PM)

#### DNS and SSL Validation
```bash
# Test 1: DNS resolution
nslookup kimmyai.io
nslookup www.kimmyai.io

# Test 2: HTTPS certificate
curl -I https://kimmyai.io
curl -I https://www.kimmyai.io

# Test 3: Verify certificate details
echo | openssl s_client -connect kimmyai.io:443 -servername kimmyai.io 2>/dev/null | openssl x509 -noout -dates -subject
```

#### CloudFront Validation
```bash
# Test 4: Verify CloudFront response headers
curl -I https://kimmyai.io

# Test 5: Verify CloudFront caching
curl -I https://kimmyai.io/assets/logo.png
# Should see X-Cache: Hit from cloudfront on second request

# Test 6: Check CloudFront distribution status
AWS_PROFILE=Tebogo-prod aws cloudfront get-distribution \
  --id $DIST_ID \
  --region us-east-1 \
  --query 'Distribution.Status'
```

#### Lambda@Edge Validation
```bash
# Test 7: Verify Lambda@Edge functions associated
AWS_PROFILE=Tebogo-prod aws cloudfront get-distribution-config \
  --id $DIST_ID \
  --region us-east-1 \
  --query 'DistributionConfig.DefaultCacheBehavior.LambdaFunctionAssociations'

# Test 8: Verify security headers
curl -I https://kimmyai.io | grep -E "(X-Content-Type-Options|X-Frame-Options|X-XSS-Protection|Strict-Transport-Security|Content-Security-Policy)"

# Test 9: Verify URL rewrite for SPA routing
curl -s https://kimmyai.io/products | grep "<html"
```

#### Production Monitoring (First 24 Hours)
- [ ] Monitor every 30 minutes for first 6 hours
- [ ] Check CloudWatch metrics hourly
- [ ] Review CloudWatch alarms
- [ ] Monitor cache hit ratio (target >80%)
- [ ] Monitor Lambda@Edge execution times
- [ ] Check for any 4xx/5xx errors
- [ ] Verify global CDN performance
- [ ] Monitor costs

#### Production Monitoring (First Week)
- [ ] Daily health checks
- [ ] Weekly performance review
- [ ] Cost monitoring (CloudFront, Lambda@Edge, S3, data transfer)
- [ ] User feedback collection
- [ ] Incident tracking
- [ ] Cache hit ratio trending
- [ ] Regional performance analysis

---

## Rollback Procedures

### SIT Rollback
```bash
# Revert CloudFront distribution to previous configuration
AWS_PROFILE=Tebogo-sit aws cloudfront update-distribution \
  --id $DIST_ID \
  --region us-east-1 \
  --if-match <etag> \
  --distribution-config file://previous-distribution-config.json

# Revert S3 content to previous version
AWS_PROFILE=Tebogo-sit aws s3 sync s3://bbws-frontend-sit-backup/ s3://bbws-frontend-sit/ --delete

# Invalidate CloudFront cache
AWS_PROFILE=Tebogo-sit aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"
```

### PROD Rollback (CRITICAL)
```bash
# Option 1: S3 versioning rollback (recommended)
# Restore previous version of objects
AWS_PROFILE=Tebogo-prod aws s3api list-object-versions \
  --bucket bbws-frontend-prod \
  --prefix "" \
  --query 'Versions[?IsLatest==`false`]'

# Restore specific version
AWS_PROFILE=Tebogo-prod aws s3api copy-object \
  --bucket bbws-frontend-prod \
  --copy-source bbws-frontend-prod/index.html?versionId=<version-id> \
  --key index.html

# Option 2: Deploy previous build
cd /Users/tebogotseka/Documents/agentic_work/2_1_bbws_backend_public/frontend
git checkout <previous-tag>
npm run build:prod
AWS_PROFILE=Tebogo-prod aws s3 sync ./dist/ s3://bbws-frontend-prod/ --delete

# Option 3: CloudFront distribution rollback
AWS_PROFILE=Tebogo-prod aws cloudfront update-distribution \
  --id $DIST_ID \
  --region us-east-1 \
  --if-match <etag> \
  --distribution-config file://previous-distribution-config.json

# ALWAYS invalidate CloudFront cache after rollback
AWS_PROFILE=Tebogo-prod aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"
```

### Rollback Triggers
- 5xx error rate > 5%
- 4xx error rate > 20%
- Critical functionality broken
- Security vulnerability detected
- Performance degradation (p95 > 3s)
- Customer escalation
- CloudFront distribution failure
- Lambda@Edge execution errors > 1%

---

## Success Criteria

### SIT Success
- [ ] S3 bucket created with public access blocked
- [ ] CloudFront distribution deployed
- [ ] Lambda@Edge functions associated
- [ ] DNS and SSL working
- [ ] Frontend assets deployed
- [ ] Cache hit ratio >80%
- [ ] Security headers present
- [ ] SPA routing working
- [ ] Integration tests passing

### PROD Success
- [ ] Zero-downtime deployment
- [ ] All health checks green
- [ ] DNS resolving correctly (kimmyai.io, www.kimmyai.io)
- [ ] SSL certificate valid
- [ ] Cache hit ratio >80%
- [ ] No 5xx errors
- [ ] 4xx error rate <5%
- [ ] Page load time <2s (p95)
- [ ] Global CDN performance verified
- [ ] Lambda@Edge error rate <0.1%
- [ ] Product Owner sign-off

---

## Monitoring & Alerts

### CloudWatch Alarms
| Alarm | Threshold | Action |
|-------|-----------|--------|
| 4xx Error Rate | > 10% | SNS alert to DevOps |
| 5xx Error Rate | > 1% | SNS alert to DevOps (CRITICAL) |
| Origin Latency | p95 > 2s | SNS alert to DevOps |
| Cache Hit Ratio | < 70% | SNS alert to DevOps |
| Lambda@Edge Errors | > 0.5% error rate | SNS alert to DevOps |
| Lambda@Edge Duration | p95 > 100ms | SNS alert to DevOps |
| Data Transfer Out | > 10TB/day | SNS alert to FinOps |

### CloudWatch Dashboards
- Create: `backend-public-sit-dashboard`
- Create: `backend-public-prod-dashboard`
- Widgets:
  - CloudFront requests
  - Cache hit ratio
  - 4xx/5xx error rates
  - Origin latency
  - Lambda@Edge invocations
  - Lambda@Edge errors
  - Lambda@Edge duration
  - Data transfer metrics
  - Cost metrics

---

## Contacts & Escalation

| Role | Contact | Availability |
|------|---------|--------------|
| DevOps Engineer | TBD | Primary deployer |
| Frontend Lead | TBD | Frontend issues |
| Security Lead | TBD | Security and SSL |
| Tech Lead | TBD | Approval & escalation |
| Product Owner | TBD | Final sign-off |
| On-Call SRE | TBD | 24/7 incident response |
| AWS Support | TBD | CloudFront/Lambda@Edge issues |

---

## Documentation

### Deployment Artifacts
- [ ] Deployment runbook (this document)
- [ ] Terraform plan outputs (sit.tfplan, prod.tfplan)
- [ ] CloudFront distribution configuration
- [ ] Lambda@Edge function code
- [ ] Cache policy documentation
- [ ] Security headers configuration
- [ ] Performance benchmarks
- [ ] Cost analysis

### Post-Deployment
- [ ] Deployment retrospective notes
- [ ] Lessons learned document
- [ ] Updated architecture diagrams
- [ ] Frontend deployment guide
- [ ] Cache invalidation procedures
- [ ] Lambda@Edge troubleshooting guide
- [ ] Incident reports (if any)

---

## Change Log

| Date | Phase | Status | Notes |
|------|-------|--------|-------|
| 2026-01-07 | Planning | 📋 Complete | Promotion plan created |
| 2026-01-13 | SIT Deploy | ⏳ Scheduled | Target deployment (Wave 2) |
| 2026-02-24 | PROD Deploy | 🔵 Planned | Target deployment (Wave 2) |

---

**Next Steps:**
1. Review and approve this plan (CRITICAL: Security Lead review required)
2. Complete pre-deployment checklist
3. MUST wait for DynamoDB and S3 schemas in SIT first
4. Schedule SIT deployment for Jan 13 (after dynamodb_schemas and s3_schemas)
5. Execute deployment following this plan

**Plan Status:** 📋 READY FOR REVIEW
**Approval Required By:** Tech Lead, DevOps Lead, Security Lead, Frontend Lead
**Wave:** Wave 2 (Infrastructure Foundation)
**Dependencies:** dynamodb_schemas, s3_schemas (MUST be in SIT first)
**CRITICAL:** S3 bucket MUST block public access (CloudFront OAI only)
**CRITICAL:** Lambda@Edge MUST be deployed in us-east-1
