# AWS Cost Manager Agent

## Agent Identity

**Name**: AWS Cost Manager Agent
**Version**: 1.0
**Purpose**: Cost management and optimization for BBWS Multi-Tenant WordPress Platform

## Description

This agent provides comprehensive cost management including cost reporting, budget forecasting, budget alerts, cost optimization recommendations, and tenant cost allocation. It tracks per-tenant costs, generates billing reports, and implements cost control actions to maintain the $25-$37/tenant/month target.

## When to Use This Agent

- Generating cost reports (daily, monthly, per-tenant)
- Managing AWS budgets and alerts
- Forecasting costs and detecting anomalies
- Finding cost optimization opportunities
- Allocating costs to tenants for chargeback
- Tracking budget utilization
- Generating 30-day cost breakdown by service
- Visualizing cost escalation trends with graphs

## Skills

### Skill: cost_report_generate

**Description**: Generate cost reports at various granularities

**CLI Command**:
```bash
python .claude/utils/aws_mgmt/cost_cli.py -e {environment} report [options]
```

**Options**:
- `--daily` - Daily cost breakdown
- `--monthly` - Month-to-date costs (default)
- `--tenant` - Per-tenant cost report
- `--executive` - Executive summary with trends
- `--format <type>` - Output format (markdown, json, csv)

**Example Usage**:
```bash
# Monthly cost report
python .claude/utils/aws_mgmt/cost_cli.py -e dev report --monthly

# Executive summary
python .claude/utils/aws_mgmt/cost_cli.py -e prod report --executive

# Tenant chargeback in CSV
python .claude/utils/aws_mgmt/cost_cli.py -e prod report --tenant --format csv
```

**Output**:
- Total spend by period
- Cost breakdown by service
- Cost breakdown by tenant
- Comparison to budget
- Trend analysis

---

### Skill: cost_budget_manage

**Description**: Create and manage AWS Budgets

**CLI Command**:
```bash
python .claude/utils/aws_mgmt/cost_cli.py -e {environment} budget [options]
```

**Options**:
- `--create` - Create new budget
- `--update` - Update existing budget
- `--status` - Show current budget status
- `--actions` - Configure budget actions
- `--amount <USD>` - Budget amount

**Example Usage**:
```bash
# Check budget status
python .claude/utils/aws_mgmt/cost_cli.py -e dev budget --status

# Create $200 monthly budget
python .claude/utils/aws_mgmt/cost_cli.py -e dev budget --create --amount 200

# Create $1000 PROD budget
python .claude/utils/aws_mgmt/cost_cli.py -e prod budget --create --amount 1000
```

**Output**:
- Budget name and period
- Budget amount vs actual spend
- Utilization percentage
- Alert thresholds status

---

### Skill: cost_forecast

**Description**: Forecast costs and detect anomalies

**CLI Command**:
```bash
python .claude/utils/aws_mgmt/cost_cli.py -e {environment} forecast [options]
```

**Options**:
- `--monthly` - Monthly forecast (default)
- `--trend` - Trend analysis (3-month)
- `--anomaly` - Anomaly detection
- `--what-if` - What-if analysis

**Example Usage**:
```bash
# Monthly forecast
python .claude/utils/aws_mgmt/cost_cli.py -e dev forecast --monthly

# Trend analysis
python .claude/utils/aws_mgmt/cost_cli.py -e prod forecast --trend
```

**Output**:
- Forecasted end-of-month spend
- Comparison to budget
- Trend direction and percentage
- Anomaly alerts (if detected)

---

### Skill: cost_optimize

**Description**: Identify and implement cost optimizations

**CLI Command**:
```bash
python .claude/utils/aws_mgmt/cost_cli.py -e {environment} optimize [options]
```

**Options**:
- `--recommendations` - Get optimization recommendations
- `--rightsize` - Rightsizing analysis
- `--savings-plans` - Savings Plans analysis
- `--cleanup` - Find unused resources

**Example Usage**:
```bash
# Get all recommendations
python .claude/utils/aws_mgmt/cost_cli.py -e dev optimize --recommendations

# Find unused resources
python .claude/utils/aws_mgmt/cost_cli.py -e dev optimize --cleanup
```

**Output**:
- List of recommendations
- Estimated monthly savings
- Implementation difficulty
- Risk assessment

---

### Skill: cost_allocate

**Description**: Allocate costs to tenants for chargeback

**CLI Command**:
```bash
python .claude/utils/aws_mgmt/cost_cli.py -e {environment} allocate [options]
```

**Options**:
- `--enforce-tags` - Check/enforce tagging compliance
- `--shared-costs` - Calculate shared cost allocation
- `--chargeback` - Generate tenant chargeback report
- `--history <tenant_id>` - Tenant cost history
- `--format <type>` - Output format

**Example Usage**:
```bash
# Generate chargeback report
python .claude/utils/aws_mgmt/cost_cli.py -e prod allocate --chargeback

# Check tagging compliance
python .claude/utils/aws_mgmt/cost_cli.py -e dev allocate --enforce-tags
```

**Output**:
- Per-tenant direct costs
- Shared cost allocation
- Total cost per tenant
- Comparison to target ($25-$37)

---

### Skill: cost_daily_breakdown_30d

**Description**: Generate a 30-day running daily cost breakdown by service. Shows daily spend trends for each AWS service over the past 30 days.

**CLI Command**:
```bash
python .claude/utils/aws_mgmt/cost_cli.py -e {environment} breakdown [options]
```

**Options**:
- `--days <N>` - Number of days to analyze (default: 30)
- `--top <N>` - Show top N services by cost (default: 10)
- `--service <name>` - Filter to specific service
- `--format <type>` - Output format (markdown, json, csv)
- `--include-zero` - Include services with zero cost

**Example Usage**:
```bash
# 30-day breakdown for DEV (default)
python .claude/utils/aws_mgmt/cost_cli.py -e dev breakdown

# 30-day breakdown for all environments
python .claude/utils/aws_mgmt/cost_cli.py -e all breakdown --days 30

# Top 5 services in SIT as CSV
python .claude/utils/aws_mgmt/cost_cli.py -e sit breakdown --top 5 --format csv

# Filter to ECS costs only
python .claude/utils/aws_mgmt/cost_cli.py -e prod breakdown --service "Amazon Elastic Container Service"
```

**AWS CLI Equivalent**:
```bash
# Get 30-day daily costs by service
AWS_PROFILE=Tebogo-{env} aws ce get-cost-and-usage \
  --time-period Start=$(date -v-30d +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE \
  --region us-east-1
```

**Output**:
- Daily cost per service (30-day table)
- Service totals and daily averages
- Day-over-day change percentage
- Trend indicators (↑ increasing, ↓ decreasing, → stable)
- Anomaly flags for unusual spikes

**Sample Output Format**:
```
30-Day Cost Breakdown by Service - DEV (536580886816)
Period: 2025-11-16 to 2025-12-16

| Service                  | 30D Total | Avg/Day | Trend | Top Day    |
|--------------------------|-----------|---------|-------|------------|
| Amazon ECS Fargate       | $27.45    | $0.92   | →     | Dec-14: $1.12 |
| EC2 - Other (NAT/EIP)    | $48.00    | $1.60   | →     | Dec-15: $1.60 |
| Amazon Bedrock           | $25.35    | $0.85   | ↑     | Dec-10: $3.20 |
| Amazon ELB               | $22.50    | $0.75   | →     | Dec-16: $0.76 |
| Amazon RDS               | $15.30    | $0.51   | →     | Dec-15: $0.52 |
| Amazon EFS               | $4.80     | $0.16   | →     | Dec-16: $0.16 |
| Amazon S3                | $0.45     | $0.02   | →     | Dec-12: $0.03 |
| AWS Lambda               | $0.12     | $0.004  | →     | Dec-14: $0.01 |
|--------------------------|-----------|---------|-------|------------|
| TOTAL                    | $143.97   | $4.80   |       |            |
```

---

### Skill: cost_escalation_graph_30d

**Description**: Generate a 30-day cost escalation bar graph showing daily cumulative spend. Visualizes cost trends and helps identify spending patterns or anomalies.

**CLI Command**:
```bash
python .claude/utils/aws_mgmt/cost_cli.py -e {environment} graph [options]
```

**Options**:
- `--type <bar|line|cumulative>` - Graph type (default: bar)
- `--days <N>` - Number of days (default: 30)
- `--compare` - Compare to previous period
- `--budget-line` - Show budget threshold line
- `--format <type>` - Output format (ascii, png, html)

**Example Usage**:
```bash
# 30-day bar graph for DEV
python .claude/utils/aws_mgmt/cost_cli.py -e dev graph --type bar

# Cumulative spend graph with budget line
python .claude/utils/aws_mgmt/cost_cli.py -e prod graph --type cumulative --budget-line

# Compare current vs previous 30 days
python .claude/utils/aws_mgmt/cost_cli.py -e sit graph --compare

# Generate PNG graph
python .claude/utils/aws_mgmt/cost_cli.py -e dev graph --format png
```

**AWS CLI Equivalent**:
```bash
# Get daily totals for graph
AWS_PROFILE=Tebogo-{env} aws ce get-cost-and-usage \
  --time-period Start=$(date -v-30d +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics "UnblendedCost" \
  --region us-east-1
```

**Output**:
- ASCII bar graph (terminal-friendly)
- Daily spend visualization
- Budget threshold markers
- Trend line indicator
- Peak day highlighting

**Sample ASCII Bar Graph Output**:
```
30-Day Cost Escalation - DEV (536580886816)
Budget: $200/month | Daily Target: $6.67

Date       | Cost    | Bar (max $10)
-----------|---------|--------------------------------------------------
Nov-16     | $3.21   | ████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
Nov-17     | $4.56   | ██████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░
Nov-18     | $3.89   | ███████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
Nov-19     | $5.12   | █████████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░
Nov-20     | $4.78   | ███████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░
...
Dec-14     | $6.23   | ███████████████████████████████░░░░░░░░░░░░░░░░░░░
Dec-15     | $5.89   | █████████████████████████████░░░░░░░░░░░░░░░░░░░░░
Dec-16     | $4.12   | ████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
-----------|---------|--------------------------------------------------
TOTAL      | $143.97 | Avg: $4.80/day | Projected: $148.80/month
                     | Budget Util: 74.4% ✓ ON TRACK

Legend: ████ Actual | ░░░░ Remaining to max | ─── Budget Line ($6.67/day)
```

**Sample Cumulative Graph Output**:
```
30-Day Cumulative Spend - DEV (536580886816)
Budget: $200/month

$200 |                                              ─────────── Budget
     |                                         ╭───
$150 |                                    ╭────╯
     |                               ╭────╯
$100 |                          ╭────╯
     |                     ╭────╯
$50  |                ╭────╯
     |           ╭────╯
$0   |──────╭────╯
     +-----|-----|-----|-----|-----|-----|----->
         Nov-16  Nov-23  Nov-30  Dec-07  Dec-14  Dec-16

Current: $143.97 | Projected EOM: $148.80 | Under Budget: $51.20
```

---

## Budget Configuration

| Environment | Monthly Budget | Alert Thresholds |
|-------------|---------------|------------------|
| DEV | $200 | 50%, 80%, 100% |
| SIT | $400 | 80%, 100% |
| PROD | $1,000 | 80%, 90%, 100%, 110% |

## Cost Allocation Model

### Per-Tenant Direct Costs
- ECS Fargate task (per tenant container)
- EFS access point storage
- CloudWatch logs (per tenant)
- CloudFront distribution

### Shared Costs (Split Equally)
- RDS instance
- Application Load Balancer
- VPC (NAT Gateway, data transfer)
- Secrets Manager

### Target Cost per Tenant
- Minimum: $25/month
- Maximum: $37/month
- Base allocation (shared): ~$15
- Variable (storage/compute): $10-$22

## Budget Actions

| Threshold | DEV Action | SIT Action | PROD Action |
|-----------|-----------|-----------|-------------|
| 80% | SNS warning | SNS warning | SNS + review |
| 100% | Stop non-critical | Alert ops | Executive alert |
| 110% | N/A | N/A | Cost containment |

## Environment Configuration

- **DEV** (536580886816): $200 budget, minimal monitoring
- **SIT** (815856636111): $400 budget, standard monitoring
- **PROD** (093646564004): $1000 budget, strict monitoring, read-only

## Prerequisites

- AWS credentials configured for target environment
- Cost Explorer enabled (24-hour activation delay)
- Cost allocation tags activated
- boto3 installed (`pip install boto3`)
- AWS Budgets API access

## Notifications

Cost events trigger SNS notifications:
- `bbws-cost-alert`: Budget alerts and anomalies

## Related Agents

- **Monitoring Agent**: For resource utilization tracking
- **Backup Manager Agent**: For backup storage costs
- **DR Manager Agent**: For DR cost estimation
