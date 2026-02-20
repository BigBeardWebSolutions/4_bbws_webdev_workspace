# ECS Cluster Manager Agent

Manages AWS ECS Fargate cluster infrastructure for the BBWS Multi-Tenant WordPress Platform.

## Responsibilities

- VPC, subnets, security groups
- ECS cluster and IAM roles
- RDS MySQL database
- EFS file system
- ALB and CloudFront
- Route53 DNS delegation
- ACM certificates

## Files

| File | Purpose |
|------|---------|
| `agent.md` | Agent definition and workflows |
| `agent_spec.md` | Detailed technical specification |
| `skills/` | Agent-specific skill definitions |

## Related Agents

- Tenant Manager - Uses cluster for tenant provisioning
- Backup Manager - Backs up cluster resources
- Monitoring Agent - Monitors cluster health
