# Stage F2: Prototype & Mockups

**Parent Plan**: [React App SDLC](./main-plan.md)
**Stage**: F2 of 6
**Status**: PENDING
**Last Updated**: 2026-01-01

---

## Objective

Create interactive prototypes from the UI/UX designs to validate user flows and gather stakeholder feedback before development begins.

---

## Agent & Skill Assignment

| Role | Agent | Skill |
|------|-------|-------|
| **Primary** | Web_Developer_Agent | `web_design_fundamentals.skill.md` |
| **Support** | UI_UX_Designer | `ui_ux_designer.skill.md` |

---

## Workers

| # | Worker | Task | Status | Output |
|---|--------|------|--------|--------|
| 1 | worker-1-figma-prototype | Create interactive Figma prototype | PENDING | `designs/prototypes/` |
| 2 | worker-2-user-flows | Document complete user flows | PENDING | `designs/flows/` |
| 3 | worker-3-stakeholder-review | Conduct stakeholder review session | PENDING | Review feedback |

---

## Worker Instructions

### Worker 1: Figma Interactive Prototype

**Objective**: Create clickable prototype for user testing

**Deliverables**:
- Interactive Figma prototype
- Screen transitions and animations
- Clickable hotspots for all interactions
- Multiple user flow paths

**Prototype Features**:
| Feature | Implementation |
|---------|----------------|
| Navigation | Header/sidebar interactions |
| CRUD flows | Create, view, edit, delete |
| Forms | Input validation feedback |
| Modals | Overlay interactions |
| Responsive | Desktop + mobile variants |

**Output Location**: `{fe-repo}/designs/prototypes/`

**Quality Criteria**:
- [ ] All primary flows interactive
- [ ] Transitions smooth and realistic
- [ ] Mobile prototype functional
- [ ] Shareable prototype link created

---

### Worker 2: User Flow Documentation

**Objective**: Document all user flows with decision points

**Deliverables**:
```
designs/flows/
├── authentication-flow.md
├── crud-operations-flow.md
├── navigation-flow.md
├── error-handling-flow.md
└── onboarding-flow.md
```

**User Flows to Document**:
| Flow | Steps |
|------|-------|
| Authentication | Login -> Dashboard |
| Create Resource | Form -> Validation -> Success |
| View/Edit | List -> Detail -> Edit -> Save |
| Delete | Confirmation -> Delete -> Redirect |
| Error Handling | Error state -> Recovery options |

**Output Location**: `{fe-repo}/designs/flows/`

**Quality Criteria**:
- [ ] All critical flows documented
- [ ] Decision points identified
- [ ] Error states included
- [ ] Success/failure paths clear

---

### Worker 3: Stakeholder Review

**Objective**: Gather feedback from stakeholders

**Review Session Agenda**:
1. Present prototype overview
2. Walk through primary user flows
3. Gather feedback on:
   - Visual design
   - User experience
   - Missing features
   - Priority adjustments
4. Document action items

**Output**: Review feedback document

**Quality Criteria**:
- [ ] All key stakeholders participated
- [ ] Feedback documented
- [ ] Action items prioritized
- [ ] Approval for development obtained

---

## Stage Outputs

| Output | Description | Location |
|--------|-------------|----------|
| Figma prototype | Interactive clickable prototype | `designs/prototypes/` |
| User flows | Flow documentation | `designs/flows/` |
| Feedback | Stakeholder review notes | Meeting notes |

---

## Success Criteria

- [ ] All 3 workers completed
- [ ] Interactive prototype covers all primary flows
- [ ] User flows documented
- [ ] Stakeholder approval obtained
- [ ] Development ready to begin

---

## Dependencies

**Depends On**: Stage F1 (UI/UX Design)
**Blocks**: Stage F3 (React + Mock API)

---

## Estimated Duration

| Activity | Agentic | Manual |
|----------|---------|--------|
| Figma prototype | 45 min | 4 hours |
| User flows | 20 min | 2 hours |
| Stakeholder review | 15 min | 2 hours |
| **Total** | **1.5 hours** | **8 hours** |

---

**Navigation**: [<- Stage F1](./stage-f1-ui-ux-design.md) | [Main Plan](./main-plan.md) | [Stage F3 ->](./stage-f3-react-mock-api.md)
