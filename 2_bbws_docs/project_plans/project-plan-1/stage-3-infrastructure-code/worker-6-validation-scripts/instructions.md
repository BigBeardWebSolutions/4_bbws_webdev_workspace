# Worker 3-6: Validation Scripts

**Worker ID**: worker-3-6-validation-scripts
**Stage**: Stage 3 - Infrastructure Code Development
**Status**: PENDING
**Estimated Effort**: Medium
**Dependencies**: Stage 2 Worker 2-6

---

## Objective

Create validation scripts for JSON schemas, Terraform modules, and HTML templates that will be used in the CI/CD pipeline.

---

## Input Documents

1. **Stage 2 Outputs**:
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-2-lld-document-creation/worker-6-cicd-pipeline-design-section/output.md` (Section 7.3 - GitHub Actions Workflows)

---

## Deliverables

Create `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-3-infrastructure-code/worker-6-validation-scripts/output.md` containing:

### 3 Python Validation Scripts

**1. validate_dynamodb_schemas.py**
- Load all JSON schema files from schemas/ directory
- Validate JSON syntax
- Check required fields: tableName, primaryKey, attributes, globalSecondaryIndexes
- Validate PK/SK patterns match naming conventions
- Validate GSI structure
- Exit with code 0 (success) or 1 (failure)

**2. validate_html_templates.py**
- Load all HTML files from templates/ directory
- Validate HTML5 syntax using html5lib
- Check for required mustache variables (from LLD)
- Check for responsive meta tags
- Check marketing emails have unsubscribe link
- Exit with code 0 (success) or 1 (failure)

**3. validate_terraform_config.py**
- Validate .tfvars files are valid HCL
- Check required variables are present
- Validate account IDs match expected values
- Validate tags structure (7 mandatory tags)
- Validate environment-specific settings (backups, replication)
- Exit with code 0 (success) or 1 (failure)

Each script should:
- Use argparse for CLI arguments
- Have verbose and quiet modes
- Generate JSON report of validation results
- Include unit tests

---

## Quality Criteria

- [ ] All 3 Python scripts created
- [ ] Valid Python 3.9+ syntax
- [ ] Scripts are executable (chmod +x)
- [ ] Each script has --help documentation
- [ ] Each script exits with proper exit codes
- [ ] Error messages are clear and actionable
- [ ] Requirements.txt file included

---

## Output Format

Write output to `output.md` containing all 3 Python scripts plus requirements.txt in code blocks.

**Target Length**: 600-800 lines

---

## Special Instructions

1. **Python Best Practices**: Use type hints, docstrings, proper error handling
2. **CI/CD Ready**: Scripts should be suitable for GitHub Actions
3. **Dependencies**: Minimize dependencies (use standard library where possible)
4. **Exit Codes**: 0 = success, 1 = validation failure, 2 = script error

---

**Worker Created**: 2025-12-25
**Execution Mode**: Parallel (with 5 other Stage 3 workers)
