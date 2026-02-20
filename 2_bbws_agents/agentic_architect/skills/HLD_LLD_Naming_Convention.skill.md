# HLD-LLD Naming Convention Skill

**Version**: 1.0
**Created**: 2025-12-17
**Type**: Documentation Architecture Pattern
**Purpose**: Establish hierarchical naming convention linking LLDs to their parent HLDs

---

## Purpose

Create a traceable hierarchy between High-Level Design (HLD) documents and their derived Low-Level Design (LLD) documents using a numeric prefix system. This ensures:
- Clear parent-child relationships between HLDs and LLDs
- Version traceability across document generations
- Easy navigation in document repositories
- Consistent naming across projects

---

## Naming Convention

### Pattern

```
[phase].[sub-phase]_[document-type]_[name].[version].md

HLD Pattern: [phase].[sub-phase]_HLD_[Name].md
LLD Pattern: [phase].[sub-phase].[lld-number]_LLD_[Name].md
```

### Hierarchy Structure

```
HLD Prefix        → LLD Prefix
───────────────────────────────
3.1               → 3.1.1, 3.1.2, 3.1.3, ...
3.2               → 3.2.1, 3.2.2, 3.2.3, ...
4.1               → 4.1.1, 4.1.2, 4.1.3, ...
```

### Components Explained

| Component | Description | Example |
|-----------|-------------|---------|
| `phase` | Major project phase number | `3` (Phase 3) |
| `sub-phase` | Sub-phase within phase | `3.1` (Phase 3, Sub-phase 1) |
| `lld-number` | Sequential LLD number under HLD | `3.1.1` (First LLD under 3.1 HLD) |
| `document-type` | HLD or LLD | `HLD`, `LLD` |
| `name` | Descriptive document name | `Customer_Portal_Public` |
| `version` | Optional version suffix | `v1.0`, `v1.2.3` |

---

## Examples

### Example 1: Customer Portal Public

**HLD**:
```
3.1_HLD_Customer_Portal_Public.md
```

**Derived LLDs**:
```
3.1.1_LLD_Frontend_Architecture.md
3.1.2_LLD_Auth_Lambda.md
3.1.3_LLD_Marketing_Lambda.md
3.1.4_LLD_Product_Lambda.md
3.1.5_LLD_Contact_Lambda.md
3.1.6_LLD_Cart_Lambda.md
3.1.7_LLD_Order_Lambda.md
3.1.8_LLD_Payment_Lambda.md
3.1.9_LLD_Newsletter_Lambda.md
3.1.10_LLD_Invitation_Lambda.md
```

### Example 2: Customer Portal Private

**HLD**:
```
3.2_HLD_Customer_Portal_Private.md
```

**Derived LLDs**:
```
3.2.1_LLD_Dashboard.md
3.2.2_LLD_Site_Management.md
3.2.3_LLD_Organisation_Management.md
3.2.4_LLD_User_Management.md
3.2.5_LLD_Billing.md
```

### Example 3: Admin Portal

**HLD**:
```
3.3_HLD_Admin_Portal.md
```

**Derived LLDs**:
```
3.3.1_LLD_Admin_Dashboard.md
3.3.2_LLD_Tenant_Administration.md
3.3.3_LLD_System_Configuration.md
3.3.4_LLD_Audit_Logging.md
```

---

## Version Suffix Convention

When HLDs have versions, LLDs inherit the major.minor version:

### HLD Versioning

```
3.1_HLD_Customer_Portal_Public_v1.0.md    # Initial version
3.1_HLD_Customer_Portal_Public_v1.1.md    # Minor update
3.1_HLD_Customer_Portal_Public_v2.0.md    # Major revision
```

### LLD Versioning (Inherits HLD Major.Minor)

```
# For HLD v1.0
3.1.1_LLD_Auth_Lambda_v1.0.md
3.1.2_LLD_Cart_Lambda_v1.0.md

# For HLD v1.1 (minor update - LLDs may or may not change)
3.1.1_LLD_Auth_Lambda_v1.1.md     # Updated
3.1.2_LLD_Cart_Lambda_v1.0.md     # Unchanged

# For HLD v2.0 (major revision - all LLDs should be reviewed)
3.1.1_LLD_Auth_Lambda_v2.0.md
3.1.2_LLD_Cart_Lambda_v2.0.md
```

### Version Rules

| Rule | Description |
|------|-------------|
| Major version bump | All LLDs must be reviewed and potentially updated |
| Minor version bump | Only affected LLDs need updates |
| Patch version bump | LLD version stays same unless directly affected |
| New LLD creation | Inherits current HLD major.minor version |

---

## Directory Structure

```
2_bbws_docs/
├── HLDs/
│   ├── 3.1_HLD_Customer_Portal_Public.md
│   ├── 3.2_HLD_Customer_Portal_Private.md
│   ├── 3.3_HLD_Admin_Portal.md
│   └── 4.1_HLD_ECS_WordPress.md
│
├── LLDs/
│   ├── 3.1.1_LLD_Frontend_Architecture.md
│   ├── 3.1.2_LLD_Auth_Lambda.md
│   ├── 3.1.3_LLD_Marketing_Lambda.md
│   ├── 3.1.4_LLD_Product_Lambda.md
│   ├── 3.1.5_LLD_Contact_Lambda.md
│   ├── 3.1.6_LLD_Cart_Lambda.md
│   ├── 3.1.7_LLD_Order_Lambda.md
│   ├── 3.1.8_LLD_Payment_Lambda.md
│   ├── 3.1.9_LLD_Newsletter_Lambda.md
│   ├── 3.1.10_LLD_Invitation_Lambda.md
│   ├── 3.2.1_LLD_Dashboard.md
│   ├── 3.2.2_LLD_Site_Management.md
│   └── ...
│
└── README.md
```

---

## HLD-LLD Reference Table

Each HLD should include a reference table listing all derived LLDs:

### In HLD Document

```markdown
## LLDs Reference

| LLD ID | LLD Name | Description | Status |
|--------|----------|-------------|--------|
| 3.1.1 | Frontend Architecture | React SPA, routing, state | Draft |
| 3.1.2 | Auth Lambda | Authentication service | In Review |
| 3.1.3 | Marketing Lambda | Campaign service | Approved |
| 3.1.4 | Product Lambda | Product catalog | Draft |
| 3.1.5 | Contact Lambda | Contact form service | Draft |
| 3.1.6 | Cart Lambda | Shopping cart | Draft |
| 3.1.7 | Order Lambda | Order management | Draft |
| 3.1.8 | Payment Lambda | PayFast integration | Draft |
| 3.1.9 | Newsletter Lambda | Newsletter subscription | Draft |
| 3.1.10 | Invitation Lambda | Invitation service | Draft |
```

### In LLD Document

```markdown
## Parent HLD Reference

| Attribute | Value |
|-----------|-------|
| Parent HLD | 3.1_HLD_Customer_Portal_Public.md |
| HLD Version | v1.2.3 |
| LLD ID | 3.1.2 |
| LLD Status | In Review |
```

---

## Workflow: Creating New LLDs from HLD

### Step 1: Identify HLD Prefix

```
HLD: 3.1_HLD_Customer_Portal_Public.md
Prefix: 3.1
```

### Step 2: Determine Next LLD Number

```bash
# List existing LLDs for this HLD
ls LLDs/3.1.*_LLD_*.md

# Output:
# 3.1.1_LLD_Frontend_Architecture.md
# 3.1.2_LLD_Auth_Lambda.md
# 3.1.3_LLD_Marketing_Lambda.md

# Next available: 3.1.4
```

### Step 3: Create LLD with Correct Prefix

```
New LLD: 3.1.4_LLD_Product_Lambda.md
```

### Step 4: Update HLD Reference Table

Add new LLD to the HLD's LLDs Reference table.

### Step 5: Add Parent Reference to LLD

Include Parent HLD Reference section in the new LLD.

---

## Decision Rules

### Rule 1: LLD Prefix Derives from HLD

```
IF creating LLD for HLD with prefix X.Y
THEN LLD prefix MUST be X.Y.Z (where Z is sequential)
```

### Rule 2: Sequential Numbering

```
LLDs are numbered sequentially starting from 1:
X.Y.1, X.Y.2, X.Y.3, ... X.Y.N
```

### Rule 3: Version Inheritance

```
IF HLD version is A.B.C
THEN new LLDs inherit version A.B (major.minor)
```

### Rule 4: Cross-Reference Required

```
HLD MUST list all derived LLDs in reference table
LLD MUST reference parent HLD with version
```

### Rule 5: Gap Filling

```
IF LLD 3.1.4 is deleted
THEN number 4 is NOT reused
NEXT LLD is 3.1.N+1 (where N is highest existing number)
```

---

## DevOps Integration

### Repository Naming Alignment

The LLD prefix maps to repository naming:

```
LLD: 3.1.2_LLD_Auth_Lambda.md
Repo: 2_bbws_auth_lambda

LLD: 3.1.6_LLD_Cart_Lambda.md
Repo: 2_bbws_cart_lambda
```

### Code Generation from LLD

```bash
# Generate code from LLD with proper naming
python utils/devops/code_gen.py scaffold \
  --lld ./LLDs/3.1.2_LLD_Auth_Lambda.md \
  --output ./2_bbws_auth_lambda

# The LLD prefix (3.1.2) is stored in repo metadata
```

### Traceability in CI/CD

```yaml
# In GitHub Actions workflow
env:
  HLD_PREFIX: "3.1"
  LLD_PREFIX: "3.1.2"
  LLD_NAME: "Auth_Lambda"
  HLD_VERSION: "v1.2.3"
```

---

## Success Criteria

This convention has been applied successfully when:

1. **Every LLD has parent HLD prefix**: All LLDs follow X.Y.Z pattern
2. **Sequential numbering maintained**: No gaps or duplicates in LLD numbers
3. **Cross-references complete**: HLD lists all LLDs, LLDs reference parent HLD
4. **Version alignment**: LLD versions align with HLD major.minor
5. **Repository traceability**: LLD can be mapped to repository

---

## Error Handling

### Orphan LLD (No Parent HLD)

```
IF LLD has no identifiable parent HLD
THEN:
  1. Determine appropriate HLD or create new one
  2. Assign correct prefix
  3. Rename LLD file
  4. Update cross-references
```

### Duplicate LLD Numbers

```
IF two LLDs have same X.Y.Z prefix
THEN:
  1. Identify which was created first (git history)
  2. Renumber the later one to next available
  3. Update all references
```

### Missing LLD Reference in HLD

```
IF LLD exists but not listed in parent HLD
THEN:
  1. Add LLD to HLD reference table
  2. Update LLD status
```

---

## Related Skills

- `repo_microservice_mapping.skill.md` - Repository naming patterns
- `hateoas_relational_design.skill.md` - API hierarchy patterns

---

## Version History

- **v1.0** (2025-12-17): Initial skill definition for HLD-LLD naming convention
