# Product Lambda CI/CD Guide

**Service**: Product Lambda API
**CI/CD**: GitHub Actions
**Last Updated**: 2025-12-29

---

## CI/CD Overview

### Workflow Architecture
```
Developer Push → GitHub Actions → Quality Checks → Package → Deploy → Validate
```

### Environments
| Environment | Trigger | Approval | Deploy Time |
|-------------|---------|----------|-------------|
| DEV | Auto (push to main) | None | ~5-10 min |
| SIT | Manual | Required | ~8-12 min |
| PROD | Manual | Strict | ~10-15 min |

---

## Workflows

### 1. Deploy to DEV (.github/workflows/deploy-dev.yml)

**Trigger**: Automatic on push to main

**Stages**:
1. **Test** - Run pytest with 80%+ coverage
2. **Quality** - black, mypy, ruff checks
3. **Package** - Create Lambda ZIP files
4. **Deploy** - Terraform apply to DEV
5. **Validate** - Post-deployment checks

**Monitoring**:
```bash
# View workflow runs
gh run list --workflow=deploy-dev.yml

# Watch specific run
gh run watch RUN_ID

# View logs
gh run view RUN_ID --log
```

---

### 2. Deploy to SIT (.github/workflows/deploy-sit.yml)

**Trigger**: Manual workflow dispatch

**Confirmation**: Type "deploy"

**Stages**:
1. **Validate Input** - Check confirmation
2. **Test** - Full test suite
3. **Quality** - Code quality checks
4. **Package** - Create Lambda ZIPs
5. **Plan** - Terraform plan (sit-plan environment)
6. **Approval Gate** ⚠️
7. **Deploy** - Terraform apply (sit environment)
8. **Validate** - Post-deployment checks

**Execution**:
```bash
# Via GitHub UI
1. Navigate to Actions tab
2. Select "Deploy to SIT"
3. Click "Run workflow"
4. Enter "deploy" in confirmation field
5. Click "Run workflow" button
6. Wait for approval gate
7. Review Terraform plan
8. Approve deployment

# Via GitHub CLI
gh workflow run deploy-sit.yml -f confirm=deploy
```

---

### 3. Deploy to PROD (.github/workflows/deploy-prod.yml)

**Trigger**: Manual workflow dispatch

**Confirmation**: Type "deploy-to-production"

**Reason Required**: Deployment justification

**Stages**:
1. **Validate Input** - Check strict confirmation
2. **Test** - Full test suite
3. **Quality** - Code quality checks
4. **Package** - Create Lambda ZIPs (7-day retention)
5. **Plan** - Terraform plan (prod-plan environment)
6. **Strict Approval Gate** ⚠️⚠️
7. **Deploy** - Terraform apply (prod environment)
8. **Validate** - Post-deployment checks
9. **Logging** - Record deployment details

**Execution**:
```bash
# Via GitHub UI (ONLY method for PROD)
1. Navigate to Actions tab
2. Select "Deploy to PROD"
3. Click "Run workflow"
4. Enter "deploy-to-production" in confirmation field
5. Enter reason (e.g., "Security patch for CVE-2025-1234")
6. Click "Run workflow" button
7. Wait for approval gate
8. Review Terraform plan carefully
9. Get secondary approval (if required)
10. Approve deployment
```

---

## GitHub Actions Configuration

### Secrets Required
```bash
# AWS OIDC Configuration (configured via GitHub repo settings)
# - GitHub Actions connects via OIDC role
# - No long-lived credentials needed

# Verify OIDC role exists
aws iam get-role --role-name github-actions-oidc
```

### Environment Configuration

**DEV Environment**:
- No protection rules
- Auto-deploys on main push

**SIT Environment**:
- Required reviewers: 1
- Protection rules: Enabled

**PROD Environment**:
- Required reviewers: 2 (recommended)
- Protection rules: Strict
- Deployment branches: main only

**Configure Environments**:
```bash
# Via GitHub UI
1. Repository → Settings → Environments
2. Add environment (dev/sit/prod)
3. Configure protection rules
4. Add required reviewers
```

---

## Pipeline Components

### Testing Stage
```yaml
- name: Run tests with coverage
  run: |
    pytest --cov=src --cov-fail-under=80 --cov-report=term-missing
```

**What it does**:
- Runs all unit tests
- Requires 80%+ code coverage
- Fails pipeline if coverage < 80%

---

### Quality Stage
```yaml
- name: Run black formatting check
  run: black --check src/ tests/

- name: Run mypy type checking
  run: mypy src/

- name: Run ruff linting
  run: ruff check src/ tests/
```

**What it does**:
- Validates code formatting
- Checks type hints
- Lints code for issues

---

### Packaging Stage
```yaml
- name: Package Lambda functions
  run: |
    for handler in list_products get_product create_product update_product delete_product; do
      pip install -r requirements.txt -t dist/$handler/
      cp -r src dist/$handler/
      cd dist/$handler && zip -r ../$handler.zip . && cd ../..
    done
```

**What it does**:
- Installs dependencies for each Lambda
- Copies source code
- Creates ZIP files
- Uploads as artifacts

---

### Deployment Stage
```yaml
- name: Terraform Init
  run: terraform init -backend-config=...

- name: Terraform Plan
  run: terraform plan -var-file=environments/$ENV.tfvars -out=tfplan

- name: Terraform Apply
  run: terraform apply -auto-approve tfplan
```

**What it does**:
- Initializes Terraform with S3 backend
- Creates deployment plan
- Applies infrastructure changes
- Deploys Lambda functions

---

## Troubleshooting Pipelines

### Pipeline Fails at Test Stage
```bash
# View test output
gh run view RUN_ID --log | grep -A 20 "Run tests"

# Common causes:
# - Test failures
# - Coverage < 80%
# - Import errors

# Fix and re-run
git commit --amend
git push --force
```

### Pipeline Fails at Quality Stage
```bash
# Format code locally
black src/ tests/

# Fix type errors
mypy src/

# Fix lint issues
ruff check --fix src/ tests/

# Commit fixes
git add . && git commit -m "fix: code quality issues"
git push
```

### Pipeline Fails at Packaging
```bash
# Check requirements.txt
cat requirements.txt

# Test packaging locally
./scripts/package_lambdas.sh
ls -lh dist/*.zip

# Verify ZIP contents
unzip -l dist/list_products.zip
```

### Pipeline Fails at Terraform Apply
```bash
# Check Terraform state lock
aws dynamodb get-item \
  --table-name terraform-state-lock-dev \
  --key '{"LockID": {"S": "bbws-terraform-state-dev/product-lambda/dev/terraform.tfstate"}}'

# Force unlock if stuck
terraform force-unlock LOCK_ID

# Re-run workflow
gh run rerun RUN_ID
```

---

## Monitoring Deployments

### Real-time Monitoring
```bash
# Watch deployment
gh run watch

# Follow logs
gh run view --log-failed

# Check specific job
gh run view RUN_ID --job=JOB_ID
```

### Post-Deployment Validation
```bash
# Check Lambda functions
aws lambda list-functions | grep bbws-product

# Test API
curl https://api.kimmyai.io/v1/v1.0/products

# Check CloudWatch logs
aws logs tail /aws/lambda/bbws-product-list-dev --follow
```

---

## Rollback Procedures

### Rollback via Git Revert
```bash
# Identify bad commit
git log --oneline

# Revert commit
git revert BAD_COMMIT_HASH

# Push (triggers auto-deploy to DEV)
git push origin main
```

### Manual Rollback
```bash
# Checkout previous version
git checkout GOOD_COMMIT_HASH

# Force push (use with caution)
git push --force origin main
```

---

## Best Practices

1. **Always run tests locally** before pushing
2. **Use feature branches** for development
3. **Write descriptive commit messages**
4. **Monitor deployments** in GitHub Actions
5. **Review Terraform plans** carefully before approval
6. **Test in DEV** before promoting to SIT/PROD
7. **Document changes** in commit messages
8. **Keep dependencies updated** regularly

---

**Related**: `product_lambda_deployment.md`, `product_lambda_dev_setup.md`
