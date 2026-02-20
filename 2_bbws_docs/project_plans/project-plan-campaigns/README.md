# Project Plan: Campaign Management Lambda Service (2.1.3)

**Project Status**: PENDING (Awaiting User Approval)
**Created**: 2026-01-15
**Total Stages**: 5
**Total Workers**: 24

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

---

## Project Structure

```
project-plan-campaigns/
├── project_plan.md              <- Master project plan with tracking
├── work.state.PENDING           <- Project-level state
├── README.md                    <- This file
|
├── stage-1-repository-infrastructure/
│   ├── plan.md                  <- Stage 1 plan
│   ├── work.state.PENDING       <- Stage-level state
│   ├── worker-1-github-repo-setup/
│   │   ├── instructions.md      <- Worker task details
│   │   └── work.state.PENDING   <- Worker-level state
│   ├── worker-2-terraform-lambda-module/
│   │   ├── instructions.md
│   │   └── work.state.PENDING
│   ├── worker-3-terraform-dynamodb-module/
│   │   ├── instructions.md
│   │   └── work.state.PENDING
│   ├── worker-4-terraform-apigateway-module/
│   │   ├── instructions.md
│   │   └── work.state.PENDING
│   ├── worker-5-terraform-iam-module/
│   │   ├── instructions.md
│   │   └── work.state.PENDING
│   └── worker-6-environment-configs/
│       ├── instructions.md
│       └── work.state.PENDING
|
├── stage-2-lambda-code-development/
│   ├── plan.md
│   ├── work.state.PENDING
│   ├── worker-1-project-structure/
│   │   ├── instructions.md
│   │   └── work.state.PENDING
│   ├── worker-2-models-exceptions/
│   │   ├── instructions.md
│   │   └── work.state.PENDING
│   ├── worker-3-repository-layer/
│   │   ├── instructions.md
│   │   └── work.state.PENDING
│   ├── worker-4-service-layer/
│   │   ├── instructions.md
│   │   └── work.state.PENDING
│   ├── worker-5-lambda-handlers/
│   │   ├── instructions.md
│   │   └── work.state.PENDING
│   └── worker-6-utils-validators/
│       ├── instructions.md
│       └── work.state.PENDING
|
├── stage-3-cicd-pipeline/
│   ├── plan.md
│   ├── work.state.PENDING
│   ├── worker-1-build-test-workflow/
│   │   ├── instructions.md
│   │   └── work.state.PENDING
│   ├── worker-2-terraform-plan-workflow/
│   │   ├── instructions.md
│   │   └── work.state.PENDING
│   ├── worker-3-deploy-workflow/
│   │   ├── instructions.md
│   │   └── work.state.PENDING
│   └── worker-4-promotion-workflow/
│       ├── instructions.md
│       └── work.state.PENDING
|
├── stage-4-testing/
│   ├── plan.md
│   ├── work.state.PENDING
│   ├── worker-1-unit-tests-handlers/
│   │   ├── instructions.md
│   │   └── work.state.PENDING
│   ├── worker-2-unit-tests-service-repo/
│   │   ├── instructions.md
│   │   └── work.state.PENDING
│   ├── worker-3-integration-tests/
│   │   ├── instructions.md
│   │   └── work.state.PENDING
│   └── worker-4-validation-scripts/
│       ├── instructions.md
│       └── work.state.PENDING
|
└── stage-5-documentation-deployment/
    ├── plan.md
    ├── work.state.PENDING
    ├── worker-1-openapi-spec/
    │   ├── instructions.md
    │   └── work.state.PENDING
    ├── worker-2-deployment-runbook/
    │   ├── instructions.md
    │   └── work.state.PENDING
    ├── worker-3-dev-deployment/
    │   ├── instructions.md
    │   └── work.state.PENDING
    └── worker-4-project-readme/
        ├── instructions.md
        └── work.state.PENDING
```

---

## Technical Context

### Lambda Functions (5 Total)

| Function | Endpoint | Description |
|----------|----------|-------------|
| list_campaigns | GET /v1.0/campaigns | List all active campaigns |
| get_campaign | GET /v1.0/campaigns/{code} | Get campaign by code |
| create_campaign | POST /v1.0/campaigns | Create new campaign |
| update_campaign | PUT /v1.0/campaigns/{code} | Update campaign |
| delete_campaign | DELETE /v1.0/campaigns/{code} | Soft delete campaign |

### Architecture Pattern

- **Direct Synchronous** - No SQS, Lambda directly reads/writes DynamoDB
- **Service/Repository Pattern** - OOP architecture with clear separation
- **Python 3.12, arm64** - Modern runtime with cost-effective architecture

### DynamoDB Schema

**Table**: `campaigns`

| Key | Pattern | Example |
|-----|---------|---------|
| PK | `CAMPAIGN#{code}` | `CAMPAIGN#SUMMER2025` |
| SK | `METADATA` | `METADATA` |

**GSI1**: CampaignsByStatusIndex
- GSI1_PK: `CAMPAIGN`
- GSI1_SK: `{status}#{code}`

---

## Execution Workflow

### 1. Approval Phase (Current)
- [ ] User reviews `project_plan.md`
- [ ] User reviews project structure in README.md (this file)
- [ ] User provides approval ("go" / "approved")

### 2. Stage 1: Repository Setup & Infrastructure Code
- [ ] Execute 6 workers in parallel
- [ ] Create stage-1 summary.md
- [ ] User approval (Gate 1)

### 3. Stage 2: Lambda Code Development
- [ ] Execute 6 workers in parallel
- [ ] Create stage-2 summary.md
- [ ] User approval (Gate 2)

### 4. Stage 3: CI/CD Pipeline Development
- [ ] Execute 4 workers in parallel
- [ ] Create stage-3 summary.md
- [ ] User approval (Gate 3)

### 5. Stage 4: Testing
- [ ] Execute 4 workers in parallel
- [ ] Create stage-4 summary.md
- [ ] User approval (Gate 4)

### 6. Stage 5: Documentation & Deployment
- [ ] Execute 4 workers in parallel
- [ ] Create stage-5 summary.md
- [ ] User approval (Gate 5)

### 7. Project Completion
- [ ] Create project summary.md
- [ ] Update project work.state to COMPLETE
- [ ] Deliver all artifacts

---

## State File Meanings

| File | Meaning |
|------|---------|
| `work.state.PENDING` | Work not started |
| `work.state.IN_PROGRESS` | Currently being worked on |
| `work.state.COMPLETE` | Work finished successfully |

---

## Key Requirements (from CLAUDE.md)

| Requirement | Implementation |
|-------------|----------------|
| TDD | Write tests before implementation |
| OOP | Service/Repository pattern |
| No hardcoded credentials | Environment variables |
| DynamoDB on-demand | Terraform with PAY_PER_REQUEST |
| DEV first | Deploy to DEV, promote to SIT/PROD |
| Microservices | Separate Terraform per service |

---

## Input Documents

| Document | Location | Status |
|----------|----------|--------|
| BRS 2.1.3 | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/BRS/2.1.3_BRS_Campaign_Management.md` | APPROVED |
| HLD 2.1.3 | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.1.3_HLD_Campaign_Management.md` | APPROVED |
| LLD 2.1.3 | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.3_LLD_Campaigns_Lambda.md` | APPROVED |

---

## Useful Commands

### Check Overall Progress
```bash
echo "Project State:"; cat work.state.*
echo "Stage States:"; find . -maxdepth 2 -name "work.state.*" | sort
echo "Worker States:"; find . -maxdepth 4 -name "work.state.*" | wc -l
```

### List Pending Workers
```bash
find . -name "work.state.PENDING" -exec dirname {} \; | grep worker
```

### List Completed Workers
```bash
find . -name "work.state.COMPLETE" -exec dirname {} \; | grep worker
```

### Count Workers by Status
```bash
echo "PENDING: $(find . -name "work.state.PENDING" | grep worker | wc -l)"
echo "IN_PROGRESS: $(find . -name "work.state.IN_PROGRESS" | grep worker | wc -l)"
echo "COMPLETE: $(find . -name "work.state.COMPLETE" | grep worker | wc -l)"
```

---

## Next Steps

### For Project Manager (Agentic PM)

1. Wait for user approval
2. Begin Stage 1 execution upon approval
3. Create worker output files as work progresses
4. Update work.state files as stages complete

### For User

1. Review `project_plan.md` (detailed plan with tracking)
2. Review project structure in README.md (this file)
3. Provide approval or request changes

---

**Project Manager**: Agentic Project Manager
**Created**: 2026-01-15
**Last Updated**: 2026-01-15
