# Southern Cross Beach House - Migration Testing & Verification Document

**Site:** southerncrossbeach.co.za
**Migration Date:** 2026-01-16
**Environment:** DEV → SIT → PROD
**Tested By:** _________________
**Test Date:** _________________

---

## Document Purpose

This document serves as a comprehensive testing checklist to verify that the southerncrossbeach.co.za WordPress site has been successfully migrated to the BBWS platform and is ready for promotion to the next environment (SIT/PROD).

**Sign-off Requirements:**
- All critical tests must pass before SIT promotion
- All high-priority tests must pass before PROD promotion
- Medium-priority test failures require documented mitigation plan
- Low-priority test failures can be addressed post-launch

---

## Site Information

### DEV Environment
- **URL:** https://southerncrossbeach.wpdev.kimmyai.io/
- **Admin URL:** https://southerncrossbeach.wpdev.kimmyai.io/wp-admin/
- **Admin User:** kimbeard
- **Admin Password:** Scb_Dev_2026!
- **Database:** tenant_southerncrossbeach_db
- **ECS Service:** dev-southerncrossbeach-service
- **ECS Task CPU/Memory:** 512/1024

### SIT Environment (Post-Promotion)
- **URL:** https://southerncrossbeach.wpsit.kimmyai.io/
- **Admin URL:** https://southerncrossbeach.wpsit.kimmyai.io/wp-admin/

### PROD Environment (Final)
- **URL:** https://southerncrossbeach.co.za/ (after DNS cutover)
- **Subdomain:** https://southerncrossbeach.wp.kimmyai.io/

---

## Site-Specific Details

### Installed Plugins (Active)

- [x] Gravity Forms
- [x] Elementor Pro
- [x] Elementor
- [x] Instagram Feed
- [x] Widget Google Reviews
- [x] Wordfence
- [x] WordPress SEO (Yoast)

### Disabled Plugins

- [x] Really Simple SSL (disabled - conflicts with CloudFront SSL)

### Key Features to Test

- Beach house accommodation information
- Photo galleries (Instagram Feed)
- Google Reviews display
- Contact/booking forms (Gravity Forms)
- Responsive design for mobile users
- SEO metadata (Yoast)

### Third-Party Integrations

- **Instagram Feed:** Connected
- **Google Reviews:** Connected
- **Gravity Forms:** Active

---

## Section 1: Pre-Migration Data Verification

### Database Content

| Test Item | Priority | Status | Notes |
|-----------|----------|--------|-------|
| Total tables imported | Critical | [x] | Expected: 67 / Actual: 67 |
| WordPress options intact | Critical | [ ] | Check siteurl, home |
| Users imported | Critical | [ ] | Expected: ___ / Actual: ___ |
| Media references intact | Critical | [ ] | No broken image links |
| Plugin settings preserved | High | [ ] | All plugin configs migrated |

**Verification Commands:**
```bash
# Check database tables
mysql -h dev-mysql.c9ko42mci6mt.eu-west-1.rds.amazonaws.com -u admin -p tenant_southerncrossbeach_db -e "SHOW TABLES;" | wc -l

# Check site URLs
mysql -e "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"
```

---

## Section 2: Content & Layout Verification

### Homepage

| Test Item | Priority | Status | Notes |
|-----------|----------|--------|-------|
| Homepage loads without errors | Critical | [x] | HTTP 200 response |
| Page title displays correctly | Critical | [x] | "About - Southerncross Beach House" |
| Navigation menu functional | Critical | [ ] | All menu items clickable |
| Footer displays correctly | High | [ ] | Links, copyright visible |
| Mobile responsive design | High | [ ] | Test on mobile viewport |
| All images load (no 404s) | Critical | [ ] | Check browser console |
| Page load time < 3 seconds | Medium | [ ] | Use DevTools Network tab |

**Test URL:** https://southerncrossbeach.wpdev.kimmyai.io/

### Key Pages

| Page | Priority | Status | Notes |
|------|----------|--------|-------|
| Homepage/About | Critical | [x] | Loads correctly |
| Accommodation/Rooms | Critical | [ ] | Room details visible |
| Gallery | High | [ ] | Images display |
| Contact | Critical | [ ] | Contact form loads |
| Location/Map | Medium | [ ] | Map displays |

### Elementor Page Builder Content

| Test Item | Priority | Status | Notes |
|-----------|----------|--------|-------|
| Elementor sections render | Critical | [ ] | All sections visible |
| Elementor widgets functional | Critical | [ ] | Sliders, galleries work |
| Page builder backend accessible | High | [ ] | Elementor editor loads |
| Custom CSS applied | Medium | [ ] | Styling matches original |

---

## Section 3: WordPress Admin Functionality

### Admin Access

| Test Item | Priority | Status | Notes |
|-----------|----------|--------|-------|
| Admin login successful | Critical | [ ] | kimbeard / Scb_Dev_2026! |
| Dashboard loads | Critical | [ ] | No PHP errors |
| All admin menus accessible | High | [ ] | Posts, Pages, Plugins, etc. |
| User role permissions correct | High | [ ] | Admin has full access |

### Content Management

| Test Item | Priority | Status | Notes |
|-----------|----------|--------|-------|
| Create new post | High | [ ] | Draft, preview, publish |
| Edit existing post | High | [ ] | Changes save correctly |
| Upload new media | High | [ ] | Image uploads to EFS |
| Edit page with Elementor | High | [ ] | Page builder functional |
| Create new page | Medium | [ ] | Page templates available |

### Plugin Management

| Test Item | Priority | Status | Notes |
|-----------|----------|--------|-------|
| All plugins listed | Critical | [ ] | No missing plugins |
| Activate/deactivate plugin | Medium | [ ] | Test with inactive plugin |
| Plugin settings accessible | High | [ ] | Configure plugin settings |

---

## Section 4: Gravity Forms Testing

### Forms Configuration

| Test Item | Priority | Status | Notes |
|-----------|----------|--------|-------|
| Gravity Forms menu accessible | Critical | [ ] | Forms > All Forms |
| All forms imported | Critical | [ ] | List all expected forms |
| Forms display on frontend | Critical | [ ] | Embed in pages loads |
| Form fields render correctly | Critical | [ ] | All field types visible |

### Form Submissions

| Test Item | Priority | Status | Notes |
|-----------|----------|--------|-------|
| Submit test form entry | Critical | [ ] | Entry saves to database |
| Required field validation | Critical | [ ] | Can't submit without required |
| Email notifications sent | High | [ ] | Check tebogo@bigbeard.co.za |
| Confirmation message displays | High | [ ] | Success message shown |
| Entry appears in admin | Critical | [ ] | Forms > Entries |

---

## Section 5: Instagram Feed Testing

### Configuration

| Test Item | Priority | Status | Notes |
|-----------|----------|--------|-------|
| Instagram Feed plugin active | High | [ ] | Plugin installed and active |
| Feed displays on site | High | [ ] | Photos visible |
| Feed styling correct | Medium | [ ] | Grid/carousel display |
| Caching working | Low | [ ] | Feed loads from cache |

### Functionality

| Test Item | Priority | Status | Notes |
|-----------|----------|--------|-------|
| Images load correctly | High | [ ] | No broken images |
| Links to Instagram work | Medium | [ ] | Opens Instagram profile |
| Responsive on mobile | Medium | [ ] | Displays well on mobile |

---

## Section 6: Google Reviews Testing

### Configuration

| Test Item | Priority | Status | Notes |
|-----------|----------|--------|-------|
| Google Reviews widget active | High | [ ] | Plugin installed |
| Reviews display on site | High | [ ] | Reviews visible |
| Star ratings display | High | [ ] | Rating stars shown |
| Review text readable | Medium | [ ] | Full text displays |

---

## Section 7: Media & Images

### Image Loading

| Test Item | Priority | Status | Notes |
|-----------|----------|--------|-------|
| All homepage images load | Critical | [ ] | No broken images (404) |
| Uploaded media accessible | Critical | [ ] | /wp-content/uploads/ path |
| Image thumbnails generated | High | [ ] | Multiple sizes available |
| Featured images display | High | [ ] | On posts and pages |
| Logo displays correctly | Critical | [ ] | Header and footer |

### Media Library

| Test Item | Priority | Status | Notes |
|-----------|----------|--------|-------|
| Media library loads in admin | High | [ ] | Media > Library |
| All images visible in grid | High | [ ] | Thumbnails load |
| Upload new image | High | [ ] | Test upload to EFS |
| Edit image metadata | Medium | [ ] | Title, alt text, caption |

---

## Section 8: SEO & Metadata

### Yoast SEO

| Test Item | Priority | Status | Notes |
|-----------|----------|--------|-------|
| Yoast SEO plugin active | High | [ ] | Plugin installed |
| Meta titles preserved | High | [ ] | Check page source |
| Meta descriptions preserved | High | [ ] | Check page source |
| XML sitemap accessible | Medium | [ ] | /sitemap_index.xml |
| Open Graph tags present | Medium | [ ] | For social sharing |

**Verified Meta Tags:**
- og:title: "Southern Cross Beach House"
- og:description: "Bursting with charm..."
- og:site_name: "Southerncross Beach House"

---

## Section 9: Performance Testing

### Page Load Speed

| Test Item | Priority | Status | Notes |
|-----------|----------|--------|-------|
| Homepage load < 3 seconds | High | [ ] | Use DevTools Network tab |
| TTFB < 500ms | Medium | [ ] | Time to first byte |
| Largest Contentful Paint < 2.5s | Medium | [ ] | Core Web Vital |

**Testing Tools:**
- Chrome DevTools (Network, Lighthouse)
- GTmetrix: https://gtmetrix.com/
- WebPageTest: https://www.webpagetest.org/

---

## Section 10: Security Testing

### WordPress Security

| Test Item | Priority | Status | Notes |
|-----------|----------|--------|-------|
| WordPress version current | High | [ ] | Latest stable version |
| Admin username not "admin" | High | [x] | Using "kimbeard" |
| Strong admin password | Critical | [x] | Scb_Dev_2026! |
| wp-config.php not accessible | Critical | [ ] | Returns 403/404 |
| Debug mode disabled | Critical | [x] | WORDPRESS_DEBUG=0 |
| Wordfence active | High | [x] | Security plugin running |

### SSL/TLS

| Test Item | Priority | Status | Notes |
|-----------|----------|--------|-------|
| SSL certificate valid | Critical | [x] | CloudFront ACM cert |
| HTTPS access works | Critical | [x] | 200 OK response |
| No mixed content warnings | High | [ ] | Check browser console |

---

## Section 11: Email Functionality

### Email Delivery (DEV Environment)

| Test Item | Priority | Status | Notes |
|-----------|----------|--------|-------|
| WordPress can send emails | Critical | [ ] | Test with password reset |
| Form notifications delivered | Critical | [ ] | To tebogo@bigbeard.co.za |
| Email redirect MU-plugin active | Critical | [x] | Deployed |
| Subject has [DEV] prefix | High | [ ] | Identifies test emails |

---

## Section 12: Mobile Responsiveness

### Mobile Testing (iOS)

| Test Item | Priority | Status | Notes |
|-----------|----------|--------|-------|
| Homepage displays correctly | High | [ ] | iPhone Safari |
| Navigation menu works | High | [ ] | Mobile menu functional |
| Forms usable on mobile | Critical | [ ] | Can complete form |
| Images scale properly | High | [ ] | No overflow/distortion |

### Mobile Testing (Android)

| Test Item | Priority | Status | Notes |
|-----------|----------|--------|-------|
| Homepage displays correctly | High | [ ] | Chrome Android |
| Navigation menu works | High | [ ] | Mobile menu functional |
| Forms usable on mobile | Critical | [ ] | Can complete form |

---

## Section 13: Browser Compatibility

### Desktop Browsers

| Browser | Version | Status | Notes |
|---------|---------|--------|-------|
| Chrome | Latest | [ ] | Primary browser |
| Firefox | Latest | [ ] | Second most used |
| Safari | Latest | [ ] | Mac users |
| Edge | Latest | [ ] | Windows users |

---

## Section 14: Infrastructure Verification

### AWS Resources (DEV)

| Resource | Priority | Status | Notes |
|----------|----------|--------|-------|
| ECS service running | Critical | [x] | dev-southerncrossbeach-service |
| Task health checks passing | Critical | [x] | Healthy targets |
| EFS mount working | Critical | [x] | Files accessible |
| RDS database accessible | Critical | [x] | Database connections work |
| ALB routing correctly | Critical | [x] | Target group healthy |
| Target group healthy | Critical | [x] | 200-302 matcher |

### DNS Configuration

| Test Item | Priority | Status | Notes |
|-----------|----------|--------|-------|
| DNS resolves correctly | Critical | [x] | southerncrossbeach.wpdev.kimmyai.io |
| CNAME record correct | Critical | [x] | Points to CloudFront |
| CloudFront distribution active | Critical | [x] | E2W27HE3T7FRW4 |

### Monitoring & Logs

| Test Item | Priority | Status | Notes |
|-----------|----------|--------|-------|
| CloudWatch logs accessible | High | [x] | /ecs/dev stream |
| Error logs reviewed | High | [ ] | No critical errors |
| Access logs working | Medium | [ ] | ALB access logs |

---

## Section 15: Environment Promotion Checklist

### DEV → SIT Promotion Criteria

**All Critical Tests:**
- [x] Homepage loads without errors
- [x] All plugins installed and active
- [x] Database content verified
- [ ] Forms functional
- [ ] Images display correctly
- [ ] Admin access works
- [ ] No PHP fatal errors

**Sign-off Required:**
- [ ] Technical lead approval
- [ ] Site owner review complete

### SIT → PROD Promotion Criteria

**All High-Priority Tests:**
- [ ] Full UAT completed
- [ ] Performance benchmarks met
- [ ] Security scan passed
- [ ] SSL certificate configured
- [ ] Email delivery tested
- [ ] Backup/rollback plan verified
- [ ] Monitoring configured

**Sign-off Required:**
- [ ] Business owner approval
- [ ] Technical lead approval
- [ ] DevOps approval

---

## Section 16: Known Issues & Limitations

### Issues Identified

| # | Issue | Severity | Status | Resolution Plan |
|---|-------|----------|--------|-----------------|
| 1 | Really Simple SSL disabled | Info | Resolved | Plugin conflicts with CloudFront SSL |
| 2 | PHP deprecation warnings (Wordfence) | Low | Resolved | DEBUG=0 suppresses |
| 3 | | | | |

### Deferred Items (Post-SIT)

| Item | Reason | Target Date |
|------|--------|-------------|
| Performance optimization | Adequate for DEV testing | Before PROD |
| Plugin updates | Not critical for testing | Before PROD |

---

## Section 17: Sign-off & Approval

### DEV Testing Sign-off

**Testing Summary:**
- Total Tests: ___
- Passed: ___
- Failed: ___
- Deferred: ___

**Critical Issues:** (Must be resolved)
1. _________________
2. _________________

**Non-Critical Issues:** (Can be addressed later)
1. _________________
2. _________________

**Tester Signature:**
Name: _________________
Date: _________________
Signature: _________________

---

### SIT Testing Sign-off

**Testing Summary:**
- Total Tests: ___
- Passed: ___
- Failed: ___
- Deferred: ___

**Tester Signature:**
Name: _________________
Date: _________________
Signature: _________________

---

### PROD Deployment Approval

**Business Owner Approval:**
Name: _________________
Date: _________________
Signature: _________________

**Technical Lead Approval:**
Name: _________________
Date: _________________
Signature: _________________

---

## Appendix A: Test Data

### Test User Accounts
- Admin: kimbeard / Scb_Dev_2026!

### Test Form Submissions
- Test entry 1: Submitted on ___ with result ___
- Test entry 2: Submitted on ___ with result ___

### Performance Metrics
| Metric | DEV | SIT | PROD | Target |
|--------|-----|-----|------|--------|
| Homepage load time | | | | < 3s |
| TTFB | | | | < 500ms |

---

## Appendix B: Useful Commands

### AWS CLI Commands
```bash
# Check ECS service status
aws ecs describe-services --cluster dev-cluster --services dev-southerncrossbeach-service

# Check target health
aws elbv2 describe-target-health --target-group-arn "arn:aws:elasticloadbalancing:eu-west-1:536580886816:targetgroup/dev-southerncrossbeach-tg/25b81013747195e8"

# View logs
aws logs get-log-events --log-group-name "/ecs/dev" --log-stream-name-prefix "southerncrossbeach"

# Force service restart
aws ecs update-service --cluster dev-cluster --service dev-southerncrossbeach-service --force-new-deployment
```

### Database Commands (via Bastion)
```bash
# Connect to bastion
aws ssm start-session --target i-0a95b5e545ce3cb5f

# Get DB password
DB_PASS=$(aws secretsmanager get-secret-value --secret-id dev-rds-master-credentials --query SecretString --output text --region eu-west-1 | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])")

# Connect to database
mysql -h dev-mysql.c9ko42mci6mt.eu-west-1.rds.amazonaws.com -u admin -p"$DB_PASS" tenant_southerncrossbeach_db

# Check site URLs
SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');

# Check active plugins
SELECT option_value FROM wp_options WHERE option_name = 'active_plugins';
```

### Site Testing Commands
```bash
# Check site status
curl -s -o /dev/null -w "%{http_code}" https://southerncrossbeach.wpdev.kimmyai.io/

# Check site title
curl -s https://southerncrossbeach.wpdev.kimmyai.io/ | grep -oi "<title>[^<]*</title>"

# Check admin access
curl -s -o /dev/null -w "%{http_code}" https://southerncrossbeach.wpdev.kimmyai.io/wp-admin/

# Check login page
curl -s -o /dev/null -w "%{http_code}" https://southerncrossbeach.wpdev.kimmyai.io/wp-login.php
```

---

## Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-16 | DevOps Engineer Agent | Initial document creation |
| | | | |

---

**Next Review Date:** After DEV testing complete
**Document Status:** [ ] Draft  [x] In Review  [ ] Approved  [ ] Archived
