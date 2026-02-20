# Worker Instructions: CloudWatch Monitoring Module

**Worker ID**: worker-6-cloudwatch-monitoring-module
**Stage**: Stage 2 - Infrastructure Terraform
**Project**: project-plan-2-access-management

---

## Task

Create Terraform module for CloudWatch monitoring including log groups, alarms, dashboards, and SNS topics for alerting.

---

## Inputs

**From Stage 1**:
- All worker outputs for service metrics
- Risk assessments for monitoring priorities

**Requirements**:
- Monitor failed transactions
- Monitor stuck transactions
- Monitor errors via SNS
- Enable dead letter queues

---

## Deliverables

Create Terraform module in `output.md`:

### 1. Module Structure

```
terraform/modules/cloudwatch-monitoring/
├── main.tf           # Log groups
├── alarms.tf         # Alarm definitions
├── dashboards.tf     # Dashboard JSON
├── sns.tf            # Alert topics
├── metrics.tf        # Custom metrics
├── variables.tf
└── outputs.tf
```

### 2. Log Groups (6 Services)

| Log Group | Retention |
|-----------|-----------|
| /aws/lambda/bbws-access-{env}-permission-service | 30 days |
| /aws/lambda/bbws-access-{env}-invitation-service | 30 days |
| /aws/lambda/bbws-access-{env}-team-service | 30 days |
| /aws/lambda/bbws-access-{env}-role-service | 30 days |
| /aws/lambda/bbws-access-{env}-authorizer | 30 days |
| /aws/lambda/bbws-access-{env}-audit-service | 90 days |

### 3. CloudWatch Alarms

| Alarm | Metric | Threshold | Action |
|-------|--------|-----------|--------|
| AuthorizerErrors | Errors | > 10/min | SNS Alert |
| AuthorizerLatency | Duration | > 100ms p95 | SNS Alert |
| InvitationFailures | Errors | > 5/min | SNS Alert |
| AuditArchiveFailures | Errors | > 1/hour | SNS Alert |
| DynamoDBThrottling | ThrottledRequests | > 0 | SNS Alert |
| LambdaConcurrency | ConcurrentExecutions | > 80% | SNS Warn |

### 4. SNS Topics

| Topic | Purpose | Subscribers |
|-------|---------|-------------|
| bbws-access-{env}-alerts-critical | Critical alerts | Email, PagerDuty |
| bbws-access-{env}-alerts-warning | Warning alerts | Email |

### 5. Dashboard

**Name**: `bbws-access-{env}-dashboard`

**Widgets**:
- Authorizer latency (line chart)
- Error rates by service (bar chart)
- Invitations sent/accepted (counter)
- Audit events per hour (area chart)
- DynamoDB consumed capacity (line chart)
- Active users (counter)

### 6. Metric Filters

Create metric filters for:
- Authorization failures (DENY responses)
- Permission denied errors
- Invitation email failures
- Audit archive errors

```hcl
resource "aws_cloudwatch_log_metric_filter" "auth_failures" {
  name           = "AuthorizationFailures"
  pattern        = "[timestamp, requestId, level=ERROR, message=\"*DENY*\"]"
  log_group_name = aws_cloudwatch_log_group.authorizer.name

  metric_transformation {
    name      = "AuthorizationFailures"
    namespace = "BBWS/AccessManagement"
    value     = "1"
  }
}
```

---

## Success Criteria

- [ ] Log groups for all 6 services
- [ ] Critical alarms configured
- [ ] SNS topics created
- [ ] Dashboard with key metrics
- [ ] Metric filters for errors
- [ ] Appropriate retention periods
- [ ] Environment parameterized
- [ ] Alarm actions configured

---

## Execution Steps

1. Read Stage 1 outputs for monitoring needs
2. Create log group definitions
3. Create SNS topics
4. Create alarm definitions
5. Create metric filters
6. Create dashboard JSON
7. Create variables and outputs
8. Validate Terraform
9. Create output.md
10. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
