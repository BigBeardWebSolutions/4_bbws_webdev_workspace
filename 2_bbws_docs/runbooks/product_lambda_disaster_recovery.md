# Product Lambda Disaster Recovery Runbook

**Service**: Product Lambda API
**RPO**: 1 hour | **RTO**: 30 minutes
**Last Updated**: 2025-12-29

---

## DR Strategy

**Primary Region**: af-south-1 (PROD only)
**DR Region**: eu-west-1 (passive standby)
**Pattern**: Multi-site Active/Active with Route 53 failover

---

## Backup Components

### 1. DynamoDB
- **PITR**: Enabled (point-in-time recovery)
- **Hourly Snapshots**: Automated
- **Cross-Region Replication**: PROD only (af-south-1 → eu-west-1)

### 2. Lambda Code
- **GitHub**: Primary source of truth
- **S3 Artifacts**: Deployment ZIPs retained
- **Terraform State**: S3 backend with versioning

### 3. Infrastructure
- **Terraform**: All infrastructure as code
- **State Backups**: S3 versioning enabled
- **Git History**: Complete deployment history

---

## Failure Scenarios

### Scenario 1: Lambda Function Failure

**Detection**:
- CloudWatch alarm: Lambda errors > 5
- API Gateway 5xx errors

**Recovery**:
```bash
# 1. Identify failed function
aws lambda list-functions --query "Functions[?LastModified > '2025-12-29']"

# 2. Rollback to previous version
aws lambda update-function-code \
  --function-name bbws-product-list-prod \
  --s3-bucket bbws-lambda-artifacts-prod \
  --s3-key previous-version/list_products.zip

# 3. Verify recovery
curl https://api.kimmyai.io/v1/v1.0/products
```

**RTO**: 5 minutes

---

### Scenario 2: API Gateway Failure

**Detection**:
- API Gateway returns consistent 502/503 errors
- CloudWatch alarm triggered

**Recovery**:
```bash
# 1. Create new deployment
aws apigateway create-deployment \
  --rest-api-id YOUR_API_ID \
  --stage-name v1

# 2. OR redeploy via Terraform
cd terraform
terraform apply -var-file=environments/prod.tfvars -target=aws_api_gateway_deployment.product_api

# 3. Test recovery
curl https://api.kimmyai.io/v1/v1.0/products
```

**RTO**: 10 minutes

---

### Scenario 3: DynamoDB Table Corruption

**Detection**:
- Unexpected data loss
- Consistent read/write failures

**Recovery**:
```bash
# 1. Restore from PITR
aws dynamodb restore-table-to-point-in-time \
  --source-table-name products-prod \
  --target-table-name products-prod-restored \
  --restore-date-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%S)

# 2. Update Lambda environment to point to restored table
aws lambda update-function-configuration \
  --function-name bbws-product-list-prod \
  --environment Variables="{DYNAMODB_TABLE=products-prod-restored,ENVIRONMENT=prod,LOG_LEVEL=INFO}"

# 3. Verify data integrity
aws dynamodb scan --table-name products-prod-restored --max-items 10
```

**RTO**: 15-20 minutes

---

### Scenario 4: Regional Failure (PROD)

**Detection**:
- All services in af-south-1 unavailable
- Route 53 health checks failing

**Recovery** (Failover to eu-west-1):
```bash
# 1. Deploy to DR region
cd terraform
terraform workspace select prod-dr
terraform apply -var-file=environments/prod-dr.tfvars

# 2. Update Route 53 to point to DR region
aws route53 change-resource-record-sets \
  --hosted-zone-id YOUR_ZONE_ID \
  --change-batch file://failover-to-dr.json

# 3. Verify failover
curl https://api.kimmyai.io/v1/v1.0/products

# 4. Check DynamoDB replication status
aws dynamodb describe-table --table-name products-prod --region eu-west-1
```

**RTO**: 30 minutes

---

### Scenario 5: Complete Infrastructure Loss

**Detection**:
- All AWS resources deleted/corrupted
- Terraform state accessible

**Recovery**:
```bash
# 1. Clone repository
git clone https://github.com/BigBeardWebSolutions/2_bbws_product_lambda.git
cd 2_bbws_product_lambda

# 2. Package Lambda functions
./scripts/package_lambdas.sh

# 3. Initialize Terraform
cd terraform
terraform init -backend-config=environments/prod.tfvars

# 4. Review plan
terraform plan -var-file=environments/prod.tfvars

# 5. Recreate infrastructure
terraform apply -var-file=environments/prod.tfvars

# 6. Restore DynamoDB data from backup
aws dynamodb restore-table-from-backup \
  --target-table-name products-prod \
  --backup-arn arn:aws:dynamodb:af-south-1:093646564004:table/products-prod/backup/LATEST
```

**RTO**: 45-60 minutes

---

## DR Testing

### Monthly DR Drill
```bash
# 1. Create test snapshot
aws dynamodb create-backup --table-name products-prod --backup-name dr-drill-$(date +%Y%m%d)

# 2. Deploy to DR region (no traffic)
terraform workspace select prod-dr
terraform plan -var-file=environments/prod-dr.tfvars

# 3. Test API in DR region
curl https://api-dr.kimmyai.io/v1/v1.0/products

# 4. Document results
# 5. Tear down DR test resources
```

---

## Backup Verification

### Weekly Backup Check
```bash
# Verify PITR enabled
aws dynamodb describe-continuous-backups --table-name products-prod

# List recent backups
aws dynamodb list-backups --table-name products-prod --time-range-lower-bound $(date -u -v-7d +%s)

# Test restore (to temporary table)
aws dynamodb restore-table-from-backup \
  --target-table-name products-prod-test-restore \
  --backup-arn arn:aws:dynamodb:af-south-1:093646564004:table/products-prod/backup/LATEST
```

---

## Post-Recovery Actions

1. **Validate Functionality**: Test all API endpoints
2. **Check Data Integrity**: Verify product data
3. **Monitor Performance**: Watch CloudWatch metrics
4. **Document Incident**: Record in incident log
5. **Root Cause Analysis**: Determine failure cause
6. **Update Procedures**: Improve DR runbook

---

## Contact Information

**Emergency Contact**: [On-call team]
**AWS Support**: Premium Support
**Escalation**: [Platform Team Lead]

---

**Related**: `product_lambda_deployment.md`, `product_lambda_operations.md`
