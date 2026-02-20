# Worker Instructions: Invitation Service Lambdas

**Worker ID**: worker-2-invitation-service-lambdas
**Stage**: Stage 3 - Lambda Services Development
**Project**: project-plan-2-access-management

---

## Task

Implement 8 Lambda functions for the Invitation Service using TDD and OOP principles. Handle invitation lifecycle, email sending, and token-based acceptance.

---

## Inputs

**From Stage 1**:
- `/stage-1-lld-review-analysis/worker-2-invitation-service-review/output.md`

**LLD Reference**:
- `/2_bbws_docs/LLDs/2.8.2_LLD_Invitation_Service.md`

---

## Lambda Functions (8)

| # | Function | Method | Endpoint | Auth |
|---|----------|--------|----------|------|
| 1 | create_invitation | POST | /v1/orgs/{orgId}/invitations | Yes |
| 2 | list_invitations | GET | /v1/orgs/{orgId}/invitations | Yes |
| 3 | get_invitation | GET | /v1/orgs/{orgId}/invitations/{id} | Yes |
| 4 | cancel_invitation | DELETE | /v1/orgs/{orgId}/invitations/{id} | Yes |
| 5 | resend_invitation | POST | /v1/orgs/{orgId}/invitations/{id}/resend | Yes |
| 6 | get_invitation_public | GET | /v1/invitations/{token} | No |
| 7 | accept_invitation | POST | /v1/invitations/accept | No |
| 8 | decline_invitation | POST | /v1/invitations/{token}/decline | No |

---

## Deliverables

Create comprehensive Python code in `output.md`:

### 1. Project Structure
```
lambda/invitation_service/
├── __init__.py
├── handlers/
│   ├── __init__.py
│   ├── create_handler.py
│   ├── list_handler.py
│   ├── get_handler.py
│   ├── cancel_handler.py
│   ├── resend_handler.py
│   ├── get_public_handler.py
│   ├── accept_handler.py
│   └── decline_handler.py
├── models/
│   ├── __init__.py
│   ├── invitation.py
│   └── requests.py
├── services/
│   ├── __init__.py
│   ├── invitation_service.py
│   └── email_service.py
├── repositories/
│   ├── __init__.py
│   └── invitation_repository.py
└── tests/
    ├── __init__.py
    ├── conftest.py
    └── test_*.py
```

### 2. Invitation State Machine

```python
class InvitationStatus(str, Enum):
    PENDING = "PENDING"
    ACCEPTED = "ACCEPTED"
    DECLINED = "DECLINED"
    EXPIRED = "EXPIRED"
    CANCELLED = "CANCELLED"

class Invitation(BaseModel):
    id: str
    org_id: str
    email: str
    team_id: str
    role_id: str
    token: str  # Secure random token
    status: InvitationStatus
    invited_by: str
    message: Optional[str]
    expires_at: datetime
    created_at: datetime
    updated_at: datetime
```

### 3. Token Generation

```python
import secrets

def generate_invitation_token() -> str:
    """Generate secure 64-character token."""
    return secrets.token_urlsafe(48)
```

### 4. Email Service

```python
class EmailService:
    def __init__(self, ses_client):
        self.ses = ses_client

    def send_invitation_email(
        self,
        to_email: str,
        org_name: str,
        inviter_name: str,
        accept_url: str,
        expiry_date: str
    ) -> bool:
        ...
```

### 5. Accept Flow

```python
def accept_invitation(token: str, user_id: str) -> dict:
    # 1. Validate token
    # 2. Check not expired
    # 3. Check status is PENDING
    # 4. Update status to ACCEPTED
    # 5. Add user to team (call Team Service)
    # 6. Assign role (call Role Service)
    # 7. Return success with team details
```

---

## Success Criteria

- [ ] All 8 Lambda handlers implemented
- [ ] Secure token generation (64 chars)
- [ ] State machine transitions validated
- [ ] Email sending via SES
- [ ] TTL for expired invitations
- [ ] Public endpoints work without auth
- [ ] Tests with moto (DynamoDB + SES)
- [ ] HATEOAS responses
- [ ] > 80% code coverage

---

## Execution Steps

1. Read Stage 1 output for API contracts
2. Create invitation models with state machine
3. Implement token generation
4. Write tests for create_invitation (TDD)
5. Implement create with email sending
6. Implement list/get handlers
7. Implement cancel/resend handlers
8. Implement public accept/decline
9. Ensure all tests pass
10. Create output.md
11. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
