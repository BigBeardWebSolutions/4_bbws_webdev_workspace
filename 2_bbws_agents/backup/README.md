# Backup Manager Agent

Manages backup operations for the BBWS Multi-Tenant WordPress Platform.

## Responsibilities

- RDS snapshot creation
- EFS backup via AWS Backup
- Cross-region replication (af-south-1 to eu-west-1)
- Backup validation
- Point-in-time recovery
- Retention policy management

## Files

| File | Purpose |
|------|---------|
| `agent.md` | Agent definition and workflows |
| `agent_spec.md` | Detailed technical specification |
| `skills/` | Agent-specific skill definitions |

## Related Agents

- DR Manager - Uses backups for failover
- Monitoring Agent - Monitors backup status
- Cost Manager - Tracks backup costs
