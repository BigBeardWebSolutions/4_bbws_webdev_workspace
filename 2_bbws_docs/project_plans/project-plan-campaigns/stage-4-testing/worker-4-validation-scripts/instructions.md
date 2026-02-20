# Worker Instructions: Validation Scripts

**Worker ID**: worker-4-validation-scripts
**Stage**: Stage 4 - Testing
**Project**: project-plan-campaigns

---

## Task

Create deployment validation scripts for smoke testing and health checks.

---

## Deliverables

### Scripts Directory
```
scripts/
├── validate_deployment.py
├── smoke_test.py
└── health_check.py
```

---

## Script Implementations

### scripts/validate_deployment.py

```python
#!/usr/bin/env python3
"""Deployment validation script for Campaign Lambda service."""

import sys
import json
import argparse
import requests
from typing import Optional


def validate_deployment(api_url: str, verbose: bool = False) -> bool:
    """
    Validate deployment by running comprehensive tests.

    Args:
        api_url: Base API Gateway URL.
        verbose: Print detailed output.

    Returns:
        True if all validations pass.
    """
    print(f"Validating deployment at: {api_url}")
    print("=" * 50)

    all_passed = True
    tests = [
        ("List Campaigns", test_list_campaigns),
        ("CORS Headers", test_cors_headers),
        ("Error Handling", test_error_handling),
    ]

    for test_name, test_func in tests:
        print(f"\nRunning: {test_name}")
        try:
            result = test_func(api_url, verbose)
            status = "PASSED" if result else "FAILED"
            print(f"  Result: {status}")
            if not result:
                all_passed = False
        except Exception as e:
            print(f"  Result: FAILED (Exception: {e})")
            all_passed = False

    print("\n" + "=" * 50)
    print(f"Overall Result: {'PASSED' if all_passed else 'FAILED'}")
    return all_passed


def test_list_campaigns(api_url: str, verbose: bool = False) -> bool:
    """Test list campaigns endpoint."""
    response = requests.get(f"{api_url}/v1.0/campaigns")

    if verbose:
        print(f"    Status: {response.status_code}")
        print(f"    Body: {response.text[:200]}...")

    if response.status_code != 200:
        return False

    data = response.json()
    if "campaigns" not in data or "count" not in data:
        return False

    return True


def test_cors_headers(api_url: str, verbose: bool = False) -> bool:
    """Test CORS headers are present."""
    response = requests.get(f"{api_url}/v1.0/campaigns")

    headers = response.headers
    required_headers = [
        "Access-Control-Allow-Origin",
    ]

    if verbose:
        print(f"    Headers: {dict(headers)}")

    for header in required_headers:
        if header not in headers:
            print(f"    Missing header: {header}")
            return False

    return True


def test_error_handling(api_url: str, verbose: bool = False) -> bool:
    """Test error handling returns proper format."""
    response = requests.get(f"{api_url}/v1.0/campaigns/NONEXISTENT_CODE_12345")

    if verbose:
        print(f"    Status: {response.status_code}")
        print(f"    Body: {response.text}")

    # Should return 404
    if response.status_code != 404:
        return False

    # Should have error structure
    data = response.json()
    if "error" not in data:
        return False

    return True


def main():
    parser = argparse.ArgumentParser(description="Validate Campaign Lambda deployment")
    parser.add_argument("api_url", help="API Gateway base URL")
    parser.add_argument("-v", "--verbose", action="store_true", help="Verbose output")

    args = parser.parse_args()

    success = validate_deployment(args.api_url, args.verbose)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
```

### scripts/smoke_test.py

```python
#!/usr/bin/env python3
"""Smoke test script for Campaign Lambda service."""

import sys
import json
import argparse
import requests
from decimal import Decimal
from datetime import datetime, timedelta


def run_smoke_tests(api_url: str, verbose: bool = False) -> bool:
    """
    Run smoke tests against the Campaign API.

    Args:
        api_url: Base API Gateway URL.
        verbose: Print detailed output.

    Returns:
        True if all smoke tests pass.
    """
    print(f"Running smoke tests against: {api_url}")
    print("=" * 50)

    results = []

    # Test 1: List campaigns (should work even if empty)
    print("\n1. Testing GET /v1.0/campaigns")
    try:
        response = requests.get(f"{api_url}/v1.0/campaigns", timeout=10)
        if response.status_code == 200:
            print("   PASSED: List campaigns returns 200")
            results.append(True)
        else:
            print(f"   FAILED: Expected 200, got {response.status_code}")
            results.append(False)
    except Exception as e:
        print(f"   FAILED: Exception - {e}")
        results.append(False)

    # Test 2: Get non-existent campaign (should return 404)
    print("\n2. Testing GET /v1.0/campaigns/NONEXISTENT")
    try:
        response = requests.get(f"{api_url}/v1.0/campaigns/NONEXISTENT", timeout=10)
        if response.status_code == 404:
            print("   PASSED: Non-existent campaign returns 404")
            results.append(True)
        else:
            print(f"   FAILED: Expected 404, got {response.status_code}")
            results.append(False)
    except Exception as e:
        print(f"   FAILED: Exception - {e}")
        results.append(False)

    # Test 3: Create campaign with invalid data (should return 400)
    print("\n3. Testing POST /v1.0/campaigns with invalid data")
    try:
        response = requests.post(
            f"{api_url}/v1.0/campaigns",
            json={"code": "X"},  # Too short
            timeout=10,
        )
        if response.status_code == 400:
            print("   PASSED: Invalid campaign returns 400")
            results.append(True)
        else:
            print(f"   FAILED: Expected 400, got {response.status_code}")
            results.append(False)
    except Exception as e:
        print(f"   FAILED: Exception - {e}")
        results.append(False)

    # Test 4: Response time check
    print("\n4. Testing response time")
    try:
        import time
        start = time.time()
        response = requests.get(f"{api_url}/v1.0/campaigns", timeout=10)
        elapsed = (time.time() - start) * 1000

        if elapsed < 500:  # Less than 500ms
            print(f"   PASSED: Response time {elapsed:.0f}ms < 500ms")
            results.append(True)
        else:
            print(f"   WARNING: Response time {elapsed:.0f}ms > 500ms")
            results.append(True)  # Warning, not failure
    except Exception as e:
        print(f"   FAILED: Exception - {e}")
        results.append(False)

    # Summary
    passed = sum(results)
    total = len(results)
    print("\n" + "=" * 50)
    print(f"Smoke Tests: {passed}/{total} passed")

    return all(results)


def main():
    parser = argparse.ArgumentParser(description="Run smoke tests")
    parser.add_argument("api_url", help="API Gateway base URL")
    parser.add_argument("-v", "--verbose", action="store_true", help="Verbose output")

    args = parser.parse_args()

    success = run_smoke_tests(args.api_url, args.verbose)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
```

### scripts/health_check.py

```python
#!/usr/bin/env python3
"""Health check script for Campaign Lambda service."""

import sys
import json
import argparse
import requests


def check_health(api_url: str, timeout: int = 5) -> dict:
    """
    Check health of the Campaign API.

    Args:
        api_url: Base API Gateway URL.
        timeout: Request timeout in seconds.

    Returns:
        Health status dictionary.
    """
    status = {
        "healthy": True,
        "api_url": api_url,
        "checks": {},
    }

    # Check 1: API is reachable
    try:
        response = requests.get(f"{api_url}/v1.0/campaigns", timeout=timeout)
        status["checks"]["api_reachable"] = {
            "status": "healthy" if response.status_code == 200 else "unhealthy",
            "response_code": response.status_code,
        }
        if response.status_code != 200:
            status["healthy"] = False
    except requests.Timeout:
        status["checks"]["api_reachable"] = {
            "status": "unhealthy",
            "error": "timeout",
        }
        status["healthy"] = False
    except requests.RequestException as e:
        status["checks"]["api_reachable"] = {
            "status": "unhealthy",
            "error": str(e),
        }
        status["healthy"] = False

    # Check 2: Response format
    try:
        response = requests.get(f"{api_url}/v1.0/campaigns", timeout=timeout)
        data = response.json()
        if "campaigns" in data and "count" in data:
            status["checks"]["response_format"] = {"status": "healthy"}
        else:
            status["checks"]["response_format"] = {
                "status": "unhealthy",
                "error": "Invalid response format",
            }
            status["healthy"] = False
    except Exception as e:
        status["checks"]["response_format"] = {
            "status": "unhealthy",
            "error": str(e),
        }
        status["healthy"] = False

    return status


def main():
    parser = argparse.ArgumentParser(description="Check Campaign API health")
    parser.add_argument("api_url", help="API Gateway base URL")
    parser.add_argument(
        "-t", "--timeout", type=int, default=5, help="Request timeout (seconds)"
    )
    parser.add_argument(
        "-f", "--format", choices=["json", "text"], default="text", help="Output format"
    )

    args = parser.parse_args()

    status = check_health(args.api_url, args.timeout)

    if args.format == "json":
        print(json.dumps(status, indent=2))
    else:
        print(f"Health Check: {args.api_url}")
        print("=" * 50)
        print(f"Overall Status: {'HEALTHY' if status['healthy'] else 'UNHEALTHY'}")
        print("\nChecks:")
        for check, result in status["checks"].items():
            print(f"  - {check}: {result['status']}")
            if "error" in result:
                print(f"    Error: {result['error']}")

    sys.exit(0 if status["healthy"] else 1)


if __name__ == "__main__":
    main()
```

---

## Usage Examples

```bash
# Validate deployment
python scripts/validate_deployment.py https://api.example.com/v1 -v

# Run smoke tests
python scripts/smoke_test.py https://api.example.com/v1

# Health check
python scripts/health_check.py https://api.example.com/v1 --format json
```

---

## Success Criteria

- [ ] validate_deployment.py created
- [ ] smoke_test.py created
- [ ] health_check.py created
- [ ] Scripts are executable
- [ ] Error handling implemented
- [ ] Exit codes are correct

---

## Execution Steps

1. Create scripts/ directory
2. Create validate_deployment.py
3. Create smoke_test.py
4. Create health_check.py
5. Make scripts executable
6. Test locally if possible
7. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
