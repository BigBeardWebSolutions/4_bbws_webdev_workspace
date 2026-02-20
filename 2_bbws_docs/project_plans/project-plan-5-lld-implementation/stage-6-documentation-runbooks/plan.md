# Stage 6: Documentation & Runbooks

**Stage ID**: stage-6-documentation-runbooks
**Project**: project-plan-5-lld-implementation
**Status**: COMPLETE
**Started**: 2026-01-25
**Completed**: 2026-01-25
**Workers**: 9 (parallel execution)

---

## Stage Objective

Create comprehensive operational documentation including deployment runbooks, troubleshooting guides, OpenAPI specifications, architecture diagrams, and developer API documentation.

---

## Stage Workers

| Worker | Task | Deliverable |
|--------|------|-------------|
| worker-1-tenant-deployment-runbook | Tenant Lambda Deployment Runbook | Deploy/promote procedures |
| worker-2-site-deployment-runbook | Site Management Deployment Runbook | Deploy/promote procedures |
| worker-3-instance-deployment-runbook | Instance Lambda Deployment Runbook | Deploy/promote procedures |
| worker-4-promotion-runbook | Environment Promotion Runbook | DEV→SIT→PROD procedures |
| worker-5-troubleshooting-runbook | Troubleshooting Runbook | Common issues and resolutions |
| worker-6-rollback-runbook | Rollback Runbook | Emergency rollback procedures |
| worker-7-openapi-specs | OpenAPI Specifications | YAML specs for all APIs |
| worker-8-architecture-diagrams | Architecture Diagrams | Component, sequence, deployment |
| worker-9-api-documentation | API Documentation | Developer guides, examples |

---

## Stage Inputs

| Input | Source |
|-------|--------|
| Deployed Lambda Code | All repositories |
| CI/CD Pipelines | Stage 4 outputs |
| Integration Test Results | Stage 5 outputs |
| LLD Documents | LLDs 2.5, 2.6, 2.7 |

---

## Stage Outputs

### Worker 1-3: Deployment Runbooks

Location: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/runbooks/`

```
runbooks/
├── tenant_lambda_deployment_runbook.md
├── site_management_deployment_runbook.md
└── instance_lambda_deployment_runbook.md
```

**Each Runbook Contains**:
1. Prerequisites
2. Pre-deployment checklist
3. DEV deployment steps
4. Smoke test verification
5. SIT promotion steps
6. PROD promotion steps
7. Post-deployment verification
8. Rollback triggers

### Worker 4: Promotion Runbook

Location: `runbooks/environment_promotion_runbook.md`

**Contents**:
1. Promotion workflow diagram
2. DEV → SIT promotion
   - Approval requirements
   - Integration test gates
   - Deployment steps
3. SIT → PROD promotion
   - Approval requirements
   - Smoke test gates
   - Deployment steps
4. Cross-service promotion coordination
5. Rollback procedures per environment

### Worker 5: Troubleshooting Runbook

Location: `runbooks/troubleshooting_runbook.md`

**Contents**:
1. Common Issues Matrix

| Symptom | Possible Cause | Resolution |
|---------|----------------|------------|
| 502 Bad Gateway | Lambda cold start timeout | Increase timeout, add provisioned concurrency |
| DynamoDB throttling | On-demand scaling lag | Enable auto-scaling alerts |
| SQS messages in DLQ | Processing failure | Check consumer logs, retry manually |

2. CloudWatch Log Queries
3. Debugging workflows
4. Escalation procedures

### Worker 6: Rollback Runbook

Location: `runbooks/rollback_runbook.md`

**Contents**:
1. Rollback decision criteria
2. Lambda version rollback
   - AWS Console steps
   - CLI commands
   - GitHub Actions trigger
3. Terraform state rollback
4. DynamoDB point-in-time recovery
5. Post-rollback verification
6. Incident documentation

### Worker 7: OpenAPI Specifications

Location: Each repository's `openapi/` directory

```
# 2_bbws_tenant_lambda
openapi/
├── tenant-api.yaml
├── hierarchy-api.yaml
├── users-api.yaml
└── invitations-api.yaml

# 2_bbws_wordpress_site_management_lambda
openapi/
├── sites-api.yaml
├── templates-api.yaml
└── plugins-api.yaml

# 2_bbws_tenants_instances_lambda
openapi/
└── instances-api.yaml
```

**OpenAPI Standards**:
- OpenAPI 3.0.3 specification
- HATEOAS links in responses
- Error response schemas
- Authentication via Cognito JWT
- Environment-specific servers

### Worker 8: Architecture Diagrams

Location: `docs/diagrams/`

**Diagrams to Create**:
1. **Component Diagram** - All services and their interactions
2. **Deployment Diagram** - AWS infrastructure per environment
3. **Sequence Diagrams** - Key API flows
   - Tenant creation flow
   - Site creation (async) flow
   - Instance provisioning (GitOps) flow
4. **Data Flow Diagram** - DynamoDB access patterns
5. **Event Flow Diagram** - EventBridge event routing

### Worker 9: API Documentation

Location: `docs/api/`

**Contents**:
```
docs/api/
├── getting-started.md
├── authentication.md
├── tenant-api-guide.md
├── site-api-guide.md
├── instance-api-guide.md
├── error-handling.md
├── pagination.md
├── webhooks-events.md
└── examples/
    ├── create-tenant.md
    ├── create-site.md
    ├── provision-instance.md
    └── handle-events.md
```

**Each API Guide Contains**:
1. Overview and use cases
2. Authentication requirements
3. Endpoint reference
4. Request/response examples
5. Error codes
6. Rate limits
7. Code samples (Python, JavaScript)

---

## Success Criteria

- [ ] All deployment runbooks complete and tested
- [ ] Promotion runbook covers all scenarios
- [ ] Troubleshooting runbook covers common issues
- [ ] Rollback runbook tested and verified
- [ ] All OpenAPI specs validate (swagger-cli validate)
- [ ] Architecture diagrams accurate and up-to-date
- [ ] API documentation complete with examples
- [ ] All 9 workers completed
- [ ] Stage summary created

---

## Dependencies

**Depends On**: Stage 5 (Integration Testing)

**Blocks**: None (final stage)

---

## Gate 6 Approval (Final)

**Approvers**: Product Owner, Tech Lead, Operations Lead

**Criteria**:
- All runbooks actionable and clear
- OpenAPI specs accurate and complete
- Architecture diagrams reflect implementation
- API documentation enables developer self-service
- Operations team can use runbooks independently

---

## Documentation Standards

- **Format**: Markdown (GitHub-flavored)
- **Diagrams**: Mermaid for inline, draw.io for complex
- **Code Examples**: Syntax highlighted
- **Version Control**: All docs in respective repos

---

**Created**: 2026-01-24
