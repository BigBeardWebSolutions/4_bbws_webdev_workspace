# BBWS ECS Operations - Project Instructions

## Project Purpose

Operations configurations for the BBWS Multi-Tenant WordPress Hosting Platform including dashboards, alerts, DR runbooks, and monitoring.

## Critical Safety Rules

- **ALWAYS** test alert configurations in DEV first
- **NEVER** modify PROD alerts without approval
- **FOLLOW** DR runbooks exactly during incidents
- **DOCUMENT** all operational changes in runbooks

## Environments

| Environment | AWS Account | Region | DR Region |
|-------------|-------------|--------|-----------|
| DEV | 536580886816 | af-south-1 | N/A |
| SIT | 815856636111 | af-south-1 | N/A |
| PROD | 093646564004 | af-south-1 | eu-west-1 |

## DR Strategy

- **Type**: Multi-site Active/Passive
- **Primary**: af-south-1 (Cape Town)
- **DR**: eu-west-1 (Ireland)
- **RPO**: 1 hour (hourly DynamoDB backups)
- **RTO**: 4 hours

## Key Components

### Dashboards

| Dashboard | Purpose |
|-----------|---------|
| `ecs-cluster.json` | ECS cluster health and metrics |
| `tenant-health.json` | Per-tenant health monitoring |
| `cost-monitoring.json` | Cost and utilization tracking |

### Alert Categories

| Category | Priority | Response |
|----------|----------|----------|
| Critical | P1 | Page on-call immediately |
| Warning | P2 | Email + Slack within 30min |
| Info | P3 | Review next business day |

### Runbook Types

| Runbook | When to Use |
|---------|-------------|
| DR_Runbook.md | Region failure, DR activation |
| Failover_Runbook.md | Planned failover, maintenance |
| Incident_Response.md | Service degradation, outages |
| Scaling_Runbook.md | Manual scaling operations |

## Related Repositories

- `2_bbws_ecs_terraform` - Infrastructure as Code
- `2_bbws_tenant_provisioner` - Tenant management CLI
- `2_bbws_ecs_tests` - Integration tests
- `2_bbws_agents` - AI agents and utilities

## Root Workflow Inheritance

This project inherits TBT mechanism and all workflow standards from the parent CLAUDE.md:

{{include:../CLAUDE.md}}
