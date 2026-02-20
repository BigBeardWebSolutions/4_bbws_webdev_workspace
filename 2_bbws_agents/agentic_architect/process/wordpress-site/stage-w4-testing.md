# Stage W4: WordPress Testing

**Parent Plan**: [BBWS SDLC Main Plan](./main-plan.md)
**Stage**: W4 of W4 (WordPress Track)
**Status**: PENDING
**Last Updated**: 2026-01-01

---

## Objective

Validate generated WordPress sites for functionality, accessibility, performance, and SEO compliance before promotion to production.

---

## Agent & Skill Assignment

| Role | Agent | Skill |
|------|-------|-------|
| **Primary** | SDET_Engineer_Agent | `website_testing.skill.md` |
| **Support** | Web_Developer_Agent | `web_design_fundamentals.skill.md` |

---

## Workers

| # | Worker | Task | Status | Output |
|---|--------|------|--------|--------|
| 1 | worker-1-functional-tests | Run functional site tests | PENDING | Test report |
| 2 | worker-2-accessibility | Run accessibility audit (WCAG) | PENDING | Accessibility report |
| 3 | worker-3-performance | Run performance tests (Lighthouse) | PENDING | Performance report |

---

## Worker Instructions

### Worker 1: Functional Testing

**Objective**: Verify all site pages and links work correctly

**Test Categories**:
| Category | Tests |
|----------|-------|
| Page Load | All pages return 200 status |
| Navigation | All internal links work |
| Forms | Contact form submits |
| Images | All images load |
| Mobile | Responsive design works |

**Functional Test Suite**:
```python
# tests/e2e/test_wordpress_site.py
import pytest
import requests
from selenium import webdriver
from selenium.webdriver.common.by import By

class TestWordPressSite:
    @pytest.fixture
    def browser(self):
        options = webdriver.ChromeOptions()
        options.add_argument('--headless')
        driver = webdriver.Chrome(options=options)
        yield driver
        driver.quit()

    def test_homepage_loads(self, site_url):
        response = requests.get(site_url)
        assert response.status_code == 200

    def test_all_pages_accessible(self, site_url):
        pages = ['/', '/about', '/services', '/contact']
        for page in pages:
            response = requests.get(f"{site_url}{page}")
            assert response.status_code == 200, f"Page {page} failed"

    def test_navigation_links(self, browser, site_url):
        browser.get(site_url)
        nav_links = browser.find_elements(By.CSS_SELECTOR, 'nav a')
        for link in nav_links:
            href = link.get_attribute('href')
            if href and not href.startswith('#'):
                response = requests.head(href)
                assert response.status_code == 200

    def test_images_load(self, browser, site_url):
        browser.get(site_url)
        images = browser.find_elements(By.TAG_NAME, 'img')
        for img in images:
            src = img.get_attribute('src')
            if src:
                response = requests.head(src)
                assert response.status_code == 200

    def test_responsive_mobile(self, browser, site_url):
        browser.set_window_size(375, 812)  # iPhone X
        browser.get(site_url)
        # Verify mobile menu exists
        assert browser.find_element(By.CSS_SELECTOR, '.mobile-menu')
```

**Quality Criteria**:
- [ ] All pages load successfully
- [ ] All internal links work
- [ ] All images load
- [ ] Mobile responsive design works

---

### Worker 2: Accessibility Audit

**Objective**: Ensure WCAG 2.1 AA compliance

**Accessibility Test Tools**:
| Tool | Purpose |
|------|---------|
| axe-core | Automated accessibility testing |
| pa11y | Command-line accessibility testing |
| WAVE | Manual accessibility review |

**Accessibility Test Suite**:
```python
# tests/accessibility/test_wcag.py
import pytest
from axe_selenium_python import Axe

class TestAccessibility:
    def test_wcag_compliance(self, browser, site_url):
        browser.get(site_url)
        axe = Axe(browser)
        axe.inject()
        results = axe.run()

        # Filter for WCAG 2.1 AA violations
        violations = [
            v for v in results['violations']
            if 'wcag2aa' in v.get('tags', [])
        ]

        assert len(violations) == 0, f"WCAG violations: {violations}"

    def test_color_contrast(self, browser, site_url):
        browser.get(site_url)
        axe = Axe(browser)
        axe.inject()
        results = axe.run()

        contrast_violations = [
            v for v in results['violations']
            if v['id'] == 'color-contrast'
        ]
        assert len(contrast_violations) == 0

    def test_alt_text(self, browser, site_url):
        browser.get(site_url)
        images = browser.find_elements(By.TAG_NAME, 'img')
        for img in images:
            alt = img.get_attribute('alt')
            assert alt is not None and len(alt) > 0, \
                f"Image missing alt text: {img.get_attribute('src')}"

    def test_heading_hierarchy(self, browser, site_url):
        browser.get(site_url)
        headings = browser.find_elements(By.CSS_SELECTOR, 'h1, h2, h3, h4, h5, h6')
        levels = [int(h.tag_name[1]) for h in headings]

        # Check no heading level is skipped
        for i in range(1, len(levels)):
            assert levels[i] <= levels[i-1] + 1, "Heading hierarchy violated"
```

**WCAG Checklist**:
- [ ] Color contrast ratio >= 4.5:1
- [ ] All images have alt text
- [ ] Keyboard navigation works
- [ ] Focus indicators visible
- [ ] Form labels present
- [ ] Heading hierarchy correct

**Quality Criteria**:
- [ ] No WCAG 2.1 AA violations
- [ ] Accessibility score >= 90
- [ ] Screen reader compatible

---

### Worker 3: Performance Testing

**Objective**: Ensure site meets performance benchmarks

**Lighthouse Performance Audit**:
```bash
# Run Lighthouse audit
npx lighthouse https://{tenant}.sites.dev.kimmyai.io \
  --output=json \
  --output-path=./reports/lighthouse-{tenant}.json \
  --chrome-flags="--headless"
```

**Performance Test Suite**:
```python
# tests/performance/test_lighthouse.py
import subprocess
import json

class TestPerformance:
    def test_performance_score(self, site_url):
        result = subprocess.run([
            'npx', 'lighthouse', site_url,
            '--output=json', '--quiet',
            '--chrome-flags=--headless'
        ], capture_output=True)

        report = json.loads(result.stdout)
        score = report['categories']['performance']['score'] * 100

        assert score >= 80, f"Performance score {score} < 80"

    def test_largest_contentful_paint(self, site_url):
        # LCP should be < 2.5s
        report = get_lighthouse_report(site_url)
        lcp = report['audits']['largest-contentful-paint']['numericValue']
        assert lcp < 2500, f"LCP {lcp}ms > 2500ms"

    def test_cumulative_layout_shift(self, site_url):
        # CLS should be < 0.1
        report = get_lighthouse_report(site_url)
        cls = report['audits']['cumulative-layout-shift']['numericValue']
        assert cls < 0.1, f"CLS {cls} > 0.1"

    def test_time_to_interactive(self, site_url):
        # TTI should be < 3.8s
        report = get_lighthouse_report(site_url)
        tti = report['audits']['interactive']['numericValue']
        assert tti < 3800, f"TTI {tti}ms > 3800ms"
```

**Performance Benchmarks**:
| Metric | Target | Description |
|--------|--------|-------------|
| Performance Score | >= 80 | Lighthouse score |
| LCP | < 2.5s | Largest Contentful Paint |
| FID | < 100ms | First Input Delay |
| CLS | < 0.1 | Cumulative Layout Shift |
| TTI | < 3.8s | Time to Interactive |

**Quality Criteria**:
- [ ] Lighthouse performance >= 80
- [ ] Core Web Vitals passing
- [ ] Page load < 3 seconds
- [ ] Images optimized (WebP)

---

## Stage Outputs

| Output | Description | Location |
|--------|-------------|----------|
| Functional tests | Test results | `reports/functional/` |
| Accessibility report | WCAG audit | `reports/accessibility/` |
| Performance report | Lighthouse results | `reports/performance/` |

---

## Approval Gate W1

**Location**: After this stage
**Approvers**: Tech Lead, Content Lead
**Criteria**:
- [ ] All functional tests passing
- [ ] WCAG 2.1 AA compliant
- [ ] Lighthouse performance >= 80
- [ ] No critical issues

---

## Success Criteria

- [ ] All 3 workers completed
- [ ] Functional tests passing
- [ ] Accessibility score >= 90
- [ ] Performance score >= 80
- [ ] Gate W1 approval obtained

---

## Dependencies

**Depends On**: Stage W3 (WordPress Deployment)
**Blocks**: Integration Phase

---

## Estimated Duration

| Activity | Agentic | Manual |
|----------|---------|--------|
| Functional tests | 15 min | 2 hours |
| Accessibility audit | 10 min | 2 hours |
| Performance tests | 10 min | 1 hour |
| **Total** | **35 min** | **5 hours** |

---

**Navigation**: [<- Stage W3](./stage-w3-deployment.md) | [Main Plan](./main-plan.md)
