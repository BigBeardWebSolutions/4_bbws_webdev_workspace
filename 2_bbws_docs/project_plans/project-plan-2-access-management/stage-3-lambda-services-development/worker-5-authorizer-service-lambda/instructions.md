# Worker Instructions: Authorizer Service Lambda

**Worker ID**: worker-5-authorizer-service-lambda
**Stage**: Stage 3 - Lambda Services Development
**Project**: project-plan-2-access-management

---

## Task

Implement the Lambda Authorizer - the critical security component that validates JWTs, resolves permissions, and builds IAM policies for API Gateway.

---

## Inputs

**From Stage 1**:
- `/stage-1-lld-review-analysis/worker-5-authorizer-service-review/output.md`

**From Stage 2**:
- Cognito integration module configuration

**LLD Reference**:
- `/2_bbws_docs/LLDs/2.8.5_LLD_Authorizer_Service.md`

---

## Lambda Function (1)

| Function | Type | Trigger |
|----------|------|---------|
| authorizer | Lambda Authorizer | API Gateway REQUEST |

---

## Deliverables

### 1. Project Structure
```
lambda/authorizer_service/
├── __init__.py
├── handler.py              # Main authorizer handler
├── jwt_validator.py        # JWT validation logic
├── permission_resolver.py  # Permission resolution
├── team_resolver.py        # Team membership resolution
├── policy_builder.py       # IAM policy builder
├── cache.py                # JWKS and permission caching
├── exceptions.py           # Custom exceptions
├── models.py               # Auth context models
└── tests/
    ├── __init__.py
    ├── conftest.py
    ├── test_jwt_validator.py
    ├── test_permission_resolver.py
    ├── test_team_resolver.py
    ├── test_policy_builder.py
    └── test_handler.py
```

### 2. Authorization Flow

```python
def lambda_handler(event: dict, context) -> dict:
    """
    Authorization flow:
    1. Extract token from Authorization header
    2. Validate JWT signature (Cognito JWKS)
    3. Extract user claims (userId, orgId)
    4. Resolve user permissions from roles
    5. Resolve team memberships
    6. Build IAM policy with context
    7. Return policy (Allow/Deny)
    """
    try:
        token = extract_token(event)
        claims = validate_jwt(token)
        permissions = resolve_permissions(claims.user_id, claims.org_id)
        team_ids = resolve_teams(claims.user_id, claims.org_id)

        return build_allow_policy(
            principal_id=claims.user_id,
            resource=event['methodArn'],
            context=AuthContext(
                user_id=claims.user_id,
                org_id=claims.org_id,
                team_ids=team_ids,
                permissions=permissions
            )
        )
    except AuthorizationError as e:
        logger.warning(f"Authorization denied: {e}")
        return build_deny_policy(event['methodArn'])
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        # FAIL-CLOSED: Deny on any error
        return build_deny_policy(event['methodArn'])
```

### 3. JWT Validation

```python
class JWTValidator:
    def __init__(self, user_pool_id: str, region: str):
        self.issuer = f"https://cognito-idp.{region}.amazonaws.com/{user_pool_id}"
        self.jwks_url = f"{self.issuer}/.well-known/jwks.json"
        self._jwks_cache = None
        self._cache_time = None

    def validate(self, token: str) -> JWTClaims:
        """
        Validate JWT:
        - Signature (RS256 with JWKS)
        - Expiration
        - Issuer
        - Token use (access)
        """
        ...

    def _get_jwks(self) -> dict:
        """Get JWKS with 1-hour cache."""
        if self._should_refresh_cache():
            self._jwks_cache = self._fetch_jwks()
            self._cache_time = datetime.now()
        return self._jwks_cache
```

### 4. Permission Resolution

```python
class PermissionResolver:
    def __init__(self, dynamodb_table):
        self.table = dynamodb_table

    def resolve(self, user_id: str, org_id: str) -> List[str]:
        """
        Resolve all permissions for user:
        1. Get user's role assignments
        2. Get permissions for each role
        3. Return union of all permissions
        """
        roles = self._get_user_roles(user_id, org_id)
        permissions = set()
        for role in roles:
            role_permissions = self._get_role_permissions(role.role_id)
            permissions.update(role_permissions)
        return list(permissions)
```

### 5. Team Resolution

```python
class TeamResolver:
    def __init__(self, dynamodb_table):
        self.table = dynamodb_table

    def resolve(self, user_id: str, org_id: str) -> List[str]:
        """
        Get all teams user belongs to.
        Uses GSI3 for efficient query.
        """
        response = self.table.query(
            IndexName='GSI3',
            KeyConditionExpression='GSI3PK = :pk',
            ExpressionAttributeValues={
                ':pk': f'USER#{user_id}#ORG#{org_id}'
            }
        )
        return [item['team_id'] for item in response['Items']]
```

### 6. Policy Builder

```python
class PolicyBuilder:
    @staticmethod
    def build_allow_policy(principal_id: str, resource: str, context: AuthContext) -> dict:
        return {
            "principalId": principal_id,
            "policyDocument": {
                "Version": "2012-10-17",
                "Statement": [{
                    "Action": "execute-api:Invoke",
                    "Effect": "Allow",
                    "Resource": resource
                }]
            },
            "context": {
                "userId": context.user_id,
                "orgId": context.org_id,
                "teamIds": json.dumps(context.team_ids),
                "permissions": json.dumps(context.permissions)
            }
        }

    @staticmethod
    def build_deny_policy(resource: str) -> dict:
        return {
            "principalId": "unauthorized",
            "policyDocument": {
                "Version": "2012-10-17",
                "Statement": [{
                    "Action": "execute-api:Invoke",
                    "Effect": "Deny",
                    "Resource": resource
                }]
            }
        }
```

---

## Success Criteria

- [ ] JWT validation with Cognito JWKS
- [ ] JWKS caching (1-hour TTL)
- [ ] Permission resolution from roles
- [ ] Team membership resolution
- [ ] IAM policy building
- [ ] FAIL-CLOSED security (deny on any error)
- [ ] Context passed to backend Lambda
- [ ] Comprehensive error handling
- [ ] Tests with mocked JWKS
- [ ] < 100ms latency target

---

## Execution Steps

1. Read Stage 1 authorizer review output
2. Implement JWT validator with JWKS caching
3. Implement permission resolver
4. Implement team resolver
5. Implement policy builder
6. Implement main handler with fail-closed
7. Write comprehensive tests
8. Ensure all tests pass
9. Create output.md
10. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
