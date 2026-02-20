# DynamoDB Single Table Design Skill

**Version**: 1.0
**Created**: 2025-12-17
**Type**: Database Design Patterns
**Purpose**: Single table design patterns for DynamoDB in serverless AWS architectures

---

## Purpose

Provide comprehensive patterns for DynamoDB single table design including access pattern modeling, key design, relationship patterns, and best practices for serverless applications.

---

## Research Summary

### Research Questions
- What are the core principles of single table design?
- How do you model relationships in single table design?
- When should single table design be used vs multi-table?
- What are common access patterns and how to implement them?

### Key Findings
- Start with access patterns first, not entity relationships
- Use composite keys (pk/sk) with generic names for overloading
- Adjacency list pattern for one-to-many relationships
- Pre-join data using item collections for performance

### Sources
- [The What, Why, and When of Single-Table Design - Alex DeBrie](https://www.alexdebrie.com/posts/dynamodb-single-table/)
- [Creating a single-table design with Amazon DynamoDB - AWS](https://aws.amazon.com/blogs/compute/creating-a-single-table-design-with-amazon-dynamodb/)
- [Data Modeling foundations in DynamoDB - AWS Docs](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/data-modeling-foundations.html)
- [DynamoDB Design Patterns for Single Table Design - Serverless Life](https://www.serverlesslife.com/DynamoDB_Design_Patterns_for_Single_Table_Design.html)
- [DynamoDB Single-Table Design Examples - Dynobase](https://dynobase.dev/dynamodb-single-table-design-examples/)

---

## Core Principles

### Access Patterns First

**Key Rule**: Design starts with access patterns, NOT entity relationships.

**Process**:
1. List all access patterns (queries your app needs)
2. Document each pattern: What data? What filters? What sort order?
3. Design keys to satisfy patterns with minimal requests
4. Optimize for the most common patterns

**Example Access Patterns**:
```
1. Get user by ID
2. Get all orders for a user
3. Get order by ID
4. Get all items in an order
5. Get all orders in date range
6. Get user's orders by status
```

### Generic Key Names

**Physical Keys** should be generic to support overloading:
```
pk    - Partition Key
sk    - Sort Key
gsi1pk - GSI 1 Partition Key
gsi1sk - GSI 1 Sort Key
```

**Entity Prefixes** identify data types:
```
USER#<user_id>
ORDER#<order_id>
ITEM#<item_id>
```

---

## Key Design Patterns

### Composite Key Pattern

**Structure**:
```
pk: ENTITY_TYPE#<id>
sk: ENTITY_TYPE#<id> or METADATA#<attribute>
```

**Example - User with Orders**:
| pk | sk | Attributes |
|----|-----|------------|
| USER#123 | USER#123 | name, email, created_at |
| USER#123 | ORDER#456 | order_date, status, total |
| USER#123 | ORDER#789 | order_date, status, total |

### Adjacency List Pattern

**Purpose**: Model one-to-many and many-to-many relationships.

**Structure**:
```
pk: Parent entity ID
sk: Child entity type + ID
```

**Example - Organization Hierarchy**:
| pk | sk | Attributes |
|----|-----|------------|
| ORG#acme | ORG#acme | name: "ACME Corp" |
| ORG#acme | DIV#sales | name: "Sales Division" |
| ORG#acme | DIV#engineering | name: "Engineering" |
| DIV#sales | TEAM#east | name: "East Region" |
| DIV#sales | TEAM#west | name: "West Region" |

### Inverted Index Pattern (GSI)

**Purpose**: Query in reverse direction.

**Structure**:
- Main table: pk=Parent, sk=Child
- GSI: pk=Child, sk=Parent

**Example - Many-to-Many (Users ↔ Teams)**:
| pk | sk | gsi1pk | gsi1sk |
|----|-----|--------|--------|
| USER#123 | TEAM#A | TEAM#A | USER#123 |
| USER#123 | TEAM#B | TEAM#B | USER#123 |
| USER#456 | TEAM#A | TEAM#A | USER#456 |

Query patterns:
- Get user's teams: `pk = USER#123`
- Get team's users: GSI `gsi1pk = TEAM#A`

---

## Time-Based Access Patterns

### Date Prefix Pattern

**Structure**:
```
sk: DATE#<iso_date>#<entity_id>
```

**Example - Orders by Date**:
| pk | sk |
|----|-----|
| USER#123 | ORDER#2025-01-15#001 |
| USER#123 | ORDER#2025-01-20#002 |
| USER#123 | ORDER#2025-02-01#003 |

**Query - Get orders in January 2025**:
```
pk = USER#123
sk BETWEEN 'ORDER#2025-01-01' AND 'ORDER#2025-01-31~'
```

### Status + Date Pattern

**Structure**:
```
sk: STATUS#<status>#DATE#<iso_date>#<id>
```

**Example - Orders by Status and Date**:
| pk | sk |
|----|-----|
| USER#123 | STATUS#PENDING#DATE#2025-01-15#001 |
| USER#123 | STATUS#SHIPPED#DATE#2025-01-20#002 |
| USER#123 | STATUS#DELIVERED#DATE#2025-02-01#003 |

**Query - Get user's pending orders**:
```
pk = USER#123
sk BEGINS_WITH 'STATUS#PENDING'
```

---

## Item Collections

### Definition
All items with the same partition key form an item collection.

### Best Practice
Design item collections to:
- Contain all data needed for a single access pattern
- Enable single-query retrieval of related data
- Maintain consistency within the collection

### Example - Order with Items
| pk | sk | type | data |
|----|-----|------|------|
| ORDER#123 | ORDER#123 | order | status, total, user_id |
| ORDER#123 | ITEM#001 | item | product_id, qty, price |
| ORDER#123 | ITEM#002 | item | product_id, qty, price |
| ORDER#123 | SHIPPING#001 | shipping | address, carrier |

**Single Query** retrieves entire order with all items.

---

## GSI Strategies

### Sparse Index Pattern

**Purpose**: Index only items with specific attributes.

**Example - Only index active users**:
```
gsi1pk: Exists only when status = "ACTIVE"
```

### GSI Overloading

**Purpose**: Multiple access patterns per GSI.

**Example**:
| Entity | gsi1pk | gsi1sk | Access Pattern |
|--------|--------|--------|----------------|
| User | EMAIL#a@b.com | USER#123 | Get user by email |
| Order | STATUS#PENDING | DATE#2025-01-15 | Get pending orders by date |

---

## Large Item Handling

### Problem
DynamoDB has 400KB item limit.

### Solution - Item Splitting
```
pk: DOC#123
sk: PART#001  → First 50KB
sk: PART#002  → Next 50KB
sk: META      → Metadata (part count, total size)
```

### Alternative - S3 Reference
```
pk: DOC#123
sk: DOC#123
s3_location: s3://bucket/doc/123.json
```

---

## When to Use Single Table Design

### Use When
- Access patterns are well-defined
- Need single-digit millisecond latency
- High read/write throughput required
- Multiple entity types accessed together
- Serverless architecture (minimize connections)

### Avoid When
- Unknown or evolving access patterns
- Heavy analytical/reporting queries
- GraphQL with complex resolvers
- Team lacks DynamoDB expertise
- Rapid prototyping phase

---

## Anti-Patterns

### Relational Thinking
**Wrong**: Design entities first, then access patterns
**Right**: Design access patterns first, then key structure

### Over-Normalization
**Wrong**: Separate tables for each entity type
**Right**: Co-locate related data in item collections

### Generic Queries
**Wrong**: Expect flexible ad-hoc queries like SQL
**Right**: Design specific keys for each access pattern

### Large Aggregates
**Wrong**: Store entire object graphs in single items
**Right**: Split large items, reference by ID

---

## Decision Checklist

Before implementing single table design:

- [ ] All access patterns documented
- [ ] Each pattern has clear pk/sk design
- [ ] Relationships mapped to adjacency lists or GSIs
- [ ] Time-based patterns use date prefixes
- [ ] Large items have splitting strategy
- [ ] GSIs designed for inverse lookups
- [ ] Team understands the patterns

---

## Version History

- **v1.0** (2025-12-17): Initial skill with embedded research on single table design patterns
