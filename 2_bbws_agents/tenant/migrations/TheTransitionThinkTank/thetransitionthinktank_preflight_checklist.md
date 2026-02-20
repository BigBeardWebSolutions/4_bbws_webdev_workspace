# Pre-Migration Checklist: TheTransitionThinkTank

**Tenant**: thetransitionthinktank
**Source Domain**: thetransitionthinktank.org
**Target Domain (DEV)**: thetransitionthinktank.wpdev.kimmyai.io
**Total Size**: ~807MB (S3 staging required)
**Database Size**: ~134MB
**Date**: 2026-01-29

---

## Infrastructure Access

- [x] S3 bucket access verified from bastion (`wordpress-migration-temp-20250903`)
- [ ] Session Manager plugin installed locally
- [ ] CloudFront basic auth exclusion added for `thetransitionthinktank.wpdev.kimmyai.io`
- [ ] Bastion host started and accessible (`start-bastion.sh dev`)

## Database Preparation

- [x] Source database export obtained (`thetransitionthinktank.sql` - 134MB)
- [x] `prepare-wordpress-for-migration.sh` executed → `thetransitionthinktank-fixed.sql`
- [ ] Source database encoding verified (expect utf8mb4)
- [ ] Encoding fix SQL script ready (`database/fix-encoding.sql`)
- [x] URL replacement SQL covers ALL tables including Yoast (`database/url-replacement.sql`)
- [x] Problematic plugins identified: **Wordfence** (deactivated in fixed SQL)

## Files Preparation

- [x] wp-content packaged (`site/thetransitionthinktank-wp-content.tar.gz` - 209MB compressed)
- [ ] EFS access point created: `/thetransitionthinktank/wp-content`
- [ ] EFS access point path verified (must be `/thetransitionthinktank/wp-content`)
- [ ] Permissions script ready (chown 33:33)
- [x] Exclusions applied: `ai1wm-backups/`, `wflogs/`, `cache/`, `upgrade/`

## IAM & Secrets

- [ ] IAM inline policy added for tenant EFS access (`dev-ecs-efs-access-thetransitionthinktank`)
- [ ] Secrets Manager secret created (`dev-thetransitionthinktank-db-credentials`)
- [ ] Secrets Manager resource-based policy added for ECS execution role
- [ ] ECS task execution role can read secret

## ALB Configuration

- [ ] Target group created (`dev-thetransitionthinktank-tg`)
- [ ] Health check path set to `/`
- [ ] Health check matcher set to `200-302`
- [ ] ALB listener rule created with correct priority

## ECS Task Definition

- [x] Task definition template created (`thetransitionthinktank_task_definition.json`)
- [x] `WORDPRESS_CONFIG_EXTRA` configured with `$_SERVER['HTTPS'] = 'on'`
- [x] `WP_HOME` and `WP_SITEURL` set to `https://thetransitionthinktank.wpdev.kimmyai.io`
- [x] `WP_ENVIRONMENT_TYPE` set to `development`
- [x] Database credentials referenced from Secrets Manager
- [x] `WORDPRESS_TABLE_PREFIX` set to `wp_`
- [ ] EFS access point ID populated (replace `fsap-XXXXXXXXXXXXX`)

## Configuration

- [x] Third-party integrations documented (see integration inventory)
- [x] Domain-specific services identified:
  - Google Analytics 4: `G-YB6L23547D`
  - Google reCAPTCHA Enterprise: `6LdcztUrAAAAAFYgIqQ-BD8-LbHv59XEJBdaoWPW`
  - LinkedIn Insight Tag: present
  - Complianz GDPR: present
- [ ] WordPress admin credentials documented or reset plan ready
- [x] Problematic plugins deactivated in fixed SQL (Wordfence)

## Validation Preparation

- [ ] EFS HTTP verification commands ready
- [ ] Elementor template check SQL ready
- [ ] ECS redeployment command ready (for EFS mount issues)
- [ ] HTTPS redirect loop test ready

---

## Migration Execution Order

### Phase 1: Pre-Migration (DONE)
1. [x] Export site from Xneelo
2. [x] Run `prepare-wordpress-for-migration.sh`
3. [x] Package wp-content (excluding ai1wm-backups, wflogs)

### Phase 2: S3 Staging Upload
4. [ ] Upload `thetransitionthinktank-fixed.sql` to S3
5. [ ] Upload `thetransitionthinktank-wp-content.tar.gz` to S3

### Phase 3: DEV Environment Provisioning
6. [ ] Create tenant database in RDS
7. [ ] Store credentials in Secrets Manager
8. [ ] Create EFS access point (`/thetransitionthinktank/wp-content`)
9. [ ] Add IAM inline policy for EFS access
10. [ ] Add Secrets Manager resource-based policy
11. [ ] Register ECS task definition (update `fsap-XXXXXXXXXXXXX`)
12. [ ] Create ALB target group
13. [ ] Create ALB listener rule
14. [ ] Create ECS service
15. [ ] Add CloudFront basic auth exclusion

### Phase 4: Data Import
16. [ ] Start bastion, connect via SSM
17. [ ] Download from S3 to bastion
18. [ ] Import database: `mysql --default-character-set=utf8mb4 -h <RDS> -u <USER> -p <DB> < thetransitionthinktank-fixed.sql`
19. [ ] Run URL replacement: `mysql -h <RDS> -u <USER> -p <DB> < url-replacement.sql`
20. [ ] Check for encoding artifacts, run fix-encoding.sql if needed
21. [ ] Extract wp-content to EFS, fix permissions (chown -R 33:33)
22. [ ] Deploy force-https-cloudfront.php MU-plugin to EFS

### Phase 5: Post-Migration Validation
23. [ ] Verify ECS service running
24. [ ] Test homepage HTTP 200 (no redirect loop)
25. [ ] Verify static files (theme CSS, plugin JS)
26. [ ] Test WordPress admin login
27. [ ] Verify Elementor templates render correctly
28. [ ] Check encoding in post content
29. [ ] Verify forms (Gravity Forms + reCAPTCHA)
30. [ ] Verify Complianz cookie banner
31. [ ] Verify Ajax Search Lite

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Wordfence redirect loops | High | Critical | Fixed SQL deactivates Wordfence + force-https MU-plugin |
| Large DB import timeout | Medium | High | Use bastion t3a.medium, import from bastion directly |
| S3 upload timeout | Low | Medium | Use multipart upload for >500MB |
| EFS permission issues | Medium | High | chown -R 33:33 immediately after copy |
| Character encoding artifacts | Medium | Medium | fix-encoding.sql ready, import with utf8mb4 |
| Elementor Pro license | High | High | Re-register license on new domain post-migration |
| reCAPTCHA domain mismatch | High | Medium | Add new domain to Google reCAPTCHA console |
| LinkedIn tracking domain | Medium | Low | Update LinkedIn campaign settings |
