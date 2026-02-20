# Disaster Recovery Runbook

## Overview

This runbook covers disaster recovery procedures for the BBWS Multi-Tenant WordPress Hosting Platform.

## DR Strategy

- **Type**: Multi-site Active/Passive
- **Primary Region**: af-south-1 (Cape Town)
- **DR Region**: eu-west-1 (Ireland)
- **RPO**: 1 hour
- **RTO**: 4 hours

## Prerequisites

- [ ] AWS CLI configured with appropriate credentials
- [ ] Access to both primary and DR regions
- [ ] Route 53 hosted zone access
- [ ] On-call team notified

## Failover Decision Matrix

| Scenario | Action |
|----------|--------|
| Primary region partial degradation | Monitor, no failover |
| Primary region complete outage | Initiate failover |
| RDS failure | Wait for RDS auto-recovery (15 min) |
| ECS cluster failure | Initiate failover |

## Failover Procedure

### Phase 1: Assessment (15 minutes)

1. **Verify Outage**
   ```bash
   # Check ECS cluster health
   aws ecs describe-clusters --clusters prod-cluster --region af-south-1

   # Check ALB health
   aws elbv2 describe-target-health --target-group-arn <TG_ARN> --region af-south-1
   ```

2. **Notify Stakeholders**
   - Send initial incident notification
   - Update status page

### Phase 2: Data Verification (30 minutes)

1. **Verify DynamoDB Replication**
   ```bash
   # Check global table status
   aws dynamodb describe-table --table-name bbws-tenants --region eu-west-1
   ```

2. **Verify S3 Cross-Region Replication**
   ```bash
   # Check replication status
   aws s3api get-bucket-replication --bucket bbws-assets --region af-south-1
   ```

### Phase 3: DNS Failover (15 minutes)

1. **Update Route 53**
   ```bash
   # Failover to DR region
   aws route53 change-resource-record-sets \
     --hosted-zone-id <ZONE_ID> \
     --change-batch file://failover-dns.json
   ```

2. **Verify DNS Propagation**
   ```bash
   dig wp.kimmyai.io
   ```

### Phase 4: Verification (30 minutes)

1. **Verify Tenant Access**
   - Test each tenant WordPress admin
   - Verify database connectivity
   - Test form submissions

2. **Update Status Page**
   - Confirm failover complete
   - Notify stakeholders

## Failback Procedure

### Prerequisites for Failback

- [ ] Primary region restored
- [ ] Data synchronized
- [ ] Business approval for failback

### Failback Steps

1. Verify primary region health
2. Synchronize any DR changes back to primary
3. Update Route 53 to primary
4. Verify tenant access
5. Monitor for 24 hours

## Emergency Contacts

| Role | Contact |
|------|---------|
| On-call Engineer | See PagerDuty |
| Platform Lead | TBD |
| AWS Support | Premium Support Portal |

## Post-Incident

- [ ] Complete incident report
- [ ] Update runbook with lessons learned
- [ ] Schedule post-mortem
