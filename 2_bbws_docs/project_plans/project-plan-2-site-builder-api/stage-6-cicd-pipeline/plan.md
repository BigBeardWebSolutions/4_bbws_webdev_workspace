# Stage 6: CI/CD Pipeline

**Stage ID**: stage-6-cicd-pipeline
**Parent Project**: Site Builder Bedrock Generation API (project-plan-2)
**Status**: PENDING
**Created**: 2026-01-15

---

## Stage Overview

**Objective**: Build GitHub Actions pipelines for automated deployment to DEV/SIT/PROD with approval gates.

**Dependencies**: Stage 5 complete

**Deliverables**:
1. GitHub Actions workflows
2. Terraform plan/apply pipelines
3. Lambda deployment pipelines
4. Environment promotion workflows

**Expected Duration**:
- Agentic: 30-45 minutes
- Manual: 2-3 days

---

## Workers

| Worker | Name | Status | Description |
|--------|------|--------|-------------|
| 1 | Terraform Workflow | PENDING | Terraform plan and apply workflows |
| 2 | Lambda Deployment | PENDING | Lambda deployment workflow |
| 3 | Environment Promotion | PENDING | DEV -> SIT -> PROD promotion workflow |
| 4 | Rollback Workflow | PENDING | Rollback workflow for failed deployments |

---

## Worker Definitions

### Worker 1: Terraform Workflow

**Objective**: Create GitHub Actions workflows for Terraform plan and apply with environment-specific configurations.

**Input Files**:
- `terraform/` (Terraform modules and environments)

**Tasks**:
1. Create Terraform plan workflow (on PR)
2. Create Terraform apply workflow (on merge)
3. Configure AWS credentials via OIDC
4. Configure environment-specific variables
5. Add approval gates for SIT/PROD
6. Configure state management (S3 backend)

**Output Requirements**:
- Create: `.github/workflows/terraform-plan.yml`
- Create: `.github/workflows/terraform-apply.yml`

**Code Structure**:
```yaml
# .github/workflows/terraform-plan.yml
name: Terraform Plan

on:
  pull_request:
    paths:
      - 'terraform/**'
      - '.github/workflows/terraform-*.yml'

env:
  TF_VERSION: '1.6.0'

permissions:
  id-token: write
  contents: read
  pull-requests: write

jobs:
  plan:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [dev, sit, prod]

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets[format('AWS_ROLE_{0}', matrix.environment)] }}
          aws-region: ${{ matrix.environment == 'prod' && 'af-south-1' || 'eu-west-1' }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Terraform Init
        working-directory: terraform/environments/${{ matrix.environment }}
        run: terraform init

      - name: Terraform Plan
        working-directory: terraform/environments/${{ matrix.environment }}
        run: terraform plan -out=tfplan -no-color
        continue-on-error: true

      - name: Comment Plan on PR
        uses: actions/github-script@v7
        with:
          script: |
            const output = `#### Terraform Plan - ${{ matrix.environment }}
            \`\`\`
            ${process.env.PLAN_OUTPUT}
            \`\`\``;
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            });
```

```yaml
# .github/workflows/terraform-apply.yml
name: Terraform Apply

on:
  push:
    branches:
      - main
    paths:
      - 'terraform/**'
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

permissions:
  id-token: write
  contents: read

jobs:
  apply-dev:
    runs-on: ubuntu-latest
    environment: dev

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_DEV }}
          aws-region: eu-west-1

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: '1.6.0'

      - name: Terraform Init
        working-directory: terraform/environments/dev
        run: terraform init

      - name: Terraform Apply
        working-directory: terraform/environments/dev
        run: terraform apply -auto-approve

  apply-sit:
    needs: apply-dev
    runs-on: ubuntu-latest
    environment: sit
    if: github.event_name == 'workflow_dispatch' && github.event.inputs.environment != 'dev'

    steps:
      # Similar to dev, with sit credentials

  apply-prod:
    needs: apply-sit
    runs-on: ubuntu-latest
    environment: prod
    if: github.event_name == 'workflow_dispatch' && github.event.inputs.environment == 'prod'

    steps:
      # Similar to sit, with prod credentials and af-south-1 region
```

**Success Criteria**:
- Plan runs on PR
- Apply runs on merge to main
- Environment-specific configurations
- Approval gates for SIT/PROD
- No hardcoded secrets

---

### Worker 2: Lambda Deployment

**Objective**: Create GitHub Actions workflow for Lambda function deployment with testing.

**Input Files**:
- `src/lambdas/` (Lambda function code)
- `tests/` (Unit tests)

**Tasks**:
1. Create Lambda deployment workflow
2. Configure Python setup
3. Run unit tests before deployment
4. Package Lambda functions
5. Deploy using AWS SAM or direct upload
6. Verify deployment

**Output Requirements**:
- Create: `.github/workflows/lambda-deploy.yml`

**Code Structure**:
```yaml
# .github/workflows/lambda-deploy.yml
name: Lambda Deployment

on:
  push:
    branches:
      - main
    paths:
      - 'src/lambdas/**'
      - 'src/shared/**'
      - 'tests/**'
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
      function:
        description: 'Specific function to deploy (or "all")'
        required: false
        default: 'all'

permissions:
  id-token: write
  contents: read

env:
  PYTHON_VERSION: '3.12'

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Install Dependencies
        run: |
          python -m pip install --upgrade pip
          pip install pytest pytest-cov moto boto3 pydantic

      - name: Run Unit Tests
        run: |
          pytest tests/unit/ -v --cov=src --cov-report=xml --cov-fail-under=80

      - name: Upload Coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage.xml

  deploy-dev:
    needs: test
    runs-on: ubuntu-latest
    environment: dev

    strategy:
      matrix:
        function:
          - page_generator
          - logo_creator
          - background_creator
          - theme_selector
          - layout_agent
          - brand_validator
          - generation_state

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_DEV }}
          aws-region: eu-west-1

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Package Lambda
        run: |
          cd src/lambdas/${{ matrix.function }}
          pip install -r requirements.txt -t .
          cp -r ../shared .
          zip -r ${{ matrix.function }}.zip .

      - name: Deploy Lambda
        run: |
          aws lambda update-function-code \
            --function-name ${{ matrix.function }}-dev \
            --zip-file fileb://src/lambdas/${{ matrix.function }}/${{ matrix.function }}.zip

      - name: Verify Deployment
        run: |
          aws lambda invoke \
            --function-name ${{ matrix.function }}-dev \
            --payload '{"test": true}' \
            response.json
          cat response.json

  deploy-sit:
    needs: deploy-dev
    runs-on: ubuntu-latest
    environment: sit
    if: github.event_name == 'workflow_dispatch' && github.event.inputs.environment != 'dev'

    # Similar to deploy-dev with sit credentials

  deploy-prod:
    needs: deploy-sit
    runs-on: ubuntu-latest
    environment: prod
    if: github.event_name == 'workflow_dispatch' && github.event.inputs.environment == 'prod'

    # Similar to deploy-sit with prod credentials and af-south-1 region
```

**Success Criteria**:
- Tests run before deployment
- 80% coverage enforced
- All functions packaged correctly
- Deployment to correct environment
- Verification step passes

---

### Worker 3: Environment Promotion

**Objective**: Create workflow for promoting deployments from DEV -> SIT -> PROD with approval gates.

**Input Files**:
- `.github/workflows/terraform-apply.yml`
- `.github/workflows/lambda-deploy.yml`

**Tasks**:
1. Create promotion workflow
2. Configure environment approval
3. Validate DEV before SIT promotion
4. Validate SIT before PROD promotion
5. Create promotion checklist
6. Notify on promotion

**Output Requirements**:
- Create: `.github/workflows/promotion.yml`

**Code Structure**:
```yaml
# .github/workflows/promotion.yml
name: Environment Promotion

on:
  workflow_dispatch:
    inputs:
      source_environment:
        description: 'Source environment'
        required: true
        type: choice
        options:
          - dev
          - sit
      target_environment:
        description: 'Target environment'
        required: true
        type: choice
        options:
          - sit
          - prod

permissions:
  id-token: write
  contents: read
  issues: write

jobs:
  validate-source:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.source_environment }}

    outputs:
      source_valid: ${{ steps.validate.outputs.valid }}

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets[format('AWS_ROLE_{0}', github.event.inputs.source_environment)] }}
          aws-region: eu-west-1

      - name: Validate Lambda Functions
        id: validate
        run: |
          # Check all functions are healthy
          functions=(page_generator logo_creator background_creator theme_selector layout_agent brand_validator generation_state)
          for fn in "${functions[@]}"; do
            aws lambda get-function --function-name "${fn}-${{ github.event.inputs.source_environment }}"
            if [ $? -ne 0 ]; then
              echo "::error::Function ${fn} not found in ${{ github.event.inputs.source_environment }}"
              echo "valid=false" >> $GITHUB_OUTPUT
              exit 1
            fi
          done
          echo "valid=true" >> $GITHUB_OUTPUT

      - name: Run Integration Tests
        run: |
          # Run integration tests against source environment
          pytest tests/integration/ -v --env=${{ github.event.inputs.source_environment }}

  create-promotion-checklist:
    needs: validate-source
    runs-on: ubuntu-latest
    if: needs.validate-source.outputs.source_valid == 'true'

    steps:
      - name: Create Promotion Issue
        uses: actions/github-script@v7
        with:
          script: |
            const issue = await github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: `Promotion: ${{ github.event.inputs.source_environment }} -> ${{ github.event.inputs.target_environment }}`,
              body: `## Promotion Checklist

              ### Source Environment: ${{ github.event.inputs.source_environment }}
              - [ ] All Lambda functions healthy
              - [ ] Integration tests passing
              - [ ] No critical CloudWatch alarms

              ### Target Environment: ${{ github.event.inputs.target_environment }}
              - [ ] Terraform plan reviewed
              - [ ] Change approval obtained
              - [ ] Rollback plan documented

              ### Approval Required
              - [ ] Tech Lead approval
              - [ ] DevOps Lead approval
              ${{ github.event.inputs.target_environment == 'prod' && '- [ ] Product Owner approval' || '' }}

              ---
              Workflow Run: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
              `,
              labels: ['promotion', '${{ github.event.inputs.target_environment }}']
            });
            console.log(`Created issue #${issue.data.number}`);

  promote:
    needs: [validate-source, create-promotion-checklist]
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.target_environment }}

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Trigger Terraform Apply
        uses: actions/github-script@v7
        with:
          script: |
            await github.rest.actions.createWorkflowDispatch({
              owner: context.repo.owner,
              repo: context.repo.repo,
              workflow_id: 'terraform-apply.yml',
              ref: 'main',
              inputs: {
                environment: '${{ github.event.inputs.target_environment }}'
              }
            });

      - name: Trigger Lambda Deploy
        uses: actions/github-script@v7
        with:
          script: |
            await github.rest.actions.createWorkflowDispatch({
              owner: context.repo.owner,
              repo: context.repo.repo,
              workflow_id: 'lambda-deploy.yml',
              ref: 'main',
              inputs: {
                environment: '${{ github.event.inputs.target_environment }}',
                function: 'all'
              }
            });

      - name: Notify Completion
        run: |
          echo "Promotion to ${{ github.event.inputs.target_environment }} initiated"
```

**Success Criteria**:
- Source validation before promotion
- Approval gates configured
- Checklist created for audit
- Promotion triggers correct workflows
- PROD requires additional approvals

---

### Worker 4: Rollback Workflow

**Objective**: Create workflow for rolling back failed deployments to previous version.

**Input Files**:
- `.github/workflows/terraform-apply.yml`
- `.github/workflows/lambda-deploy.yml`

**Tasks**:
1. Create rollback workflow
2. Support Terraform state rollback
3. Support Lambda version rollback
4. Create rollback verification
5. Notify on rollback completion

**Output Requirements**:
- Create: `.github/workflows/rollback.yml`

**Code Structure**:
```yaml
# .github/workflows/rollback.yml
name: Rollback

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
      rollback_type:
        description: 'Type of rollback'
        required: true
        type: choice
        options:
          - lambda_only
          - terraform_only
          - full
      function:
        description: 'Specific Lambda function (or "all")'
        required: false
        default: 'all'
      target_version:
        description: 'Target Lambda version (or "previous")'
        required: false
        default: 'previous'

permissions:
  id-token: write
  contents: read

jobs:
  rollback-lambda:
    if: github.event.inputs.rollback_type != 'terraform_only'
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment }}

    strategy:
      matrix:
        function:
          - page_generator
          - logo_creator
          - background_creator
          - theme_selector
          - layout_agent
          - brand_validator
          - generation_state

    steps:
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets[format('AWS_ROLE_{0}', github.event.inputs.environment)] }}
          aws-region: ${{ github.event.inputs.environment == 'prod' && 'af-south-1' || 'eu-west-1' }}

      - name: Get Previous Version
        if: github.event.inputs.target_version == 'previous'
        id: get_version
        run: |
          # Get list of versions
          versions=$(aws lambda list-versions-by-function \
            --function-name ${{ matrix.function }}-${{ github.event.inputs.environment }} \
            --query 'Versions[-2].Version' \
            --output text)
          echo "version=${versions}" >> $GITHUB_OUTPUT

      - name: Rollback Lambda Alias
        run: |
          target_version="${{ github.event.inputs.target_version }}"
          if [ "$target_version" == "previous" ]; then
            target_version="${{ steps.get_version.outputs.version }}"
          fi

          aws lambda update-alias \
            --function-name ${{ matrix.function }}-${{ github.event.inputs.environment }} \
            --name live \
            --function-version $target_version

      - name: Verify Rollback
        run: |
          aws lambda invoke \
            --function-name ${{ matrix.function }}-${{ github.event.inputs.environment }}:live \
            --payload '{"test": true}' \
            response.json
          cat response.json

  rollback-terraform:
    if: github.event.inputs.rollback_type != 'lambda_only'
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment }}

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets[format('AWS_ROLE_{0}', github.event.inputs.environment)] }}
          aws-region: ${{ github.event.inputs.environment == 'prod' && 'af-south-1' || 'eu-west-1' }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: '1.6.0'

      - name: Checkout Previous Commit
        run: git checkout HEAD~1

      - name: Terraform Init
        working-directory: terraform/environments/${{ github.event.inputs.environment }}
        run: terraform init

      - name: Terraform Apply (Rollback)
        working-directory: terraform/environments/${{ github.event.inputs.environment }}
        run: terraform apply -auto-approve

  notify:
    needs: [rollback-lambda, rollback-terraform]
    if: always()
    runs-on: ubuntu-latest

    steps:
      - name: Send Notification
        run: |
          echo "Rollback completed for ${{ github.event.inputs.environment }}"
          echo "Type: ${{ github.event.inputs.rollback_type }}"
          # Add SNS/Slack notification here
```

**Success Criteria**:
- Lambda version rollback working
- Terraform state rollback working
- Verification after rollback
- Notifications sent
- Audit trail created

---

## Stage Completion Criteria

The stage is considered **COMPLETE** when:

1. All 4 workers have completed their outputs
2. All workflow files created in `.github/workflows/`
3. Workflows validated (YAML syntax)
4. Environment secrets documented
5. Approval gates configured

---

## Approval Gate (Gate 4)

**After this stage**: Gate 4 approval required

**Approvers**:
- DevOps Lead
- Security Team

**Approval Criteria**:
- CI/CD pipelines comprehensive
- Security (OIDC, no hardcoded secrets)
- Approval gates for SIT/PROD
- Rollback procedures tested

---

**Stage Owner**: Agentic Project Manager
**Created**: 2026-01-15
**Next Action**: Wait for Stage 5 completion
