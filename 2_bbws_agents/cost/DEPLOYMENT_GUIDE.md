# Automated Cost Reporting - Deployment Guide

Step-by-step deployment guide for the BBWS Automated Cost Reporting system.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Deployment Steps](#deployment-steps)
3. [Verification](#verification)
4. [Configuration](#configuration)
5. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools

- [x] AWS CLI >= 2.0
- [x] Terraform >= 1.0
- [x] Python >= 3.11
- [x] Git

### Required Access

- [x] AWS IAM permissions to create:
  - Lambda functions
  - SNS topics
  - EventBridge rules
  - IAM roles and policies
  - CloudWatch Log Groups
- [x] Cost Explorer enabled in all accounts
- [x] Email addresses for report recipients

### Verify Prerequisites

```bash
# Check AWS CLI
aws --version
# Expected: aws-cli/2.x.x

# Check Terraform
terraform --version
# Expected: Terraform v1.x.x

# Check Python
python3 --version
# Expected: Python 3.11 or higher

# Verify AWS authentication
aws sts get-caller-identity
# Should return your account details
```

## Deployment Steps

### Step 1: Clone/Navigate to Project

```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_agents/cost
```

### Step 2: Configure AWS Profile

```bash
# Set the appropriate AWS profile for deployment
export AWS_PROFILE=Tebogo-dev  # Or Tebogo-sit, Tebogo-prod

# Verify you're in the correct account
aws sts get-caller-identity
```

### Step 3: Create Terraform Configuration

```bash
cd terraform

# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit configuration
nano terraform.tfvars  # or use your preferred editor
```

Update the following values:

```hcl
environment = "dev"  # Change to sit or prod as needed

aws_region = "af-south-1"

notification_emails = [
  "your-email@example.com",      # Replace with actual emails
  "finance@example.com",
  "devops@example.com"
]

enable_daily_report  = true
enable_weekly_report = true

log_retention_days = 7
```

### Step 4: Initialize Terraform

```bash
# Initialize Terraform and download providers
terraform init

# Expected output:
# Terraform has been successfully initialized!
```

### Step 5: Review Deployment Plan

```bash
# Generate and review the execution plan
terraform plan

# Review the resources that will be created:
# - aws_lambda_function.cost_reporter
# - aws_sns_topic.cost_report
# - aws_cloudwatch_event_rule.daily_cost_report
# - aws_cloudwatch_event_rule.weekly_cost_report
# - aws_iam_role.cost_reporter
# - aws_cloudwatch_log_group.cost_reporter
# - And more...
```

### Step 6: Deploy Infrastructure

```bash
# Apply the Terraform configuration
terraform apply

# Type 'yes' when prompted
```

**Expected output:**
```
Apply complete! Resources: 12 added, 0 changed, 0 destroyed.

Outputs:

cloudwatch_log_group = "/aws/lambda/bbws-cost-reporter-dev"
daily_schedule_rule = "bbws-daily-cost-report-dev"
lambda_function_arn = "arn:aws:lambda:af-south-1:536580886816:function:bbws-cost-reporter-dev"
lambda_function_name = "bbws-cost-reporter-dev"
sns_topic_arn = "arn:aws:sns:af-south-1:536580886816:bbws-cost-report-dev"
sns_topic_name = "bbws-cost-report-dev"
subscription_confirmation_note = "Check your email and confirm the SNS subscription to start receiving cost reports"
weekly_schedule_rule = "bbws-weekly-cost-report-dev"
```

### Step 7: Confirm Email Subscriptions

1. **Check your email** - Each recipient will receive a subscription confirmation email
2. **Subject**: "AWS Notification - Subscription Confirmation"
3. **Click** the "Confirm subscription" link
4. **Repeat** for all configured email addresses

**Verification:**
```bash
# List all subscriptions
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw sns_topic_arn)

# Status should show "Confirmed" for each subscription
```

## Verification

### Test Daily Report

```bash
# Manually trigger a daily report
aws lambda invoke \
  --function-name $(terraform output -raw lambda_function_name) \
  --payload '{"report_type": "daily"}' \
  --cli-binary-format raw-in-base64-out \
  response.json

# Check response
cat response.json
# Expected: {"statusCode": 200, "body": "{\"message\": \"Cost report generated successfully\", ...}"}
```

### Test Weekly Report

```bash
# Manually trigger a weekly report
aws lambda invoke \
  --function-name $(terraform output -raw lambda_function_name) \
  --payload '{"report_type": "weekly"}' \
  --cli-binary-format raw-in-base64-out \
  response.json

# Check response
cat response.json
```

### Verify Email Delivery

1. Check your inbox for the test report
2. Verify HTML formatting is correct
3. Confirm all environment data is displayed

### Check Lambda Logs

```bash
# View recent logs
aws logs tail $(terraform output -raw cloudwatch_log_group) --since 5m --follow
```

Expected log output:
```
2025-12-21 14:00:00 START RequestId: xxx Version: $LATEST
2025-12-21 14:00:01 Generating daily cost report for 2025-12-20 to 2025-12-21
2025-12-21 14:00:02 Report sent to SNS topic: arn:aws:sns:...
2025-12-21 14:00:02 END RequestId: xxx
2025-12-21 14:00:02 REPORT RequestId: xxx Duration: 2500.00 ms
```

### Verify EventBridge Rules

```bash
# Check daily schedule
aws events describe-rule \
  --name $(terraform output -raw daily_schedule_rule)

# Check weekly schedule
aws events describe-rule \
  --name $(terraform output -raw weekly_schedule_rule)
```

## Configuration

### Customize Report Schedule

Edit `terraform/main.tf`:

```hcl
# Daily report - change from 7 AM to 6 AM UTC
resource "aws_cloudwatch_event_rule" "daily_cost_report" {
  schedule_expression = "cron(0 6 * * ? *)"  # Changed from 7 to 6
}

# Weekly report - change to Fridays
resource "aws_cloudwatch_event_rule" "weekly_cost_report" {
  schedule_expression = "cron(0 8 ? * FRI *)"  # Changed from MON to FRI
}
```

Apply changes:
```bash
terraform apply
```

### Add/Remove Email Recipients

Edit `terraform.tfvars`:

```hcl
notification_emails = [
  "new-email@example.com",
  "existing-email@example.com"
]
```

Apply changes:
```bash
terraform apply
```

**Important**: New subscribers must confirm their subscription via email.

### Change Environment

Deploy to different environment:

```bash
# Edit terraform.tfvars
environment = "sit"  # or "prod"

# Apply
terraform apply
```

## Multi-Environment Deployment

To deploy to all three environments:

### Option 1: Workspaces

```bash
# Create workspaces
terraform workspace new dev
terraform workspace new sit
terraform workspace new prod

# Deploy to DEV
terraform workspace select dev
export AWS_PROFILE=Tebogo-dev
terraform apply

# Deploy to SIT
terraform workspace select sit
export AWS_PROFILE=Tebogo-sit
terraform apply

# Deploy to PROD
terraform workspace select prod
export AWS_PROFILE=Tebogo-prod
terraform apply
```

### Option 2: Separate Directories

```bash
# Create separate state for each environment
mkdir -p environments/dev environments/sit environments/prod

# Copy configurations
cp terraform/*.tf environments/dev/
cp terraform/*.tf environments/sit/
cp terraform/*.tf environments/prod/

# Deploy DEV
cd environments/dev
export AWS_PROFILE=Tebogo-dev
terraform init
terraform apply

# Deploy SIT
cd ../sit
export AWS_PROFILE=Tebogo-sit
terraform init
terraform apply

# Deploy PROD
cd ../prod
export AWS_PROFILE=Tebogo-prod
terraform init
terraform apply
```

## Troubleshooting

### Issue: Terraform Init Fails

**Error**: "Failed to initialize providers"

**Solution**:
```bash
# Clear Terraform cache
rm -rf .terraform .terraform.lock.hcl

# Re-initialize
terraform init
```

### Issue: Lambda Deployment Package Too Large

**Error**: "Deployment package exceeds the maximum size"

**Solution**:
The current package should be small (~50KB). If this occurs:
```bash
# Check package size
ls -lh terraform/lambda_cost_reporter.zip

# If > 50MB, check for accidental inclusions
```

### Issue: Permission Denied Errors

**Error**: "User is not authorized to perform: lambda:CreateFunction"

**Solution**:
```bash
# Verify IAM permissions
aws iam get-user

# Check attached policies
aws iam list-attached-user-policies --user-name YOUR_USERNAME

# Ensure you have AdministratorAccess or equivalent permissions
```

### Issue: Cost Explorer Not Available

**Error**: "Cost Explorer is not enabled for this account"

**Solution**:
1. Log into AWS Console
2. Navigate to AWS Cost Explorer
3. Click "Enable Cost Explorer"
4. Wait 24 hours for data to populate

### Issue: SNS Subscription Not Confirming

**Problem**: Email not received or link expired

**Solution**:
```bash
# Delete existing subscription
aws sns unsubscribe --subscription-arn <subscription-arn>

# Re-run terraform apply to recreate subscription
terraform apply

# Or manually add subscription
aws sns subscribe \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --protocol email \
  --notification-endpoint your-email@example.com
```

### Issue: Lambda Timeout

**Error**: "Task timed out after 300.00 seconds"

**Solution**:
Edit `terraform/main.tf`:
```hcl
resource "aws_lambda_function" "cost_reporter" {
  timeout = 600  # Increase from 300 to 600 seconds
}
```

Apply:
```bash
terraform apply
```

### Issue: No Cost Data in Report

**Problem**: Report shows $0.00 for all environments

**Solutions**:
1. **Wait for data**: AWS Cost Explorer data has 24-hour delay
2. **Check date range**: Ensure you're querying dates with actual usage
3. **Verify permissions**: Lambda needs `ce:GetCostAndUsage` permission
4. **Test manually**:
   ```bash
   aws ce get-cost-and-usage \
     --time-period Start=2025-12-20,End=2025-12-21 \
     --granularity DAILY \
     --metrics UnblendedCost \
     --profile Tebogo-dev
   ```

## Rollback

If you need to rollback the deployment:

```bash
# Destroy all resources
terraform destroy

# Type 'yes' when prompted
```

**Warning**: This will:
- Delete the Lambda function
- Delete the SNS topic (and all subscriptions)
- Delete EventBridge rules
- Delete CloudWatch Log Groups (and all logs)

## Next Steps

After successful deployment:

1. ✅ Confirm all email subscriptions
2. ✅ Test both daily and weekly reports
3. ✅ Verify report content is accurate
4. ✅ Set up CloudWatch dashboards (optional)
5. ✅ Document custom configurations
6. ✅ Deploy to remaining environments (SIT, PROD)

## Support

For assistance:
- Review logs: `aws logs tail /aws/lambda/bbws-cost-reporter-dev --follow`
- Check AWS Console: Lambda → Functions → bbws-cost-reporter-dev
- Contact: DevOps Team

---

**Last Updated**: 2025-12-21
**Version**: 1.0.0
