# Fix Extracted Website Prompt Template

Copy and customize this prompt to fix an extracted website so it matches the live site.

---

## Quick Prompt (Single Site)

```
Fix the extracted website [SITE_NAME] so it matches the live site at [LIVE_URL].

Local files: [LOCAL_PATH]

Agents to load:
- 4_bbws_webdev_workspace/agents/developer/Web_Developer_Agent.md
- 4_bbws_webdev_workspace/agents/ui_ux/UI_Tester_Agent.md
- 4_bbws_webdev_workspace/agents/testing/website_testing.skill.md

Steps:
1. Open the live site [LIVE_URL] and the local extracted site side-by-side
2. Compare and identify all differences (layout, styles, images, content, links)
3. Fix each issue in the local files at [LOCAL_PATH]
4. Validate the fix locally
5. Upload to S3: aws s3 sync [LOCAL_PATH] s3://bigbeard-migrated-site-dev/[SITE_NAME]/ --profile sandbox --delete
6. Clear CloudFront cache for the site
7. Check the deployed site via CloudFront URL and confirm it matches the live site
```

---

## Full Prompt (Detailed)

```
I need to fix an extracted website that doesn't match the live site.

Site details:
- Live URL: [LIVE_URL]
- Site name: [SITE_NAME]
- Local extracted files: [LOCAL_PATH]
- Target S3 bucket: bigbeard-migrated-site-dev
- AWS Profile: sandbox

Load these agents for the task:
- 4_bbws_webdev_workspace/agents/developer/Web_Developer_Agent.md (HTML/CSS/JS fixes)
- 4_bbws_webdev_workspace/agents/ui_ux/UI_Tester_Agent.md (visual comparison & diagnostics)
- 4_bbws_webdev_workspace/agents/testing/website_testing.skill.md (QA validation)

Phase 1 - Audit (compare live vs extracted):
1. Fetch the live site [LIVE_URL] and note its structure, layout, and content
2. Read the local extracted files at [LOCAL_PATH]
3. Produce a difference report covering:
   - Missing or broken images
   - CSS/styling differences (fonts, colours, spacing, layout)
   - Missing or incorrect content/text
   - Broken or absolute links (should be relative)
   - Missing pages or sections
   - JavaScript functionality gaps
   - Responsive/mobile layout issues
   - Missing assets (fonts, icons, favicons)
4. Share the findings before making any changes

Phase 2 - Fix:
5. Fix every issue identified in the audit, working through [LOCAL_PATH]
6. For each fix, explain what changed and why
7. Ensure all links are relative (not absolute to the live domain)
8. Ensure all asset references point to local files
9. Preserve the original site structure and navigation

Phase 3 - Validate locally:
10. Run website_testing.skill.md validation:
    - Verify all internal links resolve
    - Check for missing assets (404s)
    - Confirm page titles and meta tags match live site
    - Validate HTML structure
11. Confirm the site opens correctly in browser from local files

Phase 4 - Deploy to DEV:
12. Upload fixed site to S3:
    aws s3 sync [LOCAL_PATH] s3://bigbeard-migrated-site-dev/[SITE_NAME]/ \
      --profile sandbox --delete
13. Find the CloudFront distribution for bigbeard-migrated-site-dev:
    aws cloudfront list-distributions \
      --query "DistributionList.Items[?contains(Origins.Items[0].DomainName, 'bigbeard-migrated-site-dev')].{ID:Id,Domain:DomainName,OriginPath:Origins.Items[0].OriginPath}" \
      --output table --profile sandbox
14. Invalidate the CloudFront cache:
    aws cloudfront create-invalidation \
      --distribution-id [DIST_ID] \
      --paths "/[SITE_NAME]/*" \
      --profile sandbox

Phase 5 - Verify deployment:
15. Access the site via CloudFront URL and compare against [LIVE_URL]
16. Confirm the deployed version matches the live site
17. Report any remaining differences
```

---

## Example Usage

```
I need to fix an extracted website that doesn't match the live site.

Site details:
- Live URL: https://roedinolte.co.za
- Site name: roedinolte.co.za
- Local extracted files: /Users/sithembisomjoko/Downloads/AGENTIC_WORK/0_utilities/website_extractor/website-migrator/extracted_sites/dev/roedinolte.co.za
- Target S3 bucket: bigbeard-migrated-site-dev
- AWS Profile: sandbox

Load these agents for the task:
- 4_bbws_webdev_workspace/agents/developer/Web_Developer_Agent.md
- 4_bbws_webdev_workspace/agents/ui_ux/UI_Tester_Agent.md
- 4_bbws_webdev_workspace/agents/testing/website_testing.skill.md

Phase 1 - Audit:
1. Fetch the live site https://roedinolte.co.za and note its structure
2. Read the local extracted files
3. Produce a difference report
4. Share findings before making changes

Phase 2 - Fix all identified issues

Phase 3 - Validate locally (links, assets, structure)

Phase 4 - Deploy to DEV:
- S3 sync to bigbeard-migrated-site-dev/roedinolte.co.za/
- Find CloudFront distribution
- Invalidate cache

Phase 5 - Verify deployed site matches live site
```

---

## Key Paths

| Path | Purpose |
|------|---------|
| `4_bbws_webdev_workspace/agents/developer/Web_Developer_Agent.md` | HTML/CSS/JS fix agent |
| `4_bbws_webdev_workspace/agents/ui_ux/UI_Tester_Agent.md` | Visual comparison & diagnostics |
| `4_bbws_webdev_workspace/agents/testing/website_testing.skill.md` | QA & link validation |
| `4_bbws_webdev_workspace/agents/developer/static_site_developer.skill.md` | Static site expertise |
| `4_bbws_webdev_workspace/agents/skills/web_design_fundamentals.skill.md` | Design reference |

---

## Expected Workflow

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  AUDIT   │───>│   FIX    │───>│ VALIDATE │───>│  DEPLOY  │───>│  VERIFY  │
│ Compare  │    │ HTML/CSS │    │  Local   │    │ S3+CF    │    │ Live     │
│ live vs  │    │ JS/assets│    │  checks  │    │ upload   │    │ check    │
│ extracted│    │ links    │    │  links   │    │ cache    │    │ matches  │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
```

1. **Audit** - Compare live site vs extracted site, produce difference report
2. **Fix** - Resolve all differences (styles, content, links, assets)
3. **Validate** - Run local checks (links, assets, structure, rendering)
4. **Deploy** - S3 sync to `bigbeard-migrated-site-dev` + CloudFront invalidation
5. **Verify** - Confirm deployed site matches live site via CloudFront URL

---

## Common Issues & Fixes

| Issue | Root Cause | Fix |
|-------|-----------|-----|
| Broken images | Absolute URLs or missing downloads | Download missing images, convert to relative paths |
| Wrong fonts | External font CDN not captured | Download fonts locally or keep CDN references |
| Layout broken | Missing or corrupted CSS | Re-extract CSS, fix media queries |
| Links go to live site | Absolute URLs not converted | Find/replace domain with relative paths |
| Missing pages | Extractor didn't crawl deep enough | Manually extract missing pages |
| JavaScript errors | Inline scripts referencing live domain | Update API endpoints and domain references |
| Missing favicon | Not included in extraction | Download and add `<link rel="icon">` |
| Mobile layout broken | Responsive CSS missing or incomplete | Restore missing media query rules |
| Forms not working | Action URLs point to live backend | Update form actions or add placeholder |
| Missing social icons | Icon fonts/SVGs not downloaded | Download icon assets, fix references |

---

## Agents & Their Roles

| Agent | Role in Fix Workflow |
|-------|---------------------|
| **Web_Developer_Agent.md** | Primary fixer - edits HTML, CSS, JS, restructures files |
| **UI_Tester_Agent.md** | Compares live vs extracted visually, runs diagnostics |
| **website_testing.skill.md** | QA checks - links, assets, accessibility, performance |
| **static_site_developer.skill.md** | Static site patterns, performance, deployment |
| **web_design_fundamentals.skill.md** | Design system reference for style fixes |

---

## S3 & CloudFront Deployment

### DEV Environment

| Setting | Value |
|---------|-------|
| Bucket | `bigbeard-migrated-site-dev` |
| Region | `eu-west-1` |
| Profile | `sandbox` |

### Deployment Commands

**1. Upload fixed site to S3:**
```bash
aws s3 sync [LOCAL_PATH] s3://bigbeard-migrated-site-dev/[SITE_NAME]/ \
  --profile sandbox --delete
```

**2. Find the CloudFront distribution:**
```bash
aws cloudfront list-distributions \
  --query "DistributionList.Items[?contains(Origins.Items[0].DomainName, 'bigbeard-migrated-site-dev')].{ID:Id,Domain:DomainName,OriginPath:Origins.Items[0].OriginPath}" \
  --output table --profile sandbox
```

**3. Clear CloudFront cache:**
```bash
aws cloudfront create-invalidation \
  --distribution-id [DIST_ID] \
  --paths "/[SITE_NAME]/*" \
  --profile sandbox
```

**4. Verify deployment:**
```bash
# Check S3 file count
aws s3 ls s3://bigbeard-migrated-site-dev/[SITE_NAME]/ --recursive --profile sandbox | wc -l

# Check invalidation status
aws cloudfront get-invalidation \
  --distribution-id [DIST_ID] \
  --id [INVALIDATION_ID] \
  --profile sandbox
```

---

## Fix Validation Checklist

For each fixed site, verify:
- [ ] All pages render correctly (no broken layouts)
- [ ] All images load (no broken image placeholders)
- [ ] CSS styles match the live site (fonts, colours, spacing)
- [ ] All internal links work and are relative
- [ ] Navigation matches the live site structure
- [ ] JavaScript functionality works (menus, sliders, forms)
- [ ] Favicon displays correctly
- [ ] Mobile/responsive layout matches live site
- [ ] Page titles and meta descriptions match
- [ ] No console errors in browser dev tools
- [ ] S3 upload completed with correct file count
- [ ] CloudFront cache invalidated
- [ ] Deployed site accessible via CloudFront URL
- [ ] Deployed site visually matches live site
