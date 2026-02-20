# Worker Instructions: Integration Tests

**Worker ID**: worker-2-integration-tests
**Stage**: Stage 5 - Testing & Validation
**Project**: project-plan-2-access-management

---

## Task

Create integration test suites that test cross-service interactions, DynamoDB operations, and end-to-end flows using pytest with localstack or moto.

---

## Scope

### Integration Test Categories
1. **DynamoDB Integration** - CRUD operations, GSI queries
2. **Cross-Service Flows** - Invitation → Team membership
3. **Authorization Flow** - JWT → Permissions resolution
4. **Audit Integration** - Event capture from all services
5. **SES Integration** - Email sending (mocked)
6. **S3 Integration** - Audit archive operations

---

## Deliverables

Create `output.md` with:

### 1. Test Directory Structure
```
tests/integration/
├── conftest.py
├── test_permission_dynamodb.py
├── test_invitation_email_flow.py
├── test_team_membership_flow.py
├── test_role_assignment_flow.py
├── test_audit_logging_flow.py
├── test_authorizer_integration.py
├── test_s3_audit_archive.py
└── fixtures/
    ├── dynamodb_fixtures.py
    └── event_fixtures.py
```

### 2. Flow Test Scenarios

#### Flow 1: User Invitation Flow
```
1. Create invitation
2. Verify DynamoDB record
3. Verify SES called (mocked)
4. Accept invitation (public endpoint)
5. Verify team membership created
6. Verify audit events logged
```

#### Flow 2: Team Management Flow
```
1. Create team
2. Add members
3. Assign team roles
4. Verify data isolation
5. Verify audit events
```

#### Flow 3: Authorization Flow
```
1. Generate test JWT
2. Call authorizer Lambda
3. Verify policy generated
4. Verify context populated
5. Verify caching behavior
```

### 3. DynamoDB Integration Tests
- Single-table design operations
- GSI queries (by org, by user, by team)
- Pagination handling
- Conditional writes
- Transaction operations

### 4. Sample Test Implementation
Complete test file for ONE integration flow.

### 5. Test Data Setup
- Seed data scripts
- Cleanup procedures
- Data isolation strategy

---

## Integration Test Patterns

### Pattern 1: End-to-End Flow
Test complete business workflow across services.

### Pattern 2: DynamoDB Queries
Test GSI queries return correct data.

### Pattern 3: Event Propagation
Test audit events captured for all operations.

### Pattern 4: Error Propagation
Test error handling across service boundaries.

---

## Success Criteria

- [ ] 50+ integration test cases
- [ ] All major flows tested
- [ ] DynamoDB operations validated
- [ ] Audit event capture verified
- [ ] Data isolation confirmed
- [ ] Cleanup procedures defined

---

**Status**: PENDING
**Created**: 2026-01-23
