# GitHub Actions Workflow - Testing & Usage Guide

## 🎯 Quick Start

### Prerequisites Checklist
- [ ] AWS OIDC configured for GitHub Actions
- [ ] IAM Role created with proper permissions
- [ ] `AWS_ROLE_ARN` secret added to GitHub repository
- [ ] Website folder exists in `extracted_sites/prod/`
- [ ] S3 bucket exists for target environment
- [ ] CloudFront distribution exists for the folder

### Running Your First Deployment

1. **Go to GitHub Actions tab** in your repository
2. **Select "Sync Website to S3 & CloudFront"** workflow
3. **Click "Run workflow"**
4. **Fill in the parameters**:
   - Folder name: `stafpro` (or any existing folder)
   - Environment: `dev`
   - Dry run: ✅ **Check this first!**
   - Delete removed: ⬜ Leave unchecked for first run
5. **Click "Run workflow"**

## 📋 Testing Checklist

### Phase 1: Local Validation (10 minutes)

Before running GitHub Actions, validate the script works locally:

```bash
cd scripts/03_upload

# Test 1: Basic validation (dev)
./sync.sh stafpro dev
# Expected: ✅ All checks pass, outputs summary

# Test 2: Production validation
./sync.sh stafpro prod
# Expected: ✅ Validates against prod bucket

# Test 3: GitHub Actions mode (simulated)
./sync.sh stafpro dev --github-actions
# Expected: ✅ Exports outputs (but $GITHUB_OUTPUT won't work locally)

# Test 4: Invalid folder
./sync.sh nonexistent dev
# Expected: ❌ Error: Local folder not found

# Test 5: Invalid environment
./sync.sh stafpro invalid
# Expected: ❌ Error: Invalid environment
```

**✅ Phase 1 Complete When:**
- All 5 tests produce expected results
- No script errors
- CloudFront IDs are correctly identified

### Phase 2: GitHub Actions Dry Run (15 minutes)

Test the workflow without making any changes:

#### Test 2.1: Dev Environment Dry Run

1. Navigate to: **Actions → Sync Website to S3 & CloudFront → Run workflow**

2. **Parameters**:
   ```
   folder_name:     stafpro
   environment:     dev
   dry_run:         ✅ true
   delete_removed:  ⬜ false
   ```

3. **Run and verify**:
   - ✅ Checkout completes
   - ✅ AWS authentication succeeds
   - ✅ Validation finds local folder
   - ✅ S3 bucket validated
   - ✅ CloudFront distribution found
   - ✅ Dry run shows what would be synced
   - ✅ No actual sync performed
   - ✅ No invalidation created

4. **Review logs** for any warnings or errors

#### Test 2.2: Different Folder

1. **Parameters**:
   ```
   folder_name:     amandakatzart
   environment:     dev
   dry_run:         ✅ true
   delete_removed:  ⬜ false
   ```

2. **Verify**:
   - ✅ Different CloudFront distribution found
   - ✅ Different S3 path shown
   - ✅ Dry run completes successfully

**✅ Phase 2 Complete When:**
- Both dry runs complete successfully
- CloudFront IDs are different for different folders
- No errors in logs

### Phase 3: Live Deployment (Dev) (20 minutes)

Perform actual deployment to dev environment:

#### Test 3.1: Initial Deployment

1. **Parameters**:
   ```
   folder_name:     stafpro
   environment:     dev
   dry_run:         ⬜ false
   delete_removed:  ⬜ false
   ```

2. **Monitor deployment**:
   - ✅ S3 sync completes
   - ✅ File count shown in logs
   - ✅ CloudFront invalidation created
   - ✅ Invalidation ID displayed
   - ✅ Wait for invalidation completes
   - ✅ Deployment summary shown

3. **Verify deployment**:
   ```bash
   # Check S3 bucket
   aws s3 ls s3://bigbeard-migrated-site-dev/stafpro/ --recursive

   # Check CloudFront
   DISTRIBUTION_ID="E2TL5KTZ3J5HXQ"  # From logs
   aws cloudfront get-distribution --id $DISTRIBUTION_ID

   # Visit the site
   DOMAIN=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.DomainName' --output text)
   echo "Visit: https://$DOMAIN"
   ```

4. **Accessibility check**:
   - ✅ Site loads in browser
   - ✅ No 403 errors
   - ✅ CSS/JS loading correctly
   - ✅ Images displaying

#### Test 3.2: Update Deployment

Make a small change to test updates:

1. **Modify a file locally**:
   ```bash
   echo "<!-- Updated $(date) -->" >> extracted_sites/prod/stafpro/index.html
   git add extracted_sites/prod/stafpro/index.html
   git commit -m "Test: Add timestamp to stafpro index.html"
   git push
   ```

2. **Run workflow again**:
   ```
   folder_name:     stafpro
   environment:     dev
   dry_run:         ⬜ false
   delete_removed:  ⬜ false
   ```

3. **Verify update**:
   - ✅ S3 sync shows updated file
   - ✅ Invalidation created
   - ✅ New content appears on site (may take 1-5 min)

#### Test 3.3: Delete Mode

Test the delete functionality:

1. **Create a test file**:
   ```bash
   echo "Test file" > extracted_sites/prod/stafpro/test-delete-me.txt
   ```

2. **Deploy with the test file**:
   ```
   folder_name:     stafpro
   environment:     dev
   dry_run:         ⬜ false
   delete_removed:  ⬜ false
   ```

3. **Verify file in S3**:
   ```bash
   aws s3 ls s3://bigbeard-migrated-site-dev/stafpro/test-delete-me.txt
   # Should exist
   ```

4. **Remove file locally**:
   ```bash
   rm extracted_sites/prod/stafpro/test-delete-me.txt
   git add extracted_sites/prod/stafpro/test-delete-me.txt
   git commit -m "Test: Remove test file"
   git push
   ```

5. **Deploy with delete mode**:
   ```
   folder_name:     stafpro
   environment:     dev
   dry_run:         ⬜ false
   delete_removed:  ✅ true
   ```

6. **Verify file removed from S3**:
   ```bash
   aws s3 ls s3://bigbeard-migrated-site-dev/stafpro/test-delete-me.txt
   # Should NOT exist
   ```

**✅ Phase 3 Complete When:**
- Initial deployment succeeds
- Update deployment works
- Delete mode removes files correctly
- Site is accessible and working

### Phase 4: Production Deployment (30 minutes)

**⚠️ IMPORTANT: Only proceed if Phase 3 is successful**

#### Test 4.1: Production Dry Run

1. **First, always do a dry run for prod**:
   ```
   folder_name:     stafpro
   environment:     prod
   dry_run:         ✅ true
   delete_removed:  ⬜ false
   ```

2. **Review carefully**:
   - ✅ Correct prod bucket shown
   - ✅ Correct CloudFront distribution
   - ✅ File changes look reasonable
   - ✅ No unexpected deletions

#### Test 4.2: Production Deployment

1. **Get approval** (if required by GitHub environment protection)

2. **Parameters**:
   ```
   folder_name:     stafpro
   environment:     prod
   dry_run:         ⬜ false
   delete_removed:  ⬜ false
   ```

3. **Monitor closely**:
   - ✅ S3 sync to prod bucket
   - ✅ Production CloudFront invalidation
   - ✅ Deployment summary

4. **Verify production site**:
   ```bash
   # Get production domain
   DISTRIBUTION_ID="<from-logs>"
   DOMAIN=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.DomainName' --output text)
   echo "Production URL: https://$DOMAIN"
   ```

5. **Full site check**:
   - ✅ Homepage loads
   - ✅ Navigation works
   - ✅ Forms functional (if applicable)
   - ✅ Mobile responsive
   - ✅ No console errors

**✅ Phase 4 Complete When:**
- Production deployment succeeds
- Site is live and functional
- No errors or issues

### Phase 5: Error Scenarios (15 minutes)

Test error handling:

#### Test 5.1: Non-existent Folder

```
folder_name:     this-folder-does-not-exist
environment:     dev
dry_run:         ✅ true
delete_removed:  ⬜ false
```

**Expected**:
- ❌ Validation fails
- ❌ Clear error message: "Local folder not found"
- ❌ Workflow fails gracefully

#### Test 5.2: Folder Without CloudFront

If you have a folder in S3 without a CloudFront distribution:

```
folder_name:     <folder-without-cf>
environment:     dev
dry_run:         ✅ true
delete_removed:  ⬜ false
```

**Expected**:
- ❌ Validation fails
- ❌ Error: "No CloudFront distribution found"
- ❌ Helpful debug command shown

#### Test 5.3: Wrong Environment

```
folder_name:     stafpro
environment:     <invalid>
dry_run:         ✅ true
delete_removed:  ⬜ false
```

**Expected**:
- ❌ Validation fails
- ❌ Error: "Invalid environment"

**✅ Phase 5 Complete When:**
- All error scenarios produce clear error messages
- Workflow fails gracefully
- No cryptic errors or hangs

## 🔍 Verification Commands

### Local Verification

```bash
# Check local folder exists
ls -la extracted_sites/prod/stafpro

# Check file count
find extracted_sites/prod/stafpro -type f | wc -l

# Run validation
./scripts/03_upload/sync.sh stafpro dev
```

### AWS Verification

```bash
# Check S3 bucket contents
aws s3 ls s3://bigbeard-migrated-site-dev/stafpro/ --recursive --human-readable --summarize

# Check CloudFront distribution
DISTRIBUTION_ID="E2TL5KTZ3J5HXQ"
aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.{Status:Status,DomainName:DomainName,Origins:Origins.Items[0].DomainName}'

# List recent invalidations
aws cloudfront list-invalidations --distribution-id $DISTRIBUTION_ID --query 'InvalidationList.Items[0:5]'

# Get specific invalidation status
INVALIDATION_ID="<from-workflow>"
aws cloudfront get-invalidation --distribution-id $DISTRIBUTION_ID --id $INVALIDATION_ID
```

### Site Accessibility

```bash
# Get CloudFront domain
DOMAIN=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.DomainName' --output text)

# Test site accessibility
curl -I "https://$DOMAIN"

# Check specific file
curl "https://$DOMAIN/index.html" | head -20

# Full wget test (download all files)
wget --spider --recursive --no-parent "https://$DOMAIN" 2>&1 | grep -B2 -A2 "404\|403\|500"
```

## 🐛 Troubleshooting Guide

### Issue: "AWS credentials not configured"

**Symptoms**: Workflow fails at authentication step

**Causes**:
1. `AWS_ROLE_ARN` secret not set
2. IAM role doesn't trust GitHub OIDC
3. Missing `permissions.id-token: write`

**Solutions**:
```bash
# Verify secret is set
# Go to: Settings → Secrets and variables → Actions → AWS_ROLE_ARN

# Check IAM role trust policy should include:
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::536580886816:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:your-org/your-repo:*"
      }
    }
  }]
}
```

### Issue: "Local folder not found"

**Symptoms**: Validation fails, can't find folder

**Causes**:
1. Folder doesn't exist in repository
2. Typo in folder name
3. Folder is in wrong location

**Solutions**:
```bash
# Check folder exists locally
ls -la extracted_sites/prod/<folder_name>

# Check in GitHub repository
# Browse to: extracted_sites/prod/ and verify folder exists

# Ensure folder is committed
git status
git add extracted_sites/prod/<folder_name>
git commit -m "Add folder"
git push
```

### Issue: "S3 folder does NOT exist"

**Symptoms**: S3 validation fails

**Causes**:
1. Folder not yet uploaded to S3
2. Wrong environment selected
3. Bucket doesn't exist

**Solutions**:
```bash
# Check if folder exists in S3
aws s3 ls s3://bigbeard-migrated-site-dev/<folder_name>/

# Create folder if needed (upload at least one file)
aws s3 cp extracted_sites/prod/<folder_name>/ s3://bigbeard-migrated-site-dev/<folder_name>/ --recursive

# Verify bucket exists
aws s3 ls s3://bigbeard-migrated-site-dev/
```

### Issue: "CloudFront distribution not found"

**Symptoms**: Can't find CloudFront distribution

**Causes**:
1. No CloudFront distribution created for this folder
2. OriginPath doesn't match folder name
3. Distribution uses different S3 bucket

**Solutions**:
```bash
# List all distributions for the bucket
aws cloudfront list-distributions \
  --query "DistributionList.Items[?Origins.Items[?DomainName=='bigbeard-migrated-site-dev.s3.eu-west-1.amazonaws.com']].{ID:Id,OriginPath:Origins.Items[0].OriginPath}" \
  --output json

# If distribution doesn't exist, create one (use Terraform or console)
# The OriginPath must be: /<folder_name>
```

### Issue: "Invalidation timeout"

**Symptoms**: Invalidation doesn't complete within timeout

**Causes**:
1. Large number of files
2. CloudFront is slow
3. AWS service issue

**Solutions**:
- This is usually harmless - invalidation will complete eventually
- Check AWS console for invalidation status
- Typical completion time: 1-5 minutes
- Maximum completion time: 15 minutes
- The workflow continues anyway (doesn't fail)

### Issue: "Site shows old content after deployment"

**Symptoms**: Deployed new version, but site shows old content

**Causes**:
1. CloudFront invalidation not completed yet
2. Browser cache
3. Invalidation paths incorrect

**Solutions**:
```bash
# Check invalidation status
aws cloudfront get-invalidation --distribution-id $DISTRIBUTION_ID --id $INVALIDATION_ID

# Force browser refresh
# Chrome/Firefox: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)

# Test with curl (bypasses browser cache)
curl -I "https://$DOMAIN/index.html"

# If needed, create manual invalidation
aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/*"
```

## 📊 Success Criteria

Your workflow is fully validated when:

- [ ] Local validation works for multiple folders
- [ ] GitHub Actions dry run succeeds
- [ ] Dev deployment completes successfully
- [ ] Site is accessible via CloudFront
- [ ] Updates are reflected after deployment
- [ ] Delete mode removes files correctly
- [ ] Production deployment succeeds
- [ ] Error scenarios fail gracefully with clear messages
- [ ] Team members can use workflow without assistance

## 🚀 Next Steps After Validation

Once all tests pass:

1. **Document for team**
   - Create runbook for common operations
   - Train team on workflow usage
   - Establish deployment approval process

2. **Enhance workflow**
   - Add Slack notifications
   - Add deployment badges
   - Add rollback functionality
   - Add multi-folder deployment

3. **Automate further**
   - Trigger on push to main branch
   - Auto-deploy dev environment
   - Schedule regular deployments

4. **Monitor and improve**
   - Track deployment success rate
   - Monitor deployment duration
   - Collect team feedback
   - Iterate on improvements

## 📝 Deployment Log Template

Use this template to track your test deployments:

```markdown
## Deployment Test: [Date]

**Folder**: stafpro
**Environment**: dev
**Test**: Initial deployment
**Dry Run**: No

### Results
- ✅ Validation: Passed
- ✅ S3 Sync: Completed in 45s
- ✅ Invalidation: Completed in 3m12s
- ✅ Site Accessible: Yes

### Issues
- None

### Notes
- All files synced correctly
- Site loads quickly
- No console errors
```

## 🆘 Getting Help

If you encounter issues not covered in this guide:

1. **Check workflow logs** in GitHub Actions
2. **Review validation output** from sync.sh script
3. **Check AWS CloudTrail** for API call details
4. **Consult documentation**:
   - [sync.sh README](../scripts/03_upload/README.md)
   - [Deployment Plan](./DEPLOYMENT_PLAN.md)
5. **Create an issue** with:
   - Workflow run URL
   - Error messages
   - What you were trying to do
   - What environment (dev/prod/sit)

---

**Last Updated**: 2025-12-05
**Maintained by**: DevOps Team
