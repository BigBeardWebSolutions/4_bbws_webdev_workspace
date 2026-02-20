# Au Pair Hive Migration Plan
## Xneelo → BBWS Multi-Tenant WordPress Platform

**Site**: http://aupairhive.com/
**Migration Date**: TBD
**Target Environment**: DEV → SIT → PROD
**Estimated Total Time**: 4-6 hours (including testing)
**Created**: 2026-01-09

---

## Executive Summary

Migrate aupairhive.com from Xneelo shared hosting to BBWS multi-tenant WordPress platform on AWS ECS Fargate with:
- Zero data loss
- Minimal downtime (1-2 hours during DNS cutover)
- Full functionality preservation
- Performance improvement expected

---

## Site Analysis

### Current Setup (Xneelo)
- **Platform**: WordPress with Divi Theme 4.18.0
- **Complexity**: Moderate (service business site)
- **Key Features**:
  - Au pair placement matching service
  - Blog with recent content (July 2025)
  - Contact/application forms (Gravity Forms)
  - GDPR compliance (Cookie Law Info plugin)
  - Analytics (Facebook Pixel)
  - reCAPTCHA security

### Critical Components
1. **Premium Theme**: Divi by Elegant Themes (requires license)
2. **Premium Plugin**: Gravity Forms (requires license)
3. **Integrations**:
   - Facebook Pixel (tracking code)
   - reCAPTCHA (API keys)
   - Cookie Law Info (GDPR)
4. **Content Types**:
   - Pages (service descriptions, about, contact)
   - Blog posts (Au Pair Hive category)
   - Media library (images, possibly videos)
   - Forms (family/au pair applications)

### Estimated Sizes (to be confirmed during export)
- Database: ~50-200 MB (estimated)
- Files: ~500 MB - 2 GB (with media)
- Total: <2.5 GB

---

## Migration Strategy

### Phase 1: Preparation & Export (Xneelo)
**Duration**: 1-2 hours
**Responsible**: Site owner with provided instructions

1. Access Xneelo cPanel
2. Export WordPress database via phpMyAdmin
3. Download WordPress files via FTP/File Manager
4. Document current plugin licenses and API keys
5. Test backup integrity

### Phase 2: DEV Environment Setup
**Duration**: 15-30 minutes
**Responsible**: Tenant Manager Agent

1. Provision tenant 'aupairhive' in DEV environment
   - Tenant subdomain: aupairhive.wpdev.kimmyai.io
   - Database: tenant_aupairhive_db
   - ECS service with appropriate resources
2. Verify tenant isolation and health

### Phase 3: Data Import
**Duration**: 30-60 minutes
**Responsible**: Tenant Manager Agent + Manual verification

1. Import database with URL replacement:
   - Replace: http://aupairhive.com → https://aupairhive.wpdev.kimmyai.io
   - Replace: https://aupairhive.com → https://aupairhive.wpdev.kimmyai.io
   - Replace: http://www.aupairhive.com → https://aupairhive.wpdev.kimmyai.io
   - Replace: https://www.aupairhive.com → https://aupairhive.wpdev.kimmyai.io
2. Upload WordPress files to EFS
3. Regenerate wp-config.php with new database credentials
4. Update file permissions

### Phase 4: Configuration & Testing (DEV)
**Duration**: 2-3 hours
**Responsible**: Site owner + Tenant Manager Agent

1. **WordPress Configuration**:
   - Verify site URL settings
   - Reactivate plugins
   - Test Divi theme license
   - Test Gravity Forms license
   - Regenerate WordPress salts

2. **Plugin Reconfiguration**:
   - Reconnect Facebook Pixel
   - Reconfigure reCAPTCHA keys (if needed)
   - Test Cookie Law Info settings
   - Verify all forms work

3. **Functional Testing**:
   - [ ] Homepage loads correctly
   - [ ] Navigation menu works
   - [ ] All pages accessible
   - [ ] Blog posts display correctly
   - [ ] Images/media load
   - [ ] Contact forms submit successfully
   - [ ] Form validation works (reCAPTCHA)
   - [ ] Social media links work
   - [ ] Mobile responsive design
   - [ ] GDPR cookie banner displays

4. **Performance Testing**:
   - Page load times
   - Database query performance
   - Media delivery via CloudFront

5. **Security Validation**:
   - SSL certificate (CloudFront)
   - WordPress security hardening
   - Plugin/theme updates available

### Phase 5: SIT Environment Promotion
**Duration**: 30 minutes
**Responsible**: Tenant Manager Agent

1. Migrate tenant from DEV to SIT
2. Update subdomain: aupairhive.wpsit.kimmyai.io
3. Smoke test critical functionality
4. Performance benchmarking
5. User acceptance testing

### Phase 6: PROD Environment Deployment
**Duration**: 30 minutes
**Responsible**: Tenant Manager Agent

1. Migrate tenant from SIT to PROD
2. Subdomain: aupairhive.wp.kimmyai.io
3. Configure auto-scaling (2-3 tasks)
4. Enable production monitoring
5. Final pre-launch testing

### Phase 7: DNS Cutover
**Duration**: 1-2 hours (includes DNS propagation)
**Responsible**: Site owner + DevOps

**Pre-Cutover Checklist**:
- [ ] PROD site fully tested and approved
- [ ] Backup of live Xneelo site taken
- [ ] Downtime notification sent to users
- [ ] DNS TTL reduced to 300s (5 min) 24-48h before cutover

**Cutover Steps**:
1. Put Xneelo site in maintenance mode
2. Final database export from Xneelo
3. Import final changes to PROD
4. Update DNS records:
   - A record: aupairhive.com → CloudFront ALIAS
   - CNAME: www.aupairhive.com → CloudFront
5. Monitor DNS propagation
6. Verify site accessible via aupairhive.com
7. Remove maintenance mode
8. Monitor for issues

**Rollback Plan**:
- If critical issues: Revert DNS to Xneelo
- Keep Xneelo site active for 7 days as fallback

### Phase 8: Post-Migration
**Duration**: Ongoing
**Responsible**: Site owner + Monitoring

1. Monitor site performance (24-48 hours)
2. Check error logs
3. Verify form submissions
4. Monitor analytics (Facebook Pixel)
5. User feedback collection
6. Performance optimization if needed
7. Decommission Xneelo hosting (after 7-30 day grace period)

---

## Resource Requirements

### DEV Environment
- Task CPU: 256
- Task Memory: 512 MB
- Desired count: 1
- Database storage: 10 GB
- EFS storage: 5 GB allocated

### SIT Environment
- Task CPU: 512
- Task Memory: 1024 MB
- Desired count: 1
- Database storage: 20 GB

### PROD Environment
- Task CPU: 1024
- Task Memory: 2048 MB
- Desired count: 2-3 (auto-scaling enabled)
- Database storage: 50 GB
- Multi-AZ deployment

---

## Critical Dependencies

### Premium Licenses (REQUIRED)
1. **Divi Theme License**
   - Owner: Site owner
   - Action: Transfer license to new domain or purchase new
   - Timing: Before import

2. **Gravity Forms License**
   - Owner: Site owner
   - Action: Update authorized domain
   - Timing: Before form testing

### API Keys (REQUIRED)
1. **reCAPTCHA** (Google)
   - Current keys may work
   - May need to add new domain to authorized domains

2. **Facebook Pixel**
   - No changes needed (tracking code in theme)

### Domain & DNS Access
- Access to domain registrar
- Ability to modify DNS records
- Current nameserver information

---

## Risk Assessment

### High Risk Items
1. **Premium plugin licenses** - May need repurchase/transfer
2. **Custom Divi theme modifications** - Need to verify
3. **Gravity Forms data** - Form entries must migrate
4. **DNS propagation delays** - Plan for 1-2 hour window

### Mitigation Strategies
1. Test license activation in DEV first
2. Export Gravity Forms entries separately
3. Reduce DNS TTL 48h before cutover
4. Keep Xneelo site active as rollback option
5. Schedule migration during low-traffic period

### Success Criteria
- ✅ All pages load without errors
- ✅ All forms submit successfully
- ✅ All images/media display
- ✅ Premium plugins activated
- ✅ Page load time <3s
- ✅ Mobile responsive works
- ✅ SSL certificate valid
- ✅ Zero form submission failures
- ✅ Analytics tracking working

---

## Communication Plan

### Stakeholders
- Site owner/administrator
- End users (families, au pairs)
- Hosting provider (Xneelo → BBWS)

### Notifications
1. **T-7 days**: Pre-migration announcement
2. **T-48 hours**: Detailed migration schedule
3. **T-2 hours**: Maintenance window begins
4. **T+0**: Migration complete, site live
5. **T+24 hours**: Status update
6. **T+7 days**: Migration complete confirmation

### Downtime Window
- **Preferred**: Weekend evening (low traffic)
- **Duration**: 1-2 hours maximum
- **Fallback**: Weekday evening if weekend not possible

---

## Cost Estimate

### One-Time Costs
- Migration labor: Minimal (mostly automated)
- Testing time: 3-4 hours
- Potential license transfers: TBD (if needed)

### Ongoing Costs (PROD)
- ECS Fargate tasks: ~$30-50/month
- RDS database: Shared (minimal incremental)
- EFS storage: ~$0.30/GB/month
- Data transfer: Included in CloudFront
- **Estimated Total**: ~$35-60/month

### Cost Comparison
- Xneelo hosting: ~R200-500/month (to be confirmed)
- BBWS platform: More expensive but includes:
  - Auto-scaling
  - High availability
  - Better performance
  - Enterprise security
  - Managed infrastructure

---

## Next Steps

1. **Approve this migration plan**
2. **Schedule migration window** (preferred date/time)
3. **Gather Xneelo credentials** (cPanel, FTP)
4. **Verify premium licenses** (Divi, Gravity Forms)
5. **Export site from Xneelo** (using provided scripts)
6. **Begin DEV environment setup**

---

## Appendices

### A. Required Information from Site Owner
- [ ] Xneelo cPanel login URL
- [ ] Xneelo cPanel username/password
- [ ] FTP credentials (if different)
- [ ] Divi theme license key
- [ ] Gravity Forms license key
- [ ] Domain registrar access
- [ ] Current DNS settings export
- [ ] Preferred migration date/time
- [ ] Emergency contact during migration

### B. Export Scripts
See separate document: `xneelo_export_instructions.md`

### C. Testing Checklist
See separate document: `aupairhive_testing_checklist.md`

### D. Rollback Procedure
See Phase 7: DNS Cutover - Rollback Plan

---

**Plan Status**: DRAFT - PENDING APPROVAL
**Next Review**: Upon site owner confirmation
**Migration Owner**: Tenant Manager Agent
**Business Owner**: Au Pair Hive
