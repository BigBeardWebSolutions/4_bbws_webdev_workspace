# Worker Instructions: Invitation API Routes

**Worker ID**: worker-2-invitation-api-routes
**Stage**: Stage 4 - API Gateway Integration
**Project**: project-plan-2-access-management

---

## Task

Configure API Gateway routes for the Invitation Service (8 endpoints) including authenticated and public routes.

---

## Endpoints (8)

### Authenticated (5)
| # | Method | Path | Lambda |
|---|--------|------|--------|
| 1 | POST | /v1/orgs/{orgId}/invitations | create_invitation |
| 2 | GET | /v1/orgs/{orgId}/invitations | list_invitations |
| 3 | GET | /v1/orgs/{orgId}/invitations/{invitationId} | get_invitation |
| 4 | DELETE | /v1/orgs/{orgId}/invitations/{invitationId} | cancel_invitation |
| 5 | POST | /v1/orgs/{orgId}/invitations/{invitationId}/resend | resend_invitation |

### Public (3) - NO AUTHORIZER
| # | Method | Path | Lambda |
|---|--------|------|--------|
| 6 | GET | /v1/invitations/{token} | get_invitation_public |
| 7 | POST | /v1/invitations/accept | accept_invitation |
| 8 | POST | /v1/invitations/{token}/decline | decline_invitation |

---

## Deliverables

Create `output.md` with:
1. OpenAPI 3.0 specification
2. Terraform route configuration
3. Public routes WITHOUT authorizer
4. Request/response schemas
5. CORS configuration

---

## Success Criteria

- [ ] All 8 routes configured
- [ ] 5 routes with authorizer
- [ ] 3 public routes without authorizer
- [ ] CORS enabled
- [ ] OpenAPI spec complete

---

**Status**: PENDING
**Created**: 2026-01-23
