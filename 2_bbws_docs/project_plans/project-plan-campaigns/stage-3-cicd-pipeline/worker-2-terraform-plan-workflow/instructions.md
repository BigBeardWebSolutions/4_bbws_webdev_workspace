# Worker Instructions: Terraform Plan Workflow

**Worker ID**: worker-2-terraform-plan-workflow
**Stage**: Stage 3 - CI/CD Pipeline Development
**Project**: project-plan-campaigns

---

## Task

Create GitHub Actions workflow for Terraform plan on pull requests.

---

## Deliverables

### .github/workflows/terraform-plan.yml

```yaml
name: Terraform Plan

on:
  pull_request:
    branches:
      - main
    paths:
      - 'terraform/**'
      - '.github/workflows/terraform-plan.yml'

env:
  TERRAFORM_VERSION: '1.5.0'
  AWS_REGION: 'eu-west-1'

permissions:
  contents: read
  pull-requests: write

jobs:
  terraform-validate:
    name: Validate Terraform
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TERRAFORM_VERSION }}

      - name: Terraform Format Check
        id: fmt
        run: terraform fmt -check -recursive
        working-directory: terraform
        continue-on-error: true

      - name: Terraform Init
        id: init
        run: |
          terraform init -backend=false
        working-directory: terraform

      - name: Terraform Validate
        id: validate
        run: terraform validate -no-color
        working-directory: terraform

      - name: Post Validation Status
        uses: actions/github-script@v7
        if: github.event_name == 'pull_request'
        with:
          script: |
            const output = `#### Terraform Format and Style \`${{ steps.fmt.outcome }}\`
            #### Terraform Initialization \`${{ steps.init.outcome }}\`
            #### Terraform Validation \`${{ steps.validate.outcome }}\`

            *Pushed by: @${{ github.actor }}, Action: \`${{ github.event_name }}\`*`;

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            })

  terraform-plan-dev:
    name: Plan DEV Environment
    runs-on: ubuntu-latest
    needs: terraform-validate
    environment: dev

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TERRAFORM_VERSION }}

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Terraform Init
        id: init
        run: |
          terraform init \
            -backend-config="bucket=${{ secrets.TF_STATE_BUCKET }}" \
            -backend-config="key=campaigns-lambda/dev/terraform.tfstate" \
            -backend-config="region=${{ env.AWS_REGION }}" \
            -backend-config="dynamodb_table=${{ secrets.TF_STATE_LOCK_TABLE }}" \
            -backend-config="encrypt=true"
        working-directory: terraform

      - name: Terraform Plan
        id: plan
        run: |
          terraform plan \
            -var-file=environments/dev.tfvars \
            -no-color \
            -out=tfplan
        working-directory: terraform
        continue-on-error: true

      - name: Post Plan to PR
        uses: actions/github-script@v7
        if: github.event_name == 'pull_request'
        env:
          PLAN: "${{ steps.plan.outputs.stdout }}"
        with:
          script: |
            const output = `#### Terraform Plan for DEV \`${{ steps.plan.outcome }}\`

            <details><summary>Show Plan</summary>

            \`\`\`terraform
            ${process.env.PLAN}
            \`\`\`

            </details>

            *Pushed by: @${{ github.actor }}*`;

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            })

      - name: Terraform Plan Status
        if: steps.plan.outcome == 'failure'
        run: exit 1

  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    needs: terraform-validate

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run tfsec
        uses: aquasecurity/tfsec-action@v1.0.3
        with:
          working_directory: terraform
          soft_fail: true

      - name: Run Checkov
        uses: bridgecrewio/checkov-action@v12
        with:
          directory: terraform
          soft_fail: true
          framework: terraform
```

---

## Workflow Features

### Triggers
- Pull requests to main branch
- Only when terraform files change

### Jobs
1. **terraform-validate** - Format check, init, validate
2. **terraform-plan-dev** - Plan against DEV environment
3. **security-scan** - tfsec and Checkov security scanning

### GitHub Environment
- Uses `dev` environment for secrets
- Requires AWS credentials as secrets

### Required Secrets
```
AWS_ACCESS_KEY_ID      - AWS access key for DEV
AWS_SECRET_ACCESS_KEY  - AWS secret key for DEV
TF_STATE_BUCKET        - S3 bucket for Terraform state
TF_STATE_LOCK_TABLE    - DynamoDB table for state locking
```

---

## Success Criteria

- [ ] Workflow file is valid YAML
- [ ] Terraform format check works
- [ ] Terraform init with backend works
- [ ] Terraform plan runs successfully
- [ ] Plan output posted to PR
- [ ] Security scanning enabled

---

## Execution Steps

1. Create .github/workflows/terraform-plan.yml
2. Configure Terraform 1.5.0 setup
3. Add validation job
4. Add plan job for DEV
5. Add security scanning job
6. Validate workflow syntax
7. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
