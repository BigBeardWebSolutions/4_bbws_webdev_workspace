# Section 7: CI/CD Pipeline Design

**LLD Document**: `2.1.8_LLD_S3_and_DynamoDB.md`
**Section**: 7 - CI/CD Pipeline Design
**Version**: 1.0
**Date**: 2025-12-25
**Worker**: worker-2-6-cicd-pipeline-design-section

---

## 7.1 Overview

### 7.1.1 Purpose and Philosophy

The CI/CD pipeline automates deployment of DynamoDB tables and S3 buckets across three environments (DEV, SIT, PROD) while enforcing human approval gates at critical decision points.

**Core Principles:**
- **Automate the Predictable**: Validation, testing, plan generation
- **Gate the Critical**: Deployment approvals, environment promotions
- **No Auto-Deploy**: All deployments require explicit human trigger
- **Progressive Hardening**: DEV (1 approver) → SIT (2 approvers) → PROD (3 approvers)
- **Rollback Ready**: Tagged deployments enable quick recovery (< 15 min RTO)

**Integration Points:**
- GitHub Actions for workflow execution
- GitHub Environments for approval gates
- AWS OIDC for secure authentication (no long-lived credentials)
- Slack for PROD notifications
- S3 + DynamoDB for Terraform state management

---

## 7.2 Pipeline Architecture

### 7.2.1 Pipeline Stages

```
┌─────────────────────────────────────────────────────────────────────┐
│                     CI/CD PIPELINE ARCHITECTURE                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  STAGE 1: VALIDATION (Automated)                                   │
│  ├─ Trigger: Push to main, Pull Request                            │
│  ├─ JSON schema validation                                         │
│  ├─ HTML template validation                                       │
│  ├─ terraform fmt + validate                                       │
│  ├─ tfsec security scan                                            │
│  └─ infracost estimation                                           │
│                                                                     │
│  STAGE 2: TERRAFORM PLAN (Automated)                               │
│  ├─ Generate plans for DEV, SIT, PROD (parallel)                   │
│  ├─ Post plans as PR comments                                      │
│  └─ Store plan artifacts (30-day retention)                        │
│                                                                     │
│  GATE 1: PLAN REVIEW (Manual - Non-Blocking)                       │
│  └─ Team reviews terraform plans, merges PR if acceptable          │
│                                                                     │
│  STAGE 3: DEPLOY DEV (Manual Trigger + Approval)                   │
│  ├─ GitHub Environment: dev (1 approver)                           │
│  ├─ terraform apply (dev.tfvars)                                   │
│  ├─ Post-deployment validation tests                               │
│  └─ Tag deployment: deploy-dev-{timestamp}                         │
│                                                                     │
│  STAGE 4: PROMOTE SIT (Manual Trigger + Approval)                  │
│  ├─ GitHub Environment: sit (2 approvers)                          │
│  ├─ Prerequisites: DEV tests passed                                │
│  ├─ terraform apply (sit.tfvars)                                   │
│  └─ Integration tests                                              │
│                                                                     │
│  STAGE 5: PROMOTE PROD (Manual Trigger + Approval)                 │
│  ├─ GitHub Environment: prod (3 approvers)                         │
│  ├─ Prerequisites: SIT tests passed, change ticket created         │
│  ├─ terraform apply (prod.tfvars)                                  │
│  ├─ Smoke tests                                                    │
│  └─ Slack notification                                             │
│                                                                     │
│  STAGE 6: ROLLBACK (Manual Trigger + Approval)                     │
│  ├─ Select environment and state version/tag                       │
│  ├─ Same approval requirements as deployment                       │
│  └─ Restore state and apply                                        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 7.2.2 State Management Architecture

**State Isolation:**
```
S3 Backend per Environment:
├─ bbws-terraform-state-dev (Account: 536580886816)
├─ bbws-terraform-state-sit (Account: 815856636111)
└─ bbws-terraform-state-prod (Account: 093646564004)

State File per Component (blast radius reduction):
├─ 2_1_bbws_dynamodb_schemas/
│   ├─ tenants/terraform.tfstate
│   ├─ products/terraform.tfstate
│   └─ campaigns/terraform.tfstate
└─ 2_1_bbws_s3_schemas/
    └─ templates/terraform.tfstate

Lock Tables per Environment:
├─ terraform-state-lock-dev
├─ terraform-state-lock-sit
└─ terraform-state-lock-prod
```

**Benefits:**
- Environment isolation prevents cross-environment impact
- Component isolation enables independent deployments
- S3 versioning enables rollback to any previous state
- DynamoDB locking prevents concurrent modifications

---

## 7.3 GitHub Actions Workflows

### 7.3.1 Workflow Matrix

| Workflow | Trigger | Approval | Purpose |
|----------|---------|----------|---------|
| `validate-schemas.yml` | Push, PR | No | Validate JSON schemas and terraform |
| `validate-templates.yml` | Push, PR | No | Validate HTML templates |
| `terraform-plan.yml` | After validation | No | Generate terraform plans for all envs |
| `terraform-apply.yml` | Manual dispatch | Yes | Deploy to selected environment |
| `rollback.yml` | Manual dispatch | Yes | Rollback to previous state |
| `post-deploy-tests.yml` | After apply | No | Post-deployment validation |

### 7.3.2 Workflow: `validate-schemas.yml`

**Purpose**: Validate DynamoDB schemas and Terraform configuration

**Key Jobs:**
1. **validate-json-syntax**: Use `jq` to check JSON syntax
2. **terraform-format**: Run `terraform fmt -check -recursive`
3. **terraform-validate**: Run `terraform validate` (with `-backend=false`)
4. **security-scan**: Run `tfsec` (fail on HIGH/CRITICAL)
5. **cost-estimate**: Run `infracost` and post to PR

**Example Steps:**
```yaml
jobs:
  validate-json-syntax:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Validate JSON
        run: for file in schemas/**/*.json; do jq empty "$file" || exit 1; done

  terraform-format:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      - run: terraform fmt -check -recursive

  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: aquasecurity/tfsec-action@v1.0.0
```

### 7.3.3 Workflow: `validate-templates.yml`

**Purpose**: Validate HTML email templates

**Key Jobs:**
1. **html-syntax**: Use `html-tidy` to validate HTML
2. **mustache-variables**: Validate `{{variable}}` placeholders
3. **render-test**: Test template rendering with sample data

### 7.3.4 Workflow: `terraform-plan.yml`

**Purpose**: Generate Terraform plans for review

**Trigger:**
```yaml
on:
  workflow_run:
    workflows: ["Validate DynamoDB Schemas", "Validate HTML Templates"]
    types: [completed]
  pull_request:
    branches: [main]
    paths: ['terraform/**']
```

**Key Steps** (matrix strategy for all environments):
```yaml
jobs:
  plan:
    strategy:
      matrix:
        environment: [dev, sit, prod]
    steps:
      - uses: actions/checkout@v3
      - uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: ${{ secrets[format('AWS_ROLE_{0}', upper(matrix.environment))] }}
          aws-region: af-south-1
      - uses: hashicorp/setup-terraform@v2
      - name: Terraform Init
        run: |
          terraform init \
            -backend-config="bucket=bbws-terraform-state-${{ matrix.environment }}" \
            -backend-config="key=2_1_bbws_dynamodb_schemas/terraform.tfstate"
      - name: Terraform Plan
        run: terraform plan -var-file=${{ matrix.environment }}.tfvars -out=tfplan
      - uses: actions/upload-artifact@v3
        with:
          name: tfplan-${{ matrix.environment }}
          path: terraform/${{ matrix.environment }}/tfplan
      - name: Post Plan to PR
        uses: actions/github-script@v6
        # Posts plan output as PR comment
```

### 7.3.5 Workflow: `terraform-apply.yml`

**Purpose**: Deploy infrastructure to selected environment

**Trigger:**
```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        options: [dev, sit, prod]
      confirmation:
        description: 'Type "deploy-{env}" to confirm'
        required: true
      use_stored_plan:
        type: boolean
        default: true
```

**Key Jobs:**
1. **validate-confirmation**: Verify confirmation string matches
2. **deploy** (uses GitHub Environment for approval gate)
3. **post-deploy-validation**: Run automated tests
4. **notify**: Send Slack notification (PROD only)

**Critical Steps:**
```yaml
jobs:
  deploy:
    environment:
      name: ${{ github.event.inputs.environment }}
      url: https://${{ github.event.inputs.environment }}.api.kimmyai.io
    steps:
      - uses: actions/checkout@v3
      - uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: ${{ secrets[format('AWS_ROLE_{0}', upper(github.event.inputs.environment))] }}
          aws-region: af-south-1
      - uses: hashicorp/setup-terraform@v2
      - name: Download Stored Plan
        if: ${{ github.event.inputs.use_stored_plan }}
        uses: actions/download-artifact@v3
      - name: Terraform Apply
        run: terraform apply tfplan  # or -auto-approve if no plan
      - name: Tag Deployment
        run: |
          tag="deploy-${{ github.event.inputs.environment }}-$(date +%Y%m%d-%H%M%S)"
          git tag -a "$tag" -m "Deployment to ${{ github.event.inputs.environment }}"
          git push origin "$tag"
      - name: Notify Slack (PROD only)
        if: ${{ github.event.inputs.environment == 'prod' }}
        uses: slackapi/slack-github-action@v1.24.0
```

### 7.3.6 Workflow: `rollback.yml`

**Purpose**: Rollback infrastructure to previous state

**Trigger:**
```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        options: [dev, sit, prod]
      state_version_id:
        description: 'S3 state version ID to restore'
      deployment_tag:
        description: 'OR: Git tag to rollback to'
      confirmation:
        description: 'Type "rollback-{env}" to confirm'
```

**Key Steps:**
```yaml
jobs:
  rollback:
    environment: ${{ github.event.inputs.environment }}
    steps:
      - name: Checkout deployment tag
        if: ${{ github.event.inputs.deployment_tag != '' }}
        run: git checkout ${{ github.event.inputs.deployment_tag }}
      - name: Restore state version
        if: ${{ github.event.inputs.state_version_id != '' }}
        run: |
          aws s3api get-object \
            --bucket bbws-terraform-state-${{ github.event.inputs.environment }} \
            --version-id ${{ github.event.inputs.state_version_id }} \
            terraform.tfstate.backup
          terraform state push terraform.tfstate.backup
      - name: Terraform Plan (rollback preview)
        run: terraform plan -var-file=${{ github.event.inputs.environment }}.tfvars
      - name: Terraform Apply (execute rollback)
        run: terraform apply -auto-approve
```

### 7.3.7 Workflow: `post-deploy-tests.yml`

**Purpose**: Automated post-deployment validation

**Key Tests:**
1. **DynamoDB**: Verify tables exist, GSIs created, tags applied
2. **S3**: Verify buckets exist, public access blocked, versioning enabled
3. **Templates**: Verify templates uploaded and accessible
4. **Backups**: Verify PITR enabled, backup plans configured

**Example Test:**
```yaml
jobs:
  test-dynamodb:
    steps:
      - name: Test table existence
        run: |
          python -c "
          import boto3
          dynamodb = boto3.client('dynamodb', region_name='af-south-1')
          for table in ['tenants', 'products', 'campaigns']:
              response = dynamodb.describe_table(TableName=table)
              assert response['Table']['TableStatus'] == 'ACTIVE'
          "
```

---

## 7.4 Environment-Specific Configuration

### 7.4.1 Configuration Matrix

| Setting | DEV | SIT | PROD |
|---------|-----|-----|------|
| **AWS Account** | 536580886816 | 815856636111 | 093646564004 |
| **Required Approvers** | 1 (Lead Dev) | 2 (Tech Lead + QA) | 3 (Tech Lead + PO + DevOps) |
| **Deployment Window** | Anytime | Business hours (8am-5pm SAST) | Change window only |
| **Post-Deploy Tests** | Basic validation | Integration tests | Smoke tests + validation |
| **Slack Notifications** | No | Optional | **Required** |
| **Change Ticket** | No | No | **Required** |
| **Approval Timeout** | 24 hours | 24 hours | 24 hours |
| **Rollback RTO** | Best effort | < 30 min | < 15 min |

### 7.4.2 GitHub Environment Settings

**DEV Environment:**
```yaml
environment:
  name: dev
  protection_rules:
    required_reviewers: 1
    reviewers: ["lead-developer"]
    deployment_branches: ["main"]
```

**SIT Environment:**
```yaml
environment:
  name: sit
  protection_rules:
    required_reviewers: 2
    reviewers: ["tech-lead", "qa-lead"]
    deployment_branches: ["main"]
```

**PROD Environment:**
```yaml
environment:
  name: prod
  protection_rules:
    required_reviewers: 3
    reviewers: ["tech-lead", "product-owner", "devops-lead"]
    deployment_branches: ["main"]
    prevent_self_review: true
```

### 7.4.3 Deployment Window Enforcement

**SIT: Business Hours Check**
```yaml
- name: Check deployment window
  if: ${{ github.event.inputs.environment == 'sit' }}
  run: |
    hour=$(date +%H)
    day=$(date +%u)
    if [ $day -gt 5 ] || [ $hour -lt 8 ] || [ $hour -gt 17 ]; then
      echo "ERROR: SIT deployments only during business hours (Mon-Fri 8am-5pm SAST)"
      exit 1
    fi
```

**PROD: Change Window Validation**
```yaml
- name: Validate change ticket
  if: ${{ github.event.inputs.environment == 'prod' }}
  run: |
    if [ -z "${{ github.event.inputs.change_ticket }}" ]; then
      echo "ERROR: Change ticket required for PROD"
      exit 1
    fi
    python scripts/validate_change_ticket.py --ticket ${{ github.event.inputs.change_ticket }}
```

---

## 7.5 Secrets Management

### 7.5.1 GitHub Secrets

**AWS IAM Roles** (OIDC authentication):
| Secret Name | Value | Usage |
|-------------|-------|-------|
| `AWS_ROLE_DEV` | `arn:aws:iam::536580886816:role/bbws-terraform-deployer-dev` | DEV deployments |
| `AWS_ROLE_SIT` | `arn:aws:iam::815856636111:role/bbws-terraform-deployer-sit` | SIT deployments |
| `AWS_ROLE_PROD` | `arn:aws:iam::093646564004:role/bbws-terraform-deployer-prod` | PROD deployments |

**Slack Webhooks**:
| Secret Name | Usage |
|-------------|-------|
| `SLACK_WEBHOOK_DEV` | DEV alerts (optional) |
| `SLACK_WEBHOOK_SIT` | SIT alerts (optional) |
| `SLACK_WEBHOOK_PROD` | PROD alerts (**mandatory**) |

### 7.5.2 IAM Role Configuration

**Trust Policy** (OIDC):
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::{ACCOUNT}:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
        "token.actions.githubusercontent.com:sub": "repo:org/2_1_bbws_dynamodb_schemas:ref:refs/heads/main"
      }
    }
  }]
}
```

**Permissions Policy** (summary):
- DynamoDB: CreateTable, UpdateTable, DeleteTable, DescribeTable, TagResource
- S3: CreateBucket, PutBucket*, GetBucket*, ListBucket, PutObject, GetObject
- State Management: S3 GetObject/PutObject on state bucket, DynamoDB PutItem/GetItem on lock table

### 7.5.3 Secret Rotation

| Secret Type | Rotation Frequency | Owner |
|-------------|-------------------|-------|
| AWS IAM Roles (OIDC) | No rotation needed | DevOps (temporary credentials) |
| Slack Webhooks | Annually or on compromise | DevOps |

---

## 7.6 Approval Gates

### 7.6.1 Gate Overview

| Gate | Trigger | Type | Approvers |
|------|---------|------|-----------|
| **Plan Review** | After terraform plan | Informal | Any team member |
| **DEV Deploy** | Manual workflow dispatch | GitHub Environment | 1 (Lead Dev) |
| **SIT Promote** | Manual workflow dispatch | GitHub Environment | 2 (Tech Lead + QA) |
| **PROD Promote** | Manual workflow dispatch | GitHub Environment | 3 (Tech Lead + PO + DevOps) |
| **Rollback** | Manual workflow dispatch | GitHub Environment | Same as deployment |

### 7.6.2 Approval Criteria

**DEV Deployment:**
- [ ] Terraform plan reviewed
- [ ] Changes align with requirements
- [ ] No active development conflicts

**SIT Promotion:**
- [ ] DEV deployment successful
- [ ] DEV tests passed
- [ ] Integration test plan prepared
- [ ] Deployment window appropriate

**PROD Promotion:**
- [ ] SIT deployment successful
- [ ] SIT tests passed
- [ ] Business stakeholders validated
- [ ] Change ticket created and approved
- [ ] Rollback plan documented
- [ ] On-call team notified

**Rollback:**
- [ ] Incident severity justifies rollback
- [ ] Correct state version selected
- [ ] Impact understood
- [ ] Communication plan in place

### 7.6.3 Approval Notification

Slack notification when approval required:
```json
{
  "text": "⏳ Approval Required: PROD Deployment",
  "blocks": [{
    "type": "section",
    "text": {
      "type": "mrkdwn",
      "text": "*Approval Required*\n\nEnvironment: `prod`\nRequested by: @user\nApprovers needed: 3\n<https://github.com/org/repo/actions/runs/123|Approve>"
    }
  }]
}
```

---

## 7.7 Deployment Strategy

### 7.7.1 Deployment Flow

```
1. DEVELOPER CREATES PR
   └─ Validation + terraform plans run automatically

2. TEAM REVIEWS PR
   └─ Review code, plans, cost estimates → Merge PR

3. DEPLOY TO DEV (Manual)
   └─ 1 approver → terraform apply → tests → tag deployment

4. VALIDATE IN DEV
   └─ Automated + manual testing → Sign-off

5. PROMOTE TO SIT (Manual)
   └─ 2 approvers → terraform apply → integration tests → tag

6. VALIDATE IN SIT
   └─ QA + business validation → Sign-off

7. PROMOTE TO PROD (Manual)
   └─ Change ticket → 3 approvers → apply → smoke tests → notify

8. VALIDATE IN PROD
   └─ Smoke tests → monitoring → business validation

9. MONITOR (24-48 hours)
   └─ CloudWatch alarms → error rates → rollback if needed
```

### 7.7.2 Rollback Strategy

**Rollback Triggers:**
- Terraform apply fails
- Post-deployment tests fail
- Critical functionality broken
- Performance degradation
- Security vulnerability

**Rollback Decision Matrix:**
| Severity | DEV | SIT | PROD |
|----------|-----|-----|------|
| P0 (System down) | Immediate | Immediate | **Immediate** |
| P1 (Major feature broken) | < 1 hour | < 30 min | **Immediate** |
| P2 (Minor feature broken) | Fix forward | Rollback or fix | **Rollback preferred** |
| P3 (Cosmetic) | Fix forward | Fix forward | Fix next release |

**Rollback Process:**
1. Trigger rollback workflow
2. Select environment and state version/tag
3. Approval (same as deployment)
4. Execute rollback
5. Verify recovery
6. Document incident

**Rollback RTO Targets:**
- DEV: Best effort
- SIT: < 30 minutes
- PROD: < 15 minutes

---

## 7.8 Monitoring and Notifications

### 7.8.1 Workflow Monitoring

**GitHub Actions Metrics:**
- Workflow success rate
- Average deployment time
- Time in approval queue
- Rollback frequency

**State Lock Monitoring:**
```python
# Alert if lock held > 30 minutes
import boto3
dynamodb = boto3.client('dynamodb')
response = dynamodb.scan(TableName='terraform-state-lock-prod')
if response['Items']:
    print(f"WARNING: {len(response['Items'])} active locks")
```

### 7.8.2 Slack Notifications

**Notification Events:**
1. **Deployment Started** (PROD only)
2. **Deployment Completed** (PROD only)
3. **Deployment Failed** (all environments)
4. **Approval Required** (all environments)
5. **Rollback Executed** (all environments)

**Slack Channels:**
- `#dev-alerts`: DEV notifications
- `#sit-alerts`: SIT notifications
- `#prod-alerts`: PROD notifications (**mandatory**)
- `#oncall-alerts`: Critical PROD issues

**Notification Template:**
```json
{
  "text": "✅ PROD Deployment Complete",
  "blocks": [
    {
      "type": "section",
      "fields": [
        {"type": "mrkdwn", "text": "*Environment:*\nprod"},
        {"type": "mrkdwn", "text": "*Deployed by:*\n@user"},
        {"type": "mrkdwn", "text": "*Duration:*\n5m 23s"}
      ]
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*Resources:*\n• 3 DynamoDB tables created\n• 1 S3 bucket configured"
      }
    }
  ]
}
```

### 7.8.3 Alert Escalation

1. **Workflow Failure**: Slack #dev-alerts + email to initiator
2. **State Lock Timeout** (> 30 min): Slack #devops-alerts + page on-call
3. **PROD Deployment Failure**: Slack #prod-alerts + email all stakeholders + page on-call
4. **PROD Rollback**: Slack #oncall-alerts + page on-call + executive notification

---

## 7.9 Security and Compliance

### 7.9.1 Security Best Practices

1. **No Long-Lived Credentials**: OIDC authentication, 1-hour session tokens
2. **Least Privilege IAM**: Separate roles per environment, minimum permissions
3. **Secret Protection**: Secrets encrypted in GitHub, masked in logs
4. **State Encryption**: S3 encryption at rest, DynamoDB encryption
5. **Audit Trail**: All deployments logged in GitHub Actions + CloudTrail

### 7.9.2 Compliance Requirements

**Change Management:**
- PROD deployments require change ticket
- Change ticket includes impact, rollback plan, approvers

**Separation of Duties:**
- Deployer cannot approve own deployment (PROD)
- 3 independent approvers for PROD

**Access Control:**
- Only authorized team members trigger deployments
- GitHub branch protection enforces code review
- AWS IAM enforces infrastructure access

**Documentation:**
- All workflows documented (this LLD)
- Runbooks for operations
- Incident reports for rollbacks

### 7.9.3 Pipeline Security Checklist

**Before Deployment:**
- [ ] tfsec scan passed
- [ ] S3 buckets block public access
- [ ] DynamoDB tables encrypted
- [ ] IAM roles least privilege

**During Deployment:**
- [ ] OIDC authentication used
- [ ] Temporary credentials used
- [ ] Credentials not logged
- [ ] State lock acquired

**After Deployment:**
- [ ] Resources tagged correctly
- [ ] Encryption verified
- [ ] Access controls verified

---

## 7.10 Metrics and KPIs

### 7.10.1 Key Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Deployment Success Rate** | > 95% | (Successful / Total) × 100 |
| **Average Deployment Time** | < 10 min | Time from trigger to completion |
| **Rollback Rate** | < 5% | (Rollbacks / Total deploys) × 100 |
| **Mean Time to Deploy (MTTD)** | < 1 day | Code merge to PROD |
| **Mean Time to Rollback (MTTR)** | < 15 min | Issue detection to recovery |
| **Validation Pass Rate** | 100% | (Passed / Total validations) × 100 |
| **Security Scan Pass Rate** | 100% | No HIGH/CRITICAL findings |

### 7.10.2 Dashboard View

```
┌────────────────────────────────────────────────┐
│         DEPLOYMENT DASHBOARD (Last 30 Days)    │
├────────────────────────────────────────────────┤
│                                                 │
│  Success Rate: ████████████████████ 97.3%      │
│                                                 │
│  Deployments by Environment:                   │
│    DEV:  ██████████████████ 45                 │
│    SIT:  ████████ 12                           │
│    PROD: ████ 8                                │
│                                                 │
│  Avg Deployment Time:                          │
│    DEV:  6m 23s                                │
│    SIT:  8m 45s                                │
│    PROD: 12m 10s                               │
│                                                 │
│  Rollbacks: 3 (3.7%)                           │
│    DEV: 2, SIT: 1, PROD: 0                     │
│                                                 │
└────────────────────────────────────────────────┘
```

---

## 7.11 Troubleshooting Guide

### 7.11.1 Common Issues

**Issue 1: Validation Workflow Fails**

*Symptoms*: `terraform fmt -check` fails, JSON invalid

*Resolution*:
```bash
terraform fmt -recursive
jq . schemas/tenants/tenant.schema.json
git add . && git commit -m "fix: formatting" && git push
```

**Issue 2: Terraform Plan Fails**

*Symptoms*: "Backend initialization required", "No valid credentials"

*Resolution*:
```bash
aws sts get-caller-identity  # Verify credentials
terraform init -reconfigure  # Re-initialize backend
```

**Issue 3: State Lock Timeout**

*Symptoms*: "Error: state locked", workflow hangs

*Resolution*:
```bash
# Check for active locks
aws dynamodb scan --table-name terraform-state-lock-dev

# Force unlock (caution!)
terraform force-unlock {LOCK_ID}

# Verify no other workflows running
gh run list --workflow terraform-apply.yml
```

**Issue 4: Post-Deployment Tests Fail**

*Symptoms*: Table not accessible, bucket not found

*Resolution*:
```bash
# Verify resources created
aws dynamodb describe-table --table-name tenants
aws s3api head-bucket --bucket bbws-templates-dev

# Refresh terraform state if diverged
terraform refresh -var-file=dev.tfvars
```

### 7.11.2 Emergency Rollback

**PROD Down - Emergency Procedure:**

1. **Declare Incident**
   ```bash
   /incident declare "PROD infrastructure failure"
   ```

2. **Identify Last Known Good**
   ```bash
   git tag -l "deploy-prod-*" | tail -5
   ```

3. **Trigger Rollback**
   ```bash
   gh workflow run rollback.yml \
     -f environment=prod \
     -f deployment_tag=deploy-prod-{TIMESTAMP} \
     -f confirmation=rollback-prod
   ```

4. **Fast-Track Approval** (escalate to executives if needed)

5. **Verify Recovery**
   ```bash
   python tests/test_deployment.py --env prod --critical-only
   ```

6. **Post-Incident**: Update status, create report, schedule post-mortem

---

## 7.12 Future Enhancements

### 7.12.1 Planned Improvements

1. **Automated Rollback Detection**
   - Monitor CloudWatch alarms post-deployment
   - Auto-trigger rollback if critical alarms fire

2. **Canary Deployments**
   - Deploy to subset first
   - Monitor metrics for anomalies
   - Gradually increase traffic

3. **Infrastructure Drift Detection**
   - Scheduled terraform plan runs
   - Alert if infrastructure differs from code

4. **Cost Optimization**
   - Integrate AWS Cost Explorer API
   - Alert if deployment increases costs

5. **Multi-Region Support**
   - Extend pipeline to eu-west-1 (DR)
   - Automated replication validation

---

## 7.13 Summary

### 7.13.1 Key Takeaways

**Pipeline Characteristics:**
- ✅ Fully automated validation and testing
- ✅ Manual approval gates for all deployments
- ✅ Progressive deployment (DEV → SIT → PROD)
- ✅ Component-level state isolation
- ✅ Quick rollback capability (< 15 min RTO)
- ✅ Comprehensive audit trail

**Security Posture:**
- ✅ OIDC authentication (no long-lived credentials)
- ✅ Least privilege IAM roles
- ✅ Encrypted state storage
- ✅ Security scanning (tfsec)
- ✅ Secret management best practices

**Operational Excellence:**
- ✅ Automated post-deployment validation
- ✅ Slack notifications for PROD
- ✅ Tagged deployments for rollback
- ✅ Monitoring and metrics
- ✅ Comprehensive troubleshooting guide

### 7.13.2 Pipeline Maturity

**Current State: Level 3 (Automated)**
- Automated validation and testing
- Manual deployment approval
- Environment-specific configuration
- Rollback capability

**Target State: Level 4 (Self-Service)**
- Automated drift detection
- Automated rollback on failure
- Canary deployments
- Multi-region support

---

**End of Section 7: CI/CD Pipeline Design**
