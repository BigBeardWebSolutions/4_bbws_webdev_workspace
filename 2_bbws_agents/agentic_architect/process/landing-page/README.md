# Landing Page SDLC Process

**Process Type**: Single-Page Landing Page
**Parent Process**: [BBWS SDLC v1](../bbws-sdlc-v1/main-plan.md)

---

## Overview

This process is for creating high-converting landing pages for marketing campaigns, product launches, or lead generation.

## Applicable Stages

### Design Phase
| Stage | Name | Required |
|-------|------|----------|
| 1 | Requirements | Simplified |
| F1 | UI/UX Design | Yes |
| F2 | Prototype | Yes |

### Development Phase
| Stage | Name | Required |
|-------|------|----------|
| F3 | React Implementation | Yes |
| F4 | Testing | Simplified |
| F6 | Deployment | Yes |

**OR** (WordPress route)

| Stage | Name | Required |
|-------|------|----------|
| W2 | AI Generation | Yes |
| W3 | Deployment | Yes |
| W4 | Testing | Simplified |

## Technology Options

### Option A: React Landing Page
- React + TypeScript
- TailwindCSS
- Framer Motion (animations)
- S3 + CloudFront

### Option B: AI-Generated Landing Page
- WordPress Theme
- Claude for content
- Stable Diffusion for images
- Static export to S3

## Project Template

```
{landing-name}_landing/
├── src/
│   ├── components/
│   │   ├── Hero.tsx
│   │   ├── Features.tsx
│   │   ├── Testimonials.tsx
│   │   ├── Pricing.tsx
│   │   └── CTA.tsx
│   ├── styles/
│   └── App.tsx
├── designs/
├── terraform/
└── CLAUDE.md
```

## Landing Page Sections

1. **Hero** - Headline, subhead, CTA
2. **Problem** - Pain points
3. **Solution** - Your product/service
4. **Features** - Key benefits
5. **Social Proof** - Testimonials
6. **Pricing** - Plans (optional)
7. **FAQ** - Common questions
8. **CTA** - Final call to action

## Estimated Duration

| Mode | Duration |
|------|----------|
| Agentic | 2 hours |
| Manual | 8 hours |

## Examples

- Product Launch Page
- SaaS Signup Page
- Event Registration
- Lead Magnet Page

---

**Quick Start**: Use simplified stages from `../bbws-sdlc-v1/`.
