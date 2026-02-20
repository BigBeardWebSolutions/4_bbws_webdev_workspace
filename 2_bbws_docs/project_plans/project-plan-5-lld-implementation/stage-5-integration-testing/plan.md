# Stage 5: Integration Testing

**Stage ID**: stage-5-integration-testing
**Project**: project-plan-5-lld-implementation
**Status**: COMPLETE
**Started**: 2026-01-25
**Completed**: 2026-01-25
**Workers**: 5 (parallel execution)

---

## Stage Objective

Create and execute comprehensive integration tests for all APIs across the three LLDs, including cross-service integration tests and EventBridge event flow verification.

---

## Stage Workers

| Worker | Task | Scope | Test Count (Est.) |
|--------|------|-------|-------------------|
| worker-1-tenant-integration-tests | Tenant API Integration Tests | LLD 2.5 APIs | 25-30 tests |
| worker-2-site-integration-tests | Site API Integration Tests | LLD 2.6 APIs | 35-40 tests |
| worker-3-instance-integration-tests | Instance API Integration Tests | LLD 2.7 APIs | 20-25 tests |
| worker-4-cross-service-tests | Cross-Service Integration Tests | All LLDs | 15-20 tests |
| worker-5-eventbridge-tests | EventBridge Integration Tests | Event flows | 10-15 tests |

---

## Stage Inputs

| Input | Source |
|-------|--------|
| Lambda Code | Deployed to DEV |
| API Gateway Endpoints | DEV environment |
| Test Fixtures | Stage 2 & 3 |
| LLD Test Scenarios | LLDs 2.5, 2.6, 2.7 |

---

## Stage Outputs

### Worker 1: Tenant Integration Tests

```
tests/integration/
├── test_tenant_crud.py
├── test_tenant_hierarchy.py
├── test_tenant_users.py
├── test_tenant_invitations.py
└── test_tenant_lifecycle.py
```

**Test Scenarios**:
- Create tenant → verify DynamoDB record
- List tenants → verify pagination
- Get tenant → verify all fields
- Update tenant → verify field updates
- Park/Unpark tenant → verify status transitions
- Suspend/Resume tenant → verify lifecycle
- Hierarchy CRUD → verify parent-child relationships
- User assignments → verify tenant-user links
- Invitations → verify email triggers

### Worker 2: Site Integration Tests

```
tests/integration/
├── test_site_crud.py
├── test_site_operations.py
├── test_site_templates.py
├── test_site_plugins.py
└── test_site_async.py
```

**Test Scenarios**:
- Create site → verify async SQS message
- Poll site status → verify status transitions
- Clone site → verify new site created
- Promote site → verify environment change
- Apply template → verify WordPress API call
- Install plugin → verify security scan
- Uninstall plugin → verify removal

### Worker 3: Instance Integration Tests

```
tests/integration/
├── test_instance_crud.py
├── test_instance_operations.py
├── test_instance_gitops.py
└── test_instance_events.py
```

**Test Scenarios**:
- Create instance → verify GitOps trigger
- Get instance → verify infrastructure state
- Update instance (scale) → verify ECS task count
- Delete instance → verify resource cleanup
- Status check → verify ECS/RDS/EFS health
- GitOps flow → verify Terraform execution

### Worker 4: Cross-Service Tests

```
tests/integration/
├── test_tenant_to_instance.py
├── test_site_to_tenant.py
├── test_lifecycle_cascade.py
└── test_authorization_chain.py
```

**Test Scenarios**:
- Create tenant → auto-create instance (if configured)
- Create site → verify tenant exists
- Delete tenant → verify cascade to instances
- Park tenant → verify sites suspended
- Authorization → verify tenant isolation

### Worker 5: EventBridge Tests

```
tests/integration/
├── test_eventbridge_tenant_events.py
├── test_eventbridge_site_events.py
├── test_eventbridge_instance_events.py
└── test_ecs_state_sync.py
```

**Test Scenarios**:
- Tenant created event → verify consumers receive
- Site created event → verify notification sent
- Instance created event → verify DynamoDB sync
- ECS state change → verify DynamoDB update
- Event retry → verify DLQ handling

---

## Test Infrastructure

### Test Environment
```yaml
# docker-compose.yml for local testing
services:
  localstack:
    image: localstack/localstack
    ports:
      - "4566:4566"
    environment:
      - SERVICES=dynamodb,sqs,sns,eventbridge,s3,secretsmanager

  postgres:
    image: postgres:15
    # For RDS simulation if needed
```

### Test Fixtures
```python
# conftest.py
@pytest.fixture
def tenant_fixture():
    return {
        "tenantId": "tenant-test-001",
        "organisationName": "Test Org",
        "status": "ACTIVE"
    }

@pytest.fixture
def site_fixture():
    return {
        "siteId": "site-test-001",
        "tenantId": "tenant-test-001",
        "siteName": "Test Site",
        "status": "ACTIVE"
    }
```

---

## Success Criteria

- [ ] All integration tests written
- [ ] All tests pass in DEV environment
- [ ] 80%+ API coverage achieved
- [ ] Cross-service flows verified
- [ ] EventBridge event flows verified
- [ ] Test execution automated in CI/CD
- [ ] Test reports generated
- [ ] All 5 workers completed
- [ ] Stage summary created

---

## Dependencies

**Depends On**: Stage 4 (CI/CD Pipeline Development)

**Blocks**: Stage 6 (Documentation & Runbooks)

---

## Gate 5 Approval

**Approvers**: QA Lead, Tech Lead

**Criteria**:
- All integration tests pass
- Cross-service functionality verified
- EventBridge flows working
- No critical bugs found
- Test coverage meets threshold

---

**Created**: 2026-01-24
