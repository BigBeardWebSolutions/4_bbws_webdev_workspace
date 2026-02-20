# Stage 7: Integration Testing

**Stage ID**: stage-7-integration-testing
**Parent Project**: Site Builder Bedrock Generation API (project-plan-2)
**Status**: PENDING
**Created**: 2026-01-15

---

## Stage Overview

**Objective**: Integration testing with Site Builder Frontend, end-to-end validation of all API flows.

**Dependencies**: Stage 6 complete (Gate 4 approved)

**Deliverables**:
1. Integration test suite
2. E2E test scenarios
3. Performance test results
4. Bug reports and fixes

**Expected Duration**:
- Agentic: 45-60 minutes
- Manual: 3-4 days

---

## Workers

| Worker | Name | Status | Description |
|--------|------|--------|-------------|
| 1 | Frontend Integration | PENDING | Test Frontend API integration |
| 2 | Streaming Tests | PENDING | Test SSE streaming functionality |
| 3 | Performance Tests | PENDING | Performance and load testing |
| 4 | E2E Scenarios | PENDING | End-to-end test scenarios |

---

## Worker Definitions

### Worker 1: Frontend Integration

**Objective**: Test the integration between Site Builder Frontend and Generation API, validating all API contracts.

**Input Files**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.1_LLD_Site_Builder_Frontend.md`
- `openapi/generation-api.yaml`
- `openapi/agents-api.yaml`
- `openapi/validation-api.yaml`

**Tasks**:
1. Validate API contract compliance
2. Test authentication flow (JWT)
3. Test tenant isolation
4. Test request/response schemas
5. Test error response handling
6. Test CORS configuration

**Output Requirements**:
- Create: `tests/integration/test_frontend_integration.py`
- Create: `tests/integration/test_api_contracts.py`

**Test Cases**:
```python
# tests/integration/test_frontend_integration.py

import pytest
import httpx
from typing import Dict, Any

class TestFrontendIntegration:
    """Integration tests for Frontend API consumption."""

    @pytest.fixture
    def api_client(self, environment: str) -> httpx.AsyncClient:
        """Create API client for environment."""
        base_urls = {
            "dev": "https://api.dev.kimmyai.io/v1",
            "sit": "https://api.sit.kimmyai.io/v1",
            "prod": "https://api.kimmyai.io/v1"
        }
        return httpx.AsyncClient(base_url=base_urls[environment])

    @pytest.fixture
    def auth_headers(self, jwt_token: str, tenant_id: str) -> Dict[str, str]:
        """Create authentication headers."""
        return {
            "Authorization": f"Bearer {jwt_token}",
            "X-Tenant-Id": tenant_id,
            "Content-Type": "application/json"
        }

    @pytest.mark.asyncio
    async def test_generation_endpoint_accepts_valid_request(
        self, api_client: httpx.AsyncClient, auth_headers: Dict
    ):
        """Test generation endpoint accepts valid request from frontend."""
        request_body = {
            "prompt": "Create a landing page for summer sale",
            "templateId": "ecommerce-sale",
            "brandAssets": {
                "primaryColor": "#0066CC",
                "secondaryColor": "#FF6600"
            }
        }

        response = await api_client.post(
            "/sites/test-tenant/generation",
            json=request_body,
            headers=auth_headers
        )

        assert response.status_code == 200
        assert response.headers["content-type"] == "text/event-stream"

    @pytest.mark.asyncio
    async def test_logo_generation_returns_4_options(
        self, api_client: httpx.AsyncClient, auth_headers: Dict
    ):
        """Test logo generation returns 4 options as expected by frontend."""
        request_body = {
            "prompt": "Modern tech logo",
            "style": "modern",
            "colors": ["#0066CC"],
            "count": 4
        }

        response = await api_client.post(
            "/agents/logo",
            json=request_body,
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["type"] == "logo"
        assert len(data["results"]) == 4
        for result in data["results"]:
            assert "id" in result
            assert "url" in result
            assert "preview" in result

    @pytest.mark.asyncio
    async def test_validation_returns_brand_score(
        self, api_client: httpx.AsyncClient, auth_headers: Dict
    ):
        """Test validation endpoint returns brand score."""
        response = await api_client.get(
            "/sites/test-site-id/validate",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert "brandScore" in data
        assert 0 <= data["brandScore"] <= 10
        assert "securityPassed" in data
        assert "performanceMs" in data
        assert "issues" in data

    @pytest.mark.asyncio
    async def test_unauthorized_request_returns_401(
        self, api_client: httpx.AsyncClient
    ):
        """Test unauthorized request returns 401."""
        response = await api_client.post(
            "/sites/test-tenant/generation",
            json={"prompt": "test"}
        )

        assert response.status_code == 401

    @pytest.mark.asyncio
    async def test_cors_headers_present(
        self, api_client: httpx.AsyncClient
    ):
        """Test CORS headers are present for frontend."""
        response = await api_client.options(
            "/sites/test-tenant/generation",
            headers={"Origin": "https://kimmyai.io"}
        )

        assert "Access-Control-Allow-Origin" in response.headers
        assert "Access-Control-Allow-Methods" in response.headers
```

**Success Criteria**:
- All API contracts validated
- Authentication working
- Tenant isolation verified
- CORS configured correctly
- Error responses match frontend expectations

---

### Worker 2: Streaming Tests

**Objective**: Test SSE streaming functionality for page generation, ensuring TTFT and TTLT requirements are met.

**Input Files**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Bedrock_Generation_API.md`
- `src/lambdas/page_generator/streaming.py`

**Tasks**:
1. Test SSE event format
2. Test progress events
3. Test chunk delivery
4. Test completion event
5. Test error event handling
6. Measure TTFT and TTLT

**Output Requirements**:
- Create: `tests/integration/test_streaming.py`

**Test Cases**:
```python
# tests/integration/test_streaming.py

import pytest
import httpx
import time
from typing import AsyncGenerator

class TestStreamingFunctionality:
    """Integration tests for SSE streaming."""

    @pytest.mark.asyncio
    async def test_sse_stream_format(
        self, api_client: httpx.AsyncClient, auth_headers: Dict
    ):
        """Test SSE stream follows correct format."""
        request_body = {"prompt": "Create a simple landing page"}

        async with api_client.stream(
            "POST",
            "/sites/test-tenant/generation",
            json=request_body,
            headers={**auth_headers, "Accept": "text/event-stream"}
        ) as response:
            assert response.status_code == 200

            async for line in response.aiter_lines():
                if line.startswith("data:"):
                    data = json.loads(line[5:].strip())
                    assert "type" in data
                    assert data["type"] in ["progress", "chunk", "complete", "error"]

    @pytest.mark.asyncio
    async def test_ttft_under_2_seconds(
        self, api_client: httpx.AsyncClient, auth_headers: Dict
    ):
        """Test Time To First Token is under 2 seconds."""
        request_body = {"prompt": "Create a landing page"}

        start_time = time.time()
        first_token_time = None

        async with api_client.stream(
            "POST",
            "/sites/test-tenant/generation",
            json=request_body,
            headers={**auth_headers, "Accept": "text/event-stream"}
        ) as response:
            async for line in response.aiter_lines():
                if line.startswith("data:"):
                    data = json.loads(line[5:].strip())
                    if data["type"] == "chunk" and first_token_time is None:
                        first_token_time = time.time()
                        break

        ttft = first_token_time - start_time
        assert ttft < 2.0, f"TTFT {ttft}s exceeds 2s requirement"

    @pytest.mark.asyncio
    async def test_ttlt_under_60_seconds(
        self, api_client: httpx.AsyncClient, auth_headers: Dict
    ):
        """Test Time To Last Token is under 60 seconds."""
        request_body = {"prompt": "Create a comprehensive landing page with hero, features, testimonials"}

        start_time = time.time()

        async with api_client.stream(
            "POST",
            "/sites/test-tenant/generation",
            json=request_body,
            headers={**auth_headers, "Accept": "text/event-stream"}
        ) as response:
            async for line in response.aiter_lines():
                if line.startswith("data:"):
                    data = json.loads(line[5:].strip())
                    if data["type"] == "complete":
                        break

        ttlt = time.time() - start_time
        assert ttlt < 60.0, f"TTLT {ttlt}s exceeds 60s requirement"

    @pytest.mark.asyncio
    async def test_progress_events_emitted(
        self, api_client: httpx.AsyncClient, auth_headers: Dict
    ):
        """Test progress events are emitted during generation."""
        request_body = {"prompt": "Create a landing page"}
        progress_events = []

        async with api_client.stream(
            "POST",
            "/sites/test-tenant/generation",
            json=request_body,
            headers={**auth_headers, "Accept": "text/event-stream"}
        ) as response:
            async for line in response.aiter_lines():
                if line.startswith("data:"):
                    data = json.loads(line[5:].strip())
                    if data["type"] == "progress":
                        progress_events.append(data)

        assert len(progress_events) > 0, "No progress events received"
        assert progress_events[0]["progress"] == 0

    @pytest.mark.asyncio
    async def test_complete_event_contains_brand_score(
        self, api_client: httpx.AsyncClient, auth_headers: Dict
    ):
        """Test completion event includes brand score."""
        request_body = {"prompt": "Create a landing page"}
        complete_event = None

        async with api_client.stream(
            "POST",
            "/sites/test-tenant/generation",
            json=request_body,
            headers={**auth_headers, "Accept": "text/event-stream"}
        ) as response:
            async for line in response.aiter_lines():
                if line.startswith("data:"):
                    data = json.loads(line[5:].strip())
                    if data["type"] == "complete":
                        complete_event = data
                        break

        assert complete_event is not None
        assert "generationId" in complete_event
        assert "brandScore" in complete_event
        assert 0 <= complete_event["brandScore"] <= 10

    @pytest.mark.asyncio
    async def test_error_event_on_failure(
        self, api_client: httpx.AsyncClient, auth_headers: Dict
    ):
        """Test error event is emitted on generation failure."""
        # Send invalid request to trigger error
        request_body = {"prompt": ""}  # Empty prompt should fail

        error_event = None

        async with api_client.stream(
            "POST",
            "/sites/test-tenant/generation",
            json=request_body,
            headers={**auth_headers, "Accept": "text/event-stream"}
        ) as response:
            async for line in response.aiter_lines():
                if line.startswith("data:"):
                    data = json.loads(line[5:].strip())
                    if data["type"] == "error":
                        error_event = data
                        break

        assert error_event is not None
        assert "code" in error_event
        assert "message" in error_event
```

**Success Criteria**:
- SSE format correct
- TTFT < 2s verified
- TTLT < 60s verified
- Progress events working
- Error events working

---

### Worker 3: Performance Tests

**Objective**: Conduct performance and load testing to ensure API meets NFR requirements.

**Input Files**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Bedrock_Generation_API.md`

**Tasks**:
1. Test API response times for non-generation endpoints
2. Test concurrent generation requests
3. Test image generation throughput
4. Test DynamoDB read/write performance
5. Generate performance report

**Output Requirements**:
- Create: `tests/integration/test_performance.py`
- Create: `tests/reports/performance_report.md`

**Test Cases**:
```python
# tests/integration/test_performance.py

import pytest
import httpx
import asyncio
import time
from statistics import mean, stdev

class TestPerformance:
    """Performance tests for Generation API."""

    @pytest.mark.asyncio
    async def test_non_generation_endpoint_under_10ms(
        self, api_client: httpx.AsyncClient, auth_headers: Dict
    ):
        """Test non-generation endpoints respond under 10ms."""
        latencies = []

        for _ in range(100):
            start = time.time()
            response = await api_client.get(
                "/sites/test-tenant/templates",
                headers=auth_headers
            )
            latencies.append((time.time() - start) * 1000)  # Convert to ms

        avg_latency = mean(latencies)
        p95_latency = sorted(latencies)[95]

        assert avg_latency < 10, f"Average latency {avg_latency}ms exceeds 10ms"
        assert p95_latency < 20, f"P95 latency {p95_latency}ms exceeds 20ms"

    @pytest.mark.asyncio
    async def test_concurrent_generations(
        self, api_client: httpx.AsyncClient, auth_headers: Dict
    ):
        """Test handling of 10 concurrent generation requests."""
        async def generate():
            start = time.time()
            response = await api_client.post(
                "/sites/test-tenant/generation",
                json={"prompt": "Create a simple page"},
                headers=auth_headers,
                timeout=120.0
            )
            return time.time() - start, response.status_code

        results = await asyncio.gather(*[generate() for _ in range(10)])

        successful = [r for r in results if r[1] == 200]
        assert len(successful) >= 8, f"Only {len(successful)}/10 requests succeeded"

        durations = [r[0] for r in successful]
        assert max(durations) < 120, "Generation exceeded 120s timeout"

    @pytest.mark.asyncio
    async def test_image_generation_under_30s(
        self, api_client: httpx.AsyncClient, auth_headers: Dict
    ):
        """Test image generation completes under 30 seconds."""
        start = time.time()

        response = await api_client.post(
            "/agents/logo",
            json={
                "prompt": "Tech company logo",
                "count": 4
            },
            headers=auth_headers,
            timeout=60.0
        )

        duration = time.time() - start

        assert response.status_code == 200
        assert duration < 30, f"Image generation took {duration}s, exceeds 30s"

    @pytest.mark.asyncio
    async def test_load_100_requests_per_minute(
        self, api_client: httpx.AsyncClient, auth_headers: Dict
    ):
        """Test system handles 100 requests per minute."""
        async def make_request(i: int):
            endpoint = "/sites/test-tenant/templates" if i % 2 == 0 else "/sites/test-site/validate"
            start = time.time()
            try:
                response = await api_client.get(
                    endpoint,
                    headers=auth_headers,
                    timeout=5.0
                )
                return (time.time() - start, response.status_code, None)
            except Exception as e:
                return (time.time() - start, None, str(e))

        # Send 100 requests in ~60 seconds
        results = []
        for batch in range(10):
            batch_results = await asyncio.gather(*[make_request(i) for i in range(10)])
            results.extend(batch_results)
            await asyncio.sleep(6)  # 10 requests every 6 seconds = 100/minute

        successful = [r for r in results if r[1] == 200]
        error_rate = (100 - len(successful)) / 100

        assert error_rate < 0.05, f"Error rate {error_rate*100}% exceeds 5%"
```

**Performance Report Template**:
```markdown
# Performance Test Report

## Test Environment
- Environment: DEV
- Date: 2026-01-XX
- API Version: 1.0.0

## Results Summary

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Non-gen endpoint latency (avg) | < 10ms | Xms | PASS/FAIL |
| Non-gen endpoint latency (P95) | < 20ms | Xms | PASS/FAIL |
| TTFT | < 2s | Xs | PASS/FAIL |
| TTLT | < 60s | Xs | PASS/FAIL |
| Image generation | < 30s | Xs | PASS/FAIL |
| Concurrent requests (10) | 80% success | X% | PASS/FAIL |
| Load test (100 req/min) | < 5% error | X% | PASS/FAIL |

## Detailed Results
[Test output logs]

## Recommendations
[Optimization suggestions]
```

**Success Criteria**:
- Non-gen latency < 10ms
- TTFT < 2s
- TTLT < 60s
- Image generation < 30s
- 100 req/min with < 5% error rate

---

### Worker 4: E2E Scenarios

**Objective**: Create end-to-end test scenarios covering complete user workflows.

**Input Files**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.1_LLD_Site_Builder_Frontend.md`
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/3.0_BBSW_Site_Builder_HLD.md`

**Tasks**:
1. Create E2E test for page generation workflow
2. Create E2E test for logo + page workflow
3. Create E2E test for validation + deployment workflow
4. Create E2E test for version history workflow
5. Document test scenarios

**Output Requirements**:
- Create: `tests/integration/test_e2e.py`
- Create: `tests/scenarios/e2e_scenarios.md`

**Test Cases**:
```python
# tests/integration/test_e2e.py

import pytest
import httpx

class TestE2EScenarios:
    """End-to-end test scenarios."""

    @pytest.mark.asyncio
    async def test_e2e_page_generation_workflow(
        self, api_client: httpx.AsyncClient, auth_headers: Dict
    ):
        """
        E2E: User generates a landing page from prompt.

        Steps:
        1. Send generation request
        2. Receive streaming response
        3. Get brand score
        4. Verify page saved to state
        """
        # Step 1: Generate page
        generation_id = None
        html_content = []

        async with api_client.stream(
            "POST",
            "/sites/test-tenant/generation",
            json={"prompt": "Create summer sale landing page"},
            headers={**auth_headers, "Accept": "text/event-stream"}
        ) as response:
            async for line in response.aiter_lines():
                if line.startswith("data:"):
                    data = json.loads(line[5:].strip())
                    if data["type"] == "chunk":
                        html_content.append(data["content"])
                    elif data["type"] == "complete":
                        generation_id = data["generationId"]
                        break

        assert generation_id is not None
        assert len(html_content) > 0

        # Step 2: Verify generation state saved
        response = await api_client.get(
            f"/sites/test-tenant/generation/{generation_id}",
            headers=auth_headers
        )
        assert response.status_code == 200
        state = response.json()
        assert state["status"] == "COMPLETE"

        # Step 3: Verify brand score
        response = await api_client.get(
            f"/sites/{generation_id}/brand-score",
            headers=auth_headers
        )
        assert response.status_code == 200
        score = response.json()
        assert score["brandScore"] >= 0

    @pytest.mark.asyncio
    async def test_e2e_logo_then_page_workflow(
        self, api_client: httpx.AsyncClient, auth_headers: Dict
    ):
        """
        E2E: User creates logo then generates page with logo.

        Steps:
        1. Generate logo options
        2. Select logo
        3. Generate page with logo in brand assets
        4. Verify logo appears in page
        """
        # Step 1: Generate logos
        response = await api_client.post(
            "/agents/logo",
            json={"prompt": "Tech company logo", "count": 4},
            headers=auth_headers
        )
        assert response.status_code == 200
        logos = response.json()["results"]
        selected_logo = logos[0]["url"]

        # Step 2: Generate page with logo
        generation_response = None
        async with api_client.stream(
            "POST",
            "/sites/test-tenant/generation",
            json={
                "prompt": "Create tech company landing page",
                "brandAssets": {"logo": selected_logo}
            },
            headers={**auth_headers, "Accept": "text/event-stream"}
        ) as response:
            async for line in response.aiter_lines():
                if line.startswith("data:"):
                    data = json.loads(line[5:].strip())
                    if data["type"] == "complete":
                        generation_response = data
                        break

        assert generation_response is not None

    @pytest.mark.asyncio
    async def test_e2e_validation_deployment_workflow(
        self, api_client: httpx.AsyncClient, auth_headers: Dict
    ):
        """
        E2E: User validates and deploys page.

        Steps:
        1. Generate page
        2. Run validation
        3. If score >= 8, initiate deployment
        4. Verify deployment status
        """
        # Step 1: Generate page (simplified)
        response = await api_client.post(
            "/sites/test-tenant/generation",
            json={"prompt": "Create landing page"},
            headers=auth_headers
        )
        site_id = "test-site-id"

        # Step 2: Validate
        response = await api_client.get(
            f"/sites/{site_id}/validate",
            headers=auth_headers
        )
        assert response.status_code == 200
        validation = response.json()

        # Step 3: Deploy if score >= 8
        if validation["brandScore"] >= 8.0:
            response = await api_client.post(
                f"/sites/test-tenant/deployments",
                json={
                    "siteId": site_id,
                    "environment": "staging"
                },
                headers=auth_headers
            )
            assert response.status_code == 200 or response.status_code == 202

            # Step 4: Verify deployment
            deployment_id = response.json().get("deploymentId")
            if deployment_id:
                response = await api_client.get(
                    f"/sites/test-tenant/deployments/{deployment_id}",
                    headers=auth_headers
                )
                assert response.status_code == 200
```

**Success Criteria**:
- All E2E scenarios pass
- Complete workflows tested
- State transitions verified
- Integration between services confirmed

---

## Stage Completion Criteria

The stage is considered **COMPLETE** when:

1. All 4 workers have completed their outputs
2. Integration tests passing
3. Streaming tests passing
4. Performance tests meeting targets
5. E2E scenarios passing
6. Test reports generated

---

**Stage Owner**: Agentic Project Manager
**Created**: 2026-01-15
**Next Action**: Wait for Stage 6 completion and Gate 4 approval
