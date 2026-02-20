# HTML Landing Page Development Skill

**Version:** 1.0.0
**Type:** Implementation Skill
**Role:** Web Developer (HTML/CSS/JavaScript)
**Inherits From:** Web Design Fundamentals Skill
**Technology Stack:** HTML5, CSS3, Vanilla JavaScript

## Purpose

This skill provides step-by-step guidance for building landing pages using pure HTML, CSS, and JavaScript, following web standards and best practices. It inherits all design principles from the Web Design Fundamentals skill and adds HTML-specific implementation details.

---

## Prerequisites

### Required Knowledge
- HTML5 semantic elements
- CSS3 (Flexbox, Grid, animations)
- Vanilla JavaScript (DOM manipulation, events)
- Responsive design principles
- Cross-browser compatibility

### Required Tools
- Code editor (VS Code, Sublime Text)
- Live server extension
- Browser DevTools
- Git for version control
- Image optimization tools

---

## Phase 1: Project Setup

### Step 1.1: Initialize HTML Project Structure

```bash
# Create project directory
mkdir landing-page-project
cd landing-page-project

# Create directory structure
mkdir -p assets/{images/{logo,hero,features,testimonials,backgrounds},icons/{social,features},fonts}
mkdir -p css
mkdir -p js
mkdir -p docs

# Create core files
touch index.html
touch css/reset.css
touch css/variables.css
touch css/typography.css
touch css/layout.css
touch css/components.css
touch css/responsive.css
touch css/main.css
touch js/main.js
touch README.md
touch .gitignore
```

### Step 1.2: Create `.gitignore`

```gitignore
# OS Files
.DS_Store
Thumbs.db

# Editor
.vscode/
.idea/
*.sublime-*

# Misc
*.log
node_modules/
.env
```

### Step 1.3: Create Base HTML Template

**File: `index.html`**
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="ie=edge">

  <!-- SEO Meta Tags -->
  <meta name="description" content="Your page description here (150-160 characters)">
  <meta name="keywords" content="keyword1, keyword2, keyword3">
  <meta name="author" content="Company Name">

  <!-- Open Graph Meta Tags -->
  <meta property="og:title" content="Page Title">
  <meta property="og:description" content="Page description">
  <meta property="og:image" content="/assets/images/og-image.jpg">
  <meta property="og:url" content="https://yoursite.com">
  <meta property="og:type" content="website">

  <!-- Twitter Card Meta Tags -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="Page Title">
  <meta name="twitter:description" content="Page description">
  <meta name="twitter:image" content="/assets/images/twitter-card.jpg">

  <!-- Favicon -->
  <link rel="icon" type="image/x-icon" href="/assets/images/logo/favicon.ico">
  <link rel="icon" type="image/png" sizes="32x32" href="/assets/images/logo/favicon-32x32.png">
  <link rel="icon" type="image/png" sizes="16x16" href="/assets/images/logo/favicon-16x16.png">
  <link rel="apple-touch-icon" sizes="180x180" href="/assets/images/logo/apple-touch-icon.png">

  <!-- Stylesheets -->
  <link rel="stylesheet" href="/css/reset.css">
  <link rel="stylesheet" href="/css/variables.css">
  <link rel="stylesheet" href="/css/typography.css">
  <link rel="stylesheet" href="/css/layout.css">
  <link rel="stylesheet" href="/css/components.css">
  <link rel="stylesheet" href="/css/responsive.css">
  <link rel="stylesheet" href="/css/main.css">

  <!-- Google Fonts (example) -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">

  <title>Your Page Title | Company Name</title>
</head>
<body>
  <!-- Skip Navigation Link (Accessibility) -->
  <a href="#main-content" class="skip-link">Skip to main content</a>

  <!-- Navigation -->
  <nav id="navbar" class="navbar">
    <!-- Navigation content here -->
  </nav>

  <!-- Main Content -->
  <main id="main-content">
    <!-- Page sections here -->
  </main>

  <!-- Footer -->
  <footer class="footer">
    <!-- Footer content here -->
  </footer>

  <!-- JavaScript -->
  <script src="/js/main.js" defer></script>
</body>
</html>
```

### Step 1.4: Create CSS Reset

**File: `css/reset.css`**
```css
/* Modern CSS Reset */
*, *::before, *::after {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

html {
  scroll-behavior: smooth;
}

body {
  min-height: 100vh;
  line-height: 1.6;
  text-rendering: optimizeSpeed;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

img, picture, video, canvas, svg {
  display: block;
  max-width: 100%;
}

input, button, textarea, select {
  font: inherit;
}

a {
  text-decoration: none;
  color: inherit;
}

button {
  cursor: pointer;
  border: none;
  background: none;
}

ul, ol {
  list-style: none;
}
```

### Step 1.5: Create CSS Variables

**File: `css/variables.css`**
```css
:root {
  /* Colors - Inherit from Web Design Fundamentals */
  --color-primary: #0693e3;
  --color-primary-dark: #0575bd;
  --color-primary-light: #4db8ff;

  --color-secondary: #9b51e0;
  --color-secondary-dark: #7c3aed;

  --color-dark: #1a1f2e;
  --color-gray-900: #252b3d;
  --color-gray-700: #3a4055;
  --color-gray-500: #8a8f9e;
  --color-gray-300: #b8c0d4;
  --color-gray-100: #e0e4ed;
  --color-white: #ffffff;

  --color-success: #10b981;
  --color-warning: #f59e0b;
  --color-error: #ef4444;
  --color-info: #00d4ff;

  /* Typography */
  --font-family-base: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  --font-size-xs: 0.75rem;    /* 12px */
  --font-size-sm: 0.875rem;   /* 14px */
  --font-size-base: 1rem;     /* 16px */
  --font-size-lg: 1.125rem;   /* 18px */
  --font-size-xl: 1.25rem;    /* 20px */
  --font-size-2xl: 1.5rem;    /* 24px */
  --font-size-3xl: 2rem;      /* 32px */
  --font-size-4xl: 2.5rem;    /* 40px */
  --font-size-5xl: 3rem;      /* 48px */

  --font-weight-normal: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;

  /* Spacing - 8px grid system */
  --spacing-1: 0.5rem;   /* 8px */
  --spacing-2: 1rem;     /* 16px */
  --spacing-3: 1.5rem;   /* 24px */
  --spacing-4: 2rem;     /* 32px */
  --spacing-5: 2.5rem;   /* 40px */
  --spacing-6: 3rem;     /* 48px */
  --spacing-8: 4rem;     /* 64px */
  --spacing-10: 5rem;    /* 80px */

  /* Layout */
  --container-max-width: 1200px;
  --section-padding: var(--spacing-10);
  --border-radius-sm: 0.25rem;   /* 4px */
  --border-radius-md: 0.5rem;    /* 8px */
  --border-radius-lg: 1rem;      /* 16px */
  --border-radius-xl: 1.5rem;    /* 24px */

  /* Shadows */
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1);
  --shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.1);
  --shadow-xl: 0 20px 25px rgba(0, 0, 0, 0.15);

  /* Transitions */
  --transition-fast: 0.15s ease;
  --transition-base: 0.3s ease;
  --transition-slow: 0.5s ease;

  /* Z-index */
  --z-dropdown: 1000;
  --z-sticky: 1020;
  --z-fixed: 1030;
  --z-modal-backdrop: 1040;
  --z-modal: 1050;
  --z-popover: 1060;
  --z-tooltip: 1070;
}
```

---

## Phase 2: Logo Integration

### Step 2.1: Prepare Logo Assets

**Checklist:**
- [ ] Obtain logo in SVG format (preferred)
- [ ] Create PNG fallback (2x resolution)
- [ ] Generate favicon files (16x16, 32x32, 180x180)
- [ ] Create apple-touch-icon.png (180x180)
- [ ] Optimize all files

**File Organization:**
```
assets/images/logo/
├── logo.svg              # Main logo
├── logo.png              # Fallback (2x: 400x100)
├── logo-white.svg        # For dark backgrounds
├── favicon.ico           # 32x32
├── favicon-16x16.png
├── favicon-32x32.png
├── apple-touch-icon.png  # 180x180
```

### Step 2.2: Implement Logo in Navigation

**HTML (in index.html):**
```html
<nav id="navbar" class="navbar">
  <div class="navbar-container">
    <!-- Logo -->
    <a href="/" class="navbar-logo" aria-label="Company Name Home">
      <img src="/assets/images/logo/logo.svg"
           alt="Company Name Logo"
           width="150"
           height="50"
           class="logo-image">
    </a>

    <!-- Navigation content continues... -->
  </div>
</nav>
```

**CSS (in css/components.css):**
```css
.navbar-logo {
  display: flex;
  align-items: center;
  transition: opacity var(--transition-base);
}

.navbar-logo:hover {
  opacity: 0.8;
}

.logo-image {
  height: 50px;
  width: auto;
  max-width: 200px;
}

@media (max-width: 767px) {
  .logo-image {
    height: 40px;
  }
}
```

---

## Phase 3: Navigation Implementation

### Step 3.1: Build Navigation HTML

**Full Navigation Structure:**
```html
<nav id="navbar" class="navbar navbar-sticky">
  <div class="navbar-container container">
    <!-- Logo -->
    <a href="/" class="navbar-logo" aria-label="Company Name Home">
      <img src="/assets/images/logo/logo.svg"
           alt="Company Name Logo"
           class="logo-image">
    </a>

    <!-- Desktop Menu -->
    <ul class="navbar-menu" id="navbar-menu">
      <li class="navbar-item">
        <a href="#home" class="navbar-link">Home</a>
      </li>
      <li class="navbar-item">
        <a href="#about" class="navbar-link">About</a>
      </li>
      <li class="navbar-item">
        <a href="#services" class="navbar-link">Services</a>
      </li>
      <li class="navbar-item">
        <a href="#pricing" class="navbar-link">Pricing</a>
      </li>
      <li class="navbar-item">
        <a href="#contact" class="navbar-link navbar-link-highlight">Contact</a>
      </li>
    </ul>

    <!-- CTA Button -->
    <a href="#quote" class="btn btn-primary navbar-cta">Get A Quote</a>

    <!-- Mobile Menu Toggle -->
    <button class="navbar-toggle"
            id="navbar-toggle"
            aria-label="Toggle navigation menu"
            aria-expanded="false"
            aria-controls="navbar-menu">
      <span class="navbar-toggle-icon"></span>
      <span class="navbar-toggle-icon"></span>
      <span class="navbar-toggle-icon"></span>
    </button>
  </div>
</nav>
```

### Step 3.2: Navigation CSS

**File: `css/components.css`**
```css
/* ===== NAVIGATION ===== */
.navbar {
  background-color: var(--color-dark);
  color: var(--color-white);
  position: relative;
  z-index: var(--z-sticky);
}

.navbar-sticky {
  position: sticky;
  top: 0;
  box-shadow: var(--shadow-md);
}

.navbar-container {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--spacing-3) var(--spacing-6);
  max-width: var(--container-max-width);
  margin: 0 auto;
}

.navbar-menu {
  display: flex;
  align-items: center;
  gap: var(--spacing-5);
}

.navbar-link {
  font-size: var(--font-size-base);
  font-weight: var(--font-weight-medium);
  transition: color var(--transition-base);
  position: relative;
}

.navbar-link:hover,
.navbar-link:focus {
  color: var(--color-info);
}

.navbar-link::after {
  content: '';
  position: absolute;
  bottom: -4px;
  left: 0;
  width: 0;
  height: 2px;
  background-color: var(--color-info);
  transition: width var(--transition-base);
}

.navbar-link:hover::after {
  width: 100%;
}

.navbar-link-highlight {
  color: var(--color-info);
}

.navbar-cta {
  display: none;
}

@media (min-width: 1024px) {
  .navbar-cta {
    display: inline-flex;
  }
}

/* Mobile Menu Toggle */
.navbar-toggle {
  display: none;
  flex-direction: column;
  gap: 6px;
  padding: var(--spacing-1);
  background: transparent;
  border: none;
  cursor: pointer;
}

.navbar-toggle-icon {
  display: block;
  width: 25px;
  height: 2px;
  background-color: var(--color-white);
  transition: all var(--transition-base);
}

@media (max-width: 1023px) {
  .navbar-toggle {
    display: flex;
  }

  .navbar-menu {
    position: fixed;
    top: 70px;
    left: 0;
    right: 0;
    flex-direction: column;
    background-color: var(--color-dark);
    padding: var(--spacing-4);
    gap: var(--spacing-3);
    transform: translateY(-100%);
    opacity: 0;
    visibility: hidden;
    transition: all var(--transition-base);
  }

  .navbar-menu.active {
    transform: translateY(0);
    opacity: 1;
    visibility: visible;
  }

  .navbar-toggle[aria-expanded="true"] .navbar-toggle-icon:nth-child(1) {
    transform: rotate(45deg) translate(6px, 6px);
  }

  .navbar-toggle[aria-expanded="true"] .navbar-toggle-icon:nth-child(2) {
    opacity: 0;
  }

  .navbar-toggle[aria-expanded="true"] .navbar-toggle-icon:nth-child(3) {
    transform: rotate(-45deg) translate(6px, -6px);
  }
}
```

### Step 3.3: Navigation JavaScript

**File: `js/main.js`**
```javascript
// ===== MOBILE MENU TOGGLE =====
const navbarToggle = document.getElementById('navbar-toggle');
const navbarMenu = document.getElementById('navbar-menu');

if (navbarToggle && navbarMenu) {
  navbarToggle.addEventListener('click', () => {
    const isExpanded = navbarToggle.getAttribute('aria-expanded') === 'true';

    navbarToggle.setAttribute('aria-expanded', !isExpanded);
    navbarMenu.classList.toggle('active');
  });

  // Close menu when clicking outside
  document.addEventListener('click', (e) => {
    if (!e.target.closest('.navbar')) {
      navbarToggle.setAttribute('aria-expanded', 'false');
      navbarMenu.classList.remove('active');
    }
  });

  // Close menu when clicking a link
  const navbarLinks = navbarMenu.querySelectorAll('.navbar-link');
  navbarLinks.forEach(link => {
    link.addEventListener('click', () => {
      navbarToggle.setAttribute('aria-expanded', 'false');
      navbarMenu.classList.remove('active');
    });
  });
}

// ===== STICKY NAVIGATION BACKGROUND ON SCROLL =====
const navbar = document.getElementById('navbar');
if (navbar && navbar.classList.contains('navbar-transparent')) {
  window.addEventListener('scroll', () => {
    if (window.scrollY > 50) {
      navbar.classList.add('navbar-scrolled');
    } else {
      navbar.classList.remove('navbar-scrolled');
    }
  });
}
```

---

## Phase 4: Page Sections Implementation

### Step 4.1: Hero Section

**HTML:**
```html
<section id="home" class="hero">
  <div class="hero-background">
    <img src="/assets/images/hero/hero-bg.jpg"
         alt=""
         class="hero-bg-image"
         loading="eager">
  </div>
  <div class="container">
    <div class="hero-content">
      <h1 class="hero-title">
        Build Your Dream Website Today
      </h1>
      <p class="hero-subtitle">
        Professional web solutions tailored to your business needs.
        Fast, reliable, and beautifully designed.
      </p>
      <div class="hero-actions">
        <a href="#pricing" class="btn btn-primary btn-lg">
          View Pricing
        </a>
        <a href="#about" class="btn btn-outline btn-lg">
          Learn More
        </a>
      </div>
    </div>
  </div>
</section>
```

**CSS:**
```css
/* ===== HERO SECTION ===== */
.hero {
  position: relative;
  min-height: 80vh;
  display: flex;
  align-items: center;
  padding: var(--spacing-10) var(--spacing-6);
  overflow: hidden;
}

.hero-background {
  position: absolute;
  inset: 0;
  z-index: -1;
}

.hero-bg-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  filter: brightness(0.5);
}

.hero-content {
  max-width: 600px;
  color: var(--color-white);
}

.hero-title {
  font-size: var(--font-size-5xl);
  font-weight: var(--font-weight-bold);
  line-height: 1.2;
  margin-bottom: var(--spacing-3);
}

.hero-subtitle {
  font-size: var(--font-size-xl);
  color: var(--color-gray-100);
  margin-bottom: var(--spacing-6);
  line-height: 1.6;
}

.hero-actions {
  display: flex;
  gap: var(--spacing-3);
  flex-wrap: wrap;
}

@media (max-width: 767px) {
  .hero {
    min-height: 60vh;
    padding: var(--spacing-8) var(--spacing-4);
  }

  .hero-title {
    font-size: var(--font-size-4xl);
  }

  .hero-subtitle {
    font-size: var(--font-size-lg);
  }

  .hero-actions {
    flex-direction: column;
  }
}
```

### Step 4.2: Features Section

**HTML:**
```html
<section id="services" class="section section-features">
  <div class="container">
    <div class="section-header">
      <h2 class="section-title">Our Services</h2>
      <p class="section-description">
        Everything you need to succeed online
      </p>
    </div>

    <div class="features-grid">
      <div class="feature-card">
        <div class="feature-icon">
          <img src="/assets/icons/features/responsive.svg"
               alt=""
               width="48"
               height="48">
        </div>
        <h3 class="feature-title">Responsive Design</h3>
        <p class="feature-description">
          Your website will look perfect on all devices,
          from mobile to desktop.
        </p>
      </div>

      <div class="feature-card">
        <div class="feature-icon">
          <img src="/assets/icons/features/fast.svg"
               alt=""
               width="48"
               height="48">
        </div>
        <h3 class="feature-title">Lightning Fast</h3>
        <p class="feature-description">
          Optimized for speed with cutting-edge performance techniques.
        </p>
      </div>

      <div class="feature-card">
        <div class="feature-icon">
          <img src="/assets/icons/features/secure.svg"
               alt=""
               width="48"
               height="48">
        </div>
        <h3 class="feature-title">Secure & Reliable</h3>
        <p class="feature-description">
          Built with security best practices and 99.9% uptime guarantee.
        </p>
      </div>
    </div>
  </div>
</section>
```

**CSS:**
```css
/* ===== FEATURES SECTION ===== */
.section-features {
  background-color: var(--color-gray-900);
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: var(--spacing-6);
}

.feature-card {
  background-color: var(--color-gray-700);
  padding: var(--spacing-6);
  border-radius: var(--border-radius-lg);
  text-align: center;
  transition: transform var(--transition-base), box-shadow var(--transition-base);
}

.feature-card:hover {
  transform: translateY(-8px);
  box-shadow: var(--shadow-xl);
}

.feature-icon {
  width: 64px;
  height: 64px;
  margin: 0 auto var(--spacing-3);
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: rgba(0, 212, 255, 0.1);
  border-radius: var(--border-radius-md);
}

.feature-title {
  font-size: var(--font-size-2xl);
  font-weight: var(--font-weight-semibold);
  color: var(--color-white);
  margin-bottom: var(--spacing-2);
}

.feature-description {
  color: var(--color-gray-300);
  line-height: 1.6;
}
```

### Step 4.3: Footer

**HTML:**
```html
<footer class="footer">
  <div class="container">
    <div class="footer-grid">
      <!-- Company Info -->
      <div class="footer-column">
        <img src="/assets/images/logo/logo-white.svg"
             alt="Company Name Logo"
             class="footer-logo">
        <p class="footer-description">
          Building beautiful websites that drive results.
        </p>
        <div class="footer-social">
          <a href="#" class="social-link" aria-label="Facebook">
            <img src="/assets/icons/social/facebook.svg" alt="" width="24" height="24">
          </a>
          <a href="#" class="social-link" aria-label="Twitter">
            <img src="/assets/icons/social/twitter.svg" alt="" width="24" height="24">
          </a>
          <a href="#" class="social-link" aria-label="LinkedIn">
            <img src="/assets/icons/social/linkedin.svg" alt="" width="24" height="24">
          </a>
        </div>
      </div>

      <!-- Quick Links -->
      <div class="footer-column">
        <h4 class="footer-heading">Quick Links</h4>
        <ul class="footer-links">
          <li><a href="#home">Home</a></li>
          <li><a href="#about">About</a></li>
          <li><a href="#services">Services</a></li>
          <li><a href="#pricing">Pricing</a></li>
        </ul>
      </div>

      <!-- Contact -->
      <div class="footer-column">
        <h4 class="footer-heading">Contact</h4>
        <ul class="footer-links">
          <li>Email: info@company.com</li>
          <li>Phone: +27 12 345 6789</li>
          <li>Address: 123 Street, City, Country</li>
        </ul>
      </div>
    </div>

    <div class="footer-bottom">
      <p>&copy; 2025 Company Name. All rights reserved.</p>
    </div>
  </div>
</footer>
```

**CSS:**
```css
/* ===== FOOTER ===== */
.footer {
  background-color: var(--color-dark);
  color: var(--color-white);
  padding: var(--spacing-10) var(--spacing-6) var(--spacing-4);
}

.footer-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: var(--spacing-6);
  margin-bottom: var(--spacing-6);
}

.footer-logo {
  height: 40px;
  width: auto;
  margin-bottom: var(--spacing-3);
}

.footer-description {
  color: var(--color-gray-300);
  margin-bottom: var(--spacing-3);
}

.footer-social {
  display: flex;
  gap: var(--spacing-2);
}

.social-link {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  background-color: var(--color-gray-700);
  border-radius: var(--border-radius-md);
  transition: background-color var(--transition-base);
}

.social-link:hover {
  background-color: var(--color-info);
}

.footer-heading {
  font-size: var(--font-size-lg);
  font-weight: var(--font-weight-semibold);
  margin-bottom: var(--spacing-3);
}

.footer-links {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-2);
}

.footer-links a {
  color: var(--color-gray-300);
  transition: color var(--transition-base);
}

.footer-links a:hover {
  color: var(--color-info);
}

.footer-bottom {
  border-top: 1px solid var(--color-gray-700);
  padding-top: var(--spacing-4);
  text-align: center;
  color: var(--color-gray-500);
}
```

---

## Common HTML Components

### Button Styles

**CSS:**
```css
/* ===== BUTTONS ===== */
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--spacing-1);
  padding: 12px 24px;
  font-size: var(--font-size-base);
  font-weight: var(--font-weight-semibold);
  border-radius: var(--border-radius-md);
  transition: all var(--transition-base);
  cursor: pointer;
  text-decoration: none;
  border: none;
}

.btn-primary {
  background-color: var(--color-info);
  color: var(--color-dark);
}

.btn-primary:hover {
  background-color: #00c4eb;
  transform: translateY(-2px);
  box-shadow: var(--shadow-lg);
}

.btn-outline {
  background-color: transparent;
  color: var(--color-white);
  border: 1px solid var(--color-info);
}

.btn-outline:hover {
  background-color: var(--color-info);
  color: var(--color-dark);
}

.btn-lg {
  padding: 16px 32px;
  font-size: var(--font-size-lg);
}

.btn-sm {
  padding: 8px 16px;
  font-size: var(--font-size-sm);
}
```

---

## Performance Optimization

### Image Lazy Loading

**HTML:**
```html
<!-- Above-the-fold images (eager loading) -->
<img src="/assets/images/hero/hero-bg.jpg"
     alt="Hero background"
     loading="eager">

<!-- Below-the-fold images (lazy loading) -->
<img src="/assets/images/features/feature-1.jpg"
     alt="Feature description"
     loading="lazy">
```

### JavaScript Optimization

```javascript
// Debounce function for scroll events
function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

// Example usage
const handleScroll = debounce(() => {
  console.log('Scrolled!');
}, 100);

window.addEventListener('scroll', handleScroll);
```

---

## Testing Checklist

### HTML Validation
- [ ] Validate HTML with W3C validator
- [ ] Check for semantic HTML usage
- [ ] Verify proper heading hierarchy
- [ ] Ensure all images have alt attributes
- [ ] Check for proper ARIA labels

### CSS Validation
- [ ] Validate CSS with W3C CSS validator
- [ ] Check for browser-specific prefixes
- [ ] Verify responsive breakpoints
- [ ] Test hover/focus states

### JavaScript Testing
- [ ] Test in browsers without JS enabled
- [ ] Check console for errors
- [ ] Test event handlers
- [ ] Verify accessibility features

### Cross-Browser Testing
- [ ] Chrome/Edge (Chromium)
- [ ] Firefox
- [ ] Safari
- [ ] Mobile browsers

---

## Deployment

### Pre-Deployment Checklist
- [ ] Minify CSS and JavaScript
- [ ] Optimize images
- [ ] Test all links
- [ ] Verify meta tags
- [ ] Test forms
- [ ] Check 404 page
- [ ] Test loading speed
- [ ] Verify SSL certificate

### Deployment Options
1. **Static hosting**: Netlify, Vercel, GitHub Pages
2. **Traditional hosting**: cPanel, FTP upload
3. **CDN**: Cloudflare, AWS CloudFront

---

**End of HTML Landing Page Skill**
