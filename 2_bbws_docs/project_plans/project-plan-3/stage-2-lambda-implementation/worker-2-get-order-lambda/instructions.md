# Worker 2-get-order-lambda: get_order Lambda Implementation

**Lambda Function**: get_order
**Trigger/Endpoint**: GET /v1.0/orders/{orderId}
**Purpose**: Query DynamoDB by orderId

---

## Instructions

Implement the `get_order` Lambda function following the comprehensive specifications in the Stage 2 Plan.

### Reference Documents

1. **Stage 2 Plan**: `../plan.md` - Complete specifications for this Lambda function
2. **LLD**: `../../../2.1.8_LLD_Order_Lambda.md` - Low-level design reference
3. **Stage 1 Requirements**: `../../stage-1-repository-requirements/worker-2-requirements-extraction/output.md`

### Key Requirements

Refer to Stage 2 Plan section for get_order for:
- Detailed functionality specifications
- Request/response schemas
- Error handling requirements
- Test coverage requirements (80%+)
- Code quality standards (PEP 8, type hints, docstrings)

### Deliverables

1. Lambda handler: `src/handlers/get_order.py`
2. Pydantic models (if new models needed)
3. Service layer implementation
4. DAO operations (if applicable)
5. Unit tests (≥80% coverage)
6. Integration tests
7. Output documentation: `output.md`

### Implementation Standards

- Python 3.12, arm64 architecture
- Pydantic v1.10.18 for data validation
- Test-Driven Development (TDD)
- OOP principles (SOLID)
- Environment-parameterized configuration
- Structured logging with CloudWatch

---

**Status**: READY FOR EXECUTION
**Reference**: See `../plan.md` for complete specifications
