# Worker 4-3: Application Deployment Workflow

## Worker Identity
- **Worker ID**: 4-3
- **Worker Name**: Application Deployment Workflow Developer
- **Stage**: 4 - CI/CD Pipeline Development
- **Dependencies**:
  - Stage 2 complete (React application)
  - Worker 4-1 complete (Build & Test workflow)
  - Worker 4-2 complete (Infrastructure deployed)

## Objective

Create a comprehensive GitHub Actions workflow for deploying the React application to S3 and invalidating CloudFront cache. This workflow will automatically deploy to dev on merge to main, and support manual deployments to sit and prod with appropriate approvals and rollback capabilities.

## Deliverables

1. `.github/workflows/deploy-application.yml` in 2_1_bbws_web_public repository
2. Multi-environment deployment support (dev/sit/prod)
3. S3 sync with proper cache headers
4. CloudFront invalidation after deployment
5. Deployment verification steps
6. Rollback documentation

## Technical Specifications

### Workflow Features

**Triggers**:
- Push to main: Automatically deploy to dev
- Workflow dispatch: Manual deployment to any environment with approval
- Optional: Deploy on successful tag creation for releases

**Jobs**:
1. **Build**: Build production React bundle
2. **Deploy**: Sync to S3 and invalidate CloudFront
3. **Verify**: Check deployment success

**Optimizations**:
- Reuse build artifacts from Build & Test workflow (if available)
- Parallel S3 uploads for faster sync
- Targeted CloudFront invalidations
- Deployment status tracking

### Workflow File Structure

```yaml
name: Deploy Application
on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        options: [dev, sit, prod]
      version:
        description: 'Git tag or commit SHA to deploy'
        required: false

jobs:
  build:
    # Build production bundle
  deploy:
    # Deploy to S3 + invalidate CloudFront
  verify:
    # Verify deployment
```

### Environment Variables

**Node.js Version**: 18.x

**Build Configuration**:
- NODE_ENV: production
- Public URL: Environment-specific domain

**Deployment Configuration** (per environment):
- S3 Bucket: dev/sit/prod-kimmyai-web-public
- CloudFront Distribution ID: From Terraform outputs
- AWS Region: eu-west-1 (dev/sit), af-south-1 (prod)

### Required GitHub Secrets

Per environment:
- `AWS_ACCESS_KEY_ID_DEV` / `AWS_SECRET_ACCESS_KEY_DEV`
- `AWS_ACCESS_KEY_ID_SIT` / `AWS_SECRET_ACCESS_KEY_SIT`
- `AWS_ACCESS_KEY_ID_PROD` / `AWS_SECRET_ACCESS_KEY_PROD`
- `CLOUDFRONT_DISTRIBUTION_ID_DEV`
- `CLOUDFRONT_DISTRIBUTION_ID_SIT`
- `CLOUDFRONT_DISTRIBUTION_ID_PROD`

Or OIDC (preferred):
- `AWS_ROLE_ARN_DEV` / `AWS_ROLE_ARN_SIT` / `AWS_ROLE_ARN_PROD`

### Required Steps

**Build Job**:
1. Checkout repository (specific commit/tag if provided)
2. Setup Node.js 18.x
3. Restore npm cache
4. Install dependencies (npm ci)
5. Build production bundle (npm run build)
6. Upload build artifact (dist/ directory)

**Deploy Job**:
1. Download build artifact
2. Configure AWS credentials for target environment
3. Sync dist/ to S3 bucket:
   - Set long cache headers for static assets (1 year)
   - Set no-cache header for index.html
   - Use --delete flag to remove old files
4. Create CloudFront invalidation for changed paths
5. Wait for invalidation to complete
6. Save deployment metadata (timestamp, commit SHA, deployer)

**Verify Job**:
1. Wait for CloudFront invalidation
2. HTTP GET request to deployed URL
3. Check for 200 status code
4. Optional: Run smoke tests
5. Post deployment status

### Success Criteria

- Build produces optimized production bundle
- S3 sync uploads all files correctly
- Proper cache headers set on all files
- CloudFront invalidation completes successfully
- Deployed site returns 200 OK
- Deployment completes in < 5 minutes

### Error Handling

- Build failures prevent deployment
- S3 sync failures trigger rollback
- CloudFront invalidation failures reported but don't block
- Deployment failures trigger notifications
- Rollback procedure clearly documented

## Implementation Steps

### Step 1: Create Workflow File

Create `deploy-application.yml` with complete deployment configuration.

### Step 2: Configure S3 Sync

Use AWS CLI with optimized sync command:
```bash
aws s3 sync dist/ s3://$S3_BUCKET/ \
  --delete \
  --cache-control "public, max-age=31536000, immutable" \
  --exclude "index.html" \
  --exclude "*.map"

aws s3 cp dist/index.html s3://$S3_BUCKET/index.html \
  --cache-control "no-cache, no-store, must-revalidate" \
  --metadata-directive REPLACE
```

### Step 3: Configure CloudFront Invalidation

Create targeted invalidation for changed files:
```bash
aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "/*"
```

Or for specific paths only (cost optimization):
```bash
aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "/index.html" "/asset-manifest.json"
```

### Step 4: Add Deployment Verification

Check deployment success:
```bash
response=$(curl -s -o /dev/null -w "%{http_code}" https://dev.kimmyai.io)
if [ $response -eq 200 ]; then
  echo "Deployment verified successfully"
else
  echo "Deployment verification failed: HTTP $response"
  exit 1
fi
```

### Step 5: Configure Environment Protection

In GitHub repository settings:
- Create environments: dev, sit, prod
- Prod environment: Require 1-2 reviewers
- Optional: Limit deployment times (e.g., no Friday deployments)

### Step 6: Add Concurrency Control

Prevent concurrent deployments to same environment:
```yaml
concurrency:
  group: deploy-app-${{ github.event.inputs.environment || 'dev' }}
  cancel-in-progress: false
```

### Step 7: Test Workflow

1. Merge PR to main and verify auto-deploy to dev
2. Check S3 bucket contents and cache headers
3. Verify CloudFront serves updated content
4. Test manual deployment to sit
5. Test rollback procedure

## Validation Checklist

- [ ] Workflow file created in `.github/workflows/deploy-application.yml`
- [ ] Workflow triggers on push to main and manual dispatch
- [ ] Build job creates production bundle
- [ ] S3 sync uploads all files correctly
- [ ] Cache headers set correctly (long cache for assets, no-cache for index.html)
- [ ] Source maps excluded from deployment (security)
- [ ] CloudFront invalidation completes
- [ ] Deployment verification passes
- [ ] Auto-deploy to dev works on merge
- [ ] Manual deployment to sit works
- [ ] Prod deployment requires approval
- [ ] Concurrency control prevents conflicts
- [ ] Rollback procedure documented

## Example Workflow Output

**Successful Deployment**:
```
✅ Build (2m 15s)
  Bundle size: 245 KB (gzipped)

✅ Deploy to dev (1m 45s)
  Synced 23 files to S3
  Created CloudFront invalidation: I2X3Y4Z5A6B7

✅ Verify (30s)
  URL: https://dev.kimmyai.io
  Status: 200 OK
  Response time: 342ms

Total time: 4m 30s
```

**Failed Deployment** (S3 sync error):
```
✅ Build (2m 15s)

❌ Deploy to dev (45s)
  Error: Access Denied (S3 Bucket: dev-kimmyai-web-public)
  Check AWS credentials and S3 bucket policy

⏭️ Verify (skipped)

Deployment failed. No changes made to production.
```

## Best Practices

1. **Use specific AWS CLI version**: Ensure consistency
2. **Set proper cache headers**: Optimize performance
3. **Exclude source maps**: Don't expose to public
4. **Invalidate minimal paths**: Reduce costs
5. **Verify deployment**: Don't assume success
6. **Add deployment notifications**: Alert team of deployments
7. **Tag releases**: Use semantic versioning
8. **Monitor deployment metrics**: Track success rate and duration

## Cache Header Strategy

### Static Assets (JavaScript, CSS, images)
```
Cache-Control: public, max-age=31536000, immutable
```
- 1 year cache (files have content hash in filename)
- Immutable flag prevents revalidation

### HTML Files (index.html)
```
Cache-Control: no-cache, no-store, must-revalidate
Pragma: no-cache
Expires: 0
```
- Always revalidate
- Ensures users get latest version

### Service Worker (if applicable)
```
Cache-Control: no-cache
```
- Revalidate but allow caching

## Integration Points

### With Worker 4-1 (Build & Test):
- Can reuse build artifacts if workflow triggered together
- Same Node.js version for consistency
- Build validation before deployment

### With Worker 4-2 (Infrastructure):
- Requires infrastructure to be deployed first
- Uses CloudFront distribution ID from Terraform outputs
- Deploys to S3 bucket created by Terraform

### With Stage 2 (Frontend):
- Deploys React app built in Stage 2
- Uses build scripts from Stage 2
- Serves production bundle

## Security Considerations

- Use OIDC instead of long-lived access keys (recommended)
- Limit IAM permissions to S3 and CloudFront only
- Exclude source maps from production deployment
- Use environment protection for prod deployments
- Audit deployment logs in CloudWatch
- Implement deployment approval workflow
- Rotate credentials regularly

## Troubleshooting Guide

**Issue**: S3 sync fails with Access Denied
- **Solution**: Check IAM permissions, verify bucket policy allows CloudFront OAC

**Issue**: CloudFront still serves old content after invalidation
- **Solution**: Check invalidation status, wait for completion (can take 10-15 minutes)

**Issue**: Build artifact not found in deploy job
- **Solution**: Verify artifact upload in build job, check artifact retention settings

**Issue**: Deployment succeeds but site shows 404
- **Solution**: Check S3 sync actually uploaded files, verify CloudFront origin configuration

**Issue**: Cache headers not updating
- **Solution**: Use --metadata-directive REPLACE flag in S3 cp command

## Rollback Procedure

### Automatic Rollback (S3 Versioning)

S3 versioning was enabled in Stage 3. To rollback:

```bash
# List previous versions
aws s3api list-object-versions \
  --bucket dev-kimmyai-web-public \
  --prefix index.html

# Restore specific version
aws s3api copy-object \
  --bucket dev-kimmyai-web-public \
  --copy-source dev-kimmyai-web-public/index.html?versionId=VERSION_ID \
  --key index.html

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "/index.html"
```

### Manual Rollback (Redeploy Previous Commit)

```bash
# Trigger workflow with specific commit SHA
gh workflow run deploy-application.yml \
  -f environment=prod \
  -f version=abc123def
```

## Environment-Specific Configurations

### DEV
- **Trigger**: Automatic on push to main
- **Approval**: Not required
- **URL**: https://dev.kimmyai.io
- **CloudFront Invalidation**: All paths (/* )
- **Purpose**: Continuous deployment for testing

### SIT
- **Trigger**: Manual workflow dispatch
- **Approval**: Optional
- **URL**: https://sit.kimmyai.io
- **CloudFront Invalidation**: All paths
- **Purpose**: User acceptance testing

### PROD
- **Trigger**: Manual workflow dispatch only
- **Approval**: Required (1-2 reviewers)
- **URL**: https://kimmyai.io
- **CloudFront Invalidation**: Minimal paths (cost optimization)
- **Purpose**: Production deployment
- **Additional checks**:
  - Deploy only tagged releases
  - Deployment time window (e.g., 9 AM - 5 PM weekdays)
  - Post-deployment smoke tests required

## Deployment Metadata Tracking

Save deployment information for audit trail:

```yaml
- name: Save deployment metadata
  run: |
    cat > deployment-metadata.json <<EOF
    {
      "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
      "environment": "${{ github.event.inputs.environment || 'dev' }}",
      "commit_sha": "${{ github.sha }}",
      "commit_message": "${{ github.event.head_commit.message }}",
      "deployer": "${{ github.actor }}",
      "workflow_run": "${{ github.run_id }}",
      "s3_bucket": "${{ env.S3_BUCKET }}",
      "cloudfront_distribution": "${{ env.DISTRIBUTION_ID }}"
    }
    EOF

    aws s3 cp deployment-metadata.json \
      s3://$S3_BUCKET/.deployment/$(date +%Y%m%d-%H%M%S).json
```

## Future Enhancements

- Add smoke tests after deployment (Playwright or Cypress)
- Add performance monitoring (Lighthouse CI)
- Add deployment dashboards (show deployment history)
- Add automatic rollback on failed smoke tests
- Add deployment slack/teams notifications
- Add canary deployments (deploy to subset of CloudFront edge locations first)
- Add blue/green deployments
- Add deployment metrics to CloudWatch

## Cost Optimization

**S3 Costs**:
- PUT requests: $0.005 per 1,000 requests
- Typical deployment (100 files): ~$0.0005 per deployment

**CloudFront Invalidation**:
- First 1,000 paths free per month
- $0.005 per path after
- Recommendation: Invalidate only /index.html instead of /* to stay within free tier

**Estimated Monthly Cost** (100 deployments):
- S3 operations: < $1
- CloudFront invalidations: Free (if optimized)
- **Total**: < $1/month

## References

- [AWS CLI S3 sync](https://docs.aws.amazon.com/cli/latest/reference/s3/sync.html)
- [CloudFront Invalidation](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Invalidation.html)
- [S3 Versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html)
- [Cache-Control Headers](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control)
- [GitHub Actions Artifacts](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts)

## Completion Criteria

This worker is complete when:
1. Workflow file created and committed
2. GitHub Secrets configured for all environments
3. Environment protection rules configured
4. Test deployment to dev works automatically
5. Manual deployment to sit tested successfully
6. CloudFront invalidation verified
7. Cache headers validated (check with browser dev tools)
8. Rollback procedure tested
9. All validation checklist items checked
10. Workflow documented in repository README
