# Worker Instructions: Performance Tests

**Worker ID**: worker-6-performance-tests
**Stage**: Stage 5 - Testing & Validation
**Project**: project-plan-2-access-management

---

## Task

Create performance test suites using Locust to validate latency, throughput, and scalability targets for the Access Management system.

---

## Performance Targets

| Metric | Target | Priority |
|--------|--------|----------|
| Authorizer Latency | < 100ms (P95) | Critical |
| API Response Time | < 500ms (P95) | Critical |
| Throughput | > 100 RPS | High |
| Error Rate | < 0.1% | High |
| Cold Start | < 3s (P95) | Medium |

---

## Deliverables

Create `output.md` with:

### 1. Test Directory Structure
```
tests/performance/
├── locustfile.py              # Main Locust file
├── scenarios/
│   ├── authorizer_load.py     # Authorizer-specific tests
│   ├── permission_crud.py     # Permission service tests
│   ├── team_operations.py     # Team service tests
│   ├── invitation_flow.py     # Invitation flow tests
│   └── audit_queries.py       # Audit query tests
├── config/
│   ├── dev.yaml               # DEV environment config
│   ├── sit.yaml               # SIT environment config
│   └── load_profiles.yaml     # Load test profiles
├── reports/
│   └── templates/
└── requirements-performance.txt
```

### 2. Load Test Scenarios

#### Scenario 1: Authorizer Load Test
```python
class AuthorizerLoadTest(HttpUser):
    """
    Test authorizer performance under load.
    Target: < 100ms P95 latency
    """
    wait_time = between(0.1, 0.5)

    @task(10)
    def authorize_request(self):
        # Call authorizer with valid JWT
        pass
```

#### Scenario 2: API Endpoint Tests
```python
class PermissionServiceTest(HttpUser):
    """
    Test Permission Service endpoints.
    Target: < 500ms P95 latency
    """
    @task(5)
    def list_permissions(self):
        pass

    @task(3)
    def get_permission(self):
        pass

    @task(1)
    def create_permission(self):
        pass
```

#### Scenario 3: Mixed Workload
```python
class MixedWorkloadTest(HttpUser):
    """
    Simulate realistic mixed workload.
    Read:Write ratio = 80:20
    """
    pass
```

### 3. Load Profiles

#### Profile 1: Baseline
- Users: 10
- Duration: 5 minutes
- Purpose: Establish baseline metrics

#### Profile 2: Normal Load
- Users: 50
- Duration: 15 minutes
- Purpose: Verify normal operation

#### Profile 3: Peak Load
- Users: 100
- Duration: 10 minutes
- Purpose: Verify target throughput

#### Profile 4: Stress Test
- Users: 200+
- Duration: 5 minutes
- Purpose: Find breaking point

### 4. Metrics Collection

| Metric | Source | Collection |
|--------|--------|------------|
| Response Time | Locust | Automatic |
| Throughput | Locust | Automatic |
| Error Rate | Locust | Automatic |
| Lambda Duration | CloudWatch | Metrics API |
| Cold Starts | CloudWatch | Logs analysis |
| DynamoDB Latency | CloudWatch | Metrics API |

### 5. Sample locustfile.py
Complete Locust file with all scenarios.

### 6. CI Integration
```yaml
# GitHub Actions integration
performance-test:
  runs-on: ubuntu-latest
  steps:
    - name: Run Locust tests
      run: |
        locust -f locustfile.py \
          --headless \
          --users 50 \
          --spawn-rate 10 \
          --run-time 5m \
          --html report.html
```

### 7. Report Template
```markdown
## Performance Test Report

### Summary
- Date: YYYY-MM-DD
- Environment: DEV/SIT
- Duration: 15 minutes
- Peak Users: 100

### Results

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Authorizer P95 | < 100ms | 45ms | PASS |
| API P95 | < 500ms | 320ms | PASS |
| Throughput | > 100 RPS | 150 RPS | PASS |
| Error Rate | < 0.1% | 0.02% | PASS |

### Recommendations
- ...
```

---

## Success Criteria

- [ ] Locust tests implemented
- [ ] All 5 performance targets defined
- [ ] Authorizer latency < 100ms (P95)
- [ ] API response < 500ms (P95)
- [ ] Throughput > 100 RPS verified
- [ ] Error rate < 0.1%
- [ ] Performance report template

---

**Status**: PENDING
**Created**: 2026-01-23
