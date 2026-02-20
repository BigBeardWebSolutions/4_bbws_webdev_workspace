# DynamoDB Single Table Design Skill

**Skill Type**: Database Design - NoSQL
**Version**: 1.0.0
**Parent Agent**: Coding Instructor

---

## Skill Overview

Comprehensive DynamoDB single table design methodology, access patterns, data modeling, GSI strategies, and best practices for building scalable NoSQL applications.

---

## Single Table Design Philosophy

### Why Single Table?
1. **Performance**: Retrieve related data in a single query
2. **Cost**: Fewer tables = lower costs
3. **Simplicity**: One table to manage
4. **Scalability**: Better partition distribution

### Key Principles
- Design for access patterns, not entities
- Use composite keys (PK + SK)
- Leverage GSIs for alternate access patterns
- Embrace data duplication
- Think in terms of queries, not tables

---

## Core Concepts

### 1. Partition Key (PK) & Sort Key (SK)

```
PK: Groups related items together
SK: Provides ordering and enables range queries
```

#### Example: E-commerce System
```
PK             | SK                | Entity Type | Attributes
---------------|-------------------|-------------|------------------
USER#123       | METADATA          | User        | name, email, ...
USER#123       | ORDER#001         | Order       | date, total, ...
USER#123       | ORDER#002         | Order       | date, total, ...
PRODUCT#456    | METADATA          | Product     | name, price, ...
ORDER#001      | METADATA          | Order       | userId, date, ...
ORDER#001      | ITEM#PRODUCT#456  | OrderItem   | quantity, price
ORDER#001      | ITEM#PRODUCT#789  | OrderItem   | quantity, price
```

---

## Access Patterns

### Defining Access Patterns First

**Step 1**: List all queries your application needs

```
1. Get user by ID
2. Get all orders for a user
3. Get order details with line items
4. Get product by ID
5. Get all products
6. Get recent orders (last 30 days)
7. Find orders by status
```

**Step 2**: Design table structure to support all patterns

---

## Data Modeling Examples

### Example 1: User Management System

#### Entities
- Users
- Organizations
- Teams
- Memberships

#### Access Patterns
```
1. Get user by ID
2. Get user by email
3. Get all users in organization
4. Get all users in team
5. Get all teams in organization
6. Get user's organizations
7. Get user's teams
```

#### Table Design
```
PK                  | SK                | GSI1-PK           | GSI1-SK     | Attributes
--------------------|-------------------|-------------------|-------------|------------------
USER#user123        | METADATA          | EMAIL#john@...    | USER#...    | name, email, ...
USER#user123        | ORG#org456        | ORG#org456        | USER#...    | role, joinDate
USER#user123        | TEAM#team789      | TEAM#team789      | USER#...    | role, joinDate
ORG#org456          | METADATA          | -                 | -           | name, industry
ORG#org456          | TEAM#team789      | -                 | -           | name, created
TEAM#team789        | METADATA          | ORG#org456        | TEAM#...    | name, created
```

#### Query Examples

**Get user by ID**
```python
response = table.get_item(
    Key={
        'PK': 'USER#user123',
        'SK': 'METADATA'
    }
)
```

**Get user by email (using GSI1)**
```python
response = table.query(
    IndexName='GSI1',
    KeyConditionExpression='GSI1-PK = :email',
    ExpressionAttributeValues={
        ':email': 'EMAIL#john@example.com'
    }
)
```

**Get all users in organization**
```python
response = table.query(
    IndexName='GSI1',
    KeyConditionExpression='GSI1-PK = :org AND begins_with(GSI1-SK, :user)',
    ExpressionAttributeValues={
        ':org': 'ORG#org456',
        ':user': 'USER#'
    }
)
```

**Get user's organizations**
```python
response = table.query(
    KeyConditionExpression='PK = :user AND begins_with(SK, :org)',
    ExpressionAttributeValues={
        ':user': 'USER#user123',
        ':org': 'ORG#'
    }
)
```

---

### Example 2: Social Media Application

#### Entities
- Users
- Posts
- Comments
- Likes
- Follows

#### Access Patterns
```
1. Get user profile
2. Get user's posts
3. Get post with comments
4. Get user's timeline (posts from followed users)
5. Get post likes
6. Get user's followers
7. Get users that a user follows
```

#### Table Design
```
PK              | SK                    | GSI1-PK         | GSI1-SK          | Attributes
----------------|----------------------|-----------------|------------------|------------------
USER#alice      | METADATA             | -               | -                | name, bio, avatar
USER#alice      | POST#2024-12-21#001  | -               | -                | content, timestamp
POST#abc123     | METADATA             | USER#alice      | 2024-12-21#001   | content, timestamp
POST#abc123     | COMMENT#2024-12-21#001| -              | -                | userId, text, timestamp
POST#abc123     | LIKE#USER#bob        | -               | -                | timestamp
USER#alice      | FOLLOWS#USER#bob     | USER#bob        | FOLLOWER#alice   | timestamp
```

#### Query Examples

**Get user's posts (reverse chronological)**
```python
response = table.query(
    KeyConditionExpression='PK = :user AND begins_with(SK, :post)',
    ExpressionAttributeValues={
        ':user': 'USER#alice',
        ':post': 'POST#'
    },
    ScanIndexForward=False  # Descending order
)
```

**Get post with all comments**
```python
response = table.query(
    KeyConditionExpression='PK = :post',
    ExpressionAttributeValues={
        ':post': 'POST#abc123'
    }
)
```

**Get user's followers**
```python
response = table.query(
    IndexName='GSI1',
    KeyConditionExpression='GSI1-PK = :user AND begins_with(GSI1-SK, :follower)',
    ExpressionAttributeValues={
        ':user': 'USER#alice',
        ':follower': 'FOLLOWER#'
    }
)
```

---

## Advanced Patterns

### 1. Hierarchical Data

```
Organization > Division > Team > User

PK                      | SK                    | Attributes
------------------------|----------------------|------------------
ORG#acme                | METADATA             | name, industry
ORG#acme                | DIV#sales            | name, head
ORG#acme                | DIV#sales#TEAM#west  | name, manager
ORG#acme                | DIV#sales#TEAM#west#USER#john | role
```

**Query all items in sales division**
```python
response = table.query(
    KeyConditionExpression='PK = :org AND begins_with(SK, :div)',
    ExpressionAttributeValues={
        ':org': 'ORG#acme',
        ':div': 'DIV#sales'
    }
)
```

---

### 2. Time-Series Data

```
PK              | SK                    | Attributes
----------------|----------------------|------------------
SENSOR#temp001  | 2024-12-21T10:00:00  | value: 72.5
SENSOR#temp001  | 2024-12-21T10:05:00  | value: 73.1
SENSOR#temp001  | 2024-12-21T10:10:00  | value: 72.8
```

**Query data for time range**
```python
response = table.query(
    KeyConditionExpression='PK = :sensor AND SK BETWEEN :start AND :end',
    ExpressionAttributeValues={
        ':sensor': 'SENSOR#temp001',
        ':start': '2024-12-21T10:00:00',
        ':end': '2024-12-21T11:00:00'
    }
)
```

---

### 3. Many-to-Many Relationships

```
Students ↔ Courses

PK              | SK                | GSI1-PK         | GSI1-SK        | Attributes
----------------|-------------------|-----------------|----------------|------------------
STUDENT#s123    | METADATA          | -               | -              | name, email
STUDENT#s123    | COURSE#c456       | COURSE#c456     | STUDENT#s123   | grade, enrollDate
COURSE#c456     | METADATA          | -               | -              | name, instructor
```

**Get student's courses**
```python
response = table.query(
    KeyConditionExpression='PK = :student AND begins_with(SK, :course)',
    ExpressionAttributeValues={
        ':student': 'STUDENT#s123',
        ':course': 'COURSE#'
    }
)
```

**Get students in course (using GSI1)**
```python
response = table.query(
    IndexName='GSI1',
    KeyConditionExpression='GSI1-PK = :course AND begins_with(GSI1-SK, :student)',
    ExpressionAttributeValues={
        ':course': 'COURSE#c456',
        ':student': 'STUDENT#'
    }
)
```

---

## GSI (Global Secondary Index) Strategies

### GSI Best Practices

1. **Sparse Indexes**: Only items with GSI keys are included
2. **Overloading**: Use same GSI for multiple access patterns
3. **Projection**: Choose ALL, KEYS_ONLY, or INCLUDE wisely
4. **Capacity**: GSIs have their own read/write capacity

### Example: Overloaded GSI

```
Base Table:
PK          | SK          | Type    | Status  | GSI1-PK      | GSI1-SK
------------|-------------|---------|---------|--------------|------------------
USER#123    | METADATA    | User    | -       | -            | -
ORDER#456   | METADATA    | Order   | PENDING | STATUS#PENDING | ORDER#456
ORDER#789   | METADATA    | Order   | SHIPPED | STATUS#SHIPPED | ORDER#789

GSI1: Query all pending orders
GSI1: Query all shipped orders
```

---

## DynamoDB Operations

### 1. Basic Operations

#### Put Item
```python
table.put_item(
    Item={
        'PK': 'USER#user123',
        'SK': 'METADATA',
        'name': 'John Doe',
        'email': 'john@example.com',
        'createdAt': '2024-12-21T10:00:00Z'
    }
)
```

#### Get Item
```python
response = table.get_item(
    Key={
        'PK': 'USER#user123',
        'SK': 'METADATA'
    }
)
item = response.get('Item')
```

#### Update Item
```python
table.update_item(
    Key={
        'PK': 'USER#user123',
        'SK': 'METADATA'
    },
    UpdateExpression='SET #name = :name, updatedAt = :timestamp',
    ExpressionAttributeNames={
        '#name': 'name'
    },
    ExpressionAttributeValues={
        ':name': 'Jane Doe',
        ':timestamp': '2024-12-21T11:00:00Z'
    }
)
```

#### Delete Item
```python
table.delete_item(
    Key={
        'PK': 'USER#user123',
        'SK': 'METADATA'
    }
)
```

---

### 2. Query Operations

#### Basic Query
```python
response = table.query(
    KeyConditionExpression='PK = :pk',
    ExpressionAttributeValues={
        ':pk': 'USER#user123'
    }
)
```

#### Query with Sort Key Condition
```python
response = table.query(
    KeyConditionExpression='PK = :pk AND begins_with(SK, :sk)',
    ExpressionAttributeValues={
        ':pk': 'USER#user123',
        ':sk': 'ORDER#'
    }
)
```

#### Query with Filter
```python
response = table.query(
    KeyConditionExpression='PK = :pk',
    FilterExpression='#status = :status',
    ExpressionAttributeNames={
        '#status': 'status'
    },
    ExpressionAttributeValues={
        ':pk': 'USER#user123',
        ':status': 'ACTIVE'
    }
)
```

---

### 3. Batch Operations

#### BatchGetItem
```python
response = dynamodb.batch_get_item(
    RequestItems={
        'MyTable': {
            'Keys': [
                {'PK': 'USER#user123', 'SK': 'METADATA'},
                {'PK': 'USER#user456', 'SK': 'METADATA'}
            ]
        }
    }
)
```

#### BatchWriteItem
```python
dynamodb.batch_write_item(
    RequestItems={
        'MyTable': [
            {
                'PutRequest': {
                    'Item': {'PK': 'USER#user123', 'SK': 'METADATA', 'name': 'John'}
                }
            },
            {
                'DeleteRequest': {
                    'Key': {'PK': 'USER#user456', 'SK': 'METADATA'}
                }
            }
        ]
    }
)
```

---

### 4. Transactions

```python
dynamodb.transact_write_items(
    TransactItems=[
        {
            'Put': {
                'TableName': 'MyTable',
                'Item': {'PK': 'USER#user123', 'SK': 'ORDER#001'}
            }
        },
        {
            'Update': {
                'TableName': 'MyTable',
                'Key': {'PK': 'PRODUCT#prod456', 'SK': 'METADATA'},
                'UpdateExpression': 'SET stock = stock - :qty',
                'ExpressionAttributeValues': {':qty': 1}
            }
        }
    ]
)
```

---

## Best Practices

### ✅ DO:
1. Start with access patterns
2. Use composite keys (PK + SK)
3. Denormalize data when needed
4. Use GSIs for alternate queries
5. Use consistent naming conventions
6. Implement TTL for temporary data
7. Use conditional writes to prevent overwrites

### ❌ DON'T:
1. Design tables like SQL
2. Use Scan operations in production
3. Store large items (>400KB)
4. Create too many GSIs (max 20)
5. Use high-cardinality partition keys
6. Ignore hot partitions
7. Forget about eventual consistency

---

## Performance Optimization

### 1. Partition Key Design
- Use high-cardinality keys
- Distribute traffic evenly
- Avoid hot partitions

### 2. Query Optimization
- Use Query instead of Scan
- Limit results with pagination
- Use sparse indexes
- Project only needed attributes

### 3. Capacity Planning
- Use on-demand for unpredictable workloads
- Use provisioned for steady workloads
- Enable auto-scaling

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-12-21 | Initial skill creation |

---

**Skill Status**: Active
**Last Updated**: 2025-12-21
