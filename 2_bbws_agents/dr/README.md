# DR Manager Agent

Manages disaster recovery operations for the BBWS Multi-Tenant WordPress Platform.

## Responsibilities

- DR readiness assessment
- Failover execution (af-south-1 to eu-west-1)
- Failback to primary region
- Route53 DNS switching
- DR testing and drills
- RTO/RPO compliance

## Files

| File | Purpose |
|------|---------|
| `agent.md` | Agent definition and workflows |
| `agent_spec.md` | Detailed technical specification |
| `skills/` | Agent-specific skill definitions |

## Related Agents

- Backup Manager - Provides backups for DR
- Monitoring Agent - Detects failures
- Cost Manager - DR cost estimation
