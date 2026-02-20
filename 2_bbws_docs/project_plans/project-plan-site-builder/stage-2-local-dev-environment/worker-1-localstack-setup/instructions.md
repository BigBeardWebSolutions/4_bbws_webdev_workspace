# Worker 1: LocalStack Setup

**Worker**: worker-1-localstack-setup
**Stage**: Stage 2 - Local Development Environment
**Status**: PENDING

---

## Task Description

Configure LocalStack to emulate AWS DynamoDB and S3 services locally. Create initialization scripts that automatically provision all required tables and buckets on container startup.

---

## Inputs

| Input | Location | Purpose |
|-------|----------|---------|
| DynamoDB Table Schemas | `3.1.2_LLD_Site_Builder_Generation_API.md` Section 6 | Table definitions |
| S3 Bucket Requirements | `3.1.2_LLD_Site_Builder_Generation_API.md` Section 8.7 | Bucket configurations |

---

## Deliverables

### 1. Docker Compose File

**File**: `local-dev/docker-compose.localstack.yml`

```yaml
version: '3.8'

services:
  localstack:
    image: localstack/localstack:latest
    container_name: bbws-localstack
    ports:
      - "4566:4566"           # LocalStack Gateway
      - "4510-4559:4510-4559" # External services
    environment:
      - SERVICES=dynamodb,s3
      - DEBUG=1
      - DATA_DIR=/var/lib/localstack/data
      - DOCKER_HOST=unix:///var/run/docker.sock
    volumes:
      - "./localstack/init-dynamodb.sh:/etc/localstack/init/ready.d/init-dynamodb.sh"
      - "./localstack/init-s3.sh:/etc/localstack/init/ready.d/init-s3.sh"
      - "localstack-data:/var/lib/localstack"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4566/_localstack/health"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  localstack-data:
```

### 2. DynamoDB Initialization Script

**File**: `local-dev/localstack/init-dynamodb.sh`

```bash
#!/bin/bash

echo "Creating DynamoDB tables..."

# Tenants Table
awslocal dynamodb create-table \
    --table-name bbws-site-builder-tenants-dev \
    --attribute-definitions \
        AttributeName=tenant_id,AttributeType=S \
        AttributeName=created_at,AttributeType=S \
    --key-schema \
        AttributeName=tenant_id,KeyType=HASH \
    --global-secondary-indexes \
        '[{"IndexName":"created_at-index","KeySchema":[{"AttributeName":"created_at","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"}}]' \
    --billing-mode PAY_PER_REQUEST

# Users Table
awslocal dynamodb create-table \
    --table-name bbws-site-builder-users-dev \
    --attribute-definitions \
        AttributeName=tenant_id,AttributeType=S \
        AttributeName=user_id,AttributeType=S \
        AttributeName=email,AttributeType=S \
    --key-schema \
        AttributeName=tenant_id,KeyType=HASH \
        AttributeName=user_id,KeyType=RANGE \
    --global-secondary-indexes \
        '[{"IndexName":"email-index","KeySchema":[{"AttributeName":"email","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"}}]' \
    --billing-mode PAY_PER_REQUEST

# Sites Table
awslocal dynamodb create-table \
    --table-name bbws-site-builder-sites-dev \
    --attribute-definitions \
        AttributeName=tenant_id,AttributeType=S \
        AttributeName=site_id,AttributeType=S \
        AttributeName=status,AttributeType=S \
    --key-schema \
        AttributeName=tenant_id,KeyType=HASH \
        AttributeName=site_id,KeyType=RANGE \
    --global-secondary-indexes \
        '[{"IndexName":"status-index","KeySchema":[{"AttributeName":"tenant_id","KeyType":"HASH"},{"AttributeName":"status","KeyType":"RANGE"}],"Projection":{"ProjectionType":"ALL"}}]' \
    --billing-mode PAY_PER_REQUEST

# Generations Table
awslocal dynamodb create-table \
    --table-name bbws-site-builder-generations-dev \
    --attribute-definitions \
        AttributeName=generation_id,AttributeType=S \
        AttributeName=site_id,AttributeType=S \
    --key-schema \
        AttributeName=generation_id,KeyType=HASH \
    --global-secondary-indexes \
        '[{"IndexName":"site-index","KeySchema":[{"AttributeName":"site_id","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"}}]' \
    --billing-mode PAY_PER_REQUEST

# Deployments Table
awslocal dynamodb create-table \
    --table-name bbws-site-builder-deployments-dev \
    --attribute-definitions \
        AttributeName=deployment_id,AttributeType=S \
        AttributeName=site_id,AttributeType=S \
    --key-schema \
        AttributeName=deployment_id,KeyType=HASH \
    --global-secondary-indexes \
        '[{"IndexName":"site-index","KeySchema":[{"AttributeName":"site_id","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"}}]' \
    --billing-mode PAY_PER_REQUEST

# Partners Table
awslocal dynamodb create-table \
    --table-name bbws-site-builder-partners-dev \
    --attribute-definitions \
        AttributeName=partner_id,AttributeType=S \
    --key-schema \
        AttributeName=partner_id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST

echo "DynamoDB tables created successfully!"
awslocal dynamodb list-tables
```

### 3. S3 Initialization Script

**File**: `local-dev/localstack/init-s3.sh`

```bash
#!/bin/bash

echo "Creating S3 buckets..."

# Brand Assets Bucket
awslocal s3 mb s3://bbws-site-builder-brand-assets-dev
awslocal s3api put-bucket-cors --bucket bbws-site-builder-brand-assets-dev \
    --cors-configuration '{"CORSRules":[{"AllowedHeaders":["*"],"AllowedMethods":["GET","PUT","POST"],"AllowedOrigins":["http://localhost:5173"],"MaxAgeSeconds":3600}]}'

# Generated Sites Bucket
awslocal s3 mb s3://bbws-site-builder-sites-dev

# Staging Bucket
awslocal s3 mb s3://bbws-site-builder-staging-dev

# Agent Prompts Bucket
awslocal s3 mb s3://bbws-site-builder-prompts-dev

echo "S3 buckets created successfully!"
awslocal s3 ls
```

---

## Expected Output Format

**File**: `local-dev/localstack/output.md`

```markdown
# LocalStack Setup Output

## Tables Created
- [x] bbws-site-builder-tenants-dev
- [x] bbws-site-builder-users-dev
- [x] bbws-site-builder-sites-dev
- [x] bbws-site-builder-generations-dev
- [x] bbws-site-builder-deployments-dev
- [x] bbws-site-builder-partners-dev

## Buckets Created
- [x] bbws-site-builder-brand-assets-dev
- [x] bbws-site-builder-sites-dev
- [x] bbws-site-builder-staging-dev
- [x] bbws-site-builder-prompts-dev

## Verification Commands
\`\`\`bash
awslocal dynamodb list-tables
awslocal s3 ls
\`\`\`
```

---

## Success Criteria

- [ ] Docker Compose file starts LocalStack successfully
- [ ] All 6 DynamoDB tables created on startup
- [ ] All 4 S3 buckets created on startup
- [ ] Tables have correct key schemas and GSIs
- [ ] S3 buckets have CORS configured for localhost
- [ ] Health check passes
- [ ] Scripts are idempotent (can run multiple times)

---

## Execution Steps

1. Create `local-dev/` directory structure
2. Write `docker-compose.localstack.yml`
3. Write `init-dynamodb.sh` with all table definitions
4. Write `init-s3.sh` with all bucket definitions
5. Make scripts executable: `chmod +x *.sh`
6. Test with `docker-compose -f docker-compose.localstack.yml up`
7. Verify tables: `awslocal dynamodb list-tables`
8. Verify buckets: `awslocal s3 ls`
9. Document output in `output.md`
10. Update work.state to COMPLETE

---

## Environment Variables

```bash
# LocalStack endpoint for other services
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=af-south-1
```
