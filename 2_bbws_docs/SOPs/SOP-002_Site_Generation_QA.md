# SOP-002: Site Generation Quality Assurance

**Version:** 1.0
**Effective Date:** 2026-01-18
**Department:** Quality Assurance
**Approved By:** Product Manager

---

## 1. Purpose

This SOP defines the quality assurance process for AI-generated landing pages, ensuring all generated content meets brand, accessibility, and performance standards before deployment.

---

## 2. Quality Gates

### 2.1 Brand Compliance
| Check | Threshold | Action if Failed |
|-------|-----------|------------------|
| Brand Score | >= 8.0 | Block production deploy |
| Logo presence | Required | Flag for review |
| Color compliance | 90% match | Suggest corrections |
| Typography | Consistent | Auto-fix where possible |

### 2.2 Accessibility (WCAG 2.1 AA)
| Check | Requirement | Tool |
|-------|-------------|------|
| Color contrast | 4.5:1 minimum | Automated validator |
| Alt text | All images | Automated scan |
| Heading hierarchy | Logical order | HTML validator |
| Keyboard navigation | Full support | Manual test |

### 2.3 Performance
| Metric | Target | Measurement |
|--------|--------|-------------|
| Page load time | < 3 seconds | Lighthouse |
| First Contentful Paint | < 1.5s | Lighthouse |
| Largest Contentful Paint | < 2.5s | Lighthouse |
| Total page size | < 500KB | Automated |

---

## 3. Validation Process

### Step 1: Automated Validation (Immediate)
```
Trigger: Generation complete
Duration: < 5 seconds

Checks:
1. HTML syntax validation
2. CSS validation
3. Brand score calculation
4. Accessibility scan
5. Performance estimate
```

### Step 2: Results Display
```
User sees:
- Overall score (0-10)
- Category breakdown
- Specific issues with suggestions
- Deploy eligibility
```

### Step 3: Manual Review (Optional)
```
Trigger: Score 6.0-7.9 or user requests
Actions:
- Visual inspection
- Content review
- Mobile responsiveness check
```

---

## 4. Score Interpretation

| Score | Rating | Staging Deploy | Production Deploy |
|-------|--------|----------------|-------------------|
| 9.0-10.0 | Excellent | ✅ | ✅ Auto-approved |
| 8.0-8.9 | Good | ✅ | ✅ With recommendations |
| 6.0-7.9 | Needs Work | ✅ Warning | ❌ Blocked |
| < 6.0 | Poor | ❌ Blocked | ❌ Blocked |

---

## 5. Related Documents

| Document | Link |
|----------|------|
| BP-002 | /business_process/BP-002_Site_Generation.md |
| RB-002 | /runbooks/RB-002_Site_Generation_Troubleshooting.md |
