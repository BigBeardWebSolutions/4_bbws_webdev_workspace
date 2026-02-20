# Super Admin Knowledge Check Quiz

**Total Questions**: 25
**Passing Score**: 80% (20/25)
**Time Limit**: 2 hours
**Format**: Multiple choice + Practical demonstrations

---

## Section A: Infrastructure Knowledge (8 questions)

### Question 1: Environment Validation
**Which AWS CLI command should you run FIRST before any cluster operation?**

A) `terraform init`
B) `aws sts get-caller-identity`
C) `aws ecs list-clusters`
D) `terraform plan`

**Correct Answer**: B

**Explanation**: Always validate you're in the correct AWS account before operations to prevent accidental deployments to wrong environments.

---

### Question 2: Account Mapping
**Match the AWS Account ID to the correct environment:**
- 536580886816
- 815856636111
- 093646564004

A) DEV, SIT, PROD
B) PROD, DEV, SIT
C) SIT, PROD, DEV
D) DEV, PROD, SIT

**Correct Answer**: A

**Explanation**: DEV=536580886816, SIT=815856636111, PROD=093646564004

---

### Question 3: Practical - ECS Cluster Health
**DEMONSTRATE: Run the command to check ECS cluster status in SIT. Provide screenshot.**

```bash
AWS_PROFILE=Tebogo-sit aws ecs describe-clusters \
  --clusters sit-cluster \
  --query 'clusters[0].status' \
  --region eu-west-1
```

**Expected Output**: "ACTIVE"

---

### Question 4: RDS Instance Sizing
**What is the correct RDS instance size for DEV environment?**

A) db.r5.large
B) db.t3.small
C) db.t3.micro
D) db.m5.large

**Correct Answer**: C

**Explanation**: DEV uses minimal sizing (db.t3.micro) for cost optimization.

---

### Question 5: Security Group Rule
**Which port must ECS tasks be allowed to access RDS?**

A) 80
B) 443
C) 3306
D) 2049

**Correct Answer**: C

**Explanation**: 3306 is the MySQL port used by RDS.

---

### Question 6: EFS Port
**Which port is used for EFS (NFS) connections?**

A) 3306
B) 443
C) 2049
D) 22

**Correct Answer**: C

**Explanation**: NFS uses port 2049.

---

### Question 7: Practical - Terraform State
**DEMONSTRATE: Run terraform output to retrieve the ALB DNS name. Provide screenshot.**

```bash
terraform output alb_dns_name
```

---

### Question 8: DynamoDB Capacity Mode
**Per BBWS standards, what capacity mode must all DynamoDB tables use?**

A) Provisioned with auto-scaling
B) Provisioned (fixed)
C) On-demand
D) Reserved capacity

**Correct Answer**: C

**Explanation**: Per CLAUDE.md, DynamoDB table capacity mode must always be "on-demand".

---

## Section B: Security and Compliance (5 questions)

### Question 9: Encryption Verification
**DEMONSTRATE: Verify RDS storage encryption is enabled. Provide screenshot.**

```bash
AWS_PROFILE=Tebogo-sit aws rds describe-db-instances \
  --db-instance-identifier sit-mysql \
  --query 'DBInstances[0].StorageEncrypted' \
  --region eu-west-1
```

**Expected Output**: true

---

### Question 10: Secrets Management
**Where should database credentials be stored?**

A) Environment variables in task definition
B) AWS Secrets Manager
C) Parameter Store
D) In wp-config.php directly

**Correct Answer**: B

**Explanation**: Credentials should be stored in Secrets Manager and referenced by ECS tasks.

---

### Question 11: S3 Bucket Policy
**Per BBWS standards, what public access setting must all S3 buckets have?**

A) Public read access for static content
B) Public access blocked
C) Public for DEV, blocked for PROD
D) Custom bucket policy

**Correct Answer**: B

**Explanation**: Per CLAUDE.md, "all buckets in all environments must never have public access."

---

### Question 12: PROD Read-Only
**What type of access should PROD environment allow according to BBWS standards?**

A) Full administrative access
B) Read-write with approval
C) Read-only
D) No access

**Correct Answer**: C

**Explanation**: Per CLAUDE.md, "PROD environment should allow read-only."

---

### Question 13: Security Group Audit
**DEMONSTRATE: List all security groups in the VPC. Provide screenshot.**

```bash
AWS_PROFILE=Tebogo-sit aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=vpc-xxx" \
  --query 'SecurityGroups[*].[GroupId,GroupName]' \
  --output table \
  --region eu-west-1
```

---

## Section C: Performance and Monitoring (4 questions)

### Question 14: CPU Utilization Threshold
**At what CPU utilization should an alert be triggered for ECS tasks?**

A) >50%
B) >70%
C) >80%
D) >90%

**Correct Answer**: C

**Explanation**: Alert threshold is typically set at 80% to allow time for response.

---

### Question 15: Practical - CloudWatch Metrics
**DEMONSTRATE: Get ECS CPU utilization for the last hour. Provide screenshot.**

```bash
AWS_PROFILE=Tebogo-sit aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ClusterName,Value=sit-cluster \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Average \
  --region eu-west-1
```

---

### Question 16: Autoscaling Trigger
**What metric is typically used to trigger ECS service autoscaling?**

A) Memory only
B) CPU only
C) Request count
D) CPU or Memory

**Correct Answer**: D

**Explanation**: ECS autoscaling can be triggered by either CPU or Memory utilization.

---

### Question 17: EFS Burst Credits
**What happens when EFS burst credits are exhausted?**

A) File system becomes read-only
B) Throughput is reduced to baseline
C) File system becomes unavailable
D) AWS automatically provisions more credits

**Correct Answer**: B

**Explanation**: When burst credits are exhausted, EFS throughput drops to the baseline rate.

---

## Section D: Disaster Recovery (4 questions)

### Question 18: DR Model
**What DR model does BBWS use for the multi-tenant platform?**

A) Backup and restore
B) Pilot light
C) Warm standby
D) Multi-site active-active

**Correct Answer**: D

**Explanation**: Per CLAUDE.md, BBWS uses "multisite active/active DR" strategy.

---

### Question 19: Primary and DR Regions
**What are the primary and DR regions for PROD?**

A) eu-west-1 (primary), af-south-1 (DR)
B) af-south-1 (primary), eu-west-1 (DR)
C) us-east-1 (primary), eu-west-1 (DR)
D) eu-west-1 (primary), us-east-1 (DR)

**Correct Answer**: B

**Explanation**: Per CLAUDE.md, "primary region for prod is af-south-1 and failover region is eu-west-1."

---

### Question 20: Replication
**Which AWS service enables cross-region replication for DynamoDB?**

A) AWS DataSync
B) AWS Database Migration Service
C) DynamoDB Global Tables
D) S3 Cross-Region Replication

**Correct Answer**: C

**Explanation**: DynamoDB Global Tables enables multi-region, multi-active database replication.

---

### Question 21: DR Test Frequency
**How often should full DR drills be conducted for PROD?**

A) Monthly
B) Quarterly
C) Annually
D) On every deployment

**Correct Answer**: C

**Explanation**: Full DR drills for PROD are conducted annually to minimize disruption.

---

## Section E: Cost Management (4 questions)

### Question 22: Cost Allocation Tag
**What tag should be applied to all tenant-specific resources for cost tracking?**

A) environment
B) project
C) tenant_id
D) cost_center

**Correct Answer**: C

**Explanation**: The tenant_id tag enables per-tenant cost tracking and chargeback.

---

### Question 23: Practical - Cost Report
**DEMONSTRATE: Generate a cost report grouped by tenant_id for the last 30 days. Provide screenshot.**

```bash
AWS_PROFILE=Tebogo-sit aws ce get-cost-and-usage \
  --time-period Start=$(date -v-30d +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=TAG,Key=tenant_id \
  --region us-east-1
```

---

### Question 24: Budget Alert Threshold
**At what percentage should the first budget alert be triggered?**

A) 50%
B) 70%
C) 80%
D) 100%

**Correct Answer**: C

**Explanation**: First alert at 80% gives time to take action before budget is exceeded.

---

### Question 25: Practical - Create Budget
**DEMONSTRATE: List all existing budgets for the account. Provide screenshot.**

```bash
AWS_PROFILE=Tebogo-sit aws budgets describe-budgets \
  --account-id 815856636111 \
  --query 'Budgets[*].[BudgetName,BudgetLimit.Amount,CalculatedSpend.ActualSpend.Amount]' \
  --output table
```

---

## Quiz Submission Requirements

### Practical Demonstration Evidence
Submit screenshots for the following questions:
- [ ] Question 3: ECS Cluster Health
- [ ] Question 7: Terraform Output
- [ ] Question 9: RDS Encryption
- [ ] Question 13: Security Groups
- [ ] Question 15: CloudWatch Metrics
- [ ] Question 23: Cost Report
- [ ] Question 25: Budgets List

### Scoring
| Section | Questions | Points |
|---------|-----------|--------|
| Infrastructure | 8 | 32 |
| Security | 5 | 20 |
| Performance | 4 | 16 |
| Disaster Recovery | 4 | 16 |
| Cost Management | 4 | 16 |
| **Total** | **25** | **100** |

### Passing Criteria
- Minimum 80% overall (20/25 questions)
- All practical demonstrations must have valid screenshots
- No section can have less than 50% correct

---

## Answer Key

| Q# | Answer | Q# | Answer | Q# | Answer |
|----|--------|----|--------|----|--------|
| 1 | B | 10 | B | 19 | B |
| 2 | A | 11 | B | 20 | C |
| 3 | Demo | 12 | C | 21 | C |
| 4 | C | 13 | Demo | 22 | C |
| 5 | C | 14 | C | 23 | Demo |
| 6 | C | 15 | Demo | 24 | C |
| 7 | Demo | 16 | D | 25 | Demo |
| 8 | C | 17 | B | | |
| 9 | Demo | 18 | D | | |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-16 | Initial quiz |
