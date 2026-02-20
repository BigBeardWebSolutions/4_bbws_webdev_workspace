# Worker 2-1: Buy Page Component Structure

**Worker ID**: worker-1-page-structure
**Stage**: Stage 2 - Frontend Development
**Status**: PENDING
**Agent**: Web Developer Agent
**Repository**: `2_1_bbws_web_public`

---

## Objective

Create the `/buy` page component structure with React Router integration, semantic HTML layout, and SEO optimization.

---

## Prerequisites

- Stage 1 complete (Frontend requirements available)
- Repository: `2_1_bbws_web_public` cloned and set up
- Dependencies installed (`npm install`)
- Development server can run (`npm run dev`)

---

## Input Documents

1. **Frontend Requirements**: `../stage-1-requirements-design/worker-1-frontend-requirements/output.md`
   - Section 2: Page Structure
   - Section 3: Component Hierarchy
   - Section 6: Routing Configuration

---

## Tasks

### 1. Create Buy Page Component

**File**: `src/pages/Buy.tsx`

**Requirements**:
- Functional component using React 18
- TypeScript with proper type definitions
- Semantic HTML structure (header, main, section, footer)
- Placeholder sections for:
  - Hero section (optional, can be simple heading)
  - Products section (main content area)
  - CTA section (optional)

**Component Structure**:
```typescript
// src/pages/Buy.tsx
import React from 'react';

export const Buy: React.FC = () => {
  return (
    <div className="buy-page">
      {/* Hero Section (Optional) */}
      <section className="hero-section">
        <h1>Choose Your Plan</h1>
        <p>Select the perfect plan for your needs</p>
      </section>

      {/* Products Section (Main Content) */}
      <main className="products-section">
        <div className="container">
          {/* Placeholder - Worker 2-2 will add ProductGrid here */}
          <p>Product grid will be displayed here</p>
        </div>
      </main>

      {/* CTA Section (Optional) */}
      <section className="cta-section">
        <p>Questions? Contact our sales team</p>
      </section>
    </div>
  );
};

export default Buy;
```

**SEO Considerations**:
- Use semantic HTML5 elements (`<main>`, `<section>`, `<h1>`)
- Proper heading hierarchy (h1 → h2 → h3)
- Descriptive page title (will be set in Helmet or similar)

---

### 2. Update React Router Configuration

**File**: `src/App.tsx`

**Requirements**:
- Add `/buy` route using React Router v6
- Import Buy component
- Configure route with proper element

**Example**:
```typescript
// src/App.tsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Buy from './pages/Buy';
import Home from './pages/Home'; // Existing
// ... other imports

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/buy" element={<Buy />} />
        {/* Other routes */}
      </Routes>
    </BrowserRouter>
  );
}

export default App;
```

**Verification**:
- Navigate to `http://localhost:5173/buy` and verify page loads
- Check browser console for no errors
- Verify route is accessible

---

### 3. Configure SEO Metadata

**Option 1**: Using React Helmet (if available)

```typescript
// src/pages/Buy.tsx
import { Helmet } from 'react-helmet-async';

export const Buy: React.FC = () => {
  return (
    <>
      <Helmet>
        <title>Pricing Plans | KimmyAI</title>
        <meta name="description" content="Choose the perfect WordPress hosting plan for your needs. From individuals to enterprises, we have a plan for everyone." />
      </Helmet>
      <div className="buy-page">
        {/* ... page content */}
      </div>
    </>
  );
};
```

**Option 2**: Direct HTML metadata (if Helmet not available)

Update `index.html`:
```html
<!-- public/index.html or index.html -->
<head>
  <title>Pricing Plans | KimmyAI</title>
  <meta name="description" content="Choose the perfect WordPress hosting plan for your needs." />
</head>
```

---

### 4. Implement Basic Layout Structure

**Requirements from Stage 1**:
- Container max-width: 1280px
- Padding: Responsive (px-4 sm:px-6 lg:px-8)
- Centered layout

**Layout CSS (Tailwind)**:
```typescript
<div className="buy-page min-h-screen bg-gray-50">
  {/* Hero Section */}
  <section className="hero-section bg-white py-16">
    <div className="container mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <h1 className="text-4xl font-bold text-center text-gray-900">
        Choose Your Plan
      </h1>
      <p className="mt-4 text-lg text-center text-gray-600">
        Select the perfect plan for your needs
      </p>
    </div>
  </section>

  {/* Products Section */}
  <main className="products-section py-16">
    <div className="container mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      {/* Placeholder for ProductGrid (Worker 2-2) */}
      <div className="text-center text-gray-500">
        Product grid will be displayed here
      </div>
    </div>
  </main>
</div>
```

---

### 5. Create Shared Layout Component (Optional)

**File**: `src/components/layout/Layout.tsx`

If the app uses a shared layout (header, footer), ensure Buy page uses it:

```typescript
// src/components/layout/Layout.tsx
import React from 'react';
import Header from './Header';
import Footer from './Footer';

interface LayoutProps {
  children: React.ReactNode;
}

export const Layout: React.FC<LayoutProps> = ({ children }) => {
  return (
    <div className="app-layout">
      <Header />
      <main className="main-content">{children}</main>
      <Footer />
    </div>
  );
};

// src/pages/Buy.tsx (updated)
import { Layout } from '../components/layout/Layout';

export const Buy: React.FC = () => {
  return (
    <Layout>
      <div className="buy-page">
        {/* ... page content */}
      </div>
    </Layout>
  );
};
```

---

### 6. Verify Page Structure

**Checks**:
1. **Route works**: Navigate to `/buy` in browser
2. **Page renders**: No blank screen, no console errors
3. **Semantic HTML**: Use browser DevTools to inspect HTML structure
4. **Responsive**: Test on mobile (DevTools responsive mode)
5. **TypeScript**: No compilation errors (`npm run build`)

**Commands**:
```bash
# Start dev server
npm run dev

# In browser, navigate to:
http://localhost:5173/buy

# Check TypeScript compilation
npm run build

# Check linting
npm run lint
```

---

## Deliverables

### 1. File: `src/pages/Buy.tsx`
**Content**:
- Buy page component with semantic HTML
- Placeholder sections (hero, products, CTA)
- Tailwind CSS classes for basic layout
- TypeScript types and interfaces

### 2. File: `src/App.tsx` (Updated)
**Content**:
- `/buy` route added to React Router configuration
- Buy component imported and used

### 3. File: `output.md` (Worker Summary)
**Content**:
- Summary of implementation
- Route configuration details
- SEO metadata applied
- Verification results (screenshots optional)
- Next steps for Worker 2-2

---

## Success Criteria

- [ ] `src/pages/Buy.tsx` created and implements semantic HTML structure
- [ ] `/buy` route accessible in React Router
- [ ] Page renders without errors
- [ ] SEO metadata configured (title, description)
- [ ] Basic Tailwind CSS layout applied
- [ ] TypeScript compilation passes (`npm run build`)
- [ ] ESLint passes (`npm run lint`)
- [ ] Page accessible at `http://localhost:5173/buy`
- [ ] No console errors in browser DevTools
- [ ] output.md document created with implementation summary

---

## Testing

### Manual Testing

1. **Route Access**:
   ```bash
   # Start dev server
   npm run dev

   # Open browser
   http://localhost:5173/buy

   # Expected: Page displays with heading "Choose Your Plan"
   ```

2. **Responsive Layout**:
   - Open DevTools (F12)
   - Toggle device toolbar
   - Test mobile (375px), tablet (768px), desktop (1280px)
   - Expected: Layout adapts to screen size

3. **Semantic HTML**:
   - Inspect page with DevTools
   - Verify `<main>`, `<section>`, `<h1>` tags present
   - Verify proper heading hierarchy

### Automated Testing (Optional)

```typescript
// src/pages/__tests__/Buy.test.tsx
import { render, screen } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import Buy from '../Buy';

describe('Buy Page', () => {
  it('renders buy page heading', () => {
    render(
      <BrowserRouter>
        <Buy />
      </BrowserRouter>
    );
    expect(screen.getByText(/Choose Your Plan/i)).toBeInTheDocument();
  });

  it('renders products section placeholder', () => {
    render(
      <BrowserRouter>
        <Buy />
      </BrowserRouter>
    );
    expect(screen.getByText(/Product grid will be displayed here/i)).toBeInTheDocument();
  });
});
```

---

## Dependencies

**Required Before This Worker**:
- ✅ Stage 1 complete (Frontend requirements)
- ✅ Repository setup with React + TypeScript + Vite
- ✅ Tailwind CSS configured
- ✅ React Router v6 installed

**Blocks These Workers**:
- Worker 2-2: Product Components (needs page structure)
- Worker 2-4: Styling & Accessibility (needs components)

---

## Notes

- Keep component simple and focused on structure
- Worker 2-2 will add ProductGrid component to products section
- Worker 2-3 will add API integration to ProductGrid
- Worker 2-4 will refine styling and accessibility
- Focus on semantic HTML and basic layout, not final styling

---

## Output Template

```markdown
# Worker 2-1 Output: Buy Page Component Structure

## Implementation Summary

**Files Created**:
- `src/pages/Buy.tsx` - Buy page component
- Updated `src/App.tsx` - Added /buy route

**Route Configuration**:
- Path: `/buy`
- Component: Buy
- Accessible at: http://localhost:5173/buy

**SEO Metadata**:
- Title: "Pricing Plans | KimmyAI"
- Description: "Choose the perfect WordPress hosting plan..."

**Layout Structure**:
- Hero section with heading and description
- Main products section with placeholder
- Optional CTA section

## Verification Results

- [x] Route accessible: ✅
- [x] Page renders without errors: ✅
- [x] TypeScript compilation passes: ✅
- [x] ESLint passes: ✅
- [x] Semantic HTML verified: ✅
- [x] Responsive layout tested: ✅

## Screenshots (Optional)

[Screenshot of /buy page in browser]

## Next Steps

Worker 2-2 will:
- Create ProductCard component
- Create ProductGrid component
- Integrate ProductGrid into products-section in Buy.tsx

## Issues/Blockers

None
```

---

**Created**: 2025-12-30
**Worker**: worker-1-page-structure
**Agent**: Web Developer Agent
**Status**: PENDING
