# Worker Instructions: Terraform Validation

**Worker ID**: worker-1-terraform-validation
**Stage**: Stage 4 - Deployment
**Project**: project-plan-4

---

## Task Description

Validate the Terraform infrastructure code to ensure it is syntactically correct, properly formatted, and will deploy the expected resources without errors. Generate a terraform plan for review before deployment.

---

## Inputs

**Terraform Files**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/terraform/`

**Terraform Modules**:
- `terraform/modules/lambda/`
- `terraform/modules/api_gateway/`
- `terraform/modules/dynamodb/`
- `terraform/modules/sqs/`
- `terraform/modules/iam/`

**Environment Config**:
- DEV environment variables and backend configuration

---

## Deliverables

### 1. Validation Report

Create `output.md` with:
- Terraform format check results
- Terraform validate results
- Terraform plan summary
- Any warnings or issues found

### 2. Terraform Plan Output

Save plan to file:
```bash
terraform plan -out=tfplan.out
```

---

## Validation Steps

### Step 1: Check Terraform Formatting

```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/terraform

# Check formatting (don't auto-fix)
terraform fmt -check -recursive

# If fails, show diff
terraform fmt -diff -recursive
```

**Expected Output**: All files properly formatted

### Step 2: Initialize Terraform

```bash
# Initialize with backend configuration for DEV
terraform init \
  -backend-config="bucket=bbws-terraform-state-dev" \
  -backend-config="key=wordpress-site-management/terraform.tfstate" \
  -backend-config="region=af-south-1" \
  -backend-config="dynamodb_table=bbws-terraform-locks-dev"
```

### Step 3: Validate Configuration

```bash
terraform validate
```

**Expected Output**: `Success! The configuration is valid.`

### Step 4: Generate Plan

```bash
# Set environment variables for DEV
export TF_VAR_environment="dev"
export TF_VAR_aws_account_id="536580886816"
export TF_VAR_aws_region="af-south-1"

# Generate plan
terraform plan \
  -var="environment=dev" \
  -var="aws_account_id=536580886816" \
  -var="aws_region=af-south-1" \
  -out=tfplan.out
```

### Step 5: Review Plan Output

Check the plan for:
- **Resources to add**: New Lambda handlers, API Gateway routes
- **Resources to change**: Updated configurations
- **Resources to destroy**: Should be none for new handlers
- **No hardcoded credentials**: Verify all secrets are parameterized

---

## Validation Checklist

### Terraform Format
- [ ] All .tf files properly formatted
- [ ] Consistent indentation
- [ ] No trailing whitespace

### Terraform Validate
- [ ] No syntax errors
- [ ] All required providers declared
- [ ] All variables have types defined
- [ ] All required variables have values or defaults

### Terraform Plan
- [ ] Plan completes without errors
- [ ] Expected resources to be created:
  - [ ] 4 new Lambda functions (handlers)
  - [ ] API Gateway routes for new endpoints
  - [ ] IAM permissions (if needed)
- [ ] No unexpected resource deletions
- [ ] No sensitive data in plan output

### Security Checks
- [ ] No hardcoded AWS credentials
- [ ] No hardcoded API keys
- [ ] IAM policies follow least privilege
- [ ] S3 buckets have public access blocked
- [ ] DynamoDB has encryption enabled

---

## Expected Output Format

```markdown
# Terraform Validation Output

## Summary

| Check | Status | Notes |
|-------|--------|-------|
| Format Check | PASS | All files properly formatted |
| Validate | PASS | Configuration is valid |
| Plan | PASS | 12 resources to add, 0 to change, 0 to destroy |

## Format Check Results

```
$ terraform fmt -check -recursive
[No output - all files formatted correctly]
```

## Validate Results

```
$ terraform validate
Success! The configuration is valid.
```

## Plan Summary

```
Plan: 12 to add, 0 to change, 0 to destroy.

Resources to add:
- aws_lambda_function.get_site_handler
- aws_lambda_function.list_sites_handler
- aws_lambda_function.update_site_handler
- aws_lambda_function.delete_site_handler
- aws_lambda_permission.get_site_handler
- aws_lambda_permission.list_sites_handler
- aws_lambda_permission.update_site_handler
- aws_lambda_permission.delete_site_handler
- aws_api_gateway_method.get_site
- aws_api_gateway_method.list_sites
- aws_api_gateway_method.update_site
- aws_api_gateway_method.delete_site
```

## Warnings

None

## Next Steps

1. Review plan output
2. Obtain approval from DevOps Lead
3. Proceed to worker-2-dev-deployment
```

---

## Success Criteria

- [ ] terraform fmt -check passes
- [ ] terraform validate passes
- [ ] terraform plan completes without errors
- [ ] Plan shows expected resource additions
- [ ] No unexpected resource deletions
- [ ] No security warnings
- [ ] Plan saved to tfplan.out

---

## Execution Steps

1. Navigate to terraform directory
2. Run format check
3. Initialize terraform with DEV backend
4. Run validation
5. Generate plan with DEV variables
6. Review plan output
7. Save plan to file
8. Create output.md with results
9. Update work.state to COMPLETE

---

## Troubleshooting

### Format Check Fails
```bash
# Auto-fix formatting
terraform fmt -recursive
# Then commit changes
```

### Validate Fails
- Check for missing providers
- Check for undefined variables
- Check for syntax errors in .tf files

### Plan Fails
- Verify AWS credentials configured
- Verify backend bucket exists
- Check variable values

---

**Status**: PENDING
**Created**: 2026-01-23
