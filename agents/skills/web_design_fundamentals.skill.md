# Web Design Fundamentals Skill

**Version:** 1.0.0
**Type:** Base Skill
**Role:** Web Designer
**Inherited By:** HTML Landing Page, React Landing Page

## Purpose

This skill defines common web design principles, best practices, and workflows that are shared across all landing page implementations, regardless of the underlying technology (HTML, React, etc.).

## Core Design Principles

### 1. Visual Hierarchy
- **Typography Scale**: Establish consistent heading sizes (h1: 48px, h2: 36px, h3: 24px, body: 16px)
- **Spacing System**: Use 8px grid system (8, 16, 24, 32, 40, 48, 60, 80px)
- **Color Contrast**: Ensure WCAG AA compliance (4.5:1 for normal text, 3:1 for large text)

### 2. Layout Structure
- **Container Max-Width**: 1200px for content, full-width for backgrounds
- **Section Padding**: Consistent vertical rhythm (80px desktop, 40px mobile)
- **Grid System**: 12-column grid for flexible layouts
- **Responsive Breakpoints**:
  - Mobile: 0-767px
  - Tablet: 768-1023px
  - Desktop: 1024px+

### 3. Color System
- **Primary Color**: Main brand color for CTAs and key elements
- **Secondary Color**: Supporting color for accents
- **Neutral Colors**: Grays for backgrounds and text (light, medium, dark)
- **Semantic Colors**: Success (green), Warning (yellow), Error (red), Info (blue)

### 4. Component Library
- **Navigation**: Logo, menu items, CTA button
- **Hero Section**: Headline, subheadline, CTA, optional image
- **Features**: Icon/image, title, description (3-4 columns)
- **Pricing**: Cards with features list, price, CTA
- **Testimonials**: Quote, author, photo, company
- **Footer**: Links, social media, copyright

---

## Landing Page Development Workflow

### Phase 1: Project Setup & Structure

#### Step 1.1: Create Directory Structure
```
project-root/
├── assets/
│   ├── images/
│   │   ├── logo/
│   │   │   ├── logo.png
│   │   │   ├── logo.svg
│   │   │   └── favicon.ico
│   │   ├── hero/
│   │   ├── features/
│   │   ├── testimonials/
│   │   └── backgrounds/
│   ├── icons/
│   │   ├── social/
│   │   └── features/
│   └── fonts/
├── styles/
│   ├── colors.css (or colors.js)
│   ├── typography.css
│   ├── layout.css
│   └── components.css
├── docs/
│   ├── design-spec.md
│   └── color-palette.md
└── README.md
```

#### Step 1.2: Essential Files Checklist
- [ ] Logo files (PNG, SVG, ICO)
- [ ] Favicon (16x16, 32x32, 180x180)
- [ ] Social media icons (Facebook, Twitter, LinkedIn, Instagram)
- [ ] Feature icons (if applicable)
- [ ] Hero background image
- [ ] Color palette definition
- [ ] Typography definitions
- [ ] Google Maps integration code (if needed)

#### Step 1.3: SEO & Meta Files
- [ ] robots.txt
- [ ] sitemap.xml
- [ ] Open Graph images (1200x630)
- [ ] Meta descriptions
- [ ] Structured data (JSON-LD)

---

### Phase 2: Logo Integration

#### Step 2.1: Logo Requirements
**File Formats Needed:**
- SVG (scalable, best for web)
- PNG with transparency (fallback)
- ICO (favicon)
- Multiple sizes: 180x180 (Apple), 192x192 (Android), 512x512 (PWA)

**Logo Specifications:**
```css
/* Desktop Navigation */
.logo {
  height: 50-60px;
  width: auto;
  max-width: 200px;
}

/* Mobile Navigation */
@media (max-width: 767px) {
  .logo {
    height: 40px;
  }
}
```

#### Step 2.2: Logo Selection Process
1. **Obtain Logo Files**:
   - Request from client/designer
   - Ensure proper licensing
   - Verify file quality (min 300 DPI for PNG)

2. **Optimize Logo**:
   - Compress PNG (TinyPNG, ImageOptim)
   - Minify SVG (SVGO)
   - Generate favicon variants

3. **Implement Logo**:
   - Place in `/assets/images/logo/`
   - Add to navigation component
   - Include alt text for accessibility
   - Link to homepage

#### Step 2.3: Logo Upload Workflow
```bash
# Example directory structure
assets/images/logo/
  ├── logo.svg           # Primary logo
  ├── logo.png           # Fallback
  ├── logo-white.svg     # Dark background version
  ├── favicon-16x16.png
  ├── favicon-32x32.png
  ├── apple-touch-icon.png  # 180x180
  └── favicon.ico
```

---

### Phase 3: Navigation & Color System

#### Step 3.1: Navigation Structure
**Desktop Navigation Components:**
- Logo (left-aligned)
- Menu items (center or right)
  - Home
  - About
  - Services
  - Pricing
  - Blog
  - Contact
- CTA button (right-aligned)

**Mobile Navigation:**
- Hamburger menu (right)
- Logo (left or center)
- Full-screen overlay or slide-in menu

#### Step 3.2: Color System Definition

**Create Color Palette File:**
```css
/* colors.css */
:root {
  /* Primary Colors */
  --color-primary: #0693e3;
  --color-primary-dark: #0575bd;
  --color-primary-light: #4db8ff;

  /* Secondary Colors */
  --color-secondary: #9b51e0;
  --color-secondary-dark: #7c3aed;

  /* Neutral Colors */
  --color-dark: #1a1f2e;
  --color-gray-900: #252b3d;
  --color-gray-700: #3a4055;
  --color-gray-500: #8a8f9e;
  --color-gray-300: #b8c0d4;
  --color-gray-100: #e0e4ed;
  --color-white: #ffffff;

  /* Semantic Colors */
  --color-success: #10b981;
  --color-warning: #f59e0b;
  --color-error: #ef4444;
  --color-info: #00d4ff;

  /* Background Colors */
  --bg-primary: var(--color-dark);
  --bg-secondary: var(--color-gray-900);
  --bg-card: var(--color-gray-700);

  /* Text Colors */
  --text-primary: var(--color-white);
  --text-secondary: var(--color-gray-300);
  --text-muted: var(--color-gray-500);
}
```

#### Step 3.3: Navigation Styling
```css
/* Navigation Background Colors */
.nav-light {
  background-color: var(--color-white);
  color: var(--color-dark);
}

.nav-dark {
  background-color: var(--color-dark);
  color: var(--color-white);
}

.nav-transparent {
  background-color: transparent;
  position: absolute;
  top: 0;
  width: 100%;
}

/* Sticky Navigation */
.nav-sticky {
  position: sticky;
  top: 0;
  z-index: 1000;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}
```

---

### Phase 4: Layout & Sections

#### Step 4.1: Page Sections Structure

**Typical Landing Page Layout:**
```
1. Navigation (sticky)
2. Hero Section
3. Features/Services Section
4. About/Story Section
5. Pricing Section
6. Testimonials Section
7. CTA Section
8. Footer
```

#### Step 4.2: Section Specifications

**Hero Section:**
```css
.hero {
  min-height: 80vh;
  display: flex;
  align-items: center;
  padding: 80px 60px;
  background-size: cover;
  background-position: center;
}

.hero-content {
  max-width: 600px;
}

.hero-title {
  font-size: 48px;
  font-weight: 700;
  margin-bottom: 20px;
  line-height: 1.2;
}

.hero-subtitle {
  font-size: 20px;
  margin-bottom: 40px;
  color: var(--text-secondary);
}
```

**Features Section:**
```css
.features {
  padding: 80px 60px;
  background-color: var(--bg-secondary);
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 40px;
  max-width: 1200px;
  margin: 0 auto;
}

.feature-card {
  text-align: center;
  padding: 40px 30px;
  background: var(--bg-card);
  border-radius: 16px;
}
```

**Footer:**
```css
.footer {
  background-color: var(--color-dark);
  padding: 60px 60px 30px;
}

.footer-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 40px;
  margin-bottom: 40px;
}

.footer-bottom {
  border-top: 1px solid var(--color-gray-700);
  padding-top: 30px;
  text-align: center;
  color: var(--text-muted);
}
```

#### Step 4.3: Background Images Best Practices

**Image Requirements:**
- **Resolution**: Minimum 1920x1080 for full-width backgrounds
- **Format**: WebP with JPG fallback
- **Optimization**: Compress to <200KB
- **Placement**: Use object-fit: cover for responsive scaling

**Background Image Patterns:**
```css
/* Full-width background with overlay */
.section-with-bg {
  background-image:
    linear-gradient(rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.5)),
    url('/assets/images/backgrounds/hero-bg.jpg');
  background-size: cover;
  background-position: center;
  background-attachment: fixed; /* Parallax effect */
}

/* Pattern overlay */
.section-with-pattern {
  background:
    url('/assets/images/patterns/dots.svg'),
    var(--bg-primary);
  background-size: 20px 20px;
}
```

#### Step 4.4: Responsive Layout Rules

**Mobile-First Approach:**
```css
/* Mobile (default) */
.container {
  padding: 40px 20px;
}

.grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 20px;
}

/* Tablet */
@media (min-width: 768px) {
  .container {
    padding: 60px 40px;
  }

  .grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 30px;
  }
}

/* Desktop */
@media (min-width: 1024px) {
  .container {
    padding: 80px 60px;
  }

  .grid {
    grid-template-columns: repeat(3, 1fr);
    gap: 40px;
  }
}
```

---

## Accessibility Standards

### WCAG 2.1 AA Compliance
- [ ] Color contrast ratios meet minimum standards
- [ ] All interactive elements keyboard accessible
- [ ] Focus indicators visible
- [ ] Alt text for all images
- [ ] Semantic HTML structure
- [ ] ARIA labels where appropriate
- [ ] Form labels properly associated

### Screen Reader Support
- [ ] Logical heading hierarchy (h1 → h2 → h3)
- [ ] Skip navigation link
- [ ] Descriptive link text
- [ ] Form error messages announced
- [ ] Loading states communicated

---

## Performance Optimization

### Image Optimization
- Use WebP with fallbacks
- Lazy loading for below-fold images
- Responsive images with srcset
- Compress images to <200KB
- Use SVG for icons and logos

### Loading Performance
- Minimize HTTP requests
- Inline critical CSS
- Defer non-critical JavaScript
- Use CDN for static assets
- Enable Gzip/Brotli compression

### Core Web Vitals Targets
- **LCP** (Largest Contentful Paint): <2.5s
- **FID** (First Input Delay): <100ms
- **CLS** (Cumulative Layout Shift): <0.1

---

## Testing Checklist

### Cross-Browser Testing
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)
- [ ] Mobile Safari (iOS)
- [ ] Chrome Mobile (Android)

### Responsive Testing
- [ ] 320px (small mobile)
- [ ] 375px (mobile)
- [ ] 768px (tablet)
- [ ] 1024px (desktop)
- [ ] 1440px (large desktop)
- [ ] 1920px (full HD)

### Functionality Testing
- [ ] All links work
- [ ] Forms submit correctly
- [ ] Buttons trigger expected actions
- [ ] Navigation menu opens/closes
- [ ] Images load properly
- [ ] Videos play correctly

---

## Handoff Documentation

### Designer → Developer Handoff
**Required Assets:**
- Design files (Figma, Sketch, Adobe XD)
- Style guide (colors, typography, spacing)
- Logo package (all formats)
- Image assets (optimized)
- Icon set
- Copy/content document

**Required Specifications:**
- Responsive breakpoints
- Animation/transition details
- Hover states
- Interactive component behaviors
- Form validation rules

### Developer → Client Handoff
**Deliverables:**
- Live site URL
- Staging environment access
- Source code repository
- Build/deployment instructions
- Content management guide
- Analytics setup documentation
- SEO optimization report

---

## Version Control Best Practices

### Git Workflow
```bash
# Feature branch naming
feature/add-pricing-section
feature/implement-navigation
fix/mobile-menu-bug
style/update-button-colors

# Commit message format
type(scope): subject

# Examples
feat(navigation): add sticky header
style(hero): update background color
fix(form): resolve validation error
docs(readme): add setup instructions
```

### Branching Strategy
- `main` - Production-ready code
- `develop` - Development branch
- `feature/*` - New features
- `fix/*` - Bug fixes
- `hotfix/*` - Emergency production fixes

---

## Common Pitfalls to Avoid

1. **Inconsistent Spacing**: Use spacing system throughout
2. **Poor Color Contrast**: Always check accessibility
3. **Unoptimized Images**: Compress before deployment
4. **No Mobile Testing**: Test on real devices
5. **Missing Alt Text**: Add to all images
6. **Broken Links**: Verify all internal/external links
7. **No Loading States**: Show feedback for async actions
8. **Hardcoded Values**: Use CSS variables/constants
9. **No Error Handling**: Plan for edge cases
10. **Skipping Testing**: Test in multiple browsers/devices

---

## Additional Resources

### Design Tools
- Figma (UI design)
- Adobe XD (prototyping)
- Sketch (macOS design)
- InVision (collaboration)

### Development Tools
- Chrome DevTools (debugging)
- Lighthouse (performance auditing)
- WAVE (accessibility testing)
- PageSpeed Insights (performance)

### Asset Libraries
- Unsplash (stock photos)
- Pexels (free images)
- Iconify (icon library)
- Google Fonts (web fonts)
- Flaticon (icon sets)

---

**End of Web Design Fundamentals Skill**
