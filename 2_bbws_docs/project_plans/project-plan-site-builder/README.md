# BBWS AI-Powered Site Builder - Implementation Plan

**Project Status**: PENDING (Awaiting User Approval)
**Version**: 2.0
**Approach**: Local-First Development
**Total Stages**: 10
**Total Workers**: 60+

---

## Quick Start

### View Project Plan
```bash
cat project_plan.md
```

### Check Project Status
```bash
find . -name "work.state.*" | sort
```

### Count Workers by Status
```bash
echo "PENDING: $(find . -name "work.state.PENDING" | grep worker | wc -l)"
echo "IN_PROGRESS: $(find . -name "work.state.IN_PROGRESS" | grep worker | wc -l)"
echo "COMPLETE: $(find . -name "work.state.COMPLETE" | grep worker | wc -l)"
```

---

## Development Approach: Local-First

This project uses a **local-first development approach** where all user journeys are tested locally before deploying to AWS:

```
┌─────────────────────────────────────────────────────────────────┐
│                     DEVELOPMENT PHASES                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Phase 1: Local Development (Stages 2-5)                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  • No AWS credentials required                           │   │
│  │  • Full user journeys testable                           │   │
│  │  • Fast iteration (hot reload)                           │   │
│  │  • CI can run all tests                                  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                           ↓                                     │
│  Phase 2: AWS Deployment (Stages 6-9)                           │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  • Deploy infrastructure with Terraform                  │   │
│  │  • Deploy real AI agents                                 │   │
│  │  • Integration testing on DEV                            │   │
│  │  • Promote to SIT/PROD                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Local Development Stack

| Component | Local Tool | AWS Equivalent |
|-----------|-----------|----------------|
| DynamoDB | LocalStack | DynamoDB |
| S3 | LocalStack | S3 |
| Lambda | SAM Local | Lambda |
| API Gateway | SAM Local | API Gateway |
| Cognito | Mock JWT | Cognito |
| AgentCore | Mock Server | Bedrock AgentCore |

---

## Project Structure

```
project-plan-site-builder/
├── project_plan.md                    ← Master project plan v2.0
├── README.md                          ← This file
├── work.state.PENDING                 ← Project-level state
│
├── stage-1-requirements-validation/   ← Validate all documents
│   ├── plan.md
│   ├── work.state.PENDING
│   └── worker-*/
│
├── stage-2-local-dev-environment/     ← NEW: Local stack setup
│   ├── plan.md
│   ├── work.state.PENDING
│   ├── worker-1-localstack-setup/
│   ├── worker-2-sam-local-config/
│   ├── worker-3-msw-handlers/
│   ├── worker-4-agent-mock-service/
│   └── worker-5-docker-compose/
│
├── stage-3-frontend-react/            ← React with mocked APIs
│   └── worker-*/  (9 workers)
│
├── stage-4-backend-lambda/            ← Lambda with LocalStack
│   └── worker-*/  (8 workers)
│
├── stage-5-local-integration-testing/ ← NEW: Test locally
│   ├── plan.md
│   ├── work.state.PENDING
│   ├── worker-1-frontend-backend-integration/
│   ├── worker-2-user-journey-tests/
│   ├── worker-3-agent-mock-validation/
│   └── worker-4-local-e2e-suite/
│
├── stage-6-infrastructure-terraform/  ← Deploy to AWS DEV
│   └── worker-*/  (8 workers)
│
├── stage-7-agentcore-agents/          ← Deploy AI agents
│   └── worker-*/  (8 workers)
│
├── stage-8-cicd-pipeline/             ← GitHub Actions
│   └── worker-*/  (5 workers)
│
├── stage-9-aws-integration-testing/   ← Test on AWS
│   └── worker-*/  (4 workers)
│
└── stage-10-documentation-runbooks/   ← Operational docs
    └── worker-*/  (4 workers)
```

---

## Stage Overview

| Stage | Name | Workers | Local/AWS | Approval Gate |
|-------|------|---------|-----------|---------------|
| 1 | Requirements Validation | 5 | N/A | Gate 1 |
| 2 | **Local Dev Environment** | 5 | Local | Gate 2 |
| 3 | Frontend React | 9 | Local | - |
| 4 | Backend Lambda | 8 | Local | - |
| 5 | **Local Integration Testing** | 4 | Local | **Gate 3** |
| 6 | Infrastructure Terraform | 8 | AWS | Gate 4 |
| 7 | AgentCore Agents | 8 | AWS | Gate 5 |
| 8 | CI/CD Pipeline | 5 | AWS | Gate 6 |
| 9 | AWS Integration Testing | 4 | AWS | Gate 7 |
| 10 | Documentation | 4 | N/A | Gate 8 |

---

## Execution Workflow

### Phase 1: Local Development

```bash
# 1. Start local infrastructure
cd local-dev
docker-compose up -d

# 2. Start Lambda API locally
sam local start-api --port 3001

# 3. Start agent mock server
cd mocks/agents && npm start

# 4. Start React frontend with MSW
cd frontend && npm run dev

# 5. Run local integration tests
npm run test:e2e:local
```

### Phase 2: AWS Deployment

```bash
# 1. Deploy infrastructure to DEV
cd infra
terraform apply -var-file=envs/dev.tfvars

# 2. Deploy Lambda functions
sam deploy --config-env dev

# 3. Deploy agents to AgentCore
cd agents
./deploy.sh dev

# 4. Run AWS integration tests
npm run test:e2e:aws
```

---

## State File Meanings

| File | Meaning |
|------|---------|
| `work.state.PENDING` | Work not started |
| `work.state.IN_PROGRESS` | Currently being worked on |
| `work.state.COMPLETE` | Work finished successfully |

---

## Key Commands

### Local Development
```bash
# Start full local stack
./scripts/start-local.sh

# Seed test data
./scripts/seed-data.sh

# Run all local tests
npm run test:local

# Stop local stack
./scripts/stop-local.sh
```

### Testing
```bash
# Unit tests
npm run test:unit

# Integration tests (local)
npm run test:integration

# E2E tests (local)
npm run test:e2e:local

# E2E tests (AWS DEV)
npm run test:e2e:aws
```

### Deployment
```bash
# Deploy to DEV
npm run deploy:dev

# Promote to SIT
npm run deploy:sit

# Promote to PROD (requires approval)
npm run deploy:prod
```

---

## Benefits of Local-First Approach

1. **Faster Iteration**: No waiting for AWS deployments
2. **Cost Savings**: No AWS costs during development
3. **CI/CD Friendly**: Tests run without AWS credentials
4. **Offline Development**: Work without internet
5. **Confidence**: Validate flows before cloud deployment
6. **Debugging**: Easier to debug locally

---

## Epic to Stage Mapping

| Epic | Stage(s) |
|------|----------|
| Epic 1: AI Page Generation | Stages 3, 4, 5, 7 |
| Epic 2: Iterative Refinement | Stages 3, 4, 5, 7 |
| Epic 3: Quality & Validation | Stages 3, 4, 5, 7 |
| Epic 4: Deployment | Stages 4, 6 |
| Epic 5: Analytics & Optimization | Stages 3, 4 |
| Epic 6: Site Designer | Stages 3, 7 |
| Epic 7: Tenant Management | Stages 4, 6 |
| Epic 8: Site Migration | Stage 4 (Phase 2) |
| Epic 9: White-Label & Marketplace | Stages 3, 4 |

---

## User Personas to Stage Mapping

| Persona | Primary Stages |
|---------|----------------|
| Marketing User | Stages 3, 4, 5, 7 |
| Designer | Stages 3, 7 |
| Org Admin | Stages 3, 4 |
| DevOps Engineer | Stages 6, 8, 9 |
| White-Label Partner | Stages 3, 4 |

---

## Repository Structure (Target)

| Repository | Description | Language |
|------------|-------------|----------|
| bbws-site-builder-infra | Terraform IaC | HCL |
| bbws-site-builder-api | Lambda functions | Python 3.12 |
| bbws-site-builder-agents | AgentCore agents | Python 3.12 |
| bbws-site-builder-web | React frontend | TypeScript |
| bbws-site-builder-local | Local dev environment | Docker/TypeScript |

---

## Environment Configuration

| Environment | Primary Region | Agent Region | Purpose |
|-------------|----------------|--------------|---------|
| LOCAL | N/A | N/A | Local development |
| DEV | af-south-1 | eu-west-1 | Development |
| SIT | af-south-1 | eu-west-1 | System Integration Testing |
| PROD | af-south-1 | eu-west-1 | Production |

**Promotion Flow**: LOCAL -> DEV -> SIT -> PROD

---

## Next Steps

### For User
1. Review `project_plan.md`
2. Review this README
3. Approve to begin Stage 1

### For Project Manager
1. Wait for user approval
2. Execute Stage 1 workers
3. Set up local development environment (Stage 2)
4. Proceed with development stages

---

**Project Manager**: Agentic Project Manager
**Last Updated**: 2026-01-16
