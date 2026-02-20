# Phase 7: UAT and Performance Testing (SIT Environment)

**Phase**: 7 of 10
**Duration**: 2.5 days (20 hours)
**Responsible**: Product Owner + QA Team + Client Stakeholder
**Environment**: SIT
**Dependencies**: Phase 6 (SIT Environment Promotion) must be complete
**Status**: ⏳ NOT STARTED

---

## Phase Objectives

- Execute User Acceptance Testing (UAT) with client stakeholder
- Validate all business workflows and use cases
- Perform comprehensive performance and load testing
- Test disaster recovery and backup procedures
- Validate monitoring and alerting
- Test failover scenarios
- Document UAT sign-off from client
- Fix any UAT-discovered defects
- Obtain final approval for PROD deployment

---

## Prerequisites

- [ ] Phase 6 completed: Tenant promoted to SIT successfully
- [ ] SIT environment stable and functional
- [ ] Client stakeholder available for UAT sessions
- [ ] UAT test scenarios prepared
- [ ] Performance testing tools ready (JMeter, K6, or LoadRunner)
- [ ] aupairhive_testing_checklist.md available
- [ ] UAT sign-off template prepared
- [ ] Production go-live checklist prepared

---

## Detailed Tasks

### Task 7.1: Client UAT Kick-Off and Training

**Duration**: 2 hours
**Responsible**: Product Owner + Technical Lead

**Steps**:

1. **Schedule UAT kick-off meeting**:
- Attendees: Client stakeholder, Product Owner, QA Lead, Technical Lead
- Duration: 1 hour
- Agenda:
  - UAT objectives and scope
  - Test environment overview (SIT)
  - UAT schedule and timeline
  - Roles and responsibilities
  - Defect reporting process
  - Sign-off criteria

2. **Provide UAT environment access**:
- URL: https://aupairhive.wpsit.kimmyai.io
- Admin credentials: [Provide securely]
- Test user accounts: [Create 3-5 test users]
- UAT testing guide document

3. **Conduct environment walkthrough**:
- Demonstrate site navigation
- Show admin panel features
- Explain Divi Builder usage
- Demonstrate form submissions
- Show how to check form entries

4. **Set UAT expectations**:
```bash
cat > uat_guidelines.txt <<EOF
=== UAT Guidelines for Au Pair Hive ===

UAT Period: 2.5 days (Jan 10-12, 2026)
Environment: SIT (https://aupairhive.wpsit.kimmyai.io)

What to Test:
- All website pages and content
- Contact forms and applications
- Email notifications
- Admin panel functionality
- Content editing (Divi Builder)
- Mobile and desktop experience

How to Report Issues:
1. Document issue with screenshots
2. Send to: qa@kimmyai.io
3. Include: Page URL, Steps to reproduce, Expected vs Actual result
4. Severity: Critical, High, Medium, Low

UAT Sign-Off Criteria:
- All critical issues resolved
- All high-priority issues resolved or have workarounds
- Client confirms site meets business requirements
- Client approves go-live to PROD

Contact:
- Technical Questions: technical-lead@kimmyai.io
- UAT Process Questions: product-owner@kimmyai.io
EOF
```

**Verification**:
- [ ] Kick-off meeting completed
- [ ] Client has UAT environment access
- [ ] Client understands UAT process
- [ ] UAT guidelines provided
- [ ] Test accounts created

---

### Task 7.2: Business Workflow Testing (UAT)

**Duration**: 8 hours (spread across 2 days)
**Responsible**: Client Stakeholder + QA Engineer

**UAT Test Scenarios**:

**Scenario 1: Au Pair Applicant Journey**:
1. [ ] Navigate to Au Pair program page
2. [ ] Read program details and requirements
3. [ ] Click "Apply Now" button
4. [ ] Fill out Au Pair application form:
   - Personal information
   - Work experience
   - Upload resume (PDF)
   - Upload photo (JPG)
5. [ ] Complete reCAPTCHA
6. [ ] Submit application
7. [ ] Verify success message displays
8. [ ] Check confirmation email received
9. [ ] Admin: Verify entry in Gravity Forms
10. [ ] Admin: Verify file attachments present

**Scenario 2: Host Family Inquiry Journey**:
1. [ ] Navigate to Host Family page
2. [ ] Read program details and costs
3. [ ] Click "Get Started" button
4. [ ] Fill out Host Family application form
5. [ ] Submit form
6. [ ] Verify success message
7. [ ] Check confirmation email
8. [ ] Admin: Verify entry recorded

**Scenario 3: General Inquiry via Contact Form**:
1. [ ] Navigate to Contact page
2. [ ] Fill out contact form with general question
3. [ ] Submit form
4. [ ] Verify success message
5. [ ] Check auto-reply email
6. [ ] Admin: Verify notification email received at info@aupairhive.com

**Scenario 4: Content Browsing and Navigation**:
1. [ ] Navigate through all main pages
2. [ ] Test all menu links
3. [ ] Test footer links
4. [ ] Click social media icons
5. [ ] Test blog posts (if applicable)
6. [ ] Test search functionality (if exists)
7. [ ] Test pagination on blog

**Scenario 5: Admin Content Management**:
1. [ ] Login to WordPress admin
2. [ ] Edit homepage using Divi Builder
3. [ ] Add new section to page
4. [ ] Upload new image to Media Library
5. [ ] Create new blog post
6. [ ] Preview post before publishing
7. [ ] Publish post
8. [ ] Verify post displays on frontend

**Scenario 6: Form Entry Management**:
1. [ ] Go to: Forms → Entries
2. [ ] View Contact form entries
3. [ ] View Au Pair application entries
4. [ ] Download entry as PDF
5. [ ] Export entries to CSV
6. [ ] Mark entry as "Read"
7. [ ] Add note to entry

**UAT Test Results Template**:
```bash
cat > uat_test_results.txt <<EOF
=== UAT Test Results - Au Pair Hive ===
Tester: [Client Name]
Date: $(date)

Scenario                          | Status | Notes
----------------------------------|--------|---------------------------
Au Pair Applicant Journey         | PASS   | Works perfectly
Host Family Inquiry Journey       | PASS   | Works as expected
General Inquiry via Contact       | PASS   | Email received
Content Browsing and Navigation   | FAIL   | About page link broken
Admin Content Management          | PASS   | Divi Builder easy to use
Form Entry Management             | PASS   | Export to CSV works

Overall Impression:
[Client feedback here]

Issues Found:
1. About page link returns 404 - HIGH
2. Mobile form labels slightly misaligned - LOW

Approved for PROD: [ ] YES  [X] NO (fix issue #1 first)
EOF
```

**Verification**:
- [ ] All 6 UAT scenarios executed by client
- [ ] UAT results documented
- [ ] Client feedback collected
- [ ] Issues identified and logged

---

### Task 7.3: Performance Testing and Benchmarking

**Duration**: 4 hours
**Responsible**: Performance Engineer + DevOps

**Performance Test Scenarios**:

**Test 1: Baseline Page Load Performance**:
```bash
# Homepage load time
for i in {1..10}; do
    curl -o /dev/null -s -w "Attempt $i: %{time_total}s\n" https://aupairhive.wpsit.kimmyai.io
done

# Calculate average
# Target: <2 seconds average
```

**Test 2: Concurrent Users (Load Test)**:
```bash
# Using Apache Bench
ab -n 1000 -c 50 -g load_test_results.tsv https://aupairhive.wpsit.kimmyai.io/

# Expected:
# - Requests per second: >100
# - Failed requests: 0
# - Mean time per request: <500ms
```

**Test 3: Form Submission Under Load**:
```bash
# Using K6 load testing tool
cat > form_load_test.js <<EOJS
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
    stages: [
        { duration: '2m', target: 10 },  // Ramp up to 10 users
        { duration: '5m', target: 10 },  // Stay at 10 users
        { duration: '2m', target: 0 },   // Ramp down
    ],
};

export default function () {
    let payload = {
        'input_1': 'Test User',
        'input_2': 'test@example.com',
        'input_3': 'Test message for load testing',
    };

    let res = http.post('https://aupairhive.wpsit.kimmyai.io/contact/', payload);

    check(res, {
        'status is 200': (r) => r.status === 200,
        'response time < 2s': (r) => r.timings.duration < 2000,
    });

    sleep(1);
}
EOJS

k6 run form_load_test.js
```

**Test 4: Database Query Performance**:
```bash
# Enable query monitoring
# Install Query Monitor plugin or check slow query log

mysql -h $SIT_RDS_ENDPOINT -u admin -p -e "
    SET GLOBAL slow_query_log = 'ON';
    SET GLOBAL long_query_time = 1;
    SHOW VARIABLES LIKE 'slow_query_log%';
"

# Navigate site and check slow queries
# Review: /var/log/mysql/slow-query.log

# Expected: No queries >1 second
```

**Test 5: Image Optimization and CDN Performance**:
```bash
# Test image load times
curl -w "@curl-format.txt" -o /dev/null -s https://aupairhive.wpsit.kimmyai.io/wp-content/uploads/2024/01/hero-image.jpg

# Check CloudFront cache hits
# Expected: X-Cache: Hit from cloudfront (after first request)
```

**Test 6: API Endpoint Performance** (if applicable):
```bash
# Test REST API endpoints
time curl -s https://aupairhive.wpsit.kimmyai.io/wp-json/wp/v2/posts

# Expected: <500ms response time
```

**Performance Test Results**:
```bash
cat > performance_test_results.txt <<EOF
=== Performance Test Results - SIT ===
Date: $(date)
Environment: SIT

Test                          | Metric              | Result  | Target   | Status
------------------------------|---------------------|---------|----------|-------
Baseline Page Load            | Avg Load Time       | 1.8s    | <2s      | PASS
Concurrent Users (50)         | Requests/sec        | 142     | >100     | PASS
Concurrent Users (50)         | Failed Requests     | 0       | 0        | PASS
Form Submission Load          | Success Rate        | 100%    | >95%     | PASS
Form Submission Load          | Avg Response Time   | 890ms   | <2s      | PASS
Database Queries              | Slow Queries        | 2       | <5       | PASS
Image Load Time               | Hero Image          | 320ms   | <1s      | PASS
CloudFront Cache              | Hit Rate            | 98%     | >90%     | PASS

Recommendations:
- Enable browser caching for static assets
- Optimize 2 slow database queries (wp_options autoload)
- Consider lazy loading for below-the-fold images

Overall Performance: ACCEPTABLE for PROD
EOF
```

**Verification**:
- [ ] All performance tests executed
- [ ] Load testing completed (50 concurrent users)
- [ ] Form submission load test passed
- [ ] Database query performance acceptable
- [ ] Image optimization verified
- [ ] Performance results documented
- [ ] Performance meets PROD targets

---

### Task 7.4: Stress Testing and Failure Scenarios

**Duration**: 2 hours
**Responsible**: DevOps Engineer

**Stress Test Scenarios**:

**Test 1: ECS Task Failure Recovery**:
```bash
# Manually stop ECS task to simulate failure
TASK_ARN=$(aws ecs list-tasks \
    --cluster sit-cluster \
    --service-name aupairhive-sit-service \
    --query 'taskArns[0]' --output text)

# Stop task
aws ecs stop-task \
    --cluster sit-cluster \
    --task $TASK_ARN \
    --reason "Stress test: Simulating task failure"

# Monitor recovery
# Expected: New task starts automatically within 1 minute

# Verify site still accessible
curl -I https://aupairhive.wpsit.kimmyai.io
```

**Test 2: Database Connection Failure**:
```bash
# Simulate database connection issues by updating security group
# (Don't actually execute - document expected behavior)

# Expected Behavior:
# - WordPress displays "Error establishing database connection"
# - ECS health check fails after 3 consecutive failures
# - Task marked unhealthy but not restarted (DB issue)
# - After fixing DB connection, task becomes healthy again
```

**Test 3: Sustained High Load (Spike Test)**:
```bash
# Spike test: Sudden burst of 100 concurrent users for 1 minute
ab -n 6000 -c 100 -t 60 https://aupairhive.wpsit.kimmyai.io/

# Monitor:
# - ECS CPU/Memory utilization (CloudWatch)
# - RDS CPU utilization
# - ALB request count
# - Response times

# Expected:
# - ECS CPU < 80%
# - RDS CPU < 70%
# - No 5xx errors
# - Response time degradation acceptable (<3s)
```

**Test 4: EFS Storage Full Scenario**:
```bash
# Check current EFS usage
du -sh /var/www/html

# Simulate storage issues (document expected behavior)
# Expected:
# - WordPress unable to upload new images
# - Error message: "The uploaded file could not be moved"
# - Site continues to function (serving existing content)
# - CloudWatch alarm triggers (if configured)
```

**Stress Test Results**:
```bash
cat > stress_test_results.txt <<EOF
=== Stress Test Results - SIT ===

Test                          | Result                            | Status
------------------------------|-----------------------------------|-------
ECS Task Failure              | New task started in 42 seconds    | PASS
Database Connection Failure   | Error page displayed (expected)   | PASS
Sustained High Load (100 users)| 0 failed requests, avg 2.1s      | PASS
EFS Storage Full              | Uploads fail gracefully           | PASS

Observations:
- ECS auto-recovery works as expected
- Site handles 100 concurrent users without issues
- Graceful degradation when dependencies fail

Recommendations:
- Configure CloudWatch alarms for ECS task failures
- Enable EFS monitoring alerts
- Document runbook for database connection issues
EOF
```

**Verification**:
- [ ] ECS task failure recovery tested
- [ ] Database failure scenario documented
- [ ] High load stress test passed
- [ ] Storage failure scenario documented
- [ ] Auto-scaling behavior verified (if enabled)
- [ ] Stress test results documented

---

### Task 7.5: Backup and Disaster Recovery Testing

**Duration**: 2 hours
**Responsible**: Database Administrator + DevOps

**DR Test Scenarios**:

**Test 1: Database Backup and Restore**:
```bash
# Create manual backup
mysqldump -h $SIT_RDS_ENDPOINT -u $SIT_USER -p$SIT_PASS \
    --single-transaction \
    tenant_aupairhive_db > backup_dr_test_$(date +%Y%m%d_%H%M%S).sql

# Simulate data corruption (create test record)
mysql -h $SIT_RDS_ENDPOINT -u $SIT_USER -p$SIT_PASS tenant_aupairhive_db -e \
    "INSERT INTO wp_posts (post_title, post_content, post_status) VALUES ('DR TEST', 'This is a DR test post', 'publish');"

# Restore from backup
mysql -h $SIT_RDS_ENDPOINT -u $SIT_USER -p$SIT_PASS tenant_aupairhive_db < backup_dr_test_*.sql

# Verify test record removed
mysql -h $SIT_RDS_ENDPOINT -u $SIT_USER -p$SIT_PASS tenant_aupairhive_db -e \
    "SELECT COUNT(*) FROM wp_posts WHERE post_title='DR TEST';"

# Expected: Count = 0 (test record removed)
```

**Test 2: File Backup and Restore (EFS)**:
```bash
# Create EFS backup via ECS task
aws ecs run-task \
    --cluster sit-cluster \
    --task-definition aupairhive-sit-task \
    --overrides '{
        "containerOverrides": [{
            "name": "wordpress",
            "command": ["sh", "-c", "tar czf /tmp/efs-backup-$(date +%Y%m%d).tar.gz -C /var/www/html . && aws s3 cp /tmp/efs-backup-*.tar.gz s3://bbws-sit-backups/aupairhive/"]
        }]
    }' \
    --launch-type FARGATE

# Verify backup uploaded to S3
aws s3 ls s3://bbws-sit-backups/aupairhive/

# Simulate file corruption (delete test file)
# Restore from backup
# (Detailed restore procedure in DR runbook)
```

**Test 3: Point-in-Time Recovery (RDS)**:
```bash
# Verify RDS automated backups enabled
aws rds describe-db-instances \
    --db-instance-identifier bbws-sit-mysql \
    --query 'DBInstances[0].[BackupRetentionPeriod,PreferredBackupWindow,LatestRestorableTime]'

# Expected: BackupRetentionPeriod = 7 days (or more)

# Document PITR procedure (don't execute in SIT):
# 1. Identify restore point timestamp
# 2. Create new RDS instance from snapshot
# 3. Update ECS task definition with new DB endpoint
# 4. Restart ECS service
```

**DR Test Results**:
```bash
cat > dr_test_results.txt <<EOF
=== Disaster Recovery Test Results - SIT ===

Test                          | RTO      | RPO     | Status | Notes
------------------------------|----------|---------|--------|------------------------
Database Backup/Restore       | 15 min   | 0       | PASS   | Full restore successful
File Backup/Restore (EFS)     | 20 min   | 0       | PASS   | Backup to S3 works
Point-in-Time Recovery (RDS)  | 30 min   | 5 min   | DOC    | Procedure documented

RTO = Recovery Time Objective (how long to recover)
RPO = Recovery Point Objective (how much data loss acceptable)

Overall DR Readiness: GOOD
Recommendation: Schedule monthly DR drills
EOF
```

**Verification**:
- [ ] Database backup and restore tested successfully
- [ ] File backup to S3 tested
- [ ] RDS automated backups verified
- [ ] Point-in-time recovery procedure documented
- [ ] DR test results documented
- [ ] Recovery objectives met (RTO <30min, RPO <1hr)

---

### Task 7.6: Monitoring and Alerting Validation

**Duration**: 1.5 hours
**Responsible**: DevOps Engineer

**Monitoring Checks**:

**Check 1: CloudWatch Metrics**:
```bash
# Verify ECS metrics
aws cloudwatch list-metrics \
    --namespace AWS/ECS \
    --dimensions Name=ServiceName,Value=aupairhive-sit-service

# Expected metrics:
# - CPUUtilization
# - MemoryUtilization
# - TargetResponseTime

# Verify RDS metrics
aws cloudwatch list-metrics \
    --namespace AWS/RDS \
    --dimensions Name=DBInstanceIdentifier,Value=bbws-sit-mysql

# Expected metrics:
# - CPUUtilization
# - DatabaseConnections
# - FreeStorageSpace
```

**Check 2: CloudWatch Logs**:
```bash
# Verify logs are being collected
aws logs describe-log-groups --log-group-name-prefix /ecs/aupairhive-sit

# Tail recent logs
aws logs tail /ecs/aupairhive-sit --since 1h

# Check for errors
aws logs filter-events \
    --log-group-name /ecs/aupairhive-sit \
    --filter-pattern "ERROR" \
    --start-time $(date -u -d '1 hour ago' +%s)000
```

**Check 3: CloudWatch Alarms** (if configured):
```bash
# List alarms for aupairhive
aws cloudwatch describe-alarms \
    --alarm-name-prefix aupairhive-sit

# Expected alarms:
# - ECS CPU > 80%
# - ECS Memory > 80%
# - ALB TargetResponseTime > 2s
# - RDS CPU > 70%
# - ECS UnhealthyTargetCount > 0
```

**Check 4: Test Alert Triggering**:
```bash
# Trigger high CPU alarm (simulate load)
ab -n 10000 -c 100 https://aupairhive.wpsit.kimmyai.io/

# Monitor CloudWatch alarm state
aws cloudwatch describe-alarms \
    --alarm-names aupairhive-sit-high-cpu \
    --query 'MetricAlarms[0].StateValue'

# Expected: State changes from OK → ALARM → OK
# Expected: SNS notification sent (check email)
```

**Monitoring Validation Results**:
```bash
cat > monitoring_validation_results.txt <<EOF
=== Monitoring Validation Results - SIT ===

Component                     | Status | Notes
------------------------------|--------|---------------------------
ECS CloudWatch Metrics        | PASS   | All metrics publishing
RDS CloudWatch Metrics        | PASS   | All metrics publishing
CloudWatch Logs               | PASS   | Logs streaming correctly
CloudWatch Alarms             | PASS   | 5 alarms configured
Alert Triggering              | PASS   | SNS notification received
Dashboard                     | PASS   | Custom dashboard viewable

Recommendations:
- Add alarm for form submission failures
- Configure log retention (30 days recommended)
- Create runbook for each alarm type
EOF
```

**Verification**:
- [ ] CloudWatch metrics collecting for ECS and RDS
- [ ] CloudWatch logs streaming correctly
- [ ] CloudWatch alarms configured
- [ ] Alert triggering tested (SNS email received)
- [ ] Custom dashboard created (if applicable)
- [ ] Monitoring validation results documented

---

### Task 7.7: Security and Compliance Testing

**Duration**: 1.5 hours
**Responsible**: Security Engineer / DevOps

**Security Tests**:

**Test 1: SSL/TLS Security**:
```bash
# Test SSL configuration
./testssl.sh https://aupairhive.wpsit.kimmyai.io

# Or use SSL Labs
# Navigate to: https://www.ssllabs.com/ssltest/
# Enter: aupairhive.wpsit.kimmyai.io
# Target Grade: A or A-
```

**Test 2: OWASP Top 10 Vulnerability Scan**:
```bash
# Run OWASP ZAP scan
zap-cli quick-scan -s all https://aupairhive.wpsit.kimmyai.io

# Or use WPScan
wpscan --url https://aupairhive.wpsit.kimmyai.io \
    --enumerate vp,vt,u \
    --api-token YOUR_API_TOKEN \
    --format cli

# Review vulnerabilities found
```

**Test 3: Authentication and Authorization**:
- [ ] Verify wp-admin requires login
- [ ] Verify strong password policy enforced (if plugin installed)
- [ ] Test failed login attempts lockout (if configured)
- [ ] Verify two-factor authentication (if configured)
- [ ] Test user role permissions (admin vs editor vs subscriber)

**Test 4: Data Protection**:
```bash
# Verify database encryption at rest (RDS)
aws rds describe-db-instances \
    --db-instance-identifier bbws-sit-mysql \
    --query 'DBInstances[0].StorageEncrypted'

# Expected: true

# Verify EFS encryption at rest
aws efs describe-file-systems \
    --file-system-id $SIT_EFS_ID \
    --query 'FileSystems[0].Encrypted'

# Expected: true
```

**Test 5: Secrets Management**:
```bash
# Verify wp-config.php not accessible
curl -I https://aupairhive.wpsit.kimmyai.io/wp-config.php
# Expected: 403 Forbidden or 404 Not Found

# Verify database credentials in Secrets Manager (not hardcoded)
# Check ECS task definition uses Secrets Manager references
aws ecs describe-task-definition \
    --task-definition aupairhive-sit-task \
    --query 'taskDefinition.containerDefinitions[0].secrets'
```

**Security Test Results**:
```bash
cat > security_test_results.txt <<EOF
=== Security Test Results - SIT ===

Test                          | Result                         | Status
------------------------------|--------------------------------|-------
SSL/TLS Configuration         | Grade A-                       | PASS
OWASP Vulnerability Scan      | 0 high, 2 medium found         | WARN
Authentication                | Login required, lockout works  | PASS
Database Encryption           | Enabled                        | PASS
EFS Encryption                | Enabled                        | PASS
Secrets Management            | Secrets Manager used           | PASS
wp-config.php Protection      | 403 Forbidden                  | PASS

Medium Vulnerabilities Found:
1. Outdated Gravity Forms version (update available)
2. WordPress version disclosure in meta tag

Action Items:
- Update Gravity Forms plugin
- Remove WordPress version from meta tags
EOF
```

**Verification**:
- [ ] SSL/TLS configuration tested (Grade A or A-)
- [ ] Vulnerability scan completed
- [ ] Authentication and authorization tested
- [ ] Data encryption verified (RDS, EFS)
- [ ] Secrets management validated
- [ ] Security findings documented
- [ ] Medium/low vulnerabilities acceptable for go-live (or fixed)

---

### Task 7.8: UAT Defect Remediation

**Duration**: Variable (4-8 hours depending on defects)
**Responsible**: Development Team

**Process**:

1. **Consolidate UAT defects**:
```bash
cat uat_test_results.txt stress_test_results.txt security_test_results.txt > all_uat_defects.txt

# Categorize by severity
grep -i "high\|critical" all_uat_defects.txt > critical_defects.txt
```

2. **Triage and prioritize**:
```bash
cat > uat_defect_triage.txt <<EOF
=== UAT Defect Triage ===

P0 (Critical - MUST FIX for PROD):
- ID-201: About page link returns 404

P1 (High - Fix before PROD):
- ID-202: Gravity Forms outdated (security)

P2 (Medium - Can monitor in PROD):
- ID-203: Mobile form label alignment off by 2px
- ID-204: WordPress version disclosed in meta tag

P3 (Low - Post-launch):
- None

Total Defects: 4
Blocking PROD Go-Live: 2 (P0 + P1)
EOF
```

3. **Fix P0 defects**:
```bash
# Example: Fix broken About page link
# Update navigation menu or page permalink
# Verify fix in SIT
curl -I https://aupairhive.wpsit.kimmyai.io/about/
# Expected: HTTP 200
```

4. **Fix P1 defects**:
```bash
# Example: Update Gravity Forms plugin
wp plugin update gravityforms --path=/var/www/html

# Verify update
wp plugin list --path=/var/www/html | grep gravityforms
```

5. **Retest after fixes**:
- Re-execute failed UAT scenarios
- Verify fixes resolve issues
- Document retest results

6. **Update UAT status**:
```bash
cat > uat_defect_resolution.txt <<EOF
=== UAT Defect Resolution ===

ID     | Severity | Description                  | Status    | Resolution
-------|----------|------------------------------|-----------|---------------------------
ID-201 | P0       | About page link 404          | RESOLVED  | Fixed permalink
ID-202 | P1       | Gravity Forms outdated       | RESOLVED  | Updated to v2.8.5
ID-203 | P2       | Mobile label alignment       | DEFERRED  | CSS tweak post-launch
ID-204 | P2       | WP version disclosure        | DEFERRED  | Remove in next release

All blocking defects resolved: YES
Ready for PROD: YES
EOF
```

**Verification**:
- [ ] All UAT defects cataloged
- [ ] P0 defects resolved and retested
- [ ] P1 defects resolved and retested
- [ ] P2/P3 defects documented for post-launch
- [ ] Client informed of resolutions
- [ ] Retest results documented

---

### Task 7.9: Final UAT Sign-Off

**Duration**: 1 hour
**Responsible**: Client Stakeholder + Product Owner

**Sign-Off Process**:

1. **Prepare UAT summary report**:
```bash
cat > uat_summary_report.txt <<EOF
=== Au Pair Hive UAT Summary Report ===
Date: $(date)
Environment: SIT (https://aupairhive.wpsit.kimmyai.io)

UAT Participants:
- Client Stakeholder: [Name]
- Product Owner: [Name]
- QA Lead: [Name]

UAT Duration: 2.5 days (Jan 10-12, 2026)

Test Scenarios Executed:
1. Au Pair Applicant Journey - PASS
2. Host Family Inquiry Journey - PASS
3. General Inquiry via Contact - PASS
4. Content Browsing and Navigation - PASS (after fix)
5. Admin Content Management - PASS
6. Form Entry Management - PASS

Performance Test Results:
- Concurrent Users: 50 users handled successfully
- Page Load Time: 1.8s average (target <2s)
- Form Submission Load: 100% success rate

Security Test Results:
- SSL/TLS: Grade A-
- Vulnerabilities: 2 medium (resolved)
- Data Encryption: Enabled

Defects Found: 4
- P0 (Critical): 1 - RESOLVED
- P1 (High): 1 - RESOLVED
- P2 (Medium): 2 - DEFERRED to post-launch

Client Feedback:
[Insert client feedback here]

UAT RESULT: ✓ APPROVED
Ready for Production Deployment: YES
Approved By: [Client Name]
Date: [Date]
EOF
```

2. **Conduct sign-off meeting**:
- Review UAT summary report
- Address any final client concerns
- Confirm all blocking issues resolved
- Obtain formal sign-off

3. **Document formal approval**:
```bash
cat > uat_sign_off.txt <<EOF
=== FORMAL UAT SIGN-OFF ===

Project: Au Pair Hive Migration to BBWS Platform
Environment: SIT (https://aupairhive.wpsit.kimmyai.io)

I, [Client Name], hereby approve the Au Pair Hive website for deployment to Production.

I confirm that:
✓ All critical and high-priority defects have been resolved
✓ The website meets all business requirements
✓ All forms and functionality work as expected
✓ The site is ready for public launch

Signature: _______________________
Name: [Client Name]
Title: [Title]
Date: [Date]

Witnessed By:
Product Owner: _________________ Date: _________
Technical Lead: _________________ Date: _________
EOF
```

**Verification**:
- [ ] UAT summary report prepared
- [ ] Sign-off meeting conducted
- [ ] Client feedback documented
- [ ] Formal UAT sign-off obtained
- [ ] All stakeholders informed
- [ ] Ready for Phase 8 (PROD Preparation)

---

## Verification Checklist

### UAT Execution
- [ ] Client trained on UAT process
- [ ] All 6 UAT scenarios executed
- [ ] Client feedback collected
- [ ] UAT defects identified and logged

### Performance Testing
- [ ] Baseline performance tests passed
- [ ] Load testing passed (50 concurrent users)
- [ ] Form submission load test passed
- [ ] Database query performance acceptable
- [ ] Stress tests passed

### DR and Monitoring
- [ ] Backup and restore tested
- [ ] Disaster recovery procedures validated
- [ ] CloudWatch monitoring verified
- [ ] Alerting tested

### Security
- [ ] SSL/TLS configuration tested
- [ ] Vulnerability scan completed
- [ ] Data encryption verified
- [ ] Secrets management validated

### Defect Resolution
- [ ] All UAT defects cataloged and triaged
- [ ] All P0 defects resolved
- [ ] All P1 defects resolved
- [ ] P2/P3 defects documented for post-launch

### Final Sign-Off
- [ ] UAT summary report prepared
- [ ] Client sign-off obtained
- [ ] Formal approval documented
- [ ] Ready for PROD deployment

---

## Rollback Procedure

If UAT fails critically (client does not approve):

1. **Document root cause** of UAT failure
2. **Assess scope of fixes** required
3. **Determine timeline** for fixes
4. **Fix issues in DEV** first (if significant changes)
5. **Re-promote to SIT** (repeat Phase 6 if needed)
6. **Re-execute UAT** (Phase 7)
7. **Obtain approval** before proceeding to PROD

---

## Success Criteria

- [ ] All UAT scenarios executed successfully
- [ ] Client approval obtained
- [ ] Performance targets met (load time <2s, 50 concurrent users)
- [ ] Stress tests passed
- [ ] Backup and DR procedures validated
- [ ] Monitoring and alerting functional
- [ ] Security baseline acceptable
- [ ] All P0 and P1 defects resolved
- [ ] Formal UAT sign-off documented
- [ ] Ready for Phase 8 (PROD Deployment Preparation)

**Definition of Done**:
UAT completed successfully with client approval. Site validated for performance, security, and reliability. All blocking defects resolved. Formal sign-off obtained for PROD deployment.

---

## Sign-Off

**UAT Completed By**: _________________ Date: _________
**Client Stakeholder**: _________________ Date: _________
**Product Owner**: _________________ Date: _________
**QA Lead**: _________________ Date: _________

**UAT Scenarios Passed**: _________ / 6
**Performance Tests Passed**: _________ / 6
**Security Tests Passed**: _________ / 7
**Client Approval**: [ ] YES [ ] NO
**Ready for Phase 8**: [ ] YES [ ] NO

---

## Notes and Observations

[Space for team and client to document findings]

**Client Feedback**:
-
-

**Performance Highlights**:
-
-

**Security Findings**:
-
-

**Recommendations for PROD**:
-
-

---

**Next Phase**: Proceed to **Phase 8**: `08_PROD_Deployment_Preparation.md`
