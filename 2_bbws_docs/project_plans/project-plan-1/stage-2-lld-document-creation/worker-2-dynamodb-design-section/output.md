# Section 4: DynamoDB Table Design

**Document**: 2.1.8_LLD_S3_and_DynamoDB.md
**Section**: 4
**Worker**: worker-2-2-dynamodb-design-section
**Created**: 2025-12-25
**Status**: Complete

---

## 4.1 Overview

### 4.1.1 Purpose

DynamoDB tables serve as the primary data store for the BBWS Customer Portal Public application, supporting product catalog management, marketing campaigns, and tenant (customer) records. These tables provide:

- **Product Catalog**: Central repository for all WordPress hosting products with pricing and features
- **Campaign Management**: Marketing campaigns with time-based validity and product associations
- **Tenant Registry**: Customer tenant records with email-based identity and status lifecycle management

### 4.1.2 Design Philosophy

The DynamoDB design follows a **separate tables approach** rather than single-table design, with each domain entity stored in its own dedicated table:

| Table | Domain | Rationale |
|-------|--------|-----------|
| `tenants` | Customer/Tenant Management | Independent lifecycle from orders, email-based identity |
| `products` | Product Catalog | Standalone reference data, admin-managed |
| `campaigns` | Marketing Campaigns | Time-based promotional offers, product associations |

**Why Separate Tables:**

1. **Clear Separation of Concerns**: Each table has a single responsibility aligned with a domain entity
2. **Independent Scaling**: Each table can be monitored and scaled independently based on access patterns
3. **Simpler Access Control**: IAM policies can grant fine-grained permissions per table
4. **Migration Flexibility**: Individual tables can be migrated or replaced without impacting others
5. **Development Velocity**: Parallel development by different teams without schema conflicts
6. **Operational Clarity**: Backups, monitoring, and troubleshooting are table-specific

**Trade-offs Accepted:**

- Slightly higher cost (3 tables vs 1 table with composite keys)
- No cross-table transactions (acceptable for this use case - eventual consistency is sufficient)
- Multiple GSIs required (vs overloaded single-table GSIs)

### 4.1.3 Key Patterns Used

The DynamoDB table design implements three core patterns consistently across all tables:

#### 4.1.3.1 Soft Delete Pattern

All entities use a soft delete pattern with an `active` boolean field:

```json
{
  "active": true  // or false
}
```

**Implementation**:
- Default value: `true` (entity is active)
- Soft delete: Set `active=false` (entity is soft deleted)
- Query filter: All list queries filter by `active=true` by default
- Override: Use query parameter `includeInactive=true` to include soft-deleted records
- No physical DELETE operations in DynamoDB

**Rationale**:
- **Audit Trail Preservation**: Historical records maintained for compliance and analysis
- **Data Recovery**: Accidental deletes can be reversed by setting `active=true`
- **Referential Integrity**: Related entities can still reference soft-deleted items
- **Business Intelligence**: Analytics can include historical data trends
- **Compliance**: Meets data retention requirements (POPIA, GDPR)

**Example Query**:
```python
# Default: Active only
response = table.scan(
    FilterExpression=Attr('active').eq(True)
)

# Include inactive
response = table.scan(
    FilterExpression=Attr('active').eq(True) | Attr('active').eq(False)
)
```

#### 4.1.3.2 Activatable Entity Pattern

All entities follow the Activatable Entity Pattern with five mandatory fields:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `id` | String (UUID) | Yes | Generated | Unique identifier (UUID v4 format) |
| `dateCreated` | String (ISO 8601) | Yes | Auto | Creation timestamp (e.g., "2025-12-25T10:30:00Z") |
| `dateLastUpdated` | String (ISO 8601) | Yes | Auto | Last update timestamp (e.g., "2025-12-25T14:00:00Z") |
| `lastUpdatedBy` | String (email) | Yes | From context | User or system that made the last update |
| `active` | Boolean | Yes | `true` | Soft delete flag |

**Implementation Pattern**:
```python
import uuid
from datetime import datetime

def create_entity(entity_data, user_email):
    return {
        "id": str(uuid.uuid4()),
        "dateCreated": datetime.utcnow().isoformat() + "Z",
        "dateLastUpdated": datetime.utcnow().isoformat() + "Z",
        "lastUpdatedBy": user_email,
        "active": True,
        **entity_data  # Merge entity-specific fields
    }

def update_entity(existing_entity, updates, user_email):
    existing_entity.update({
        "dateLastUpdated": datetime.utcnow().isoformat() + "Z",
        "lastUpdatedBy": user_email,
        **updates
    })
    return existing_entity
```

**Benefits**:
- **Consistent Audit Trail**: Every entity tracks who created/updated it and when
- **Standardized Metadata**: All entities have the same base structure
- **Simplified Debugging**: Timestamps and user attribution aid troubleshooting
- **Data Governance**: Automated compliance with data lineage requirements

#### 4.1.3.3 Hierarchical Ownership Pattern

Entities are organized in a hierarchical ownership structure using Primary Key (PK) and Sort Key (SK) patterns:

```
TENANT (Root Entity)
├── PK: TENANT#{tenantId}
├── SK: METADATA
│
└── ORDER (Child Entity - not in this LLD scope)
    ├── PK: TENANT#{tenantId}
    ├── SK: ORDER#{orderId}
```

**Pattern Rules**:
- **Root Entities**: Use `PK={ENTITY}#{id}` and `SK=METADATA` (single item per PK)
- **Child Entities**: Inherit parent PK prefix and use `SK={CHILD}#{childId}` (multiple items per PK)
- **Standalone Entities**: No hierarchical dependency (e.g., Product, Campaign)

**Primary Key Patterns**:

| Entity | PK Pattern | SK Pattern | Purpose |
|--------|------------|------------|---------|
| Tenant | `TENANT#{tenantId}` | `METADATA` | Unique tenant identifier |
| Product | `PRODUCT#{productId}` | `METADATA` | Unique product identifier |
| Campaign | `CAMPAIGN#{code}` | `METADATA` | Campaign code (business key) |

**Query Benefits**:
- Get tenant: `GetItem(PK=TENANT#{tenantId}, SK=METADATA)`
- Get product: `GetItem(PK=PRODUCT#{productId}, SK=METADATA)`
- Get campaign by code: `GetItem(PK=CAMPAIGN#{code}, SK=METADATA)`

**Design Rationale**:
- **Explicit Ownership**: PK patterns make entity relationships clear
- **Efficient Queries**: Get item operations are single-digit millisecond latency
- **Data Locality**: Related items are stored together in the same partition
- **Future-Proof**: Hierarchical pattern supports future child entities (e.g., tenant orders)

---

## 4.2 Table: `tenants`

### 4.2.1 Table Schema

#### Table Configuration

| Setting | Value | Justification |
|---------|-------|---------------|
| **Table Name** | `tenants` | Simple domain name, environment isolated by AWS account |
| **Primary Key** | PK (String), SK (String) | Composite key supports hierarchical data model |
| **Capacity Mode** | ON_DEMAND | Variable traffic patterns, no capacity planning overhead |
| **Encryption** | AWS-managed (SSE-KMS) | Data protection at rest, no key management overhead |
| **PITR** | Enabled (all environments) | Point-in-time recovery for disaster recovery, 35-day retention |
| **Backups** | Hourly (PROD only via AWS Backup) | Automated backup retention: DEV 7 days, SIT 14 days, PROD 90 days |
| **Deletion Protection** | Enabled (PROD only) | Prevent accidental table deletion in production |
| **Streams** | Enabled (New and Old Images) | Change data capture for auditing and event-driven workflows |
| **TTL** | Not enabled | No automatic expiration needed for tenant records |

#### Attribute Definitions

| Attribute | Type | Key | Required | Default | Description |
|-----------|------|-----|----------|---------|-------------|
| `PK` | String | Partition Key | Yes | - | Primary key: `TENANT#{tenantId}` |
| `SK` | String | Sort Key | Yes | - | Sort key: `METADATA` (single item per tenant) |
| `id` | String | - | Yes | UUID v4 | Unique tenant identifier (e.g., "tenant_bb0e8400-e29b-41d4-a716-446655440006") |
| `email` | String | GSI PK | Yes | - | Customer email address (unique, used for lookup via EmailIndex) |
| `status` | String | GSI PK | Yes | - | Tenant lifecycle status: UNVALIDATED \| VALIDATED \| REGISTERED \| SUSPENDED |
| `organizationName` | String | - | No | - | Organization name (for business tenants) |
| `destinationEmail` | String | - | No | - | Destination email for form submissions (defaults to `email` if not set) |
| `active` | Boolean | GSI PK | Yes | `true` | Soft delete flag (true=active, false=soft deleted) |
| `dateCreated` | String | - | Yes | Auto | Creation timestamp (ISO 8601 format: "2025-12-25T10:30:00Z") |
| `dateLastUpdated` | String | - | Yes | Auto | Last update timestamp (ISO 8601 format: "2025-12-25T14:00:00Z") |
| `lastUpdatedBy` | String | - | Yes | From context | User/system email that made the last update |

**Attribute Type Mapping (DynamoDB)**:
```json
{
  "AttributeDefinitions": [
    { "AttributeName": "PK", "AttributeType": "S" },
    { "AttributeName": "SK", "AttributeType": "S" },
    { "AttributeName": "email", "AttributeType": "S" },
    { "AttributeName": "status", "AttributeType": "S" },
    { "AttributeName": "active", "AttributeType": "S" },
    { "AttributeName": "dateCreated", "AttributeType": "S" }
  ]
}
```

**Note**: Only attributes used in keys (PK, SK) or GSI keys need to be defined in `AttributeDefinitions`. Other attributes are schema-less and can be added to items without table schema changes.

#### Example Item

```json
{
  "PK": "TENANT#tenant_bb0e8400-e29b-41d4-a716-446655440006",
  "SK": "METADATA",
  "id": "tenant_bb0e8400-e29b-41d4-a716-446655440006",
  "email": "customer@example.com",
  "status": "VALIDATED",
  "organizationName": "Example Corp",
  "destinationEmail": "forms@example.com",
  "active": true,
  "dateCreated": "2025-12-19T10:30:00Z",
  "dateLastUpdated": "2025-12-19T14:00:00Z",
  "lastUpdatedBy": "system@kimmyai.io"
}
```

### 4.2.2 Primary Key Design

#### Key Structure

| Key Component | Pattern | Example | Purpose |
|---------------|---------|---------|---------|
| Partition Key (PK) | `TENANT#{tenantId}` | `TENANT#tenant_bb0e8400-e29b-41d4-a716-446655440006` | Unique tenant identifier |
| Sort Key (SK) | `METADATA` | `METADATA` | Single item per tenant (no child items yet) |

#### Design Justification

**PK Pattern: `TENANT#{tenantId}`**

The partition key uses a prefixed UUID pattern for the following reasons:

1. **Namespace Isolation**: The `TENANT#` prefix distinguishes tenant records from other entity types if future entities share the same table
2. **Human Readability**: Clear entity type identification in CloudWatch logs and debugging
3. **Collision Avoidance**: UUID v4 ensures globally unique identifiers with negligible collision probability
4. **Deterministic Access**: Tenant ID is known at query time, enabling efficient GetItem operations
5. **Even Distribution**: UUID randomness ensures even distribution across DynamoDB partitions

**SK Pattern: `METADATA`**

The sort key uses a static `METADATA` value because:

1. **Single Item Per Tenant**: Each tenant has one record in this table (no child items)
2. **Future Extensibility**: SK pattern supports future child items (e.g., `TENANT#{id}` with `SK=PROFILE`, `SK=SETTINGS`)
3. **Consistent Pattern**: Aligns with DynamoDB best practices for single-item root entities
4. **Query Simplicity**: GetItem operations are straightforward with fixed SK value

**Alternative Patterns Considered and Rejected**:

| Pattern | Why Rejected |
|---------|--------------|
| PK=email, SK=METADATA | Email is not immutable (can change), would require migration |
| PK=tenantId (no prefix) | Loses namespace clarity, harder to debug multi-table systems |
| Single-table design with PK=TENANT#{id}#METADATA | Unnecessary complexity for separate table approach |

#### Access Pattern Efficiency

| Operation | Key Condition | Complexity | Latency |
|-----------|---------------|------------|---------|
| Get tenant by ID | `PK = TENANT#{id}` AND `SK = METADATA` | O(1) | Single-digit ms |
| Get tenant by email | Use `EmailIndex` GSI | O(1) | Single-digit ms |
| List all tenants | Scan with filter `active=true` | O(n) | Varies by table size |

### 4.2.3 Global Secondary Indexes

The `tenants` table has three Global Secondary Indexes (GSIs) to support various query patterns:

#### GSI 1: EmailIndex

**Purpose**: Lookup tenant by email address (primary use case: tenant auto-creation at checkout)

| Setting | Value | Justification |
|---------|-------|---------------|
| **Index Name** | `EmailIndex` | Descriptive name following pattern `{Attribute}Index` |
| **Partition Key** | `email` (String) | Email address is unique per tenant |
| **Sort Key** | None | One-to-one relationship (email → tenant) |
| **Projection Type** | `ALL` | Include all attributes to avoid base table reads |
| **Capacity Mode** | ON_DEMAND (inherited) | Matches base table billing mode |

**Use Case**:
```python
# Find tenant by email during checkout
response = table.query(
    IndexName='EmailIndex',
    KeyConditionExpression=Key('email').eq('customer@example.com')
)

if response['Items']:
    tenant = response['Items'][0]  # Email is unique
else:
    # Create new tenant
    tenant = create_tenant(email='customer@example.com')
```

**Cost Implications**:
- **Projection Type: ALL** → Higher storage cost (duplicate data) but no base table reads (lower query cost)
- **Alternative**: `KEYS_ONLY` projection would save storage but require additional GetItem calls
- **Decision**: ALL projection chosen because tenant records are small (<1KB) and query latency is critical

**Query Performance**:
- Latency: Single-digit milliseconds (similar to base table GetItem)
- Consistency: Eventually consistent reads (acceptable for this use case)
- Hot Partitions: Unlikely (email queries are evenly distributed)

#### GSI 2: TenantStatusIndex

**Purpose**: List tenants by lifecycle status (e.g., all UNVALIDATED tenants for batch processing)

| Setting | Value | Justification |
|---------|-------|---------------|
| **Index Name** | `TenantStatusIndex` | Descriptive name following pattern `{Entity}{Attribute}Index` |
| **Partition Key** | `status` (String) | Group tenants by status: UNVALIDATED, VALIDATED, REGISTERED, SUSPENDED |
| **Sort Key** | `dateCreated` (String) | Sort by creation timestamp (oldest first or newest first) |
| **Projection Type** | `ALL` | Include all attributes to avoid base table reads |
| **Capacity Mode** | ON_DEMAND (inherited) | Matches base table billing mode |

**Use Case**:
```python
# Get all UNVALIDATED tenants created in the last 24 hours
yesterday = (datetime.utcnow() - timedelta(days=1)).isoformat() + "Z"

response = table.query(
    IndexName='TenantStatusIndex',
    KeyConditionExpression=Key('status').eq('UNVALIDATED') & Key('dateCreated').gte(yesterday),
    ScanIndexForward=False  # Sort descending (newest first)
)

for tenant in response['Items']:
    send_validation_reminder(tenant)
```

**Query Patterns**:
- List all tenants by status (e.g., "show me all SUSPENDED tenants")
- List tenants by status created within a date range
- Count tenants by status (for metrics and dashboards)

**Partition Distribution**:
- Status values: UNVALIDATED, VALIDATED, REGISTERED, SUSPENDED (4 partitions)
- Distribution depends on tenant lifecycle (most will be REGISTERED)
- Hot partition risk: REGISTERED status may become a hot partition at scale
- Mitigation: Sort key (dateCreated) provides range query capability to limit result set

**Cost-Benefit Analysis**:
- **Benefit**: Enables business-critical queries (e.g., "send reminders to UNVALIDATED tenants")
- **Cost**: Additional write cost (every status change writes to GSI), storage duplication
- **Decision**: Benefits outweigh costs for this use case

#### GSI 3: ActiveIndex (Sparse Index)

**Purpose**: Filter tenants by active status (exclude soft-deleted tenants)

| Setting | Value | Justification |
|---------|-------|---------------|
| **Index Name** | `ActiveIndex` | Descriptive name following pattern `{Attribute}Index` |
| **Partition Key** | `active` (String) | Boolean stored as string: "true" or "false" |
| **Sort Key** | `dateCreated` (String) | Sort by creation timestamp |
| **Projection Type** | `ALL` | Include all attributes to avoid base table reads |
| **Capacity Mode** | ON_DEMAND (inherited) | Matches base table billing mode |
| **Sparse Index** | Yes | Only items with `active` attribute are indexed |

**Use Case**:
```python
# List all active tenants (exclude soft-deleted)
response = table.query(
    IndexName='ActiveIndex',
    KeyConditionExpression=Key('active').eq('true'),
    ScanIndexForward=False  # Sort descending (newest first)
)

for tenant in response['Items']:
    process_active_tenant(tenant)
```

**Sparse Index Pattern**:
- **Sparse**: Only items with `active` attribute are included in the index
- **Storage Savings**: If most tenants are active (`active=true`), soft-deleted tenants (`active=false`) would not be indexed
- **In Practice**: This is NOT truly sparse because all tenants have `active` attribute (required field)
- **Future Optimization**: If soft deletes are rare, could omit `active=false` from index by not writing it

**Partition Distribution**:
- Two partitions: `active=true` and `active=false`
- Hot partition risk: `active=true` partition will contain most tenants
- Mitigation: Sort key (dateCreated) provides range query capability

**Query Patterns**:
- List all active tenants (default view in admin portal)
- List soft-deleted tenants (for recovery/audit)
- Count active vs inactive tenants (for metrics)

**Alternative Approaches Considered**:

| Approach | Why Not Used |
|----------|--------------|
| Filter expression on base table scan | O(n) complexity, high read cost at scale |
| Application-level filtering | Requires reading all items, inefficient |
| Separate table for deleted items | Adds complexity, duplication |

### 4.2.4 Access Patterns

The `tenants` table supports the following access patterns:

#### AP-1: Get Tenant by ID

**Use Case**: Retrieve tenant details when tenant ID is known (e.g., from JWT token, order record)

**Method**: `GetItem`

**Key Condition**:
```python
response = table.get_item(
    Key={
        'PK': f'TENANT#{tenant_id}',
        'SK': 'METADATA'
    }
)
tenant = response.get('Item')
```

**Performance**:
- Latency: Single-digit milliseconds (direct partition read)
- Cost: 1 RCU per 4KB item (on-demand pricing: $0.25 per million reads)
- Consistency: Strongly consistent read

**Example**:
```python
tenant_id = "tenant_bb0e8400-e29b-41d4-a716-446655440006"
tenant = get_tenant_by_id(tenant_id)
# Returns: { "id": "...", "email": "...", "status": "VALIDATED", ... }
```

#### AP-2: Get Tenant by Email

**Use Case**: Find existing tenant by email during checkout (tenant auto-creation)

**Method**: `Query` on `EmailIndex` GSI

**Key Condition**:
```python
response = table.query(
    IndexName='EmailIndex',
    KeyConditionExpression=Key('email').eq(customer_email)
)

if response['Items']:
    tenant = response['Items'][0]  # Email is unique
else:
    tenant = None  # Create new tenant
```

**Performance**:
- Latency: Single-digit milliseconds (GSI query)
- Cost: 1 RCU per 4KB item (on-demand pricing: $0.25 per million reads)
- Consistency: Eventually consistent (acceptable for this use case)

**Business Logic**:
```python
def get_or_create_tenant(email):
    # Check if tenant exists
    tenant = get_tenant_by_email(email)

    if tenant:
        # Existing tenant, reuse
        return tenant
    else:
        # New tenant, auto-create
        return create_tenant(
            email=email,
            status='UNVALIDATED',
            active=True
        )
```

#### AP-3: List All Tenants with Pagination

**Use Case**: Admin portal tenant management (list all tenants with pagination)

**Method**: `Scan` with filter expression

**Query**:
```python
response = table.scan(
    FilterExpression=Attr('active').eq(True),
    Limit=page_size,
    ExclusiveStartKey=last_evaluated_key  # From previous page
)

tenants = response['Items']
next_page_token = response.get('LastEvaluatedKey')
```

**Pagination Parameters**:
- `pageSize` (integer, optional): Number of items per page. Default: `50`, Max: `100`
- `startAt` (string, optional): Pagination token (base64 encoded `LastEvaluatedKey`)
- `moreAvailable` (boolean, response): True if more items exist

**Performance**:
- Latency: Varies by table size (scans entire table)
- Cost: 1 RCU per 4KB scanned (not just returned items)
- Optimization: Use `ActiveIndex` GSI query instead of scan for better performance

**Improved Version Using ActiveIndex**:
```python
response = table.query(
    IndexName='ActiveIndex',
    KeyConditionExpression=Key('active').eq('true'),
    Limit=page_size,
    ExclusiveStartKey=last_evaluated_key,
    ScanIndexForward=False  # Newest first
)
```

#### AP-4: List Tenants by Status

**Use Case**: Admin portal filtered views (e.g., "show all UNVALIDATED tenants")

**Method**: `Query` on `TenantStatusIndex` GSI

**Query**:
```python
response = table.query(
    IndexName='TenantStatusIndex',
    KeyConditionExpression=Key('status').eq('UNVALIDATED'),
    ScanIndexForward=False  # Newest first
)

tenants = response['Items']
```

**Supported Filters**:
- Status: UNVALIDATED, VALIDATED, REGISTERED, SUSPENDED
- Date range: Created after/before specific date

**Example with Date Range**:
```python
# Get UNVALIDATED tenants created in the last 7 days
seven_days_ago = (datetime.utcnow() - timedelta(days=7)).isoformat() + "Z"

response = table.query(
    IndexName='TenantStatusIndex',
    KeyConditionExpression=Key('status').eq('UNVALIDATED') & Key('dateCreated').gte(seven_days_ago)
)
```

#### AP-5: Create Tenant

**Use Case**: Auto-create tenant during checkout or manual admin creation

**Method**: `PutItem`

**Operation**:
```python
from uuid import uuid4
from datetime import datetime

def create_tenant(email, status='UNVALIDATED', organization_name=None):
    tenant_id = f"tenant_{uuid4()}"
    now = datetime.utcnow().isoformat() + "Z"

    item = {
        'PK': f'TENANT#{tenant_id}',
        'SK': 'METADATA',
        'id': tenant_id,
        'email': email,
        'status': status,
        'organizationName': organization_name,
        'active': True,
        'dateCreated': now,
        'dateLastUpdated': now,
        'lastUpdatedBy': 'system@kimmyai.io'
    }

    # Use ConditionExpression to prevent duplicate emails
    table.put_item(
        Item=item,
        ConditionExpression='attribute_not_exists(PK)'
    )

    return item
```

**Email Uniqueness Enforcement**:
- Check `EmailIndex` GSI before creation
- If email exists, return existing tenant (idempotent)
- Use conditional put to prevent race conditions

**Performance**:
- Latency: Single-digit milliseconds
- Cost: 1 WCU per 1KB item (on-demand pricing: $1.25 per million writes)
- GSI Updates: 3 WCUs total (base table + EmailIndex + TenantStatusIndex + ActiveIndex)

#### AP-6: Update Tenant Status

**Use Case**: Status lifecycle transitions (UNVALIDATED → VALIDATED → REGISTERED)

**Method**: `UpdateItem`

**Operation**:
```python
def update_tenant_status(tenant_id, new_status, updated_by):
    response = table.update_item(
        Key={
            'PK': f'TENANT#{tenant_id}',
            'SK': 'METADATA'
        },
        UpdateExpression='SET #status = :status, dateLastUpdated = :now, lastUpdatedBy = :user',
        ExpressionAttributeNames={
            '#status': 'status'  # 'status' is a reserved word
        },
        ExpressionAttributeValues={
            ':status': new_status,
            ':now': datetime.utcnow().isoformat() + "Z",
            ':user': updated_by
        },
        ReturnValues='ALL_NEW'
    )

    return response['Attributes']
```

**Status Lifecycle**:
```
UNVALIDATED (created at checkout, email not verified)
    ↓ (email OTP verification)
VALIDATED (email verified)
    ↓ (full Cognito registration)
REGISTERED (full account created)
    ↓ (admin action)
SUSPENDED (account suspended)
```

**Business Rules**:
- UNVALIDATED → VALIDATED: Requires email OTP verification
- VALIDATED → REGISTERED: Requires full Cognito registration
- Any status → SUSPENDED: Admin action only
- SUSPENDED → REGISTERED: Requires admin approval

#### AP-7: Soft Delete Tenant

**Use Case**: Deactivate tenant without physical deletion

**Method**: `UpdateItem`

**Operation**:
```python
def soft_delete_tenant(tenant_id, deleted_by):
    response = table.update_item(
        Key={
            'PK': f'TENANT#{tenant_id}',
            'SK': 'METADATA'
        },
        UpdateExpression='SET active = :false, dateLastUpdated = :now, lastUpdatedBy = :user',
        ExpressionAttributeValues={
            ':false': False,
            ':now': datetime.utcnow().isoformat() + "Z",
            ':user': deleted_by
        },
        ReturnValues='ALL_NEW'
    )

    return response['Attributes']
```

**No Physical DELETE**:
- No `DeleteItem` operations allowed
- Soft delete sets `active=false`
- Default queries filter `active=true`
- Override with `includeInactive=true` query parameter

**Recovery**:
```python
def restore_tenant(tenant_id, restored_by):
    response = table.update_item(
        Key={
            'PK': f'TENANT#{tenant_id}',
            'SK': 'METADATA'
        },
        UpdateExpression='SET active = :true, dateLastUpdated = :now, lastUpdatedBy = :user',
        ExpressionAttributeValues={
            ':true': True,
            ':now': datetime.utcnow().isoformat() + "Z",
            ':user': restored_by
        },
        ReturnValues='ALL_NEW'
    )

    return response['Attributes']
```

### 4.2.5 Business Rules

#### Rule 1: Tenant Auto-Creation at Checkout

**Trigger**: Customer enters email at checkout

**Logic**:
1. Query `EmailIndex` GSI for existing tenant with email
2. If tenant exists:
   - Reuse existing tenant (return tenant record)
   - Do NOT create duplicate tenant
3. If tenant does not exist:
   - Auto-create new tenant with `status=UNVALIDATED`
   - Email will be used for order confirmation
   - User can register later to link order history

**Implementation**:
```python
def get_or_create_tenant_at_checkout(email):
    # Check if tenant exists
    response = table.query(
        IndexName='EmailIndex',
        KeyConditionExpression=Key('email').eq(email)
    )

    if response['Items']:
        # Tenant exists, reuse
        tenant = response['Items'][0]
        logger.info(f"Reusing existing tenant: {tenant['id']}")
        return tenant
    else:
        # Tenant does not exist, auto-create
        tenant = create_tenant(
            email=email,
            status='UNVALIDATED',
            organization_name=None  # Not collected at checkout
        )
        logger.info(f"Created new tenant: {tenant['id']}")
        return tenant
```

**Business Benefit**: Reduces checkout friction, increases conversion rate

#### Rule 2: Email Uniqueness Enforcement

**Constraint**: One tenant per email address

**Enforcement Mechanism**:
1. **EmailIndex GSI**: Email is partition key (unique lookup)
2. **Pre-creation Check**: Query EmailIndex before creating tenant
3. **Idempotent Creation**: Return existing tenant if email already exists

**Edge Case Handling**:
- **Race Condition**: Two simultaneous checkout requests with same email
  - **Solution**: Use conditional put with `attribute_not_exists(PK)` for tenant ID
  - **Outcome**: One request succeeds, other fails and retries with EmailIndex check
- **Email Change**: If user wants to change email
  - **Solution**: Do NOT allow email changes (email is identity)
  - **Alternative**: Create new tenant with new email, migrate data

**Implementation**:
```python
def enforce_email_uniqueness(email):
    # Check EmailIndex
    response = table.query(
        IndexName='EmailIndex',
        KeyConditionExpression=Key('email').eq(email)
    )

    if response['Items']:
        raise ConflictError(f"Tenant with email '{email}' already exists")

    # Proceed with tenant creation
    # ...
```

#### Rule 3: Status Lifecycle Management

**Status Flow**:
```
UNVALIDATED → VALIDATED → REGISTERED → SUSPENDED
```

**Status Definitions**:

| Status | Definition | Trigger | Next Status |
|--------|------------|---------|-------------|
| UNVALIDATED | Created at checkout, email not verified | Auto-created at checkout | VALIDATED (email OTP verification) |
| VALIDATED | Email verified via OTP | User clicks email verification link | REGISTERED (full Cognito registration) |
| REGISTERED | Full Cognito registration complete | User completes registration form | SUSPENDED (admin action) |
| SUSPENDED | Account suspended | Admin action (e.g., fraud, policy violation) | REGISTERED (admin approval) |

**Validation Logic**:
```python
ALLOWED_TRANSITIONS = {
    'UNVALIDATED': ['VALIDATED'],
    'VALIDATED': ['REGISTERED'],
    'REGISTERED': ['SUSPENDED'],
    'SUSPENDED': ['REGISTERED']
}

def validate_status_transition(current_status, new_status):
    if new_status not in ALLOWED_TRANSITIONS.get(current_status, []):
        raise ValidationError(
            f"Invalid status transition: {current_status} → {new_status}"
        )
```

**Exception**: Admin users can transition to any status (with audit logging)

#### Rule 4: Soft Delete (No Physical Deletion)

**Policy**: No physical `DeleteItem` operations on tenant records

**Rationale**:
- **Audit Trail**: Historical records required for compliance (POPIA, GDPR)
- **Data Recovery**: Accidental deletes can be reversed
- **Referential Integrity**: Orders and payments reference tenant IDs
- **Analytics**: Historical data analysis requires complete tenant history

**Implementation**:
- **API Level**: No `DELETE /v1.0/tenants/{id}` endpoint
- **DynamoDB Level**: No `DeleteItem` operations in Lambda code
- **Soft Delete**: `PUT /v1.0/tenants/{id}` with body `{"active": false}`

**Query Behavior**:
- Default queries filter `active=true` (exclude soft-deleted)
- Admin queries can use `includeInactive=true` parameter
- Metrics count `active=true` tenants only

**Data Retention**:
- Soft-deleted tenants remain in DynamoDB indefinitely
- Future: Archive to S3 Glacier after 7 years (compliance requirement)

#### Rule 5: Organization and Destination Email (Optional)

**Fields**:
- `organizationName` (String, optional): For business tenants
- `destinationEmail` (String, optional): Where form submissions are sent

**Business Logic**:
- If `destinationEmail` is not set, use `email` field as destination
- If `organizationName` is set, tenant is a business account
- Individual accounts: `organizationName=null`

**Use Case**:
- Business tenant wants forms sent to `forms@company.com` (not personal email)
- Organization name displayed in admin portal tenant list

**Default Behavior**:
```python
def get_destination_email(tenant):
    return tenant.get('destinationEmail', tenant['email'])
```

---

## 4.3 Table: `products`

### 4.3.1 Table Schema

#### Table Configuration

| Setting | Value | Justification |
|---------|-------|---------------|
| **Table Name** | `products` | Simple domain name, environment isolated by AWS account |
| **Primary Key** | PK (String), SK (String) | Composite key supports hierarchical data model (future child items) |
| **Capacity Mode** | ON_DEMAND | Admin-managed table with low write volume, variable read patterns |
| **Encryption** | AWS-managed (SSE-KMS) | Data protection at rest, no key management overhead |
| **PITR** | Enabled (all environments) | Point-in-time recovery for disaster recovery, 35-day retention |
| **Backups** | Hourly (PROD only via AWS Backup) | Automated backup retention: DEV 7 days, SIT 14 days, PROD 90 days |
| **Deletion Protection** | Enabled (PROD only) | Prevent accidental table deletion in production |
| **Streams** | Enabled (New and Old Images) | Change data capture for price change auditing |
| **TTL** | Not enabled | No automatic expiration needed for products |

#### Attribute Definitions

| Attribute | Type | Key | Required | Default | Description |
|-----------|------|-----|----------|---------|-------------|
| `PK` | String | Partition Key | Yes | - | Primary key: `PRODUCT#{productId}` |
| `SK` | String | Sort Key | Yes | - | Sort key: `METADATA` (single item per product) |
| `id` | String | - | Yes | UUID v4 | Unique product identifier (e.g., "prod_550e8400-e29b-41d4-a716-446655440000") |
| `name` | String | - | Yes | - | Product name (e.g., "WordPress Professional Plan") |
| `description` | String | - | Yes | - | Product description (marketing copy) |
| `price` | Number | - | Yes | - | Product price in ZAR (decimal, e.g., 299.99) |
| `features` | List | - | No | [] | Array of feature strings (e.g., ["Up to 10 sites", "100GB storage"]) |
| `billingCycle` | String | - | Yes | - | Billing frequency: "monthly" \| "yearly" |
| `active` | Boolean | GSI PK | Yes | `true` | Soft delete flag (true=available, false=soft deleted) |
| `dateCreated` | String | - | Yes | Auto | Creation timestamp (ISO 8601 format: "2025-12-25T10:30:00Z") |
| `dateLastUpdated` | String | - | Yes | Auto | Last update timestamp (ISO 8601 format: "2025-12-25T14:00:00Z") |
| `lastUpdatedBy` | String | - | Yes | From context | Admin email that made the last update |

**Attribute Type Mapping (DynamoDB)**:
```json
{
  "AttributeDefinitions": [
    { "AttributeName": "PK", "AttributeType": "S" },
    { "AttributeName": "SK", "AttributeType": "S" },
    { "AttributeName": "active", "AttributeType": "S" },
    { "AttributeName": "dateCreated", "AttributeType": "S" }
  ]
}
```

#### Example Item

```json
{
  "PK": "PRODUCT#prod_550e8400-e29b-41d4-a716-446655440000",
  "SK": "METADATA",
  "id": "prod_550e8400-e29b-41d4-a716-446655440000",
  "name": "WordPress Professional Plan",
  "description": "Professional WordPress hosting with advanced features",
  "price": 299.99,
  "features": [
    "Up to 10 WordPress sites",
    "100GB storage",
    "Unlimited bandwidth",
    "Daily backups",
    "Priority support"
  ],
  "billingCycle": "monthly",
  "active": true,
  "dateCreated": "2025-12-19T10:30:00Z",
  "dateLastUpdated": "2025-12-19T14:00:00Z",
  "lastUpdatedBy": "admin@kimmyai.io"
}
```

### 4.3.2 Primary Key Design

#### Key Structure

| Key Component | Pattern | Example | Purpose |
|---------------|---------|---------|---------|
| Partition Key (PK) | `PRODUCT#{productId}` | `PRODUCT#prod_550e8400-e29b-41d4-a716-446655440000` | Unique product identifier |
| Sort Key (SK) | `METADATA` | `METADATA` | Single item per product (no child items yet) |

#### Design Justification

**PK Pattern: `PRODUCT#{productId}`**

The partition key uses a prefixed UUID pattern for consistency with other tables:

1. **Namespace Clarity**: `PRODUCT#` prefix distinguishes products from other entities
2. **UUID Uniqueness**: UUID v4 ensures globally unique identifiers
3. **Deterministic Access**: Product ID is known at query time (from URL, campaign reference)
4. **Even Distribution**: UUID randomness ensures even partition distribution
5. **Future-Proof**: Supports potential multi-table consolidation

**SK Pattern: `METADATA`**

The sort key uses a static `METADATA` value:

1. **Single Item Per Product**: Each product has one record in this table
2. **Consistent Pattern**: Aligns with tenant table design
3. **Future Extensibility**: Could support child items (e.g., `SK=PRICE_HISTORY`, `SK=REVIEWS`)

**Alternative Patterns Considered**:

| Pattern | Why Not Used |
|---------|--------------|
| PK=productId (no prefix) | Loses namespace clarity, inconsistent with tenant table |
| PK=name, SK=METADATA | Product name can change, not immutable |
| Composite SK with version | Products don't have versions (price changes are updates, not versions) |

#### Access Pattern Efficiency

| Operation | Key Condition | Complexity | Latency |
|-----------|---------------|------------|---------|
| Get product by ID | `PK = PRODUCT#{id}` AND `SK = METADATA` | O(1) | Single-digit ms |
| List all products | Scan with filter `active=true` | O(n) | Varies (small table, fast) |
| List active products | Query `ProductActiveIndex` | O(n) | Faster than scan |

### 4.3.3 Global Secondary Indexes

The `products` table has two Global Secondary Indexes (GSIs):

#### GSI 1: ProductActiveIndex

**Purpose**: List active products (exclude soft-deleted) for public pricing page

| Setting | Value | Justification |
|---------|-------|---------------|
| **Index Name** | `ProductActiveIndex` | Descriptive name following pattern `{Entity}{Attribute}Index` |
| **Partition Key** | `active` (String) | Boolean stored as string: "true" or "false" |
| **Sort Key** | `dateCreated` (String) | Sort by creation timestamp (oldest first or newest first) |
| **Projection Type** | `ALL` | Include all attributes (product records are small, < 1KB) |
| **Capacity Mode** | ON_DEMAND (inherited) | Matches base table billing mode |

**Use Case**:
```python
# List all active products for pricing page
response = table.query(
    IndexName='ProductActiveIndex',
    KeyConditionExpression=Key('active').eq('true'),
    ScanIndexForward=True  # Oldest first
)

products = response['Items']
```

**Query Patterns**:
- List all active products (default pricing page)
- List soft-deleted products (admin recovery view)
- Count active products (for metrics dashboard)

**Partition Distribution**:
- Two partitions: `active=true` and `active=false`
- Hot partition: `active=true` will contain most products (expected < 100 products)
- Scale consideration: Small table size, hot partition is acceptable

**Cost-Benefit**:
- **Benefit**: Avoids full table scan for pricing page (most common query)
- **Cost**: Minimal (small table, low write volume)
- **Decision**: Benefits outweigh costs

#### GSI 2: ActiveIndex (Sparse Index)

**Purpose**: Cross-entity active status filtering (shared pattern with tenants table)

| Setting | Value | Justification |
|---------|-------|---------------|
| **Index Name** | `ActiveIndex` | Descriptive name following pattern `{Attribute}Index` |
| **Partition Key** | `active` (String) | Boolean stored as string: "true" or "false" |
| **Sort Key** | `dateCreated` (String) | Sort by creation timestamp |
| **Projection Type** | `ALL` | Include all attributes |
| **Capacity Mode** | ON_DEMAND (inherited) | Matches base table billing mode |

**Use Case**:
```python
# List all active products (alternative to ProductActiveIndex)
response = table.query(
    IndexName='ActiveIndex',
    KeyConditionExpression=Key('active').eq('true')
)
```

**Note**: Functionally similar to `ProductActiveIndex`, but follows cross-table naming pattern for consistency.

### 4.3.4 Access Patterns

The `products` table supports the following access patterns:

#### AP-1: Get Product by ID

**Use Case**: Retrieve product details for pricing page, campaign association, order creation

**Method**: `GetItem`

**Operation**:
```python
response = table.get_item(
    Key={
        'PK': f'PRODUCT#{product_id}',
        'SK': 'METADATA'
    }
)
product = response.get('Item')
```

**Performance**:
- Latency: Single-digit milliseconds
- Cost: 1 RCU per 4KB item
- Consistency: Strongly consistent read

#### AP-2: List All Active Products

**Use Case**: Public pricing page display

**Method**: `Query` on `ProductActiveIndex` GSI

**Operation**:
```python
response = table.query(
    IndexName='ProductActiveIndex',
    KeyConditionExpression=Key('active').eq('true'),
    ScanIndexForward=True  # Oldest first (or False for newest)
)

products = response['Items']
```

**Pagination** (if > 100 products):
```python
response = table.query(
    IndexName='ProductActiveIndex',
    KeyConditionExpression=Key('active').eq('true'),
    Limit=page_size,
    ExclusiveStartKey=last_evaluated_key
)
```

#### AP-3: Create Product (Admin Only)

**Use Case**: Admin creates new product via Admin Portal

**Method**: `PutItem`

**Operation**:
```python
from uuid import uuid4
from datetime import datetime

def create_product(name, description, price, features, billing_cycle, admin_email):
    product_id = f"prod_{uuid4()}"
    now = datetime.utcnow().isoformat() + "Z"

    item = {
        'PK': f'PRODUCT#{product_id}',
        'SK': 'METADATA',
        'id': product_id,
        'name': name,
        'description': description,
        'price': price,
        'features': features,
        'billingCycle': billing_cycle,
        'active': True,
        'dateCreated': now,
        'dateLastUpdated': now,
        'lastUpdatedBy': admin_email
    }

    table.put_item(Item=item)
    return item
```

**Validation**:
- `price` > 0 (positive number)
- `name` not empty (required)
- `billingCycle` in ["monthly", "yearly"]

#### AP-4: Update Product (Price Changes, Feature Updates)

**Use Case**: Admin updates product price or features

**Method**: `UpdateItem`

**Operation**:
```python
def update_product(product_id, updates, admin_email):
    # Build update expression dynamically
    update_expr = 'SET dateLastUpdated = :now, lastUpdatedBy = :user'
    expr_values = {
        ':now': datetime.utcnow().isoformat() + "Z",
        ':user': admin_email
    }

    if 'price' in updates:
        update_expr += ', price = :price'
        expr_values[':price'] = updates['price']

    if 'description' in updates:
        update_expr += ', description = :desc'
        expr_values[':desc'] = updates['description']

    # Execute update
    response = table.update_item(
        Key={
            'PK': f'PRODUCT#{product_id}',
            'SK': 'METADATA'
        },
        UpdateExpression=update_expr,
        ExpressionAttributeValues=expr_values,
        ReturnValues='ALL_NEW'
    )

    return response['Attributes']
```

**Price Change Auditing**:
- DynamoDB Streams enabled (New and Old Images)
- Lambda trigger captures price changes and logs to CloudWatch
- Admin actions logged with `lastUpdatedBy` field

#### AP-5: Soft Delete Product

**Use Case**: Admin deactivates product (no longer offered)

**Method**: `UpdateItem`

**Operation**:
```python
def soft_delete_product(product_id, admin_email):
    response = table.update_item(
        Key={
            'PK': f'PRODUCT#{product_id}',
            'SK': 'METADATA'
        },
        UpdateExpression='SET active = :false, dateLastUpdated = :now, lastUpdatedBy = :user',
        ExpressionAttributeValues={
            ':false': False,
            ':now': datetime.utcnow().isoformat() + "Z",
            ':user': admin_email
        },
        ReturnValues='ALL_NEW'
    )

    return response['Attributes']
```

**Business Impact**:
- Soft-deleted products do NOT appear on pricing page
- Existing orders/campaigns referencing product are unaffected (data snapshot)
- Product can be restored by setting `active=true`

### 4.3.5 Business Rules

#### Rule 1: Product Lifecycle (Active/Inactive)

**States**:
- `active=true`: Product is available for purchase (appears on pricing page)
- `active=false`: Product is soft-deleted (hidden from pricing page, historical data retained)

**Transitions**:
- Admin creates product → `active=true`
- Admin soft-deletes product → `active=false`
- Admin restores product → `active=true`

**No Physical Deletion**: Products are never physically deleted from DynamoDB

#### Rule 2: Price Updates Are Immediate

**Behavior**: Price changes apply immediately to new orders

**Impact**:
- Existing orders: Use snapshot price (stored in OrderItem.unitPrice)
- Active campaigns: Use current price (recalculate discounted price)
- Future: Consider price history table for analytics

**Admin Warning**: "Changing price will affect all new orders immediately. Existing orders are unaffected."

#### Rule 3: Features List Is Flexible

**Schema**: `features` field is a list of strings (flexible, no fixed schema)

**Examples**:
```json
{
  "features": [
    "Up to 10 WordPress sites",
    "100GB storage",
    "Unlimited bandwidth"
  ]
}
```

**Admin Portal**: Dynamic form to add/remove features (array manipulation)

#### Rule 4: Billing Cycle Determines Pricing

**Supported Cycles**:
- `monthly`: Billed monthly
- `yearly`: Billed annually (future: discount for annual plans)

**Future Enhancement**: Support both monthly and yearly pricing in same product (e.g., `pricingTiers` array)

---

## 4.4 Table: `campaigns`

### 4.4.1 Table Schema

#### Table Configuration

| Setting | Value | Justification |
|---------|-------|---------------|
| **Table Name** | `campaigns` | Simple domain name, environment isolated by AWS account |
| **Primary Key** | PK (String), SK (String) | Composite key supports hierarchical data model (future child items) |
| **Capacity Mode** | ON_DEMAND | Low write volume, variable read patterns (campaign landing pages) |
| **Encryption** | AWS-managed (SSE-KMS) | Data protection at rest, no key management overhead |
| **PITR** | Enabled (all environments) | Point-in-time recovery for disaster recovery, 35-day retention |
| **Backups** | Hourly (PROD only via AWS Backup) | Automated backup retention: DEV 7 days, SIT 14 days, PROD 90 days |
| **Deletion Protection** | Enabled (PROD only) | Prevent accidental table deletion in production |
| **Streams** | Enabled (New and Old Images) | Change data capture for campaign modification auditing |
| **TTL** | Not enabled | Campaigns remain in table after expiration (for historical reporting) |

#### Attribute Definitions

| Attribute | Type | Key | Required | Default | Description |
|-----------|------|-----|----------|---------|-------------|
| `PK` | String | Partition Key | Yes | - | Primary key: `CAMPAIGN#{code}` (business key, not UUID) |
| `SK` | String | Sort Key | Yes | - | Sort key: `METADATA` (single item per campaign) |
| `id` | String | - | Yes | UUID v4 | Unique campaign identifier (e.g., "camp_770e8400-e29b-41d4-a716-446655440002") |
| `code` | String | - | Yes | - | Campaign code (e.g., "SUMMER2025", used in PK and URLs) |
| `description` | String | - | Yes | - | Campaign description (e.g., "Summer 2025 Special Offer") |
| `discountPercentage` | Number | - | Yes | - | Discount percentage (0-100, e.g., 20.0 = 20% off) |
| `productId` | String | GSI PK | Yes | - | Associated product UUID (e.g., "prod_550e8400...") |
| `termsConditionsLink` | String | - | Yes | - | URL to campaign terms and conditions |
| `fromDate` | String | GSI SK | Yes | - | Campaign start date (ISO 8601 date: "2025-06-01") |
| `toDate` | String | - | Yes | - | Campaign end date (ISO 8601 date: "2025-08-31") |
| `active` | Boolean | GSI PK | Yes | `true` | Soft delete flag (true=active, false=soft deleted) |
| `dateCreated` | String | - | Yes | Auto | Creation timestamp (ISO 8601: "2025-12-25T10:30:00Z") |
| `dateLastUpdated` | String | - | Yes | Auto | Last update timestamp (ISO 8601: "2025-12-25T14:00:00Z") |
| `lastUpdatedBy` | String | - | Yes | From context | Admin email that made the last update |

**Computed Attributes** (returned in GET responses, not stored):
- `productName` (String): Fetched from Product table using `productId`
- `originalPrice` (Number): Fetched from Product table
- `discountedPrice` (Number): Calculated as `originalPrice * (1 - discountPercentage/100)`
- `isValid` (Boolean): Computed as `current_date >= fromDate AND current_date <= toDate AND active=true`

**Attribute Type Mapping (DynamoDB)**:
```json
{
  "AttributeDefinitions": [
    { "AttributeName": "PK", "AttributeType": "S" },
    { "AttributeName": "SK", "AttributeType": "S" },
    { "AttributeName": "active", "AttributeType": "S" },
    { "AttributeName": "productId", "AttributeType": "S" },
    { "AttributeName": "fromDate", "AttributeType": "S" },
    { "AttributeName": "dateCreated", "AttributeType": "S" }
  ]
}
```

#### Example Item

```json
{
  "PK": "CAMPAIGN#SUMMER2025",
  "SK": "METADATA",
  "id": "camp_770e8400-e29b-41d4-a716-446655440002",
  "code": "SUMMER2025",
  "description": "Summer 2025 Special Offer - 20% off all WordPress plans",
  "discountPercentage": 20.0,
  "productId": "prod_550e8400-e29b-41d4-a716-446655440000",
  "termsConditionsLink": "https://kimmyai.io/terms/campaigns/summer2025",
  "fromDate": "2025-06-01",
  "toDate": "2025-08-31",
  "active": true,
  "dateCreated": "2025-12-19T10:30:00Z",
  "dateLastUpdated": "2025-12-19T10:30:00Z",
  "lastUpdatedBy": "admin@kimmyai.io"
}
```

**Enriched Response Example** (with computed attributes):
```json
{
  "id": "camp_770e8400-e29b-41d4-a716-446655440002",
  "code": "SUMMER2025",
  "description": "Summer 2025 Special Offer - 20% off all WordPress plans",
  "discountPercentage": 20.0,
  "productId": "prod_550e8400-e29b-41d4-a716-446655440000",
  "productName": "WordPress Professional Plan",
  "originalPrice": 299.99,
  "discountedPrice": 239.99,
  "termsConditionsLink": "https://kimmyai.io/terms/campaigns/summer2025",
  "fromDate": "2025-06-01",
  "toDate": "2025-08-31",
  "isValid": true,
  "active": true,
  "dateCreated": "2025-12-19T10:30:00Z",
  "dateLastUpdated": "2025-12-19T10:30:00Z",
  "lastUpdatedBy": "admin@kimmyai.io"
}
```

### 4.4.2 Primary Key Design

#### Key Structure

| Key Component | Pattern | Example | Purpose |
|---------------|---------|---------|---------|
| Partition Key (PK) | `CAMPAIGN#{code}` | `CAMPAIGN#SUMMER2025` | Campaign code (business key used in URLs) |
| Sort Key (SK) | `METADATA` | `METADATA` | Single item per campaign |

#### Design Justification

**PK Pattern: `CAMPAIGN#{code}`**

The partition key uses campaign **code** (not UUID) for the following reasons:

1. **Business Key**: Campaign code is the natural identifier used in marketing URLs (e.g., `https://kimmyai.io/campaigns/SUMMER2025`)
2. **Human-Readable**: Codes like "SUMMER2025" are easier to remember and communicate than UUIDs
3. **URL Compatibility**: Code can be used directly in URL path without mapping
4. **Deterministic Access**: Code is known at query time (from URL parameter, checkout form)
5. **Uniqueness**: Campaign codes are globally unique (enforced by admin portal)

**Trade-off**: Campaign code cannot be changed after creation (PK is immutable). If code change is needed, create new campaign and soft-delete old one.

**SK Pattern: `METADATA`**

The sort key uses a static `METADATA` value:

1. **Single Item Per Campaign**: Each campaign has one record
2. **Consistent Pattern**: Aligns with tenant and product table designs
3. **Future Extensibility**: Could support child items (e.g., `SK=ANALYTICS`, `SK=REDEMPTIONS`)

**Alternative Patterns Considered**:

| Pattern | Why Not Used |
|---------|--------------|
| PK=CAMPAIGN#{id}, SK=METADATA | Loses direct URL access, requires code→id mapping |
| PK=productId, SK=CAMPAIGN#{code} | Campaign is not child of product (weak reference) |
| PK=code (no prefix) | Loses namespace clarity, inconsistent with other tables |

#### Access Pattern Efficiency

| Operation | Key Condition | Complexity | Latency |
|-----------|---------------|------------|---------|
| Get campaign by code | `PK = CAMPAIGN#{code}` AND `SK = METADATA` | O(1) | Single-digit ms |
| List campaigns by product | Query `CampaignProductIndex` | O(n) | Fast (small table) |
| List active campaigns | Query `CampaignActiveIndex` | O(n) | Fast (small table) |

### 4.4.3 Global Secondary Indexes

The `campaigns` table has three Global Secondary Indexes (GSIs):

#### GSI 1: CampaignActiveIndex

**Purpose**: List active campaigns sorted by start date (for marketing dashboard)

| Setting | Value | Justification |
|---------|-------|---------------|
| **Index Name** | `CampaignActiveIndex` | Descriptive name following pattern `{Entity}{Attribute}Index` |
| **Partition Key** | `active` (String) | Boolean stored as string: "true" or "false" |
| **Sort Key** | `fromDate` (String) | Sort by campaign start date (ISO 8601 date format) |
| **Projection Type** | `ALL` | Include all attributes (campaign records are small, < 1KB) |
| **Capacity Mode** | ON_DEMAND (inherited) | Matches base table billing mode |

**Use Case**:
```python
# List all active campaigns sorted by start date
response = table.query(
    IndexName='CampaignActiveIndex',
    KeyConditionExpression=Key('active').eq('true'),
    ScanIndexForward=False  # Newest campaigns first
)

campaigns = response['Items']
```

**Query Patterns**:
- List all active campaigns (marketing dashboard)
- List upcoming campaigns (fromDate > today)
- List expired campaigns (toDate < today)

**Partition Distribution**:
- Two partitions: `active=true` and `active=false`
- Hot partition: `active=true` (expected < 50 campaigns at any time)
- Scale consideration: Small table size, hot partition is acceptable

#### GSI 2: CampaignProductIndex

**Purpose**: List campaigns for a specific product (admin view, pricing page)

| Setting | Value | Justification |
|---------|-------|---------------|
| **Index Name** | `CampaignProductIndex` | Descriptive name following pattern `{Entity}{ForeignKey}Index` |
| **Partition Key** | `productId` (String) | Product UUID (foreign key reference) |
| **Sort Key** | `fromDate` (String) | Sort by campaign start date |
| **Projection Type** | `ALL` | Include all attributes |
| **Capacity Mode** | ON_DEMAND (inherited) | Matches base table billing mode |

**Use Case**:
```python
# Get all campaigns for a product
response = table.query(
    IndexName='CampaignProductIndex',
    KeyConditionExpression=Key('productId').eq(product_id),
    ScanIndexForward=False  # Newest campaigns first
)

campaigns = response['Items']
```

**Query Patterns**:
- "Show all campaigns for WordPress Professional Plan"
- "Are there any active campaigns for this product?"
- Analytics: Campaign effectiveness per product

**Partition Distribution**:
- One partition per product (expected < 10 products)
- Even distribution across products (each product has a few campaigns)

#### GSI 3: ActiveIndex (Sparse Index)

**Purpose**: Cross-entity active status filtering (shared pattern)

| Setting | Value | Justification |
|---------|-------|---------------|
| **Index Name** | `ActiveIndex` | Descriptive name following pattern `{Attribute}Index` |
| **Partition Key** | `active` (String) | Boolean stored as string: "true" or "false" |
| **Sort Key** | `dateCreated` (String) | Sort by creation timestamp |
| **Projection Type** | `ALL` | Include all attributes |
| **Capacity Mode** | ON_DEMAND (inherited) | Matches base table billing mode |

**Use Case**:
```python
# List all active campaigns (alternative to CampaignActiveIndex)
response = table.query(
    IndexName='ActiveIndex',
    KeyConditionExpression=Key('active').eq('true')
)
```

**Note**: Functionally similar to `CampaignActiveIndex`, but sorted by `dateCreated` instead of `fromDate`.

### 4.4.4 Access Patterns

The `campaigns` table supports the following access patterns:

#### AP-1: Get Campaign by Code

**Use Case**: Retrieve campaign details for landing page (e.g., `/campaigns/SUMMER2025`)

**Method**: `GetItem`

**Operation**:
```python
def get_campaign_by_code(code):
    response = table.get_item(
        Key={
            'PK': f'CAMPAIGN#{code}',
            'SK': 'METADATA'
        }
    )
    campaign = response.get('Item')

    if campaign:
        # Enrich with product data
        product = get_product(campaign['productId'])
        campaign['productName'] = product['name']
        campaign['originalPrice'] = product['price']
        campaign['discountedPrice'] = calculate_discounted_price(
            product['price'], campaign['discountPercentage']
        )
        campaign['isValid'] = is_campaign_valid(campaign)

    return campaign

def is_campaign_valid(campaign):
    today = datetime.utcnow().date().isoformat()
    return (
        campaign['active'] and
        campaign['fromDate'] <= today <= campaign['toDate']
    )

def calculate_discounted_price(original_price, discount_percentage):
    return round(original_price * (1 - discount_percentage / 100), 2)
```

**Performance**:
- Latency: Single-digit milliseconds (GetItem + GetItem for product)
- Cost: 2 RCUs (1 for campaign, 1 for product)
- Consistency: Strongly consistent read

#### AP-2: List Active Campaigns

**Use Case**: Marketing dashboard, campaign selection dropdown

**Method**: `Query` on `CampaignActiveIndex` GSI

**Operation**:
```python
def list_active_campaigns(valid_only=False):
    response = table.query(
        IndexName='CampaignActiveIndex',
        KeyConditionExpression=Key('active').eq('true'),
        ScanIndexForward=False  # Newest first
    )

    campaigns = response['Items']

    # Filter by date validity if requested
    if valid_only:
        today = datetime.utcnow().date().isoformat()
        campaigns = [
            c for c in campaigns
            if c['fromDate'] <= today <= c['toDate']
        ]

    # Enrich with product data
    for campaign in campaigns:
        product = get_product(campaign['productId'])
        campaign['productName'] = product['name']
        campaign['originalPrice'] = product['price']
        campaign['discountedPrice'] = calculate_discounted_price(
            product['price'], campaign['discountPercentage']
        )

    return campaigns
```

**Query Parameter**: `validOnly=true` filters campaigns by date range

#### AP-3: List Campaigns by Product

**Use Case**: Admin view "All campaigns for WordPress Professional Plan"

**Method**: `Query` on `CampaignProductIndex` GSI

**Operation**:
```python
def list_campaigns_by_product(product_id):
    response = table.query(
        IndexName='CampaignProductIndex',
        KeyConditionExpression=Key('productId').eq(product_id),
        ScanIndexForward=False  # Newest first
    )

    return response['Items']
```

#### AP-4: Create Campaign (Admin Only)

**Use Case**: Admin creates new marketing campaign

**Method**: `PutItem`

**Operation**:
```python
from uuid import uuid4
from datetime import datetime

def create_campaign(code, description, discount_percentage, product_id,
                     terms_link, from_date, to_date, admin_email):
    # Validate campaign code uniqueness
    existing = get_campaign_by_code(code)
    if existing:
        raise ConflictError(f"Campaign with code '{code}' already exists")

    # Validate product exists
    product = get_product(product_id)
    if not product:
        raise ValidationError(f"Product '{product_id}' not found")

    # Validate date range
    if from_date > to_date:
        raise ValidationError("fromDate must be before toDate")

    # Create campaign
    campaign_id = f"camp_{uuid4()}"
    now = datetime.utcnow().isoformat() + "Z"

    item = {
        'PK': f'CAMPAIGN#{code}',
        'SK': 'METADATA',
        'id': campaign_id,
        'code': code,
        'description': description,
        'discountPercentage': discount_percentage,
        'productId': product_id,
        'termsConditionsLink': terms_link,
        'fromDate': from_date,
        'toDate': to_date,
        'active': True,
        'dateCreated': now,
        'dateLastUpdated': now,
        'lastUpdatedBy': admin_email
    }

    table.put_item(Item=item)
    return item
```

**Validation**:
- Campaign code is unique (check via GetItem)
- Product exists (check via GetItem on products table)
- Date range is valid (`fromDate <= toDate`)
- Discount percentage is 0-100
- Code format: uppercase alphanumeric (e.g., "SUMMER2025")

#### AP-5: Update Campaign

**Use Case**: Admin updates campaign dates or discount percentage

**Method**: `UpdateItem`

**Operation**:
```python
def update_campaign(code, updates, admin_email):
    # Build update expression
    update_expr = 'SET dateLastUpdated = :now, lastUpdatedBy = :user'
    expr_values = {
        ':now': datetime.utcnow().isoformat() + "Z",
        ':user': admin_email
    }

    if 'discountPercentage' in updates:
        update_expr += ', discountPercentage = :discount'
        expr_values[':discount'] = updates['discountPercentage']

    if 'toDate' in updates:
        update_expr += ', toDate = :to'
        expr_values[':to'] = updates['toDate']

    # Execute update
    response = table.update_item(
        Key={
            'PK': f'CAMPAIGN#{code}',
            'SK': 'METADATA'
        },
        UpdateExpression=update_expr,
        ExpressionAttributeValues=expr_values,
        ReturnValues='ALL_NEW'
    )

    return response['Attributes']
```

**Immutable Fields**:
- `code`: Cannot be changed (PK is immutable)
- `productId`: Cannot be changed (create new campaign if product changes)

**Mutable Fields**:
- `description`: Can be updated
- `discountPercentage`: Can be updated (affects new orders immediately)
- `fromDate`, `toDate`: Can be updated (extend or shorten campaign)
- `termsConditionsLink`: Can be updated

#### AP-6: Soft Delete Campaign

**Use Case**: Admin deactivates campaign (no longer valid)

**Method**: `UpdateItem`

**Operation**:
```python
def soft_delete_campaign(code, admin_email):
    response = table.update_item(
        Key={
            'PK': f'CAMPAIGN#{code}',
            'SK': 'METADATA'
        },
        UpdateExpression='SET active = :false, dateLastUpdated = :now, lastUpdatedBy = :user',
        ExpressionAttributeValues={
            ':false': False,
            ':now': datetime.utcnow().isoformat() + "Z",
            ':user': admin_email
        },
        ReturnValues='ALL_NEW'
    )

    return response['Attributes']
```

**Business Impact**:
- Soft-deleted campaigns do NOT appear in campaign listings
- Campaign landing page shows "Campaign no longer available"
- Existing orders with campaign snapshot are unaffected

### 4.4.5 Business Rules

#### Rule 1: Campaign Code Uniqueness

**Constraint**: Campaign code must be globally unique

**Enforcement**:
- Check via GetItem before creation
- Return ConflictError if code exists

**Code Format**:
- Uppercase alphanumeric (e.g., "SUMMER2025", "BLACK_FRIDAY_2025")
- Underscores allowed, no spaces
- Recommended length: 6-20 characters

#### Rule 2: Date Validation

**Constraints**:
1. `fromDate <= toDate` (start date before end date)
2. Date format: ISO 8601 date (YYYY-MM-DD)
3. Dates can be in the past (for historical campaigns)

**Validation**:
```python
from datetime import datetime

def validate_campaign_dates(from_date, to_date):
    # Parse dates
    try:
        from_dt = datetime.strptime(from_date, '%Y-%m-%d').date()
        to_dt = datetime.strptime(to_date, '%Y-%m-%d').date()
    except ValueError:
        raise ValidationError("Invalid date format. Use YYYY-MM-DD")

    # Check range
    if from_dt > to_dt:
        raise ValidationError("fromDate must be before or equal to toDate")
```

**Validity Check**:
```python
def is_campaign_valid(campaign):
    today = datetime.utcnow().date().isoformat()
    return (
        campaign['active'] and
        campaign['fromDate'] <= today <= campaign['toDate']
    )
```

#### Rule 3: Discount Calculation

**Formula**:
```
discountedPrice = originalPrice * (1 - discountPercentage / 100)
```

**Example**:
- Original Price: $299.99
- Discount Percentage: 20.0
- Discounted Price: $299.99 * (1 - 20/100) = $299.99 * 0.8 = $239.99

**Implementation**:
```python
def calculate_discounted_price(original_price, discount_percentage):
    discount_multiplier = 1 - (discount_percentage / 100)
    discounted_price = original_price * discount_multiplier
    return round(discounted_price, 2)  # Round to 2 decimal places
```

**Validation**:
- Discount percentage must be 0-100 (inclusive)
- Discounted price must be > 0 (cannot be free)

#### Rule 4: Product Association

**Constraint**: Campaign must reference a valid product

**Enforcement**:
- Validate product exists before campaign creation
- Product lookup during campaign retrieval (enrich response)

**Weak Reference**:
- Campaign stores `productId` (not embedded product object)
- Product can be soft-deleted independently
- Campaign remains valid even if product is soft-deleted (historical data)

**Data Enrichment**:
```python
def enrich_campaign_with_product(campaign):
    product = get_product(campaign['productId'])

    if product:
        campaign['productName'] = product['name']
        campaign['originalPrice'] = product['price']
        campaign['discountedPrice'] = calculate_discounted_price(
            product['price'], campaign['discountPercentage']
        )
    else:
        # Product was soft-deleted
        campaign['productName'] = "[Product Unavailable]"
        campaign['originalPrice'] = None
        campaign['discountedPrice'] = None

    return campaign
```

#### Rule 5: Campaign Snapshot in Orders

**Behavior**: When order is created with campaign, full campaign object is embedded in order

**Rationale**:
- Order preserves pricing at time of purchase
- Campaign changes do not affect historical orders
- Audit trail for discount applied

**Embedded Object**:
```json
{
  "order": {
    "id": "order_...",
    "campaign": {
      "id": "camp_770e8400...",
      "code": "SUMMER2025",
      "description": "Summer 2025 Special Offer",
      "discountPercentage": 20.0,
      "productId": "prod_550e8400...",
      "termsConditionsLink": "https://...",
      "fromDate": "2025-06-01",
      "toDate": "2025-08-31",
      "isValid": true,
      "active": true,
      "dateCreated": "2025-12-19T10:30:00Z",
      "dateLastUpdated": "2025-12-19T10:30:00Z",
      "lastUpdatedBy": "admin@kimmyai.io"
    }
  }
}
```

**Validation at Order Creation**:
- Campaign must be valid (`isValid=true`)
- Campaign must be active (`active=true`)
- Campaign dates must include current date

---

## 4.5 Repository Structure

### 4.5.1 Repository: `2_1_bbws_dynamodb_schemas`

The DynamoDB table schemas, GSI definitions, and Terraform modules are organized in a single repository:

**Repository Name**: `2_1_bbws_dynamodb_schemas`

**Purpose**: Centralized repository for all DynamoDB table schemas, Terraform infrastructure code, and deployment pipelines

#### Folder Structure

```
2_1_bbws_dynamodb_schemas/
├── schemas/
│   ├── tenants/
│   │   ├── tenant.schema.json
│   │   └── README.md
│   ├── products/
│   │   ├── product.schema.json
│   │   └── README.md
│   └── campaigns/
│       ├── campaign.schema.json
│       └── README.md
├── terraform/
│   ├── modules/
│   │   ├── dynamodb_table/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   ├── gsi/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── backup/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── dev.tfvars
│   ├── sit/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── sit.tfvars
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── prod.tfvars
├── .github/
│   └── workflows/
│       ├── validate-schemas.yml
│       ├── terraform-plan.yml
│       ├── terraform-apply-dev.yml
│       ├── terraform-apply-sit.yml
│       └── terraform-apply-prod.yml
├── tests/
│   ├── test_schemas.py
│   └── test_terraform.py
├── scripts/
│   └── validate_schemas.py
└── README.md
```

#### Folder Descriptions

| Folder | Purpose | Contents |
|--------|---------|----------|
| `schemas/` | JSON schema definitions for DynamoDB tables | One subfolder per table with `.schema.json` file |
| `terraform/modules/` | Reusable Terraform modules | `dynamodb_table`, `gsi`, `backup` modules |
| `terraform/dev/` | DEV environment Terraform code | Environment-specific `main.tf`, `variables.tf`, `dev.tfvars` |
| `terraform/sit/` | SIT environment Terraform code | Environment-specific `main.tf`, `variables.tf`, `sit.tfvars` |
| `terraform/prod/` | PROD environment Terraform code | Environment-specific `main.tf`, `variables.tf`, `prod.tfvars` |
| `.github/workflows/` | GitHub Actions CI/CD pipelines | Validation, plan, and apply workflows |
| `tests/` | Python test scripts | Schema validation, Terraform testing |
| `scripts/` | Helper scripts | Schema validation, migration scripts |

### 4.5.2 JSON Schema Examples

#### tenants.schema.json

```json
{
  "tableName": "tenants",
  "description": "Customer tenant records with email-based identity",
  "primaryKey": {
    "partitionKey": {
      "name": "PK",
      "type": "S",
      "pattern": "TENANT#{tenantId}"
    },
    "sortKey": {
      "name": "SK",
      "type": "S",
      "pattern": "METADATA"
    }
  },
  "attributes": [
    {
      "name": "PK",
      "type": "S",
      "required": true,
      "description": "Partition key: TENANT#{tenantId}"
    },
    {
      "name": "SK",
      "type": "S",
      "required": true,
      "description": "Sort key: METADATA"
    },
    {
      "name": "id",
      "type": "S",
      "required": true,
      "description": "Unique tenant identifier (UUID v4)"
    },
    {
      "name": "email",
      "type": "S",
      "required": true,
      "description": "Customer email address (unique)"
    },
    {
      "name": "status",
      "type": "S",
      "required": true,
      "enum": ["UNVALIDATED", "VALIDATED", "REGISTERED", "SUSPENDED"],
      "description": "Tenant lifecycle status"
    },
    {
      "name": "organizationName",
      "type": "S",
      "required": false,
      "description": "Organization name (for business tenants)"
    },
    {
      "name": "destinationEmail",
      "type": "S",
      "required": false,
      "description": "Destination email for form submissions"
    },
    {
      "name": "active",
      "type": "BOOL",
      "required": true,
      "default": true,
      "description": "Soft delete flag"
    },
    {
      "name": "dateCreated",
      "type": "S",
      "required": true,
      "format": "ISO 8601",
      "description": "Creation timestamp"
    },
    {
      "name": "dateLastUpdated",
      "type": "S",
      "required": true,
      "format": "ISO 8601",
      "description": "Last update timestamp"
    },
    {
      "name": "lastUpdatedBy",
      "type": "S",
      "required": true,
      "description": "User/system email that made last update"
    }
  ],
  "globalSecondaryIndexes": [
    {
      "indexName": "EmailIndex",
      "partitionKey": "email",
      "sortKey": null,
      "projectionType": "ALL",
      "description": "Lookup tenant by email address"
    },
    {
      "indexName": "TenantStatusIndex",
      "partitionKey": "status",
      "sortKey": "dateCreated",
      "projectionType": "ALL",
      "description": "List tenants by status, sorted by creation date"
    },
    {
      "indexName": "ActiveIndex",
      "partitionKey": "active",
      "sortKey": "dateCreated",
      "projectionType": "ALL",
      "description": "Filter tenants by active status"
    }
  ],
  "capacityMode": "ON_DEMAND",
  "pitr": {
    "enabled": true,
    "description": "Point-in-time recovery enabled for all environments"
  },
  "backup": {
    "dev": {
      "frequency": "daily",
      "retention": 7
    },
    "sit": {
      "frequency": "daily",
      "retention": 14
    },
    "prod": {
      "frequency": "hourly",
      "retention": 90
    }
  },
  "streams": {
    "enabled": true,
    "viewType": "NEW_AND_OLD_IMAGES",
    "description": "Change data capture for auditing"
  },
  "tags": {
    "Project": "2.1",
    "Application": "CustomerPortalPublic",
    "Component": "dynamodb",
    "ManagedBy": "Terraform"
  }
}
```

#### products.schema.json

```json
{
  "tableName": "products",
  "description": "Product catalog with pricing and features",
  "primaryKey": {
    "partitionKey": {
      "name": "PK",
      "type": "S",
      "pattern": "PRODUCT#{productId}"
    },
    "sortKey": {
      "name": "SK",
      "type": "S",
      "pattern": "METADATA"
    }
  },
  "attributes": [
    {
      "name": "PK",
      "type": "S",
      "required": true,
      "description": "Partition key: PRODUCT#{productId}"
    },
    {
      "name": "SK",
      "type": "S",
      "required": true,
      "description": "Sort key: METADATA"
    },
    {
      "name": "id",
      "type": "S",
      "required": true,
      "description": "Unique product identifier (UUID v4)"
    },
    {
      "name": "name",
      "type": "S",
      "required": true,
      "description": "Product name"
    },
    {
      "name": "description",
      "type": "S",
      "required": true,
      "description": "Product description"
    },
    {
      "name": "price",
      "type": "N",
      "required": true,
      "description": "Product price in ZAR (decimal)"
    },
    {
      "name": "features",
      "type": "L",
      "required": false,
      "description": "Array of feature strings"
    },
    {
      "name": "billingCycle",
      "type": "S",
      "required": true,
      "enum": ["monthly", "yearly"],
      "description": "Billing frequency"
    },
    {
      "name": "active",
      "type": "BOOL",
      "required": true,
      "default": true,
      "description": "Soft delete flag"
    },
    {
      "name": "dateCreated",
      "type": "S",
      "required": true,
      "format": "ISO 8601",
      "description": "Creation timestamp"
    },
    {
      "name": "dateLastUpdated",
      "type": "S",
      "required": true,
      "format": "ISO 8601",
      "description": "Last update timestamp"
    },
    {
      "name": "lastUpdatedBy",
      "type": "S",
      "required": true,
      "description": "Admin email that made last update"
    }
  ],
  "globalSecondaryIndexes": [
    {
      "indexName": "ProductActiveIndex",
      "partitionKey": "active",
      "sortKey": "dateCreated",
      "projectionType": "ALL",
      "description": "List active products"
    },
    {
      "indexName": "ActiveIndex",
      "partitionKey": "active",
      "sortKey": "dateCreated",
      "projectionType": "ALL",
      "description": "Filter products by active status"
    }
  ],
  "capacityMode": "ON_DEMAND",
  "pitr": {
    "enabled": true
  },
  "backup": {
    "dev": {
      "frequency": "daily",
      "retention": 7
    },
    "sit": {
      "frequency": "daily",
      "retention": 14
    },
    "prod": {
      "frequency": "hourly",
      "retention": 90
    }
  },
  "streams": {
    "enabled": true,
    "viewType": "NEW_AND_OLD_IMAGES",
    "description": "Price change auditing"
  },
  "tags": {
    "Project": "2.1",
    "Application": "CustomerPortalPublic",
    "Component": "dynamodb",
    "ManagedBy": "Terraform"
  }
}
```

#### campaigns.schema.json

```json
{
  "tableName": "campaigns",
  "description": "Marketing campaigns with time-based validity",
  "primaryKey": {
    "partitionKey": {
      "name": "PK",
      "type": "S",
      "pattern": "CAMPAIGN#{code}"
    },
    "sortKey": {
      "name": "SK",
      "type": "S",
      "pattern": "METADATA"
    }
  },
  "attributes": [
    {
      "name": "PK",
      "type": "S",
      "required": true,
      "description": "Partition key: CAMPAIGN#{code}"
    },
    {
      "name": "SK",
      "type": "S",
      "required": true,
      "description": "Sort key: METADATA"
    },
    {
      "name": "id",
      "type": "S",
      "required": true,
      "description": "Unique campaign identifier (UUID v4)"
    },
    {
      "name": "code",
      "type": "S",
      "required": true,
      "description": "Campaign code (e.g., SUMMER2025)"
    },
    {
      "name": "description",
      "type": "S",
      "required": true,
      "description": "Campaign description"
    },
    {
      "name": "discountPercentage",
      "type": "N",
      "required": true,
      "description": "Discount percentage (0-100)"
    },
    {
      "name": "productId",
      "type": "S",
      "required": true,
      "description": "Associated product UUID"
    },
    {
      "name": "termsConditionsLink",
      "type": "S",
      "required": true,
      "description": "URL to campaign T&C"
    },
    {
      "name": "fromDate",
      "type": "S",
      "required": true,
      "format": "ISO 8601 date (YYYY-MM-DD)",
      "description": "Campaign start date"
    },
    {
      "name": "toDate",
      "type": "S",
      "required": true,
      "format": "ISO 8601 date (YYYY-MM-DD)",
      "description": "Campaign end date"
    },
    {
      "name": "active",
      "type": "BOOL",
      "required": true,
      "default": true,
      "description": "Soft delete flag"
    },
    {
      "name": "dateCreated",
      "type": "S",
      "required": true,
      "format": "ISO 8601",
      "description": "Creation timestamp"
    },
    {
      "name": "dateLastUpdated",
      "type": "S",
      "required": true,
      "format": "ISO 8601",
      "description": "Last update timestamp"
    },
    {
      "name": "lastUpdatedBy",
      "type": "S",
      "required": true,
      "description": "Admin email that made last update"
    }
  ],
  "globalSecondaryIndexes": [
    {
      "indexName": "CampaignActiveIndex",
      "partitionKey": "active",
      "sortKey": "fromDate",
      "projectionType": "ALL",
      "description": "List active campaigns sorted by start date"
    },
    {
      "indexName": "CampaignProductIndex",
      "partitionKey": "productId",
      "sortKey": "fromDate",
      "projectionType": "ALL",
      "description": "List campaigns by product"
    },
    {
      "indexName": "ActiveIndex",
      "partitionKey": "active",
      "sortKey": "dateCreated",
      "projectionType": "ALL",
      "description": "Filter campaigns by active status"
    }
  ],
  "capacityMode": "ON_DEMAND",
  "pitr": {
    "enabled": true
  },
  "backup": {
    "dev": {
      "frequency": "daily",
      "retention": 7
    },
    "sit": {
      "frequency": "daily",
      "retention": 14
    },
    "prod": {
      "frequency": "hourly",
      "retention": 90
    }
  },
  "streams": {
    "enabled": true,
    "viewType": "NEW_AND_OLD_IMAGES",
    "description": "Campaign modification auditing"
  },
  "tags": {
    "Project": "2.1",
    "Application": "CustomerPortalPublic",
    "Component": "dynamodb",
    "ManagedBy": "Terraform"
  }
}
```

---

## 4.6 Environment Configuration

### 4.6.1 DEV Environment

**AWS Account**: 536580886816
**Region**: af-south-1 (Cape Town, South Africa)

#### DynamoDB Configuration

| Setting | Value | Justification |
|---------|-------|---------------|
| **Capacity Mode** | ON_DEMAND | Pay-per-use, no capacity planning |
| **PITR** | Enabled | 35-day continuous backup |
| **Backups** | Daily via AWS Backup, 7-day retention | Dev testing, shorter retention acceptable |
| **Deletion Protection** | Disabled | Allow table deletion for testing |
| **Streams** | Enabled (New and Old Images) | Change data capture for testing |
| **Cross-Region Replication** | No | Dev environment, no DR needed |
| **Encryption** | AWS-managed (SSE-KMS) | Default encryption at rest |

#### Tags

```hcl
tags = {
  Environment = "dev"
  Project     = "BBWS WP Containers"
  Owner       = "Tebogo"
  CostCenter  = "AWS"
  ManagedBy   = "Terraform"
  Component   = "dynamodb"
  Application = "CustomerPortalPublic"
}
```

#### Cost Estimate

| Resource | Monthly Cost (USD) |
|----------|-------------------|
| DynamoDB (ON_DEMAND) | $50 |
| DynamoDB Backups | $5 |
| DynamoDB Streams | $10 |
| **Total** | **$65** |

**Budget Alert**: $400 (80% of $500 monthly budget)

### 4.6.2 SIT Environment

**AWS Account**: 815856636111
**Region**: af-south-1 (Cape Town, South Africa)

#### DynamoDB Configuration

| Setting | Value | Justification |
|---------|-------|---------------|
| **Capacity Mode** | ON_DEMAND | Pay-per-use, no capacity planning |
| **PITR** | Enabled | 35-day continuous backup |
| **Backups** | Daily via AWS Backup, 14-day retention | QA testing, medium retention |
| **Deletion Protection** | Disabled | Allow table deletion for testing |
| **Streams** | Enabled (New and Old Images) | Change data capture for testing |
| **Cross-Region Replication** | No | SIT environment, no DR needed |
| **Encryption** | AWS-managed (SSE-KMS) | Default encryption at rest |

#### Tags

```hcl
tags = {
  Environment = "sit"
  Project     = "BBWS WP Containers"
  Owner       = "Tebogo"
  CostCenter  = "AWS"
  ManagedBy   = "Terraform"
  Component   = "dynamodb"
  Application = "CustomerPortalPublic"
}
```

#### Cost Estimate

| Resource | Monthly Cost (USD) |
|----------|-------------------|
| DynamoDB (ON_DEMAND) | $100 |
| DynamoDB Backups | $10 |
| DynamoDB Streams | $20 |
| **Total** | **$130** |

**Budget Alert**: $800 (80% of $1,000 monthly budget)

### 4.6.3 PROD Environment

**AWS Account**: 093646564004
**Primary Region**: af-south-1 (Cape Town, South Africa)
**DR Region**: eu-west-1 (Ireland)

#### DynamoDB Configuration

| Setting | Value | Justification |
|---------|-------|---------------|
| **Capacity Mode** | ON_DEMAND | Production workload, unpredictable traffic |
| **PITR** | Enabled | 35-day continuous backup |
| **Backups** | Hourly via AWS Backup, 90-day retention | Production, longest retention for compliance |
| **Deletion Protection** | **Enabled** | Prevent accidental table deletion |
| **Streams** | Enabled (New and Old Images) | Change data capture for auditing |
| **Cross-Region Replication** | **Yes** (to eu-west-1) | Disaster recovery (multi-site active/active) |
| **Encryption** | AWS-managed (SSE-KMS) | Default encryption at rest |

#### Tags

```hcl
tags = {
  Environment  = "prod"
  Project      = "BBWS WP Containers"
  Owner        = "Tebogo"
  CostCenter   = "AWS"
  ManagedBy    = "Terraform"
  Component    = "dynamodb"
  Application  = "CustomerPortalPublic"
  BackupPolicy = "hourly"
  DR           = "enabled"
  LLD          = "2.1.8"
}
```

**Note**: PROD has 7 mandatory tags (compared to DEV/SIT with 5 tags)

#### Cost Estimate

| Resource | Monthly Cost (USD) |
|----------|-------------------|
| DynamoDB (ON_DEMAND) - Primary | $800 |
| DynamoDB (ON_DEMAND) - DR Replica | $800 |
| DynamoDB Backups (hourly, 90 days) | $100 |
| DynamoDB Streams | $100 |
| Cross-Region Replication | $300 |
| **Total** | **$2,100** |

**Budget Alert**: $4,000 (80% of $5,000 monthly budget)

### 4.6.4 Environment Comparison Matrix

| Configuration | DEV | SIT | PROD |
|---------------|-----|-----|------|
| AWS Account | 536580886816 | 815856636111 | 093646564004 |
| Region | af-south-1 | af-south-1 | af-south-1 + eu-west-1 |
| Capacity Mode | ON_DEMAND | ON_DEMAND | ON_DEMAND |
| PITR | Enabled | Enabled | Enabled |
| Backup Frequency | Daily | Daily | **Hourly** |
| Backup Retention | 7 days | 14 days | **90 days** |
| Deletion Protection | Disabled | Disabled | **Enabled** |
| Streams | Enabled | Enabled | Enabled |
| Cross-Region Replication | No | No | **Yes (eu-west-1)** |
| Monthly Budget | $500 | $1,000 | $5,000 |
| Estimated Cost | $65 | $130 | $2,100 |

---

## 4.7 Capacity Planning

### 4.7.1 ON_DEMAND Capacity Mode

All DynamoDB tables use **ON_DEMAND** capacity mode (not provisioned capacity).

**Rationale**:

1. **Unpredictable Traffic**: Serverless architecture with variable traffic patterns (campaign launches, flash sales)
2. **Cost Optimization**: Pay only for what you use (no idle capacity cost)
3. **Automatic Scaling**: AWS handles capacity scaling automatically
4. **Simplified Operations**: No capacity planning or threshold monitoring required
5. **Startup Phase**: Unknown traffic patterns in early stages

**Pricing Model**:

| Operation | Cost per Million Requests | Notes |
|-----------|---------------------------|-------|
| Read Request (GetItem, Query, Scan) | $0.25 | Per 4KB item |
| Write Request (PutItem, UpdateItem, DeleteItem) | $1.25 | Per 1KB item |
| GSI Read | $0.25 | Same as base table |
| GSI Write | $1.25 | Writes to base table also write to GSIs |
| Streams Read | $0.02 | Per 100KB |
| Backup Storage | $0.10 per GB/month | PITR and AWS Backup |

**Cost Calculation Example** (PROD Monthly):

Assumptions:
- 100,000 orders/month
- 1,000,000 product page views/month (read products)
- 10,000 campaign page views/month (read campaigns)
- 500 admin operations/month (create/update products/campaigns)

| Operation | Requests/Month | Cost Calculation | Monthly Cost |
|-----------|----------------|------------------|--------------|
| Product reads (pricing page) | 1,000,000 | 1M * $0.25 | $250 |
| Campaign reads (landing pages) | 10,000 | 0.01M * $0.25 | $2.50 |
| Tenant lookups (checkout) | 100,000 | 0.1M * $0.25 | $25 |
| Order writes (checkout) | 100,000 | 0.1M * $1.25 | $125 |
| Tenant writes (new customers) | 50,000 | 0.05M * $1.25 | $62.50 |
| Admin operations | 500 | 0.0005M * $1.25 | $0.62 |
| GSI writes (EmailIndex, StatusIndex, etc.) | 200,000 | 0.2M * $1.25 | $250 |
| **Total ON_DEMAND** | | | **$715.62** |
| Backups (hourly, 90 days, ~10GB) | | 10GB * $0.10 | $1 |
| Streams (change data capture) | | ~50GB * ($0.02/100KB) | $10 |
| Cross-Region Replication (data transfer) | | ~500GB * $0.02 | $10 |
| **Total DynamoDB (PROD)** | | | **$736.62** |

**Actual PROD Estimate**: $800-$2,100/month (includes safety margin for traffic spikes)

### 4.7.2 Capacity Monitoring

**CloudWatch Metrics**:

| Metric | Alert Threshold | Action |
|--------|-----------------|--------|
| `ConsumedReadCapacityUnits` | > 10,000 per minute | Investigate read patterns, consider caching |
| `ConsumedWriteCapacityUnits` | > 5,000 per minute | Investigate write patterns, batch operations |
| `ThrottledRequests` | > 10 in 5 minutes | Increase capacity (should not happen with ON_DEMAND) |
| `SystemErrors` | > 5 in 5 minutes | Investigate DynamoDB issues, check AWS status |

**Cost Anomaly Detection**:
- AWS Cost Anomaly Detection enabled for DynamoDB service
- Alert if daily cost exceeds 150% of 7-day average

### 4.7.3 Alternative Capacity Mode (Not Used)

**Provisioned Capacity** (not used):

**Why Not Used**:
- Requires capacity planning (unknown traffic patterns)
- Risk of throttling during traffic spikes
- Complex auto-scaling configuration
- Higher operational overhead
- No cost benefit for variable traffic

**When to Consider Provisioned**:
- Predictable, steady traffic patterns
- Cost optimization for high-volume tables (> $1,000/month)
- Budget constraints (provisioned can be cheaper at scale)

---

## 4.8 Backup and Recovery

### 4.8.1 Point-in-Time Recovery (PITR)

**Configuration**: Enabled for all tables in all environments

| Setting | Value | Details |
|---------|-------|---------|
| **PITR Enabled** | Yes | All tables (tenants, products, campaigns) |
| **Retention** | 35 days | Maximum AWS PITR retention |
| **Recovery Granularity** | 1 second | Restore to any second within retention window |
| **Cost** | $0.20 per GB/month | Based on table size |

**Use Case**: Accidental data corruption, human error (e.g., admin deletes all products)

**Recovery Process**:

1. **Identify Recovery Point**: Determine timestamp before corruption (e.g., "2025-12-25T14:30:00Z")
2. **Initiate Restore**: Use AWS Console or Terraform to restore table to new table name
3. **Verify Data**: Compare restored table with current table
4. **Cutover**: Update Lambda environment variables to point to restored table
5. **Cleanup**: Delete corrupted table after verification

**Terraform Restore Example**:
```hcl
resource "aws_dynamodb_table" "tenants_restored" {
  name = "tenants_restored"

  restore_source_name = "tenants"
  restore_date_time   = "2025-12-25T14:30:00Z"
  restore_to_latest_time = false

  # Restore configuration matches original table
  billing_mode = "PAY_PER_REQUEST"
  # ... other settings
}
```

### 4.8.2 AWS Backup (Scheduled Backups)

**Configuration**: Automated backups via AWS Backup service

#### DEV Environment

| Setting | Value |
|---------|-------|
| **Backup Frequency** | Daily (1:00 AM UTC) |
| **Retention** | 7 days |
| **Backup Vault** | `bbws-backup-vault-dev` |
| **Recovery Point Objective (RPO)** | 24 hours |

#### SIT Environment

| Setting | Value |
|---------|-------|
| **Backup Frequency** | Daily (2:00 AM UTC) |
| **Retention** | 14 days |
| **Backup Vault** | `bbws-backup-vault-sit` |
| **Recovery Point Objective (RPO)** | 24 hours |

#### PROD Environment

| Setting | Value |
|---------|-------|
| **Backup Frequency** | **Hourly** (top of every hour) |
| **Retention** | 90 days |
| **Backup Vault** | `bbws-backup-vault-prod` |
| **Recovery Point Objective (RPO)** | **1 hour** |
| **Cross-Region Backup** | Yes (replicated to eu-west-1) |

**AWS Backup Plan** (PROD):
```hcl
resource "aws_backup_plan" "dynamodb_prod" {
  name = "bbws-dynamodb-prod-hourly"

  rule {
    rule_name         = "hourly_backup"
    target_vault_name = aws_backup_vault.prod.name
    schedule          = "cron(0 * * * ? *)"  # Every hour

    lifecycle {
      delete_after = 90  # 90 days retention
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.prod_replica_eu_west_1.arn

      lifecycle {
        delete_after = 90
      }
    }
  }
}

resource "aws_backup_selection" "dynamodb_prod" {
  name         = "bbws-dynamodb-prod-selection"
  plan_id      = aws_backup_plan.dynamodb_prod.id
  iam_role_arn = aws_iam_role.backup_role.arn

  resources = [
    aws_dynamodb_table.tenants.arn,
    aws_dynamodb_table.products.arn,
    aws_dynamodb_table.campaigns.arn
  ]
}
```

### 4.8.3 Cross-Region Replication (PROD Only)

**Configuration**: DynamoDB Global Tables for disaster recovery

| Setting | Value |
|---------|-------|
| **Primary Region** | af-south-1 (Cape Town, South Africa) |
| **DR Region** | eu-west-1 (Ireland) |
| **Replication Lag** | < 1 second (typically milliseconds) |
| **Consistency** | Eventual consistency (cross-region) |
| **Failover Time (RTO)** | < 15 minutes (DNS failover via Route 53) |

**DynamoDB Global Table** (PROD):
```hcl
resource "aws_dynamodb_table" "tenants_prod" {
  name         = "tenants"
  billing_mode = "PAY_PER_REQUEST"

  # Primary key
  hash_key  = "PK"
  range_key = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  # Enable streams for replication
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  # Cross-region replica
  replica {
    region_name = "eu-west-1"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Environment = "prod"
    DR          = "enabled"
  }
}
```

**Replication Monitoring**:

| Metric | Alert Threshold | Action |
|--------|-----------------|--------|
| `ReplicationLatency` | > 5 seconds | Investigate network issues, AWS status |
| `PendingReplicationCount` | > 1,000 items | Check replication backlog |
| `ReplicationErrorRate` | > 1% | Investigate replication conflicts |

**Failover Strategy**:

1. **Health Check Failure**: Route 53 detects primary region failure (af-south-1 unhealthy)
2. **DNS Failover**: Route 53 automatically routes traffic to DR region (eu-west-1)
3. **Application Switchover**: Lambda functions in eu-west-1 use local replica tables
4. **RTO**: < 15 minutes (time for DNS propagation + health check detection)
5. **RPO**: < 1 second (replication lag is milliseconds)

**Failback Process**:

1. **Primary Region Recovery**: af-south-1 region becomes healthy again
2. **Data Sync**: Verify data consistency between regions (bi-directional replication)
3. **Manual Failback**: Route 53 health check re-enables af-south-1
4. **Traffic Shift**: DNS gradually shifts traffic back to primary region
5. **Monitoring**: Monitor for replication conflicts or data discrepancies

### 4.8.4 Recovery Time Objectives (RTO) and Recovery Point Objectives (RPO)

#### RTO (Recovery Time Objective)

| Scenario | DEV | SIT | PROD |
|----------|-----|-----|------|
| **Accidental Delete** (PITR restore) | Best effort (1-2 hours) | < 2 hours | < 1 hour |
| **Table Corruption** (AWS Backup restore) | Best effort (2-4 hours) | < 4 hours | < 2 hours |
| **Region Failure** (Cross-region failover) | N/A | N/A | **< 15 minutes** |

#### RPO (Recovery Point Objective)

| Scenario | DEV | SIT | PROD |
|----------|-----|-----|------|
| **PITR** | 35 days | 35 days | 35 days |
| **AWS Backup** | 24 hours (daily) | 24 hours (daily) | **1 hour** (hourly) |
| **Cross-Region Replication** | N/A | N/A | **< 1 second** |

---

## Summary

This DynamoDB table design section provides comprehensive specifications for three core tables:

1. **tenants**: Customer tenant records with email-based identity, status lifecycle, and soft delete
2. **products**: Product catalog with pricing, features, and billing cycles
3. **campaigns**: Marketing campaigns with time-based validity and product associations

**Key Design Decisions**:
- **Separate Tables**: Each domain entity has its own table (not single-table design)
- **Soft Delete Pattern**: All entities use `active` boolean field (no physical deletes)
- **Activatable Entity Pattern**: All entities have id, dateCreated, dateLastUpdated, lastUpdatedBy, active
- **Hierarchical Ownership**: PK/SK patterns establish clear entity relationships
- **ON_DEMAND Capacity**: Pay-per-use billing for unpredictable traffic
- **Multi-Region DR**: PROD has cross-region replication to eu-west-1

**Environment Configuration**:
- **DEV**: Daily backups (7 days), no DR, $65/month estimated
- **SIT**: Daily backups (14 days), no DR, $130/month estimated
- **PROD**: Hourly backups (90 days), DR enabled, $800-$2,100/month estimated

**Repository**: `2_1_bbws_dynamodb_schemas` contains JSON schemas, Terraform modules, and CI/CD pipelines

This design supports the BBWS Customer Portal Public application with scalable, durable, and cost-effective data storage.

---

**End of Section 4: DynamoDB Table Design**
