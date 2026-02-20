# Stage 6: API Proxy

**Parent Plan**: [BBWS SDLC Main Plan](./main-plan.md)
**Stage**: 6 of 10
**Status**: ⏳ PENDING
**Last Updated**: 2026-01-01

---

## Objective

Create an API proxy client that agents can use to interact with the deployed API. The proxy provides a clean Python interface for all CRUD operations with proper error handling.

---

## Agent & Skill Assignment

| Role | Agent | Skill |
|------|-------|-------|
| **Primary** | Python_AWS_Developer_Agent | `AWS_Python_Dev.skill.md` |

**Agent Path**: `agentic_architect/Python_AWS_Developer_Agent.md`

---

## Workers

| # | Worker | Task | Status | Output |
|---|--------|------|--------|--------|
| 1 | worker-1-proxy-implementation | Implement API proxy class | ⏳ PENDING | `tests/proxies/` |
| 2 | worker-2-proxy-tests | Write tests for proxy | ⏳ PENDING | `tests/proxies/tests/` |

---

## Worker Instructions

### Worker 1: Proxy Implementation

**Objective**: Create HTTP client proxy for the API

**Inputs**:
- API contracts from Stage 3
- E2E config from Stage 4

**Deliverables**:
```
tests/proxies/
├── __init__.py
├── {entity}_api_proxy.py    # Main proxy class
└── proxy_config.py          # Configuration helper
```

**Implementation Pattern**:
```python
import requests
from typing import Dict, Any, Optional

class ProductAPIProxy:
    """HTTP client proxy for Product Lambda API."""

    API_VERSION = "v1.0"

    def __init__(
        self,
        base_url: str,
        api_key: Optional[str] = None,
        timeout: int = 30,
    ):
        self._base_url = base_url.rstrip("/")
        self._api_key = api_key
        self._timeout = timeout
        self._session = requests.Session()
        self._session.headers.update({
            "Content-Type": "application/json",
            "Accept": "application/json",
        })
        if api_key:
            self._session.headers["x-api-key"] = api_key

    @property
    def endpoint(self) -> str:
        return f"{self._base_url}/{self.API_VERSION}/products"

    def list_products(self) -> Dict[str, Any]:
        response = self._session.get(self.endpoint, timeout=self._timeout)
        response.raise_for_status()
        return response.json()

    def get_product(self, product_id: str) -> Dict[str, Any]:
        response = self._session.get(f"{self.endpoint}/{product_id}", timeout=self._timeout)
        response.raise_for_status()
        return response.json()

    def create_product(self, data: Dict[str, Any]) -> Dict[str, Any]:
        response = self._session.post(self.endpoint, json=data, timeout=self._timeout)
        response.raise_for_status()
        return response.json()

    def update_product(self, product_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        response = self._session.put(f"{self.endpoint}/{product_id}", json=data, timeout=self._timeout)
        response.raise_for_status()
        return response.json()

    def delete_product(self, product_id: str) -> None:
        response = self._session.delete(f"{self.endpoint}/{product_id}", timeout=self._timeout)
        response.raise_for_status()


def create_proxy_for_environment(env_name: str = "dev", api_key: str = None):
    """Factory function to create proxy for specified environment."""
    from tests.e2e.config import get_environment
    config = get_environment(env_name)
    return ProductAPIProxy(base_url=config.base_url, api_key=api_key)
```

**Quality Criteria**:
- [ ] All CRUD operations implemented
- [ ] Environment-aware configuration
- [ ] Standard exceptions (HTTPError, ConnectionError)
- [ ] Session-based for connection pooling

---

### Worker 2: Proxy Tests

**Objective**: Write tests for the API proxy

**Inputs**:
- Proxy implementation from Worker 1

**Deliverables**:
```
tests/proxies/tests/
├── __init__.py
├── conftest.py              # Test fixtures
└── test_{entity}_api_proxy.py
```

**Test Categories**:
- Initialization tests
- CRUD operation tests (mocked responses)
- Error handling tests
- Header configuration tests
- Factory function tests

**Quality Criteria**:
- [ ] 80%+ coverage on proxy code
- [ ] All methods tested
- [ ] Error scenarios covered
- [ ] Mock HTTP responses properly

---

## Stage Outputs

| Output | Description | Location |
|--------|-------------|----------|
| API Proxy | HTTP client class | `{repo}/tests/proxies/` |
| Proxy tests | Unit tests for proxy | `{repo}/tests/proxies/tests/` |

---

## Approval Gate 2

**Location**: After this stage
**Approvers**: Tech Lead, Developer Lead
**Criteria**:
- [ ] All tests passing (unit, mock, proxy)
- [ ] Coverage ≥ 80%
- [ ] Code review completed
- [ ] No security issues

---

## Usage Example

After deployment, agents can use the proxy:

```python
from tests.proxies import ProductAPIProxy, create_proxy_for_environment

# Create proxy for DEV environment
proxy = create_proxy_for_environment("dev")

# CRUD operations
products = proxy.list_products()
product = proxy.get_product("PROD-ABC123")
created = proxy.create_product({"name": "New", "price": "99.99", ...})
updated = proxy.update_product("PROD-ABC123", {"name": "Updated"})
proxy.delete_product("PROD-ABC123")
```

---

## Success Criteria

- [ ] All 2 workers completed
- [ ] Proxy tests passing
- [ ] Proxy coverage ≥ 80%
- [ ] Ready for infrastructure stage
- [ ] Gate 2 approval obtained

---

## Dependencies

**Depends On**: Stage 5 (API Implementation)
**Blocks**: Stage 7 (Infrastructure)

---

## Estimated Duration

| Activity | Agentic | Manual |
|----------|---------|--------|
| Proxy implementation | 15 min | 1 hour |
| Proxy tests | 15 min | 1 hour |
| **Total** | **30 min** | **2 hours** |

---

**Navigation**: [← Stage 5](./stage-5-api-implementation.md) | [Main Plan](./main-plan.md) | [Stage 7: Infrastructure →](./stage-7-infrastructure.md)
