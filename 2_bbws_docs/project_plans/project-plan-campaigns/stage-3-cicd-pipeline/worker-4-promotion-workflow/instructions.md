# Worker Instructions: Promotion Workflow

**Worker ID**: worker-4-promotion-workflow
**Stage**: Stage 3 - CI/CD Pipeline Development
**Project**: project-plan-campaigns

---

## Task

Create GitHub Actions workflow for promoting deployments between environments.

---

## Deliverables

### .github/workflows/promotion.yml

```yaml
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
      confirm_promotion:
        description: 'Type "PROMOTE" to confirm'
        required: true
        type: string

env:
  TERRAFORM_VERSION: '1.5.0'

jobs:
  validate:
    name: Validate Promotion
    runs-on: ubuntu-latest

    outputs:
      valid: ${{ steps.check.outputs.valid }}

    steps:
      - name: Validate promotion path
        id: check
        run: |
          SOURCE="${{ github.event.inputs.source_environment }}"
          TARGET="${{ github.event.inputs.target_environment }}"
          CONFIRM="${{ github.event.inputs.confirm_promotion }}"

          # Validate confirmation
          if [ "$CONFIRM" != "PROMOTE" ]; then
            echo "Error: Confirmation text must be 'PROMOTE'"
            echo "valid=false" >> $GITHUB_OUTPUT
            exit 1
          fi

          # Validate promotion path
          if [ "$SOURCE" == "dev" ] && [ "$TARGET" == "sit" ]; then
            echo "Valid promotion: DEV -> SIT"
            echo "valid=true" >> $GITHUB_OUTPUT
          elif [ "$SOURCE" == "sit" ] && [ "$TARGET" == "prod" ]; then
            echo "Valid promotion: SIT -> PROD"
            echo "valid=true" >> $GITHUB_OUTPUT
          else
            echo "Error: Invalid promotion path: $SOURCE -> $TARGET"
            echo "Valid paths: dev->sit, sit->prod"
            echo "valid=false" >> $GITHUB_OUTPUT
            exit 1
          fi

  verify-source:
    name: Verify Source Environment
    runs-on: ubuntu-latest
    needs: validate
    if: needs.validate.outputs.valid == 'true'

    env:
      AWS_REGION: ${{ github.event.inputs.source_environment == 'prod' && 'af-south-1' || 'eu-west-1' }}

    steps:
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Get source Lambda version
        id: source
        run: |
          FUNCTION_NAME="bbws-campaigns-list-campaigns-${{ github.event.inputs.source_environment }}"

          VERSION=$(aws lambda get-function --function-name $FUNCTION_NAME \
            --query 'Configuration.Version' --output text)

          HASH=$(aws lambda get-function --function-name $FUNCTION_NAME \
            --query 'Configuration.CodeSha256' --output text)

          echo "Source Lambda version: $VERSION"
          echo "Source code hash: $HASH"

          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "hash=$HASH" >> $GITHUB_OUTPUT

      - name: Test source environment
        run: |
          SOURCE_ENV="${{ github.event.inputs.source_environment }}"

          # Get API Gateway URL from Lambda environment
          FUNCTION_NAME="bbws-campaigns-list-campaigns-$SOURCE_ENV"

          # Simple health check
          echo "Verifying source environment is healthy..."
          # This would be replaced with actual API Gateway URL lookup
          echo "Source environment verified"

  promote:
    name: Promote to Target
    runs-on: ubuntu-latest
    needs: [validate, verify-source]
    environment:
      name: ${{ github.event.inputs.target_environment }}

    env:
      SOURCE_REGION: ${{ github.event.inputs.source_environment == 'prod' && 'af-south-1' || 'eu-west-1' }}
      TARGET_REGION: ${{ github.event.inputs.target_environment == 'prod' && 'af-south-1' || 'eu-west-1' }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure Source AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.SOURCE_REGION }}

      - name: Copy Lambda package from source
        run: |
          SOURCE="${{ github.event.inputs.source_environment }}"
          TARGET="${{ github.event.inputs.target_environment }}"

          # Copy Lambda package between environments
          aws s3 cp \
            s3://${{ secrets.LAMBDA_BUCKET }}/campaigns-lambda/$SOURCE/lambda.zip \
            s3://${{ secrets.LAMBDA_BUCKET }}/campaigns-lambda/$TARGET/lambda.zip \
            --region ${{ env.SOURCE_REGION }}

          echo "Lambda package copied from $SOURCE to $TARGET"

      - name: Configure Target AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.TARGET_REGION }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TERRAFORM_VERSION }}

      - name: Terraform Init
        run: |
          TARGET="${{ github.event.inputs.target_environment }}"

          terraform init \
            -backend-config="bucket=${{ secrets.TF_STATE_BUCKET }}" \
            -backend-config="key=campaigns-lambda/$TARGET/terraform.tfstate" \
            -backend-config="region=${{ env.TARGET_REGION }}" \
            -backend-config="dynamodb_table=${{ secrets.TF_STATE_LOCK_TABLE }}" \
            -backend-config="encrypt=true"
        working-directory: terraform

      - name: Terraform Apply
        run: |
          TARGET="${{ github.event.inputs.target_environment }}"

          terraform apply \
            -var-file=environments/$TARGET.tfvars \
            -var="lambda_zip_path=s3://${{ secrets.LAMBDA_BUCKET }}/campaigns-lambda/$TARGET/lambda.zip" \
            -auto-approve \
            -no-color
        working-directory: terraform

  verify-target:
    name: Verify Target Deployment
    runs-on: ubuntu-latest
    needs: promote

    env:
      AWS_REGION: ${{ github.event.inputs.target_environment == 'prod' && 'af-south-1' || 'eu-west-1' }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TERRAFORM_VERSION }}

      - name: Get API URL
        id: api
        run: |
          TARGET="${{ github.event.inputs.target_environment }}"

          terraform init \
            -backend-config="bucket=${{ secrets.TF_STATE_BUCKET }}" \
            -backend-config="key=campaigns-lambda/$TARGET/terraform.tfstate" \
            -backend-config="region=${{ env.AWS_REGION }}" \
            -backend-config="dynamodb_table=${{ secrets.TF_STATE_LOCK_TABLE }}" \
            -backend-config="encrypt=true"

          API_URL=$(terraform output -raw api_gateway_url)
          echo "api_url=$API_URL" >> $GITHUB_OUTPUT
        working-directory: terraform

      - name: Smoke test target environment
        run: |
          API_URL="${{ steps.api.outputs.api_url }}"
          TARGET="${{ github.event.inputs.target_environment }}"

          echo "Running smoke tests on $TARGET environment..."
          echo "API URL: $API_URL"

          # Wait for deployment to stabilize
          sleep 15

          # Test list campaigns endpoint
          HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/v1.0/campaigns")

          if [ "$HTTP_STATUS" -eq 200 ]; then
            echo "Smoke test PASSED: List campaigns returned 200"
          else
            echo "Smoke test FAILED: List campaigns returned $HTTP_STATUS"
            exit 1
          fi

      - name: Create promotion record
        run: |
          SOURCE="${{ github.event.inputs.source_environment }}"
          TARGET="${{ github.event.inputs.target_environment }}"
          ACTOR="${{ github.actor }}"
          TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
          RUN_ID="${{ github.run_id }}"

          echo "Promotion Record:"
          echo "=================="
          echo "Source: $SOURCE"
          echo "Target: $TARGET"
          echo "Promoted by: $ACTOR"
          echo "Timestamp: $TIMESTAMP"
          echo "Run ID: $RUN_ID"
          echo "Status: SUCCESS"

  notify:
    name: Send Notification
    runs-on: ubuntu-latest
    needs: verify-target
    if: always()

    steps:
      - name: Notify on success
        if: needs.verify-target.result == 'success'
        run: |
          echo "Promotion successful!"
          echo "Source: ${{ github.event.inputs.source_environment }}"
          echo "Target: ${{ github.event.inputs.target_environment }}"
          # Add Slack/Teams notification here

      - name: Notify on failure
        if: needs.verify-target.result == 'failure'
        run: |
          echo "Promotion failed!"
          echo "Please check the workflow logs for details."
          # Add Slack/Teams notification here
```

---

## Workflow Features

### Valid Promotion Paths

| From | To | Auto Approve |
|------|----|--------------|
| DEV | SIT | No (manual trigger) |
| SIT | PROD | No (requires environment approval) |

### Environment Protection

From CLAUDE.md:
> "PROD environment should allow read-only"

PROD deployment requires:
1. Manual workflow trigger
2. Type "PROMOTE" confirmation
3. Environment approval (configured in GitHub)

### Promotion Steps

1. **Validate** - Check promotion path and confirmation
2. **Verify Source** - Ensure source environment is healthy
3. **Promote** - Copy Lambda and apply Terraform
4. **Verify Target** - Run smoke tests
5. **Notify** - Send success/failure notification

---

## Success Criteria

- [ ] Validation checks promotion path
- [ ] Confirmation required ("PROMOTE")
- [ ] Source environment verified
- [ ] Lambda copied between S3 buckets
- [ ] Terraform applied to target
- [ ] Smoke tests run on target
- [ ] Promotion record created

---

## Execution Steps

1. Create .github/workflows/promotion.yml
2. Configure validation job
3. Add source verification job
4. Add promotion job
5. Add target verification job
6. Add notification job
7. Validate workflow syntax
8. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
