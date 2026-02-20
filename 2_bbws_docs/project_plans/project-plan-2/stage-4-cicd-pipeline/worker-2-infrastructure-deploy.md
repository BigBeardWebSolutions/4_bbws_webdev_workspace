# Worker 4-2: Infrastructure Deployment Workflow

## Worker Identity
- **Worker ID**: 4-2
- **Worker Name**: Infrastructure Deployment Workflow Developer
- **Stage**: 4 - CI/CD Pipeline Development
- **Dependencies**: Stage 3 complete (Terraform infrastructure code)

## Objective

Create a comprehensive GitHub Actions workflow for Terraform infrastructure CI/CD. This workflow will automatically plan infrastructure changes on pull requests, apply changes on merge to main for dev environment, and support manual deployments to sit and prod with appropriate approvals.

## Deliverables

1. `.github/workflows/deploy-infrastructure.yml` in 2_1_bbws_infrastructure repository
2. Multi-environment deployment support (dev/sit/prod)
3. Terraform plan artifacts saved for review
4. PR comments with plan output
5. Environment protection rules documentation

## Technical Specifications

### Workflow Features

**Triggers**:
- Pull requests: Run terraform plan for all environments
- Push to main: Automatically apply to dev environment
- Workflow dispatch: Manual deployment to any environment with approval

**Jobs**:
1. **Validate**: Terraform fmt, validate, and security checks
2. **Plan**: Generate and save Terraform plans per environment
3. **Apply**: Apply Terraform changes (conditional based on trigger)
4. **Outputs**: Display Terraform outputs after apply

**Optimizations**:
- Terraform provider caching
- Matrix strategy for multi-environment planning
- Plan artifact reuse between plan and apply
- Concurrency control to prevent simultaneous deployments

### Workflow File Structure

```yaml
name: Deploy Infrastructure
on:
  pull_request:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        options: [dev, sit, prod]
      action:
        type: choice
        options: [plan, apply]

jobs:
  validate:
    # Validation job
  plan:
    # Planning job (matrix for environments)
  apply:
    # Apply job (with approval for prod)
  outputs:
    # Display outputs
```

### Environment Variables

**Terraform Version**: 1.6.0 or later

**AWS Configuration**:
- Region: From terraform.tfvars (dev/sit: eu-west-1, prod: af-south-1)
- Profile: Uses GitHub Secrets for credentials
- Backend: S3 + DynamoDB (configured in Terraform)

### Required GitHub Secrets

Per environment:
- `AWS_ACCESS_KEY_ID_DEV` / `AWS_SECRET_ACCESS_KEY_DEV`
- `AWS_ACCESS_KEY_ID_SIT` / `AWS_SECRET_ACCESS_KEY_SIT`
- `AWS_ACCESS_KEY_ID_PROD` / `AWS_SECRET_ACCESS_KEY_PROD`

Or OIDC (preferred):
- `AWS_ROLE_ARN_DEV`
- `AWS_ROLE_ARN_SIT`
- `AWS_ROLE_ARN_PROD`

### Required Steps

**Validate Job**:
1. Checkout repository
2. Setup Terraform 1.6+
3. Terraform fmt -check -recursive
4. Terraform init (all environments)
5. Terraform validate (all environments)
6. Optional: tfsec security scan

**Plan Job** (matrix: [dev, sit, prod]):
1. Checkout repository
2. Setup Terraform
3. Configure AWS credentials for environment
4. Terraform init (environment-specific)
5. Terraform plan -out=tfplan
6. Upload plan artifact
7. Comment plan output on PR (if PR)

**Apply Job**:
1. Download plan artifact
2. Setup Terraform
3. Configure AWS credentials
4. Terraform apply tfplan
5. Save apply output

**Outputs Job**:
1. Setup Terraform
2. Terraform output
3. Display CloudFront URL, S3 bucket, etc.

### Success Criteria

- Validate job fails on formatting or validation errors
- Plan job generates valid plan for each environment
- Apply job only runs on appropriate triggers
- Prod deployments require manual approval
- State locking prevents concurrent modifications
- Clear outputs displayed after successful apply

### Error Handling

- Workflow fails if any Terraform command fails
- State lock errors clearly reported
- Plan failures annotated in PR
- Apply failures trigger notifications
- Rollback instructions provided on failure

## Implementation Steps

### Step 1: Create Workflow Directory

Create `.github/workflows/` directory in 2_1_bbws_infrastructure repository.

### Step 2: Create Workflow File

Create `deploy-infrastructure.yml` with complete Terraform CI/CD configuration.

### Step 3: Configure AWS Authentication

Two options:

**Option A: Access Keys** (simpler but less secure):
```yaml
- name: Configure AWS Credentials
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID_DEV }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY_DEV }}
    AWS_REGION: eu-west-1
```

**Option B: OIDC** (recommended, more secure):
```yaml
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN_DEV }}
    aws-region: eu-west-1
```

### Step 4: Configure Environment Protection

In GitHub repository settings:
- Create environments: dev, sit, prod
- Prod environment: Require 1-2 reviewers
- Prod environment: Limit to main branch
- Optional: Add deployment branch restrictions

### Step 5: Add PR Comment Action

Use `hashicorp/setup-terraform@v3` with `terraform_wrapper: true` to enable PR comments:
```yaml
- uses: hashicorp/setup-terraform@v3
  with:
    terraform_version: 1.6.0
    terraform_wrapper: true
```

### Step 6: Implement Concurrency Control

Prevent concurrent deployments to same environment:
```yaml
concurrency:
  group: deploy-${{ github.event.inputs.environment || 'dev' }}
  cancel-in-progress: false
```

### Step 7: Test Workflow

1. Create test PR with Terraform change
2. Verify plan runs and comments on PR
3. Merge PR and verify auto-deploy to dev
4. Test manual deployment to sit

## Validation Checklist

- [ ] Workflow file created in `.github/workflows/deploy-infrastructure.yml`
- [ ] Workflow triggers on PR, push, and manual dispatch
- [ ] Validate job checks formatting and validates Terraform
- [ ] Plan job generates plans for all environments
- [ ] Plan output commented on PRs
- [ ] Auto-apply to dev on merge to main
- [ ] Manual deployment to sit works
- [ ] Prod deployment requires approval
- [ ] Concurrency control prevents conflicts
- [ ] State locking works correctly
- [ ] Outputs displayed after apply

## Example Workflow Output

**Successful Plan** (PR):
```
✅ Validate (45s)
✅ Plan - dev (1m 20s)
  + 5 resources to create
  ~ 2 resources to update
✅ Plan - sit (1m 15s)
  + 5 resources to create
  ~ 2 resources to update
✅ Plan - prod (1m 25s)
  + 5 resources to create
  ~ 2 resources to update

Total time: 4m 45s
```

**Successful Apply** (merge to main):
```
✅ Validate (45s)
✅ Plan - dev (1m 20s)
✅ Apply - dev (3m 45s)
  ✅ 5 resources created
  ✅ 2 resources updated
✅ Outputs
  cloudfront_url: https://d123abc.cloudfront.net
  s3_bucket: dev-kimmyai-web-public
  website_url: https://dev.kimmyai.io

Total time: 6m 30s
```

## Best Practices

1. **Use Terraform wrapper**: Enables PR comments with plan output
2. **Cache Terraform providers**: Speeds up workflow
3. **Use matrix strategy**: Plan all environments in parallel
4. **Save plan artifacts**: Ensure plan matches apply
5. **Implement concurrency control**: Prevent state conflicts
6. **Use environment protection**: Require approvals for prod
7. **Add timeout limits**: Prevent runaway Terraform operations
8. **Use tfsec or Checkov**: Scan for security issues

## Integration Points

### With Stage 3 (Infrastructure):
- Uses Terraform modules created in Stage 3
- Uses environment configurations from Stage 3
- Applies infrastructure to AWS

### With Worker 4-3 (Application Deployment):
- Infrastructure must be deployed before application
- Provides CloudFront distribution ID and S3 bucket name
- Creates resources needed for app deployment

## Security Considerations

- Use OIDC instead of long-lived access keys (recommended)
- Limit IAM permissions to least privilege
- Require approval for production deployments
- Enable CloudTrail logging for audit trail
- Store sensitive outputs as encrypted secrets
- Use Terraform state encryption (already configured in S3 backend)
- Rotate credentials regularly

## Troubleshooting Guide

**Issue**: State lock timeout
- **Solution**: Check for stuck locks in DynamoDB, manually release if needed
- Command: `terraform force-unlock <lock_id>`

**Issue**: Plan shows unexpected changes
- **Solution**: Check for manual changes in AWS console, import state if needed
- Command: `terraform import <resource> <id>`

**Issue**: Authentication failure
- **Solution**: Verify GitHub Secrets are set correctly, check IAM permissions

**Issue**: Provider plugin download fails
- **Solution**: Check network connectivity, verify Terraform version compatibility

**Issue**: Terraform init fails with backend error
- **Solution**: Verify S3 bucket and DynamoDB table exist, check credentials

## Environment-Specific Configurations

### DEV
- **Trigger**: Automatic on push to main
- **Approval**: Not required
- **Region**: eu-west-1
- **Purpose**: Continuous deployment for testing

### SIT
- **Trigger**: Manual workflow dispatch
- **Approval**: Optional (recommended for testing approval flow)
- **Region**: eu-west-1
- **Purpose**: User acceptance testing

### PROD
- **Trigger**: Manual workflow dispatch only
- **Approval**: Required (1-2 reviewers)
- **Region**: af-south-1
- **Purpose**: Production deployment
- **Additional checks**:
  - Deployment time restrictions (e.g., no Fridays)
  - Require tagged releases
  - Post-deployment verification

## Terraform State Management

**Backend Configuration** (from Stage 3):
- **DEV**: s3://bbws-terraform-state-dev/2-1-bbws-web-public/terraform.tfstate
- **SIT**: s3://bbws-terraform-state-sit/2-1-bbws-web-public/terraform.tfstate
- **PROD**: s3://bbws-terraform-state-prod/2-1-bbws-web-public/terraform.tfstate

**State Locking**:
- DynamoDB tables: bbws-terraform-locks-{dev|sit|prod}
- Lock timeout: 10 minutes (default)

## Future Enhancements

- Add drift detection on schedule (e.g., nightly)
- Add cost estimation with Infracost
- Add compliance scanning with Checkov
- Add Terraform docs generation
- Add Slack/Teams notifications for deployments
- Add deployment dashboard with status

## References

- [GitHub Actions for Terraform](https://learn.hashicorp.com/tutorials/terraform/github-actions)
- [hashicorp/setup-terraform](https://github.com/hashicorp/setup-terraform)
- [aws-actions/configure-aws-credentials](https://github.com/aws-actions/configure-aws-credentials)
- [Terraform State Locking](https://www.terraform.io/language/state/locking)
- [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)

## Completion Criteria

This worker is complete when:
1. Workflow file created and committed
2. GitHub Secrets configured for all environments
3. Environment protection rules configured
4. Test PR created and plan runs successfully
5. Test merge and auto-deploy to dev works
6. Manual deployment to sit tested
7. All validation checklist items checked
8. Workflow documented in repository README
