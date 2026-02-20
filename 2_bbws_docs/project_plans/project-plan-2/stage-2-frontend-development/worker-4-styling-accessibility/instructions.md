# Worker 2-4: Styling & Accessibility

**Worker ID**: worker-4-styling-accessibility
**Stage**: Stage 2 - Frontend Development
**Status**: PENDING
**Agent**: Web Developer Agent
**Repository**: `2_1_bbws_web_public`

---

## Objective

Apply comprehensive Tailwind CSS styling and ensure WCAG 2.1 Level AA accessibility compliance across all buy page components.

---

## Prerequisites

- ✅ Worker 2-1 complete (Buy page structure)
- ✅ Worker 2-2 complete (Product components)
- ✅ Worker 2-3 complete (API integration)
- Tailwind CSS installed and configured

---

## Input Documents

1. **Frontend Requirements**: `../stage-1-requirements-design/worker-1-frontend-requirements/output.md`
   - Section 8: Accessibility Requirements (WCAG 2.1 Level AA)
   - Section 5: Responsive Design

---

## Tasks

### 1. Verify Tailwind CSS Configuration

**File**: `tailwind.config.js`

Ensure Tailwind is properly configured:

```javascript
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#1e3a8a',
        },
      },
      spacing: {
        '128': '32rem',
        '144': '36rem',
      },
      screens: {
        'xs': '475px',
      },
    },
  },
  plugins: [],
}
```

---

### 2. Refine Component Styling

#### 2.1 ProductCard Styling Enhancements

**File**: `src/components/products/ProductCard.tsx` (Update)

**Enhancements**:
- Enhanced hover effects
- Focus states for accessibility
- Better visual hierarchy
- Consistent spacing

```typescript
export const ProductCard: React.FC<ProductCardProps> = ({ product, onSelect }) => {
  return (
    <div className="product-card group relative bg-white rounded-xl shadow-md hover:shadow-2xl transition-all duration-300 p-8 flex flex-col h-full border-2 border-gray-100 hover:border-blue-500">
      {/* Popular Badge (conditional) */}
      {product.name === 'Standard' && (
        <div className="absolute top-0 right-8 transform -translate-y-1/2">
          <span className="bg-blue-600 text-white text-xs font-bold px-3 py-1 rounded-full uppercase tracking-wide">
            Popular
          </span>
        </div>
      )}

      {/* Product Header */}
      <div className="product-header mb-6">
        <h3 className="text-2xl font-bold text-gray-900 group-hover:text-blue-600 transition-colors">
          {product.name}
        </h3>
        <p className="mt-3 text-base text-gray-600 leading-relaxed">
          {product.description}
        </p>
      </div>

      {/* Pricing */}
      <div className="product-pricing mb-8">
        <div className="flex items-baseline">
          <span className="text-5xl font-extrabold text-gray-900">
            {product.currency === 'USD' ? '$' : product.currency}
            {product.price.toFixed(2)}
          </span>
          <span className="ml-2 text-lg text-gray-500 font-medium">
            / {product.period}
          </span>
        </div>
      </div>

      {/* Features */}
      <div className="product-features mb-8 flex-grow">
        <ProductFeatureList features={product.features} />
      </div>

      {/* CTA Button */}
      <div className="product-cta mt-auto">
        <button
          onClick={handleSelect}
          className="w-full bg-blue-600 text-white font-semibold text-base py-4 px-6 rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-4 focus:ring-blue-300 focus:ring-offset-2 transform hover:-translate-y-0.5 transition-all duration-200 active:translate-y-0"
          aria-label={`Select ${product.name} plan for ${product.currency}${product.price} per ${product.period}`}
        >
          Get Started
        </button>
      </div>
    </div>
  );
};
```

#### 2.2 ProductGrid Styling Enhancements

**File**: `src/components/products/ProductGrid.tsx` (Update)

**Enhancements**:
- Better loading spinner
- Improved error state
- Better empty state

```typescript
// Loading State Enhancement
if (isLoading) {
  return (
    <div className="flex flex-col justify-center items-center py-20">
      <div className="relative">
        <div className="animate-spin rounded-full h-16 w-16 border-t-4 border-b-4 border-blue-600"></div>
        <div className="absolute top-0 left-0 h-16 w-16 rounded-full border-4 border-gray-200"></div>
      </div>
      <p className="mt-6 text-gray-600 text-lg font-medium" role="status" aria-live="polite">
        Loading products...
      </p>
    </div>
  );
}

// Error State Enhancement
if (isError) {
  return (
    <div className="flex flex-col justify-center items-center py-20 px-4" role="alert" aria-live="assertive">
      <svg className="h-16 w-16 text-red-500 mb-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      <h3 className="text-xl font-semibold text-gray-900 mb-2">
        Failed to Load Products
      </h3>
      <p className="text-gray-600 mb-6 text-center max-w-md">
        We're having trouble loading the pricing plans. Please try again later.
      </p>
      <button
        onClick={() => window.location.reload()}
        className="px-6 py-3 bg-blue-600 text-white font-semibold rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-4 focus:ring-blue-300"
      >
        Retry
      </button>
    </div>
  );
}

// Empty State Enhancement
if (!products || products.length === 0) {
  return (
    <div className="flex flex-col justify-center items-center py-20 px-4">
      <svg className="h-16 w-16 text-gray-400 mb-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
      </svg>
      <h3 className="text-xl font-semibold text-gray-900 mb-2">
        No Products Available
      </h3>
      <p className="text-gray-600 text-center max-w-md">
        We don't have any pricing plans available at the moment. Please check back soon!
      </p>
    </div>
  );
}
```

---

### 3. Accessibility Enhancements

#### 3.1 Semantic HTML Audit

Verify all components use proper semantic HTML:

**Checklist**:
- [ ] `<main>` for primary content
- [ ] `<section>` for content sections
- [ ] `<h1>` - `<h6>` proper heading hierarchy
- [ ] `<ul>` / `<ol>` for lists
- [ ] `<button>` for clickable actions
- [ ] `<nav>` for navigation (if applicable)

#### 3.2 ARIA Labels and Attributes

**ProductCard.tsx**:
```typescript
<button
  onClick={handleSelect}
  className="..."
  aria-label={`Select ${product.name} plan for ${product.currency}${product.price} per ${product.period}`}
  aria-describedby={`product-${product.productId}-description`}
>
  Get Started
</button>

<p id={`product-${product.productId}-description`} className="sr-only">
  {product.description}. Includes: {product.features.join(', ')}
</p>
```

**ProductGrid.tsx**:
```typescript
// Loading state
<div role="status" aria-live="polite">
  <span className="sr-only">Loading products...</span>
  {/* spinner */}
</div>

// Error state
<div role="alert" aria-live="assertive">
  {/* error content */}
</div>
```

**ProductFeatureList.tsx**:
```typescript
<ul className="feature-list space-y-3" role="list">
  {features.map((feature, index) => (
    <li key={index} className="flex items-start">
      <svg aria-hidden="true" className="..." />
      <span className="text-gray-700">{feature}</span>
    </li>
  ))}
</ul>
```

#### 3.3 Keyboard Navigation

Ensure all interactive elements are keyboard accessible:

**Focus Styles** (add to global CSS or Tailwind):
```css
/* src/index.css */
*:focus {
  outline: 2px solid #3b82f6;
  outline-offset: 2px;
}

*:focus:not(:focus-visible) {
  outline: none;
}

*:focus-visible {
  outline: 2px solid #3b82f6;
  outline-offset: 2px;
}
```

**Tailwind Focus Classes**:
- `focus:outline-none`
- `focus:ring-4`
- `focus:ring-blue-300`
- `focus:ring-offset-2`

#### 3.4 Screen Reader Support

Add screen-reader-only utility class:

```css
/* src/index.css */
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border-width: 0;
}
```

---

### 4. Responsive Design Verification

**Breakpoints to Test**:
- Mobile: 320px - 639px (1 column)
- Tablet: 640px - 1023px (2 columns)
- Desktop: 1024px+ (4 columns)

**Test in DevTools**:
```
Preset Devices:
- iPhone SE (375px)
- iPad (768px)
- Laptop (1024px)
- Desktop (1440px)
```

---

### 5. Color Contrast Verification

**WCAG 2.1 AA Requirements**:
- Normal text: Minimum 4.5:1 contrast ratio
- Large text (18pt+): Minimum 3:1 contrast ratio

**Test Combinations**:
```
Background    Text Color      Contrast Ratio    Status
---------------------------------------------------------
#ffffff       #111827        15.8:1             ✅ PASS
#f9fafb       #374151        11.7:1             ✅ PASS
#3b82f6       #ffffff         4.7:1             ✅ PASS
#10b981       #ffffff         3.4:1             ⚠️  FAIL (normal text)
```

**Tools**:
- Chrome DevTools Accessibility panel
- https://webaim.org/resources/contrastchecker/

---

### 6. Install Accessibility Testing Tools

```bash
# Install axe-core for automated accessibility testing
npm install --save-dev @axe-core/react

# Install eslint-plugin-jsx-a11y for linting
npm install --save-dev eslint-plugin-jsx-a11y
```

**Setup axe in dev mode**:

```typescript
// src/main.tsx (add in dev mode only)
if (import.meta.env.DEV) {
  import('@axe-core/react').then((axe) => {
    axe.default(React, ReactDOM, 1000);
  });
}
```

**ESLint configuration**:

```json
// .eslintrc.json
{
  "extends": [
    "plugin:jsx-a11y/recommended"
  ],
  "plugins": ["jsx-a11y"]
}
```

---

### 7. Cross-Browser Testing

**Browsers to Test**:
- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

**Features to Verify**:
- CSS Grid layout works
- Tailwind styles render correctly
- Hover effects work
- Focus styles visible
- Fonts load correctly
- No console errors

---

### 8. Performance Optimization

#### 8.1 Image Optimization (if using images)

```typescript
// Lazy load images
<img
  src={product.image}
  alt={product.name}
  loading="lazy"
  className="..."
/>
```

#### 8.2 Code Splitting (if needed)

```typescript
// Lazy load Buy page
const Buy = lazy(() => import('./pages/Buy'));

<Suspense fallback={<LoadingSpinner />}>
  <Buy />
</Suspense>
```

---

## Deliverables

1. **All components styled** with enhanced Tailwind CSS
2. **Accessibility audit report** (output.md)
3. **WCAG 2.1 AA compliance** verified
4. **Cross-browser testing** results
5. **Responsive design** verified across breakpoints
6. **axe-core** automated accessibility scan results
7. **output.md** - Worker summary

---

## Success Criteria

- [ ] All components have polished Tailwind CSS styling
- [ ] WCAG 2.1 Level AA compliance verified
- [ ] All interactive elements keyboard accessible
- [ ] Focus styles visible and clear
- [ ] Proper ARIA labels on all components
- [ ] Semantic HTML verified
- [ ] Color contrast ratios pass WCAG AA
- [ ] Screen reader tested (macOS VoiceOver or NVDA)
- [ ] Responsive design works on mobile/tablet/desktop
- [ ] Cross-browser testing complete (Chrome, Firefox, Safari, Edge)
- [ ] axe-core scan shows 0 critical issues
- [ ] ESLint jsx-a11y passes
- [ ] output.md created with accessibility audit report

---

## Testing

### Automated Accessibility Testing

```bash
# Run ESLint with jsx-a11y
npm run lint

# Expected: No accessibility errors
```

### Manual Accessibility Testing

**Keyboard Navigation Test**:
1. Open `/buy` page
2. Press `Tab` key repeatedly
3. Verify:
   - All buttons are focusable
   - Focus indicator is clearly visible
   - Tab order is logical (top to bottom, left to right)
   - Press `Enter` on button activates it

**Screen Reader Test (macOS)**:
```
1. Enable VoiceOver: Cmd + F5
2. Navigate to /buy page
3. Use Cmd + Right Arrow to navigate
4. Verify:
   - Headings announced correctly
   - Buttons have descriptive labels
   - List items announced as lists
   - Loading/error states announced
```

**Screen Reader Test (Windows)**:
```
1. Install NVDA (free)
2. Navigate to /buy page
3. Use Down Arrow to navigate
4. Verify same items as above
```

### Contrast Checker

```
1. Open Chrome DevTools
2. Inspect text element
3. Open "Accessibility" panel
4. Check "Contrast" section
5. Verify all ratios pass AA standard
```

### axe DevTools

```
1. Install axe DevTools browser extension
2. Open /buy page
3. Run axe scan
4. Fix all critical and serious issues
5. Document any warnings
```

---

## Accessibility Audit Report Template

**File**: `output.md`

```markdown
# Accessibility Audit Report

## WCAG 2.1 Level AA Compliance

### Automated Testing Results

**axe-core scan**: ✅ 0 critical issues, ✅ 0 serious issues, ⚠️  X minor issues

**ESLint jsx-a11y**: ✅ PASS

### Manual Testing Results

**Keyboard Navigation**: ✅ PASS
- All interactive elements focusable
- Focus indicators visible
- Logical tab order

**Screen Reader (VoiceOver)**: ✅ PASS
- Headings announced correctly
- Buttons have descriptive labels
- Lists announced properly
- Live regions work for loading/error states

**Color Contrast**: ✅ PASS
- All text meets minimum 4.5:1 ratio
- Large text meets minimum 3:1 ratio

### Issues Found

| Issue | Severity | Status | Resolution |
|-------|----------|--------|------------|
| None | - | - | - |

### Recommendations

- Consider adding skip-to-content link
- Consider adding keyboard shortcuts
- Consider high contrast mode support

## Browser Compatibility

| Browser | Version | Status | Notes |
|---------|---------|--------|-------|
| Chrome | Latest | ✅ PASS | All features work |
| Firefox | Latest | ✅ PASS | All features work |
| Safari | Latest | ✅ PASS | All features work |
| Edge | Latest | ✅ PASS | All features work |

## Responsive Design

| Breakpoint | Device | Status | Notes |
|------------|--------|--------|-------|
| 375px | Mobile | ✅ PASS | 1 column layout |
| 768px | Tablet | ✅ PASS | 2 column layout |
| 1024px+ | Desktop | ✅ PASS | 4 column layout |

## Summary

The buy page meets WCAG 2.1 Level AA accessibility standards. All critical and serious issues have been resolved. The page is fully keyboard navigable, screen reader compatible, and has proper color contrast throughout.
```

---

## Dependencies

**Required Before This Worker**:
- ✅ Worker 2-1, 2-2, 2-3 complete

---

## Notes

- Accessibility is not optional - it's a requirement
- Test with actual screen readers, not just automated tools
- Keep accessibility in mind for future features
- Document any accessibility decisions made

---

**Created**: 2025-12-30
**Worker**: worker-4-styling-accessibility
**Agent**: Web Developer Agent
**Status**: PENDING
