# Marketing Lambda - BBWS Customer Portal

Marketing Lambda service for campaign retrieval and validation.

## Overview

**Repository**: `2_bbws_marketing_lambda`
**Runtime**: Python 3.12
**Architecture**: arm64
**API Endpoint**: GET /v1.0/campaigns/{code}

## Project Structure

```
2_bbws_marketing_lambda/
├── src/
│   ├── handlers/
│   │   └── get_campaign.py          # Lambda handler
│   ├── services/
│   │   └── campaign_service.py      # Business logic
│   ├── repositories/
│   │   └── campaign_repository.py   # Data access
│   ├── models/
│   │   └── campaign.py              # Pydantic models
│   └── exceptions/
│       └── campaign_exceptions.py   # Custom exceptions
├── tests/
│   ├── unit/                        # Unit tests (80%+ coverage)
│   ├── integration/                 # Integration tests
│   └── e2e/                         # End-to-end tests
├── terraform/                        # Infrastructure as Code
├── requirements.txt                  # Production dependencies
├── requirements-dev.txt              # Development dependencies
├── pytest.ini                        # Pytest configuration
└── mypy.ini                          # Type checking configuration
```

## Setup

### Prerequisites
- Python 3.12
- AWS CLI configured
- Access to DynamoDB table: `bbws-cpp-{env}`

### Installation

```bash
# Create virtual environment
python3.12 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements-dev.txt
```

## Development

### Run Tests
```bash
# All tests with coverage
pytest

# Unit tests only
pytest -m unit

# Integration tests
pytest -m integration

# E2E tests
pytest -m e2e
```

### Code Quality
```bash
# Format code
black src tests

# Lint code
ruff check src tests

# Type check
mypy src
```

## Deployment

### Environments

| Environment | AWS Account | Region | DynamoDB Table |
|-------------|-------------|--------|----------------|
| DEV | 536580886816 | eu-west-1 | bbws-cpp-dev |
| SIT | 815856636111 | eu-west-1 | bbws-cpp-sit |
| PROD | 093646564004 | af-south-1 | bbws-cpp-prod |

### Deployment Flow
```
DEV (auto on merge) → [Approval] → SIT (manual) → [Approval] → PROD (manual)
```

## API

### GET /v1.0/campaigns/{code}

Get campaign details by code.

**Response** (200 OK):
```json
{
  "code": "SUMMER2025",
  "productId": "PROD-001",
  "discountPercent": 20,
  "listPrice": 100.00,
  "price": 80.00,
  "termsAndConditions": "Valid until...",
  "status": "ACTIVE",
  "fromDate": "2025-06-01T00:00:00Z",
  "toDate": "2025-08-31T23:59:59Z",
  "specialConditions": null,
  "isValid": true
}
```

**Response** (404 Not Found):
```json
{
  "message": "Campaign not found",
  "code": "SUMMER2025"
}
```

## License

Copyright © 2025 BBWS. All rights reserved.
