# Worker Instructions: Repository Naming Convention Validation

**Worker ID**: worker-3-repository-naming-validation
**Stage**: Stage 1 - Requirements & Analysis
**Project**: project-plan-4 (Marketing Lambda Implementation)

---

## Task Description

Validate that the repository name `2_bbws_marketing_lambda` follows the established naming conventions, verify it doesn't conflict with existing repositories, and create a repository setup checklist.

---

## Inputs

- Marketing Lambda LLD section 1.2: Component Overview (Repository name)
- Project CLAUDE.md: Repository naming standards
- Existing repository list (check GitHub)

---

## Deliverables

- `output.md` containing:
  1. Repository Naming Validation
  2. Naming Convention Compliance Check
  3. Conflict Analysis
  4. Repository Setup Checklist
  5. Recommendations

---

## Expected Output Format

```markdown
# Repository Naming Validation Output

## 1. Repository Name Validation

**Proposed Repository Name**: `2_bbws_marketing_lambda`

### Naming Pattern Analysis

| Component | Value | Validation |
|-----------|-------|------------|
| Prefix | `2_` | ✅ Customer Portal (2.x) |
| Organization | `bbws` | ✅ BBWS project |
| Component | `marketing_lambda` | ✅ Descriptive, clear purpose |
| Full Name | `2_bbws_marketing_lambda` | ✅ Compliant |

### Naming Convention Rules

| Rule | Requirement | Status | Notes |
|------|-------------|--------|-------|
| Pattern | `{sequence}_bbws_{component_name}` | ✅ Pass | Follows pattern |
| Lowercase | All lowercase | ✅ Pass | No uppercase letters |
| Separators | Underscores only | ✅ Pass | No hyphens |
| Descriptive | Clear component purpose | ✅ Pass | "marketing_lambda" is clear |
| Parent Reference | Matches HLD numbering (2.1.3) | ✅ Pass | 2_ prefix aligns with 2.1.x |

## 2. Naming Convention Compliance

### LLD Hierarchical Naming
- **HLD**: 2.1_BBWS_Customer_Portal_Public_HLD_V1.1.md
- **LLD**: 2.1.3_LLD_Marketing_Lambda.md
- **Repository**: `2_bbws_marketing_lambda`

**Compliance**: ✅ Naming aligns with LLD hierarchy

### Comparison with Existing Repositories

| LLD | Repository | Naming Pattern |
|-----|------------|----------------|
| 2.1.1_LLD_Tenant_Lambda | `2_bbws_tenant_lambda` | {prefix}_bbws_{component}_lambda |
| 2.1.2_LLD_Auth_Lambda | `2_bbws_auth_lambda` | {prefix}_bbws_{component}_lambda |
| 2.1.3_LLD_Marketing_Lambda | `2_bbws_marketing_lambda` | {prefix}_bbws_{component}_lambda |
| 2.1.4_LLD_Product_Lambda | `2_bbws_product_lambda` | {prefix}_bbws_{component}_lambda |

**Pattern Consistency**: ✅ Follows same pattern as other Lambda repositories

## 3. Conflict Analysis

### Check for Existing Repositories

(Run: gh repo list | grep marketing)

**Result**: ✅ No conflicts found

### Similar Named Repositories
- None identified

## 4. Repository Setup Checklist

### GitHub Repository Creation
- [ ] Create repository: `2_bbws_marketing_lambda`
- [ ] Set description: "Marketing Lambda for BBWS Customer Portal - Campaign retrieval and validation"
- [ ] Set visibility: Private
- [ ] Initialize with README: Yes
- [ ] Add .gitignore: Python
- [ ] Add license: (Per organization policy)

### Repository Configuration
- [ ] Enable Issues
- [ ] Enable Projects
- [ ] Enable Wiki (optional)
- [ ] Enable Discussions (optional)
- [ ] Branch protection rules:
  - [ ] Require pull request reviews (1 reviewer minimum)
  - [ ] Require status checks to pass
  - [ ] Require conversation resolution
  - [ ] Enforce for administrators

### GitHub Secrets Setup

#### DEV Environment
- [ ] `AWS_ACCOUNT_ID_DEV` = 536580886816
- [ ] `AWS_REGION_DEV` = af-south-1
- [ ] `DYNAMODB_TABLE_DEV` = bbws-cpp-dev
- [ ] `AWS_ACCESS_KEY_ID_DEV` (from AWS IAM)
- [ ] `AWS_SECRET_ACCESS_KEY_DEV` (from AWS IAM)

#### SIT Environment
- [ ] `AWS_ACCOUNT_ID_SIT` = 815856636111
- [ ] `AWS_REGION_SIT` = af-south-1
- [ ] `DYNAMODB_TABLE_SIT` = bbws-cpp-sit
- [ ] `AWS_ACCESS_KEY_ID_SIT` (from AWS IAM)
- [ ] `AWS_SECRET_ACCESS_KEY_SIT` (from AWS IAM)

#### PROD Environment
- [ ] `AWS_ACCOUNT_ID_PROD` = 093646564004
- [ ] `AWS_REGION_PROD` = af-south-1
- [ ] `DYNAMODB_TABLE_PROD` = bbws-cpp-prod
- [ ] `AWS_ACCESS_KEY_ID_PROD` (from AWS IAM)
- [ ] `AWS_SECRET_ACCESS_KEY_PROD` (from AWS IAM)

### Repository Topics/Tags
- [ ] `bbws`
- [ ] `marketing`
- [ ] `lambda`
- [ ] `python`
- [ ] `terraform`
- [ ] `customer-portal`
- [ ] `serverless`

## 5. Recommendations

1. **Create Repository Immediately**: Once approved, create the repository to reserve the name
2. **Clone Template**: Consider using an existing Lambda repository as template for consistency
3. **Setup Branch Protection**: Enable branch protection rules before merging any code
4. **Configure Secrets**: Set up all GitHub secrets before enabling CI/CD workflows
5. **Add Topics**: Add repository topics for discoverability

## 6. Validation Summary

- **Repository Name**: ✅ `2_bbws_marketing_lambda` is valid
- **Naming Convention**: ✅ Compliant with established pattern
- **Conflicts**: ✅ No conflicts found
- **Recommendation**: ✅ Approved to proceed with repository creation
```

---

## Success Criteria

- [ ] Repository name validated against naming convention
- [ ] Repository name pattern documented
- [ ] Compliance with LLD hierarchy verified
- [ ] Existing repositories checked for conflicts
- [ ] Repository setup checklist created
- [ ] GitHub secrets configuration documented
- [ ] Branch protection recommendations provided
- [ ] Output.md created with all sections

---

## Execution Steps

1. Extract repository name from Marketing Lambda LLD section 1.2
2. Validate naming pattern: `{sequence}_bbws_{component_name}`
3. Check compliance with LLD/HLD hierarchy
4. Compare with existing Lambda repository naming patterns
5. Check for conflicts (gh repo list | grep marketing)
6. Create repository setup checklist
7. Document GitHub secrets configuration
8. Provide branch protection recommendations
9. Create validation summary
10. Create output.md with all findings
11. Update work.state to COMPLETE

---

## Naming Convention Reference

### Standard Pattern
```
{sequence}_bbws_{component_name}
```

### Examples
- `2_bbws_tenant_lambda` - Tenant management Lambda
- `2_bbws_auth_lambda` - Authentication Lambda
- `2_bbws_marketing_lambda` - Marketing Lambda (this project)
- `2_bbws_product_lambda` - Product Lambda
- `2_bbws_order_lambda` - Order Lambda

### Rules
1. Use sequence number matching HLD (2.x → 2_)
2. Include `bbws` organization prefix
3. Use descriptive component name
4. Use underscores as separators
5. All lowercase
6. No special characters except underscores

---

**Created**: 2025-12-30
