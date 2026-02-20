# SIT Environment Setup Commands

This document contains all AWS CLI commands needed to set up the SIT environment infrastructure.

## Prerequisites

- AWS CLI installed and configured
- AWS SSO authentication configured for all three accounts
- jq installed for JSON processing
- GitHub CLI (gh) installed for GitHub configuration

## Step 1: Create Terraform Backend Resources

**Estimated Time:** 15 minutes
**AWS Profile:** Tebogo-sit
**AWS Account:** 815856636111
**Region:** af-south-1

### 1.1 Set Environment Variables

```bash
export AWS_PROFILE=Tebogo-sit
export AWS_REGION=af-south-1
export ENVIRONMENT=sit
```

### 1.2 Verify AWS Connection

```bash
# Verify you're connected to the correct account
aws sts get-caller-identity

# Expected output should show Account: 815856636111
```

### 1.3 Create S3 Backend Bucket

```bash
# Create bucket
aws s3 mb s3://bbws-terraform-state-sit --region af-south-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket bbws-terraform-state-sit \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket bbws-terraform-state-sit \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      },
      "BucketKeyEnabled": false
    }]
  }'

# Block all public access
aws s3api put-public-access-block \
  --bucket bbws-terraform-state-sit \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Add bucket policy (optional - for additional security)
aws s3api put-bucket-policy \
  --bucket bbws-terraform-state-sit \
  --policy '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::bbws-terraform-state-sit",
        "arn:aws:s3:::bbws-terraform-state-sit/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }]
  }'
```

### 1.4 Create DynamoDB Lock Table

```bash
# Create table
aws dynamodb create-table \
  --table-name bbws-terraform-locks-sit \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region af-south-1 \
  --tags Key=Environment,Value=sit Key=Purpose,Value=TerraformStateLocking

# Wait for table to be active
aws dynamodb wait table-exists --table-name bbws-terraform-locks-sit --region af-south-1

# Enable point-in-time recovery
aws dynamodb update-continuous-backups \
  --table-name bbws-terraform-locks-sit \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true \
  --region af-south-1
```

### 1.5 Verify Backend Resources

```bash
# Verify S3 bucket
aws s3 ls s3://bbws-terraform-state-sit
echo "✅ S3 bucket exists"

# Verify DynamoDB table
aws dynamodb describe-table \
  --table-name bbws-terraform-locks-sit \
  --region af-south-1 \
  --query 'Table.TableStatus' \
  --output text

# Should output: ACTIVE
echo "✅ DynamoDB table is active"
```

---

## Step 2: Configure AWS OIDC for GitHub Actions

**Estimated Time:** 15 minutes
**AWS Profile:** Tebogo-sit
**Purpose:** Allow GitHub Actions to deploy infrastructure without long-lived credentials

### 2.1 Create OIDC Provider

```bash
# Create OIDC provider for GitHub Actions
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --tags Key=Purpose,Value=GitHubActionsOIDC

# Verify OIDC provider created
aws iam list-open-id-connect-providers
```

### 2.2 Create IAM Role for GitHub Actions

**Note:** Replace `OWNER/2_bbws_ecs_terraform` with your actual GitHub repository

```bash
# Create trust policy file
cat > /tmp/github-actions-trust-policy.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::815856636111:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:OWNER/2_bbws_ecs_terraform:*"
      }
    }
  }]
}
EOF

# Create IAM role
aws iam create-role \
  --role-name GitHubActionsRole \
  --assume-role-policy-document file:///tmp/github-actions-trust-policy.json \
  --description "Role for GitHub Actions to deploy SIT infrastructure" \
  --tags Key=Environment,Value=sit Key=ManagedBy,Value=Manual
```

### 2.3 Attach Permissions to IAM Role

**Option 1: Administrator Access (Quick setup, use for initial deployment)**

```bash
aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

**Option 2: Least Privilege Policy (Recommended for production)**

```bash
# Create custom policy with only required permissions
cat > /tmp/github-actions-policy.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "ecs:*",
        "rds:*",
        "elasticloadbalancing:*",
        "efs:*",
        "cloudfront:*",
        "route53:*",
        "acm:*",
        "ecr:*",
        "logs:*",
        "cloudwatch:*",
        "sns:*",
        "dynamodb:*",
        "secretsmanager:*",
        "kms:*",
        "iam:GetRole",
        "iam:PassRole",
        "iam:CreateRole",
        "iam:AttachRolePolicy",
        "iam:PutRolePolicy",
        "s3:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name GitHubActionsTerraformPolicy \
  --policy-document file:///tmp/github-actions-policy.json

aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::815856636111:policy/GitHubActionsTerraformPolicy
```

### 2.4 Verify IAM Role

```bash
# Get role ARN
aws iam get-role \
  --role-name GitHubActionsRole \
  --query 'Role.Arn' \
  --output text

# Should output: arn:aws:iam::815856636111:role/GitHubActionsRole
```

---

## Step 3: Configure GitHub Repository

**Prerequisites:** GitHub CLI (gh) installed and authenticated

### 3.1 Create GitHub Environment for SIT

```bash
# Create 'sit' environment with protection rules
gh api repos/OWNER/2_bbws_ecs_terraform/environments/sit -X PUT \
  --field deployment_branch_policy='{"protected_branches": true, "custom_branch_policies": false}'

echo "✅ GitHub environment 'sit' created"
```

### 3.2 Add Environment Secrets

```bash
# Set AWS role ARN secret
gh secret set AWS_ROLE_ARN_SIT \
  --env sit \
  --body "arn:aws:iam::815856636111:role/GitHubActionsRole"

# Set alert email secret
gh secret set ALERT_EMAIL \
  --env sit \
  --body "devops@bbws.com"

echo "✅ GitHub secrets configured"
```

### 3.3 Add Required Reviewers (Dev Lead Approval)

```bash
# Add required reviewers for deployment approval
# Replace 'dev-lead-username' with actual GitHub username
gh api repos/OWNER/2_bbws_ecs_terraform/environments/sit/deployment-protection-rules -X POST \
  --field type='required_reviewers' \
  --field reviewers='["dev-lead-username"]'

echo "✅ Deployment approval gate configured"
```

### 3.4 Create 'destroy-sit' Environment (2 Approvals Required)

```bash
# Create destroy environment with stricter protection
gh api repos/OWNER/2_bbws_ecs_terraform/environments/destroy-sit -X PUT \
  --field deployment_branch_policy='{"protected_branches": true, "custom_branch_policies": false}'

# Add 2 required reviewers for destroy operations
gh api repos/OWNER/2_bbws_ecs_terraform/environments/destroy-sit/deployment-protection-rules -X POST \
  --field type='required_reviewers' \
  --field reviewers='["dev-lead-username", "tech-lead-username"]'

echo "✅ Destroy environment configured with 2-approval requirement"
```

---

## Step 4: Deploy SIT Infrastructure via GitHub Actions

**Estimated Time:** 45-60 minutes
**Method:** GitHub Actions workflow

### 4.1 Commit Terraform Files

```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform

# Add all new files
git add terraform/environments/sit/
git add terraform/rds_dr.tf
git add terraform/dynamodb.tf
git add terraform/cloudwatch.tf
git add .github/workflows/deploy-sit.yml

# Commit changes
git commit -m "feat: Add SIT environment with cross-region DR

- Add SIT environment configuration (account 815856636111)
- Implement RDS automated backup replication to eu-west-1
- Add DynamoDB state tracking tables with global replication
- Configure CloudWatch monitoring and alerting
- Add GitHub Actions pipeline with approval gates

Infrastructure includes:
- VPC (10.1.0.0/16) with public/private subnets
- RDS MySQL db.t3.micro with 7-day backups
- ECS Fargate cluster (512 CPU, 1GB RAM)
- Application Load Balancer
- EFS filesystem
- CloudWatch alarms and SNS notifications
- Cross-region DR to eu-west-1"

# Push to main branch
git push origin main
```

### 4.2 Trigger GitHub Actions Workflow

```bash
# Trigger terraform plan
gh workflow run deploy-sit.yml --field action=plan

# Wait for workflow to complete
gh run watch

# Review plan output in GitHub Actions UI
# https://github.com/OWNER/2_bbws_ecs_terraform/actions
```

### 4.3 Apply Infrastructure (Requires Dev Lead Approval)

```bash
# Trigger terraform apply
gh workflow run deploy-sit.yml --field action=apply

# This will wait for Dev Lead approval in GitHub UI
# After approval, infrastructure will be deployed
```

### 4.4 Monitor Deployment

```bash
# Watch deployment progress
gh run watch

# Check deployment status
gh run list --workflow=deploy-sit.yml --limit 1
```

---

## Step 5: Validate Infrastructure Deployment

### 5.1 Run Health Check Script

```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_agents

# Run comprehensive health check
bash utils/health_check_sit.sh
```

### 5.2 Manual Validation Commands

```bash
export AWS_PROFILE=Tebogo-sit
export AWS_REGION=af-south-1

# Check RDS
aws rds describe-db-instances \
  --db-instance-identifier sit-mysql \
  --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address]' \
  --output table

# Check ECS Cluster
aws ecs describe-clusters \
  --clusters sit-cluster \
  --query 'clusters[0].[status,runningTasksCount,activeServicesCount]' \
  --output table

# Check ALB
aws elbv2 describe-load-balancers \
  --names sit-alb \
  --query 'LoadBalancers[0].[State.Code,DNSName]' \
  --output table

# Check DynamoDB Tables
aws dynamodb list-tables \
  --query 'TableNames[?starts_with(@, `sit-`)]' \
  --output table
```

---

## Step 6: Subscribe to CloudWatch Alerts

```bash
# Get SNS topic ARN
SNS_TOPIC_ARN=$(aws sns list-topics \
  --region af-south-1 \
  --profile Tebogo-sit \
  --query 'Topics[?contains(TopicArn, `sit-bbws-alerts`)].TopicArn' \
  --output text)

echo "SNS Topic ARN: $SNS_TOPIC_ARN"

# Subscribe email address to SNS topic
aws sns subscribe \
  --topic-arn $SNS_TOPIC_ARN \
  --protocol email \
  --notification-endpoint devops@bbws.com \
  --region af-south-1 \
  --profile Tebogo-sit

# Check your email and confirm subscription
echo "✅ Subscription request sent. Check email to confirm."
```

---

## Step 7: Get Infrastructure Outputs

```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform/terraform

# Initialize terraform
terraform init -backend-config=environments/sit/backend-sit.hcl

# Select SIT workspace
terraform workspace select sit

# Get all outputs
terraform output

# Get specific outputs
ALB_DNS=$(terraform output -raw alb_dns_name)
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
VPC_ID=$(terraform output -raw vpc_id)

echo "ALB DNS: $ALB_DNS"
echo "RDS Endpoint: $RDS_ENDPOINT"
echo "VPC ID: $VPC_ID"
```

---

## Troubleshooting

### Backend Resources Not Found

```bash
# Verify S3 bucket exists
aws s3 ls s3://bbws-terraform-state-sit

# If not found, recreate:
aws s3 mb s3://bbws-terraform-state-sit --region af-south-1

# Verify DynamoDB table
aws dynamodb describe-table --table-name bbws-terraform-locks-sit
```

### GitHub Actions Workflow Fails

```bash
# Check workflow logs
gh run view --log

# Verify AWS OIDC trust policy
aws iam get-role --role-name GitHubActionsRole \
  --query 'Role.AssumeRolePolicyDocument' \
  --output json | jq
```

### Terraform State Locked

```bash
# List items in DynamoDB lock table
aws dynamodb scan --table-name bbws-terraform-locks-sit

# Force unlock (use with caution!)
terraform force-unlock LOCK_ID
```

---

## Cleanup / Destroy

### Destroy SIT Infrastructure

```bash
# Via GitHub Actions (requires 2 approvals)
gh workflow run deploy-sit.yml --field action=destroy

# Or via Terraform CLI (not recommended, use GitHub Actions for audit trail)
cd terraform
terraform init -backend-config=environments/sit/backend-sit.hcl
terraform workspace select sit
terraform destroy -var-file=environments/sit/sit.tfvars
```

### Delete Backend Resources (Only if starting completely fresh)

```bash
# WARNING: This deletes state and lock resources

# Delete S3 bucket (removes all versions)
aws s3 rm s3://bbws-terraform-state-sit --recursive
aws s3 rb s3://bbws-terraform-state-sit

# Delete DynamoDB table
aws dynamodb delete-table --table-name bbws-terraform-locks-sit

# Delete OIDC provider
OIDC_ARN=$(aws iam list-open-id-connect-providers \
  --query 'OpenIDConnectProviderList[?contains(Arn, `token.actions.githubusercontent.com`)].Arn' \
  --output text)
aws iam delete-open-id-connect-provider --open-id-connect-provider-arn $OIDC_ARN

# Delete IAM role
aws iam detach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
aws iam delete-role --role-name GitHubActionsRole
```

---

## Next Steps

After successful infrastructure deployment:

1. **Export Tenants from DEV**
   ```bash
   cd /Users/tebogotseka/Documents/agentic_work/2_bbws_tenant_provisioner
   python src/provisioner/export_tenant.py --env dev --tenant-id tenant-1 --output-dir /tmp/tenant-exports
   python src/provisioner/export_tenant.py --env dev --tenant-id tenant-2 --output-dir /tmp/tenant-exports
   ```

2. **Import Tenants to SIT**
   ```bash
   python src/provisioner/import_tenant.py --env sit --manifest /tmp/tenant-exports/tenant-1_manifest.json --priority 20
   python src/provisioner/import_tenant.py --env sit --manifest /tmp/tenant-exports/tenant-2_manifest.json --priority 21
   ```

3. **Configure DNS Records**
   ```bash
   # Get ALB DNS name and create Route 53 records
   # See plan document for DNS configuration commands
   ```

4. **Run Integration Tests**

5. **Perform DR Failover Test**

---

## Reference

- **Plan Document:** `/Users/tebogotseka/.claude/plans/quiet-toasting-owl.md`
- **Terraform Code:** `/Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform/terraform/`
- **Provisioner Scripts:** `/Users/tebogotseka/Documents/agentic_work/2_bbws_tenant_provisioner/src/provisioner/`
- **Health Check:** `/Users/tebogotseka/Documents/agentic_work/2_bbws_agents/utils/health_check_sit.sh`
