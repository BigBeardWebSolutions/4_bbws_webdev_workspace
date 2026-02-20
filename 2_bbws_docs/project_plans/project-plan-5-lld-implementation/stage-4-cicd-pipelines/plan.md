# Stage 4: CI/CD Pipeline Development

**Stage ID**: stage-4-cicd-pipelines
**Project**: project-plan-5-lld-implementation
**Status**: IN_PROGRESS
**Workers**: 6
**Started**: 2026-01-25

---

## Gap Analysis - Existing CI/CD

### Repository CI/CD Status

| Repository | Existing Workflows | Status |
|------------|-------------------|--------|
| `2_bbws_tenants_instances_lambda` | 7 workflows | ✅ Complete |
| `2_bbws_wordpress_site_management_lambda` | 5 workflows | ✅ Complete |
| `2_bbws_tenants_event_handler` | 0 workflows | ❌ Needs CI/CD |
| `2_bbws_tenants_instances_dev` | 1 workflow | ⚠️ Needs promotion workflows |

### Existing Workflows Detail

**`2_bbws_tenants_instances_lambda`**:
- `deploy-dev.yml` - Automatic DEV deployment
- `promote-to-sit.yml` - Manual SIT promotion
- `promote-to-prod.yml` - Manual PROD promotion
- `rollback.yml` - Rollback workflow
- `quality-gates.yml` - Test and lint checks
- `terraform-deploy.yml` - Infrastructure deployment
- `deploy.yml` - Generic deployment

**`2_bbws_wordpress_site_management_lambda`**:
- `deploy-dev.yml` - DEV deployment
- `deploy-sit.yml` - SIT deployment
- `deploy-prod.yml` - PROD deployment
- `test.yml` - Test workflow
- `release-and-test.yml` - Release workflow

---

## Revised Worker Scope

Given existing CI/CD, workers are adjusted to focus on gaps:

| Worker | Task | Scope |
|--------|------|-------|
| Worker 4-1 | Tenant/Instance Lambda CI/CD | ✅ Already complete - VERIFY ONLY |
| Worker 4-2 | Site Management Lambda CI/CD | ✅ Already complete - VERIFY ONLY |
| Worker 4-3 | Event Handler Lambda CI/CD | ❌ CREATE all workflows |
| Worker 4-4 | Terraform Pipelines | ⚠️ Add promotion workflows to GitOps repo |
| Worker 4-5 | GitOps Workflows | ⚠️ Add SIT/PROD environment support |
| Worker 4-6 | Test Automation | ⚠️ Add shared test configurations |

---

## Worker Specifications

### Worker 4-1: Tenant/Instance Lambda CI/CD (VERIFY)

**Repository**: `2_bbws_tenants_instances_lambda`
**Status**: Already has 7 workflows

**Tasks**:
- Verify existing workflows function correctly
- Document workflow usage in README
- Create CI/CD status badge for README

**No new files needed - verification only**

### Worker 4-2: Site Management Lambda CI/CD (VERIFY)

**Repository**: `2_bbws_wordpress_site_management_lambda`
**Status**: Already has 5 workflows

**Tasks**:
- Verify existing workflows function correctly
- Document workflow usage
- Create CI/CD status badge

**No new files needed - verification only**

### Worker 4-3: Event Handler Lambda CI/CD (CREATE)

**Repository**: `2_bbws_tenants_event_handler`
**Status**: No workflows exist

**Files to Create**:
```
.github/workflows/
├── deploy-dev.yml        # DEV deployment on main push
├── promote-to-sit.yml    # Manual SIT promotion
├── promote-to-prod.yml   # Manual PROD promotion
├── rollback.yml          # Emergency rollback
├── quality-gates.yml     # Test, lint, type check
└── sam-deploy.yml        # SAM build and deploy
```

**Pattern**: Follow `2_bbws_tenants_instances_lambda` workflow patterns

### Worker 4-4: Terraform Pipelines (ENHANCE)

**Repository**: `2_bbws_tenants_instances_dev`
**Status**: Has `deploy-tenant.yml` for DEV only

**Files to Create**:
```
.github/workflows/
├── deploy-tenant-sit.yml   # SIT environment tenant deployment
├── deploy-tenant-prod.yml  # PROD environment tenant deployment
└── destroy-tenant.yml      # Controlled tenant destruction
```

### Worker 4-5: GitOps Workflows (ENHANCE)

**Repository**: `2_bbws_tenants_instances_dev`

**Files to Create**:
```
.github/workflows/
├── validate-tenant-config.yml  # PR validation for tenant configs
├── drift-detection.yml         # Scheduled Terraform drift check
└── bulk-operations.yml         # Bulk tenant operations
```

### Worker 4-6: Test Automation (CREATE)

**Scope**: Shared test configurations across repositories

**Files to Create**:
```
# In each Lambda repository
.github/workflows/
└── test-coverage.yml       # Coverage reporting to Codecov

# Shared GitHub Actions
.github/actions/
└── python-setup/
    └── action.yml          # Reusable Python setup action
```

---

## Stage Inputs

| Input | Source |
|-------|--------|
| Existing Workflows | Repository `.github/workflows/` directories |
| Stage 3 Outputs | New repositories created |
| LLD CI/CD Requirements | LLD 2.5, 2.6, 2.7 deployment sections |

---

## Stage Outputs

### Worker 4-3 Outputs (Event Handler CI/CD)
```
2_bbws_tenants_event_handler/.github/workflows/
├── deploy-dev.yml
├── promote-to-sit.yml
├── promote-to-prod.yml
├── rollback.yml
├── quality-gates.yml
└── sam-deploy.yml
```

### Worker 4-4 Outputs (Terraform Pipelines)
```
2_bbws_tenants_instances_dev/.github/workflows/
├── deploy-tenant-sit.yml
├── deploy-tenant-prod.yml
└── destroy-tenant.yml
```

### Worker 4-5 Outputs (GitOps Workflows)
```
2_bbws_tenants_instances_dev/.github/workflows/
├── validate-tenant-config.yml
├── drift-detection.yml
└── bulk-operations.yml
```

### Worker 4-6 Outputs (Test Automation)
```
Each Lambda repo:
├── .github/workflows/test-coverage.yml
├── pytest.ini (if missing)
└── .coveragerc (if missing)
```

---

## Success Criteria

- [ ] Event Handler Lambda has complete CI/CD (6 workflows)
- [ ] GitOps repo supports all environments (DEV/SIT/PROD)
- [ ] All workflows use OIDC authentication (no static credentials)
- [ ] Rollback procedures documented and tested
- [ ] Test coverage reporting configured
- [ ] Quality gates include linting, type checking, tests
- [ ] All 6 workers completed
- [ ] Stage summary created

---

## Environment Configuration

| Environment | AWS Account | Region | OIDC Role |
|-------------|-------------|--------|-----------|
| DEV | 536580886816 | af-south-1 | bbws-github-actions-role-dev |
| SIT | 815856636111 | af-south-1 | bbws-github-actions-role-sit |
| PROD | 093646564004 | af-south-1 | bbws-github-actions-role-prod |

---

## Gate 4 Approval

**Approvers**: DevOps Lead, QA Lead

**Criteria**:
- All CI/CD pipelines functional
- Test automation working
- OIDC authentication verified
- Promotion workflows tested
- Rollback procedures documented

---

**Created**: 2026-01-25
