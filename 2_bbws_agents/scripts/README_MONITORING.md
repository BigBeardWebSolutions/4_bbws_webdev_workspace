# SIT Soak Testing - Automated Monitoring Scripts

**Created**: 2026-01-08
**Purpose**: Automated health checks and smoke tests for SIT environment
**Schedule**: Every 6 hours (02:00, 08:00, 14:00, 20:00)

---

## 📁 Scripts Overview

### 1. Automated Monitoring

**`sit_soak_monitor.sh`** - Main monitoring script
- Runs comprehensive health checks
- Collects CloudWatch metrics
- Checks Lambda function status
- Validates DynamoDB tables
- Monitors CloudWatch alarms
- Generates JSON metrics output

**Usage**:
```bash
# Run manually with checkpoint number
./sit_soak_monitor.sh 3

# Run with auto checkpoint numbering
./sit_soak_monitor.sh auto

# View logs
tail -f ~/.claude/logs/soak_checkpoints.log
```

**Checks Performed**:
- ✅ API health (campaigns, products, orders, backend)
- ✅ Lambda function status (20 functions)
- ✅ CloudWatch metrics (invocations, errors, throttles, duration)
- ✅ CloudWatch alarms (ALARM state count)
- ✅ DynamoDB tables (campaigns, products, tenants)

**Outputs**:
- `/Users/tebogotseka/Documents/agentic_work/.claude/logs/soak_checkpoints.log` - Human-readable log
- `/Users/tebogotseka/Documents/agentic_work/.claude/logs/soak_metrics.json` - JSON metrics

---

### 2. Smoke Tests

Individual API smoke test scripts:

#### **`smoke_test_campaigns.sh`** - Campaigns API tests
```bash
./smoke_test_campaigns.sh sit
```

Tests:
- Health check endpoint
- Auth enforcement (401/403 responses)
- Invalid HTTP methods
- Malformed JSON handling
- Response time (<2s)
- CORS headers

#### **`smoke_test_products.sh`** - Product API tests
```bash
./smoke_test_products.sh sit
```

Tests:
- Health/list products endpoints
- CRUD auth enforcement (create, update, delete)
- Response time
- Lambda function count (5)
- API Gateway configuration

#### **`smoke_test_orders.sh`** - Order API tests
```bash
./smoke_test_orders.sh sit
```

Tests:
- Health/list orders endpoints
- CRUD auth enforcement
- Public order creation endpoint
- Payment confirmation endpoint
- Response time
- Lambda function count (10)
- S3 buckets (invoices, templates)

#### **`run_all_smoke_tests.sh`** - Master test runner
```bash
# Run all tests sequentially
./run_all_smoke_tests.sh sit sequential

# Run all tests in parallel
./run_all_smoke_tests.sh sit parallel

# View results
cat ~/.claude/logs/smoke_tests_sit_*.log
```

---

### 3. Cron Scheduler

**`setup_cron_monitoring.sh`** - Cron job management

```bash
# Install cron job (runs every 6 hours)
./setup_cron_monitoring.sh install

# Check status
./setup_cron_monitoring.sh status

# Uninstall cron job
./setup_cron_monitoring.sh uninstall

# View help
./setup_cron_monitoring.sh help
```

**Cron Schedule**:
- 02:00 AM - Checkpoint (overnight stability)
- 08:00 AM - Checkpoint (morning baseline)
- 14:00 PM - Checkpoint (afternoon performance)
- 20:00 PM - Checkpoint (evening stability)

**Cron Entry** (auto-generated):
```cron
0 2,8,14,20 * * * /path/to/sit_soak_monitor.sh auto >> /path/to/cron_monitor.log 2>&1
```

---

## 🚀 Quick Start

### 1. Manual Checkpoint (Run Now)
```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_agents/scripts

# Run monitoring checkpoint
./sit_soak_monitor.sh auto

# Run smoke tests
./run_all_smoke_tests.sh sit sequential
```

### 2. Automated Monitoring (Every 6 Hours)
```bash
# Install cron job
./setup_cron_monitoring.sh install

# Verify installation
./setup_cron_monitoring.sh status

# View live logs
tail -f ~/.claude/logs/cron_monitor.log
```

### 3. Manual Smoke Test (Single API)
```bash
# Test campaigns API only
./smoke_test_campaigns.sh sit

# Test products API only
./smoke_test_products.sh sit

# Test orders API only
./smoke_test_orders.sh sit
```

---

## 📊 Interpreting Results

### Monitoring Script

**Pass Criteria**:
- ✅ All Lambda functions active (20/20)
- ✅ API health checks returning 200/401/403
- ✅ Error rate < 0.1%
- ✅ Zero throttling events
- ✅ <= 1 alarm in ALARM state (pre-existing order DLQ alarm acceptable)

**Sample Output**:
```
==========================================
  SIT SOAK TESTING CHECKPOINT #3
  Time: 2026-01-08 08:00:00
==========================================

=== 1. API Health Checks ===
  ✅ Campaigns API: HTTP 403, 0.71s
  ✅ Product API: HTTP 403, 0.82s
  ✅ Order API: HTTP 403, 0.75s

=== 2. Lambda Function Status ===
  Lambda functions: 20/20 active

=== 3. CloudWatch Metrics (Last 6 Hours) ===
  Campaigns Lambda (get):
    Invocations: 0
    Errors: 0
    Throttles: 0
    Avg Duration: 0ms

=== 4. CloudWatch Alarms ===
  ⚠️  1 alarm(s) in ALARM state
  (Pre-existing order DLQ alarm from Jan 3)

✅ CHECKPOINT #3: PASSED
```

### Smoke Tests

**Sample Output**:
```
==========================================
Campaigns API Smoke Tests - sit Environment
==========================================

TEST: Health Check Endpoint
✅ PASS: Health endpoint returned HTTP 403 (service is up)

TEST: List Campaigns (without auth - should fail)
✅ PASS: Auth is enforced (HTTP 403)

TEST: API Response Time
✅ PASS: Response time: 707ms (< 2000ms threshold)

==========================================
Test Summary
==========================================
Total Tests:  8
Passed:       8
Failed:       0

✅ ALL TESTS PASSED
```

---

## 📝 Logs Location

All logs are stored in: `/Users/tebogotseka/Documents/agentic_work/.claude/logs/`

| Log File | Purpose |
|----------|---------|
| `soak_checkpoints.log` | Monitoring checkpoint results |
| `soak_metrics.json` | JSON metrics from last checkpoint |
| `cron_monitor.log` | Cron job execution log |
| `smoke_tests_sit_*.log` | Smoke test results (timestamped) |

---

## 🔧 Troubleshooting

### Issue: AWS SSO Token Expired

**Error**: `Error loading SSO Token`

**Solution**:
```bash
aws sso login --profile Tebogo-sit
```

### Issue: Cron Job Not Running

**Check**:
```bash
# View current cron jobs
crontab -l

# Check cron logs
tail -50 ~/.claude/logs/cron_monitor.log

# Verify cron service is running (macOS)
sudo launchctl list | grep cron
```

### Issue: Script Permission Denied

**Solution**:
```bash
chmod +x /Users/tebogotseka/Documents/agentic_work/2_bbws_agents/scripts/*.sh
```

### Issue: bc Command Not Found

**Solution** (macOS):
```bash
brew install bc
```

---

## 📅 Checkpoint Schedule (48-Hour Soak Test)

| Checkpoint | Scheduled Time | Status |
|------------|----------------|--------|
| #1 | Jan 8, 07:25 | ✅ COMPLETED |
| #2 | Jan 8, 02:00 | ⏳ SKIPPED (run at 07:25) |
| #3 | Jan 8, 08:00 | ⏳ PENDING |
| #4 | Jan 8, 14:00 | ⏳ PENDING |
| #5 | Jan 8, 20:00 | ⏳ PENDING |
| #6 | Jan 9, 02:00 | ⏳ PENDING |
| #7 | Jan 9, 08:00 | ⏳ PENDING |
| #8 | Jan 9, 14:00 | ⏳ PENDING (final) |

**Completion Target**: Jan 9, 18:40

---

## ✅ Success Criteria

After 48 hours (8 checkpoints), the following must be met:

- [ ] All 8 checkpoints completed
- [ ] Error rate < 0.1% across all checkpoints
- [ ] No P0 or P1 incidents
- [ ] Lambda duration p95 < 2s
- [ ] Zero throttling events
- [ ] All CloudWatch alarms green (except pre-existing order DLQ)
- [ ] No memory leaks detected (steady memory usage)
- [ ] No restarts or redeployments required

**If ALL criteria met**: ✅ Proceed to Phase 2 (SIT Validation - Jan 11-31)
**If ANY criteria failed**: ❌ Investigate and fix before proceeding

---

## 🔗 Related Documents

- **SIT Soak Testing Log**: `/Users/tebogotseka/Documents/agentic_work/.claude/plans/promotions/SIT_SOAK_TESTING_LOG.md`
- **PROD Execution Plan**: `/Users/tebogotseka/Documents/agentic_work/.claude/plans/promotions/PROD_EXECUTION_PLAN.md`
- **Execution Log**: `/Users/tebogotseka/Documents/agentic_work/.claude/plans/promotions/EXECUTION_LOG.md`

---

**Last Updated**: 2026-01-08
**Maintained By**: DevOps Team
