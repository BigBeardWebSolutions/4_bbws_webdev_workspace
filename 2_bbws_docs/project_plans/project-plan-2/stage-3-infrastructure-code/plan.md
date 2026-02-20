# Stage 3 Plan: Infrastructure Code Development

**Stage**: Stage 3 - Infrastructure Code Development
**Project**: Buy Page Implementation - Frontend + Infrastructure
**Status**: IN PROGRESS
**Created**: 2025-12-30
**Agent**: DevOps Engineer Agent
**Workers**: 5

---

## Stage Overview

**Objective**: Create Terraform modules for all AWS infrastructure components required to host the React buy page with CloudFront CDN, S3 origin, Route 53 DNS, ACM certificates, and Lambda@Edge Basic Auth.

**Prerequisites**:
- ✅ Stage 1 complete (Requirements & Design Analysis)
- ✅ Stage 2 complete (Frontend Development)
- ✅ Gate 2 approved
- Stage 2 outputs available:
  - Frontend application in `2_1_bbws_web_public` repository
  - Production build in `2_1_bbws_web_public/dist/`

**Repository**: `2_1_bbws_infrastructure` (Terraform infrastructure code)

---

## Architecture Overview

**Target Infrastructure** (Per Environment: DEV, SIT, PROD):

```
User Request (https://dev.kimmyai.io/buy)
    │
    ├──> Route 53 (DNS)
    │       └──> kimmyai.io Hosted Zone
    │               └──> dev.kimmyai.io A Record → CloudFront
    │
    ├──> ACM Certificate (us-east-1)
    │       └──> *.kimmyai.io wildcard certificate
    │
    └──> CloudFront Distribution
            ├──> Lambda@Edge (Viewer Request)
            │       └──> Basic Auth validation
            │
            └──> Origin: S3 Bucket (OAC - Origin Access Control)
                    └──> React build artifacts (HTML, JS, CSS)
```

---

## Technology Stack

**Infrastructure as Code**:
- **Terraform**: 1.6+
- **Provider**: AWS (hashicorp/aws ~> 5.0)
- **State Backend**: S3 + DynamoDB (for state locking)
- **Modules**: Custom Terraform modules

**AWS Services**:
- **S3**: Static website hosting (origin)
- **CloudFront**: CDN distribution
- **Route 53**: DNS management
- **ACM**: SSL/TLS certificates
- **Lambda@Edge**: Basic authentication
- **IAM**: Permissions and policies
- **CloudWatch**: Logging and monitoring

---

## Workers Breakdown

### Worker 3-1: S3 Bucket & CloudFront Distribution
**Status**: PENDING
**Location**: `worker-1-s3-cloudfront/`

**Objective**: Create Terraform module for S3 origin bucket and CloudFront distribution with OAC (Origin Access Control).

**Tasks**:
1. Create S3 bucket module (`modules/s3-website/`)
2. Configure bucket policies for CloudFront OAC
3. Create CloudFront distribution module (`modules/cloudfront/`)
4. Configure CloudFront behaviors (SPA routing, error pages)
5. Set up OAC for secure S3 access
6. Configure cache behaviors and TTLs

**Deliverables**:
- `modules/s3-website/main.tf`
- `modules/s3-website/variables.tf`
- `modules/s3-website/outputs.tf`
- `modules/cloudfront/main.tf`
- `modules/cloudfront/variables.tf`
- `modules/cloudfront/outputs.tf`

---

### Worker 3-2: Route 53 DNS Configuration
**Status**: PENDING
**Location**: `worker-2-route53/`

**Objective**: Create Terraform module for Route 53 DNS records and hosted zone management.

**Tasks**:
1. Create Route 53 module (`modules/route53/`)
2. Configure A record (alias to CloudFront)
3. Configure AAAA record (IPv6 support)
4. Set up health checks (optional)
5. Configure DNS failover (for multi-region DR)

**Deliverables**:
- `modules/route53/main.tf`
- `modules/route53/variables.tf`
- `modules/route53/outputs.tf`

---

### Worker 3-3: ACM Certificate Provisioning
**Status**: PENDING
**Location**: `worker-3-acm/`

**Objective**: Create Terraform module for ACM certificate provisioning and DNS validation.

**Tasks**:
1. Create ACM module (`modules/acm/`)
2. Request wildcard certificate (`*.kimmyai.io`, `kimmyai.io`)
3. Configure DNS validation with Route 53
4. Wait for certificate validation
5. Output certificate ARN for CloudFront

**Deliverables**:
- `modules/acm/main.tf`
- `modules/acm/variables.tf`
- `modules/acm/outputs.tf`

**Important**: ACM certificates for CloudFront must be in **us-east-1** region.

---

### Worker 3-4: Lambda@Edge Basic Auth
**Status**: PENDING
**Location**: `worker-4-lambda-edge/`

**Objective**: Create Lambda@Edge function for Basic Authentication and Terraform module for deployment.

**Tasks**:
1. Create Lambda function code (`lambda/basic-auth/index.js`)
2. Implement Basic Auth logic (viewer-request trigger)
3. Create Lambda IAM role and policies
4. Create Lambda@Edge module (`modules/lambda-edge/`)
5. Configure CloudWatch Logs (replicated across all regions)

**Deliverables**:
- `lambda/basic-auth/index.js` - Lambda function code
- `lambda/basic-auth/package.json` - Node.js dependencies (if any)
- `modules/lambda-edge/main.tf`
- `modules/lambda-edge/variables.tf`
- `modules/lambda-edge/outputs.tf`

**Important**: Lambda@Edge functions must be in **us-east-1** region.

---

### Worker 3-5: Terraform Root Module Integration
**Status**: PENDING
**Location**: `worker-5-root-module/`

**Objective**: Create root Terraform configuration that integrates all modules for multi-environment deployment.

**Tasks**:
1. Create environment-specific configurations (`environments/dev/`, `environments/sit/`, `environments/prod/`)
2. Create root module (`main.tf`) with module composition
3. Configure Terraform backend (S3 + DynamoDB)
4. Create `terraform.tfvars` templates for each environment
5. Document deployment procedures
6. Create `Makefile` for common operations

**Deliverables**:
- `environments/dev/main.tf`
- `environments/dev/variables.tf`
- `environments/dev/terraform.tfvars`
- `environments/sit/` (similar structure)
- `environments/prod/` (similar structure)
- `backend.tf` - S3 backend configuration
- `Makefile` - Deployment automation
- `README.md` - Deployment guide

---

## Repository Structure (Expected Output)

```
2_1_bbws_infrastructure/
├── modules/
│   ├── s3-website/                  # Worker 3-1
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── cloudfront/                  # Worker 3-1
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── route53/                     # Worker 3-2
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── acm/                         # Worker 3-3
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── lambda-edge/                 # Worker 3-4
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── lambda/
│   └── basic-auth/                  # Worker 3-4
│       ├── index.js
│       └── package.json
├── environments/
│   ├── dev/                         # Worker 3-5
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── sit/                         # Worker 3-5
│   │   └── (similar structure)
│   └── prod/                        # Worker 3-5
│       └── (similar structure)
├── Makefile                         # Worker 3-5
├── README.md                        # Worker 3-5
└── .gitignore
```

---

## Success Criteria

- [ ] All Terraform modules created with proper variables and outputs
- [ ] S3 bucket configured with CloudFront OAC (no public access)
- [ ] CloudFront distribution configured with custom domain
- [ ] Route 53 DNS records created (A, AAAA)
- [ ] ACM certificate provisioned and validated
- [ ] Lambda@Edge Basic Auth function deployed
- [ ] Multi-environment support (dev, sit, prod)
- [ ] Terraform state backend configured (S3 + DynamoDB)
- [ ] `terraform plan` succeeds for all environments
- [ ] Documentation complete (README, deployment guide)

---

## Environment Configuration

### DEV Environment

```hcl
environment     = "dev"
domain_name     = "dev.kimmyai.io"
hosted_zone_id  = "<Route53-Hosted-Zone-ID>"
aws_region      = "eu-west-1"
cloudfront_region = "us-east-1"  # Required for ACM & Lambda@Edge

basic_auth_username = "admin"
basic_auth_password = "<hashed-password>"

s3_bucket_name = "dev-kimmyai-web-public"

cloudfront_price_class = "PriceClass_100"  # North America + Europe
```

### SIT Environment

```hcl
environment     = "sit"
domain_name     = "sit.kimmyai.io"
hosted_zone_id  = "<Route53-Hosted-Zone-ID>"
aws_region      = "eu-west-1"
cloudfront_region = "us-east-1"

basic_auth_username = "admin"
basic_auth_password = "<hashed-password>"

s3_bucket_name = "sit-kimmyai-web-public"

cloudfront_price_class = "PriceClass_100"
```

### PROD Environment

```hcl
environment     = "prod"
domain_name     = "kimmyai.io"
hosted_zone_id  = "<Route53-Hosted-Zone-ID>"
aws_region      = "af-south-1"  # Primary region (Cape Town)
cloudfront_region = "us-east-1"

basic_auth_enabled = false  # No Basic Auth in production

s3_bucket_name = "prod-kimmyai-web-public"

cloudfront_price_class = "PriceClass_All"  # Global distribution
```

---

## Dependencies

### External Dependencies

**AWS Account Setup**:
- AWS accounts for DEV, SIT, PROD
- IAM user/role with Terraform permissions
- Route 53 hosted zone for `kimmyai.io` (already exists)

**Terraform State Backend**:
- S3 bucket for Terraform state (e.g., `bbws-terraform-state-dev`)
- DynamoDB table for state locking (e.g., `bbws-terraform-locks-dev`)

### Internal Dependencies (Worker Execution Order)

```
Worker 3-3 (ACM) ──┐
                   │
Worker 3-1 (S3 + CloudFront) ──> Worker 3-4 (Lambda@Edge)
                   │                          │
Worker 3-2 (Route 53) ────────────────────────┴──> Worker 3-5 (Root Module)
```

**Execution Order**:
1. Workers 3-1, 3-2, 3-3 can run in parallel (independent modules)
2. Worker 3-4 (Lambda@Edge) requires Worker 3-1 complete (needs CloudFront distribution)
3. Worker 3-5 (Root Module) requires all previous workers complete

---

## Terraform Best Practices

### Module Design Principles

1. **Single Responsibility**: Each module manages one AWS service
2. **Reusability**: Modules parameterized for multi-environment use
3. **Outputs**: All resource IDs/ARNs exposed as outputs
4. **Variables**: All configurable values as variables
5. **Documentation**: README.md in each module

### Security Best Practices

1. **No Hardcoded Secrets**: Use AWS Secrets Manager or environment variables
2. **Least Privilege IAM**: Minimal permissions for Lambda@Edge
3. **S3 Bucket Security**:
   - Block public access
   - Server-side encryption enabled
   - Versioning enabled
4. **CloudFront Security**:
   - OAC (not legacy OAI)
   - TLS 1.2+ only
   - HSTS headers (via Lambda@Edge)

### State Management

**Backend Configuration** (per environment):

```hcl
terraform {
  backend "s3" {
    bucket         = "bbws-terraform-state-dev"
    key            = "2-1-bbws-web-public/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "bbws-terraform-locks-dev"
  }
}
```

---

## Testing Strategy

### Terraform Validation

```bash
# Validate syntax
terraform validate

# Format check
terraform fmt -check -recursive

# Security scanning (tfsec)
tfsec .

# Compliance scanning (checkov)
checkov -d .
```

### Deployment Testing (DEV)

1. **Plan**: `terraform plan` - Verify resources to be created
2. **Apply**: `terraform apply` - Create infrastructure
3. **Verify**:
   - S3 bucket created and build uploaded
   - CloudFront distribution accessible
   - DNS resolves correctly
   - ACM certificate validated
   - Basic Auth prompts correctly
   - HTTPS works (certificate valid)

### Integration Testing

- Load `https://dev.kimmyai.io/buy` in browser
- Verify Basic Auth prompt appears
- Enter credentials and verify page loads
- Check browser console for errors
- Verify all assets load from CloudFront
- Test 404 fallback to index.html (SPA routing)

---

## Quality Gates

### Worker Completion Criteria

- [ ] Terraform code passes `terraform validate`
- [ ] Terraform code formatted (`terraform fmt`)
- [ ] Module README.md created
- [ ] Variables documented with descriptions
- [ ] Outputs documented
- [ ] Security best practices followed
- [ ] output.md document created

### Stage 3 Completion Criteria

- [ ] All 5 workers complete
- [ ] Stage 3 summary created
- [ ] `terraform plan` succeeds for DEV environment
- [ ] Gate 3 approval obtained (DevOps Lead, Security Lead)

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| ACM validation takes too long | Medium | Use DNS validation (automated via Route 53) |
| Lambda@Edge deployment slow | Medium | Expect 5-10 min for global replication |
| Route 53 hosted zone doesn't exist | High | Verify hosted zone ID before starting |
| State backend not configured | High | Create S3 bucket + DynamoDB table first |
| IAM permissions insufficient | High | Use AdministratorAccess for initial setup |

---

## Deployment Workflow

### Initial Setup (One-time)

```bash
# 1. Create Terraform state backend
aws s3 mb s3://bbws-terraform-state-dev --region eu-west-1
aws dynamodb create-table \
  --table-name bbws-terraform-locks-dev \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region eu-west-1

# 2. Clone infrastructure repository
git clone <2_1_bbws_infrastructure_repo>
cd 2_1_bbws_infrastructure
```

### Environment Deployment

```bash
# DEV deployment
cd environments/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# SIT deployment (after DEV verified)
cd ../sit
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# PROD deployment (after SIT verified)
cd ../prod
terraform init
terraform plan -out=tfplan
# IMPORTANT: Manual approval required
terraform apply tfplan
```

### Application Deployment

```bash
# Build frontend
cd 2_1_bbws_web_public
npm run build

# Sync to S3 (DEV)
aws s3 sync dist/ s3://dev-kimmyai-web-public/ \
  --delete \
  --cache-control "public, max-age=31536000" \
  --exclude "index.html" \
  --profile Tebogo-dev

# Sync index.html (no cache)
aws s3 cp dist/index.html s3://dev-kimmyai-web-public/ \
  --cache-control "no-cache" \
  --profile Tebogo-dev

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id <CloudFront-Distribution-ID> \
  --paths "/*" \
  --profile Tebogo-dev
```

---

## Estimated Timeline

**Total Duration**: 2-3 work sessions

| Worker | Estimated Time | Complexity |
|--------|----------------|------------|
| Worker 3-1: S3 + CloudFront | 2-3 hours | Medium-High |
| Worker 3-2: Route 53 | 1-2 hours | Low-Medium |
| Worker 3-3: ACM | 1-2 hours | Medium |
| Worker 3-4: Lambda@Edge | 2-3 hours | Medium-High |
| Worker 3-5: Root Module | 2-3 hours | Medium |

---

## Next Steps (After Stage 3)

**Stage 4**: CI/CD Pipeline Development (3 workers)
- GitHub Actions workflows for automated deployment
- Build, test, deploy automation
- Multi-environment promotion workflow

**Stage 5**: Testing & Documentation (3 workers)
- Integration tests
- Deployment runbooks
- Troubleshooting guides
- Operational dashboards

---

**Created**: 2025-12-30
**Status**: IN PROGRESS
**Agent**: DevOps Engineer Agent
**Stage**: Stage 3 - Infrastructure Code Development
**Project Manager**: Agentic Project Manager
