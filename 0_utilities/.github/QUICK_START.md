# GitHub Actions Workflow - Quick Start Guide

## ⚡ 5-Minute Setup

### Prerequisites
- [ ] GitHub repository access
- [ ] AWS credentials configured for OIDC
- [ ] `AWS_ROLE_ARN` secret added to GitHub

### First Deployment

1. **Go to Actions tab** in GitHub
2. **Select**: "Sync Website to S3 & CloudFront"
3. **Click**: "Run workflow"
4. **Configure**:
   ```
   folder_name:     stafpro
   environment:     dev
   dry_run:         ✅ TRUE (check this!)
   delete_removed:  ⬜ false
   ```
5. **Click**: "Run workflow"
6. **Wait**: ~2 minutes
7. **Verify**: All steps green ✅

### Go Live

If dry run succeeds:

1. **Run workflow again** with:
   ```
   dry_run: ⬜ FALSE
   ```
2. **Visit**: `https://<cloudfront-domain>` (from logs)
3. **Verify**: Site loads correctly

## 🎯 Common Operations

### Deploy to Development

```
Folder:     <your-folder>
Environment: dev
Dry run:    ⬜ false
Delete:     ⬜ false
```

### Deploy to Production

```
Folder:     <your-folder>
Environment: prod
Dry run:    ⬜ false
Delete:     ⬜ false
```

### Preview Changes

```
Folder:     <your-folder>
Environment: dev
Dry run:    ✅ TRUE
Delete:     ⬜ false
```

### Clean Deployment (Remove Deleted Files)

```
Folder:     <your-folder>
Environment: dev
Dry run:    ⬜ false
Delete:     ✅ TRUE
```

## 🔧 Local Testing

```bash
# Navigate to scripts directory
cd scripts/03_upload

# Test validation
./sync.sh stafpro dev

# Expected output: All checks ✅
```

## 📋 Available Environments

| Environment | S3 Bucket | Use Case |
|------------|-----------|----------|
| `dev` | bigbeard-migrated-site-dev | Development/testing |
| `sit` | bigbeard-migrated-site-sit | System integration testing |
| `prod` | bigbeard-migrated-site-prod | Production |

## 🚨 Troubleshooting

### Workflow fails at authentication
→ Check: `AWS_ROLE_ARN` secret is set correctly
→ Go to: Settings → Secrets → AWS_ROLE_ARN

### Can't find local folder
→ Check: Folder exists in `extracted_sites/prod/`
→ Run locally: `ls extracted_sites/prod/<folder>`

### CloudFront not found
→ Check: Distribution exists for folder
→ Run: See [WORKFLOW_TESTING_GUIDE.md](./WORKFLOW_TESTING_GUIDE.md) for debug commands

### Site shows old content
→ Wait: Invalidation takes 1-5 minutes
→ Refresh: Ctrl+Shift+R (hard refresh)
→ Verify: Check invalidation status in logs

## 📚 Full Documentation

- **[SUMMARY.md](./SUMMARY.md)** - Overview and what was created
- **[DEPLOYMENT_PLAN.md](./DEPLOYMENT_PLAN.md)** - Detailed implementation plan
- **[WORKFLOW_TESTING_GUIDE.md](./WORKFLOW_TESTING_GUIDE.md)** - Complete testing procedures

## ✅ Success Checklist

- [ ] AWS OIDC configured
- [ ] `AWS_ROLE_ARN` secret added
- [ ] Local validation passes
- [ ] Dry run workflow succeeds
- [ ] Live deployment succeeds
- [ ] Site accessible via CloudFront
- [ ] Team trained on workflow

## 🎓 Learn More

See complete documentation for:
- Detailed testing procedures
- Error scenario handling
- Production deployment best practices
- Security considerations
- Monitoring and observability

---

**Need Help?** → See [WORKFLOW_TESTING_GUIDE.md](./WORKFLOW_TESTING_GUIDE.md) Troubleshooting section
