# Phase 9: DNS Cutover and Go-Live

**Phase**: 9 of 10
**Duration**: 4 hours (includes 2-hour downtime window + 2-hour monitoring)
**Responsible**: Entire Team (War Room)
**Environment**: PROD
**Dependencies**: Phase 8 (PROD Deployment Preparation) must be complete
**Status**: ⏳ NOT STARTED

---

## Phase Objectives

- Execute production migration during scheduled downtime window
- Perform final data export from Xneelo
- Import final data to PROD
- Execute DNS cutover from Xneelo to BBWS platform
- Verify site functionality immediately post-cutover
- Make Go/No-Go decision
- Monitor site for 2 hours post-launch
- Communicate go-live success to stakeholders
- Hand off to Phase 10 monitoring

---

## Prerequisites

- [ ] Phase 8 completed: PROD infrastructure ready
- [ ] Go-live date and time scheduled with client
- [ ] Client notified of downtime window (email sent 48h, 24h, 2h before)
- [ ] All team members available during go-live window
- [ ] War room (video conference) link shared
- [ ] Slack channel #aupairhive-golive created
- [ ] Go-live runbook reviewed by all team members
- [ ] Rollback procedures reviewed
- [ ] On-call schedule confirmed
- [ ] Final backups from SIT completed
- [ ] DNS registrar access confirmed
- [ ] Xneelo cPanel access confirmed

---

## Go-Live Timeline

**Scheduled Date**: _____________
**Downtime Window**: _____________ to _____________ (2 hours max)
**Time Zone**: SAST (South Africa Standard Time, UTC+2)

---

## Detailed Tasks

### Task 9.1: T-24 Hours - Final Pre-Go-Live Checks

**Time**: 24 hours before go-live
**Responsible**: Technical Lead

**Steps**:

1. **Verify PROD infrastructure health**:
```bash
export AWS_PROFILE=Tebogo-prod

# Check ECS service
aws ecs describe-services \
    --cluster prod-cluster \
    --services aupairhive-prod-service \
    --query 'services[0].[runningCount,desiredCount,deployments[0].rolloutState]'

# Expected: [2, 2, "COMPLETED"]

# Check ALB target health
aws elbv2 describe-target-health \
    --target-group-arn $PROD_TG_ARN \
    --query 'TargetHealthDescriptions[*].TargetHealth.State'

# Expected: ["healthy", "healthy"]

# Check RDS status
aws rds describe-db-instances \
    --db-instance-identifier bbws-prod-mysql \
    --query 'DBInstances[0].DBInstanceStatus'

# Expected: "available"

# Check CloudFront distribution
aws cloudfront get-distribution --id $DISTRIBUTION_ID \
    --query 'Distribution.Status'

# Expected: "Deployed"
```

2. **Send final notification to client**:
```bash
cat > final_golive_notification.txt <<EOF
Subject: Au Pair Hive Migration - Go-Live Tomorrow at [TIME]

Dear [Client Name],

This is a final reminder that the Au Pair Hive website migration to our new platform will occur tomorrow:

Date: [DATE]
Start Time: [TIME] SAST
Expected Downtime: Up to 2 hours
New Platform URL: https://aupairhive.com (same URL, new infrastructure)

During the migration:
- Your website will display a "Maintenance Mode" message
- No data will be lost
- Forms will be unavailable during downtime
- Email notifications will resume after migration

After the migration:
- You will receive a confirmation email when the site is live
- Please test the site and report any issues immediately
- We will monitor the site for 24 hours post-launch

Contact Information (available during migration):
- Technical Lead: [Phone] / [Email]
- War Room Link: [Zoom/Teams Link]

Thank you for your patience.

Best regards,
[Technical Lead Name]
EOF

# Send email
mail -s "Au Pair Hive Migration - Go-Live Tomorrow" client@aupairhive.com < final_golive_notification.txt
```

3. **Confirm team availability**:
```bash
# Send reminder to team
cat > team_reminder.txt <<EOF
Team,

Go-Live for Au Pair Hive is scheduled for:
Date: [DATE]
Time: [TIME] SAST
Duration: 4 hours (2h cutover + 2h monitoring)

War Room: [Zoom/Teams Link]
Slack: #aupairhive-golive

Please confirm your availability by replying to this email.

Checklist:
- [ ] VPN access tested
- [ ] AWS CLI configured (Tebogo-prod profile)
- [ ] Go-live runbook reviewed
- [ ] Rollback procedures reviewed
- [ ] Phone fully charged
- [ ] Backup laptop available

See you tomorrow!

[Technical Lead]
EOF
```

**Verification**:
- [ ] PROD infrastructure health confirmed
- [ ] Client notified (final reminder)
- [ ] Team availability confirmed
- [ ] All access credentials verified

---

### Task 9.2: T-2 Hours - War Room Setup and Final Preparations

**Time**: 2 hours before downtime window
**Responsible**: Technical Lead

**Steps**:

1. **Open war room**:
```bash
# Join video conference
# URL: [Zoom/Teams Link]

# Post in Slack
echo "War room is open. All team members please join: [Link]" | slack-cli post -c #aupairhive-golive
```

2. **Team roll call**:
- [ ] Technical Lead: Present
- [ ] DevOps Engineer: Present
- [ ] Database Administrator: Present
- [ ] QA Engineer: Present
- [ ] Product Owner: Present
- [ ] Client Stakeholder: Present (optional)

3. **Final infrastructure check**:
```bash
# Run health check script
cat > health_check.sh <<'EOSH'
#!/bin/bash
echo "=== PROD Health Check ==="
echo "Time: $(date)"

echo -n "ECS Service: "
aws ecs describe-services --cluster prod-cluster --services aupairhive-prod-service --query 'services[0].runningCount' --output text
echo " / 2 tasks running"

echo -n "ALB Targets: "
aws elbv2 describe-target-health --target-group-arn $PROD_TG_ARN --query 'length(TargetHealthDescriptions[?TargetHealth.State==`healthy`])' --output text
echo " / 2 healthy"

echo -n "RDS Status: "
aws rds describe-db-instances --db-instance-identifier bbws-prod-mysql --query 'DBInstances[0].DBInstanceStatus' --output text

echo -n "CloudFront: "
aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.Status' --output text

echo "=== All systems ready ==="
EOSH

chmod +x health_check.sh
./health_check.sh
```

4. **Verify SIT still functional** (as reference):
```bash
export AWS_PROFILE=Tebogo-sit
curl -I https://aupairhive.wpsit.kimmyai.io
# Expected: HTTP 200
```

5. **Review go/no-go criteria**:
```bash
cat > go_no_go_criteria.txt <<EOF
=== Go/No-Go Criteria ===

GO Criteria (all must be YES):
- [ ] PROD infrastructure healthy (ECS, RDS, ALB, CloudFront)
- [ ] All team members present
- [ ] Xneelo cPanel access confirmed
- [ ] DNS registrar access confirmed
- [ ] Client approved to proceed

NO-GO Criteria (any triggers abort):
- [ ] Critical infrastructure failure
- [ ] Team member unavailable (Technical Lead or DevOps)
- [ ] Client requests postponement
- [ ] AWS service degradation in af-south-1

Current Status: _________
Decision: [ ] GO  [ ] NO-GO
Authorized by: _________________ Time: _________
EOF
```

**Verification**:
- [ ] War room open with all team members present
- [ ] PROD infrastructure health confirmed (green)
- [ ] SIT still functional (backup reference)
- [ ] Go/No-Go criteria reviewed
- [ ] GO decision authorized by Technical Lead

---

### Task 9.3: T-1 Hour - Put Xneelo Site in Maintenance Mode

**Time**: 1 hour before data export
**Responsible**: WordPress Developer

**Steps**:

1. **Access Xneelo cPanel**:
- URL: https://cPanel.xneelo.co.za
- Login with credentials

2. **Install maintenance mode plugin** (if not already):
```bash
# Via WordPress admin on Xneelo:
# Plugins → Add New → Search "WP Maintenance Mode"
# Install and activate

# Or create manual maintenance.html:
```

3. **Enable maintenance mode**:
```html
<!-- Create: /public_html/.maintenance (WordPress core recognizes this) -->
<?php
$upgrading = time();
?>

<!-- Or create custom maintenance.html in document root -->
<!DOCTYPE html>
<html>
<head>
    <title>Au Pair Hive - Site Maintenance</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            padding: 50px;
            background: #f4f4f4;
        }
        .maintenance-box {
            max-width: 600px;
            margin: 0 auto;
            background: white;
            padding: 40px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 { color: #333; }
        p { color: #666; line-height: 1.6; }
    </style>
</head>
<body>
    <div class="maintenance-box">
        <h1>🔧 Site Maintenance in Progress</h1>
        <p>We're upgrading our website to serve you better!</p>
        <p>We'll be back online shortly. Thank you for your patience.</p>
        <p><strong>Expected completion: [TIME] SAST</strong></p>
        <p>For urgent inquiries, please email: info@aupairhive.com</p>
    </div>
</body>
</html>
```

4. **Verify maintenance mode active**:
```bash
curl -I http://aupairhive.com

# Test in browser (incognito mode)
# Expected: Maintenance page displays
```

5. **Announce maintenance start**:
```bash
# Post to Slack
echo "[T-1h] Maintenance mode enabled on Xneelo. Site now showing maintenance page." | slack-cli post -c #aupairhive-golive

# Email to client
echo "Maintenance mode is now active. Migration proceeding as scheduled." | mail -s "Go-Live: Maintenance Mode Active" client@aupairhive.com
```

**Verification**:
- [ ] Xneelo site showing maintenance page
- [ ] Forms no longer accepting submissions
- [ ] Maintenance mode confirmed in multiple browsers
- [ ] Client notified

---

### Task 9.4: T-30 Minutes - Final Data Export from Xneelo

**Time**: 30 minutes before import
**Responsible**: Database Administrator

**Steps**:

1. **Export database from Xneelo** (final production data):
```bash
# Via cPanel → phpMyAdmin
# 1. Select aupairhive database
# 2. Click "Export" tab
# 3. Export method: Custom
# 4. Format: SQL
# 5. Tables: Select all
# 6. Object creation options:
#    ✓ Add DROP TABLE
#    ✓ Add IF NOT EXISTS
# 7. Data dump options:
#    ✓ Complete inserts
#    ✓ Extended inserts (faster)
# 8. Click "Go"
# 9. Save file: aupairhive_final_prod_export_[DATETIME].sql
```

2. **Verify export file**:
```bash
# Download to local machine
ls -lh ~/Downloads/aupairhive_final_prod_export_*.sql

# Check file size (should be similar to SIT export)
# Expected: 10-50 MB (depending on content)

# Verify SQL syntax
head -n 50 aupairhive_final_prod_export_*.sql

# Expected: See CREATE TABLE, INSERT statements
# No errors or warnings
```

3. **Calculate checksum** (for verification):
```bash
sha256sum aupairhive_final_prod_export_*.sql > export_checksum.txt
cat export_checksum.txt

# Document checksum
```

4. **Check for new uploads** (since SIT testing):
```bash
# Via cPanel → File Manager
# Navigate to: public_html/wp-content/uploads/

# Check if any files uploaded since SIT export
# If yes, download incremental uploads folder
# Example: wp-content/uploads/2026/01/

# Create incremental archive (if needed)
tar czf aupairhive_incremental_uploads_[DATETIME].tar.gz wp-content/uploads/2026/
```

5. **Announce export completion**:
```bash
echo "[T-30m] Final database export completed. File size: $(ls -lh aupairhive_final_prod_export_*.sql | awk '{print $5}'). Checksum: $(cat export_checksum.txt | awk '{print $1}')" | slack-cli post -c #aupairhive-golive
```

**Verification**:
- [ ] Database exported successfully
- [ ] Export file size reasonable (10-50 MB)
- [ ] SQL syntax validated
- [ ] Checksum calculated and documented
- [ ] Incremental file uploads identified (if any)
- [ ] Export completion announced

---

### Task 9.5: T-15 Minutes - Import Final Data to PROD

**Time**: 15 minutes before DNS cutover
**Responsible**: Database Administrator + DevOps Engineer

**Steps**:

1. **Import final database to PROD**:
```bash
export AWS_PROFILE=Tebogo-prod

# Get PROD credentials
PROD_SECRET=$(aws secretsmanager get-secret-value \
    --secret-id bbws/prod/aupairhive/database \
    --query SecretString --output text)

PROD_HOST=$(echo $PROD_SECRET | jq -r '.host')
PROD_USER=$(echo $PROD_SECRET | jq -r '.username')
PROD_PASS=$(echo $PROD_SECRET | jq -r '.password')
PROD_DB=$(echo $PROD_SECRET | jq -r '.dbname')

# IMPORTANT: No URL replacement needed (keeping aupairhive.com)
# Import directly
mysql -h $PROD_HOST -u $PROD_USER -p$PROD_PASS $PROD_DB < aupairhive_final_prod_export_*.sql

echo "Database import completed at $(date)"
```

2. **Verify database import**:
```bash
# Check table count
TABLE_COUNT=$(mysql -h $PROD_HOST -u $PROD_USER -p$PROD_PASS $PROD_DB -e "SHOW TABLES;" | wc -l)
echo "Tables imported: $TABLE_COUNT"

# Check site URL (should be aupairhive.com, not wpdev or wpsit)
mysql -h $PROD_HOST -u $PROD_USER -p$PROD_PASS $PROD_DB -e \
    "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"

# Expected:
# siteurl  | https://aupairhive.com
# home     | https://aupairhive.com

# Check row counts
mysql -h $PROD_HOST -u $PROD_USER -p$PROD_PASS $PROD_DB -e \
    "SELECT
        (SELECT COUNT(*) FROM wp_posts WHERE post_status='publish') as published_posts,
        (SELECT COUNT(*) FROM wp_users) as users,
        (SELECT COUNT(*) FROM gf_entry) as form_entries;"
```

3. **Upload incremental files** (if any new uploads since SIT):
```bash
# If incremental uploads exist
if [ -f aupairhive_incremental_uploads_*.tar.gz ]; then
    # Upload to S3 staging
    aws s3 cp aupairhive_incremental_uploads_*.tar.gz \
        s3://bbws-prod-staging/aupairhive/incremental/

    # Deploy to EFS via ECS task
    aws ecs run-task \
        --cluster prod-cluster \
        --task-definition aupairhive-prod-task \
        --overrides '{
            "containerOverrides": [{
                "name": "wordpress",
                "command": ["sh", "-c", "aws s3 cp s3://bbws-prod-staging/aupairhive/incremental/aupairhive_incremental_uploads_*.tar.gz /tmp/ && tar xzf /tmp/aupairhive_incremental_uploads_*.tar.gz -C /var/www/html/ && chown -R www-data:www-data /var/www/html/wp-content/uploads/"]
            }]
        }' \
        --launch-type FARGATE

    echo "Incremental files uploaded"
fi
```

4. **Verify PROD site via CloudFront URL** (before DNS cutover):
```bash
# Get CloudFront domain
CF_DOMAIN=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID \
    --query 'Distribution.DomainName' --output text)

# Test via CloudFront (using Host header)
curl -H "Host: aupairhive.com" https://$CF_DOMAIN

# Or add to /etc/hosts temporarily for browser testing:
# [CloudFront IP] aupairhive.com

# Browser test checklist:
# - [ ] Homepage loads
# - [ ] Admin login works
# - [ ] One form displays
# - [ ] No 404 errors
```

5. **Announce import completion**:
```bash
echo "[T-15m] PROD database import completed. Tables: $TABLE_COUNT. Site verified via CloudFront. Ready for DNS cutover." | slack-cli post -c #aupairhive-golive
```

**Verification**:
- [ ] Database imported to PROD successfully
- [ ] Table count matches export
- [ ] Site URLs correct (aupairhive.com, not wpdev/wpsit)
- [ ] Row counts documented
- [ ] Incremental files uploaded (if applicable)
- [ ] PROD site tested via CloudFront URL
- [ ] Import completion announced

---

### Task 9.6: T-0 - DNS Cutover

**Time**: Scheduled cutover time
**Responsible**: DevOps Engineer

**CRITICAL SECTION - Triple-check before executing**

**Steps**:

1. **Final Go/No-Go decision**:
```bash
cat > final_go_no_go.txt <<EOF
=== FINAL GO/NO-GO DECISION ===
Time: $(date)

Checklist:
- [ ] PROD database imported and verified
- [ ] PROD site functional via CloudFront URL
- [ ] ECS service: 2 healthy tasks
- [ ] ALB targets: 2 healthy
- [ ] CloudFront: Deployed status
- [ ] Team consensus: GO
- [ ] Client approval: YES

Decision: [ ] GO  [ ] NO-GO

Authorized by:
- Technical Lead: _____________ Time: _______
- DevOps Engineer: _____________ Time: _______
- Client (if present): _____________ Time: _______

IF GO, PROCEED TO DNS CUTOVER
IF NO-GO, EXECUTE ROLLBACK PROCEDURE
EOF

# Wait for authorization
echo "Awaiting final GO authorization..."
```

2. **Lower DNS TTL** (if not already low):
```bash
# If TTL is still high (>300s), lower it first
# Wait for TTL to expire before proceeding

# Check current TTL
dig aupairhive.com | grep -A1 "ANSWER SECTION"

# If TTL >300, update in DNS registrar and wait
```

3. **Access DNS registrar**:
```bash
# Typically via web console:
# - Go to domain registrar (e.g., GoDaddy, Namecheap, etc.)
# - Login with credentials
# - Navigate to: Domains → aupairhive.com → DNS Management
```

4. **Document current DNS settings** (for rollback):
```bash
cat > current_dns_settings_backup.txt <<EOF
=== Current DNS Settings (Xneelo) ===
Date: $(date)

A Record:
Type: A
Host: @
Value: [Xneelo IP Address]
TTL: [Current TTL]

CNAME Record:
Type: CNAME
Host: www
Value: [Xneelo hostname]
TTL: [Current TTL]

Nameservers:
NS1: [Xneelo NS1]
NS2: [Xneelo NS2]

MX Records (if any):
[Document all MX records]

Other Records:
[Document TXT, SPF, DKIM records]
EOF
```

5. **Update DNS records to CloudFront**:

**CloudFront Distribution Domain**:
```bash
# Get CloudFront domain
echo "CloudFront Domain: $CF_DOMAIN"
# Example: d1234567890abc.cloudfront.net
```

**DNS Updates**:
```
=== NEW DNS SETTINGS ===

A Record (root domain):
Type: A
Host: @ (or aupairhive.com)
Value: (Delete - use CNAME below instead)

CNAME Record (root domain):
Type: CNAME
Host: @ (or aupairhive.com)
Value: d1234567890abc.cloudfront.net
TTL: 300 (5 minutes)

CNAME Record (www subdomain):
Type: CNAME
Host: www
Value: d1234567890abc.cloudfront.net
TTL: 300 (5 minutes)

IMPORTANT: Keep all other records (MX, TXT, SPF, DKIM) unchanged
```

**Alternative (if registrar doesn't support CNAME for root)**:
```
Use ALIAS record (if supported) or CloudFront IP addresses (not recommended)
```

6. **Execute DNS update**:
```bash
# In DNS registrar console:
# 1. Update @ record to CNAME pointing to CloudFront
# 2. Update www record to CNAME pointing to CloudFront
# 3. Set TTL to 300 seconds
# 4. Save changes

# SCREENSHOT THE CHANGES BEFORE SAVING!

# Save DNS changes
# Click "Save" or "Apply Changes"

# Note exact time of DNS update
echo "DNS updated at: $(date)" >> dns_cutover_log.txt
```

7. **Announce DNS cutover**:
```bash
echo "🚀 [T-0] DNS CUTOVER EXECUTED! DNS now points to CloudFront. Awaiting propagation..." | slack-cli post -c #aupairhive-golive
```

**Verification**:
- [ ] Final GO decision authorized
- [ ] Current DNS settings documented (for rollback)
- [ ] DNS records updated to CloudFront
- [ ] Changes saved in DNS registrar
- [ ] Screenshot of DNS changes captured
- [ ] DNS cutover time logged
- [ ] Cutover announced to team

---

### Task 9.7: T+5 Minutes - DNS Propagation and Initial Verification

**Time**: 5 minutes after DNS cutover
**Responsible**: Entire Team (distributed testing)

**Steps**:

1. **Monitor DNS propagation**:
```bash
# Check DNS resolution every 30 seconds
watch -n 30 "dig aupairhive.com +short"

# Expected progression:
# - Initially: Xneelo IP (old, cached)
# - After 2-5 min: CloudFront IPs (new)

# Check from multiple DNS servers
dig @8.8.8.8 aupairhive.com +short  # Google DNS
dig @1.1.1.1 aupairhive.com +short  # Cloudflare DNS
dig aupairhive.com +short            # Local DNS

# Check WWW subdomain
dig www.aupairhive.com +short
```

2. **Test site access** (distributed):
```bash
# Each team member tests from their location

# Technical Lead - Homepage
curl -I https://aupairhive.com
# Expected: HTTP 200, X-Cache: Hit from cloudfront (after first request)

# DevOps - Admin Panel
curl -I https://aupairhive.com/wp-admin
# Expected: HTTP 302 (redirect to login) or HTTP 200

# QA - Contact Page
curl -I https://aupairhive.com/contact/
# Expected: HTTP 200

# Database Admin - Database connectivity check
# (Already tested via WordPress loading)
```

3. **Browser testing** (visual verification):

**Technical Lead**:
- [ ] Navigate to https://aupairhive.com
- [ ] Homepage loads correctly
- [ ] Divi styling applied
- [ ] Navigation menu works

**QA Engineer**:
- [ ] Login to wp-admin
- [ ] Dashboard loads
- [ ] Go to: Forms → Entries
- [ ] Verify recent form entries exist

**Client** (if present):
- [ ] Navigate to homepage
- [ ] Visual verification
- [ ] Test one contact form submission

4. **Check CloudWatch metrics**:
```bash
# Check CloudFront requests
aws cloudwatch get-metric-statistics \
    --namespace AWS/CloudFront \
    --metric-name Requests \
    --dimensions Name=DistributionId,Value=$DISTRIBUTION_ID \
    --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Sum \
    --region us-east-1

# Expected: Requests count should start increasing

# Check for errors
aws cloudwatch get-metric-statistics \
    --namespace AWS/CloudFront \
    --metric-name 5xxErrorRate \
    --dimensions Name=DistributionId,Value=$DISTRIBUTION_ID \
    --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 60 \
    --statistics Average \
    --region us-east-1

# Expected: 5xxErrorRate = 0 or very low (<0.1%)
```

5. **Log test results**:
```bash
cat > initial_verification_results.txt <<EOF
=== Initial Verification Results (T+5min) ===
Time: $(date)

DNS Propagation:
- Google DNS (8.8.8.8): [CloudFront IP or Xneelo IP]
- Cloudflare DNS (1.1.1.1): [CloudFront IP or Xneelo IP]
- Local DNS: [CloudFront IP or Xneelo IP]

Site Accessibility:
- Homepage (HTTP): [200/other]
- Homepage (Visual): [PASS/FAIL]
- Admin Panel: [PASS/FAIL]
- Contact Form: [PASS/FAIL]

CloudFront Metrics:
- Requests (last 5 min): [count]
- 5xx Error Rate: [percentage]

Team Testing Status:
- Technical Lead: [PASS/FAIL]
- DevOps: [PASS/FAIL]
- QA: [PASS/FAIL]
- Client: [PASS/FAIL/N/A]

Overall Status: [GREEN/YELLOW/RED]
EOF

cat initial_verification_results.txt
```

**Verification**:
- [ ] DNS propagation in progress (may not be complete yet)
- [ ] Site accessible via https://aupairhive.com
- [ ] Homepage loads correctly
- [ ] Admin panel accessible
- [ ] CloudFront metrics showing traffic
- [ ] No critical errors (5xx)
- [ ] Test results logged

---

### Task 9.8: T+30 Minutes - Go/No-Go Decision Point

**Time**: 30 minutes after DNS cutover
**Responsible**: Technical Lead + Product Owner + Client

**Critical Decision Point**

**Steps**:

1. **Consolidate all test results**:
```bash
cat > t_plus_30_status_report.txt <<EOF
=== T+30 Minutes Status Report ===
Time: $(date)

DNS Propagation:
- Status: [COMPLETE/IN PROGRESS]
- Google DNS: [CloudFront IP]
- Cloudflare DNS: [CloudFront IP]
- Estimated full propagation: [time remaining]

Site Functionality:
- Homepage: [PASS/FAIL] - [notes]
- All Pages: [PASS/FAIL] - [notes]
- Contact Form: [PASS/FAIL] - [notes]
- Au Pair Application: [PASS/FAIL] - [notes]
- Host Family Application: [PASS/FAIL] - [notes]
- Admin Panel: [PASS/FAIL] - [notes]
- Divi Builder: [PASS/FAIL] - [notes]
- Gravity Forms Entries: [PASS/FAIL] - [notes]

Infrastructure Health:
- ECS Service: [running count] / 2 tasks
- ALB Healthy Targets: [count] / 2
- CloudFront Errors: [percentage]
- RDS Connections: [count]

Issues Found:
1. [Issue description] - Severity: [P0/P1/P2/P3]
2. [Issue description] - Severity: [P0/P1/P2/P3]

Client Feedback:
- [Client comments]

RECOMMENDATION: [ ] GO (Site is live, monitor)  [ ] NO-GO (Rollback required)
EOF

cat t_plus_30_status_report.txt
```

2. **Go/No-Go decision matrix**:
```bash
cat > go_no_go_decision_matrix.txt <<EOF
=== Go/No-Go Decision Matrix ===

GO Criteria (all must be YES):
- [ ] DNS propagation >50% complete
- [ ] Homepage loads successfully
- [ ] Admin panel accessible
- [ ] At least 2 forms functional
- [ ] No P0 (critical) issues
- [ ] ECS service healthy (2/2 tasks)
- [ ] ALB healthy targets (2/2)
- [ ] CloudFront 5xx error rate <1%
- [ ] Client approval (if present)

NO-GO Criteria (any triggers ROLLBACK):
- [ ] Site completely down (503/504 errors)
- [ ] Database connection failures
- [ ] Data loss detected
- [ ] Multiple P0 issues
- [ ] CloudFront 5xx error rate >5%
- [ ] Client requests rollback

Decision: [ ] GO  [ ] NO-GO

If GO: Announce success, continue monitoring (Task 9.9)
If NO-GO: Execute rollback procedure immediately (see prod_rollback_procedures.md)

Authorized By:
- Technical Lead: _________________ Time: _______
- Product Owner: _________________ Time: _______
- Client: _________________ Time: _______
EOF
```

3. **Make decision**:
```bash
# Technical Lead makes recommendation
echo "Technical Lead recommendation: [GO/NO-GO] based on status report"

# Product Owner confirms business readiness
echo "Product Owner confirms: [GO/NO-GO]"

# Client provides approval (if present)
echo "Client approval: [GO/NO-GO/Not Present]"

# FINAL DECISION
echo "=== FINAL DECISION: [GO/NO-GO] ==="
```

4. **If GO: Announce success**:
```bash
if [ "$DECISION" == "GO" ]; then
    cat > golive_success_announcement.txt <<EOF
🎉 AU PAIR HIVE GO-LIVE SUCCESSFUL! 🎉

Time: $(date)

The Au Pair Hive website has been successfully migrated to the new platform!

Site Status: LIVE ✅
URL: https://aupairhive.com
Infrastructure: AWS BBWS Platform (af-south-1)

Next Steps:
- Continue monitoring for 2 hours
- Address any P1/P2 issues
- Send client success notification
- Begin Phase 10: Post-Migration Monitoring

Thank you team! 🙌
EOF

    cat golive_success_announcement.txt
    slack-cli post -c #aupairhive-golive -f golive_success_announcement.txt

    # Send email to client
    mail -s "✅ Au Pair Hive Go-Live Successful" client@aupairhive.com < golive_success_announcement.txt
fi
```

5. **If NO-GO: Execute rollback**:
```bash
if [ "$DECISION" == "NO-GO" ]; then
    echo "❌ NO-GO DECISION: Initiating rollback procedure"
    echo "See: prod_rollback_procedures.md"

    # Immediate DNS rollback
    echo "Reverting DNS to Xneelo..."
    # (Manual in DNS registrar - revert to backed-up settings)

    # Notify stakeholders
    echo "ROLLBACK IN PROGRESS. Migration aborted due to critical issues." | slack-cli post -c #aupairhive-golive

    # Email client
    echo "Migration rollback initiated. Site returning to previous hosting. Details to follow." | mail -s "⚠️ Migration Rollback" client@aupairhive.com

    # Exit go-live process
    exit 1
fi
```

**Verification**:
- [ ] Status report consolidated
- [ ] All test results reviewed
- [ ] Go/No-Go criteria evaluated
- [ ] Decision authorized by stakeholders
- [ ] If GO: Success announced
- [ ] If NO-GO: Rollback initiated

---

### Task 9.9: T+30 to T+120 Minutes - Post-Launch Monitoring

**Time**: 30 minutes to 2 hours after DNS cutover
**Responsible**: DevOps Engineer + Technical Lead

**Continuous Monitoring Tasks**:

1. **Monitor CloudWatch Dashboard**:
```bash
# Open CloudWatch Dashboard in browser
# URL: https://console.aws.amazon.com/cloudwatch/dashboards/AuPairHive-PROD

# Watch metrics every 5 minutes:
# - ECS CPU/Memory utilization
# - ALB Healthy targets
# - RDS CPU/Connections
# - CloudFront Requests/Errors
```

2. **Monitor CloudWatch Alarms**:
```bash
# Check alarm status every 10 minutes
aws cloudwatch describe-alarms \
    --alarm-name-prefix aupairhive-prod \
    --query 'MetricAlarms[*].[AlarmName,StateValue]' \
    --output table

# Expected: All alarms in "OK" state
# If any alarm in "ALARM" state, investigate immediately
```

3. **Monitor CloudWatch Logs**:
```bash
# Tail WordPress container logs
aws logs tail /ecs/aupairhive-prod --follow --since 30m

# Look for:
# - PHP errors
# - Database connection errors
# - WordPress errors
# - HTTP 5xx errors
```

4. **Monitor form submissions**:
```bash
# Every 30 minutes, check for new form entries
# Login to wp-admin → Forms → Entries
# Verify entries are being recorded

# Check email notifications
# Verify notification emails being received
```

5. **Monitor DNS propagation completion**:
```bash
# Check DNS propagation every 15 minutes
dig aupairhive.com +short
dig www.aupairhive.com +short

# Use online tools:
# https://www.whatsmydns.net/#A/aupairhive.com

# Expected: 100% propagation within 1-2 hours
```

6. **Monitor site traffic**:
```bash
# Check CloudFront request count
aws cloudwatch get-metric-statistics \
    --namespace AWS/CloudFront \
    --metric-name Requests \
    --dimensions Name=DistributionId,Value=$DISTRIBUTION_ID \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Sum \
    --region us-east-1

# Compare to historical traffic (if available)
```

7. **Log monitoring observations**:
```bash
cat >> post_launch_monitoring_log.txt <<EOF
=== Monitoring Observation [$(date)] ===
ECS Tasks: [running count] / 2
ALB Healthy Targets: [count] / 2
CloudFront Requests (last 5 min): [count]
CloudFront 5xx Error Rate: [percentage]
RDS CPU: [percentage]
RDS Connections: [count]
CloudWatch Alarms: [OK/ALARM count]
DNS Propagation: [percentage]
Issues: [any new issues]

EOF
```

8. **Address P1/P2 issues** (if found):
```bash
# If non-critical issues found:
# - Document issue
# - Assess severity
# - Fix if possible without downtime
# - Or defer to post-launch (Phase 10)

cat >> issues_log.txt <<EOF
Issue ID: [ID]
Time: $(date)
Severity: [P1/P2/P3]
Description: [description]
Impact: [impact description]
Action Taken: [what was done]
Status: [OPEN/IN PROGRESS/RESOLVED]

EOF
```

**Hourly Status Updates**:
```bash
# T+60 minutes
cat > t_plus_60_status.txt <<EOF
=== T+60 Minutes Status ===
Time: $(date)

Overall Site Status: [GREEN/YELLOW/RED]
DNS Propagation: [percentage]
Traffic: [requests count]
Errors: [count]
Issues: [count P0/P1/P2/P3]
Team Status: [All monitoring/Stood down partially]

Next Check: T+90 minutes
EOF

# T+90 minutes
# [Similar status update]

# T+120 minutes (Final)
# [Final status update - prepare to hand off to Phase 10]
```

**Verification**:
- [ ] CloudWatch Dashboard monitored continuously
- [ ] CloudWatch Alarms in OK state
- [ ] CloudWatch Logs reviewed (no critical errors)
- [ ] Form submissions functional
- [ ] DNS propagation >90% complete
- [ ] Site traffic normal
- [ ] Hourly status updates logged
- [ ] Any P1/P2 issues addressed or documented

---

### Task 9.10: T+120 Minutes - Go-Live Completion and Handoff

**Time**: 2 hours after DNS cutover
**Responsible**: Technical Lead

**Steps**:

1. **Final status report**:
```bash
cat > final_golive_status_report.txt <<EOF
=== FINAL GO-LIVE STATUS REPORT ===
Date: $(date)
Migration: Au Pair Hive (Xneelo → BBWS Platform)

Timeline:
- Maintenance Mode Start: [time]
- Data Export Complete: [time]
- Data Import Complete: [time]
- DNS Cutover: [time]
- Go Decision: [time]
- Monitoring Complete: [time]
- Total Duration: [hours:minutes]

Infrastructure Status:
- ECS Service: [running count] / 2 tasks - HEALTHY ✅
- ALB Targets: [count] / 2 - HEALTHY ✅
- RDS Database: [status] - HEALTHY ✅
- CloudFront: [status] - HEALTHY ✅

Performance Metrics (Last 2 Hours):
- Total Requests: [count]
- Avg Response Time: [ms]
- Error Rate: [percentage]
- DNS Propagation: [percentage]

Issues Summary:
- P0 (Critical): [count] - [All resolved/Outstanding]
- P1 (High): [count] - [All resolved/Outstanding]
- P2 (Medium): [count] - [Resolved/Deferred to Phase 10]
- P3 (Low): [count] - [Deferred to Phase 10]

Client Feedback:
- [Client comments/approval]

MIGRATION STATUS: ✅ SUCCESSFUL

Next Steps:
1. Disable Xneelo maintenance mode (keep as backup for 7 days)
2. Send client success notification
3. Team stand down (except on-call engineer)
4. Begin Phase 10: Post-Migration Monitoring (24-48 hours)
5. Schedule post-launch review meeting

Completed By: [Technical Lead Name]
Verified By: [Product Owner Name]
Client Approval: [Client Name / N/A]
EOF

cat final_golive_status_report.txt
```

2. **Remove Xneelo maintenance mode** (but keep as backup):
```bash
# Access Xneelo cPanel
# - Disable maintenance mode plugin
# - OR remove .maintenance file
# - Keep site active as backup for 7 days

# Note: Site will not receive traffic (DNS points to BBWS)
# But accessible via direct Xneelo URL for emergency rollback
```

3. **Send client success notification**:
```bash
cat > client_success_email.txt <<EOF
Subject: ✅ Au Pair Hive Migration Complete - Site is Live!

Dear [Client Name],

Great news! The Au Pair Hive website migration has been completed successfully.

Migration Summary:
- Start Time: [time]
- Completion Time: [time]
- Total Downtime: [duration] (under 2 hours as planned)
- New Platform: AWS BBWS Multi-Tenant Platform
- Region: Cape Town, South Africa (af-south-1)

Your Site:
- URL: https://aupairhive.com (same URL, new infrastructure)
- Status: LIVE and fully functional ✅
- Performance: Improved (faster page loads, CloudFront CDN enabled)
- Security: Enhanced (SSL/TLS, encrypted storage, automatic backups)

What's New:
- ✅ Faster page load times (CloudFront CDN)
- ✅ Auto-scaling (handles traffic spikes automatically)
- ✅ Automated backups (daily)
- ✅ Enhanced security (encrypted database and file storage)
- ✅ 24/7 monitoring and alerting

Next Steps:
1. Please test your website and confirm everything works as expected
2. Report any issues to: technical-lead@kimmyai.io (24/7 support for next 48 hours)
3. We will monitor the site closely for the next 48 hours
4. A post-launch review meeting will be scheduled

What You Should Test:
- Browse all pages
- Submit a test contact form
- Check form entries in admin panel
- Test any recent content you added

Support:
- Technical Support: technical-lead@kimmyai.io / [Phone]
- On-Call Engineer: Available 24/7 for next 48 hours

Thank you for your patience during the migration. We're confident the new platform will serve you well!

Best regards,
[Technical Lead Name]
[Company Name]
EOF

# Send email
mail -s "✅ Au Pair Hive Migration Complete" client@aupairhive.com < client_success_email.txt
```

4. **Team stand down**:
```bash
echo "📢 GO-LIVE COMPLETE! Team may stand down. Thank you all for your hard work! 🎉" | slack-cli post -c #aupairhive-golive

echo "On-call engineer: [Name] - Please continue monitoring for next 24 hours." | slack-cli post -c #aupairhive-golive

echo "War room closing. See you at the post-launch review!" | slack-cli post -c #aupairhive-golive
```

5. **Schedule post-launch review meeting**:
```bash
# Send calendar invite
cat > post_launch_review_invite.txt <<EOF
Subject: Au Pair Hive - Post-Launch Review Meeting

Date: [Tomorrow or +2 days]
Time: [Time]
Duration: 1 hour

Attendees:
- Technical Lead
- DevOps Engineer
- Database Administrator
- QA Engineer
- Product Owner
- Client (optional)

Agenda:
1. Migration recap and timeline review
2. Issues encountered and resolutions
3. Performance metrics review
4. Lessons learned
5. Action items for Phase 10
6. Client feedback

Location: [Virtual meeting link]
EOF
```

6. **Handoff to Phase 10**:
```bash
cat > phase_10_handoff.txt <<EOF
=== HANDOFF TO PHASE 10: POST-MIGRATION MONITORING ===

Phase 9 Status: ✅ COMPLETE

Handoff Details:
- Go-Live Date/Time: $(date)
- Site Status: LIVE and HEALTHY
- DNS Propagation: [percentage]
- Outstanding Issues: [count P1/P2/P3]

Phase 10 Responsibilities:
- Monitor site for 48 hours (extended)
- Address any deferred P2/P3 issues
- Collect performance baseline data
- Monitor form submissions and email notifications
- Create final migration report
- Client satisfaction survey

On-Call Engineer: [Name]
Contact: [Phone] / [Email]

Phase 10 Documentation: 10_Post_Migration_Monitoring.md
EOF

cat phase_10_handoff.txt
```

**Verification**:
- [ ] Final status report completed
- [ ] Xneelo maintenance mode disabled (site kept as backup)
- [ ] Client success notification sent
- [ ] Team stood down from war room
- [ ] Post-launch review meeting scheduled
- [ ] Handoff to Phase 10 documented
- [ ] On-call engineer confirmed

---

## Verification Checklist

### Pre-Go-Live
- [ ] T-24h: PROD infrastructure health confirmed
- [ ] T-24h: Client notified (final reminder)
- [ ] T-2h: War room opened, team assembled
- [ ] T-2h: Final GO decision authorized
- [ ] T-1h: Xneelo maintenance mode enabled

### Data Migration
- [ ] T-30m: Final database exported from Xneelo
- [ ] T-30m: Export file verified (size, syntax, checksum)
- [ ] T-15m: Database imported to PROD
- [ ] T-15m: Import verified (table count, URLs, rows)
- [ ] T-15m: Incremental files uploaded (if any)
- [ ] T-15m: PROD site tested via CloudFront URL

### DNS Cutover
- [ ] T-0: Final GO decision confirmed
- [ ] T-0: Current DNS settings documented (for rollback)
- [ ] T-0: DNS updated to CloudFront
- [ ] T-0: DNS changes saved and logged
- [ ] T-0: DNS cutover announced

### Post-Cutover
- [ ] T+5m: DNS propagation monitored
- [ ] T+5m: Site accessible via aupairhive.com
- [ ] T+5m: Initial verification tests passed
- [ ] T+30m: Status report consolidated
- [ ] T+30m: GO decision confirmed (no rollback needed)
- [ ] T+30m: Success announced

### Monitoring
- [ ] T+30m to T+120m: Continuous monitoring
- [ ] CloudWatch Dashboard monitored
- [ ] CloudWatch Alarms in OK state
- [ ] Form submissions functional
- [ ] DNS propagation >90% complete
- [ ] Hourly status updates logged

### Completion
- [ ] T+120m: Final status report completed
- [ ] Xneelo maintenance mode disabled
- [ ] Client success notification sent
- [ ] Team stood down
- [ ] Post-launch review meeting scheduled
- [ ] Handoff to Phase 10 completed

---

## Success Criteria

- [ ] Site migrated successfully from Xneelo to BBWS platform
- [ ] DNS cutover executed without critical issues
- [ ] Downtime within 2-hour window
- [ ] Zero data loss
- [ ] All core functionality operational (homepage, forms, admin)
- [ ] GO decision confirmed at T+30m
- [ ] No rollback required
- [ ] Client approval obtained
- [ ] 2-hour monitoring period completed with no critical issues
- [ ] Handoff to Phase 10 (Post-Migration Monitoring)

**Definition of Done**:
Au Pair Hive website successfully migrated from Xneelo to BBWS platform. DNS cutover completed. Site live and functional. Client notified and satisfied. Team stood down. Phase 10 monitoring underway.

---

## Sign-Off

**Go-Live Date**: _________________
**Downtime Start**: _________________
**DNS Cutover**: _________________
**Go Decision**: _________________
**Monitoring Complete**: _________________
**Total Downtime**: _________________

**Authorized By**:
- **Technical Lead**: _________________ Date: _________
- **DevOps Engineer**: _________________ Date: _________
- **Product Owner**: _________________ Date: _________
- **Client Stakeholder**: _________________ Date: _________

**Migration Status**: [ ] SUCCESSFUL  [ ] ROLLED BACK

**Ready for Phase 10**: [ ] YES  [ ] NO

---

## Notes

**Issues Encountered**:
-
-

**Performance Metrics**:
- Downtime Duration: _________
- DNS Propagation Time: _________
- First Request After Cutover: _________

**Client Feedback**:
-
-

---

**Next Phase**: Proceed to **Phase 10**: `10_Post_Migration_Monitoring.md`
