# Tenant Deployment Pipeline Design
## GitHub Actions Based Multi-Environment Deployment

**Version:** 1.0
**Date:** 2025-12-23
**Status:** Design Draft

---

## Executive Summary

This document outlines a comprehensive GitHub Actions-based CI/CD pipeline for deploying WordPress tenants to ECS across DEV, SIT, and PROD environments. The design emphasizes:

- **Minimal manual intervention** through automation
- **Safe promotion workflow** (DEV → SIT → PROD)
- **Terraform state persistence** in S3 for collaborative work
- **3-phase deployment** (ECS → Database → Testing)
- **Human approval gates** for production deployments
- **Automated validation** at each stage

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Pipeline Workflow](#pipeline-workflow)
3. [GitHub Actions Structure](#github-actions-structure)
4. [Terraform Organization](#terraform-organization)
5. [S3 State Management](#s3-state-management)
6. [Deployment Phases](#deployment-phases)
7. [Approval Gates](#approval-gates)
8. [Tenant Configuration](#tenant-configuration)
9. [Rollback Strategy](#rollback-strategy)
10. [Implementation Plan](#implementation-plan)

---

## Architecture Overview

### High-Level Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    GITHUB REPOSITORY                             │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ .github/workflows/                                         │ │
│  │  ├── deploy-tenant.yml (Reusable workflow)                │ │
│  │  ├── tenant-goldencrust.yml (Tenant-specific trigger)     │ │
│  │  ├── tenant-sunsetbistro.yml                              │ │
│  │  └── ...                                                   │ │
│  │                                                            │ │
│  │ terraform/tenants/                                         │ │
│  │  ├── modules/                                              │ │
│  │  │   ├── ecs-tenant/          (Phase 1)                   │ │
│  │  │   ├── database/             (Phase 2 - Python wrapper) │ │
│  │  │   └── dns-cloudfront/       (Phase 3)                  │ │
│  │  └── {tenant-name}/                                       │ │
│  │      ├── dev.tfvars                                       │ │
│  │      ├── sit.tfvars                                       │ │
│  │      └── prod.tfvars                                      │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                          ↓ (Manual Trigger)
┌─────────────────────────────────────────────────────────────────┐
│              GITHUB ACTIONS WORKFLOW EXECUTION                   │
│                                                                  │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐                  │
│  │   DEV    │───→│   SIT    │───→│   PROD   │                  │
│  │ (Auto)   │    │ (Auto*)  │    │(Approval)│                  │
│  └──────────┘    └──────────┘    └──────────┘                  │
│       ↓               ↓               ↓                         │
│  Phase 1: ECS    Phase 1: ECS   Phase 1: ECS                   │
│  Phase 2: DB     Phase 2: DB    Phase 2: DB                    │
│  Phase 3: Test   Phase 3: DNS   Phase 3: DNS                   │
│                                                                  │
│  *Auto if DEV successful                                        │
└─────────────────────────────────────────────────────────────────┘
                          ↓ (State Persistence)
┌─────────────────────────────────────────────────────────────────┐
│                    AWS S3 + DYNAMODB                             │
│                                                                  │
│  S3: bbws-terraform-state-{env}/                                │
│    └── tenants/{tenant-name}/terraform.tfstate                 │
│                                                                  │
│  DynamoDB: bbws-terraform-locks-{env}                           │
│    └── State locking for concurrent protection                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Pipeline Workflow

### Tenant Deployment Lifecycle

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. DEVELOPER INITIATES DEPLOYMENT                               │
│    - Go to GitHub Actions UI                                    │
│    - Select tenant-specific workflow (e.g., tenant-goldencrust) │
│    - Input: Environment (dev/sit/prod)                          │
│    - Input: Tenant Name (auto-filled)                           │
│    - Input: ALB Priority (unique number)                        │
│    - Click "Run workflow"                                       │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. VALIDATION PHASE                                             │
│    ✓ Validate inputs (tenant name, priority, environment)       │
│    ✓ Check Terraform syntax                                     │
│    ✓ Verify AWS credentials for target environment             │
│    ✓ Check for ALB priority conflicts                          │
│    ✓ Validate environment config exists                        │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. PHASE 1 - ECS INFRASTRUCTURE                                 │
│    Terraform Module: ecs-tenant                                 │
│                                                                  │
│    ✓ Initialize Terraform with S3 backend                       │
│    ✓ Create/select workspace: {env}-{tenant}                   │
│    ✓ Plan ECS resources:                                        │
│      - EFS Access Point (/{tenant})                             │
│      - ECS Task Definition (WordPress container)                │
│      - ALB Target Group ({env}-{tenant}-tg)                     │
│      - ALB Listener Rule (host: {tenant}.wp{env}.kimmyai.io)   │
│      - ECS Service (1 task, Fargate)                            │
│    ✓ Apply with auto-approve (DEV/SIT) or manual (PROD)        │
│    ✓ Output: ECS service ARN, target group ARN                 │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. PHASE 2 - DATABASE CREATION                                  │
│    Python Script: init_tenant_db.py                             │
│                                                                  │
│    ✓ Retrieve RDS master credentials from Secrets Manager       │
│    ✓ Generate secure tenant password (24 chars)                │
│    ✓ Create Secrets Manager secret: {env}-{tenant}-db-creds    │
│    ✓ Execute Python script:                                     │
│      python3 init_tenant_db.py \                                │
│        '{"username":"admin","password":"***"}' \                │
│        '{"database":"{tenant}_db","username":"{tenant}_user"}' │
│    ✓ Verify database creation                                   │
│    ✓ Create IAM policy for secret access                       │
│    ✓ Attach policy to ECS task execution role                  │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. PHASE 3A - TESTING (DEV/SIT ONLY)                           │
│    Bash Script: verify_deployment.sh                            │
│                                                                  │
│    ✓ Wait for ECS service stabilization (60s)                  │
│    ✓ Check 1: Secrets Manager secret exists                    │
│    ✓ Check 2: ECS service status = ACTIVE                      │
│    ✓ Check 3: ECS tasks running = desired count                │
│    ✓ Check 4: ALB target health = healthy                      │
│    ✓ Check 5: HTTP endpoint test (curl)                        │
│    ✓ Check 6: CloudWatch logs (no errors)                      │
│    ✓ Generate test report artifact                             │
│                                                                  │
│    ⚠️  IF ANY CHECK FAILS → Trigger rollback                    │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. PHASE 3B - DNS + CLOUDFRONT (SIT/PROD ONLY)                 │
│    Terraform Module: dns-cloudfront (only after tests pass)     │
│                                                                  │
│    ✓ Create Route53 A record:                                   │
│      {tenant}.wp{env}.kimmyai.io → CloudFront                  │
│    ✓ Update CloudFront origin (if needed)                      │
│    ✓ Test HTTPS endpoint with Basic Auth                       │
│    ✓ Verify WordPress installation page loads                  │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│ 6. POST-DEPLOYMENT                                              │
│    Generate Tenant Configuration Document                       │
│                                                                  │
│    ✓ Generate JSON config:                                      │
│      {                                                           │
│        "tenant_name": "goldencrust",                            │
│        "environment": "sit",                                    │
│        "deployment_date": "2025-12-23T10:30:00Z",              │
│        "ecs_service": "sit-goldencrust-service",               │
│        "database": "goldencrust_db",                            │
│        "secret_arn": "arn:aws:secretsmanager:...",             │
│        "url": "https://goldencrust.wpsit.kimmyai.io",          │
│        "alb_priority": 140,                                     │
│        "resources": { ... }                                     │
│      }                                                           │
│    ✓ Commit to Git: config/{env}/{tenant}.json                 │
│    ✓ Upload to S3: s3://configs/{env}/{tenant}-config.json     │
│    ✓ Send Slack/Email notification                             │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│ 7. PROMOTION WORKFLOW (Optional)                                │
│    Promote DEV → SIT → PROD                                     │
│                                                                  │
│    ✓ If environment = dev AND all tests pass:                  │
│      - Automatically trigger SIT deployment (same tenant)       │
│    ✓ If environment = sit AND all tests pass:                  │
│      - Create PR for PROD deployment (manual merge)            │
│    ✓ If environment = prod:                                     │
│      - Require approval from designated reviewers              │
│      - Deploy to PROD after approval                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## Repository Organization

**See detailed folder structure:** [`FOLDER_STRUCTURE.md`](./FOLDER_STRUCTURE.md)

### Primary Repositories

```
┌──────────────────────────────────────────────────────────┐
│ 2_bbws_agents                                            │
│ → GitHub workflows, scripts, configs, documentation      │
└──────────────────────────────────────────────────────────┘
2_bbws_agents/
├── .github/
│   ├── workflows/                        # GitHub Actions
│   │   ├── deploy-tenant.yml            # Reusable workflow
│   │   └── tenant-{name}.yml            # 13 tenant triggers
│   └── actions/                          # Custom actions
│       ├── validate-inputs/
│       ├── check-priority-conflict/
│       └── generate-tenant-config/
├── devops/
│   ├── design/                           # Design documents
│   │   ├── TENANT_DEPLOYMENT_PIPELINE_DESIGN.md
│   │   └── FOLDER_STRUCTURE.md
│   ├── runbooks/                         # Operations runbooks
│   └── scripts/                          # DevOps utilities
├── utils/                                # Utility scripts (existing)
│   ├── init_tenant_db.py
│   ├── verify_deployment.sh
│   └── create_iam_policy.sh
└── config/                               # Auto-generated configs
    ├── dev/, sit/, prod/

┌──────────────────────────────────────────────────────────┐
│ 2_bbws_ecs_terraform                                     │
│ → Terraform infrastructure as code                       │
└──────────────────────────────────────────────────────────┘
2_bbws_ecs_terraform/
├── terraform/
│   ├── modules/                          # Reusable modules
│   │   ├── ecs-tenant/                  # Phase 1: ECS
│   │   ├── database/                    # Phase 2: Database
│   │   └── dns-cloudfront/              # Phase 3: DNS
│   ├── tenants/                          # Per-tenant configs
│   │   ├── goldencrust/
│   │   │   ├── main.tf
│   │   │   ├── backend.tf
│   │   │   ├── dev.tfvars
│   │   │   ├── sit.tfvars
│   │   │   └── prod.tfvars
│   │   └── ... (13 tenant folders)
│   ├── environments/                     # Environment configs
│   │   ├── dev/backend-dev.hcl
│   │   ├── sit/backend-sit.hcl
│   │   └── prod/backend-prod.hcl
│   └── scripts/                          # Terraform helpers
└── README.md

┌──────────────────────────────────────────────────────────┐
│ 2_bbws_tenant_provisioner                               │
│ → Python provisioning utilities (existing)               │
└──────────────────────────────────────────────────────────┘
(No changes needed - existing scripts reused)
```

---

## GitHub Actions Workflows

### 1. Reusable Workflow: `deploy-tenant.yml`

```yaml
name: Deploy Tenant (Reusable)

on:
  workflow_call:
    inputs:
      tenant_name:
        required: true
        type: string
      environment:
        required: true
        type: string
      alb_priority:
        required: true
        type: number
      auto_promote:
        required: false
        type: boolean
        default: false

    secrets:
      AWS_ACCESS_KEY_ID:
        required: true
      AWS_SECRET_ACCESS_KEY:
        required: true

jobs:
  validate:
    name: Validate Inputs
    runs-on: ubuntu-latest
    outputs:
      env_valid: ${{ steps.validate.outputs.env_valid }}
      priority_available: ${{ steps.check-priority.outputs.available }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Validate environment
        id: validate
        run: |
          if [[ ! "${{ inputs.environment }}" =~ ^(dev|sit|prod)$ ]]; then
            echo "❌ Invalid environment: ${{ inputs.environment }}"
            exit 1
          fi
          echo "env_valid=true" >> $GITHUB_OUTPUT

      - name: Check ALB priority conflict
        id: check-priority
        run: |
          # Query existing ALB rules for priority conflicts
          aws elbv2 describe-rules \
            --listener-arn $(cat terraform/tenants/${{ inputs.tenant_name }}/${{ inputs.environment }}.tfvars | grep listener_arn | cut -d'"' -f2) \
            --profile Tebogo-${{ inputs.environment }} \
            --query "Rules[?Priority=='${{ inputs.alb_priority }}'].RuleArn" \
            --output text

          if [ -n "$EXISTING_RULE" ]; then
            echo "❌ Priority ${{ inputs.alb_priority }} already in use"
            exit 1
          fi
          echo "available=true" >> $GITHUB_OUTPUT

  phase1-ecs:
    name: Phase 1 - ECS Infrastructure
    needs: validate
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ inputs.environment == 'prod' && 'af-south-1' || 'eu-west-1' }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0

      - name: Terraform Init
        working-directory: terraform/tenants/${{ inputs.tenant_name }}
        run: |
          terraform init \
            -backend-config="bucket=bbws-terraform-state-${{ inputs.environment }}" \
            -backend-config="key=tenants/${{ inputs.tenant_name }}/terraform.tfstate" \
            -backend-config="region=${{ inputs.environment == 'prod' && 'af-south-1' || 'eu-west-1' }}" \
            -backend-config="dynamodb_table=bbws-terraform-locks-${{ inputs.environment }}"

      - name: Terraform Workspace
        working-directory: terraform/tenants/${{ inputs.tenant_name }}
        run: |
          terraform workspace select ${{ inputs.environment }} || terraform workspace new ${{ inputs.environment }}

      - name: Terraform Plan - ECS Module
        working-directory: terraform/tenants/${{ inputs.tenant_name }}
        run: |
          terraform plan \
            -var-file=${{ inputs.environment }}.tfvars \
            -var="alb_priority=${{ inputs.alb_priority }}" \
            -target=module.ecs_tenant \
            -out=ecs-plan.tfplan

      - name: Terraform Apply - ECS Module
        working-directory: terraform/tenants/${{ inputs.tenant_name }}
        run: |
          terraform apply -auto-approve ecs-plan.tfplan

      - name: Export ECS Outputs
        id: ecs-outputs
        working-directory: terraform/tenants/${{ inputs.tenant_name }}
        run: |
          echo "service_arn=$(terraform output -raw ecs_service_arn)" >> $GITHUB_OUTPUT
          echo "target_group_arn=$(terraform output -raw target_group_arn)" >> $GITHUB_OUTPUT

  phase2-database:
    name: Phase 2 - Database Creation
    needs: phase1-ecs
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ inputs.environment == 'prod' && 'af-south-1' || 'eu-west-1' }}

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install boto3 pymysql

      - name: Get RDS Master Credentials
        id: rds-creds
        run: |
          SECRET=$(aws secretsmanager get-secret-value \
            --secret-id ${{ inputs.environment }}-rds-master-credentials \
            --query SecretString \
            --output text)
          echo "master_creds<<EOF" >> $GITHUB_OUTPUT
          echo "$SECRET" >> $GITHUB_OUTPUT
          echo "EOF" >> $GITHUB_OUTPUT

      - name: Generate Tenant Password
        id: gen-password
        run: |
          PASSWORD=$(openssl rand -base64 24 | tr -d '/+=' | cut -c1-24)
          echo "password=$PASSWORD" >> $GITHUB_OUTPUT

      - name: Create Secrets Manager Secret
        run: |
          aws secretsmanager create-secret \
            --name ${{ inputs.environment }}-${{ inputs.tenant_name }}-db-credentials \
            --secret-string "{\"username\":\"${{ inputs.tenant_name }}_user\",\"password\":\"${{ steps.gen-password.outputs.password }}\",\"database\":\"${{ inputs.tenant_name }}_db\",\"host\":\"$(echo '${{ steps.rds-creds.outputs.master_creds }}' | jq -r .host)\",\"port\":3306}" \
            --tags Key=Tenant,Value=${{ inputs.tenant_name }} Key=Environment,Value=${{ inputs.environment }} \
            || echo "Secret already exists, updating..."

      - name: Create Database
        run: |
          python3 scripts/init_tenant_db.py \
            '${{ steps.rds-creds.outputs.master_creds }}' \
            "{\"database\":\"${{ inputs.tenant_name }}_db\",\"username\":\"${{ inputs.tenant_name }}_user\",\"password\":\"${{ steps.gen-password.outputs.password }}\",\"host\":\"$(echo '${{ steps.rds-creds.outputs.master_creds }}' | jq -r .host)\"}"

      - name: Create IAM Policy for Secret Access
        run: |
          bash scripts/create_iam_policy.sh \
            ${{ inputs.tenant_name }} \
            ${{ inputs.environment }}

  phase3-testing:
    name: Phase 3 - Deployment Testing
    needs: phase2-database
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    if: inputs.environment != 'prod'

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ inputs.environment == 'prod' && 'af-south-1' || 'eu-west-1' }}

      - name: Wait for ECS Service Stabilization
        run: sleep 60

      - name: Run Deployment Verification
        id: verify
        run: |
          bash scripts/verify_deployment.sh ${{ inputs.tenant_name }} ${{ inputs.environment }}

      - name: Upload Test Report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-report-${{ inputs.tenant_name }}-${{ inputs.environment }}
          path: /tmp/verify_*.log

  phase3-dns:
    name: Phase 3 - DNS + CloudFront
    needs: [phase2-database, phase3-testing]
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    if: (inputs.environment == 'sit' || inputs.environment == 'prod') && success()

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ inputs.environment == 'prod' && 'af-south-1' || 'eu-west-1' }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0

      - name: Terraform Apply - DNS Module
        working-directory: terraform/tenants/${{ inputs.tenant_name }}
        run: |
          terraform apply \
            -var-file=${{ inputs.environment }}.tfvars \
            -target=module.dns_cloudfront \
            -auto-approve

      - name: Test HTTPS Endpoint
        run: |
          URL="https://${{ inputs.tenant_name }}.wp${{ inputs.environment }}.kimmyai.io"
          HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $URL)
          echo "HTTP Response: $HTTP_CODE"

          if [[ "$HTTP_CODE" =~ ^(200|301|302|401)$ ]]; then
            echo "✅ HTTPS endpoint is accessible"
          else
            echo "❌ HTTPS endpoint returned unexpected code: $HTTP_CODE"
            exit 1
          fi

  post-deployment:
    name: Post-Deployment Tasks
    needs: [phase3-testing, phase3-dns]
    if: always() && (success() || needs.phase3-testing.result == 'success')
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Generate Tenant Configuration
        run: |
          cat > config/${{ inputs.environment }}/${{ inputs.tenant_name }}.json <<EOF
          {
            "tenant_name": "${{ inputs.tenant_name }}",
            "environment": "${{ inputs.environment }}",
            "deployment_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
            "deployed_by": "${{ github.actor }}",
            "workflow_run": "${{ github.run_id }}",
            "ecs_service": "${{ inputs.environment }}-${{ inputs.tenant_name }}-service",
            "database": "${{ inputs.tenant_name }}_db",
            "secret_name": "${{ inputs.environment }}-${{ inputs.tenant_name }}-db-credentials",
            "url": "https://${{ inputs.tenant_name }}.wp${{ inputs.environment }}.kimmyai.io",
            "alb_priority": ${{ inputs.alb_priority }},
            "region": "${{ inputs.environment == 'prod' && 'af-south-1' || 'eu-west-1' }}",
            "terraform_workspace": "${{ inputs.environment }}",
            "status": "active"
          }
          EOF

      - name: Commit Configuration
        run: |
          git config user.name "GitHub Actions Bot"
          git config user.email "actions@github.com"
          git add config/${{ inputs.environment }}/${{ inputs.tenant_name }}.json
          git commit -m "Add tenant config: ${{ inputs.tenant_name }} (${{ inputs.environment }})"
          git push

      - name: Upload to S3
        run: |
          aws s3 cp \
            config/${{ inputs.environment }}/${{ inputs.tenant_name }}.json \
            s3://bbws-tenant-configs/${{ inputs.environment }}/${{ inputs.tenant_name }}-config.json

      - name: Send Notification
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          text: |
            ✅ Tenant ${{ inputs.tenant_name }} deployed to ${{ inputs.environment }}
            URL: https://${{ inputs.tenant_name }}.wp${{ inputs.environment }}.kimmyai.io
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
        if: always()

  auto-promote:
    name: Auto-Promote to Next Environment
    needs: post-deployment
    if: inputs.auto_promote && inputs.environment == 'dev' && success()
    runs-on: ubuntu-latest

    steps:
      - name: Trigger SIT Deployment
        uses: actions/github-script@v7
        with:
          script: |
            await github.rest.actions.createWorkflowDispatch({
              owner: context.repo.owner,
              repo: context.repo.repo,
              workflow_id: 'tenant-${{ inputs.tenant_name }}.yml',
              ref: 'main',
              inputs: {
                environment: 'sit',
                alb_priority: String(${{ inputs.alb_priority }} + 100)
              }
            })
```

### 2. Tenant-Specific Workflow: `tenant-goldencrust.yml`

```yaml
name: Deploy Tenant - goldencrust

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        type: choice
        options:
          - dev
          - sit
          - prod
      alb_priority:
        description: 'ALB listener rule priority (unique number 10-260)'
        required: true
        type: number
      auto_promote:
        description: 'Auto-promote to next environment if successful'
        required: false
        type: boolean
        default: false

jobs:
  deploy:
    uses: ./.github/workflows/deploy-tenant.yml
    with:
      tenant_name: goldencrust
      environment: ${{ inputs.environment }}
      alb_priority: ${{ inputs.alb_priority }}
      auto_promote: ${{ inputs.auto_promote }}
    secrets:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID_${{ inputs.environment }} }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY_${{ inputs.environment }} }}
```

---

## Terraform Organization

### Module 1: `ecs-tenant`

**File:** `terraform/modules/ecs-tenant/main.tf`

```hcl
# EFS Access Point
resource "aws_efs_access_point" "tenant" {
  file_system_id = var.efs_id

  posix_user {
    uid = 33  # www-data
    gid = 33
  }

  root_directory {
    path = "/${var.tenant_name}"
    creation_info {
      owner_uid   = 33
      owner_gid   = 33
      permissions = "755"
    }
  }

  tags = {
    Name        = "${var.environment}-${var.tenant_name}-ap"
    Tenant      = var.tenant_name
    Environment = var.environment
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "tenant" {
  family                   = "${var.environment}-${var.tenant_name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([{
    name      = "wordpress"
    image     = var.wordpress_image
    essential = true

    portMappings = [{
      containerPort = 80
      protocol      = "tcp"
    }]

    environment = [
      { name = "WORDPRESS_DB_HOST", value = var.rds_endpoint },
      { name = "WORDPRESS_DB_NAME", value = "${var.tenant_name}_db" },
      { name = "WORDPRESS_TABLE_PREFIX", value = "wp_" },
      { name = "WORDPRESS_DEBUG", value = "1" },
      {
        name  = "WORDPRESS_CONFIG_EXTRA"
        value = <<-EOT
          if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
              $_SERVER['HTTPS'] = 'on';
          }
          if (isset($_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO']) && $_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO'] === 'https') {
              $_SERVER['HTTPS'] = 'on';
          }
          define('FORCE_SSL_ADMIN', true);
          define('WP_HOME', 'https://${var.tenant_name}.wp${var.environment}.kimmyai.io');
          define('WP_SITEURL', 'https://${var.tenant_name}.wp${var.environment}.kimmyai.io');
        EOT
      }
    ]

    secrets = [
      {
        name      = "WORDPRESS_DB_USER"
        valueFrom = "${var.secret_arn}:username::"
      },
      {
        name      = "WORDPRESS_DB_PASSWORD"
        valueFrom = "${var.secret_arn}:password::"
      }
    ]

    mountPoints = [{
      sourceVolume  = "wp-content"
      containerPath = "/var/www/html/wp-content"
      readOnly      = false
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.environment}"
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = var.tenant_name
      }
    }
  }])

  volume {
    name = "wp-content"
    efs_volume_configuration {
      file_system_id     = var.efs_id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.tenant.id
        iam             = "ENABLED"
      }
    }
  }

  tags = {
    Name        = "${var.environment}-${var.tenant_name}-task"
    Tenant      = var.tenant_name
    Environment = var.environment
  }
}

# ALB Target Group
resource "aws_lb_target_group" "tenant" {
  name        = "${var.environment}-${var.tenant_name}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200,301,302"
  }

  tags = {
    Name        = "${var.environment}-${var.tenant_name}-tg"
    Tenant      = var.tenant_name
    Environment = var.environment
  }
}

# ALB Listener Rule
resource "aws_lb_listener_rule" "tenant" {
  listener_arn = var.alb_listener_arn
  priority     = var.alb_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tenant.arn
  }

  condition {
    host_header {
      values = ["${var.tenant_name}.wp${var.environment}.kimmyai.io"]
    }
  }

  tags = {
    Name        = "${var.environment}-${var.tenant_name}-rule"
    Tenant      = var.tenant_name
    Environment = var.environment
  }
}

# ECS Service
resource "aws_ecs_service" "tenant" {
  name            = "${var.environment}-${var.tenant_name}-service"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.tenant.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tenant.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  tags = {
    Name        = "${var.environment}-${var.tenant_name}-service"
    Tenant      = var.tenant_name
    Environment = var.environment
  }

  depends_on = [aws_lb_listener_rule.tenant]
}
```

### Module 2: `database` (Python Wrapper)

**File:** `terraform/modules/database/main.tf`

```hcl
# This module wraps the Python database creation script
# Terraform will execute it as a null_resource

resource "null_resource" "create_database" {
  triggers = {
    tenant_name = var.tenant_name
    environment = var.environment
    timestamp   = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      python3 ${path.module}/scripts/create_database.sh \
        ${var.tenant_name} \
        ${var.environment} \
        ${var.rds_master_secret_arn}
    EOT
  }
}

output "database_name" {
  value = "${var.tenant_name}_db"
}

output "secret_name" {
  value = "${var.environment}-${var.tenant_name}-db-credentials"
}
```

**File:** `terraform/modules/database/scripts/create_database.sh`

```bash
#!/bin/bash
# Wrapper script for Python database creation

TENANT=$1
ENV=$2
MASTER_SECRET_ARN=$3

# Get RDS master credentials
MASTER_CREDS=$(aws secretsmanager get-secret-value \
  --secret-id $MASTER_SECRET_ARN \
  --query SecretString \
  --output text)

# Generate tenant password
PASSWORD=$(openssl rand -base64 24 | tr -d '/+=' | cut -c1-24)

# Create tenant secret
aws secretsmanager create-secret \
  --name ${ENV}-${TENANT}-db-credentials \
  --secret-string "{\"username\":\"${TENANT}_user\",\"password\":\"${PASSWORD}\",\"database\":\"${TENANT}_db\"}" \
  || echo "Secret exists, updating..."

# Create database using Python script
TENANT_CREDS="{\"database\":\"${TENANT}_db\",\"username\":\"${TENANT}_user\",\"password\":\"${PASSWORD}\"}"

python3 $(dirname $0)/../../../scripts/init_tenant_db.py \
  "$MASTER_CREDS" \
  "$TENANT_CREDS"

# Create IAM policy
bash $(dirname $0)/../../../scripts/create_iam_policy.sh $TENANT $ENV
```

### Module 3: `dns-cloudfront`

**File:** `terraform/modules/dns-cloudfront/main.tf`

```hcl
# Route53 A Record
resource "aws_route53_record" "tenant" {
  zone_id = var.route53_zone_id
  name    = "${var.tenant_name}.wp${var.environment}.kimmyai.io"
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_zone_id
    evaluate_target_health = false
  }
}

output "dns_name" {
  value = aws_route53_record.tenant.fqdn
}
```

---

## S3 State Management

### Backend Configuration

**File:** `terraform/tenants/goldencrust/backend.tf`

```hcl
terraform {
  backend "s3" {
    # Configured via -backend-config in GitHub Actions
    # bucket         = "bbws-terraform-state-${environment}"
    # key            = "tenants/goldencrust/terraform.tfstate"
    # region         = "eu-west-1" or "af-south-1"
    # dynamodb_table = "bbws-terraform-locks-${environment}"
    encrypt        = true
  }
}
```

### S3 Bucket Structure

```
S3 Bucket: bbws-terraform-state-dev
├── tenants/
│   ├── goldencrust/
│   │   └── terraform.tfstate
│   ├── sunsetbistro/
│   │   └── terraform.tfstate
│   └── ...

S3 Bucket: bbws-terraform-state-sit
├── tenants/
│   ├── goldencrust/
│   │   └── terraform.tfstate
│   └── ...

S3 Bucket: bbws-terraform-state-prod
├── tenants/
│   ├── goldencrust/
│   │   └── terraform.tfstate
│   └── ...
```

### DynamoDB Lock Tables

```
Table: bbws-terraform-locks-dev
├── LockID (String, Partition Key)

Table: bbws-terraform-locks-sit
├── LockID (String, Partition Key)

Table: bbws-terraform-locks-prod
├── LockID (String, Partition Key)
```

---

## Deployment Phases

### Phase 1: ECS Infrastructure (Terraform)

**Resources Created:**
- EFS Access Point
- ECS Task Definition
- ALB Target Group
- ALB Listener Rule
- ECS Service

**Duration:** ~2-3 minutes

**Rollback Strategy:**
- `terraform destroy -target=module.ecs_tenant`
- Removes all ECS resources
- Does not affect database

---

### Phase 2: Database Creation (Python Script)

**Resources Created:**
- Secrets Manager Secret
- MySQL Database
- MySQL User with Privileges
- IAM Policy for Secret Access

**Duration:** ~1 minute

**Rollback Strategy:**
- Delete secret: `aws secretsmanager delete-secret --secret-id {env}-{tenant}-db-credentials --force`
- Drop database: Execute `DROP DATABASE {tenant}_db; DROP USER '{tenant}_user'@'%';`
- Delete IAM policy: `aws iam delete-role-policy --role-name {env}-ecs-task-execution-role --policy-name {env}-ecs-secrets-access-{tenant}`

---

### Phase 3A: Testing (DEV/SIT Only)

**Tests Performed:**
1. Secrets Manager secret exists
2. ECS service status = ACTIVE
3. ECS tasks running = desired count
4. ALB target health = healthy
5. HTTP endpoint returns 200/301/302
6. CloudWatch logs show no errors

**Duration:** ~2-3 minutes (includes 60s wait)

**Failure Action:**
- Trigger automatic rollback
- Upload test report as artifact
- Send failure notification

---

### Phase 3B: DNS + CloudFront (SIT/PROD Only)

**Resources Created:**
- Route53 A record

**Duration:** ~1 minute

**Tests Performed:**
- HTTPS endpoint accessible (200/301/302/401)
- WordPress installation page loads
- Basic Auth working (if SIT/PROD)

---

## Approval Gates

### GitHub Environment Protection Rules

**Environment: dev**
- No approval required
- Auto-deploy on workflow trigger

**Environment: sit**
- Optional: Require 1 reviewer approval
- Wait timer: 0 minutes
- Auto-promote from DEV (if enabled)

**Environment: prod**
- **REQUIRED: 2 reviewer approvals**
- Restricted to designated approvers:
  - @tebogotseka
  - @lead-devops-engineer
- Wait timer: 5 minutes (manual review window)
- Deployment window: Business hours only (optional)

### Setting Up Protection Rules

```bash
# Via GitHub UI:
# Settings → Environments → Create Environment → Protection Rules

# Or via GitHub API:
curl -X PUT \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/OWNER/REPO/environments/prod \
  -d '{
    "reviewers": [
      {"type": "User", "id": 12345678}
    ],
    "deployment_branch_policy": {
      "protected_branches": true,
      "custom_branch_policies": false
    }
  }'
```

---

## Tenant Configuration Document

### Generated Configuration JSON

**File:** `config/sit/goldencrust.json`

```json
{
  "tenant_name": "goldencrust",
  "environment": "sit",
  "deployment_date": "2025-12-23T10:30:00Z",
  "deployed_by": "tebogotseka",
  "workflow_run": "12345678",
  "version": "1.0.0",

  "infrastructure": {
    "region": "eu-west-1",
    "vpc_id": "vpc-xxxxx",
    "cluster": "sit-cluster",
    "ecs_service": "sit-goldencrust-service",
    "task_definition": "sit-goldencrust:5",
    "target_group": "sit-goldencrust-tg",
    "alb_listener_rule_priority": 140
  },

  "database": {
    "name": "goldencrust_db",
    "username": "goldencrust_user",
    "rds_endpoint": "sit-mysql.xxxxx.eu-west-1.rds.amazonaws.com",
    "secret_arn": "arn:aws:secretsmanager:eu-west-1:815856636111:secret:sit-goldencrust-db-credentials-xxxxx"
  },

  "storage": {
    "efs_id": "fs-xxxxx",
    "access_point_id": "fsap-xxxxx",
    "mount_path": "/goldencrust"
  },

  "networking": {
    "domain": "goldencrust.wpsit.kimmyai.io",
    "url": "https://goldencrust.wpsit.kimmyai.io",
    "cloudfront_distribution": "E1234567890ABC",
    "route53_zone_id": "Z07406882WSFMSDQTX1HR",
    "basic_auth": true
  },

  "terraform": {
    "workspace": "sit",
    "state_bucket": "bbws-terraform-state-sit",
    "state_key": "tenants/goldencrust/terraform.tfstate",
    "lock_table": "bbws-terraform-locks-sit"
  },

  "status": "active",
  "health_check_url": "https://goldencrust.wpsit.kimmyai.io/",
  "admin_url": "https://goldencrust.wpsit.kimmyai.io/wp-admin"
}
```

---

## Rollback Strategy

### Automatic Rollback Triggers

1. **Phase 1 Failure:** Terraform apply fails
   - **Action:** `terraform destroy -target=module.ecs_tenant -auto-approve`
   - **Result:** All ECS resources removed

2. **Phase 2 Failure:** Database creation fails
   - **Action:** Delete secret, drop database, remove IAM policy
   - **Result:** Database resources cleaned up

3. **Phase 3 Testing Failure:** Health checks fail
   - **Action:** Destroy all resources (Phase 1 + Phase 2)
   - **Result:** Complete cleanup

### Manual Rollback Procedure

```bash
# 1. Destroy Terraform resources
cd terraform/tenants/goldencrust
terraform workspace select sit
terraform destroy -var-file=sit.tfvars -auto-approve

# 2. Delete database
aws ecs run-task \
  --cluster sit-cluster \
  --task-definition sit-db-init:1 \
  --overrides '{
    "containerOverrides": [{
      "name": "db-init",
      "command": ["sh", "-c", "mysql -h $DB_HOST -u $MASTER_USER -p$MASTER_PASSWORD -e \"DROP DATABASE IF EXISTS goldencrust_db; DROP USER IF EXISTS goldencrust_user@'%';\""]
    }]
  }'

# 3. Delete secrets
aws secretsmanager delete-secret \
  --secret-id sit-goldencrust-db-credentials \
  --force-delete-without-recovery

# 4. Delete IAM policy
aws iam delete-role-policy \
  --role-name sit-ecs-task-execution-role \
  --policy-name sit-ecs-secrets-access-goldencrust

# 5. Delete configuration
rm config/sit/goldencrust.json
git add config/sit/goldencrust.json
git commit -m "Remove tenant config: goldencrust (sit)"
git push
```

---

## Implementation Plan

### Phase 1: Foundation (Week 1-2)

**Tasks:**
1. ✅ Create S3 buckets for Terraform state (per environment)
2. ✅ Create DynamoDB tables for Terraform locks (per environment)
3. ✅ Create reusable Terraform modules:
   - `ecs-tenant`
   - `database`
   - `dns-cloudfront`
4. ✅ Create GitHub Actions reusable workflow: `deploy-tenant.yml`
5. ✅ Set up GitHub Environments with protection rules
6. ✅ Configure GitHub Secrets for AWS credentials

**Deliverables:**
- S3 buckets: `bbws-terraform-state-{dev|sit|prod}`
- DynamoDB tables: `bbws-terraform-locks-{dev|sit|prod}`
- Terraform modules in `terraform/modules/`
- GitHub workflow: `.github/workflows/deploy-tenant.yml`

---

### Phase 2: Pilot Deployment (Week 3)

**Tasks:**
1. ✅ Create tenant-specific workflow for `goldencrust`
2. ✅ Create Terraform configuration for `goldencrust`:
   - `terraform/tenants/goldencrust/main.tf`
   - `terraform/tenants/goldencrust/dev.tfvars`
   - `terraform/tenants/goldencrust/sit.tfvars`
   - `terraform/tenants/goldencrust/prod.tfvars`
3. ✅ Test deployment to DEV
4. ✅ Test deployment to SIT (with approval)
5. ✅ Test deployment to PROD (with approval)
6. ✅ Validate tenant configuration document generation

**Success Criteria:**
- goldencrust successfully deployed to all 3 environments
- All health checks pass
- Terraform state persisted to S3
- Configuration documents generated correctly

---

### Phase 3: Batch Rollout (Week 4-5)

**Tasks:**
1. ✅ Create workflows for remaining tenants:
   - sunsetbistro
   - sterlinglaw
   - ironpeak
   - premierprop
   - lenslight
   - nexgentech
   - serenity
   - bloompetal
   - precisionauto
2. ✅ Deploy all tenants to DEV (automated)
3. ✅ Deploy all tenants to SIT (automated with testing)
4. ✅ Deploy all tenants to PROD (manual approval)

**Timeline:**
- Week 4: Deploy 5 tenants
- Week 5: Deploy remaining 5 tenants

---

### Phase 4: Optimization (Week 6)

**Tasks:**
1. ✅ Implement auto-promotion (DEV → SIT)
2. ✅ Add Slack/Email notifications
3. ✅ Create monitoring dashboards
4. ✅ Document operational procedures
5. ✅ Conduct team training

---

## Operational Procedures

### Deploying a New Tenant

1. Navigate to GitHub Actions
2. Select tenant workflow (e.g., `tenant-goldencrust.yml`)
3. Click "Run workflow"
4. Fill in inputs:
   - Environment: `dev`
   - ALB Priority: `140`
   - Auto-promote: `false`
5. Click "Run workflow"
6. Monitor execution in Actions tab
7. Review generated configuration in `config/dev/goldencrust.json`

### Promoting Tenant to SIT

**Option A: Manual**
1. Trigger tenant workflow with `environment: sit`
2. ALB Priority: `240` (DEV priority + 100)

**Option B: Automatic** (if enabled)
1. Deployment to DEV completes successfully
2. Workflow automatically triggers SIT deployment
3. Monitor SIT deployment progress

### Promoting Tenant to PROD

1. Trigger tenant workflow with `environment: prod`
2. ALB Priority: `340` (SIT priority + 100)
3. **Wait for approval** (2 reviewers required)
4. Reviewers check:
   - DEV and SIT deployments successful
   - All tests passed
   - Tenant configuration correct
5. Approve deployment
6. Monitor PROD deployment

### Troubleshooting Failed Deployment

1. Check GitHub Actions logs
2. Review test report artifact
3. Check CloudWatch logs:
   ```bash
   aws logs tail /ecs/sit --filter-pattern 'goldencrust' --follow
   ```
4. Verify Terraform state:
   ```bash
   cd terraform/tenants/goldencrust
   terraform workspace select sit
   terraform show
   ```
5. Manual rollback if needed (see Rollback Strategy)

---

## Security Considerations

### GitHub Secrets

Store per-environment AWS credentials:

```
AWS_ACCESS_KEY_ID_dev
AWS_SECRET_ACCESS_KEY_dev
AWS_ACCESS_KEY_ID_sit
AWS_SECRET_ACCESS_KEY_sit
AWS_ACCESS_KEY_ID_prod
AWS_SECRET_ACCESS_KEY_prod
SLACK_WEBHOOK
```

### IAM Permissions Required

**Minimum permissions for GitHub Actions:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:*",
        "elbv2:*",
        "elasticfilesystem:*",
        "secretsmanager:*",
        "iam:GetRole",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "logs:*",
        "s3:GetObject",
        "s3:PutObject",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "*"
    }
  ]
}
```

### State File Encryption

- S3 bucket encryption: **AES-256**
- Terraform state encryption: **Enabled**
- DynamoDB encryption: **AWS managed keys**

---

## Cost Optimization

### GitHub Actions Minutes

- Free tier: 2,000 minutes/month (private repos)
- Estimated usage per deployment: ~10 minutes
- Monthly deployments: ~50
- Total minutes: 500/month
- **Cost: $0 (within free tier)**

### S3 Storage Costs

- Terraform state files: ~10 KB each
- 13 tenants × 3 environments = 39 files
- Total storage: ~400 KB
- **Cost: $0.01/month**

### DynamoDB Costs

- On-demand pricing
- Lock operations: ~10 per deployment
- Monthly operations: 500
- **Cost: $0.25/month**

**Total Infrastructure Cost: ~$0.26/month**

---

## Monitoring & Alerting

### GitHub Actions Notifications

- Slack notifications on deployment success/failure
- Email notifications for PROD approvals
- GitHub commit status updates

### Deployment Metrics

Track in GitHub Actions:
- Deployment success rate
- Average deployment time
- Rollback frequency
- Time to production

### CloudWatch Alarms

- ECS service health (desired count != running count)
- ALB unhealthy targets
- Database connection errors
- High error rates in logs

---

## Appendix

### A. Required AWS Resources

**Per Environment:**
- S3 bucket for Terraform state
- DynamoDB table for Terraform locks
- ECS cluster
- RDS MySQL instance
- Application Load Balancer
- EFS filesystem
- CloudFront distribution
- Route53 hosted zone

### B. GitHub Repository Structure

```
2_bbws_agents/
├── .github/
│   └── workflows/
│       ├── deploy-tenant.yml
│       ├── tenant-goldencrust.yml
│       └── ... (13 tenant workflows)
├── terraform/
│   ├── modules/
│   │   ├── ecs-tenant/
│   │   ├── database/
│   │   └── dns-cloudfront/
│   └── tenants/
│       ├── goldencrust/
│       └── ... (13 tenant configs)
├── scripts/
│   ├── init_tenant_db.py
│   ├── verify_deployment.sh
│   └── create_iam_policy.sh
└── config/
    ├── dev/
    ├── sit/
    └── prod/
```

### C. Glossary

- **ALB Priority:** Unique number (10-260) for ALB listener rule ordering
- **EFS Access Point:** Isolated directory path for tenant wp-content
- **Terraform Workspace:** Environment-specific state isolation
- **GitHub Environment:** Protected deployment target with approval rules

---

## Document Status

**Version:** 1.0 (Draft)
**Next Review:** 2025-12-30
**Approvals Required:**
- [ ] DevOps Lead
- [ ] Infrastructure Architect
- [ ] Security Team

**Change Log:**
- 2025-12-23: Initial design draft created

---

**END OF DOCUMENT**
