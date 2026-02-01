# BBWS Web Development Team - Onboarding Guide

Welcome to the BBWS Web Development Team! This guide will help you set up your environment and get started with the sandbox environment.

## Environment Overview

| Setting | Value |
|---------|-------|
| AWS Account | 417589271098 |
| Region | eu-west-1 |
| Profile | sandbox |
| VPC CIDR | 10.1.0.0/16 |
| Alert Email | development@bigbeard.co.za |

## Quick Start

### Option 1: Automated Setup (Recommended)

Run the setup script to automatically install and configure everything:

```bash
cd 4_bbws_webdev_workspace
./scripts/setup-webdev-env.sh
```

### Option 2: Manual Setup

Follow the steps below to manually set up your environment.

---

## Step 1: Install Required Tools

### AWS CLI v2

```bash
# macOS
brew install awscli

# Verify installation
aws --version
```

### Terraform

```bash
# macOS
brew install terraform

# Verify installation
terraform version
```

### GitHub CLI

```bash
# macOS
brew install gh

# Verify installation
gh --version
```

### Docker Desktop

Download and install from: https://www.docker.com/products/docker-desktop

### Claude Code (Optional)

```bash
npm install -g @anthropic-ai/claude-code
# OR
brew install claude-code
```

---

## Step 2: Configure AWS SSO Profile

Add the following to your `~/.aws/config` file:

```ini
[sso-session Sithembiso]
sso_start_url = https://d-9367a8daf2.awsapps.com/start/#
sso_region = eu-west-1
sso_registration_scopes = sso:account:access

[profile sandbox]
sso_session = Sithembiso
sso_account_id = 417589271098
sso_role_name = AWSAdministratorAccess
region = eu-west-1
output = json
```

### Login to AWS SSO

```bash
aws sso login --profile sandbox
```

### Verify Access

```bash
aws sts get-caller-identity --profile sandbox
```

Expected output:
```json
{
    "UserId": "AROAXXXXXXXXX:your-name",
    "Account": "417589271098",
    "Arn": "arn:aws:sts::417589271098:assumed-role/AWSAdministratorAccess/your-name"
}
```

---

## Step 3: Configure GitHub Access

### Authenticate with GitHub

```bash
gh auth login
```

Follow the prompts to authenticate with your GitHub account.

### Clone Required Repositories

```bash
# Clone the repositories you need
gh repo clone BigBeardWebSolutions/0_utilities
gh repo clone BigBeardWebSolutions/2_bbws_ecs_terraform
gh repo clone BigBeardWebSolutions/2_bbws_ecs_operations
gh repo clone BigBeardWebSolutions/2_bbws_wordpress_container
gh repo clone BigBeardWebSolutions/4_bbws_webdev_workspace
```

---

## Step 4: Install VSCode Extensions

Install the following extensions:

| Extension | ID |
|-----------|-----|
| AWS Toolkit | `amazonwebservices.aws-toolkit-vscode` |
| HashiCorp Terraform | `hashicorp.terraform` |
| Python | `ms-python.python` |
| Docker | `ms-azuretools.vscode-docker` |
| GitLens | `eamodio.gitlens` |
| YAML | `redhat.vscode-yaml` |

Or install via command line:

```bash
code --install-extension amazonwebservices.aws-toolkit-vscode
code --install-extension hashicorp.terraform
code --install-extension ms-python.python
code --install-extension ms-azuretools.vscode-docker
code --install-extension eamodio.gitlens
code --install-extension redhat.vscode-yaml
```

---

## Common Tasks

### Website Extractor - Upload Site to S3

```bash
export AWS_PROFILE=sandbox

# Upload extracted site
aws s3 sync ./extracted_site/ s3://bigbeard-migrated-site-sandbox/site-name/ --delete

# List bucket contents
aws s3 ls s3://bigbeard-migrated-site-sandbox/

# Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id EXXXXXXXXXXXX --paths "/*"
```

### ECS Operations

```bash
export AWS_PROFILE=sandbox

# List ECS clusters
aws ecs list-clusters

# Describe a service
aws ecs describe-services --cluster sandbox-cluster --services tenant-1

# Force new deployment
aws ecs update-service --cluster sandbox-cluster --service tenant-1 --force-new-deployment

# View running tasks
aws ecs list-tasks --cluster sandbox-cluster

# View logs
aws logs tail /aws/ecs/sandbox --follow
```

### ECR - Docker Image Operations

```bash
export AWS_PROFILE=sandbox

# Login to ECR
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 417589271098.dkr.ecr.eu-west-1.amazonaws.com

# List repositories
aws ecr describe-repositories

# Push an image
docker tag my-image:latest 417589271098.dkr.ecr.eu-west-1.amazonaws.com/my-repo:latest
docker push 417589271098.dkr.ecr.eu-west-1.amazonaws.com/my-repo:latest
```

### Terraform Operations

```bash
export AWS_PROFILE=sandbox
cd 2_bbws_ecs_terraform/terraform

# Initialize
terraform init \
  -backend-config="../../4_bbws_webdev_workspace/terraform/environments/sandbox/backend-sandbox.hcl" \
  -backend-config="key=infrastructure/terraform.tfstate"

# Plan
terraform plan -var-file="../../4_bbws_webdev_workspace/terraform/environments/sandbox/sandbox.tfvars"

# Apply
terraform apply -var-file="../../4_bbws_webdev_workspace/terraform/environments/sandbox/sandbox.tfvars"
```

---

## Environment Variables

Add these to your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
# Default AWS profile
export AWS_PROFILE=sandbox
export AWS_REGION=eu-west-1

# Useful aliases
alias awswho='aws sts get-caller-identity'
alias ecr-login='aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 417589271098.dkr.ecr.eu-west-1.amazonaws.com'
```

---

## Troubleshooting

### AWS SSO Token Expired

If you see "Token has expired", re-authenticate:

```bash
aws sso login --profile sandbox
```

### Permission Denied

Verify you're using the correct profile:

```bash
aws sts get-caller-identity --profile sandbox
```

### Terraform State Lock

If Terraform is locked, you may need to force-unlock:

```bash
terraform force-unlock <LOCK_ID>
```

### Docker Login Failed

Ensure you're logged into AWS SSO first:

```bash
aws sso login --profile sandbox
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 417589271098.dkr.ecr.eu-west-1.amazonaws.com
```

---

## Support

- **Email**: development@bigbeard.co.za
- **GitHub Team**: webdev-team
- **Slack**: #webdev-team (if applicable)

---

## Quick Reference Card

| Task | Command |
|------|---------|
| AWS Login | `aws sso login --profile sandbox` |
| Check Identity | `aws sts get-caller-identity --profile sandbox` |
| List S3 Buckets | `aws s3 ls --profile sandbox` |
| List ECS Clusters | `aws ecs list-clusters --profile sandbox` |
| ECR Login | `aws ecr get-login-password --region eu-west-1 \| docker login --username AWS --password-stdin 417589271098.dkr.ecr.eu-west-1.amazonaws.com` |
| CloudFront Invalidation | `aws cloudfront create-invalidation --distribution-id DIST_ID --paths "/*"` |
| View Logs | `aws logs tail /aws/ecs/sandbox --follow` |
