# Worker 4-1: Validation Workflows

**Worker ID**: worker-4-1-validation-workflows
**Stage**: Stage 4 - CI/CD Pipeline Development
**Status**: PENDING
**Estimated Effort**: Medium
**Dependencies**: Stage 2 Worker 2-6, Stage 3 Worker 3-6

---

## Objective

Create GitHub Actions validation workflows for both repositories that run on pull requests and push to main.

---

## Input Documents

1. **Stage 2 LLD**: CI/CD Pipeline Design (Section 7.3)
2. **Stage 3**: Validation scripts from Worker 3-6

---

## Deliverables

Create workflows for both repositories:

### DynamoDB Repository: `.github/workflows/`
1. **validate-schemas.yml** - Validate JSON schemas
2. **validate-terraform.yml** - Validate Terraform code

### S3 Repository: `.github/workflows/`
1. **validate-templates.yml** - Validate HTML templates
2. **validate-terraform.yml** - Validate Terraform code

Each workflow must:
- Run on pull_request and push to main
- Use Python 3.9+ for validation scripts
- Call validation scripts from Stage 3
- Post results as PR comments
- Fail workflow if validation fails
- Use proper exit codes

---

## Quality Criteria

- [ ] All 4 workflows created
- [ ] Valid YAML syntax
- [ ] Proper triggers (pull_request, push)
- [ ] Uses validation scripts from Stage 3
- [ ] PR comment integration
- [ ] Proper error handling

---

## Output Format

Write output to `output.md` with all 4 workflow files in code blocks.

**Target Length**: 400-500 lines

---

**Worker Created**: 2025-12-25
**Execution Mode**: Parallel
