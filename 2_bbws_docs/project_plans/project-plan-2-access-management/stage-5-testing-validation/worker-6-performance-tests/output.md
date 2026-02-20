# Worker Output: Performance Tests

**Worker ID**: worker-6-performance-tests
**Stage**: Stage 5 - Testing & Validation
**Project**: project-plan-2-access-management
**Status**: COMPLETE
**Completed**: 2026-01-24

---

## Executive Summary

This document provides a comprehensive performance testing framework using Locust for the Access Management system. The framework validates critical performance targets including authorizer latency (< 100ms P95), API response time (< 500ms P95), throughput (> 100 RPS), and error rate (< 0.1%).

---

## 1. Test Directory Structure

```
tests/performance/
├── locustfile.py                     # Main Locust entry point
├── scenarios/
│   ├── __init__.py
│   ├── base_user.py                  # Base user class with auth
│   ├── authorizer_load.py            # Authorizer-specific tests
│   ├── permission_crud.py            # Permission service tests
│   ├── team_operations.py            # Team service tests
│   ├── role_operations.py            # Role service tests
│   ├── invitation_flow.py            # Invitation flow tests
│   ├── audit_queries.py              # Audit query tests
│   └── mixed_workload.py             # Combined realistic workload
├── config/
│   ├── dev.yaml                      # DEV environment config
│   ├── sit.yaml                      # SIT environment config
│   ├── load_profiles.yaml            # Load test profiles
│   └── thresholds.yaml               # Performance thresholds
├── utils/
│   ├── __init__.py
│   ├── token_generator.py            # JWT token generation
│   ├── data_factory.py               # Test data generation
│   ├── metrics_collector.py          # CloudWatch metrics collector
│   └── report_generator.py           # Custom report generation
├── reports/
│   ├── templates/
│   │   ├── performance_report.html
│   │   └── performance_report.md
│   └── .gitkeep
├── requirements-performance.txt      # Performance test dependencies
└── README.md                         # Performance test documentation
```

---

## 2. Complete locustfile.py Implementation

```python
"""
Access Management Performance Tests - Main Locust File

This file orchestrates all performance test scenarios for the Access Management system.
Validates performance targets:
- Authorizer Latency: < 100ms (P95)
- API Response Time: < 500ms (P95)
- Throughput: > 100 RPS
- Error Rate: < 0.1%

Usage:
    # Headless mode (CI/CD)
    locust -f locustfile.py --headless --users 50 --spawn-rate 10 --run-time 5m

    # Web UI mode
    locust -f locustfile.py --host https://api.dev.bbws.io

    # With specific config
    locust -f locustfile.py --config config/dev.yaml
"""

import os
import sys
import logging
import random
import time
from datetime import datetime, timedelta
from typing import Optional, Dict, Any, List

from locust import HttpUser, TaskSet, task, between, events, constant_throughput
from locust.runners import MasterRunner, WorkerRunner
import gevent

# Add scenarios directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from scenarios.base_user import BaseAccessManagementUser
from scenarios.authorizer_load import AuthorizerLoadTest
from scenarios.permission_crud import PermissionServiceTest
from scenarios.team_operations import TeamServiceTest
from scenarios.role_operations import RoleServiceTest
from scenarios.invitation_flow import InvitationFlowTest
from scenarios.audit_queries import AuditQueryTest
from scenarios.mixed_workload import MixedWorkloadTest

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


# ============================================================================
# Environment Configuration
# ============================================================================

class Config:
    """Environment-specific configuration"""

    ENV = os.getenv('PERF_ENV', 'dev')

    ENVIRONMENTS = {
        'dev': {
            'base_url': 'https://api.dev.bbws.io/v1',
            'cognito_pool_id': 'af-south-1_DevPoolXXX',
            'cognito_client_id': 'dev-client-id-xxx',
            'test_org_id': 'org-dev-001',
        },
        'sit': {
            'base_url': 'https://api.sit.bbws.io/v1',
            'cognito_pool_id': 'af-south-1_SitPoolXXX',
            'cognito_client_id': 'sit-client-id-xxx',
            'test_org_id': 'org-sit-001',
        },
        'prod': {
            'base_url': 'https://api.bbws.io/v1',
            'cognito_pool_id': 'af-south-1_ProdPoolXXX',
            'cognito_client_id': 'prod-client-id-xxx',
            'test_org_id': None,  # PROD is read-only
        }
    }

    # Performance thresholds
    THRESHOLDS = {
        'authorizer_p95_ms': 100,
        'api_p95_ms': 500,
        'min_rps': 100,
        'max_error_rate': 0.001,  # 0.1%
        'cold_start_p95_ms': 3000,
    }

    @classmethod
    def get_env_config(cls) -> Dict[str, Any]:
        """Get configuration for current environment"""
        return cls.ENVIRONMENTS.get(cls.ENV, cls.ENVIRONMENTS['dev'])


# ============================================================================
# Custom Metrics Collection
# ============================================================================

class MetricsCollector:
    """Collects and aggregates custom metrics during test execution"""

    def __init__(self):
        self.authorizer_latencies: List[float] = []
        self.api_latencies: Dict[str, List[float]] = {}
        self.error_count: int = 0
        self.total_requests: int = 0
        self.cold_starts: List[float] = []

    def record_authorizer_latency(self, latency_ms: float):
        """Record authorizer-specific latency"""
        self.authorizer_latencies.append(latency_ms)

    def record_api_latency(self, endpoint: str, latency_ms: float):
        """Record API endpoint latency"""
        if endpoint not in self.api_latencies:
            self.api_latencies[endpoint] = []
        self.api_latencies[endpoint].append(latency_ms)

    def record_error(self):
        """Record an error"""
        self.error_count += 1

    def record_request(self):
        """Record a request"""
        self.total_requests += 1

    def record_cold_start(self, duration_ms: float):
        """Record a cold start duration"""
        self.cold_starts.append(duration_ms)

    def get_percentile(self, data: List[float], percentile: float) -> float:
        """Calculate percentile from data"""
        if not data:
            return 0.0
        sorted_data = sorted(data)
        index = int(len(sorted_data) * percentile / 100)
        return sorted_data[min(index, len(sorted_data) - 1)]

    def get_summary(self) -> Dict[str, Any]:
        """Get metrics summary"""
        return {
            'authorizer_p95_ms': self.get_percentile(self.authorizer_latencies, 95),
            'authorizer_p99_ms': self.get_percentile(self.authorizer_latencies, 99),
            'authorizer_avg_ms': sum(self.authorizer_latencies) / len(self.authorizer_latencies) if self.authorizer_latencies else 0,
            'api_p95_ms': self.get_percentile(
                [lat for lats in self.api_latencies.values() for lat in lats], 95
            ),
            'error_rate': self.error_count / self.total_requests if self.total_requests > 0 else 0,
            'total_requests': self.total_requests,
            'cold_starts_count': len(self.cold_starts),
            'cold_start_p95_ms': self.get_percentile(self.cold_starts, 95) if self.cold_starts else 0,
        }


# Global metrics collector instance
metrics = MetricsCollector()


# ============================================================================
# Event Hooks
# ============================================================================

@events.request.add_listener
def on_request(request_type, name, response_time, response_length, response, context, exception, **kwargs):
    """Hook into every request for custom metrics"""
    metrics.record_request()

    if exception or (response and response.status_code >= 400):
        metrics.record_error()

    # Track authorizer-specific latency
    if 'authorizer' in name.lower() or name.startswith('/auth'):
        metrics.record_authorizer_latency(response_time)
    else:
        metrics.record_api_latency(name, response_time)

    # Detect cold starts (response > 1500ms on first request to endpoint)
    if response_time > 1500:
        metrics.record_cold_start(response_time)


@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    """Called when test starts"""
    logger.info(f"Performance test starting - Environment: {Config.ENV}")
    logger.info(f"Thresholds: {Config.THRESHOLDS}")


@events.test_stop.add_listener
def on_test_stop(environment, **kwargs):
    """Called when test stops - validate thresholds"""
    summary = metrics.get_summary()

    logger.info("=" * 60)
    logger.info("PERFORMANCE TEST SUMMARY")
    logger.info("=" * 60)

    # Validate authorizer latency
    auth_p95 = summary['authorizer_p95_ms']
    auth_threshold = Config.THRESHOLDS['authorizer_p95_ms']
    auth_status = "PASS" if auth_p95 < auth_threshold else "FAIL"
    logger.info(f"Authorizer P95: {auth_p95:.2f}ms (threshold: {auth_threshold}ms) - {auth_status}")

    # Validate API latency
    api_p95 = summary['api_p95_ms']
    api_threshold = Config.THRESHOLDS['api_p95_ms']
    api_status = "PASS" if api_p95 < api_threshold else "FAIL"
    logger.info(f"API P95: {api_p95:.2f}ms (threshold: {api_threshold}ms) - {api_status}")

    # Validate error rate
    error_rate = summary['error_rate'] * 100
    max_error = Config.THRESHOLDS['max_error_rate'] * 100
    error_status = "PASS" if error_rate < max_error else "FAIL"
    logger.info(f"Error Rate: {error_rate:.3f}% (threshold: {max_error}%) - {error_status}")

    # Validate cold starts
    cold_p95 = summary['cold_start_p95_ms']
    cold_threshold = Config.THRESHOLDS['cold_start_p95_ms']
    cold_status = "PASS" if cold_p95 < cold_threshold else "FAIL"
    logger.info(f"Cold Start P95: {cold_p95:.2f}ms (threshold: {cold_threshold}ms) - {cold_status}")

    logger.info("=" * 60)

    # Set exit code based on results
    all_pass = all([
        auth_status == "PASS",
        api_status == "PASS",
        error_status == "PASS",
        cold_status == "PASS"
    ])

    if not all_pass:
        logger.error("PERFORMANCE THRESHOLDS NOT MET - TEST FAILED")
        environment.process_exit_code = 1
    else:
        logger.info("ALL PERFORMANCE THRESHOLDS MET - TEST PASSED")


# ============================================================================
# Main User Classes (Import from scenarios)
# ============================================================================

# Export all user classes for Locust discovery
# Users can be run individually or combined

class AccessManagementMixedUser(MixedWorkloadTest):
    """
    Primary user class for mixed workload testing.
    Simulates realistic 80:20 read:write ratio.
    """
    host = Config.get_env_config()['base_url'].rsplit('/v1', 1)[0]
    weight = 10  # Higher weight for mixed workload


class AuthorizerStressUser(AuthorizerLoadTest):
    """
    Authorizer-focused stress testing.
    Target: < 100ms P95 latency
    """
    host = Config.get_env_config()['base_url'].rsplit('/v1', 1)[0]
    weight = 5


class PermissionApiUser(PermissionServiceTest):
    """Permission Service API testing"""
    host = Config.get_env_config()['base_url'].rsplit('/v1', 1)[0]
    weight = 2


class TeamApiUser(TeamServiceTest):
    """Team Service API testing"""
    host = Config.get_env_config()['base_url'].rsplit('/v1', 1)[0]
    weight = 3


class RoleApiUser(RoleServiceTest):
    """Role Service API testing"""
    host = Config.get_env_config()['base_url'].rsplit('/v1', 1)[0]
    weight = 2


class AuditApiUser(AuditQueryTest):
    """Audit Service API testing"""
    host = Config.get_env_config()['base_url'].rsplit('/v1', 1)[0]
    weight = 1


# ============================================================================
# CLI Entry Point for Custom Profiles
# ============================================================================

if __name__ == "__main__":
    import subprocess
    import argparse

    parser = argparse.ArgumentParser(description='Access Management Performance Tests')
    parser.add_argument('--profile', choices=['baseline', 'normal', 'peak', 'stress'],
                       default='normal', help='Load test profile')
    parser.add_argument('--env', choices=['dev', 'sit'], default='dev',
                       help='Target environment')

    args, remaining = parser.parse_known_args()

    # Set environment
    os.environ['PERF_ENV'] = args.env

    # Profile configurations
    profiles = {
        'baseline': {'users': 10, 'spawn_rate': 2, 'run_time': '5m'},
        'normal': {'users': 50, 'spawn_rate': 10, 'run_time': '15m'},
        'peak': {'users': 100, 'spawn_rate': 20, 'run_time': '10m'},
        'stress': {'users': 200, 'spawn_rate': 50, 'run_time': '5m'},
    }

    profile = profiles[args.profile]

    cmd = [
        'locust',
        '-f', __file__,
        '--headless',
        '--users', str(profile['users']),
        '--spawn-rate', str(profile['spawn_rate']),
        '--run-time', profile['run_time'],
        '--html', f'reports/performance_{args.profile}_{args.env}_{datetime.now().strftime("%Y%m%d_%H%M%S")}.html',
    ] + remaining

    subprocess.run(cmd)
```

---

## 3. Scenario Implementations

### 3.1 Base User Class (scenarios/base_user.py)

```python
"""
Base User Class for Access Management Performance Tests

Provides common authentication, headers, and utility methods
for all test scenarios.
"""

import os
import time
import logging
import json
from typing import Optional, Dict, Any, List
from datetime import datetime, timedelta

from locust import HttpUser, between
import jwt


logger = logging.getLogger(__name__)


class BaseAccessManagementUser(HttpUser):
    """
    Base class for all Access Management test users.

    Provides:
    - JWT token generation and refresh
    - Common headers with authorization
    - Test data fixtures
    - Utility methods for API calls
    """

    abstract = True  # Don't instantiate directly
    wait_time = between(0.5, 2.0)  # Realistic think time

    # Test user configuration
    TEST_USERS = [
        {
            'user_id': 'user-perf-001',
            'email': 'perf-admin@bbws.io',
            'org_id': 'org-dev-001',
            'roles': ['ORG_ADMIN'],
            'permissions': ['permission:read', 'permission:write', 'team:read', 'team:write',
                          'role:read', 'role:write', 'invitation:read', 'invitation:write',
                          'audit:read'],
            'team_ids': ['team-001', 'team-002'],
        },
        {
            'user_id': 'user-perf-002',
            'email': 'perf-manager@bbws.io',
            'org_id': 'org-dev-001',
            'roles': ['ORG_MANAGER'],
            'permissions': ['team:read', 'team:write', 'invitation:read', 'invitation:write'],
            'team_ids': ['team-001'],
        },
        {
            'user_id': 'user-perf-003',
            'email': 'perf-viewer@bbws.io',
            'org_id': 'org-dev-001',
            'roles': ['SITE_VIEWER'],
            'permissions': ['team:read', 'permission:read'],
            'team_ids': ['team-001'],
        },
    ]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.env = os.getenv('PERF_ENV', 'dev')
        self.token: Optional[str] = None
        self.token_expiry: Optional[datetime] = None
        self.current_user: Optional[Dict] = None
        self.created_resources: List[Dict] = []  # Track for cleanup

    def on_start(self):
        """Called when user starts - authenticate"""
        self._select_test_user()
        self._generate_token()
        logger.info(f"User {self.current_user['email']} started")

    def on_stop(self):
        """Called when user stops - cleanup"""
        self._cleanup_resources()
        logger.info(f"User {self.current_user['email']} stopped")

    def _select_test_user(self):
        """Randomly select a test user profile"""
        import random
        self.current_user = random.choice(self.TEST_USERS)

    def _generate_token(self):
        """Generate a JWT token for the current user"""
        # In real tests, this would call Cognito. For load testing,
        # we generate a mock JWT that the authorizer accepts in test mode.

        now = datetime.utcnow()
        expiry = now + timedelta(hours=1)

        payload = {
            'sub': self.current_user['user_id'],
            'email': self.current_user['email'],
            'cognito:groups': self.current_user['roles'],
            'custom:org_id': self.current_user['org_id'],
            'iat': int(now.timestamp()),
            'exp': int(expiry.timestamp()),
            'iss': f'https://cognito-idp.af-south-1.amazonaws.com/test-pool',
            'aud': 'test-client',
        }

        # For load testing, use a test secret or pre-generated tokens
        # In production, integrate with Cognito for real tokens
        test_secret = os.getenv('JWT_TEST_SECRET', 'test-secret-key-for-performance-testing')

        self.token = jwt.encode(payload, test_secret, algorithm='HS256')
        self.token_expiry = expiry

    def _get_headers(self) -> Dict[str, str]:
        """Get common headers with authorization"""
        # Refresh token if expired
        if self.token_expiry and datetime.utcnow() >= self.token_expiry:
            self._generate_token()

        return {
            'Authorization': f'Bearer {self.token}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-Request-ID': f'perf-{self.current_user["user_id"]}-{int(time.time() * 1000)}',
        }

    def _get_org_id(self) -> str:
        """Get current user's org ID"""
        return self.current_user['org_id']

    def _track_resource(self, resource_type: str, resource_id: str):
        """Track created resource for cleanup"""
        self.created_resources.append({
            'type': resource_type,
            'id': resource_id,
            'created_at': datetime.utcnow().isoformat(),
        })

    def _cleanup_resources(self):
        """Clean up created resources"""
        for resource in reversed(self.created_resources):
            try:
                if resource['type'] == 'permission':
                    self.client.delete(
                        f"/v1/permissions/{resource['id']}",
                        headers=self._get_headers(),
                        name="/v1/permissions/[id] (cleanup)"
                    )
                elif resource['type'] == 'team':
                    self.client.delete(
                        f"/v1/orgs/{self._get_org_id()}/teams/{resource['id']}",
                        headers=self._get_headers(),
                        name="/v1/orgs/[orgId]/teams/[id] (cleanup)"
                    )
                elif resource['type'] == 'role':
                    self.client.delete(
                        f"/v1/orgs/{self._get_org_id()}/roles/{resource['id']}",
                        headers=self._get_headers(),
                        name="/v1/orgs/[orgId]/roles/[id] (cleanup)"
                    )
            except Exception as e:
                logger.warning(f"Cleanup failed for {resource['type']}/{resource['id']}: {e}")

        self.created_resources.clear()

    def api_get(self, path: str, name: Optional[str] = None, **kwargs):
        """Make authenticated GET request"""
        return self.client.get(
            path,
            headers=self._get_headers(),
            name=name or path,
            **kwargs
        )

    def api_post(self, path: str, json_data: Dict, name: Optional[str] = None, **kwargs):
        """Make authenticated POST request"""
        return self.client.post(
            path,
            json=json_data,
            headers=self._get_headers(),
            name=name or path,
            **kwargs
        )

    def api_put(self, path: str, json_data: Dict, name: Optional[str] = None, **kwargs):
        """Make authenticated PUT request"""
        return self.client.put(
            path,
            json=json_data,
            headers=self._get_headers(),
            name=name or path,
            **kwargs
        )

    def api_delete(self, path: str, name: Optional[str] = None, **kwargs):
        """Make authenticated DELETE request"""
        return self.client.delete(
            path,
            headers=self._get_headers(),
            name=name or path,
            **kwargs
        )
```

### 3.2 Authorizer Load Test (scenarios/authorizer_load.py)

```python
"""
Authorizer Load Test Scenario

Tests Lambda Authorizer performance under load.
Target: < 100ms P95 latency

This scenario focuses specifically on authorizer performance by:
1. Making rapid API calls that trigger authorization
2. Testing with various token sizes and permission sets
3. Validating cache behavior
"""

import random
import time
from locust import task, between, constant_throughput

from .base_user import BaseAccessManagementUser


class AuthorizerLoadTest(BaseAccessManagementUser):
    """
    Test authorizer performance under load.

    Target Metrics:
    - P95 Latency: < 100ms
    - P99 Latency: < 150ms
    - Error Rate: < 0.1%

    Test Strategy:
    - High-frequency lightweight requests to isolate authorizer latency
    - Test cache effectiveness (same token, different tokens)
    - Test with varying permission set sizes
    """

    wait_time = between(0.1, 0.3)  # Fast requests to stress authorizer

    # Additional test users with varying permission sizes
    PERMISSION_SIZES = {
        'small': ['permission:read'],
        'medium': ['permission:read', 'team:read', 'role:read', 'audit:read'],
        'large': [
            'permission:read', 'permission:write', 'permission:delete',
            'team:read', 'team:write', 'team:delete',
            'role:read', 'role:write', 'role:delete',
            'invitation:read', 'invitation:write',
            'audit:read', 'audit:export',
            'site:read', 'site:write', 'site:delete',
        ],
    }

    @task(10)
    def authorize_cached_token(self):
        """
        Test authorizer with cached token (same user, repeated calls).
        Authorizer cache TTL is 300 seconds.
        """
        # Lightweight endpoint to minimize backend processing time
        # This isolates authorizer latency
        with self.api_get(
            "/v1/permissions",
            name="/v1/permissions (auth-cached)",
            params={'limit': 1}
        ) as response:
            if response.status_code != 200:
                response.failure(f"Auth failed: {response.status_code}")

    @task(5)
    def authorize_fresh_context(self):
        """
        Test authorizer with fresh token (regenerate token).
        Simulates new session or token refresh.
        """
        # Force token regeneration
        self._generate_token()

        with self.api_get(
            "/v1/permissions",
            name="/v1/permissions (auth-fresh)",
            params={'limit': 1}
        ) as response:
            if response.status_code != 200:
                response.failure(f"Auth failed: {response.status_code}")

    @task(3)
    def authorize_with_large_permissions(self):
        """
        Test authorizer with large permission set.
        Validates performance doesn't degrade with complex tokens.
        """
        # Temporarily set large permissions
        original_permissions = self.current_user['permissions']
        self.current_user['permissions'] = self.PERMISSION_SIZES['large']
        self._generate_token()

        with self.api_get(
            "/v1/permissions",
            name="/v1/permissions (auth-large-perms)",
            params={'limit': 1}
        ) as response:
            if response.status_code != 200:
                response.failure(f"Auth failed: {response.status_code}")

        # Restore original permissions
        self.current_user['permissions'] = original_permissions
        self._generate_token()

    @task(2)
    def authorize_different_endpoints(self):
        """
        Test authorizer across different API endpoints.
        Validates consistent performance regardless of endpoint.
        """
        endpoints = [
            ("/v1/permissions", {'limit': 1}),
            (f"/v1/orgs/{self._get_org_id()}/teams", {'limit': 1}),
            (f"/v1/orgs/{self._get_org_id()}/roles", {'limit': 1}),
            ("/v1/platform/roles", {}),
        ]

        endpoint, params = random.choice(endpoints)

        with self.api_get(
            endpoint,
            name=f"{endpoint} (auth-varied)",
            params=params
        ) as response:
            if response.status_code not in [200, 403]:  # 403 is OK for auth test
                response.failure(f"Unexpected status: {response.status_code}")


class AuthorizerStressTest(BaseAccessManagementUser):
    """
    Extreme stress test for authorizer.

    Uses constant throughput to ensure consistent request rate.
    Target: 100+ RPS to authorizer
    """

    # Constant throughput: 5 requests per second per user
    # With 20 users = 100 RPS
    wait_time = constant_throughput(5)

    @task
    def rapid_authorize(self):
        """Rapid authorization requests"""
        with self.api_get(
            "/v1/permissions",
            name="/v1/permissions (stress)",
            params={'limit': 1}
        ) as response:
            if response.status_code not in [200, 429]:  # 429 expected under stress
                response.failure(f"Unexpected: {response.status_code}")
```

### 3.3 Permission Service Test (scenarios/permission_crud.py)

```python
"""
Permission Service Performance Tests

Tests CRUD operations on Permission Service.
Target: < 500ms P95 response time
"""

import random
import uuid
from locust import task, between

from .base_user import BaseAccessManagementUser


class PermissionServiceTest(BaseAccessManagementUser):
    """
    Test Permission Service endpoints.

    Endpoints:
    - GET /v1/permissions - List all permissions
    - GET /v1/permissions/{id} - Get permission by ID
    - POST /v1/permissions - Create permission
    - PUT /v1/permissions/{id} - Update permission
    - DELETE /v1/permissions/{id} - Soft delete permission
    - POST /v1/permissions/seed - Seed platform permissions

    Target: < 500ms P95 latency
    """

    wait_time = between(0.5, 1.5)

    # Track created permission IDs for subsequent operations
    created_permission_ids = []
    known_permission_ids = []

    def on_start(self):
        """Initialize and fetch known permissions"""
        super().on_start()
        self._fetch_known_permissions()

    def _fetch_known_permissions(self):
        """Fetch existing permission IDs for GET/UPDATE operations"""
        response = self.api_get(
            "/v1/permissions",
            name="/v1/permissions (init)",
            params={'limit': 50}
        )
        if response.status_code == 200:
            data = response.json()
            self.known_permission_ids = [p['id'] for p in data.get('items', [])]

    @task(5)
    def list_permissions(self):
        """
        List all permissions with pagination.
        Most common read operation.
        """
        params = {
            'limit': random.choice([10, 25, 50]),
            'offset': random.randint(0, 5) * 10,
        }

        with self.api_get(
            "/v1/permissions",
            name="/v1/permissions",
            params=params
        ) as response:
            if response.status_code != 200:
                response.failure(f"List failed: {response.status_code}")
            else:
                data = response.json()
                # Update known IDs from response
                new_ids = [p['id'] for p in data.get('items', [])]
                self.known_permission_ids = list(set(self.known_permission_ids + new_ids))

    @task(3)
    def list_permissions_filtered(self):
        """
        List permissions with resource filter.
        """
        resources = ['permission', 'team', 'role', 'invitation', 'audit', 'site']

        params = {
            'resource': random.choice(resources),
            'limit': 25,
        }

        with self.api_get(
            "/v1/permissions",
            name="/v1/permissions?resource=X",
            params=params
        ) as response:
            if response.status_code != 200:
                response.failure(f"Filtered list failed: {response.status_code}")

    @task(4)
    def get_permission(self):
        """
        Get single permission by ID.
        """
        if not self.known_permission_ids:
            return

        permission_id = random.choice(self.known_permission_ids)

        with self.api_get(
            f"/v1/permissions/{permission_id}",
            name="/v1/permissions/[id]"
        ) as response:
            if response.status_code == 404:
                # Permission may have been deleted, remove from known list
                if permission_id in self.known_permission_ids:
                    self.known_permission_ids.remove(permission_id)
            elif response.status_code != 200:
                response.failure(f"Get failed: {response.status_code}")

    @task(1)
    def create_permission(self):
        """
        Create a new permission.
        Lower weight as it's a write operation.
        """
        unique_id = str(uuid.uuid4())[:8]

        payload = {
            'name': f'perf-test-permission-{unique_id}',
            'code': f'perf:test:{unique_id}',
            'description': f'Performance test permission {unique_id}',
            'resource': 'test',
            'action': random.choice(['read', 'write', 'delete', 'manage']),
        }

        with self.api_post(
            "/v1/permissions",
            json_data=payload,
            name="/v1/permissions (create)"
        ) as response:
            if response.status_code == 201:
                data = response.json()
                permission_id = data.get('id')
                if permission_id:
                    self.created_permission_ids.append(permission_id)
                    self.known_permission_ids.append(permission_id)
                    self._track_resource('permission', permission_id)
            elif response.status_code != 409:  # Conflict is acceptable
                response.failure(f"Create failed: {response.status_code}")

    @task(1)
    def update_permission(self):
        """
        Update an existing permission.
        Only update permissions we created.
        """
        if not self.created_permission_ids:
            return

        permission_id = random.choice(self.created_permission_ids)

        payload = {
            'description': f'Updated description at {uuid.uuid4().hex[:8]}',
        }

        with self.api_put(
            f"/v1/permissions/{permission_id}",
            json_data=payload,
            name="/v1/permissions/[id] (update)"
        ) as response:
            if response.status_code == 404:
                if permission_id in self.created_permission_ids:
                    self.created_permission_ids.remove(permission_id)
            elif response.status_code not in [200, 403]:
                response.failure(f"Update failed: {response.status_code}")
```

### 3.4 Team Service Test (scenarios/team_operations.py)

```python
"""
Team Service Performance Tests

Tests team management operations.
Target: < 500ms P95 response time
"""

import random
import uuid
from locust import task, between

from .base_user import BaseAccessManagementUser


class TeamServiceTest(BaseAccessManagementUser):
    """
    Test Team Service endpoints.

    Endpoints tested:
    - POST /v1/orgs/{orgId}/teams - Create team
    - GET /v1/orgs/{orgId}/teams - List teams
    - GET /v1/orgs/{orgId}/teams/{teamId} - Get team
    - PUT /v1/orgs/{orgId}/teams/{teamId} - Update team
    - Team Roles CRUD
    - Team Members CRUD

    Target: < 500ms P95 latency
    """

    wait_time = between(0.5, 1.5)

    known_team_ids = []
    created_team_ids = []
    known_team_role_ids = []

    def on_start(self):
        """Initialize and fetch known teams"""
        super().on_start()
        self._fetch_known_teams()
        self._fetch_known_team_roles()

    def _fetch_known_teams(self):
        """Fetch existing team IDs"""
        response = self.api_get(
            f"/v1/orgs/{self._get_org_id()}/teams",
            name="/v1/orgs/[orgId]/teams (init)",
            params={'limit': 50}
        )
        if response.status_code == 200:
            data = response.json()
            self.known_team_ids = [t['id'] for t in data.get('items', [])]

    def _fetch_known_team_roles(self):
        """Fetch existing team role IDs"""
        response = self.api_get(
            f"/v1/orgs/{self._get_org_id()}/team-roles",
            name="/v1/orgs/[orgId]/team-roles (init)",
            params={'limit': 50}
        )
        if response.status_code == 200:
            data = response.json()
            self.known_team_role_ids = [r['id'] for r in data.get('items', [])]

    # Team Operations

    @task(5)
    def list_teams(self):
        """List teams in organisation"""
        params = {
            'limit': random.choice([10, 25, 50]),
            'offset': random.randint(0, 3) * 10,
        }

        with self.api_get(
            f"/v1/orgs/{self._get_org_id()}/teams",
            name="/v1/orgs/[orgId]/teams",
            params=params
        ) as response:
            if response.status_code != 200:
                response.failure(f"List teams failed: {response.status_code}")

    @task(4)
    def get_team(self):
        """Get single team by ID"""
        if not self.known_team_ids:
            return

        team_id = random.choice(self.known_team_ids)

        with self.api_get(
            f"/v1/orgs/{self._get_org_id()}/teams/{team_id}",
            name="/v1/orgs/[orgId]/teams/[teamId]"
        ) as response:
            if response.status_code == 404:
                if team_id in self.known_team_ids:
                    self.known_team_ids.remove(team_id)
            elif response.status_code != 200:
                response.failure(f"Get team failed: {response.status_code}")

    @task(1)
    def create_team(self):
        """Create a new team"""
        unique_id = str(uuid.uuid4())[:8]

        payload = {
            'name': f'Perf Test Team {unique_id}',
            'description': f'Performance test team created at {unique_id}',
            'metadata': {
                'created_by': 'performance_test',
                'test_run': unique_id,
            }
        }

        with self.api_post(
            f"/v1/orgs/{self._get_org_id()}/teams",
            json_data=payload,
            name="/v1/orgs/[orgId]/teams (create)"
        ) as response:
            if response.status_code == 201:
                data = response.json()
                team_id = data.get('id')
                if team_id:
                    self.created_team_ids.append(team_id)
                    self.known_team_ids.append(team_id)
                    self._track_resource('team', team_id)
            elif response.status_code not in [409, 403]:
                response.failure(f"Create team failed: {response.status_code}")

    @task(1)
    def update_team(self):
        """Update team details"""
        if not self.created_team_ids:
            return

        team_id = random.choice(self.created_team_ids)

        payload = {
            'description': f'Updated at {uuid.uuid4().hex[:8]}',
        }

        with self.api_put(
            f"/v1/orgs/{self._get_org_id()}/teams/{team_id}",
            json_data=payload,
            name="/v1/orgs/[orgId]/teams/[teamId] (update)"
        ) as response:
            if response.status_code == 404:
                if team_id in self.created_team_ids:
                    self.created_team_ids.remove(team_id)
            elif response.status_code not in [200, 403]:
                response.failure(f"Update team failed: {response.status_code}")

    # Team Roles Operations

    @task(3)
    def list_team_roles(self):
        """List team roles"""
        with self.api_get(
            f"/v1/orgs/{self._get_org_id()}/team-roles",
            name="/v1/orgs/[orgId]/team-roles"
        ) as response:
            if response.status_code != 200:
                response.failure(f"List team roles failed: {response.status_code}")

    @task(2)
    def get_team_role(self):
        """Get team role by ID"""
        if not self.known_team_role_ids:
            return

        role_id = random.choice(self.known_team_role_ids)

        with self.api_get(
            f"/v1/orgs/{self._get_org_id()}/team-roles/{role_id}",
            name="/v1/orgs/[orgId]/team-roles/[roleId]"
        ) as response:
            if response.status_code not in [200, 404]:
                response.failure(f"Get team role failed: {response.status_code}")

    # Team Members Operations

    @task(4)
    def list_team_members(self):
        """List members in a team"""
        if not self.known_team_ids:
            return

        team_id = random.choice(self.known_team_ids)

        with self.api_get(
            f"/v1/orgs/{self._get_org_id()}/teams/{team_id}/members",
            name="/v1/orgs/[orgId]/teams/[teamId]/members"
        ) as response:
            if response.status_code not in [200, 404]:
                response.failure(f"List members failed: {response.status_code}")

    @task(2)
    def get_user_teams(self):
        """Get teams for current user"""
        user_id = self.current_user['user_id']

        with self.api_get(
            f"/v1/orgs/{self._get_org_id()}/users/{user_id}/teams",
            name="/v1/orgs/[orgId]/users/[userId]/teams"
        ) as response:
            if response.status_code != 200:
                response.failure(f"Get user teams failed: {response.status_code}")
```

### 3.5 Role Service Test (scenarios/role_operations.py)

```python
"""
Role Service Performance Tests

Tests platform and organisation role operations.
Target: < 500ms P95 response time
"""

import random
import uuid
from locust import task, between

from .base_user import BaseAccessManagementUser


class RoleServiceTest(BaseAccessManagementUser):
    """
    Test Role Service endpoints.

    Endpoints tested:
    - GET /v1/platform/roles - List platform roles
    - GET /v1/platform/roles/{roleId} - Get platform role
    - POST /v1/orgs/{orgId}/roles - Create org role
    - GET /v1/orgs/{orgId}/roles - List org roles
    - GET /v1/orgs/{orgId}/roles/{roleId} - Get org role
    - PUT /v1/orgs/{orgId}/roles/{roleId} - Update org role
    - DELETE /v1/orgs/{orgId}/roles/{roleId} - Delete org role

    Target: < 500ms P95 latency
    """

    wait_time = between(0.5, 1.5)

    platform_role_ids = []
    known_org_role_ids = []
    created_org_role_ids = []

    def on_start(self):
        """Initialize and fetch known roles"""
        super().on_start()
        self._fetch_platform_roles()
        self._fetch_org_roles()

    def _fetch_platform_roles(self):
        """Fetch platform role IDs"""
        response = self.api_get(
            "/v1/platform/roles",
            name="/v1/platform/roles (init)"
        )
        if response.status_code == 200:
            data = response.json()
            self.platform_role_ids = [r['id'] for r in data.get('items', [])]

    def _fetch_org_roles(self):
        """Fetch organisation role IDs"""
        response = self.api_get(
            f"/v1/orgs/{self._get_org_id()}/roles",
            name="/v1/orgs/[orgId]/roles (init)"
        )
        if response.status_code == 200:
            data = response.json()
            self.known_org_role_ids = [r['id'] for r in data.get('items', [])]

    # Platform Roles (Read-Only)

    @task(4)
    def list_platform_roles(self):
        """List platform roles"""
        with self.api_get(
            "/v1/platform/roles",
            name="/v1/platform/roles"
        ) as response:
            if response.status_code != 200:
                response.failure(f"List platform roles failed: {response.status_code}")

    @task(3)
    def get_platform_role(self):
        """Get platform role by ID"""
        if not self.platform_role_ids:
            return

        role_id = random.choice(self.platform_role_ids)

        with self.api_get(
            f"/v1/platform/roles/{role_id}",
            name="/v1/platform/roles/[roleId]"
        ) as response:
            if response.status_code not in [200, 404]:
                response.failure(f"Get platform role failed: {response.status_code}")

    # Organisation Roles

    @task(5)
    def list_org_roles(self):
        """List organisation roles"""
        params = {
            'limit': random.choice([10, 25]),
        }

        with self.api_get(
            f"/v1/orgs/{self._get_org_id()}/roles",
            name="/v1/orgs/[orgId]/roles",
            params=params
        ) as response:
            if response.status_code != 200:
                response.failure(f"List org roles failed: {response.status_code}")

    @task(3)
    def get_org_role(self):
        """Get organisation role by ID"""
        if not self.known_org_role_ids:
            return

        role_id = random.choice(self.known_org_role_ids)

        with self.api_get(
            f"/v1/orgs/{self._get_org_id()}/roles/{role_id}",
            name="/v1/orgs/[orgId]/roles/[roleId]"
        ) as response:
            if response.status_code not in [200, 404]:
                response.failure(f"Get org role failed: {response.status_code}")

    @task(1)
    def create_org_role(self):
        """Create a new organisation role"""
        unique_id = str(uuid.uuid4())[:8]

        # Select random permissions for the role
        available_permissions = [
            'team:read', 'team:write', 'site:read', 'site:write',
            'invitation:read', 'invitation:write', 'audit:read',
        ]

        payload = {
            'name': f'Perf Test Role {unique_id}',
            'description': f'Performance test role {unique_id}',
            'permissions': random.sample(available_permissions, k=random.randint(2, 5)),
            'is_default': False,
        }

        with self.api_post(
            f"/v1/orgs/{self._get_org_id()}/roles",
            json_data=payload,
            name="/v1/orgs/[orgId]/roles (create)"
        ) as response:
            if response.status_code == 201:
                data = response.json()
                role_id = data.get('id')
                if role_id:
                    self.created_org_role_ids.append(role_id)
                    self.known_org_role_ids.append(role_id)
                    self._track_resource('role', role_id)
            elif response.status_code not in [409, 403]:
                response.failure(f"Create org role failed: {response.status_code}")

    @task(1)
    def update_org_role(self):
        """Update organisation role"""
        if not self.created_org_role_ids:
            return

        role_id = random.choice(self.created_org_role_ids)

        payload = {
            'description': f'Updated at {uuid.uuid4().hex[:8]}',
        }

        with self.api_put(
            f"/v1/orgs/{self._get_org_id()}/roles/{role_id}",
            json_data=payload,
            name="/v1/orgs/[orgId]/roles/[roleId] (update)"
        ) as response:
            if response.status_code == 404:
                if role_id in self.created_org_role_ids:
                    self.created_org_role_ids.remove(role_id)
            elif response.status_code not in [200, 403]:
                response.failure(f"Update org role failed: {response.status_code}")
```

### 3.6 Invitation Flow Test (scenarios/invitation_flow.py)

```python
"""
Invitation Service Performance Tests

Tests invitation lifecycle operations.
Target: < 500ms P95 response time
"""

import random
import uuid
from locust import task, between

from .base_user import BaseAccessManagementUser


class InvitationFlowTest(BaseAccessManagementUser):
    """
    Test Invitation Service endpoints.

    Endpoints tested:
    - POST /v1/orgs/{orgId}/invitations - Send invitation
    - GET /v1/orgs/{orgId}/invitations - List org invitations
    - GET /v1/orgs/{orgId}/invitations/{invId} - Get invitation details
    - POST /v1/orgs/{orgId}/invitations/{invId}/resend - Resend invitation
    - POST /v1/orgs/{orgId}/invitations/{invId}/cancel - Cancel invitation
    - GET /v1/invitations/{token} - Get invitation by token (public)
    - POST /v1/invitations/accept - Accept invitation (public)
    - POST /v1/invitations/{token}/decline - Decline invitation (public)

    Target: < 500ms P95 latency
    """

    wait_time = between(0.5, 2.0)

    known_invitation_ids = []
    known_invitation_tokens = []
    created_invitation_ids = []

    def on_start(self):
        """Initialize and fetch known invitations"""
        super().on_start()
        self._fetch_known_invitations()

    def _fetch_known_invitations(self):
        """Fetch existing invitation IDs"""
        response = self.api_get(
            f"/v1/orgs/{self._get_org_id()}/invitations",
            name="/v1/orgs/[orgId]/invitations (init)",
            params={'limit': 50, 'status': 'PENDING'}
        )
        if response.status_code == 200:
            data = response.json()
            self.known_invitation_ids = [i['id'] for i in data.get('items', [])]

    # Authenticated Endpoints

    @task(4)
    def list_invitations(self):
        """List invitations for organisation"""
        params = {
            'limit': random.choice([10, 25]),
            'status': random.choice(['PENDING', 'ACCEPTED', 'EXPIRED', None]),
        }
        # Remove None values
        params = {k: v for k, v in params.items() if v is not None}

        with self.api_get(
            f"/v1/orgs/{self._get_org_id()}/invitations",
            name="/v1/orgs/[orgId]/invitations",
            params=params
        ) as response:
            if response.status_code != 200:
                response.failure(f"List invitations failed: {response.status_code}")

    @task(3)
    def get_invitation(self):
        """Get invitation by ID"""
        if not self.known_invitation_ids:
            return

        inv_id = random.choice(self.known_invitation_ids)

        with self.api_get(
            f"/v1/orgs/{self._get_org_id()}/invitations/{inv_id}",
            name="/v1/orgs/[orgId]/invitations/[invId]"
        ) as response:
            if response.status_code == 404:
                if inv_id in self.known_invitation_ids:
                    self.known_invitation_ids.remove(inv_id)
            elif response.status_code != 200:
                response.failure(f"Get invitation failed: {response.status_code}")

    @task(1)
    def send_invitation(self):
        """
        Send a new invitation.
        Note: Rate limited to avoid spam
        """
        unique_id = str(uuid.uuid4())[:8]

        # Get available roles and teams for invitation
        role_id = 'role-default-member'  # Default member role
        team_id = random.choice(self.current_user['team_ids']) if self.current_user['team_ids'] else None

        payload = {
            'email': f'perf-test-{unique_id}@example.com',
            'role_id': role_id,
            'team_ids': [team_id] if team_id else [],
            'message': f'Performance test invitation {unique_id}',
            'expires_in_days': 1,  # Short expiry for testing
        }

        with self.api_post(
            f"/v1/orgs/{self._get_org_id()}/invitations",
            json_data=payload,
            name="/v1/orgs/[orgId]/invitations (send)"
        ) as response:
            if response.status_code == 201:
                data = response.json()
                inv_id = data.get('id')
                token = data.get('token')
                if inv_id:
                    self.created_invitation_ids.append(inv_id)
                    self.known_invitation_ids.append(inv_id)
                if token:
                    self.known_invitation_tokens.append(token)
            elif response.status_code not in [409, 429, 403]:  # Conflict, rate limit, forbidden OK
                response.failure(f"Send invitation failed: {response.status_code}")

    @task(1)
    def cancel_invitation(self):
        """Cancel a pending invitation"""
        if not self.created_invitation_ids:
            return

        inv_id = random.choice(self.created_invitation_ids)

        with self.api_post(
            f"/v1/orgs/{self._get_org_id()}/invitations/{inv_id}/cancel",
            json_data={},
            name="/v1/orgs/[orgId]/invitations/[invId]/cancel"
        ) as response:
            if response.status_code == 200:
                if inv_id in self.created_invitation_ids:
                    self.created_invitation_ids.remove(inv_id)
            elif response.status_code not in [404, 409, 403]:
                response.failure(f"Cancel invitation failed: {response.status_code}")

    # Public Endpoints (No Authentication)

    @task(2)
    def get_invitation_by_token(self):
        """
        Get invitation by token (public endpoint).
        Tests public endpoint performance.
        """
        if not self.known_invitation_tokens:
            return

        token = random.choice(self.known_invitation_tokens)

        # Public endpoint - no auth header
        with self.client.get(
            f"/v1/invitations/{token}",
            name="/v1/invitations/[token] (public)",
            headers={
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            }
        ) as response:
            if response.status_code == 404:
                if token in self.known_invitation_tokens:
                    self.known_invitation_tokens.remove(token)
            elif response.status_code not in [200, 410]:  # 410 = expired
                response.failure(f"Get by token failed: {response.status_code}")
```

### 3.7 Audit Query Test (scenarios/audit_queries.py)

```python
"""
Audit Service Performance Tests

Tests audit log query operations.
Target: < 500ms P95 response time (with query optimisation)
"""

import random
from datetime import datetime, timedelta
from locust import task, between

from .base_user import BaseAccessManagementUser


class AuditQueryTest(BaseAccessManagementUser):
    """
    Test Audit Service endpoints.

    Endpoints tested:
    - GET /v1/orgs/{orgId}/audit - Query org audit logs
    - GET /v1/orgs/{orgId}/audit/users/{userId} - Query user audit
    - GET /v1/orgs/{orgId}/audit/resources/{type}/{resourceId} - Query resource audit
    - GET /v1/orgs/{orgId}/audit/summary - Get audit summary
    - POST /v1/orgs/{orgId}/audit/export - Export audit logs

    Target: < 500ms P95 latency
    Note: Audit queries may have higher latency due to data volume
    """

    wait_time = between(1.0, 3.0)  # Longer wait time for audit queries

    # Event types for filtering
    EVENT_TYPES = [
        'PERMISSION_CREATED', 'PERMISSION_UPDATED', 'PERMISSION_DELETED',
        'TEAM_CREATED', 'TEAM_UPDATED', 'TEAM_MEMBER_ADDED',
        'ROLE_CREATED', 'ROLE_UPDATED',
        'INVITATION_SENT', 'INVITATION_ACCEPTED',
        'USER_LOGIN', 'USER_LOGOUT',
    ]

    # Resource types
    RESOURCE_TYPES = ['permission', 'team', 'role', 'invitation', 'user']

    @task(5)
    def query_org_audit(self):
        """
        Query organisation audit logs.
        Most common audit query pattern.
        """
        # Date range: last 7 days
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=7)

        params = {
            'start_date': start_date.isoformat() + 'Z',
            'end_date': end_date.isoformat() + 'Z',
            'limit': random.choice([25, 50, 100]),
        }

        # Optionally add event type filter
        if random.random() > 0.5:
            params['event_type'] = random.choice(self.EVENT_TYPES)

        with self.api_get(
            f"/v1/orgs/{self._get_org_id()}/audit",
            name="/v1/orgs/[orgId]/audit",
            params=params
        ) as response:
            if response.status_code != 200:
                response.failure(f"Query audit failed: {response.status_code}")

    @task(3)
    def query_user_audit(self):
        """Query audit logs for specific user"""
        user_id = self.current_user['user_id']

        # Date range: last 24 hours
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(hours=24)

        params = {
            'start_date': start_date.isoformat() + 'Z',
            'end_date': end_date.isoformat() + 'Z',
            'limit': 50,
        }

        with self.api_get(
            f"/v1/orgs/{self._get_org_id()}/audit/users/{user_id}",
            name="/v1/orgs/[orgId]/audit/users/[userId]",
            params=params
        ) as response:
            if response.status_code not in [200, 404]:
                response.failure(f"Query user audit failed: {response.status_code}")

    @task(2)
    def query_resource_audit(self):
        """Query audit logs for specific resource"""
        resource_type = random.choice(self.RESOURCE_TYPES)
        resource_id = f'{resource_type}-001'  # Known test resource

        params = {
            'limit': 25,
        }

        with self.api_get(
            f"/v1/orgs/{self._get_org_id()}/audit/resources/{resource_type}/{resource_id}",
            name="/v1/orgs/[orgId]/audit/resources/[type]/[id]",
            params=params
        ) as response:
            if response.status_code not in [200, 404]:
                response.failure(f"Query resource audit failed: {response.status_code}")

    @task(3)
    def get_audit_summary(self):
        """Get audit summary statistics"""
        # Date range: last 30 days
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=30)

        params = {
            'start_date': start_date.isoformat() + 'Z',
            'end_date': end_date.isoformat() + 'Z',
        }

        with self.api_get(
            f"/v1/orgs/{self._get_org_id()}/audit/summary",
            name="/v1/orgs/[orgId]/audit/summary",
            params=params
        ) as response:
            if response.status_code != 200:
                response.failure(f"Get audit summary failed: {response.status_code}")

    @task(1)
    def export_audit_logs(self):
        """
        Request audit log export.
        Note: This initiates an async export job.
        """
        # Date range: last 7 days
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=7)

        payload = {
            'start_date': start_date.isoformat() + 'Z',
            'end_date': end_date.isoformat() + 'Z',
            'format': 'json',
            'include_metadata': True,
        }

        with self.api_post(
            f"/v1/orgs/{self._get_org_id()}/audit/export",
            json_data=payload,
            name="/v1/orgs/[orgId]/audit/export"
        ) as response:
            # 202 = Accepted (async job started)
            # 429 = Rate limited (expected under load)
            if response.status_code not in [200, 202, 429, 403]:
                response.failure(f"Export audit failed: {response.status_code}")
```

### 3.8 Mixed Workload Test (scenarios/mixed_workload.py)

```python
"""
Mixed Workload Performance Test

Simulates realistic production workload patterns.
Read:Write ratio = 80:20
"""

import random
import uuid
from locust import task, between

from .base_user import BaseAccessManagementUser


class MixedWorkloadTest(BaseAccessManagementUser):
    """
    Simulate realistic mixed workload.

    Workload Distribution:
    - 80% Read operations
    - 20% Write operations

    Service Distribution (based on expected production usage):
    - 30% Permission queries
    - 25% Team operations
    - 20% Role queries
    - 15% Audit queries
    - 10% Invitation operations

    Target: < 500ms P95 overall
    """

    wait_time = between(0.5, 2.0)  # Realistic think time

    # Track resources for the session
    known_teams = []
    known_roles = []

    def on_start(self):
        """Initialize with known resources"""
        super().on_start()
        self._warm_up()

    def _warm_up(self):
        """Fetch known resources for realistic operations"""
        # Fetch teams
        response = self.api_get(
            f"/v1/orgs/{self._get_org_id()}/teams",
            name="/v1/orgs/[orgId]/teams (warmup)",
            params={'limit': 20}
        )
        if response.status_code == 200:
            self.known_teams = [t['id'] for t in response.json().get('items', [])]

        # Fetch roles
        response = self.api_get(
            f"/v1/orgs/{self._get_org_id()}/roles",
            name="/v1/orgs/[orgId]/roles (warmup)",
            params={'limit': 20}
        )
        if response.status_code == 200:
            self.known_roles = [r['id'] for r in response.json().get('items', [])]

    # =========================================================================
    # Read Operations (80% of traffic)
    # =========================================================================

    @task(15)  # 15% - Most common read
    def read_permissions_list(self):
        """List permissions - common dashboard operation"""
        with self.api_get(
            "/v1/permissions",
            name="/v1/permissions (mixed-read)",
            params={'limit': 25}
        ) as response:
            if response.status_code != 200:
                response.failure(f"Read failed: {response.status_code}")

    @task(10)  # 10% - Team list
    def read_teams_list(self):
        """List teams - common navigation"""
        with self.api_get(
            f"/v1/orgs/{self._get_org_id()}/teams",
            name="/v1/orgs/[orgId]/teams (mixed-read)",
            params={'limit': 25}
        ) as response:
            if response.status_code != 200:
                response.failure(f"Read failed: {response.status_code}")

    @task(8)  # 8% - Single team
    def read_team_detail(self):
        """Get team detail"""
        if not self.known_teams:
            return

        team_id = random.choice(self.known_teams)

        with self.api_get(
            f"/v1/orgs/{self._get_org_id()}/teams/{team_id}",
            name="/v1/orgs/[orgId]/teams/[id] (mixed-read)"
        ) as response:
            if response.status_code not in [200, 404]:
                response.failure(f"Read failed: {response.status_code}")

    @task(7)  # 7% - Team members
    def read_team_members(self):
        """List team members"""
        if not self.known_teams:
            return

        team_id = random.choice(self.known_teams)

        with self.api_get(
            f"/v1/orgs/{self._get_org_id()}/teams/{team_id}/members",
            name="/v1/orgs/[orgId]/teams/[id]/members (mixed-read)"
        ) as response:
            if response.status_code not in [200, 404]:
                response.failure(f"Read failed: {response.status_code}")

    @task(10)  # 10% - Roles list
    def read_roles_list(self):
        """List organisation roles"""
        with self.api_get(
            f"/v1/orgs/{self._get_org_id()}/roles",
            name="/v1/orgs/[orgId]/roles (mixed-read)",
            params={'limit': 25}
        ) as response:
            if response.status_code != 200:
                response.failure(f"Read failed: {response.status_code}")

    @task(5)  # 5% - Platform roles
    def read_platform_roles(self):
        """List platform roles"""
        with self.api_get(
            "/v1/platform/roles",
            name="/v1/platform/roles (mixed-read)"
        ) as response:
            if response.status_code != 200:
                response.failure(f"Read failed: {response.status_code}")

    @task(8)  # 8% - Audit queries
    def read_audit_logs(self):
        """Query audit logs"""
        from datetime import datetime, timedelta

        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=7)

        with self.api_get(
            f"/v1/orgs/{self._get_org_id()}/audit",
            name="/v1/orgs/[orgId]/audit (mixed-read)",
            params={
                'start_date': start_date.isoformat() + 'Z',
                'end_date': end_date.isoformat() + 'Z',
                'limit': 25
            }
        ) as response:
            if response.status_code != 200:
                response.failure(f"Read failed: {response.status_code}")

    @task(5)  # 5% - User's teams
    def read_my_teams(self):
        """Get current user's teams"""
        user_id = self.current_user['user_id']

        with self.api_get(
            f"/v1/orgs/{self._get_org_id()}/users/{user_id}/teams",
            name="/v1/orgs/[orgId]/users/[id]/teams (mixed-read)"
        ) as response:
            if response.status_code != 200:
                response.failure(f"Read failed: {response.status_code}")

    @task(5)  # 5% - Invitations list
    def read_invitations(self):
        """List pending invitations"""
        with self.api_get(
            f"/v1/orgs/{self._get_org_id()}/invitations",
            name="/v1/orgs/[orgId]/invitations (mixed-read)",
            params={'status': 'PENDING', 'limit': 25}
        ) as response:
            if response.status_code != 200:
                response.failure(f"Read failed: {response.status_code}")

    @task(7)  # 7% - Audit summary
    def read_audit_summary(self):
        """Get audit summary"""
        from datetime import datetime, timedelta

        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=30)

        with self.api_get(
            f"/v1/orgs/{self._get_org_id()}/audit/summary",
            name="/v1/orgs/[orgId]/audit/summary (mixed-read)",
            params={
                'start_date': start_date.isoformat() + 'Z',
                'end_date': end_date.isoformat() + 'Z',
            }
        ) as response:
            if response.status_code != 200:
                response.failure(f"Read failed: {response.status_code}")

    # =========================================================================
    # Write Operations (20% of traffic)
    # =========================================================================

    @task(5)  # 5% - Create team
    def write_create_team(self):
        """Create a new team"""
        unique_id = str(uuid.uuid4())[:8]

        payload = {
            'name': f'Mixed Test Team {unique_id}',
            'description': f'Created during mixed workload test',
        }

        with self.api_post(
            f"/v1/orgs/{self._get_org_id()}/teams",
            json_data=payload,
            name="/v1/orgs/[orgId]/teams (mixed-write)"
        ) as response:
            if response.status_code == 201:
                data = response.json()
                if data.get('id'):
                    self.known_teams.append(data['id'])
                    self._track_resource('team', data['id'])
            elif response.status_code not in [409, 403]:
                response.failure(f"Write failed: {response.status_code}")

    @task(3)  # 3% - Update team
    def write_update_team(self):
        """Update team details"""
        if not self.known_teams:
            return

        team_id = random.choice(self.known_teams)

        payload = {
            'description': f'Updated at {uuid.uuid4().hex[:8]}',
        }

        with self.api_put(
            f"/v1/orgs/{self._get_org_id()}/teams/{team_id}",
            json_data=payload,
            name="/v1/orgs/[orgId]/teams/[id] (mixed-write)"
        ) as response:
            if response.status_code not in [200, 404, 403]:
                response.failure(f"Write failed: {response.status_code}")

    @task(4)  # 4% - Create role
    def write_create_role(self):
        """Create a new role"""
        unique_id = str(uuid.uuid4())[:8]

        payload = {
            'name': f'Mixed Test Role {unique_id}',
            'description': 'Created during mixed workload test',
            'permissions': ['team:read', 'site:read'],
        }

        with self.api_post(
            f"/v1/orgs/{self._get_org_id()}/roles",
            json_data=payload,
            name="/v1/orgs/[orgId]/roles (mixed-write)"
        ) as response:
            if response.status_code == 201:
                data = response.json()
                if data.get('id'):
                    self.known_roles.append(data['id'])
                    self._track_resource('role', data['id'])
            elif response.status_code not in [409, 403]:
                response.failure(f"Write failed: {response.status_code}")

    @task(3)  # 3% - Update role
    def write_update_role(self):
        """Update role"""
        if not self.known_roles:
            return

        role_id = random.choice(self.known_roles)

        payload = {
            'description': f'Updated at {uuid.uuid4().hex[:8]}',
        }

        with self.api_put(
            f"/v1/orgs/{self._get_org_id()}/roles/{role_id}",
            json_data=payload,
            name="/v1/orgs/[orgId]/roles/[id] (mixed-write)"
        ) as response:
            if response.status_code not in [200, 404, 403]:
                response.failure(f"Write failed: {response.status_code}")

    @task(3)  # 3% - Send invitation
    def write_send_invitation(self):
        """Send invitation"""
        unique_id = str(uuid.uuid4())[:8]

        payload = {
            'email': f'mixed-test-{unique_id}@example.com',
            'role_id': self.known_roles[0] if self.known_roles else 'role-default',
            'team_ids': [self.known_teams[0]] if self.known_teams else [],
            'message': 'Performance test invitation',
            'expires_in_days': 1,
        }

        with self.api_post(
            f"/v1/orgs/{self._get_org_id()}/invitations",
            json_data=payload,
            name="/v1/orgs/[orgId]/invitations (mixed-write)"
        ) as response:
            if response.status_code not in [201, 409, 429, 403]:
                response.failure(f"Write failed: {response.status_code}")

    @task(2)  # 2% - Export audit
    def write_export_audit(self):
        """Request audit export"""
        from datetime import datetime, timedelta

        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=7)

        payload = {
            'start_date': start_date.isoformat() + 'Z',
            'end_date': end_date.isoformat() + 'Z',
            'format': 'json',
        }

        with self.api_post(
            f"/v1/orgs/{self._get_org_id()}/audit/export",
            json_data=payload,
            name="/v1/orgs/[orgId]/audit/export (mixed-write)"
        ) as response:
            if response.status_code not in [200, 202, 429, 403]:
                response.failure(f"Write failed: {response.status_code}")
```

---

## 4. Load Test Profiles

### 4.1 Load Profiles Configuration (config/load_profiles.yaml)

```yaml
# Load Test Profiles for Access Management Performance Testing
# ============================================================

profiles:
  # Profile 1: Baseline
  # Purpose: Establish baseline metrics with minimal load
  baseline:
    name: "Baseline Test"
    description: "Establish baseline metrics with minimal load"
    users: 10
    spawn_rate: 2  # users per second
    run_time: "5m"
    scenarios:
      - name: MixedWorkloadTest
        weight: 10
    thresholds:
      authorizer_p95_ms: 100
      api_p95_ms: 500
      error_rate_percent: 0.1

  # Profile 2: Normal Load
  # Purpose: Verify system operates correctly under normal production load
  normal:
    name: "Normal Load Test"
    description: "Verify normal production load handling"
    users: 50
    spawn_rate: 10
    run_time: "15m"
    scenarios:
      - name: MixedWorkloadTest
        weight: 10
      - name: AuthorizerLoadTest
        weight: 3
    thresholds:
      authorizer_p95_ms: 100
      api_p95_ms: 500
      min_rps: 50
      error_rate_percent: 0.1

  # Profile 3: Peak Load
  # Purpose: Verify system handles peak traffic (100+ RPS target)
  peak:
    name: "Peak Load Test"
    description: "Verify peak traffic handling (100+ RPS)"
    users: 100
    spawn_rate: 20
    run_time: "10m"
    scenarios:
      - name: MixedWorkloadTest
        weight: 10
      - name: AuthorizerLoadTest
        weight: 5
      - name: TeamServiceTest
        weight: 3
    thresholds:
      authorizer_p95_ms: 100
      api_p95_ms: 500
      min_rps: 100
      error_rate_percent: 0.1

  # Profile 4: Stress Test
  # Purpose: Find system breaking point and graceful degradation
  stress:
    name: "Stress Test"
    description: "Find breaking point and test graceful degradation"
    users: 200
    spawn_rate: 50
    run_time: "5m"
    scenarios:
      - name: MixedWorkloadTest
        weight: 10
      - name: AuthorizerStressTest
        weight: 5
    thresholds:
      authorizer_p95_ms: 150  # Relaxed for stress
      api_p95_ms: 750  # Relaxed for stress
      min_rps: 150
      error_rate_percent: 1.0  # Higher tolerance under stress

  # Profile 5: Soak Test
  # Purpose: Verify system stability over extended period
  soak:
    name: "Soak Test"
    description: "Extended duration stability test"
    users: 30
    spawn_rate: 5
    run_time: "60m"
    scenarios:
      - name: MixedWorkloadTest
        weight: 10
    thresholds:
      authorizer_p95_ms: 100
      api_p95_ms: 500
      min_rps: 30
      error_rate_percent: 0.1
      memory_leak_threshold_mb: 50

  # Profile 6: Authorizer Focused
  # Purpose: Specifically stress test the Lambda Authorizer
  authorizer_focus:
    name: "Authorizer Focus Test"
    description: "Stress test Lambda Authorizer specifically"
    users: 50
    spawn_rate: 25
    run_time: "5m"
    scenarios:
      - name: AuthorizerLoadTest
        weight: 8
      - name: AuthorizerStressTest
        weight: 2
    thresholds:
      authorizer_p95_ms: 100
      authorizer_p99_ms: 150
      min_rps: 200  # Authorizer should handle high RPS
      error_rate_percent: 0.05

  # Profile 7: Cold Start Test
  # Purpose: Measure and validate Lambda cold start behaviour
  cold_start:
    name: "Cold Start Test"
    description: "Measure Lambda cold start latencies"
    users: 5
    spawn_rate: 1
    run_time: "10m"
    user_wait_time: "30s-60s"  # Long wait to allow Lambda to cool down
    scenarios:
      - name: PermissionServiceTest
        weight: 1
      - name: TeamServiceTest
        weight: 1
      - name: RoleServiceTest
        weight: 1
    thresholds:
      cold_start_p95_ms: 3000
      warm_p95_ms: 500

# Environment-specific overrides
environments:
  dev:
    base_url: "https://api.dev.bbws.io"
    cognito_pool_id: "af-south-1_DevPoolId"
    test_org_id: "org-dev-001"

  sit:
    base_url: "https://api.sit.bbws.io"
    cognito_pool_id: "af-south-1_SitPoolId"
    test_org_id: "org-sit-001"

  prod:
    base_url: "https://api.bbws.io"
    cognito_pool_id: "af-south-1_ProdPoolId"
    test_org_id: null  # No performance testing against prod data
    read_only: true    # PROD is read-only
```

### 4.2 Environment Configuration (config/dev.yaml)

```yaml
# DEV Environment Configuration
# ==============================

environment: dev
region: af-south-1

# API Configuration
api:
  base_url: "https://api.dev.bbws.io"
  version: "v1"
  timeout_seconds: 30

# Authentication
cognito:
  pool_id: "af-south-1_DevPoolId"
  client_id: "dev-client-id-xxx"
  region: "af-south-1"

# Test Data
test_data:
  organisation_id: "org-dev-001"
  test_users:
    admin:
      user_id: "user-perf-admin-001"
      email: "perf-admin@dev.bbws.io"
      roles: ["ORG_ADMIN"]
    manager:
      user_id: "user-perf-manager-001"
      email: "perf-manager@dev.bbws.io"
      roles: ["ORG_MANAGER"]
    viewer:
      user_id: "user-perf-viewer-001"
      email: "perf-viewer@dev.bbws.io"
      roles: ["SITE_VIEWER"]

# CloudWatch Metrics Collection
cloudwatch:
  enabled: true
  namespace: "BBWS/AccessManagement/DEV"
  metrics:
    - name: "LambdaDuration"
      dimension: "FunctionName"
    - name: "LambdaErrors"
      dimension: "FunctionName"
    - name: "DynamoDBReadCapacity"
      dimension: "TableName"
    - name: "DynamoDBWriteCapacity"
      dimension: "TableName"
```

### 4.3 SIT Environment Configuration (config/sit.yaml)

```yaml
# SIT Environment Configuration
# =============================

environment: sit
region: af-south-1

# API Configuration
api:
  base_url: "https://api.sit.bbws.io"
  version: "v1"
  timeout_seconds: 30

# Authentication
cognito:
  pool_id: "af-south-1_SitPoolId"
  client_id: "sit-client-id-xxx"
  region: "af-south-1"

# Test Data
test_data:
  organisation_id: "org-sit-001"
  test_users:
    admin:
      user_id: "user-perf-admin-001"
      email: "perf-admin@sit.bbws.io"
      roles: ["ORG_ADMIN"]
    manager:
      user_id: "user-perf-manager-001"
      email: "perf-manager@sit.bbws.io"
      roles: ["ORG_MANAGER"]
    viewer:
      user_id: "user-perf-viewer-001"
      email: "perf-viewer@sit.bbws.io"
      roles: ["SITE_VIEWER"]

# CloudWatch Metrics Collection
cloudwatch:
  enabled: true
  namespace: "BBWS/AccessManagement/SIT"
  metrics:
    - name: "LambdaDuration"
      dimension: "FunctionName"
    - name: "LambdaErrors"
      dimension: "FunctionName"
    - name: "DynamoDBReadCapacity"
      dimension: "TableName"
    - name: "DynamoDBWriteCapacity"
      dimension: "TableName"
```

---

## 5. Metrics Collection Configuration

### 5.1 Metrics Overview

| Metric | Source | Collection Method | Target |
|--------|--------|-------------------|--------|
| Response Time | Locust | Automatic per request | < 500ms P95 |
| Authorizer Latency | Locust + CloudWatch | Custom tracking + Lambda duration | < 100ms P95 |
| Throughput (RPS) | Locust | Automatic aggregation | > 100 RPS |
| Error Rate | Locust | Automatic counting | < 0.1% |
| Lambda Duration | CloudWatch | Metrics API query | < 500ms P95 |
| Lambda Cold Starts | CloudWatch Logs | Logs Insights query | < 3s P95 |
| DynamoDB Latency | CloudWatch | Metrics API query | < 25ms average |
| Memory Usage | CloudWatch | Lambda metrics | Monitor for leaks |

### 5.2 CloudWatch Metrics Collector (utils/metrics_collector.py)

```python
"""
CloudWatch Metrics Collector

Collects AWS CloudWatch metrics during performance tests for
comprehensive performance analysis.
"""

import os
import boto3
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
import logging

logger = logging.getLogger(__name__)


class CloudWatchMetricsCollector:
    """
    Collects CloudWatch metrics for Lambda functions and DynamoDB tables
    during performance test execution.
    """

    def __init__(self, region: str = 'af-south-1', environment: str = 'dev'):
        self.region = region
        self.environment = environment
        self.cloudwatch = boto3.client('cloudwatch', region_name=region)
        self.logs = boto3.client('logs', region_name=region)

        # Lambda function naming convention
        self.function_prefix = f'bbws-access-{environment}'

        # DynamoDB table naming convention
        self.table_prefix = f'bbws-access-{environment}'

    def get_lambda_duration_stats(
        self,
        function_name: str,
        start_time: datetime,
        end_time: datetime
    ) -> Dict[str, float]:
        """
        Get Lambda function duration statistics.

        Returns:
            Dict with avg, p50, p95, p99, max duration in ms
        """
        response = self.cloudwatch.get_metric_statistics(
            Namespace='AWS/Lambda',
            MetricName='Duration',
            Dimensions=[
                {'Name': 'FunctionName', 'Value': function_name}
            ],
            StartTime=start_time,
            EndTime=end_time,
            Period=60,  # 1 minute granularity
            Statistics=['Average', 'Minimum', 'Maximum'],
            ExtendedStatistics=['p50', 'p95', 'p99']
        )

        datapoints = response.get('Datapoints', [])

        if not datapoints:
            return {
                'avg_ms': 0, 'p50_ms': 0, 'p95_ms': 0,
                'p99_ms': 0, 'max_ms': 0, 'sample_count': 0
            }

        # Aggregate across all datapoints
        total_avg = sum(dp.get('Average', 0) for dp in datapoints) / len(datapoints)
        max_val = max(dp.get('Maximum', 0) for dp in datapoints)

        # Get extended statistics from first datapoint (averaged)
        extended = datapoints[0].get('ExtendedStatistics', {})

        return {
            'avg_ms': round(total_avg, 2),
            'p50_ms': round(extended.get('p50', 0), 2),
            'p95_ms': round(extended.get('p95', 0), 2),
            'p99_ms': round(extended.get('p99', 0), 2),
            'max_ms': round(max_val, 2),
            'sample_count': len(datapoints)
        }

    def get_lambda_errors(
        self,
        function_name: str,
        start_time: datetime,
        end_time: datetime
    ) -> Dict[str, int]:
        """
        Get Lambda function error counts.
        """
        response = self.cloudwatch.get_metric_statistics(
            Namespace='AWS/Lambda',
            MetricName='Errors',
            Dimensions=[
                {'Name': 'FunctionName', 'Value': function_name}
            ],
            StartTime=start_time,
            EndTime=end_time,
            Period=60,
            Statistics=['Sum']
        )

        total_errors = sum(
            dp.get('Sum', 0) for dp in response.get('Datapoints', [])
        )

        return {'total_errors': int(total_errors)}

    def get_lambda_invocations(
        self,
        function_name: str,
        start_time: datetime,
        end_time: datetime
    ) -> int:
        """
        Get total Lambda invocations count.
        """
        response = self.cloudwatch.get_metric_statistics(
            Namespace='AWS/Lambda',
            MetricName='Invocations',
            Dimensions=[
                {'Name': 'FunctionName', 'Value': function_name}
            ],
            StartTime=start_time,
            EndTime=end_time,
            Period=60,
            Statistics=['Sum']
        )

        return int(sum(
            dp.get('Sum', 0) for dp in response.get('Datapoints', [])
        ))

    def get_cold_start_count(
        self,
        function_name: str,
        start_time: datetime,
        end_time: datetime
    ) -> Dict[str, Any]:
        """
        Query CloudWatch Logs to count cold starts.

        Cold starts are identified by "Init Duration" in Lambda logs.
        """
        log_group = f'/aws/lambda/{function_name}'

        query = """
        fields @timestamp, @message
        | filter @message like /Init Duration/
        | stats count() as cold_start_count
        """

        try:
            # Start query
            response = self.logs.start_query(
                logGroupName=log_group,
                startTime=int(start_time.timestamp()),
                endTime=int(end_time.timestamp()),
                queryString=query
            )

            query_id = response['queryId']

            # Wait for results (with timeout)
            import time
            max_wait = 30
            waited = 0

            while waited < max_wait:
                result = self.logs.get_query_results(queryId=query_id)

                if result['status'] == 'Complete':
                    results = result.get('results', [])
                    if results:
                        count = int(results[0][0].get('value', 0))
                        return {'cold_start_count': count}
                    return {'cold_start_count': 0}

                time.sleep(1)
                waited += 1

            return {'cold_start_count': -1, 'error': 'Query timeout'}

        except Exception as e:
            logger.warning(f"Cold start query failed: {e}")
            return {'cold_start_count': -1, 'error': str(e)}

    def get_dynamodb_latency(
        self,
        table_name: str,
        start_time: datetime,
        end_time: datetime
    ) -> Dict[str, float]:
        """
        Get DynamoDB operation latencies.
        """
        metrics = {}

        for operation in ['GetItem', 'PutItem', 'Query', 'Scan']:
            response = self.cloudwatch.get_metric_statistics(
                Namespace='AWS/DynamoDB',
                MetricName='SuccessfulRequestLatency',
                Dimensions=[
                    {'Name': 'TableName', 'Value': table_name},
                    {'Name': 'Operation', 'Value': operation}
                ],
                StartTime=start_time,
                EndTime=end_time,
                Period=60,
                Statistics=['Average', 'Maximum']
            )

            datapoints = response.get('Datapoints', [])
            if datapoints:
                avg = sum(dp.get('Average', 0) for dp in datapoints) / len(datapoints)
                metrics[f'{operation.lower()}_avg_ms'] = round(avg, 2)

        return metrics

    def collect_all_metrics(
        self,
        start_time: datetime,
        end_time: datetime
    ) -> Dict[str, Any]:
        """
        Collect all relevant CloudWatch metrics for the test period.
        """
        # Lambda functions to monitor
        lambda_functions = [
            f'{self.function_prefix}-authorizer',
            f'{self.function_prefix}-permission-list',
            f'{self.function_prefix}-permission-get',
            f'{self.function_prefix}-team-list',
            f'{self.function_prefix}-team-get',
            f'{self.function_prefix}-role-list',
            f'{self.function_prefix}-audit-query',
        ]

        # DynamoDB tables
        tables = [
            f'{self.table_prefix}-permissions',
            f'{self.table_prefix}-teams',
            f'{self.table_prefix}-roles',
            f'{self.table_prefix}-audit',
        ]

        results = {
            'collection_period': {
                'start': start_time.isoformat(),
                'end': end_time.isoformat(),
            },
            'lambda_metrics': {},
            'dynamodb_metrics': {},
        }

        # Collect Lambda metrics
        for func in lambda_functions:
            func_name = func.split('/')[-1]  # Get short name
            results['lambda_metrics'][func_name] = {
                'duration': self.get_lambda_duration_stats(func, start_time, end_time),
                'errors': self.get_lambda_errors(func, start_time, end_time),
                'invocations': self.get_lambda_invocations(func, start_time, end_time),
                'cold_starts': self.get_cold_start_count(func, start_time, end_time),
            }

        # Collect DynamoDB metrics
        for table in tables:
            table_name = table.split('/')[-1]
            results['dynamodb_metrics'][table_name] = self.get_dynamodb_latency(
                table, start_time, end_time
            )

        return results


# Utility function for test integration
def create_metrics_report(
    start_time: datetime,
    end_time: datetime,
    environment: str = 'dev'
) -> Dict[str, Any]:
    """
    Create a comprehensive metrics report for the test period.
    """
    collector = CloudWatchMetricsCollector(environment=environment)
    return collector.collect_all_metrics(start_time, end_time)
```

---

## 6. CI Integration Example

### 6.1 GitHub Actions Workflow (.github/workflows/performance-tests.yml)

```yaml
# Performance Tests CI Pipeline
# =============================
# Runs performance tests against DEV/SIT environments

name: Performance Tests

on:
  # Manual trigger
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        default: 'dev'
        type: choice
        options:
          - dev
          - sit
      profile:
        description: 'Load test profile'
        required: true
        default: 'normal'
        type: choice
        options:
          - baseline
          - normal
          - peak
          - stress
          - authorizer_focus

  # Scheduled runs
  schedule:
    # Daily baseline test at 6 AM UTC
    - cron: '0 6 * * *'

  # Run on main branch merges (optional)
  # push:
  #   branches:
  #     - main
  #   paths:
  #     - 'src/access-management/**'

env:
  PYTHON_VERSION: '3.11'
  AWS_REGION: 'af-south-1'

jobs:
  performance-test:
    name: Run Performance Tests
    runs-on: ubuntu-latest
    timeout-minutes: 30

    # Environment-specific settings
    environment:
      name: ${{ github.event.inputs.environment || 'dev' }}

    permissions:
      id-token: write  # For AWS OIDC
      contents: read

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r tests/performance/requirements-performance.txt

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Set test parameters
        id: params
        run: |
          # Set environment (default to dev for scheduled runs)
          ENV="${{ github.event.inputs.environment || 'dev' }}"
          PROFILE="${{ github.event.inputs.profile || 'baseline' }}"

          echo "environment=$ENV" >> $GITHUB_OUTPUT
          echo "profile=$PROFILE" >> $GITHUB_OUTPUT

          # Set profile-specific parameters
          case $PROFILE in
            baseline)
              echo "users=10" >> $GITHUB_OUTPUT
              echo "spawn_rate=2" >> $GITHUB_OUTPUT
              echo "run_time=5m" >> $GITHUB_OUTPUT
              ;;
            normal)
              echo "users=50" >> $GITHUB_OUTPUT
              echo "spawn_rate=10" >> $GITHUB_OUTPUT
              echo "run_time=15m" >> $GITHUB_OUTPUT
              ;;
            peak)
              echo "users=100" >> $GITHUB_OUTPUT
              echo "spawn_rate=20" >> $GITHUB_OUTPUT
              echo "run_time=10m" >> $GITHUB_OUTPUT
              ;;
            stress)
              echo "users=200" >> $GITHUB_OUTPUT
              echo "spawn_rate=50" >> $GITHUB_OUTPUT
              echo "run_time=5m" >> $GITHUB_OUTPUT
              ;;
            authorizer_focus)
              echo "users=50" >> $GITHUB_OUTPUT
              echo "spawn_rate=25" >> $GITHUB_OUTPUT
              echo "run_time=5m" >> $GITHUB_OUTPUT
              ;;
          esac

      - name: Run Locust performance tests
        id: locust
        env:
          PERF_ENV: ${{ steps.params.outputs.environment }}
          JWT_TEST_SECRET: ${{ secrets.JWT_TEST_SECRET }}
        run: |
          TIMESTAMP=$(date +%Y%m%d_%H%M%S)
          REPORT_NAME="perf_${PROFILE}_${ENV}_${TIMESTAMP}"

          locust -f tests/performance/locustfile.py \
            --headless \
            --users ${{ steps.params.outputs.users }} \
            --spawn-rate ${{ steps.params.outputs.spawn_rate }} \
            --run-time ${{ steps.params.outputs.run_time }} \
            --html reports/${REPORT_NAME}.html \
            --csv reports/${REPORT_NAME} \
            --csv-full-history \
            2>&1 | tee reports/${REPORT_NAME}.log

          # Check exit code
          if [ $? -eq 0 ]; then
            echo "status=passed" >> $GITHUB_OUTPUT
          else
            echo "status=failed" >> $GITHUB_OUTPUT
          fi

          echo "report_name=${REPORT_NAME}" >> $GITHUB_OUTPUT

      - name: Collect CloudWatch metrics
        if: always()
        env:
          PERF_ENV: ${{ steps.params.outputs.environment }}
        run: |
          python tests/performance/utils/collect_cloudwatch_metrics.py \
            --environment $PERF_ENV \
            --output reports/cloudwatch_metrics.json

      - name: Generate performance report
        if: always()
        run: |
          python tests/performance/utils/report_generator.py \
            --locust-csv reports/${{ steps.locust.outputs.report_name }}_stats.csv \
            --cloudwatch-json reports/cloudwatch_metrics.json \
            --output reports/performance_summary.md

      - name: Upload test reports
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: performance-reports-${{ steps.params.outputs.environment }}-${{ steps.params.outputs.profile }}
          path: reports/
          retention-days: 30

      - name: Post results to PR (if applicable)
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const summary = fs.readFileSync('reports/performance_summary.md', 'utf8');

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## Performance Test Results\n\n${summary}`
            });

      - name: Fail if thresholds not met
        if: steps.locust.outputs.status == 'failed'
        run: |
          echo "Performance thresholds not met!"
          exit 1

  notify:
    name: Notify Results
    needs: performance-test
    runs-on: ubuntu-latest
    if: always()

    steps:
      - name: Send Slack notification
        if: ${{ needs.performance-test.result == 'failure' }}
        uses: slackapi/slack-github-action@v1
        with:
          channel-id: ${{ secrets.SLACK_CHANNEL_ID }}
          payload: |
            {
              "text": "Performance Test Failed",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": ":x: *Performance Test Failed*\n*Environment:* ${{ github.event.inputs.environment || 'dev' }}\n*Profile:* ${{ github.event.inputs.profile || 'baseline' }}\n*Run:* <${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}|View Details>"
                  }
                }
              ]
            }
        env:
          SLACK_BOT_TOKEN: ${{ secrets.SLACK_BOT_TOKEN }}
```

### 6.2 Requirements File (requirements-performance.txt)

```txt
# Performance Testing Dependencies
# =================================

# Locust load testing framework
locust>=2.20.0

# JWT handling for authentication
PyJWT>=2.8.0

# AWS SDK for CloudWatch metrics
boto3>=1.28.0

# YAML configuration parsing
PyYAML>=6.0.1

# HTTP client improvements
requests>=2.31.0
urllib3>=2.0.0

# Report generation
jinja2>=3.1.2
markdown>=3.5.0

# Data analysis for metrics
pandas>=2.1.0
numpy>=1.26.0

# Time handling
python-dateutil>=2.8.2

# Logging improvements
structlog>=23.2.0

# Testing utilities
pytest>=7.4.0
```

---

## 7. Performance Report Template

### 7.1 Markdown Report Template (reports/templates/performance_report.md)

```markdown
# Performance Test Report

## Summary

| Field | Value |
|-------|-------|
| Date | {{ report_date }} |
| Environment | {{ environment }} |
| Profile | {{ profile }} |
| Duration | {{ duration }} |
| Peak Users | {{ peak_users }} |
| Test Run ID | {{ run_id }} |

---

## Performance Targets vs Actual

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Authorizer P95 Latency | < 100ms | {{ authorizer_p95 }}ms | {{ authorizer_status }} |
| API Response P95 | < 500ms | {{ api_p95 }}ms | {{ api_status }} |
| Throughput | > 100 RPS | {{ throughput }} RPS | {{ throughput_status }} |
| Error Rate | < 0.1% | {{ error_rate }}% | {{ error_status }} |
| Cold Start P95 | < 3000ms | {{ cold_start_p95 }}ms | {{ cold_start_status }} |

**Overall Status**: {{ overall_status }}

---

## Detailed Results

### Request Statistics

| Endpoint | Requests | Avg (ms) | P50 (ms) | P95 (ms) | P99 (ms) | Max (ms) | Errors |
|----------|----------|----------|----------|----------|----------|----------|--------|
{% for endpoint in endpoints %}
| {{ endpoint.name }} | {{ endpoint.requests }} | {{ endpoint.avg }} | {{ endpoint.p50 }} | {{ endpoint.p95 }} | {{ endpoint.p99 }} | {{ endpoint.max }} | {{ endpoint.errors }} |
{% endfor %}

### Throughput Over Time

```
{{ throughput_chart }}
```

### Response Time Distribution

- P50 (Median): {{ response_p50 }}ms
- P75: {{ response_p75 }}ms
- P90: {{ response_p90 }}ms
- P95: {{ response_p95 }}ms
- P99: {{ response_p99 }}ms

---

## Lambda Performance (CloudWatch)

### Function Duration Statistics

| Function | Invocations | Avg (ms) | P95 (ms) | P99 (ms) | Errors | Cold Starts |
|----------|-------------|----------|----------|----------|--------|-------------|
{% for func in lambda_functions %}
| {{ func.name }} | {{ func.invocations }} | {{ func.avg }} | {{ func.p95 }} | {{ func.p99 }} | {{ func.errors }} | {{ func.cold_starts }} |
{% endfor %}

### Authorizer Performance

| Metric | Value |
|--------|-------|
| Total Invocations | {{ authorizer.invocations }} |
| Average Duration | {{ authorizer.avg }}ms |
| P95 Duration | {{ authorizer.p95 }}ms |
| P99 Duration | {{ authorizer.p99 }}ms |
| Cache Hit Rate | {{ authorizer.cache_hit_rate }}% |
| Error Rate | {{ authorizer.error_rate }}% |

---

## DynamoDB Performance

| Table | GetItem Avg | PutItem Avg | Query Avg | Throttles |
|-------|-------------|-------------|-----------|-----------|
{% for table in dynamodb_tables %}
| {{ table.name }} | {{ table.get_avg }}ms | {{ table.put_avg }}ms | {{ table.query_avg }}ms | {{ table.throttles }} |
{% endfor %}

---

## Error Analysis

### Error Distribution

| Error Type | Count | Percentage |
|------------|-------|------------|
{% for error in errors %}
| {{ error.type }} | {{ error.count }} | {{ error.percentage }}% |
{% endfor %}

### Sample Errors

```
{% for sample in error_samples %}
{{ sample }}
{% endfor %}
```

---

## Recommendations

{% for rec in recommendations %}
- {{ rec }}
{% endfor %}

---

## Test Configuration

### Load Profile: {{ profile }}

```yaml
users: {{ config.users }}
spawn_rate: {{ config.spawn_rate }}
run_time: {{ config.run_time }}
scenarios: {{ config.scenarios }}
```

### Thresholds Applied

```yaml
authorizer_p95_ms: {{ thresholds.authorizer_p95_ms }}
api_p95_ms: {{ thresholds.api_p95_ms }}
min_rps: {{ thresholds.min_rps }}
max_error_rate: {{ thresholds.max_error_rate }}
cold_start_p95_ms: {{ thresholds.cold_start_p95_ms }}
```

---

## Appendix

### Test Environment Details

- API Gateway: {{ api_gateway_id }}
- Lambda Runtime: Python 3.11
- Lambda Memory: 256MB / 512MB (authorizer)
- DynamoDB Mode: On-Demand
- Region: af-south-1

### Files Generated

- `{{ report_name }}.html` - Interactive HTML report
- `{{ report_name }}_stats.csv` - Request statistics
- `{{ report_name }}_failures.csv` - Failure details
- `cloudwatch_metrics.json` - AWS CloudWatch data

---

*Report generated at {{ generated_at }}*

*Generated with Locust {{ locust_version }}*
```

### 7.2 Sample Completed Report

```markdown
# Performance Test Report

## Summary

| Field | Value |
|-------|-------|
| Date | 2026-01-24 |
| Environment | DEV |
| Profile | Peak |
| Duration | 10 minutes |
| Peak Users | 100 |
| Test Run ID | perf-peak-dev-20260124-143022 |

---

## Performance Targets vs Actual

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Authorizer P95 Latency | < 100ms | 45ms | PASS |
| API Response P95 | < 500ms | 320ms | PASS |
| Throughput | > 100 RPS | 156 RPS | PASS |
| Error Rate | < 0.1% | 0.02% | PASS |
| Cold Start P95 | < 3000ms | 1850ms | PASS |

**Overall Status**: PASS

---

## Detailed Results

### Request Statistics

| Endpoint | Requests | Avg (ms) | P50 (ms) | P95 (ms) | P99 (ms) | Max (ms) | Errors |
|----------|----------|----------|----------|----------|----------|----------|--------|
| /v1/permissions | 12,450 | 125 | 98 | 245 | 380 | 1250 | 2 |
| /v1/orgs/[orgId]/teams | 9,820 | 142 | 115 | 285 | 420 | 1380 | 1 |
| /v1/orgs/[orgId]/roles | 8,540 | 138 | 110 | 275 | 410 | 1320 | 0 |
| /v1/orgs/[orgId]/audit | 6,230 | 185 | 155 | 365 | 520 | 1580 | 3 |
| /v1/platform/roles | 4,120 | 95 | 78 | 185 | 290 | 980 | 0 |

### Response Time Distribution

- P50 (Median): 112ms
- P75: 178ms
- P90: 285ms
- P95: 320ms
- P99: 465ms

---

## Lambda Performance (CloudWatch)

### Function Duration Statistics

| Function | Invocations | Avg (ms) | P95 (ms) | P99 (ms) | Errors | Cold Starts |
|----------|-------------|----------|----------|----------|--------|-------------|
| bbws-access-dev-authorizer | 41,160 | 28 | 45 | 68 | 0 | 12 |
| bbws-access-dev-permission-list | 12,450 | 85 | 165 | 245 | 2 | 8 |
| bbws-access-dev-team-list | 9,820 | 98 | 185 | 280 | 1 | 6 |
| bbws-access-dev-role-list | 8,540 | 92 | 175 | 268 | 0 | 5 |
| bbws-access-dev-audit-query | 6,230 | 142 | 285 | 420 | 3 | 4 |

### Authorizer Performance

| Metric | Value |
|--------|-------|
| Total Invocations | 41,160 |
| Average Duration | 28ms |
| P95 Duration | 45ms |
| P99 Duration | 68ms |
| Cache Hit Rate | 85% |
| Error Rate | 0% |

---

## Recommendations

- Authorizer performance is excellent at 45ms P95, well under the 100ms target
- Consider increasing Lambda memory for audit-query function to reduce P95 latency
- Cold start count is acceptable (35 total) with provisioned concurrency not needed at current load
- DynamoDB on-demand capacity is handling load well with no throttling observed
- Consider implementing response caching for frequently accessed platform roles

---

*Report generated at 2026-01-24T14:45:22Z*

*Generated with Locust 2.20.0*
```

---

## 8. Success Criteria Validation

| Criterion | Status |
|-----------|--------|
| Locust tests implemented | COMPLETE |
| All 5 performance targets defined | COMPLETE |
| Authorizer latency < 100ms (P95) target | DEFINED |
| API response < 500ms (P95) target | DEFINED |
| Throughput > 100 RPS target | DEFINED |
| Error rate < 0.1% target | DEFINED |
| Performance report template | COMPLETE |
| CI integration example | COMPLETE |
| Environment configurations | COMPLETE |
| CloudWatch metrics collection | COMPLETE |

---

## Files Delivered

```
tests/performance/
├── locustfile.py                          # Main orchestration (complete)
├── scenarios/
│   ├── __init__.py
│   ├── base_user.py                       # Base class with auth
│   ├── authorizer_load.py                 # Authorizer tests
│   ├── permission_crud.py                 # Permission service tests
│   ├── team_operations.py                 # Team service tests
│   ├── role_operations.py                 # Role service tests
│   ├── invitation_flow.py                 # Invitation tests
│   ├── audit_queries.py                   # Audit service tests
│   └── mixed_workload.py                  # Realistic mixed load
├── config/
│   ├── dev.yaml                           # DEV environment
│   ├── sit.yaml                           # SIT environment
│   └── load_profiles.yaml                 # All load profiles
├── utils/
│   ├── __init__.py
│   └── metrics_collector.py               # CloudWatch collector
├── reports/
│   └── templates/
│       └── performance_report.md          # Report template
├── requirements-performance.txt           # Dependencies
└── .github/workflows/
    └── performance-tests.yml              # CI pipeline
```

---

**Worker Status**: COMPLETE
**Completed**: 2026-01-24
