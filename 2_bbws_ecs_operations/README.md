# BBWS ECS Operations

Operations configurations for the BBWS Multi-Tenant WordPress Hosting Platform.

## Overview

This repository contains:
- CloudWatch dashboards configurations
- CloudWatch alarm definitions
- Disaster Recovery (DR) runbooks
- Monitoring configurations

## Directory Structure

```
dashboards/
├── ecs-cluster.json          # ECS cluster metrics dashboard
├── tenant-health.json        # Per-tenant health dashboard
└── cost-monitoring.json      # Cost and resource utilization

alerts/
├── ecs-alerts.tf             # ECS service alerts (Terraform)
├── rds-alerts.tf             # RDS alerts
├── alb-alerts.tf             # ALB alerts
└── sns-topics.tf             # SNS notification topics

runbooks/
├── DR_Runbook.md             # Disaster Recovery procedures
├── Failover_Runbook.md       # Regional failover procedures
├── Incident_Response.md      # Incident response procedures
└── Scaling_Runbook.md        # Manual scaling procedures

monitoring/
├── prometheus/               # Prometheus configurations (future)
├── grafana/                  # Grafana dashboards (future)
└── cloudwatch-agent/         # CloudWatch agent configs
```

## Dashboards

### ECS Cluster Dashboard

Monitors:
- CPU and memory utilization
- Running tasks count
- Service health
- Container insights

### Tenant Health Dashboard

Per-tenant metrics:
- Request latency
- Error rates
- Database connections
- EFS throughput

### Cost Monitoring

Resource costs:
- ECS compute costs
- RDS costs
- EFS storage costs
- Data transfer costs

## Alerts

### Critical Alerts

| Alert | Threshold | Action |
|-------|-----------|--------|
| ECS Service Unhealthy | Running < Desired | Page on-call |
| RDS High CPU | > 80% for 5min | Email + Slack |
| ALB 5xx Errors | > 10/min | Page on-call |
| EFS High Latency | > 200ms | Email |

### Warning Alerts

| Alert | Threshold | Action |
|-------|-----------|--------|
| ECS Low Memory | > 70% | Email |
| RDS Storage Low | < 20% free | Email |
| ALB Slow Response | p95 > 2s | Slack |

## Runbooks

### Disaster Recovery

- **RPO**: 1 hour (DynamoDB backup interval)
- **RTO**: 4 hours (multi-region failover)
- **Strategy**: Active-Passive with cross-region replication

### Regions

- **Primary**: af-south-1 (Cape Town)
- **DR**: eu-west-1 (Ireland)

## Environments

| Environment | AWS Account | Region |
|-------------|-------------|--------|
| DEV | 536580886816 | af-south-1 |
| SIT | 815856636111 | af-south-1 |
| PROD | 093646564004 | af-south-1 + eu-west-1 |

## Deployment

```bash
# Deploy dashboards
aws cloudwatch put-dashboard \
  --dashboard-name "bbws-ecs-cluster" \
  --dashboard-body file://dashboards/ecs-cluster.json

# Deploy alerts (via Terraform)
cd alerts
terraform init
terraform apply -var-file=../../../2_bbws_ecs_terraform/tfvars/dev.tfvars
```

## Related Repositories

- `2_bbws_ecs_terraform` - Infrastructure as Code
- `2_bbws_tenant_provisioner` - Tenant management CLI
- `2_bbws_ecs_tests` - Integration tests
- `2_bbws_agent_utils` - Agent utility scripts

## License

Proprietary - Big Beard Web Solutions
