# BBWS Documentation - Project Instructions

## Project Purpose

Technical documentation for the BBWS Multi-Tenant WordPress Hosting Platform including HLDs, LLDs, and training materials.

## Document Standards

### HLD Standards
- Use clear, unambiguous language
- Document architecture at system level
- Focus on component interactions and data flows
- Include AWS service selections and rationale
- Address non-functional requirements

### LLD Standards
- Provide detailed component specifications
- Include API contracts and interfaces
- Document database schemas
- Specify security implementations
- Include deployment procedures

### Training Standards
- Role-based training content
- Include practical exercises
- Provide knowledge quizzes
- Follow progressive learning path

## Document Naming Convention

| Type | Format | Example |
|------|--------|---------|
| HLD | `BBWS_[SystemName]_HLD.md` | `BBWS_ECS_WordPress_HLD.md` |
| LLD | `[Component]_LLD.md` | `Tenant_Management_LLD.md` |
| Runbook | `[System]_[Type]_Runbook.md` | `CPP_DR_Runbook.md` |
| Training | `[type]_[role].md` | `quiz_tenant_admin.md` |

## Key Systems

### ECS WordPress Platform
- Multi-tenant WordPress hosting
- ECS Fargate containers
- RDS MySQL (bridge model)
- EFS for content storage
- ALB with CloudFront

### Customer Portal (CPP)
- Public-facing customer portal
- Serverless Lambda architecture
- DynamoDB for data storage
- Cognito for authentication

### Admin Systems
- Admin portal for operations
- Admin app for mobile access

## Environments

| Environment | AWS Account | Region |
|-------------|-------------|--------|
| DEV | 536580886816 | af-south-1 |
| SIT | 815856636111 | af-south-1 |
| PROD | 093646564004 | af-south-1 |

## Related Repositories

- `2_bbws_ecs_terraform` - Infrastructure as Code
- `2_bbws_tenant_provisioner` - Tenant management CLI
- `2_bbws_wordpress_container` - WordPress Docker image
- `2_bbws_ecs_tests` - Integration tests
- `2_bbws_agents` - AI agents and utilities
- `2_bbws_ecs_operations` - Dashboards, alerts, runbooks

## Root Workflow Inheritance

This project inherits TBT mechanism and all workflow standards from the parent CLAUDE.md:

{{include:../CLAUDE.md}}
