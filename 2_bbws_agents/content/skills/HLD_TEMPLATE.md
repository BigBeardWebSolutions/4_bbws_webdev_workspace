# [Application Name] - High-Level Design

**Version**: 1.0.0
**Created**: [YYYY-MM-DD]
**Status**: Draft
**Document Type**: High-Level Design (HLD)
**Application**: [Application Name]
**Phase**: [Phase Number] ([Phase Description])

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | [YYYY-MM-DD] | [Author Name] | Initial version |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Application Overview](#2-application-overview)
3. [Screens](#3-screens)
4. [Microservices](#4-microservices)
5. [API Endpoints](#5-api-endpoints)
6. [Authentication](#6-authentication)
7. [DynamoDB Schema](#7-dynamodb-schema)
8. [Infrastructure](#8-infrastructure)
9. [Repositories](#9-repositories)
10. [Business Approval Requirements](#10-business-approval-requirements)
11. [Implementation Plan](#11-implementation-plan)
12. [LLDs Reference](#12-llds-reference)
13. [Appendices](#13-appendices)

---

## 1. Executive Summary

### 1.1 Purpose

[Describe the purpose and business objective of this application]

### 1.2 Business Value

- **[Value Point 1]**: [Description]
- **[Value Point 2]**: [Description]
- **[Value Point 3]**: [Description]
- **[Value Point 4]**: [Description]
- **[Value Point 5]**: [Description]

### 1.3 Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Backend | Lambda (Python 3.12) | [Rationale] |
| Frontend | React SPA | [Rationale] |
| Database | DynamoDB | [Rationale] |
| Infrastructure | Per-component Terraform | [Rationale] |
| Development | UI-first + API mocks | [Rationale] |
| Data Deletion | Soft delete (active=false) | Audit trail, recovery, data integrity |
| API Pattern | No DELETE operations | Status updates for all state changes |

---

## 2. Application Overview

### 2.1 Application Definition

| Attribute | Value |
|-----------|-------|
| **HLD File** | `[HLD_File_Name].md` |
| **URL (PROD)** | `https://[domain]` |
| **URL (SIT)** | `https://sit.[domain]` |
| **URL (DEV)** | `https://dev.[domain]` |
| **API Base (PROD)** | `https://api.[domain]` |
| **API Base (SIT)** | `https://sit.api.[domain]` |
| **API Base (DEV)** | `https://dev.api.[domain]` |
| **Authentication** | [Auth Type] (e.g., Cognito, OAuth, API Key, None) |
| **Target Users** | [User Personas] |
| **Priority** | Phase [X] ([Priority Description]) |

### 2.2 Scope

**In Scope:**
- [Feature 1]
- [Feature 2]
- [Feature 3]
- [Feature 4]

**Out of Scope:**
- [Feature 1]
- [Feature 2]
- [Feature 3]

---

## 3. Screens

### 3.1 Screen Summary ([X] Total)

| Category | Screens | Count |
|----------|---------|-------|
| [Category 1] | [Screen IDs] | [X] |
| [Category 2] | [Screen IDs] | [X] |
| [Category 3] | [Screen IDs] | [X] |
| **Total** | | **[X]** |

### 3.2 Screen List

#### [Category Name] Screens ([X])

| # | Screen ID | Screen Name | Description |
|---|-----------|-------------|-------------|
| 1 | [APP-XXX] | [Screen Name] | [Description] |
| 2 | [APP-XXX] | [Screen Name] | [Description] |

---

## 4. Microservices

### 4.1 Service Overview ([X] Total)

| # | Service | Repository | API Prefix | Functions | Description |
|---|---------|------------|------------|-----------|-------------|
| 1 | [Service Name] | `[HLD_Prefix]_[project]_[service]_lambda` | `/v1.0/[resource]` | [X] | [Description] |

### 4.2 Lambda Function Count

| Service | Functions | Total |
|---------|-----------|-------|
| [Service] | create-[entity], get-[entity], update-[entity], list-[entities], soft-delete-[entity] | 5 |
| **Total** | | **[X]** |

### 4.3 Lambda Configuration

| Setting | Value |
|---------|-------|
| Runtime | Python 3.12 |
| Memory | 256MB |
| Timeout | 30s |
| Architecture | arm64 |

---

## 5. API Endpoints

### 5.1 API Structure

**Base URL (PROD)**: `https://api.[domain]`
**Base URL (SIT)**: `https://sit.api.[domain]`
**Base URL (DEV)**: `https://dev.api.[domain]`

> **Note**: API version (`/v1.0`) is included in each endpoint path, not the base URL.

### 5.2 HATEOAS Operations: [Entity Name]

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/v1.0/[entities]` | Create a new [entity] |
| GET | `/v1.0/[entities]/{id}` | Get [entity] details |
| GET | `/v1.0/[entities]` | List all [entities] (active only by default, use `?include_inactive=true` for all) |
| PUT | `/v1.0/[entities]/{id}` | Update [entity] details |
| PUT | `/v1.0/[entities]/{id}` | Soft delete [entity] (set active=false) |

#### 5.2.1 POST `/v1.0/[entities]` - Create [Entity]

**Request Headers:**
```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer <token>"
}
```

**Request Body:**
```json
{
  "name": "Example Entity",
  "description": "This is an example entity",
  "status": "ACTIVE",
  "metadata": {
    "key1": "value1",
    "key2": "value2"
  }
}
```

**Success Response (201 Created):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Example Entity",
  "description": "This is an example entity",
  "status": "ACTIVE",
  "dateCreated": "2025-12-19T10:30:00Z",
  "dateLastUpdated": "2025-12-19T10:30:00Z",
  "lastUpdatedBy": "admin@example.com",
  "active": true,
  "metadata": {
    "key1": "value1",
    "key2": "value2"
  }
}
```

**Error Response (400 Bad Request):**
```json
{
  "error": "ValidationError",
  "message": "Invalid request payload",
  "details": [
    {
      "field": "name",
      "message": "Name is required"
    }
  ]
}
```

#### 5.2.2 GET `/v1.0/[entities]/{id}` - Get [Entity]

**Request Headers:**
```json
{
  "Authorization": "Bearer <token>"
}
```

**Success Response (200 OK):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Example Entity",
  "description": "This is an example entity",
  "status": "ACTIVE",
  "dateCreated": "2025-12-19T10:30:00Z",
  "dateLastUpdated": "2025-12-19T10:30:00Z",
  "lastUpdatedBy": "admin@example.com",
  "active": true,
  "metadata": {
    "key1": "value1",
    "key2": "value2"
  }
}
```

**Error Response (404 Not Found):**
```json
{
  "error": "NotFound",
  "message": "Entity with id '550e8400-e29b-41d4-a716-446655440000' not found"
}
```

#### 5.2.3 GET `/v1.0/[entities]` - List [Entities]

**Query Parameters:**
- `include_inactive` (boolean, optional): Include soft-deleted records. Default: `false`
- `pageSize` (integer, optional): Number of items to return per page. Default: `50`, Max: `100`
- `startAt` (string, optional): Pagination token to start at a specific position

**Request Headers:**
```json
{
  "Authorization": "Bearer <token>"
}
```

**Success Response (200 OK):**
```json
{
  "items": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Example Entity 1",
      "description": "First example",
      "status": "ACTIVE",
      "dateCreated": "2025-12-19T10:30:00Z",
      "dateLastUpdated": "2025-12-19T10:30:00Z",
      "lastUpdatedBy": "admin@example.com",
      "active": true
    },
    {
      "id": "660e8400-e29b-41d4-a716-446655440001",
      "name": "Example Entity 2",
      "description": "Second example",
      "status": "ACTIVE",
      "dateCreated": "2025-12-19T11:00:00Z",
      "dateLastUpdated": "2025-12-19T11:00:00Z",
      "lastUpdatedBy": "admin@example.com",
      "active": true
    }
  ],
  "startAt": "660e8400-e29b-41d4-a716-446655440001",
  "moreAvailable": false
}
```

#### 5.2.4 PUT `/v1.0/[entities]/{id}` - Update [Entity]

**Request Headers:**
```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer <token>"
}
```

**Request Body (Update Details):**
```json
{
  "name": "Updated Entity Name",
  "description": "Updated description",
  "metadata": {
    "key1": "updated_value1"
  }
}
```

**Success Response (200 OK):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Updated Entity Name",
  "description": "Updated description",
  "status": "ACTIVE",
  "dateCreated": "2025-12-19T10:30:00Z",
  "dateLastUpdated": "2025-12-19T12:00:00Z",
  "lastUpdatedBy": "admin@example.com",
  "active": true,
  "metadata": {
    "key1": "updated_value1"
  }
}
```

#### 5.2.5 PUT `/v1.0/[entities]/{id}` - Soft Delete [Entity]

**Request Headers:**
```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer <token>"
}
```

**Request Body (Soft Delete):**
```json
{
  "active": false
}
```

**Success Response (200 OK):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Example Entity",
  "description": "This is an example entity",
  "status": "ACTIVE",
  "dateCreated": "2025-12-19T10:30:00Z",
  "dateLastUpdated": "2025-12-19T13:00:00Z",
  "lastUpdatedBy": "admin@example.com",
  "active": false,
  "metadata": {
    "key1": "value1"
  }
}
```

---

## 6. Authentication

### 6.1 Authentication Method

[Describe authentication approach]

**Authentication Types:**
- [Type 1]: [Description]
- [Type 2]: [Description]

### 6.2 Protected Endpoints

| Endpoint Pattern | Auth Required | Roles |
|-----------------|---------------|-------|
| `/v1.0/[resource]/*` | [Yes/No] | [Role1, Role2] |

---

## 7. DynamoDB Schema

### 7.1 Core Entity Rules

| Entity | Tenant Association | Rule |
|--------|-------------------|------|
| [Entity1] | [Required/Optional/None] | [Description] |
| [Entity2] | [Required/Optional/None] | [Description] |

### 7.2 Entities

> **Soft Delete Pattern**: All entities have an `active` boolean field (default=true). To delete, set `active=false`. Queries filter by `active=true` by default.

| Entity | PK | SK | Attributes |
|--------|----|----|------------|
| [Entity] | `[ENTITY]#{id}` | `METADATA` | id, name, description, dateCreated, dateLastUpdated, lastUpdatedBy, active |

### 7.3 GSIs

| GSI Name | PK | SK | Purpose |
|----------|----|----|---------|
| ActiveIndex | active | dateCreated | Filter by active status (sparse index, all entities) |
| [CustomIndex] | [field] | [field] | [Purpose] |

> **Query Pattern**: All list queries include `active=true` filter by default. Use `include_inactive=true` parameter to include soft-deleted records.

### 7.4 Entity Details

#### 7.4.1 [Entity Name]

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| id | String | Yes | Unique entity identifier (UUID) |
| name | String | Yes | Entity name |
| description | String | Yes | Entity description |
| dateCreated | String | Yes | Creation timestamp (ISO 8601) |
| dateLastUpdated | String | Yes | Last update timestamp (ISO 8601) |
| lastUpdatedBy | String | Yes | Email or ID of user who last updated the entity |
| active | Boolean | Yes | Active status (default=true, false=soft deleted) |

---

## 8. Infrastructure

### 8.1 Per-Component Architecture

Each component manages its own infrastructure:

```
[HLD_Prefix]_[project]_[service]_lambda/
├── src/
│   └── handlers/
├── tests/
├── terraform/
│   ├── main.tf
│   ├── api_gateway.tf
│   ├── lambda.tf
│   ├── cloudfront.tf
│   └── variables.tf
└── README.md
```

### 8.2 AWS Services (Per Component)

| Service | Purpose |
|---------|---------|
| API Gateway | REST API (created per component) |
| Lambda | Python 3.12 handlers |
| CloudFront | CDN routing (per component) |
| DynamoDB | Shared table (accessed by component) |
| S3 | Static assets, deployment artifacts |
| [Other Services] | [Purpose] |

### 8.3 Deployment Strategy

- Each Lambda component has its own `/terraform` folder
- Each component creates its own API Gateway resources
- CloudFront routing configured per component
- Domain routing managed at component level

---

## 9. Repositories

### 9.1 Repository List ([X] Total)

| # | Repository | Type | Description |
|---|------------|------|-------------|
| 1 | `[HLD_Prefix]_[project]_web_[app]` | Frontend | React SPA |
| 2 | `[HLD_Prefix]_[project]_[service]_lambda` | Backend | [Service] service (Python) |
| 3 | `[HLD_Prefix]_[project]_dynamodb_schemas` | Database | DynamoDB table schemas, GSIs, migrations |
| 4 | `[HLD_Prefix]_[project]_operations` | Operations | Dashboards, Alerts, Budgets, Config, Guardrails, Firewall, SCPs etc |

### 9.2 Repository Naming Convention

```
[HLD_Prefix]_[project]_web_[app]          # Frontend application
[HLD_Prefix]_[project]_{service}_lambda   # Lambda backend services
```

**Rules:**
- Prefix: `[HLD_Prefix]_[project]_` (project identifier)
- Lambda services end with `_lambda`
- Each repo contains its own `/terraform` folder

### 9.3 Repository Structure

```
[HLD_Prefix]_[project]_{service}_lambda/
├── src/
│   ├── handlers/          # Lambda handlers
│   ├── services/          # Business logic
│   ├── models/            # Data models
│   └── utils/             # Utilities
├── tests/
│   ├── unit/
│   └── integration/
├── terraform/
│   ├── main.tf
│   ├── api_gateway.tf
│   ├── lambda.tf
│   ├── iam.tf
│   ├── cloudfront.tf
│   ├── variables.tf
│   └── outputs.tf
├── requirements.txt
├── pytest.ini
└── README.md
```

### 9.4 Operations Repository - JSON Configuration Examples

The Operations repository contains JSON configurations for monitoring, alerting, budgets, and security. Below are example JSON payloads for common operational configurations.

#### 9.4.1 CloudWatch Alarm Configuration

**Example: Lambda Error Rate Alarm**
```json
{
  "AlarmName": "[HLD_Prefix]-[service]-error-rate-alarm",
  "AlarmDescription": "Alert when Lambda error rate exceeds threshold",
  "MetricName": "Errors",
  "Namespace": "AWS/Lambda",
  "Statistic": "Sum",
  "Period": 300,
  "EvaluationPeriods": 2,
  "Threshold": 5.0,
  "ComparisonOperator": "GreaterThanThreshold",
  "Dimensions": [
    {
      "Name": "FunctionName",
      "Value": "[HLD_Prefix]-[service]-[function]"
    }
  ],
  "ActionsEnabled": true,
  "AlarmActions": [
    "arn:aws:sns:region:account-id:alert-topic"
  ],
  "TreatMissingData": "notBreaching"
}
```

#### 9.4.2 CloudWatch Dashboard Configuration

**Example: Service Monitoring Dashboard**
```json
{
  "DashboardName": "[HLD_Prefix]-[service]-dashboard",
  "DashboardBody": {
    "widgets": [
      {
        "type": "metric",
        "properties": {
          "metrics": [
            ["AWS/Lambda", "Invocations", {"stat": "Sum", "label": "Total Invocations"}],
            [".", "Errors", {"stat": "Sum", "label": "Total Errors"}],
            [".", "Duration", {"stat": "Average", "label": "Avg Duration"}]
          ],
          "period": 300,
          "stat": "Average",
          "region": "af-south-1",
          "title": "Lambda Performance Metrics",
          "yAxis": {
            "left": {
              "label": "Count",
              "showUnits": false
            }
          }
        }
      },
      {
        "type": "metric",
        "properties": {
          "metrics": [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", {"stat": "Sum"}],
            [".", "ConsumedWriteCapacityUnits", {"stat": "Sum"}]
          ],
          "period": 300,
          "stat": "Average",
          "region": "af-south-1",
          "title": "DynamoDB Capacity"
        }
      }
    ]
  }
}
```

#### 9.4.3 AWS Budget Configuration

**Example: Monthly Cost Budget**
```json
{
  "Budget": {
    "BudgetName": "[HLD_Prefix]-monthly-budget-dev",
    "BudgetLimit": {
      "Amount": "1000",
      "Unit": "USD"
    },
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST",
    "CostFilters": {
      "TagKeyValue": [
        "user:Project$[HLD_Prefix]",
        "user:Environment$DEV"
      ]
    }
  },
  "NotificationsWithSubscribers": [
    {
      "Notification": {
        "NotificationType": "ACTUAL",
        "ComparisonOperator": "GREATER_THAN",
        "Threshold": 80,
        "ThresholdType": "PERCENTAGE",
        "NotificationState": "ALARM"
      },
      "Subscribers": [
        {
          "SubscriptionType": "EMAIL",
          "Address": "devops@example.com"
        }
      ]
    },
    {
      "Notification": {
        "NotificationType": "FORECASTED",
        "ComparisonOperator": "GREATER_THAN",
        "Threshold": 100,
        "ThresholdType": "PERCENTAGE",
        "NotificationState": "ALARM"
      },
      "Subscribers": [
        {
          "SubscriptionType": "EMAIL",
          "Address": "finance@example.com"
        }
      ]
    }
  ]
}
```

#### 9.4.4 AWS Config Rule Configuration

**Example: S3 Bucket Encryption Rule**
```json
{
  "ConfigRuleName": "[HLD_Prefix]-s3-bucket-encryption",
  "Description": "Ensure all S3 buckets have encryption enabled",
  "Source": {
    "Owner": "AWS",
    "SourceIdentifier": "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  },
  "Scope": {
    "ComplianceResourceTypes": [
      "AWS::S3::Bucket"
    ],
    "TagKey": "Project",
    "TagValue": "[HLD_Prefix]"
  },
  "ConfigRuleState": "ACTIVE"
}
```

#### 9.4.5 SNS Topic Configuration for Alerts

**Example: Critical Alerts Topic**
```json
{
  "TopicName": "[HLD_Prefix]-critical-alerts",
  "DisplayName": "[Application Name] Critical Alerts",
  "Attributes": {
    "DeliveryPolicy": {
      "http": {
        "defaultHealthyRetryPolicy": {
          "minDelayTarget": 20,
          "maxDelayTarget": 20,
          "numRetries": 3,
          "numMaxDelayRetries": 0,
          "numNoDelayRetries": 0,
          "numMinDelayRetries": 0,
          "backoffFunction": "linear"
        }
      }
    }
  },
  "Subscriptions": [
    {
      "Protocol": "email",
      "Endpoint": "oncall@example.com"
    },
    {
      "Protocol": "sms",
      "Endpoint": "+1234567890"
    },
    {
      "Protocol": "lambda",
      "Endpoint": "arn:aws:lambda:region:account-id:function:alert-handler"
    }
  ],
  "Tags": [
    {
      "Key": "Project",
      "Value": "[HLD_Prefix]"
    },
    {
      "Key": "Environment",
      "Value": "PROD"
    }
  ]
}
```

#### 9.4.6 WAF Web ACL Configuration

**Example: API Gateway Protection**
```json
{
  "Name": "[HLD_Prefix]-api-gateway-waf",
  "Scope": "REGIONAL",
  "DefaultAction": {
    "Allow": {}
  },
  "Rules": [
    {
      "Name": "RateLimitRule",
      "Priority": 1,
      "Statement": {
        "RateBasedStatement": {
          "Limit": 2000,
          "AggregateKeyType": "IP"
        }
      },
      "Action": {
        "Block": {}
      },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "RateLimitRule"
      }
    },
    {
      "Name": "AWSManagedRulesCommonRuleSet",
      "Priority": 2,
      "Statement": {
        "ManagedRuleGroupStatement": {
          "VendorName": "AWS",
          "Name": "AWSManagedRulesCommonRuleSet"
        }
      },
      "OverrideAction": {
        "None": {}
      },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "AWSManagedRulesCommonRuleSet"
      }
    }
  ],
  "VisibilityConfig": {
    "SampledRequestsEnabled": true,
    "CloudWatchMetricsEnabled": true,
    "MetricName": "[HLD_Prefix]-api-waf"
  },
  "Tags": [
    {
      "Key": "Project",
      "Value": "[HLD_Prefix]"
    }
  ]
}
```

#### 9.4.7 EventBridge Rule Configuration

**Example: Scheduled Lambda Invocation**
```json
{
  "Name": "[HLD_Prefix]-daily-cleanup",
  "Description": "Trigger cleanup Lambda function daily at 2 AM UTC",
  "ScheduleExpression": "cron(0 2 * * ? *)",
  "State": "ENABLED",
  "Targets": [
    {
      "Id": "1",
      "Arn": "arn:aws:lambda:region:account-id:function:[HLD_Prefix]-cleanup",
      "Input": "{\"action\": \"cleanup\", \"environment\": \"prod\"}",
      "RetryPolicy": {
        "MaximumRetryAttempts": 2,
        "MaximumEventAge": 3600
      },
      "DeadLetterConfig": {
        "Arn": "arn:aws:sqs:region:account-id:dlq-queue"
      }
    }
  ],
  "Tags": [
    {
      "Key": "Project",
      "Value": "[HLD_Prefix]"
    }
  ]
}
```

#### 9.4.8 Lambda Dead Letter Queue Configuration

**Example: DLQ for Failed Lambda Invocations**
```json
{
  "QueueName": "[HLD_Prefix]-lambda-dlq",
  "Attributes": {
    "MessageRetentionPeriod": "1209600",
    "VisibilityTimeout": "300",
    "ReceiveMessageWaitTimeSeconds": "20",
    "MaximumMessageSize": "262144"
  },
  "Tags": {
    "Project": "[HLD_Prefix]",
    "Purpose": "DeadLetterQueue",
    "Service": "Lambda"
  },
  "AlarmConfiguration": {
    "AlarmName": "[HLD_Prefix]-dlq-messages-alarm",
    "MetricName": "ApproximateNumberOfMessagesVisible",
    "Namespace": "AWS/SQS",
    "Threshold": 1,
    "ComparisonOperator": "GreaterThanOrEqualToThreshold",
    "EvaluationPeriods": 1,
    "Period": 300,
    "Statistic": "Average",
    "ActionsEnabled": true,
    "AlarmActions": [
      "arn:aws:sns:region:account-id:critical-alerts"
    ]
  }
}
```

---

## 10. Business Approval Requirements

### 10.1 Artefacts Requiring Business Approval

The following artefacts **MUST** have Business Owner (BO) approval before deployment:

| Category | Artefacts | Approval Required |
|----------|-----------|-------------------|
| **UI/UX** | All screens, layouts, components, branding | BO Sign-off |
| **Email Templates** | All transactional email templates | BO Sign-off |
| **Customer Messaging** | Error messages, success messages, notifications, tooltips | BO Sign-off |
| **Marketing Content** | Landing page copy, feature descriptions | BO Sign-off |
| **Legal Content** | Terms of Service, Privacy Policy | BO + Legal Sign-off |

### 10.2 Business Approval Process

```
┌─────────────────────────────────────────────────────────────────┐
│              BUSINESS APPROVAL PROCESS                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. DEVELOPMENT                                                 │
│     └── Dev team completes artefact                            │
│                                                                 │
│  2. DEV REVIEW                                                  │
│     └── Technical review (code quality, security)              │
│                                                                 │
│  3. STAGING DEPLOYMENT                                          │
│     └── Deploy to SIT for business review                      │
│                                                                 │
│  4. BUSINESS OWNER REVIEW                                       │
│     ├── BO reviews UI/messaging/content in SIT                 │
│     ├── BO provides feedback or approval                       │
│     └── Iterate until BO sign-off obtained                     │
│                                                                 │
│  5. PRODUCTION DEPLOYMENT                                       │
│     └── Only after BO sign-off documented                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 11. Implementation Plan

### 11.1 UI-First Development Approach

```
┌─────────────────────────────────────────────────────────────────┐
│               UI-FIRST IMPLEMENTATION FLOW                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Phase 1: UI SCREENS                                            │
│  ├── Build all screens in React                                │
│  ├── Use mock data (static JSON)                               │
│  ├── Component library setup                                   │
│  └── Responsive design                                         │
│                                                                 │
│  Phase 2: API MOCKS                                             │
│  ├── MSW (Mock Service Worker) setup                           │
│  ├── JSON Server for REST endpoints                            │
│  ├── Mock all endpoints                                        │
│  └── Realistic test data                                       │
│                                                                 │
│  Phase 3: PLAYBACK & PO APPROVAL                                │
│  ├── Demo to Product Owner                                     │
│  ├── User flow walkthroughs                                    │
│  ├── Gather feedback                                           │
│  └── Iterate on UI/UX                                          │
│                                                                 │
│  Phase 4: BACKEND IMPLEMENTATION                                │
│  ├── Lambda functions (Python 3.12)                            │
│  ├── DynamoDB tables                                           │
│  ├── API Gateway configuration                                 │
│  └── Per-component Terraform                                   │
│                                                                 │
│  Phase 5: INTEGRATION                                           │
│  ├── Connect frontend to real APIs                             │
│  ├── E2E testing                                               │
│  ├── Integration testing                                       │
│  └── Production deployment                                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 11.2 Milestones (with Business Owner Gates)

> **IMPORTANT**: Each milestone requires **Business Owner (BO) Review** before proceeding to the next milestone. No milestone is considered complete without documented BO sign-off.

| # | Milestone | Deliverables | Tech Review | BO Review |
|---|-----------|--------------|-------------|-----------|
| 0.1 | UI Screens | [X] React screens with mock data | Dev Review | **BO Sign-off Required** |
| 0.2 | API Mocks | MSW handlers for all endpoints | Dev Review | **BO Sign-off Required** |
| 0.3 | Playback | Demo walkthrough, feedback collection | PO Review | **BO Approval Required** |
| 0.4 | DynamoDB Schemas | DynamoDB schemas + migrations | Dev Review | **BO Sign-off Required** |
| 0.5 | [Service] Lambda | Lambda + TF | Dev Review | **BO Sign-off Required** |
| 0.6 | Integration | Frontend + Backend connected | QA Review | **BO Sign-off Required** |
| 0.7 | E2E Testing | Full flow tests | QA Approval | **BO Sign-off Required** |
| 0.8 | UAT | User Acceptance Testing in SIT | QA Review | **BO Final Approval** |
| 0.9 | Production | Live deployment | Tech Lead | **BO Go-Live Approval** |

---

## 12. LLDs Reference

### 12.1 Parent HLD Information

| Attribute | Value |
|-----------|-------|
| HLD Document | `[HLD_Prefix]_HLD_[Name].md` |
| HLD Version | v1.0.0 |
| HLD Prefix | `[HLD_Prefix]` |
| Total LLDs | [X] technical + [Y] operational |

### 12.2 Technical LLDs ([X] Documents)

Following the naming convention: `[HLD_Prefix].[LLD_Number]_LLD_[Name].md`

> **Repository Naming Convention:** All repositories follow the pattern `{HLD_Prefix}_[project]_{service}` where dots in the HLD prefix are replaced with underscores.

| LLD ID | LLD Name | Description | Repository | Status |
|--------|----------|-------------|------------|--------|
| [HLD_Prefix].1 | `[HLD_Prefix].1_LLD_Frontend_Architecture.md` | React SPA, routing, state management | `[repo_prefix]_web_[app]` | Draft |
| [HLD_Prefix].2 | `[HLD_Prefix].2_LLD_[Service]_Lambda.md` | [Service] design (CRUD operations) | `[repo_prefix]_[service]_lambda` | Draft |

### 12.3 Operational Runbooks ([Y] Documents)

Following the naming convention: `[HLD_Prefix].[Number]_OPS_[Name].md`

| OPS ID | Runbook Name | Description | Status |
|--------|--------------|-------------|--------|
| [HLD_Prefix].X | `[HLD_Prefix].X_OPS_Deployment_Runbook.md` | Per-component deployment procedures | Draft |
| [HLD_Prefix].Y | `[HLD_Prefix].Y_OPS_Monitoring_Runbook.md` | CloudWatch dashboards and alerts | Draft |

---

## 13. Appendices

### Appendix A: User Stories

| Story ID | User Story | Priority |
|----------|------------|----------|
| US-[APP]-001 | As a [user type], I want to [action] | P0 |
| US-[APP]-002 | As a [user type], I want to [action] | P1 |

### Appendix B: Screen-to-Service Matrix

| Screen | [Service1] | [Service2] | [Service3] |
|--------|------------|------------|------------|
| [APP-001] [Screen Name] | ✓ | - | - |
| [APP-002] [Screen Name] | - | ✓ | - |

---

## Related Documents

- [Related HLD 1](./[HLD_File].md)
- [Related HLD 2](./[HLD_File].md)
- [Master Plan](/.claude/plans/[plan-file].md)

---

**End of Document**
