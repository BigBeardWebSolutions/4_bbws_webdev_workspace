# HATEOAS Relational Design Skill

**Version**: 1.1
**Created**: 2025-12-17
**Last Updated**: 2025-12-19
**Type**: Architecture Design Pattern
**Extracted From**: HLD architecture sessions - recurring rework pattern

---

## Purpose

Guide architects to design **hierarchical HATEOAS** API structures that reflect real-world entity relationships, avoiding flat structures that lose relational context and require costly rework.

**Problem Solved**: Flat HATEOAS designs treat entities as independent resources, losing the inherent parent-child relationships. This leads to:
- Ambiguous ownership (which organization owns this user?)
- Complex authorization logic (can user X access resource Y?)
- Rework when relationships need to be added later
- Inconsistent DynamoDB key patterns

---

## Trigger Conditions

### When to Apply This Skill

Invoke this skill when:
- Designing API endpoints for entities with parent-child relationships
- Creating DynamoDB schemas for relational data
- Reviewing HLD/LLD documents with API definitions
- User mentions: organizations, tenants, users, teams, divisions, orders, carts, or similar hierarchical entities

### Red Flags (Flat Design Detected)

Watch for these anti-patterns:
```
/users/{userId}                    # Where does this user belong?
/invitations/{invitationId}        # Who sent this invitation?
/orders/{orderId}                  # Which customer's order?
/payments/{paymentId}              # Payment for which order?
```

---

## Core Concept: Flat vs Hierarchical HATEOAS

### Anti-Pattern: Flat HATEOAS

```
# Flat endpoints - entities appear independent
GET  /organizations/{orgId}
GET  /divisions/{divisionId}
GET  /teams/{teamId}
GET  /users/{userId}
GET  /invitations/{invitationId}

# Problems:
# - No context of ownership
# - Authorization requires extra lookups
# - URL doesn't convey relationship
# - DynamoDB keys become complex GSI lookups
```

**Flat DynamoDB Schema** (problematic):
| Entity | PK | SK | Problem |
|--------|----|----|---------|
| Organization | `ORG#{orgId}` | `METADATA` | OK |
| Division | `DIV#{divId}` | `METADATA` | Which org? |
| Team | `TEAM#{teamId}` | `METADATA` | Which division? |
| User | `USER#{userId}` | `METADATA` | Which team? |
| Invitation | `INV#{invId}` | `METADATA` | From whom? To whom? |

### Correct Pattern: Hierarchical HATEOAS

```
# Hierarchical endpoints - relationships explicit in URL
GET  /organizations/{orgId}
GET  /organizations/{orgId}/divisions/{divisionId}
GET  /organizations/{orgId}/divisions/{divisionId}/teams/{teamId}
GET  /organizations/{orgId}/divisions/{divisionId}/teams/{teamId}/users/{userId}
GET  /organizations/{orgId}/invitations/{invitationId}

# Benefits:
# - URL conveys full context
# - Authorization is path-based
# - Parent validation implicit
# - DynamoDB keys naturally composite
```

**Hierarchical DynamoDB Schema** (correct):
| Entity | PK | SK | Benefit |
|--------|----|----|---------|
| Organization | `ORG#{orgId}` | `METADATA` | Root entity |
| Division | `ORG#{orgId}` | `DIV#{divId}` | Org context in PK |
| Team | `ORG#{orgId}#DIV#{divId}` | `TEAM#{teamId}` | Full hierarchy |
| User | `ORG#{orgId}#DIV#{divId}#TEAM#{teamId}` | `USER#{userId}` | Full context |
| Invitation | `ORG#{orgId}` | `INV#{invId}` | Org-scoped |

---

## Real-World Example: Organization Hierarchy

### Business Context

Most applications have organizational hierarchies:
```
Organization (BigBeard Inc)
├── Division (Engineering)
│   ├── Team (Platform)
│   │   ├── User (alice@bigbeard.com)
│   │   └── User (bob@bigbeard.com)
│   └── Team (Frontend)
│       └── User (carol@bigbeard.com)
├── Division (Sales)
│   └── Team (Enterprise)
│       └── User (dave@bigbeard.com)
└── Invitations (pending users)
```

### Hierarchical API Design

```yaml
# Organization Management
GET    /v1.0/organizations/{orgId}
PUT    /v1.0/organizations/{orgId}

# Division Management (under Organization)
GET    /v1.0/organizations/{orgId}/divisions
POST   /v1.0/organizations/{orgId}/divisions
GET    /v1.0/organizations/{orgId}/divisions/{divId}
PUT    /v1.0/organizations/{orgId}/divisions/{divId}

# Team Management (under Division)
GET    /v1.0/organizations/{orgId}/divisions/{divId}/teams
POST   /v1.0/organizations/{orgId}/divisions/{divId}/teams
GET    /v1.0/organizations/{orgId}/divisions/{divId}/teams/{teamId}
PUT    /v1.0/organizations/{orgId}/divisions/{divId}/teams/{teamId}

# User Management (under Team)
GET    /v1.0/organizations/{orgId}/divisions/{divId}/teams/{teamId}/users
POST   /v1.0/organizations/{orgId}/divisions/{divId}/teams/{teamId}/users
GET    /v1.0/organizations/{orgId}/divisions/{divId}/teams/{teamId}/users/{userId}
PUT    /v1.0/organizations/{orgId}/divisions/{divId}/teams/{teamId}/users/{userId}

# Invitations (under Organization - cross-cutting)
GET    /v1.0/organizations/{orgId}/invitations
POST   /v1.0/organizations/{orgId}/invitations
GET    /v1.0/organizations/{orgId}/invitations/{invId}
PUT    /v1.0/organizations/{orgId}/invitations/{invId}
```

### Hierarchical DynamoDB Schema

```
| Entity | PK | SK | Attributes |
|--------|----|----|------------|
| Organization | `ORG#{orgId}` | `METADATA` | name, dateCreated, dateLastUpdated, lastUpdatedBy, active |
| Division | `ORG#{orgId}` | `DIV#{divId}` | name, dateCreated, dateLastUpdated, lastUpdatedBy, active |
| Team | `ORG#{orgId}#DIV#{divId}` | `TEAM#{teamId}` | name, dateCreated, dateLastUpdated, lastUpdatedBy, active |
| User | `ORG#{orgId}#DIV#{divId}#TEAM#{teamId}` | `USER#{userId}` | email, role, dateCreated, dateLastUpdated, lastUpdatedBy, active |
| Invitation | `ORG#{orgId}` | `INV#{invId}` | email, target_team, status, dateCreated, dateLastUpdated, lastUpdatedBy, active |
```

### Key Relationships Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                HIERARCHICAL KEY PATTERN                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ORGANIZATION                                                   │
│  PK: ORG#{orgId}                                                │
│  SK: METADATA                                                   │
│       │                                                         │
│       ├──────────────────────────────────────┐                  │
│       │                                      │                  │
│       ▼                                      ▼                  │
│  DIVISION                              INVITATION               │
│  PK: ORG#{orgId}                       PK: ORG#{orgId}          │
│  SK: DIV#{divId}                       SK: INV#{invId}          │
│       │                                                         │
│       ▼                                                         │
│  TEAM                                                           │
│  PK: ORG#{orgId}#DIV#{divId}                                    │
│  SK: TEAM#{teamId}                                              │
│       │                                                         │
│       ▼                                                         │
│  USER                                                           │
│  PK: ORG#{orgId}#DIV#{divId}#TEAM#{teamId}                      │
│  SK: USER#{userId}                                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Real-World Example: E-Commerce Hierarchy

### Business Context

E-commerce has natural hierarchies:
```
Tenant (customer@email.com)
├── Cart
│   └── CartItems
└── Orders
    ├── Order #1
    │   ├── OrderItems
    │   └── Payments
    └── Order #2
        ├── OrderItems
        └── Payments
```

### Hierarchical API Design

```yaml
# Tenant root
GET    /v1.0/tenants/{tenantId}

# Cart (under Tenant)
GET    /v1.0/tenants/{tenantId}/cart
PUT    /v1.0/tenants/{tenantId}/cart

# Cart Items (under Cart)
GET    /v1.0/tenants/{tenantId}/cart/items
POST   /v1.0/tenants/{tenantId}/cart/items
PUT    /v1.0/tenants/{tenantId}/cart/items/{itemId}

# Orders (under Tenant)
GET    /v1.0/tenants/{tenantId}/orders
POST   /v1.0/tenants/{tenantId}/orders
GET    /v1.0/tenants/{tenantId}/orders/{orderId}
PUT    /v1.0/tenants/{tenantId}/orders/{orderId}

# Order Items (under Order)
GET    /v1.0/tenants/{tenantId}/orders/{orderId}/items

# Payments (under Order)
GET    /v1.0/tenants/{tenantId}/orders/{orderId}/payments
POST   /v1.0/tenants/{tenantId}/orders/{orderId}/payments
GET    /v1.0/tenants/{tenantId}/orders/{orderId}/payments/{paymentId}
```

### Hierarchical DynamoDB Schema

```
| Entity | PK | SK | Attributes |
|--------|----|----|------------|
| Tenant | `TENANT#{tenantId}` | `METADATA` | email, status, dateCreated, dateLastUpdated, lastUpdatedBy, active |
| Cart | `TENANT#{tenantId}#CART#{cartId}` | `METADATA` | type, dateCreated, dateLastUpdated, lastUpdatedBy, active |
| CartItem | `TENANT#{tenantId}#CART#{cartId}` | `ITEM#{itemId}` | product_id, quantity, dateCreated, dateLastUpdated, lastUpdatedBy, active |
| Order | `TENANT#{tenantId}` | `ORDER#{orderId}` | status, total, dateCreated, dateLastUpdated, lastUpdatedBy, active |
| OrderItem | `TENANT#{tenantId}#ORDER#{orderId}` | `ITEM#{itemId}` | product_id, quantity, dateCreated, dateLastUpdated, lastUpdatedBy, active |
| Payment | `TENANT#{tenantId}#ORDER#{orderId}` | `PAYMENT#{paymentId}` | amount, status, dateCreated, dateLastUpdated, lastUpdatedBy, active |
```

---

## Pagination Pattern for List Operations

### Standard Pagination (MANDATORY)

All list endpoints (GET collection operations) MUST implement pagination using the **pageSize/startAt/moreAvailable** pattern.

#### Request Parameters

```yaml
Query Parameters:
  - pageSize (integer, optional): Number of items to return per page
      Default: 50
      Maximum: 100
  - startAt (string, optional): Pagination token to start at a specific position
      Format: Last item ID or continuation token from previous response
  - include_inactive (boolean, optional): Include soft-deleted records
      Default: false
```

#### Response Format

```json
{
  "items": [...],
  "startAt": "last_item_id_or_continuation_token",
  "moreAvailable": true
}
```

**Response Fields:**
- `items`: Array of results for current page
- `startAt`: Token to fetch next page (ID of last item or continuation token)
- `moreAvailable`: Boolean indicating if more results exist beyond current page

### Pagination Examples

#### Organization Divisions List

```yaml
GET /v1.0/organizations/{orgId}/divisions?pageSize=50&startAt=DIV_12345
```

**Response (200 OK):**
```json
{
  "items": [
    {
      "id": "DIV_67890",
      "name": "Engineering",
      "description": "Product engineering division",
      "dateCreated": "2025-12-19T10:00:00Z",
      "dateLastUpdated": "2025-12-19T10:00:00Z",
      "lastUpdatedBy": "admin@example.com",
      "active": true
    },
    {
      "id": "DIV_11111",
      "name": "Sales",
      "description": "Sales and business development",
      "dateCreated": "2025-12-19T11:00:00Z",
      "dateLastUpdated": "2025-12-19T11:00:00Z",
      "lastUpdatedBy": "admin@example.com",
      "active": true
    }
  ],
  "startAt": "DIV_11111",
  "moreAvailable": true
}
```

#### Team Users List

```yaml
GET /v1.0/organizations/{orgId}/divisions/{divId}/teams/{teamId}/users?pageSize=20&include_inactive=true
```

**Response (200 OK):**
```json
{
  "items": [
    {
      "id": "USER_alice",
      "email": "alice@example.com",
      "role": "developer",
      "dateCreated": "2025-12-15T08:00:00Z",
      "dateLastUpdated": "2025-12-19T14:00:00Z",
      "lastUpdatedBy": "alice@example.com",
      "active": true
    },
    {
      "id": "USER_bob",
      "email": "bob@example.com",
      "role": "manager",
      "dateCreated": "2025-12-10T09:00:00Z",
      "dateLastUpdated": "2025-12-18T16:00:00Z",
      "lastUpdatedBy": "admin@example.com",
      "active": false
    }
  ],
  "startAt": "USER_bob",
  "moreAvailable": false
}
```

#### Tenant Orders List

```yaml
GET /v1.0/tenants/{tenantId}/orders?pageSize=25&status=COMPLETED
```

**Response (200 OK):**
```json
{
  "items": [
    {
      "id": "ORDER_550e8400",
      "status": "COMPLETED",
      "total": 299.99,
      "currency": "ZAR",
      "items_count": 3,
      "dateCreated": "2025-12-01T10:00:00Z",
      "dateLastUpdated": "2025-12-01T15:00:00Z",
      "lastUpdatedBy": "system",
      "active": true
    }
  ],
  "startAt": "ORDER_550e8400",
  "moreAvailable": false
}
```

### Pagination Best Practices

1. **Always Include Pagination**: Every list endpoint must support pagination, even if dataset is currently small
2. **Consistent Token Format**: Use consistent token format across all endpoints (typically last item ID)
3. **Filter Before Paginate**: Apply filters (include_inactive, status, etc.) before pagination
4. **Default Page Size**: Use sensible defaults (50) to prevent over-fetching
5. **Maximum Page Size**: Enforce maximum (100) to protect backend performance
6. **Empty Results**: Return empty items array with moreAvailable=false when no results

### DynamoDB Integration

When implementing pagination with DynamoDB:

```python
# Query with pagination
response = table.query(
    KeyConditionExpression=Key('PK').eq(f'ORG#{org_id}'),
    Limit=page_size,
    ExclusiveStartKey=start_key if start_at else None
)

# Build response
return {
    "items": response['Items'],
    "startAt": response.get('LastEvaluatedKey', {}).get('SK', None),
    "moreAvailable": 'LastEvaluatedKey' in response
}
```

---

## Decision Rules

### Rule 1: Parent in URL Path

```
IF entity has a parent relationship
THEN parent ID(s) MUST appear in URL path

# Wrong
GET /payments/{paymentId}

# Correct
GET /tenants/{tenantId}/orders/{orderId}/payments/{paymentId}
```

### Rule 2: Composite Keys Mirror URL

```
IF URL has hierarchy /a/{aId}/b/{bId}/c/{cId}
THEN DynamoDB key SHOULD be:
  PK: A#{aId}#B#{bId}  (or similar composite)
  SK: C#{cId}
```

### Rule 3: Cross-Cutting Concerns

```
IF entity spans multiple parents (e.g., invitation can target any team)
THEN anchor to highest common parent

# Invitation can target any team in org
PK: ORG#{orgId}
SK: INV#{invId}
Attributes: target_division, target_team
```

### Rule 4: Query Patterns Drive Key Design

```
IF primary query is "all X for parent Y"
THEN PK should include parent, SK should be entity

# "All orders for tenant" → PK: TENANT#{id}, SK: ORDER#{orderId}
# "All items for order" → PK: TENANT#{id}#ORDER#{orderId}, SK: ITEM#{itemId}
```

### Rule 5: Soft Delete with Active Flag

```
ALL entities MUST have `active` boolean field
NO DELETE operations - use PUT with active=false
Queries filter active=true by default
```

---

## Workflow: Applying This Skill

### Step 1: Identify Entity Relationships

```
1. List all entities in the domain
2. Draw parent-child relationships
3. Identify ownership chains
4. Note cross-cutting entities
```

### Step 2: Design URL Hierarchy

```
1. Start from root entity
2. Build paths reflecting ownership
3. Ensure every entity has parent context in URL
4. Use consistent naming (plural for collections)
```

### Step 3: Design DynamoDB Keys

```
1. Map URL hierarchy to composite keys
2. PK = parent context
3. SK = entity identifier
4. Add GSIs for alternate access patterns
```

### Step 4: Review for Flat Anti-Patterns

```
Check for:
- Entities without parent in URL
- PKs without relationship context
- Orphaned GSIs replacing proper hierarchy
```

---

## Success Criteria

This skill has been applied successfully when:

1. **URL Clarity**: Any URL path reveals full entity context
2. **Key Alignment**: DynamoDB keys mirror URL hierarchy
3. **No Orphans**: Every child entity has parent in path
4. **Query Efficiency**: Primary queries use PK, not GSI
5. **Authorization Ready**: Path-based auth is possible

---

## Error Handling

### Flat Design Detected

```
IF reviewing HLD and flat patterns found
THEN:
  1. Flag specific endpoints
  2. Propose hierarchical alternative
  3. Show DynamoDB key impact
  4. Estimate rework if not fixed now
```

### Deep Hierarchy Concern

```
IF hierarchy exceeds 4 levels
THEN:
  - Consider if middle levels are necessary
  - Check if GSI can flatten for specific queries
  - Document why depth is required
```

### Cross-Reference Needed

```
IF entity needs to reference non-parent entity
THEN:
  - Store reference as attribute (not in key)
  - Create GSI if reverse lookup needed
  - Don't break hierarchy for edge cases
```

---

## Abstraction Notes

**Generalized From**:
- Organization → Division → Team → User hierarchy patterns
- Tenant → Order → Payment e-commerce patterns
- Cart management with anonymous/registered states

**Privacy Applied**:
- Removed specific customer/tenant identifiers
- Abstracted business-specific entity names
- Preserved structural patterns only

**Assumptions**:
- DynamoDB single-table design preferred
- Soft delete pattern (active boolean) standard
- REST API with version prefix (/v1.0/)

---

## Related Skills

- `soft_delete_pattern.skill.md` - Active boolean field pattern
- `dynamodb_single_table.skill.md` - Single-table design principles
- `api_versioning.skill.md` - Version in path, not base URL

---

## Version History

- **v1.0** (2025-12-17): Extracted from HLD architecture sessions - recurring HATEOAS rework pattern
- **v1.1** (2025-12-19): Added pagination pattern section (pageSize/startAt/moreAvailable), updated all DynamoDB schemas to use Activatable Entity Pattern (dateCreated, dateLastUpdated, lastUpdatedBy), added DynamoDB integration examples
