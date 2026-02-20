# Worker 3: Naming Validation

**Worker Task**: Validate repository and AWS resource naming conventions
**Parent Stage**: Stage 1 - Repository Requirements
**LLD Reference**: 2.1.8_LLD_Order_Lambda.md

---

## Task Description

Validate that all naming conventions for the Order Lambda service follow BBWS standards. This includes the GitHub repository name, AWS resource names, code artifacts, and configuration files. Proper naming ensures consistency across the organization and prevents naming conflicts.

### Key Responsibilities

1. Validate GitHub repository naming
2. Validate AWS resource naming (Lambda, DynamoDB, SQS, S3, etc.)
3. Validate code artifact naming (classes, functions, modules)
4. Validate configuration and infrastructure file naming
5. Validate environment variable naming
6. Create naming convention reference guide
7. Identify any deviations and recommend fixes

---

## Inputs

### BBWS Naming Standards

#### Repository Naming Convention

**Pattern**: `{sequence}_{product}_{component}_{optional_suffix}`

**Examples**:
- `2_bbws_ecs_terraform` - ECS infrastructure
- `2_bbws_ecs_tests` - ECS testing
- `2_bbws_wordpress_container` - WordPress container
- `2_bbws_order_lambda` - Order Lambda service (NEW)

**Rules**:
- Use sequence number (2 = Customer Portal layer)
- All lowercase
- Underscores separate components
- No hyphens
- No dots except in file extensions
- Descriptive but concise (max 40 characters)

#### AWS Resource Naming Convention

**DynamoDB Tables**:
- Pattern: `{product}-{component}-{resource_type}-{environment}`
- Example: `bbws-customer-portal-orders-dev`
- Rule: Lowercase, hyphens as separators, environment suffix

**SQS Queues**:
- Pattern: `{product}-{component}-queue-{environment}`
- Example: `bbws-order-creation-dev`
- DLQ Variant: `{queue_name}-dlq`
- Example: `bbws-order-creation-dlq-dev`

**Lambda Functions**:
- Pattern: `{product}-{component}-{function_name}-{environment}`
- Example: `bbws-order-lambda-create-order-dev`
- Constraint: Max 64 characters

**S3 Buckets**:
- Pattern: `{product}-{component}-{purpose}-{environment}`
- Example: `bbws-email-templates-dev`
- Rule: Must be globally unique, lowercase, hyphens only

**IAM Roles**:
- Pattern: `{product}-{component}-{role_purpose}-{environment}`
- Example: `bbws-order-lambda-execution-dev`

**CloudWatch Log Groups**:
- Pattern: `/aws/lambda/{lambda_function_name}`
- Example: `/aws/lambda/bbws-order-lambda-create-order-dev`

**SNS Topics**:
- Pattern: `{product}-{component}-{purpose}-{environment}`
- Example: `bbws-alerts-dev`, `bbws-order-dlq-notifications-dev`

**CloudWatch Alarms**:
- Pattern: `{product}-{component}-{metric}-{environment}`
- Example: `bbws-order-dlq-depth-dev`

**API Gateway APIs**:
- Pattern: `{product}-{component}-api-{environment}`
- Example: `bbws-order-api-dev`

**VPC/Network Resources**:
- Pattern: `{product}-{component}-{resource}-{environment}`
- Example: `bbws-order-sg-dev` (security group)

#### Code Artifact Naming

**Python Modules**:
- Pattern: `snake_case`
- Example: `order_service.py`, `create_order_handler.py`

**Python Classes**:
- Pattern: `PascalCase`
- Example: `OrderService`, `CreateOrderHandler`

**Python Functions**:
- Pattern: `snake_case`
- Example: `get_order()`, `validate_request()`

**Python Constants**:
- Pattern: `UPPER_SNAKE_CASE`
- Example: `ORDER_TIMEOUT`, `MAX_RETRIES`

**Python Private Methods/Attributes**:
- Pattern: `_leading_underscore_snake_case`
- Example: `_validate_order()`, `_calculate_total()`

**Test Files**:
- Pattern: `test_{module_name}.py`
- Example: `test_order_service.py`

**Terraform Files**:
- Pattern: `{resource_type}.tf` or `{component}.tf`
- Example: `dynamodb.tf`, `sqs.tf`, `lambda.tf`

**Environment Variables**:
- Pattern: `UPPER_SNAKE_CASE`
- Prefix: Environment name for multi-env configs
- Example: `DEV_DYNAMODB_TABLE_NAME`, `SIT_SQS_QUEUE_URL`

**Terraform Variables**:
- Pattern: `snake_case`
- Example: `environment`, `aws_region`, `dynamodb_table_name`

---

## Deliverables

### Output Document: `output.md`

The final output must be saved as `/worker-3-naming-validation/output.md` and include:

1. **Repository Naming Validation**
   - Repository name: `2_bbws_order_lambda`
   - Validation status (pass/fail with reasons)
   - Comparison to similar repositories

2. **AWS Resource Naming Validation Matrix**
   - For each resource type (Lambda, DynamoDB, SQS, S3, etc.)
   - Current/proposed names
   - Validation status (pass/fail)
   - Deviation notes (if any)

3. **Code Artifact Naming Validation**
   - Module naming validation (snake_case)
   - Class naming validation (PascalCase)
   - Function naming validation (snake_case)
   - Constants validation (UPPER_SNAKE_CASE)

4. **Configuration File Naming**
   - Terraform file naming
   - GitHub Actions workflow naming
   - Environment file naming

5. **Environment Variable Naming**
   - List of all environment variables
   - Naming validation
   - Cross-environment mapping

6. **Naming Convention Reference Guide**
   - Quick reference for all conventions
   - Examples for each type
   - Templates for new resources

7. **Validation Summary**
   - Overall compliance score
   - List of deviations (if any)
   - Recommendations for fixes
   - Approved naming patterns

---

## Success Criteria

### Validation Completeness

- [ ] Repository name validated
- [ ] All Lambda function names specified and validated
- [ ] DynamoDB table names validated
- [ ] SQS queue names (main + DLQ) validated
- [ ] S3 bucket names validated
- [ ] IAM role names specified and validated
- [ ] CloudWatch resource names validated
- [ ] API Gateway resource names validated

### Quality Criteria

- [ ] All names follow BBWS convention pattern
- [ ] Names are environment-parameterized (no hardcoding dev/sit/prod where possible)
- [ ] Names are globally unique (especially S3 buckets)
- [ ] Names follow AWS length restrictions
- [ ] Names use only allowed characters (lowercase, hyphens, underscores)
- [ ] Names are descriptive and self-documenting

### Consistency Criteria

- [ ] All resources use consistent naming patterns
- [ ] Environment naming is consistent (dev, sit, prod - not dev, stage, prod)
- [ ] Component naming matches across all resources
- [ ] Product identifier (bbws) used consistently
- [ ] Naming aligns with other BBWS repositories

---

## Execution Steps

### Step 1: Validate Repository Name

**Action**: Verify GitHub repository naming

**Repository Name**: `2_bbws_order_lambda`

**Validation Checklist**:
- [ ] Starts with sequence number (2)
- [ ] Includes product identifier (bbws)
- [ ] Includes component name (order)
- [ ] Includes resource type (lambda)
- [ ] All lowercase
- [ ] Uses underscores as separators
- [ ] No dots or hyphens
- [ ] Max 40 characters (current: 21 characters - PASS)
- [ ] Unique within organization
- [ ] Matches sibling repositories (e.g., 2_bbws_product_lambda, 2_bbws_tenant_lambda)

**Deliverable Evidence**:
- Repository name validation table
- Comparison to similar repositories
- Pass/fail status

### Step 2: Validate Lambda Function Names

**Action**: Extract from LLD and validate each Lambda name

**LLD Reference**: Section 1.3, 4.x

**Lambda Functions to Validate**:

```
API Handlers:
1. create_order → AWS Name: bbws-order-lambda-create-order-{env}
2. get_order → AWS Name: bbws-order-lambda-get-order-{env}
3. list_orders → AWS Name: bbws-order-lambda-list-orders-{env}
4. update_order → AWS Name: bbws-order-lambda-update-order-{env}

Event-Driven:
5. OrderCreatorRecord → AWS Name: bbws-order-lambda-creator-record-{env}
6. OrderPDFCreator → AWS Name: bbws-order-lambda-pdf-creator-{env}
7. OrderInternalNotificationSender → AWS Name: bbws-order-lambda-internal-notifier-{env}
8. CustomerOrderConfirmationSender → AWS Name: bbws-order-lambda-customer-notifier-{env}
```

**Validation for Each Function**:
- [ ] Includes product identifier (bbws)
- [ ] Includes component (order)
- [ ] Includes resource type (lambda)
- [ ] Includes function name
- [ ] Parameterized environment ({env})
- [ ] All lowercase
- [ ] Uses hyphens as separators
- [ ] Max 64 character AWS limit (validate each)
- [ ] Unique within AWS account
- [ ] Descriptive name

**Deliverable Evidence**:
- Lambda naming validation table (8 functions)
- Pass/fail for each
- Character count validation
- Environment parameterization verification

### Step 3: Validate DynamoDB Table Names

**Action**: Validate table naming

**Table Name Pattern**: `bbws-customer-portal-orders-{environment}`

**Validation**:
- [ ] Includes product identifier (bbws)
- [ ] Includes component (customer-portal, orders)
- [ ] Includes resource type indication (orders)
- [ ] Parameterized environment ({environment})
- [ ] All lowercase
- [ ] Uses hyphens as separators
- [ ] Unique within AWS account
- [ ] Matches naming in LLD section 5.1.1

**GSI Naming**:

| GSI Name | Validation |
|----------|------------|
| OrdersByDateIndex | Descriptive, CamelCase for index names (PASS) |
| OrderByIdIndex | Descriptive, CamelCase for index names (PASS) |

**Deliverable Evidence**:
- DynamoDB naming validation table
- Pass/fail for table and indexes

### Step 4: Validate SQS Queue Names

**Action**: Validate queue naming

**LLD Reference**: Section 5.4

**Queues to Validate**:

| Queue | Expected Name | Validation |
|-------|---------------|------------|
| Main Queue | bbws-order-creation-{environment} | Check pattern |
| DLQ | bbws-order-creation-dlq-{environment} | Check pattern |

**Validation for Each Queue**:
- [ ] Includes product identifier (bbws)
- [ ] Includes component (order)
- [ ] Includes purpose (creation)
- [ ] Parameterized environment ({environment})
- [ ] All lowercase
- [ ] Uses hyphens as separators
- [ ] DLQ suffix: `-dlq` (not `-dead-letter-queue`)
- [ ] Unique within AWS account

**Deliverable Evidence**:
- SQS queue naming validation table
- Pass/fail status
- DLQ suffix validation

### Step 5: Validate S3 Bucket Names

**Action**: Validate bucket naming

**LLD Reference**: Section 6

**Buckets to Validate**:

| Bucket | Expected Name | Purpose |
|--------|---------------|---------|
| Email Templates | bbws-email-templates-{environment} | Email template storage |
| Order Artifacts | bbws-orders-{environment} | PDF and receipt storage |

**Validation for Each Bucket**:
- [ ] Includes product identifier (bbws)
- [ ] Includes purpose/component
- [ ] Parameterized environment ({environment})
- [ ] All lowercase
- [ ] Uses hyphens as separators
- [ ] No dots (except for domain/FQDN purposes)
- [ ] Globally unique (AWS requirement)
- [ ] Max 63 characters
- [ ] Valid DNS-compliant format

**Special Note**: S3 bucket names are globally unique across all AWS accounts. Validate format compliance and uniqueness strategy.

**Deliverable Evidence**:
- S3 bucket naming validation table
- Global uniqueness strategy documented
- Pass/fail status

### Step 6: Validate IAM Role Names

**Action**: Extract IAM role requirements and validate naming

**Roles to Validate**:

| Role | Expected Name | Purpose |
|------|---------------|---------|
| Lambda Execution Role | bbws-order-lambda-execution-{environment} | Lambda service execution |
| OIDC Role (DEV) | github-2-bbws-order-lambda-dev | GitHub Actions OIDC auth |
| OIDC Role (SIT) | github-2-bbws-order-lambda-sit | GitHub Actions OIDC auth |
| OIDC Role (PROD) | github-2-bbws-order-lambda-prod | GitHub Actions OIDC auth |

**Validation for Each Role**:
- [ ] Includes product/project identifier
- [ ] Includes component (order-lambda)
- [ ] Includes purpose
- [ ] Parameterized environment ({environment})
- [ ] All lowercase
- [ ] Uses hyphens as separators
- [ ] Max 64 characters
- [ ] Clear purpose from name

**Deliverable Evidence**:
- IAM role naming validation table
- Pass/fail for each role

### Step 7: Validate CloudWatch Resources

**Action**: Validate CloudWatch log group and alarm naming

**CloudWatch Log Groups**:

```
/aws/lambda/bbws-order-lambda-create-order-{env}
/aws/lambda/bbws-order-lambda-get-order-{env}
/aws/lambda/bbws-order-lambda-list-orders-{env}
/aws/lambda/bbws-order-lambda-update-order-{env}
/aws/lambda/bbws-order-lambda-creator-record-{env}
/aws/lambda/bbws-order-lambda-pdf-creator-{env}
/aws/lambda/bbws-order-lambda-internal-notifier-{env}
/aws/lambda/bbws-order-lambda-customer-notifier-{env}
```

**Validation**:
- [ ] Follow AWS convention: `/aws/lambda/{function_name}`
- [ ] Include full Lambda function name
- [ ] Parameterized environment
- [ ] Unique within AWS account

**CloudWatch Alarms**:

| Alarm | Expected Name |
|-------|---------------|
| DLQ Depth Alarm | bbws-order-dlq-depth-{environment} |
| Lambda Error Rate | bbws-order-lambda-error-rate-{environment} |
| SQS Age Alarm | bbws-order-sqs-age-{environment} |
| DynamoDB Throttle | bbws-order-dynamodb-throttle-{environment} |

**Validation**:
- [ ] Includes product/component
- [ ] Includes metric/purpose
- [ ] Parameterized environment
- [ ] Descriptive and unambiguous

**Deliverable Evidence**:
- CloudWatch resource naming validation table
- Pass/fail status

### Step 8: Validate Code Artifact Naming

**Action**: Validate Python module, class, and function naming

**LLD Reference**: Section 15.1 (Project Structure)

**Expected Structure**:
```
src/
├── handlers/
│   ├── create_order.py (module)
│   ├── get_order.py (module)
│   ├── list_orders.py (module)
│   └── update_order.py (module)
├── services/
│   ├── order_service.py (module)
│   ├── cart_service.py (module)
│   └── email_service.py (module)
├── repositories/
│   └── order_dao.py (module)
└── models/
    ├── order.py (module)
    ├── order_item.py (module)
    └── billing_details.py (module)
```

**Module Naming Validation**:
- [ ] All `.py` files use `snake_case`
- [ ] Meaningful descriptive names
- [ ] Singular form for entity models (order.py, not orders.py)
- [ ] Handler suffix for API handlers (create_order_handler, not create_order)
- [ ] Service suffix for services (order_service, not order_svc)
- [ ] DAO suffix for data access objects (order_dao, not order_repository)

**Class Naming Validation**:
- [ ] All classes use `PascalCase`
- [ ] Exception classes use suffix: `Exception` or specific exception type
- [ ] Request/Response classes use suffix: `Request`, `Response`
- [ ] Service classes use suffix: `Service`
- [ ] DAO classes use suffix: `DAO` or `Repository`

**Function Naming Validation**:
- [ ] All functions use `snake_case`
- [ ] Handler functions: `lambda_handler()` or `handler_*`
- [ ] Service methods: verb_noun pattern (get_order, create_order)
- [ ] Private methods: `_leading_underscore`

**Constant Naming Validation**:
- [ ] All constants use `UPPER_SNAKE_CASE`
- [ ] Meaningful descriptive names
- [ ] Grouped logically in modules

**Deliverable Evidence**:
- Code artifact naming validation table
- Module structure diagram
- Examples of correct naming for each type
- Pass/fail overall

### Step 9: Validate Terraform File Naming

**Action**: Validate Terraform configuration file naming

**Expected Structure**:
```
terraform/
├── dev/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── lambda.tf
│   ├── dynamodb.tf
│   ├── sqs.tf
│   ├── s3.tf
│   ├── iam.tf
│   ├── api_gateway.tf
│   └── monitoring.tf
├── sit/
│   └── [same as dev]
├── prod/
│   └── [same as dev]
├── modules/
│   ├── lambda/
│   ├── dynamodb/
│   ├── sqs/
│   └── s3/
└── environments.tfvars (or dev.tfvars, sit.tfvars, prod.tfvars)
```

**Validation**:
- [ ] Resource type prefix for specific resource files (lambda.tf, dynamodb.tf)
- [ ] main.tf, variables.tf, outputs.tf naming
- [ ] Module directory names match resource types
- [ ] Environment-specific directories (dev, sit, prod)
- [ ] tfvars files named by environment
- [ ] All lowercase
- [ ] Underscores for multi-word names (api_gateway.tf)

**Deliverable Evidence**:
- Terraform file naming validation
- Directory structure diagram
- Pass/fail status

### Step 10: Validate Environment Variables

**Action**: Extract and validate environment variable naming

**LLD References**: Various sections with environment-specific configs

**Expected Environment Variables**:

```
# DynamoDB
DYNAMODB_TABLE_NAME=bbws-customer-portal-orders-{env}
DYNAMODB_REGION=af-south-1

# SQS
SQS_QUEUE_URL=https://sqs.{region}.amazonaws.com/{account}/bbws-order-creation-{env}
SQS_DLQ_URL=https://sqs.{region}.amazonaws.com/{account}/bbws-order-creation-dlq-{env}

# S3
S3_TEMPLATES_BUCKET=bbws-email-templates-{env}
S3_ORDERS_BUCKET=bbws-orders-{env}

# Lambda Configuration
LAMBDA_TIMEOUT=30
LAMBDA_MEMORY=512
LOG_LEVEL=INFO

# AWS Configuration
AWS_REGION=af-south-1
AWS_ACCOUNT_ID={environment specific}
ENVIRONMENT=dev|sit|prod

# Email Configuration
SES_FROM_ADDRESS=orders@kimmyai.io
SES_REGION=af-south-1
```

**Validation for Each Variable**:
- [ ] Uses `UPPER_SNAKE_CASE`
- [ ] No product/component prefix (app config handled separately)
- [ ] Environment-specific values parameterized
- [ ] Descriptive names
- [ ] No sensitive data in variable names
- [ ] Grouped logically by resource type

**Deliverable Evidence**:
- Environment variable naming table
- Parameter file template (.env.example)
- Parameterization validation
- Security review (no sensitive data in names)

### Step 11: Create Naming Reference Guide

**Action**: Compile comprehensive naming convention guide

**Guide Contents**:

1. **Quick Reference Table**
   - Resource type | Pattern | Example | Rules

2. **Detailed Conventions**
   - Repository
   - AWS Resources (each type)
   - Code Artifacts
   - Configuration Files
   - Environment Variables

3. **Templates**
   - New resource naming templates
   - Variable naming templates
   - Code artifact templates

4. **Do's and Don'ts**
   - Common mistakes
   - Corrections
   - Why conventions matter

**Deliverable Evidence**:
- Naming convention reference guide document
- One-page quick reference
- Templates for each resource type

### Step 12: Compile Validation Summary

**Action**: Create final validation report

**Summary Contents**:

1. **Overall Compliance Score**
   - Percentage of resources following naming conventions
   - Pass/fail for each category

2. **Deviations Found**
   - List of non-compliant names
   - Reasons for deviation
   - Recommended corrections

3. **Recommendations**
   - Resources to rename
   - Renaming strategy
   - Implementation order
   - Impact assessment

4. **Approved Naming Patterns**
   - All validated and approved resource names
   - Ready for use in Stage 2 implementation

---

## Output Format

### Output File: `worker-3-naming-validation/output.md`

```markdown
# Worker 3 Output: Naming Validation

**Date Completed**: YYYY-MM-DD
**Worker**: [Your Name/Identifier]
**Status**: Complete / In Progress / Blocked

## Executive Summary

[Summary of naming convention validation results]

## Validation Results

### Repository Naming
| Item | Expected | Actual | Status |
|------|----------|--------|--------|
| Repository Name | 2_bbws_order_lambda | 2_bbws_order_lambda | PASS |

### AWS Resource Naming

#### Lambda Functions (8 total)
[Complete table with all 8 functions]

#### DynamoDB Tables
[Table naming validation]

#### SQS Queues
[Queue naming validation]

#### S3 Buckets
[Bucket naming validation]

#### IAM Roles
[IAM role naming validation]

#### CloudWatch Resources
[Log groups and alarms]

### Code Artifact Naming

#### Module Naming
[Module validation table]

#### Class Naming
[Class naming validation]

#### Function Naming
[Function naming validation]

#### Constant Naming
[Constant naming validation]

### Configuration File Naming

#### Terraform Files
[Terraform file naming validation]

#### GitHub Actions
[Workflow naming validation]

### Environment Variables

[Environment variable naming validation]

## Naming Convention Reference

[Quick reference guide with examples]

## Validation Summary

### Compliance Score: XX%

[Overall compliance assessment]

### Deviations Found

[List of deviations with explanations]

### Recommendations

[Corrective actions if needed]

## Approved Naming Patterns

[Final approved names for all resources]

## Issues/Blockers

[Any naming conflicts or concerns]

## Appendix: Naming Templates

[Templates for new resources]
```

---

## References

- **BBWS Documentation**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/CLAUDE.md`
- **LLD Document**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.8_LLD_Order_Lambda.md`
- **AWS Naming Best Practices**: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html

---

**Document Version**: 1.0
**Created**: 2025-12-30
