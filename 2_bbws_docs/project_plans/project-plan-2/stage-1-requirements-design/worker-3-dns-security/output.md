# DNS & Security Requirements Analysis
## Worker 1-3: DNS & Security Requirements

**Worker ID**: worker-3-dns-security
**Stage**: Stage 1 - Requirements & Design Analysis
**Status**: COMPLETE
**Created**: 2025-12-30
**Project**: Buy Page Implementation - Frontend + Infrastructure

---

## Table of Contents

1. [DNS Architecture Overview](#1-dns-architecture-overview)
2. [Route 53 Configuration](#2-route-53-configuration)
3. [ACM Certificate Specification](#3-acm-certificate-specification)
4. [Basic Auth Implementation](#4-basic-auth-implementation)
5. [CloudFront Security Configuration](#5-cloudfront-security-configuration)
6. [Deployment Sequence](#6-deployment-sequence)
7. [Testing Procedures](#7-testing-procedures)
8. [Runbook Procedures](#8-runbook-procedures)

---

## 1. DNS Architecture Overview

### 1.1 DNS Hierarchy

The DNS architecture implements a three-tier environment strategy with subdomains for DEV and SIT, and the apex domain for PROD:

```
┌─────────────────────────────────────────────────────────────┐
│                  Route 53 Hosted Zone                        │
│                      kimmyai.io                              │
└─────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┼─────────────┐
                │             │             │
                ▼             ▼             ▼
        dev.kimmyai.io  sit.kimmyai.io  kimmyai.io
                │             │             │
                │             │             │
          (A/AAAA ALIAS)  (A/AAAA ALIAS)  (A/AAAA ALIAS)
                │             │             │
                ▼             ▼             ▼
      ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
      │ CloudFront  │ │ CloudFront  │ │ CloudFront  │
      │    (DEV)    │ │    (SIT)    │ │   (PROD)    │
      │             │ │             │ │             │
      │ +Basic Auth │ │ +Basic Auth │ │ +Basic Auth │
      │ +Lambda@Edge│ │ +Lambda@Edge│ │ +Lambda@Edge│
      └─────────────┘ └─────────────┘ └─────────────┘
                │             │             │
                ▼             ▼             ▼
      ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
      │  S3 Bucket  │ │  S3 Bucket  │ │  S3 Bucket  │
      │  (dev-web)  │ │  (sit-web)  │ │ (prod-web)  │
      │             │ │             │ │             │
      │ [OAC Only]  │ │ [OAC Only]  │ │ [OAC Only]  │
      └─────────────┘ └─────────────┘ └─────────────┘
```

### 1.2 Environment-Specific DNS Mappings

| Environment | Domain | Full URL | CloudFront Distribution | Basic Auth |
|-------------|--------|----------|------------------------|------------|
| **DEV** | `dev.kimmyai.io` | `https://dev.kimmyai.io/buy` | CloudFront DEV distribution | ENABLED (dev/devpassword) |
| **SIT** | `sit.kimmyai.io` | `https://sit.kimmyai.io/buy` | CloudFront SIT distribution | ENABLED (sit/sitpassword) |
| **PROD** | `kimmyai.io` | `https://kimmyai.io/buy` | CloudFront PROD distribution | ENABLED (prod/prodpassword)* |

**Note**: PROD Basic Auth will be manually disabled before go-live using Terraform variable configuration.

### 1.3 DNS Flow Diagram

```
User Browser
    │
    ├─ https://dev.kimmyai.io/buy
    │       │
    │       └─> Route 53 DNS Query
    │               │
    │               └─> A/AAAA ALIAS Record → CloudFront DEV
    │                           │
    │                           ├─> Lambda@Edge (Viewer Request - Basic Auth)
    │                           │       │
    │                           │       ├─ Check Authorization Header
    │                           │       ├─ Valid? → Continue
    │                           │       └─ Invalid? → 401 Unauthorized
    │                           │
    │                           └─> S3 Bucket (via OAC)
    │                                   │
    │                                   └─> /buy/index.html
    │
    ├─ https://sit.kimmyai.io/buy
    │       [Same flow as DEV]
    │
    └─ https://kimmyai.io/buy
            [Same flow as DEV]
```

---

## 2. Route 53 Configuration

### 2.1 Hosted Zone Requirements

**Zone Name**: `kimmyai.io`

**Pre-Deployment Check**:
```bash
# Check if hosted zone already exists
aws route53 list-hosted-zones-by-name \
  --dns-name kimmyai.io \
  --max-items 1 \
  --query "HostedZones[?Name=='kimmyai.io.']" \
  --output table
```

**Expected Output**:
- If exists: Capture the `HostedZoneId` (e.g., `Z0123456789ABCDEFGHIJ`)
- If not exists: Create hosted zone (usually managed at domain registrar level)

### 2.2 DNS Record Specifications

#### 2.2.1 DEV Environment Record

**Record Name**: `dev.kimmyai.io`
**Record Type**: A (IPv4) + AAAA (IPv6) - ALIAS
**Target**: CloudFront DEV distribution domain (e.g., `d111111abcdef8.cloudfront.net`)
**Routing Policy**: Simple
**Evaluate Target Health**: No
**TTL**: Managed by Route 53 (ALIAS records don't have TTL)

**Terraform Example**:
```hcl
resource "aws_route53_record" "dev" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "dev.kimmyai.io"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.dev.domain_name
    zone_id                = aws_cloudfront_distribution.dev.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "dev_ipv6" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "dev.kimmyai.io"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.dev.domain_name
    zone_id                = aws_cloudfront_distribution.dev.hosted_zone_id
    evaluate_target_health = false
  }
}
```

#### 2.2.2 SIT Environment Record

**Record Name**: `sit.kimmyai.io`
**Record Type**: A (IPv4) + AAAA (IPv6) - ALIAS
**Target**: CloudFront SIT distribution domain
**Configuration**: Same as DEV

#### 2.2.3 PROD Environment Records

**Apex Record**:
- **Record Name**: `kimmyai.io` (apex/root domain)
- **Record Type**: A (IPv4) + AAAA (IPv6) - ALIAS
- **Target**: CloudFront PROD distribution domain

**WWW Record** (Optional):
- **Record Name**: `www.kimmyai.io`
- **Record Type**: A (IPv4) + AAAA (IPv6) - ALIAS
- **Target**: CloudFront PROD distribution domain (same as apex)

### 2.3 DNS Validation Settings

| Setting | Value | Rationale |
|---------|-------|-----------|
| **TTL** (for non-ALIAS) | 300 seconds (5 minutes) | Fast propagation during testing |
| **ALIAS TTL** | Managed by Route 53 | Automatic based on CloudFront |
| **Health Checks** | Not required | CloudFront handles health |
| **Propagation Time** | 30-60 seconds (Route 53) | AWS-managed, typically very fast |

### 2.4 DNS Testing Commands

```bash
# Test DNS resolution
dig dev.kimmyai.io
dig sit.kimmyai.io
dig kimmyai.io

# Test with specific DNS server
dig @8.8.8.8 dev.kimmyai.io

# Check DNS propagation globally
nslookup dev.kimmyai.io
nslookup sit.kimmyai.io
nslookup kimmyai.io
```

---

## 3. ACM Certificate Specification

### 3.1 Certificate Requirements

**Primary Domain**: `kimmyai.io`
**Wildcard Domain**: `*.kimmyai.io`
**Region**: **`us-east-1`** (REQUIRED for CloudFront)
**Validation Method**: DNS validation (automated via Route 53)
**Key Algorithm**: RSA 2048 or higher

**Coverage**:
- `kimmyai.io` (apex domain)
- `dev.kimmyai.io` (covered by wildcard)
- `sit.kimmyai.io` (covered by wildcard)
- `www.kimmyai.io` (covered by wildcard)
- Any future subdomains

### 3.2 CRITICAL: Check for Existing Certificate FIRST

**Problem**: Creating duplicate ACM certificates can cause conflicts and management issues.

**Solution**: Use Terraform data source to check for existing certificate before creating a new one.

#### 3.2.1 Terraform Approach - Check Existing Certificate

```hcl
# Provider for us-east-1 (required for CloudFront certificates)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# Data source to check for existing certificate
data "aws_acm_certificate" "existing" {
  provider    = aws.us_east_1
  domain      = "kimmyai.io"
  statuses    = ["ISSUED"]
  most_recent = true

  # This will return null if no certificate exists
}

# Conditionally create certificate only if it doesn't exist
resource "aws_acm_certificate" "main" {
  count    = data.aws_acm_certificate.existing.arn == null ? 1 : 0
  provider = aws.us_east_1

  domain_name               = "kimmyai.io"
  subject_alternative_names = ["*.kimmyai.io"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "kimmyai.io-wildcard"
    Environment = "shared"
    ManagedBy   = "terraform"
  }
}

# Use existing certificate ARN or newly created one
locals {
  certificate_arn = coalesce(
    data.aws_acm_certificate.existing.arn,
    try(aws_acm_certificate.main[0].arn, null)
  )
}

# DNS validation records (only if creating new certificate)
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in try(aws_acm_certificate.main[0].domain_validation_options, []) : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# Certificate validation (only if creating new certificate)
resource "aws_acm_certificate_validation" "main" {
  count           = data.aws_acm_certificate.existing.arn == null ? 1 : 0
  provider        = aws.us_east_1
  certificate_arn = aws_acm_certificate.main[0].arn
  validation_record_fqdns = [
    for record in aws_route53_record.cert_validation : record.fqdn
  ]

  timeouts {
    create = "15m"
  }
}
```

#### 3.2.2 AWS CLI Check Command

```bash
# Check for existing ACM certificate in us-east-1
aws acm list-certificates \
  --region us-east-1 \
  --certificate-statuses ISSUED \
  --query "CertificateSummaryList[?DomainName=='kimmyai.io']" \
  --output table

# Get detailed certificate information
aws acm describe-certificate \
  --region us-east-1 \
  --certificate-arn <ARN_FROM_ABOVE> \
  --output json
```

### 3.3 Certificate Creation Workflow (If Not Exists)

```
1. Check for existing certificate
   ├─ EXISTS? → Use existing ARN → Skip to Step 7
   └─ NOT EXISTS? → Continue to Step 2

2. Create ACM certificate request
   ├─ Domain: kimmyai.io
   ├─ SAN: *.kimmyai.io
   └─ Validation: DNS

3. ACM generates DNS validation records
   ├─ Record Name: _abc123.kimmyai.io
   ├─ Record Type: CNAME
   └─ Record Value: _xyz789.acm-validations.aws.

4. Create DNS validation records in Route 53
   └─ Terraform automatically adds CNAME records

5. Wait for DNS propagation (30-60 seconds)

6. ACM validates ownership (5-10 minutes)
   └─ Certificate status: PENDING_VALIDATION → ISSUED

7. Certificate ARN available for CloudFront
```

### 3.4 Certificate Validation Record Example

**DNS Validation Record**:
```
Name:  _1234567890abcdef.kimmyai.io
Type:  CNAME
Value: _abcdef1234567890.acm-validations.aws.
TTL:   60 seconds
```

**Note**: Terraform automatically creates these records when using `aws_acm_certificate` resource with DNS validation.

### 3.5 Certificate Usage in CloudFront

```hcl
resource "aws_cloudfront_distribution" "dev" {
  # ... other configuration ...

  viewer_certificate {
    acm_certificate_arn      = local.certificate_arn
    ssl_support_method       = "sni-only"  # Cost-effective option
    minimum_protocol_version = "TLSv1.2_2021"
  }

  aliases = ["dev.kimmyai.io"]
}
```

---

## 4. Basic Auth Implementation

### 4.1 Requirements Summary

**Implementation**: Lambda@Edge function triggered on Viewer Request
**Runtime**: Node.js 18.x (latest supported for Lambda@Edge)
**Memory**: 128 MB (maximum for Viewer Request)
**Timeout**: 5 seconds (maximum for Viewer Request)
**Region**: Must be deployed in **us-east-1**
**Deployment**: All environments (DEV, SIT, PROD)
**PROD Status**: ENABLED initially, manually disabled before go-live

### 4.2 Authentication Flow

```
┌─────────────┐
│ User Browser│
└──────┬──────┘
       │
       │ GET https://dev.kimmyai.io/buy
       │
       ▼
┌─────────────────────────────────────────────────────┐
│           CloudFront Distribution                   │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │ Lambda@Edge (Viewer Request Trigger)         │  │
│  │                                              │  │
│  │  1. Check Authorization header               │  │
│  │     │                                        │  │
│  │     ├─ Header exists?                        │  │
│  │     │   │                                    │  │
│  │     │   ├─ YES → Decode Base64              │  │
│  │     │   │          │                         │  │
│  │     │   │          ├─ Extract username:password │
│  │     │   │          │                         │  │
│  │     │   │          ├─ Validate credentials  │  │
│  │     │   │          │   │                     │  │
│  │     │   │          │   ├─ VALID → ALLOW     │  │
│  │     │   │          │   │   (return request) │  │
│  │     │   │          │   │                     │  │
│  │     │   │          │   └─ INVALID → 401     │  │
│  │     │   │                                    │  │
│  │     │   └─ NO → Return 401 Unauthorized     │  │
│  │     │           with WWW-Authenticate header│  │
│  └──────────────────────────────────────────────┘  │
│         │                │                          │
│         │ ALLOW          │ 401                      │
└─────────┼────────────────┼──────────────────────────┘
          │                │
          ▼                ▼
    ┌─────────┐      ┌──────────────┐
    │ S3/OAC  │      │ Auth Prompt  │
    │ Content │      │ (Browser)    │
    └─────────┘      └──────────────┘
```

### 4.3 Lambda@Edge Function Structure

#### 4.3.1 Function Code (Node.js 18.x)

```javascript
/**
 * Lambda@Edge Basic Authentication
 * Event: Viewer Request
 * Region: us-east-1
 * Runtime: Node.js 18.x
 */

// Environment-specific credentials
// NOTE: Lambda@Edge does NOT support environment variables
// Credentials must be embedded or fetched from Secrets Manager
const CREDENTIALS = {
  dev: { username: 'dev', password: 'devpassword' },
  sit: { username: 'sit', password: 'sitpassword' },
  prod: { username: 'prod', password: 'prodpassword' }
};

// Determine environment from domain
function getEnvironment(host) {
  if (host.startsWith('dev.')) return 'dev';
  if (host.startsWith('sit.')) return 'sit';
  return 'prod';
}

exports.handler = async (event) => {
  const request = event.Records[0].cf.request;
  const headers = request.headers;

  // Extract host to determine environment
  const host = headers.host[0].value;
  const env = getEnvironment(host);

  // Get credentials for this environment
  const validCredentials = CREDENTIALS[env];

  // Check if Authorization header exists
  const authHeader = headers.authorization;

  if (!authHeader) {
    // No auth header - return 401 with WWW-Authenticate header
    return {
      status: '401',
      statusDescription: 'Unauthorized',
      headers: {
        'www-authenticate': [{
          key: 'WWW-Authenticate',
          value: `Basic realm="${env.toUpperCase()} Environment"`
        }],
        'content-type': [{
          key: 'Content-Type',
          value: 'text/plain'
        }]
      },
      body: 'Unauthorized - Authentication Required'
    };
  }

  // Extract and decode Basic Auth credentials
  const authValue = authHeader[0].value;
  const encodedCreds = authValue.replace('Basic ', '');
  const decodedCreds = Buffer.from(encodedCreds, 'base64').toString('utf-8');
  const [username, password] = decodedCreds.split(':');

  // Validate credentials
  if (
    username === validCredentials.username &&
    password === validCredentials.password
  ) {
    // Valid credentials - allow request to proceed
    return request;
  } else {
    // Invalid credentials - return 401
    return {
      status: '401',
      statusDescription: 'Unauthorized',
      headers: {
        'www-authenticate': [{
          key: 'WWW-Authenticate',
          value: `Basic realm="${env.toUpperCase()} Environment"`
        }],
        'content-type': [{
          key: 'Content-Type',
          value: 'text/plain'
        }]
      },
      body: 'Unauthorized - Invalid Credentials'
    };
  }
};
```

#### 4.3.2 Alternative: Secrets Manager Integration (Recommended for Production)

```javascript
/**
 * Lambda@Edge with AWS Secrets Manager
 * NOTE: Fetch secrets at function initialization (cold start) and cache
 */

const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');

const client = new SecretsManagerClient({ region: 'us-east-1' });

// Cache credentials (fetched once during cold start)
let cachedCredentials = null;

async function getCredentials() {
  if (cachedCredentials) {
    return cachedCredentials;
  }

  const command = new GetSecretValueCommand({
    SecretId: 'bbws/basic-auth/credentials'
  });

  const response = await client.send(command);
  cachedCredentials = JSON.parse(response.SecretString);
  return cachedCredentials;
}

exports.handler = async (event) => {
  const request = event.Records[0].cf.request;
  const headers = request.headers;

  // Fetch credentials (cached after first call)
  const credentials = await getCredentials();

  // ... rest of authentication logic (same as above)
};
```

### 4.4 Credentials Management

#### 4.4.1 Environment-Specific Credentials

| Environment | Username | Password | Storage Method |
|-------------|----------|----------|----------------|
| **DEV** | `dev` | `devpassword` | Embedded in Lambda or Secrets Manager |
| **SIT** | `sit` | `sitpassword` | Embedded in Lambda or Secrets Manager |
| **PROD** | `prod` | `prodpassword` | **Secrets Manager (recommended)** |

#### 4.4.2 Secrets Manager Structure

**Secret Name**: `bbws/basic-auth/credentials`
**Secret Type**: JSON

**Secret Value**:
```json
{
  "dev": {
    "username": "dev",
    "password": "devpassword"
  },
  "sit": {
    "username": "sit",
    "password": "sitpassword"
  },
  "prod": {
    "username": "prod",
    "password": "prodpassword"
  }
}
```

**Create Secret (AWS CLI)**:
```bash
aws secretsmanager create-secret \
  --region us-east-1 \
  --name bbws/basic-auth/credentials \
  --description "Basic Auth credentials for CloudFront distributions" \
  --secret-string '{
    "dev": {"username": "dev", "password": "devpassword"},
    "sit": {"username": "sit", "password": "sitpassword"},
    "prod": {"username": "prod", "password": "prodpassword"}
  }'
```

### 4.5 Enable/Disable Configuration

#### 4.5.1 Terraform Variable for Basic Auth Control

```hcl
variable "enable_basic_auth" {
  description = "Enable Basic Authentication for environments"
  type        = map(bool)
  default = {
    dev  = true
    sit  = true
    prod = true  # Change to false before go-live
  }
}

# Conditional Lambda@Edge association
resource "aws_cloudfront_distribution" "main" {
  # ... other configuration ...

  dynamic "lambda_function_association" {
    for_each = var.enable_basic_auth[var.environment] ? [1] : []

    content {
      event_type   = "viewer-request"
      lambda_arn   = "${aws_lambda_function.basic_auth.arn}:${aws_lambda_function.basic_auth.version}"
      include_body = false
    }
  }
}
```

#### 4.5.2 Disabling Basic Auth for PROD

**Step 1**: Update `terraform/environments/prod.tfvars`:
```hcl
enable_basic_auth = {
  dev  = true
  sit  = true
  prod = false  # Changed from true to false
}
```

**Step 2**: Apply Terraform changes:
```bash
cd terraform
terraform plan -var-file=environments/prod.tfvars
terraform apply -var-file=environments/prod.tfvars
```

**Step 3**: Invalidate CloudFront cache:
```bash
aws cloudfront create-invalidation \
  --distribution-id <PROD_DISTRIBUTION_ID> \
  --paths "/*"
```

**Step 4**: Verify Basic Auth disabled:
```bash
curl -I https://kimmyai.io/buy
# Should return 200 OK without authentication prompt
```

### 4.6 Lambda@Edge Deployment Requirements

| Requirement | Value | Notes |
|-------------|-------|-------|
| **Region** | us-east-1 | REQUIRED for Lambda@Edge |
| **Runtime** | Node.js 18.x | Latest supported |
| **Memory** | 128 MB | Maximum for Viewer Request |
| **Timeout** | 5 seconds | Maximum for Viewer Request |
| **IAM Role** | Lambda execution + CloudFront association | See below |
| **Environment Variables** | NOT SUPPORTED | Use embedded or Secrets Manager |
| **Versioning** | REQUIRED | Must publish version for association |

#### 4.6.1 IAM Role for Lambda@Edge

```hcl
# Trust policy for Lambda@Edge
data "aws_iam_policy_document" "lambda_edge_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
        "edgelambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "lambda_edge" {
  name               = "basic-auth-lambda-edge-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_edge_assume_role.json
}

# Attach CloudWatch Logs policy
resource "aws_iam_role_policy_attachment" "lambda_edge_logs" {
  role       = aws_iam_role.lambda_edge.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# If using Secrets Manager, add policy
resource "aws_iam_role_policy" "secrets_manager" {
  name = "secrets-manager-access"
  role = aws_iam_role.lambda_edge.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:us-east-1:*:secret:bbws/basic-auth/credentials-*"
      }
    ]
  })
}
```

---

## 5. CloudFront Security Configuration

### 5.1 Overview

CloudFront distributions will implement multiple security layers:

1. **HTTPS Enforcement** - Redirect HTTP to HTTPS
2. **TLS 1.2+ Minimum** - Modern encryption protocols
3. **Origin Access Control (OAC)** - Secure S3 access (replaces deprecated OAI)
4. **Basic Auth** - Lambda@Edge viewer request authentication
5. **Security Headers** - HSTS, CSP, X-Frame-Options, etc.
6. **Cache Security** - Proper cache key and origin request policies

### 5.2 HTTPS Configuration

#### 5.2.1 Viewer Protocol Policy

```hcl
resource "aws_cloudfront_distribution" "main" {
  # ... other configuration ...

  # Default cache behavior
  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"  # Force HTTPS
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${var.environment}"
    compress               = true

    # Modern cache policy
    cache_policy_id          = aws_cloudfront_cache_policy.default.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.default.id
  }

  # SSL/TLS configuration
  viewer_certificate {
    acm_certificate_arn      = local.certificate_arn
    ssl_support_method       = "sni-only"  # Cost-effective
    minimum_protocol_version = "TLSv1.2_2021"  # TLS 1.2+ only
  }
}
```

#### 5.2.2 Supported TLS Versions

| Version | Support | Rationale |
|---------|---------|-----------|
| **TLSv1.2_2021** | ✅ Recommended | Modern, secure, widely supported |
| TLSv1.2_2019 | ⚠️  Acceptable | Slightly older cipher suites |
| TLSv1.1 | ❌ Not recommended | Deprecated, insecure |
| SSLv3 | ❌ Blocked | Critically insecure |

### 5.3 Origin Access Control (OAC) - RECOMMENDED

**Important**: AWS recommends using **Origin Access Control (OAC)** instead of the deprecated Origin Access Identity (OAI) as of 2025.

#### 5.3.1 Why OAC Over OAI?

| Feature | OAC | OAI (Deprecated) |
|---------|-----|------------------|
| **SSE-KMS Support** | ✅ Yes | ❌ No |
| **All AWS Regions** | ✅ Yes | ❌ Limited |
| **PUT/POST/DELETE** | ✅ Yes | ❌ No |
| **Short-term Credentials** | ✅ Yes | ❌ No (long-lived) |
| **Frequent Rotation** | ✅ Yes | ❌ No |
| **Resource Policies** | ✅ Granular | ⚠️  Limited |

#### 5.3.2 OAC Configuration

```hcl
# Create Origin Access Control
resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "bbws-${var.environment}-oac"
  description                       = "OAC for ${var.environment} S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront distribution with OAC
resource "aws_cloudfront_distribution" "main" {
  # ... other configuration ...

  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "S3-${var.environment}"
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }
}

# S3 bucket policy to allow ONLY CloudFront OAC
resource "aws_s3_bucket_policy" "cloudfront_oac" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.main.arn
          }
        }
      }
    ]
  })
}

# S3 bucket - Block ALL public access
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### 5.4 Custom Domain Setup

```hcl
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "BBWS ${var.environment} distribution"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"  # US, Canada, Europe

  # Alternate domain names (CNAMEs)
  aliases = var.environment == "prod" ? [
    "kimmyai.io",
    "www.kimmyai.io"
  ] : [
    "${var.environment}.kimmyai.io"
  ]

  # ... rest of configuration ...
}
```

### 5.5 Cache Behaviors

```hcl
# Cache policy for static content
resource "aws_cloudfront_cache_policy" "default" {
  name        = "bbws-${var.environment}-cache-policy"
  comment     = "Cache policy for ${var.environment}"
  default_ttl = 86400   # 24 hours
  max_ttl     = 31536000 # 1 year
  min_ttl     = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }

    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

# Origin request policy
resource "aws_cloudfront_origin_request_policy" "default" {
  name    = "bbws-${var.environment}-origin-request-policy"
  comment = "Origin request policy for ${var.environment}"

  cookies_config {
    cookie_behavior = "none"
  }
  headers_config {
    header_behavior = "none"
  }
  query_strings_config {
    query_string_behavior = "none"
  }
}
```

### 5.6 Security Headers

Implement security headers using **CloudFront Functions** (lighter weight than Lambda@Edge):

```javascript
/**
 * CloudFront Function: Add Security Headers
 * Event: Viewer Response
 */

function handler(event) {
  var response = event.response;
  var headers = response.headers;

  // Strict-Transport-Security (HSTS)
  headers['strict-transport-security'] = {
    value: 'max-age=31536000; includeSubDomains; preload'
  };

  // X-Content-Type-Options
  headers['x-content-type-options'] = {
    value: 'nosniff'
  };

  // X-Frame-Options
  headers['x-frame-options'] = {
    value: 'DENY'
  };

  // X-XSS-Protection
  headers['x-xss-protection'] = {
    value: '1; mode=block'
  };

  // Content-Security-Policy
  headers['content-security-policy'] = {
    value: "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https://api.kimmyai.io https://dev.api.kimmyai.io https://sit.api.kimmyai.io;"
  };

  // Referrer-Policy
  headers['referrer-policy'] = {
    value: 'strict-origin-when-cross-origin'
  };

  // Permissions-Policy
  headers['permissions-policy'] = {
    value: 'geolocation=(), microphone=(), camera=()'
  };

  return response;
}
```

**Terraform Configuration**:
```hcl
resource "aws_cloudfront_function" "security_headers" {
  name    = "bbws-${var.environment}-security-headers"
  runtime = "cloudfront-js-2.0"
  comment = "Add security headers to responses"
  publish = true
  code    = file("${path.module}/functions/security-headers.js")
}

resource "aws_cloudfront_distribution" "main" {
  # ... other configuration ...

  default_cache_behavior {
    # ... other settings ...

    function_association {
      event_type   = "viewer-response"
      function_arn = aws_cloudfront_function.security_headers.arn
    }
  }
}
```

### 5.7 Lambda@Edge Association

```hcl
resource "aws_cloudfront_distribution" "main" {
  # ... other configuration ...

  default_cache_behavior {
    # ... other settings ...

    # Basic Auth Lambda@Edge (Viewer Request)
    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = "${aws_lambda_function.basic_auth.qualified_arn}"
      include_body = false
    }

    # Security Headers CloudFront Function (Viewer Response)
    function_association {
      event_type   = "viewer-response"
      function_arn = aws_cloudfront_function.security_headers.arn
    }
  }
}
```

### 5.8 Custom Error Pages

```hcl
resource "aws_cloudfront_distribution" "main" {
  # ... other configuration ...

  # SPA routing: redirect 404/403 to index.html
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
    error_caching_min_ttl = 10
  }
}
```

---

## 6. Deployment Sequence

### 6.1 Correct Deployment Order

The following sequence ensures dependencies are met and minimizes deployment issues:

```
1. Route 53 Hosted Zone
   ├─ Check if kimmyai.io hosted zone exists
   ├─ If not exists → Create hosted zone (or verify at registrar)
   └─ Capture HostedZoneId

2. ACM Certificate (us-east-1)
   ├─ Check for existing certificate (*.kimmyai.io, kimmyai.io)
   │  └─ Use Terraform data source: aws_acm_certificate
   ├─ If EXISTS → Capture ARN → Skip to Step 3
   └─ If NOT EXISTS:
       ├─ Create ACM certificate request
       ├─ ACM generates DNS validation records
       ├─ Create DNS CNAME records in Route 53
       ├─ Wait for DNS propagation (30-60 seconds)
       └─ Wait for ACM validation (5-10 minutes)

3. Certificate Validation Complete
   └─ Certificate Status: ISSUED

4. S3 Buckets
   ├─ Create S3 bucket (2-bbws-web-public-{env})
   ├─ Enable versioning
   ├─ Block ALL public access
   ├─ Configure server-side encryption (AES-256)
   └─ Add bucket policy for CloudFront OAC (will be created in Step 6)

5. Basic Auth Lambda@Edge (us-east-1)
   ├─ Create Lambda execution role
   ├─ Create Lambda function
   ├─ Deploy function code
   ├─ Publish Lambda version (REQUIRED for Lambda@Edge)
   └─ Grant CloudFront permission to invoke

6. CloudFront Distributions
   ├─ Create Origin Access Control (OAC)
   ├─ Create CloudFront distribution
   │  ├─ Configure S3 origin with OAC
   │  ├─ Set alternate domain names (CNAMEs)
   │  ├─ Attach ACM certificate
   │  ├─ Configure viewer protocol policy (redirect-to-https)
   │  ├─ Set TLS minimum version (TLSv1.2_2021)
   │  ├─ Associate Lambda@Edge (viewer-request)
   │  ├─ Associate CloudFront Function (viewer-response for headers)
   │  └─ Configure cache behaviors
   ├─ Wait for distribution deployment (15-20 minutes)
   └─ Capture CloudFront domain name

7. Update S3 Bucket Policy
   ├─ Add CloudFront OAC permissions
   └─ Apply bucket policy

8. Route 53 DNS Records
   ├─ Create A record (ALIAS to CloudFront)
   ├─ Create AAAA record (ALIAS to CloudFront)
   └─ Wait for DNS propagation (30-60 seconds)

9. Deploy Frontend Assets
   ├─ Build React application (npm run build)
   ├─ Sync build files to S3 bucket
   └─ Verify files uploaded

10. CloudFront Cache Invalidation
    ├─ Invalidate /* (all paths)
    └─ Wait for invalidation complete (5-10 minutes)

11. Validation & Testing
    ├─ Test DNS resolution
    ├─ Test HTTPS certificate
    ├─ Test Basic Auth
    ├─ Test application load
    └─ Verify security headers
```

### 6.2 Dependency Graph

```
Route 53 Hosted Zone ──────────────┐
                                   │
                                   ├──> ACM Certificate DNS Validation
                                   │
                                   └──> DNS Records (A/AAAA ALIAS)
                                           │
ACM Certificate (ISSUED) ──────────────┐  │
                                       │  │
S3 Bucket ──────────────────────────┐  │  │
                                    │  │  │
Lambda@Edge (Published) ────────┐   │  │  │
                                │   │  │  │
                                └───┴──┴──┴──> CloudFront Distribution
                                                       │
                                                       ├──> Frontend Deploy
                                                       │
                                                       └──> Cache Invalidation
```

### 6.3 Terraform Apply Sequence

```bash
# Step 1: Initialize Terraform
terraform init

# Step 2: Plan for environment (e.g., DEV)
terraform plan -var-file=environments/dev.tfvars -out=dev.tfplan

# Step 3: Review plan carefully
# Ensure it's checking for existing ACM certificate

# Step 4: Apply infrastructure
terraform apply dev.tfplan

# Step 5: Wait for CloudFront distribution deployment
# Monitor with:
aws cloudfront get-distribution \
  --id <DISTRIBUTION_ID> \
  --query "Distribution.Status" \
  --output text

# Step 6: Deploy frontend assets (after distribution is deployed)
npm run build
aws s3 sync ./dist s3://2-bbws-web-public-dev --delete

# Step 7: Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --paths "/*"

# Step 8: Verify deployment
curl -I https://dev.kimmyai.io/buy
```

### 6.4 Validation Checkpoints

| Checkpoint | Validation Command | Expected Result |
|------------|-------------------|-----------------|
| **1. Hosted Zone Exists** | `aws route53 list-hosted-zones-by-name --dns-name kimmyai.io` | Zone ID returned |
| **2. Certificate Issued** | `aws acm describe-certificate --certificate-arn <ARN> --region us-east-1` | Status: ISSUED |
| **3. S3 Bucket Created** | `aws s3 ls \| grep bbws-web-public` | Bucket listed |
| **4. Lambda Published** | `aws lambda get-function --function-name basic-auth` | Version number |
| **5. CloudFront Deployed** | `aws cloudfront get-distribution --id <ID>` | Status: Deployed |
| **6. DNS Resolves** | `dig dev.kimmyai.io` | CloudFront IP addresses |
| **7. HTTPS Works** | `curl -I https://dev.kimmyai.io` | 401 or 200 response |
| **8. Basic Auth** | `curl -u dev:devpassword https://dev.kimmyai.io` | 200 OK |

---

## 7. Testing Procedures

### 7.1 DNS Testing

#### 7.1.1 DNS Resolution Tests

```bash
# Test DNS resolution with system resolver
nslookup dev.kimmyai.io
nslookup sit.kimmyai.io
nslookup kimmyai.io

# Test with specific DNS servers
dig @8.8.8.8 dev.kimmyai.io         # Google DNS
dig @1.1.1.1 sit.kimmyai.io         # Cloudflare DNS
dig @208.67.222.222 kimmyai.io      # OpenDNS

# Detailed DNS query
dig dev.kimmyai.io +trace

# Check both IPv4 and IPv6
dig dev.kimmyai.io A
dig dev.kimmyai.io AAAA

# Verify ALIAS records point to CloudFront
dig dev.kimmyai.io
# Expected: IP addresses from CloudFront range
```

#### 7.1.2 Expected DNS Output

```
# dig dev.kimmyai.io

;; ANSWER SECTION:
dev.kimmyai.io.     300     IN      A       13.224.XXX.XXX
dev.kimmyai.io.     300     IN      A       13.224.XXX.XXX
dev.kimmyai.io.     300     IN      A       13.224.XXX.XXX
dev.kimmyai.io.     300     IN      A       13.224.XXX.XXX
```

### 7.2 SSL Certificate Testing

#### 7.2.1 Certificate Validation Tests

```bash
# Test SSL certificate with OpenSSL
openssl s_client -connect dev.kimmyai.io:443 -servername dev.kimmyai.io

# Check certificate details
openssl s_client -connect dev.kimmyai.io:443 -servername dev.kimmyai.io \
  </dev/null 2>/dev/null | openssl x509 -noout -text

# Verify certificate chain
openssl s_client -connect dev.kimmyai.io:443 -servername dev.kimmyai.io -showcerts

# Test TLS version
openssl s_client -connect dev.kimmyai.io:443 -tls1_2 -servername dev.kimmyai.io
openssl s_client -connect dev.kimmyai.io:443 -tls1_3 -servername dev.kimmyai.io

# Check certificate expiry
echo | openssl s_client -servername dev.kimmyai.io -connect dev.kimmyai.io:443 2>/dev/null \
  | openssl x509 -noout -dates
```

#### 7.2.2 Online SSL Testing Tools

```bash
# Use SSL Labs for comprehensive analysis
# Visit: https://www.ssllabs.com/ssltest/analyze.html?d=dev.kimmyai.io
# Expected Grade: A or A+

# Alternative: Use curl with verbose output
curl -Iv https://dev.kimmyai.io 2>&1 | grep -i ssl
curl -Iv https://dev.kimmyai.io 2>&1 | grep -i tls
```

### 7.3 Basic Auth Testing

#### 7.3.1 Without Credentials (Should Fail)

```bash
# Test without credentials - should return 401
curl -I https://dev.kimmyai.io/buy

# Expected Output:
# HTTP/2 401
# www-authenticate: Basic realm="DEV Environment"
```

#### 7.3.2 With Valid Credentials (Should Succeed)

```bash
# Test with valid credentials - should return 200
curl -u dev:devpassword -I https://dev.kimmyai.io/buy

# Expected Output:
# HTTP/2 200
# content-type: text/html

# Test with credentials in URL (not recommended for production)
curl -I https://dev:devpassword@dev.kimmyai.io/buy

# Test full page load
curl -u dev:devpassword https://dev.kimmyai.io/buy
```

#### 7.3.3 With Invalid Credentials (Should Fail)

```bash
# Test with wrong password
curl -u dev:wrongpassword -I https://dev.kimmyai.io/buy

# Expected Output:
# HTTP/2 401
# www-authenticate: Basic realm="DEV Environment"

# Test with wrong username
curl -u wronguser:devpassword -I https://dev.kimmyai.io/buy

# Expected Output:
# HTTP/2 401
```

#### 7.3.4 Browser Testing

```bash
# Open in browser (will prompt for credentials)
open https://dev.kimmyai.io/buy

# Expected: Browser shows authentication prompt
# Enter username: dev
# Enter password: devpassword
# Result: Page loads successfully
```

### 7.4 HTTPS Enforcement Testing

```bash
# Test HTTP to HTTPS redirect
curl -I http://dev.kimmyai.io/buy

# Expected Output:
# HTTP/1.1 301 Moved Permanently
# Location: https://dev.kimmyai.io/buy

# Verify redirect works
curl -L http://dev.kimmyai.io/buy
# Should redirect to HTTPS and then prompt for auth
```

### 7.5 Security Headers Testing

```bash
# Check all security headers
curl -I https://dev.kimmyai.io/buy -u dev:devpassword

# Expected headers:
# strict-transport-security: max-age=31536000; includeSubDomains; preload
# x-content-type-options: nosniff
# x-frame-options: DENY
# x-xss-protection: 1; mode=block
# content-security-policy: default-src 'self'; ...
# referrer-policy: strict-origin-when-cross-origin

# Use online security header checker
# Visit: https://securityheaders.com/?q=https://dev.kimmyai.io
```

### 7.6 CloudFront Caching Testing

```bash
# Check CloudFront cache status
curl -I https://dev.kimmyai.io/buy -u dev:devpassword | grep -i x-cache

# Expected on first request:
# x-cache: Miss from cloudfront

# Expected on subsequent requests:
# x-cache: Hit from cloudfront

# Test cache invalidation
aws cloudfront create-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --paths "/buy/*"

# Verify invalidation status
aws cloudfront get-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --id <INVALIDATION_ID>
```

### 7.7 End-to-End Testing

#### 7.7.1 Full User Flow Test

```bash
#!/bin/bash
# E2E test script for DNS and security

ENV="dev"
DOMAIN="${ENV}.kimmyai.io"
USERNAME="${ENV}"
PASSWORD="${ENV}password"

echo "=== Testing ${DOMAIN} ==="

echo "1. DNS Resolution..."
dig ${DOMAIN} +short

echo "2. HTTPS Certificate..."
openssl s_client -connect ${DOMAIN}:443 -servername ${DOMAIN} </dev/null 2>/dev/null | openssl x509 -noout -subject -dates

echo "3. Basic Auth (no creds) - should fail..."
curl -I https://${DOMAIN}/buy 2>&1 | grep -E "HTTP|401"

echo "4. Basic Auth (valid creds) - should succeed..."
curl -u ${USERNAME}:${PASSWORD} -I https://${DOMAIN}/buy 2>&1 | grep -E "HTTP|200"

echo "5. Security Headers..."
curl -u ${USERNAME}:${PASSWORD} -I https://${DOMAIN}/buy 2>&1 | grep -i -E "strict-transport|x-content-type|x-frame"

echo "6. HTTP to HTTPS redirect..."
curl -I http://${DOMAIN}/buy 2>&1 | grep -E "301|Location"

echo "=== All tests complete ==="
```

#### 7.7.2 Cross-Browser Testing

**Browsers to Test**:
- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)
- Mobile Safari (iOS)
- Chrome Mobile (Android)

**Test Cases**:
1. Visit `https://dev.kimmyai.io/buy`
2. Verify Basic Auth prompt appears
3. Enter valid credentials
4. Verify page loads
5. Check browser console for errors
6. Verify HTTPS padlock icon
7. Inspect certificate details
8. Check for mixed content warnings

---

## 8. Runbook Procedures

### 8.1 Procedure: Disable Basic Auth in PROD Before Go-Live

**Purpose**: Remove Basic Authentication from PROD environment when ready for public launch.

**Prerequisites**:
- PROD infrastructure fully tested
- Approval from stakeholders
- Terraform access to PROD environment

**Procedure**:

```bash
# Step 1: Update Terraform variable file
cd terraform/environments
vim prod.tfvars

# Change:
# enable_basic_auth = true
# To:
# enable_basic_auth = false

# Step 2: Plan Terraform changes
terraform plan \
  -var-file=environments/prod.tfvars \
  -out=prod-disable-auth.tfplan

# Step 3: Review plan carefully
# Expected changes:
# - CloudFront distribution update (remove Lambda@Edge association)

# Step 4: Apply changes
terraform apply prod-disable-auth.tfplan

# Step 5: Wait for CloudFront distribution update (10-15 minutes)
aws cloudfront get-distribution \
  --id <PROD_DISTRIBUTION_ID> \
  --query "Distribution.Status" \
  --output text
# Wait until Status = Deployed

# Step 6: Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id <PROD_DISTRIBUTION_ID> \
  --paths "/*"

# Step 7: Monitor invalidation
aws cloudfront get-invalidation \
  --distribution-id <PROD_DISTRIBUTION_ID> \
  --id <INVALIDATION_ID> \
  --query "Invalidation.Status" \
  --output text
# Wait until Status = Completed

# Step 8: Verify Basic Auth disabled
curl -I https://kimmyai.io/buy
# Expected: HTTP/2 200 (no authentication prompt)

# Step 9: Test from multiple locations
curl -I https://kimmyai.io/buy --resolve kimmyai.io:443:<CLOUDFRONT_IP>

# Step 10: Browser test
open https://kimmyai.io/buy
# Expected: Page loads without authentication prompt
```

**Rollback Procedure**:
```bash
# Re-enable Basic Auth if needed
cd terraform/environments
vim prod.tfvars

# Change:
# enable_basic_auth = false
# Back to:
# enable_basic_auth = true

terraform plan -var-file=environments/prod.tfvars
terraform apply -var-file=environments/prod.tfvars
```

### 8.2 Procedure: Update Basic Auth Credentials

**Purpose**: Change Basic Authentication credentials for any environment.

**Procedure**:

#### Option 1: Update Embedded Credentials (Simplest)

```bash
# Step 1: Update Lambda function code
cd lambda/basic-auth
vim index.js

# Update credentials in CREDENTIALS object
const CREDENTIALS = {
  dev: { username: 'dev', password: 'newdevpass123' },
  sit: { username: 'sit', password: 'newsitpass123' },
  prod: { username: 'prod', password: 'newprodpass123' }
};

# Step 2: Deploy updated Lambda
terraform apply -target=aws_lambda_function.basic_auth

# Step 3: Wait for Lambda@Edge propagation (15-20 minutes)
# Lambda@Edge updates must propagate to all edge locations

# Step 4: Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --paths "/*"

# Step 5: Test with new credentials
curl -u dev:newdevpass123 -I https://dev.kimmyai.io/buy
```

#### Option 2: Update Secrets Manager (Recommended)

```bash
# Step 1: Update secret in Secrets Manager
aws secretsmanager update-secret \
  --region us-east-1 \
  --secret-id bbws/basic-auth/credentials \
  --secret-string '{
    "dev": {"username": "dev", "password": "newdevpass123"},
    "sit": {"username": "sit", "password": "newsitpass123"},
    "prod": {"username": "prod", "password": "newprodpass123"}
  }'

# Step 2: Verify secret updated
aws secretsmanager get-secret-value \
  --region us-east-1 \
  --secret-id bbws/basic-auth/credentials \
  --query SecretString \
  --output text

# Step 3: Invalidate Lambda@Edge function cache
# Force new Lambda execution by invalidating CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --paths "/*"

# Step 4: Test with new credentials
curl -u dev:newdevpass123 -I https://dev.kimmyai.io/buy
```

### 8.3 Procedure: Troubleshoot DNS Issues

**Symptoms**: Domain not resolving, DNS timeout, incorrect IP addresses.

**Diagnosis**:

```bash
# Step 1: Check Route 53 hosted zone
aws route53 list-hosted-zones-by-name \
  --dns-name kimmyai.io \
  --query "HostedZones[0]"

# Step 2: List DNS records
aws route53 list-resource-record-sets \
  --hosted-zone-id <HOSTED_ZONE_ID> \
  --query "ResourceRecordSets[?Name=='dev.kimmyai.io.']"

# Step 3: Verify ALIAS target
dig dev.kimmyai.io
# Should show CloudFront IP addresses

# Step 4: Check CloudFront distribution status
aws cloudfront get-distribution \
  --id <DISTRIBUTION_ID> \
  --query "Distribution.Status"

# Step 5: Test DNS from multiple servers
dig @8.8.8.8 dev.kimmyai.io       # Google
dig @1.1.1.1 dev.kimmyai.io       # Cloudflare
dig @208.67.222.222 dev.kimmyai.io # OpenDNS
```

**Common Issues**:

| Issue | Cause | Solution |
|-------|-------|----------|
| DNS not resolving | ALIAS record not created | Create Route 53 ALIAS record |
| Wrong IP addresses | ALIAS points to wrong target | Update ALIAS to correct CloudFront domain |
| Slow propagation | DNS caching | Wait 5 minutes, flush local DNS cache |
| NXDOMAIN error | Hosted zone doesn't exist | Create hosted zone or check domain registrar |

### 8.4 Procedure: Renew ACM Certificate

**Note**: ACM certificates with DNS validation renew automatically. Manual renewal is rarely needed.

**Automatic Renewal**:
- ACM automatically renews certificates 60 days before expiry
- DNS validation records must remain in Route 53
- No manual action required

**Verify Certificate Renewal Status**:

```bash
# Check certificate status
aws acm describe-certificate \
  --region us-east-1 \
  --certificate-arn <CERTIFICATE_ARN> \
  --query "Certificate.{Status:Status, NotAfter:NotAfter, RenewalEligibility:RenewalEligibility}" \
  --output table

# Expected output:
# Status: ISSUED
# RenewalEligibility: ELIGIBLE
```

**Manual Renewal (if automatic fails)**:

```bash
# Step 1: Request new certificate
aws acm request-certificate \
  --region us-east-1 \
  --domain-name kimmyai.io \
  --subject-alternative-names "*.kimmyai.io" \
  --validation-method DNS

# Step 2: Get validation records
aws acm describe-certificate \
  --region us-east-1 \
  --certificate-arn <NEW_CERTIFICATE_ARN> \
  --query "Certificate.DomainValidationOptions"

# Step 3: Add DNS validation records to Route 53
# (Terraform automatically handles this)

# Step 4: Wait for validation
aws acm wait certificate-validated \
  --region us-east-1 \
  --certificate-arn <NEW_CERTIFICATE_ARN>

# Step 5: Update CloudFront distribution with new certificate ARN
terraform apply -var="certificate_arn=<NEW_CERTIFICATE_ARN>"
```

### 8.5 Procedure: CloudFront Cache Invalidation

**Purpose**: Clear cached content from CloudFront edge locations.

**When to Invalidate**:
- After deploying new frontend code
- After changing Lambda@Edge function
- After updating security headers
- After disabling Basic Auth

**Procedure**:

```bash
# Invalidate all paths (most common)
aws cloudfront create-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --paths "/*"

# Invalidate specific paths
aws cloudfront create-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --paths "/buy/*" "/assets/*"

# Monitor invalidation status
aws cloudfront get-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --id <INVALIDATION_ID>

# List all invalidations
aws cloudfront list-invalidations \
  --distribution-id <DISTRIBUTION_ID>
```

**Cost Considerations**:
- First 1,000 invalidation paths per month: FREE
- Additional paths: $0.005 per path
- Use versioned file names to avoid frequent invalidations

### 8.6 Procedure: Emergency Rollback

**Scenario**: Critical issue in PROD, need immediate rollback.

**Procedure**:

```bash
# Step 1: Identify last known good Terraform state
cd terraform
terraform state list

# Step 2: Revert to previous Terraform configuration
git log --oneline
git checkout <LAST_GOOD_COMMIT>

# Step 3: Plan rollback
terraform plan -var-file=environments/prod.tfvars

# Step 4: Apply rollback
terraform apply -var-file=environments/prod.tfvars

# Step 5: Deploy previous frontend version
aws s3 sync s3://backup-bucket/last-good-build s3://2-bbws-web-public-prod --delete

# Step 6: Invalidate cache
aws cloudfront create-invalidation \
  --distribution-id <PROD_DISTRIBUTION_ID> \
  --paths "/*"

# Step 7: Verify rollback
curl -I https://kimmyai.io/buy
```

---

## 9. Summary & Key Takeaways

### 9.1 Critical Requirements Checklist

- [ ] **ACM Certificate**: Check for existing certificate BEFORE creating new one
- [ ] **Certificate Region**: Must be in us-east-1 for CloudFront
- [ ] **DNS Records**: Use A/AAAA ALIAS records (not CNAME for apex)
- [ ] **Basic Auth**: ALL environments (dev, sit, prod) have Basic Auth ENABLED
- [ ] **PROD Basic Auth**: Will be manually disabled before go-live
- [ ] **S3 Security**: Use OAC (not deprecated OAI) for S3 access
- [ ] **S3 Public Access**: Block ALL public access on S3 buckets
- [ ] **HTTPS**: Enforce HTTPS everywhere (redirect HTTP)
- [ ] **TLS Version**: Minimum TLSv1.2_2021
- [ ] **Security Headers**: Implement via CloudFront Function

### 9.2 Environment Configuration Summary

| Environment | Domain | Basic Auth | Credentials | Deployment |
|-------------|--------|------------|-------------|------------|
| **DEV** | dev.kimmyai.io | ✅ ENABLED | dev/devpassword | Auto on `develop` branch |
| **SIT** | sit.kimmyai.io | ✅ ENABLED | sit/sitpassword | Auto on `staging` branch |
| **PROD** | kimmyai.io | ✅ ENABLED* | prod/prodpassword | Manual approval required |

**Note**: PROD Basic Auth disabled before go-live via Terraform variable.

### 9.3 Terraform Code Snippets Summary

**Key Terraform Patterns**:

1. **Check Existing ACM Certificate**:
   ```hcl
   data "aws_acm_certificate" "existing" {
     provider = aws.us_east_1
     domain   = "kimmyai.io"
     statuses = ["ISSUED"]
     most_recent = true
   }
   ```

2. **Conditional Certificate Creation**:
   ```hcl
   resource "aws_acm_certificate" "main" {
     count = data.aws_acm_certificate.existing.arn == null ? 1 : 0
     # ... configuration ...
   }
   ```

3. **OAC for S3 Security**:
   ```hcl
   resource "aws_cloudfront_origin_access_control" "main" {
     origin_access_control_origin_type = "s3"
     signing_behavior = "always"
     signing_protocol = "sigv4"
   }
   ```

4. **Basic Auth Control**:
   ```hcl
   variable "enable_basic_auth" {
     type = map(bool)
     default = {
       dev  = true
       sit  = true
       prod = true  # Change to false before go-live
     }
   }
   ```

### 9.4 AWS CLI Commands Reference

**Quick Reference**:

```bash
# Check ACM certificate
aws acm list-certificates --region us-east-1

# Check Route 53 records
aws route53 list-resource-record-sets --hosted-zone-id <ID>

# Check CloudFront distribution
aws cloudfront get-distribution --id <ID>

# Invalidate cache
aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"

# Test Basic Auth
curl -u dev:devpassword -I https://dev.kimmyai.io/buy
```

---

**Document Status**: COMPLETE
**Created**: 2025-12-30
**Worker**: worker-3-dns-security
**Stage**: Stage 1 - Requirements & Design Analysis
