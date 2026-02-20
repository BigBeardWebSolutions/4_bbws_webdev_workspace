# Stage 5: Local Integration Testing

**Stage**: 5
**Name**: Local Integration Testing
**Status**: PENDING
**Workers**: 4
**Dependencies**: Stage 3 (Frontend), Stage 4 (Backend)

---

## Objective

Validate complete user journeys locally before any AWS deployment. This stage ensures that all 5 persona flows work correctly with mocked services, establishing confidence before incurring cloud infrastructure costs.

---

## Workers

| Worker | Task | Test Coverage | Tools |
|--------|------|---------------|-------|
| worker-1-frontend-backend-integration | Frontend ↔ Backend API tests | All API calls | Cypress + SAM Local |
| worker-2-user-journey-tests | Complete user flows for all personas | 5 personas | Playwright |
| worker-3-agent-mock-validation | Agent response handling | SSE streaming, multi-agent | Jest + mock server |
| worker-4-local-e2e-suite | Full E2E test suite | Happy paths + error cases | Playwright |

---

## Test Scenarios by Persona

### Marketing User Journey
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login with mock JWT | Dashboard loads |
| 2 | Click "Create New Page" | Builder workspace opens |
| 3 | Enter prompt in chat | SSE stream shows agent thinking |
| 4 | AI generates preview | HTML preview renders |
| 5 | Provide feedback | Iterative refinement works |
| 6 | Check brand score | Validation report shows |
| 7 | Deploy to staging | Mock S3 upload succeeds |

### Designer Journey
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as Designer | Dashboard with design tools |
| 2 | Open Logo Creator | Logo panel loads |
| 3 | Generate logo | Mock SD XL response |
| 4 | Open Theme Selector | Theme panel loads |
| 5 | Apply theme | Preview updates |
| 6 | Save changes | DynamoDB write succeeds |

### Org Admin Journey
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as Admin | Admin dashboard loads |
| 2 | Navigate to Users | User list loads |
| 3 | Invite new user | Mock email triggered |
| 4 | Configure hierarchy | Org structure updates |
| 5 | View audit log | Activity log shows |

### DevOps Engineer Journey
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as DevOps | Monitoring dashboard |
| 2 | View metrics | Mock CloudWatch data |
| 3 | Check deployments | Deployment history shows |
| 4 | View logs | Log viewer works |

### White-Label Partner Journey
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as Partner | Partner dashboard loads |
| 2 | Configure branding | Logo/colors upload |
| 3 | Manage sub-tenants | Tenant list shows |
| 4 | View billing | Usage metrics display |

---

## Success Criteria

- [ ] All 5 persona journeys pass locally
- [ ] SSE streaming works end-to-end
- [ ] Error handling verified (network errors, validation failures)
- [ ] Performance baseline established (< 2s page load)
- [ ] No AWS credentials required to run tests
- [ ] CI pipeline can execute all tests
- [ ] Test reports generated automatically

---

## Approval Gate

**Gate 3**: Local Testing Complete
- **Approvers**: QA Lead, Tech Lead
- **Criteria**: All persona journeys pass, test coverage > 80%
- **Artifact**: Test reports, coverage reports, demo recording

---

## Test Commands

```bash
# Run all local integration tests
npm run test:integration

# Run specific persona journey
npm run test:journey:marketing
npm run test:journey:designer
npm run test:journey:admin
npm run test:journey:devops
npm run test:journey:partner

# Run E2E suite
npm run test:e2e:local

# Generate coverage report
npm run test:coverage
```

---

## Notes

- Tests must be idempotent (can run multiple times)
- Seed data should be reset before each test run
- Screenshot failures for debugging
- Record video for complex journeys
