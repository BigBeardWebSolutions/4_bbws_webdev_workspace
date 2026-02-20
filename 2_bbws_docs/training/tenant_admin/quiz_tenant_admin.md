# Tenant Admin Knowledge Check Quiz

**Total Questions**: 20
**Passing Score**: 80% (16/20)
**Time Limit**: 1.5 hours
**Format**: Multiple choice + Practical demonstrations + Scenario analysis

---

## Section A: Tenant CRUD Operations (5 questions)

### Question 1: List Tenants
**Which AWS CLI command lists all tenant ECS services in a cluster?**

A) `aws ecs list-tasks --cluster sit-cluster`
B) `aws ecs list-services --cluster sit-cluster`
C) `aws ecs describe-clusters --clusters sit-cluster`
D) `aws ecs list-containers --cluster sit-cluster`

**Correct Answer**: B

---

### Question 2: Practical - Service Status
**DEMONSTRATE: Get the running and desired count for tenant-1-service. Provide screenshot.**

```bash
AWS_PROFILE=Tebogo-sit aws ecs describe-services \
  --cluster sit-cluster \
  --services tenant-1-service \
  --query 'services[0].{Running: runningCount, Desired: desiredCount}' \
  --region eu-west-1
```

---

### Question 3: Soft Delete vs Hard Delete
**What is the difference between soft delete and hard delete for a tenant?**

A) Soft delete removes the database; hard delete removes the ECS service
B) Soft delete sets desired count to 0; hard delete removes all resources
C) Soft delete pauses billing; hard delete stops billing
D) There is no difference

**Correct Answer**: B

---

### Question 4: Tenant Resource Order
**In what order should tenant resources be deleted during hard delete?**

A) Database → ECS Service → EFS → ALB → DNS
B) DNS → ALB → ECS Service → EFS → Database
C) ECS Service → ALB → DNS → EFS → Database
D) Any order is acceptable

**Correct Answer**: C

**Explanation**: Delete in reverse dependency order: stop traffic first (ECS, ALB, DNS), then remove storage (EFS), finally database.

---

### Question 5: Tenant Tags
**Which tags are REQUIRED on all tenant resources per BBWS standards?**

A) Name only
B) Environment and Name
C) tenant_id, Environment, Name
D) cost_center only

**Correct Answer**: C

---

## Section B: Tenant Suspension and Resumption (3 questions)

### Question 6: Suspension Methods
**Which method provides the FASTEST tenant suspension?**

A) DNS redirect to maintenance page
B) Set ECS service desired count to 0
C) Modify ALB listener rule to return 503
D) Revoke database credentials

**Correct Answer**: C

**Explanation**: ALB rule change takes effect immediately. ECS scale-down takes time for tasks to stop.

---

### Question 7: Practical - Suspend Tenant
**DEMONSTRATE: Suspend tenant-1 by setting desired count to 0. Provide screenshot.**

```bash
AWS_PROFILE=Tebogo-sit aws ecs update-service \
  --cluster sit-cluster \
  --service tenant-1-service \
  --desired-count 0 \
  --region eu-west-1
```

**Then verify:**
```bash
AWS_PROFILE=Tebogo-sit aws ecs describe-services \
  --cluster sit-cluster \
  --services tenant-1-service \
  --query 'services[0].{Running: runningCount, Desired: desiredCount}' \
  --region eu-west-1
```

---

### Question 8: Suspension State Tracking
**How should you track that a tenant has been suspended?**

A) Add a tag with key "suspended" and value "true"
B) Create a DynamoDB record
C) Update a spreadsheet
D) Rely on the desired count being 0

**Correct Answer**: A

**Explanation**: Tags provide a queryable, auditable way to track suspension state.

---

## Section C: Problem Diagnosis (4 questions)

### Question 9: Task Failure Diagnosis
**A tenant's ECS task keeps failing to start. What is the FIRST thing you should check?**

A) RDS database status
B) ECS service events
C) CloudWatch logs
D) Security group rules

**Correct Answer**: B

**Explanation**: Service events show the most recent status changes and error messages.

---

### Question 10: Practical - CloudWatch Logs
**DEMONSTRATE: Get the last 10 error log entries for tenant-1. Provide screenshot.**

```bash
AWS_PROFILE=Tebogo-sit aws logs filter-log-events \
  --log-group-name /ecs/sit \
  --log-stream-name-prefix tenant-1 \
  --filter-pattern "ERROR" \
  --limit 10 \
  --region eu-west-1
```

---

### Question 11: Health Check Failure
**An ALB target is showing "unhealthy". What are the possible causes? (Select all that apply)**

A) Task not responding on health check port
B) Health check path returns non-200 status
C) Security group blocking ALB to ECS communication
D) All of the above

**Correct Answer**: D

---

### Question 12: Database Connection Error
**A tenant shows "Error establishing database connection". What should you check FIRST?**

A) WordPress wp-config.php file
B) RDS instance status and connectivity
C) PHP memory limits
D) WordPress plugin conflicts

**Correct Answer**: B

**Explanation**: First verify the database is available before checking application-level issues.

---

## Section D: Security and Hijack Detection (5 questions)

### Question 13: Hijack Indicators
**Which of the following could indicate a tenant hijack? (Select all that apply)**

A) Multiple failed login attempts from unusual IPs
B) Unexpected admin user accounts created
C) DNS record pointing to unexpected target
D) All of the above

**Correct Answer**: D

---

### Question 14: DNS Hijack Detection
**DEMONSTRATE: Write a command to verify tenant-1's DNS is pointing to the correct CloudFront distribution.**

```bash
# Get current DNS target
dig +short tenant-1.wpsit.kimmyai.io

# Compare with expected (CloudFront domain)
# Expected: dxxxxxxxxx.cloudfront.net
```

---

### Question 15: Hijack Response - Step 1
**If you detect a potential tenant hijack, what should be your FIRST action?**

A) Notify the tenant
B) Isolate the tenant (suspend service)
C) Restore from backup
D) Change all passwords

**Correct Answer**: B

**Explanation**: ISOLATE first to prevent further damage, then investigate and remediate.

---

### Question 16: Scenario - Suspicious Activity
**SCENARIO: You notice tenant-1 has 50 failed login attempts from IPs in a country where the tenant has no business. The attempts occurred over 10 minutes. What actions should you take?**

Write your response including:
1. Immediate action
2. Investigation steps
3. Remediation
4. Prevention

**Expected Answer Points**:
1. **Immediate**: Review if attack succeeded, check for new admin accounts
2. **Investigation**: Check CloudWatch logs, review successful logins, audit user accounts
3. **Remediation**: If breached - suspend tenant, rotate credentials, restore from backup
4. **Prevention**: Enable 2FA, configure stricter rate limiting, implement geo-blocking

---

### Question 17: Credential Rotation
**After a security incident, which credentials should be rotated? (Select all that apply)**

A) Database credentials
B) WordPress admin passwords
C) AWS access keys (if exposed)
D) All of the above

**Correct Answer**: D

---

## Section E: Multi-Environment Operations (3 questions)

### Question 18: Environment Promotion
**When promoting a tenant from DEV to SIT, what must be updated in the database?**

A) User passwords
B) Site URLs (search-replace)
C) Plugin licenses
D) Nothing - it works automatically

**Correct Answer**: B

**Explanation**: WordPress stores absolute URLs in the database; these must be updated for the new environment.

---

### Question 19: Practical - Search Replace
**What WP-CLI command updates URLs when promoting from DEV to SIT?**

A) `wp db migrate wpdev.kimmyai.io wpsit.kimmyai.io`
B) `wp search-replace 'wpdev.kimmyai.io' 'wpsit.kimmyai.io' --all-tables`
C) `wp url update wpdev.kimmyai.io wpsit.kimmyai.io`
D) `wp config set siteurl wpsit.kimmyai.io`

**Correct Answer**: B

---

### Question 20: Promotion Validation
**After promoting tenant from DEV to SIT, which items should you validate? (Select all that apply)**

A) Site loads at new URL
B) All internal links work
C) Media files display correctly
D) Forms submit successfully
E) All of the above

**Correct Answer**: E

---

## Scenario-Based Questions

### Scenario 1: Complete Tenant Outage
**SCENARIO**: Tenant-2 reports their site is completely down. You investigate and find:
- ECS task status: STOPPED
- Stop reason: "Essential container in task exited"
- Exit code: 137

**Question**: What does exit code 137 indicate and what's your remediation?

**Expected Answer**:
- Exit code 137 = Out of Memory (OOMKilled)
- Remediation: Increase memory allocation in task definition
- Create new task definition revision with higher memory limit
- Update service to use new task definition

### Scenario 2: Suspected Hijack
**SCENARIO**: You receive an alert that tenant-3's DNS record was changed. Investigation shows:
- DNS now points to: 192.168.1.1 (instead of CloudFront)
- Change was made 2 hours ago
- No change request ticket exists

**Question**: Document your complete response following the hijack playbook.

**Expected Answer**:
1. **ISOLATE**: Suspend tenant service immediately
2. **CAPTURE**: Take EFS snapshot, database backup for forensics
3. **INVESTIGATE**:
   - Check CloudTrail for who made DNS change
   - Check Route53 change history
   - Review all tenant admin access
4. **REMEDIATE**:
   - Correct DNS record
   - Rotate all credentials
   - Review and revoke unauthorized access
5. **RESTORE**: If data compromised, restore from clean backup
6. **RESUME**: After verification, resume service
7. **DOCUMENT**: Create incident report

---

## Quiz Submission Requirements

### Practical Demonstration Evidence
Submit screenshots for:
- [ ] Question 2: Service Status
- [ ] Question 7: Suspend Tenant
- [ ] Question 10: CloudWatch Logs
- [ ] Question 14: DNS Verification

### Scenario Responses
Submit written responses for:
- [ ] Question 16: Suspicious Activity Response
- [ ] Scenario 1: Complete Tenant Outage
- [ ] Scenario 2: Suspected Hijack

### Scoring
| Section | Questions | Points |
|---------|-----------|--------|
| CRUD Operations | 5 | 25 |
| Suspension | 3 | 15 |
| Problem Diagnosis | 4 | 20 |
| Security & Hijack | 5 | 25 |
| Multi-Environment | 3 | 15 |
| **Total** | **20** | **100** |

### Passing Criteria
- Minimum 80% overall (16/20)
- All practical demonstrations must have valid screenshots
- Scenario responses must cover all required points
- Security section cannot score below 60%

---

## Answer Key

| Q# | Answer | Q# | Answer |
|----|--------|----|--------|
| 1 | B | 11 | D |
| 2 | Demo | 12 | B |
| 3 | B | 13 | D |
| 4 | C | 14 | Demo |
| 5 | C | 15 | B |
| 6 | C | 16 | Scenario |
| 7 | Demo | 17 | D |
| 8 | A | 18 | B |
| 9 | B | 19 | B |
| 10 | Demo | 20 | E |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-16 | Initial quiz with hijack detection scenarios |
