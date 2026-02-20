# Product Lambda Deployment Runbook

**Service**: Product Lambda API
**Repository**: https://github.com/BigBeardWebSolutions/2_bbws_product_lambda
**Last Updated**: 2025-12-29

---

## Overview

This runbook covers deployment procedures for the Product Lambda service across all environments (DEV, SIT, PROD).

---

## Prerequisites

### Required Access
- GitHub repository access
- AWS Console access for target environment
- Terraform CLI installed (>= 1.5.0)
- Python 3.12 installed
- AWS CLI configured

### Infrastructure Requirements
- DynamoDB table: `products-{environment}` must exist
- S3 backend bucket for Terraform state
- DynamoDB lock table for Terraform state locking
- GitHub OIDC role configured for GitHub Actions

---

## Deployment Methods

### Method 1: Automated Deployment (Recommended)

**DEV Environment** (Auto-deploy):
```bash
# 1. Commit and push changes to main branch
git add .
git commit -m "Your commit message"
git push origin main

# 2. GitHub Actions automatically deploys to DEV
# Monitor: https://github.com/BigBeardWebSolutions/2_bbws_product_lambda/actions

# 3. Wait for workflow to complete (~5-10 minutes)
```

**SIT Environment** (Manual trigger):
```bash
# 1. Navigate to GitHub Actions
# 2. Select "Deploy to SIT" workflow
# 3. Click "Run workflow"
# 4. Type "deploy" to confirm
# 5. Click "Run workflow" button
# 6. Wait for approval gate
# 7. Approve deployment in GitHub Actions UI
```

**PROD Environment** (Strict manual trigger):
```bash
# 1. Navigate to GitHub Actions
# 2. Select "Deploy to PROD" workflow
# 3. Click "Run workflow"
# 4. Type "deploy-to-production" to confirm
# 5. Enter reason for deployment
# 6. Click "Run workflow" button
# 7. Wait for approval gate
# 8. Approve deployment in GitHub Actions UI
```

---

### Method 2: Local Terraform Deployment (DEV only)

**Step 1: Package Lambda Functions**
```bash
cd /path/to/2_bbws_product_lambda

# Run packaging script
./scripts/package_lambdas.sh

# Verify ZIP files created
ls -lh dist/*.zip
```

**Step 2: Initialize Terraform**
```bash
cd terraform

# Initialize with DEV backend
terraform init \
  -backend-config="bucket=bbws-terraform-state-dev" \
  -backend-config="key=product-lambda/dev/terraform.tfstate" \
  -backend-config="region=eu-west-1" \
  -backend-config="dynamodb_table=terraform-state-lock-dev" \
  -backend-config="encrypt=true"
```

**Step 3: Plan Deployment**
```bash
# Review changes
terraform plan -var-file=environments/dev.tfvars

# Save plan to file
terraform plan -var-file=environments/dev.tfvars -out=tfplan
```

**Step 4: Apply Deployment**
```bash
# Apply with saved plan
terraform apply tfplan

# OR apply directly (requires confirmation)
terraform apply -var-file=environments/dev.tfvars
```

**Step 5: Verify Deployment**
```bash
# Get API Gateway URL
terraform output api_gateway_url

# Test API endpoint
curl $(terraform output -raw api_gateway_url)
```

---

## Post-Deployment Validation

### 1. Verify Lambda Functions
```bash
# Check all 5 Lambda functions exist
aws lambda list-functions \
  --region eu-west-1 \
  --query "Functions[?starts_with(FunctionName, 'bbws-product-')].FunctionName"

# Expected output:
# - bbws-product-list-dev
# - bbws-product-get-dev
# - bbws-product-create-dev
# - bbws-product-update-dev
# - bbws-product-delete-dev
```

### 2. Verify API Gateway
```bash
# Get API details
aws apigateway get-rest-apis \
  --region eu-west-1 \
  --query "items[?name=='bbws-product-api-dev']"

# Get API URL
terraform output -raw api_gateway_url
```

### 3. Test API Endpoints
```bash
API_URL=$(terraform output -raw api_gateway_url)

# Test list products
curl -X GET $API_URL

# Expected: {"products": []}
```

### 4. Check CloudWatch Logs
```bash
# List log groups
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/lambda/bbws-product-" \
  --region eu-west-1

# Check recent logs
aws logs tail /aws/lambda/bbws-product-list-dev --follow
```

### 5. Verify CloudWatch Alarms
```bash
# List alarms
aws cloudwatch describe-alarms \
  --alarm-name-prefix "bbws-product-" \
  --region eu-west-1
```

---

## Rollback Procedures

### Rollback via GitHub Actions
```bash
# 1. Identify last good commit
git log --oneline

# 2. Revert to last good commit
git revert <commit-hash>
git push origin main

# 3. GitHub Actions will auto-deploy rollback to DEV
```

### Rollback via Terraform
```bash
cd terraform

# 1. Checkout previous Terraform state
terraform state pull > previous-state.json

# 2. Review differences
git diff HEAD~1 terraform/

# 3. Checkout previous version
git checkout HEAD~1 terraform/

# 4. Re-deploy
terraform apply -var-file=environments/dev.tfvars
```

---

## Troubleshooting

### Issue: Terraform Lock Timeout
**Symptom**: `Error acquiring the state lock`

**Solution**:
```bash
# Check lock status
aws dynamodb get-item \
  --table-name terraform-state-lock-dev \
  --key '{"LockID": {"S": "bbws-terraform-state-dev/product-lambda/dev/terraform.tfstate"}}'

# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### Issue: Lambda Deployment Fails
**Symptom**: `ResourceNotFoundException: Function not found`

**Solution**:
1. Check ZIP file exists: `ls dist/*.zip`
2. Verify ZIP contents: `unzip -l dist/list_products.zip`
3. Check IAM role permissions
4. Review CloudWatch logs for errors

### Issue: API Gateway 502 Bad Gateway
**Symptom**: API returns 502 error

**Solution**:
1. Check Lambda execution role has DynamoDB permissions
2. Verify DynamoDB table exists: `aws dynamodb describe-table --table-name products-dev`
3. Check Lambda environment variables
4. Review CloudWatch logs for Lambda errors

---

## Environment-Specific Details

| Environment | AWS Account | Region | Auto-Deploy | Approval Required |
|-------------|-------------|--------|-------------|-------------------|
| DEV | 536580886816 | eu-west-1 | Yes (on push to main) | No |
| SIT | 815856636111 | eu-west-1 | No (manual trigger) | Yes |
| PROD | 093646564004 | af-south-1 | No (manual trigger) | Yes (strict) |

---

## Related Documentation

- **Development Setup**: `product_lambda_dev_setup.md`
- **Operations Guide**: `product_lambda_operations.md`
- **Disaster Recovery**: `product_lambda_disaster_recovery.md`
- **CI/CD Guide**: `product_lambda_cicd_guide.md`
- **LLD**: `2.1.4_LLD_Product_Lambda.md`

---

## Support Contacts

**Platform Team**: [Contact details]
**AWS Support**: [Support portal]

---

**Version**: 1.0
**Status**: Active
