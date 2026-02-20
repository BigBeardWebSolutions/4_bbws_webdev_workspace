# Team Service Lambda Functions - Implementation Output

**Worker ID**: worker-3-team-service-lambdas
**Stage**: Stage 3 - Lambda Services Development
**Project**: project-plan-2-access-management
**Date**: 2026-01-23
**Status**: COMPLETE

---

## Executive Summary

This document contains the complete implementation of 14 Lambda functions for the Team Service, including:
- 3 Domain Models (Team, TeamRoleDefinition, TeamMember)
- 7 Team Role Capabilities
- 4 Default Team Roles
- 14 Lambda Handlers (4 Team + 5 Team Role + 5 Member)
- Comprehensive unit tests with pytest + moto

All code follows TDD principles (tests written first) and OOP design patterns.

---

## Table of Contents

1. [Project Structure](#1-project-structure)
2. [Models](#2-models)
3. [Exceptions](#3-exceptions)
4. [Repositories](#4-repositories)
5. [Services](#5-services)
6. [Handlers](#6-handlers)
7. [Unit Tests](#7-unit-tests)
8. [Configuration](#8-configuration)

---

## 1. Project Structure

```
2_bbws_access_team_lambda/
├── src/
│   ├── __init__.py
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
│   │   │   ├── update_team_role.py
│   │   │   └── delete_team_role.py
│   │   └── member/
│   │       ├── __init__.py
│   │       ├── add_member.py
│   │       ├── list_members.py
│   │       ├── get_member.py
│   │       ├── update_member.py
│   │       └── get_user_teams.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── team.py
│   │   ├── team_role.py
│   │   ├── team_member.py
│   │   ├── capabilities.py
│   │   └── requests.py
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
│   ├── __init__.py
│   ├── conftest.py
│   ├── unit/
│   │   ├── __init__.py
│   │   ├── test_models/
│   │   ├── test_services/
│   │   ├── test_repositories/
│   │   └── test_handlers/
│   └── integration/
│       └── test_api.py
├── requirements.txt
├── requirements-dev.txt
└── pytest.ini
```

---

## 2. Models

### 2.1 src/models/capabilities.py

```python
"""
Team Role Capabilities - Defines what actions a team role can perform.
"""
from enum import Enum
from typing import List


class TeamRoleCapability(str, Enum):
    """
    Valid capabilities that can be assigned to team roles.

    These capabilities control what actions members with a given role
    can perform within their team context.
    """
    CAN_MANAGE_MEMBERS = "CAN_MANAGE_MEMBERS"
    CAN_UPDATE_TEAM = "CAN_UPDATE_TEAM"
    CAN_VIEW_MEMBERS = "CAN_VIEW_MEMBERS"
    CAN_VIEW_SITES = "CAN_VIEW_SITES"
    CAN_EDIT_SITES = "CAN_EDIT_SITES"
    CAN_DELETE_SITES = "CAN_DELETE_SITES"
    CAN_VIEW_AUDIT = "CAN_VIEW_AUDIT"

    @classmethod
    def all_capabilities(cls) -> List[str]:
        """Return all capability values as a list of strings."""
        return [cap.value for cap in cls]

    @classmethod
    def validate_capabilities(cls, capabilities: List[str]) -> bool:
        """Validate that all capabilities are valid enum values."""
        valid_caps = cls.all_capabilities()
        return all(cap in valid_caps for cap in capabilities)

    @classmethod
    def get_invalid_capabilities(cls, capabilities: List[str]) -> List[str]:
        """Return list of invalid capability strings."""
        valid_caps = cls.all_capabilities()
        return [cap for cap in capabilities if cap not in valid_caps]
```

### 2.2 src/models/team.py

```python
"""
Team Model - Represents a team within an organisation.
"""
from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional, Dict, Any
import uuid


@dataclass
class Team:
    """
    Represents a team within an organisation.

    Teams are the primary unit of data isolation - users can only access
    WordPress sites belonging to their teams.
    """
    team_id: str
    name: str
    organisation_id: str
    description: str = ""
    division_id: Optional[str] = None
    group_id: Optional[str] = None
    member_count: int = 0
    site_count: int = 0
    active: bool = True
    date_created: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    date_last_updated: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    created_by: str = ""
    last_updated_by: str = ""

    @classmethod
    def create(
        cls,
        name: str,
        organisation_id: str,
        created_by: str,
        description: str = "",
        division_id: Optional[str] = None,
        group_id: Optional[str] = None
    ) -> "Team":
        """Factory method to create a new Team."""
        now = datetime.utcnow().isoformat()
        return cls(
            team_id=str(uuid.uuid4()),
            name=name,
            organisation_id=organisation_id,
            description=description,
            division_id=division_id,
            group_id=group_id,
            member_count=0,
            site_count=0,
            active=True,
            date_created=now,
            date_last_updated=now,
            created_by=created_by,
            last_updated_by=created_by
        )

    def update(
        self,
        updated_by: str,
        name: Optional[str] = None,
        description: Optional[str] = None,
        division_id: Optional[str] = None,
        group_id: Optional[str] = None,
        active: Optional[bool] = None
    ) -> "Team":
        """Update team attributes and return self."""
        if name is not None:
            self.name = name
        if description is not None:
            self.description = description
        if division_id is not None:
            self.division_id = division_id
        if group_id is not None:
            self.group_id = group_id
        if active is not None:
            self.active = active
        self.date_last_updated = datetime.utcnow().isoformat()
        self.last_updated_by = updated_by
        return self

    def increment_member_count(self) -> None:
        """Increment member count."""
        self.member_count += 1

    def decrement_member_count(self) -> None:
        """Decrement member count, minimum 0."""
        self.member_count = max(0, self.member_count - 1)

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for DynamoDB."""
        return {
            "teamId": self.team_id,
            "name": self.name,
            "description": self.description,
            "organisationId": self.organisation_id,
            "divisionId": self.division_id,
            "groupId": self.group_id,
            "memberCount": self.member_count,
            "siteCount": self.site_count,
            "active": self.active,
            "dateCreated": self.date_created,
            "dateLastUpdated": self.date_last_updated,
            "createdBy": self.created_by,
            "lastUpdatedBy": self.last_updated_by
        }

    def to_response(self, base_url: str = "") -> Dict[str, Any]:
        """Convert to API response format with HATEOAS links."""
        response = self.to_dict()
        response["id"] = self.team_id
        response["_links"] = {
            "self": {"href": f"{base_url}/v1/organisations/{self.organisation_id}/teams/{self.team_id}"},
            "members": {"href": f"{base_url}/v1/organisations/{self.organisation_id}/teams/{self.team_id}/members"},
            "organisation": {"href": f"{base_url}/v1/organisations/{self.organisation_id}"}
        }
        return response

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "Team":
        """Create Team from dictionary."""
        return cls(
            team_id=data.get("teamId", ""),
            name=data.get("name", ""),
            organisation_id=data.get("organisationId", ""),
            description=data.get("description", ""),
            division_id=data.get("divisionId"),
            group_id=data.get("groupId"),
            member_count=data.get("memberCount", 0),
            site_count=data.get("siteCount", 0),
            active=data.get("active", True),
            date_created=data.get("dateCreated", ""),
            date_last_updated=data.get("dateLastUpdated", ""),
            created_by=data.get("createdBy", ""),
            last_updated_by=data.get("lastUpdatedBy", "")
        )
```

### 2.3 src/models/team_role.py

```python
"""
Team Role Definition Model - Configurable roles for team members.
"""
from dataclasses import dataclass, field
from datetime import datetime
from typing import List, Optional, Dict, Any
import uuid

from .capabilities import TeamRoleCapability


@dataclass
class TeamRoleDefinition:
    """
    Represents a configurable team role definition.

    Team roles are organisation-scoped and define capabilities
    that members with that role can perform within teams.
    """
    team_role_id: str
    name: str
    display_name: str
    organisation_id: str
    capabilities: List[str]
    description: str = ""
    is_default: bool = False
    sort_order: int = 100
    active: bool = True
    date_created: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    date_last_updated: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    created_by: str = ""
    last_updated_by: str = ""

    @classmethod
    def create(
        cls,
        name: str,
        display_name: str,
        organisation_id: str,
        capabilities: List[str],
        created_by: str,
        description: str = "",
        is_default: bool = False,
        sort_order: int = 100
    ) -> "TeamRoleDefinition":
        """Factory method to create a new TeamRoleDefinition."""
        # Validate capabilities
        if not TeamRoleCapability.validate_capabilities(capabilities):
            invalid = TeamRoleCapability.get_invalid_capabilities(capabilities)
            raise ValueError(f"Invalid capabilities: {invalid}")

        now = datetime.utcnow().isoformat()
        return cls(
            team_role_id=str(uuid.uuid4()),
            name=name.upper().replace(" ", "_"),
            display_name=display_name,
            organisation_id=organisation_id,
            capabilities=capabilities,
            description=description,
            is_default=is_default,
            sort_order=sort_order,
            active=True,
            date_created=now,
            date_last_updated=now,
            created_by=created_by,
            last_updated_by=created_by
        )

    def update(
        self,
        updated_by: str,
        display_name: Optional[str] = None,
        description: Optional[str] = None,
        capabilities: Optional[List[str]] = None,
        sort_order: Optional[int] = None,
        active: Optional[bool] = None
    ) -> "TeamRoleDefinition":
        """Update role attributes and return self."""
        if display_name is not None:
            self.display_name = display_name
        if description is not None:
            self.description = description
        if capabilities is not None:
            if not TeamRoleCapability.validate_capabilities(capabilities):
                invalid = TeamRoleCapability.get_invalid_capabilities(capabilities)
                raise ValueError(f"Invalid capabilities: {invalid}")
            self.capabilities = capabilities
        if sort_order is not None:
            self.sort_order = sort_order
        if active is not None:
            self.active = active
        self.date_last_updated = datetime.utcnow().isoformat()
        self.last_updated_by = updated_by
        return self

    def has_capability(self, capability: TeamRoleCapability) -> bool:
        """Check if this role has a specific capability."""
        return capability.value in self.capabilities

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for DynamoDB."""
        return {
            "teamRoleId": self.team_role_id,
            "name": self.name,
            "displayName": self.display_name,
            "description": self.description,
            "organisationId": self.organisation_id,
            "capabilities": self.capabilities,
            "isDefault": self.is_default,
            "sortOrder": self.sort_order,
            "active": self.active,
            "dateCreated": self.date_created,
            "dateLastUpdated": self.date_last_updated,
            "createdBy": self.created_by,
            "lastUpdatedBy": self.last_updated_by
        }

    def to_response(self, base_url: str = "") -> Dict[str, Any]:
        """Convert to API response format with HATEOAS links."""
        response = self.to_dict()
        response["id"] = self.team_role_id
        response["_links"] = {
            "self": {"href": f"{base_url}/v1/organisations/{self.organisation_id}/team-roles/{self.team_role_id}"},
            "organisation": {"href": f"{base_url}/v1/organisations/{self.organisation_id}"}
        }
        return response

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "TeamRoleDefinition":
        """Create TeamRoleDefinition from dictionary."""
        return cls(
            team_role_id=data.get("teamRoleId", ""),
            name=data.get("name", ""),
            display_name=data.get("displayName", ""),
            organisation_id=data.get("organisationId", ""),
            capabilities=data.get("capabilities", []),
            description=data.get("description", ""),
            is_default=data.get("isDefault", False),
            sort_order=data.get("sortOrder", 100),
            active=data.get("active", True),
            date_created=data.get("dateCreated", ""),
            date_last_updated=data.get("dateLastUpdated", ""),
            created_by=data.get("createdBy", ""),
            last_updated_by=data.get("lastUpdatedBy", "")
        )
```

### 2.4 src/models/team_member.py

```python
"""
Team Member Model - Represents a user's membership in a team.
"""
from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional, Dict, Any
import uuid


@dataclass
class TeamMember:
    """
    Represents a user's membership in a team.

    Contains denormalized user info for efficient queries and
    references the team role for capability checks.
    """
    organisation_id: str
    team_id: str
    user_id: str
    team_role_id: str
    user_email: str = ""
    user_first_name: str = ""
    user_last_name: str = ""
    team_role_name: str = ""
    joined_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    added_by: str = ""
    active: bool = True
    date_created: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    date_last_updated: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    last_updated_by: str = ""

    @classmethod
    def create(
        cls,
        organisation_id: str,
        team_id: str,
        user_id: str,
        team_role_id: str,
        added_by: str,
        user_email: str = "",
        user_first_name: str = "",
        user_last_name: str = "",
        team_role_name: str = ""
    ) -> "TeamMember":
        """Factory method to create a new TeamMember."""
        now = datetime.utcnow().isoformat()
        return cls(
            organisation_id=organisation_id,
            team_id=team_id,
            user_id=user_id,
            team_role_id=team_role_id,
            user_email=user_email,
            user_first_name=user_first_name,
            user_last_name=user_last_name,
            team_role_name=team_role_name,
            joined_at=now,
            added_by=added_by,
            active=True,
            date_created=now,
            date_last_updated=now,
            last_updated_by=added_by
        )

    def update(
        self,
        updated_by: str,
        team_role_id: Optional[str] = None,
        team_role_name: Optional[str] = None,
        active: Optional[bool] = None
    ) -> "TeamMember":
        """Update member attributes and return self."""
        if team_role_id is not None:
            self.team_role_id = team_role_id
        if team_role_name is not None:
            self.team_role_name = team_role_name
        if active is not None:
            self.active = active
        self.date_last_updated = datetime.utcnow().isoformat()
        self.last_updated_by = updated_by
        return self

    @property
    def full_name(self) -> str:
        """Get user's full name."""
        return f"{self.user_first_name} {self.user_last_name}".strip()

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for DynamoDB."""
        return {
            "organisationId": self.organisation_id,
            "teamId": self.team_id,
            "userId": self.user_id,
            "userEmail": self.user_email,
            "userFirstName": self.user_first_name,
            "userLastName": self.user_last_name,
            "teamRoleId": self.team_role_id,
            "teamRoleName": self.team_role_name,
            "joinedAt": self.joined_at,
            "addedBy": self.added_by,
            "active": self.active,
            "dateCreated": self.date_created,
            "dateLastUpdated": self.date_last_updated,
            "lastUpdatedBy": self.last_updated_by
        }

    def to_response(self, base_url: str = "") -> Dict[str, Any]:
        """Convert to API response format with HATEOAS links."""
        response = self.to_dict()
        response["firstName"] = self.user_first_name
        response["lastName"] = self.user_last_name
        response["email"] = self.user_email
        response["_links"] = {
            "self": {"href": f"{base_url}/v1/organisations/{self.organisation_id}/teams/{self.team_id}/members/{self.user_id}"},
            "team": {"href": f"{base_url}/v1/organisations/{self.organisation_id}/teams/{self.team_id}"},
            "user": {"href": f"{base_url}/v1/organisations/{self.organisation_id}/users/{self.user_id}"},
            "role": {"href": f"{base_url}/v1/organisations/{self.organisation_id}/team-roles/{self.team_role_id}"}
        }
        return response

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "TeamMember":
        """Create TeamMember from dictionary."""
        return cls(
            organisation_id=data.get("organisationId", ""),
            team_id=data.get("teamId", ""),
            user_id=data.get("userId", ""),
            team_role_id=data.get("teamRoleId", ""),
            user_email=data.get("userEmail", ""),
            user_first_name=data.get("userFirstName", ""),
            user_last_name=data.get("userLastName", ""),
            team_role_name=data.get("teamRoleName", ""),
            joined_at=data.get("joinedAt", ""),
            added_by=data.get("addedBy", ""),
            active=data.get("active", True),
            date_created=data.get("dateCreated", ""),
            date_last_updated=data.get("dateLastUpdated", ""),
            last_updated_by=data.get("lastUpdatedBy", "")
        )


@dataclass
class TeamMembership:
    """
    Lightweight representation of a user's team membership.
    Used for getUserTeams response.
    """
    team_id: str
    team_name: str
    team_role_id: str
    team_role_name: str
    joined_at: str
    is_primary: bool = False
    site_count: int = 0

    def to_response(self, base_url: str = "", org_id: str = "") -> Dict[str, Any]:
        """Convert to API response format."""
        return {
            "teamId": self.team_id,
            "teamName": self.team_name,
            "teamRoleId": self.team_role_id,
            "teamRoleName": self.team_role_name,
            "joinedAt": self.joined_at,
            "isPrimary": self.is_primary,
            "siteCount": self.site_count,
            "_links": {
                "team": {"href": f"{base_url}/v1/organisations/{org_id}/teams/{self.team_id}"},
                "role": {"href": f"{base_url}/v1/organisations/{org_id}/team-roles/{self.team_role_id}"}
            }
        }
```

### 2.5 src/models/requests.py

```python
"""
Request Models - Data transfer objects for API requests.
"""
from dataclasses import dataclass
from typing import List, Optional


@dataclass
class CreateTeamRequest:
    """Request DTO for creating a team."""
    name: str
    description: str = ""
    division_id: Optional[str] = None
    group_id: Optional[str] = None

    @classmethod
    def from_dict(cls, data: dict) -> "CreateTeamRequest":
        return cls(
            name=data.get("name", ""),
            description=data.get("description", ""),
            division_id=data.get("divisionId"),
            group_id=data.get("groupId")
        )

    def validate(self) -> List[str]:
        """Validate request and return list of errors."""
        errors = []
        if not self.name or len(self.name) < 2:
            errors.append("Name must be at least 2 characters")
        if len(self.name) > 100:
            errors.append("Name must not exceed 100 characters")
        if self.description and len(self.description) > 500:
            errors.append("Description must not exceed 500 characters")
        return errors


@dataclass
class UpdateTeamRequest:
    """Request DTO for updating a team."""
    name: Optional[str] = None
    description: Optional[str] = None
    division_id: Optional[str] = None
    group_id: Optional[str] = None
    active: Optional[bool] = None

    @classmethod
    def from_dict(cls, data: dict) -> "UpdateTeamRequest":
        return cls(
            name=data.get("name"),
            description=data.get("description"),
            division_id=data.get("divisionId"),
            group_id=data.get("groupId"),
            active=data.get("active")
        )

    def validate(self) -> List[str]:
        """Validate request and return list of errors."""
        errors = []
        if self.name is not None:
            if len(self.name) < 2:
                errors.append("Name must be at least 2 characters")
            if len(self.name) > 100:
                errors.append("Name must not exceed 100 characters")
        if self.description is not None and len(self.description) > 500:
            errors.append("Description must not exceed 500 characters")
        return errors


@dataclass
class CreateTeamRoleRequest:
    """Request DTO for creating a team role."""
    name: str
    display_name: str
    capabilities: List[str]
    description: str = ""
    sort_order: int = 100

    @classmethod
    def from_dict(cls, data: dict) -> "CreateTeamRoleRequest":
        return cls(
            name=data.get("name", ""),
            display_name=data.get("displayName", ""),
            capabilities=data.get("capabilities", []),
            description=data.get("description", ""),
            sort_order=data.get("sortOrder", 100)
        )

    def validate(self) -> List[str]:
        """Validate request and return list of errors."""
        import re
        errors = []
        if not self.name or len(self.name) < 2:
            errors.append("Name must be at least 2 characters")
        if len(self.name) > 50:
            errors.append("Name must not exceed 50 characters")
        if not re.match(r'^[A-Z][A-Z0-9_]*$', self.name.upper()):
            errors.append("Name must match pattern: ^[A-Z][A-Z0-9_]*$")
        if not self.display_name or len(self.display_name) < 2:
            errors.append("Display name must be at least 2 characters")
        if len(self.display_name) > 100:
            errors.append("Display name must not exceed 100 characters")
        if not self.capabilities:
            errors.append("At least one capability is required")
        if self.description and len(self.description) > 500:
            errors.append("Description must not exceed 500 characters")
        if self.sort_order < 1 or self.sort_order > 999:
            errors.append("Sort order must be between 1 and 999")
        return errors


@dataclass
class UpdateTeamRoleRequest:
    """Request DTO for updating a team role."""
    display_name: Optional[str] = None
    description: Optional[str] = None
    capabilities: Optional[List[str]] = None
    sort_order: Optional[int] = None
    active: Optional[bool] = None

    @classmethod
    def from_dict(cls, data: dict) -> "UpdateTeamRoleRequest":
        return cls(
            display_name=data.get("displayName"),
            description=data.get("description"),
            capabilities=data.get("capabilities"),
            sort_order=data.get("sortOrder"),
            active=data.get("active")
        )

    def validate(self) -> List[str]:
        """Validate request and return list of errors."""
        errors = []
        if self.display_name is not None:
            if len(self.display_name) < 2:
                errors.append("Display name must be at least 2 characters")
            if len(self.display_name) > 100:
                errors.append("Display name must not exceed 100 characters")
        if self.capabilities is not None and not self.capabilities:
            errors.append("At least one capability is required if capabilities provided")
        if self.description is not None and len(self.description) > 500:
            errors.append("Description must not exceed 500 characters")
        if self.sort_order is not None and (self.sort_order < 1 or self.sort_order > 999):
            errors.append("Sort order must be between 1 and 999")
        return errors


@dataclass
class AddMemberRequest:
    """Request DTO for adding a member to a team."""
    user_id: str
    team_role_id: str

    @classmethod
    def from_dict(cls, data: dict) -> "AddMemberRequest":
        return cls(
            user_id=data.get("userId", ""),
            team_role_id=data.get("teamRoleId", "")
        )

    def validate(self) -> List[str]:
        """Validate request and return list of errors."""
        errors = []
        if not self.user_id:
            errors.append("User ID is required")
        if not self.team_role_id:
            errors.append("Team role ID is required")
        return errors


@dataclass
class UpdateMemberRequest:
    """Request DTO for updating a team member."""
    team_role_id: Optional[str] = None
    active: Optional[bool] = None

    @classmethod
    def from_dict(cls, data: dict) -> "UpdateMemberRequest":
        return cls(
            team_role_id=data.get("teamRoleId"),
            active=data.get("active")
        )

    def validate(self) -> List[str]:
        """Validate request and return list of errors."""
        errors = []
        # At least one field should be provided
        if self.team_role_id is None and self.active is None:
            errors.append("At least one field (teamRoleId or active) must be provided")
        return errors
```

---

## 3. Exceptions

### 3.1 src/exceptions/team_exceptions.py

```python
"""
Team Service Exceptions - Custom exception classes for error handling.
"""


class TeamServiceException(Exception):
    """Base exception for Team Service."""

    def __init__(self, message: str, status_code: int = 500):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)


class TeamNotFoundException(TeamServiceException):
    """Raised when team not found."""

    def __init__(self, team_id: str):
        self.team_id = team_id
        super().__init__(
            message=f"Team not found: {team_id}",
            status_code=404
        )


class TeamRoleNotFoundException(TeamServiceException):
    """Raised when team role not found."""

    def __init__(self, role_id: str):
        self.role_id = role_id
        super().__init__(
            message=f"Team role not found: {role_id}",
            status_code=404
        )


class MemberNotFoundException(TeamServiceException):
    """Raised when member not found in team."""

    def __init__(self, user_id: str, team_id: str):
        self.user_id = user_id
        self.team_id = team_id
        super().__init__(
            message=f"Member {user_id} not found in team {team_id}",
            status_code=404
        )


class DuplicateTeamNameException(TeamServiceException):
    """Raised when team name already exists in org."""

    def __init__(self, name: str):
        self.name = name
        super().__init__(
            message=f"Team name already exists: {name}",
            status_code=409
        )


class DuplicateRoleNameException(TeamServiceException):
    """Raised when role name already exists in org."""

    def __init__(self, name: str):
        self.name = name
        super().__init__(
            message=f"Role name already exists: {name}",
            status_code=409
        )


class UserAlreadyMemberException(TeamServiceException):
    """Raised when user is already a team member."""

    def __init__(self, user_id: str, team_id: str):
        self.user_id = user_id
        self.team_id = team_id
        super().__init__(
            message=f"User {user_id} is already a member of team {team_id}",
            status_code=409
        )


class UserNotInOrgException(TeamServiceException):
    """Raised when user is not a member of the organisation."""

    def __init__(self, user_id: str, org_id: str):
        self.user_id = user_id
        self.org_id = org_id
        super().__init__(
            message=f"User {user_id} is not a member of organisation {org_id}",
            status_code=400
        )


class InsufficientPermissionException(TeamServiceException):
    """Raised when user lacks required permission."""

    def __init__(self, message: str = "Insufficient permissions"):
        super().__init__(
            message=message,
            status_code=403
        )


class CannotRemoveLastLeadException(TeamServiceException):
    """Raised when trying to remove the last team lead."""

    def __init__(self, team_id: str):
        self.team_id = team_id
        super().__init__(
            message=f"Cannot remove the last team lead from team {team_id}",
            status_code=400
        )


class RoleInUseException(TeamServiceException):
    """Raised when trying to delete a role that has members."""

    def __init__(self, role_id: str, member_count: int):
        self.role_id = role_id
        self.member_count = member_count
        super().__init__(
            message=f"Cannot deactivate role {role_id}: {member_count} members are using it",
            status_code=400
        )


class ValidationException(TeamServiceException):
    """Raised when request validation fails."""

    def __init__(self, errors: list):
        self.errors = errors
        super().__init__(
            message=f"Validation failed: {', '.join(errors)}",
            status_code=400
        )


class InvalidCapabilityException(TeamServiceException):
    """Raised when invalid capability is provided."""

    def __init__(self, invalid_capabilities: list):
        self.invalid_capabilities = invalid_capabilities
        super().__init__(
            message=f"Invalid capabilities: {', '.join(invalid_capabilities)}",
            status_code=400
        )
```

---

## 4. Repositories

### 4.1 src/repositories/team_repository.py

```python
"""
Team Repository - Data access layer for Team entities.
"""
import os
from typing import Optional, List, Dict, Any, Tuple
import boto3
from boto3.dynamodb.conditions import Key, Attr

from ..models.team import Team


class TeamRepository:
    """
    Repository for Team entity CRUD operations.

    Uses DynamoDB single-table design with the following access patterns:
    - Get team by ID: PK=ORG#{orgId}, SK=TEAM#{teamId}
    - List org teams: PK=ORG#{orgId}, SK begins_with TEAM#
    - Find by name: GSI1PK=ORG#{orgId}#ACTIVE#{active}, GSI1SK=TEAM#{name}
    """

    def __init__(self, table_name: str = None, dynamodb_resource=None):
        """Initialize repository with table reference."""
        self.table_name = table_name or os.environ.get(
            "DYNAMODB_TABLE_NAME",
            "bbws-aipagebuilder-dev-ddb-access-management"
        )
        self.dynamodb = dynamodb_resource or boto3.resource("dynamodb")
        self.table = self.dynamodb.Table(self.table_name)

    def _build_pk(self, org_id: str) -> str:
        """Build partition key for team."""
        return f"ORG#{org_id}"

    def _build_sk(self, team_id: str) -> str:
        """Build sort key for team."""
        return f"TEAM#{team_id}"

    def _build_gsi1_pk(self, org_id: str, active: bool) -> str:
        """Build GSI1 partition key."""
        return f"ORG#{org_id}#ACTIVE#{str(active).lower()}"

    def _build_gsi1_sk(self, name: str) -> str:
        """Build GSI1 sort key."""
        return f"TEAM#{name}"

    def _build_gsi2_pk(self, org_id: str, division_id: str) -> str:
        """Build GSI2 partition key for division filtering."""
        return f"ORG#{org_id}#DIV#{division_id or 'NONE'}"

    def _to_item(self, team: Team) -> Dict[str, Any]:
        """Convert Team to DynamoDB item."""
        item = team.to_dict()
        item["PK"] = self._build_pk(team.organisation_id)
        item["SK"] = self._build_sk(team.team_id)
        item["GSI1PK"] = self._build_gsi1_pk(team.organisation_id, team.active)
        item["GSI1SK"] = self._build_gsi1_sk(team.name)
        item["GSI2PK"] = self._build_gsi2_pk(team.organisation_id, team.division_id)
        item["GSI2SK"] = self._build_sk(team.team_id)
        item["entityType"] = "TEAM"
        return item

    def _to_entity(self, item: Dict[str, Any]) -> Team:
        """Convert DynamoDB item to Team."""
        return Team.from_dict(item)

    def save(self, team: Team) -> Team:
        """Save a new team to the database."""
        item = self._to_item(team)
        self.table.put_item(Item=item)
        return team

    def find_by_id(self, org_id: str, team_id: str) -> Optional[Team]:
        """Find team by ID."""
        response = self.table.get_item(
            Key={
                "PK": self._build_pk(org_id),
                "SK": self._build_sk(team_id)
            }
        )
        item = response.get("Item")
        return self._to_entity(item) if item else None

    def find_by_org_id(
        self,
        org_id: str,
        include_inactive: bool = False,
        division_id: Optional[str] = None,
        page_size: int = 50,
        start_at: Optional[str] = None
    ) -> Tuple[List[Team], Optional[str], int]:
        """
        List teams for an organisation.

        Returns: (teams, next_token, total_count)
        """
        query_params = {
            "KeyConditionExpression": Key("PK").eq(self._build_pk(org_id)) &
                                      Key("SK").begins_with("TEAM#"),
            "Limit": page_size
        }

        if not include_inactive:
            query_params["FilterExpression"] = Attr("active").eq(True)

        if start_at:
            query_params["ExclusiveStartKey"] = {
                "PK": self._build_pk(org_id),
                "SK": start_at
            }

        response = self.table.query(**query_params)

        teams = [self._to_entity(item) for item in response.get("Items", [])]

        # Filter by division if specified
        if division_id:
            teams = [t for t in teams if t.division_id == division_id]

        next_token = None
        if response.get("LastEvaluatedKey"):
            next_token = response["LastEvaluatedKey"]["SK"]

        return teams, next_token, len(teams)

    def find_by_name(self, org_id: str, name: str) -> Optional[Team]:
        """Find team by name within an organisation."""
        response = self.table.query(
            IndexName="GSI1",
            KeyConditionExpression=Key("GSI1PK").eq(self._build_gsi1_pk(org_id, True)) &
                                   Key("GSI1SK").eq(self._build_gsi1_sk(name))
        )
        items = response.get("Items", [])
        return self._to_entity(items[0]) if items else None

    def update(self, team: Team) -> Team:
        """Update an existing team."""
        item = self._to_item(team)
        self.table.put_item(Item=item)
        return team

    def delete(self, org_id: str, team_id: str) -> None:
        """Delete a team (hard delete - use update for soft delete)."""
        self.table.delete_item(
            Key={
                "PK": self._build_pk(org_id),
                "SK": self._build_sk(team_id)
            }
        )
```

### 4.2 src/repositories/team_role_repository.py

```python
"""
Team Role Repository - Data access layer for TeamRoleDefinition entities.
"""
import os
from typing import Optional, List, Dict, Any, Tuple
import boto3
from boto3.dynamodb.conditions import Key, Attr

from ..models.team_role import TeamRoleDefinition


class TeamRoleRepository:
    """
    Repository for TeamRoleDefinition entity CRUD operations.

    Uses DynamoDB single-table design with the following access patterns:
    - Get role by ID: PK=ORG#{orgId}, SK=TEAMROLE#{roleId}
    - List org roles: PK=ORG#{orgId}, SK begins_with TEAMROLE#
    - Find by name: GSI1PK=ORG#{orgId}#ACTIVE#{active}, GSI1SK=TEAMROLE#{name}
    """

    def __init__(self, table_name: str = None, dynamodb_resource=None):
        """Initialize repository with table reference."""
        self.table_name = table_name or os.environ.get(
            "DYNAMODB_TABLE_NAME",
            "bbws-aipagebuilder-dev-ddb-access-management"
        )
        self.dynamodb = dynamodb_resource or boto3.resource("dynamodb")
        self.table = self.dynamodb.Table(self.table_name)

    def _build_pk(self, org_id: str) -> str:
        """Build partition key for team role."""
        return f"ORG#{org_id}"

    def _build_sk(self, role_id: str) -> str:
        """Build sort key for team role."""
        return f"TEAMROLE#{role_id}"

    def _build_gsi1_pk(self, org_id: str, active: bool) -> str:
        """Build GSI1 partition key."""
        return f"ORG#{org_id}#ACTIVE#{str(active).lower()}"

    def _build_gsi1_sk(self, name: str) -> str:
        """Build GSI1 sort key."""
        return f"TEAMROLE#{name}"

    def _to_item(self, role: TeamRoleDefinition) -> Dict[str, Any]:
        """Convert TeamRoleDefinition to DynamoDB item."""
        item = role.to_dict()
        item["PK"] = self._build_pk(role.organisation_id)
        item["SK"] = self._build_sk(role.team_role_id)
        item["GSI1PK"] = self._build_gsi1_pk(role.organisation_id, role.active)
        item["GSI1SK"] = self._build_gsi1_sk(role.name)
        item["entityType"] = "TEAMROLE"
        return item

    def _to_entity(self, item: Dict[str, Any]) -> TeamRoleDefinition:
        """Convert DynamoDB item to TeamRoleDefinition."""
        return TeamRoleDefinition.from_dict(item)

    def save(self, role: TeamRoleDefinition) -> TeamRoleDefinition:
        """Save a new team role to the database."""
        item = self._to_item(role)
        self.table.put_item(Item=item)
        return role

    def find_by_id(self, org_id: str, role_id: str) -> Optional[TeamRoleDefinition]:
        """Find team role by ID."""
        response = self.table.get_item(
            Key={
                "PK": self._build_pk(org_id),
                "SK": self._build_sk(role_id)
            }
        )
        item = response.get("Item")
        return self._to_entity(item) if item else None

    def find_by_org_id(
        self,
        org_id: str,
        include_inactive: bool = False,
        defaults_only: bool = False,
        page_size: int = 50,
        start_at: Optional[str] = None
    ) -> Tuple[List[TeamRoleDefinition], Optional[str], int]:
        """
        List team roles for an organisation.

        Returns: (roles, next_token, total_count)
        """
        query_params = {
            "KeyConditionExpression": Key("PK").eq(self._build_pk(org_id)) &
                                      Key("SK").begins_with("TEAMROLE#"),
            "Limit": page_size
        }

        filter_conditions = []
        if not include_inactive:
            filter_conditions.append(Attr("active").eq(True))
        if defaults_only:
            filter_conditions.append(Attr("isDefault").eq(True))

        if filter_conditions:
            filter_expr = filter_conditions[0]
            for condition in filter_conditions[1:]:
                filter_expr = filter_expr & condition
            query_params["FilterExpression"] = filter_expr

        if start_at:
            query_params["ExclusiveStartKey"] = {
                "PK": self._build_pk(org_id),
                "SK": start_at
            }

        response = self.table.query(**query_params)

        roles = [self._to_entity(item) for item in response.get("Items", [])]

        # Sort by sort_order
        roles.sort(key=lambda r: r.sort_order)

        next_token = None
        if response.get("LastEvaluatedKey"):
            next_token = response["LastEvaluatedKey"]["SK"]

        return roles, next_token, len(roles)

    def find_by_name(self, org_id: str, name: str) -> Optional[TeamRoleDefinition]:
        """Find team role by name within an organisation."""
        response = self.table.query(
            IndexName="GSI1",
            KeyConditionExpression=Key("GSI1PK").eq(self._build_gsi1_pk(org_id, True)) &
                                   Key("GSI1SK").eq(self._build_gsi1_sk(name))
        )
        items = response.get("Items", [])
        return self._to_entity(items[0]) if items else None

    def update(self, role: TeamRoleDefinition) -> TeamRoleDefinition:
        """Update an existing team role."""
        item = self._to_item(role)
        self.table.put_item(Item=item)
        return role

    def count_members_with_role(self, org_id: str, role_id: str) -> int:
        """Count how many active members have this role assigned."""
        # Query GSI2 for members with this role
        response = self.table.query(
            IndexName="GSI2",
            KeyConditionExpression=Key("GSI2PK").begins_with(f"ORG#{org_id}") &
                                   Key("GSI2SK").begins_with("MEMBER#"),
            FilterExpression=Attr("teamRoleId").eq(role_id) & Attr("active").eq(True),
            Select="COUNT"
        )
        return response.get("Count", 0)

    def delete(self, org_id: str, role_id: str) -> None:
        """Delete a team role (hard delete - use update for soft delete)."""
        self.table.delete_item(
            Key={
                "PK": self._build_pk(org_id),
                "SK": self._build_sk(role_id)
            }
        )
```

### 4.3 src/repositories/team_member_repository.py

```python
"""
Team Member Repository - Data access layer for TeamMember entities.
"""
import os
from typing import Optional, List, Dict, Any, Tuple
import boto3
from boto3.dynamodb.conditions import Key, Attr

from ..models.team_member import TeamMember


class TeamMemberRepository:
    """
    Repository for TeamMember entity CRUD operations.

    Uses DynamoDB single-table design with the following access patterns:
    - Get member: PK=ORG#{orgId}#TEAM#{teamId}, SK=MEMBER#{userId}
    - List team members: PK=ORG#{orgId}#TEAM#{teamId}, SK begins_with MEMBER#
    - Get user's teams: GSI1PK=USER#{userId}, GSI1SK begins_with ORG#{orgId}#TEAM#
    - List by role: GSI2PK=ORG#{orgId}#TEAM#{teamId}#ROLE#{roleId}
    """

    def __init__(self, table_name: str = None, dynamodb_resource=None):
        """Initialize repository with table reference."""
        self.table_name = table_name or os.environ.get(
            "DYNAMODB_TABLE_NAME",
            "bbws-aipagebuilder-dev-ddb-access-management"
        )
        self.dynamodb = dynamodb_resource or boto3.resource("dynamodb")
        self.table = self.dynamodb.Table(self.table_name)

    def _build_pk(self, org_id: str, team_id: str) -> str:
        """Build partition key for team member."""
        return f"ORG#{org_id}#TEAM#{team_id}"

    def _build_sk(self, user_id: str) -> str:
        """Build sort key for team member."""
        return f"MEMBER#{user_id}"

    def _build_gsi1_pk(self, user_id: str) -> str:
        """Build GSI1 partition key for user's teams lookup."""
        return f"USER#{user_id}"

    def _build_gsi1_sk(self, org_id: str, team_id: str) -> str:
        """Build GSI1 sort key."""
        return f"ORG#{org_id}#TEAM#{team_id}"

    def _build_gsi2_pk(self, org_id: str, team_id: str, role_id: str) -> str:
        """Build GSI2 partition key for role filtering."""
        return f"ORG#{org_id}#TEAM#{team_id}#ROLE#{role_id}"

    def _to_item(self, member: TeamMember) -> Dict[str, Any]:
        """Convert TeamMember to DynamoDB item."""
        item = member.to_dict()
        item["PK"] = self._build_pk(member.organisation_id, member.team_id)
        item["SK"] = self._build_sk(member.user_id)
        item["GSI1PK"] = self._build_gsi1_pk(member.user_id)
        item["GSI1SK"] = self._build_gsi1_sk(member.organisation_id, member.team_id)
        item["GSI2PK"] = self._build_gsi2_pk(
            member.organisation_id, member.team_id, member.team_role_id
        )
        item["GSI2SK"] = self._build_sk(member.user_id)
        item["entityType"] = "TEAMMEMBER"
        return item

    def _to_entity(self, item: Dict[str, Any]) -> TeamMember:
        """Convert DynamoDB item to TeamMember."""
        return TeamMember.from_dict(item)

    def save(self, member: TeamMember) -> TeamMember:
        """Save a new team member to the database."""
        item = self._to_item(member)
        self.table.put_item(Item=item)
        return member

    def find_member(
        self, org_id: str, team_id: str, user_id: str
    ) -> Optional[TeamMember]:
        """Find a specific team member."""
        response = self.table.get_item(
            Key={
                "PK": self._build_pk(org_id, team_id),
                "SK": self._build_sk(user_id)
            }
        )
        item = response.get("Item")
        return self._to_entity(item) if item else None

    def find_by_team_id(
        self,
        org_id: str,
        team_id: str,
        include_inactive: bool = False,
        team_role_id: Optional[str] = None,
        page_size: int = 50,
        start_at: Optional[str] = None
    ) -> Tuple[List[TeamMember], Optional[str], int]:
        """
        List members for a team.

        Returns: (members, next_token, total_count)
        """
        query_params = {
            "KeyConditionExpression": Key("PK").eq(self._build_pk(org_id, team_id)) &
                                      Key("SK").begins_with("MEMBER#"),
            "Limit": page_size
        }

        filter_conditions = []
        if not include_inactive:
            filter_conditions.append(Attr("active").eq(True))
        if team_role_id:
            filter_conditions.append(Attr("teamRoleId").eq(team_role_id))

        if filter_conditions:
            filter_expr = filter_conditions[0]
            for condition in filter_conditions[1:]:
                filter_expr = filter_expr & condition
            query_params["FilterExpression"] = filter_expr

        if start_at:
            query_params["ExclusiveStartKey"] = {
                "PK": self._build_pk(org_id, team_id),
                "SK": start_at
            }

        response = self.table.query(**query_params)

        members = [self._to_entity(item) for item in response.get("Items", [])]

        next_token = None
        if response.get("LastEvaluatedKey"):
            next_token = response["LastEvaluatedKey"]["SK"]

        return members, next_token, len(members)

    def find_by_user_id(
        self, org_id: str, user_id: str
    ) -> List[TeamMember]:
        """Find all team memberships for a user in an organisation."""
        response = self.table.query(
            IndexName="GSI1",
            KeyConditionExpression=Key("GSI1PK").eq(self._build_gsi1_pk(user_id)) &
                                   Key("GSI1SK").begins_with(f"ORG#{org_id}#TEAM#"),
            FilterExpression=Attr("active").eq(True)
        )
        return [self._to_entity(item) for item in response.get("Items", [])]

    def count_members_with_role_in_team(
        self, org_id: str, team_id: str, role_id: str
    ) -> int:
        """Count active members with a specific role in a team."""
        response = self.table.query(
            IndexName="GSI2",
            KeyConditionExpression=Key("GSI2PK").eq(
                self._build_gsi2_pk(org_id, team_id, role_id)
            ),
            FilterExpression=Attr("active").eq(True),
            Select="COUNT"
        )
        return response.get("Count", 0)

    def update(self, member: TeamMember) -> TeamMember:
        """Update an existing team member."""
        item = self._to_item(member)
        self.table.put_item(Item=item)
        return member

    def delete(self, org_id: str, team_id: str, user_id: str) -> None:
        """Delete a team member (hard delete - use update for soft delete)."""
        self.table.delete_item(
            Key={
                "PK": self._build_pk(org_id, team_id),
                "SK": self._build_sk(user_id)
            }
        )
```

---

## 5. Services

### 5.1 src/utils/default_roles.py

```python
"""
Default Team Roles - Configuration for default roles seeded on org creation.
"""
from typing import List, Dict, Any

from ..models.capabilities import TeamRoleCapability


DEFAULT_TEAM_ROLES: List[Dict[str, Any]] = [
    {
        "name": "TEAM_LEAD",
        "display_name": "Team Lead",
        "description": "Team lead with full team management capabilities",
        "capabilities": [
            TeamRoleCapability.CAN_MANAGE_MEMBERS.value,
            TeamRoleCapability.CAN_UPDATE_TEAM.value,
            TeamRoleCapability.CAN_VIEW_MEMBERS.value,
            TeamRoleCapability.CAN_VIEW_SITES.value,
            TeamRoleCapability.CAN_EDIT_SITES.value,
            TeamRoleCapability.CAN_DELETE_SITES.value,
        ],
        "is_default": True,
        "sort_order": 1,
    },
    {
        "name": "SENIOR_MEMBER",
        "display_name": "Senior Member",
        "description": "Senior team member with edit capabilities",
        "capabilities": [
            TeamRoleCapability.CAN_VIEW_MEMBERS.value,
            TeamRoleCapability.CAN_VIEW_SITES.value,
            TeamRoleCapability.CAN_EDIT_SITES.value,
        ],
        "is_default": True,
        "sort_order": 2,
    },
    {
        "name": "MEMBER",
        "display_name": "Member",
        "description": "Standard team member with view capabilities",
        "capabilities": [
            TeamRoleCapability.CAN_VIEW_MEMBERS.value,
            TeamRoleCapability.CAN_VIEW_SITES.value,
        ],
        "is_default": True,
        "sort_order": 3,
    },
    {
        "name": "VIEWER",
        "display_name": "Viewer",
        "description": "Read-only team member",
        "capabilities": [
            TeamRoleCapability.CAN_VIEW_MEMBERS.value,
        ],
        "is_default": True,
        "sort_order": 4,
    },
]


def get_default_roles() -> List[Dict[str, Any]]:
    """Return the default team roles configuration."""
    return DEFAULT_TEAM_ROLES.copy()


def get_team_lead_role_name() -> str:
    """Return the name of the team lead role."""
    return "TEAM_LEAD"
```

### 5.2 src/services/team_service.py

```python
"""
Team Service - Business logic for team operations.
"""
from typing import Optional, List, Tuple
from aws_lambda_powertools import Logger

from ..models.team import Team
from ..models.requests import CreateTeamRequest, UpdateTeamRequest
from ..repositories.team_repository import TeamRepository
from ..exceptions.team_exceptions import (
    TeamNotFoundException,
    DuplicateTeamNameException,
    ValidationException
)


logger = Logger(service="TeamService")


class TeamService:
    """
    Service class for team business logic.

    Handles team CRUD operations with validation and audit logging.
    """

    def __init__(self, repository: TeamRepository = None):
        """Initialize service with repository."""
        self.repository = repository or TeamRepository()

    def create_team(
        self,
        org_id: str,
        request: CreateTeamRequest,
        created_by: str
    ) -> Team:
        """
        Create a new team.

        Args:
            org_id: Organisation ID
            request: Create team request
            created_by: Email of creator

        Returns:
            Created Team

        Raises:
            ValidationException: If request is invalid
            DuplicateTeamNameException: If team name exists
        """
        # Validate request
        errors = request.validate()
        if errors:
            raise ValidationException(errors)

        # Check for duplicate name
        existing = self.repository.find_by_name(org_id, request.name)
        if existing:
            raise DuplicateTeamNameException(request.name)

        # Create team
        team = Team.create(
            name=request.name,
            organisation_id=org_id,
            created_by=created_by,
            description=request.description,
            division_id=request.division_id,
            group_id=request.group_id
        )

        # Save and return
        saved_team = self.repository.save(team)
        logger.info(
            "Team created",
            extra={"team_id": saved_team.team_id, "org_id": org_id}
        )

        return saved_team

    def list_teams(
        self,
        org_id: str,
        include_inactive: bool = False,
        division_id: Optional[str] = None,
        page_size: int = 50,
        start_at: Optional[str] = None
    ) -> Tuple[List[Team], Optional[str], int]:
        """
        List teams for an organisation.

        Returns: (teams, next_token, count)
        """
        return self.repository.find_by_org_id(
            org_id=org_id,
            include_inactive=include_inactive,
            division_id=division_id,
            page_size=page_size,
            start_at=start_at
        )

    def get_team(self, org_id: str, team_id: str) -> Team:
        """
        Get a team by ID.

        Raises:
            TeamNotFoundException: If team not found
        """
        team = self.repository.find_by_id(org_id, team_id)
        if not team:
            raise TeamNotFoundException(team_id)
        return team

    def update_team(
        self,
        org_id: str,
        team_id: str,
        request: UpdateTeamRequest,
        updated_by: str
    ) -> Team:
        """
        Update a team.

        Raises:
            TeamNotFoundException: If team not found
            ValidationException: If request is invalid
            DuplicateTeamNameException: If new name already exists
        """
        # Validate request
        errors = request.validate()
        if errors:
            raise ValidationException(errors)

        # Get existing team
        team = self.get_team(org_id, team_id)

        # Check for duplicate name if name is being changed
        if request.name and request.name != team.name:
            existing = self.repository.find_by_name(org_id, request.name)
            if existing and existing.team_id != team_id:
                raise DuplicateTeamNameException(request.name)

        # Update team
        team.update(
            updated_by=updated_by,
            name=request.name,
            description=request.description,
            division_id=request.division_id,
            group_id=request.group_id,
            active=request.active
        )

        # Save and return
        updated_team = self.repository.update(team)
        logger.info(
            "Team updated",
            extra={"team_id": team_id, "org_id": org_id}
        )

        return updated_team

    def deactivate_team(
        self,
        org_id: str,
        team_id: str,
        deactivated_by: str
    ) -> Team:
        """Soft delete a team by setting active=false."""
        team = self.get_team(org_id, team_id)
        team.update(updated_by=deactivated_by, active=False)
        return self.repository.update(team)

    def increment_member_count(self, org_id: str, team_id: str) -> None:
        """Increment the member count for a team."""
        team = self.get_team(org_id, team_id)
        team.increment_member_count()
        self.repository.update(team)

    def decrement_member_count(self, org_id: str, team_id: str) -> None:
        """Decrement the member count for a team."""
        team = self.get_team(org_id, team_id)
        team.decrement_member_count()
        self.repository.update(team)
```

### 5.3 src/services/team_role_service.py

```python
"""
Team Role Service - Business logic for team role operations.
"""
from typing import Optional, List, Tuple
from aws_lambda_powertools import Logger

from ..models.team_role import TeamRoleDefinition
from ..models.requests import CreateTeamRoleRequest, UpdateTeamRoleRequest
from ..repositories.team_role_repository import TeamRoleRepository
from ..repositories.team_member_repository import TeamMemberRepository
from ..utils.default_roles import get_default_roles
from ..exceptions.team_exceptions import (
    TeamRoleNotFoundException,
    DuplicateRoleNameException,
    RoleInUseException,
    ValidationException,
    InvalidCapabilityException
)
from ..models.capabilities import TeamRoleCapability


logger = Logger(service="TeamRoleService")


class TeamRoleService:
    """
    Service class for team role business logic.

    Handles team role CRUD operations with validation.
    """

    def __init__(
        self,
        repository: TeamRoleRepository = None,
        member_repository: TeamMemberRepository = None
    ):
        """Initialize service with repositories."""
        self.repository = repository or TeamRoleRepository()
        self.member_repository = member_repository or TeamMemberRepository()

    def create_role(
        self,
        org_id: str,
        request: CreateTeamRoleRequest,
        created_by: str
    ) -> TeamRoleDefinition:
        """
        Create a new team role.

        Raises:
            ValidationException: If request is invalid
            DuplicateRoleNameException: If role name exists
            InvalidCapabilityException: If capabilities are invalid
        """
        # Validate request
        errors = request.validate()
        if errors:
            raise ValidationException(errors)

        # Validate capabilities
        if not TeamRoleCapability.validate_capabilities(request.capabilities):
            invalid = TeamRoleCapability.get_invalid_capabilities(request.capabilities)
            raise InvalidCapabilityException(invalid)

        # Check for duplicate name
        normalized_name = request.name.upper().replace(" ", "_")
        existing = self.repository.find_by_name(org_id, normalized_name)
        if existing:
            raise DuplicateRoleNameException(request.name)

        # Create role
        role = TeamRoleDefinition.create(
            name=request.name,
            display_name=request.display_name,
            organisation_id=org_id,
            capabilities=request.capabilities,
            created_by=created_by,
            description=request.description,
            is_default=False,
            sort_order=request.sort_order
        )

        # Save and return
        saved_role = self.repository.save(role)
        logger.info(
            "Team role created",
            extra={"role_id": saved_role.team_role_id, "org_id": org_id}
        )

        return saved_role

    def list_roles(
        self,
        org_id: str,
        include_inactive: bool = False,
        defaults_only: bool = False,
        page_size: int = 50,
        start_at: Optional[str] = None
    ) -> Tuple[List[TeamRoleDefinition], Optional[str], int]:
        """List team roles for an organisation."""
        return self.repository.find_by_org_id(
            org_id=org_id,
            include_inactive=include_inactive,
            defaults_only=defaults_only,
            page_size=page_size,
            start_at=start_at
        )

    def get_role(self, org_id: str, role_id: str) -> TeamRoleDefinition:
        """
        Get a team role by ID.

        Raises:
            TeamRoleNotFoundException: If role not found
        """
        role = self.repository.find_by_id(org_id, role_id)
        if not role:
            raise TeamRoleNotFoundException(role_id)
        return role

    def update_role(
        self,
        org_id: str,
        role_id: str,
        request: UpdateTeamRoleRequest,
        updated_by: str
    ) -> TeamRoleDefinition:
        """
        Update a team role.

        Raises:
            TeamRoleNotFoundException: If role not found
            ValidationException: If request is invalid
            InvalidCapabilityException: If capabilities are invalid
        """
        # Validate request
        errors = request.validate()
        if errors:
            raise ValidationException(errors)

        # Validate capabilities if provided
        if request.capabilities:
            if not TeamRoleCapability.validate_capabilities(request.capabilities):
                invalid = TeamRoleCapability.get_invalid_capabilities(request.capabilities)
                raise InvalidCapabilityException(invalid)

        # Get existing role
        role = self.get_role(org_id, role_id)

        # Update role
        role.update(
            updated_by=updated_by,
            display_name=request.display_name,
            description=request.description,
            capabilities=request.capabilities,
            sort_order=request.sort_order,
            active=request.active
        )

        # Save and return
        updated_role = self.repository.update(role)
        logger.info(
            "Team role updated",
            extra={"role_id": role_id, "org_id": org_id}
        )

        return updated_role

    def deactivate_role(
        self,
        org_id: str,
        role_id: str,
        deactivated_by: str
    ) -> TeamRoleDefinition:
        """
        Deactivate a team role (soft delete).

        Raises:
            TeamRoleNotFoundException: If role not found
            RoleInUseException: If role has active members
        """
        role = self.get_role(org_id, role_id)

        # Check if role is in use
        member_count = self.repository.count_members_with_role(org_id, role_id)
        if member_count > 0:
            raise RoleInUseException(role_id, member_count)

        # Deactivate
        role.update(updated_by=deactivated_by, active=False)
        return self.repository.update(role)

    def seed_default_roles(
        self,
        org_id: str,
        created_by: str
    ) -> List[TeamRoleDefinition]:
        """
        Seed default team roles for a new organisation.

        Called when an organisation is created.
        """
        default_roles = get_default_roles()
        created_roles = []

        for role_config in default_roles:
            role = TeamRoleDefinition.create(
                name=role_config["name"],
                display_name=role_config["display_name"],
                organisation_id=org_id,
                capabilities=role_config["capabilities"],
                created_by=created_by,
                description=role_config["description"],
                is_default=role_config["is_default"],
                sort_order=role_config["sort_order"]
            )
            saved_role = self.repository.save(role)
            created_roles.append(saved_role)

        logger.info(
            "Default team roles seeded",
            extra={"org_id": org_id, "count": len(created_roles)}
        )

        return created_roles

    def get_role_by_name(
        self, org_id: str, name: str
    ) -> Optional[TeamRoleDefinition]:
        """Find a role by name."""
        return self.repository.find_by_name(org_id, name)
```

### 5.4 src/services/team_member_service.py

```python
"""
Team Member Service - Business logic for team member operations.
"""
from typing import Optional, List, Tuple
from aws_lambda_powertools import Logger

from ..models.team_member import TeamMember, TeamMembership
from ..models.requests import AddMemberRequest, UpdateMemberRequest
from ..repositories.team_member_repository import TeamMemberRepository
from ..services.team_service import TeamService
from ..services.team_role_service import TeamRoleService
from ..utils.default_roles import get_team_lead_role_name
from ..exceptions.team_exceptions import (
    MemberNotFoundException,
    UserAlreadyMemberException,
    TeamRoleNotFoundException,
    CannotRemoveLastLeadException,
    ValidationException
)


logger = Logger(service="TeamMemberService")


class TeamMemberService:
    """
    Service class for team member business logic.

    Handles adding, removing, and updating team members.
    """

    def __init__(
        self,
        repository: TeamMemberRepository = None,
        team_service: TeamService = None,
        role_service: TeamRoleService = None
    ):
        """Initialize service with dependencies."""
        self.repository = repository or TeamMemberRepository()
        self.team_service = team_service or TeamService()
        self.role_service = role_service or TeamRoleService()

    def add_member(
        self,
        org_id: str,
        team_id: str,
        request: AddMemberRequest,
        added_by: str,
        user_email: str = "",
        user_first_name: str = "",
        user_last_name: str = ""
    ) -> TeamMember:
        """
        Add a member to a team.

        Raises:
            ValidationException: If request is invalid
            UserAlreadyMemberException: If user is already a member
            TeamRoleNotFoundException: If role doesn't exist
        """
        # Validate request
        errors = request.validate()
        if errors:
            raise ValidationException(errors)

        # Check team exists
        self.team_service.get_team(org_id, team_id)

        # Check if already a member
        existing = self.repository.find_member(org_id, team_id, request.user_id)
        if existing and existing.active:
            raise UserAlreadyMemberException(request.user_id, team_id)

        # Check role exists
        role = self.role_service.get_role(org_id, request.team_role_id)

        # Create member
        member = TeamMember.create(
            organisation_id=org_id,
            team_id=team_id,
            user_id=request.user_id,
            team_role_id=request.team_role_id,
            added_by=added_by,
            user_email=user_email,
            user_first_name=user_first_name,
            user_last_name=user_last_name,
            team_role_name=role.display_name
        )

        # Save member
        saved_member = self.repository.save(member)

        # Update team member count
        self.team_service.increment_member_count(org_id, team_id)

        logger.info(
            "Member added to team",
            extra={
                "user_id": request.user_id,
                "team_id": team_id,
                "org_id": org_id
            }
        )

        return saved_member

    def list_members(
        self,
        org_id: str,
        team_id: str,
        include_inactive: bool = False,
        team_role_id: Optional[str] = None,
        page_size: int = 50,
        start_at: Optional[str] = None
    ) -> Tuple[List[TeamMember], Optional[str], int]:
        """List members of a team."""
        return self.repository.find_by_team_id(
            org_id=org_id,
            team_id=team_id,
            include_inactive=include_inactive,
            team_role_id=team_role_id,
            page_size=page_size,
            start_at=start_at
        )

    def get_member(
        self, org_id: str, team_id: str, user_id: str
    ) -> TeamMember:
        """
        Get a team member.

        Raises:
            MemberNotFoundException: If member not found
        """
        member = self.repository.find_member(org_id, team_id, user_id)
        if not member:
            raise MemberNotFoundException(user_id, team_id)
        return member

    def update_member(
        self,
        org_id: str,
        team_id: str,
        user_id: str,
        request: UpdateMemberRequest,
        updated_by: str
    ) -> TeamMember:
        """
        Update a team member.

        Raises:
            MemberNotFoundException: If member not found
            ValidationException: If request is invalid
            CannotRemoveLastLeadException: If removing last team lead
        """
        # Validate request
        errors = request.validate()
        if errors:
            raise ValidationException(errors)

        # Get existing member
        member = self.get_member(org_id, team_id, user_id)

        # If deactivating, check if this is the last team lead
        if request.active is False:
            self._check_not_last_lead(org_id, team_id, member)

        # If changing role, validate new role exists
        role_name = None
        if request.team_role_id:
            role = self.role_service.get_role(org_id, request.team_role_id)
            role_name = role.display_name

        # Update member
        member.update(
            updated_by=updated_by,
            team_role_id=request.team_role_id,
            team_role_name=role_name,
            active=request.active
        )

        # Save member
        updated_member = self.repository.update(member)

        # Update team member count if deactivated
        if request.active is False:
            self.team_service.decrement_member_count(org_id, team_id)

        logger.info(
            "Team member updated",
            extra={
                "user_id": user_id,
                "team_id": team_id,
                "org_id": org_id
            }
        )

        return updated_member

    def remove_member(
        self,
        org_id: str,
        team_id: str,
        user_id: str,
        removed_by: str
    ) -> None:
        """
        Remove a member from a team (soft delete).

        Raises:
            MemberNotFoundException: If member not found
            CannotRemoveLastLeadException: If removing last team lead
        """
        member = self.get_member(org_id, team_id, user_id)

        # Check if this is the last team lead
        self._check_not_last_lead(org_id, team_id, member)

        # Soft delete
        member.update(updated_by=removed_by, active=False)
        self.repository.update(member)

        # Update team member count
        self.team_service.decrement_member_count(org_id, team_id)

        logger.info(
            "Member removed from team",
            extra={
                "user_id": user_id,
                "team_id": team_id,
                "org_id": org_id
            }
        )

    def get_user_teams(
        self, org_id: str, user_id: str
    ) -> List[TeamMembership]:
        """
        Get all team memberships for a user.

        Returns list of TeamMembership with team details.
        """
        members = self.repository.find_by_user_id(org_id, user_id)

        memberships = []
        for member in members:
            # Get team details
            try:
                team = self.team_service.get_team(org_id, member.team_id)
                membership = TeamMembership(
                    team_id=member.team_id,
                    team_name=team.name,
                    team_role_id=member.team_role_id,
                    team_role_name=member.team_role_name,
                    joined_at=member.joined_at,
                    is_primary=len(memberships) == 0,  # First team is primary
                    site_count=team.site_count
                )
                memberships.append(membership)
            except Exception:
                # Skip if team not found
                continue

        return memberships

    def _check_not_last_lead(
        self, org_id: str, team_id: str, member: TeamMember
    ) -> None:
        """Check if removing this member would leave team without a lead."""
        # Get team lead role
        lead_role = self.role_service.get_role_by_name(
            org_id, get_team_lead_role_name()
        )
        if not lead_role:
            return

        # If this member is not a team lead, no issue
        if member.team_role_id != lead_role.team_role_id:
            return

        # Count team leads
        lead_count = self.repository.count_members_with_role_in_team(
            org_id, team_id, lead_role.team_role_id
        )

        if lead_count <= 1:
            raise CannotRemoveLastLeadException(team_id)
```

---

## 6. Handlers

### 6.1 src/utils/response_builder.py

```python
"""
Response Builder - Utility for building Lambda responses.
"""
import json
from typing import Any, Dict, Optional


class ResponseBuilder:
    """Utility class for building standardized API Gateway responses."""

    @staticmethod
    def success(
        body: Any,
        status_code: int = 200,
        headers: Optional[Dict[str, str]] = None
    ) -> Dict[str, Any]:
        """Build a successful response."""
        default_headers = {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization"
        }
        if headers:
            default_headers.update(headers)

        return {
            "statusCode": status_code,
            "headers": default_headers,
            "body": json.dumps(body, default=str)
        }

    @staticmethod
    def created(body: Any) -> Dict[str, Any]:
        """Build a 201 Created response."""
        return ResponseBuilder.success(body, status_code=201)

    @staticmethod
    def no_content() -> Dict[str, Any]:
        """Build a 204 No Content response."""
        return {
            "statusCode": 204,
            "headers": {
                "Access-Control-Allow-Origin": "*"
            },
            "body": ""
        }

    @staticmethod
    def error(
        message: str,
        status_code: int = 500,
        error_code: Optional[str] = None,
        details: Optional[Any] = None
    ) -> Dict[str, Any]:
        """Build an error response."""
        body = {
            "error": {
                "message": message,
                "code": error_code or f"ERROR_{status_code}"
            }
        }
        if details:
            body["error"]["details"] = details

        return {
            "statusCode": status_code,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps(body)
        }

    @staticmethod
    def bad_request(message: str, details: Any = None) -> Dict[str, Any]:
        """Build a 400 Bad Request response."""
        return ResponseBuilder.error(
            message=message,
            status_code=400,
            error_code="BAD_REQUEST",
            details=details
        )

    @staticmethod
    def not_found(message: str) -> Dict[str, Any]:
        """Build a 404 Not Found response."""
        return ResponseBuilder.error(
            message=message,
            status_code=404,
            error_code="NOT_FOUND"
        )

    @staticmethod
    def conflict(message: str) -> Dict[str, Any]:
        """Build a 409 Conflict response."""
        return ResponseBuilder.error(
            message=message,
            status_code=409,
            error_code="CONFLICT"
        )

    @staticmethod
    def forbidden(message: str = "Forbidden") -> Dict[str, Any]:
        """Build a 403 Forbidden response."""
        return ResponseBuilder.error(
            message=message,
            status_code=403,
            error_code="FORBIDDEN"
        )

    @staticmethod
    def paginated_response(
        items: list,
        start_at: Optional[str],
        count: int,
        base_url: str = ""
    ) -> Dict[str, Any]:
        """Build a paginated list response."""
        return {
            "items": items,
            "startAt": start_at,
            "moreAvailable": start_at is not None,
            "count": count,
            "_links": {
                "self": {"href": base_url}
            }
        }
```

### 6.2 src/handlers/team/create_team.py

```python
"""
Create Team Handler - Lambda handler for POST /v1/organisations/{orgId}/teams
"""
import json
import os
from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

from ...models.requests import CreateTeamRequest
from ...services.team_service import TeamService
from ...utils.response_builder import ResponseBuilder
from ...exceptions.team_exceptions import (
    DuplicateTeamNameException,
    ValidationException,
    TeamServiceException
)


logger = Logger(service="CreateTeamHandler")
tracer = Tracer(service="CreateTeamHandler")


@tracer.capture_lambda_handler
@logger.inject_lambda_context
def handler(event: dict, context: LambdaContext) -> dict:
    """
    Lambda handler for creating a team.

    Args:
        event: API Gateway event
        context: Lambda context

    Returns:
        API Gateway response
    """
    try:
        # Extract path parameters
        path_params = event.get("pathParameters", {}) or {}
        org_id = path_params.get("orgId")

        if not org_id:
            return ResponseBuilder.bad_request("Organisation ID is required")

        # Parse request body
        body = event.get("body", "{}")
        if isinstance(body, str):
            body = json.loads(body)

        # Get authenticated user from request context
        request_context = event.get("requestContext", {})
        authorizer = request_context.get("authorizer", {})
        created_by = authorizer.get("claims", {}).get("email", "system")

        # Create request DTO
        request = CreateTeamRequest.from_dict(body)

        # Call service
        service = TeamService()
        team = service.create_team(org_id, request, created_by)

        # Build response
        base_url = os.environ.get("API_BASE_URL", "")
        response_body = team.to_response(base_url)

        logger.info("Team created successfully", extra={"team_id": team.team_id})

        return ResponseBuilder.created(response_body)

    except ValidationException as e:
        logger.warning("Validation error", extra={"errors": e.errors})
        return ResponseBuilder.bad_request(e.message, details=e.errors)

    except DuplicateTeamNameException as e:
        logger.warning("Duplicate team name", extra={"name": e.name})
        return ResponseBuilder.conflict(e.message)

    except TeamServiceException as e:
        logger.error("Service error", extra={"message": e.message})
        return ResponseBuilder.error(e.message, status_code=e.status_code)

    except json.JSONDecodeError:
        return ResponseBuilder.bad_request("Invalid JSON in request body")

    except Exception as e:
        logger.exception("Unexpected error")
        return ResponseBuilder.error(f"Internal server error: {str(e)}")
```

### 6.3 src/handlers/team/list_teams.py

```python
"""
List Teams Handler - Lambda handler for GET /v1/organisations/{orgId}/teams
"""
import os
from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

from ...services.team_service import TeamService
from ...utils.response_builder import ResponseBuilder
from ...exceptions.team_exceptions import TeamServiceException


logger = Logger(service="ListTeamsHandler")
tracer = Tracer(service="ListTeamsHandler")


@tracer.capture_lambda_handler
@logger.inject_lambda_context
def handler(event: dict, context: LambdaContext) -> dict:
    """
    Lambda handler for listing teams.

    Query Parameters:
        - divisionId: Filter by division
        - includeInactive: Include inactive teams (default: false)
        - pageSize: Number of items per page (default: 50)
        - startAt: Pagination cursor
    """
    try:
        # Extract path parameters
        path_params = event.get("pathParameters", {}) or {}
        org_id = path_params.get("orgId")

        if not org_id:
            return ResponseBuilder.bad_request("Organisation ID is required")

        # Extract query parameters
        query_params = event.get("queryStringParameters", {}) or {}
        division_id = query_params.get("divisionId")
        include_inactive = query_params.get("includeInactive", "false").lower() == "true"
        page_size = int(query_params.get("pageSize", "50"))
        start_at = query_params.get("startAt")

        # Call service
        service = TeamService()
        teams, next_token, count = service.list_teams(
            org_id=org_id,
            include_inactive=include_inactive,
            division_id=division_id,
            page_size=page_size,
            start_at=start_at
        )

        # Build response
        base_url = os.environ.get("API_BASE_URL", "")
        items = [team.to_response(base_url) for team in teams]

        response_body = ResponseBuilder.paginated_response(
            items=items,
            start_at=next_token,
            count=count,
            base_url=f"{base_url}/v1/organisations/{org_id}/teams"
        )

        return ResponseBuilder.success(response_body)

    except TeamServiceException as e:
        logger.error("Service error", extra={"message": e.message})
        return ResponseBuilder.error(e.message, status_code=e.status_code)

    except Exception as e:
        logger.exception("Unexpected error")
        return ResponseBuilder.error(f"Internal server error: {str(e)}")
```

### 6.4 src/handlers/team/get_team.py

```python
"""
Get Team Handler - Lambda handler for GET /v1/organisations/{orgId}/teams/{teamId}
"""
import os
from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

from ...services.team_service import TeamService
from ...utils.response_builder import ResponseBuilder
from ...exceptions.team_exceptions import TeamNotFoundException, TeamServiceException


logger = Logger(service="GetTeamHandler")
tracer = Tracer(service="GetTeamHandler")


@tracer.capture_lambda_handler
@logger.inject_lambda_context
def handler(event: dict, context: LambdaContext) -> dict:
    """Lambda handler for getting a team by ID."""
    try:
        # Extract path parameters
        path_params = event.get("pathParameters", {}) or {}
        org_id = path_params.get("orgId")
        team_id = path_params.get("teamId")

        if not org_id:
            return ResponseBuilder.bad_request("Organisation ID is required")
        if not team_id:
            return ResponseBuilder.bad_request("Team ID is required")

        # Call service
        service = TeamService()
        team = service.get_team(org_id, team_id)

        # Build response
        base_url = os.environ.get("API_BASE_URL", "")
        response_body = team.to_response(base_url)

        return ResponseBuilder.success(response_body)

    except TeamNotFoundException as e:
        logger.warning("Team not found", extra={"team_id": e.team_id})
        return ResponseBuilder.not_found(e.message)

    except TeamServiceException as e:
        logger.error("Service error", extra={"message": e.message})
        return ResponseBuilder.error(e.message, status_code=e.status_code)

    except Exception as e:
        logger.exception("Unexpected error")
        return ResponseBuilder.error(f"Internal server error: {str(e)}")
```

### 6.5 src/handlers/team/update_team.py

```python
"""
Update Team Handler - Lambda handler for PUT /v1/organisations/{orgId}/teams/{teamId}
"""
import json
import os
from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

from ...models.requests import UpdateTeamRequest
from ...services.team_service import TeamService
from ...utils.response_builder import ResponseBuilder
from ...exceptions.team_exceptions import (
    TeamNotFoundException,
    DuplicateTeamNameException,
    ValidationException,
    TeamServiceException
)


logger = Logger(service="UpdateTeamHandler")
tracer = Tracer(service="UpdateTeamHandler")


@tracer.capture_lambda_handler
@logger.inject_lambda_context
def handler(event: dict, context: LambdaContext) -> dict:
    """Lambda handler for updating a team."""
    try:
        # Extract path parameters
        path_params = event.get("pathParameters", {}) or {}
        org_id = path_params.get("orgId")
        team_id = path_params.get("teamId")

        if not org_id:
            return ResponseBuilder.bad_request("Organisation ID is required")
        if not team_id:
            return ResponseBuilder.bad_request("Team ID is required")

        # Parse request body
        body = event.get("body", "{}")
        if isinstance(body, str):
            body = json.loads(body)

        # Get authenticated user
        request_context = event.get("requestContext", {})
        authorizer = request_context.get("authorizer", {})
        updated_by = authorizer.get("claims", {}).get("email", "system")

        # Create request DTO
        request = UpdateTeamRequest.from_dict(body)

        # Call service
        service = TeamService()
        team = service.update_team(org_id, team_id, request, updated_by)

        # Build response
        base_url = os.environ.get("API_BASE_URL", "")
        response_body = team.to_response(base_url)

        logger.info("Team updated successfully", extra={"team_id": team_id})

        return ResponseBuilder.success(response_body)

    except ValidationException as e:
        logger.warning("Validation error", extra={"errors": e.errors})
        return ResponseBuilder.bad_request(e.message, details=e.errors)

    except TeamNotFoundException as e:
        return ResponseBuilder.not_found(e.message)

    except DuplicateTeamNameException as e:
        return ResponseBuilder.conflict(e.message)

    except TeamServiceException as e:
        logger.error("Service error", extra={"message": e.message})
        return ResponseBuilder.error(e.message, status_code=e.status_code)

    except json.JSONDecodeError:
        return ResponseBuilder.bad_request("Invalid JSON in request body")

    except Exception as e:
        logger.exception("Unexpected error")
        return ResponseBuilder.error(f"Internal server error: {str(e)}")
```

### 6.6 src/handlers/team_role/create_team_role.py

```python
"""
Create Team Role Handler - Lambda handler for POST /v1/organisations/{orgId}/team-roles
"""
import json
import os
from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

from ...models.requests import CreateTeamRoleRequest
from ...services.team_role_service import TeamRoleService
from ...utils.response_builder import ResponseBuilder
from ...exceptions.team_exceptions import (
    DuplicateRoleNameException,
    ValidationException,
    InvalidCapabilityException,
    TeamServiceException
)


logger = Logger(service="CreateTeamRoleHandler")
tracer = Tracer(service="CreateTeamRoleHandler")


@tracer.capture_lambda_handler
@logger.inject_lambda_context
def handler(event: dict, context: LambdaContext) -> dict:
    """Lambda handler for creating a team role."""
    try:
        # Extract path parameters
        path_params = event.get("pathParameters", {}) or {}
        org_id = path_params.get("orgId")

        if not org_id:
            return ResponseBuilder.bad_request("Organisation ID is required")

        # Parse request body
        body = event.get("body", "{}")
        if isinstance(body, str):
            body = json.loads(body)

        # Get authenticated user
        request_context = event.get("requestContext", {})
        authorizer = request_context.get("authorizer", {})
        created_by = authorizer.get("claims", {}).get("email", "system")

        # Create request DTO
        request = CreateTeamRoleRequest.from_dict(body)

        # Call service
        service = TeamRoleService()
        role = service.create_role(org_id, request, created_by)

        # Build response
        base_url = os.environ.get("API_BASE_URL", "")
        response_body = role.to_response(base_url)

        logger.info("Team role created", extra={"role_id": role.team_role_id})

        return ResponseBuilder.created(response_body)

    except ValidationException as e:
        return ResponseBuilder.bad_request(e.message, details=e.errors)

    except InvalidCapabilityException as e:
        return ResponseBuilder.bad_request(e.message, details=e.invalid_capabilities)

    except DuplicateRoleNameException as e:
        return ResponseBuilder.conflict(e.message)

    except TeamServiceException as e:
        return ResponseBuilder.error(e.message, status_code=e.status_code)

    except json.JSONDecodeError:
        return ResponseBuilder.bad_request("Invalid JSON in request body")

    except Exception as e:
        logger.exception("Unexpected error")
        return ResponseBuilder.error(f"Internal server error: {str(e)}")
```

### 6.7 src/handlers/team_role/list_team_roles.py

```python
"""
List Team Roles Handler - Lambda handler for GET /v1/organisations/{orgId}/team-roles
"""
import os
from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

from ...services.team_role_service import TeamRoleService
from ...utils.response_builder import ResponseBuilder
from ...exceptions.team_exceptions import TeamServiceException


logger = Logger(service="ListTeamRolesHandler")
tracer = Tracer(service="ListTeamRolesHandler")


@tracer.capture_lambda_handler
@logger.inject_lambda_context
def handler(event: dict, context: LambdaContext) -> dict:
    """Lambda handler for listing team roles."""
    try:
        # Extract path parameters
        path_params = event.get("pathParameters", {}) or {}
        org_id = path_params.get("orgId")

        if not org_id:
            return ResponseBuilder.bad_request("Organisation ID is required")

        # Extract query parameters
        query_params = event.get("queryStringParameters", {}) or {}
        include_inactive = query_params.get("includeInactive", "false").lower() == "true"
        defaults_only = query_params.get("defaultsOnly", "false").lower() == "true"
        page_size = int(query_params.get("pageSize", "50"))
        start_at = query_params.get("startAt")

        # Call service
        service = TeamRoleService()
        roles, next_token, count = service.list_roles(
            org_id=org_id,
            include_inactive=include_inactive,
            defaults_only=defaults_only,
            page_size=page_size,
            start_at=start_at
        )

        # Build response
        base_url = os.environ.get("API_BASE_URL", "")
        items = [role.to_response(base_url) for role in roles]

        response_body = ResponseBuilder.paginated_response(
            items=items,
            start_at=next_token,
            count=count,
            base_url=f"{base_url}/v1/organisations/{org_id}/team-roles"
        )

        return ResponseBuilder.success(response_body)

    except TeamServiceException as e:
        return ResponseBuilder.error(e.message, status_code=e.status_code)

    except Exception as e:
        logger.exception("Unexpected error")
        return ResponseBuilder.error(f"Internal server error: {str(e)}")
```

### 6.8 src/handlers/team_role/get_team_role.py

```python
"""
Get Team Role Handler - Lambda handler for GET /v1/organisations/{orgId}/team-roles/{roleId}
"""
import os
from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

from ...services.team_role_service import TeamRoleService
from ...utils.response_builder import ResponseBuilder
from ...exceptions.team_exceptions import TeamRoleNotFoundException, TeamServiceException


logger = Logger(service="GetTeamRoleHandler")
tracer = Tracer(service="GetTeamRoleHandler")


@tracer.capture_lambda_handler
@logger.inject_lambda_context
def handler(event: dict, context: LambdaContext) -> dict:
    """Lambda handler for getting a team role by ID."""
    try:
        # Extract path parameters
        path_params = event.get("pathParameters", {}) or {}
        org_id = path_params.get("orgId")
        role_id = path_params.get("roleId")

        if not org_id:
            return ResponseBuilder.bad_request("Organisation ID is required")
        if not role_id:
            return ResponseBuilder.bad_request("Role ID is required")

        # Call service
        service = TeamRoleService()
        role = service.get_role(org_id, role_id)

        # Build response
        base_url = os.environ.get("API_BASE_URL", "")
        response_body = role.to_response(base_url)

        return ResponseBuilder.success(response_body)

    except TeamRoleNotFoundException as e:
        return ResponseBuilder.not_found(e.message)

    except TeamServiceException as e:
        return ResponseBuilder.error(e.message, status_code=e.status_code)

    except Exception as e:
        logger.exception("Unexpected error")
        return ResponseBuilder.error(f"Internal server error: {str(e)}")
```

### 6.9 src/handlers/team_role/update_team_role.py

```python
"""
Update Team Role Handler - Lambda handler for PUT /v1/organisations/{orgId}/team-roles/{roleId}
"""
import json
import os
from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

from ...models.requests import UpdateTeamRoleRequest
from ...services.team_role_service import TeamRoleService
from ...utils.response_builder import ResponseBuilder
from ...exceptions.team_exceptions import (
    TeamRoleNotFoundException,
    ValidationException,
    InvalidCapabilityException,
    TeamServiceException
)


logger = Logger(service="UpdateTeamRoleHandler")
tracer = Tracer(service="UpdateTeamRoleHandler")


@tracer.capture_lambda_handler
@logger.inject_lambda_context
def handler(event: dict, context: LambdaContext) -> dict:
    """Lambda handler for updating a team role."""
    try:
        # Extract path parameters
        path_params = event.get("pathParameters", {}) or {}
        org_id = path_params.get("orgId")
        role_id = path_params.get("roleId")

        if not org_id:
            return ResponseBuilder.bad_request("Organisation ID is required")
        if not role_id:
            return ResponseBuilder.bad_request("Role ID is required")

        # Parse request body
        body = event.get("body", "{}")
        if isinstance(body, str):
            body = json.loads(body)

        # Get authenticated user
        request_context = event.get("requestContext", {})
        authorizer = request_context.get("authorizer", {})
        updated_by = authorizer.get("claims", {}).get("email", "system")

        # Create request DTO
        request = UpdateTeamRoleRequest.from_dict(body)

        # Call service
        service = TeamRoleService()
        role = service.update_role(org_id, role_id, request, updated_by)

        # Build response
        base_url = os.environ.get("API_BASE_URL", "")
        response_body = role.to_response(base_url)

        logger.info("Team role updated", extra={"role_id": role_id})

        return ResponseBuilder.success(response_body)

    except ValidationException as e:
        return ResponseBuilder.bad_request(e.message, details=e.errors)

    except InvalidCapabilityException as e:
        return ResponseBuilder.bad_request(e.message, details=e.invalid_capabilities)

    except TeamRoleNotFoundException as e:
        return ResponseBuilder.not_found(e.message)

    except TeamServiceException as e:
        return ResponseBuilder.error(e.message, status_code=e.status_code)

    except json.JSONDecodeError:
        return ResponseBuilder.bad_request("Invalid JSON in request body")

    except Exception as e:
        logger.exception("Unexpected error")
        return ResponseBuilder.error(f"Internal server error: {str(e)}")
```

### 6.10 src/handlers/team_role/delete_team_role.py

```python
"""
Delete Team Role Handler - Lambda handler for DELETE /v1/organisations/{orgId}/team-roles/{roleId}
(Soft delete via deactivation)
"""
import os
from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

from ...services.team_role_service import TeamRoleService
from ...utils.response_builder import ResponseBuilder
from ...exceptions.team_exceptions import (
    TeamRoleNotFoundException,
    RoleInUseException,
    TeamServiceException
)


logger = Logger(service="DeleteTeamRoleHandler")
tracer = Tracer(service="DeleteTeamRoleHandler")


@tracer.capture_lambda_handler
@logger.inject_lambda_context
def handler(event: dict, context: LambdaContext) -> dict:
    """Lambda handler for deleting (deactivating) a team role."""
    try:
        # Extract path parameters
        path_params = event.get("pathParameters", {}) or {}
        org_id = path_params.get("orgId")
        role_id = path_params.get("roleId")

        if not org_id:
            return ResponseBuilder.bad_request("Organisation ID is required")
        if not role_id:
            return ResponseBuilder.bad_request("Role ID is required")

        # Get authenticated user
        request_context = event.get("requestContext", {})
        authorizer = request_context.get("authorizer", {})
        deleted_by = authorizer.get("claims", {}).get("email", "system")

        # Call service
        service = TeamRoleService()
        role = service.deactivate_role(org_id, role_id, deleted_by)

        # Build response
        base_url = os.environ.get("API_BASE_URL", "")
        response_body = role.to_response(base_url)

        logger.info("Team role deactivated", extra={"role_id": role_id})

        return ResponseBuilder.success(response_body)

    except TeamRoleNotFoundException as e:
        return ResponseBuilder.not_found(e.message)

    except RoleInUseException as e:
        return ResponseBuilder.bad_request(e.message)

    except TeamServiceException as e:
        return ResponseBuilder.error(e.message, status_code=e.status_code)

    except Exception as e:
        logger.exception("Unexpected error")
        return ResponseBuilder.error(f"Internal server error: {str(e)}")
```

### 6.11 src/handlers/member/add_member.py

```python
"""
Add Member Handler - Lambda handler for POST /v1/organisations/{orgId}/teams/{teamId}/members
"""
import json
import os
from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

from ...models.requests import AddMemberRequest
from ...services.team_member_service import TeamMemberService
from ...utils.response_builder import ResponseBuilder
from ...exceptions.team_exceptions import (
    TeamNotFoundException,
    TeamRoleNotFoundException,
    UserAlreadyMemberException,
    ValidationException,
    TeamServiceException
)


logger = Logger(service="AddMemberHandler")
tracer = Tracer(service="AddMemberHandler")


@tracer.capture_lambda_handler
@logger.inject_lambda_context
def handler(event: dict, context: LambdaContext) -> dict:
    """Lambda handler for adding a member to a team."""
    try:
        # Extract path parameters
        path_params = event.get("pathParameters", {}) or {}
        org_id = path_params.get("orgId")
        team_id = path_params.get("teamId")

        if not org_id:
            return ResponseBuilder.bad_request("Organisation ID is required")
        if not team_id:
            return ResponseBuilder.bad_request("Team ID is required")

        # Parse request body
        body = event.get("body", "{}")
        if isinstance(body, str):
            body = json.loads(body)

        # Get authenticated user
        request_context = event.get("requestContext", {})
        authorizer = request_context.get("authorizer", {})
        added_by = authorizer.get("claims", {}).get("email", "system")

        # User info could be enriched from user service
        # For now, use request body if provided
        user_email = body.get("userEmail", "")
        user_first_name = body.get("userFirstName", "")
        user_last_name = body.get("userLastName", "")

        # Create request DTO
        request = AddMemberRequest.from_dict(body)

        # Call service
        service = TeamMemberService()
        member = service.add_member(
            org_id=org_id,
            team_id=team_id,
            request=request,
            added_by=added_by,
            user_email=user_email,
            user_first_name=user_first_name,
            user_last_name=user_last_name
        )

        # Build response
        base_url = os.environ.get("API_BASE_URL", "")
        response_body = member.to_response(base_url)

        logger.info("Member added to team", extra={
            "user_id": request.user_id,
            "team_id": team_id
        })

        return ResponseBuilder.created(response_body)

    except ValidationException as e:
        return ResponseBuilder.bad_request(e.message, details=e.errors)

    except TeamNotFoundException as e:
        return ResponseBuilder.not_found(e.message)

    except TeamRoleNotFoundException as e:
        return ResponseBuilder.not_found(e.message)

    except UserAlreadyMemberException as e:
        return ResponseBuilder.conflict(e.message)

    except TeamServiceException as e:
        return ResponseBuilder.error(e.message, status_code=e.status_code)

    except json.JSONDecodeError:
        return ResponseBuilder.bad_request("Invalid JSON in request body")

    except Exception as e:
        logger.exception("Unexpected error")
        return ResponseBuilder.error(f"Internal server error: {str(e)}")
```

### 6.12 src/handlers/member/list_members.py

```python
"""
List Members Handler - Lambda handler for GET /v1/organisations/{orgId}/teams/{teamId}/members
"""
import os
from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

from ...services.team_member_service import TeamMemberService
from ...utils.response_builder import ResponseBuilder
from ...exceptions.team_exceptions import TeamServiceException


logger = Logger(service="ListMembersHandler")
tracer = Tracer(service="ListMembersHandler")


@tracer.capture_lambda_handler
@logger.inject_lambda_context
def handler(event: dict, context: LambdaContext) -> dict:
    """Lambda handler for listing team members."""
    try:
        # Extract path parameters
        path_params = event.get("pathParameters", {}) or {}
        org_id = path_params.get("orgId")
        team_id = path_params.get("teamId")

        if not org_id:
            return ResponseBuilder.bad_request("Organisation ID is required")
        if not team_id:
            return ResponseBuilder.bad_request("Team ID is required")

        # Extract query parameters
        query_params = event.get("queryStringParameters", {}) or {}
        include_inactive = query_params.get("includeInactive", "false").lower() == "true"
        team_role_id = query_params.get("teamRoleId")
        page_size = int(query_params.get("pageSize", "50"))
        start_at = query_params.get("startAt")

        # Call service
        service = TeamMemberService()
        members, next_token, count = service.list_members(
            org_id=org_id,
            team_id=team_id,
            include_inactive=include_inactive,
            team_role_id=team_role_id,
            page_size=page_size,
            start_at=start_at
        )

        # Build response
        base_url = os.environ.get("API_BASE_URL", "")
        items = [member.to_response(base_url) for member in members]

        response_body = ResponseBuilder.paginated_response(
            items=items,
            start_at=next_token,
            count=count,
            base_url=f"{base_url}/v1/organisations/{org_id}/teams/{team_id}/members"
        )

        return ResponseBuilder.success(response_body)

    except TeamServiceException as e:
        return ResponseBuilder.error(e.message, status_code=e.status_code)

    except Exception as e:
        logger.exception("Unexpected error")
        return ResponseBuilder.error(f"Internal server error: {str(e)}")
```

### 6.13 src/handlers/member/get_member.py

```python
"""
Get Member Handler - Lambda handler for GET /v1/organisations/{orgId}/teams/{teamId}/members/{userId}
"""
import os
from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

from ...services.team_member_service import TeamMemberService
from ...utils.response_builder import ResponseBuilder
from ...exceptions.team_exceptions import MemberNotFoundException, TeamServiceException


logger = Logger(service="GetMemberHandler")
tracer = Tracer(service="GetMemberHandler")


@tracer.capture_lambda_handler
@logger.inject_lambda_context
def handler(event: dict, context: LambdaContext) -> dict:
    """Lambda handler for getting a team member."""
    try:
        # Extract path parameters
        path_params = event.get("pathParameters", {}) or {}
        org_id = path_params.get("orgId")
        team_id = path_params.get("teamId")
        user_id = path_params.get("userId")

        if not org_id:
            return ResponseBuilder.bad_request("Organisation ID is required")
        if not team_id:
            return ResponseBuilder.bad_request("Team ID is required")
        if not user_id:
            return ResponseBuilder.bad_request("User ID is required")

        # Call service
        service = TeamMemberService()
        member = service.get_member(org_id, team_id, user_id)

        # Build response
        base_url = os.environ.get("API_BASE_URL", "")
        response_body = member.to_response(base_url)

        return ResponseBuilder.success(response_body)

    except MemberNotFoundException as e:
        return ResponseBuilder.not_found(e.message)

    except TeamServiceException as e:
        return ResponseBuilder.error(e.message, status_code=e.status_code)

    except Exception as e:
        logger.exception("Unexpected error")
        return ResponseBuilder.error(f"Internal server error: {str(e)}")
```

### 6.14 src/handlers/member/update_member.py

```python
"""
Update Member Handler - Lambda handler for PUT /v1/organisations/{orgId}/teams/{teamId}/members/{userId}
"""
import json
import os
from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

from ...models.requests import UpdateMemberRequest
from ...services.team_member_service import TeamMemberService
from ...utils.response_builder import ResponseBuilder
from ...exceptions.team_exceptions import (
    MemberNotFoundException,
    TeamRoleNotFoundException,
    CannotRemoveLastLeadException,
    ValidationException,
    TeamServiceException
)


logger = Logger(service="UpdateMemberHandler")
tracer = Tracer(service="UpdateMemberHandler")


@tracer.capture_lambda_handler
@logger.inject_lambda_context
def handler(event: dict, context: LambdaContext) -> dict:
    """Lambda handler for updating a team member."""
    try:
        # Extract path parameters
        path_params = event.get("pathParameters", {}) or {}
        org_id = path_params.get("orgId")
        team_id = path_params.get("teamId")
        user_id = path_params.get("userId")

        if not org_id:
            return ResponseBuilder.bad_request("Organisation ID is required")
        if not team_id:
            return ResponseBuilder.bad_request("Team ID is required")
        if not user_id:
            return ResponseBuilder.bad_request("User ID is required")

        # Parse request body
        body = event.get("body", "{}")
        if isinstance(body, str):
            body = json.loads(body)

        # Get authenticated user
        request_context = event.get("requestContext", {})
        authorizer = request_context.get("authorizer", {})
        updated_by = authorizer.get("claims", {}).get("email", "system")

        # Create request DTO
        request = UpdateMemberRequest.from_dict(body)

        # Call service
        service = TeamMemberService()
        member = service.update_member(
            org_id=org_id,
            team_id=team_id,
            user_id=user_id,
            request=request,
            updated_by=updated_by
        )

        # Build response
        base_url = os.environ.get("API_BASE_URL", "")
        response_body = member.to_response(base_url)

        logger.info("Team member updated", extra={
            "user_id": user_id,
            "team_id": team_id
        })

        return ResponseBuilder.success(response_body)

    except ValidationException as e:
        return ResponseBuilder.bad_request(e.message, details=e.errors)

    except MemberNotFoundException as e:
        return ResponseBuilder.not_found(e.message)

    except TeamRoleNotFoundException as e:
        return ResponseBuilder.not_found(e.message)

    except CannotRemoveLastLeadException as e:
        return ResponseBuilder.bad_request(e.message)

    except TeamServiceException as e:
        return ResponseBuilder.error(e.message, status_code=e.status_code)

    except json.JSONDecodeError:
        return ResponseBuilder.bad_request("Invalid JSON in request body")

    except Exception as e:
        logger.exception("Unexpected error")
        return ResponseBuilder.error(f"Internal server error: {str(e)}")
```

### 6.15 src/handlers/member/get_user_teams.py

```python
"""
Get User Teams Handler - Lambda handler for GET /v1/organisations/{orgId}/users/{userId}/teams
"""
import os
from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

from ...services.team_member_service import TeamMemberService
from ...utils.response_builder import ResponseBuilder
from ...exceptions.team_exceptions import TeamServiceException


logger = Logger(service="GetUserTeamsHandler")
tracer = Tracer(service="GetUserTeamsHandler")


@tracer.capture_lambda_handler
@logger.inject_lambda_context
def handler(event: dict, context: LambdaContext) -> dict:
    """Lambda handler for getting a user's team memberships."""
    try:
        # Extract path parameters
        path_params = event.get("pathParameters", {}) or {}
        org_id = path_params.get("orgId")
        user_id = path_params.get("userId")

        if not org_id:
            return ResponseBuilder.bad_request("Organisation ID is required")
        if not user_id:
            return ResponseBuilder.bad_request("User ID is required")

        # Call service
        service = TeamMemberService()
        memberships = service.get_user_teams(org_id, user_id)

        # Build response
        base_url = os.environ.get("API_BASE_URL", "")
        teams = [m.to_response(base_url, org_id) for m in memberships]

        response_body = {
            "teams": teams,
            "_links": {
                "self": {"href": f"{base_url}/v1/organisations/{org_id}/users/{user_id}/teams"},
                "user": {"href": f"{base_url}/v1/organisations/{org_id}/users/{user_id}"}
            }
        }

        return ResponseBuilder.success(response_body)

    except TeamServiceException as e:
        return ResponseBuilder.error(e.message, status_code=e.status_code)

    except Exception as e:
        logger.exception("Unexpected error")
        return ResponseBuilder.error(f"Internal server error: {str(e)}")
```

---

## 7. Unit Tests

### 7.1 tests/conftest.py

```python
"""
Pytest Fixtures - Shared test fixtures using moto for DynamoDB mocking.
"""
import os
import pytest
import boto3
from moto import mock_aws


@pytest.fixture(scope="function")
def aws_credentials():
    """Mock AWS credentials for moto."""
    os.environ["AWS_ACCESS_KEY_ID"] = "testing"
    os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
    os.environ["AWS_SECURITY_TOKEN"] = "testing"
    os.environ["AWS_SESSION_TOKEN"] = "testing"
    os.environ["AWS_DEFAULT_REGION"] = "af-south-1"


@pytest.fixture(scope="function")
def dynamodb_table(aws_credentials):
    """Create a mock DynamoDB table for testing."""
    with mock_aws():
        dynamodb = boto3.resource("dynamodb", region_name="af-south-1")

        table = dynamodb.create_table(
            TableName="bbws-aipagebuilder-dev-ddb-access-management",
            KeySchema=[
                {"AttributeName": "PK", "KeyType": "HASH"},
                {"AttributeName": "SK", "KeyType": "RANGE"}
            ],
            AttributeDefinitions=[
                {"AttributeName": "PK", "AttributeType": "S"},
                {"AttributeName": "SK", "AttributeType": "S"},
                {"AttributeName": "GSI1PK", "AttributeType": "S"},
                {"AttributeName": "GSI1SK", "AttributeType": "S"},
                {"AttributeName": "GSI2PK", "AttributeType": "S"},
                {"AttributeName": "GSI2SK", "AttributeType": "S"}
            ],
            GlobalSecondaryIndexes=[
                {
                    "IndexName": "GSI1",
                    "KeySchema": [
                        {"AttributeName": "GSI1PK", "KeyType": "HASH"},
                        {"AttributeName": "GSI1SK", "KeyType": "RANGE"}
                    ],
                    "Projection": {"ProjectionType": "ALL"}
                },
                {
                    "IndexName": "GSI2",
                    "KeySchema": [
                        {"AttributeName": "GSI2PK", "KeyType": "HASH"},
                        {"AttributeName": "GSI2SK", "KeyType": "RANGE"}
                    ],
                    "Projection": {"ProjectionType": "ALL"}
                }
            ],
            BillingMode="PAY_PER_REQUEST"
        )

        table.wait_until_exists()

        os.environ["DYNAMODB_TABLE_NAME"] = table.table_name

        yield dynamodb

        table.delete()


@pytest.fixture
def sample_org_id():
    """Sample organisation ID for testing."""
    return "org-12345678"


@pytest.fixture
def sample_team_id():
    """Sample team ID for testing."""
    return "team-12345678"


@pytest.fixture
def sample_user_id():
    """Sample user ID for testing."""
    return "user-12345678"


@pytest.fixture
def sample_role_id():
    """Sample role ID for testing."""
    return "role-12345678"
```

### 7.2 tests/unit/test_models/test_team.py

```python
"""
Unit Tests for Team Model - TDD approach (tests written first).
"""
import pytest
from datetime import datetime

from src.models.team import Team


class TestTeamModel:
    """Test cases for Team model."""

    def test_create_team_with_required_fields(self):
        """Test creating a team with required fields only."""
        # Given
        name = "Engineering"
        org_id = "org-123"
        created_by = "admin@example.com"

        # When
        team = Team.create(
            name=name,
            organisation_id=org_id,
            created_by=created_by
        )

        # Then
        assert team.name == name
        assert team.organisation_id == org_id
        assert team.created_by == created_by
        assert team.team_id is not None
        assert team.active is True
        assert team.member_count == 0
        assert team.site_count == 0

    def test_create_team_with_all_fields(self):
        """Test creating a team with all optional fields."""
        # Given
        name = "Engineering"
        org_id = "org-123"
        created_by = "admin@example.com"
        description = "Engineering team"
        division_id = "div-123"
        group_id = "group-123"

        # When
        team = Team.create(
            name=name,
            organisation_id=org_id,
            created_by=created_by,
            description=description,
            division_id=division_id,
            group_id=group_id
        )

        # Then
        assert team.description == description
        assert team.division_id == division_id
        assert team.group_id == group_id

    def test_update_team_name(self):
        """Test updating team name."""
        # Given
        team = Team.create(
            name="Old Name",
            organisation_id="org-123",
            created_by="admin@example.com"
        )

        # When
        team.update(updated_by="editor@example.com", name="New Name")

        # Then
        assert team.name == "New Name"
        assert team.last_updated_by == "editor@example.com"

    def test_update_team_active_status(self):
        """Test soft delete by setting active=False."""
        # Given
        team = Team.create(
            name="Team",
            organisation_id="org-123",
            created_by="admin@example.com"
        )
        assert team.active is True

        # When
        team.update(updated_by="admin@example.com", active=False)

        # Then
        assert team.active is False

    def test_increment_member_count(self):
        """Test incrementing member count."""
        # Given
        team = Team.create(
            name="Team",
            organisation_id="org-123",
            created_by="admin@example.com"
        )
        assert team.member_count == 0

        # When
        team.increment_member_count()

        # Then
        assert team.member_count == 1

    def test_decrement_member_count(self):
        """Test decrementing member count."""
        # Given
        team = Team.create(
            name="Team",
            organisation_id="org-123",
            created_by="admin@example.com"
        )
        team.member_count = 5

        # When
        team.decrement_member_count()

        # Then
        assert team.member_count == 4

    def test_decrement_member_count_minimum_zero(self):
        """Test that member count cannot go below zero."""
        # Given
        team = Team.create(
            name="Team",
            organisation_id="org-123",
            created_by="admin@example.com"
        )
        assert team.member_count == 0

        # When
        team.decrement_member_count()

        # Then
        assert team.member_count == 0

    def test_to_dict_conversion(self):
        """Test converting team to dictionary."""
        # Given
        team = Team.create(
            name="Engineering",
            organisation_id="org-123",
            created_by="admin@example.com"
        )

        # When
        result = team.to_dict()

        # Then
        assert result["teamId"] == team.team_id
        assert result["name"] == "Engineering"
        assert result["organisationId"] == "org-123"
        assert result["active"] is True

    def test_from_dict_conversion(self):
        """Test creating team from dictionary."""
        # Given
        data = {
            "teamId": "team-123",
            "name": "Engineering",
            "organisationId": "org-123",
            "description": "Eng team",
            "active": True,
            "memberCount": 5,
            "siteCount": 3,
            "dateCreated": "2026-01-23T10:00:00",
            "dateLastUpdated": "2026-01-23T10:00:00",
            "createdBy": "admin@example.com",
            "lastUpdatedBy": "admin@example.com"
        }

        # When
        team = Team.from_dict(data)

        # Then
        assert team.team_id == "team-123"
        assert team.name == "Engineering"
        assert team.member_count == 5

    def test_to_response_includes_hateoas_links(self):
        """Test that response includes HATEOAS links."""
        # Given
        team = Team.create(
            name="Engineering",
            organisation_id="org-123",
            created_by="admin@example.com"
        )
        base_url = "https://api.example.com"

        # When
        response = team.to_response(base_url)

        # Then
        assert "_links" in response
        assert "self" in response["_links"]
        assert "members" in response["_links"]
        assert "organisation" in response["_links"]
        assert f"/teams/{team.team_id}" in response["_links"]["self"]["href"]
```

### 7.3 tests/unit/test_models/test_team_role.py

```python
"""
Unit Tests for TeamRoleDefinition Model.
"""
import pytest

from src.models.team_role import TeamRoleDefinition
from src.models.capabilities import TeamRoleCapability


class TestTeamRoleDefinitionModel:
    """Test cases for TeamRoleDefinition model."""

    def test_create_role_with_valid_capabilities(self):
        """Test creating a role with valid capabilities."""
        # Given
        name = "SENIOR_DEV"
        display_name = "Senior Developer"
        org_id = "org-123"
        capabilities = [
            TeamRoleCapability.CAN_VIEW_MEMBERS.value,
            TeamRoleCapability.CAN_VIEW_SITES.value,
            TeamRoleCapability.CAN_EDIT_SITES.value
        ]
        created_by = "admin@example.com"

        # When
        role = TeamRoleDefinition.create(
            name=name,
            display_name=display_name,
            organisation_id=org_id,
            capabilities=capabilities,
            created_by=created_by
        )

        # Then
        assert role.name == "SENIOR_DEV"
        assert role.display_name == display_name
        assert role.capabilities == capabilities
        assert role.active is True
        assert role.is_default is False

    def test_create_role_normalizes_name(self):
        """Test that role name is normalized to uppercase."""
        # Given/When
        role = TeamRoleDefinition.create(
            name="senior dev",
            display_name="Senior Developer",
            organisation_id="org-123",
            capabilities=[TeamRoleCapability.CAN_VIEW_MEMBERS.value],
            created_by="admin@example.com"
        )

        # Then
        assert role.name == "SENIOR_DEV"

    def test_create_role_with_invalid_capability_raises_error(self):
        """Test that invalid capabilities raise ValueError."""
        # Given
        invalid_capabilities = ["CAN_VIEW_MEMBERS", "INVALID_CAPABILITY"]

        # When/Then
        with pytest.raises(ValueError) as exc_info:
            TeamRoleDefinition.create(
                name="ROLE",
                display_name="Role",
                organisation_id="org-123",
                capabilities=invalid_capabilities,
                created_by="admin@example.com"
            )

        assert "Invalid capabilities" in str(exc_info.value)

    def test_has_capability_returns_true_when_present(self):
        """Test has_capability returns True for present capability."""
        # Given
        role = TeamRoleDefinition.create(
            name="LEAD",
            display_name="Lead",
            organisation_id="org-123",
            capabilities=[
                TeamRoleCapability.CAN_MANAGE_MEMBERS.value,
                TeamRoleCapability.CAN_VIEW_MEMBERS.value
            ],
            created_by="admin@example.com"
        )

        # When/Then
        assert role.has_capability(TeamRoleCapability.CAN_MANAGE_MEMBERS) is True
        assert role.has_capability(TeamRoleCapability.CAN_VIEW_MEMBERS) is True
        assert role.has_capability(TeamRoleCapability.CAN_DELETE_SITES) is False

    def test_update_role_capabilities(self):
        """Test updating role capabilities."""
        # Given
        role = TeamRoleDefinition.create(
            name="ROLE",
            display_name="Role",
            organisation_id="org-123",
            capabilities=[TeamRoleCapability.CAN_VIEW_MEMBERS.value],
            created_by="admin@example.com"
        )

        # When
        new_capabilities = [
            TeamRoleCapability.CAN_VIEW_MEMBERS.value,
            TeamRoleCapability.CAN_EDIT_SITES.value
        ]
        role.update(
            updated_by="admin@example.com",
            capabilities=new_capabilities
        )

        # Then
        assert role.capabilities == new_capabilities

    def test_update_role_with_invalid_capabilities_raises_error(self):
        """Test that updating with invalid capabilities raises ValueError."""
        # Given
        role = TeamRoleDefinition.create(
            name="ROLE",
            display_name="Role",
            organisation_id="org-123",
            capabilities=[TeamRoleCapability.CAN_VIEW_MEMBERS.value],
            created_by="admin@example.com"
        )

        # When/Then
        with pytest.raises(ValueError):
            role.update(
                updated_by="admin@example.com",
                capabilities=["INVALID"]
            )

    def test_to_response_includes_hateoas_links(self):
        """Test that response includes HATEOAS links."""
        # Given
        role = TeamRoleDefinition.create(
            name="ROLE",
            display_name="Role",
            organisation_id="org-123",
            capabilities=[TeamRoleCapability.CAN_VIEW_MEMBERS.value],
            created_by="admin@example.com"
        )
        base_url = "https://api.example.com"

        # When
        response = role.to_response(base_url)

        # Then
        assert "_links" in response
        assert "self" in response["_links"]
        assert f"/team-roles/{role.team_role_id}" in response["_links"]["self"]["href"]
```

### 7.4 tests/unit/test_models/test_capabilities.py

```python
"""
Unit Tests for TeamRoleCapability Enum.
"""
import pytest

from src.models.capabilities import TeamRoleCapability


class TestTeamRoleCapability:
    """Test cases for TeamRoleCapability enum."""

    def test_all_capabilities_returns_all_values(self):
        """Test that all_capabilities returns all enum values."""
        # When
        all_caps = TeamRoleCapability.all_capabilities()

        # Then
        assert len(all_caps) == 7
        assert "CAN_MANAGE_MEMBERS" in all_caps
        assert "CAN_UPDATE_TEAM" in all_caps
        assert "CAN_VIEW_MEMBERS" in all_caps
        assert "CAN_VIEW_SITES" in all_caps
        assert "CAN_EDIT_SITES" in all_caps
        assert "CAN_DELETE_SITES" in all_caps
        assert "CAN_VIEW_AUDIT" in all_caps

    def test_validate_capabilities_returns_true_for_valid(self):
        """Test validate_capabilities with valid capabilities."""
        # Given
        valid_caps = ["CAN_MANAGE_MEMBERS", "CAN_VIEW_MEMBERS"]

        # When
        result = TeamRoleCapability.validate_capabilities(valid_caps)

        # Then
        assert result is True

    def test_validate_capabilities_returns_false_for_invalid(self):
        """Test validate_capabilities with invalid capabilities."""
        # Given
        invalid_caps = ["CAN_VIEW_MEMBERS", "INVALID_CAP"]

        # When
        result = TeamRoleCapability.validate_capabilities(invalid_caps)

        # Then
        assert result is False

    def test_get_invalid_capabilities_returns_invalid_only(self):
        """Test get_invalid_capabilities returns only invalid ones."""
        # Given
        mixed_caps = ["CAN_VIEW_MEMBERS", "INVALID_1", "CAN_EDIT_SITES", "INVALID_2"]

        # When
        invalid = TeamRoleCapability.get_invalid_capabilities(mixed_caps)

        # Then
        assert invalid == ["INVALID_1", "INVALID_2"]

    def test_capability_enum_value_matches_name(self):
        """Test that enum value matches the name."""
        # When/Then
        assert TeamRoleCapability.CAN_MANAGE_MEMBERS.value == "CAN_MANAGE_MEMBERS"
        assert TeamRoleCapability.CAN_VIEW_SITES.value == "CAN_VIEW_SITES"
```

### 7.5 tests/unit/test_services/test_team_service.py

```python
"""
Unit Tests for Team Service - Integration tests with moto.
"""
import pytest
from moto import mock_aws

from src.services.team_service import TeamService
from src.repositories.team_repository import TeamRepository
from src.models.requests import CreateTeamRequest, UpdateTeamRequest
from src.exceptions.team_exceptions import (
    TeamNotFoundException,
    DuplicateTeamNameException,
    ValidationException
)


class TestTeamService:
    """Test cases for TeamService."""

    @mock_aws
    def test_create_team_success(self, dynamodb_table, sample_org_id):
        """Test successfully creating a team."""
        # Given
        repository = TeamRepository(dynamodb_resource=dynamodb_table)
        service = TeamService(repository=repository)
        request = CreateTeamRequest(
            name="Engineering",
            description="Engineering team"
        )

        # When
        team = service.create_team(
            org_id=sample_org_id,
            request=request,
            created_by="admin@example.com"
        )

        # Then
        assert team.name == "Engineering"
        assert team.organisation_id == sample_org_id
        assert team.active is True

    @mock_aws
    def test_create_team_validation_error(self, dynamodb_table, sample_org_id):
        """Test create team with invalid name."""
        # Given
        repository = TeamRepository(dynamodb_resource=dynamodb_table)
        service = TeamService(repository=repository)
        request = CreateTeamRequest(name="A")  # Too short

        # When/Then
        with pytest.raises(ValidationException):
            service.create_team(
                org_id=sample_org_id,
                request=request,
                created_by="admin@example.com"
            )

    @mock_aws
    def test_create_team_duplicate_name_error(self, dynamodb_table, sample_org_id):
        """Test create team with duplicate name."""
        # Given
        repository = TeamRepository(dynamodb_resource=dynamodb_table)
        service = TeamService(repository=repository)
        request = CreateTeamRequest(name="Engineering")

        # Create first team
        service.create_team(
            org_id=sample_org_id,
            request=request,
            created_by="admin@example.com"
        )

        # When/Then - try to create duplicate
        with pytest.raises(DuplicateTeamNameException):
            service.create_team(
                org_id=sample_org_id,
                request=request,
                created_by="admin@example.com"
            )

    @mock_aws
    def test_get_team_success(self, dynamodb_table, sample_org_id):
        """Test successfully getting a team."""
        # Given
        repository = TeamRepository(dynamodb_resource=dynamodb_table)
        service = TeamService(repository=repository)
        request = CreateTeamRequest(name="Engineering")
        created_team = service.create_team(
            org_id=sample_org_id,
            request=request,
            created_by="admin@example.com"
        )

        # When
        team = service.get_team(sample_org_id, created_team.team_id)

        # Then
        assert team.team_id == created_team.team_id
        assert team.name == "Engineering"

    @mock_aws
    def test_get_team_not_found(self, dynamodb_table, sample_org_id):
        """Test get team that doesn't exist."""
        # Given
        repository = TeamRepository(dynamodb_resource=dynamodb_table)
        service = TeamService(repository=repository)

        # When/Then
        with pytest.raises(TeamNotFoundException):
            service.get_team(sample_org_id, "nonexistent-team-id")

    @mock_aws
    def test_list_teams_success(self, dynamodb_table, sample_org_id):
        """Test listing teams."""
        # Given
        repository = TeamRepository(dynamodb_resource=dynamodb_table)
        service = TeamService(repository=repository)

        # Create multiple teams
        for name in ["Engineering", "Marketing", "Sales"]:
            service.create_team(
                org_id=sample_org_id,
                request=CreateTeamRequest(name=name),
                created_by="admin@example.com"
            )

        # When
        teams, next_token, count = service.list_teams(sample_org_id)

        # Then
        assert count == 3
        assert len(teams) == 3

    @mock_aws
    def test_list_teams_excludes_inactive(self, dynamodb_table, sample_org_id):
        """Test that inactive teams are excluded by default."""
        # Given
        repository = TeamRepository(dynamodb_resource=dynamodb_table)
        service = TeamService(repository=repository)

        # Create teams
        team1 = service.create_team(
            org_id=sample_org_id,
            request=CreateTeamRequest(name="Active Team"),
            created_by="admin@example.com"
        )
        team2 = service.create_team(
            org_id=sample_org_id,
            request=CreateTeamRequest(name="Inactive Team"),
            created_by="admin@example.com"
        )

        # Deactivate one team
        service.deactivate_team(sample_org_id, team2.team_id, "admin@example.com")

        # When
        teams, _, count = service.list_teams(sample_org_id, include_inactive=False)

        # Then
        assert count == 1
        assert teams[0].name == "Active Team"

    @mock_aws
    def test_update_team_success(self, dynamodb_table, sample_org_id):
        """Test updating a team."""
        # Given
        repository = TeamRepository(dynamodb_resource=dynamodb_table)
        service = TeamService(repository=repository)
        team = service.create_team(
            org_id=sample_org_id,
            request=CreateTeamRequest(name="Old Name"),
            created_by="admin@example.com"
        )

        # When
        request = UpdateTeamRequest(name="New Name", description="Updated")
        updated = service.update_team(
            org_id=sample_org_id,
            team_id=team.team_id,
            request=request,
            updated_by="editor@example.com"
        )

        # Then
        assert updated.name == "New Name"
        assert updated.description == "Updated"
        assert updated.last_updated_by == "editor@example.com"
```

### 7.6 tests/unit/test_services/test_team_role_service.py

```python
"""
Unit Tests for Team Role Service.
"""
import pytest
from moto import mock_aws

from src.services.team_role_service import TeamRoleService
from src.repositories.team_role_repository import TeamRoleRepository
from src.repositories.team_member_repository import TeamMemberRepository
from src.models.requests import CreateTeamRoleRequest, UpdateTeamRoleRequest
from src.models.capabilities import TeamRoleCapability
from src.exceptions.team_exceptions import (
    TeamRoleNotFoundException,
    DuplicateRoleNameException,
    ValidationException,
    InvalidCapabilityException
)


class TestTeamRoleService:
    """Test cases for TeamRoleService."""

    @mock_aws
    def test_create_role_success(self, dynamodb_table, sample_org_id):
        """Test successfully creating a team role."""
        # Given
        repository = TeamRoleRepository(dynamodb_resource=dynamodb_table)
        service = TeamRoleService(repository=repository)
        request = CreateTeamRoleRequest(
            name="ARCHITECT",
            display_name="Architect",
            capabilities=[
                TeamRoleCapability.CAN_VIEW_MEMBERS.value,
                TeamRoleCapability.CAN_VIEW_SITES.value
            ],
            sort_order=50
        )

        # When
        role = service.create_role(
            org_id=sample_org_id,
            request=request,
            created_by="admin@example.com"
        )

        # Then
        assert role.name == "ARCHITECT"
        assert role.display_name == "Architect"
        assert len(role.capabilities) == 2
        assert role.is_default is False

    @mock_aws
    def test_create_role_invalid_capability(self, dynamodb_table, sample_org_id):
        """Test create role with invalid capability."""
        # Given
        repository = TeamRoleRepository(dynamodb_resource=dynamodb_table)
        service = TeamRoleService(repository=repository)
        request = CreateTeamRoleRequest(
            name="ROLE",
            display_name="Role",
            capabilities=["INVALID_CAPABILITY"]
        )

        # When/Then
        with pytest.raises(InvalidCapabilityException):
            service.create_role(
                org_id=sample_org_id,
                request=request,
                created_by="admin@example.com"
            )

    @mock_aws
    def test_seed_default_roles(self, dynamodb_table, sample_org_id):
        """Test seeding default roles for an organisation."""
        # Given
        repository = TeamRoleRepository(dynamodb_resource=dynamodb_table)
        service = TeamRoleService(repository=repository)

        # When
        roles = service.seed_default_roles(
            org_id=sample_org_id,
            created_by="system"
        )

        # Then
        assert len(roles) == 4
        role_names = [r.name for r in roles]
        assert "TEAM_LEAD" in role_names
        assert "SENIOR_MEMBER" in role_names
        assert "MEMBER" in role_names
        assert "VIEWER" in role_names

        # Verify all are marked as default
        for role in roles:
            assert role.is_default is True

    @mock_aws
    def test_get_role_success(self, dynamodb_table, sample_org_id):
        """Test getting a role by ID."""
        # Given
        repository = TeamRoleRepository(dynamodb_resource=dynamodb_table)
        service = TeamRoleService(repository=repository)
        request = CreateTeamRoleRequest(
            name="ROLE",
            display_name="Role",
            capabilities=[TeamRoleCapability.CAN_VIEW_MEMBERS.value]
        )
        created = service.create_role(
            org_id=sample_org_id,
            request=request,
            created_by="admin@example.com"
        )

        # When
        role = service.get_role(sample_org_id, created.team_role_id)

        # Then
        assert role.team_role_id == created.team_role_id
        assert role.name == "ROLE"

    @mock_aws
    def test_get_role_not_found(self, dynamodb_table, sample_org_id):
        """Test get role that doesn't exist."""
        # Given
        repository = TeamRoleRepository(dynamodb_resource=dynamodb_table)
        service = TeamRoleService(repository=repository)

        # When/Then
        with pytest.raises(TeamRoleNotFoundException):
            service.get_role(sample_org_id, "nonexistent-role-id")

    @mock_aws
    def test_list_roles_defaults_only(self, dynamodb_table, sample_org_id):
        """Test listing only default roles."""
        # Given
        repository = TeamRoleRepository(dynamodb_resource=dynamodb_table)
        service = TeamRoleService(repository=repository)

        # Seed defaults
        service.seed_default_roles(sample_org_id, "system")

        # Create custom role
        service.create_role(
            org_id=sample_org_id,
            request=CreateTeamRoleRequest(
                name="CUSTOM",
                display_name="Custom",
                capabilities=[TeamRoleCapability.CAN_VIEW_MEMBERS.value]
            ),
            created_by="admin@example.com"
        )

        # When - get defaults only
        roles, _, count = service.list_roles(
            sample_org_id,
            defaults_only=True
        )

        # Then
        assert count == 4
        for role in roles:
            assert role.is_default is True

    @mock_aws
    def test_update_role_success(self, dynamodb_table, sample_org_id):
        """Test updating a role."""
        # Given
        repository = TeamRoleRepository(dynamodb_resource=dynamodb_table)
        service = TeamRoleService(repository=repository)
        role = service.create_role(
            org_id=sample_org_id,
            request=CreateTeamRoleRequest(
                name="ROLE",
                display_name="Old Display",
                capabilities=[TeamRoleCapability.CAN_VIEW_MEMBERS.value]
            ),
            created_by="admin@example.com"
        )

        # When
        updated = service.update_role(
            org_id=sample_org_id,
            role_id=role.team_role_id,
            request=UpdateTeamRoleRequest(
                display_name="New Display",
                capabilities=[
                    TeamRoleCapability.CAN_VIEW_MEMBERS.value,
                    TeamRoleCapability.CAN_EDIT_SITES.value
                ]
            ),
            updated_by="admin@example.com"
        )

        # Then
        assert updated.display_name == "New Display"
        assert len(updated.capabilities) == 2
```

### 7.7 tests/unit/test_services/test_team_member_service.py

```python
"""
Unit Tests for Team Member Service.
"""
import pytest
from moto import mock_aws

from src.services.team_member_service import TeamMemberService
from src.services.team_service import TeamService
from src.services.team_role_service import TeamRoleService
from src.repositories.team_repository import TeamRepository
from src.repositories.team_role_repository import TeamRoleRepository
from src.repositories.team_member_repository import TeamMemberRepository
from src.models.requests import (
    CreateTeamRequest,
    AddMemberRequest,
    UpdateMemberRequest
)
from src.exceptions.team_exceptions import (
    MemberNotFoundException,
    UserAlreadyMemberException,
    CannotRemoveLastLeadException
)


class TestTeamMemberService:
    """Test cases for TeamMemberService."""

    @mock_aws
    def test_add_member_success(self, dynamodb_table, sample_org_id, sample_user_id):
        """Test successfully adding a member to a team."""
        # Given
        team_repo = TeamRepository(dynamodb_resource=dynamodb_table)
        role_repo = TeamRoleRepository(dynamodb_resource=dynamodb_table)
        member_repo = TeamMemberRepository(dynamodb_resource=dynamodb_table)

        team_service = TeamService(repository=team_repo)
        role_service = TeamRoleService(repository=role_repo)
        member_service = TeamMemberService(
            repository=member_repo,
            team_service=team_service,
            role_service=role_service
        )

        # Create team and seed roles
        team = team_service.create_team(
            org_id=sample_org_id,
            request=CreateTeamRequest(name="Engineering"),
            created_by="admin@example.com"
        )
        roles = role_service.seed_default_roles(sample_org_id, "system")
        member_role = next(r for r in roles if r.name == "MEMBER")

        # When
        member = member_service.add_member(
            org_id=sample_org_id,
            team_id=team.team_id,
            request=AddMemberRequest(
                user_id=sample_user_id,
                team_role_id=member_role.team_role_id
            ),
            added_by="admin@example.com",
            user_email="user@example.com",
            user_first_name="John",
            user_last_name="Doe"
        )

        # Then
        assert member.user_id == sample_user_id
        assert member.team_id == team.team_id
        assert member.team_role_id == member_role.team_role_id
        assert member.user_email == "user@example.com"

    @mock_aws
    def test_add_member_already_member(self, dynamodb_table, sample_org_id, sample_user_id):
        """Test adding a user who is already a member."""
        # Given
        team_repo = TeamRepository(dynamodb_resource=dynamodb_table)
        role_repo = TeamRoleRepository(dynamodb_resource=dynamodb_table)
        member_repo = TeamMemberRepository(dynamodb_resource=dynamodb_table)

        team_service = TeamService(repository=team_repo)
        role_service = TeamRoleService(repository=role_repo)
        member_service = TeamMemberService(
            repository=member_repo,
            team_service=team_service,
            role_service=role_service
        )

        team = team_service.create_team(
            org_id=sample_org_id,
            request=CreateTeamRequest(name="Engineering"),
            created_by="admin@example.com"
        )
        roles = role_service.seed_default_roles(sample_org_id, "system")
        member_role = next(r for r in roles if r.name == "MEMBER")

        # Add member first time
        member_service.add_member(
            org_id=sample_org_id,
            team_id=team.team_id,
            request=AddMemberRequest(
                user_id=sample_user_id,
                team_role_id=member_role.team_role_id
            ),
            added_by="admin@example.com"
        )

        # When/Then - try to add again
        with pytest.raises(UserAlreadyMemberException):
            member_service.add_member(
                org_id=sample_org_id,
                team_id=team.team_id,
                request=AddMemberRequest(
                    user_id=sample_user_id,
                    team_role_id=member_role.team_role_id
                ),
                added_by="admin@example.com"
            )

    @mock_aws
    def test_get_member_success(self, dynamodb_table, sample_org_id, sample_user_id):
        """Test getting a team member."""
        # Given - setup services and add member
        team_repo = TeamRepository(dynamodb_resource=dynamodb_table)
        role_repo = TeamRoleRepository(dynamodb_resource=dynamodb_table)
        member_repo = TeamMemberRepository(dynamodb_resource=dynamodb_table)

        team_service = TeamService(repository=team_repo)
        role_service = TeamRoleService(repository=role_repo)
        member_service = TeamMemberService(
            repository=member_repo,
            team_service=team_service,
            role_service=role_service
        )

        team = team_service.create_team(
            org_id=sample_org_id,
            request=CreateTeamRequest(name="Engineering"),
            created_by="admin@example.com"
        )
        roles = role_service.seed_default_roles(sample_org_id, "system")
        member_role = next(r for r in roles if r.name == "MEMBER")

        added_member = member_service.add_member(
            org_id=sample_org_id,
            team_id=team.team_id,
            request=AddMemberRequest(
                user_id=sample_user_id,
                team_role_id=member_role.team_role_id
            ),
            added_by="admin@example.com"
        )

        # When
        member = member_service.get_member(
            sample_org_id,
            team.team_id,
            sample_user_id
        )

        # Then
        assert member.user_id == sample_user_id

    @mock_aws
    def test_get_member_not_found(self, dynamodb_table, sample_org_id, sample_team_id):
        """Test get member that doesn't exist."""
        # Given
        member_repo = TeamMemberRepository(dynamodb_resource=dynamodb_table)
        member_service = TeamMemberService(repository=member_repo)

        # When/Then
        with pytest.raises(MemberNotFoundException):
            member_service.get_member(
                sample_org_id,
                sample_team_id,
                "nonexistent-user"
            )

    @mock_aws
    def test_list_members_success(self, dynamodb_table, sample_org_id):
        """Test listing team members."""
        # Given
        team_repo = TeamRepository(dynamodb_resource=dynamodb_table)
        role_repo = TeamRoleRepository(dynamodb_resource=dynamodb_table)
        member_repo = TeamMemberRepository(dynamodb_resource=dynamodb_table)

        team_service = TeamService(repository=team_repo)
        role_service = TeamRoleService(repository=role_repo)
        member_service = TeamMemberService(
            repository=member_repo,
            team_service=team_service,
            role_service=role_service
        )

        team = team_service.create_team(
            org_id=sample_org_id,
            request=CreateTeamRequest(name="Engineering"),
            created_by="admin@example.com"
        )
        roles = role_service.seed_default_roles(sample_org_id, "system")
        member_role = next(r for r in roles if r.name == "MEMBER")

        # Add multiple members
        for i in range(3):
            member_service.add_member(
                org_id=sample_org_id,
                team_id=team.team_id,
                request=AddMemberRequest(
                    user_id=f"user-{i}",
                    team_role_id=member_role.team_role_id
                ),
                added_by="admin@example.com"
            )

        # When
        members, _, count = member_service.list_members(
            sample_org_id,
            team.team_id
        )

        # Then
        assert count == 3

    @mock_aws
    def test_get_user_teams(self, dynamodb_table, sample_org_id, sample_user_id):
        """Test getting all teams for a user."""
        # Given
        team_repo = TeamRepository(dynamodb_resource=dynamodb_table)
        role_repo = TeamRoleRepository(dynamodb_resource=dynamodb_table)
        member_repo = TeamMemberRepository(dynamodb_resource=dynamodb_table)

        team_service = TeamService(repository=team_repo)
        role_service = TeamRoleService(repository=role_repo)
        member_service = TeamMemberService(
            repository=member_repo,
            team_service=team_service,
            role_service=role_service
        )

        roles = role_service.seed_default_roles(sample_org_id, "system")
        member_role = next(r for r in roles if r.name == "MEMBER")

        # Create multiple teams and add user to each
        for name in ["Engineering", "Marketing"]:
            team = team_service.create_team(
                org_id=sample_org_id,
                request=CreateTeamRequest(name=name),
                created_by="admin@example.com"
            )
            member_service.add_member(
                org_id=sample_org_id,
                team_id=team.team_id,
                request=AddMemberRequest(
                    user_id=sample_user_id,
                    team_role_id=member_role.team_role_id
                ),
                added_by="admin@example.com"
            )

        # When
        memberships = member_service.get_user_teams(sample_org_id, sample_user_id)

        # Then
        assert len(memberships) == 2
        team_names = [m.team_name for m in memberships]
        assert "Engineering" in team_names
        assert "Marketing" in team_names

    @mock_aws
    def test_update_member_role(self, dynamodb_table, sample_org_id, sample_user_id):
        """Test updating a member's role."""
        # Given
        team_repo = TeamRepository(dynamodb_resource=dynamodb_table)
        role_repo = TeamRoleRepository(dynamodb_resource=dynamodb_table)
        member_repo = TeamMemberRepository(dynamodb_resource=dynamodb_table)

        team_service = TeamService(repository=team_repo)
        role_service = TeamRoleService(repository=role_repo)
        member_service = TeamMemberService(
            repository=member_repo,
            team_service=team_service,
            role_service=role_service
        )

        team = team_service.create_team(
            org_id=sample_org_id,
            request=CreateTeamRequest(name="Engineering"),
            created_by="admin@example.com"
        )
        roles = role_service.seed_default_roles(sample_org_id, "system")
        member_role = next(r for r in roles if r.name == "MEMBER")
        senior_role = next(r for r in roles if r.name == "SENIOR_MEMBER")

        member_service.add_member(
            org_id=sample_org_id,
            team_id=team.team_id,
            request=AddMemberRequest(
                user_id=sample_user_id,
                team_role_id=member_role.team_role_id
            ),
            added_by="admin@example.com"
        )

        # When
        updated = member_service.update_member(
            org_id=sample_org_id,
            team_id=team.team_id,
            user_id=sample_user_id,
            request=UpdateMemberRequest(team_role_id=senior_role.team_role_id),
            updated_by="admin@example.com"
        )

        # Then
        assert updated.team_role_id == senior_role.team_role_id
        assert updated.team_role_name == "Senior Member"
```

---

## 8. Configuration

### 8.1 requirements.txt

```txt
boto3>=1.34.0
aws-lambda-powertools>=2.30.0
pydantic>=2.0.0
```

### 8.2 requirements-dev.txt

```txt
-r requirements.txt
pytest>=7.4.0
pytest-cov>=4.1.0
moto[dynamodb]>=5.0.0
black>=23.0.0
flake8>=6.0.0
mypy>=1.0.0
```

### 8.3 pytest.ini

```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_functions = test_*
python_classes = Test*
addopts = -v --cov=src --cov-report=term-missing --cov-report=html
filterwarnings =
    ignore::DeprecationWarning
env =
    AWS_DEFAULT_REGION=af-south-1
    DYNAMODB_TABLE_NAME=bbws-aipagebuilder-dev-ddb-access-management
```

---

## Summary

This implementation provides:

### Models (3)
1. **Team** - Team entity with full CRUD support
2. **TeamRoleDefinition** - Configurable team roles with capabilities
3. **TeamMember** - Team membership with denormalized user info

### Capabilities (7)
- CAN_MANAGE_MEMBERS
- CAN_UPDATE_TEAM
- CAN_VIEW_MEMBERS
- CAN_VIEW_SITES
- CAN_EDIT_SITES
- CAN_DELETE_SITES
- CAN_VIEW_AUDIT

### Default Team Roles (4)
1. **TEAM_LEAD** - Full management capabilities
2. **SENIOR_MEMBER** - View and edit capabilities
3. **MEMBER** - View only capabilities
4. **VIEWER** - Minimal read-only access

### Lambda Handlers (14)
**Team Operations (4)**
- create_team
- list_teams
- get_team
- update_team

**Team Role Operations (5)**
- create_team_role
- list_team_roles
- get_team_role
- update_team_role
- delete_team_role

**Member Operations (5)**
- add_member
- list_members
- get_member
- update_member
- get_user_teams

### Test Coverage
- Unit tests for all models
- Service integration tests with moto
- Test fixtures for DynamoDB mocking
- TDD approach followed throughout

---

**Document Status**: COMPLETE
**Generated**: 2026-01-23
**Worker**: worker-3-team-service-lambdas
