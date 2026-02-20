# Worker 2-6: CI/CD Pipeline Design Section

**Worker ID**: worker-2-6-cicd-pipeline-design-section
**Stage**: Stage 2 - LLD Document Creation
**Status**: PENDING
**Estimated Effort**: High
**Dependencies**: Stage 1 Worker 4-4

---

## Objective

Create comprehensive CI/CD pipeline design section (Section 7) of the LLD document with GitHub Actions workflows, approval gates, deployment strategies, and rollback procedures.

---

## Input Documents

1. **Stage 1 Outputs**:
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-1-requirements-analysis/worker-4-environment-configuration-analysis/output.md` (CI/CD config matrix)
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-1-requirements-analysis/worker-3-naming-convention-analysis/output.md` (Workflow naming)

2. **Specification Documents**:
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/specs/2.1.8_LLD_S3_and_DynamoDB_Spec.md` (Section 6: GitHub Actions Pipeline)

---

## Deliverables

Create `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-2-lld-document-creation/worker-6-cicd-pipeline-design-section/output.md` containing:

### Section 7: CI/CD Pipeline Design

#### 7.1 Overview
- Purpose of CI/CD automation
- Pipeline philosophy: Automate validation, require human approval for deployment
- Integration with GitHub Actions

#### 7.2 Pipeline Architecture

**7.2.1 Pipeline Stages**

```
┌─────────────────────────────────────────────────────────┐
│ STAGE 1: VALIDATION (Automated)                        │
├─────────────────────────────────────────────────────────┤
│ - JSON schema validation                                │
│ - Terraform validate                                    │
│ - Terraform fmt check                                   │
│ - Linting and formatting                                │
│ Triggers: Pull Request, Push to main                    │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ STAGE 2: TERRAFORM PLAN (Automated)                    │
├─────────────────────────────────────────────────────────┤
│ - terraform init                                        │
│ - terraform plan                                        │
│ - Post plan as PR comment                               │
│ - Store plan artifact                                   │
│ Triggers: Pull Request to main                          │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ GATE 1: PLAN REVIEW (Manual Approval)                  │
├─────────────────────────────────────────────────────────┤
│ Approvers: 1 (DEV), 2 (SIT), 3 (PROD)                  │
│ Review: Terraform plan output, resource changes         │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ STAGE 3: DEPLOYMENT (Manual Trigger)                   │
├─────────────────────────────────────────────────────────┤
│ - terraform apply (using stored plan)                   │
│ - Tag deployment                                        │
│ - Notify Slack                                          │
│ Triggers: Manual workflow_dispatch                      │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ STAGE 4: VALIDATION (Automated)                        │
├─────────────────────────────────────────────────────────┤
│ - Test DynamoDB table creation                          │
│ - Test S3 bucket access                                 │
│ - Verify GSIs exist                                     │
│ - Verify tags applied                                   │
│ Triggers: After terraform apply                         │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ GATE 2: PROMOTION APPROVAL (Manual)                    │
├─────────────────────────────────────────────────────────┤
│ Approvers: 2 (SIT), 3 (PROD)                           │
│ Review: Validation results, logs                        │
│ Decision: Promote to next environment or rollback       │
└─────────────────────────────────────────────────────────┘
```

#### 7.3 GitHub Actions Workflows

**7.3.1 Workflow: validate-schemas.yml**

**Purpose**: Validate JSON schemas on every PR

**Trigger**:
```yaml
on:
  pull_request:
    paths:
      - 'schemas/**'
  push:
    branches:
      - main
    paths:
      - 'schemas/**'
```

**Jobs**:
1. **validate-json**: Validate JSON syntax
2. **validate-schema**: Validate against JSON schema spec
3. **check-naming**: Validate naming conventions

**Steps**:
```yaml
jobs:
  validate-json:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Validate JSON syntax
        run: |
          for file in schemas/*.json; do
            jq empty "$file" || exit 1
          done
      - name: Validate schema structure
        run: |
          # Validate required fields exist
          # Validate PK/SK patterns
          # Validate GSI definitions
```

**7.3.2 Workflow: terraform-plan.yml**

**Purpose**: Run terraform plan and post results to PR

**Trigger**:
```yaml
on:
  pull_request:
    branches:
      - main
    paths:
      - 'terraform/**'
```

**Jobs**:
1. **plan-dev**: Plan DEV deployment
2. **plan-sit**: Plan SIT deployment (if PR approved)
3. **plan-prod**: Plan PROD deployment (if PR approved)

**Steps**:
```yaml
jobs:
  plan-dev:
    runs-on: ubuntu-latest
    environment: dev
    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::536580886816:role/GithubActionsRole
          aws-region: af-south-1

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0

      - name: Terraform Init
        run: terraform init -backend-config=environments/dev.tfvars

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        run: terraform plan -var-file=environments/dev.tfvars -out=tfplan

      - name: Upload Plan
        uses: actions/upload-artifact@v3
        with:
          name: tfplan-dev
          path: tfplan

      - name: Comment PR
        uses: actions/github-script@v6
        with:
          script: |
            // Post terraform plan output to PR comment
```

**7.3.3 Workflow: terraform-apply.yml**

**Purpose**: Apply terraform changes with manual approval

**Trigger**:
```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        type: choice
        options:
          - dev
          - sit
          - prod
```

**Jobs**:
1. **approval-gate**: Wait for manual approval
2. **apply**: Apply terraform plan
3. **validate**: Run post-deployment validation
4. **notify**: Send Slack notification

**Steps**:
```yaml
jobs:
  approval-gate:
    runs-on: ubuntu-latest
    environment:
      name: ${{ github.event.inputs.environment }}
      required-approvers: 1  # DEV=1, SIT=2, PROD=3
    steps:
      - name: Wait for approval
        run: echo "Deployment approved"

  apply:
    needs: approval-gate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: af-south-1

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2

      - name: Download Plan
        uses: actions/download-artifact@v3
        with:
          name: tfplan-${{ github.event.inputs.environment }}

      - name: Terraform Apply
        run: terraform apply tfplan

      - name: Tag Deployment
        run: |
          git tag "deploy-${{ github.event.inputs.environment }}-$(date +%Y%m%d-%H%M%S)"
          git push --tags

  validate:
    needs: apply
    runs-on: ubuntu-latest
    steps:
      - name: Test DynamoDB Tables
        run: |
          # Verify tables exist
          aws dynamodb describe-table --table-name tenants
          aws dynamodb describe-table --table-name products
          aws dynamodb describe-table --table-name campaigns

      - name: Test S3 Bucket
        run: |
          # Verify bucket exists and is configured
          aws s3api head-bucket --bucket bbws-templates-${{ github.event.inputs.environment }}

      - name: Verify Tags
        run: |
          # Verify tags are applied correctly

  notify:
    needs: validate
    runs-on: ubuntu-latest
    steps:
      - name: Notify Slack
        if: ${{ github.event.inputs.environment == 'prod' }}
        uses: slackapi/slack-github-action@v1
        with:
          webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
          payload: |
            {
              "text": "PROD deployment completed: ${{ github.event.inputs.environment }}"
            }
```

**7.3.4 Workflow: rollback.yml**

**Purpose**: Rollback to previous terraform state

**Trigger**:
```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to rollback'
        required: true
        type: choice
        options:
          - dev
          - sit
          - prod
      tag:
        description: 'Deployment tag to rollback to'
        required: true
        type: string
```

**Steps**:
```yaml
jobs:
  rollback:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout tag
        run: git checkout ${{ github.event.inputs.tag }}

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: af-south-1

      - name: Terraform Init
        run: terraform init -backend-config=environments/${{ github.event.inputs.environment }}.tfvars

      - name: Terraform Plan
        run: terraform plan -var-file=environments/${{ github.event.inputs.environment }}.tfvars

      - name: Manual Approval
        uses: trstringer/manual-approval@v1
        with:
          approvers: platform-team
          minimum-approvals: 2

      - name: Terraform Apply
        run: terraform apply -auto-approve
```

#### 7.4 Environment-Specific Configuration

**7.4.1 DEV Environment**
- Auto-deploy on merge to main: NO (manual workflow_dispatch)
- Required approvers: 1 (any platform team member)
- Deployment window: Anytime
- Slack notifications: No

**7.4.2 SIT Environment**
- Auto-deploy: NO (manual promotion from DEV)
- Required approvers: 2 (tech lead + DevOps lead)
- Deployment window: Business hours only
- Slack notifications: Optional

**7.4.3 PROD Environment**
- Auto-deploy: NO (manual promotion from SIT)
- Required approvers: 3 (tech lead + DevOps lead + product owner)
- Deployment window: Scheduled maintenance windows
- Slack notifications: REQUIRED
- Change ticket required: YES

#### 7.5 Secrets Management

**7.5.1 GitHub Secrets**

Per environment:
- `AWS_ROLE_ARN`: IAM role ARN for GitHub Actions
- `SLACK_WEBHOOK_URL`: Slack webhook for PROD notifications
- `TERRAFORM_STATE_BUCKET`: S3 bucket for terraform state
- `TERRAFORM_LOCK_TABLE`: DynamoDB table for state locks

**7.5.2 GitHub Environments**

Three environments configured:
1. `dev`: 1 required approver
2. `sit`: 2 required approvers
3. `prod`: 3 required approvers, deployment branch restriction (main only)

#### 7.6 Approval Gates

**7.6.1 Gate 1: After Terraform Plan**
- Who: 1 approver (DEV), 2 approvers (SIT), 3 approvers (PROD)
- What: Review terraform plan output
- Criteria: No unexpected resource changes, cost estimate acceptable

**7.6.2 Gate 2: Before Environment Promotion**
- Who: 2 approvers (SIT), 3 approvers (PROD)
- What: Review validation results from previous environment
- Criteria: All tests passed, no errors in logs

#### 7.7 Deployment Strategy

**7.7.1 Deployment Flow**

```
DEV deployment → DEV validation → SIT approval → SIT deployment → SIT validation → PROD approval → PROD deployment → PROD validation
```

**7.7.2 Rollback Strategy**

- Use git tags to track deployments
- Rollback = checkout previous tag + terraform apply
- Requires manual approval (same as deployment)
- Test rollback in DEV first

#### 7.8 Monitoring and Notifications

**7.8.1 Workflow Monitoring**
- GitHub Actions logs
- Terraform state lock monitoring
- Failed workflow alerts

**7.8.2 Slack Notifications**
- PROD deployments (success/failure)
- Rollback operations
- Approval gate timeouts

---

## Quality Criteria

- [ ] All 4 workflows documented with YAML examples
- [ ] Approval gates clearly defined
- [ ] Environment-specific configs documented
- [ ] Secrets management documented
- [ ] Rollback procedure documented
- [ ] Deployment flow diagram clear
- [ ] No placeholder text

---

## Output Format

Write output to `output.md` using markdown format with proper headings, code blocks, and diagrams.

**Target Length**: 1,000-1,200 lines

---

## Special Instructions

1. **Use Stage 1 Configs**:
   - Approval counts from Worker 4-4 CI/CD matrix
   - Environment account IDs from Worker 4-4
   - Workflow naming from Worker 3-3

2. **GitHub Actions Best Practices**:
   - Use reusable workflows where possible
   - Use environments for approval gates
   - Use OIDC for AWS authentication (no access keys)

3. **YAML Quality**:
   - Proper indentation
   - Comments in workflows
   - Use latest action versions

---

**Worker Created**: 2025-12-25
**Execution Mode**: Parallel (with 5 other Stage 2 workers)
