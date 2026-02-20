# Worker Instructions: DEV Deployment

**Worker ID**: worker-2-dev-deployment
**Stage**: Stage 4 - Deployment
**Project**: project-plan-4

---

## Task Description

Deploy the WordPress Site Management Lambda with the 4 new handlers to the DEV environment (AWS Account: 536580886816, Region: af-south-1). This requires human approval before applying the Terraform plan.

---

## Inputs

**Terraform Plan**:
- `terraform/tfplan.out` (from worker-1-terraform-validation)

**Validation Report**:
- `worker-1-terraform-validation/output.md`

**Environment Details**:
- AWS Account: 536580886816
- Region: af-south-1
- Environment: DEV

---

## Deliverables

### 1. Deployment Confirmation

Create `output.md` with:
- Terraform apply output
- Deployed resource ARNs
- API Gateway endpoint URLs
- CloudWatch Log Group names

### 2. Verification Checklist

Confirm all resources deployed successfully.

---

## Pre-Deployment Requirements

### Approvals Required
- [ ] Terraform plan reviewed by Tech Lead
- [ ] DevOps Lead approval obtained
- [ ] No blockers from Security review

### Prerequisites
- [ ] AWS credentials configured for DEV account
- [ ] Terraform plan generated and reviewed
- [ ] All Stage 3 tests passing
- [ ] No outstanding issues from validation

---

## Deployment Steps

### Step 1: Verify AWS Credentials

```bash
# Verify you're connected to DEV account
aws sts get-caller-identity

# Expected output:
# Account: 536580886816
# Region should be: af-south-1
```

### Step 2: Review Plan (Final Check)

```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/terraform

# Show the saved plan
terraform show tfplan.out
```

### Step 3: Apply Terraform Plan

**IMPORTANT**: This step requires explicit human approval before execution.

```bash
# Apply the saved plan
terraform apply tfplan.out

# Wait for completion
# This may take 2-5 minutes
```

### Step 4: Verify Deployment

```bash
# List deployed Lambda functions
aws lambda list-functions \
  --region af-south-1 \
  --query "Functions[?contains(FunctionName, 'site')].[FunctionName,Runtime,LastModified]" \
  --output table

# Get API Gateway endpoints
aws apigateway get-rest-apis \
  --region af-south-1 \
  --query "items[?contains(name, 'sites')].[id,name]" \
  --output table
```

### Step 5: Test Endpoints (Quick Smoke Test)

```bash
# Get API Gateway URL
API_ID=$(aws apigateway get-rest-apis --region af-south-1 --query "items[?contains(name, 'sites')].id" --output text)
API_URL="https://${API_ID}.execute-api.af-south-1.amazonaws.com/dev"

# Test health endpoint (if exists)
curl -X GET "${API_URL}/health"

# Note: Full API testing is done in Stage 5
```

---

## Expected Outputs

### Terraform Apply Output

```
Apply complete! Resources: 12 added, 0 changed, 0 destroyed.

Outputs:

api_gateway_url = "https://abc123.execute-api.af-south-1.amazonaws.com/dev"
lambda_function_arns = {
  "get_site" = "arn:aws:lambda:af-south-1:536580886816:function:bbws-get-site-handler-dev"
  "list_sites" = "arn:aws:lambda:af-south-1:536580886816:function:bbws-list-sites-handler-dev"
  "update_site" = "arn:aws:lambda:af-south-1:536580886816:function:bbws-update-site-handler-dev"
  "delete_site" = "arn:aws:lambda:af-south-1:536580886816:function:bbws-delete-site-handler-dev"
}
```

### Deployed Resources

| Resource Type | Name | ARN/URL |
|---------------|------|---------|
| Lambda Function | get-site-handler | arn:aws:lambda:af-south-1:536580886816:function:bbws-get-site-handler-dev |
| Lambda Function | list-sites-handler | arn:aws:lambda:af-south-1:536580886816:function:bbws-list-sites-handler-dev |
| Lambda Function | update-site-handler | arn:aws:lambda:af-south-1:536580886816:function:bbws-update-site-handler-dev |
| Lambda Function | delete-site-handler | arn:aws:lambda:af-south-1:536580886816:function:bbws-delete-site-handler-dev |
| API Gateway | Sites API | https://xxx.execute-api.af-south-1.amazonaws.com/dev |

---

## Rollback Procedure

If deployment fails or needs rollback:

### Option 1: Terraform Destroy (Full Rollback)
```bash
# Only if needed to completely remove new resources
terraform destroy -target=aws_lambda_function.get_site_handler
terraform destroy -target=aws_lambda_function.list_sites_handler
terraform destroy -target=aws_lambda_function.update_site_handler
terraform destroy -target=aws_lambda_function.delete_site_handler
```

### Option 2: Redeploy Previous Version
```bash
# Checkout previous working commit
git checkout <previous-commit>
terraform apply
```

### Option 3: AWS Console Manual Rollback
- Navigate to Lambda console
- Update function code to previous version
- Update API Gateway routes

---

## Post-Deployment Checklist

- [ ] Terraform apply completed successfully
- [ ] All 4 new Lambda functions deployed
- [ ] API Gateway routes created
- [ ] CloudWatch Log Groups created
- [ ] IAM roles/policies applied
- [ ] Quick smoke test passed
- [ ] Deployment documented in output.md

---

## Success Criteria

- [ ] Terraform apply completes without errors
- [ ] All Lambda functions show as "Active"
- [ ] API Gateway endpoints accessible
- [ ] No error logs in initial CloudWatch entries
- [ ] Smoke test returns valid responses

---

## Execution Steps

1. Verify AWS credentials for DEV account
2. Obtain explicit approval (DevOps Lead, Tech Lead)
3. Review saved plan one final time
4. Execute terraform apply
5. Monitor apply progress
6. Verify all resources deployed
7. Run quick smoke test
8. Document deployed resources in output.md
9. Update work.state to COMPLETE

---

## Important Notes

### Human Approval Required

**DO NOT** proceed with terraform apply without explicit approval. The deployment modifies production-like infrastructure and should only be done after:
1. Plan review completed
2. Tech Lead approval
3. DevOps Lead approval

### Environment Safety

- This deploys to DEV only
- DEV is the starting point for all changes
- After DEV validation, promote to SIT
- PROD is read-only and requires separate approval process

### Cost Considerations

- Lambda functions: Pay per invocation
- API Gateway: Pay per request
- CloudWatch Logs: Pay per GB ingested
- DynamoDB: On-demand pricing

Estimated additional cost for 4 handlers: Minimal (<$1/month in DEV)

---

**Status**: PENDING
**Created**: 2026-01-23
