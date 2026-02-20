# Worker Instructions: Monitoring & Alerts Workflows

**Worker ID**: worker-6-monitoring-alerts-workflow
**Stage**: Stage 6 - CI/CD Pipeline
**Project**: project-plan-2-access-management

---

## Task

Create GitHub Actions workflows for deploying CloudWatch monitoring, alarms, dashboards, and SNS alert notifications.

---

## Deliverables

Create `output.md` with:

### 1. setup-monitoring.yml
- Trigger: Manual or post-deployment
- Steps:
  1. Deploy CloudWatch alarms via Terraform
  2. Configure SNS topics
  3. Setup CloudWatch dashboards
  4. Configure log groups
  5. Verify alarm state
  6. Test alert notification

### 2. CloudWatch Alarms Configuration
| Alarm | Metric | Threshold | Action |
|-------|--------|-----------|--------|
| Lambda Errors | Errors | > 5/min | SNS Alert |
| Lambda Duration | Duration | > 10s | SNS Alert |
| Lambda Throttles | Throttles | > 1/min | SNS Alert |
| DynamoDB Throttles | ReadThrottle | > 1/min | SNS Alert |
| API Gateway 5XX | 5XXError | > 1% | SNS Alert |
| API Gateway 4XX | 4XXError | > 10% | SNS Warning |
| Authorizer Latency | Duration | > 100ms P95 | SNS Alert |

### 3. Dashboard Configuration
- Lambda performance dashboard
- API Gateway metrics
- DynamoDB operations
- Authorizer performance
- Error tracking

### 4. SNS Topics
- Critical alerts (PagerDuty/Slack)
- Warning alerts (Slack)
- Info notifications (Email)

### 5. Log Retention
| Log Group | Retention |
|-----------|-----------|
| Lambda logs | 30 days |
| API Gateway logs | 30 days |
| Audit logs | 7 years |

### 6. Alert Notification Integration
- Slack webhook integration
- PagerDuty integration (optional)
- Email notifications

---

## Monitoring Stack

```
CloudWatch Metrics
       ↓
CloudWatch Alarms
       ↓
SNS Topics
       ↓
┌──────┴──────┐
Slack    Email    PagerDuty
```

---

## Success Criteria

- [ ] All alarms deployed
- [ ] SNS topics configured
- [ ] Dashboards created
- [ ] Slack notifications working
- [ ] Log groups configured
- [ ] Alert thresholds verified

---

**Status**: PENDING
**Created**: 2026-01-24
