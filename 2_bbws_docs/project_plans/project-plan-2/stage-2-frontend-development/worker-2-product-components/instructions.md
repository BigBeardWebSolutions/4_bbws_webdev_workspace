# Worker 2-2: Product Components

**Worker ID**: worker-2-product-components
**Stage**: Stage 2 - Frontend Development
**Status**: PENDING
**Agent**: Web Developer Agent
**Repository**: `2_1_bbws_web_public`

---

## Objective

Build reusable product display components (ProductCard, ProductGrid, ProductFeatureList) with responsive design and TypeScript type safety.

---

## Prerequisites

- ✅ Worker 2-1 complete (Buy page structure exists)
- Stage 1 Frontend Requirements available
- Repository setup with dependencies installed

---

## Input Documents

1. **Frontend Requirements**: `../stage-1-requirements-design/worker-1-frontend-requirements/output.md`
   - Section 2.3: Component Hierarchy
   - Section 4: Component Specifications
   - Section 5: Responsive Design

2. **API Contract**: `../stage-1-requirements-design/worker-2-api-contract/output.md`
   - Section 3: Response Schema (Product interface)

---

## Tasks

### 1. Create TypeScript Product Interface

**File**: `src/types/product.types.ts`

```typescript
export interface Product {
  productId: string;
  name: string;
  description: string;
  price: number;
  currency: string;
  period: string;
  features: string[];
  active: boolean;
  createdAt: string;
}

export interface ProductListResponse {
  products: Product[];
  count: number;
}
```

---

### 2. Create ProductCard Component

**File**: `src/components/products/ProductCard.tsx`

**Requirements**:
- Display single product information
- Props: `product: Product`
- Show: name, description, price, currency, period, features
- Tailwind CSS styling
- Responsive design
- Hover effects
- CTA button ("Get Started" or "Choose Plan")

**Implementation**:
```typescript
import React from 'react';
import { Product } from '../../types/product.types';
import { ProductFeatureList } from './ProductFeatureList';

interface ProductCardProps {
  product: Product;
  onSelect?: (productId: string) => void;
}

export const ProductCard: React.FC<ProductCardProps> = ({ product, onSelect }) => {
  const handleSelect = () => {
    if (onSelect) {
      onSelect(product.productId);
    }
  };

  return (
    <div className="product-card bg-white rounded-lg shadow-lg p-6 flex flex-col h-full border border-gray-200 hover:shadow-xl transition-shadow duration-300">
      {/* Product Header */}
      <div className="product-header mb-4">
        <h3 className="text-2xl font-bold text-gray-900">{product.name}</h3>
        <p className="mt-2 text-gray-600">{product.description}</p>
      </div>

      {/* Pricing */}
      <div className="product-pricing mb-6">
        <div className="flex items-baseline">
          <span className="text-4xl font-extrabold text-gray-900">
            {product.currency === 'USD' ? '$' : product.currency}
            {product.price.toFixed(2)}
          </span>
          <span className="ml-2 text-gray-500">/ {product.period}</span>
        </div>
      </div>

      {/* Features */}
      <div className="product-features mb-6 flex-grow">
        <ProductFeatureList features={product.features} />
      </div>

      {/* CTA Button */}
      <div className="product-cta">
        <button
          onClick={handleSelect}
          className="w-full bg-blue-600 text-white font-semibold py-3 px-6 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors duration-200"
          aria-label={`Select ${product.name} plan`}
        >
          Get Started
        </button>
      </div>
    </div>
  );
};

export default ProductCard;
```

---

### 3. Create ProductFeatureList Component

**File**: `src/components/products/ProductFeatureList.tsx`

**Requirements**:
- Display list of product features
- Props: `features: string[]`
- Use check icon for each feature
- Semantic HTML (`<ul>`, `<li>`)

**Implementation**:
```typescript
import React from 'react';

interface ProductFeatureListProps {
  features: string[];
}

export const ProductFeatureList: React.FC<ProductFeatureListProps> = ({ features }) => {
  return (
    <ul className="feature-list space-y-3" role="list">
      {features.map((feature, index) => (
        <li key={index} className="flex items-start">
          {/* Check Icon */}
          <svg
            className="h-5 w-5 text-green-500 mt-0.5 mr-3 flex-shrink-0"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            aria-hidden="true"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M5 13l4 4L19 7"
            />
          </svg>
          <span className="text-gray-700">{feature}</span>
        </li>
      ))}
    </ul>
  );
};

export default ProductFeatureList;
```

---

### 4. Create ProductGrid Component

**File**: `src/components/products/ProductGrid.tsx`

**Requirements**:
- Display products in responsive grid
- Props: `products: Product[]`, `onProductSelect?: (productId: string) => void`
- Responsive layout:
  - Mobile (< 640px): 1 column
  - Tablet (640px - 1024px): 2 columns
  - Desktop (>= 1024px): 4 columns
- Loading state support
- Empty state support
- Error state support

**Implementation**:
```typescript
import React from 'react';
import { Product } from '../../types/product.types';
import { ProductCard } from './ProductCard';

interface ProductGridProps {
  products: Product[];
  isLoading?: boolean;
  isError?: boolean;
  onProductSelect?: (productId: string) => void;
}

export const ProductGrid: React.FC<ProductGridProps> = ({
  products,
  isLoading = false,
  isError = false,
  onProductSelect,
}) => {
  // Loading State
  if (isLoading) {
    return (
      <div className="flex justify-center items-center py-16">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600" aria-label="Loading products"></div>
      </div>
    );
  }

  // Error State
  if (isError) {
    return (
      <div className="text-center py-16">
        <div className="text-red-600 font-semibold text-lg">
          Failed to load products. Please try again later.
        </div>
      </div>
    );
  }

  // Empty State
  if (!products || products.length === 0) {
    return (
      <div className="text-center py-16">
        <p className="text-gray-500 text-lg">No products available at this time.</p>
      </div>
    );
  }

  // Products Grid
  return (
    <div className="product-grid grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
      {products.map((product) => (
        <ProductCard
          key={product.productId}
          product={product}
          onSelect={onProductSelect}
        />
      ))}
    </div>
  );
};

export default ProductGrid;
```

---

### 5. Create PricingFilter Component (Placeholder)

**File**: `src/components/products/PricingFilter.tsx`

**Note**: This is a future enhancement. Create placeholder component.

```typescript
import React from 'react';

interface PricingFilterProps {
  onFilterChange?: (filter: string) => void;
}

export const PricingFilter: React.FC<PricingFilterProps> = ({ onFilterChange }) => {
  // Placeholder - to be implemented in future iteration
  return null;

  // Future implementation:
  // return (
  //   <div className="pricing-filter mb-8 flex justify-center">
  //     <div className="inline-flex rounded-md shadow-sm" role="group">
  //       <button className="px-4 py-2 text-sm font-medium">Monthly</button>
  //       <button className="px-4 py-2 text-sm font-medium">Annual</button>
  //     </div>
  //   </div>
  // );
};

export default PricingFilter;
```

---

### 6. Update Buy Page to Use ProductGrid

**File**: `src/pages/Buy.tsx` (Update)

**Update the products section**:

```typescript
import React from 'react';
import { ProductGrid } from '../components/products/ProductGrid';

export const Buy: React.FC = () => {
  // Placeholder mock data for testing (Worker 2-3 will add real API)
  const mockProducts = [
    {
      productId: '1',
      name: 'Entry',
      description: 'Perfect for individuals',
      price: 9.99,
      currency: 'USD',
      period: 'monthly',
      features: ['1 WordPress site', '10 GB storage', 'Basic support'],
      active: true,
      createdAt: '2025-12-30T00:00:00Z',
    },
    // Add 2-3 more mock products for testing
  ];

  return (
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
          <ProductGrid products={mockProducts} />
        </div>
      </main>
    </div>
  );
};

export default Buy;
```

---

## Deliverables

1. **File**: `src/types/product.types.ts` - TypeScript interfaces
2. **File**: `src/components/products/ProductCard.tsx` - Product card component
3. **File**: `src/components/products/ProductFeatureList.tsx` - Feature list component
4. **File**: `src/components/products/ProductGrid.tsx` - Product grid component
5. **File**: `src/components/products/PricingFilter.tsx` - Filter placeholder
6. **File**: `src/pages/Buy.tsx` (Updated) - Using ProductGrid with mock data
7. **File**: `output.md` - Worker summary

---

## Success Criteria

- [ ] All component files created
- [ ] TypeScript interfaces defined
- [ ] ProductCard displays product information correctly
- [ ] ProductGrid shows responsive layout (1/2/4 columns)
- [ ] Loading, error, and empty states work
- [ ] Tailwind CSS styling applied
- [ ] Components render without errors
- [ ] TypeScript compilation passes
- [ ] ESLint passes
- [ ] Mock data displays on /buy page
- [ ] Responsive design verified (mobile/tablet/desktop)
- [ ] output.md created

---

## Testing

### Manual Testing

```bash
# Start dev server
npm run dev

# Navigate to http://localhost:5173/buy

# Expected:
# - See 3-4 product cards in grid
# - Mobile: 1 column
# - Tablet: 2 columns
# - Desktop: 4 columns
# - Hover effects work on cards
# - "Get Started" button visible on each card
```

### Unit Tests (Optional)

```typescript
// src/components/products/__tests__/ProductCard.test.tsx
import { render, screen } from '@testing-library/react';
import { ProductCard } from '../ProductCard';

const mockProduct = {
  productId: '1',
  name: 'Entry',
  description: 'Perfect for individuals',
  price: 9.99,
  currency: 'USD',
  period: 'monthly',
  features: ['1 site', '10 GB'],
  active: true,
  createdAt: '2025-12-30T00:00:00Z',
};

describe('ProductCard', () => {
  it('renders product name', () => {
    render(<ProductCard product={mockProduct} />);
    expect(screen.getByText('Entry')).toBeInTheDocument();
  });

  it('renders product price', () => {
    render(<ProductCard product={mockProduct} />);
    expect(screen.getByText(/9.99/)).toBeInTheDocument();
  });

  it('renders all features', () => {
    render(<ProductCard product={mockProduct} />);
    expect(screen.getByText('1 site')).toBeInTheDocument();
    expect(screen.getByText('10 GB')).toBeInTheDocument();
  });
});
```

---

## Dependencies

**Required Before This Worker**:
- ✅ Worker 2-1 complete (Buy page exists)

**Blocks These Workers**:
- Worker 2-3: API Integration (will replace mock data with real API)
- Worker 2-4: Styling & Accessibility (will refine component styles)

---

## Notes

- Use mock data for now (Worker 2-3 will add real API integration)
- Focus on component structure and basic styling
- Worker 2-4 will refine accessibility and styling
- Keep components reusable and well-typed

---

**Created**: 2025-12-30
**Worker**: worker-2-product-components
**Agent**: Web Developer Agent
**Status**: PENDING
