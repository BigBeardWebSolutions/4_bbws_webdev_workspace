# Worker Instructions: Deployment Runbook

**Worker ID**: worker-2-deployment-runbook
**Stage**: Stage 5 - Documentation & Deployment
**Project**: project-plan-campaigns

---

## Task

Create comprehensive deployment runbook for the Campaign Lambda service.

---

## Deliverables

### docs/deployment-runbook.md

```markdown
# Campaign Lambda Service - Deployment Runbook

**Version**: 1.0
**Last Updated**: 2026-01-15
**Service**: 2_bbws_campaigns_lambda

---

## Overview

This runbook provides step-by-step instructions for deploying the Campaign Lambda service to AWS environments.

---

## Prerequisites

### Tools Required

| Tool | Version | Installation |
|------|---------|--------------|
| AWS CLI | 2.x | `brew install awscli` |
| Terraform | 1.5+ | `brew install terraform` |
| Python | 3.12 | `pyenv install 3.12` |
| GitHub CLI | 2.x | `brew install gh` |

### AWS Credentials

Ensure you have AWS credentials configured for the target environment:

```bash
# Configure credentials
aws configure --profile bbws-dev

# Verify access
aws sts get-caller-identity --profile bbws-dev
```

### Environment Access

| Environment | Region | AWS Account |
|-------------|--------|-------------|
| DEV | eu-west-1 | 536580886816 |
| SIT | eu-west-1 | 815856636111 |
| PROD | af-south-1 | 093646564004 |

---

## Deployment Methods

### Method 1: GitHub Actions (Recommended)

#### Deploy to DEV (Automatic)

Push to main branch triggers automatic deployment:

```bash
git checkout main
git pull origin main
git push origin main
```

Monitor deployment in GitHub Actions.

#### Deploy to SIT/PROD (Manual)

1. Go to GitHub repository
2. Click "Actions" tab
3. Select "Deploy" workflow
4. Click "Run workflow"
5. Select target environment
6. Click "Run workflow"

### Method 2: Manual Deployment

#### Step 1: Build Lambda Package

```bash
cd 2_bbws_campaigns_lambda

# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt -t package/
cp -r src/ package/

# Create ZIP
cd package
zip -r ../dist/lambda.zip .
cd ..
```

#### Step 2: Upload to S3

```bash
ENVIRONMENT=dev
REGION=eu-west-1

aws s3 cp dist/lambda.zip \
  s3://bbws-lambda-packages-${ENVIRONMENT}/campaigns-lambda/lambda.zip \
  --region $REGION
```

#### Step 3: Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init \
  -backend-config="bucket=bbws-terraform-state-${ENVIRONMENT}" \
  -backend-config="key=campaigns-lambda/terraform.tfstate" \
  -backend-config="region=${REGION}"

# Plan changes
terraform plan -var-file=environments/${ENVIRONMENT}.tfvars -out=tfplan

# Apply changes (review plan first!)
terraform apply tfplan
```

#### Step 4: Validate Deployment

```bash
# Get API URL
API_URL=$(terraform output -raw api_gateway_url)

# Run validation
python scripts/validate_deployment.py $API_URL
```

---

## Rollback Procedures

### Quick Rollback (Lambda Version)

```bash
FUNCTION_NAME=bbws-campaigns-list-campaigns-dev
PREVIOUS_VERSION=1

# List versions
aws lambda list-versions-by-function --function-name $FUNCTION_NAME

# Update alias to previous version
aws lambda update-alias \
  --function-name $FUNCTION_NAME \
  --name live \
  --function-version $PREVIOUS_VERSION
```

### Full Rollback (Terraform)

```bash
cd terraform

# Get previous state version
terraform state list

# Rollback to previous commit
git log --oneline
git checkout <previous-commit> -- terraform/

# Apply previous state
terraform plan -var-file=environments/dev.tfvars
terraform apply
```

---

## Monitoring

### CloudWatch Dashboards

| Dashboard | URL |
|-----------|-----|
| DEV | https://eu-west-1.console.aws.amazon.com/cloudwatch/home?region=eu-west-1#dashboards:name=campaigns-lambda-dev |

### Key Metrics

| Metric | Threshold | Action |
|--------|-----------|--------|
| Lambda Errors | > 5% | Investigate immediately |
| API Latency p95 | > 500ms | Check Lambda cold starts |
| DynamoDB Throttling | Any | Check capacity |

### Alarms

```bash
# List alarms
aws cloudwatch describe-alarms \
  --alarm-name-prefix "campaigns-lambda-dev" \
  --region eu-west-1
```

---

## Troubleshooting

### Lambda Not Responding

1. Check CloudWatch Logs:
   ```bash
   aws logs tail /aws/lambda/bbws-campaigns-list-campaigns-dev --follow
   ```

2. Check Lambda configuration:
   ```bash
   aws lambda get-function --function-name bbws-campaigns-list-campaigns-dev
   ```

3. Check IAM permissions:
   ```bash
   aws lambda get-policy --function-name bbws-campaigns-list-campaigns-dev
   ```

### DynamoDB Errors

1. Check table status:
   ```bash
   aws dynamodb describe-table --table-name campaigns-dev
   ```

2. Check item count:
   ```bash
   aws dynamodb scan --table-name campaigns-dev --select COUNT
   ```

### API Gateway Errors

1. Check API Gateway logs:
   ```bash
   aws logs tail /aws/apigateway/bbws-campaigns-api-dev --follow
   ```

2. Test endpoint directly:
   ```bash
   curl -v https://api-id.execute-api.eu-west-1.amazonaws.com/v1/v1.0/campaigns
   ```

---

## Environment Promotion

### DEV to SIT

1. Ensure all tests pass in DEV
2. Run GitHub Actions promotion workflow
3. Select: source=dev, target=sit
4. Type "PROMOTE" to confirm
5. Verify SIT deployment

### SIT to PROD

1. Ensure all tests pass in SIT
2. Get approval from Tech Lead
3. Run GitHub Actions promotion workflow
4. Select: source=sit, target=prod
5. Type "PROMOTE" to confirm
6. Verify PROD deployment
7. Monitor metrics for 30 minutes

---

## Contacts

| Role | Name | Contact |
|------|------|---------|
| Tech Lead | TBD | platform@kimmyai.io |
| DevOps | TBD | devops@kimmyai.io |
| On-Call | TBD | oncall@kimmyai.io |

---

## Change Log

| Date | Version | Changes |
|------|---------|---------|
| 2026-01-15 | 1.0 | Initial version |
```

---

## Success Criteria

- [ ] Runbook covers all deployment methods
- [ ] Rollback procedures documented
- [ ] Monitoring section complete
- [ ] Troubleshooting guide included
- [ ] Environment promotion documented
- [ ] Contacts listed

---

## Execution Steps

1. Create docs/ directory
2. Create deployment-runbook.md
3. Document all procedures
4. Include troubleshooting
5. Add monitoring info
6. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
