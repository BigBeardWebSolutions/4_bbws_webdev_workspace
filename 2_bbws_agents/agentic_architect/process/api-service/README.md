# API Service SDLC Process

**Process Type**: Backend API / Lambda Service
**Parent Process**: [BBWS SDLC v1](../bbws-sdlc-v1/main-plan.md)

---

## Overview

This process is for developing serverless API services using AWS Lambda, API Gateway, and DynamoDB.

## Applicable Stages

| Stage | Name | Required |
|-------|------|----------|
| 1 | Requirements & Analysis | Yes |
| 2 | HLD Creation | Yes |
| 3 | LLD Creation | Yes |
| 4 | API Tests (TDD) | Yes |
| 5 | API Implementation | Yes |
| 6 | API Proxy | Yes |
| 7 | Infrastructure (Terraform) | Yes |
| 8 | CI/CD Pipeline | Yes |
| 9 | Route53/Domain | Yes |
| 10 | Deploy & Test | Yes |

## Technology Stack

- **Runtime**: Python 3.12
- **Framework**: AWS Lambda
- **Database**: DynamoDB (Single Table Design)
- **API**: API Gateway REST API
- **Infrastructure**: Terraform
- **CI/CD**: GitHub Actions with OIDC

## Project Template

```
{service-name}_lambda/
├── src/
│   ├── handlers/
│   ├── services/
│   ├── repositories/
│   ├── models/
│   ├── validators/
│   ├── exceptions/
│   └── utils/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── terraform/
│   └── environments/
├── .github/workflows/
├── requirements.txt
├── requirements-dev.txt
└── CLAUDE.md
```

## Estimated Duration

| Mode | Duration |
|------|----------|
| Agentic | 8 hours |
| Manual | 36 hours |

## Examples

- Product Lambda Service
- Order Lambda Service
- Tenant Management Service

---

**Quick Start**: Copy the full process from `../bbws-sdlc-v1/` and follow stages 1-10.
