# Stage 3: Lambda Services Development

**Stage ID**: stage-3-lambda-services-development
**Project**: project-plan-2-access-management
**Status**: PENDING
**Workers**: 6 (parallel execution)

---

## Stage Objective

Implement all 41 Lambda functions using Test-Driven Development (TDD) and Object-Oriented Programming (OOP) principles. Each service should be a self-contained microservice.

---

## Stage Workers

| Worker | Task | Lambda Count | Status |
|--------|------|--------------|--------|
| worker-1-permission-service-lambdas | Implement Permission Service | 6 | PENDING |
| worker-2-invitation-service-lambdas | Implement Invitation Service | 7 | PENDING |
| worker-3-team-service-lambdas | Implement Team Service | 14 | PENDING |
| worker-4-role-service-lambdas | Implement Role Service | 8 | PENDING |
| worker-5-authorizer-service-lambda | Implement Lambda Authorizer | 1 | PENDING |
| worker-6-audit-service-lambdas | Implement Audit Service | 5 | PENDING |

**Total**: 41 Lambda Functions

---

## Stage Inputs

**From Stage 1**:
- API contract summaries
- Data model summaries
- Implementation checklists

**From Stage 2**:
- DynamoDB table names
- IAM role ARNs
- S3 bucket names

**LLD References**:
- Pydantic models from each LLD
- Handler code examples
- Business logic specifications

---

## Lambda Function Summary

### Permission Service (6 functions)
| Function | Endpoint | Method |
|----------|----------|--------|
| permission_list | /permissions | GET |
| permission_get | /permissions/{id} | GET |
| permission_create | /permissions | POST |
| permission_update | /permissions/{id} | PUT |
| permission_delete | /permissions/{id} | DELETE |
| permission_seed | /permissions/seed | POST |

### Invitation Service (7 functions)
| Function | Endpoint | Method |
|----------|----------|--------|
| invitation_create | /orgs/{orgId}/invitations | POST |
| invitation_list | /orgs/{orgId}/invitations | GET |
| invitation_get | /orgs/{orgId}/invitations/{id} | GET |
| invitation_cancel | /orgs/{orgId}/invitations/{id} | DELETE |
| invitation_resend | /orgs/{orgId}/invitations/{id}/resend | POST |
| invitation_accept | /invitations/accept | POST |
| invitation_cleanup | (scheduled) | - |

### Team Service (14 functions)
| Function | Endpoint | Method |
|----------|----------|--------|
| team_create | /orgs/{orgId}/teams | POST |
| team_list | /orgs/{orgId}/teams | GET |
| team_get | /orgs/{orgId}/teams/{id} | GET |
| team_update | /orgs/{orgId}/teams/{id} | PUT |
| team_delete | /orgs/{orgId}/teams/{id} | DELETE |
| team_member_add | /orgs/{orgId}/teams/{id}/members | POST |
| team_member_list | /orgs/{orgId}/teams/{id}/members | GET |
| team_member_remove | /orgs/{orgId}/teams/{id}/members/{userId} | DELETE |
| team_member_update_role | /orgs/{orgId}/teams/{id}/members/{userId}/role | PUT |
| team_role_create | /orgs/{orgId}/team-roles | POST |
| team_role_list | /orgs/{orgId}/team-roles | GET |
| team_role_get | /orgs/{orgId}/team-roles/{id} | GET |
| team_role_update | /orgs/{orgId}/team-roles/{id} | PUT |
| team_role_delete | /orgs/{orgId}/team-roles/{id} | DELETE |

### Role Service (8 functions)
| Function | Endpoint | Method |
|----------|----------|--------|
| platform_role_list | /platform/roles | GET |
| platform_role_get | /platform/roles/{id} | GET |
| org_role_create | /orgs/{orgId}/roles | POST |
| org_role_list | /orgs/{orgId}/roles | GET |
| org_role_get | /orgs/{orgId}/roles/{id} | GET |
| org_role_update | /orgs/{orgId}/roles/{id} | PUT |
| org_role_delete | /orgs/{orgId}/roles/{id} | DELETE |
| org_role_seed | /orgs/{orgId}/roles/seed | POST |

### Authorizer Service (1 function)
| Function | Type | Description |
|----------|------|-------------|
| authorizer | Lambda Authorizer | JWT validation, permission resolution |

### Audit Service (5 functions)
| Function | Endpoint | Method |
|----------|----------|--------|
| audit_query_org | /orgs/{orgId}/audit | GET |
| audit_query_user | /orgs/{orgId}/audit/users/{userId} | GET |
| audit_query_resource | /orgs/{orgId}/audit/resources/{type}/{id} | GET |
| audit_export | /orgs/{orgId}/audit/export | POST |
| audit_archive | (scheduled) | - |

---

## Stage Outputs

### Directory Structure (per service)
```
lambda/
├── permission_service/
│   ├── __init__.py
│   ├── handlers/
│   │   ├── __init__.py
│   │   ├── list_handler.py
│   │   ├── get_handler.py
│   │   ├── create_handler.py
│   │   ├── update_handler.py
│   │   ├── delete_handler.py
│   │   └── seed_handler.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── permission.py
│   │   └── requests.py
│   ├── services/
│   │   ├── __init__.py
│   │   └── permission_service.py
│   ├── repositories/
│   │   ├── __init__.py
│   │   └── permission_repository.py
│   └── tests/
│       ├── __init__.py
│       ├── test_list_handler.py
│       ├── test_get_handler.py
│       └── ...
├── invitation_service/
│   └── ... (same structure)
├── team_service/
│   └── ...
├── role_service/
│   └── ...
├── authorizer_service/
│   └── ...
└── audit_service/
    └── ...
```

---

## Success Criteria

- [ ] All 41 Lambda functions implemented
- [ ] Tests written BEFORE code (TDD)
- [ ] All unit tests passing
- [ ] > 80% code coverage
- [ ] OOP principles applied
- [ ] Pydantic models match LLD specifications
- [ ] Error handling implemented
- [ ] Logging implemented
- [ ] All 6 workers completed
- [ ] Stage summary created

---

## TDD Workflow

For each Lambda function:
1. **Write test** - Define expected behavior
2. **Run test** - Confirm it fails (RED)
3. **Write code** - Minimum to pass test (GREEN)
4. **Refactor** - Improve code quality
5. **Commit** - Test + code together

---

## Dependencies

**Depends On**: Stage 2 (Infrastructure Terraform)

**Blocks**: Stage 4 (API Gateway Integration)

---

## Shared Components

```
lambda/shared/
├── __init__.py
├── dynamodb_client.py    # DynamoDB wrapper
├── response_builder.py   # HATEOAS responses
├── pagination.py         # Pagination helper
├── audit_logger.py       # Audit event publisher
├── exceptions.py         # Custom exceptions
└── decorators.py         # Auth decorators
```

---

**Created**: 2026-01-23
