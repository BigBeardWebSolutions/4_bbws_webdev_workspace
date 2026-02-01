# React Landing Page Development Skill

**Version:** 1.1.0
**Type:** Implementation Skill
**Last Updated:** 2026-01-03
**Role:** React Developer
**Inherits From:** Web Design Fundamentals Skill
**Technology Stack:** React 18+, Vite, CSS Modules/Styled Components

## Purpose

This skill provides step-by-step guidance for building modern landing pages using React, following component-based architecture and React best practices. It inherits all design principles from the Web Design Fundamentals skill and adds React-specific implementation patterns.

---

## Prerequisites

### Required Knowledge
- React fundamentals (components, props, state, hooks)
- JSX syntax
- ES6+ JavaScript
- CSS-in-JS or CSS Modules
- Node.js and npm/yarn
- Component-based architecture

### Required Tools
- Node.js (v18+ recommended)
- npm or yarn
- VS Code with React extensions
- Git for version control
- React DevTools browser extension

---

## Phase 1: Project Setup

### Step 1.1: Initialize React Project with Vite

```bash
# Create new Vite + React project
npm create vite@latest landing-page-project -- --template react

# Navigate to project
cd landing-page-project

# Install dependencies
npm install

# Start dev server
npm run dev
```

### Step 1.2: Project Structure

```bash
# Create additional directories
mkdir -p src/{components/{layout,common,sections},assets/{images/{logo,hero,features,backgrounds},icons/{social,features}},styles,utils,hooks}

# Project structure
landing-page-project/
├── public/
│   ├── favicon.ico
│   └── robots.txt
├── src/
│   ├── assets/
│   │   ├── images/
│   │   │   ├── logo/
│   │   │   ├── hero/
│   │   │   ├── features/
│   │   │   └── backgrounds/
│   │   └── icons/
│   │       ├── social/
│   │       └── features/
│   ├── components/
│   │   ├── layout/
│   │   │   ├── Header.jsx
│   │   │   ├── Footer.jsx
│   │   │   └── Layout.jsx
│   │   ├── common/
│   │   │   ├── Button.jsx
│   │   │   ├── Card.jsx
│   │   │   └── Section.jsx
│   │   └── sections/
│   │       ├── Hero.jsx
│   │       ├── Features.jsx
│   │       ├── Pricing.jsx
│   │       └── Contact.jsx
│   ├── styles/
│   │   ├── variables.css
│   │   ├── global.css
│   │   └── components/
│   ├── hooks/
│   │   └── useScrollPosition.js
│   ├── utils/
│   │   └── helpers.js
│   ├── App.jsx
│   ├── main.jsx
│   └── index.css
├── .gitignore
├── package.json
├── vite.config.js
└── README.md
```

### Step 1.3: Install Additional Dependencies

```bash
# For routing (if needed)
npm install react-router-dom

# For animations
npm install framer-motion

# For icons
npm install react-icons

# For forms
npm install react-hook-form

# Optional: For styled components
npm install styled-components

# Optional: For CSS modules with Sass
npm install sass
```

### Step 1.4: Configure Vite

**File: `vite.config.js`**
```javascript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      '@components': path.resolve(__dirname, './src/components'),
      '@assets': path.resolve(__dirname, './src/assets'),
      '@styles': path.resolve(__dirname, './src/styles'),
      '@hooks': path.resolve(__dirname, './src/hooks'),
      '@utils': path.resolve(__dirname, './src/utils'),
    }
  },
  build: {
    outDir: 'dist',
    sourcemap: false,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom']
        }
      }
    }
  }
})
```

### Step 1.5: Setup Global Styles

**File: `src/styles/variables.css`**
```css
:root {
  /* Colors */
  --color-primary: #0693e3;
  --color-primary-dark: #0575bd;
  --color-secondary: #9b51e0;
  --color-dark: #1a1f2e;
  --color-gray-900: #252b3d;
  --color-gray-700: #3a4055;
  --color-gray-500: #8a8f9e;
  --color-gray-300: #b8c0d4;
  --color-white: #ffffff;
  --color-info: #00d4ff;

  /* Typography */
  --font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  --font-size-base: 16px;
  --font-size-lg: 18px;
  --font-size-xl: 20px;
  --font-size-2xl: 24px;
  --font-size-3xl: 32px;
  --font-size-4xl: 40px;
  --font-size-5xl: 48px;

  /* Spacing */
  --spacing-1: 8px;
  --spacing-2: 16px;
  --spacing-3: 24px;
  --spacing-4: 32px;
  --spacing-6: 48px;
  --spacing-8: 64px;
  --spacing-10: 80px;

  /* Layout */
  --container-max-width: 1200px;
  --border-radius-md: 8px;
  --border-radius-lg: 16px;

  /* Shadows */
  --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1);
  --shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.1);

  /* Transitions */
  --transition-base: 0.3s ease;
}
```

**File: `src/styles/global.css`**
```css
@import './variables.css';

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

html {
  scroll-behavior: smooth;
}

body {
  font-family: var(--font-family);
  font-size: var(--font-size-base);
  line-height: 1.6;
  color: var(--color-white);
  background-color: var(--color-dark);
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

img {
  max-width: 100%;
  height: auto;
  display: block;
}

a {
  text-decoration: none;
  color: inherit;
}

button {
  font-family: inherit;
  cursor: pointer;
  border: none;
  background: none;
}

.container {
  max-width: var(--container-max-width);
  margin: 0 auto;
  padding: 0 var(--spacing-6);
}
```

---

## Phase 2: Logo Integration

### Step 2.1: Logo Component

**File: `src/components/common/Logo.jsx`**
```jsx
import React from 'react';
import logoImage from '@assets/images/logo/logo.png';
import './Logo.css';

const Logo = ({ variant = 'default', height = 60 }) => {
  return (
    <a href="/" className={`logo logo-${variant}`} aria-label="Company Name Home">
      <img
        src={logoImage}
        alt="Company Name Logo"
        style={{ height: `${height}px`, width: 'auto' }}
        className="logo-image"
      />
    </a>
  );
};

export default Logo;
```

**File: `src/components/common/Logo.css`**
```css
.logo {
  display: inline-flex;
  align-items: center;
  transition: opacity var(--transition-base);
}

.logo:hover {
  opacity: 0.8;
}

.logo-image {
  object-fit: contain;
}

.logo-white .logo-image {
  filter: brightness(0) invert(1);
}

@media (max-width: 767px) {
  .logo-image {
    height: 40px !important;
  }
}
```

### Step 2.2: Logo Assets Setup

```bash
# Copy logo files to assets
cp /path/to/logo.png src/assets/images/logo/
cp /path/to/logo.svg src/assets/images/logo/
cp /path/to/favicon.ico public/
```

**Update `index.html`:**
```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/x-icon" href="/favicon.ico" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content="Your landing page description" />

    <!-- Open Graph -->
    <meta property="og:title" content="Your Page Title" />
    <meta property="og:description" content="Your page description" />
    <meta property="og:image" content="/og-image.jpg" />

    <title>Your Page Title | Company Name</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
```

---

## Phase 3: Navigation Component

### Step 3.1: Header Component

**File: `src/components/layout/Header.jsx`**
```jsx
import React, { useState, useEffect } from 'react';
import Logo from '@components/common/Logo';
import Button from '@components/common/Button';
import './Header.css';

const Header = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isScrolled, setIsScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 50);
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const navItems = [
    { label: 'Home', href: '#home' },
    { label: 'About', href: '#about' },
    { label: 'Services', href: '#services' },
    { label: 'Pricing', href: '#pricing' },
    { label: 'Contact', href: '#contact' }
  ];

  const handleNavClick = () => {
    setIsMenuOpen(false);
  };

  return (
    <header className={`header ${isScrolled ? 'header-scrolled' : ''}`}>
      <nav className="container">
        <div className="nav-wrapper">
          {/* Logo */}
          <Logo height={50} />

          {/* Desktop Navigation */}
          <ul className={`nav-menu ${isMenuOpen ? 'nav-menu-open' : ''}`}>
            {navItems.map((item) => (
              <li key={item.label} className="nav-item">
                <a
                  href={item.href}
                  className="nav-link"
                  onClick={handleNavClick}
                >
                  {item.label}
                </a>
              </li>
            ))}
          </ul>

          {/* CTA Button */}
          <Button
            variant="primary"
            className="nav-cta"
            onClick={() => {
              window.location.href = '#quote';
            }}
          >
            Get A Quote
          </Button>

          {/* Mobile Menu Toggle */}
          <button
            className={`nav-toggle ${isMenuOpen ? 'nav-toggle-active' : ''}`}
            onClick={() => setIsMenuOpen(!isMenuOpen)}
            aria-label="Toggle navigation menu"
            aria-expanded={isMenuOpen}
          >
            <span className="nav-toggle-icon"></span>
            <span className="nav-toggle-icon"></span>
            <span className="nav-toggle-icon"></span>
          </button>
        </div>
      </nav>
    </header>
  );
};

export default Header;
```

**File: `src/components/layout/Header.css`**
```css
.header {
  position: sticky;
  top: 0;
  z-index: 1000;
  background-color: var(--color-dark);
  transition: box-shadow var(--transition-base), background-color var(--transition-base);
}

.header-scrolled {
  box-shadow: var(--shadow-md);
  background-color: rgba(26, 31, 46, 0.95);
  backdrop-filter: blur(10px);
}

.nav-wrapper {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--spacing-3) 0;
  gap: var(--spacing-4);
}

.nav-menu {
  display: flex;
  align-items: center;
  gap: var(--spacing-6);
  list-style: none;
}

.nav-link {
  font-size: var(--font-size-base);
  font-weight: 500;
  color: var(--color-white);
  transition: color var(--transition-base);
  position: relative;
}

.nav-link:hover {
  color: var(--color-info);
}

.nav-link::after {
  content: '';
  position: absolute;
  bottom: -4px;
  left: 0;
  width: 0;
  height: 2px;
  background-color: var(--color-info);
  transition: width var(--transition-base);
}

.nav-link:hover::after {
  width: 100%;
}

.nav-cta {
  display: none;
}

.nav-toggle {
  display: none;
  flex-direction: column;
  gap: 6px;
  padding: var(--spacing-1);
  background: transparent;
  border: none;
  cursor: pointer;
}

.nav-toggle-icon {
  width: 25px;
  height: 2px;
  background-color: var(--color-white);
  transition: all var(--transition-base);
}

@media (min-width: 1024px) {
  .nav-cta {
    display: inline-flex;
  }
}

@media (max-width: 1023px) {
  .nav-toggle {
    display: flex;
  }

  .nav-menu {
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

  .nav-menu-open {
    transform: translateY(0);
    opacity: 1;
    visibility: visible;
  }

  .nav-toggle-active .nav-toggle-icon:nth-child(1) {
    transform: rotate(45deg) translate(6px, 6px);
  }

  .nav-toggle-active .nav-toggle-icon:nth-child(2) {
    opacity: 0;
  }

  .nav-toggle-active .nav-toggle-icon:nth-child(3) {
    transform: rotate(-45deg) translate(6px, -6px);
  }
}
```

---

## Phase 4: Reusable Components

### Step 4.1: Button Component

**File: `src/components/common/Button.jsx`**
```jsx
import React from 'react';
import './Button.css';

const Button = ({
  children,
  variant = 'primary',
  size = 'md',
  onClick,
  type = 'button',
  disabled = false,
  className = '',
  ...props
}) => {
  return (
    <button
      type={type}
      className={`btn btn-${variant} btn-${size} ${className}`}
      onClick={onClick}
      disabled={disabled}
      {...props}
    >
      {children}
    </button>
  );
};

export default Button;
```

**File: `src/components/common/Button.css`**
```css
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--spacing-1);
  font-weight: 600;
  border-radius: var(--border-radius-md);
  transition: all var(--transition-base);
  cursor: pointer;
  border: none;
}

.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Variants */
.btn-primary {
  background-color: var(--color-info);
  color: var(--color-dark);
}

.btn-primary:hover:not(:disabled) {
  background-color: #00c4eb;
  transform: translateY(-2px);
  box-shadow: var(--shadow-lg);
}

.btn-outline {
  background-color: transparent;
  color: var(--color-white);
  border: 1px solid var(--color-info);
}

.btn-outline:hover:not(:disabled) {
  background-color: var(--color-info);
  color: var(--color-dark);
}

/* Sizes */
.btn-sm {
  padding: 8px 16px;
  font-size: 14px;
}

.btn-md {
  padding: 12px 24px;
  font-size: 16px;
}

.btn-lg {
  padding: 16px 32px;
  font-size: 18px;
}
```

### Step 4.2: Section Component

**File: `src/components/common/Section.jsx`**
```jsx
import React from 'react';
import './Section.css';

const Section = ({
  id,
  children,
  className = '',
  background = 'default',
  padding = 'normal'
}) => {
  return (
    <section
      id={id}
      className={`section section-bg-${background} section-padding-${padding} ${className}`}
    >
      <div className="container">
        {children}
      </div>
    </section>
  );
};

export default Section;
```

**File: `src/components/common/Section.css`**
```css
.section {
  position: relative;
}

.section-padding-normal {
  padding: var(--spacing-10) 0;
}

.section-padding-large {
  padding: calc(var(--spacing-10) * 1.5) 0;
}

.section-padding-small {
  padding: var(--spacing-8) 0;
}

.section-bg-default {
  background-color: var(--color-dark);
}

.section-bg-dark {
  background-color: var(--color-gray-900);
}

.section-bg-light {
  background-color: var(--color-white);
  color: var(--color-dark);
}

@media (max-width: 767px) {
  .section-padding-normal {
    padding: var(--spacing-8) 0;
  }

  .section-padding-large {
    padding: var(--spacing-10) 0;
  }

  .section-padding-small {
    padding: var(--spacing-6) 0;
  }
}
```

---

## Phase 5: Page Sections

### Step 5.1: Hero Section Component

**File: `src/components/sections/Hero.jsx`**
```jsx
import React from 'react';
import Button from '@components/common/Button';
import heroBackground from '@assets/images/hero/hero-bg.jpg';
import './Hero.css';

const Hero = () => {
  return (
    <section id="home" className="hero">
      <div
        className="hero-background"
        style={{ backgroundImage: `url(${heroBackground})` }}
      />
      <div className="container">
        <div className="hero-content">
          <h1 className="hero-title">
            Build Your Dream Website Today
          </h1>
          <p className="hero-subtitle">
            Professional web solutions tailored to your business needs.
            Fast, reliable, and beautifully designed.
          </p>
          <div className="hero-actions">
            <Button variant="primary" size="lg" onClick={() => window.location.href = '#pricing'}>
              View Pricing
            </Button>
            <Button variant="outline" size="lg" onClick={() => window.location.href = '#about'}>
              Learn More
            </Button>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Hero;
```

**File: `src/components/sections/Hero.css`**
```css
.hero {
  position: relative;
  min-height: 80vh;
  display: flex;
  align-items: center;
  padding: var(--spacing-10) 0;
  overflow: hidden;
}

.hero-background {
  position: absolute;
  inset: 0;
  background-size: cover;
  background-position: center;
  z-index: -1;
}

.hero-background::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.5));
}

.hero-content {
  max-width: 600px;
  color: var(--color-white);
}

.hero-title {
  font-size: var(--font-size-5xl);
  font-weight: 700;
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

### Step 5.2: Features Section Component

**File: `src/components/sections/Features.jsx`**
```jsx
import React from 'react';
import Section from '@components/common/Section';
import { FaMobile, FaBolt, FaLock } from 'react-icons/fa';
import './Features.css';

const Features = () => {
  const features = [
    {
      icon: <FaMobile size={48} />,
      title: 'Responsive Design',
      description: 'Your website will look perfect on all devices, from mobile to desktop.'
    },
    {
      icon: <FaBolt size={48} />,
      title: 'Lightning Fast',
      description: 'Optimized for speed with cutting-edge performance techniques.'
    },
    {
      icon: <FaLock size={48} />,
      title: 'Secure & Reliable',
      description: 'Built with security best practices and 99.9% uptime guarantee.'
    }
  ];

  return (
    <Section id="services" background="dark">
      <div className="section-header">
        <h2 className="section-title">Our Services</h2>
        <p className="section-description">
          Everything you need to succeed online
        </p>
      </div>

      <div className="features-grid">
        {features.map((feature, index) => (
          <div key={index} className="feature-card">
            <div className="feature-icon">
              {feature.icon}
            </div>
            <h3 className="feature-title">{feature.title}</h3>
            <p className="feature-description">{feature.description}</p>
          </div>
        ))}
      </div>
    </Section>
  );
};

export default Features;
```

**File: `src/components/sections/Features.css`**
```css
.section-header {
  text-align: center;
  margin-bottom: var(--spacing-8);
}

.section-title {
  font-size: var(--font-size-4xl);
  font-weight: 700;
  margin-bottom: var(--spacing-2);
}

.section-description {
  font-size: var(--font-size-lg);
  color: var(--color-gray-300);
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
  box-shadow: var(--shadow-lg);
}

.feature-icon {
  width: 80px;
  height: 80px;
  margin: 0 auto var(--spacing-3);
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(0, 212, 255, 0.1);
  border-radius: var(--border-radius-md);
  color: var(--color-info);
}

.feature-title {
  font-size: var(--font-size-2xl);
  font-weight: 600;
  margin-bottom: var(--spacing-2);
}

.feature-description {
  color: var(--color-gray-300);
  line-height: 1.6;
}
```

### Step 5.3: Footer Component

**File: `src/components/layout/Footer.jsx`**
```jsx
import React from 'react';
import Logo from '@components/common/Logo';
import { FaFacebook, FaTwitter, FaLinkedin, FaInstagram } from 'react-icons/fa';
import './Footer.css';

const Footer = () => {
  const currentYear = new Date().getFullYear();

  const footerLinks = {
    quickLinks: [
      { label: 'Home', href: '#home' },
      { label: 'About', href: '#about' },
      { label: 'Services', href: '#services' },
      { label: 'Pricing', href: '#pricing' }
    ],
    contact: [
      { label: 'Email: info@company.com', href: 'mailto:info@company.com' },
      { label: 'Phone: +27 12 345 6789', href: 'tel:+27123456789' },
      { label: 'Address: 123 Street, City, Country' }
    ]
  };

  const socialLinks = [
    { icon: <FaFacebook />, href: '#', label: 'Facebook' },
    { icon: <FaTwitter />, href: '#', label: 'Twitter' },
    { icon: <FaLinkedin />, href: '#', label: 'LinkedIn' },
    { icon: <FaInstagram />, href: '#', label: 'Instagram' }
  ];

  return (
    <footer className="footer">
      <div className="container">
        <div className="footer-grid">
          {/* Company Info */}
          <div className="footer-column">
            <Logo variant="white" height={40} />
            <p className="footer-description">
              Building beautiful websites that drive results.
            </p>
            <div className="footer-social">
              {socialLinks.map((social, index) => (
                <a
                  key={index}
                  href={social.href}
                  className="social-link"
                  aria-label={social.label}
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {social.icon}
                </a>
              ))}
            </div>
          </div>

          {/* Quick Links */}
          <div className="footer-column">
            <h4 className="footer-heading">Quick Links</h4>
            <ul className="footer-links">
              {footerLinks.quickLinks.map((link, index) => (
                <li key={index}>
                  <a href={link.href}>{link.label}</a>
                </li>
              ))}
            </ul>
          </div>

          {/* Contact */}
          <div className="footer-column">
            <h4 className="footer-heading">Contact</h4>
            <ul className="footer-links">
              {footerLinks.contact.map((link, index) => (
                <li key={index}>
                  {link.href ? (
                    <a href={link.href}>{link.label}</a>
                  ) : (
                    <span>{link.label}</span>
                  )}
                </li>
              ))}
            </ul>
          </div>
        </div>

        <div className="footer-bottom">
          <p>&copy; {currentYear} Company Name. All rights reserved.</p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
```

**File: `src/components/layout/Footer.css`**
```css
.footer {
  background-color: var(--color-dark);
  padding: var(--spacing-10) 0 var(--spacing-4);
}

.footer-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: var(--spacing-6);
  margin-bottom: var(--spacing-6);
}

.footer-description {
  color: var(--color-gray-300);
  margin: var(--spacing-3) 0;
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
  color: var(--color-white);
  font-size: 20px;
  transition: all var(--transition-base);
}

.social-link:hover {
  background-color: var(--color-info);
  color: var(--color-dark);
  transform: translateY(-2px);
}

.footer-heading {
  font-size: var(--font-size-lg);
  font-weight: 600;
  margin-bottom: var(--spacing-3);
}

.footer-links {
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: var(--spacing-2);
}

.footer-links a,
.footer-links span {
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

## Phase 6: Main App Component

### Step 6.1: App.jsx

**File: `src/App.jsx`**
```jsx
import React from 'react';
import Header from '@components/layout/Header';
import Footer from '@components/layout/Footer';
import Hero from '@components/sections/Hero';
import Features from '@components/sections/Features';
import '@styles/global.css';

function App() {
  return (
    <div className="app">
      <Header />
      <main>
        <Hero />
        <Features />
        {/* Add more sections as needed */}
      </main>
      <Footer />
    </div>
  );
}

export default App;
```

### Step 6.2: main.jsx

**File: `src/main.jsx`**
```jsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App.jsx';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

---

## Custom Hooks

### useScrollPosition Hook

**File: `src/hooks/useScrollPosition.js`**
```javascript
import { useState, useEffect } from 'react';

const useScrollPosition = () => {
  const [scrollPosition, setScrollPosition] = useState(0);

  useEffect(() => {
    const handleScroll = () => {
      setScrollPosition(window.scrollY);
    };

    window.addEventListener('scroll', handleScroll, { passive: true });

    return () => {
      window.removeEventListener('scroll', handleScroll);
    };
  }, []);

  return scrollPosition;
};

export default useScrollPosition;
```

### useMediaQuery Hook

**File: `src/hooks/useMediaQuery.js`**
```javascript
import { useState, useEffect } from 'react';

const useMediaQuery = (query) => {
  const [matches, setMatches] = useState(false);

  useEffect(() => {
    const media = window.matchMedia(query);
    if (media.matches !== matches) {
      setMatches(media.matches);
    }

    const listener = () => setMatches(media.matches);
    media.addEventListener('change', listener);

    return () => media.removeEventListener('change', listener);
  }, [matches, query]);

  return matches;
};

export default useMediaQuery;
```

---

## Performance Optimization

### Code Splitting

```jsx
import React, { lazy, Suspense } from 'react';

const Hero = lazy(() => import('@components/sections/Hero'));
const Features = lazy(() => import('@components/sections/Features'));
const Pricing = lazy(() => import('@components/sections/Pricing'));

function App() {
  return (
    <div className="app">
      <Header />
      <main>
        <Suspense fallback={<div>Loading...</div>}>
          <Hero />
          <Features />
          <Pricing />
        </Suspense>
      </main>
      <Footer />
    </div>
  );
}
```

### Image Optimization

```jsx
// Use dynamic imports for images
const heroImage = new URL('@assets/images/hero/hero-bg.jpg', import.meta.url).href;

// Lazy load images
<img
  src={heroImage}
  alt="Hero"
  loading="lazy"
  decoding="async"
/>
```

### Memoization

```jsx
import React, { memo, useMemo, useCallback } from 'react';

const FeatureCard = memo(({ feature }) => {
  return (
    <div className="feature-card">
      {/* Card content */}
    </div>
  );
});

const Features = () => {
  const features = useMemo(() => [
    // features array
  ], []);

  const handleClick = useCallback((id) => {
    console.log('Clicked:', id);
  }, []);

  return (
    <div className="features-grid">
      {features.map((feature) => (
        <FeatureCard key={feature.id} feature={feature} />
      ))}
    </div>
  );
};
```

---

## Testing

### Component Testing with Vitest

**Install dependencies:**
```bash
npm install -D vitest @testing-library/react @testing-library/jest-dom
```

**Example test:**
```jsx
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import Button from '@components/common/Button';

describe('Button component', () => {
  it('renders with correct text', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByText('Click me')).toBeInTheDocument();
  });

  it('applies correct variant class', () => {
    render(<Button variant="primary">Primary</Button>);
    const button = screen.getByText('Primary');
    expect(button).toHaveClass('btn-primary');
  });
});
```

---

## Build and Deployment

### Build for Production

```bash
# Build the project
npm run build

# Preview the production build
npm run preview
```

### Deployment Options

1. **Vercel** (Recommended for React)
```bash
npm install -g vercel
vercel
```

2. **Netlify**
```bash
npm install -g netlify-cli
netlify deploy --prod
```

3. **GitHub Pages**
```bash
npm install -D gh-pages

# Add to package.json scripts:
"predeploy": "npm run build",
"deploy": "gh-pages -d dist"

# Deploy:
npm run deploy
```

---

## Best Practices

### Component Organization
- One component per file
- Use functional components with hooks
- Keep components small and focused
- Use PropTypes or TypeScript for type checking

### State Management
- Use local state for component-specific data
- Lift state up when needed
- Consider Context API for global state
- Use custom hooks for shared logic

### Performance
- Memoize expensive calculations
- Use React.memo for pure components
- Implement code splitting
- Lazy load below-fold content
- Optimize images

### Accessibility
- Use semantic HTML
- Add ARIA labels where needed
- Ensure keyboard navigation
- Test with screen readers
- Maintain focus management

---

## Environment Configuration (Multi-Environment)

### Environment-Aware API Configuration

**File: `src/services/api.config.ts`**
```typescript
interface ApiConfig {
  baseUrl: string;
  apiKey: string;
  endpoint: string;
}

type Environment = 'development' | 'production' | 'test';

const API_CONFIG: Record<Environment, ApiConfig> = {
  development: {
    baseUrl: 'https://api.dev.example.com',
    apiKey: import.meta.env.VITE_ORDER_API_KEY || '',
    endpoint: '/v1.0/resource'
  },
  production: {
    baseUrl: 'https://api.example.com',
    apiKey: import.meta.env.VITE_ORDER_API_KEY || '',
    endpoint: '/v1.0/resource'
  },
  test: {
    baseUrl: 'https://api.dev.example.com',
    apiKey: import.meta.env.VITE_ORDER_API_KEY || '',
    endpoint: '/v1.0/resource'
  }
};

// Use VITE_ENV for explicit environment control
const getEnvironment = (): Environment => {
  return (import.meta.env.VITE_ENV || import.meta.env.MODE || 'development') as Environment;
};

export const getApiConfig = (): ApiConfig => {
  const env = getEnvironment();
  return API_CONFIG[env] || API_CONFIG.development;
};
```

### Environment Files

```bash
# .env.development (local dev)
VITE_ENV=development
VITE_API_BASE_URL=https://api.dev.example.com
VITE_ORDER_API_KEY=dev-api-key

# .env.production (production build)
VITE_ENV=production
VITE_API_BASE_URL=https://api.example.com
VITE_ORDER_API_KEY=${PROD_ORDER_API_KEY}

# .env.sit (SIT environment)
VITE_ENV=sit
VITE_API_BASE_URL=https://api.sit.example.com
VITE_ORDER_API_KEY=${SIT_ORDER_API_KEY}
```

### Build Commands

```bash
# Build for different environments
npm run build                    # Uses .env.production
npm run build -- --mode development  # Uses .env.development
npm run build -- --mode sit      # Uses .env.sit
```

---

## Form Field Mapping (Frontend to Backend)

### Field Transformation Pattern

```typescript
interface FrontendFormData {
  fullName: string;
  email: string;
  phone: string;
  address: string;
  city: string;
  postalCode: string;
}

interface BackendPayload {
  customerEmail: string;
  firstName: string;
  lastName: string;
  primaryPhone: string;
  billingAddress: {
    street: string;
    city: string;
    postalCode: string;
    country: string;
  };
}

const transformToBackendPayload = (formData: FrontendFormData): BackendPayload => {
  // Split full name into first and last
  const nameParts = formData.fullName.trim().split(/\s+/);
  const firstName = nameParts[0] || '';
  const lastName = nameParts.slice(1).join(' ') || nameParts[0] || '';

  return {
    customerEmail: formData.email.trim().toLowerCase(),
    firstName,
    lastName,
    primaryPhone: formData.phone.trim(),
    billingAddress: {
      street: formData.address.trim(),
      city: formData.city.trim(),
      postalCode: formData.postalCode.trim(),
      country: 'ZA' // Default country
    }
  };
};
```

### Field Mapping Table Pattern

| Frontend Field | Backend Field | Transformation |
|----------------|---------------|----------------|
| `fullName` | `firstName` + `lastName` | Split on whitespace |
| `email` | `customerEmail` | Lowercase, trim |
| `phone` | `primaryPhone` | Trim, E.164 format |
| `address` | `billingAddress.street` | Direct mapping |

---

## API Error Handling

### Custom Error Classes

```typescript
export class OrderValidationError extends Error {
  field: string;
  originalError: string;

  constructor(field: string, message: string, originalError: string) {
    super(message);
    this.name = 'OrderValidationError';
    this.field = field;
    this.originalError = originalError;
  }
}

// Backend error response interface
interface BackendValidationError {
  error: string;
  errorCode: string;
  details?: {
    field: string;
    [key: string]: unknown;
  };
}
```

### Error Parsing and Field Mapping

```typescript
// Map backend field names to frontend field names
const FIELD_MAPPING: Record<string, string> = {
  'customerEmail': 'email',
  'firstName': 'fullName',
  'lastName': 'fullName',
  'primaryPhone': 'phone',
  'billingAddress.street': 'address',
  'billingAddress.city': 'city',
  'billingAddress.postalCode': 'postalCode'
};

const parseBackendError = (error: BackendValidationError): { field: string; message: string } => {
  let field = 'form'; // Default to generic form error
  let message = error.error;

  if (error.details?.field) {
    const backendField = error.details.field;
    field = FIELD_MAPPING[backendField] || backendField;
  } else {
    // Try to detect field from error message
    for (const [backendField, frontendField] of Object.entries(FIELD_MAPPING)) {
      if (error.error.toLowerCase().includes(backendField.toLowerCase())) {
        field = frontendField;
        break;
      }
    }
  }

  return { field, message };
};
```

### API Call with Error Handling

```typescript
export const submitOrder = async (formData: FormData): Promise<OrderResponse> => {
  const config = getApiConfig();
  const url = `${config.baseUrl}${config.endpoint}`;

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Api-Key': config.apiKey
      },
      body: JSON.stringify(transformToBackendPayload(formData))
    });

    const data = await response.json();

    if (!response.ok) {
      if (response.status === 400 && data.errorCode) {
        const { field, message } = parseBackendError(data);
        throw new OrderValidationError(field, message, data.error);
      }
      throw new Error(data.error || 'Request failed');
    }

    return data;
  } catch (error) {
    if (error instanceof OrderValidationError) throw error;
    throw new Error('Unable to connect to server. Please try again.');
  }
};
```

---

## CORS Configuration Requirements

### Required Headers for API Gateway

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Headers: Content-Type,Authorization,X-Tenant-Id,X-Api-Key,Accept
Access-Control-Allow-Methods: GET,POST,PUT,DELETE,OPTIONS
```

### Frontend Fetch Headers

```typescript
const headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'X-Api-Key': apiKey
};
```

---

## Deployment to AWS S3/CloudFront

### Build and Deploy Script

```bash
#!/bin/bash

# Build for production
npm run build

# Sync to S3
aws s3 sync dist/ s3://bucket-name/path/ --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id DISTRIBUTION_ID \
  --paths "/path/*"
```

### CloudFront Invalidation (after deployment)

```bash
# Invalidate specific paths
aws cloudfront create-invalidation \
  --distribution-id E2U6ZEDEHW56SB \
  --paths "/buy/*" "/buy/index.html" "/buy/assets/*"
```

---

## Lessons Learned

### 1. Vite Environment Variables

- `import.meta.env.MODE` is set by Vite based on build command
- For explicit environment control, use custom `VITE_ENV` variable
- Environment files: `.env.development`, `.env.production`, `.env.[mode]`

### 2. API Key Exposure

- Never hardcode API keys in source code
- Use environment variables: `import.meta.env.VITE_API_KEY`
- For production, inject keys during CI/CD pipeline

### 3. CORS Preflight

- Browser sends OPTIONS request before actual request
- Must include all custom headers in `Access-Control-Allow-Headers`
- Both OPTIONS (API Gateway) and actual responses (Lambda) need CORS headers

### 4. Field Validation Errors

- Backend validation errors should include field name in `details.field`
- Frontend maps backend field names to form field names
- Display errors at field level for better UX

### 5. CloudFront Caching

- Changes to S3 may not reflect immediately due to CDN caching
- Always invalidate CloudFront after deployment
- Use unique filenames (hash in filename) for cache busting

---

## AWS CloudFront + S3 SPA Deployment (Critical Lessons)

### Problem: CloudFront Custom Error Responses with Subdirectories

When deploying a React SPA to a subdirectory (e.g., `/buy/`), CloudFront's custom error responses can cause unexpected behavior.

**Scenario**: CloudFront configured with:
```json
{
  "ErrorCode": 404,
  "ResponsePagePath": "/index.html",
  "ResponseCode": "200"
}
```

**Issue**: When accessing `/buy/`, if S3 returns 403/404 (directory access), CloudFront serves `/index.html` from the **S3 bucket root**, NOT `/buy/index.html`.

**Symptoms**:
- Old version of app served despite S3 having new files
- Cache invalidations seem to have no effect
- `/buy/` serves different content than `/buy/index.html`

**Root Cause Diagram**:
```
User requests: https://dev.example.com/buy/
     ↓
CloudFront → S3: GET /buy/
     ↓
S3 returns: 403 Forbidden (directory listing denied)
     ↓
CloudFront Custom Error Response: Serve /index.html (ROOT!)
     ↓
User gets: OLD /index.html (not /buy/index.html)
```

### Solution: Deploy to Both Root and Subdirectory

```bash
# 1. Build for your environment
npm run build:dev

# 2. Deploy to subdirectory path
aws s3 sync dist/ s3://bucket-name/buy/ --delete

# 3. CRITICAL: Also update root for CloudFront error fallback
aws s3 cp dist/index.html s3://bucket-name/index.html
aws s3 sync dist/assets/ s3://bucket-name/assets/

# 4. Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id DISTRIBUTION_ID \
  --paths "/*" "/index.html" "/buy/*" "/assets/*"
```

### Alternative Solution: Update CloudFront Error Response

Change the error response to serve the subdirectory's index.html:

```json
{
  "ErrorCode": 404,
  "ResponsePagePath": "/buy/index.html",
  "ResponseCode": "200"
}
```

**Note**: This only works if you have a single SPA. For multiple SPAs, use the root deployment approach.

---

## Diagnosing "Unable to Connect to Server" Errors

### Systematic Diagnostic Workflow

When users report "Unable to connect to server" in a React app:

**Step 1: Identify the actual URL being called**
```bash
# Download deployed JS and check API URL
curl -s "https://site.com/buy/assets/index-*.js" --compressed | \
  grep -oE "https://api\.[a-z.]*example\.com" | sort | uniq
```

**Step 2: Compare with expected URL**
| Environment | Expected URL |
|-------------|--------------|
| DEV | `api.dev.example.com` |
| SIT | `api.sit.example.com` |
| PROD | `api.example.com` |

**Step 3: If URL is wrong, check the build source**
```bash
# Check which JS file index.html references
curl -s "https://site.com/buy/" | grep -oE 'assets/index-[^"]+\.js'

# Check if CloudFront is serving stale index.html
# Compare /buy/ vs /buy/index.html
curl -s "https://site.com/buy/" | grep 'index-'
curl -s "https://site.com/buy/index.html" | grep 'index-'
```

**Step 4: If different files served, check S3 root**
```bash
# The root index.html might be outdated
aws s3 cp s3://bucket/index.html - | grep 'index-'
```

### Common Error Messages and Root Causes

| Browser Error | API Response | Root Cause |
|---------------|--------------|------------|
| "Unable to connect to server" | `ERR_NAME_NOT_RESOLVED` | Wrong API domain (doesn't exist) |
| "Unable to connect to server" | `ERR_CONNECTION_REFUSED` | API server down |
| Network error | `{"message":"Missing Authentication Token"}` | Wrong API path |
| Network error | `{"message":"Forbidden"}` | Missing/invalid API key |
| CORS error | No response | API missing CORS headers |

### Quick Diagnostic Commands

```bash
# Test 1: Frontend accessible?
curl -s -o /dev/null -w "%{http_code}" "https://site.com/buy/"

# Test 2: API CORS preflight?
curl -s -X OPTIONS "https://api.example.com/endpoint" \
  -H "Origin: https://site.com" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type,X-Api-Key" \
  -w "%{http_code}"

# Test 3: API POST works?
curl -s -X POST "https://api.example.com/endpoint" \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: YOUR_KEY" \
  -d '{"test":"data"}'

# Test 4: Check API URL in deployed JS
curl -s "https://site.com/buy/assets/index-*.js" --compressed | \
  grep -oE "https://api\.[a-z.]*example\.com" | sort | uniq

# Test 5: Compare MD5 hashes (local vs deployed)
md5 dist/assets/index-*.js
curl -s "https://site.com/buy/assets/index-*.js" --compressed > /tmp/deployed.js
md5 /tmp/deployed.js
```

---

## Vite Build Modes and Environment Files

### How Vite Loads Environment Files

```
vite build                    → MODE=production → loads .env.production
vite build --mode development → MODE=development → loads .env.development
vite build --mode sit         → MODE=sit → loads .env.sit
```

### Recommended package.json Scripts

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "build:dev": "vite build --mode development",
    "build:sit": "vite build --mode sit",
    "build:prod": "vite build --mode production"
  }
}
```

### Environment File Template

```bash
# .env.development
VITE_ENV=development
VITE_API_BASE_URL=https://api.dev.example.com
VITE_ORDER_API_KEY=dev-api-key-here
VITE_ORDER_API_ENDPOINT=/orders/v1.0/orders
VITE_DEBUG_MODE=true

# .env.sit
VITE_ENV=sit
VITE_API_BASE_URL=https://api.sit.example.com
VITE_ORDER_API_KEY=${SIT_API_KEY}
VITE_ORDER_API_ENDPOINT=/orders/v1.0/orders
VITE_DEBUG_MODE=false

# .env.production
VITE_ENV=production
VITE_API_BASE_URL=https://api.example.com
VITE_ORDER_API_KEY=${PROD_API_KEY}
VITE_ORDER_API_ENDPOINT=/orders/v1.0/orders
VITE_DEBUG_MODE=false
```

### Centralized Config Module Pattern

```typescript
// src/config/index.ts
export type Environment = 'development' | 'sit' | 'production';

export interface AppConfig {
  env: Environment;
  api: {
    baseUrl: string;
    orderEndpoint: string;
    orderApiKey: string;
    timeout: number;
  };
  features: {
    debugMode: boolean;
  };
}

const getEnvironment = (): Environment => {
  // Prefer explicit VITE_ENV over Vite's MODE
  const env = import.meta.env.VITE_ENV as string;
  if (env === 'sit' || env === 'production' || env === 'development') {
    return env;
  }
  return import.meta.env.MODE === 'production' ? 'production' : 'development';
};

export const config: AppConfig = {
  env: getEnvironment(),
  api: {
    baseUrl: import.meta.env.VITE_API_BASE_URL || 'https://api.dev.example.com',
    orderEndpoint: import.meta.env.VITE_ORDER_API_ENDPOINT || '/orders/v1.0/orders',
    orderApiKey: import.meta.env.VITE_ORDER_API_KEY || '',
    timeout: 15000,
  },
  features: {
    debugMode: import.meta.env.VITE_DEBUG_MODE === 'true',
  },
};

export const getOrderApiUrl = (): string => {
  return `${config.api.baseUrl}${config.api.orderEndpoint}`;
};

export const getApiHeaders = (): Record<string, string> => ({
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'X-Api-Key': config.api.orderApiKey,
});
```

---

## CloudFront Cache Invalidation Best Practices

### When to Invalidate

1. After every S3 deployment
2. When index.html changes (new JS bundle hash)
3. When debugging stale content issues

### Invalidation Commands

```bash
# Invalidate specific paths
aws cloudfront create-invalidation \
  --distribution-id E2U6ZEDEHW56SB \
  --paths "/buy/*"

# Invalidate everything (more expensive but thorough)
aws cloudfront create-invalidation \
  --distribution-id E2U6ZEDEHW56SB \
  --paths "/*"

# Invalidate specific files including directory paths
aws cloudfront create-invalidation \
  --distribution-id E2U6ZEDEHW56SB \
  --paths "/buy" "/buy/" "/buy/index.html" "/buy/assets/*" "/index.html" "/assets/*"
```

### Cache Headers for S3 Objects

```bash
# HTML files - no caching (always fetch fresh)
aws s3 cp dist/index.html s3://bucket/index.html \
  --cache-control "no-cache, no-store, must-revalidate" \
  --content-type "text/html"

# JS/CSS files with hash in filename - long cache
aws s3 cp dist/assets/index-abc123.js s3://bucket/assets/index-abc123.js \
  --cache-control "max-age=31536000" \
  --content-type "application/javascript"
```

---

## UI Testing Agent Pattern

### Systematic Test Workflow

When testing frontend-backend integration:

```markdown
## UI Test Report - [Environment]

### 1. Accessibility Tests
| Component | URL | Status | HTTP Code |
|-----------|-----|--------|-----------|
| Frontend | site.com/buy/ | ✅/❌ | 200/4xx |
| API CORS | api.site.com/endpoint | ✅/❌ | 200/4xx |
| API POST | api.site.com/endpoint | ✅/❌ | 200/4xx |

### 2. Configuration Verification
| Setting | Expected | Actual | Match |
|---------|----------|--------|-------|
| API Base URL | api.dev.site.com | api.dev.site.com | ✅/❌ |
| API Endpoint | /orders/v1.0/orders | /orders/v1.0/orders | ✅/❌ |
| API Key | Present | Present | ✅/❌ |

### 3. Asset Verification
| Check | Local | Deployed | Match |
|-------|-------|----------|-------|
| JS File | index-6gTx.js | index-6gTx.js | ✅/❌ |
| MD5 Hash | 65b1b406... | 65b1b406... | ✅/❌ |

### 4. Issues Found
- [Issue description with root cause]

### 5. Recommended Fixes
- [Specific commands to fix each issue]
```

---

## Complete Deployment Checklist

### Pre-Deployment
- [ ] Verify `.env.[environment]` has correct API URLs
- [ ] Run `npm run build:[environment]`
- [ ] Check built JS contains correct API URL: `grep -o "api\\..*\\.com" dist/assets/*.js`

### Deployment
- [ ] Sync to S3 subdirectory: `aws s3 sync dist/ s3://bucket/buy/`
- [ ] Update root index.html: `aws s3 cp dist/index.html s3://bucket/index.html`
- [ ] Update root assets: `aws s3 sync dist/assets/ s3://bucket/assets/`
- [ ] Create CloudFront invalidation: `aws cloudfront create-invalidation --paths "/*"`

### Post-Deployment Verification
- [ ] Wait for invalidation to complete
- [ ] Test `/buy/` returns correct JS file reference
- [ ] Test `/buy/index.html` returns same content
- [ ] Verify API URL in deployed JS matches expected
- [ ] Test actual API call from browser

---

**End of React Landing Page Skill**
