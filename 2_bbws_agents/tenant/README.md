# Tenant Manager Agent

Manages tenant lifecycle for the BBWS Multi-Tenant WordPress Platform.

## Responsibilities

- Tenant database provisioning
- ECS service creation
- EFS access points
- ALB target groups
- Cognito User Pools
- DNS subdomain configuration

## Files

| File | Purpose |
|------|---------|
| `agent.md` | Agent definition and workflows |
| `agent_spec.md` | Detailed technical specification |
| `skills/` | Agent-specific skill definitions |

## Related Agents

- ECS Cluster Manager - Provides infrastructure
- Content Manager - Manages tenant content
- Backup Manager - Backs up tenant data
