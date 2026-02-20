# Stage 4: CI/CD Pipeline Development

## Stage Overview

**Objective**: Create GitHub Actions workflows for automated Continuous Integration and Continuous Deployment (CI/CD) of both the React application and Terraform infrastructure across all environments (dev/sit/prod).

**Duration**: 3 workers executed sequentially

**Dependencies**:
- Stage 3 complete (Terraform infrastructure code ready)
- Stage 2 complete (React application ready)
- GitHub repositories created
- AWS credentials configured in GitHub Secrets

## Workers

### Worker 4-1: Build & Test Workflow
**Purpose**: Create GitHub Actions workflow for React application CI

**Deliverables**:
- `.github/workflows/build-test.yml` in 2_1_bbws_web_public repository
- Automated linting, testing, and build on every PR and push
- Build artifact caching for faster builds
- PR status checks

**Triggers**:
- Pull requests to main/master
- Push to main/master
- Manual workflow dispatch

**Steps**:
1. Checkout code
2. Setup Node.js 18.x
3. Cache npm dependencies
4. Install dependencies
5. Run ESLint
6. Run unit tests with coverage
7. Build React app
8. Upload build artifacts

### Worker 4-2: Infrastructure Deployment Workflow
**Purpose**: Create GitHub Actions workflow for Terraform infrastructure CI/CD

**Deliverables**:
- `.github/workflows/deploy-infrastructure.yml` in 2_1_bbws_infrastructure repository
- Terraform plan on pull requests
- Terraform apply on merge to main
- Multi-environment support (dev/sit/prod)
- State locking with DynamoDB
- Drift detection

**Triggers**:
- Pull requests: Run terraform plan
- Push to main: Run terraform apply for dev
- Manual workflow dispatch: Deploy to sit or prod with approval

**Steps**:
1. Checkout code
2. Setup Terraform 1.6+
3. Configure AWS credentials (OIDC or secrets)
4. Terraform init
5. Terraform validate
6. Terraform fmt check
7. Terraform plan (save plan artifact)
8. Terraform apply (on merge, with approval for prod)
9. Post deployment outputs

### Worker 4-3: Application Deployment Workflow
**Purpose**: Create GitHub Actions workflow for React app deployment to S3 and CloudFront

**Deliverables**:
- `.github/workflows/deploy-application.yml` in 2_1_bbws_web_public repository
- Automated deployment to S3 on merge to main
- CloudFront cache invalidation
- Multi-environment support
- Rollback capability

**Triggers**:
- Push to main: Deploy to dev automatically
- Manual workflow dispatch: Deploy to sit or prod with approval

**Steps**:
1. Checkout code
2. Setup Node.js 18.x
3. Install dependencies
4. Build React app (production mode)
5. Configure AWS credentials
6. Sync build artifacts to S3 bucket
7. Set appropriate cache headers
8. Create CloudFront invalidation
9. Verify deployment

## Technical Requirements

### GitHub Secrets Required

**AWS Credentials** (per environment):
- `AWS_ACCESS_KEY_ID_DEV` / `AWS_SECRET_ACCESS_KEY_DEV`
- `AWS_ACCESS_KEY_ID_SIT` / `AWS_SECRET_ACCESS_KEY_SIT`
- `AWS_ACCESS_KEY_ID_PROD` / `AWS_SECRET_ACCESS_KEY_PROD`

Or OIDC configuration:
- `AWS_ROLE_ARN_DEV`
- `AWS_ROLE_ARN_SIT`
- `AWS_ROLE_ARN_PROD`

**S3 Buckets**:
- `S3_BUCKET_DEV`: dev-kimmyai-web-public
- `S3_BUCKET_SIT`: sit-kimmyai-web-public
- `S3_BUCKET_PROD`: prod-kimmyai-web-public

**CloudFront Distribution IDs**:
- `CLOUDFRONT_DISTRIBUTION_ID_DEV`
- `CLOUDFRONT_DISTRIBUTION_ID_SIT`
- `CLOUDFRONT_DISTRIBUTION_ID_PROD`

### GitHub Actions Best Practices

1. **Use caching**: Cache npm dependencies and Terraform providers
2. **Use environments**: GitHub environments for prod approvals
3. **Use concurrency**: Prevent concurrent deployments to same environment
4. **Use matrix strategy**: Test against multiple Node versions if needed
5. **Use OIDC**: Prefer AWS OIDC over long-lived credentials
6. **Use artifacts**: Save build outputs and Terraform plans
7. **Use status checks**: Require CI to pass before merge

### Security Considerations

1. **Least privilege**: IAM roles with minimal permissions
2. **No hardcoded secrets**: Use GitHub Secrets
3. **Environment protection**: Require approvals for prod deployments
4. **Branch protection**: Protect main branch, require reviews
5. **OIDC trust**: Limit trust to specific repositories and branches
6. **Audit logs**: Enable CloudTrail for deployment tracking

## Environment Strategy

### DEV Environment
- **Trigger**: Automatic on push to main
- **Approval**: None required
- **Purpose**: Rapid iteration and testing
- **Basic Auth**: Enabled

### SIT Environment
- **Trigger**: Manual workflow dispatch
- **Approval**: Optional (recommended for testing approval flow)
- **Purpose**: User acceptance testing
- **Basic Auth**: Enabled

### PROD Environment
- **Trigger**: Manual workflow dispatch only
- **Approval**: Required (2 approvers recommended)
- **Purpose**: Live production traffic
- **Basic Auth**: Disabled

## Workflow Orchestration

### Deployment Sequence

**Infrastructure First**:
```
PR → Terraform Plan → Review → Merge → Terraform Apply (dev) → Manual (sit/prod)
```

**Application Deployment**:
```
PR → Build/Test → Review → Merge → Deploy (dev) → Manual (sit/prod)
```

### Rollback Strategy

**Infrastructure Rollback**:
- Revert Terraform code
- Re-run deployment workflow
- State rollback if needed (manual)

**Application Rollback**:
- Restore previous S3 version (versioning enabled)
- Invalidate CloudFront cache
- Or: Redeploy previous commit

## Success Criteria

- [ ] Build & Test workflow runs on every PR
- [ ] Infrastructure deployment workflow plans on PR, applies on merge
- [ ] Application deployment workflow deploys to dev automatically
- [ ] Manual deployments to sit/prod work correctly
- [ ] CloudFront invalidation completes successfully
- [ ] All workflows use proper secrets management
- [ ] Workflows include proper error handling
- [ ] Workflows post status updates (success/failure)

## Validation Steps

After creating all workflows:

1. **Test Build & Test**:
   - Create test PR with code change
   - Verify lint, test, and build steps pass
   - Merge PR

2. **Test Infrastructure Deployment**:
   - Create test PR with Terraform change
   - Verify plan output in PR comments
   - Merge and verify apply to dev
   - Test manual deployment to sit

3. **Test Application Deployment**:
   - Verify automatic deployment to dev after merge
   - Check S3 file upload
   - Check CloudFront invalidation
   - Verify site updates

4. **Test Approval Flow**:
   - Attempt prod deployment
   - Verify approval requirement
   - Complete approval and deployment

## Integration with Existing Infrastructure

### Repositories

**2_1_bbws_web_public**:
- Contains React application code
- Workflows: build-test.yml, deploy-application.yml
- Deploys to: S3 + CloudFront

**2_1_bbws_infrastructure**:
- Contains Terraform code
- Workflow: deploy-infrastructure.yml
- Manages: S3, CloudFront, Route 53, ACM, Lambda@Edge

### State Management

**Terraform State**:
- Backend: S3 + DynamoDB (already configured in Stage 3)
- Buckets: bbws-terraform-state-{dev|sit|prod}
- Lock tables: bbws-terraform-locks-{dev|sit|prod}

**S3 Versioning**:
- Enabled in Stage 3
- Allows rollback of application deployments

## Cost Considerations

**GitHub Actions**:
- Public repos: Free for public repositories
- Private repos: 2,000 minutes/month free, $0.008/minute after
- Storage: 500MB free, $0.25/GB after

**AWS Data Transfer**:
- S3 PUT requests: $0.005 per 1,000 requests
- CloudFront invalidations: First 1,000 paths free per month, $0.005 per path after

**Estimated Monthly Cost** (assuming 100 deployments/month):
- GitHub Actions: Free (within limits)
- S3 PUT requests: < $1
- CloudFront invalidations: Free (within limits)
- **Total**: ~$0-5/month

## Documentation

Each workflow will include:
- Inline comments explaining each step
- README section in repository root
- Troubleshooting guide for common issues
- Example manual deployment commands

## Next Steps After Stage 4

- **Stage 5**: Monitoring & Alerting (CloudWatch dashboards, alarms)
- **Stage 6**: Cost Optimization (S3 lifecycle, CloudFront optimization)
- **Stage 7**: Documentation (Runbooks, architecture diagrams)

## Notes

- All workflows follow GitHub Actions best practices
- Workflows are environment-aware using inputs and secrets
- Proper error handling and notifications included
- Workflows can be extended for additional environments
- Security scanning can be added later (Dependabot, CodeQL)
