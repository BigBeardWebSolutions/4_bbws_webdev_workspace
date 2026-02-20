# Access Management - Environment Promotion Runbook

**Document ID**: RUNBOOK-ACCESS-PROMOTION-001
**Version**: 1.0
**Last Updated**: 2026-01-25
**Owner**: DevOps Team
**Review Frequency**: Quarterly

---

## 1. Overview

### 1.1 Purpose
This runbook provides step-by-step procedures for promoting Access Management releases between environments: DEV → SIT → PROD.

### 1.2 Scope
- DEV to SIT promotion
- SIT to PROD promotion
- Version management
- Approval workflows

### 1.3 Promotion Flow

```
┌─────────┐    promote-to-sit    ┌─────────┐    promote-to-prod    ┌─────────┐
│   DEV   │ ──────────────────► │   SIT   │ ───────────────────► │  PROD   │
│ develop │                      │release/*│                       │  main   │
└─────────┘                      └─────────┘                       └─────────┘
     │                                │                                 │
     ▼                                ▼                                 ▼
  Automated                        Manual                            Manual
  on merge                       promotion                         promotion
                                 + UAT                            + approval
```

---

## 2. Prerequisites

### 2.1 Access Requirements

| Action | Required Permission | Approvers |
|--------|---------------------|-----------|
| Promote to SIT | GitHub Write | None |
| Promote to PROD | GitHub Write | 2 Approvers |
| Terraform Apply (PROD) | AWS Admin | Change Board |

### 2.2 Pre-Promotion Requirements

| Requirement | DEV → SIT | SIT → PROD |
|-------------|-----------|------------|
| All tests pass | ✅ | ✅ |
| Code review complete | ✅ | ✅ |
| Security scan pass | ✅ | ✅ |
| 24hr stability in source env | ✅ | ✅ |
| UAT complete | ❌ | ✅ |
| Change request approved | ❌ | ✅ |
| Rollback plan documented | ✅ | ✅ |

---

## 3. DEV to SIT Promotion

### 3.1 Pre-Promotion Checklist

- [ ] All unit tests pass (> 80% coverage)
- [ ] All integration tests pass in DEV
- [ ] No critical/high security vulnerabilities
- [ ] DEV deployment stable for 24+ hours
- [ ] No blocking bugs in DEV
- [ ] QA team notified of upcoming SIT release
- [ ] Release notes drafted

### 3.2 Promotion Procedure

#### Step 1: Verify DEV Stability

```bash
# Check recent deployments
gh run list --workflow=lambda-deploy-dev.yml --limit=5

# Check alarm status
aws cloudwatch describe-alarms \
  --alarm-name-prefix "bbws-access-dev" \
  --state-value ALARM \
  --query 'MetricAlarms[*].AlarmName'
# Expected: Empty list

# Check error rate (should be < 1%)
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=bbws-access-dev-lambda-* \
  --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 86400 \
  --statistics Sum
```

#### Step 2: Determine Version

```bash
# Get latest tag
git fetch --tags
git tag -l "v*" --sort=-version:refname | head -5

# Determine new version (semantic versioning)
# Major: Breaking changes
# Minor: New features
# Patch: Bug fixes

# Example: Current is v1.2.0, new feature release
NEW_VERSION="v1.3.0"
```

#### Step 3: Execute Promotion

```bash
# Trigger promotion workflow
gh workflow run promote-to-sit.yml \
  -f version=$NEW_VERSION \
  -f skip_tests=false

# Monitor workflow
gh run list --workflow=promote-to-sit.yml --limit=1
gh run watch $(gh run list --workflow=promote-to-sit.yml --limit=1 --json databaseId -q '.[0].databaseId')
```

#### Step 4: Verify SIT Deployment

```bash
# Run smoke tests
pytest tests/smoke/ -v --environment=sit

# Verify version deployed
aws ssm get-parameter \
  --name "/bbws-access/sit/deployed-version" \
  --query 'Parameter.Value' \
  --output text
# Expected: v1.3.0

# Check release branch exists
git branch -r | grep "release/$NEW_VERSION"
```

### 3.3 Post-Promotion Actions

1. **Notify QA Team**
   ```
   @qa-team SIT promotion complete
   Version: v1.3.0
   Release branch: release/v1.3.0
   Ready for UAT testing
   ```

2. **Update Tracking**
   - Update Jira tickets to "Ready for UAT"
   - Create draft GitHub release

3. **Monitor SIT**
   - Watch for errors in first 2 hours
   - Address any issues immediately

---

## 4. SIT to PROD Promotion

### 4.1 Pre-Promotion Checklist

- [ ] UAT testing complete and signed off
- [ ] All SIT tests pass
- [ ] Performance testing complete (if applicable)
- [ ] Security review complete
- [ ] Change request approved (CHG-XXXXX)
- [ ] Rollback plan documented and reviewed
- [ ] On-call engineer assigned
- [ ] Stakeholders notified of maintenance window
- [ ] DR verification complete

### 4.2 Change Request Requirements

| Field | Value |
|-------|-------|
| Change Type | Normal / Standard |
| Risk Level | Medium / High |
| Implementation Window | Off-peak hours |
| Rollback Time | < 30 minutes |
| Testing Plan | Smoke tests + health checks |
| Communication Plan | Slack #deployments |

### 4.3 Promotion Procedure

#### Step 1: Final Verification in SIT

```bash
# Verify SIT health
aws cloudwatch describe-alarms \
  --alarm-name-prefix "bbws-access-sit" \
  --state-value ALARM \
  --query 'MetricAlarms[*].AlarmName'
# Expected: Empty list

# Run full test suite
pytest tests/ -v --environment=sit --junitxml=sit-final-tests.xml

# Verify version
aws ssm get-parameter \
  --name "/bbws-access/sit/deployed-version" \
  --query 'Parameter.Value' \
  --output text
```

#### Step 2: Notify Stakeholders

```
:rotating_light: **PROD Deployment Starting**

Environment: PROD (af-south-1)
Version: v1.3.0
Change Request: CHG-12345
Window: 2026-01-25 22:00 - 23:00 UTC
On-Call: @oncall-engineer

Expected Impact: None (zero-downtime deployment)
Rollback Plan: Lambda alias rollback (< 5 min)
```

#### Step 3: Execute Promotion

```bash
# Trigger PROD promotion
gh workflow run promote-to-prod.yml \
  -f version=v1.3.0 \
  -f release_notes="Bug fixes and performance improvements"

# Wait for approval prompt in GitHub
echo "Waiting for approval in GitHub UI..."

# After approval, monitor deployment
gh run watch $(gh run list --workflow=promote-to-prod.yml --limit=1 --json databaseId -q '.[0].databaseId')
```

#### Step 4: Monitor Canary Deployment

```bash
# Canary deploys with 10% traffic for 5 minutes
# Monitor error rate during canary

aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=bbws-access-prod-lambda-* \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum

# If errors increase significantly, workflow will auto-fail
# Otherwise, traffic shifts to 100%
```

#### Step 5: Verify PROD Deployment

```bash
# Run smoke tests
pytest tests/smoke/ -v --environment=prod

# Verify version
aws ssm get-parameter \
  --name "/bbws-access/prod/deployed-version" \
  --region af-south-1 \
  --query 'Parameter.Value' \
  --output text

# Check all alarms OK
aws cloudwatch describe-alarms \
  --alarm-name-prefix "bbws-access-prod" \
  --state-value ALARM \
  --region af-south-1 \
  --query 'MetricAlarms[*].AlarmName'
```

### 4.4 Post-Promotion Actions

1. **Close Change Request**
   - Update status to "Implemented"
   - Document actual implementation time
   - Note any deviations

2. **Notify Stakeholders**
   ```
   :white_check_mark: **PROD Deployment Complete**

   Version: v1.3.0
   Duration: 18 minutes
   Status: SUCCESS

   All health checks pass.
   Change request CHG-12345 closed.
   ```

3. **Publish GitHub Release**
   - Finalize release notes
   - Publish (remove draft status)

4. **Monitor PROD**
   - Watch metrics for 2 hours post-deployment
   - Be ready for immediate rollback

---

## 5. Rollback Criteria

### 5.1 Automatic Rollback Triggers

| Condition | Action |
|-----------|--------|
| Error rate > 5% for 2 minutes | Auto-rollback |
| P95 latency > 3x baseline | Alert + manual decision |
| Canary health check fails | Auto-rollback |

### 5.2 Manual Rollback Triggers

Initiate rollback if:
- Critical functionality broken
- Data integrity issues detected
- Security vulnerability discovered
- Customer-impacting issues reported

### 5.3 Rollback Procedure

```bash
# Quick rollback command
gh workflow run rollback-lambda.yml \
  -f environment=prod \
  -f target_version=previous \
  -f services=all \
  -f reason="Post-deployment issues detected"
```

See **Rollback Runbook** for detailed procedures.

---

## 6. Version Management

### 6.1 Semantic Versioning

| Version Component | When to Increment | Example |
|-------------------|-------------------|---------|
| Major (X.0.0) | Breaking API changes | 1.0.0 → 2.0.0 |
| Minor (0.X.0) | New features, backward compatible | 1.2.0 → 1.3.0 |
| Patch (0.0.X) | Bug fixes only | 1.2.3 → 1.2.4 |

### 6.2 Branch Naming

| Branch | Environment | Example |
|--------|-------------|---------|
| `develop` | DEV | Always latest development |
| `release/vX.Y.Z` | SIT | `release/v1.3.0` |
| `main` | PROD | Production releases only |

### 6.3 Hotfix Procedure

For critical PROD issues:

```bash
# Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/v1.3.1

# Fix issue, commit, push
git add .
git commit -m "fix: critical bug description"
git push origin hotfix/v1.3.1

# Create PR to main (emergency approval)
gh pr create --base main --title "Hotfix: v1.3.1 - Critical fix"

# After merge, promote directly to PROD
gh workflow run promote-to-prod.yml -f version=v1.3.1

# Back-merge to develop
git checkout develop
git merge main
git push origin develop
```

---

## 7. Communication Templates

### 7.1 SIT Promotion Notification

```
:package: **SIT Promotion**

Version: v1.3.0
Source: DEV (develop)
Target: SIT (release/v1.3.0)
Initiated by: @username

Changes included:
- Feature A
- Bug fix B
- Enhancement C

QA Team: @qa-team - Ready for UAT
```

### 7.2 PROD Promotion Request

```
:warning: **PROD Promotion Request**

Version: v1.3.0
Change Request: CHG-12345
Proposed Window: 2026-01-25 22:00-23:00 UTC
Risk Level: Medium

Approvers Required: 2
- [ ] @approver1
- [ ] @approver2

Changes Summary:
- [List changes]

Rollback Plan: Lambda alias rollback (< 5 min)
```

---

## 8. Approval Matrix

| Environment | Approvers Required | Approval Method |
|-------------|-------------------|-----------------|
| DEV | 0 | Automatic |
| SIT | 0 | Manual trigger |
| PROD | 2 | GitHub Environment Protection |

### PROD Approvers

| Role | Approver |
|------|----------|
| Engineering Lead | @eng-lead |
| DevOps Lead | @devops-lead |
| QA Lead | @qa-lead |
| Product Owner | @product-owner |

---

## 9. Troubleshooting

### 9.1 Promotion Workflow Fails

| Error | Cause | Resolution |
|-------|-------|------------|
| "Branch already exists" | Release branch exists | Delete or use existing |
| "Tests failed" | Test failures in source env | Fix tests first |
| "Approval timeout" | No approval in 24 hours | Re-trigger workflow |
| "Terraform error" | Infrastructure issue | Check Terraform logs |

### 9.2 Rollback After Failed Promotion

```bash
# If SIT promotion fails mid-way
# SIT may be in inconsistent state

# 1. Check what was deployed
aws ssm get-parameter --name "/bbws-access/sit/deployed-version"

# 2. Rollback to previous version
gh workflow run rollback-lambda.yml \
  -f environment=sit \
  -f target_version=previous \
  -f services=all \
  -f reason="Promotion failed"

# 3. Delete failed release branch
git push origin --delete release/vX.Y.Z
```

---

## 10. Contacts

| Role | Contact | Availability |
|------|---------|--------------|
| Release Manager | @release-manager | Business hours |
| DevOps On-Call | PagerDuty | 24/7 |
| QA Lead | @qa-lead | Business hours |
| Change Board | #change-board | Weekly meetings |

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-25 | DevOps Team | Initial version |
