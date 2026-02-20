# Worker Instructions: Lambda IAM Roles Module

**Worker ID**: worker-2-lambda-iam-roles-module
**Stage**: Stage 2 - Infrastructure Terraform
**Project**: project-plan-2-access-management

---

## Task

Create Terraform module for IAM roles and policies for all 6 Access Management Lambda services. Follow least-privilege principle.

---

## Inputs

**From Stage 1**:
- All worker outputs for service requirements
- Integration points identified

**LLD References**:
- IAM policies from all LLDs

---

## Deliverables

Create Terraform module in `output.md`:

### 1. Module Structure

```
terraform/modules/iam-access-management/
├── main.tf           # Role definitions
├── policies.tf       # Policy documents
├── variables.tf      # Input variables
└── outputs.tf        # Output values (role ARNs)
```

### 2. IAM Roles (6 Service Roles)

| Role Name | Service | Key Permissions |
|-----------|---------|-----------------|
| permission-service-role | Permission Service | DynamoDB CRUD on permissions |
| invitation-service-role | Invitation Service | DynamoDB, SES send |
| team-service-role | Team Service | DynamoDB CRUD on teams |
| role-service-role | Role Service | DynamoDB CRUD on roles |
| authorizer-service-role | Authorizer | DynamoDB read, Cognito JWKS |
| audit-service-role | Audit Service | DynamoDB, S3, EventBridge |

### 3. Policy Requirements

**Common Permissions** (all roles):
- CloudWatch Logs (logs:CreateLogGroup, PutLogEvents)
- X-Ray (xray:PutTraceSegments)

**Permission Service**:
- DynamoDB: GetItem, PutItem, UpdateItem, DeleteItem, Query on permissions
- Condition: Key prefix PERMISSION#

**Invitation Service**:
- DynamoDB: Full CRUD on invitations
- SES: SendEmail
- Condition: Key prefix ORG#*INVITATION#, TOKEN#

**Team Service**:
- DynamoDB: Full CRUD on teams, members, team roles
- Condition: Key prefix ORG#*TEAM#, TEAM#*MEMBER#

**Role Service**:
- DynamoDB: Full CRUD on roles, assignments
- Condition: Key prefix PLATFORM, ORG#*ROLE#, ORG#*USER#*ROLE#

**Authorizer Service**:
- DynamoDB: Read-only on all entities
- No write permissions

**Audit Service**:
- DynamoDB: Read/Write on audit events
- S3: PutObject, GetObject on audit bucket
- EventBridge: PutEvents
- Condition: Key prefix ORG#*DATE#*EVENT#

### 4. Trust Policy

All roles trust Lambda service:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "lambda.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
```

---

## Success Criteria

- [ ] 6 IAM roles created
- [ ] Least-privilege policies
- [ ] No wildcard resources where avoidable
- [ ] DynamoDB conditions use key prefixes
- [ ] CloudWatch Logs permissions included
- [ ] X-Ray permissions included
- [ ] Environment parameterized
- [ ] Role ARNs exported as outputs

---

## Execution Steps

1. Read Stage 1 outputs for service permissions
2. Design role structure
3. Create trust policy
4. Create service-specific policies
5. Add CloudWatch and X-Ray permissions
6. Create variables.tf
7. Create outputs.tf with role ARNs
8. Validate Terraform syntax
9. Create output.md
10. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
