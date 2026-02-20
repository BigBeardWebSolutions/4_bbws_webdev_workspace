# Worker 5 Output: Authorizer Service Lambda Implementation

**Worker ID**: worker-5-authorizer-service-lambda
**Stage**: Stage 3 - Lambda Services Development
**Project**: project-plan-2-access-management
**Status**: COMPLETE
**Date**: 2026-01-23

---

## Executive Summary

This document provides the complete implementation of the Lambda Authorizer - the critical security component that validates JWTs, resolves permissions, determines team memberships, and builds IAM policies for API Gateway. The implementation follows **FAIL-CLOSED** security principles.

---

## 1. Project Structure

```
lambda/authorizer_service/
├── __init__.py
├── handler.py                    # Main Lambda handler entry point
├── jwt_validator.py              # JWT validation with Cognito JWKS
├── permission_resolver.py        # Permission resolution from roles
├── team_resolver.py              # Team membership resolution
├── policy_builder.py             # IAM policy builder
├── cache.py                      # JWKS caching implementation
├── exceptions.py                 # Custom authorization exceptions
├── models.py                     # Pydantic models for auth context
├── config.py                     # Configuration and endpoint mapping
├── requirements.txt              # Python dependencies
└── tests/
    ├── __init__.py
    ├── conftest.py               # Pytest fixtures
    ├── test_jwt_validator.py     # JWT validation tests
    ├── test_permission_resolver.py
    ├── test_team_resolver.py
    ├── test_policy_builder.py
    └── test_handler.py           # Integration tests
```

---

## 2. Implementation Files

### 2.1 exceptions.py - Custom Exceptions

```python
"""
Custom exceptions for the Authorizer Service.
All exceptions result in DENY policy (fail-closed security).
"""
from enum import Enum
from typing import Optional


class DenyReason(str, Enum):
    """Reasons for authorization denial."""
    TOKEN_MISSING = "token_missing"
    TOKEN_INVALID = "token_invalid"
    TOKEN_EXPIRED = "token_expired"
    TOKEN_SIGNATURE_INVALID = "token_signature_invalid"
    ORG_ACCESS_DENIED = "org_access_denied"
    PERMISSION_DENIED = "permission_denied"
    USER_NOT_FOUND = "user_not_found"
    USER_INACTIVE = "user_inactive"
    INTERNAL_ERROR = "internal_error"


class AuthorizationException(Exception):
    """Base exception for authorization errors."""

    def __init__(self, message: str, reason: DenyReason):
        self.message = message
        self.reason = reason
        super().__init__(self.message)


class TokenMissingException(AuthorizationException):
    """No authorization token provided."""

    def __init__(self, message: str = "No authorization token provided"):
        super().__init__(message, DenyReason.TOKEN_MISSING)


class TokenExpiredException(AuthorizationException):
    """Token has expired."""

    def __init__(self, message: str = "Token has expired"):
        super().__init__(message, DenyReason.TOKEN_EXPIRED)


class TokenInvalidException(AuthorizationException):
    """Token is invalid (malformed, bad signature, etc.)."""

    def __init__(self, detail: str = ""):
        message = f"Token invalid: {detail}" if detail else "Token invalid"
        super().__init__(message, DenyReason.TOKEN_INVALID)


class TokenSignatureInvalidException(AuthorizationException):
    """Token signature verification failed."""

    def __init__(self, message: str = "Token signature verification failed"):
        super().__init__(message, DenyReason.TOKEN_SIGNATURE_INVALID)


class PermissionDeniedException(AuthorizationException):
    """User lacks required permission."""

    def __init__(self, required_permission: str, user_permissions: Optional[list] = None):
        self.required_permission = required_permission
        self.user_permissions = user_permissions or []
        message = f"Permission denied: requires {required_permission}"
        super().__init__(message, DenyReason.PERMISSION_DENIED)


class OrgAccessDeniedException(AuthorizationException):
    """User attempting to access different organisation."""

    def __init__(self, requested_org: str, user_org: str):
        self.requested_org = requested_org
        self.user_org = user_org
        message = f"Organisation access denied: requested {requested_org}, user belongs to {user_org}"
        super().__init__(message, DenyReason.ORG_ACCESS_DENIED)


class UserNotFoundException(AuthorizationException):
    """User not found in the system."""

    def __init__(self, user_id: str):
        self.user_id = user_id
        message = f"User not found: {user_id}"
        super().__init__(message, DenyReason.USER_NOT_FOUND)


class UserInactiveException(AuthorizationException):
    """User account is inactive."""

    def __init__(self, user_id: str):
        self.user_id = user_id
        message = f"User account inactive: {user_id}"
        super().__init__(message, DenyReason.USER_INACTIVE)
```

---

### 2.2 models.py - Pydantic Models

```python
"""
Pydantic models for the Authorizer Service.
Defines data structures for JWT claims, auth context, and authorization results.
"""
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from enum import Enum


class TokenClaims(BaseModel):
    """Claims extracted from validated JWT token."""
    sub: str  # User ID (Cognito subject)
    email: str
    cognito_username: Optional[str] = Field(None, alias="cognito:username")
    org_id: str = Field(..., alias="custom:organisation_id")
    exp: int  # Expiration timestamp
    iat: int  # Issued at timestamp
    token_use: str  # "access" or "id"
    iss: str  # Issuer (Cognito URL)
    aud: Optional[str] = None  # Audience (for id tokens)

    class Config:
        populate_by_name = True
        extra = "ignore"  # Ignore extra claims from Cognito


class AuthContext(BaseModel):
    """Context passed to backend Lambda via requestContext.authorizer."""
    user_id: str
    email: str
    org_id: str
    team_ids: str  # Comma-separated team UUIDs
    permissions: str  # Comma-separated permissions
    role_ids: str  # Comma-separated role UUIDs

    def to_policy_context(self) -> dict:
        """Convert to dict for API Gateway policy context.

        Note: API Gateway context values must be strings, numbers, or booleans.
        """
        return {
            "userId": self.user_id,
            "email": self.email,
            "orgId": self.org_id,
            "teamIds": self.team_ids,
            "permissions": self.permissions,
            "roleIds": self.role_ids
        }

    def get_team_ids_list(self) -> List[str]:
        """Convert comma-separated teamIds to list."""
        if not self.team_ids:
            return []
        return [t.strip() for t in self.team_ids.split(",") if t.strip()]

    def get_permissions_list(self) -> List[str]:
        """Convert comma-separated permissions to list."""
        if not self.permissions:
            return []
        return [p.strip() for p in self.permissions.split(",") if p.strip()]

    def get_role_ids_list(self) -> List[str]:
        """Convert comma-separated roleIds to list."""
        if not self.role_ids:
            return []
        return [r.strip() for r in self.role_ids.split(",") if r.strip()]


class AuthorizationDecision(str, Enum):
    """Authorization decision outcomes."""
    ALLOW = "Allow"
    DENY = "Deny"


class AuthorizationResult(BaseModel):
    """Result of authorization check."""
    allowed: bool
    principal_id: str
    effect: AuthorizationDecision
    resource: str  # methodArn
    context: Optional[AuthContext] = None
    deny_reason: Optional[str] = None

    class Config:
        use_enum_values = True
```

---

### 2.3 config.py - Configuration and Endpoint Permission Mapping

```python
"""
Configuration for the Authorizer Service.
Includes endpoint-to-permission mapping and environment configuration.
"""
import os
import re
from typing import Optional, Tuple


class Config:
    """Environment configuration for the authorizer."""

    def __init__(self):
        self.cognito_user_pool_id = os.environ.get("COGNITO_USER_POOL_ID", "")
        self.cognito_region = os.environ.get("COGNITO_REGION", "af-south-1")
        self.dynamodb_table = os.environ.get("DYNAMODB_TABLE", "")
        self.log_level = os.environ.get("LOG_LEVEL", "INFO")
        self.jwks_cache_ttl_seconds = int(os.environ.get("JWKS_CACHE_TTL", "3600"))  # 1 hour
        self.policy_cache_ttl_seconds = int(os.environ.get("POLICY_CACHE_TTL", "300"))  # 5 minutes

    @property
    def cognito_issuer(self) -> str:
        """Get the Cognito issuer URL."""
        return f"https://cognito-idp.{self.cognito_region}.amazonaws.com/{self.cognito_user_pool_id}"

    @property
    def jwks_url(self) -> str:
        """Get the JWKS URL for Cognito."""
        return f"{self.cognito_issuer}/.well-known/jwks.json"


class EndpointPermissionMap:
    """Maps HTTP method + path patterns to required permissions."""

    # Static mapping of endpoints to required permissions
    # None means no specific permission required (authenticated access only)
    PERMISSION_MAP = {
        # Sites
        ("GET", "/organisations/{orgId}/sites"): "site:read",
        ("GET", "/organisations/{orgId}/sites/{siteId}"): "site:read",
        ("POST", "/organisations/{orgId}/sites"): "site:create",
        ("PUT", "/organisations/{orgId}/sites/{siteId}"): "site:update",
        ("DELETE", "/organisations/{orgId}/sites/{siteId}"): "site:delete",
        ("POST", "/organisations/{orgId}/sites/{siteId}/publish"): "site:publish",

        # Teams
        ("GET", "/organisations/{orgId}/teams"): "team:read",
        ("GET", "/organisations/{orgId}/teams/{teamId}"): "team:read",
        ("POST", "/organisations/{orgId}/teams"): "team:create",
        ("PUT", "/organisations/{orgId}/teams/{teamId}"): "team:update",
        ("DELETE", "/organisations/{orgId}/teams/{teamId}"): "team:delete",
        ("POST", "/organisations/{orgId}/teams/{teamId}/members"): "team:member:add",
        ("PUT", "/organisations/{orgId}/teams/{teamId}/members/{userId}"): "team:member:update",
        ("DELETE", "/organisations/{orgId}/teams/{teamId}/members/{userId}"): "team:member:remove",

        # Users
        ("GET", "/organisations/{orgId}/users"): "user:read",
        ("GET", "/organisations/{orgId}/users/{userId}"): "user:read",
        ("PUT", "/organisations/{orgId}/users/{userId}"): "user:update",
        ("DELETE", "/organisations/{orgId}/users/{userId}"): "user:delete",

        # Roles
        ("GET", "/organisations/{orgId}/roles"): "role:read",
        ("GET", "/organisations/{orgId}/roles/{roleId}"): "role:read",
        ("POST", "/organisations/{orgId}/roles"): "role:create",
        ("PUT", "/organisations/{orgId}/roles/{roleId}"): "role:update",
        ("DELETE", "/organisations/{orgId}/roles/{roleId}"): "role:delete",

        # Invitations
        ("GET", "/organisations/{orgId}/invitations"): "invitation:read",
        ("GET", "/organisations/{orgId}/invitations/{invitationId}"): "invitation:read",
        ("POST", "/organisations/{orgId}/invitations"): "invitation:create",
        ("PUT", "/organisations/{orgId}/invitations/{invitationId}"): "invitation:update",
        ("DELETE", "/organisations/{orgId}/invitations/{invitationId}"): "invitation:revoke",
        ("POST", "/organisations/{orgId}/invitations/{invitationId}/resend"): "invitation:create",

        # Platform (read-only for all authenticated users)
        ("GET", "/platform/permissions"): None,
        ("GET", "/platform/roles"): None,

        # Public endpoints (no auth required - handled by API Gateway)
        ("GET", "/invitations/{token}"): None,
        ("POST", "/invitations/{token}/accept"): None,
        ("POST", "/invitations/{token}/decline"): None,
    }

    @classmethod
    def get_required_permission(cls, method: str, path: str) -> Optional[str]:
        """Get required permission for an endpoint.

        Args:
            method: HTTP method (GET, POST, PUT, DELETE)
            path: URL path (e.g., /organisations/org-123/sites)

        Returns:
            Required permission string or None if no specific permission required.
        """
        # Normalize method
        method = method.upper()

        # Normalize path (remove leading/trailing slashes, version prefix)
        path = path.strip("/")
        if path.startswith("v1/"):
            path = path[3:]
        path = "/" + path

        # Try exact match first (for parameterized patterns)
        normalized_path = cls._normalize_path_to_pattern(path)

        permission = cls.PERMISSION_MAP.get((method, normalized_path))
        if permission is not None:
            return permission

        # Check if this is a known endpoint that doesn't require specific permission
        if (method, normalized_path) in cls.PERMISSION_MAP:
            return None

        # Unknown endpoint - default to None (will be handled by fail-closed)
        return None

    @classmethod
    def _normalize_path_to_pattern(cls, path: str) -> str:
        """Convert a concrete path to a pattern with placeholders.

        Example: /organisations/org-123/sites/site-456
                 -> /organisations/{orgId}/sites/{siteId}
        """
        # Pattern replacements (order matters - more specific first)
        replacements = [
            (r"/organisations/[^/]+", "/organisations/{orgId}"),
            (r"/sites/[^/]+", "/sites/{siteId}"),
            (r"/teams/[^/]+", "/teams/{teamId}"),
            (r"/users/[^/]+", "/users/{userId}"),
            (r"/roles/[^/]+", "/roles/{roleId}"),
            (r"/invitations/[^/]+", "/invitations/{invitationId}"),
            (r"/members/[^/]+", "/members/{userId}"),
        ]

        result = path
        for pattern, replacement in replacements:
            result = re.sub(pattern, replacement, result)

        return result


def check_permission(required: str, user_permissions: list) -> bool:
    """Check if user has the required permission.

    Supports wildcard permissions (e.g., site:* covers site:read).

    Args:
        required: Required permission string
        user_permissions: List of user's permissions

    Returns:
        True if user has the required permission.
    """
    # Exact match
    if required in user_permissions:
        return True

    # Wildcard match (resource:*)
    resource = required.split(":")[0]
    if f"{resource}:*" in user_permissions:
        return True

    # Super admin wildcard
    if "*:*" in user_permissions:
        return True

    return False
```

---

### 2.4 cache.py - JWKS Caching Implementation

```python
"""
Caching implementation for JWKS and other authorization data.
JWKS is cached for 1 hour to reduce Cognito API calls.
"""
import time
from typing import Optional, Dict, Any
from dataclasses import dataclass, field
from threading import Lock


@dataclass
class CacheEntry:
    """A single cache entry with TTL."""
    value: Any
    expires_at: float

    def is_expired(self) -> bool:
        """Check if this cache entry has expired."""
        return time.time() >= self.expires_at


class JWKSCache:
    """
    Thread-safe cache for JWKS (JSON Web Key Set).

    This cache persists across warm Lambda invocations and refreshes
    after the TTL expires (default 1 hour).
    """

    def __init__(self, ttl_seconds: int = 3600):
        """Initialize the cache.

        Args:
            ttl_seconds: Time-to-live in seconds (default 1 hour).
        """
        self._cache: Optional[CacheEntry] = None
        self._lock = Lock()
        self._ttl_seconds = ttl_seconds

    def get(self) -> Optional[Dict[str, Any]]:
        """Get cached JWKS if available and not expired.

        Returns:
            Cached JWKS dict or None if cache miss or expired.
        """
        with self._lock:
            if self._cache is None:
                return None
            if self._cache.is_expired():
                self._cache = None
                return None
            return self._cache.value

    def set(self, jwks: Dict[str, Any]) -> None:
        """Store JWKS in cache.

        Args:
            jwks: The JWKS dict to cache.
        """
        with self._lock:
            expires_at = time.time() + self._ttl_seconds
            self._cache = CacheEntry(value=jwks, expires_at=expires_at)

    def clear(self) -> None:
        """Clear the cache."""
        with self._lock:
            self._cache = None

    def is_valid(self) -> bool:
        """Check if cache has valid (non-expired) data."""
        with self._lock:
            return self._cache is not None and not self._cache.is_expired()

    @property
    def ttl_seconds(self) -> int:
        """Get the TTL in seconds."""
        return self._ttl_seconds


# Global cache instance (persists across warm Lambda invocations)
_jwks_cache: Optional[JWKSCache] = None


def get_jwks_cache(ttl_seconds: int = 3600) -> JWKSCache:
    """Get or create the global JWKS cache instance.

    Args:
        ttl_seconds: Time-to-live in seconds.

    Returns:
        The global JWKSCache instance.
    """
    global _jwks_cache
    if _jwks_cache is None:
        _jwks_cache = JWKSCache(ttl_seconds=ttl_seconds)
    return _jwks_cache
```

---

### 2.5 jwt_validator.py - JWT Validation with Cognito JWKS

```python
"""
JWT Validator for Cognito tokens.
Validates JWT signature using JWKS, checks expiry, issuer, and token_use claims.
"""
import jwt
import requests
from typing import Optional, Dict, Any
from datetime import datetime

from .cache import get_jwks_cache, JWKSCache
from .models import TokenClaims
from .exceptions import (
    TokenInvalidException,
    TokenExpiredException,
    TokenSignatureInvalidException,
)
from .config import Config


class JWTValidator:
    """
    Validates Cognito JWT tokens using JWKS public keys.

    Features:
    - RS256 signature verification
    - 1-hour JWKS caching
    - Expiry validation
    - Issuer validation
    - Token use validation (access or id)
    """

    def __init__(self, config: Optional[Config] = None):
        """Initialize the JWT validator.

        Args:
            config: Configuration object. If None, uses default Config.
        """
        self._config = config or Config()
        self._cache: JWKSCache = get_jwks_cache(self._config.jwks_cache_ttl_seconds)

    def validate(self, token: str) -> TokenClaims:
        """Validate JWT token and return claims.

        Args:
            token: The JWT token string (without "Bearer " prefix).

        Returns:
            TokenClaims object with validated claims.

        Raises:
            TokenInvalidException: If token is malformed or invalid.
            TokenExpiredException: If token has expired.
            TokenSignatureInvalidException: If signature verification fails.
        """
        if not token:
            raise TokenInvalidException("Empty token")

        # Get JWKS (cached)
        jwks = self._get_jwks()

        # Decode header to get key ID (kid)
        try:
            unverified_header = jwt.get_unverified_header(token)
        except jwt.exceptions.DecodeError as e:
            raise TokenInvalidException(f"Invalid token format: {str(e)}")

        kid = unverified_header.get("kid")
        if not kid:
            raise TokenInvalidException("Token missing key ID (kid)")

        # Find matching key in JWKS
        key = self._find_key(jwks, kid)
        if not key:
            # Key not found - try refreshing JWKS in case of key rotation
            self._cache.clear()
            jwks = self._get_jwks()
            key = self._find_key(jwks, kid)
            if not key:
                raise TokenInvalidException(f"Key ID {kid} not found in JWKS")

        # Build public key from JWK
        try:
            public_key = jwt.algorithms.RSAAlgorithm.from_jwk(key)
        except Exception as e:
            raise TokenInvalidException(f"Failed to construct public key: {str(e)}")

        # Decode and verify token
        try:
            claims = jwt.decode(
                token,
                public_key,
                algorithms=["RS256"],
                issuer=self._config.cognito_issuer,
                options={
                    "verify_aud": False,  # Cognito doesn't always set aud in access tokens
                    "verify_exp": True,
                    "verify_iss": True,
                    "require": ["exp", "iat", "iss", "sub", "token_use"]
                }
            )
        except jwt.ExpiredSignatureError:
            raise TokenExpiredException()
        except jwt.InvalidSignatureError:
            raise TokenSignatureInvalidException()
        except jwt.InvalidIssuerError:
            raise TokenInvalidException("Invalid issuer")
        except jwt.MissingRequiredClaimError as e:
            raise TokenInvalidException(f"Missing required claim: {str(e)}")
        except jwt.InvalidTokenError as e:
            raise TokenInvalidException(str(e))

        # Validate token_use claim
        token_use = claims.get("token_use")
        if token_use not in ["access", "id"]:
            raise TokenInvalidException(f"Invalid token_use claim: {token_use}")

        # Validate custom:organisation_id exists
        if "custom:organisation_id" not in claims:
            raise TokenInvalidException("Missing custom:organisation_id claim")

        # Parse and return claims
        return TokenClaims(**claims)

    def _get_jwks(self) -> Dict[str, Any]:
        """Get JWKS, using cache if available.

        Returns:
            JWKS dict containing public keys.

        Raises:
            TokenInvalidException: If JWKS fetch fails.
        """
        # Try cache first
        cached = self._cache.get()
        if cached is not None:
            return cached

        # Fetch from Cognito
        try:
            response = requests.get(
                self._config.jwks_url,
                timeout=5,
                headers={"Accept": "application/json"}
            )
            response.raise_for_status()
            jwks = response.json()
        except requests.RequestException as e:
            raise TokenInvalidException(f"Failed to fetch JWKS: {str(e)}")
        except ValueError as e:
            raise TokenInvalidException(f"Invalid JWKS response: {str(e)}")

        # Validate JWKS structure
        if "keys" not in jwks or not isinstance(jwks["keys"], list):
            raise TokenInvalidException("Invalid JWKS structure")

        # Cache the JWKS
        self._cache.set(jwks)

        return jwks

    def _find_key(self, jwks: Dict[str, Any], kid: str) -> Optional[Dict[str, Any]]:
        """Find a key by key ID in JWKS.

        Args:
            jwks: The JWKS dict.
            kid: The key ID to find.

        Returns:
            The matching key dict or None if not found.
        """
        for key in jwks.get("keys", []):
            if key.get("kid") == kid:
                return key
        return None
```

---

### 2.6 permission_resolver.py - Permission Resolution from Roles

```python
"""
Permission Resolver for the Authorizer Service.
Resolves user permissions by expanding all assigned roles to their permissions.
"""
import boto3
from typing import List, Set, Optional, Tuple
from boto3.dynamodb.conditions import Key, Attr

from .config import Config
from .exceptions import UserNotFoundException


class PermissionResolver:
    """
    Resolves user permissions from DynamoDB.

    Flow:
    1. Query user's role assignments
    2. For each role, get its permissions
    3. Return union of all permissions (deduplicated)
    """

    def __init__(self, config: Optional[Config] = None, table=None):
        """Initialize the permission resolver.

        Args:
            config: Configuration object. If None, uses default Config.
            table: DynamoDB table resource. If None, creates from config.
        """
        self._config = config or Config()
        if table is not None:
            self._table = table
        else:
            dynamodb = boto3.resource("dynamodb")
            self._table = dynamodb.Table(self._config.dynamodb_table)

    def resolve(self, user_id: str, org_id: str) -> List[str]:
        """Resolve all permissions for a user.

        Gets all roles assigned to the user, then expands each role
        to its permissions, returning the union of all permissions.

        Args:
            user_id: The user's ID (Cognito sub).
            org_id: The organisation ID.

        Returns:
            List of unique permission strings.
        """
        # Get user's roles
        role_ids = self._get_user_roles(user_id, org_id)

        if not role_ids:
            return []

        # Get permissions for each role and aggregate
        permissions: Set[str] = set()
        for role_id in role_ids:
            role_permissions = self._get_role_permissions(role_id, org_id)
            permissions.update(role_permissions)

        return sorted(list(permissions))

    def get_user_role_ids(self, user_id: str, org_id: str) -> List[str]:
        """Get list of role IDs assigned to a user.

        Args:
            user_id: The user's ID.
            org_id: The organisation ID.

        Returns:
            List of role IDs.
        """
        return self._get_user_roles(user_id, org_id)

    def _get_user_roles(self, user_id: str, org_id: str) -> List[str]:
        """Query DynamoDB for user's role assignments.

        Access Pattern: PK = USER#{userId}#ORG#{orgId}, SK begins_with ROLE#

        Args:
            user_id: The user's ID.
            org_id: The organisation ID.

        Returns:
            List of role IDs assigned to the user.
        """
        pk = f"USER#{user_id}#ORG#{org_id}"

        try:
            response = self._table.query(
                KeyConditionExpression=Key("PK").eq(pk) & Key("SK").begins_with("ROLE#"),
                FilterExpression=Attr("status").eq("ACTIVE") | Attr("status").not_exists(),
                ProjectionExpression="role_id, SK"
            )
        except Exception:
            # Fail-closed: return empty list on error
            return []

        role_ids = []
        for item in response.get("Items", []):
            role_id = item.get("role_id")
            if not role_id:
                # Extract from SK if role_id not present
                sk = item.get("SK", "")
                if sk.startswith("ROLE#"):
                    role_id = sk[5:]  # Remove "ROLE#" prefix
            if role_id:
                role_ids.append(role_id)

        return role_ids

    def _get_role_permissions(self, role_id: str, org_id: str) -> List[str]:
        """Query DynamoDB for role's permissions.

        Access Pattern: PK = ROLE#{roleId}, SK begins_with PERM#

        Args:
            role_id: The role ID.
            org_id: The organisation ID.

        Returns:
            List of permission strings for the role.
        """
        pk = f"ROLE#{role_id}"

        try:
            response = self._table.query(
                KeyConditionExpression=Key("PK").eq(pk) & Key("SK").begins_with("PERM#"),
                ProjectionExpression="permission_id, permission_name, SK"
            )
        except Exception:
            # Fail-closed: return empty list on error
            return []

        permissions = []
        for item in response.get("Items", []):
            # Try permission_name first, then permission_id, then extract from SK
            perm = item.get("permission_name") or item.get("permission_id")
            if not perm:
                sk = item.get("SK", "")
                if sk.startswith("PERM#"):
                    perm = sk[5:]  # Remove "PERM#" prefix
            if perm:
                permissions.append(perm)

        return permissions
```

---

### 2.7 team_resolver.py - Team Membership Resolution

```python
"""
Team Resolver for the Authorizer Service.
Resolves user's team memberships for data isolation.
"""
import boto3
from typing import List, Optional
from boto3.dynamodb.conditions import Key, Attr

from .config import Config


class TeamResolver:
    """
    Resolves user's team memberships from DynamoDB.

    Team IDs are passed to backend Lambdas to enable data isolation
    (users can only see data for teams they belong to).
    """

    def __init__(self, config: Optional[Config] = None, table=None):
        """Initialize the team resolver.

        Args:
            config: Configuration object. If None, uses default Config.
            table: DynamoDB table resource. If None, creates from config.
        """
        self._config = config or Config()
        if table is not None:
            self._table = table
        else:
            dynamodb = boto3.resource("dynamodb")
            self._table = dynamodb.Table(self._config.dynamodb_table)

    def resolve(self, user_id: str, org_id: str) -> List[str]:
        """Get all teams the user belongs to.

        Uses GSI1 for efficient query by user.

        Args:
            user_id: The user's ID (Cognito sub).
            org_id: The organisation ID.

        Returns:
            List of team IDs the user is a member of.
        """
        return self._get_active_team_memberships(user_id, org_id)

    def _get_active_team_memberships(self, user_id: str, org_id: str) -> List[str]:
        """Query DynamoDB for user's active team memberships.

        Access Pattern: GSI1PK = USER#{userId}, GSI1SK begins_with TEAM#
        Filter: organisation_id = orgId AND status = ACTIVE

        Args:
            user_id: The user's ID.
            org_id: The organisation ID.

        Returns:
            List of team IDs where user has active membership.
        """
        gsi1pk = f"USER#{user_id}"

        try:
            response = self._table.query(
                IndexName="GSI1",
                KeyConditionExpression=Key("GSI1PK").eq(gsi1pk) & Key("GSI1SK").begins_with("TEAM#"),
                FilterExpression=(
                    (Attr("organisation_id").eq(org_id) | Attr("org_id").eq(org_id)) &
                    (Attr("status").eq("ACTIVE") | Attr("active").eq(True) | Attr("status").not_exists())
                ),
                ProjectionExpression="team_id, GSI1SK"
            )
        except Exception:
            # Fail-closed: return empty list on error
            return []

        team_ids = []
        for item in response.get("Items", []):
            team_id = item.get("team_id")
            if not team_id:
                # Extract from GSI1SK if team_id not present
                gsi1sk = item.get("GSI1SK", "")
                if gsi1sk.startswith("TEAM#"):
                    team_id = gsi1sk[5:]  # Remove "TEAM#" prefix
            if team_id:
                team_ids.append(team_id)

        return team_ids
```

---

### 2.8 policy_builder.py - IAM Policy Builder

```python
"""
IAM Policy Builder for the Authorizer Service.
Builds Allow/Deny policies for API Gateway Lambda Authorizer.
"""
from typing import Optional
from .models import AuthContext, AuthorizationDecision


class PolicyBuilder:
    """
    Builds IAM policy documents for API Gateway authorizer responses.

    The policy document determines whether API Gateway allows or denies
    the request. Context is passed to backend Lambdas for additional
    authorization checks and data filtering.
    """

    @staticmethod
    def build_allow_policy(
        principal_id: str,
        resource: str,
        context: AuthContext
    ) -> dict:
        """Build an Allow policy with auth context.

        Args:
            principal_id: The user ID (Cognito sub).
            resource: The methodArn from the authorization request.
            context: Auth context to pass to backend Lambda.

        Returns:
            IAM policy document with Allow effect and context.
        """
        return {
            "principalId": principal_id,
            "policyDocument": PolicyBuilder._build_policy_document(
                effect=AuthorizationDecision.ALLOW,
                resource=PolicyBuilder._build_resource_arn(resource)
            ),
            "context": context.to_policy_context()
        }

    @staticmethod
    def build_deny_policy(principal_id: str, resource: str) -> dict:
        """Build a Deny policy (no context needed).

        Args:
            principal_id: The principal ID (can be "anonymous" for unknown users).
            resource: The methodArn from the authorization request.

        Returns:
            IAM policy document with Deny effect.
        """
        return {
            "principalId": principal_id,
            "policyDocument": PolicyBuilder._build_policy_document(
                effect=AuthorizationDecision.DENY,
                resource=PolicyBuilder._build_resource_arn(resource)
            )
        }

    @staticmethod
    def _build_policy_document(effect: AuthorizationDecision, resource: str) -> dict:
        """Build the IAM policy document structure.

        Args:
            effect: Allow or Deny.
            resource: The resource ARN.

        Returns:
            IAM policy document dict.
        """
        return {
            "Version": "2012-10-17",
            "Statement": [{
                "Action": "execute-api:Invoke",
                "Effect": effect.value if isinstance(effect, AuthorizationDecision) else effect,
                "Resource": resource
            }]
        }

    @staticmethod
    def _build_resource_arn(method_arn: str) -> str:
        """Build wildcard resource ARN from method ARN.

        This allows the cached policy to be used for any method/path
        on the same API stage.

        Args:
            method_arn: The full method ARN.
                Format: arn:aws:execute-api:region:account:api-id/stage/method/path

        Returns:
            Wildcard resource ARN for the API stage.
        """
        if not method_arn:
            return "*"

        # Split by "/" and take API base + stage, then add wildcard
        parts = method_arn.split("/")
        if len(parts) >= 2:
            # Return: arn:aws:execute-api:region:account:api-id/stage/*
            return "/".join(parts[:2]) + "/*"

        return method_arn
```

---

### 2.9 handler.py - Main Lambda Handler

```python
"""
Lambda Authorizer Handler for API Gateway.

CRITICAL: This handler implements FAIL-CLOSED security.
Any error results in a DENY policy to prevent unauthorized access.
"""
import os
import re
import logging
from typing import Optional, Tuple

from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext

from .config import Config, EndpointPermissionMap, check_permission
from .jwt_validator import JWTValidator
from .permission_resolver import PermissionResolver
from .team_resolver import TeamResolver
from .policy_builder import PolicyBuilder
from .models import AuthContext, AuthorizationDecision
from .exceptions import (
    AuthorizationException,
    TokenMissingException,
    TokenExpiredException,
    TokenInvalidException,
    TokenSignatureInvalidException,
    PermissionDeniedException,
    OrgAccessDeniedException,
    DenyReason,
)

# Initialize logger
logger = Logger(service="authorizer-service")


class AuthorizerHandler:
    """
    Lambda Authorizer handler for API Gateway.

    This is the main entry point for authorization requests.
    It orchestrates JWT validation, permission resolution, team resolution,
    and policy building.

    SECURITY: Implements FAIL-CLOSED - any error results in DENY.
    """

    def __init__(
        self,
        config: Optional[Config] = None,
        jwt_validator: Optional[JWTValidator] = None,
        permission_resolver: Optional[PermissionResolver] = None,
        team_resolver: Optional[TeamResolver] = None
    ):
        """Initialize the authorizer handler.

        Args:
            config: Configuration object.
            jwt_validator: JWT validator instance.
            permission_resolver: Permission resolver instance.
            team_resolver: Team resolver instance.
        """
        self._config = config or Config()
        self._jwt_validator = jwt_validator or JWTValidator(self._config)
        self._permission_resolver = permission_resolver or PermissionResolver(self._config)
        self._team_resolver = team_resolver or TeamResolver(self._config)

    @logger.inject_lambda_context
    def handle(self, event: dict, context: LambdaContext) -> dict:
        """Handle authorization request from API Gateway.

        Args:
            event: API Gateway authorizer event.
            context: Lambda context.

        Returns:
            IAM policy document (Allow or Deny).
        """
        method_arn = event.get("methodArn", "")
        principal_id = "anonymous"

        logger.info("Authorization request received", extra={
            "method_arn": method_arn,
            "type": event.get("type", "TOKEN")
        })

        try:
            # Step 1: Extract token from Authorization header
            token = self._extract_token(event)
            if not token:
                raise TokenMissingException()

            # Step 2: Validate JWT (signature, expiry, issuer)
            claims = self._jwt_validator.validate(token)
            principal_id = claims.sub
            user_org_id = claims.org_id

            logger.info("JWT validated successfully", extra={
                "user_id": principal_id,
                "org_id": user_org_id
            })

            # Step 3: Validate organisation access
            path_org_id = self._extract_org_from_arn(method_arn)
            if path_org_id and path_org_id != user_org_id:
                raise OrgAccessDeniedException(
                    requested_org=path_org_id,
                    user_org=user_org_id
                )

            # Step 4: Resolve user permissions from roles
            permissions = self._permission_resolver.resolve(principal_id, user_org_id)
            role_ids = self._permission_resolver.get_user_role_ids(principal_id, user_org_id)

            logger.debug("Permissions resolved", extra={
                "user_id": principal_id,
                "permissions": permissions,
                "role_ids": role_ids
            })

            # Step 5: Resolve team memberships
            team_ids = self._team_resolver.resolve(principal_id, user_org_id)

            logger.debug("Teams resolved", extra={
                "user_id": principal_id,
                "team_ids": team_ids
            })

            # Step 6: Check required permission for endpoint
            method, path = self._extract_method_path(method_arn)
            required_permission = EndpointPermissionMap.get_required_permission(method, path)

            if required_permission:
                if not check_permission(required_permission, permissions):
                    raise PermissionDeniedException(
                        required_permission=required_permission,
                        user_permissions=permissions
                    )

            # Step 7: Build auth context for backend
            auth_context = AuthContext(
                user_id=principal_id,
                email=claims.email,
                org_id=user_org_id,
                team_ids=",".join(team_ids) if team_ids else "",
                permissions=",".join(permissions) if permissions else "",
                role_ids=",".join(role_ids) if role_ids else ""
            )

            # Step 8: Return Allow policy with context
            logger.info("Authorization ALLOWED", extra={
                "user_id": principal_id,
                "org_id": user_org_id,
                "method": method,
                "path": path,
                "required_permission": required_permission
            })

            return PolicyBuilder.build_allow_policy(
                principal_id=principal_id,
                resource=method_arn,
                context=auth_context
            )

        except TokenMissingException as e:
            logger.warning("Authorization DENIED: Token missing")
            return PolicyBuilder.build_deny_policy(principal_id, method_arn)

        except TokenExpiredException as e:
            logger.warning("Authorization DENIED: Token expired", extra={
                "user_id": principal_id
            })
            return PolicyBuilder.build_deny_policy(principal_id, method_arn)

        except TokenInvalidException as e:
            logger.warning("Authorization DENIED: Token invalid", extra={
                "error": e.message
            })
            return PolicyBuilder.build_deny_policy(principal_id, method_arn)

        except TokenSignatureInvalidException as e:
            logger.warning("Authorization DENIED: Token signature invalid")
            return PolicyBuilder.build_deny_policy(principal_id, method_arn)

        except OrgAccessDeniedException as e:
            logger.warning("Authorization DENIED: Organisation access denied", extra={
                "user_id": principal_id,
                "user_org": e.user_org,
                "requested_org": e.requested_org
            })
            return PolicyBuilder.build_deny_policy(principal_id, method_arn)

        except PermissionDeniedException as e:
            logger.warning("Authorization DENIED: Permission denied", extra={
                "user_id": principal_id,
                "required_permission": e.required_permission,
                "user_permissions": e.user_permissions
            })
            return PolicyBuilder.build_deny_policy(principal_id, method_arn)

        except AuthorizationException as e:
            logger.warning(f"Authorization DENIED: {e.reason.value}", extra={
                "error": e.message
            })
            return PolicyBuilder.build_deny_policy(principal_id, method_arn)

        except Exception as e:
            # FAIL-CLOSED: Any unexpected error results in DENY
            logger.exception("Authorization DENIED: Unexpected error", extra={
                "error": str(e)
            })
            return PolicyBuilder.build_deny_policy(principal_id, method_arn)

    def _extract_token(self, event: dict) -> Optional[str]:
        """Extract Bearer token from authorization header.

        Args:
            event: API Gateway authorizer event.

        Returns:
            Token string without "Bearer " prefix, or None if not found.
        """
        # For TOKEN authorizer type
        auth_token = event.get("authorizationToken", "")

        # For REQUEST authorizer type (headers)
        if not auth_token:
            headers = event.get("headers", {})
            auth_token = headers.get("Authorization", "") or headers.get("authorization", "")

        # Remove Bearer prefix
        if auth_token.startswith("Bearer "):
            return auth_token[7:].strip()
        elif auth_token.startswith("bearer "):
            return auth_token[7:].strip()

        return auth_token if auth_token else None

    def _extract_org_from_arn(self, method_arn: str) -> Optional[str]:
        """Extract organisation ID from path in method ARN.

        Args:
            method_arn: The method ARN from API Gateway.

        Returns:
            Organisation ID if found in path, else None.
        """
        # Pattern: .../organisations/{orgId}/...
        match = re.search(r"/organisations/([^/]+)", method_arn)
        return match.group(1) if match else None

    def _extract_method_path(self, method_arn: str) -> Tuple[str, str]:
        """Extract HTTP method and path from method ARN.

        Args:
            method_arn: The method ARN from API Gateway.
                Format: arn:aws:execute-api:region:account:api/stage/METHOD/path

        Returns:
            Tuple of (method, path).
        """
        if not method_arn:
            return ("GET", "/")

        parts = method_arn.split("/")
        method = parts[2] if len(parts) > 2 else "GET"
        path = "/" + "/".join(parts[3:]) if len(parts) > 3 else "/"

        return (method.upper(), path)


# Global handler instance (reused across warm invocations)
_handler: Optional[AuthorizerHandler] = None


def get_handler() -> AuthorizerHandler:
    """Get or create the global handler instance."""
    global _handler
    if _handler is None:
        _handler = AuthorizerHandler()
    return _handler


def lambda_handler(event: dict, context: LambdaContext) -> dict:
    """Lambda entry point for API Gateway authorizer.

    Args:
        event: API Gateway authorizer event.
        context: Lambda context.

    Returns:
        IAM policy document.
    """
    handler = get_handler()
    return handler.handle(event, context)
```

---

### 2.10 requirements.txt

```
# Core dependencies
pyjwt[crypto]>=2.8.0
cryptography>=41.0.0
requests>=2.31.0
pydantic>=2.5.0
boto3>=1.34.0

# AWS Lambda Powertools
aws-lambda-powertools>=2.30.0

# Testing dependencies (dev only)
pytest>=7.4.0
pytest-cov>=4.1.0
pytest-mock>=3.12.0
moto>=5.0.0
responses>=0.24.0
```

---

## 3. Unit Tests

### 3.1 tests/conftest.py - Pytest Fixtures

```python
"""
Pytest fixtures for Authorizer Service tests.
Provides mocked AWS services, sample tokens, and test data.
"""
import os
import json
import pytest
import boto3
from datetime import datetime, timedelta
from unittest.mock import MagicMock, patch
from moto import mock_dynamodb

# Set test environment variables before importing modules
os.environ["COGNITO_USER_POOL_ID"] = "af-south-1_testpool"
os.environ["COGNITO_REGION"] = "af-south-1"
os.environ["DYNAMODB_TABLE"] = "test-access-management"
os.environ["LOG_LEVEL"] = "DEBUG"


@pytest.fixture
def sample_user_id():
    """Sample user ID (Cognito sub)."""
    return "user-770e8400-e29b-41d4-a716-446655440003"


@pytest.fixture
def sample_org_id():
    """Sample organisation ID."""
    return "org-550e8400-e29b-41d4-a716-446655440000"


@pytest.fixture
def sample_team_ids():
    """Sample team IDs."""
    return ["team-001", "team-002", "team-003"]


@pytest.fixture
def sample_role_ids():
    """Sample role IDs."""
    return ["role-team-lead", "role-operator"]


@pytest.fixture
def sample_permissions():
    """Sample permissions."""
    return ["site:read", "site:update", "site:publish", "team:read"]


@pytest.fixture
def sample_token_claims(sample_user_id, sample_org_id):
    """Sample JWT token claims."""
    now = int(datetime.utcnow().timestamp())
    return {
        "sub": sample_user_id,
        "email": "john.doe@example.com",
        "cognito:username": "johndoe",
        "custom:organisation_id": sample_org_id,
        "exp": now + 3600,  # 1 hour from now
        "iat": now,
        "token_use": "access",
        "iss": f"https://cognito-idp.af-south-1.amazonaws.com/af-south-1_testpool"
    }


@pytest.fixture
def sample_expired_token_claims(sample_token_claims):
    """Sample expired JWT token claims."""
    claims = sample_token_claims.copy()
    claims["exp"] = int(datetime.utcnow().timestamp()) - 3600  # 1 hour ago
    return claims


@pytest.fixture
def sample_method_arn(sample_org_id):
    """Sample API Gateway method ARN."""
    return f"arn:aws:execute-api:af-south-1:123456789012:api-id/prod/GET/v1/organisations/{sample_org_id}/sites"


@pytest.fixture
def sample_authorizer_event(sample_method_arn):
    """Sample API Gateway authorizer event."""
    return {
        "type": "TOKEN",
        "authorizationToken": "Bearer mock-jwt-token",
        "methodArn": sample_method_arn
    }


@pytest.fixture
def sample_jwks():
    """Sample JWKS response."""
    return {
        "keys": [
            {
                "alg": "RS256",
                "e": "AQAB",
                "kid": "test-key-id",
                "kty": "RSA",
                "n": "test-modulus",
                "use": "sig"
            }
        ]
    }


@pytest.fixture
def mock_dynamodb_table():
    """Create a mocked DynamoDB table with test data."""
    with mock_dynamodb():
        dynamodb = boto3.resource("dynamodb", region_name="af-south-1")

        # Create table
        table = dynamodb.create_table(
            TableName="test-access-management",
            KeySchema=[
                {"AttributeName": "PK", "KeyType": "HASH"},
                {"AttributeName": "SK", "KeyType": "RANGE"}
            ],
            AttributeDefinitions=[
                {"AttributeName": "PK", "AttributeType": "S"},
                {"AttributeName": "SK", "AttributeType": "S"},
                {"AttributeName": "GSI1PK", "AttributeType": "S"},
                {"AttributeName": "GSI1SK", "AttributeType": "S"}
            ],
            GlobalSecondaryIndexes=[
                {
                    "IndexName": "GSI1",
                    "KeySchema": [
                        {"AttributeName": "GSI1PK", "KeyType": "HASH"},
                        {"AttributeName": "GSI1SK", "KeyType": "RANGE"}
                    ],
                    "Projection": {"ProjectionType": "ALL"}
                }
            ],
            BillingMode="PAY_PER_REQUEST"
        )

        table.wait_until_exists()
        yield table


@pytest.fixture
def populated_dynamodb_table(mock_dynamodb_table, sample_user_id, sample_org_id, sample_role_ids, sample_team_ids, sample_permissions):
    """DynamoDB table populated with test data."""
    table = mock_dynamodb_table

    # Add user role assignments
    for role_id in sample_role_ids:
        table.put_item(Item={
            "PK": f"USER#{sample_user_id}#ORG#{sample_org_id}",
            "SK": f"ROLE#{role_id}",
            "role_id": role_id,
            "status": "ACTIVE"
        })

    # Add role permissions
    role_permissions = {
        "role-team-lead": ["site:read", "site:update", "team:read"],
        "role-operator": ["site:read", "site:publish"]
    }

    for role_id, perms in role_permissions.items():
        for perm in perms:
            table.put_item(Item={
                "PK": f"ROLE#{role_id}",
                "SK": f"PERM#{perm}",
                "permission_name": perm
            })

    # Add team memberships
    for team_id in sample_team_ids:
        table.put_item(Item={
            "PK": f"TEAM#{team_id}",
            "SK": f"USER#{sample_user_id}",
            "GSI1PK": f"USER#{sample_user_id}",
            "GSI1SK": f"TEAM#{team_id}",
            "team_id": team_id,
            "organisation_id": sample_org_id,
            "status": "ACTIVE"
        })

    yield table


@pytest.fixture
def mock_config():
    """Mocked configuration."""
    from authorizer_service.config import Config
    return Config()


@pytest.fixture
def lambda_context():
    """Mock Lambda context."""
    context = MagicMock()
    context.function_name = "authorizer"
    context.memory_limit_in_mb = 512
    context.invoked_function_arn = "arn:aws:lambda:af-south-1:123456789012:function:authorizer"
    context.aws_request_id = "test-request-id"
    return context
```

---

### 3.2 tests/test_jwt_validator.py

```python
"""
Unit tests for JWT Validator.
Tests JWT signature verification, expiry validation, and JWKS caching.
"""
import pytest
import jwt
import time
from datetime import datetime, timedelta
from unittest.mock import patch, MagicMock
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.backends import default_backend
import json

# Import after setting env vars in conftest
from authorizer_service.jwt_validator import JWTValidator
from authorizer_service.exceptions import (
    TokenInvalidException,
    TokenExpiredException,
    TokenSignatureInvalidException
)
from authorizer_service.cache import get_jwks_cache


class TestJWTValidator:
    """Tests for JWTValidator class."""

    @pytest.fixture
    def rsa_key_pair(self):
        """Generate RSA key pair for testing."""
        private_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=2048,
            backend=default_backend()
        )
        return private_key

    @pytest.fixture
    def valid_token(self, rsa_key_pair, sample_token_claims):
        """Generate a valid JWT token."""
        return jwt.encode(
            sample_token_claims,
            rsa_key_pair,
            algorithm="RS256",
            headers={"kid": "test-key-id"}
        )

    @pytest.fixture
    def expired_token(self, rsa_key_pair, sample_expired_token_claims):
        """Generate an expired JWT token."""
        return jwt.encode(
            sample_expired_token_claims,
            rsa_key_pair,
            algorithm="RS256",
            headers={"kid": "test-key-id"}
        )

    @pytest.fixture
    def jwks_from_key(self, rsa_key_pair):
        """Generate JWKS from RSA key pair."""
        public_key = rsa_key_pair.public_key()
        jwk = jwt.algorithms.RSAAlgorithm.to_jwk(public_key, as_dict=True)
        jwk["kid"] = "test-key-id"
        jwk["use"] = "sig"
        jwk["alg"] = "RS256"
        return {"keys": [jwk]}

    def test_validate_valid_token(self, mock_config, rsa_key_pair, valid_token, jwks_from_key):
        """Test validation of a valid JWT token."""
        validator = JWTValidator(mock_config)

        # Clear and mock the cache
        get_jwks_cache().clear()

        with patch.object(validator, '_get_jwks', return_value=jwks_from_key):
            claims = validator.validate(valid_token)

            assert claims.sub is not None
            assert claims.email == "john.doe@example.com"
            assert claims.token_use == "access"

    def test_validate_expired_token(self, mock_config, rsa_key_pair, expired_token, jwks_from_key):
        """Test that expired tokens are rejected."""
        validator = JWTValidator(mock_config)
        get_jwks_cache().clear()

        with patch.object(validator, '_get_jwks', return_value=jwks_from_key):
            with pytest.raises(TokenExpiredException):
                validator.validate(expired_token)

    def test_validate_empty_token(self, mock_config):
        """Test that empty tokens are rejected."""
        validator = JWTValidator(mock_config)

        with pytest.raises(TokenInvalidException) as exc_info:
            validator.validate("")

        assert "Empty token" in str(exc_info.value)

    def test_validate_malformed_token(self, mock_config):
        """Test that malformed tokens are rejected."""
        validator = JWTValidator(mock_config)

        with pytest.raises(TokenInvalidException):
            validator.validate("not-a-valid-jwt-token")

    def test_validate_token_missing_kid(self, mock_config):
        """Test that tokens without kid header are rejected."""
        validator = JWTValidator(mock_config)

        # Create token without kid
        token = jwt.encode(
            {"sub": "test"},
            "secret",
            algorithm="HS256"
        )

        with pytest.raises(TokenInvalidException) as exc_info:
            validator.validate(token)

        assert "kid" in str(exc_info.value).lower()

    def test_validate_token_wrong_issuer(self, mock_config, rsa_key_pair, jwks_from_key):
        """Test that tokens with wrong issuer are rejected."""
        validator = JWTValidator(mock_config)
        get_jwks_cache().clear()

        # Create token with wrong issuer
        claims = {
            "sub": "user-123",
            "email": "test@example.com",
            "custom:organisation_id": "org-123",
            "exp": int(datetime.utcnow().timestamp()) + 3600,
            "iat": int(datetime.utcnow().timestamp()),
            "token_use": "access",
            "iss": "https://wrong-issuer.example.com"
        }

        token = jwt.encode(
            claims,
            rsa_key_pair,
            algorithm="RS256",
            headers={"kid": "test-key-id"}
        )

        with patch.object(validator, '_get_jwks', return_value=jwks_from_key):
            with pytest.raises(TokenInvalidException) as exc_info:
                validator.validate(token)

            assert "issuer" in str(exc_info.value).lower()

    def test_validate_token_invalid_token_use(self, mock_config, rsa_key_pair, sample_token_claims, jwks_from_key):
        """Test that tokens with invalid token_use are rejected."""
        validator = JWTValidator(mock_config)
        get_jwks_cache().clear()

        # Create token with invalid token_use
        claims = sample_token_claims.copy()
        claims["token_use"] = "refresh"  # Invalid

        token = jwt.encode(
            claims,
            rsa_key_pair,
            algorithm="RS256",
            headers={"kid": "test-key-id"}
        )

        with patch.object(validator, '_get_jwks', return_value=jwks_from_key):
            with pytest.raises(TokenInvalidException) as exc_info:
                validator.validate(token)

            assert "token_use" in str(exc_info.value).lower()

    def test_validate_token_missing_org_id(self, mock_config, rsa_key_pair, sample_token_claims, jwks_from_key):
        """Test that tokens without organisation_id are rejected."""
        validator = JWTValidator(mock_config)
        get_jwks_cache().clear()

        # Create token without organisation_id
        claims = sample_token_claims.copy()
        del claims["custom:organisation_id"]

        token = jwt.encode(
            claims,
            rsa_key_pair,
            algorithm="RS256",
            headers={"kid": "test-key-id"}
        )

        with patch.object(validator, '_get_jwks', return_value=jwks_from_key):
            with pytest.raises(TokenInvalidException) as exc_info:
                validator.validate(token)

            assert "organisation_id" in str(exc_info.value).lower()

    def test_jwks_caching(self, mock_config, sample_jwks):
        """Test that JWKS is cached and reused."""
        validator = JWTValidator(mock_config)
        cache = get_jwks_cache()
        cache.clear()

        with patch('requests.get') as mock_get:
            mock_response = MagicMock()
            mock_response.json.return_value = sample_jwks
            mock_response.raise_for_status = MagicMock()
            mock_get.return_value = mock_response

            # First call - should fetch
            jwks1 = validator._get_jwks()
            assert mock_get.call_count == 1

            # Second call - should use cache
            jwks2 = validator._get_jwks()
            assert mock_get.call_count == 1  # No additional call

            assert jwks1 == jwks2
```

---

### 3.3 tests/test_permission_resolver.py

```python
"""
Unit tests for Permission Resolver.
Tests permission resolution from user roles.
"""
import pytest
from moto import mock_dynamodb

from authorizer_service.permission_resolver import PermissionResolver


class TestPermissionResolver:
    """Tests for PermissionResolver class."""

    def test_resolve_permissions(self, populated_dynamodb_table, mock_config, sample_user_id, sample_org_id):
        """Test resolving permissions for a user with multiple roles."""
        resolver = PermissionResolver(mock_config, populated_dynamodb_table)

        permissions = resolver.resolve(sample_user_id, sample_org_id)

        # Should have union of all role permissions (deduplicated)
        assert "site:read" in permissions
        assert "site:update" in permissions
        assert "site:publish" in permissions
        assert "team:read" in permissions

        # Should be deduplicated (site:read appears in both roles)
        assert len([p for p in permissions if p == "site:read"]) == 1

    def test_resolve_permissions_user_with_no_roles(self, mock_dynamodb_table, mock_config):
        """Test resolving permissions for a user with no roles."""
        resolver = PermissionResolver(mock_config, mock_dynamodb_table)

        permissions = resolver.resolve("user-no-roles", "org-123")

        assert permissions == []

    def test_get_user_role_ids(self, populated_dynamodb_table, mock_config, sample_user_id, sample_org_id, sample_role_ids):
        """Test getting user's role IDs."""
        resolver = PermissionResolver(mock_config, populated_dynamodb_table)

        role_ids = resolver.get_user_role_ids(sample_user_id, sample_org_id)

        assert set(role_ids) == set(sample_role_ids)

    def test_resolve_permissions_handles_inactive_roles(self, mock_dynamodb_table, mock_config, sample_user_id, sample_org_id):
        """Test that inactive role assignments are filtered out."""
        table = mock_dynamodb_table

        # Add an inactive role assignment
        table.put_item(Item={
            "PK": f"USER#{sample_user_id}#ORG#{sample_org_id}",
            "SK": "ROLE#role-inactive",
            "role_id": "role-inactive",
            "status": "INACTIVE"
        })

        # Add role permissions
        table.put_item(Item={
            "PK": "ROLE#role-inactive",
            "SK": "PERM#should:not:appear",
            "permission_name": "should:not:appear"
        })

        resolver = PermissionResolver(mock_config, table)
        permissions = resolver.resolve(sample_user_id, sample_org_id)

        # Inactive role's permissions should not be included
        assert "should:not:appear" not in permissions

    def test_resolve_permissions_returns_sorted_list(self, populated_dynamodb_table, mock_config, sample_user_id, sample_org_id):
        """Test that permissions are returned sorted."""
        resolver = PermissionResolver(mock_config, populated_dynamodb_table)

        permissions = resolver.resolve(sample_user_id, sample_org_id)

        assert permissions == sorted(permissions)
```

---

### 3.4 tests/test_team_resolver.py

```python
"""
Unit tests for Team Resolver.
Tests team membership resolution.
"""
import pytest
from moto import mock_dynamodb

from authorizer_service.team_resolver import TeamResolver


class TestTeamResolver:
    """Tests for TeamResolver class."""

    def test_resolve_teams(self, populated_dynamodb_table, mock_config, sample_user_id, sample_org_id, sample_team_ids):
        """Test resolving team memberships for a user."""
        resolver = TeamResolver(mock_config, populated_dynamodb_table)

        team_ids = resolver.resolve(sample_user_id, sample_org_id)

        assert set(team_ids) == set(sample_team_ids)

    def test_resolve_teams_user_with_no_teams(self, mock_dynamodb_table, mock_config):
        """Test resolving teams for a user with no team memberships."""
        resolver = TeamResolver(mock_config, mock_dynamodb_table)

        team_ids = resolver.resolve("user-no-teams", "org-123")

        assert team_ids == []

    def test_resolve_teams_filters_by_org(self, mock_dynamodb_table, mock_config, sample_user_id):
        """Test that team memberships are filtered by organisation."""
        table = mock_dynamodb_table

        # Add memberships in different orgs
        table.put_item(Item={
            "PK": "TEAM#team-org-a",
            "SK": f"USER#{sample_user_id}",
            "GSI1PK": f"USER#{sample_user_id}",
            "GSI1SK": "TEAM#team-org-a",
            "team_id": "team-org-a",
            "organisation_id": "org-a",
            "status": "ACTIVE"
        })

        table.put_item(Item={
            "PK": "TEAM#team-org-b",
            "SK": f"USER#{sample_user_id}",
            "GSI1PK": f"USER#{sample_user_id}",
            "GSI1SK": "TEAM#team-org-b",
            "team_id": "team-org-b",
            "organisation_id": "org-b",
            "status": "ACTIVE"
        })

        resolver = TeamResolver(mock_config, table)

        # Should only return teams from org-a
        team_ids = resolver.resolve(sample_user_id, "org-a")
        assert team_ids == ["team-org-a"]

        # Should only return teams from org-b
        team_ids = resolver.resolve(sample_user_id, "org-b")
        assert team_ids == ["team-org-b"]

    def test_resolve_teams_filters_inactive_memberships(self, mock_dynamodb_table, mock_config, sample_user_id, sample_org_id):
        """Test that inactive team memberships are filtered out."""
        table = mock_dynamodb_table

        # Add active and inactive memberships
        table.put_item(Item={
            "PK": "TEAM#team-active",
            "SK": f"USER#{sample_user_id}",
            "GSI1PK": f"USER#{sample_user_id}",
            "GSI1SK": "TEAM#team-active",
            "team_id": "team-active",
            "organisation_id": sample_org_id,
            "status": "ACTIVE"
        })

        table.put_item(Item={
            "PK": "TEAM#team-inactive",
            "SK": f"USER#{sample_user_id}",
            "GSI1PK": f"USER#{sample_user_id}",
            "GSI1SK": "TEAM#team-inactive",
            "team_id": "team-inactive",
            "organisation_id": sample_org_id,
            "status": "INACTIVE"
        })

        resolver = TeamResolver(mock_config, table)
        team_ids = resolver.resolve(sample_user_id, sample_org_id)

        assert "team-active" in team_ids
        assert "team-inactive" not in team_ids
```

---

### 3.5 tests/test_policy_builder.py

```python
"""
Unit tests for Policy Builder.
Tests IAM policy document construction.
"""
import pytest
from authorizer_service.policy_builder import PolicyBuilder
from authorizer_service.models import AuthContext, AuthorizationDecision


class TestPolicyBuilder:
    """Tests for PolicyBuilder class."""

    @pytest.fixture
    def sample_auth_context(self, sample_user_id, sample_org_id, sample_team_ids, sample_permissions, sample_role_ids):
        """Create sample auth context."""
        return AuthContext(
            user_id=sample_user_id,
            email="john.doe@example.com",
            org_id=sample_org_id,
            team_ids=",".join(sample_team_ids),
            permissions=",".join(sample_permissions),
            role_ids=",".join(sample_role_ids)
        )

    def test_build_allow_policy(self, sample_auth_context, sample_user_id, sample_method_arn):
        """Test building an Allow policy."""
        policy = PolicyBuilder.build_allow_policy(
            principal_id=sample_user_id,
            resource=sample_method_arn,
            context=sample_auth_context
        )

        assert policy["principalId"] == sample_user_id
        assert policy["policyDocument"]["Version"] == "2012-10-17"

        statement = policy["policyDocument"]["Statement"][0]
        assert statement["Effect"] == "Allow"
        assert statement["Action"] == "execute-api:Invoke"

        # Check context
        assert policy["context"]["userId"] == sample_user_id
        assert "teamIds" in policy["context"]
        assert "permissions" in policy["context"]

    def test_build_deny_policy(self, sample_method_arn):
        """Test building a Deny policy."""
        policy = PolicyBuilder.build_deny_policy(
            principal_id="anonymous",
            resource=sample_method_arn
        )

        assert policy["principalId"] == "anonymous"
        assert policy["policyDocument"]["Version"] == "2012-10-17"

        statement = policy["policyDocument"]["Statement"][0]
        assert statement["Effect"] == "Deny"
        assert statement["Action"] == "execute-api:Invoke"

        # Deny policy should not have context
        assert "context" not in policy

    def test_build_resource_arn_wildcard(self, sample_method_arn):
        """Test that resource ARN is converted to wildcard for caching."""
        resource = PolicyBuilder._build_resource_arn(sample_method_arn)

        # Should end with /* for wildcard matching
        assert resource.endswith("/*")

        # Should preserve API Gateway base ARN
        assert "execute-api" in resource

    def test_build_resource_arn_empty(self):
        """Test handling of empty method ARN."""
        resource = PolicyBuilder._build_resource_arn("")
        assert resource == "*"

    def test_allow_policy_context_values_are_strings(self, sample_auth_context, sample_user_id, sample_method_arn):
        """Test that all context values are strings (API Gateway requirement)."""
        policy = PolicyBuilder.build_allow_policy(
            principal_id=sample_user_id,
            resource=sample_method_arn,
            context=sample_auth_context
        )

        for key, value in policy["context"].items():
            assert isinstance(value, str), f"Context value '{key}' must be string, got {type(value)}"
```

---

### 3.6 tests/test_handler.py - Integration Tests

```python
"""
Integration tests for the Authorizer Handler.
Tests the complete authorization flow.
"""
import pytest
import jwt
from datetime import datetime
from unittest.mock import patch, MagicMock
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.backends import default_backend

from authorizer_service.handler import AuthorizerHandler, lambda_handler
from authorizer_service.config import Config
from authorizer_service.jwt_validator import JWTValidator
from authorizer_service.permission_resolver import PermissionResolver
from authorizer_service.team_resolver import TeamResolver
from authorizer_service.cache import get_jwks_cache


class TestAuthorizerHandler:
    """Integration tests for AuthorizerHandler."""

    @pytest.fixture
    def rsa_key_pair(self):
        """Generate RSA key pair for testing."""
        return rsa.generate_private_key(
            public_exponent=65537,
            key_size=2048,
            backend=default_backend()
        )

    @pytest.fixture
    def valid_token(self, rsa_key_pair, sample_token_claims):
        """Generate a valid JWT token."""
        return jwt.encode(
            sample_token_claims,
            rsa_key_pair,
            algorithm="RS256",
            headers={"kid": "test-key-id"}
        )

    @pytest.fixture
    def jwks_from_key(self, rsa_key_pair):
        """Generate JWKS from RSA key pair."""
        public_key = rsa_key_pair.public_key()
        jwk = jwt.algorithms.RSAAlgorithm.to_jwk(public_key, as_dict=True)
        jwk["kid"] = "test-key-id"
        jwk["use"] = "sig"
        jwk["alg"] = "RS256"
        return {"keys": [jwk]}

    @pytest.fixture
    def handler_with_mocks(self, mock_config, populated_dynamodb_table, jwks_from_key):
        """Create handler with mocked dependencies."""
        get_jwks_cache().clear()

        jwt_validator = JWTValidator(mock_config)
        permission_resolver = PermissionResolver(mock_config, populated_dynamodb_table)
        team_resolver = TeamResolver(mock_config, populated_dynamodb_table)

        handler = AuthorizerHandler(
            config=mock_config,
            jwt_validator=jwt_validator,
            permission_resolver=permission_resolver,
            team_resolver=team_resolver
        )

        # Mock JWKS fetch
        with patch.object(jwt_validator, '_get_jwks', return_value=jwks_from_key):
            yield handler

    def test_successful_authorization(self, handler_with_mocks, valid_token, sample_method_arn, lambda_context, sample_user_id, sample_org_id):
        """Test successful authorization flow."""
        event = {
            "type": "TOKEN",
            "authorizationToken": f"Bearer {valid_token}",
            "methodArn": sample_method_arn
        }

        result = handler_with_mocks.handle(event, lambda_context)

        assert result["principalId"] == sample_user_id
        assert result["policyDocument"]["Statement"][0]["Effect"] == "Allow"
        assert "context" in result
        assert result["context"]["userId"] == sample_user_id
        assert result["context"]["orgId"] == sample_org_id

    def test_missing_token_returns_deny(self, handler_with_mocks, sample_method_arn, lambda_context):
        """Test that missing token returns Deny policy."""
        event = {
            "type": "TOKEN",
            "authorizationToken": "",
            "methodArn": sample_method_arn
        }

        result = handler_with_mocks.handle(event, lambda_context)

        assert result["policyDocument"]["Statement"][0]["Effect"] == "Deny"

    def test_invalid_token_returns_deny(self, handler_with_mocks, sample_method_arn, lambda_context):
        """Test that invalid token returns Deny policy."""
        event = {
            "type": "TOKEN",
            "authorizationToken": "Bearer invalid-token",
            "methodArn": sample_method_arn
        }

        result = handler_with_mocks.handle(event, lambda_context)

        assert result["policyDocument"]["Statement"][0]["Effect"] == "Deny"

    def test_org_mismatch_returns_deny(self, handler_with_mocks, valid_token, lambda_context, sample_org_id):
        """Test that accessing different org returns Deny policy."""
        # Method ARN with different org
        wrong_org_arn = "arn:aws:execute-api:af-south-1:123456789012:api-id/prod/GET/v1/organisations/different-org/sites"

        event = {
            "type": "TOKEN",
            "authorizationToken": f"Bearer {valid_token}",
            "methodArn": wrong_org_arn
        }

        result = handler_with_mocks.handle(event, lambda_context)

        assert result["policyDocument"]["Statement"][0]["Effect"] == "Deny"

    def test_permission_denied_returns_deny(self, mock_config, populated_dynamodb_table, jwks_from_key, rsa_key_pair, sample_token_claims, lambda_context, sample_org_id):
        """Test that missing required permission returns Deny policy."""
        get_jwks_cache().clear()

        jwt_validator = JWTValidator(mock_config)
        permission_resolver = PermissionResolver(mock_config, populated_dynamodb_table)
        team_resolver = TeamResolver(mock_config, populated_dynamodb_table)

        handler = AuthorizerHandler(
            config=mock_config,
            jwt_validator=jwt_validator,
            permission_resolver=permission_resolver,
            team_resolver=team_resolver
        )

        # Create token
        token = jwt.encode(
            sample_token_claims,
            rsa_key_pair,
            algorithm="RS256",
            headers={"kid": "test-key-id"}
        )

        # Method ARN that requires site:delete (user doesn't have this)
        delete_method_arn = f"arn:aws:execute-api:af-south-1:123456789012:api-id/prod/DELETE/v1/organisations/{sample_org_id}/sites/site-123"

        event = {
            "type": "TOKEN",
            "authorizationToken": f"Bearer {token}",
            "methodArn": delete_method_arn
        }

        with patch.object(jwt_validator, '_get_jwks', return_value=jwks_from_key):
            result = handler.handle(event, lambda_context)

        assert result["policyDocument"]["Statement"][0]["Effect"] == "Deny"

    def test_fail_closed_on_exception(self, mock_config, sample_method_arn, lambda_context):
        """Test that unexpected exceptions result in Deny (fail-closed)."""
        handler = AuthorizerHandler(config=mock_config)

        # Mock JWT validator to raise unexpected exception
        handler._jwt_validator = MagicMock()
        handler._jwt_validator.validate.side_effect = RuntimeError("Unexpected error")

        event = {
            "type": "TOKEN",
            "authorizationToken": "Bearer some-token",
            "methodArn": sample_method_arn
        }

        result = handler.handle(event, lambda_context)

        # Should return Deny on any error
        assert result["policyDocument"]["Statement"][0]["Effect"] == "Deny"

    def test_context_contains_all_required_fields(self, handler_with_mocks, valid_token, sample_method_arn, lambda_context):
        """Test that auth context contains all required fields."""
        event = {
            "type": "TOKEN",
            "authorizationToken": f"Bearer {valid_token}",
            "methodArn": sample_method_arn
        }

        result = handler_with_mocks.handle(event, lambda_context)

        context = result.get("context", {})
        assert "userId" in context
        assert "email" in context
        assert "orgId" in context
        assert "teamIds" in context
        assert "permissions" in context
        assert "roleIds" in context

    def test_request_authorizer_type(self, handler_with_mocks, valid_token, sample_method_arn, lambda_context):
        """Test handling of REQUEST authorizer type (headers-based)."""
        event = {
            "type": "REQUEST",
            "headers": {
                "Authorization": f"Bearer {valid_token}"
            },
            "methodArn": sample_method_arn
        }

        result = handler_with_mocks.handle(event, lambda_context)

        assert result["policyDocument"]["Statement"][0]["Effect"] == "Allow"


class TestEndpointPermissionMapping:
    """Tests for endpoint permission mapping."""

    def test_get_sites_requires_site_read(self):
        """Test that GET /sites requires site:read permission."""
        from authorizer_service.config import EndpointPermissionMap

        perm = EndpointPermissionMap.get_required_permission(
            "GET",
            "/v1/organisations/org-123/sites"
        )

        assert perm == "site:read"

    def test_delete_site_requires_site_delete(self):
        """Test that DELETE /sites/{id} requires site:delete permission."""
        from authorizer_service.config import EndpointPermissionMap

        perm = EndpointPermissionMap.get_required_permission(
            "DELETE",
            "/v1/organisations/org-123/sites/site-456"
        )

        assert perm == "site:delete"

    def test_platform_endpoints_no_permission_required(self):
        """Test that platform endpoints don't require specific permission."""
        from authorizer_service.config import EndpointPermissionMap

        perm = EndpointPermissionMap.get_required_permission(
            "GET",
            "/v1/platform/permissions"
        )

        assert perm is None


class TestWildcardPermissions:
    """Tests for wildcard permission checking."""

    def test_wildcard_permission_matches(self):
        """Test that wildcard permissions match specific permissions."""
        from authorizer_service.config import check_permission

        assert check_permission("site:read", ["site:*"]) is True
        assert check_permission("site:delete", ["site:*"]) is True

    def test_exact_permission_matches(self):
        """Test that exact permissions match."""
        from authorizer_service.config import check_permission

        assert check_permission("site:read", ["site:read"]) is True

    def test_missing_permission_fails(self):
        """Test that missing permissions don't match."""
        from authorizer_service.config import check_permission

        assert check_permission("site:delete", ["site:read", "site:update"]) is False

    def test_super_admin_wildcard(self):
        """Test that super admin wildcard matches everything."""
        from authorizer_service.config import check_permission

        assert check_permission("site:delete", ["*:*"]) is True
        assert check_permission("user:admin", ["*:*"]) is True
```

---

## 4. Success Criteria Verification

| Criteria | Status | Notes |
|----------|--------|-------|
| JWT validation with Cognito JWKS | COMPLETE | RS256 signature verification, issuer/expiry validation |
| JWKS caching (1-hour TTL) | COMPLETE | Thread-safe cache with automatic refresh |
| Permission resolution from roles | COMPLETE | Aggregates permissions from all user roles |
| Team membership resolution | COMPLETE | GSI1 query with org/active filtering |
| IAM policy building | COMPLETE | Allow/Deny policies with wildcard resource ARN |
| FAIL-CLOSED security | COMPLETE | All exceptions result in Deny policy |
| Context passed to backend Lambda | COMPLETE | userId, orgId, teamIds, permissions, roleIds |
| Comprehensive error handling | COMPLETE | Custom exceptions for each failure mode |
| Tests with mocked JWKS | COMPLETE | Full test coverage with mocked AWS services |
| < 100ms latency target | DESIGN | Caching strategies support this target |

---

## 5. Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `COGNITO_USER_POOL_ID` | Cognito User Pool ID | `af-south-1_abc123` |
| `COGNITO_REGION` | Cognito region | `af-south-1` |
| `DYNAMODB_TABLE` | Access management table | `bbws-aipagebuilder-dev-ddb-access-management` |
| `LOG_LEVEL` | Logging level | `INFO` |
| `JWKS_CACHE_TTL` | JWKS cache TTL (seconds) | `3600` |
| `POLICY_CACHE_TTL` | API Gateway cache TTL | `300` |

---

## 6. Deployment Notes

1. **Lambda Configuration**:
   - Runtime: Python 3.12
   - Architecture: arm64
   - Memory: 512MB
   - Timeout: 10 seconds
   - Layer: aws-lambda-powertools, PyJWT

2. **API Gateway Configuration**:
   - Authorizer Type: TOKEN
   - Identity Source: `method.request.header.Authorization`
   - Cache TTL: 300 seconds (5 minutes)

3. **IAM Permissions Required**:
   - `dynamodb:Query` on access management table and GSI1
   - CloudWatch Logs for logging

---

**End of Output Document**
