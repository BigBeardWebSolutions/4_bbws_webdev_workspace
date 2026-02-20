# Worker Instructions: DEV Environment Deployment

**Worker ID**: worker-3-dev-deployment
**Stage**: Stage 5 - Documentation & Deployment
**Project**: project-plan-campaigns

---

## Task

Deploy the Campaign Lambda service to the DEV environment.

---

## Environment Details

| Attribute | Value |
|-----------|-------|
| Environment | DEV |
| Region | eu-west-1 |
| AWS Account | 536580886816 |

---

## Prerequisites

Before deployment:

1. [ ] All unit tests passing
2. [ ] All integration tests passing
3. [ ] Code coverage > 80%
4. [ ] Terraform validates successfully
5. [ ] CI/CD workflows configured
6. [ ] AWS credentials available

---

## Deployment Steps

### Step 1: Verify Tests Pass

```bash
# Run all tests
pytest tests/ -v --cov=src --cov-report=term-missing

# Verify coverage
pytest tests/ --cov=src --cov-fail-under=80
```

### Step 2: Build Lambda Package

```bash
# Create package directory
mkdir -p package dist

# Install dependencies
pip install -r requirements.txt -t package/

# Copy source code
cp -r src/ package/

# Create ZIP
cd package && zip -r ../dist/lambda.zip . && cd ..

# Verify package size (should be < 50MB)
ls -lh dist/lambda.zip
```

### Step 3: Upload to S3

```bash
# Set environment
export AWS_PROFILE=bbws-dev
export AWS_REGION=eu-west-1

# Upload Lambda package
aws s3 cp dist/lambda.zip \
  s3://bbws-lambda-packages-dev/campaigns-lambda/lambda.zip \
  --region $AWS_REGION
```

### Step 4: Initialize Terraform

```bash
cd terraform

# Initialize with DEV backend
terraform init \
  -backend-config="bucket=bbws-terraform-state-dev" \
  -backend-config="key=campaigns-lambda/terraform.tfstate" \
  -backend-config="region=eu-west-1" \
  -backend-config="dynamodb_table=terraform-state-lock" \
  -backend-config="encrypt=true"
```

### Step 5: Plan Infrastructure

```bash
# Generate plan
terraform plan \
  -var-file=environments/dev.tfvars \
  -out=tfplan

# Review the plan carefully
```

### Step 6: Apply Infrastructure

```bash
# Apply changes
terraform apply tfplan

# Capture outputs
terraform output > deployment-outputs.txt
```

### Step 7: Validate Deployment

```bash
# Get API URL
API_URL=$(terraform output -raw api_gateway_url)
echo "API URL: $API_URL"

# Run validation script
python ../scripts/validate_deployment.py $API_URL -v

# Run smoke tests
python ../scripts/smoke_test.py $API_URL

# Health check
python ../scripts/health_check.py $API_URL --format json
```

### Step 8: Test API Endpoints

```bash
API_URL=$(terraform output -raw api_gateway_url)

# Test list campaigns
curl -s "$API_URL/v1.0/campaigns" | jq .

# Test get campaign (should return 404 if none exist)
curl -s "$API_URL/v1.0/campaigns/TEST" | jq .

# Test create campaign
curl -s -X POST "$API_URL/v1.0/campaigns" \
  -H "Content-Type: application/json" \
  -d '{
    "code": "DEVTEST2025",
    "name": "DEV Test Campaign",
    "productId": "PROD-001",
    "discountPercent": 20,
    "listPrice": 100.00,
    "termsAndConditions": "This is a test campaign for DEV environment validation.",
    "fromDate": "2025-01-01T00:00:00Z",
    "toDate": "2025-12-31T23:59:59Z"
  }' | jq .

# Test get created campaign
curl -s "$API_URL/v1.0/campaigns/DEVTEST2025" | jq .

# Cleanup test campaign
curl -s -X DELETE "$API_URL/v1.0/campaigns/DEVTEST2025"
```

---

## Expected Outputs

After successful deployment:

| Resource | Expected Value |
|----------|----------------|
| Lambda Functions | 5 (list, get, create, update, delete) |
| DynamoDB Table | campaigns-dev |
| API Gateway | Regional endpoint with /v1.0/campaigns |
| CloudWatch Logs | 5 log groups created |

---

## Verification Checklist

- [ ] Lambda functions deployed and healthy
- [ ] DynamoDB table created with PITR enabled
- [ ] API Gateway returns 200 for list campaigns
- [ ] API Gateway returns 404 for non-existent campaign
- [ ] Create/Update/Delete endpoints work
- [ ] CloudWatch logs are populated
- [ ] Validation script passes
- [ ] Smoke tests pass

---

## Rollback Plan

If deployment fails:

```bash
# Option 1: Terraform destroy and recreate
terraform destroy -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars

# Option 2: Revert to previous state
terraform state list
# Identify problematic resources
terraform state rm <resource>
terraform import <resource> <id>
```

---

## Post-Deployment Tasks

1. **Update project plan** - Mark deployment as complete
2. **Notify team** - Send deployment notification
3. **Document any issues** - Update runbook if needed
4. **Monitor metrics** - Watch for 30 minutes

---

## Success Criteria

- [ ] All 5 Lambda functions deployed
- [ ] DynamoDB table created
- [ ] API Gateway configured
- [ ] All validation tests pass
- [ ] API endpoints respond correctly
- [ ] No errors in CloudWatch logs

---

## Execution Steps

1. Verify prerequisites
2. Build Lambda package
3. Upload to S3
4. Initialize Terraform
5. Plan and apply
6. Run validations
7. Test all endpoints
8. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
