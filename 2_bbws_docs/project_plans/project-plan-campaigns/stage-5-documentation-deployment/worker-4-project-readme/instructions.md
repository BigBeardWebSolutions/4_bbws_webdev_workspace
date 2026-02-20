# Worker Instructions: Project README

**Worker ID**: worker-4-project-readme
**Stage**: Stage 5 - Documentation & Deployment
**Project**: project-plan-campaigns

---

## Task

Create comprehensive README.md for the Campaign Lambda repository.

---

## Deliverables

### README.md

```markdown
# Campaign Management Lambda Service

Campaign Management Lambda service for the BBWS Customer Portal. Provides CRUD operations for promotional campaigns with discounts for WordPress hosting packages.

## Overview

| Attribute | Value |
|-----------|-------|
| Component | 2.1.3 Campaign Management |
| Runtime | Python 3.12 |
| Architecture | arm64 |
| Repository | `2_bbws_campaigns_lambda` |

## Features

- **List Campaigns** - Retrieve all active promotional campaigns
- **Get Campaign** - Get campaign details by code
- **Create Campaign** - Create new promotional campaigns
- **Update Campaign** - Modify existing campaigns
- **Delete Campaign** - Soft delete campaigns (set active=false)

## Architecture

```
API Gateway -> Lambda -> DynamoDB
```

**Pattern**: Direct synchronous (no SQS queues)

## Quick Start

### Prerequisites

- Python 3.12
- AWS CLI configured
- Terraform 1.5+

### Local Development

```bash
# Clone repository
git clone https://github.com/your-org/2_bbws_campaigns_lambda.git
cd 2_bbws_campaigns_lambda

# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements-dev.txt

# Run tests
pytest tests/ -v
```

### Run Tests

```bash
# Unit tests
pytest tests/unit/ -v

# Integration tests
pytest tests/integration/ -v

# With coverage
pytest tests/ --cov=src --cov-report=html
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /v1.0/campaigns | List all campaigns |
| GET | /v1.0/campaigns/{code} | Get campaign by code |
| POST | /v1.0/campaigns | Create campaign |
| PUT | /v1.0/campaigns/{code} | Update campaign |
| DELETE | /v1.0/campaigns/{code} | Delete campaign |

### Example Requests

**List Campaigns**
```bash
curl https://api.example.com/v1.0/campaigns
```

**Get Campaign**
```bash
curl https://api.example.com/v1.0/campaigns/SUMMER2025
```

**Create Campaign**
```bash
curl -X POST https://api.example.com/v1.0/campaigns \
  -H "Content-Type: application/json" \
  -d '{
    "code": "WINTER2025",
    "name": "Winter Sale",
    "productId": "PROD-001",
    "discountPercent": 25,
    "listPrice": 1000.00,
    "termsAndConditions": "Valid for all customers.",
    "fromDate": "2025-07-01T00:00:00Z",
    "toDate": "2025-08-31T23:59:59Z"
  }'
```

## Project Structure

```
2_bbws_campaigns_lambda/
├── src/
│   ├── handlers/          # Lambda handlers
│   ├── services/          # Business logic
│   ├── repositories/      # Data access
│   ├── models/            # Pydantic models
│   ├── validators/        # Input validation
│   ├── exceptions/        # Custom exceptions
│   └── utils/             # Utilities
├── tests/
│   ├── unit/              # Unit tests
│   └── integration/       # Integration tests
├── terraform/
│   ├── environments/      # Environment configs
│   └── *.tf               # Terraform modules
├── openapi/
│   └── campaigns-api.yaml # OpenAPI spec
├── scripts/
│   ├── validate_deployment.py
│   ├── smoke_test.py
│   └── health_check.py
├── .github/workflows/     # CI/CD pipelines
├── requirements.txt       # Production deps
├── requirements-dev.txt   # Development deps
└── README.md
```

## DynamoDB Schema

**Table**: `campaigns`

| Key | Pattern | Example |
|-----|---------|---------|
| PK | `CAMPAIGN#{code}` | `CAMPAIGN#SUMMER2025` |
| SK | `METADATA` | `METADATA` |

**GSI**: CampaignsByStatusIndex
- GSI1_PK: `CAMPAIGN`
- GSI1_SK: `{status}#{code}`

## Deployment

### GitHub Actions (Recommended)

Push to main triggers DEV deployment automatically.

For SIT/PROD, use manual workflow dispatch.

### Manual Deployment

```bash
cd terraform

# Initialize
terraform init -backend-config="bucket=bbws-terraform-state-dev" ...

# Plan
terraform plan -var-file=environments/dev.tfvars -out=tfplan

# Apply
terraform apply tfplan
```

See [Deployment Runbook](docs/deployment-runbook.md) for details.

## Environments

| Environment | Region | Auto Deploy |
|-------------|--------|-------------|
| DEV | eu-west-1 | Yes (on push) |
| SIT | eu-west-1 | Manual |
| PROD | af-south-1 | Manual + Approval |

## Testing Strategy

- **TDD Approach**: Tests written before implementation
- **Unit Tests**: All handlers, services, repositories
- **Integration Tests**: Full API flow testing
- **Coverage Target**: 80%+

## CI/CD

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| build-test.yml | PR | Lint, test, build |
| terraform-plan.yml | PR | Terraform validation |
| deploy.yml | Push/Manual | Deploy to environment |
| promotion.yml | Manual | Promote between envs |

## Monitoring

- **CloudWatch Logs**: 90 day retention
- **CloudWatch Metrics**: Lambda duration, errors
- **CloudWatch Alarms**: Error rate, latency

## Related Documents

- [BRS 2.1.3: Campaign Management](../docs/BRS/2.1.3_BRS_Campaign_Management.md)
- [HLD 2.1.3: Campaign Management](../docs/HLDs/2.1.3_HLD_Campaign_Management.md)
- [LLD 2.1.3: Campaigns Lambda](../docs/LLDs/2.1.3_LLD_Campaigns_Lambda.md)
- [OpenAPI Specification](openapi/campaigns-api.yaml)

## Contributing

1. Create feature branch from `develop`
2. Write tests first (TDD)
3. Implement feature
4. Ensure all tests pass
5. Submit PR for review

## License

Proprietary - BBWS Platform

## Contact

Platform Team - platform@kimmyai.io
```

---

## Success Criteria

- [ ] README covers all sections
- [ ] Quick start guide included
- [ ] API examples provided
- [ ] Project structure documented
- [ ] Deployment instructions included
- [ ] CI/CD explained
- [ ] Related documents linked

---

## Execution Steps

1. Create README.md in repository root
2. Include all required sections
3. Add code examples
4. Document project structure
5. Link to related docs
6. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
