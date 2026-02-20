# Worker Instructions: UX Wireframes Validation

**Worker ID**: worker-5-ux-wireframes-validation
**Stage**: Stage 1 - Requirements Validation
**Project**: project-plan-site-builder

---

## Task

Validate the Site Builder UX Wireframes v1.1 document for completeness. Ensure all user journeys, screens, and interactions are documented and mapped to user stories for all 5 personas.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/UX/Site_Builder_Wireframes_v1.md`

**Supporting Inputs**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/BRS/BBWS_Site_Builder_BRS_v1.md`
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.1_LLD_Site_Builder_Frontend.md`

---

## Deliverables

Create `output.md` with the following sections:

### 1. User Journey Validation

Validate all 5 persona journeys are documented:

| Persona | Journey Documented | Steps | Decision Points | Complete |
|---------|-------------------|-------|-----------------|----------|
| Marketing User | Yes/No | X | X | Yes/No |
| Designer | Yes/No | X | X | Yes/No |
| Org Admin | Yes/No | X | X | Yes/No |
| DevOps Engineer | Yes/No | X | X | Yes/No |
| White-Label Partner | Yes/No | X | X | Yes/No |

### 2. Screen Inventory Validation

Validate all screens are documented:

**Core Screens (CORE-001 to CORE-006)**:
| Screen ID | Name | Route | Wireframe | States |
|-----------|------|-------|-----------|--------|
| CORE-001 | Login | `/login` | Yes/No | Empty, Error, Loading |
| CORE-002 | Register | `/register` | Yes/No | Yes/No |
| CORE-003 | Forgot Password | `/forgot-password` | Yes/No | Yes/No |
| CORE-004 | Dashboard | `/page_builder` | Yes/No | Yes/No |
| CORE-005 | Profile Settings | `/settings/profile` | Yes/No | Yes/No |
| CORE-006 | Notifications | `/notifications` | Yes/No | Yes/No |

**Marketing User Screens (MKT-001 to MKT-007)**:
| Screen ID | Name | Route | User Stories | Wireframe |
|-----------|------|-------|--------------|-----------|
| MKT-001 | Page Builder | `/page_builder/project/:id` | US-001, US-003 | Yes/No |
| MKT-002 | Template Selection | `/page_builder/templates` | US-002 | Yes/No |
| MKT-003 | Generation Progress | (SSE) | US-001 | Yes/No |
| MKT-004 | Version History | `/page_builder/project/:id/history` | US-004 | Yes/No |
| MKT-005 | Deployment Modal | (Modal) | US-007 | Yes/No |
| MKT-006 | Analytics Dashboard | `/analytics` | US-009 | Yes/No |
| MKT-007 | Newsletter Generator | `/page_builder/newsletter` | US-024 | Yes/No |

**Designer Screens (DES-001 to DES-010)**:
| Screen ID | Name | Route | User Stories | Wireframe |
|-----------|------|-------|--------------|-----------|
| DES-001 | Logo Creator | `/page_builder/agents/logo` | US-011 | Yes/No |
| DES-002 | Background Generator | `/page_builder/agents/background` | US-012 | Yes/No |
| DES-003 | Theme Selector | `/page_builder/agents/theme` | US-013 | Yes/No |
| DES-004 | Layout Editor | `/page_builder/agents/layout` | US-023 | Yes/No |
| DES-005 | Blog Generator | `/page_builder/agents/blog` | US-022 | Yes/No |
| DES-006 | Newsletter Generator | `/page_builder/agents/newsletter` | US-024 | Yes/No |
| DES-007 | Brand Assets Library | `/assets` | US-002 | Yes/No |
| DES-008 | Template Management | `/templates/manage` | US-002 | Yes/No |
| DES-009 | Brand Score Review | `/page_builder/project/:id/validate` | US-005 | Yes/No |
| DES-010 | Page Structure Outliner | `/page_builder/project/:id/outline` | US-014 | Yes/No |

**Org Admin Screens (ADM-001 to ADM-007)**:
| Screen ID | Name | Route | User Stories | Wireframe |
|-----------|------|-------|--------------|-----------|
| ADM-001 | Organisation Dashboard | `/admin` | US-015 | Yes/No |
| ADM-002 | User Management | `/admin/users` | US-016 | Yes/No |
| ADM-003 | User Invitation | `/admin/users/invite` | US-016 | Yes/No |
| ADM-004 | Team Management | `/admin/teams` | US-017 | Yes/No |
| ADM-005 | Hierarchy Management | `/admin/hierarchy` | US-015 | Yes/No |
| ADM-006 | Access Control Settings | `/admin/access` | US-017 | Yes/No |
| ADM-007 | Multi-Team Assignment | `/admin/users/:id/teams` | US-018 | Yes/No |

**DevOps Engineer Screens (DEV-001 to DEV-007)**:
| Screen ID | Name | Route | User Stories | Wireframe |
|-----------|------|-------|--------------|-----------|
| DEV-001 | Monitoring Dashboard | `/devops` | US-010 | Yes/No |
| DEV-002 | Deployment History | `/devops/deployments` | US-008 | Yes/No |
| DEV-003 | Performance Analytics | `/devops/performance` | US-008 | Yes/No |
| DEV-004 | Error Logs View | `/devops/logs` | US-006 | Yes/No |
| DEV-005 | Cost Analytics | `/devops/costs` | US-010 | Yes/No |
| DEV-006 | Security Scan Results | `/devops/security` | US-006 | Yes/No |
| DEV-007 | Migration Dashboard | `/devops/migration` | US-019-021 | Yes/No |

**Partner Screens (PTN-001 to PTN-008)**:
| Screen ID | Name | Route | User Stories | Wireframe |
|-----------|------|-------|--------------|-----------|
| PTN-001 | Partner Portal Dashboard | `/partner` | US-025-028 | Yes/No |
| PTN-002 | Branding Configuration | `/partner/branding` | US-025 | Yes/No |
| PTN-003 | Sub-Tenant Management | `/partner/tenants` | US-026 | Yes/No |
| PTN-004 | Add Tenant Modal | `/partner/tenants/new` | US-026 | Yes/No |
| PTN-005 | Subscription Management | `/partner/subscription` | US-027 | Yes/No |
| PTN-006 | Billing & Reports | `/partner/billing` | US-028 | Yes/No |
| PTN-007 | Usage Analytics | `/partner/usage` | US-028 | Yes/No |
| PTN-008 | Partner Admin Management | `/partner/admins` | US-026 | Yes/No |

### 3. Navigation Flow Validation

Validate navigation rules are documented:

| From Screen | Action | To Screen | Condition | Documented |
|-------------|--------|-----------|-----------|------------|
| Login | Success | Dashboard | Auth valid | Yes/No |
| Dashboard | Create New | Builder | Always | Yes/No |
| Builder | Deploy | Deployment Modal | Score visible | Yes/No |
| Builder | Click Agent | Agent Panel | Agent available | Yes/No |
| Any | Session timeout | Login | After 30 min | Yes/No |
| Partner Dashboard | Update Branding | Branding Config | Always | Yes/No |

### 4. Screen States Validation

Validate all screens have state variations:

| Screen | Empty State | Loading State | Error State | Success State |
|--------|-------------|---------------|-------------|---------------|
| Login | Yes/No | Yes/No | Yes/No | - |
| Dashboard | Yes/No | Yes/No | Yes/No | Yes/No |
| Builder | Yes/No | Yes/No | Yes/No | Yes/No |
| Deployment Modal | - | Yes/No | Yes/No | Yes/No |
| Partner Dashboard | Yes/No | Yes/No | Yes/No | Yes/No |

### 5. User Story to Screen Mapping

Validate all user stories have wireframe coverage:

| User Story | Primary Screen(s) | Wireframe Exists | States Shown |
|------------|-------------------|------------------|--------------|
| US-001 | MKT-001, MKT-003 | Yes/No | Yes/No |
| US-002 | MKT-002, DES-007 | Yes/No | Yes/No |
| US-003 | MKT-001 | Yes/No | Yes/No |
| US-004 | MKT-004 | Yes/No | Yes/No |
| US-005 | DES-009 | Yes/No | Yes/No |
| US-006 | DEV-004, DEV-006 | Yes/No | Yes/No |
| US-007 | MKT-005 | Yes/No | Yes/No |
| US-008 | DEV-002, DEV-003 | Yes/No | Yes/No |
| US-009 | MKT-006 | Yes/No | Yes/No |
| US-010 | DEV-001, DEV-005 | Yes/No | Yes/No |
| US-011 | DES-001 | Yes/No | Yes/No |
| US-012 | DES-002 | Yes/No | Yes/No |
| US-013 | DES-003 | Yes/No | Yes/No |
| US-014 | DES-010 | Yes/No | Yes/No |
| US-015 | ADM-001, ADM-005 | Yes/No | Yes/No |
| US-016 | ADM-002, ADM-003 | Yes/No | Yes/No |
| US-017 | ADM-004, ADM-006 | Yes/No | Yes/No |
| US-018 | ADM-007 | Yes/No | Yes/No |
| US-019 | DEV-007 | Yes/No | Yes/No |
| US-020 | DEV-007 | Yes/No | Yes/No |
| US-021 | DEV-007 | Yes/No | Yes/No |
| US-022 | DES-005 | Yes/No | Yes/No |
| US-023 | DES-004 | Yes/No | Yes/No |
| US-024 | DES-006, MKT-007 | Yes/No | Yes/No |
| US-025 | PTN-002 | Yes/No | Yes/No |
| US-026 | PTN-003, PTN-004, PTN-008 | Yes/No | Yes/No |
| US-027 | PTN-005 | Yes/No | Yes/No |
| US-028 | PTN-006, PTN-007 | Yes/No | Yes/No |

### 6. Responsive Design Validation

Validate responsive breakpoints are documented:

| Breakpoint | Width | Screens Affected | Documented |
|------------|-------|------------------|------------|
| Desktop | >= 1280px | All | Yes/No |
| Tablet | 768-1279px | All | Yes/No |
| Mobile | < 768px | All | Yes/No |

### 7. Gaps and Issues

| ID | Description | Severity | Recommendation |
|----|-------------|----------|----------------|
| GAP-001 | ... | Critical/High/Medium/Low | ... |

---

## Expected Output Format

```markdown
# UX Wireframes Validation Output

## 1. User Journey Validation

| Persona | Journey Documented | Complete |
|---------|-------------------|----------|
| Marketing User | Yes | Yes |
...

**All 5 personas have documented journeys: Yes/No**

## 2. Screen Inventory Validation

**Core Screens**: X/6 documented
**Marketing Screens**: X/7 documented
**Designer Screens**: X/10 documented
**Admin Screens**: X/7 documented
**DevOps Screens**: X/7 documented
**Partner Screens**: X/8 documented

**Total**: XX/45 screens documented

## 3. Navigation Flow Validation

**Navigation Rules Documented**: X/X

## 4. Screen States Validation

**Screens with All States**: X/XX

## 5. User Story to Screen Mapping

**User Story Coverage**: XX/28

## 6. Responsive Design Validation

**Breakpoints Documented**: X/3

## 7. Gaps and Issues

| ID | Description | Severity |
|----|-------------|----------|
...

## Summary

- Total Screens: 45
- Documented: XX/45
- User Story Coverage: XX/28
- All Personas Have Journeys: Yes/No
- Ready for Stage 5: Yes/No
```

---

## Success Criteria

- [ ] All 5 persona journeys documented
- [ ] All 45+ screens documented
- [ ] All 28 user stories have screen coverage
- [ ] Navigation flows documented
- [ ] Screen states documented
- [ ] Responsive design documented
- [ ] Gaps documented

---

## Execution Steps

1. Read UX Wireframes v1.1 completely
2. Validate user journeys against Section 2
3. Validate screen inventory against Section 3
4. Check navigation rules against Section 10
5. Validate screen states
6. Map user stories to screens
7. Check responsive design documentation
8. Document gaps
9. Create output.md
10. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-16
