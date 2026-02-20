# Third-Party Integration Inventory: TheTransitionThinkTank

**Source**: PROD site analysis of thetransitionthinktank.org (2026-01-29)

---

## Domain-Specific Services (Require Reconfiguration)

| # | Integration | Domain-Locked? | Current Config | DEV Action | PROD Action |
|---|-------------|----------------|----------------|------------|-------------|
| 1 | Google Analytics 4 | YES | ID: `G-YB6L23547D` | Mock/disable in DEV | Update property domain |
| 2 | Google Tag Manager | YES | (loaded via gtag) | No action for DEV | Verify data stream |
| 3 | Google reCAPTCHA Enterprise | YES | Site key: `6LdcztUrAAAAAFYgIqQ-BD8-LbHv59XEJBdaoWPW` | Add DEV domain to reCAPTCHA console | Add PROD domain |
| 4 | LinkedIn Insight Tag | YES | Present in page | Disable in DEV | Update allowed domains |
| 5 | Complianz GDPR | Partial | Cookie consent banner | Update domain in settings | Re-scan cookies |

## Non-Domain-Specific Services (Work Automatically)

| # | Integration | Notes |
|---|-------------|-------|
| 1 | Google Fonts (IBM Plex Sans, Roboto, Open Sans) | External CDN, works on any domain |
| 2 | Google Maps (embedded link) | Static link, works automatically |
| 3 | Yoast SEO | Local plugin, URLs updated via replacement SQL |
| 4 | Ajax Search Lite | Local plugin, works automatically |

## WordPress Plugins (License-Dependent)

| # | Plugin | License Required? | Domain-Locked? | Action |
|---|--------|-------------------|----------------|--------|
| 1 | Elementor Pro | YES (paid) | YES | Re-activate license on new domain |
| 2 | Gravity Forms | YES (paid) | YES | Re-activate license on new domain |
| 3 | Gravity Forms reCAPTCHA | Addon (included with GF) | NO | reCAPTCHA key needs domain update |
| 4 | Yoast SEO | Unknown (free or premium) | NO | Works automatically |
| 5 | Complianz GDPR | Unknown | NO | Update domain in settings |
| 6 | Ajax Search Lite | Unknown | NO | Works automatically |

## Plugins to DEACTIVATE (Security/Redirect Issues)

| # | Plugin | Status | Reason |
|---|--------|--------|--------|
| 1 | Wordfence | Deactivated in fixed SQL | Firewall blocks CloudFront IPs, causes redirect loops |

## Font Dependencies

| Font | Source | Load Method | Notes |
|------|--------|-------------|-------|
| IBM Plex Sans | Google Fonts | CSS @import | Primary body font |
| Roboto | Google Fonts | CSS @import | Secondary font |
| Open Sans | Google Fonts | CSS @import | **Loaded twice** - consider dequeuing duplicate |

## Email Configuration

| Setting | Value | Notes |
|---------|-------|-------|
| Test email redirect | tebogo@bigbeard.co.za | Standard for all migrations |
| Transactional email | TBD | Check wp_options for SMTP plugin settings |

## Post-Migration Verification Checklist

- [ ] Google Analytics tracking verified (check real-time view)
- [ ] Gravity Forms submission test (should arrive at test email)
- [ ] reCAPTCHA challenge displays correctly
- [ ] Complianz cookie banner appears on first visit
- [ ] Ajax Search Lite returns results
- [ ] Elementor pages render correctly (check 3+ pages)
- [ ] LinkedIn Insight Tag loading (check browser dev tools)
- [ ] Google Fonts loading correctly (check Network tab)
