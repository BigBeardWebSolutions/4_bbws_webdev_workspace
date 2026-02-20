# Worker Output: DEV Deployment

**Worker**: worker-2-dev-deployment
**Status**: READY FOR DEPLOYMENT
**Date**: 2026-01-23

---

## Pre-Deployment Checklist

- [x] API Gateway routes added (4 new routes)
- [x] Lambda router created
- [x] Handler paths updated in all tfvars
- [x] HCL syntax validated
- [x] Python syntax validated
- [ ] Lambda package built (dist/lambda.zip)
- [ ] Terraform initialized
- [ ] Terraform applied

---

## Deployment Steps

### Step 1: Build Lambda Package

```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service

# Create dist directory
mkdir -p dist

# Install dependencies to package directory
pip install -r requirements.txt -t dist/package/

# Copy source code
cp -r src dist/package/

# Create zip file
cd dist/package
zip -r ../lambda.zip .
cd ../..

# Verify package
ls -la dist/lambda.zip
```

### Step 2: Initialize Terraform

```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/terraform

# Initialize with DEV backend
terraform init -backend-config=environments/dev/backend.tfvars
```

### Step 3: Plan Changes

```bash
# Preview changes
terraform plan -var-file=environments/dev/dev.tfvars -out=dev.tfplan
```

### Step 4: Apply Changes

```bash
# Apply the plan
terraform apply dev.tfplan
```

### Step 5: Verify Deployment

```bash
# Get API Gateway URL from terraform output
terraform output api_gateway_url

# Test endpoints (replace with actual values)
API_URL="<api_gateway_url>"
TOKEN="<jwt_token>"

# Test List Sites
curl -H "Authorization: Bearer $TOKEN" "$API_URL/v1.0/tenants/test-tenant/sites"

# Test Get Site
curl -H "Authorization: Bearer $TOKEN" "$API_URL/v1.0/tenants/test-tenant/sites/test-site"
```

---

## Expected Terraform Changes

```
# API Gateway routes to be added:
+ aws_apigatewayv2_route.sites_list
+ aws_apigatewayv2_route.sites_get
+ aws_apigatewayv2_route.sites_update
+ aws_apigatewayv2_route.sites_delete

# Lambda function update:
~ aws_lambda_function.sites_service (handler path change)
```

---

## Rollback Steps (if needed)

```bash
# Revert handler to previous version
# In dev.tfvars, change:
# sites_lambda_handler = "src.handlers.sites.create_site_handler.lambda_handler"

# Apply rollback
terraform apply -var-file=environments/dev/dev.tfvars
```

---

## Environment Details

| Parameter | Value |
|-----------|-------|
| Environment | DEV |
| AWS Account | 536580886816 |
| Region | eu-west-1 |
| Lambda Runtime | Python 3.13 |
| API Stage | v1 |

---

## Post-Deployment Verification

1. Check Lambda function updated in AWS Console
2. Check API Gateway routes in AWS Console
3. Test each new endpoint with curl or Postman
4. Review CloudWatch logs for any errors
