# Phase 5: Testing and Validation (DEV Environment)

**Phase**: 5 of 10
**Duration**: 2 days (16 hours)
**Responsible**: QA Engineer + WordPress Developer
**Environment**: DEV
**Dependencies**: Phase 4 (Data Import and Configuration) must be complete
**Status**: ⏳ NOT STARTED

---

## Phase Objectives

- Execute comprehensive testing using aupairhive_testing_checklist.md
- Verify all migrated content displays correctly
- Test all Gravity Forms submissions and notifications
- Validate Divi Builder functionality
- Test all integrations (reCAPTCHA, Facebook Pixel, SMTP)
- Perform performance and security baseline checks
- Test cross-browser and mobile responsiveness
- Document all defects and issues
- Fix P0/P1 defects before proceeding to SIT
- Sign off on DEV environment readiness

---

## Prerequisites

- [ ] Phase 4 completed: Database and files imported to DEV
- [ ] WordPress homepage accessible at https://aupairhive.wpdev.kimmyai.io
- [ ] Admin access functional
- [ ] Premium licenses activated (Divi, Gravity Forms)
- [ ] API keys configured (reCAPTCHA, Facebook Pixel, SMTP)
- [ ] aupairhive_testing_checklist.md available
- [ ] Browser testing tools installed (Chrome, Firefox, Safari, Edge)
- [ ] Mobile testing devices available (or browser DevTools)
- [ ] Performance testing tools ready (GTmetrix, PageSpeed Insights)

---

## Testing Strategy

**Testing Approach**: Structured testing following aupairhive_testing_checklist.md (127 test cases)

**Test Phases**:
1. Infrastructure Validation (Phase 1 of checklist)
2. Functional Testing (Phase 2 of checklist)
3. Theme and Plugin Testing (Phase 3 of checklist)
4. Integrations Testing (Phase 4 of checklist)
5. Performance Testing (Phase 5 of checklist)
6. Security Baseline (Phase 6 of checklist)
7. Mobile and Browser Testing (Phase 7 of checklist)
8. SEO Validation (Phase 8 of checklist)

**Defect Severity**:
- **P0 (Critical)**: Site down, data loss, cannot proceed - MUST FIX immediately
- **P1 (High)**: Major functionality broken - FIX before SIT promotion
- **P2 (Medium)**: Minor functionality issues - Can defer to SIT testing
- **P3 (Low)**: Cosmetic issues - Can defer to later phases

**Exit Criteria**: All P0 and P1 defects resolved, 90%+ test cases passed

---

## Detailed Tasks

### Task 5.1: Infrastructure Validation Testing

**Duration**: 2 hours
**Responsible**: DevOps Engineer + QA

**Reference**: aupairhive_testing_checklist.md → Phase 1: Infrastructure Validation (Tests 1-15)

**Key Tests**:

1. **Test DNS Resolution**:
```bash
# Test DNS lookup
nslookup aupairhive.wpdev.kimmyai.io
dig aupairhive.wpdev.kimmyai.io

# Expected: Should resolve to CloudFront distribution or ALB
```

2. **Test SSL/TLS Certificate**:
```bash
# Check SSL certificate
curl -vI https://aupairhive.wpdev.kimmyai.io 2>&1 | grep -i "certificate"

# Expected: Valid certificate (may be self-signed in DEV)
```

3. **Test HTTP to HTTPS Redirect**:
```bash
curl -I http://aupairhive.wpdev.kimmyai.io

# Expected: HTTP 301 redirect to https://
```

4. **Test ECS Service Health**:
```bash
export AWS_PROFILE=Tebogo-dev

aws ecs describe-services \
    --cluster dev-cluster \
    --services aupairhive-dev-service \
    --query 'services[0].[runningCount,desiredCount,healthCheckGracePeriodSeconds]'

# Expected: runningCount = desiredCount (1)
```

5. **Test ALB Target Health**:
```bash
# Get target group ARN
TG_ARN=$(aws elbv2 describe-target-groups \
    --query "TargetGroups[?contains(TargetGroupName, 'aupairhive')].TargetGroupArn" \
    --output text)

# Check target health
aws elbv2 describe-target-health --target-group-arn $TG_ARN

# Expected: HealthCheckState = "healthy"
```

6. **Test Database Connectivity**:
```bash
# Get credentials from Secrets Manager
DB_SECRET=$(aws secretsmanager get-secret-value \
    --secret-id bbws/dev/aupairhive/database \
    --query SecretString --output text)

DB_HOST=$(echo $DB_SECRET | jq -r '.host')
DB_USER=$(echo $DB_SECRET | jq -r '.username')
DB_PASS=$(echo $DB_SECRET | jq -r '.password')
DB_NAME=$(echo $DB_SECRET | jq -r '.dbname')

# Test connection
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME -e "SELECT 1;"

# Expected: Returns 1
```

7. **Test EFS Mount**:
```bash
# Check ECS task has EFS mounted
aws ecs describe-tasks \
    --cluster dev-cluster \
    --tasks $(aws ecs list-tasks --cluster dev-cluster --service aupairhive-dev-service --query 'taskArns[0]' --output text) \
    --query 'tasks[0].containers[0].mountPoints'

# Expected: Shows mount point for /var/www/html
```

**Test Results Documentation**:
```bash
cat > infrastructure_test_results.txt <<EOF
=== Infrastructure Validation Test Results ===
Date: $(date)
Environment: DEV
Tenant: aupairhive

DNS Resolution: [PASS/FAIL]
SSL Certificate: [PASS/FAIL]
HTTP Redirect: [PASS/FAIL]
ECS Service Health: [PASS/FAIL]
ALB Target Health: [PASS/FAIL]
Database Connectivity: [PASS/FAIL]
EFS Mount: [PASS/FAIL]

Issues Found:
-
-
EOF
```

**Verification**:
- [ ] DNS resolves correctly
- [ ] SSL certificate valid (or documented if self-signed)
- [ ] HTTP redirects to HTTPS
- [ ] ECS service running with desired count
- [ ] ALB target health is "healthy"
- [ ] Database connection successful
- [ ] EFS mounted on container
- [ ] All tests documented

---

### Task 5.2: Functional Testing - Content Verification

**Duration**: 3 hours
**Responsible**: QA Engineer

**Reference**: aupairhive_testing_checklist.md → Phase 2: Functional Testing (Tests 16-40)

**Key Tests**:

1. **Homepage Testing**:
- [ ] Homepage loads without errors (HTTP 200)
- [ ] Hero section displays with correct content
- [ ] Header logo displays
- [ ] Navigation menu shows all links
- [ ] Call-to-action buttons functional
- [ ] Footer displays contact information
- [ ] Social media icons link correctly

2. **Test All Pages**:
```bash
# Get list of all published pages
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME -e \
    "SELECT post_title, guid FROM wp_posts
     WHERE post_type='page' AND post_status='publish'
     ORDER BY post_title;" > pages_to_test.txt

# Test each page manually in browser
```

Pages to test:
- [ ] About Us
- [ ] Services / Programs
- [ ] Au Pair Application
- [ ] Host Family Application
- [ ] Contact Us
- [ ] FAQ
- [ ] Blog (if exists)
- [ ] Privacy Policy
- [ ] Terms of Service

3. **Test Blog Posts** (if applicable):
- [ ] Blog page displays all posts
- [ ] Individual posts load correctly
- [ ] Post images display
- [ ] Categories and tags functional
- [ ] Author information displays
- [ ] Comments section loads (if enabled)

4. **Test Navigation**:
- [ ] Main menu navigation works
- [ ] Footer navigation works
- [ ] Breadcrumbs display correctly
- [ ] Internal links functional
- [ ] External links open in new tab

5. **Test Images and Media**:
```bash
# Find all images in database
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME -e \
    "SELECT guid FROM wp_posts
     WHERE post_type='attachment' AND post_mime_type LIKE 'image%'
     LIMIT 20;" > images_to_test.txt

# Manually test image URLs in browser
```

- [ ] Header logo displays
- [ ] Featured images display on pages/posts
- [ ] Gallery images display
- [ ] Background images load
- [ ] No broken image placeholders (404s)

6. **Test Downloads** (if applicable):
- [ ] PDF downloads functional
- [ ] Document links work
- [ ] File download tracking works (if configured)

**Defect Tracking**:
```bash
cat > functional_test_defects.txt <<EOF
=== Functional Test Defects ===
Date: $(date)

ID | Severity | Page/Feature | Issue Description | Status
---|----------|--------------|-------------------|-------
1  | P1       | Contact Page | Form not loading  | OPEN
2  | P2       | About Page   | Image broken      | OPEN
EOF
```

**Verification**:
- [ ] All pages load successfully
- [ ] All navigation links functional
- [ ] Images display correctly (no 404s)
- [ ] Content displays as expected
- [ ] No critical defects (P0/P1) blocking progression
- [ ] Defects documented in tracking sheet

---

### Task 5.3: Gravity Forms Testing

**Duration**: 3 hours
**Responsible**: QA Engineer + WordPress Developer

**Reference**: aupairhive_testing_checklist.md → Phase 3: Theme and Plugins (Tests 41-65)

**Key Tests**:

1. **List All Forms**:
```bash
# Via WP-CLI in container
aws ecs execute-command \
    --cluster dev-cluster \
    --task $(aws ecs list-tasks --cluster dev-cluster --service aupairhive-dev-service --query 'taskArns[0]' --output text) \
    --container wordpress \
    --interactive \
    --command "wp gf form list --path=/var/www/html"

# Or via admin: Forms → Forms
```

Expected forms:
- [ ] Contact Form
- [ ] Au Pair Application Form
- [ ] Host Family Application Form
- [ ] Newsletter Signup Form
- [ ] Other forms...

2. **Test Each Form Functionality**:

**Contact Form Test**:
- Navigate to: https://aupairhive.wpdev.kimmyai.io/contact/
- Fill out form with test data:
  - Name: Test User
  - Email: testuser@example.com
  - Phone: +27 123 456 789
  - Message: This is a test submission from DEV environment
- Verify reCAPTCHA displays
- Complete reCAPTCHA
- Submit form
- **Expected**: Success message displays

**Au Pair Application Form Test**:
- Navigate to application page
- Fill out all required fields
- Upload test file (resume/photo)
- Submit form
- **Expected**: Success message, file uploaded

**Newsletter Signup Form Test**:
- Locate newsletter form (footer or sidebar)
- Enter test email: newsletter@example.com
- Submit
- **Expected**: Subscription confirmation

3. **Verify Form Submissions in Admin**:
- Go to: Forms → Entries
- Verify test submissions recorded
- Check all field data captured correctly
- Verify file uploads attached

4. **Test Email Notifications**:
```bash
# Check SMTP plugin logs
# Go to: WP Mail SMTP → Email Log
```

- [ ] Admin notification email received (check info@aupairhive.com inbox)
- [ ] User confirmation email received (check test email inbox)
- [ ] Email contains correct form data
- [ ] Email formatting correct (HTML vs plain text)

5. **Test Form Validations**:

**Required Fields**:
- Try submitting form with empty required fields
- **Expected**: Validation errors display

**Email Validation**:
- Enter invalid email: "notanemail"
- **Expected**: Error "Please enter a valid email"

**Phone Validation**:
- Enter invalid phone: "abcdef"
- **Expected**: Error "Please enter a valid phone number"

**File Upload Validation**:
- Try uploading file >10MB (if limit exists)
- **Expected**: Error "File too large"

6. **Test reCAPTCHA**:
- Submit form without completing reCAPTCHA
- **Expected**: Error "Please verify you are not a robot"

7. **Test Conditional Logic** (if forms have conditional fields):
- Trigger conditional field display
- Verify field shows/hides correctly
- Submit with different conditional paths

8. **Test Multi-Page Forms** (if applicable):
- Navigate between form pages
- Verify data persists across pages
- Test "Previous" and "Next" buttons
- Submit final page

**Form Testing Checklist**:
```bash
cat > gravity_forms_test_results.txt <<EOF
=== Gravity Forms Test Results ===

Form Name                  | Load | Submit | Email | Validation | reCAPTCHA | Status
---------------------------|------|--------|-------|------------|-----------|-------
Contact Form               | PASS | PASS   | PASS  | PASS       | PASS      | PASS
Au Pair Application        | PASS | FAIL   | N/A   | PASS       | PASS      | FAIL
Host Family Application    | PASS | PASS   | PASS  | PASS       | PASS      | PASS
Newsletter Signup          | PASS | PASS   | PASS  | PASS       | N/A       | PASS

Defects:
- Au Pair Application: File upload fails for files >5MB
- Contact Form: Email notification delay (3-5 minutes)
EOF
```

**Verification**:
- [ ] All forms load correctly
- [ ] All forms accept submissions
- [ ] Email notifications sent and received
- [ ] Required field validations work
- [ ] reCAPTCHA functional
- [ ] File uploads work (if applicable)
- [ ] Conditional logic works (if applicable)
- [ ] No P0/P1 defects

---

### Task 5.4: Divi Builder and Theme Testing

**Duration**: 2 hours
**Responsible**: WordPress Developer

**Reference**: aupairhive_testing_checklist.md → Phase 3: Theme and Plugins (Tests 41-65)

**Key Tests**:

1. **Test Divi Builder Access**:
- Go to: Pages → All Pages
- Click "Edit" on Homepage
- Click "Use The Divi Builder"
- **Expected**: Divi Builder loads without errors

2. **Test Divi Modules**:
- Verify all modules load in builder panel
- Test adding new module to page
- Test editing existing module
- Test module settings save correctly

3. **Test Divi Theme Options**:
- Go to: Divi → Theme Options
- Verify all tabs load (General, Navigation, Layout, SEO, etc.)
- Check logo upload works
- Check color scheme settings
- Verify changes save

4. **Test Visual Builder**:
- On homepage, click "Enable Visual Builder"
- **Expected**: Visual Builder toolbar appears
- Test inline editing of text
- Test drag-and-drop of modules
- Test saving changes
- Click "Exit Visual Builder"
- Verify changes persisted

5. **Test Divi Theme Customizer**:
- Go to: Appearance → Customize
- Test changing colors
- Test changing typography
- Test widget areas
- Test custom CSS (if used)
- Verify live preview works

6. **Test Responsive Design in Builder**:
- In Divi Builder, switch to Tablet view
- Verify layout adjusts correctly
- Switch to Phone view
- Verify mobile layout correct
- Test hiding elements on mobile (if configured)

7. **Test Divi Library** (saved layouts):
- Go to: Divi → Divi Library
- Verify saved layouts exist
- Test loading saved layout on new page
- Test exporting/importing layout (optional)

**Divi Testing Checklist**:
```bash
cat > divi_theme_test_results.txt <<EOF
=== Divi Theme Test Results ===

Feature                    | Status | Notes
---------------------------|--------|--------------------------------------
Divi Builder Access        | PASS   | Loads without errors
Visual Builder             | PASS   | Inline editing works
Divi Theme Options         | PASS   | All settings accessible
Divi Library               | PASS   | 5 saved layouts found
Module Editing             | PASS   | Settings save correctly
Responsive Design          | PASS   | Mobile layout correct
Theme Customizer           | PASS   | Live preview functional

Defects:
- None
EOF
```

**Verification**:
- [ ] Divi Builder loads and functions correctly
- [ ] Visual Builder accessible
- [ ] Theme Options save correctly
- [ ] Divi Library accessible
- [ ] Responsive design works
- [ ] No errors in builder interface
- [ ] No P0/P1 defects

---

### Task 5.5: Integrations Testing

**Duration**: 2 hours
**Responsible**: QA Engineer

**Reference**: aupairhive_testing_checklist.md → Phase 4: Integration Testing (Tests 66-80)

**Key Tests**:

1. **Test Google reCAPTCHA**:
- Submit form with reCAPTCHA
- Complete reCAPTCHA challenge
- Verify form submits successfully
- Check Gravity Forms entry shows reCAPTCHA score (if v3)

2. **Test Facebook Pixel Tracking**:
```bash
# Install Facebook Pixel Helper browser extension
# Navigate to homepage
# Check Pixel Helper icon
```

- [ ] Facebook Pixel detected on page
- [ ] PageView event fires
- [ ] FormSubmit event fires (if configured)
- [ ] Purchase event fires (if ecommerce)

3. **Test SMTP Email Delivery**:
- Send test email from: WP Mail SMTP → Email Test
- Check email arrives in inbox
- Verify sender name: "Au Pair Hive"
- Verify sender email: info@aupairhive.com
- Check email formatting (HTML)

4. **Test Google Analytics** (if integrated):
- Navigate to homepage
- Check browser DevTools → Network tab
- Look for Google Analytics requests (google-analytics.com or gtag)
- Verify tracking code fires

5. **Test Social Media Integrations**:
- Check social sharing buttons (if exists)
- Test Facebook share button
- Test Twitter share button
- Test LinkedIn share button
- Verify correct URL and metadata shared

6. **Test Third-Party Plugins**:
- List all active plugins via admin
- Test each plugin's functionality
- Verify plugin settings preserved from Xneelo

**Integration Testing Results**:
```bash
cat > integration_test_results.txt <<EOF
=== Integration Test Results ===

Integration              | Status | Notes
-------------------------|--------|--------------------------------------
Google reCAPTCHA v2      | PASS   | Works on all forms
Facebook Pixel           | PASS   | PageView and events tracked
SMTP Email (SendGrid)    | PASS   | Emails delivered in <1 minute
Google Analytics         | N/A    | Not configured
Social Sharing           | PASS   | Share buttons functional

Defects:
- None
EOF
```

**Verification**:
- [ ] reCAPTCHA functional on all forms
- [ ] Facebook Pixel tracking events
- [ ] SMTP email delivery working
- [ ] Google Analytics tracking (if applicable)
- [ ] Social sharing functional (if applicable)
- [ ] Third-party plugins functional
- [ ] No P0/P1 defects

---

### Task 5.6: Performance Baseline Testing

**Duration**: 2 hours
**Responsible**: DevOps Engineer + QA

**Reference**: aupairhive_testing_checklist.md → Phase 5: Performance Testing (Tests 81-95)

**Key Tests**:

1. **Test Page Load Time**:
```bash
# Use curl to measure load time
curl -o /dev/null -s -w "Time Total: %{time_total}s\n" https://aupairhive.wpdev.kimmyai.io

# Expected: <3 seconds for DEV environment
```

2. **Test with GTmetrix**:
- Navigate to: https://gtmetrix.com
- Enter URL: https://aupairhive.wpdev.kimmyai.io
- Run test
- **Target**: GTmetrix Grade B or higher, Load time <5s

3. **Test with Google PageSpeed Insights**:
- Navigate to: https://pagespeed.web.dev/
- Enter URL: https://aupairhive.wpdev.kimmyai.io
- Run test for Desktop and Mobile
- **Target**: Score >60 for DEV (higher in PROD)

4. **Test Database Query Performance**:
```bash
# Enable query monitoring (if not already enabled via WP_DEBUG)
# Or use Query Monitor plugin

# Check slow queries in database
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME -e "SHOW PROCESSLIST;"

# Expected: No queries running >1 second
```

5. **Test Image Optimization**:
- Navigate to homepage
- Open browser DevTools → Network tab
- Filter by "Img"
- Check image sizes
- **Expected**: Images <500KB, total page size <5MB

6. **Test Caching** (if caching plugin installed):
- Install browser extension: Cache Checker
- Visit homepage
- Check response headers for cache indicators
- **Expected**: X-Cache: HIT (if CloudFront enabled)

7. **Test Concurrent Users** (load testing):
```bash
# Use Apache Bench for simple load test
ab -n 100 -c 10 https://aupairhive.wpdev.kimmyai.io/

# Expected: No failed requests, avg response time <2s
```

**Performance Test Results**:
```bash
cat > performance_test_results.txt <<EOF
=== Performance Test Results ===
Date: $(date)
Environment: DEV

Metric                     | Result  | Target  | Status
---------------------------|---------|---------|-------
Homepage Load Time         | 2.8s    | <3s     | PASS
GTmetrix Grade             | B       | B+      | PASS
PageSpeed Score (Desktop)  | 72      | >60     | PASS
PageSpeed Score (Mobile)   | 58      | >60     | FAIL
Total Page Size            | 3.2 MB  | <5 MB   | PASS
Image Optimization         | Partial | Full    | WARN
Concurrent Users (10)      | 100/100 | 100/100 | PASS

Recommendations:
- Optimize mobile performance (enable lazy loading)
- Compress images further (use WebP format)
- Enable caching plugin (W3 Total Cache or WP Super Cache)
EOF
```

**Verification**:
- [ ] Homepage loads in <3 seconds
- [ ] GTmetrix score documented
- [ ] PageSpeed Insights score documented
- [ ] No slow database queries
- [ ] Image sizes reasonable
- [ ] Caching enabled (if applicable)
- [ ] Load test passed (no failures)
- [ ] Performance baseline documented

---

### Task 5.7: Security Baseline Validation

**Duration**: 1.5 hours
**Responsible**: Security Engineer / DevOps

**Reference**: aupairhive_testing_checklist.md → Phase 6: Security Testing (Tests 96-105)

**Key Tests**:

1. **Test SSL/TLS Configuration**:
```bash
# Use SSL Labs SSL Test
# Navigate to: https://www.ssllabs.com/ssltest/
# Enter: aupairhive.wpdev.kimmyai.io
# Target: Grade A (may be lower in DEV with self-signed cert)

# Or use testssl.sh
./testssl.sh https://aupairhive.wpdev.kimmyai.io
```

2. **Test WordPress Security Headers**:
```bash
curl -I https://aupairhive.wpdev.kimmyai.io | grep -E "X-Frame-Options|X-Content-Type-Options|X-XSS-Protection|Strict-Transport-Security"

# Expected headers:
# X-Frame-Options: SAMEORIGIN
# X-Content-Type-Options: nosniff
# X-XSS-Protection: 1; mode=block
```

3. **Test WordPress Version Disclosure**:
```bash
curl -s https://aupairhive.wpdev.kimmyai.io | grep "wp-includes"

# Expected: WordPress version NOT disclosed in meta tags
```

4. **Test Admin Access Control**:
- Try accessing wp-admin without login
- **Expected**: Redirect to login page
- Try common admin usernames: admin, administrator
- **Expected**: Do not disclose if username exists

5. **Test File Upload Security**:
- Try uploading malicious file (.php, .exe) via Media Library
- **Expected**: File type blocked or sanitized

6. **Test Database Security**:
```bash
# Verify database user has limited privileges (not root)
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -e "SHOW GRANTS FOR CURRENT_USER();"

# Expected: Grants only for tenant_aupairhive_db, not global
```

7. **Test Secrets Management**:
```bash
# Verify wp-config.php not accessible via web
curl -I https://aupairhive.wpdev.kimmyai.io/wp-config.php

# Expected: HTTP 403 Forbidden or 404 Not Found
```

8. **Run WPScan** (WordPress security scanner):
```bash
# Install WPScan: gem install wpscan
wpscan --url https://aupairhive.wpdev.kimmyai.io --enumerate u,p,t --api-token YOUR_API_TOKEN

# Review vulnerabilities found
```

**Security Test Results**:
```bash
cat > security_test_results.txt <<EOF
=== Security Test Results ===
Date: $(date)
Environment: DEV

Check                          | Status | Notes
-------------------------------|--------|----------------------------------
SSL/TLS Configuration          | PASS   | Grade A- (self-signed cert)
Security Headers               | WARN   | X-Frame-Options missing
WordPress Version Disclosure   | PASS   | Version hidden
Admin Access Control           | PASS   | Login required
File Upload Security           | PASS   | PHP files blocked
Database User Privileges       | PASS   | Limited to tenant DB only
wp-config.php Protection       | PASS   | Not accessible via web
WPScan Vulnerabilities         | WARN   | 2 plugin vulnerabilities found

Action Items:
- Add X-Frame-Options header via ALB
- Update plugins with known vulnerabilities
EOF
```

**Verification**:
- [ ] SSL/TLS configured correctly
- [ ] Security headers present
- [ ] WordPress version not disclosed
- [ ] Admin access restricted
- [ ] File uploads validated
- [ ] Database user has minimal privileges
- [ ] wp-config.php not accessible
- [ ] WPScan results documented
- [ ] No critical vulnerabilities (P0)

---

### Task 5.8: Mobile and Cross-Browser Testing

**Duration**: 2 hours
**Responsible**: QA Engineer

**Reference**: aupairhive_testing_checklist.md → Phase 7: Mobile and Browser Compatibility (Tests 106-115)

**Key Tests**:

1. **Desktop Browser Testing**:

**Chrome**:
- [ ] Homepage loads correctly
- [ ] Forms submit successfully
- [ ] Images display
- [ ] No console errors

**Firefox**:
- [ ] Homepage loads correctly
- [ ] Forms submit successfully
- [ ] CSS renders correctly
- [ ] No console errors

**Safari** (macOS):
- [ ] Homepage loads correctly
- [ ] Forms submit successfully
- [ ] Fonts render correctly
- [ ] No console errors

**Edge**:
- [ ] Homepage loads correctly
- [ ] Forms submit successfully
- [ ] No layout issues
- [ ] No console errors

2. **Mobile Browser Testing**:

**Chrome Mobile** (Android):
- [ ] Homepage loads and scrolls smoothly
- [ ] Navigation menu collapses to hamburger icon
- [ ] Forms fill out easily on mobile
- [ ] Tap targets adequate size
- [ ] No horizontal scrolling

**Safari Mobile** (iOS):
- [ ] Homepage loads and scrolls smoothly
- [ ] Navigation menu functional
- [ ] Forms functional
- [ ] Pinch to zoom works
- [ ] No layout issues

3. **Responsive Design Testing**:
```bash
# Use browser DevTools responsive mode
# Test common screen sizes:
# - 320px (iPhone SE)
# - 375px (iPhone 12)
# - 768px (iPad)
# - 1024px (iPad Pro)
# - 1920px (Desktop)
```

- [ ] 320px: Layout responsive, no horizontal scroll
- [ ] 375px: Content readable, images scale
- [ ] 768px: Tablet layout displays correctly
- [ ] 1024px: Desktop layout begins
- [ ] 1920px: Full desktop layout, no stretched content

4. **Touch Interaction Testing** (mobile devices):
- [ ] Tap buttons responsive
- [ ] Swipe gestures work
- [ ] Pinch to zoom functional
- [ ] Form fields focus correctly
- [ ] Virtual keyboard doesn't obscure form fields

**Browser Compatibility Matrix**:
```bash
cat > browser_compatibility_results.txt <<EOF
=== Browser Compatibility Test Results ===

Browser           | Version | Load | Forms | Images | CSS | JavaScript | Status
------------------|---------|------|-------|--------|-----|------------|-------
Chrome Desktop    | 120     | PASS | PASS  | PASS   | PASS| PASS       | PASS
Firefox Desktop   | 121     | PASS | PASS  | PASS   | PASS| PASS       | PASS
Safari Desktop    | 17      | PASS | PASS  | PASS   | WARN| PASS       | PASS
Edge Desktop      | 120     | PASS | PASS  | PASS   | PASS| PASS       | PASS
Chrome Mobile     | Android | PASS | PASS  | PASS   | PASS| PASS       | PASS
Safari Mobile     | iOS 17  | PASS | PASS  | PASS   | WARN| PASS       | PASS

Issues:
- Safari: Custom font rendering slightly different
- Safari Mobile: Form label positioning off by 2px

Responsive Breakpoints:
- 320px: PASS
- 375px: PASS
- 768px: PASS
- 1024px: PASS
- 1920px: PASS
EOF
```

**Verification**:
- [ ] All major desktop browsers tested
- [ ] Mobile browsers tested (iOS + Android)
- [ ] Responsive design works at all breakpoints
- [ ] No layout breaking issues
- [ ] Forms functional on all browsers
- [ ] Touch interactions work on mobile
- [ ] Compatibility matrix documented

---

### Task 5.9: SEO Validation

**Duration**: 1 hour
**Responsible**: SEO Specialist / QA

**Reference**: aupairhive_testing_checklist.md → Phase 8: SEO Validation (Tests 116-120)

**Key Tests**:

1. **Test Meta Tags**:
```bash
curl -s https://aupairhive.wpdev.kimmyai.io | grep -E "<title>|<meta name=\"description\"|<meta name=\"keywords\""
```

- [ ] Title tag exists and descriptive
- [ ] Meta description exists
- [ ] Open Graph tags exist (og:title, og:description, og:image)
- [ ] Twitter Card tags exist

2. **Test robots.txt**:
```bash
curl https://aupairhive.wpdev.kimmyai.io/robots.txt
```

**Expected for DEV**:
```
User-agent: *
Disallow: /
```
(Block all search engines in DEV environment)

3. **Test XML Sitemap** (if using SEO plugin):
```bash
curl -I https://aupairhive.wpdev.kimmyai.io/sitemap.xml

# Or via Yoast: /sitemap_index.xml
```

- [ ] Sitemap accessible
- [ ] Sitemap includes all pages
- [ ] Sitemap valid XML format

4. **Test Canonical URLs**:
```bash
curl -s https://aupairhive.wpdev.kimmyai.io | grep "<link rel=\"canonical\""
```

- [ ] Canonical tag exists
- [ ] Points to correct DEV URL

5. **Test Structured Data** (if implemented):
- Use Google Rich Results Test
- Enter URL: https://aupairhive.wpdev.kimmyai.io
- Check for schema.org markup (Organization, LocalBusiness, etc.)

6. **Test 404 Error Page**:
```bash
curl -I https://aupairhive.wpdev.kimmyai.io/page-that-does-not-exist
```

- [ ] Returns HTTP 404
- [ ] Custom 404 page displays (not generic server error)

**SEO Validation Results**:
```bash
cat > seo_validation_results.txt <<EOF
=== SEO Validation Results ===

Check                      | Status | Notes
---------------------------|--------|----------------------------------
Title Tags                 | PASS   | Present on all pages
Meta Descriptions          | PASS   | Present on all pages
Open Graph Tags            | PASS   | og:title, og:description, og:image
robots.txt                 | PASS   | Blocking search engines (DEV)
XML Sitemap                | PASS   | 15 pages indexed
Canonical URLs             | PASS   | Point to DEV domain
Structured Data            | N/A    | Not implemented
404 Page                   | PASS   | Custom 404 displays

Recommendations:
- Add structured data for LocalBusiness
- Update robots.txt for PROD (allow indexing)
EOF
```

**Verification**:
- [ ] Meta tags present on all pages
- [ ] robots.txt blocks search engines (DEV)
- [ ] XML sitemap accessible and valid
- [ ] Canonical URLs correct
- [ ] 404 page functional
- [ ] SEO baseline documented

---

### Task 5.10: Defect Triage and Remediation

**Duration**: Variable (depends on defects found)
**Responsible**: Entire Team

**Process**:

1. **Consolidate all defects**:
```bash
# Merge all defect logs into master defect tracker
cat infrastructure_test_results.txt \
    functional_test_defects.txt \
    gravity_forms_test_results.txt \
    divi_theme_test_results.txt \
    integration_test_results.txt \
    performance_test_results.txt \
    security_test_results.txt \
    browser_compatibility_results.txt \
    seo_validation_results.txt \
    > master_defect_tracker.txt
```

2. **Categorize defects by severity**:
```bash
cat > defect_triage.txt <<EOF
=== Defect Triage Summary ===
Date: $(date)

P0 (Critical - MUST FIX NOW):
- None

P1 (High - Fix before SIT):
- ID-042: Au Pair Application form file upload fails >5MB
- ID-087: Mobile PageSpeed score below target (58)

P2 (Medium - Can defer to SIT):
- ID-103: Safari font rendering slightly different
- ID-065: Email notification delay 3-5 minutes

P3 (Low - Can defer to later):
- ID-118: SEO structured data not implemented
- ID-091: Image optimization incomplete

Total Defects: 6
P0: 0 | P1: 2 | P2: 2 | P3: 2
EOF
```

3. **Fix P0 and P1 defects**:

**Fix P1-042: File upload limit**:
```bash
# Increase PHP upload limit in WordPress
# Edit wp-config.php or .htaccess
cat >> /var/www/html/.htaccess <<EOF
php_value upload_max_filesize 20M
php_value post_max_size 20M
EOF

# Or update Gravity Forms settings
# Forms → Settings → File Upload Size Limit → 20MB

# Retest file upload
```

**Fix P1-087: Mobile performance**:
```bash
# Install lazy loading plugin
wp plugin install a3-lazy-load --activate --path=/var/www/html

# Or enable native WordPress lazy loading (WP 5.5+)
# Already enabled by default

# Enable image compression plugin
wp plugin install ewww-image-optimizer --activate --path=/var/www/html

# Retest mobile PageSpeed score
```

4. **Retest after fixes**:
- Retest file upload with 15MB file
- Retest mobile PageSpeed score
- Update defect tracker with results

5. **Document deferred defects**:
```bash
cat > deferred_defects_sit.txt <<EOF
=== Defects Deferred to SIT ===

ID    | Severity | Description                        | Plan
------|----------|------------------------------------|-------------------
ID-103| P2       | Safari font rendering different    | Test in SIT
ID-065| P2       | Email delay 3-5 minutes            | Monitor in SIT
ID-118| P3       | SEO structured data missing        | Implement post-SIT
ID-091| P3       | Image optimization incomplete      | Optimize in batch
EOF
```

**Verification**:
- [ ] All defects cataloged and categorized
- [ ] All P0 defects resolved
- [ ] All P1 defects resolved
- [ ] P2/P3 defects documented for later phases
- [ ] Fixes verified via retesting

---

### Task 5.11: Final DEV Sign-Off

**Duration**: 1 hour
**Responsible**: Technical Lead + QA Lead

**Process**:

1. **Review all test results**:
```bash
ls -lh *_test_results.txt *_defects.txt

# Review each file for PASS/FAIL status
```

2. **Calculate test pass rate**:
```bash
cat > test_summary.txt <<EOF
=== DEV Testing Summary ===
Date: $(date)
Environment: DEV
Tenant: aupairhive

Test Phase                    | Total Tests | Passed | Failed | Pass Rate
------------------------------|-------------|--------|--------|----------
Infrastructure Validation     | 15          | 15     | 0      | 100%
Functional Testing            | 25          | 24     | 1      | 96%
Gravity Forms Testing         | 15          | 14     | 1      | 93%
Divi Theme Testing            | 10          | 10     | 0      | 100%
Integrations Testing          | 15          | 15     | 0      | 100%
Performance Testing           | 10          | 9      | 1      | 90%
Security Testing              | 10          | 10     | 0      | 100%
Browser Compatibility         | 12          | 12     | 0      | 100%
SEO Validation                | 5           | 5      | 0      | 100%
------------------------------|-------------|--------|--------|----------
TOTAL                         | 127         | 114    | 3      | 92%

Defect Summary:
- P0 (Critical): 0
- P1 (High): 0 (2 resolved)
- P2 (Medium): 2 (deferred to SIT)
- P3 (Low): 2 (deferred to later)

**DEV SIGN-OFF**: APPROVED
Ready for SIT Promotion: YES
EOF

cat test_summary.txt
```

3. **Obtain stakeholder approval**:
- Technical Lead reviews test summary
- QA Lead confirms all P0/P1 defects resolved
- Product Owner approves deferred defects acceptable
- DevOps confirms infrastructure stable

4. **Document lessons learned**:
```bash
cat > dev_lessons_learned.txt <<EOF
=== DEV Testing Lessons Learned ===

What Went Well:
- Database import script worked flawlessly
- Premium licenses activated without issues
- Infrastructure provisioning stable
- Most functionality migrated successfully

What Could Be Improved:
- File upload limits should be configured earlier
- Mobile performance optimization should be proactive
- Email notification delays need investigation
- More time needed for comprehensive testing

Recommendations for SIT:
- Increase file upload limit to 20MB from start
- Enable caching plugin before testing
- Monitor email delivery times closely
- Allocate 2.5 days for SIT testing (vs 2 days for DEV)
EOF
```

**Verification**:
- [ ] All test results reviewed
- [ ] Test pass rate >90%
- [ ] All P0/P1 defects resolved
- [ ] Stakeholder approval obtained
- [ ] Lessons learned documented
- [ ] DEV sign-off recorded

---

## Verification Checklist

### Testing Completion
- [ ] Infrastructure validation: 100% tests passed
- [ ] Functional testing: >90% tests passed
- [ ] Gravity Forms testing: All forms functional
- [ ] Divi Builder testing: Builder functional
- [ ] Integrations testing: All integrations working
- [ ] Performance testing: Baseline documented
- [ ] Security testing: No critical vulnerabilities
- [ ] Browser compatibility: All major browsers tested
- [ ] SEO validation: Baseline documented

### Defect Management
- [ ] All defects cataloged and categorized
- [ ] All P0 (Critical) defects resolved
- [ ] All P1 (High) defects resolved
- [ ] P2/P3 defects documented for later phases

### Documentation
- [ ] Test results documented for all phases
- [ ] Performance baseline recorded
- [ ] Security baseline recorded
- [ ] Browser compatibility matrix complete
- [ ] Defect tracker maintained
- [ ] Lessons learned documented

### Sign-Off
- [ ] Technical Lead approval
- [ ] QA Lead approval
- [ ] Product Owner approval (for deferred defects)
- [ ] DevOps confirmation (infrastructure stable)
- [ ] Ready for Phase 6 (SIT Promotion)

---

## Rollback Procedure

If testing reveals critical defects that cannot be resolved:

1. **Document root cause** of critical defect
2. **Rollback to Phase 4** (re-import database/files if corruption suspected)
3. **Fix root cause** in export data or configuration
4. **Re-execute Phase 4** (import and configuration)
5. **Restart Phase 5** testing

**Note**: Rollback should only be necessary for data corruption or major configuration errors. Most defects can be fixed in place.

---

## Success Criteria

- [ ] >90% of all test cases passed (117/127 or better)
- [ ] All P0 and P1 defects resolved
- [ ] WordPress site fully functional in DEV
- [ ] All forms submit successfully
- [ ] Email notifications working
- [ ] Premium licenses activated and functional
- [ ] Performance baseline meets minimum targets (load time <3s)
- [ ] Security baseline established (no critical vulnerabilities)
- [ ] Cross-browser compatibility confirmed
- [ ] Mobile responsiveness verified
- [ ] SEO baseline established
- [ ] Test results documented
- [ ] Stakeholder sign-off obtained
- [ ] Ready for SIT promotion

**Definition of Done**:
All testing phases completed, critical defects resolved, and DEV environment validated as stable and ready for SIT promotion.

---

## Sign-Off

**Completed By**: _________________ Date: _________
**Verified By**: _________________ Date: _________
**Total Tests Executed**: _________ / 127
**Tests Passed**: _________ / _________
**Pass Rate**: _________ %
**P0 Defects**: _________ (All resolved: YES/NO)
**P1 Defects**: _________ (All resolved: YES/NO)
**Ready for Phase 6**: [ ] YES [ ] NO

---

## Notes and Observations

[Space for team to document findings]

**Critical Issues Found**:
-
-

**Performance Metrics**:
- Homepage Load Time: _________s
- GTmetrix Grade: _________
- PageSpeed Desktop: _________
- PageSpeed Mobile: _________

**Security Findings**:
-
-

**Recommendations for SIT**:
-
-

---

**Next Phase**: Proceed to **Phase 6**: `06_SIT_Environment_Promotion.md`
