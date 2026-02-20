# Database Module

Terraform module for creating tenant-specific MySQL databases and users in a shared RDS instance.

## Features

- **Python Script Integration**: Calls existing `init_tenant_db.py` script via Terraform
- **Idempotent Operations**: Safe to run multiple times (CREATE IF NOT EXISTS)
- **Secrets Manager Integration**: Reads credentials from tenant secret
- **Optional Verification**: Can verify database creation after provisioning
- **Multi-Account Support**: Uses AWS profiles for different environments

## How It Works

1. Reads tenant database credentials from Secrets Manager (created by ecs-tenant module)
2. Executes Python script to create database and user in shared RDS instance
3. Optionally verifies the database was created successfully

## Resources Created

This module uses **null_resource** with **local-exec** provisioners to execute Python scripts. It does not create AWS resources directly.

**Database Operations** (via Python script):
- MySQL Database: `{tenant_name}_db`
- MySQL User: `{tenant_name}_user`
- Grants: `ALL PRIVILEGES ON {tenant_name}_db.* TO '{tenant_name}_user'@'%'`

## Usage

### Basic Example

```hcl
module "goldencrust_database" {
  source = "../../modules/database"

  # Tenant Identity
  tenant_name = "goldencrust"
  environment = "sit"

  # Secrets Manager Secret (from ecs-tenant module)
  tenant_db_secret_arn = module.goldencrust_tenant.db_secret_arn

  # AWS Configuration
  aws_region  = "eu-west-1"
  aws_profile = "Tebogo-sit"

  # Optional: Custom script path
  init_db_script_path = "../../../2_bbws_agents/utils/init_tenant_db.py"

  # Optional: Disable verification
  verify_database = true
}
```

### Full Tenant Deployment (ECS + Database)

```hcl
# Phase 1: ECS Infrastructure
module "goldencrust_tenant" {
  source = "../../modules/ecs-tenant"

  tenant_name  = "goldencrust"
  environment  = "sit"
  domain_name  = "goldencrust.wpsit.kimmyai.io"
  alb_priority = 140

  # ... other required variables
}

# Phase 2: Database Creation
module "goldencrust_database" {
  source = "../../modules/database"

  tenant_name          = "goldencrust"
  environment          = "sit"
  tenant_db_secret_arn = module.goldencrust_tenant.db_secret_arn
  aws_region           = "eu-west-1"
  aws_profile          = "Tebogo-sit"

  depends_on = [
    module.goldencrust_tenant
  ]
}
```

### Without Verification

```hcl
module "sunsetbistro_database" {
  source = "../../modules/database"

  tenant_name          = "sunsetbistro"
  environment          = "sit"
  tenant_db_secret_arn = module.sunsetbistro_tenant.db_secret_arn
  aws_region           = "eu-west-1"
  aws_profile          = "Tebogo-sit"

  # Skip verification for faster deployment
  verify_database = false
}
```

## Outputs

| Name | Description |
|------|-------------|
| database_name | Name of the created database (e.g., `goldencrust_db`) |
| database_username | Database username (e.g., `goldencrust_user`) |
| database_created | Timestamp/ID when database was created |
| database_verified | Verification status (null if disabled) |
| secret_arn | Secrets Manager secret ARN (passthrough) |

## Requirements

### Prerequisites

1. **Python 3.x** - Must be available in PATH
2. **Python Script** - `init_tenant_db.py` must exist at specified path
3. **AWS CLI** - Configured with appropriate profile
4. **RDS Instance** - MySQL database instance must exist
5. **Secrets Manager Secret** - Tenant credentials must be created (via ecs-tenant module)
6. **Network Access** - Script must be able to reach RDS endpoint

### Python Dependencies

The `init_tenant_db.py` script requires:
- `boto3` - AWS SDK for Python
- `pymysql` - MySQL client library

Install via:
```bash
pip3 install boto3 pymysql
```

### IAM Permissions

The AWS profile must have:
- `secretsmanager:GetSecretValue` - Read tenant credentials
- `secretsmanager:GetSecretValue` - Read RDS master credentials (if stored in Secrets Manager)

## Script Path Configuration

The module expects the Python script at a relative path from the Terraform working directory:

```
2_bbws_ecs_terraform/terraform/tenants/goldencrust/
└── (terraform runs here)
    └── ../../../2_bbws_agents/utils/init_tenant_db.py
```

If your repository structure is different, override the path:

```hcl
module "database" {
  source = "../../modules/database"

  # ... other variables

  init_db_script_path = "/absolute/path/to/init_tenant_db.py"
}
```

## Database Script Behavior

### CREATE IF NOT EXISTS

The Python script is **idempotent** and uses:
```sql
CREATE DATABASE IF NOT EXISTS goldencrust_db;
CREATE USER IF NOT EXISTS 'goldencrust_user'@'%' IDENTIFIED BY '...';
GRANT ALL PRIVILEGES ON goldencrust_db.* TO 'goldencrust_user'@'%';
```

This means:
- ✅ Safe to run multiple times
- ✅ Won't fail if database already exists
- ✅ Updates user password if it changed
- ✅ Ensures grants are applied

### Verification Mode

When `verify_database = true`, the module runs a second script execution with `--verify-only` flag:
- Connects to database
- Checks if database exists
- Verifies user can connect
- Does **not** make any changes

## Troubleshooting

### Script Not Found
```
Error: Error running command 'python3 /path/to/init_tenant_db.py': exec: "python3": executable file not found
```

**Solution**: Ensure Python 3 is installed and in PATH:
```bash
which python3
python3 --version
```

### Database Connection Failed
```
pymysql.err.OperationalError: (2003, "Can't connect to MySQL server")
```

**Solutions**:
1. Check RDS security group allows connections from Terraform runner
2. Verify RDS endpoint in Secrets Manager is correct
3. Ensure RDS instance is running

### Secrets Manager Access Denied
```
botocore.exceptions.ClientError: An error occurred (AccessDeniedException)
```

**Solution**: Ensure AWS profile has `secretsmanager:GetSecretValue` permission:
```bash
aws secretsmanager get-secret-value \
  --secret-id sit-goldencrust-db-credentials \
  --profile Tebogo-sit
```

### Python Module Not Found
```
ModuleNotFoundError: No module named 'pymysql'
```

**Solution**: Install required dependencies:
```bash
pip3 install boto3 pymysql
```

## Module Dependencies

This module is designed to be used **after** the `ecs-tenant` module:

```
ecs-tenant (Phase 1)
    ↓ creates db_secret_arn
database (Phase 2)
    ↓ creates database
ECS Service starts (Phase 1 completion)
```

## Limitations

1. **Local Execution Only**: Uses local-exec, so must run from a machine with:
   - Network access to RDS
   - Python and dependencies installed
   - AWS credentials configured

2. **No State Tracking**: Since this uses null_resource, Terraform doesn't track the actual database state in RDS. It only tracks that the script was executed.

3. **No Rollback**: Terraform destroy **does not** drop the database. You must manually drop databases or use a separate cleanup script.

4. **CI/CD Considerations**: In GitHub Actions, ensure the runner has:
   - Python 3.x installed (ubuntu-latest includes it)
   - Dependencies installed via `pip install boto3 pymysql`
   - RDS security group allows GitHub Actions runner IPs (or use VPC runner)

## Alternative: RDS via ECS Task

For production environments, consider using an ECS task instead of local-exec:

```hcl
resource "aws_ecs_task_definition" "db_init" {
  # Run init_tenant_db.py in a container with MySQL client
  # Has access to RDS via VPC networking
}
```

This avoids local-exec limitations and runs in the same VPC as RDS.

## Inputs Reference

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| tenant_name | Tenant identifier | string | - | yes |
| environment | Environment (dev/sit/prod) | string | - | yes |
| tenant_db_secret_arn | Secrets Manager ARN | string | - | yes |
| aws_region | AWS region | string | - | yes |
| aws_profile | AWS CLI profile | string | - | yes |
| init_db_script_path | Path to Python script | string | `../../../2_bbws_agents/utils/init_tenant_db.py` | no |
| verify_database | Enable verification | bool | true | no |

## Related Documentation

- [Pipeline Design](../../../../2_bbws_agents/devops/design/TENANT_DEPLOYMENT_PIPELINE_DESIGN.md)
- [ECS Tenant Module](../ecs-tenant/README.md)
- [Python Script Documentation](../../../../2_bbws_agents/utils/README.md)

## Version

- **Terraform**: >= 1.5.0
- **AWS Provider**: ~> 5.0
- **Null Provider**: ~> 3.2
