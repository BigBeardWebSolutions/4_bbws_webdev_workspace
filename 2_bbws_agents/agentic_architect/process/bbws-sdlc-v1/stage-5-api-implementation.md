# Stage 5: API Implementation

**Parent Plan**: [BBWS SDLC Main Plan](./main-plan.md)
**Stage**: 5 of 10
**Status**: ⏳ PENDING
**Last Updated**: 2026-01-01

---

## Objective

Implement the Lambda handlers, service layer, repository layer, and models following the LLD specifications and making all tests from Stage 4 pass (TDD red → green).

---

## Agent & Skill Assignment

| Role | Agent | Skill |
|------|-------|-------|
| **Primary** | Python_AWS_Developer_Agent | `AWS_Python_Dev.skill.md` |
| **Support** | - | `Lambda_Management.skill.md` |
| **Support** | - | `Development_Best_Practices.skill.md` |

**Agent Path**: `agentic_architect/Python_AWS_Developer_Agent.md`

---

## Workers

| # | Worker | Task | Status | Output |
|---|--------|------|--------|--------|
| 1 | worker-1-models | Implement Pydantic models | ⏳ PENDING | `src/models/` |
| 2 | worker-2-repository | Implement DynamoDB repository | ⏳ PENDING | `src/repositories/` |
| 3 | worker-3-service | Implement service layer | ⏳ PENDING | `src/services/` |
| 4 | worker-4-handlers | Implement Lambda handlers | ⏳ PENDING | `src/handlers/` |
| 5 | worker-5-utils | Implement utilities and exceptions | ⏳ PENDING | `src/utils/`, `src/exceptions/` |

---

## Worker Instructions

### Worker 1: Pydantic Models

**Objective**: Implement data models using Pydantic

**Skill Reference**: Apply `AWS_Python_Dev.skill.md`

**Inputs**:
- LLD document (API contracts)
- `api_contracts.md` from Stage 3

**Deliverables**:
```
src/models/
├── __init__.py
├── {entity}.py         # Main entity model
├── requests.py         # Request models
└── responses.py        # Response models
```

**Implementation Pattern**:
```python
from pydantic import BaseModel, Field
from decimal import Decimal

class Product(BaseModel):
    productId: str = Field(..., alias="product_id")
    name: str = Field(..., min_length=1, max_length=100)
    price: Decimal = Field(..., gt=0)

    class Config:
        allow_population_by_field_name = True
```

**Quality Criteria**:
- [ ] All models from LLD implemented
- [ ] Validation rules applied
- [ ] Serialization works correctly
- [ ] Tests pass (from Stage 4)

---

### Worker 2: Repository Layer

**Objective**: Implement DynamoDB data access layer

**Skill Reference**: Apply `AWS_Python_Dev.skill.md`, `DynamoDB_Single_Table.skill.md`

**Inputs**:
- LLD document (database design)
- `database_design.md` from Stage 3

**Deliverables**:
```
src/repositories/
├── __init__.py
└── {entity}_repository.py
```

**Implementation Pattern**:
```python
class ProductRepository:
    def __init__(self, table_name: str = None):
        self.table = boto3.resource("dynamodb").Table(
            table_name or os.environ.get("DYNAMODB_TABLE")
        )

    def get_by_id(self, product_id: str) -> Product:
        ...

    def list_active(self) -> List[Product]:
        ...

    def create(self, product: Product) -> Product:
        ...
```

**Quality Criteria**:
- [ ] All CRUD operations implemented
- [ ] PK/SK patterns match LLD
- [ ] Error handling for DynamoDB errors
- [ ] Tests pass (from Stage 4)

---

### Worker 3: Service Layer

**Objective**: Implement business logic layer

**Inputs**:
- LLD document (service specifications)
- Repository from Worker 2

**Deliverables**:
```
src/services/
├── __init__.py
└── {entity}_service.py
```

**Implementation Pattern**:
```python
class ProductService:
    def __init__(self, repository: ProductRepository = None):
        self.repository = repository or ProductRepository()

    def list_products(self) -> ProductListResponse:
        products = self.repository.list_active()
        return ProductListResponse(products=products)

    def create_product(self, request: CreateProductRequest) -> Product:
        product = Product(
            productId=self._generate_id(),
            **request.dict()
        )
        return self.repository.create(product)
```

**Quality Criteria**:
- [ ] Business logic encapsulated
- [ ] Dependency injection for testability
- [ ] Validation at service boundary
- [ ] Tests pass (from Stage 4)

---

### Worker 4: Lambda Handlers

**Objective**: Implement Lambda handler functions

**Skill Reference**: Apply `Lambda_Management.skill.md`

**Inputs**:
- LLD document (handler specifications)
- Service from Worker 3

**Deliverables**:
```
src/handlers/
├── __init__.py
├── list_{entities}.py
├── get_{entity}.py
├── create_{entity}.py
├── update_{entity}.py
└── delete_{entity}.py
```

**Implementation Pattern**:
```python
from src.services.product_service import ProductService
from src.utils.response_builder import ResponseBuilder

def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    try:
        service = ProductService()
        result = service.list_products()
        return ResponseBuilder.success(result)
    except Exception as e:
        return exception_to_response(e)
```

**Quality Criteria**:
- [ ] All 5 CRUD handlers implemented
- [ ] API Gateway event parsing correct
- [ ] Error handling complete
- [ ] Tests pass (from Stage 4)

---

### Worker 5: Utilities & Exceptions

**Objective**: Implement shared utilities and exception classes

**Inputs**:
- LLD document

**Deliverables**:
```
src/utils/
├── __init__.py
├── response_builder.py    # API Gateway response helper
└── logger.py              # Structured logging

src/exceptions/
├── __init__.py
└── {entity}_exceptions.py  # Custom exceptions

src/validators/
├── __init__.py
└── {entity}_validator.py   # Input validation
```

**Quality Criteria**:
- [ ] ResponseBuilder handles all status codes
- [ ] Custom exceptions with proper HTTP codes
- [ ] Structured JSON logging
- [ ] Tests pass (from Stage 4)

---

## Stage Outputs

| Output | Description | Location |
|--------|-------------|----------|
| Models | Pydantic data models | `{repo}/src/models/` |
| Repositories | DynamoDB access layer | `{repo}/src/repositories/` |
| Services | Business logic layer | `{repo}/src/services/` |
| Handlers | Lambda entry points | `{repo}/src/handlers/` |
| Utils | Shared utilities | `{repo}/src/utils/` |
| Exceptions | Custom exceptions | `{repo}/src/exceptions/` |

---

## TDD Verification

After implementation, verify tests pass:

```bash
# Run all tests
pytest tests/ -v --cov=src --cov-report=term-missing

# Verify coverage ≥ 80%
pytest --cov-fail-under=80
```

---

## Success Criteria

- [ ] All 5 workers completed
- [ ] All unit tests pass (green)
- [ ] All mock tests pass (green)
- [ ] Coverage ≥ 80%
- [ ] Code formatted (black)
- [ ] Type hints complete (mypy)
- [ ] Linting clean (ruff)

---

## Dependencies

**Depends On**: Stage 4 (API Tests)
**Blocks**: Stage 6 (API Proxy)

---

## Estimated Duration

| Activity | Agentic | Manual |
|----------|---------|--------|
| Models | 15 min | 1 hour |
| Repository | 20 min | 2 hours |
| Service | 15 min | 1.5 hours |
| Handlers | 20 min | 2 hours |
| Utils/Exceptions | 15 min | 1 hour |
| **Total** | **85 min** | **7.5 hours** |

---

**Navigation**: [← Stage 4](./stage-4-api-tests.md) | [Main Plan](./main-plan.md) | [Stage 6: API Proxy →](./stage-6-api-proxy.md)
