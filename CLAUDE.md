# 4_bbws_webdev_workspace - Web Development Team Workspace

## Project Purpose

This repository contains the deployment package and workspace configuration for the BBWS Web Development Team. It provides tools, scripts, and infrastructure configurations for the sandbox environment (AWS Account: 417589271098).

## Environment

| Setting | Value |
|---------|-------|
| AWS Account | 417589271098 |
| Region | eu-west-1 |
| Profile | sandbox |
| VPC CIDR | 10.1.0.0/16 |

## Directory Structure

```
4_bbws_webdev_workspace/
├── CLAUDE.md                    # This file
├── terraform/
│   └── environments/
│       └── sandbox/
│           ├── backend-sandbox.hcl   # Terraform backend config
│           └── sandbox.tfvars        # Environment variables
├── iam-policies/                # IAM policy JSON files
│   ├── WebDevS3Policy.json
│   ├── WebDevCloudFrontPolicy.json
│   ├── WebDevECSPolicy.json
│   ├── WebDevECRPolicy.json
│   ├── WebDevLogsPolicy.json
│   ├── WebDevSecretsPolicy.json
│   └── WebDevInfraPolicy.json
├── scripts/
│   ├── bootstrap-sandbox.sh     # Bootstrap AWS resources
│   └── setup-webdev-env.sh      # Team member setup script
├── docs/
│   └── ONBOARDING.md            # Team onboarding guide
└── .claude/                     # TBT workflow files
    ├── logs/
    ├── plans/
    ├── snapshots/
    └── staging/
```

## Quick Start

### For Admins (One-time Setup)
```bash
# 1. Bootstrap AWS resources
./scripts/bootstrap-sandbox.sh

# 2. Deploy infrastructure (in 2_bbws_ecs_terraform)
cd ../2_bbws_ecs_terraform/terraform
terraform init -backend-config="../4_bbws_webdev_workspace/terraform/environments/sandbox/backend-sandbox.hcl"
terraform apply -var-file="../4_bbws_webdev_workspace/terraform/environments/sandbox/sandbox.tfvars"
```

### For Team Members
```bash
# Run the setup script
./scripts/setup-webdev-env.sh

# Login to AWS
aws sso login --profile sandbox
```

## Related Repositories

- `2_bbws_ecs_terraform` - Infrastructure as Code (add sandbox env here)
- `2_bbws_ecs_operations` - Operations runbooks
- `0_utilities` - Website extractor and shared tools

## Contact

- Alert Email: development@bigbeard.co.za
- GitHub Team: webdev-team

## Root Workflow Inheritance

This project inherits TBT mechanism and all workflow standards from the parent CLAUDE.md:

{{include:../CLAUDE.md}}
