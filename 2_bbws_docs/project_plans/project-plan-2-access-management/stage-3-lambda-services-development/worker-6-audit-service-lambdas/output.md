# Worker 6 Output: Audit Service Lambda Functions

**Worker ID**: worker-6-audit-service-lambdas
**Stage**: Stage 3 - Lambda Services Development
**Project**: project-plan-2-access-management
**Created**: 2026-01-23
**Status**: COMPLETE

---

## 1. Project Structure

```
lambda/audit_service/
├── __init__.py
├── models/
│   ├── __init__.py
│   ├── audit_event.py
│   ├── enums.py
│   └── requests.py
├── repositories/
│   ├── __init__.py
│   ├── audit_repository.py
│   └── s3_repository.py
├── services/
│   ├── __init__.py
│   ├── audit_logger.py
│   ├── audit_query_service.py
│   ├── audit_export_service.py
│   └── audit_archive_service.py
├── handlers/
│   ├── __init__.py
│   ├── query_org_handler.py
│   ├── query_user_handler.py
│   ├── query_resource_handler.py
│   ├── summary_handler.py
│   ├── export_handler.py
│   └── archive_handler.py
├── utils/
│   ├── __init__.py
│   ├── response_builder.py
│   └── csv_generator.py
└── tests/
    ├── __init__.py
    ├── conftest.py
    ├── test_models.py
    ├── test_audit_logger.py
    ├── test_audit_repository.py
    ├── test_query_handlers.py
    ├── test_export_handler.py
    └── test_archive_handler.py
```

---

## 2. Enums and Constants

### 2.1 models/enums.py

```python
"""
Audit Service Enums and Constants.
Defines event types, outcomes, storage tiers, and retention policies.
"""
from enum import Enum


class AuditEventType(str, Enum):
    """Types of audit events captured by the system."""
    AUTHORIZATION = "AUTHORIZATION"
    PERMISSION_CHANGE = "PERMISSION_CHANGE"
    USER_MANAGEMENT = "USER_MANAGEMENT"
    TEAM_MEMBERSHIP = "TEAM_MEMBERSHIP"
    ROLE_CHANGE = "ROLE_CHANGE"
    INVITATION = "INVITATION"
    CONFIGURATION = "CONFIGURATION"


class AuditOutcome(str, Enum):
    """Outcome of an audited action."""
    SUCCESS = "SUCCESS"
    FAILURE = "FAILURE"
    DENIED = "DENIED"


class ActorType(str, Enum):
    """Type of actor performing the action."""
    USER = "USER"
    SYSTEM = "SYSTEM"


class StorageTier(str, Enum):
    """Storage tier for audit events."""
    HOT = "HOT"      # DynamoDB, 0-30 days
    WARM = "WARM"    # S3 Standard, 31-90 days
    COLD = "COLD"    # S3 Glacier, 91+ days


class ExportFormat(str, Enum):
    """Supported export formats."""
    CSV = "csv"
    JSON = "json"


# Retention Configuration
HOT_RETENTION_DAYS = 30
WARM_RETENTION_DAYS = 90
COLD_RETENTION_YEARS = 7

# Presigned URL expiry (24 hours in seconds)
PRESIGNED_URL_EXPIRY_SECONDS = 86400

# Pagination defaults
DEFAULT_PAGE_SIZE = 50
MAX_PAGE_SIZE = 100
```

---

## 3. Audit Event Model

### 3.1 models/audit_event.py

```python
"""
Audit Event Model.
Core data model for audit events with DynamoDB key construction.
"""
import uuid
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from dataclasses import dataclass, field, asdict

from .enums import (
    AuditEventType,
    AuditOutcome,
    ActorType,
    HOT_RETENTION_DAYS
)


@dataclass
class AuditEvent:
    """
    Represents an audit event in the system.

    Attributes:
        event_id: Unique identifier for the event
        event_type: Category of the audit event
        timestamp: When the event occurred
        org_id: Organisation the event belongs to
        actor_id: ID of the user/system performing the action
        actor_type: Whether actor is USER or SYSTEM
        action: The action performed (e.g., create, update, delete)
        resource_type: Type of resource affected
        resource_id: ID of the affected resource
        details: Additional event-specific information
        outcome: Result of the action
        ip_address: Client IP address (optional)
        user_agent: Client user agent (optional)
        request_id: API Gateway request ID (optional)
        user_email: Email of the acting user (optional)
    """
    event_type: AuditEventType
    org_id: str
    actor_id: str
    action: str
    resource_type: str
    resource_id: str
    outcome: AuditOutcome = AuditOutcome.SUCCESS
    event_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    timestamp: datetime = field(default_factory=datetime.utcnow)
    actor_type: ActorType = ActorType.USER
    details: Dict[str, Any] = field(default_factory=dict)
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    request_id: Optional[str] = None
    user_email: Optional[str] = None
    ttl: Optional[int] = None

    def __post_init__(self):
        """Set TTL if not provided."""
        if self.ttl is None:
            expiry = datetime.utcnow() + timedelta(days=HOT_RETENTION_DAYS)
            self.ttl = int(expiry.timestamp())

    @property
    def pk(self) -> str:
        """Primary key for DynamoDB table."""
        date_str = self.timestamp.strftime("%Y-%m-%d")
        return f"ORG#{self.org_id}#DATE#{date_str}"

    @property
    def sk(self) -> str:
        """Sort key for DynamoDB table."""
        ts = self.timestamp.isoformat()
        return f"EVENT#{ts}#{self.event_id}"

    @property
    def gsi1pk(self) -> str:
        """GSI1 partition key for user queries."""
        return f"USER#{self.actor_id}"

    @property
    def gsi1sk(self) -> str:
        """GSI1 sort key for user queries."""
        ts = self.timestamp.isoformat()
        return f"{ts}#{self.event_id}"

    @property
    def gsi2pk(self) -> str:
        """GSI2 partition key for event type queries."""
        return f"ORG#{self.org_id}#TYPE#{self.event_type.value}"

    @property
    def gsi2sk(self) -> str:
        """GSI2 sort key for event type queries."""
        ts = self.timestamp.isoformat()
        return f"{ts}#{self.event_id}"

    @property
    def gsi3pk(self) -> str:
        """GSI3 partition key for resource queries."""
        return f"RESOURCE#{self.resource_type}#{self.resource_id}"

    @property
    def gsi3sk(self) -> str:
        """GSI3 sort key for resource queries."""
        ts = self.timestamp.isoformat()
        return f"{ts}#{self.event_id}"

    def to_dynamodb_item(self) -> Dict[str, Any]:
        """Convert to DynamoDB item format."""
        return {
            "PK": self.pk,
            "SK": self.sk,
            "GSI1PK": self.gsi1pk,
            "GSI1SK": self.gsi1sk,
            "GSI2PK": self.gsi2pk,
            "GSI2SK": self.gsi2sk,
            "GSI3PK": self.gsi3pk,
            "GSI3SK": self.gsi3sk,
            "eventId": self.event_id,
            "eventType": self.event_type.value,
            "timestamp": self.timestamp.isoformat(),
            "orgId": self.org_id,
            "actorId": self.actor_id,
            "actorType": self.actor_type.value,
            "action": self.action,
            "resourceType": self.resource_type,
            "resourceId": self.resource_id,
            "details": self.details,
            "outcome": self.outcome.value,
            "ipAddress": self.ip_address,
            "userAgent": self.user_agent,
            "requestId": self.request_id,
            "userEmail": self.user_email,
            "ttl": self.ttl,
            "entityType": "AUDIT_EVENT"
        }

    @classmethod
    def from_dynamodb_item(cls, item: Dict[str, Any]) -> "AuditEvent":
        """Create AuditEvent from DynamoDB item."""
        return cls(
            event_id=item["eventId"],
            event_type=AuditEventType(item["eventType"]),
            timestamp=datetime.fromisoformat(item["timestamp"]),
            org_id=item["orgId"],
            actor_id=item["actorId"],
            actor_type=ActorType(item.get("actorType", "USER")),
            action=item["action"],
            resource_type=item["resourceType"],
            resource_id=item["resourceId"],
            details=item.get("details", {}),
            outcome=AuditOutcome(item["outcome"]),
            ip_address=item.get("ipAddress"),
            user_agent=item.get("userAgent"),
            request_id=item.get("requestId"),
            user_email=item.get("userEmail"),
            ttl=item.get("ttl")
        )

    def to_api_response(self) -> Dict[str, Any]:
        """Convert to API response format."""
        return {
            "id": self.event_id,
            "eventType": self.event_type.value,
            "timestamp": self.timestamp.isoformat(),
            "orgId": self.org_id,
            "actorId": self.actor_id,
            "actorType": self.actor_type.value,
            "action": self.action,
            "resourceType": self.resource_type,
            "resourceId": self.resource_id,
            "details": self.details,
            "outcome": self.outcome.value,
            "ipAddress": self.ip_address,
            "userEmail": self.user_email
        }
```

---

## 4. Request Models

### 4.1 models/requests.py

```python
"""
Request Models for Audit Service.
Defines filter and request objects for queries and exports.
"""
from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional, List

from .enums import AuditEventType, AuditOutcome, ExportFormat


@dataclass
class DateRange:
    """Date range for filtering queries."""
    start_date: datetime
    end_date: datetime

    def __post_init__(self):
        """Validate date range."""
        if self.start_date > self.end_date:
            raise ValueError("start_date must be before end_date")


@dataclass
class PaginationParams:
    """Pagination parameters."""
    page_size: int = 50
    start_at: Optional[str] = None

    def __post_init__(self):
        """Validate page size."""
        if self.page_size < 1:
            self.page_size = 1
        elif self.page_size > 100:
            self.page_size = 100


@dataclass
class OrgAuditFilters:
    """Filters for organisation audit queries."""
    org_id: str
    date_range: DateRange
    event_types: Optional[List[AuditEventType]] = None
    user_id: Optional[str] = None
    resource_type: Optional[str] = None
    outcome: Optional[AuditOutcome] = None


@dataclass
class UserAuditFilters:
    """Filters for user audit queries."""
    org_id: str
    user_id: str
    date_range: DateRange
    event_types: Optional[List[AuditEventType]] = None


@dataclass
class ResourceAuditFilters:
    """Filters for resource audit queries."""
    org_id: str
    resource_type: str
    resource_id: str
    date_range: DateRange


@dataclass
class SummaryFilters:
    """Filters for audit summary."""
    org_id: str
    date_range: DateRange


@dataclass
class ExportRequest:
    """Request for audit log export."""
    org_id: str
    date_range: DateRange
    event_types: Optional[List[AuditEventType]] = None
    format: ExportFormat = ExportFormat.JSON


@dataclass
class ExportResult:
    """Result of audit log export."""
    export_id: str
    s3_key: str
    download_url: str
    expires_at: datetime
    record_count: int

    def to_api_response(self) -> dict:
        """Convert to API response."""
        return {
            "exportId": self.export_id,
            "s3Key": self.s3_key,
            "downloadUrl": self.download_url,
            "expiresAt": self.expires_at.isoformat(),
            "recordCount": self.record_count
        }


@dataclass
class AuditSummary:
    """Summary statistics for audit logs."""
    total_events: int = 0
    authorization_events: int = 0
    permission_changes: int = 0
    user_management_events: int = 0
    allowed_requests: int = 0
    denied_requests: int = 0
    failed_requests: int = 0
    events_by_type: dict = field(default_factory=dict)
    events_by_user: dict = field(default_factory=dict)
    events_by_day: dict = field(default_factory=dict)

    def to_api_response(self) -> dict:
        """Convert to API response."""
        return {
            "totalEvents": self.total_events,
            "authorizationEvents": self.authorization_events,
            "permissionChanges": self.permission_changes,
            "userManagementEvents": self.user_management_events,
            "allowedRequests": self.allowed_requests,
            "deniedRequests": self.denied_requests,
            "failedRequests": self.failed_requests,
            "eventsByType": self.events_by_type,
            "eventsByUser": self.events_by_user,
            "eventsByDay": self.events_by_day
        }


@dataclass
class PaginatedResult:
    """Paginated query result."""
    items: List
    count: int
    more_available: bool
    next_token: Optional[str] = None

    def to_api_response(self) -> dict:
        """Convert to API response."""
        response = {
            "items": [item.to_api_response() for item in self.items],
            "count": self.count,
            "moreAvailable": self.more_available
        }
        if self.next_token:
            response["nextToken"] = self.next_token
        return response
```

---

## 5. Audit Repository

### 5.1 repositories/audit_repository.py

```python
"""
Audit Repository.
Handles DynamoDB operations for audit events.
"""
import os
import json
import base64
import logging
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any, Tuple

import boto3
from boto3.dynamodb.conditions import Key, Attr
from botocore.exceptions import ClientError

from ..models.audit_event import AuditEvent
from ..models.enums import AuditEventType, AuditOutcome
from ..models.requests import (
    OrgAuditFilters,
    UserAuditFilters,
    ResourceAuditFilters,
    PaginationParams,
    PaginatedResult,
    AuditSummary,
    DateRange
)

logger = logging.getLogger(__name__)


class AuditRepository:
    """
    Repository for audit event persistence and retrieval.

    Uses DynamoDB single-table design with GSIs for efficient queries.
    """

    def __init__(self, table_name: Optional[str] = None, dynamodb_resource=None):
        """
        Initialize the repository.

        Args:
            table_name: DynamoDB table name (defaults to env var)
            dynamodb_resource: Optional boto3 DynamoDB resource for testing
        """
        self.table_name = table_name or os.environ.get(
            "DYNAMODB_TABLE_NAME",
            "bbws-aipagebuilder-dev-ddb-access-management"
        )
        self.dynamodb = dynamodb_resource or boto3.resource("dynamodb")
        self.table = self.dynamodb.Table(self.table_name)

    def save(self, event: AuditEvent) -> None:
        """
        Save an audit event to DynamoDB.

        Args:
            event: The audit event to save

        Raises:
            ClientError: If DynamoDB operation fails
        """
        try:
            item = event.to_dynamodb_item()
            # Remove None values
            item = {k: v for k, v in item.items() if v is not None}
            self.table.put_item(Item=item)
            logger.info(f"Saved audit event: {event.event_id}")
        except ClientError as e:
            logger.error(f"Failed to save audit event: {e}")
            raise

    def save_batch(self, events: List[AuditEvent]) -> None:
        """
        Save multiple audit events in batch.

        Args:
            events: List of audit events to save
        """
        try:
            with self.table.batch_writer() as batch:
                for event in events:
                    item = event.to_dynamodb_item()
                    item = {k: v for k, v in item.items() if v is not None}
                    batch.put_item(Item=item)
            logger.info(f"Batch saved {len(events)} audit events")
        except ClientError as e:
            logger.error(f"Failed to batch save audit events: {e}")
            raise

    def query_by_org(
        self,
        filters: OrgAuditFilters,
        pagination: PaginationParams
    ) -> PaginatedResult:
        """
        Query audit events by organisation.

        Args:
            filters: Query filters including org_id and date range
            pagination: Pagination parameters

        Returns:
            PaginatedResult with matching events
        """
        events = []
        last_evaluated_key = None

        # Decode pagination token if provided
        if pagination.start_at:
            try:
                last_evaluated_key = json.loads(
                    base64.b64decode(pagination.start_at).decode()
                )
            except Exception:
                last_evaluated_key = None

        # Query each day in the date range
        current_date = filters.date_range.start_date.date()
        end_date = filters.date_range.end_date.date()

        while current_date <= end_date and len(events) < pagination.page_size:
            pk = f"ORG#{filters.org_id}#DATE#{current_date.isoformat()}"

            query_kwargs = {
                "KeyConditionExpression": Key("PK").eq(pk),
                "Limit": pagination.page_size - len(events),
                "ScanIndexForward": False  # Most recent first
            }

            if last_evaluated_key:
                query_kwargs["ExclusiveStartKey"] = last_evaluated_key
                last_evaluated_key = None

            # Add filter expressions
            filter_conditions = self._build_filter_conditions(filters)
            if filter_conditions:
                query_kwargs["FilterExpression"] = filter_conditions

            response = self.table.query(**query_kwargs)

            for item in response.get("Items", []):
                events.append(AuditEvent.from_dynamodb_item(item))

            if "LastEvaluatedKey" in response:
                last_evaluated_key = response["LastEvaluatedKey"]

            current_date += timedelta(days=1)

        # Build next token
        next_token = None
        if last_evaluated_key:
            next_token = base64.b64encode(
                json.dumps(last_evaluated_key).encode()
            ).decode()

        return PaginatedResult(
            items=events[:pagination.page_size],
            count=len(events[:pagination.page_size]),
            more_available=len(events) >= pagination.page_size or next_token is not None,
            next_token=next_token
        )

    def query_by_user(
        self,
        filters: UserAuditFilters,
        pagination: PaginationParams
    ) -> PaginatedResult:
        """
        Query audit events by user using GSI1.

        Args:
            filters: Query filters including user_id and date range
            pagination: Pagination parameters

        Returns:
            PaginatedResult with matching events
        """
        gsi1pk = f"USER#{filters.user_id}"
        start_sk = filters.date_range.start_date.isoformat()
        end_sk = filters.date_range.end_date.isoformat()

        query_kwargs = {
            "IndexName": "GSI1",
            "KeyConditionExpression": (
                Key("GSI1PK").eq(gsi1pk) &
                Key("GSI1SK").between(start_sk, end_sk + "Z")
            ),
            "Limit": pagination.page_size,
            "ScanIndexForward": False
        }

        if pagination.start_at:
            try:
                query_kwargs["ExclusiveStartKey"] = json.loads(
                    base64.b64decode(pagination.start_at).decode()
                )
            except Exception:
                pass

        # Filter by org_id to ensure user can only see their org's events
        query_kwargs["FilterExpression"] = Attr("orgId").eq(filters.org_id)

        response = self.table.query(**query_kwargs)

        events = [
            AuditEvent.from_dynamodb_item(item)
            for item in response.get("Items", [])
        ]

        next_token = None
        if "LastEvaluatedKey" in response:
            next_token = base64.b64encode(
                json.dumps(response["LastEvaluatedKey"]).encode()
            ).decode()

        return PaginatedResult(
            items=events,
            count=len(events),
            more_available="LastEvaluatedKey" in response,
            next_token=next_token
        )

    def query_by_resource(
        self,
        filters: ResourceAuditFilters,
        pagination: PaginationParams
    ) -> PaginatedResult:
        """
        Query audit events by resource using GSI3.

        Args:
            filters: Query filters including resource_type and resource_id
            pagination: Pagination parameters

        Returns:
            PaginatedResult with matching events
        """
        gsi3pk = f"RESOURCE#{filters.resource_type}#{filters.resource_id}"
        start_sk = filters.date_range.start_date.isoformat()
        end_sk = filters.date_range.end_date.isoformat()

        query_kwargs = {
            "IndexName": "GSI3",
            "KeyConditionExpression": (
                Key("GSI3PK").eq(gsi3pk) &
                Key("GSI3SK").between(start_sk, end_sk + "Z")
            ),
            "Limit": pagination.page_size,
            "ScanIndexForward": False
        }

        if pagination.start_at:
            try:
                query_kwargs["ExclusiveStartKey"] = json.loads(
                    base64.b64decode(pagination.start_at).decode()
                )
            except Exception:
                pass

        # Filter by org_id
        query_kwargs["FilterExpression"] = Attr("orgId").eq(filters.org_id)

        response = self.table.query(**query_kwargs)

        events = [
            AuditEvent.from_dynamodb_item(item)
            for item in response.get("Items", [])
        ]

        next_token = None
        if "LastEvaluatedKey" in response:
            next_token = base64.b64encode(
                json.dumps(response["LastEvaluatedKey"]).encode()
            ).decode()

        return PaginatedResult(
            items=events,
            count=len(events),
            more_available="LastEvaluatedKey" in response,
            next_token=next_token
        )

    def get_summary(
        self,
        org_id: str,
        date_range: DateRange
    ) -> AuditSummary:
        """
        Get audit summary statistics for an organisation.

        Args:
            org_id: Organisation ID
            date_range: Date range for summary

        Returns:
            AuditSummary with statistics
        """
        summary = AuditSummary()

        current_date = date_range.start_date.date()
        end_date = date_range.end_date.date()

        while current_date <= end_date:
            pk = f"ORG#{org_id}#DATE#{current_date.isoformat()}"

            response = self.table.query(
                KeyConditionExpression=Key("PK").eq(pk),
                ProjectionExpression="eventType, outcome, actorId, #ts",
                ExpressionAttributeNames={"#ts": "timestamp"}
            )

            for item in response.get("Items", []):
                summary.total_events += 1

                event_type = item.get("eventType")
                outcome = item.get("outcome")
                actor_id = item.get("actorId")
                day = current_date.isoformat()

                # Count by type
                summary.events_by_type[event_type] = \
                    summary.events_by_type.get(event_type, 0) + 1

                # Count by user (top 10)
                if len(summary.events_by_user) < 10 or actor_id in summary.events_by_user:
                    summary.events_by_user[actor_id] = \
                        summary.events_by_user.get(actor_id, 0) + 1

                # Count by day
                summary.events_by_day[day] = \
                    summary.events_by_day.get(day, 0) + 1

                # Count specific types
                if event_type == AuditEventType.AUTHORIZATION.value:
                    summary.authorization_events += 1
                elif event_type == AuditEventType.PERMISSION_CHANGE.value:
                    summary.permission_changes += 1
                elif event_type == AuditEventType.USER_MANAGEMENT.value:
                    summary.user_management_events += 1

                # Count outcomes
                if outcome == AuditOutcome.SUCCESS.value:
                    summary.allowed_requests += 1
                elif outcome == AuditOutcome.DENIED.value:
                    summary.denied_requests += 1
                elif outcome == AuditOutcome.FAILURE.value:
                    summary.failed_requests += 1

            current_date += timedelta(days=1)

        return summary

    def query_events_before(
        self,
        cutoff_date: datetime,
        limit: int = 1000
    ) -> List[AuditEvent]:
        """
        Query events older than cutoff date for archiving.

        Args:
            cutoff_date: Events before this date will be returned
            limit: Maximum events to return

        Returns:
            List of audit events to archive
        """
        events = []
        cutoff_ttl = int(cutoff_date.timestamp())

        # Scan for events with TTL before cutoff
        scan_kwargs = {
            "FilterExpression": Attr("ttl").lt(cutoff_ttl) &
                               Attr("entityType").eq("AUDIT_EVENT"),
            "Limit": limit
        }

        response = self.table.scan(**scan_kwargs)

        for item in response.get("Items", []):
            events.append(AuditEvent.from_dynamodb_item(item))

        return events

    def delete_events(self, events: List[AuditEvent]) -> None:
        """
        Delete archived events from DynamoDB.

        Args:
            events: List of events to delete
        """
        with self.table.batch_writer() as batch:
            for event in events:
                batch.delete_item(
                    Key={
                        "PK": event.pk,
                        "SK": event.sk
                    }
                )
        logger.info(f"Deleted {len(events)} archived events")

    def _build_filter_conditions(self, filters: OrgAuditFilters):
        """Build DynamoDB filter expression from filters."""
        conditions = None

        if filters.event_types:
            type_values = [et.value for et in filters.event_types]
            conditions = Attr("eventType").is_in(type_values)

        if filters.user_id:
            user_cond = Attr("actorId").eq(filters.user_id)
            conditions = conditions & user_cond if conditions else user_cond

        if filters.resource_type:
            res_cond = Attr("resourceType").eq(filters.resource_type)
            conditions = conditions & res_cond if conditions else res_cond

        if filters.outcome:
            out_cond = Attr("outcome").eq(filters.outcome.value)
            conditions = conditions & out_cond if conditions else out_cond

        return conditions
```

---

## 6. S3 Repository

### 6.1 repositories/s3_repository.py

```python
"""
S3 Repository for Audit Service.
Handles S3 operations for exports and archives.
"""
import os
import gzip
import json
import logging
from datetime import datetime, timedelta
from typing import List, Optional

import boto3
from botocore.exceptions import ClientError

from ..models.audit_event import AuditEvent
from ..models.enums import PRESIGNED_URL_EXPIRY_SECONDS

logger = logging.getLogger(__name__)


class S3Repository:
    """
    Repository for S3 operations including exports and archives.
    """

    def __init__(
        self,
        bucket_name: Optional[str] = None,
        s3_client=None
    ):
        """
        Initialize S3 repository.

        Args:
            bucket_name: S3 bucket name (defaults to env var)
            s3_client: Optional boto3 S3 client for testing
        """
        self.bucket_name = bucket_name or os.environ.get(
            "AUDIT_S3_BUCKET",
            "bbws-aipagebuilder-dev-s3-audit-archive"
        )
        self.s3_client = s3_client or boto3.client("s3")

    def write_archive(
        self,
        events: List[AuditEvent],
        org_id: str,
        archive_date: datetime
    ) -> str:
        """
        Write events to S3 archive as compressed JSON.

        Args:
            events: List of events to archive
            org_id: Organisation ID
            archive_date: Date for archive path

        Returns:
            S3 key of the archive file
        """
        # Build S3 key
        s3_key = (
            f"archive/{org_id}/"
            f"{archive_date.year}/"
            f"{archive_date.month:02d}/"
            f"{archive_date.day:02d}.json.gz"
        )

        # Convert events to JSON
        events_data = [event.to_api_response() for event in events]
        json_data = json.dumps(events_data, default=str)

        # Compress with gzip
        compressed_data = gzip.compress(json_data.encode("utf-8"))

        # Upload to S3
        try:
            self.s3_client.put_object(
                Bucket=self.bucket_name,
                Key=s3_key,
                Body=compressed_data,
                ContentType="application/gzip",
                ContentEncoding="gzip",
                Metadata={
                    "org_id": org_id,
                    "event_count": str(len(events)),
                    "archive_date": archive_date.isoformat()
                }
            )
            logger.info(f"Archived {len(events)} events to {s3_key}")
            return s3_key
        except ClientError as e:
            logger.error(f"Failed to write archive: {e}")
            raise

    def write_export(
        self,
        data: bytes,
        org_id: str,
        export_id: str,
        file_extension: str
    ) -> str:
        """
        Write export file to S3.

        Args:
            data: Export file data
            org_id: Organisation ID
            export_id: Export request ID
            file_extension: File extension (csv or json)

        Returns:
            S3 key of the export file
        """
        today = datetime.utcnow().strftime("%Y-%m-%d")
        s3_key = f"exports/{org_id}/{today}/{export_id}.{file_extension}.gz"

        # Compress data
        compressed_data = gzip.compress(data)

        content_type = (
            "text/csv" if file_extension == "csv"
            else "application/json"
        )

        try:
            self.s3_client.put_object(
                Bucket=self.bucket_name,
                Key=s3_key,
                Body=compressed_data,
                ContentType=content_type,
                ContentEncoding="gzip",
                Metadata={
                    "org_id": org_id,
                    "export_id": export_id
                }
            )
            logger.info(f"Wrote export to {s3_key}")
            return s3_key
        except ClientError as e:
            logger.error(f"Failed to write export: {e}")
            raise

    def generate_presigned_url(
        self,
        s3_key: str,
        expiry_seconds: int = PRESIGNED_URL_EXPIRY_SECONDS
    ) -> str:
        """
        Generate a presigned URL for downloading a file.

        Args:
            s3_key: S3 object key
            expiry_seconds: URL expiry time in seconds

        Returns:
            Presigned URL string
        """
        try:
            url = self.s3_client.generate_presigned_url(
                "get_object",
                Params={
                    "Bucket": self.bucket_name,
                    "Key": s3_key
                },
                ExpiresIn=expiry_seconds
            )
            return url
        except ClientError as e:
            logger.error(f"Failed to generate presigned URL: {e}")
            raise

    def read_archive(
        self,
        org_id: str,
        archive_date: datetime
    ) -> List[dict]:
        """
        Read archived events from S3.

        Args:
            org_id: Organisation ID
            archive_date: Date of archive to read

        Returns:
            List of event dictionaries
        """
        s3_key = (
            f"archive/{org_id}/"
            f"{archive_date.year}/"
            f"{archive_date.month:02d}/"
            f"{archive_date.day:02d}.json.gz"
        )

        try:
            response = self.s3_client.get_object(
                Bucket=self.bucket_name,
                Key=s3_key
            )

            compressed_data = response["Body"].read()
            json_data = gzip.decompress(compressed_data).decode("utf-8")
            return json.loads(json_data)
        except self.s3_client.exceptions.NoSuchKey:
            logger.warning(f"No archive found for {s3_key}")
            return []
        except ClientError as e:
            logger.error(f"Failed to read archive: {e}")
            raise
```

---

## 7. Audit Logger Utility

### 7.1 services/audit_logger.py

```python
"""
Audit Logger Utility.
Provides a simple interface for other services to log audit events.
"""
import os
import logging
from datetime import datetime
from typing import Optional, Dict, Any

import boto3

from ..models.audit_event import AuditEvent
from ..models.enums import AuditEventType, AuditOutcome, ActorType
from ..repositories.audit_repository import AuditRepository

logger = logging.getLogger(__name__)


class AuditLogger:
    """
    Utility class for other services to log audit events.

    Example usage:
        audit_logger = AuditLogger()
        event_id = audit_logger.log(
            event_type=AuditEventType.AUTHORIZATION,
            org_id="org-123",
            actor_id="user-456",
            action="access",
            resource_type="site",
            resource_id="site-789",
            details={"path": "/v1/sites"},
            outcome=AuditOutcome.SUCCESS
        )
    """

    def __init__(
        self,
        repository: Optional[AuditRepository] = None,
        table_name: Optional[str] = None
    ):
        """
        Initialize the audit logger.

        Args:
            repository: Optional AuditRepository instance
            table_name: Optional DynamoDB table name
        """
        self.repository = repository or AuditRepository(table_name=table_name)

    def log(
        self,
        event_type: AuditEventType,
        org_id: str,
        actor_id: str,
        action: str,
        resource_type: str,
        resource_id: str,
        details: Optional[Dict[str, Any]] = None,
        outcome: AuditOutcome = AuditOutcome.SUCCESS,
        actor_type: ActorType = ActorType.USER,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
        request_id: Optional[str] = None,
        user_email: Optional[str] = None
    ) -> str:
        """
        Log an audit event.

        Args:
            event_type: Type of audit event
            org_id: Organisation ID
            actor_id: ID of actor performing action
            action: Action being performed
            resource_type: Type of resource being acted upon
            resource_id: ID of the resource
            details: Additional event details
            outcome: Result of the action
            actor_type: Whether actor is USER or SYSTEM
            ip_address: Client IP address
            user_agent: Client user agent
            request_id: API Gateway request ID
            user_email: Actor's email address

        Returns:
            The generated event ID
        """
        event = AuditEvent(
            event_type=event_type,
            org_id=org_id,
            actor_id=actor_id,
            actor_type=actor_type,
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            details=details or {},
            outcome=outcome,
            ip_address=ip_address,
            user_agent=user_agent,
            request_id=request_id,
            user_email=user_email
        )

        try:
            self.repository.save(event)
            logger.info(
                f"Logged audit event: {event.event_id} "
                f"type={event_type.value} action={action}"
            )
            return event.event_id
        except Exception as e:
            logger.error(f"Failed to log audit event: {e}")
            # Don't raise - audit logging should not break main flow
            return event.event_id

    def log_authorization(
        self,
        org_id: str,
        actor_id: str,
        action: str,
        resource_type: str,
        resource_id: str,
        outcome: AuditOutcome,
        method: Optional[str] = None,
        path: Optional[str] = None,
        required_permission: Optional[str] = None,
        user_permissions: Optional[list] = None,
        ip_address: Optional[str] = None,
        request_id: Optional[str] = None
    ) -> str:
        """
        Log an authorization event.

        Convenience method for AUTHORIZATION type events.
        """
        details = {}
        if method:
            details["method"] = method
        if path:
            details["path"] = path
        if required_permission:
            details["requiredPermission"] = required_permission
        if user_permissions:
            details["userPermissions"] = user_permissions

        return self.log(
            event_type=AuditEventType.AUTHORIZATION,
            org_id=org_id,
            actor_id=actor_id,
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            details=details,
            outcome=outcome,
            ip_address=ip_address,
            request_id=request_id
        )

    def log_permission_change(
        self,
        org_id: str,
        actor_id: str,
        role_id: str,
        role_name: str,
        before_permissions: list,
        after_permissions: list,
        actor_email: Optional[str] = None,
        ip_address: Optional[str] = None,
        request_id: Optional[str] = None
    ) -> str:
        """
        Log a permission change event.

        Convenience method for PERMISSION_CHANGE type events.
        """
        added = list(set(after_permissions) - set(before_permissions))
        removed = list(set(before_permissions) - set(after_permissions))

        details = {
            "roleName": role_name,
            "before": before_permissions,
            "after": after_permissions,
            "added": added,
            "removed": removed
        }

        return self.log(
            event_type=AuditEventType.PERMISSION_CHANGE,
            org_id=org_id,
            actor_id=actor_id,
            action="update_permissions",
            resource_type="role",
            resource_id=role_id,
            details=details,
            outcome=AuditOutcome.SUCCESS,
            user_email=actor_email,
            ip_address=ip_address,
            request_id=request_id
        )

    def log_user_management(
        self,
        org_id: str,
        actor_id: str,
        action: str,
        target_user_id: str,
        details: Optional[Dict[str, Any]] = None,
        outcome: AuditOutcome = AuditOutcome.SUCCESS,
        actor_email: Optional[str] = None,
        ip_address: Optional[str] = None,
        request_id: Optional[str] = None
    ) -> str:
        """
        Log a user management event.

        Convenience method for USER_MANAGEMENT type events.
        """
        return self.log(
            event_type=AuditEventType.USER_MANAGEMENT,
            org_id=org_id,
            actor_id=actor_id,
            action=action,
            resource_type="user",
            resource_id=target_user_id,
            details=details or {},
            outcome=outcome,
            user_email=actor_email,
            ip_address=ip_address,
            request_id=request_id
        )

    def log_team_membership(
        self,
        org_id: str,
        actor_id: str,
        action: str,
        team_id: str,
        member_id: str,
        team_name: Optional[str] = None,
        role: Optional[str] = None,
        actor_email: Optional[str] = None,
        ip_address: Optional[str] = None,
        request_id: Optional[str] = None
    ) -> str:
        """
        Log a team membership event.

        Convenience method for TEAM_MEMBERSHIP type events.
        """
        details = {"memberId": member_id}
        if team_name:
            details["teamName"] = team_name
        if role:
            details["role"] = role

        return self.log(
            event_type=AuditEventType.TEAM_MEMBERSHIP,
            org_id=org_id,
            actor_id=actor_id,
            action=action,
            resource_type="team",
            resource_id=team_id,
            details=details,
            outcome=AuditOutcome.SUCCESS,
            user_email=actor_email,
            ip_address=ip_address,
            request_id=request_id
        )

    def log_role_change(
        self,
        org_id: str,
        actor_id: str,
        action: str,
        target_user_id: str,
        role_id: str,
        role_name: str,
        actor_email: Optional[str] = None,
        ip_address: Optional[str] = None,
        request_id: Optional[str] = None
    ) -> str:
        """
        Log a role change event.

        Convenience method for ROLE_CHANGE type events.
        """
        details = {
            "targetUserId": target_user_id,
            "roleId": role_id,
            "roleName": role_name
        }

        return self.log(
            event_type=AuditEventType.ROLE_CHANGE,
            org_id=org_id,
            actor_id=actor_id,
            action=action,
            resource_type="user_role",
            resource_id=f"{target_user_id}#{role_id}",
            details=details,
            outcome=AuditOutcome.SUCCESS,
            user_email=actor_email,
            ip_address=ip_address,
            request_id=request_id
        )

    def log_invitation(
        self,
        org_id: str,
        actor_id: str,
        action: str,
        invitation_id: str,
        invitee_email: str,
        role: Optional[str] = None,
        team_id: Optional[str] = None,
        actor_email: Optional[str] = None,
        ip_address: Optional[str] = None,
        request_id: Optional[str] = None
    ) -> str:
        """
        Log an invitation event.

        Convenience method for INVITATION type events.
        """
        details = {"inviteeEmail": invitee_email}
        if role:
            details["role"] = role
        if team_id:
            details["teamId"] = team_id

        return self.log(
            event_type=AuditEventType.INVITATION,
            org_id=org_id,
            actor_id=actor_id,
            action=action,
            resource_type="invitation",
            resource_id=invitation_id,
            details=details,
            outcome=AuditOutcome.SUCCESS,
            user_email=actor_email,
            ip_address=ip_address,
            request_id=request_id
        )

    def log_configuration(
        self,
        org_id: str,
        actor_id: str,
        action: str,
        config_type: str,
        config_id: str,
        before: Optional[Dict[str, Any]] = None,
        after: Optional[Dict[str, Any]] = None,
        actor_email: Optional[str] = None,
        ip_address: Optional[str] = None,
        request_id: Optional[str] = None
    ) -> str:
        """
        Log a configuration change event.

        Convenience method for CONFIGURATION type events.
        """
        details = {}
        if before:
            details["before"] = before
        if after:
            details["after"] = after

        return self.log(
            event_type=AuditEventType.CONFIGURATION,
            org_id=org_id,
            actor_id=actor_id,
            action=action,
            resource_type=config_type,
            resource_id=config_id,
            details=details,
            outcome=AuditOutcome.SUCCESS,
            user_email=actor_email,
            ip_address=ip_address,
            request_id=request_id
        )
```

---

## 8. Export Service

### 8.1 services/audit_export_service.py

```python
"""
Audit Export Service.
Handles export of audit events to S3 with presigned URL generation.
"""
import uuid
import json
import csv
import io
import logging
from datetime import datetime, timedelta
from typing import List, Optional

from ..models.audit_event import AuditEvent
from ..models.enums import ExportFormat, PRESIGNED_URL_EXPIRY_SECONDS
from ..models.requests import (
    ExportRequest,
    ExportResult,
    OrgAuditFilters,
    PaginationParams,
    DateRange
)
from ..repositories.audit_repository import AuditRepository
from ..repositories.s3_repository import S3Repository

logger = logging.getLogger(__name__)


class AuditExportService:
    """
    Service for exporting audit events to S3.
    """

    def __init__(
        self,
        audit_repository: Optional[AuditRepository] = None,
        s3_repository: Optional[S3Repository] = None
    ):
        """
        Initialize export service.

        Args:
            audit_repository: Repository for querying events
            s3_repository: Repository for S3 operations
        """
        self.audit_repo = audit_repository or AuditRepository()
        self.s3_repo = s3_repository or S3Repository()

    def export(self, request: ExportRequest) -> ExportResult:
        """
        Export audit events to S3 and generate presigned URL.

        Args:
            request: Export request with filters

        Returns:
            ExportResult with download URL
        """
        export_id = str(uuid.uuid4())
        logger.info(f"Starting export {export_id} for org {request.org_id}")

        # Query all matching events
        events = self._query_all_events(request)
        logger.info(f"Found {len(events)} events to export")

        # Generate export file
        if request.format == ExportFormat.CSV:
            file_data = self._generate_csv(events)
            file_extension = "csv"
        else:
            file_data = self._generate_json(events)
            file_extension = "json"

        # Upload to S3
        s3_key = self.s3_repo.write_export(
            data=file_data,
            org_id=request.org_id,
            export_id=export_id,
            file_extension=file_extension
        )

        # Generate presigned URL
        download_url = self.s3_repo.generate_presigned_url(s3_key)

        expires_at = datetime.utcnow() + timedelta(
            seconds=PRESIGNED_URL_EXPIRY_SECONDS
        )

        return ExportResult(
            export_id=export_id,
            s3_key=s3_key,
            download_url=download_url,
            expires_at=expires_at,
            record_count=len(events)
        )

    def _query_all_events(self, request: ExportRequest) -> List[AuditEvent]:
        """Query all events matching the export request."""
        events = []
        pagination = PaginationParams(page_size=100)

        filters = OrgAuditFilters(
            org_id=request.org_id,
            date_range=request.date_range,
            event_types=request.event_types
        )

        while True:
            result = self.audit_repo.query_by_org(filters, pagination)
            events.extend(result.items)

            if not result.more_available or not result.next_token:
                break

            pagination.start_at = result.next_token

        return events

    def _generate_csv(self, events: List[AuditEvent]) -> bytes:
        """Generate CSV file from events."""
        output = io.StringIO()
        writer = csv.writer(output)

        # Header
        writer.writerow([
            "eventId",
            "eventType",
            "timestamp",
            "actorId",
            "actorType",
            "action",
            "resourceType",
            "resourceId",
            "outcome",
            "ipAddress",
            "userEmail"
        ])

        # Data rows
        for event in events:
            writer.writerow([
                event.event_id,
                event.event_type.value,
                event.timestamp.isoformat(),
                event.actor_id,
                event.actor_type.value,
                event.action,
                event.resource_type,
                event.resource_id,
                event.outcome.value,
                event.ip_address or "",
                event.user_email or ""
            ])

        return output.getvalue().encode("utf-8")

    def _generate_json(self, events: List[AuditEvent]) -> bytes:
        """Generate JSON file from events."""
        data = [event.to_api_response() for event in events]
        return json.dumps(data, indent=2, default=str).encode("utf-8")
```

---

## 9. Archive Service

### 9.1 services/audit_archive_service.py

```python
"""
Audit Archive Service.
Handles archival of old audit events from DynamoDB to S3.
"""
import logging
from datetime import datetime, timedelta
from typing import List, Dict, Tuple
from collections import defaultdict

from ..models.audit_event import AuditEvent
from ..models.enums import HOT_RETENTION_DAYS
from ..repositories.audit_repository import AuditRepository
from ..repositories.s3_repository import S3Repository

logger = logging.getLogger(__name__)


class AuditArchiveService:
    """
    Service for archiving expired audit events to S3.
    """

    def __init__(
        self,
        audit_repository: AuditRepository = None,
        s3_repository: S3Repository = None
    ):
        """
        Initialize archive service.

        Args:
            audit_repository: Repository for DynamoDB operations
            s3_repository: Repository for S3 operations
        """
        self.audit_repo = audit_repository or AuditRepository()
        self.s3_repo = s3_repository or S3Repository()

    def archive_expired_events(self, batch_size: int = 1000) -> dict:
        """
        Archive events older than HOT_RETENTION_DAYS.

        Args:
            batch_size: Maximum events to process per run

        Returns:
            Summary of archived events
        """
        cutoff = datetime.utcnow() - timedelta(days=HOT_RETENTION_DAYS)
        logger.info(f"Archiving events before {cutoff.isoformat()}")

        # Query expired events
        events = self.audit_repo.query_events_before(cutoff, limit=batch_size)

        if not events:
            logger.info("No events to archive")
            return {"eventsArchived": 0, "orgsProcessed": 0}

        # Group by org and date
        grouped = self._group_events_by_org_date(events)
        logger.info(f"Grouped {len(events)} events into {len(grouped)} batches")

        archived_count = 0
        orgs_processed = set()

        for (org_id, archive_date), org_events in grouped.items():
            try:
                # Write to S3
                self.s3_repo.write_archive(
                    events=org_events,
                    org_id=org_id,
                    archive_date=archive_date
                )

                # Delete from DynamoDB
                self.audit_repo.delete_events(org_events)

                archived_count += len(org_events)
                orgs_processed.add(org_id)

                logger.info(
                    f"Archived {len(org_events)} events for "
                    f"org {org_id} date {archive_date.date()}"
                )
            except Exception as e:
                logger.error(
                    f"Failed to archive events for org {org_id}: {e}"
                )
                # Continue with other batches

        return {
            "eventsArchived": archived_count,
            "orgsProcessed": len(orgs_processed),
            "batchesProcessed": len(grouped)
        }

    def _group_events_by_org_date(
        self,
        events: List[AuditEvent]
    ) -> Dict[Tuple[str, datetime], List[AuditEvent]]:
        """Group events by organisation and date."""
        grouped = defaultdict(list)

        for event in events:
            # Use date part of timestamp for grouping
            event_date = datetime(
                event.timestamp.year,
                event.timestamp.month,
                event.timestamp.day
            )
            key = (event.org_id, event_date)
            grouped[key].append(event)

        return dict(grouped)
```

---

## 10. Lambda Handlers

### 10.1 handlers/query_org_handler.py

```python
"""
Query Organisation Audit Handler.
Lambda handler for GET /v1/orgs/{orgId}/audit
"""
import json
import logging
from datetime import datetime
from typing import Dict, Any

from ..models.requests import OrgAuditFilters, PaginationParams, DateRange
from ..models.enums import AuditEventType, AuditOutcome
from ..repositories.audit_repository import AuditRepository
from ..utils.response_builder import ResponseBuilder

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for querying organisation audit logs.

    Args:
        event: API Gateway event
        context: Lambda context

    Returns:
        API Gateway response
    """
    try:
        # Extract path parameter
        org_id = event.get("pathParameters", {}).get("orgId")
        if not org_id:
            return ResponseBuilder.bad_request("orgId is required")

        # Extract query parameters
        query_params = event.get("queryStringParameters") or {}

        # Parse date range (required)
        start_date_str = query_params.get("startDate")
        end_date_str = query_params.get("endDate")

        if not start_date_str or not end_date_str:
            return ResponseBuilder.bad_request(
                "startDate and endDate are required"
            )

        try:
            start_date = datetime.fromisoformat(
                start_date_str.replace("Z", "+00:00")
            )
            end_date = datetime.fromisoformat(
                end_date_str.replace("Z", "+00:00")
            )
        except ValueError:
            return ResponseBuilder.bad_request(
                "Invalid date format. Use ISO 8601"
            )

        # Parse optional filters
        event_type_str = query_params.get("eventType")
        event_types = None
        if event_type_str:
            try:
                event_types = [AuditEventType(event_type_str)]
            except ValueError:
                return ResponseBuilder.bad_request(
                    f"Invalid eventType: {event_type_str}"
                )

        outcome_str = query_params.get("outcome")
        outcome = None
        if outcome_str:
            try:
                outcome = AuditOutcome(outcome_str)
            except ValueError:
                return ResponseBuilder.bad_request(
                    f"Invalid outcome: {outcome_str}"
                )

        # Build filters
        filters = OrgAuditFilters(
            org_id=org_id,
            date_range=DateRange(start_date=start_date, end_date=end_date),
            event_types=event_types,
            user_id=query_params.get("userId"),
            resource_type=query_params.get("resourceType"),
            outcome=outcome
        )

        # Parse pagination
        page_size = int(query_params.get("pageSize", 50))
        pagination = PaginationParams(
            page_size=page_size,
            start_at=query_params.get("startAt")
        )

        # Query events
        repository = AuditRepository()
        result = repository.query_by_org(filters, pagination)

        return ResponseBuilder.success(result.to_api_response())

    except Exception as e:
        logger.exception(f"Error querying org audit: {e}")
        return ResponseBuilder.internal_error(str(e))
```

### 10.2 handlers/query_user_handler.py

```python
"""
Query User Audit Handler.
Lambda handler for GET /v1/orgs/{orgId}/audit/users/{userId}
"""
import json
import logging
from datetime import datetime
from typing import Dict, Any

from ..models.requests import UserAuditFilters, PaginationParams, DateRange
from ..models.enums import AuditEventType
from ..repositories.audit_repository import AuditRepository
from ..utils.response_builder import ResponseBuilder

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for querying user audit logs.

    Args:
        event: API Gateway event
        context: Lambda context

    Returns:
        API Gateway response
    """
    try:
        # Extract path parameters
        path_params = event.get("pathParameters", {})
        org_id = path_params.get("orgId")
        user_id = path_params.get("userId")

        if not org_id or not user_id:
            return ResponseBuilder.bad_request("orgId and userId are required")

        # Extract query parameters
        query_params = event.get("queryStringParameters") or {}

        # Parse date range
        start_date_str = query_params.get("startDate")
        end_date_str = query_params.get("endDate")

        if not start_date_str or not end_date_str:
            return ResponseBuilder.bad_request(
                "startDate and endDate are required"
            )

        try:
            start_date = datetime.fromisoformat(
                start_date_str.replace("Z", "+00:00")
            )
            end_date = datetime.fromisoformat(
                end_date_str.replace("Z", "+00:00")
            )
        except ValueError:
            return ResponseBuilder.bad_request(
                "Invalid date format. Use ISO 8601"
            )

        # Build filters
        filters = UserAuditFilters(
            org_id=org_id,
            user_id=user_id,
            date_range=DateRange(start_date=start_date, end_date=end_date)
        )

        # Parse pagination
        page_size = int(query_params.get("pageSize", 50))
        pagination = PaginationParams(
            page_size=page_size,
            start_at=query_params.get("startAt")
        )

        # Query events
        repository = AuditRepository()
        result = repository.query_by_user(filters, pagination)

        return ResponseBuilder.success(result.to_api_response())

    except Exception as e:
        logger.exception(f"Error querying user audit: {e}")
        return ResponseBuilder.internal_error(str(e))
```

### 10.3 handlers/query_resource_handler.py

```python
"""
Query Resource Audit Handler.
Lambda handler for GET /v1/orgs/{orgId}/audit/resources/{type}/{id}
"""
import logging
from datetime import datetime
from typing import Dict, Any

from ..models.requests import ResourceAuditFilters, PaginationParams, DateRange
from ..repositories.audit_repository import AuditRepository
from ..utils.response_builder import ResponseBuilder

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for querying resource audit logs.

    Args:
        event: API Gateway event
        context: Lambda context

    Returns:
        API Gateway response
    """
    try:
        # Extract path parameters
        path_params = event.get("pathParameters", {})
        org_id = path_params.get("orgId")
        resource_type = path_params.get("type")
        resource_id = path_params.get("id")

        if not org_id or not resource_type or not resource_id:
            return ResponseBuilder.bad_request(
                "orgId, resource type and id are required"
            )

        # Extract query parameters
        query_params = event.get("queryStringParameters") or {}

        # Parse date range
        start_date_str = query_params.get("startDate")
        end_date_str = query_params.get("endDate")

        if not start_date_str or not end_date_str:
            return ResponseBuilder.bad_request(
                "startDate and endDate are required"
            )

        try:
            start_date = datetime.fromisoformat(
                start_date_str.replace("Z", "+00:00")
            )
            end_date = datetime.fromisoformat(
                end_date_str.replace("Z", "+00:00")
            )
        except ValueError:
            return ResponseBuilder.bad_request(
                "Invalid date format. Use ISO 8601"
            )

        # Build filters
        filters = ResourceAuditFilters(
            org_id=org_id,
            resource_type=resource_type,
            resource_id=resource_id,
            date_range=DateRange(start_date=start_date, end_date=end_date)
        )

        # Parse pagination
        page_size = int(query_params.get("pageSize", 50))
        pagination = PaginationParams(
            page_size=page_size,
            start_at=query_params.get("startAt")
        )

        # Query events
        repository = AuditRepository()
        result = repository.query_by_resource(filters, pagination)

        return ResponseBuilder.success(result.to_api_response())

    except Exception as e:
        logger.exception(f"Error querying resource audit: {e}")
        return ResponseBuilder.internal_error(str(e))
```

### 10.4 handlers/summary_handler.py

```python
"""
Audit Summary Handler.
Lambda handler for GET /v1/orgs/{orgId}/audit/summary
"""
import logging
from datetime import datetime
from typing import Dict, Any

from ..models.requests import DateRange
from ..repositories.audit_repository import AuditRepository
from ..utils.response_builder import ResponseBuilder

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for getting audit summary statistics.

    Args:
        event: API Gateway event
        context: Lambda context

    Returns:
        API Gateway response
    """
    try:
        # Extract path parameter
        org_id = event.get("pathParameters", {}).get("orgId")
        if not org_id:
            return ResponseBuilder.bad_request("orgId is required")

        # Extract query parameters
        query_params = event.get("queryStringParameters") or {}

        # Parse date range
        start_date_str = query_params.get("startDate")
        end_date_str = query_params.get("endDate")

        if not start_date_str or not end_date_str:
            return ResponseBuilder.bad_request(
                "startDate and endDate are required"
            )

        try:
            start_date = datetime.fromisoformat(
                start_date_str.replace("Z", "+00:00")
            )
            end_date = datetime.fromisoformat(
                end_date_str.replace("Z", "+00:00")
            )
        except ValueError:
            return ResponseBuilder.bad_request(
                "Invalid date format. Use ISO 8601"
            )

        date_range = DateRange(start_date=start_date, end_date=end_date)

        # Get summary
        repository = AuditRepository()
        summary = repository.get_summary(org_id, date_range)

        return ResponseBuilder.success(summary.to_api_response())

    except Exception as e:
        logger.exception(f"Error getting audit summary: {e}")
        return ResponseBuilder.internal_error(str(e))
```

### 10.5 handlers/export_handler.py

```python
"""
Audit Export Handler.
Lambda handler for POST /v1/orgs/{orgId}/audit/export
"""
import json
import logging
from datetime import datetime
from typing import Dict, Any

from ..models.requests import ExportRequest, DateRange
from ..models.enums import ExportFormat, AuditEventType
from ..services.audit_export_service import AuditExportService
from ..utils.response_builder import ResponseBuilder

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for exporting audit logs.

    Args:
        event: API Gateway event
        context: Lambda context

    Returns:
        API Gateway response (202 Accepted)
    """
    try:
        # Extract path parameter
        org_id = event.get("pathParameters", {}).get("orgId")
        if not org_id:
            return ResponseBuilder.bad_request("orgId is required")

        # Parse request body
        try:
            body = json.loads(event.get("body", "{}"))
        except json.JSONDecodeError:
            return ResponseBuilder.bad_request("Invalid JSON body")

        # Validate required fields
        date_range_data = body.get("dateRange", {})
        start_date_str = date_range_data.get("startDate")
        end_date_str = date_range_data.get("endDate")

        if not start_date_str or not end_date_str:
            return ResponseBuilder.bad_request(
                "dateRange with startDate and endDate is required"
            )

        try:
            start_date = datetime.fromisoformat(
                start_date_str.replace("Z", "+00:00")
            )
            end_date = datetime.fromisoformat(
                end_date_str.replace("Z", "+00:00")
            )
        except ValueError:
            return ResponseBuilder.bad_request(
                "Invalid date format. Use ISO 8601"
            )

        # Parse optional event types
        event_types = None
        event_type_strs = body.get("eventTypes")
        if event_type_strs:
            try:
                event_types = [AuditEventType(et) for et in event_type_strs]
            except ValueError as e:
                return ResponseBuilder.bad_request(f"Invalid eventType: {e}")

        # Parse format
        format_str = body.get("format", "json").lower()
        try:
            export_format = ExportFormat(format_str)
        except ValueError:
            return ResponseBuilder.bad_request(
                f"Invalid format: {format_str}. Use 'csv' or 'json'"
            )

        # Build export request
        export_request = ExportRequest(
            org_id=org_id,
            date_range=DateRange(start_date=start_date, end_date=end_date),
            event_types=event_types,
            format=export_format
        )

        # Execute export
        service = AuditExportService()
        result = service.export(export_request)

        return ResponseBuilder.accepted(result.to_api_response())

    except Exception as e:
        logger.exception(f"Error exporting audit logs: {e}")
        return ResponseBuilder.internal_error(str(e))
```

### 10.6 handlers/archive_handler.py

```python
"""
Audit Archive Handler.
Lambda handler for scheduled EventBridge trigger.
"""
import logging
from typing import Dict, Any

from ..services.audit_archive_service import AuditArchiveService

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for archiving expired audit events.

    Triggered by EventBridge schedule: cron(0 2 * * ? *)

    Args:
        event: EventBridge event
        context: Lambda context

    Returns:
        Archive result summary
    """
    logger.info("Starting audit archive process")

    try:
        service = AuditArchiveService()
        result = service.archive_expired_events(batch_size=1000)

        logger.info(f"Archive complete: {result}")
        return {
            "statusCode": 200,
            "body": result
        }

    except Exception as e:
        logger.exception(f"Error archiving audit events: {e}")
        return {
            "statusCode": 500,
            "body": {"error": str(e)}
        }
```

---

## 11. Utility Classes

### 11.1 utils/response_builder.py

```python
"""
Response Builder Utility.
Provides standardized API Gateway response formatting.
"""
import json
from typing import Any, Dict, Optional


class ResponseBuilder:
    """Utility class for building API Gateway responses."""

    CORS_HEADERS = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type,Authorization",
        "Access-Control-Allow-Methods": "GET,POST,OPTIONS"
    }

    @classmethod
    def success(cls, body: Any) -> Dict[str, Any]:
        """Build 200 OK response."""
        return cls._build_response(200, body)

    @classmethod
    def accepted(cls, body: Any) -> Dict[str, Any]:
        """Build 202 Accepted response."""
        return cls._build_response(202, body)

    @classmethod
    def bad_request(cls, message: str) -> Dict[str, Any]:
        """Build 400 Bad Request response."""
        return cls._build_response(400, {"error": message})

    @classmethod
    def unauthorized(cls, message: str = "Unauthorized") -> Dict[str, Any]:
        """Build 401 Unauthorized response."""
        return cls._build_response(401, {"error": message})

    @classmethod
    def forbidden(cls, message: str = "Forbidden") -> Dict[str, Any]:
        """Build 403 Forbidden response."""
        return cls._build_response(403, {"error": message})

    @classmethod
    def not_found(cls, message: str = "Not found") -> Dict[str, Any]:
        """Build 404 Not Found response."""
        return cls._build_response(404, {"error": message})

    @classmethod
    def internal_error(cls, message: str = "Internal error") -> Dict[str, Any]:
        """Build 500 Internal Server Error response."""
        return cls._build_response(500, {"error": message})

    @classmethod
    def _build_response(
        cls,
        status_code: int,
        body: Any,
        headers: Optional[Dict[str, str]] = None
    ) -> Dict[str, Any]:
        """Build standardized response."""
        response_headers = {**cls.CORS_HEADERS}
        if headers:
            response_headers.update(headers)

        return {
            "statusCode": status_code,
            "headers": response_headers,
            "body": json.dumps(body, default=str)
        }
```

### 11.2 utils/csv_generator.py

```python
"""
CSV Generator Utility.
Provides CSV generation for audit event exports.
"""
import csv
import io
from typing import List

from ..models.audit_event import AuditEvent


class CSVGenerator:
    """Utility class for generating CSV exports."""

    HEADERS = [
        "eventId",
        "eventType",
        "timestamp",
        "orgId",
        "actorId",
        "actorType",
        "action",
        "resourceType",
        "resourceId",
        "outcome",
        "ipAddress",
        "userEmail",
        "details"
    ]

    @classmethod
    def generate(cls, events: List[AuditEvent]) -> str:
        """
        Generate CSV string from audit events.

        Args:
            events: List of audit events

        Returns:
            CSV formatted string
        """
        output = io.StringIO()
        writer = csv.DictWriter(output, fieldnames=cls.HEADERS)
        writer.writeheader()

        for event in events:
            writer.writerow({
                "eventId": event.event_id,
                "eventType": event.event_type.value,
                "timestamp": event.timestamp.isoformat(),
                "orgId": event.org_id,
                "actorId": event.actor_id,
                "actorType": event.actor_type.value,
                "action": event.action,
                "resourceType": event.resource_type,
                "resourceId": event.resource_id,
                "outcome": event.outcome.value,
                "ipAddress": event.ip_address or "",
                "userEmail": event.user_email or "",
                "details": str(event.details)
            })

        return output.getvalue()
```

---

## 12. Unit Tests (TDD)

### 12.1 tests/conftest.py

```python
"""
Pytest Configuration and Fixtures.
Sets up moto mocks for DynamoDB and S3.
"""
import os
import pytest
import boto3
from moto import mock_aws
from datetime import datetime, timedelta


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
    """Create mock DynamoDB table."""
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
                {"AttributeName": "GSI2SK", "AttributeType": "S"},
                {"AttributeName": "GSI3PK", "AttributeType": "S"},
                {"AttributeName": "GSI3SK", "AttributeType": "S"}
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
                },
                {
                    "IndexName": "GSI3",
                    "KeySchema": [
                        {"AttributeName": "GSI3PK", "KeyType": "HASH"},
                        {"AttributeName": "GSI3SK", "KeyType": "RANGE"}
                    ],
                    "Projection": {"ProjectionType": "ALL"}
                }
            ],
            BillingMode="PAY_PER_REQUEST"
        )

        table.wait_until_exists()
        yield dynamodb


@pytest.fixture(scope="function")
def s3_bucket(aws_credentials):
    """Create mock S3 bucket."""
    with mock_aws():
        s3 = boto3.client("s3", region_name="af-south-1")
        s3.create_bucket(
            Bucket="bbws-aipagebuilder-dev-s3-audit-archive",
            CreateBucketConfiguration={"LocationConstraint": "af-south-1"}
        )
        yield s3


@pytest.fixture
def sample_event():
    """Create sample audit event for testing."""
    from audit_service.models.audit_event import AuditEvent
    from audit_service.models.enums import AuditEventType, AuditOutcome

    return AuditEvent(
        event_type=AuditEventType.AUTHORIZATION,
        org_id="org-123",
        actor_id="user-456",
        action="access",
        resource_type="site",
        resource_id="site-789",
        outcome=AuditOutcome.SUCCESS,
        details={"path": "/v1/sites"},
        ip_address="192.168.1.1"
    )
```

### 12.2 tests/test_models.py

```python
"""
Unit Tests for Audit Models.
Tests AuditEvent model and related data classes.
"""
import pytest
from datetime import datetime, timedelta

from audit_service.models.audit_event import AuditEvent
from audit_service.models.enums import (
    AuditEventType,
    AuditOutcome,
    ActorType,
    HOT_RETENTION_DAYS
)
from audit_service.models.requests import DateRange, PaginationParams


class TestAuditEvent:
    """Test cases for AuditEvent model."""

    def test_create_audit_event_with_defaults(self):
        """Test creating audit event with default values."""
        event = AuditEvent(
            event_type=AuditEventType.AUTHORIZATION,
            org_id="org-123",
            actor_id="user-456",
            action="access",
            resource_type="site",
            resource_id="site-789"
        )

        assert event.event_id is not None
        assert event.event_type == AuditEventType.AUTHORIZATION
        assert event.org_id == "org-123"
        assert event.actor_id == "user-456"
        assert event.outcome == AuditOutcome.SUCCESS
        assert event.actor_type == ActorType.USER
        assert event.ttl is not None

    def test_audit_event_ttl_calculation(self):
        """Test TTL is set to 30 days from now."""
        event = AuditEvent(
            event_type=AuditEventType.AUTHORIZATION,
            org_id="org-123",
            actor_id="user-456",
            action="access",
            resource_type="site",
            resource_id="site-789"
        )

        expected_ttl = datetime.utcnow() + timedelta(days=HOT_RETENTION_DAYS)
        # Allow 1 second tolerance
        assert abs(event.ttl - int(expected_ttl.timestamp())) <= 1

    def test_audit_event_pk_format(self):
        """Test primary key format."""
        event = AuditEvent(
            event_type=AuditEventType.AUTHORIZATION,
            org_id="org-123",
            actor_id="user-456",
            action="access",
            resource_type="site",
            resource_id="site-789",
            timestamp=datetime(2026, 1, 23, 14, 30, 0)
        )

        assert event.pk == "ORG#org-123#DATE#2026-01-23"

    def test_audit_event_sk_format(self):
        """Test sort key format."""
        event = AuditEvent(
            event_type=AuditEventType.AUTHORIZATION,
            org_id="org-123",
            actor_id="user-456",
            action="access",
            resource_type="site",
            resource_id="site-789"
        )

        assert event.sk.startswith("EVENT#")
        assert event.event_id in event.sk

    def test_audit_event_gsi1_keys(self):
        """Test GSI1 keys for user queries."""
        event = AuditEvent(
            event_type=AuditEventType.AUTHORIZATION,
            org_id="org-123",
            actor_id="user-456",
            action="access",
            resource_type="site",
            resource_id="site-789"
        )

        assert event.gsi1pk == "USER#user-456"
        assert event.event_id in event.gsi1sk

    def test_audit_event_gsi2_keys(self):
        """Test GSI2 keys for event type queries."""
        event = AuditEvent(
            event_type=AuditEventType.PERMISSION_CHANGE,
            org_id="org-123",
            actor_id="user-456",
            action="update",
            resource_type="role",
            resource_id="role-789"
        )

        assert event.gsi2pk == "ORG#org-123#TYPE#PERMISSION_CHANGE"

    def test_audit_event_gsi3_keys(self):
        """Test GSI3 keys for resource queries."""
        event = AuditEvent(
            event_type=AuditEventType.AUTHORIZATION,
            org_id="org-123",
            actor_id="user-456",
            action="access",
            resource_type="site",
            resource_id="site-789"
        )

        assert event.gsi3pk == "RESOURCE#site#site-789"

    def test_to_dynamodb_item(self):
        """Test conversion to DynamoDB item."""
        event = AuditEvent(
            event_type=AuditEventType.AUTHORIZATION,
            org_id="org-123",
            actor_id="user-456",
            action="access",
            resource_type="site",
            resource_id="site-789",
            ip_address="192.168.1.1"
        )

        item = event.to_dynamodb_item()

        assert item["PK"] == event.pk
        assert item["SK"] == event.sk
        assert item["eventType"] == "AUTHORIZATION"
        assert item["orgId"] == "org-123"
        assert item["entityType"] == "AUDIT_EVENT"
        assert item["ipAddress"] == "192.168.1.1"

    def test_from_dynamodb_item(self):
        """Test creation from DynamoDB item."""
        item = {
            "eventId": "evt-123",
            "eventType": "AUTHORIZATION",
            "timestamp": "2026-01-23T14:30:00",
            "orgId": "org-123",
            "actorId": "user-456",
            "actorType": "USER",
            "action": "access",
            "resourceType": "site",
            "resourceId": "site-789",
            "outcome": "SUCCESS",
            "details": {"path": "/v1/sites"},
            "ipAddress": "192.168.1.1"
        }

        event = AuditEvent.from_dynamodb_item(item)

        assert event.event_id == "evt-123"
        assert event.event_type == AuditEventType.AUTHORIZATION
        assert event.org_id == "org-123"
        assert event.ip_address == "192.168.1.1"

    def test_to_api_response(self):
        """Test conversion to API response format."""
        event = AuditEvent(
            event_type=AuditEventType.AUTHORIZATION,
            org_id="org-123",
            actor_id="user-456",
            action="access",
            resource_type="site",
            resource_id="site-789"
        )

        response = event.to_api_response()

        assert response["id"] == event.event_id
        assert response["eventType"] == "AUTHORIZATION"
        assert response["orgId"] == "org-123"


class TestDateRange:
    """Test cases for DateRange model."""

    def test_valid_date_range(self):
        """Test creating valid date range."""
        start = datetime(2026, 1, 1)
        end = datetime(2026, 1, 31)

        date_range = DateRange(start_date=start, end_date=end)

        assert date_range.start_date == start
        assert date_range.end_date == end

    def test_invalid_date_range_raises_error(self):
        """Test that invalid date range raises ValueError."""
        start = datetime(2026, 1, 31)
        end = datetime(2026, 1, 1)

        with pytest.raises(ValueError) as exc_info:
            DateRange(start_date=start, end_date=end)

        assert "start_date must be before end_date" in str(exc_info.value)


class TestPaginationParams:
    """Test cases for PaginationParams model."""

    def test_default_page_size(self):
        """Test default page size."""
        pagination = PaginationParams()
        assert pagination.page_size == 50

    def test_max_page_size_enforced(self):
        """Test page size is capped at 100."""
        pagination = PaginationParams(page_size=200)
        assert pagination.page_size == 100

    def test_min_page_size_enforced(self):
        """Test page size minimum is 1."""
        pagination = PaginationParams(page_size=0)
        assert pagination.page_size == 1
```

### 12.3 tests/test_audit_logger.py

```python
"""
Unit Tests for Audit Logger.
Tests the AuditLogger utility class.
"""
import pytest
from unittest.mock import Mock, patch
from datetime import datetime

from audit_service.services.audit_logger import AuditLogger
from audit_service.models.enums import AuditEventType, AuditOutcome
from audit_service.repositories.audit_repository import AuditRepository


class TestAuditLogger:
    """Test cases for AuditLogger class."""

    def test_log_creates_event_with_correct_type(self):
        """Test that log creates event with correct type."""
        mock_repo = Mock(spec=AuditRepository)

        logger = AuditLogger(repository=mock_repo)
        event_id = logger.log(
            event_type=AuditEventType.AUTHORIZATION,
            org_id="org-123",
            actor_id="user-456",
            action="access",
            resource_type="site",
            resource_id="site-789"
        )

        assert event_id is not None
        mock_repo.save.assert_called_once()
        saved_event = mock_repo.save.call_args[0][0]
        assert saved_event.event_type == AuditEventType.AUTHORIZATION

    def test_log_authorization_convenience_method(self):
        """Test log_authorization convenience method."""
        mock_repo = Mock(spec=AuditRepository)

        logger = AuditLogger(repository=mock_repo)
        event_id = logger.log_authorization(
            org_id="org-123",
            actor_id="user-456",
            action="access",
            resource_type="site",
            resource_id="site-789",
            outcome=AuditOutcome.SUCCESS,
            method="GET",
            path="/v1/sites"
        )

        assert event_id is not None
        saved_event = mock_repo.save.call_args[0][0]
        assert saved_event.event_type == AuditEventType.AUTHORIZATION
        assert saved_event.details["method"] == "GET"
        assert saved_event.details["path"] == "/v1/sites"

    def test_log_permission_change_calculates_diff(self):
        """Test log_permission_change calculates added/removed."""
        mock_repo = Mock(spec=AuditRepository)

        logger = AuditLogger(repository=mock_repo)
        logger.log_permission_change(
            org_id="org-123",
            actor_id="admin-001",
            role_id="role-123",
            role_name="SITE_EDITOR",
            before_permissions=["site:read", "site:update"],
            after_permissions=["site:read", "site:update", "site:publish"]
        )

        saved_event = mock_repo.save.call_args[0][0]
        assert saved_event.event_type == AuditEventType.PERMISSION_CHANGE
        assert "site:publish" in saved_event.details["added"]
        assert saved_event.details["removed"] == []

    def test_log_team_membership(self):
        """Test log_team_membership convenience method."""
        mock_repo = Mock(spec=AuditRepository)

        logger = AuditLogger(repository=mock_repo)
        logger.log_team_membership(
            org_id="org-123",
            actor_id="admin-001",
            action="add_member",
            team_id="team-456",
            member_id="user-789",
            team_name="Engineering"
        )

        saved_event = mock_repo.save.call_args[0][0]
        assert saved_event.event_type == AuditEventType.TEAM_MEMBERSHIP
        assert saved_event.resource_type == "team"
        assert saved_event.details["memberId"] == "user-789"

    def test_log_does_not_raise_on_repository_error(self):
        """Test that log doesn't raise when repository fails."""
        mock_repo = Mock(spec=AuditRepository)
        mock_repo.save.side_effect = Exception("DB Error")

        logger = AuditLogger(repository=mock_repo)
        # Should not raise
        event_id = logger.log(
            event_type=AuditEventType.AUTHORIZATION,
            org_id="org-123",
            actor_id="user-456",
            action="access",
            resource_type="site",
            resource_id="site-789"
        )

        assert event_id is not None  # Returns event_id even on failure

    def test_log_role_change(self):
        """Test log_role_change convenience method."""
        mock_repo = Mock(spec=AuditRepository)

        logger = AuditLogger(repository=mock_repo)
        logger.log_role_change(
            org_id="org-123",
            actor_id="admin-001",
            action="assign",
            target_user_id="user-456",
            role_id="role-789",
            role_name="ADMIN"
        )

        saved_event = mock_repo.save.call_args[0][0]
        assert saved_event.event_type == AuditEventType.ROLE_CHANGE
        assert saved_event.details["targetUserId"] == "user-456"
        assert saved_event.details["roleName"] == "ADMIN"

    def test_log_invitation(self):
        """Test log_invitation convenience method."""
        mock_repo = Mock(spec=AuditRepository)

        logger = AuditLogger(repository=mock_repo)
        logger.log_invitation(
            org_id="org-123",
            actor_id="admin-001",
            action="sent",
            invitation_id="inv-456",
            invitee_email="newuser@example.com",
            role="VIEWER"
        )

        saved_event = mock_repo.save.call_args[0][0]
        assert saved_event.event_type == AuditEventType.INVITATION
        assert saved_event.details["inviteeEmail"] == "newuser@example.com"
```

### 12.4 tests/test_audit_repository.py

```python
"""
Unit Tests for Audit Repository.
Tests DynamoDB operations using moto mock.
"""
import pytest
from datetime import datetime, timedelta
from moto import mock_aws
import boto3

from audit_service.models.audit_event import AuditEvent
from audit_service.models.enums import AuditEventType, AuditOutcome
from audit_service.models.requests import (
    OrgAuditFilters,
    UserAuditFilters,
    ResourceAuditFilters,
    PaginationParams,
    DateRange
)
from audit_service.repositories.audit_repository import AuditRepository


@pytest.fixture
def setup_dynamodb():
    """Set up mock DynamoDB with table."""
    with mock_aws():
        dynamodb = boto3.resource("dynamodb", region_name="af-south-1")

        table = dynamodb.create_table(
            TableName="test-audit-table",
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
                {"AttributeName": "GSI2SK", "AttributeType": "S"},
                {"AttributeName": "GSI3PK", "AttributeType": "S"},
                {"AttributeName": "GSI3SK", "AttributeType": "S"}
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
                },
                {
                    "IndexName": "GSI3",
                    "KeySchema": [
                        {"AttributeName": "GSI3PK", "KeyType": "HASH"},
                        {"AttributeName": "GSI3SK", "KeyType": "RANGE"}
                    ],
                    "Projection": {"ProjectionType": "ALL"}
                }
            ],
            BillingMode="PAY_PER_REQUEST"
        )

        table.wait_until_exists()
        yield dynamodb


class TestAuditRepository:
    """Test cases for AuditRepository."""

    def test_save_event(self, setup_dynamodb):
        """Test saving an audit event."""
        repo = AuditRepository(
            table_name="test-audit-table",
            dynamodb_resource=setup_dynamodb
        )

        event = AuditEvent(
            event_type=AuditEventType.AUTHORIZATION,
            org_id="org-123",
            actor_id="user-456",
            action="access",
            resource_type="site",
            resource_id="site-789"
        )

        repo.save(event)

        # Verify item was saved
        table = setup_dynamodb.Table("test-audit-table")
        response = table.get_item(Key={"PK": event.pk, "SK": event.sk})
        assert "Item" in response
        assert response["Item"]["eventId"] == event.event_id

    def test_save_batch(self, setup_dynamodb):
        """Test batch saving events."""
        repo = AuditRepository(
            table_name="test-audit-table",
            dynamodb_resource=setup_dynamodb
        )

        events = [
            AuditEvent(
                event_type=AuditEventType.AUTHORIZATION,
                org_id="org-123",
                actor_id=f"user-{i}",
                action="access",
                resource_type="site",
                resource_id=f"site-{i}"
            )
            for i in range(5)
        ]

        repo.save_batch(events)

        # Verify all items saved
        table = setup_dynamodb.Table("test-audit-table")
        for event in events:
            response = table.get_item(Key={"PK": event.pk, "SK": event.sk})
            assert "Item" in response

    def test_query_by_org(self, setup_dynamodb):
        """Test querying events by organisation."""
        repo = AuditRepository(
            table_name="test-audit-table",
            dynamodb_resource=setup_dynamodb
        )

        # Create events for different orgs
        now = datetime.utcnow()
        events = [
            AuditEvent(
                event_type=AuditEventType.AUTHORIZATION,
                org_id="org-123",
                actor_id="user-456",
                action="access",
                resource_type="site",
                resource_id="site-1",
                timestamp=now
            ),
            AuditEvent(
                event_type=AuditEventType.AUTHORIZATION,
                org_id="org-123",
                actor_id="user-789",
                action="access",
                resource_type="site",
                resource_id="site-2",
                timestamp=now
            ),
            AuditEvent(
                event_type=AuditEventType.AUTHORIZATION,
                org_id="org-other",
                actor_id="user-000",
                action="access",
                resource_type="site",
                resource_id="site-3",
                timestamp=now
            )
        ]

        for event in events:
            repo.save(event)

        # Query org-123
        filters = OrgAuditFilters(
            org_id="org-123",
            date_range=DateRange(
                start_date=now - timedelta(hours=1),
                end_date=now + timedelta(hours=1)
            )
        )
        pagination = PaginationParams(page_size=50)

        result = repo.query_by_org(filters, pagination)

        assert result.count == 2
        for item in result.items:
            assert item.org_id == "org-123"

    def test_query_by_user(self, setup_dynamodb):
        """Test querying events by user using GSI1."""
        repo = AuditRepository(
            table_name="test-audit-table",
            dynamodb_resource=setup_dynamodb
        )

        now = datetime.utcnow()
        events = [
            AuditEvent(
                event_type=AuditEventType.AUTHORIZATION,
                org_id="org-123",
                actor_id="user-456",
                action="access",
                resource_type="site",
                resource_id=f"site-{i}",
                timestamp=now
            )
            for i in range(3)
        ]

        for event in events:
            repo.save(event)

        filters = UserAuditFilters(
            org_id="org-123",
            user_id="user-456",
            date_range=DateRange(
                start_date=now - timedelta(hours=1),
                end_date=now + timedelta(hours=1)
            )
        )
        pagination = PaginationParams(page_size=50)

        result = repo.query_by_user(filters, pagination)

        assert result.count == 3
        for item in result.items:
            assert item.actor_id == "user-456"

    def test_query_by_resource(self, setup_dynamodb):
        """Test querying events by resource using GSI3."""
        repo = AuditRepository(
            table_name="test-audit-table",
            dynamodb_resource=setup_dynamodb
        )

        now = datetime.utcnow()
        events = [
            AuditEvent(
                event_type=AuditEventType.AUTHORIZATION,
                org_id="org-123",
                actor_id=f"user-{i}",
                action="access",
                resource_type="site",
                resource_id="site-789",
                timestamp=now
            )
            for i in range(2)
        ]

        for event in events:
            repo.save(event)

        filters = ResourceAuditFilters(
            org_id="org-123",
            resource_type="site",
            resource_id="site-789",
            date_range=DateRange(
                start_date=now - timedelta(hours=1),
                end_date=now + timedelta(hours=1)
            )
        )
        pagination = PaginationParams(page_size=50)

        result = repo.query_by_resource(filters, pagination)

        assert result.count == 2
        for item in result.items:
            assert item.resource_id == "site-789"

    def test_get_summary(self, setup_dynamodb):
        """Test getting audit summary statistics."""
        repo = AuditRepository(
            table_name="test-audit-table",
            dynamodb_resource=setup_dynamodb
        )

        now = datetime.utcnow()
        events = [
            AuditEvent(
                event_type=AuditEventType.AUTHORIZATION,
                org_id="org-123",
                actor_id="user-456",
                action="access",
                resource_type="site",
                resource_id="site-1",
                outcome=AuditOutcome.SUCCESS,
                timestamp=now
            ),
            AuditEvent(
                event_type=AuditEventType.AUTHORIZATION,
                org_id="org-123",
                actor_id="user-456",
                action="access",
                resource_type="site",
                resource_id="site-2",
                outcome=AuditOutcome.DENIED,
                timestamp=now
            ),
            AuditEvent(
                event_type=AuditEventType.PERMISSION_CHANGE,
                org_id="org-123",
                actor_id="admin-001",
                action="update",
                resource_type="role",
                resource_id="role-1",
                outcome=AuditOutcome.SUCCESS,
                timestamp=now
            )
        ]

        for event in events:
            repo.save(event)

        date_range = DateRange(
            start_date=now - timedelta(hours=1),
            end_date=now + timedelta(hours=1)
        )

        summary = repo.get_summary("org-123", date_range)

        assert summary.total_events == 3
        assert summary.authorization_events == 2
        assert summary.permission_changes == 1
        assert summary.allowed_requests == 2
        assert summary.denied_requests == 1

    def test_pagination(self, setup_dynamodb):
        """Test pagination with next token."""
        repo = AuditRepository(
            table_name="test-audit-table",
            dynamodb_resource=setup_dynamodb
        )

        now = datetime.utcnow()
        # Create 10 events
        events = [
            AuditEvent(
                event_type=AuditEventType.AUTHORIZATION,
                org_id="org-123",
                actor_id="user-456",
                action="access",
                resource_type="site",
                resource_id=f"site-{i}",
                timestamp=now - timedelta(minutes=i)
            )
            for i in range(10)
        ]

        for event in events:
            repo.save(event)

        filters = OrgAuditFilters(
            org_id="org-123",
            date_range=DateRange(
                start_date=now - timedelta(hours=1),
                end_date=now + timedelta(hours=1)
            )
        )

        # First page
        pagination = PaginationParams(page_size=5)
        result = repo.query_by_org(filters, pagination)

        assert result.count == 5
        assert result.more_available is True
```

### 12.5 tests/test_query_handlers.py

```python
"""
Unit Tests for Query Lambda Handlers.
Tests handler functions with mocked dependencies.
"""
import pytest
import json
from datetime import datetime, timedelta
from unittest.mock import Mock, patch

from audit_service.handlers import query_org_handler
from audit_service.models.requests import PaginatedResult
from audit_service.models.audit_event import AuditEvent
from audit_service.models.enums import AuditEventType, AuditOutcome


class TestQueryOrgHandler:
    """Test cases for query_org_handler."""

    def test_missing_org_id_returns_400(self):
        """Test that missing orgId returns 400."""
        event = {
            "pathParameters": {},
            "queryStringParameters": {
                "startDate": "2026-01-01T00:00:00Z",
                "endDate": "2026-01-31T23:59:59Z"
            }
        }

        response = query_org_handler.handler(event, None)

        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert "orgId is required" in body["error"]

    def test_missing_date_range_returns_400(self):
        """Test that missing date range returns 400."""
        event = {
            "pathParameters": {"orgId": "org-123"},
            "queryStringParameters": {}
        }

        response = query_org_handler.handler(event, None)

        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert "startDate and endDate are required" in body["error"]

    def test_invalid_date_format_returns_400(self):
        """Test that invalid date format returns 400."""
        event = {
            "pathParameters": {"orgId": "org-123"},
            "queryStringParameters": {
                "startDate": "invalid-date",
                "endDate": "2026-01-31"
            }
        }

        response = query_org_handler.handler(event, None)

        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert "Invalid date format" in body["error"]

    def test_invalid_event_type_returns_400(self):
        """Test that invalid event type returns 400."""
        event = {
            "pathParameters": {"orgId": "org-123"},
            "queryStringParameters": {
                "startDate": "2026-01-01T00:00:00Z",
                "endDate": "2026-01-31T23:59:59Z",
                "eventType": "INVALID_TYPE"
            }
        }

        response = query_org_handler.handler(event, None)

        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert "Invalid eventType" in body["error"]

    @patch("audit_service.handlers.query_org_handler.AuditRepository")
    def test_successful_query_returns_200(self, mock_repo_class):
        """Test successful query returns 200 with data."""
        mock_repo = Mock()
        mock_repo_class.return_value = mock_repo

        # Create mock result
        mock_event = AuditEvent(
            event_type=AuditEventType.AUTHORIZATION,
            org_id="org-123",
            actor_id="user-456",
            action="access",
            resource_type="site",
            resource_id="site-789"
        )
        mock_result = PaginatedResult(
            items=[mock_event],
            count=1,
            more_available=False
        )
        mock_repo.query_by_org.return_value = mock_result

        event = {
            "pathParameters": {"orgId": "org-123"},
            "queryStringParameters": {
                "startDate": "2026-01-01T00:00:00Z",
                "endDate": "2026-01-31T23:59:59Z"
            }
        }

        response = query_org_handler.handler(event, None)

        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert body["count"] == 1
        assert len(body["items"]) == 1
```

### 12.6 tests/test_export_handler.py

```python
"""
Unit Tests for Export Lambda Handler.
Tests export handler with mocked S3 and DynamoDB.
"""
import pytest
import json
from datetime import datetime
from unittest.mock import Mock, patch

from audit_service.handlers import export_handler
from audit_service.models.requests import ExportResult


class TestExportHandler:
    """Test cases for export_handler."""

    def test_missing_org_id_returns_400(self):
        """Test that missing orgId returns 400."""
        event = {
            "pathParameters": {},
            "body": json.dumps({
                "dateRange": {
                    "startDate": "2026-01-01T00:00:00Z",
                    "endDate": "2026-01-31T23:59:59Z"
                }
            })
        }

        response = export_handler.handler(event, None)

        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert "orgId is required" in body["error"]

    def test_invalid_json_returns_400(self):
        """Test that invalid JSON body returns 400."""
        event = {
            "pathParameters": {"orgId": "org-123"},
            "body": "invalid json"
        }

        response = export_handler.handler(event, None)

        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert "Invalid JSON" in body["error"]

    def test_missing_date_range_returns_400(self):
        """Test that missing date range returns 400."""
        event = {
            "pathParameters": {"orgId": "org-123"},
            "body": json.dumps({})
        }

        response = export_handler.handler(event, None)

        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert "dateRange" in body["error"]

    def test_invalid_format_returns_400(self):
        """Test that invalid format returns 400."""
        event = {
            "pathParameters": {"orgId": "org-123"},
            "body": json.dumps({
                "dateRange": {
                    "startDate": "2026-01-01T00:00:00Z",
                    "endDate": "2026-01-31T23:59:59Z"
                },
                "format": "xml"
            })
        }

        response = export_handler.handler(event, None)

        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert "Invalid format" in body["error"]

    @patch("audit_service.handlers.export_handler.AuditExportService")
    def test_successful_export_returns_202(self, mock_service_class):
        """Test successful export returns 202 Accepted."""
        mock_service = Mock()
        mock_service_class.return_value = mock_service

        mock_result = ExportResult(
            export_id="exp-123",
            s3_key="exports/org-123/2026-01-23/exp-123.json.gz",
            download_url="https://s3.amazonaws.com/...",
            expires_at=datetime(2026, 1, 24, 12, 0, 0),
            record_count=100
        )
        mock_service.export.return_value = mock_result

        event = {
            "pathParameters": {"orgId": "org-123"},
            "body": json.dumps({
                "dateRange": {
                    "startDate": "2026-01-01T00:00:00Z",
                    "endDate": "2026-01-31T23:59:59Z"
                },
                "format": "json"
            })
        }

        response = export_handler.handler(event, None)

        assert response["statusCode"] == 202
        body = json.loads(response["body"])
        assert body["exportId"] == "exp-123"
        assert body["recordCount"] == 100
        assert "downloadUrl" in body
```

### 12.7 tests/test_archive_handler.py

```python
"""
Unit Tests for Archive Lambda Handler.
Tests archive handler with mocked services.
"""
import pytest
from unittest.mock import Mock, patch

from audit_service.handlers import archive_handler


class TestArchiveHandler:
    """Test cases for archive_handler."""

    @patch("audit_service.handlers.archive_handler.AuditArchiveService")
    def test_successful_archive(self, mock_service_class):
        """Test successful archive execution."""
        mock_service = Mock()
        mock_service_class.return_value = mock_service
        mock_service.archive_expired_events.return_value = {
            "eventsArchived": 150,
            "orgsProcessed": 3,
            "batchesProcessed": 5
        }

        result = archive_handler.handler({}, None)

        assert result["statusCode"] == 200
        assert result["body"]["eventsArchived"] == 150
        mock_service.archive_expired_events.assert_called_once_with(
            batch_size=1000
        )

    @patch("audit_service.handlers.archive_handler.AuditArchiveService")
    def test_no_events_to_archive(self, mock_service_class):
        """Test when no events need archiving."""
        mock_service = Mock()
        mock_service_class.return_value = mock_service
        mock_service.archive_expired_events.return_value = {
            "eventsArchived": 0,
            "orgsProcessed": 0
        }

        result = archive_handler.handler({}, None)

        assert result["statusCode"] == 200
        assert result["body"]["eventsArchived"] == 0

    @patch("audit_service.handlers.archive_handler.AuditArchiveService")
    def test_archive_error_returns_500(self, mock_service_class):
        """Test that archive errors return 500."""
        mock_service = Mock()
        mock_service_class.return_value = mock_service
        mock_service.archive_expired_events.side_effect = Exception(
            "S3 error"
        )

        result = archive_handler.handler({}, None)

        assert result["statusCode"] == 500
        assert "error" in result["body"]
```

---

## 13. Requirements and Configuration

### 13.1 requirements.txt

```
boto3>=1.34.0
botocore>=1.34.0
aws-lambda-powertools>=2.30.0
pydantic>=2.5.0
python-dateutil>=2.8.2

# Testing
pytest>=7.4.0
pytest-cov>=4.1.0
moto[all]>=4.2.0
```

### 13.2 pytest.ini

```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = -v --cov=audit_service --cov-report=term-missing --cov-fail-under=80
```

---

## 14. Success Criteria Checklist

- [x] All 6 Lambda handlers implemented
  - [x] query_org_handler
  - [x] query_user_handler
  - [x] query_resource_handler
  - [x] summary_handler
  - [x] export_handler
  - [x] archive_handler
- [x] AuditEvent model with event types
- [x] AuditLogger utility class for other services
- [x] Query by org, user, resource
- [x] Summary statistics
- [x] Export with presigned URLs
- [x] Archive scheduled handler
- [x] Compressed JSON storage (gzip)
- [x] TTL for DynamoDB (30 days)
- [x] Storage tiers (Hot 30d, Warm 90d, Cold 7y)
- [x] Tests with moto (DynamoDB + S3)
- [x] > 80% code coverage target

---

**Worker Status**: COMPLETE
**Completion Date**: 2026-01-23
**Output Location**: /Users/tebogotseka/Documents/agentic_work/2_bbws_docs/project_plans/project-plan-2-access-management/stage-3-lambda-services-development/worker-6-audit-service-lambdas/output.md
