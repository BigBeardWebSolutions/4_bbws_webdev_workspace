# Project Plan 2: BBWS Customer Portal (Private)

**Project Status**: PENDING (Awaiting User Approval)
**Created**: 2026-01-18
**BRS Reference**: 2.2_BRS_Customer_Portal_Private.md
**HLD Reference**: 2.2_BBWS_Customer_Portal_Private_HLD.md

---

## Executive Summary

This project plan covers the implementation of the BBWS Customer Portal (Private) - the authenticated customer dashboard for managing WordPress sites, subscriptions, billing, and support tickets.

### Project Scope

| Metric | Count |
|--------|-------|
| Total Screens | 45 |
| Total Microservices | 15 |
| Total Lambda Functions | 66 |
| Total LLDs Required | 10 |
| Total Runbooks Required | 12 |
| Total Repositories | 21 |
| Estimated Stages | 8 |
| Estimated Workers | 55+ |

---

## Project Stages Overview

| Stage | Name | Workers | Dependencies |
|-------|------|---------|--------------|
| 1 | Requirements Analysis & Validation | 4 | None |
| 2 | LLD Document Creation | 10 | Stage 1 |
| 3 | Infrastructure Setup | 6 | Stage 2 |
| 4 | Frontend Development | 8 | Stage 3 |
| 5 | Microservices Implementation | 15 | Stage 3 |
| 6 | CI/CD Pipeline | 5 | Stage 4, 5 |
| 7 | Integration Testing | 4 | Stage 5, 6 |
| 8 | Documentation & Runbooks | 12 | Stage 5 |

---

## Stage 1: Requirements Analysis & Validation

**Goal**: Validate BRS requirements, analyse HLD, confirm naming conventions, and prepare for LLD creation.

### Workers

| Worker | Task | Inputs | Outputs |
|--------|------|--------|---------|
| 1.1 | BRS Analysis | BRS 2.2 | requirements_summary.md |
| 1.2 | HLD Architecture Review | HLD 2.2 | architecture_analysis.md |
| 1.3 | API Contract Validation | HLD Section 6 | api_contracts.md |
| 1.4 | DynamoDB Schema Validation | HLD Section 8 | schema_validation.md |

### Stage 1 Deliverables
- [ ] Validated requirements document
- [ ] Architecture analysis report
- [ ] API contract definitions (OpenAPI stubs)
- [ ] DynamoDB schema validation report

---

## Stage 2: LLD Document Creation

**Goal**: Create 10 detailed Low-Level Design documents following the LLD template.

### Workers (10 LLDs from HLD Section 12.1)

| Worker | LLD Name | Scope |
|--------|----------|-------|
| 2.1 | CP_Frontend_Architecture_LLD | React SPA, protected routes, component library |
| 2.2 | CP_Auth_Service_LLD | JWT, MFA, session management |
| 2.3 | CP_Organisation_Service_LLD | Organisation CRUD, user management |
| 2.4 | CP_Tenant_Service_LLD | Tenant lifecycle, user invitations |
| 2.5 | CP_Site_Service_LLD | Site provisioning, environments, backups |
| 2.6 | CP_Migration_Service_LLD | WordPress migrator (Mode A/B) |
| 2.7 | CP_Billing_Service_LLD | PayFast integration, subscriptions |
| 2.8 | CP_Ticket_Service_LLD | Support tickets, follow-ups |
| 2.9 | CP_Notification_Service_LLD | Notifications, email alerts |
| 2.10 | CP_Cognito_Integration_LLD | Cognito configuration, user pools |

### Stage 2 Deliverables
- [ ] 10 complete LLD documents
- [ ] OpenAPI specifications for each service
- [ ] Component diagrams
- [ ] Sequence diagrams for key flows

---

## Stage 3: Infrastructure Setup

**Goal**: Create Terraform modules and infrastructure for the Customer Portal.

### Workers

| Worker | Task | Outputs |
|--------|------|---------|
| 3.1 | Cognito User Pool Setup | Terraform module for customer pool |
| 3.2 | API Gateway Configuration | API Gateway with Lambda authorizer |
| 3.3 | DynamoDB Tables & GSIs | Single-table design implementation |
| 3.4 | S3 + CloudFront Setup | SPA hosting infrastructure |
| 3.5 | SQS Queues Setup | Async processing queues |
| 3.6 | SES Configuration | Email notifications setup |

### Stage 3 Deliverables
- [ ] Terraform modules for all infrastructure
- [ ] Environment configurations (dev, sit, prod)
- [ ] Infrastructure validation scripts

---

## Stage 4: Frontend Development

**Goal**: Build the React SPA with all 45 screens.

### Workers (by Screen Category)

| Worker | Category | Screens | Count |
|--------|----------|---------|-------|
| 4.1 | Dashboard & Account | CP-001 to CP-003 | 3 |
| 4.2 | Organisation | CP-010 to CP-014 | 5 |
| 4.3 | Tenant | CP-020 to CP-024 | 5 |
| 4.4 | Sites | CP-030 to CP-039 | 10 |
| 4.5 | DNS Sites | CP-040 to CP-043 | 4 |
| 4.6 | Migrations | CP-050 to CP-055 | 6 |
| 4.7 | Billing | CP-060 to CP-066 | 7 |
| 4.8 | Support | CP-070 to CP-074 | 5 |

### Stage 4 Deliverables
- [ ] Complete React SPA with 45 screens
- [ ] Reusable component library
- [ ] Unit tests (80%+ coverage)
- [ ] Storybook documentation

---

## Stage 5: Microservices Implementation

**Goal**: Implement 15 microservices with 66 Lambda functions.

### Workers (by Service)

| Worker | Service | Repo | Functions |
|--------|---------|------|-----------|
| 5.1 | Portal Auth Service | 2_2_bbws_portal_svc_auth | 5 |
| 5.2 | Organisation Service | 2_2_bbws_portal_svc_organisation | 5 |
| 5.3 | Tenant Service | 2_2_bbws_portal_svc_tenant | 6 |
| 5.4 | Site Service | 2_2_bbws_portal_svc_site | 12 |
| 5.5 | Migration Service | 2_2_bbws_portal_svc_migration | 6 |
| 5.6 | Billing Service | 2_2_bbws_portal_svc_billing | 7 |
| 5.7 | Ticket Service | 2_2_bbws_portal_svc_ticket | 5 |
| 5.8 | Notification Service | 2_2_bbws_portal_svc_notification | 2 |
| 5.9 | Auth Public Service | 2_2_bbws_auth_public_lambda | 5 |
| 5.10 | Marketing Service | 2_2_bbws_marketing_lambda | 1 |
| 5.11 | Contact Service | 2_2_bbws_contact_lambda | 1 |
| 5.12 | Invitation Service | 2_2_bbws_invitation_lambda | 3 |
| 5.13 | Cart Service | 2_2_bbws_cart_lambda | 4 |
| 5.14 | Payment Service | 2_2_bbws_payment_lambda | 3 |
| 5.15 | Newsletter Service | 2_2_bbws_newsletter_lambda | 1 |

### Stage 5 Deliverables
- [ ] 15 microservices fully implemented
- [ ] 66 Lambda functions with tests
- [ ] Unit tests (80%+ coverage)
- [ ] Integration tests

---

## Stage 6: CI/CD Pipeline

**Goal**: Create GitHub Actions workflows for all repositories.

### Workers

| Worker | Task | Outputs |
|--------|------|---------|
| 6.1 | Frontend CI/CD | Build, test, deploy React SPA |
| 6.2 | Backend CI/CD Template | Reusable workflow for Lambdas |
| 6.3 | Infrastructure CI/CD | Terraform plan/apply workflows |
| 6.4 | Environment Promotion | DEV → SIT → PROD workflows |
| 6.5 | Rollback Workflows | Rollback procedures |

### Stage 6 Deliverables
- [ ] CI/CD workflows for all 21 repositories
- [ ] Environment promotion workflows
- [ ] Rollback procedures

---

## Stage 7: Integration Testing

**Goal**: End-to-end testing of the complete Customer Portal.

### Workers

| Worker | Task | Scope |
|--------|------|-------|
| 7.1 | Authentication Flows | Registration, login, MFA, password reset |
| 7.2 | Site Management Flows | Create, update, delete, backup, restore |
| 7.3 | Billing Flows | Subscription, payment, invoice |
| 7.4 | E2E Test Automation | Playwright/Cypress test suite |

### Stage 7 Deliverables
- [ ] E2E test suite
- [ ] Test reports
- [ ] Performance benchmarks

---

## Stage 8: Documentation & Runbooks

**Goal**: Create 12 operational runbooks for the Customer Portal.

### Workers (12 Runbooks from HLD Section 12.2)

| Worker | Runbook | Purpose |
|--------|---------|---------|
| 8.1 | CP_Ops_Deployment_Runbook | Deployment procedures |
| 8.2 | CP_Ops_Monitoring_Runbook | API monitoring |
| 8.3 | CP_Ops_Incident_Response_Runbook | Outage response |
| 8.4 | CP_Ops_User_Management_Runbook | User issues |
| 8.5 | CP_Ops_Site_Provisioning_Runbook | Site creation |
| 8.6 | CP_Ops_Migration_Troubleshooting_Runbook | Migration issues |
| 8.7 | CP_Ops_Backup_Restore_Runbook | Backup/restore |
| 8.8 | CP_Ops_Environment_Promotion_Runbook | Env promotion |
| 8.9 | CP_Ops_Billing_Issues_Runbook | Payment issues |
| 8.10 | CP_Ops_DNS_Configuration_Runbook | DNS setup |
| 8.11 | CP_Ops_WordPress_Health_Runbook | WP health |
| 8.12 | CP_Ops_Database_Runbook | RDS maintenance |

### Stage 8 Deliverables
- [ ] 12 operational runbooks
- [ ] Knowledge base articles
- [ ] Training materials

---

## Implementation Priority

Based on the BRS user stories and HLD, the implementation should follow this priority:

### P0 (Critical Path)
1. Authentication (Cognito + Auth Service)
2. Tenant Service
3. Site Service (core CRUD)
4. Frontend scaffold with auth

### P1 (High Priority)
5. Organisation Service
6. Billing Service (PayFast)
7. Ticket Service
8. Frontend screens (Dashboard, Sites, Billing)

### P2 (Medium Priority)
9. Migration Service
10. Notification Service
11. Backup/Restore features
12. Remaining frontend screens

---

## Environment Configuration

| Environment | Account | Region | API Base URL |
|-------------|---------|--------|--------------|
| DEV | 536580886816 | eu-west-1 | dev.portal-api.kimmyai.io |
| SIT | 815856636111 | af-south-1 | sit.portal-api.kimmyai.io |
| PROD | 093646564004 | af-south-1 | portal-api.kimmyai.io |

---

## Repository Naming Convention

All repositories follow the pattern: `2_2_bbws_<service>_<type>`

- `2_2` = Phase 2, Application 2 (Customer Portal Private)
- `bbws` = Project prefix
- `<service>` = Service name (e.g., portal_svc_auth)
- `<type>` = lambda, cron, frontend, etc.

---

## Next Steps

1. User approval of this project plan
2. Begin Stage 1: Requirements Analysis
3. Create LLDs (Stage 2) in parallel with validation
4. Infrastructure setup (Stage 3)
5. Begin frontend and backend development (Stage 4, 5)

---

**Project Manager**: Agentic Project Manager
**Created**: 2026-01-18
**Last Updated**: 2026-01-18
