# Stage 2: Lambda Code Development

**Stage ID**: stage-2-lambda-code-development
**Project**: project-plan-campaigns
**Status**: PENDING
**Workers**: 6 (parallel execution)

---

## Stage Objective

Develop the Python Lambda code following TDD and OOP principles with Service/Repository pattern.

---

## Stage Workers

| Worker | Task | Status |
|--------|------|--------|
| worker-1-project-structure | Create project structure and dependencies | PENDING |
| worker-2-models-exceptions | Create Pydantic models and custom exceptions | PENDING |
| worker-3-repository-layer | Create CampaignRepository with DynamoDB operations | PENDING |
| worker-4-service-layer | Create CampaignService with business logic | PENDING |
| worker-5-lambda-handlers | Create 5 Lambda handler functions | PENDING |
| worker-6-utils-validators | Create utilities and validators | PENDING |

---

## Stage Inputs

**From Stage 1**:
- Repository structure with all directories
- Terraform modules (for understanding resource names)

**Primary Reference**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.3_LLD_Campaigns_Lambda.md`

---

## Stage Outputs

### Source Code Structure
```
src/
├── __init__.py
├── handlers/
│   ├── __init__.py
│   ├── list_campaigns.py
│   ├── get_campaign.py
│   ├── create_campaign.py
│   ├── update_campaign.py
│   └── delete_campaign.py
├── services/
│   ├── __init__.py
│   └── campaign_service.py
├── repositories/
│   ├── __init__.py
│   └── campaign_repository.py
├── models/
│   ├── __init__.py
│   └── campaign.py
├── validators/
│   ├── __init__.py
│   └── campaign_validator.py
├── exceptions/
│   ├── __init__.py
│   └── campaign_exceptions.py
└── utils/
    ├── __init__.py
    ├── response_builder.py
    ├── date_utils.py
    └── logger.py
```

---

## Architecture Pattern

### OOP with Service/Repository Pattern

```
Lambda Handler
    |
    v
CampaignService (Business Logic)
    |
    v
CampaignRepository (Data Access)
    |
    v
DynamoDB
```

### Key Classes

1. **Campaign** (Pydantic Model) - Data model with validation
2. **CampaignRepository** - DynamoDB CRUD operations
3. **CampaignService** - Business logic, status calculation, price calculation
4. **Handlers** - Lambda entry points, request parsing, response building

---

## Success Criteria

- [ ] All Python files created with proper structure
- [ ] Pydantic models match LLD Section 5.2
- [ ] Repository implements all DynamoDB operations
- [ ] Service implements business logic from LLD
- [ ] All 5 handlers implemented
- [ ] TDD approach followed (tests written first)
- [ ] OOP principles applied
- [ ] All 6 workers completed
- [ ] Stage summary created

---

## Key Requirements from LLD

### From Section 3: Component Diagram
- CampaignAPIHandler -> CampaignService -> CampaignRepository
- Clear separation of concerns

### From Section 5.2: Pydantic Models
- Campaign, CampaignResponse, CampaignListResponse
- CreateCampaignRequest, UpdateCampaignRequest
- CampaignStatus enum

### From Section 6: REST API Operations
- List, Get, Create, Update, Delete
- Proper HTTP status codes
- Error handling

---

## Dependencies

**Depends On**: Stage 1 (Repository Setup & Infrastructure Code)

**Blocks**: Stage 3 (CI/CD Pipeline Development)

---

**Created**: 2026-01-15
