# Team Service LLD Review - Implementation-Ready Specifications

**Worker ID**: worker-3-team-service-review
**Stage**: Stage 1 - LLD Review & Analysis
**Project**: project-plan-2-access-management
**Source Document**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.8.3_LLD_Team_Service.md`
**Date**: 2026-01-23
**Status**: COMPLETE

---

## Executive Summary

The Team Service LLD (2.8.3) defines 14 Lambda functions for managing teams, team members, and configurable team roles within the BBWS Access Management system. Teams are the primary unit of data isolation - users can only access WordPress sites belonging to their teams.

---

## 1. Lambda Function Checklist (14 Functions)

### 1.1 Team Operations (4 Functions)

| # | Function Name | Handler File | Method | Endpoint | Auth Required | Description |
|---|--------------|--------------|--------|----------|---------------|-------------|
| 1 | create_team | `handlers/team/create_team.py` | POST | `/v1/organisations/{orgId}/teams` | Org Admin | Create a new team |
| 2 | list_teams | `handlers/team/list_teams.py` | GET | `/v1/organisations/{orgId}/teams` | Org Member | List organisation teams |
| 3 | get_team | `handlers/team/get_team.py` | GET | `/v1/organisations/{orgId}/teams/{teamId}` | Team Member | Get team details |
| 4 | update_team | `handlers/team/update_team.py` | PUT | `/v1/organisations/{orgId}/teams/{teamId}` | Team Lead | Update team details |

### 1.2 Team Role Operations (5 Functions)

| # | Function Name | Handler File | Method | Endpoint | Auth Required | Description |
|---|--------------|--------------|--------|----------|---------------|-------------|
| 5 | create_team_role | `handlers/team_role/create_team_role.py` | POST | `/v1/organisations/{orgId}/team-roles` | Org Admin | Create custom team role |
| 6 | list_team_roles | `handlers/team_role/list_team_roles.py` | GET | `/v1/organisations/{orgId}/team-roles` | Org Member | List org team roles |
| 7 | get_team_role | `handlers/team_role/get_team_role.py` | GET | `/v1/organisations/{orgId}/team-roles/{roleId}` | Org Member | Get role details |
| 8 | update_team_role | `handlers/team_role/update_team_role.py` | PUT | `/v1/organisations/{orgId}/team-roles/{roleId}` | Org Admin | Update team role |
| 9 | delete_team_role | `handlers/team_role/update_team_role.py` | PUT | `/v1/organisations/{orgId}/team-roles/{roleId}` | Org Admin | Deactivate team role (soft delete via active=false) |

### 1.3 Team Member Operations (5 Functions)

| # | Function Name | Handler File | Method | Endpoint | Auth Required | Description |
|---|--------------|--------------|--------|----------|---------------|-------------|
| 10 | add_member | `handlers/member/add_member.py` | POST | `/v1/organisations/{orgId}/teams/{teamId}/members` | Team Lead | Add member to team |
| 11 | list_members | `handlers/member/list_members.py` | GET | `/v1/organisations/{orgId}/teams/{teamId}/members` | Team Member | List team members |
| 12 | get_member | `handlers/member/get_member.py` | GET | `/v1/organisations/{orgId}/teams/{teamId}/members/{userId}` | Team Member | Get member details |
| 13 | update_member | `handlers/member/update_member.py` | PUT | `/v1/organisations/{orgId}/teams/{teamId}/members/{userId}` | Team Lead | Update/remove member |
| 14 | get_user_teams | `handlers/member/get_user_teams.py` | GET | `/v1/organisations/{orgId}/users/{userId}/teams` | Self/Admin | Get user's team memberships |

### Lambda Configuration

| Attribute | Value |
|-----------|-------|
| Repository | `2_bbws_access_team_lambda` |
| Runtime | Python 3.12 |
| Memory | 256MB |
| Timeout | 30s |
| Architecture | arm64 |
| Layer | aws-lambda-powertools |

---

## 2. API Contract Summary (14 Endpoints)

### 2.1 Team Endpoints

#### POST /v1/organisations/{orgId}/teams
**Operation**: createTeam
**Auth**: Org Admin (team:create)

**Request Body**:
```json
{
  "name": "string (2-100 chars, required)",
  "description": "string (max 500 chars)",
  "divisionId": "string (optional)",
  "groupId": "string (optional)"
}
```

**Response**: 201 Created
```json
{
  "id": "uuid",
  "name": "string",
  "description": "string",
  "organisationId": "string",
  "divisionId": "string|null",
  "groupId": "string|null",
  "memberCount": 0,
  "siteCount": 0,
  "active": true,
  "dateCreated": "ISO8601",
  "dateLastUpdated": "ISO8601",
  "createdBy": "string",
  "_links": {}
}
```

**Error Responses**: 409 (Team name already exists)

---

#### GET /v1/organisations/{orgId}/teams
**Operation**: listTeams
**Auth**: Org Member

**Query Parameters**:
- `divisionId` (optional): Filter by division
- `includeInactive` (boolean, default: false)
- `pageSize` (integer, default: 50)
- `startAt` (string, pagination cursor)

**Response**: 200 OK
```json
{
  "items": [TeamResponse],
  "startAt": "string",
  "moreAvailable": boolean,
  "count": integer,
  "_links": {}
}
```

---

#### GET /v1/organisations/{orgId}/teams/{teamId}
**Operation**: getTeam
**Auth**: Team Member

**Response**: 200 OK (TeamResponse)
**Error Responses**: 404 (Team not found)

---

#### PUT /v1/organisations/{orgId}/teams/{teamId}
**Operation**: updateTeam
**Auth**: Team Lead (CAN_UPDATE_TEAM)

**Request Body**:
```json
{
  "name": "string (optional)",
  "description": "string (optional)",
  "divisionId": "string (optional)",
  "groupId": "string (optional)",
  "active": "boolean (optional, for soft delete)"
}
```

**Response**: 200 OK (TeamResponse)

---

### 2.2 Team Role Endpoints

#### POST /v1/organisations/{orgId}/team-roles
**Operation**: createTeamRole
**Auth**: Org Admin (team:role:create)

**Request Body**:
```json
{
  "name": "string (2-50 chars, pattern: ^[A-Z][A-Z0-9_]*$, required)",
  "displayName": "string (2-100 chars, required)",
  "description": "string (max 500 chars)",
  "capabilities": ["CAN_MANAGE_MEMBERS", "CAN_VIEW_MEMBERS", ...] (min 1 required),
  "sortOrder": "integer (1-999, default: 100)"
}
```

**Response**: 201 Created
```json
{
  "id": "uuid",
  "name": "string",
  "displayName": "string",
  "description": "string",
  "capabilities": ["string"],
  "isDefault": false,
  "sortOrder": integer,
  "active": true,
  "dateCreated": "ISO8601",
  "dateLastUpdated": "ISO8601",
  "_links": {}
}
```

**Error Responses**: 409 (Role name already exists)

---

#### GET /v1/organisations/{orgId}/team-roles
**Operation**: listTeamRoles
**Auth**: Org Member

**Query Parameters**:
- `includeInactive` (boolean, default: false)
- `defaultsOnly` (boolean, default: false)
- `pageSize` (integer, default: 50)
- `startAt` (string, pagination cursor)

**Response**: 200 OK (TeamRoleListResponse)

---

#### GET /v1/organisations/{orgId}/team-roles/{roleId}
**Operation**: getTeamRole
**Auth**: Org Member

**Response**: 200 OK (TeamRoleResponse)
**Error Responses**: 404 (Role not found)

---

#### PUT /v1/organisations/{orgId}/team-roles/{roleId}
**Operation**: updateTeamRole
**Auth**: Org Admin

**Request Body**:
```json
{
  "displayName": "string (optional)",
  "description": "string (optional)",
  "capabilities": ["string"] (optional, min 1 if provided),
  "sortOrder": "integer (optional)",
  "active": "boolean (optional, set to false to deactivate)"
}
```

**Response**: 200 OK (TeamRoleResponse)
**Error Responses**: 400 (Cannot deactivate role in use)

---

### 2.3 Team Member Endpoints

#### POST /v1/organisations/{orgId}/teams/{teamId}/members
**Operation**: addMember
**Auth**: Team Lead (team:member:add, CAN_MANAGE_MEMBERS)

**Request Body**:
```json
{
  "userId": "string (required, must be org member)",
  "teamRoleId": "string (required, reference to team role)"
}
```

**Response**: 201 Created
```json
{
  "userId": "string",
  "email": "string",
  "firstName": "string",
  "lastName": "string",
  "teamRoleId": "string",
  "teamRoleName": "string",
  "joinedAt": "ISO8601",
  "addedBy": "string",
  "active": true,
  "dateCreated": "ISO8601",
  "_links": {}
}
```

**Error Responses**:
- 409 (User already a member)
- 400 (User not in org)

---

#### GET /v1/organisations/{orgId}/teams/{teamId}/members
**Operation**: listMembers
**Auth**: Team Member (team:member:read)

**Query Parameters**:
- `teamRoleId` (optional): Filter by role
- `includeInactive` (boolean, default: false)
- `pageSize` (integer, default: 50)
- `startAt` (string, pagination cursor)

**Response**: 200 OK (MemberListResponse)
**Error Responses**: 403 (Not a team member)

---

#### GET /v1/organisations/{orgId}/teams/{teamId}/members/{userId}
**Operation**: getMember
**Auth**: Team Member

**Response**: 200 OK (TeamMemberResponse)
**Error Responses**: 404 (Member not found)

---

#### PUT /v1/organisations/{orgId}/teams/{teamId}/members/{userId}
**Operation**: updateMember
**Auth**: Team Lead (team:member:remove, CAN_MANAGE_MEMBERS)

**Request Body**:
```json
{
  "teamRoleId": "string (optional, to change role)",
  "active": "boolean (optional, set to false to remove)"
}
```

**Response**: 200 OK (TeamMemberResponse)
**Error Responses**: 400 (Cannot remove last team lead)

---

#### POST /v1/organisations/{orgId}/teams/{teamId}/members/{userId}/transfer
**Operation**: transferMember
**Auth**: Org Admin (org:user:manage)

**Request Body**:
```json
{
  "toTeamId": "string (required)",
  "teamRoleId": "string (optional, defaults to current role)"
}
```

**Response**: 200 OK (TeamMemberResponse)

---

#### GET /v1/organisations/{orgId}/users/{userId}/teams
**Operation**: getUserTeams
**Auth**: Self or Org Admin

**Response**: 200 OK
```json
{
  "teams": [
    {
      "teamId": "string",
      "teamName": "string",
      "teamRoleId": "string",
      "teamRoleName": "string",
      "joinedAt": "ISO8601",
      "isPrimary": boolean,
      "siteCount": integer,
      "_links": {}
    }
  ],
  "_links": {}
}
```

**Error Responses**: 403 (Can only view own teams or must be admin)

---

## 3. DynamoDB Schema

### 3.1 Table Configuration

**Table Name**: `bbws-aipagebuilder-{env}-ddb-access-management`
**Capacity Mode**: On-Demand (PAY_PER_REQUEST)

### 3.2 Team Entity

| Attribute | Type | Description |
|-----------|------|-------------|
| PK | String | `ORG#{organisationId}` |
| SK | String | `TEAM#{teamId}` |
| teamId | String | UUID |
| name | String | Team name (unique per org) |
| description | String | Team description |
| organisationId | String | Parent organisation UUID |
| divisionId | String | Optional division UUID |
| groupId | String | Optional group UUID |
| memberCount | Number | Current member count |
| siteCount | Number | Number of sites assigned |
| active | Boolean | Soft delete flag |
| dateCreated | String | ISO 8601 timestamp |
| dateLastUpdated | String | ISO 8601 timestamp |
| createdBy | String | Creator email |
| lastUpdatedBy | String | Last updater email |
| GSI1PK | String | `ORG#{organisationId}#ACTIVE#{active}` |
| GSI1SK | String | `TEAM#{name}` |
| GSI2PK | String | `ORG#{organisationId}#DIV#{divisionId}` |
| GSI2SK | String | `TEAM#{teamId}` |

### 3.3 TeamRoleDefinition Entity

| Attribute | Type | Description |
|-----------|------|-------------|
| PK | String | `ORG#{organisationId}` |
| SK | String | `TEAMROLE#{teamRoleId}` |
| teamRoleId | String | UUID |
| name | String | Role code name (e.g., TEAM_LEAD) |
| displayName | String | Human-readable name |
| description | String | Role description |
| organisationId | String | Parent organisation UUID |
| capabilities | StringSet | List of capability values |
| isDefault | Boolean | True if seeded default role |
| sortOrder | Number | Display order (1=highest) |
| active | Boolean | Soft delete flag |
| dateCreated | String | ISO 8601 timestamp |
| dateLastUpdated | String | ISO 8601 timestamp |
| createdBy | String | Creator email |
| lastUpdatedBy | String | Last updater email |
| GSI1PK | String | `ORG#{organisationId}#ACTIVE#{active}` |
| GSI1SK | String | `TEAMROLE#{name}` |

### 3.4 TeamMember Entity

| Attribute | Type | Description |
|-----------|------|-------------|
| PK | String | `ORG#{organisationId}#TEAM#{teamId}` |
| SK | String | `MEMBER#{userId}` |
| organisationId | String | Organisation UUID |
| teamId | String | Team UUID |
| userId | String | User UUID |
| userEmail | String | User email (denormalized) |
| userFirstName | String | User first name (denormalized) |
| userLastName | String | User last name (denormalized) |
| teamRoleId | String | Reference to TeamRoleDefinition |
| teamRoleName | String | Role name (denormalized for display) |
| joinedAt | String | ISO 8601 timestamp |
| addedBy | String | Email of who added them |
| active | Boolean | Soft delete flag |
| dateCreated | String | ISO 8601 timestamp |
| dateLastUpdated | String | ISO 8601 timestamp |
| lastUpdatedBy | String | Last updater email |
| GSI1PK | String | `USER#{userId}` |
| GSI1SK | String | `ORG#{organisationId}#TEAM#{teamId}` |
| GSI2PK | String | `ORG#{organisationId}#TEAM#{teamId}#ROLE#{teamRoleId}` |
| GSI2SK | String | `MEMBER#{userId}` |

### 3.5 GSI Definitions

| GSI Name | PK | SK | Purpose |
|----------|----|----|---------|
| GSI1 | GSI1PK | GSI1SK | User's teams lookup, team/role name lookup |
| GSI2 | GSI2PK | GSI2SK | Division teams, role filtering |

### 3.6 Access Patterns

| Pattern | Query | Index |
|---------|-------|-------|
| Get team by ID | PK=`ORG#{orgId}`, SK=`TEAM#{teamId}` | Table |
| List org teams | PK=`ORG#{orgId}`, SK begins_with `TEAM#` | Table |
| Find team by name | GSI1PK=`ORG#{orgId}#ACTIVE#true`, GSI1SK=`TEAM#{name}` | GSI1 |
| List division teams | GSI2PK=`ORG#{orgId}#DIV#{divId}`, SK begins_with `TEAM#` | GSI2 |
| Get team role by ID | PK=`ORG#{orgId}`, SK=`TEAMROLE#{roleId}` | Table |
| List org team roles | PK=`ORG#{orgId}`, SK begins_with `TEAMROLE#` | Table |
| Find role by name | GSI1PK=`ORG#{orgId}#ACTIVE#true`, GSI1SK=`TEAMROLE#{name}` | GSI1 |
| Get team member | PK=`ORG#{orgId}#TEAM#{teamId}`, SK=`MEMBER#{userId}` | Table |
| List team members | PK=`ORG#{orgId}#TEAM#{teamId}`, SK begins_with `MEMBER#` | Table |
| Get user's teams | GSI1PK=`USER#{userId}`, GSI1SK begins_with `ORG#{orgId}#TEAM#` | GSI1 |
| List members by role | GSI2PK=`ORG#{orgId}#TEAM#{teamId}#ROLE#{roleId}` | GSI2 |

---

## 4. Configurable Team Roles (Capabilities System)

### 4.1 Team Role Capabilities (Enumeration)

| Capability | Code | Description |
|------------|------|-------------|
| Manage Members | `CAN_MANAGE_MEMBERS` | Add, remove, update team members |
| Update Team | `CAN_UPDATE_TEAM` | Update team name, description |
| View Members | `CAN_VIEW_MEMBERS` | View team member list |
| View Sites | `CAN_VIEW_SITES` | View sites belonging to team |
| Edit Sites | `CAN_EDIT_SITES` | Edit sites belonging to team |
| Delete Sites | `CAN_DELETE_SITES` | Delete sites belonging to team |
| View Audit | `CAN_VIEW_AUDIT` | View audit logs for team |

### 4.2 Capability Validation

```python
class TeamRoleCapability(str, Enum):
    """Valid capabilities that can be assigned to team roles."""
    CAN_MANAGE_MEMBERS = "CAN_MANAGE_MEMBERS"
    CAN_UPDATE_TEAM = "CAN_UPDATE_TEAM"
    CAN_VIEW_MEMBERS = "CAN_VIEW_MEMBERS"
    CAN_VIEW_SITES = "CAN_VIEW_SITES"
    CAN_EDIT_SITES = "CAN_EDIT_SITES"
    CAN_DELETE_SITES = "CAN_DELETE_SITES"
    CAN_VIEW_AUDIT = "CAN_VIEW_AUDIT"
```

### 4.3 Key Principles

1. **Organisation-Scoped**: Team roles are defined per organisation
2. **Default Roles**: Seeded when organisation is created
3. **Customizable**: Org admins can modify defaults or create new roles
4. **Reference by ID**: Team membership references teamRoleId (not hardcoded name)
5. **Protection**: Cannot delete role that is assigned to active members

---

## 5. Default Team Roles

### 5.1 Default Roles (Seeded on Organisation Creation)

| Role Name | Display Name | Capabilities | Sort Order | Description |
|-----------|--------------|--------------|------------|-------------|
| TEAM_LEAD | Team Lead | CAN_MANAGE_MEMBERS, CAN_UPDATE_TEAM, CAN_VIEW_MEMBERS, CAN_VIEW_SITES, CAN_EDIT_SITES, CAN_DELETE_SITES | 1 | Full team management access |
| SENIOR_MEMBER | Senior Member | CAN_VIEW_MEMBERS, CAN_VIEW_SITES, CAN_EDIT_SITES | 2 | Can edit sites but not manage members |
| MEMBER | Member | CAN_VIEW_MEMBERS, CAN_VIEW_SITES | 3 | View-only access to team and sites |
| VIEWER | Viewer | CAN_VIEW_MEMBERS | 4 | Minimal read-only access |

### 5.2 Default Roles Python Configuration

```python
DEFAULT_TEAM_ROLES = [
    {
        "name": "TEAM_LEAD",
        "display_name": "Team Lead",
        "description": "Team lead with full team management capabilities",
        "capabilities": [
            TeamRoleCapability.CAN_MANAGE_MEMBERS,
            TeamRoleCapability.CAN_UPDATE_TEAM,
            TeamRoleCapability.CAN_VIEW_MEMBERS,
            TeamRoleCapability.CAN_VIEW_SITES,
            TeamRoleCapability.CAN_EDIT_SITES,
            TeamRoleCapability.CAN_DELETE_SITES,
        ],
        "is_default": True,
        "sort_order": 1,
    },
    {
        "name": "SENIOR_MEMBER",
        "display_name": "Senior Member",
        "description": "Senior team member with edit capabilities",
        "capabilities": [
            TeamRoleCapability.CAN_VIEW_MEMBERS,
            TeamRoleCapability.CAN_VIEW_SITES,
            TeamRoleCapability.CAN_EDIT_SITES,
        ],
        "is_default": True,
        "sort_order": 2,
    },
    {
        "name": "MEMBER",
        "display_name": "Member",
        "description": "Standard team member with view capabilities",
        "capabilities": [
            TeamRoleCapability.CAN_VIEW_MEMBERS,
            TeamRoleCapability.CAN_VIEW_SITES,
        ],
        "is_default": True,
        "sort_order": 3,
    },
    {
        "name": "VIEWER",
        "display_name": "Viewer",
        "description": "Read-only team member",
        "capabilities": [
            TeamRoleCapability.CAN_VIEW_MEMBERS,
        ],
        "is_default": True,
        "sort_order": 4,
    },
]
```

### 5.3 Role Lifecycle

1. Default roles are created when organisation is created (via `seedDefaultRoles()`)
2. Admin can modify default roles (displayName, description, capabilities)
3. Admin can create new custom roles
4. Admin can deactivate roles that are not in use
5. Cannot deactivate a role that has active members assigned

---

## 6. Integration Points

### 6.1 Service Dependencies

| Service | Integration Type | Purpose |
|---------|------------------|---------|
| Organisation Service | Sync Call | Validate org exists, seed default roles on org creation |
| User Service | Sync Call | Validate user exists in org before adding to team |
| Audit Service | Async Event | Log team/member/role changes |
| Invitation Service | Event Consumer | Accept invitation triggers add_member |
| Site Service | Sync Call | Team-site association, filter sites by teamIds |

### 6.2 Event Publishing (SNS/EventBridge)

| Event | Trigger | Payload |
|-------|---------|---------|
| TeamCreated | create_team | teamId, orgId, name, createdBy |
| TeamUpdated | update_team | teamId, changes, updatedBy |
| TeamDeactivated | update_team (active=false) | teamId, deactivatedBy |
| TeamRoleCreated | create_team_role | roleId, orgId, name, capabilities |
| TeamRoleUpdated | update_team_role | roleId, changes, updatedBy |
| MemberAdded | add_member | teamId, userId, teamRoleId, addedBy |
| MemberRemoved | update_member (active=false) | teamId, userId, removedBy |
| MemberRoleChanged | update_member (teamRoleId) | teamId, userId, oldRole, newRole |
| MemberTransferred | transfer_member | userId, fromTeamId, toTeamId |

### 6.3 Event Consumption

| Event | Source | Action |
|-------|--------|--------|
| OrganisationCreated | Organisation Service | Trigger seedDefaultRoles() |
| InvitationAccepted | Invitation Service | Trigger add_member for team invitation |
| UserDeactivated | User Service | Deactivate all team memberships |

### 6.4 Email Notifications (SES)

| Event | Recipient | Template |
|-------|-----------|----------|
| Member added | New member | team_member_added |
| Member removed | Removed member | team_member_removed |
| Role changed | Member | team_role_changed |
| Member transferred | Member | team_member_transferred |
| Team deactivated | All members | team_deactivated |

### 6.5 Data Isolation Flow

The Team Service is central to data isolation:

```
User Request for Site Data
         |
         v
+-------------------------+
|    Lambda Authorizer    |
|  Extract user's teamIds |
|  from JWT + DynamoDB    |
+------------+------------+
             |
             v context.teamIds = ["team-A", "team-B"]
+-------------------------+
|    Site Service Lambda  |
|  Filter: site.teamId    |
|  IN context.teamIds     |
+------------+------------+
             |
             v Only returns sites from Team A and Team B
+-------------------------+
|       Response          |
|  Sites user can access  |
+-------------------------+
```

---

## 7. Risk Assessment

### 7.1 Identified Risks

| Risk ID | Risk | Impact | Likelihood | Mitigation |
|---------|------|--------|------------|------------|
| R-T-001 | Remove last team lead | High | Medium | Check lead count before removal; throw `CannotRemoveLastLeadException` |
| R-T-002 | Duplicate team names within org | Low | Medium | Unique constraint per org via GSI query before create |
| R-T-003 | Member count inconsistency | Medium | Low | Transactional updates with DynamoDB transactions; periodic reconciliation |
| R-T-004 | Cross-team data leak | High | Low | Auth context includes teamIds for filtering; strict authorization checks |
| R-T-005 | Orphan memberships | Medium | Low | Cascade deactivate on team delete; cleanup job |
| R-T-006 | Role in use deletion | Medium | Medium | Check member count before role deactivation; throw `RoleInUseException` |
| R-T-007 | Invalid capability assignment | Low | Low | Validate capabilities against enum before save |
| R-T-008 | Permission escalation | High | Low | Validate caller has CAN_MANAGE_MEMBERS to modify roles |

### 7.2 Security Controls

| Control | Implementation |
|---------|----------------|
| Authorization | Team leads can add/remove members in their team only |
| Org Admin Override | Org admins can manage any team in their org |
| Data Isolation | Auth context includes `teamIds[]` for filtering |
| Cross-team Protection | Lambda handlers filter results by authorized teams |
| Forbidden Access | Cross-team queries rejected with 403 |
| PII Protection | User data encrypted at rest (DynamoDB KMS) |
| Transport Security | TLS 1.3 for all communications |

### 7.3 Exception Classes

```python
class TeamNotFoundException(Exception):
    """Raised when team not found."""
    pass

class TeamRoleNotFoundException(Exception):
    """Raised when team role not found."""
    pass

class MemberNotFoundException(Exception):
    """Raised when member not found in team."""
    pass

class DuplicateTeamNameException(Exception):
    """Raised when team name already exists in org."""
    pass

class DuplicateRoleNameException(Exception):
    """Raised when role name already exists in org."""
    pass

class UserAlreadyMemberException(Exception):
    """Raised when user is already a team member."""
    pass

class UserNotInOrgException(Exception):
    """Raised when user is not a member of the organisation."""
    pass

class InsufficientPermissionException(Exception):
    """Raised when user lacks required permission."""
    pass

class CannotRemoveLastLeadException(Exception):
    """Raised when trying to remove the last team lead."""
    pass

class RoleInUseException(Exception):
    """Raised when trying to delete a role that has members."""
    pass
```

---

## 8. Non-Functional Requirements

| Metric | Target |
|--------|--------|
| Create team latency (p95) | < 500ms |
| Add member latency (p95) | < 500ms |
| List members latency (p95) | < 200ms |
| Get user teams latency (p95) | < 200ms |
| Lambda cold start | < 2s |
| Error rate | < 0.1% |

---

## 9. Project Structure (Repository)

```
2_bbws_access_team_lambda/
├── src/
│   ├── handlers/
│   │   ├── __init__.py
│   │   ├── team/
│   │   │   ├── __init__.py
│   │   │   ├── create_team.py
│   │   │   ├── list_teams.py
│   │   │   ├── get_team.py
│   │   │   └── update_team.py
│   │   ├── team_role/
│   │   │   ├── __init__.py
│   │   │   ├── create_team_role.py
│   │   │   ├── list_team_roles.py
│   │   │   ├── get_team_role.py
│   │   │   └── update_team_role.py
│   │   └── member/
│   │       ├── __init__.py
│   │       ├── add_member.py
│   │       ├── list_members.py
│   │       ├── get_member.py
│   │       ├── update_member.py
│   │       ├── transfer_member.py
│   │       └── get_user_teams.py
│   ├── services/
│   │   ├── __init__.py
│   │   ├── team_service.py
│   │   ├── team_role_service.py
│   │   └── team_member_service.py
│   ├── repositories/
│   │   ├── __init__.py
│   │   ├── team_repository.py
│   │   ├── team_role_repository.py
│   │   └── team_member_repository.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── team.py
│   │   ├── team_role.py
│   │   ├── team_member.py
│   │   ├── capabilities.py
│   │   └── requests.py
│   ├── exceptions/
│   │   ├── __init__.py
│   │   └── team_exceptions.py
│   └── utils/
│       ├── __init__.py
│       ├── response_builder.py
│       ├── validators.py
│       ├── default_roles.py
│       └── hateoas.py
├── tests/
│   ├── unit/
│   │   ├── test_handlers/
│   │   ├── test_services/
│   │   └── test_repositories/
│   └── integration/
│       └── test_api.py
├── terraform/
│   ├── main.tf
│   ├── api_gateway.tf
│   ├── lambda.tf
│   ├── iam.tf
│   ├── variables.tf
│   └── outputs.tf
├── openapi/
│   └── team-service-api.yaml
├── requirements.txt
├── pytest.ini
└── README.md
```

---

## 10. Tagging Standards

| Tag | Value |
|-----|-------|
| Project | BBWS |
| Component | TeamService |
| CostCenter | BBWS-ACCESS |
| Environment | {env} (dev/sit/prod) |
| ManagedBy | Terraform |

---

## 11. Success Criteria Checklist

- [x] All 14 Lambda functions documented
- [x] All API endpoints specified with request/response schemas
- [x] DynamoDB schema complete for all 3 entities (Team, TeamRoleDefinition, TeamMember)
- [x] Team role capabilities documented (7 capabilities)
- [x] Default roles defined (4 roles: TEAM_LEAD, SENIOR_MEMBER, MEMBER, VIEWER)
- [x] Integration points identified (5 services + events + notifications)
- [x] Risks assessed (8 risks with mitigations)

---

## 12. References

- **Source LLD**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.8.3_LLD_Team_Service.md`
- **Parent HLD**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.8_HLD_Access_Management.md`
- **Related LLDs**:
  - LLD 2.8.1: Permission Service
  - LLD 2.8.2: Invitation Service

---

**Document Status**: COMPLETE
**Generated**: 2026-01-23
**Worker**: worker-3-team-service-review
