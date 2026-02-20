# LLD Analysis Output

**Worker**: worker-1-lld-analysis
**Date**: 2025-12-30
**Status**: COMPLETE

---

## 1. Component Overview

| Attribute | Value |
|-----------|-------|
| Repository | `2_bbws_marketing_lambda` |
| Runtime | Python 3.12 |
| Memory | 256MB |
| Timeout | 30s |
| Architecture | arm64 |
| Version | 1.0 |
| Status | Draft |
| Parent HLD | BBWS Customer Portal Public HLD |

### Lambda Functions (1 Total)

| Function | Endpoint | HTTP Method | Description |
|----------|----------|-------------|-------------|
| get_campaign | /v1.0/campaigns/{code} | GET | Get campaign details by code |

---

## 2. User Stories

| User Story # | Epic | User Story | Test Scenario(s) |
|--------------|------|------------|------------------|
| US-MKT-001 | Marketing | As a visitor, I want to view campaign details | Given valid code, then campaign returned with status |
| US-MKT-002 | Marketing | As a visitor, I see if campaign is expired | Given expired campaign, then status=EXPIRED returned |
| US-MKT-003 | Marketing | As a visitor, I see campaign discount | Given active campaign, then discount and prices shown |

**Total User Stories**: 3
**Epic**: Marketing
**User Role**: Visitor (public endpoint)

---

## 3. Component Diagram

### Classes Identified

#### 1. CampaignHandler
- **Type**: Handler Layer
- **Attributes**:
  - campaignService: CampaignService (private)
  - responseBuilder: ResponseBuilder (private)
- **Methods**:
  - `handle(event: dict, context: LambdaContext) -> dict` (public)
  - `extractPathParams(event: dict) -> dict` (private)
- **Responsibilities**: Entry point for Lambda, parameter extraction, error handling

#### 2. CampaignService
- **Type**: Service Layer (Business Logic)
- **Attributes**:
  - repository: CampaignRepository (private)
- **Methods**:
  - `getCampaign(code: str) -> Campaign` (public)
  - `validateCampaignStatus(campaign: Campaign) -> Campaign` (private)
  - `calculateEffectivePrice(campaign: Campaign) -> Campaign` (private)
- **Responsibilities**: Campaign retrieval, status validation, price calculation

#### 3. CampaignRepository
- **Type**: Repository Layer (Data Access)
- **Attributes**:
  - table: Table (private)
- **Methods**:
  - `findByCode(code: str) -> Optional[Campaign]` (public)
  - `toEntity(item: dict) -> Campaign` (private)
- **Responsibilities**: DynamoDB access, entity mapping

#### 4. Campaign
- **Type**: Domain Model
- **Attributes**:
  - code: str
  - productId: str
  - discountPercent: int
  - listPrice: Decimal
  - price: Decimal
  - termsAndConditions: str
  - status: CampaignStatus
  - fromDate: str
  - toDate: str
  - specialConditions: Optional[str]
  - active: bool
- **Responsibilities**: Campaign data structure

#### 5. CampaignStatus
- **Type**: Enumeration
- **Values**:
  - DRAFT
  - ACTIVE
  - EXPIRED
- **Responsibilities**: Campaign status states

#### 6. CampaignNotFoundException
- **Type**: Exception (Business Exception)
- **Attributes**:
  - message: str
  - code: str
  - statusCode: int
- **Responsibilities**: Handle campaign not found errors

### Component Relationships
```
CampaignHandler --> CampaignService
CampaignService --> CampaignRepository
CampaignRepository --> Campaign
Campaign --> CampaignStatus
```

**Architecture Pattern**: Layered architecture (Handler → Service → Repository → Model)

---

## 4. Sequence Diagrams

### Get Campaign Flow (Happy Path)

**Participants**:
1. Client
2. API Gateway
3. CampaignHandler
4. CampaignService
5. CampaignRepository
6. DynamoDB

**Flow**:
1. Client → API Gateway: `GET /v1.0/campaigns/{code}`
2. API Gateway → CampaignHandler: `handle(event, context)`
3. CampaignHandler → CampaignHandler: `extractPathParams(event)`
4. CampaignHandler → CampaignService: `getCampaign(code)`
5. CampaignService → CampaignRepository: `findByCode(code)`
6. CampaignRepository → DynamoDB: `get_item(PK=CAMPAIGN#{code})`
7. DynamoDB → CampaignRepository: item
8. CampaignRepository → CampaignService: `Optional[Campaign]`
9. CampaignService → CampaignService: `validateCampaignStatus(campaign)`
   - Check fromDate and toDate
   - Update status if expired
10. CampaignService → CampaignService: `calculateEffectivePrice(campaign)`
    - Calculate: `price = listPrice * (1 - discountPercent/100)`
11. CampaignService → CampaignHandler: Campaign
12. CampaignHandler → API Gateway: `{statusCode: 200, body: campaign}`
13. API Gateway → Client: 200 OK

### Error Handling Flows

#### BusinessException (Campaign Not Found)
1. CampaignRepository returns `Optional.empty()`
2. CampaignService throws `CampaignNotFoundException`
3. CampaignHandler catches BusinessException
4. CampaignHandler → API Gateway: `{statusCode: 404, body: "Campaign not found"}`
5. API Gateway → Client: 404 Not Found

#### UnexpectedException (System Errors)
1. Any layer throws unexpected exception
2. CampaignHandler catches UnexpectedException
3. CampaignHandler logs error: `logger.error(exception)`
4. CampaignHandler → API Gateway: `{statusCode: 500, body: "Internal server error"}`
5. API Gateway → Client: 500 Internal Server Error

**Error Handling Strategy**: try-except-else pattern with separate handling for business vs system exceptions

---

## 5. Data Models

### DynamoDB Schema

#### Campaign Entity

| Attribute | Type | Description | Example |
|-----------|------|-------------|---------|
| PK | String | Partition Key | `CAMPAIGN#SUMMER2025` |
| SK | String | Sort Key | `METADATA` |
| code | String | Campaign code | `SUMMER2025` |
| productId | String | Associated product | `PROD-001` |
| discountPercent | Number | Discount percentage | 20 |
| listPrice | Number | Original price | 100.00 |
| price | Number | Discounted price | 80.00 |
| termsAndConditions | String | T&Cs | "Valid until..." |
| status | String | Campaign status | DRAFT / ACTIVE / EXPIRED |
| fromDate | String | Start date (ISO 8601) | "2025-06-01T00:00:00Z" |
| toDate | String | End date (ISO 8601) | "2025-08-31T23:59:59Z" |
| specialConditions | String | Additional conditions | "Excludes sale items" |
| active | Boolean | Soft delete flag | true |

**Access Pattern**: Get campaign by code
- **Query**: `get_item(PK=CAMPAIGN#{code}, SK=METADATA)`
- **Table**: Single-table design (bbws-cpp-{env})

### Pydantic Models

#### CampaignStatus (Enum)
```python
class CampaignStatus(str, Enum):
    DRAFT = "DRAFT"
    ACTIVE = "ACTIVE"
    EXPIRED = "EXPIRED"
```

#### Campaign (Domain Model)
```python
class Campaign(BaseModel):
    code: str
    product_id: str = Field(..., alias="productId")
    discount_percent: int = Field(..., alias="discountPercent")
    list_price: Decimal = Field(..., alias="listPrice")
    price: Decimal
    terms_and_conditions: str = Field(..., alias="termsAndConditions")
    status: CampaignStatus
    from_date: str = Field(..., alias="fromDate")
    to_date: str = Field(..., alias="toDate")
    special_conditions: Optional[str] = Field(None, alias="specialConditions")
    active: bool = True
```

**Validation**: Pydantic for data validation and serialization

#### CampaignResponse (API Response Model)
```python
class CampaignResponse(BaseModel):
    code: str
    product_id: str = Field(..., alias="productId")
    discount_percent: int = Field(..., alias="discountPercent")
    list_price: Decimal = Field(..., alias="listPrice")
    price: Decimal
    terms_and_conditions: str = Field(..., alias="termsAndConditions")
    status: CampaignStatus
    from_date: str = Field(..., alias="fromDate")
    to_date: str = Field(..., alias="toDate")
    special_conditions: Optional[str] = Field(None, alias="specialConditions")
    is_valid: bool = Field(..., alias="isValid")
```

**Additional Field**: `is_valid` indicates if campaign is currently active

---

## 6. Infrastructure Requirements

### Lambda Configuration

| Parameter | Value | Notes |
|-----------|-------|-------|
| Runtime | Python 3.12 | Latest Python version |
| Architecture | arm64 | Cost-effective Graviton2 |
| Memory | 256MB | Sufficient for campaign retrieval |
| Timeout | 30s | Ample for DynamoDB read + processing |
| Handler | get_campaign.lambda_handler | Entry point |

### Environment Variables

| Variable | Description | Example Values |
|----------|-------------|----------------|
| DYNAMODB_TABLE_NAME | DynamoDB table reference | bbws-cpp-dev / bbws-cpp-sit / bbws-cpp-prod |
| AWS_REGION | AWS region | eu-west-1 (DEV/SIT) / af-south-1 (PROD) |
| LOG_LEVEL | Logging level | DEBUG (DEV) / INFO (SIT) / WARN (PROD) |
| ENVIRONMENT | Environment identifier | dev / sit / prod |
| CACHE_TTL | Cache TTL in seconds | 300 (5 minutes) |

**Configuration Strategy**: All parameterized via environment variables

### DynamoDB Table Reference

| Environment | Table Name | Region |
|-------------|------------|--------|
| DEV | bbws-cpp-dev | eu-west-1 |
| SIT | bbws-cpp-sit | eu-west-1 |
| PROD | bbws-cpp-prod | af-south-1 |

**Access Pattern**: `get_item` with PK=CAMPAIGN#{code}

### API Gateway Configuration

| Setting | Value |
|---------|-------|
| Endpoint | /v1.0/campaigns/{code} |
| Method | GET |
| Authentication | None (public endpoint) |
| Rate Limiting | 100 req/s |

---

## 7. Testing Requirements

### Non-Functional Requirements (NFRs)

| Metric | Target | Measurement |
|--------|--------|-------------|
| Get campaign latency (p95) | < 200ms | CloudWatch Metrics |
| Cold start | < 500ms | CloudWatch Insights |
| Cache hit ratio | > 90% | Custom metric |

### Test Coverage Targets

**Unit Tests** (80%+ coverage required):
- `test_campaign_handler.py` - Handler layer tests
- `test_campaign_service.py` - Service layer tests
- `test_campaign_repository.py` - Repository layer tests
- `test_campaign_model.py` - Model validation tests

**Integration Tests**:
- `test_get_campaign_integration.py` - Lambda + DynamoDB integration

**End-to-End Tests**:
- `test_get_campaign_e2e.py` - API Gateway → Lambda → DynamoDB

### Test Scenarios (from User Stories)

| Test Scenario | User Story | Expected Result |
|---------------|------------|-----------------|
| Valid campaign code | US-MKT-001 | 200 OK with campaign details |
| Expired campaign | US-MKT-002 | 200 OK with status=EXPIRED |
| Active campaign with discount | US-MKT-003 | 200 OK with calculated discount price |
| Invalid campaign code | N/A | 404 Not Found |
| System error | N/A | 500 Internal Server Error |

---

## 8. Implementation Checklist

### Code Implementation
- [ ] Handler layer: `src/handlers/get_campaign.py`
  - [ ] Lambda handler function
  - [ ] Parameter extraction
  - [ ] Error handling (try-except-else)
  - [ ] Response builder

- [ ] Service layer: `src/services/campaign_service.py`
  - [ ] `getCampaign(code: str)` method
  - [ ] `validateCampaignStatus(campaign: Campaign)` method
  - [ ] `calculateEffectivePrice(campaign: Campaign)` method
  - [ ] Business logic for status validation
  - [ ] Price calculation formula

- [ ] Repository layer: `src/repositories/campaign_repository.py`
  - [ ] `findByCode(code: str)` method
  - [ ] DynamoDB get_item operation
  - [ ] `toEntity(item: dict)` mapping method
  - [ ] Optional[Campaign] return type

- [ ] Model layer: `src/models/campaign.py`
  - [ ] Campaign Pydantic model
  - [ ] CampaignStatus enum
  - [ ] CampaignResponse model
  - [ ] Field aliases for camelCase ↔ snake_case

- [ ] Exceptions: `src/exceptions/campaign_exceptions.py`
  - [ ] CampaignNotFoundException
  - [ ] BaseBusinessException (if needed)
  - [ ] BaseSystemException (if needed)

### Test Implementation
- [ ] Unit tests (TDD - write first!):
  - [ ] `tests/unit/test_campaign_handler.py`
  - [ ] `tests/unit/test_campaign_service.py`
  - [ ] `tests/unit/test_campaign_repository.py`
  - [ ] `tests/unit/test_campaign_model.py`

- [ ] Integration tests:
  - [ ] `tests/integration/test_get_campaign_integration.py`

- [ ] End-to-end tests:
  - [ ] `tests/e2e/test_get_campaign_e2e.py`

### Infrastructure
- [ ] Terraform Lambda module: `terraform/modules/lambda/`
- [ ] Terraform API Gateway module: `terraform/modules/apigateway/`
- [ ] Environment configurations: DEV, SIT, PROD

### CI/CD
- [ ] GitHub Actions workflows (10 workflows)
- [ ] Validation, deployment, promotion pipelines

### Documentation
- [ ] Deployment runbook
- [ ] Promotion runbook
- [ ] Troubleshooting runbook
- [ ] Rollback runbook

---

## 9. Additional Requirements

### Security (Section 11)
- Public endpoint (no authentication required)
- Rate limiting: 100 req/s at API Gateway level
- No PII handling

### Messaging (Section 6)
- No email notifications required for this service

### Troubleshooting (Section 10)

| Issue | Resolution |
|-------|------------|
| Campaign not found | Verify code in DynamoDB using AWS Console or CLI |
| Wrong status | Check from_date/to_date values, ensure date format is ISO 8601 |

### Risks and Mitigations (Section 8)

| Risk | Impact | Mitigation |
|------|--------|------------|
| Stale campaign data | Low | Short cache TTL (5 min) |
| Invalid campaign codes | Low | Return 404 gracefully |

### Tagging (Section 9)

| Tag | Value |
|-----|-------|
| Project | BBWS |
| Component | MarketingLambda |
| CostCenter | BBWS-CPP |
| Environment | dev / sit / prod |
| ManagedBy | Terraform |

---

## 10. Project Structure (from LLD Section 15)

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
│   ├── unit/
│   │   ├── test_campaign_handler.py
│   │   ├── test_campaign_service.py
│   │   ├── test_campaign_repository.py
│   │   └── test_campaign_model.py
│   ├── integration/
│   │   └── test_get_campaign_integration.py
│   └── e2e/
│       └── test_get_campaign_e2e.py
├── terraform/
│   ├── modules/
│   │   ├── lambda/
│   │   └── apigateway/
│   └── environments/
│       ├── dev/
│       ├── sit/
│       └── prod/
├── requirements.txt                  # Production dependencies
├── requirements-dev.txt              # Development dependencies
├── pytest.ini                        # Pytest configuration
├── mypy.ini                          # Type checking configuration
└── .gitignore
```

---

## 11. Summary

### Key Findings
- **Single Lambda Function**: GET /v1.0/campaigns/{code}
- **3 User Stories**: Campaign retrieval, expiry check, discount display
- **Layered Architecture**: Handler → Service → Repository → Model
- **6 Classes/Components**: CampaignHandler, CampaignService, CampaignRepository, Campaign, CampaignStatus, CampaignNotFoundException
- **1 API Endpoint**: Public GET endpoint with rate limiting
- **3 Campaign States**: DRAFT, ACTIVE, EXPIRED
- **2 Error Types**: BusinessException (404) and UnexpectedException (500)

### OOP Compliance
✅ Service layer encapsulates business logic
✅ Repository layer encapsulates data access
✅ Model layer defines domain entities
✅ Clear separation of concerns
✅ Single Responsibility Principle

### TDD Readiness
✅ Unit test structure defined
✅ Integration test requirements specified
✅ E2E test scenarios outlined
✅ 80%+ coverage target set

### Completeness
✅ All LLD sections analyzed
✅ Component diagram documented
✅ Sequence diagrams documented
✅ Data models extracted
✅ Infrastructure requirements specified
✅ Testing strategy defined
✅ Implementation checklist created

---

**Analysis Complete**: 2025-12-30
**Worker Status**: COMPLETE
**Lines Analyzed**: 339 lines from LLD
**Components Identified**: 6
**User Stories**: 3
**Ready for**: Stage 2 (Lambda Implementation)
