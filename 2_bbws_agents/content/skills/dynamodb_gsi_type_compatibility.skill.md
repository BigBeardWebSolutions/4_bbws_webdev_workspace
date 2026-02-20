# DynamoDB GSI Type Compatibility Skill

## Skill Metadata
- **Name**: DynamoDB GSI Type Compatibility
- **Version**: 1.0.0
- **Category**: AWS / DynamoDB / Data Modeling
- **Applicable Agents**: Python AWS Developer, LLD Architect, DevOps Engineer
- **Created**: 2025-12-31
- **Source Session**: Campaigns Lambda DEV Deployment

---

## Problem Statement

When using DynamoDB Global Secondary Indexes (GSIs), the attribute types defined in the table schema must match exactly with the data types stored by the application code. A common pitfall occurs when:

- **Table Schema**: Defines an attribute as `N` (Number)
- **Application Code**: Stores the attribute as `BOOL` (Boolean)

This mismatch causes a `ValidationException` during write operations.

---

## Error Signature

```
botocore.exceptions.ClientError: An error occurred (ValidationException) when calling the PutItem operation: One or more parameter values were invalid: Type mismatch for Index Key {attribute_name} Expected: N Actual: BOOL IndexName: {index_name}
```

### Example Error
```
Type mismatch for Index Key active Expected: N Actual: BOOL IndexName: ActiveIndex
```

---

## Root Cause

DynamoDB is strict about attribute types for GSI key attributes:

| DynamoDB Type | Code Type | Compatible |
|---------------|-----------|------------|
| `N` (Number) | `int`, `float`, `Decimal` | Yes |
| `N` (Number) | `bool` (`True`/`False`) | **No** |
| `S` (String) | `str` | Yes |
| `BOOL` | `bool` | Yes |

**Key Insight**: Python's `True`/`False` are stored as DynamoDB `BOOL` type, not `N` (Number). If your GSI expects `N`, you must convert booleans to `1`/`0`.

---

## Solution Pattern

### 1. Writing to DynamoDB (Boolean to Number)

```python
def _to_dynamodb_item(self, entity: Entity) -> dict:
    """Convert entity to DynamoDB item."""
    return {
        "PK": f"ENTITY#{entity.id}",
        "SK": "METADATA",
        # Convert boolean to number for GSI compatibility
        "active": 1 if entity.active else 0,
        # Other attributes...
    }
```

### 2. Reading from DynamoDB (Number to Boolean)

```python
def _to_entity(self, item: dict) -> Entity:
    """Convert DynamoDB item to entity."""
    return Entity(
        id=item["id"],
        # Convert number back to boolean
        active=bool(item.get("active", 1)),
        # Other attributes...
    )
```

### 3. Filter Expressions (Use Number, Not Boolean)

```python
# WRONG - Will cause type mismatch in filter
response = table.scan(
    FilterExpression="active = :active",
    ExpressionAttributeValues={
        ":active": True,  # BOOL type - incorrect
    },
)

# CORRECT - Use number for GSI-indexed attributes
response = table.scan(
    FilterExpression="active = :active",
    ExpressionAttributeValues={
        ":active": 1,  # Number type - correct
    },
)
```

### 4. Update Expressions (Use Number, Not Boolean)

```python
# WRONG
table.update_item(
    Key={"PK": pk, "SK": sk},
    UpdateExpression="SET active = :inactive",
    ExpressionAttributeValues={
        ":inactive": False,  # BOOL type - incorrect
    },
)

# CORRECT
table.update_item(
    Key={"PK": pk, "SK": sk},
    UpdateExpression="SET active = :inactive",
    ExpressionAttributeValues={
        ":inactive": 0,  # Number type - correct
    },
)
```

---

## Complete Repository Example

```python
"""
Repository pattern with GSI type compatibility.
"""
import logging
from typing import Optional
from decimal import Decimal

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)


class CampaignRepository:
    """Repository with proper GSI type handling."""

    def __init__(self, table_name: str) -> None:
        self.dynamodb = boto3.resource("dynamodb")
        self.table = self.dynamodb.Table(table_name)

    def _campaign_to_item(self, campaign: Campaign) -> dict:
        """
        Convert Campaign model to DynamoDB item.

        IMPORTANT: GSI 'ActiveIndex' expects 'active' as Number (N),
        so we convert boolean to 1/0.
        """
        return {
            "PK": f"CAMPAIGN#{campaign.code}",
            "SK": "METADATA",
            "entityType": "CAMPAIGN",
            "code": campaign.code,
            "name": campaign.name,
            # GSI key attribute - must be Number, not Boolean
            "active": 1 if campaign.active else 0,
            # Other attributes...
        }

    def _to_entity(self, item: dict) -> Campaign:
        """
        Convert DynamoDB item to Campaign entity.

        Converts Number back to boolean for application use.
        """
        return Campaign(
            code=item["code"],
            name=item.get("name", ""),
            # Convert Number to boolean
            active=bool(item.get("active", 1)),
            # Other attributes...
        )

    def find_all_active(self) -> list[Campaign]:
        """Find all active campaigns using GSI."""
        try:
            # Use Number (1) not Boolean (True) for GSI query
            response = self.table.query(
                IndexName="ActiveIndex",
                KeyConditionExpression="active = :active",
                ExpressionAttributeValues={
                    ":active": 1,  # Number, not True
                },
            )
            return [self._to_entity(item) for item in response.get("Items", [])]
        except ClientError as e:
            logger.error(f"DynamoDB error: {e}")
            raise

    def soft_delete(self, code: str) -> bool:
        """Soft delete by setting active=0."""
        try:
            self.table.update_item(
                Key={"PK": f"CAMPAIGN#{code}", "SK": "METADATA"},
                UpdateExpression="SET active = :inactive",
                ExpressionAttributeValues={
                    ":inactive": 0,  # Number, not False
                },
                ConditionExpression="attribute_exists(PK)",
            )
            return True
        except ClientError as e:
            logger.error(f"DynamoDB error: {e}")
            raise
```

---

## Prevention Strategies

### 1. Schema-First Design
Before writing code, document the DynamoDB table schema including all GSI key attributes and their types:

```yaml
# DynamoDB Schema Definition
TableName: campaigns
AttributeDefinitions:
  - AttributeName: PK
    AttributeType: S
  - AttributeName: SK
    AttributeType: S
  - AttributeName: active
    AttributeType: N  # Number - code must use 1/0, not True/False

GlobalSecondaryIndexes:
  - IndexName: ActiveIndex
    KeySchema:
      - AttributeName: active
        KeyType: HASH
```

### 2. Type Mapping Documentation
Create a type mapping document for your repository:

| Entity Field | Python Type | DynamoDB Type | GSI? | Notes |
|--------------|-------------|---------------|------|-------|
| `active` | `bool` | `N` | Yes (ActiveIndex) | Store as 1/0 |
| `status` | `str` | `S` | Yes (StatusIndex) | Enum value |
| `is_deleted` | `bool` | `BOOL` | No | Native boolean OK |

### 3. Unit Tests
Always test the conversion functions:

```python
def test_campaign_to_item_converts_active_to_number():
    """Ensure active field is stored as Number for GSI."""
    repo = CampaignRepository("test-table")
    campaign = Campaign(code="TEST", name="Test", active=True)

    item = repo._campaign_to_item(campaign)

    # Must be 1, not True
    assert item["active"] == 1
    assert type(item["active"]) == int

def test_to_entity_converts_number_to_boolean():
    """Ensure Number is converted back to boolean."""
    repo = CampaignRepository("test-table")
    item = {"code": "TEST", "name": "Test", "active": 1}

    entity = repo._to_entity(item)

    assert entity.active is True
    assert type(entity.active) == bool
```

---

## Debugging Workflow

### Step 1: Identify the Error
Check CloudWatch Logs for the Lambda function:
```bash
aws logs tail /aws/lambda/{function-name} --since 5m --region {region}
```

Look for: `Type mismatch for Index Key`

### Step 2: Check Table Schema
```bash
aws dynamodb describe-table \
  --table-name {table-name} \
  --query 'Table.{AttributeDefinitions:AttributeDefinitions,GlobalSecondaryIndexes:GlobalSecondaryIndexes}' \
  --output json
```

### Step 3: Identify GSI Key Attributes
From the output, note which attributes are GSI keys and their expected types:
```json
{
  "AttributeDefinitions": [
    {"AttributeName": "active", "AttributeType": "N"}
  ],
  "GlobalSecondaryIndexes": [
    {"IndexName": "ActiveIndex", "KeySchema": [{"AttributeName": "active", "KeyType": "HASH"}]}
  ]
}
```

### Step 4: Fix Code
Update repository code to convert types appropriately (see Solution Pattern above).

### Step 5: Update Tests
Add/update unit tests to verify type conversion.

---

## Related Patterns

- **Single-Table Design**: Often uses GSIs with computed/derived attributes
- **Soft Delete Pattern**: Commonly uses `active` or `is_deleted` flags with GSIs
- **Status-based Queries**: GSIs on status fields for efficient filtering

---

## References

- [AWS DynamoDB Data Types](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.NamingRulesDataTypes.html)
- [AWS DynamoDB GSI Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GSI.html)
- [Boto3 DynamoDB Type Handling](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/customizations/dynamodb.html)

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-12-31 | Initial version from Campaigns Lambda deployment |
