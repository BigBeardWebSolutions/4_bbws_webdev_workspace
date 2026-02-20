# Migration Plan: DEV Sites from nip.io to wpdev.kimmyai.io

**Date Created**: 2025-12-21
**Status**: Ready for Approval
**Pilot Migration**: ✅ Completed (goldencrust)
**Remaining**: 11 tenants

---

## Overview

Migrate remaining 11 DEV environment WordPress sites from nip.io wildcard DNS to proper subdomains under wpdev.kimmyai.io with SSL via CloudFront.

**Pattern**: `{tenant}.wpdev.kimmyai.io` (e.g., `goldencrust.wpdev.kimmyai.io`)
**Approach**: Automated batch migration using AWS CLI
**Method**: Python script to update ALB rules, task definitions, and ECS services
**SSL**: Existing CloudFront + ACM wildcard certificate

---

## Current State (2025-12-21)

### Infrastructure Verified ✅
- ✅ CloudFront distribution: E2W27HE3T7FRW4 (djooedduypbsr.cloudfront.net)
- ✅ ACM certificate: `*.wpdev.kimmyai.io` (ISSUED, us-east-1)
- ✅ Route 53: A record `*.wpdev.kimmyai.io` → CloudFront (WORKING)
- ✅ DNS, SSL, HTTPS all verified and working

### Migration Status (13 total tenants)

**COMPLETED (2):**
1. ✅ **goldencrust** (Priority 30) - DONE (Pilot migration successful)
2. ✅ **bbwstrustedservice** (Priority 50) - DONE (Already migrated)

**REMAINING (11):**
1. ❌ tenant-1 (Priority 10) - No Terraform file
2. ❌ tenant-2 (Priority 20) - Has custom WORDPRESS_CONFIG_EXTRA
3. ❌ sunsetbistro (Priority 31)
4. ❌ sterlinglaw (Priority 32)
5. ❌ ironpeak (Priority 33)
6. ❌ premierprop (Priority 34)
7. ❌ lenslight (Priority 35)
8. ❌ nexgentech (Priority 36)
9. ❌ serenity (Priority 37)
10. ❌ bloompetal (Priority 38)
11. ❌ precisionauto (Priority 39)

---

## Lessons Learned from Goldencrust Pilot

**What Worked:**
- ✅ AWS CLI approach bypassed Terraform backend issues
- ✅ Direct ALB rule modification via `aws elbv2 modify-rule`
- ✅ Task definition update via Python script (proper JSON handling)
- ✅ ECS service update with `--force-new-deployment`
- ✅ CloudFront, DNS, SSL all worked immediately

**Key Discoveries:**
- ⚠️ Terraform backend configured for SIT, not DEV
- ⚠️ Actual ALB priorities differ from Terraform code
- ⚠️ tenant-1 exists in AWS but has no Terraform file
- ✅ All WordPress sites need WP_HOME and WP_SITEURL for proper URL handling

---

## Implementation Approach

### Phase 1: Create Automated Migration Script

Create Python script `/Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform/scripts/migrate_tenant_to_wpdev.py`:

**Core Functionality:**

```python
import boto3
import json
import argparse
import time
from datetime import datetime

class TenantMigrator:
    def __init__(self, tenant, priority, cluster, region, profile, dry_run=False):
        # Initialize AWS clients (ECS, ELBv2)
        # Set instance variables

    def get_alb_listener_arn(self):
        # Get ALB for dev-cluster
        # Return HTTP listener ARN (port 80)

    def get_rule_arn_by_priority(self, listener_arn, priority):
        # Describe rules, find by priority
        # Return rule ARN

    def update_alb_rule(self, rule_arn):
        # Modify rule to use {tenant}.wpdev.kimmyai.io
        # Log changes

    def get_current_task_definition(self):
        # Describe task definition: dev-{tenant}
        # Return task definition JSON

    def update_task_definition(self, task_def):
        # Update WORDPRESS_CONFIG_EXTRA:
        #   - Set HTTPS detection
        #   - Set WP_HOME to https://{tenant}.wpdev.kimmyai.io
        #   - Set WP_SITEURL to https://{tenant}.wpdev.kimmyai.io
        # Register new task definition
        # Return new revision number

    def update_ecs_service(self, task_def_arn):
        # Update service: dev-{tenant}-service
        # Force new deployment
        # Wait for services-stable

    def test_migration(self):
        # Test DNS resolution
        # Test HTTPS via CloudFront (expect 401)
        # Test HTTP via ALB direct (expect 200)
        # Return test results

    def migrate(self):
        # Execute full migration workflow
        # Handle errors with rollback
        # Return migration report
```

**Parameters:**
- `--tenant`: Tenant name (e.g., "sunsetbistro")
- `--priority`: ALB listener rule priority (e.g., 31)
- `--cluster`: ECS cluster name (default: "dev-cluster")
- `--region`: AWS region (default: "eu-west-1")
- `--profile`: AWS profile (default: "Tebogo-dev")
- `--dry-run`: Preview changes without applying
- `--rollback`: Revert to nip.io configuration

**WordPress Config Template:**
```php
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}
if (isset($_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO']) && $_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}
define('FORCE_SSL_ADMIN', true);
define('WP_HOME', 'https://{tenant}.wpdev.kimmyai.io');
define('WP_SITEURL', 'https://{tenant}.wpdev.kimmyai.io');
```

---

### Phase 2: Execute Migration in Batches

**Batch Strategy:** Migrate 3-4 tenants at a time, validate, then proceed to next batch

#### Batch 1: Small Tenants (3 tenants)
```bash
# tenant-1, tenant-2, sunsetbistro
python3 scripts/migrate_tenant_to_wpdev.py --tenant tenant1 --priority 10
python3 scripts/migrate_tenant_to_wpdev.py --tenant tenant2 --priority 20
python3 scripts/migrate_tenant_to_wpdev.py --tenant sunsetbistro --priority 31
```

**Validation:**
- Test each site via curl and browser
- Check ECS service health in AWS Console
- Monitor CloudWatch logs for errors

#### Batch 2: Medium Tenants (4 tenants)
```bash
# sterlinglaw, ironpeak, premierprop, lenslight
python3 scripts/migrate_tenant_to_wpdev.py --tenant sterlinglaw --priority 32
python3 scripts/migrate_tenant_to_wpdev.py --tenant ironpeak --priority 33
python3 scripts/migrate_tenant_to_wpdev.py --tenant premierprop --priority 34
python3 scripts/migrate_tenant_to_wpdev.py --tenant lenslight --priority 35
```

**Validation:** Same as Batch 1

#### Batch 3: Final Tenants (4 tenants)
```bash
# nexgentech, serenity, bloompetal, precisionauto
python3 scripts/migrate_tenant_to_wpdev.py --tenant nexgentech --priority 36
python3 scripts/migrate_tenant_to_wpdev.py --tenant serenity --priority 37
python3 scripts/migrate_tenant_to_wpdev.py --tenant bloompetal --priority 38
python3 scripts/migrate_tenant_to_wpdev.py --tenant precisionauto --priority 39
```

**Validation:** Same as Batch 1

---

### Phase 3: Validation & Cleanup

**1. Comprehensive Testing**

```bash
# Test all 13 tenants
TENANTS="tenant1 tenant2 goldencrust sunsetbistro sterlinglaw ironpeak premierprop lenslight nexgentech serenity bloompetal precisionauto bbwstrustedservice"

for tenant in $TENANTS; do
  echo "Testing $tenant..."

  # DNS resolution
  dig +short ${tenant}.wpdev.kimmyai.io | head -1

  # HTTPS response (through CloudFront)
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://${tenant}.wpdev.kimmyai.io 2>&1)

  # Direct ALB test (bypassing CloudFront)
  ALB_DNS="dev-alb-875048671.eu-west-1.elb.amazonaws.com"
  ALB_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: ${tenant}.wpdev.kimmyai.io" http://${ALB_DNS}/ 2>&1)

  echo "  CloudFront: $HTTP_CODE | ALB: $ALB_CODE"
done
```

**2. Verify Terraform Files**

Update all `.tf` files to match the deployed state:
- Update `host_header` values to use `{tenant}.wpdev.kimmyai.io`
- Add WORDPRESS_CONFIG_EXTRA to all task definitions
- Update priorities to match actual ALB rules

**3. Remove nip.io References**

```bash
# Search for any remaining nip.io references
grep -rn "nip\.io" /Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform/terraform/*.tf

# Expected: Only commented-out or backup files
```

**4. Update Documentation**

- Update README with new URLs
- Document the migration process
- Create troubleshooting guide

---

## Risks & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **ALB rule update breaks tenant access** | High | Low | Non-destructive change; rollback in <1 min via AWS CLI |
| **Task definition update fails** | Medium | Low | Previous revision remains active; service continues running |
| **ECS service fails to stabilize** | High | Low | Automatic rollback to previous task definition after timeout |
| **WordPress URLs misconfigured** | Medium | Low | Test script validates WP_HOME/WP_SITEURL before next batch |
| **CloudFront caching issues** | Low | Medium | CloudFront basic auth bypasses cache; ALB serves fresh content |
| **Multiple tenants fail simultaneously** | High | Very Low | Batch approach limits blast radius to 3-4 tenants |
| **Terraform state drift** | Low | High | Accepted; update .tf files post-migration as documentation |
| **tenant-1 missing Terraform file** | Low | Certain | Migrate via AWS CLI only; document in README |

**Key Mitigations:**
1. **Batch Approach**: Limits impact to 3-4 tenants per batch
2. **Validation Between Batches**: Catch issues early before proceeding
3. **Non-Destructive Changes**: ALB rules can be reverted instantly
4. **Dry-Run Mode**: Test migrations without applying changes
5. **Automated Rollback**: Script includes rollback functionality

---

## Rollback Strategy

### Individual Tenant Rollback (using Python script)

```bash
# Add --rollback flag to migration script to revert to nip.io
python3 scripts/migrate_tenant_to_wpdev.py --tenant sunsetbistro --priority 31 --rollback

# Or manual rollback via AWS CLI:
TENANT="sunsetbistro"
PRIORITY=31
RULE_ARN=$(aws elbv2 describe-rules --listener-arn <LISTENER_ARN> --region eu-west-1 \
  --query "Rules[?Priority=='${PRIORITY}'].RuleArn" --output text)

# Revert ALB rule to nip.io
aws elbv2 modify-rule --rule-arn $RULE_ARN \
  --conditions '[{"Field":"host-header","HostHeaderConfig":{"Values":["'${TENANT}'.*.nip.io","'${TENANT}'.localhost","'${TENANT}'.*"]}}]' \
  --region eu-west-1

# Revert task definition (restore previous WordPress config)
# Force new ECS deployment
aws ecs update-service --cluster dev-cluster --service dev-${TENANT}-service --force-new-deployment --region eu-west-1
```

### Emergency Full Rollback

If multiple tenants fail, revert all at once using a rollback script that:
1. Reads the pre-migration ALB rules snapshot (saved before migration)
2. Restores all ALB rules to nip.io patterns
3. Reverts all task definitions to previous revisions
4. Forces new deployments for all affected services

**Note:** ALB rules are non-destructive - changing host_header doesn't affect existing connections.

---

## Timeline

- **Phase 1: Script Creation**: 2-3 hours
- **Phase 2: Batch Migrations**: 4-6 hours (3 batches × 1-2 hours)
- **Phase 3: Validation**: 1-2 hours

**Total Execution Time**: 7-11 hours (1-2 working days)
**Total Elapsed Time**: Can be spread over multiple days with validation checkpoints

---

## Critical Files

**Scripts to Create:**
1. **NEW**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform/scripts/migrate_tenant_to_wpdev.py` - Main migration automation
2. **NEW**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform/scripts/test_all_tenants.sh` - Validation script

**Terraform Files to Update (Post-Migration):**
3. `/Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform/terraform/tenant2.tf`
4. `/Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform/terraform/sunsetbistro.tf`
5. `/Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform/terraform/sterlinglaw.tf`
6. `/Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform/terraform/ironpeak.tf`
7. `/Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform/terraform/premierprop.tf`
8. `/Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform/terraform/lenslight.tf`
9. `/Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform/terraform/nexgentech.tf`
10. `/Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform/terraform/serenity.tf`
11. `/Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform/terraform/bloompetal.tf`
12. `/Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform/terraform/precisionauto.tf`

**Reference (Already Migrated):**
13. ✅ `/Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform/terraform/goldencrust.tf`
14. ✅ `/Users/tebogotseka/Documents/agentic_work/2_bbws_ecs_terraform/terraform/bbwstrustedservice.tf`

---

## Success Criteria

**Infrastructure:**
- ✅ All 13 tenants accessible via `https://{tenant}.wpdev.kimmyai.io`
- ✅ Valid SSL certificates (*.wpdev.kimmyai.io) for all tenants
- ✅ DNS resolving to CloudFront for all tenant subdomains
- ✅ CloudFront basic auth protecting all sites (HTTP 401)
- ✅ WordPress sites responding with HTTP 200 via ALB

**WordPress Configuration:**
- ✅ All WordPress sites have WP_HOME and WP_SITEURL properly configured
- ✅ All internal WordPress links use https://{tenant}.wpdev.kimmyai.io
- ✅ No mixed content warnings
- ✅ wp-admin accessible with correct URLs

**Code Quality:**
- ✅ No nip.io references in ALB listener rules
- ✅ Terraform files updated to match deployed state (documentation)
- ✅ Migration scripts committed to repository
- ✅ Rollback procedures tested and documented

**Validation:**
- ✅ All 11 migrated tenants tested and working
- ✅ No errors in ECS task logs
- ✅ No errors in CloudWatch logs
- ✅ ECS services stable and healthy

---

## Approval

**Plan Status**: ⏳ Awaiting Approval
**Reviewed By**: _____________
**Approved By**: _____________
**Date**: _____________

**Sign-off**: I approve this migration plan and authorize execution of the migration in accordance with the phased approach outlined above.

Signature: _______________________
