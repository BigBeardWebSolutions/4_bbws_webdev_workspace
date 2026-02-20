# Stage W1: WordPress Theme Development

**Parent Plan**: [BBWS SDLC Main Plan](./main-plan.md)
**Stage**: W1 of W4 (WordPress Track)
**Status**: PENDING
**Last Updated**: 2026-01-01

---

## Objective

Develop customizable WordPress themes that serve as the foundation for AI-generated static sites. These themes are converted to static HTML/CSS/JS for S3/CloudFront hosting.

---

## Agent & Skill Assignment

| Role | Agent | Skill |
|------|-------|-------|
| **Primary** | Web_Developer_Agent | `wordpress_theme.skill.md` |
| **Support** | Web_Developer_Agent | `web_design_fundamentals.skill.md` |

---

## Workers

| # | Worker | Task | Status | Output |
|---|--------|------|--------|--------|
| 1 | worker-1-theme-structure | Create theme base structure | PENDING | `themes/bbws-starter/` |
| 2 | worker-2-template-system | Build template system for AI | PENDING | Template files |
| 3 | worker-3-style-system | Create configurable style system | PENDING | `styles/` |

---

## Worker Instructions

### Worker 1: Theme Base Structure

**Objective**: Create a modular WordPress theme structure

**Theme Structure**:
```
themes/bbws-starter/
├── assets/
│   ├── css/
│   ├── js/
│   └── images/
├── templates/
│   ├── header.php
│   ├── footer.php
│   ├── home.php
│   ├── about.php
│   ├── services.php
│   ├── contact.php
│   └── blog/
├── components/
│   ├── hero.php
│   ├── features.php
│   ├── testimonials.php
│   ├── cta.php
│   └── gallery.php
├── config/
│   ├── theme.json
│   └── blocks.json
├── functions.php
├── style.css
└── screenshot.png
```

**Quality Criteria**:
- [ ] Theme structure follows WordPress standards
- [ ] Modular component architecture
- [ ] Configuration-driven design
- [ ] Static export compatible

---

### Worker 2: Template System for AI

**Objective**: Create AI-friendly template placeholders

**Template Placeholders**:
```php
<!-- hero.php -->
<section class="hero" style="background-image: url('{{HERO_IMAGE}}');">
  <div class="hero-content">
    <h1>{{HERO_TITLE}}</h1>
    <p>{{HERO_SUBTITLE}}</p>
    <a href="{{CTA_LINK}}" class="btn btn-primary">{{CTA_TEXT}}</a>
  </div>
</section>
```

**Placeholder Categories**:
| Category | Placeholders |
|----------|--------------|
| Text | `{{TITLE}}`, `{{DESCRIPTION}}`, `{{BODY}}` |
| Images | `{{HERO_IMAGE}}`, `{{LOGO}}`, `{{GALLERY_IMAGES}}` |
| Colors | `{{PRIMARY_COLOR}}`, `{{SECONDARY_COLOR}}` |
| Links | `{{CTA_LINK}}`, `{{SOCIAL_LINKS}}` |
| Business | `{{COMPANY_NAME}}`, `{{ADDRESS}}`, `{{PHONE}}` |

**Quality Criteria**:
- [ ] All dynamic content uses placeholders
- [ ] Placeholders documented
- [ ] Default fallback values set
- [ ] AI generation ready

---

### Worker 3: Configurable Style System

**Objective**: Create CSS variables for easy customization

**Style Configuration**:
```css
/* styles/variables.css */
:root {
  /* Colors - AI customizable */
  --color-primary: var(--theme-primary, #3b82f6);
  --color-secondary: var(--theme-secondary, #10b981);
  --color-background: var(--theme-bg, #ffffff);
  --color-text: var(--theme-text, #1f2937);

  /* Typography */
  --font-heading: var(--theme-font-heading, 'Inter', sans-serif);
  --font-body: var(--theme-font-body, 'Inter', sans-serif);

  /* Spacing */
  --spacing-section: var(--theme-spacing, 4rem);

  /* Border Radius */
  --radius-default: var(--theme-radius, 0.5rem);
}
```

**Theme Configuration JSON**:
```json
{
  "theme": {
    "name": "BBWS Starter",
    "version": "1.0.0",
    "configurable": {
      "colors": {
        "primary": "#3b82f6",
        "secondary": "#10b981",
        "accent": "#f59e0b"
      },
      "fonts": {
        "heading": "Inter",
        "body": "Inter"
      },
      "layout": {
        "maxWidth": "1200px",
        "containerPadding": "1.5rem"
      }
    }
  }
}
```

**Quality Criteria**:
- [ ] CSS variables for all customizable properties
- [ ] JSON configuration schema
- [ ] Responsive design system
- [ ] Dark mode support

---

## Stage Outputs

| Output | Description | Location |
|--------|-------------|----------|
| Theme structure | Base WordPress theme | `themes/bbws-starter/` |
| Templates | AI-ready template files | `themes/bbws-starter/templates/` |
| Styles | Configurable CSS system | `themes/bbws-starter/styles/` |
| Config | Theme configuration | `themes/bbws-starter/config/` |

---

## Success Criteria

- [ ] All 3 workers completed
- [ ] Theme builds successfully
- [ ] Templates work with AI generation
- [ ] Styles are configurable via JSON

---

## Dependencies

**Depends On**: Stage 3 (LLD) - Design specifications
**Blocks**: Stage W2 (AI Generation)

---

## Estimated Duration

| Activity | Agentic | Manual |
|----------|---------|--------|
| Theme structure | 20 min | 2 hours |
| Template system | 25 min | 3 hours |
| Style system | 20 min | 2 hours |
| **Total** | **1 hour** | **7 hours** |

---

**Navigation**: [Main Plan](./main-plan.md) | [Stage W2: AI Generation ->](./stage-w2-ai-generation.md)
