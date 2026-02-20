# WordPress Container Troubleshooting Skill

**Version**: 1.0
**Created**: 2024-12-21
**Extracted From**: tenant1 HTTP 500 troubleshooting during wpdev.kimmyai.io migration

---

## Purpose

Diagnose and resolve WordPress container failures in ECS, specifically PHP parse errors caused by buggy Docker images, custom entrypoint wrappers, and environment variable injection issues.

---

## Trigger Conditions

### When to Use
- WordPress containers returning HTTP 500 errors
- ECS tasks failing health checks repeatedly
- PHP parse errors in CloudWatch logs
- Containers showing "unexpected token" errors
- WordPress sites failing after task definition updates
- Migration-induced container failures

### User Invocation Examples
- "Troubleshoot tenant HTTP 500 error"
- "Debug WordPress container failing health checks"
- "Fix PHP parse error in ECS task"
- "Investigate why WordPress container keeps restarting"

---

## Input Requirements

**Required**:
- Tenant/service name with issue
- ECS cluster name
- AWS profile/region
- ALB DNS name (for direct testing)

**Optional**:
- CloudFront domain (for end-to-end testing)
- Specific task ARN (if known)
- Task definition revision number

**Preconditions**:
- AWS CLI access configured
- Appropriate IAM permissions for ECS, CloudWatch Logs, ECR
- Service is in ACTIVE state (even if unhealthy)

---

## Workflow

### Step 1: Identify the Failing Service
```bash
1. Check ECS service status
   aws ecs describe-services --cluster <cluster> --services <service>

2. Look for:
   - runningCount vs desiredCount mismatch
   - Recent deployment failures
   - Tasks stuck in PROVISIONING or failing health checks
```

### Step 2: Examine Task Failures
```bash
1. List running and stopped tasks
   aws ecs list-tasks --cluster <cluster> --service <service> --desired-status STOPPED

2. Describe failed tasks
   aws ecs describe-tasks --cluster <cluster> --tasks <task-arn>

3. Check for:
   - stopCode: EssentialContainerExited
   - stoppedReason: "Task failed ELB health checks"
   - Health check failure codes (500, 502, etc.)
```

### Step 3: Analyze Container Logs
```bash
1. Tail CloudWatch logs for the service
   aws logs tail /ecs/<env> --since 30m --filter-pattern "<tenant-name>"

2. Search for critical errors:
   - "PHP Parse error"
   - "syntax error, unexpected token"
   - "Fatal error"
   - "segmentation fault"

3. Note the specific error location (file and line number)
```

### Step 4: Compare Task Definitions
```bash
1. Get current task definition
   aws ecs describe-task-definition --task-definition <family>:<revision>

2. Compare with a working tenant's task definition

3. Check differences in:
   - Container image and imageDigest
   - Environment variables (especially WORDPRESS_CONFIG_EXTRA)
   - Volume mounts
   - Container entrypoint/command overrides
```

### Step 5: Inspect Docker Image
```bash
1. Identify which image is being used:
   - Custom ECR image: <account>.dkr.ecr.<region>.amazonaws.com/<repo>:tag
   - Official image: wordpress:latest

2. Check running task's actual image digest:
   aws ecs describe-tasks --cluster <cluster> --tasks <task-arn> \
     --query 'tasks[0].containers[0].{image:image,digest:imageDigest}'

3. Compare digests between working and failing tasks
```

### Step 6: Root Cause Analysis

**Common Issue: Buggy Custom Docker Image**

If using custom ECR image, check for:
- Custom entrypoint wrappers that modify wp-config.php
- Sed/awk commands that inject malformed PHP
- Duplicate PHP opening tags (`<?php <?php`)

**Example Bug Pattern**:
```bash
# In docker-entrypoint-wrapper.sh
sed -i '1a <?php require_once(...) ?>' /var/www/html/wp-config.php

# This creates duplicate <?php tags if file already starts with <?php
```

### Step 7: Implement Fix

**Solution A: Use Official WordPress Image**
```bash
1. Export current task definition
2. Modify image to "wordpress:latest"
3. Remove custom image references
4. Register new task definition
5. Update service with new revision
```

**Solution B: Fix Custom Docker Image**
```bash
1. Locate entrypoint wrapper in Docker image repo
2. Fix sed command to not inject duplicate PHP tags
3. Rebuild and push Docker image
4. Update task definition to use new image
5. Deploy updated service
```

### Step 8: Deploy and Validate
```bash
1. Register corrected task definition:
   aws ecs register-task-definition --cli-input-json file://taskdef.json

2. Update service:
   aws ecs update-service --cluster <cluster> \
     --service <service> \
     --task-definition <family>:<new-revision> \
     --force-new-deployment

3. Monitor deployment:
   - Watch for new tasks starting
   - Check logs for errors
   - Test health checks

4. Validate:
   - CloudFront HTTPS: curl -s -o /dev/null -w "%{http_code}" https://<tenant>.wpdev.kimmyai.io
     Expected: 401 (basic auth) or 200

   - ALB HTTP: curl -s -o /dev/null -w "%{http_code}" -H "Host: <tenant>.wpdev.kimmyai.io" http://<alb-dns>/
     Expected: 200 or 302
```

---

## Decision Logic

### If Multiple Tasks Are Failing
```
Check if they share the same task definition revision
→ YES: Issue is with task definition or image
→ NO: Infrastructure or network issue
```

### If Only One Tenant Failing
```
Compare task definitions between working and failing
→ Different images: Image issue
→ Same image, different digests: Image was updated, old tasks cached
→ Different environment vars: Configuration issue
```

### If Error is "PHP Parse error"
```
Check line number in error message
→ Line 2: Likely duplicate <?php tag from entrypoint wrapper
→ Other line: Check WORDPRESS_CONFIG_EXTRA syntax
```

### If Health Checks Fail with 500
```
1. Check container logs for application errors
2. Test direct container access (if possible)
3. Verify environment variables are set correctly
4. Check database connectivity
```

---

## Error Handling

### Cannot Access Container Logs
```
If: CloudWatch logs not available
Then:
  - Check log group exists (/ecs/<env>)
  - Verify task execution role has CloudWatch Logs permissions
  - Check log driver in task definition (should be awslogs)
```

### Task Immediately Fails on Start
```
If: Task exits within seconds
Then:
  - Check container command/entrypoint
  - Verify required environment variables exist
  - Check secrets manager access
  - Review task execution role permissions
```

### Service Won't Deploy New Revision
```
If: Service stuck deploying
Then:
  - Check task definition is valid
  - Verify ECR image is accessible
  - Check subnet/security group configuration
  - Review service events for specific errors
```

### ECS Waiter Timeouts
```
If: Waiter times out but service eventually deploys
Then:
  - This is often a false alarm
  - Verify service manually after timeout
  - Check if tasks pass health checks
  - Consider increasing waiter timeout or removing wait
```

---

## Success Criteria

Troubleshooting succeeds when:

1. **Root cause identified**: Specific error and cause documented
2. **Fix applied**: Task definition or image corrected
3. **Service healthy**: Tasks pass ALB health checks
4. **Validation passed**:
   - CloudFront HTTPS returns 401/200
   - ALB HTTP returns 200/302
5. **Stable deployment**: No task restarts after 5+ minutes
6. **Documentation updated**: Issue and fix recorded for future reference

---

## Common Root Causes & Solutions

### Issue 1: Custom Docker Image with Buggy Entrypoint

**Symptoms**:
- PHP Parse error: syntax error, unexpected token '<'
- Error on line 2 of wp-config.php
- Works with official image, fails with custom

**Root Cause**:
Custom entrypoint wrapper injects duplicate PHP tags:
```bash
# Bad
sed -i '1a <?php require_once(...) ?>' wp-config.php
# Creates: <?php\n<?php require_once(...) (duplicate tags)
```

**Solution**:
Switch to official WordPress image or fix entrypoint:
```bash
# Good
sed -i '2i require_once(...);' wp-config.php
# No PHP tags, inserted inside existing <?php block
```

### Issue 2: Malformed WORDPRESS_CONFIG_EXTRA

**Symptoms**:
- PHP syntax errors in wp-config.php
- Errors on various line numbers
- Cannot redeclare constant errors

**Root Cause**:
WORDPRESS_CONFIG_EXTRA has:
- Missing semicolons
- Unclosed braces/quotes
- HTML/XML instead of PHP
- Redeclared constants (WP_HOME, WP_SITEURL)

**Solution**:
```php
# Validate WORDPRESS_CONFIG_EXTRA syntax
# Good example:
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}
define('WP_HOME', 'https://tenant.domain.com');
define('WP_SITEURL', 'https://tenant.domain.com');
```

### Issue 3: Image Digest Mismatch

**Symptoms**:
- Task definition looks correct
- But containers use different image
- Inconsistent behavior across tasks

**Root Cause**:
- ECR image updated with same tag
- Old tasks cached old image digest
- New tasks pull new (possibly broken) image

**Solution**:
```bash
# Force pull latest image
aws ecs update-service --cluster <cluster> \
  --service <service> \
  --force-new-deployment

# Or use specific image digest in task definition
"image": "123456.dkr.ecr.region.amazonaws.com/repo@sha256:abc123..."
```

---

## Diagnostic Commands Reference

### Quick Health Check
```bash
# Service status
aws ecs describe-services --cluster dev-cluster --services dev-<tenant>-service \
  --query 'services[0].{desired:desiredCount,running:runningCount,pending:pendingCount}'

# Recent task failures
aws ecs list-tasks --cluster dev-cluster --service dev-<tenant>-service \
  --desired-status STOPPED | head -3

# Container logs (last 30 min)
aws logs tail /ecs/dev --since 30m --filter-pattern "<tenant>" | grep -i error
```

### Deep Dive
```bash
# Compare task definitions
diff <(aws ecs describe-task-definition --task-definition dev-tenant-1:3 | jq '.taskDefinition') \
     <(aws ecs describe-task-definition --task-definition dev-tenant-2:3 | jq '.taskDefinition')

# Check image digests
aws ecs describe-tasks --cluster dev-cluster --tasks <task-arn> \
  --query 'tasks[0].containers[0].{image:image,digest:imageDigest}'

# Environment variables
aws ecs describe-task-definition --task-definition dev-<tenant>:3 \
  --query 'taskDefinition.containerDefinitions[0].environment'
```

### Test Endpoints
```bash
# Via ALB (direct)
curl -v -H "Host: tenant.wpdev.kimmyai.io" http://dev-alb-<id>.eu-west-1.elb.amazonaws.com/

# Via CloudFront (HTTPS)
curl -v https://tenant.wpdev.kimmyai.io

# Expected responses:
# CloudFront: 401 (basic auth) or 200
# ALB: 200 or 302 (redirect to HTTPS)
```

---

## Real-World Example: tenant1 HTTP 500 Fix

### Problem
```
Tenant: tenant1
Error: HTTP 500
Logs: PHP Parse error: syntax error, unexpected token "<" on line 2
```

### Investigation
```bash
# 1. Checked task definition
aws ecs describe-task-definition --task-definition dev-tenant-1:3
# Found: Using custom ECR image

# 2. Compared with working tenant2
# Found: tenant2 using wordpress:latest (revision 1)
#        tenant2 revision 3 also has custom image but not deployed yet

# 3. Examined custom Docker image source
# Found: docker-entrypoint-wrapper.sh line 16 has buggy sed command
#        sed -i '1a <?php require_once(...) ?>' wp-config.php
#        This creates duplicate <?php tags
```

### Solution Applied
```bash
# 1. Export and modify task definition
aws ecs describe-task-definition --task-definition dev-tenant-1:3 > taskdef.json
jq 'del(.taskDefinition.taskDefinitionArn, .taskDefinition.revision, ...) |
    .taskDefinition.containerDefinitions[0].image = "wordpress:latest"' \
    taskdef.json > taskdef-fixed.json

# 2. Register new revision
aws ecs register-task-definition --cli-input-json file://taskdef-fixed.json
# Result: dev-tenant-1:4

# 3. Update service
aws ecs update-service --cluster dev-cluster \
  --service dev-tenant-1-service \
  --task-definition dev-tenant-1:4 \
  --force-new-deployment

# 4. Validate
curl -s -o /dev/null -w "%{http_code}" https://tenant1.wpdev.kimmyai.io
# Result: 401 ✅

curl -s -o /dev/null -w "%{http_code}" \
  -H "Host: tenant1.wpdev.kimmyai.io" \
  http://dev-alb-875048671.eu-west-1.elb.amazonaws.com/
# Result: 302 ✅
```

### Outcome
- tenant1 fully operational
- Issue documented in this skill
- Future tenants will use official image to avoid this bug

---

## Prevention Guidelines

### For Custom Docker Images
1. **Test thoroughly**: Deploy to DEV first, verify all tenants
2. **Avoid sed on generated files**: WordPress generates wp-config.php, don't modify it with sed
3. **Use includes**: If you need custom config, use `require_once()` instead of inline injection
4. **Validate PHP syntax**: Run `php -l wp-config.php` in container startup
5. **Version images**: Don't rely on `:latest`, use semantic versions or digests

### For Task Definitions
1. **Standardize**: Use Terraform modules for consistent task definitions
2. **Validate env vars**: Check WORDPRESS_CONFIG_EXTRA syntax before deploying
3. **Use revisions**: Never modify running task definitions, always create new revisions
4. **Test migrations**: Dry-run migrations with one tenant before batch operations

### For Deployments
1. **Monitor logs**: Watch CloudWatch during deployments
2. **Gradual rollout**: Deploy to 1-2 tenants first, validate, then batch
3. **Health checks**: Ensure ALB health checks are properly configured
4. **Rollback plan**: Keep previous task definition revision for quick rollback

---

## Related Skills

- ECS Service Deployment (DevOps Agent)
- Docker Image Building (DevOps Agent)
- Multi-Tenant Migration (DevOps Agent)
- CloudWatch Log Analysis (Monitoring Agent)

---

## Version History

- **v1.0** (2024-12-21): Initial skill extracted from tenant1 HTTP 500 troubleshooting session during wpdev.kimmyai.io migration
