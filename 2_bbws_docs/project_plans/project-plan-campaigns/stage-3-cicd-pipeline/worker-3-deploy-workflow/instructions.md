# Worker Instructions: Deploy Workflow

**Worker ID**: worker-3-deploy-workflow
**Stage**: Stage 3 - CI/CD Pipeline Development
**Project**: project-plan-campaigns

---

## Task

Create GitHub Actions workflow for deploying the Lambda service to AWS environments.

---

## Deliverables

### .github/workflows/deploy.yml

```yaml
name: Deploy

on:
  push:
    branches:
      - main
    paths:
      - 'src/**'
      - 'terraform/**'
      - 'requirements.txt'

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
        default: dev

env:
  PYTHON_VERSION: '3.12'
  TERRAFORM_VERSION: '1.5.0'

jobs:
  build:
    name: Build Lambda Package
    runs-on: ubuntu-latest

    outputs:
      package_hash: ${{ steps.hash.outputs.hash }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Install dependencies for packaging
        run: |
          python -m pip install --upgrade pip
          mkdir -p package
          pip install -r requirements.txt -t package/

      - name: Copy source code
        run: |
          cp -r src/ package/

      - name: Create Lambda ZIP
        run: |
          cd package
          zip -r ../lambda.zip .
          cd ..

      - name: Calculate package hash
        id: hash
        run: |
          HASH=$(sha256sum lambda.zip | cut -d ' ' -f 1)
          echo "hash=$HASH" >> $GITHUB_OUTPUT

      - name: Upload Lambda package
        uses: actions/upload-artifact@v4
        with:
          name: lambda-package
          path: lambda.zip
          retention-days: 30

  deploy-dev:
    name: Deploy to DEV
    runs-on: ubuntu-latest
    needs: build
    if: github.event_name == 'push' || (github.event_name == 'workflow_dispatch' && github.event.inputs.environment == 'dev')
    environment:
      name: dev
      url: ${{ steps.output.outputs.api_url }}

    env:
      AWS_REGION: 'eu-west-1'
      ENVIRONMENT: 'dev'

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Download Lambda package
        uses: actions/download-artifact@v4
        with:
          name: lambda-package
          path: dist/

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Upload Lambda to S3
        run: |
          aws s3 cp dist/lambda.zip s3://${{ secrets.LAMBDA_BUCKET }}/campaigns-lambda/${{ env.ENVIRONMENT }}/lambda.zip

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TERRAFORM_VERSION }}

      - name: Terraform Init
        run: |
          terraform init \
            -backend-config="bucket=${{ secrets.TF_STATE_BUCKET }}" \
            -backend-config="key=campaigns-lambda/${{ env.ENVIRONMENT }}/terraform.tfstate" \
            -backend-config="region=${{ env.AWS_REGION }}" \
            -backend-config="dynamodb_table=${{ secrets.TF_STATE_LOCK_TABLE }}" \
            -backend-config="encrypt=true"
        working-directory: terraform

      - name: Terraform Apply
        run: |
          terraform apply \
            -var-file=environments/${{ env.ENVIRONMENT }}.tfvars \
            -var="lambda_zip_path=s3://${{ secrets.LAMBDA_BUCKET }}/campaigns-lambda/${{ env.ENVIRONMENT }}/lambda.zip" \
            -auto-approve \
            -no-color
        working-directory: terraform

      - name: Get API URL
        id: output
        run: |
          API_URL=$(terraform output -raw api_gateway_url)
          echo "api_url=$API_URL" >> $GITHUB_OUTPUT
        working-directory: terraform

      - name: Validate Deployment
        run: |
          echo "Validating deployment to DEV..."
          API_URL="${{ steps.output.outputs.api_url }}"
          echo "API URL: $API_URL"

          # Wait for API Gateway to be ready
          sleep 10

          # Test list campaigns endpoint
          HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/v1.0/campaigns")
          if [ "$HTTP_STATUS" -eq 200 ]; then
            echo "Deployment validation successful!"
          else
            echo "Deployment validation failed with status: $HTTP_STATUS"
            exit 1
          fi

  deploy-sit:
    name: Deploy to SIT
    runs-on: ubuntu-latest
    needs: build
    if: github.event_name == 'workflow_dispatch' && github.event.inputs.environment == 'sit'
    environment:
      name: sit
      url: ${{ steps.output.outputs.api_url }}

    env:
      AWS_REGION: 'eu-west-1'
      ENVIRONMENT: 'sit'

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Download Lambda package
        uses: actions/download-artifact@v4
        with:
          name: lambda-package
          path: dist/

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Upload Lambda to S3
        run: |
          aws s3 cp dist/lambda.zip s3://${{ secrets.LAMBDA_BUCKET }}/campaigns-lambda/${{ env.ENVIRONMENT }}/lambda.zip

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TERRAFORM_VERSION }}

      - name: Terraform Init
        run: |
          terraform init \
            -backend-config="bucket=${{ secrets.TF_STATE_BUCKET }}" \
            -backend-config="key=campaigns-lambda/${{ env.ENVIRONMENT }}/terraform.tfstate" \
            -backend-config="region=${{ env.AWS_REGION }}" \
            -backend-config="dynamodb_table=${{ secrets.TF_STATE_LOCK_TABLE }}" \
            -backend-config="encrypt=true"
        working-directory: terraform

      - name: Terraform Apply
        run: |
          terraform apply \
            -var-file=environments/${{ env.ENVIRONMENT }}.tfvars \
            -var="lambda_zip_path=s3://${{ secrets.LAMBDA_BUCKET }}/campaigns-lambda/${{ env.ENVIRONMENT }}/lambda.zip" \
            -auto-approve \
            -no-color
        working-directory: terraform

      - name: Get API URL
        id: output
        run: |
          API_URL=$(terraform output -raw api_gateway_url)
          echo "api_url=$API_URL" >> $GITHUB_OUTPUT
        working-directory: terraform

  deploy-prod:
    name: Deploy to PROD
    runs-on: ubuntu-latest
    needs: build
    if: github.event_name == 'workflow_dispatch' && github.event.inputs.environment == 'prod'
    environment:
      name: prod
      url: ${{ steps.output.outputs.api_url }}

    env:
      AWS_REGION: 'af-south-1'
      ENVIRONMENT: 'prod'

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Download Lambda package
        uses: actions/download-artifact@v4
        with:
          name: lambda-package
          path: dist/

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Upload Lambda to S3
        run: |
          aws s3 cp dist/lambda.zip s3://${{ secrets.LAMBDA_BUCKET }}/campaigns-lambda/${{ env.ENVIRONMENT }}/lambda.zip

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TERRAFORM_VERSION }}

      - name: Terraform Init
        run: |
          terraform init \
            -backend-config="bucket=${{ secrets.TF_STATE_BUCKET }}" \
            -backend-config="key=campaigns-lambda/${{ env.ENVIRONMENT }}/terraform.tfstate" \
            -backend-config="region=${{ env.AWS_REGION }}" \
            -backend-config="dynamodb_table=${{ secrets.TF_STATE_LOCK_TABLE }}" \
            -backend-config="encrypt=true"
        working-directory: terraform

      - name: Terraform Apply
        run: |
          terraform apply \
            -var-file=environments/${{ env.ENVIRONMENT }}.tfvars \
            -var="lambda_zip_path=s3://${{ secrets.LAMBDA_BUCKET }}/campaigns-lambda/${{ env.ENVIRONMENT }}/lambda.zip" \
            -auto-approve \
            -no-color
        working-directory: terraform

      - name: Get API URL
        id: output
        run: |
          API_URL=$(terraform output -raw api_gateway_url)
          echo "api_url=$API_URL" >> $GITHUB_OUTPUT
        working-directory: terraform
```

---

## Workflow Features

### Triggers
- Push to main branch (auto-deploy to DEV)
- Manual workflow dispatch with environment choice

### Environment Configuration

| Environment | Region | Auto Deploy | Approval Required |
|-------------|--------|-------------|-------------------|
| DEV | eu-west-1 | Yes (on push) | No |
| SIT | eu-west-1 | No (manual) | No |
| PROD | af-south-1 | No (manual) | Yes |

### Required Secrets (per environment)

```
AWS_ACCESS_KEY_ID      - AWS access key
AWS_SECRET_ACCESS_KEY  - AWS secret key
TF_STATE_BUCKET        - S3 bucket for state
TF_STATE_LOCK_TABLE    - DynamoDB table for locking
LAMBDA_BUCKET          - S3 bucket for Lambda code
```

---

## Success Criteria

- [ ] Build job creates Lambda package
- [ ] DEV deploys automatically on push
- [ ] SIT/PROD require manual trigger
- [ ] Each environment uses correct region
- [ ] Deployment validation included
- [ ] API URL output captured

---

## Execution Steps

1. Create .github/workflows/deploy.yml
2. Configure build job
3. Add DEV deployment job
4. Add SIT deployment job
5. Add PROD deployment job
6. Add deployment validation
7. Validate workflow syntax
8. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
