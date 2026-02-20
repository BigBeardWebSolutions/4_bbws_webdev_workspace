# Stage T2: User Hierarchy System

**Parent Plan**: [BBWS SDLC Main Plan](./main-plan.md)
**Stage**: T2 of T3 (Tenant Management Track)
**Status**: PENDING
**Last Updated**: 2026-01-01

---

## Objective

Implement the organizational user hierarchy system: Organization -> Division -> Group -> Team -> User, with support for user invitations and multi-team membership.

---

## Agent & Skill Assignment

| Role | Agent | Skill |
|------|-------|-------|
| **Primary** | Python_AWS_Developer_Agent | `AWS_Python_Dev.skill.md` |
| **Support** | Python_AWS_Developer_Agent | `DynamoDB_Single_Table.skill.md` |

---

## Workers

| # | Worker | Task | Status | Output |
|---|--------|------|--------|--------|
| 1 | worker-1-hierarchy-models | Create hierarchy data models | PENDING | `src/models/` |
| 2 | worker-2-hierarchy-repository | Implement DynamoDB for hierarchy | PENDING | `src/repositories/` |
| 3 | worker-3-user-service | Implement user management service | PENDING | `src/services/` |
| 4 | worker-4-invitation-system | Build invitation system | PENDING | `src/services/` |

---

## Worker Instructions

### Worker 1: Hierarchy Data Models

**Objective**: Define models for organizational hierarchy

**Hierarchy Structure**:
```
Organization (Tenant)
├── Division (optional)
│   └── Group (optional)
│       └── Team
│           └── User
```

**Model Definitions**:
```python
# src/models/hierarchy.py
from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum

class HierarchyLevel(str, Enum):
    ORGANIZATION = "organization"
    DIVISION = "division"
    GROUP = "group"
    TEAM = "team"

class Division(BaseModel):
    """Division within an organization."""
    division_id: str
    tenant_id: str
    name: str = Field(..., min_length=2, max_length=100)
    description: Optional[str] = None
    parent_id: Optional[str] = None  # For nested divisions
    created_at: datetime = Field(default_factory=datetime.utcnow)

class Group(BaseModel):
    """Group within a division."""
    group_id: str
    tenant_id: str
    division_id: str
    name: str = Field(..., min_length=2, max_length=100)
    description: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)

class Team(BaseModel):
    """Team within a group."""
    team_id: str
    tenant_id: str
    group_id: Optional[str] = None  # Direct team under org if no group
    division_id: Optional[str] = None
    name: str = Field(..., min_length=2, max_length=100)
    description: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)

class UserStatus(str, Enum):
    ACTIVE = "active"
    INVITED = "invited"
    SUSPENDED = "suspended"

class User(BaseModel):
    """User within the organization."""
    user_id: str
    tenant_id: str
    email: EmailStr
    name: str = Field(..., min_length=2, max_length=100)
    status: UserStatus = Field(default=UserStatus.INVITED)
    primary_team_id: str
    teams: List[str] = Field(default_factory=list)  # Multi-team membership
    created_at: datetime = Field(default_factory=datetime.utcnow)
    last_login: Optional[datetime] = None

class TeamMembership(BaseModel):
    """User membership in a team."""
    user_id: str
    team_id: str
    tenant_id: str
    role: str = "member"  # member, lead, admin
    joined_at: datetime = Field(default_factory=datetime.utcnow)
```

**Quality Criteria**:
- [ ] All hierarchy levels modeled
- [ ] Multi-team membership supported
- [ ] User status tracking
- [ ] Validation rules applied

---

### Worker 2: Hierarchy Repository

**Objective**: Implement DynamoDB access patterns for hierarchy

**DynamoDB Access Patterns**:
| Pattern | PK | SK | Use Case |
|---------|----|----|----------|
| Get Division | `TENANT#{tenant_id}` | `DIV#{division_id}` | Get division |
| List Divisions | `TENANT#{tenant_id}` | `DIV#` (begins_with) | List tenant divisions |
| Get Group | `TENANT#{tenant_id}` | `GRP#{group_id}` | Get group |
| List Groups | `DIV#{division_id}` | `GRP#` (begins_with) | List division groups |
| Get Team | `TENANT#{tenant_id}` | `TEAM#{team_id}` | Get team |
| List Teams | `GRP#{group_id}` | `TEAM#` (begins_with) | List group teams |
| Get User | `TENANT#{tenant_id}` | `USER#{user_id}` | Get user |
| User by Email | GSI: `EMAIL#{email}` | `TENANT#{tenant_id}` | Find by email |
| Team Members | `TEAM#{team_id}` | `MEMBER#{user_id}` | List team members |
| User Teams | `USER#{user_id}` | `MEMBERSHIP#{team_id}` | List user teams |

**Repository Implementation**:
```python
# src/repositories/hierarchy_repository.py
class HierarchyRepository:
    """Repository for organizational hierarchy."""

    def __init__(self, table_name: str):
        self.dynamodb = boto3.resource('dynamodb')
        self.table = self.dynamodb.Table(table_name)

    # Division operations
    def create_division(self, division: Division) -> Division:
        item = {
            'PK': f'TENANT#{division.tenant_id}',
            'SK': f'DIV#{division.division_id}',
            **division.dict()
        }
        self.table.put_item(Item=item)
        return division

    def list_divisions(self, tenant_id: str) -> List[Division]:
        response = self.table.query(
            KeyConditionExpression='PK = :pk AND begins_with(SK, :sk)',
            ExpressionAttributeValues={
                ':pk': f'TENANT#{tenant_id}',
                ':sk': 'DIV#'
            }
        )
        return [Division(**item) for item in response.get('Items', [])]

    # Group operations
    def create_group(self, group: Group) -> Group:
        item = {
            'PK': f'DIV#{group.division_id}',
            'SK': f'GRP#{group.group_id}',
            **group.dict()
        }
        self.table.put_item(Item=item)
        return group

    # Team operations
    def create_team(self, team: Team) -> Team:
        parent_pk = f'GRP#{team.group_id}' if team.group_id else f'TENANT#{team.tenant_id}'
        item = {
            'PK': parent_pk,
            'SK': f'TEAM#{team.team_id}',
            **team.dict()
        }
        self.table.put_item(Item=item)
        return team

    # User operations
    def create_user(self, user: User) -> User:
        item = {
            'PK': f'TENANT#{user.tenant_id}',
            'SK': f'USER#{user.user_id}',
            'GSI1PK': f'EMAIL#{user.email}',
            'GSI1SK': f'TENANT#{user.tenant_id}',
            **user.dict()
        }
        self.table.put_item(Item=item)
        return user

    def get_user_by_email(self, email: str, tenant_id: str) -> Optional[User]:
        response = self.table.query(
            IndexName='GSI1',
            KeyConditionExpression='GSI1PK = :pk AND GSI1SK = :sk',
            ExpressionAttributeValues={
                ':pk': f'EMAIL#{email}',
                ':sk': f'TENANT#{tenant_id}'
            }
        )
        items = response.get('Items', [])
        return User(**items[0]) if items else None

    # Team membership operations
    def add_user_to_team(self, membership: TeamMembership) -> TeamMembership:
        # Add to team's member list
        self.table.put_item(Item={
            'PK': f'TEAM#{membership.team_id}',
            'SK': f'MEMBER#{membership.user_id}',
            **membership.dict()
        })
        # Add to user's team list
        self.table.put_item(Item={
            'PK': f'USER#{membership.user_id}',
            'SK': f'MEMBERSHIP#{membership.team_id}',
            **membership.dict()
        })
        return membership

    def get_team_members(self, team_id: str) -> List[TeamMembership]:
        response = self.table.query(
            KeyConditionExpression='PK = :pk AND begins_with(SK, :sk)',
            ExpressionAttributeValues={
                ':pk': f'TEAM#{team_id}',
                ':sk': 'MEMBER#'
            }
        )
        return [TeamMembership(**item) for item in response.get('Items', [])]

    def get_user_teams(self, user_id: str) -> List[TeamMembership]:
        response = self.table.query(
            KeyConditionExpression='PK = :pk AND begins_with(SK, :sk)',
            ExpressionAttributeValues={
                ':pk': f'USER#{user_id}',
                ':sk': 'MEMBERSHIP#'
            }
        )
        return [TeamMembership(**item) for item in response.get('Items', [])]
```

**Quality Criteria**:
- [ ] All hierarchy CRUD implemented
- [ ] Efficient query patterns
- [ ] Multi-team membership working
- [ ] Transactional writes where needed

---

### Worker 3: User Management Service

**Objective**: Implement user management business logic

**Service Implementation**:
```python
# src/services/user_service.py
class UserService:
    """Service for user management."""

    def __init__(self, repository: HierarchyRepository):
        self.repository = repository

    def create_user(self, tenant_id: str, email: str, name: str, team_id: str) -> User:
        """Create a new user in a team."""
        user_id = f"USR-{uuid.uuid4().hex[:8].upper()}"

        user = User(
            user_id=user_id,
            tenant_id=tenant_id,
            email=email,
            name=name,
            status=UserStatus.INVITED,
            primary_team_id=team_id,
            teams=[team_id]
        )

        self.repository.create_user(user)

        # Add team membership
        membership = TeamMembership(
            user_id=user_id,
            team_id=team_id,
            tenant_id=tenant_id,
            role='member'
        )
        self.repository.add_user_to_team(membership)

        return user

    def add_user_to_team(self, user_id: str, team_id: str, tenant_id: str, role: str = 'member') -> TeamMembership:
        """Add user to additional team."""
        user = self.repository.get_user(user_id)

        # Check user belongs to same tenant
        if user.tenant_id != tenant_id:
            raise PermissionError("Cannot add user from different tenant")

        membership = TeamMembership(
            user_id=user_id,
            team_id=team_id,
            tenant_id=tenant_id,
            role=role
        )

        self.repository.add_user_to_team(membership)

        # Update user's team list
        if team_id not in user.teams:
            user.teams.append(team_id)
            self.repository.update_user(user)

        return membership

    def remove_user_from_team(self, user_id: str, team_id: str) -> None:
        """Remove user from a team."""
        user = self.repository.get_user(user_id)

        if user.primary_team_id == team_id:
            raise ValueError("Cannot remove user from primary team")

        self.repository.remove_team_membership(user_id, team_id)

        user.teams = [t for t in user.teams if t != team_id]
        self.repository.update_user(user)

    def get_user_hierarchy(self, user_id: str) -> dict:
        """Get full hierarchy path for a user."""
        user = self.repository.get_user(user_id)
        team = self.repository.get_team(user.primary_team_id)

        hierarchy = {
            'user': user.dict(),
            'team': team.dict(),
        }

        if team.group_id:
            group = self.repository.get_group(team.group_id)
            hierarchy['group'] = group.dict()

            if group.division_id:
                division = self.repository.get_division(group.division_id)
                hierarchy['division'] = division.dict()

        return hierarchy
```

**Quality Criteria**:
- [ ] User CRUD operations
- [ ] Multi-team membership management
- [ ] Hierarchy traversal
- [ ] Tenant isolation enforced

---

### Worker 4: Invitation System

**Objective**: Build email invitation system for users

**Invitation Model**:
```python
# src/models/invitation.py
class InvitationStatus(str, Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    EXPIRED = "expired"
    REVOKED = "revoked"

class Invitation(BaseModel):
    """User invitation to join organization."""
    invitation_id: str
    tenant_id: str
    email: EmailStr
    team_id: str
    invited_by: str  # user_id of inviter
    role: str = "member"
    status: InvitationStatus = InvitationStatus.PENDING
    created_at: datetime = Field(default_factory=datetime.utcnow)
    expires_at: datetime
    accepted_at: Optional[datetime] = None
```

**Invitation Service**:
```python
# src/services/invitation_service.py
class InvitationService:
    """Service for managing user invitations."""

    def __init__(self, repository: HierarchyRepository, ses_client=None):
        self.repository = repository
        self.ses = ses_client or boto3.client('ses')

    def create_invitation(
        self,
        tenant_id: str,
        email: str,
        team_id: str,
        invited_by: str,
        role: str = 'member'
    ) -> Invitation:
        """Create and send user invitation."""
        invitation_id = f"INV-{uuid.uuid4().hex[:8].upper()}"
        expires_at = datetime.utcnow() + timedelta(days=7)

        invitation = Invitation(
            invitation_id=invitation_id,
            tenant_id=tenant_id,
            email=email,
            team_id=team_id,
            invited_by=invited_by,
            role=role,
            expires_at=expires_at
        )

        self.repository.create_invitation(invitation)
        self._send_invitation_email(invitation)

        return invitation

    def accept_invitation(self, invitation_id: str, user_name: str) -> User:
        """Accept invitation and create user."""
        invitation = self.repository.get_invitation(invitation_id)

        if invitation.status != InvitationStatus.PENDING:
            raise ValueError(f"Invitation is {invitation.status.value}")

        if datetime.utcnow() > invitation.expires_at:
            invitation.status = InvitationStatus.EXPIRED
            self.repository.update_invitation(invitation)
            raise ValueError("Invitation has expired")

        # Create user
        user_service = UserService(self.repository)
        user = user_service.create_user(
            tenant_id=invitation.tenant_id,
            email=invitation.email,
            name=user_name,
            team_id=invitation.team_id
        )

        # Mark invitation as accepted
        invitation.status = InvitationStatus.ACCEPTED
        invitation.accepted_at = datetime.utcnow()
        self.repository.update_invitation(invitation)

        return user

    def _send_invitation_email(self, invitation: Invitation) -> None:
        """Send invitation email via SES."""
        invite_url = f"{os.environ['APP_URL']}/invite/{invitation.invitation_id}"

        self.ses.send_email(
            Source=os.environ['FROM_EMAIL'],
            Destination={'ToAddresses': [invitation.email]},
            Message={
                'Subject': {'Data': 'You have been invited to join BBWS'},
                'Body': {
                    'Html': {'Data': f'''
                        <h1>Welcome to BBWS</h1>
                        <p>You have been invited to join an organization.</p>
                        <p>Click the link below to accept:</p>
                        <a href="{invite_url}">Accept Invitation</a>
                        <p>This invitation expires in 7 days.</p>
                    '''}
                }
            }
        )
```

**Quality Criteria**:
- [ ] Invitation creation working
- [ ] Email sending via SES
- [ ] Acceptance workflow complete
- [ ] Expiration handling

---

## Stage Outputs

| Output | Description | Location |
|--------|-------------|----------|
| Hierarchy models | Division, Group, Team, User | `src/models/` |
| Hierarchy repository | DynamoDB access layer | `src/repositories/` |
| User service | User management logic | `src/services/` |
| Invitation service | Invitation system | `src/services/` |

---

## Success Criteria

- [ ] All 4 workers completed
- [ ] Hierarchy CRUD working
- [ ] Multi-team membership functional
- [ ] Invitation system operational
- [ ] Test coverage >= 80%

---

## Dependencies

**Depends On**: Stage T1 (Tenant API)
**Blocks**: Stage T3 (Access Control)

---

## Estimated Duration

| Activity | Agentic | Manual |
|----------|---------|--------|
| Hierarchy models | 20 min | 2 hours |
| Repository | 35 min | 4 hours |
| User service | 25 min | 3 hours |
| Invitation system | 25 min | 3 hours |
| **Total** | **1.75 hours** | **12 hours** |

---

**Navigation**: [<- Stage T1](./stage-t1-tenant-api.md) | [Main Plan](./main-plan.md) | [Stage T3 ->](./stage-t3-access-control.md)
