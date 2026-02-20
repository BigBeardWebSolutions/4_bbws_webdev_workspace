# Worker 2-3: Product Service & API Integration

**Worker ID**: worker-3-api-integration
**Stage**: Stage 2 - Frontend Development
**Status**: PENDING
**Agent**: Web Developer Agent
**Repository**: `2_1_bbws_web_public`

---

## Objective

Implement Product Lambda API integration using Axios and React Query with proper error handling, retry logic, and caching strategy.

---

## Prerequisites

- ✅ Worker 2-1 complete (Buy page exists)
- ✅ Worker 2-2 complete (ProductGrid component exists)
- Product Lambda API deployed in DEV environment
- API endpoint accessible: `https://dev.api.kimmyai.io/v1.0/products`

---

## Input Documents

1. **API Contract**: `../stage-1-requirements-design/worker-2-api-contract/output.md`
   - Section 1: Endpoint Specification
   - Section 3: Response Schema
   - Section 5: Error Handling Strategy
   - Section 6: Retry Strategy
   - Section 7: Caching Strategy

2. **Frontend Requirements**: `../stage-1-requirements-design/worker-1-frontend-requirements/output.md`
   - Section 7: API Integration Pattern

---

## Tasks

### 1. Install Dependencies (if not already installed)

```bash
npm install axios @tanstack/react-query
```

**Verify versions**:
- axios: ^1.6.0 or higher
- @tanstack/react-query: ^5.0.0 or higher

---

### 2. Create API Configuration

**File**: `src/config/api.config.ts`

```typescript
const API_BASE_URLS = {
  development: 'https://dev.api.kimmyai.io',
  sit: 'https://sit.api.kimmyai.io',
  production: 'https://api.kimmyai.io',
};

const getEnvironment = (): 'development' | 'sit' | 'production' => {
  // Vite uses import.meta.env.MODE
  const mode = import.meta.env.MODE;

  if (mode === 'production') return 'production';
  if (mode === 'sit') return 'sit';
  return 'development';
};

export const API_CONFIG = {
  baseURL: API_BASE_URLS[getEnvironment()],
  timeout: 10000, // 10 seconds
  headers: {
    'Content-Type': 'application/json',
  },
};

export const API_ENDPOINTS = {
  products: '/v1.0/products',
};
```

**Environment Files**:

**`.env.development`**:
```
VITE_API_BASE_URL=https://dev.api.kimmyai.io
```

**`.env.production`**:
```
VITE_API_BASE_URL=https://api.kimmyai.io
```

---

### 3. Create Product Service (Axios Client)

**File**: `src/services/product.service.ts`

```typescript
import axios, { AxiosInstance, AxiosError } from 'axios';
import { API_CONFIG, API_ENDPOINTS } from '../config/api.config';
import { ProductListResponse } from '../types/product.types';

class ProductService {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: API_CONFIG.baseURL,
      timeout: API_CONFIG.timeout,
      headers: API_CONFIG.headers,
    });

    // Request interceptor (for logging, auth tokens, etc.)
    this.client.interceptors.request.use(
      (config) => {
        console.log(`[API Request] ${config.method?.toUpperCase()} ${config.url}`);
        return config;
      },
      (error) => {
        return Promise.reject(error);
      }
    );

    // Response interceptor (for error handling)
    this.client.interceptors.response.use(
      (response) => {
        console.log(`[API Response] ${response.status} ${response.config.url}`);
        return response;
      },
      (error: AxiosError) => {
        return Promise.reject(this.handleError(error));
      }
    );
  }

  private handleError(error: AxiosError): Error {
    if (error.response) {
      // Server responded with error status
      const status = error.response.status;

      if (status >= 500) {
        return new Error('Server error. Please try again later.');
      } else if (status === 429) {
        return new Error('Too many requests. Please wait a moment.');
      } else if (status >= 400) {
        return new Error('Bad request. Please check your input.');
      }
    } else if (error.request) {
      // Request made but no response received
      return new Error('Network error. Please check your connection.');
    }

    return new Error('An unexpected error occurred.');
  }

  async getProducts(): Promise<ProductListResponse> {
    try {
      const response = await this.client.get<ProductListResponse>(
        API_ENDPOINTS.products
      );
      return response.data;
    } catch (error) {
      throw error;
    }
  }
}

export const productService = new ProductService();
export default productService;
```

---

### 4. Create React Query Hook

**File**: `src/hooks/useProducts.ts`

```typescript
import { useQuery, UseQueryResult } from '@tanstack/react-query';
import { productService } from '../services/product.service';
import { ProductListResponse } from '../types/product.types';

export const useProducts = (): UseQueryResult<ProductListResponse, Error> => {
  return useQuery({
    queryKey: ['products'],
    queryFn: () => productService.getProducts(),

    // Caching configuration (from Stage 1 requirements)
    staleTime: 60 * 1000, // 1 minute (data considered fresh)
    gcTime: 5 * 60 * 1000, // 5 minutes (cache time, formerly cacheTime)

    // Retry configuration (from Stage 1 requirements)
    retry: 3, // Retry failed requests 3 times
    retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 30000), // Exponential backoff

    // Refetch configuration
    refetchOnWindowFocus: true, // Refetch when user returns to window
    refetchOnMount: false, // Don't refetch if data is fresh
    refetchOnReconnect: true, // Refetch when network reconnects
  });
};

export default useProducts;
```

---

### 5. Setup React Query Provider

**File**: `src/main.tsx` (Update)

```typescript
import React from 'react';
import ReactDOM from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';
import App from './App';
import './index.css';

// Create QueryClient instance
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60 * 1000, // 1 minute default
      gcTime: 5 * 60 * 1000, // 5 minutes default
      retry: 3,
      refetchOnWindowFocus: false,
    },
  },
});

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <App />
      {/* React Query Devtools (dev only) */}
      {import.meta.env.DEV && <ReactQueryDevtools initialIsOpen={false} />}
    </QueryClientProvider>
  </React.StrictMode>
);
```

---

### 6. Update Buy Page to Use Real API

**File**: `src/pages/Buy.tsx` (Update)

```typescript
import React from 'react';
import { ProductGrid } from '../components/products/ProductGrid';
import { useProducts } from '../hooks/useProducts';

export const Buy: React.FC = () => {
  // Use React Query hook to fetch products
  const { data, isLoading, isError, error } = useProducts();

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
          <ProductGrid
            products={data?.products || []}
            isLoading={isLoading}
            isError={isError}
          />

          {/* Error message (if needed) */}
          {isError && error && (
            <div className="mt-4 text-center text-red-600">
              {error.message}
            </div>
          )}
        </div>
      </main>
    </div>
  );
};

export default Buy;
```

---

### 7. Create Error Boundary (Optional)

**File**: `src/components/ErrorBoundary.tsx`

```typescript
import React, { Component, ErrorInfo, ReactNode } from 'react';

interface Props {
  children: ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('ErrorBoundary caught an error:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen flex items-center justify-center bg-gray-50">
          <div className="text-center">
            <h1 className="text-2xl font-bold text-gray-900 mb-4">
              Something went wrong
            </h1>
            <p className="text-gray-600 mb-6">
              {this.state.error?.message || 'An unexpected error occurred'}
            </p>
            <button
              onClick={() => window.location.reload()}
              className="px-6 py-3 bg-blue-600 text-white rounded-md hover:bg-blue-700"
            >
              Reload Page
            </button>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;
```

**Usage in App.tsx**:
```typescript
import { ErrorBoundary } from './components/ErrorBoundary';

function App() {
  return (
    <ErrorBoundary>
      <BrowserRouter>
        {/* Routes */}
      </BrowserRouter>
    </ErrorBoundary>
  );
}
```

---

## Deliverables

1. **File**: `src/config/api.config.ts` - API configuration
2. **File**: `src/services/product.service.ts` - Axios client
3. **File**: `src/hooks/useProducts.ts` - React Query hook
4. **File**: `src/main.tsx` (Updated) - QueryClientProvider setup
5. **File**: `src/pages/Buy.tsx` (Updated) - Using real API
6. **File**: `.env.development` - Development environment variables
7. **File**: `src/components/ErrorBoundary.tsx` (Optional) - Error boundary
8. **File**: `output.md` - Worker summary

---

## Success Criteria

- [ ] Axios installed and configured
- [ ] React Query installed and configured
- [ ] API service makes successful requests to Product Lambda
- [ ] Products display on /buy page from real API
- [ ] Loading state shows spinner during API call
- [ ] Error state shows message when API fails
- [ ] Retry logic works (3 attempts with exponential backoff)
- [ ] Caching works (1 min stale, 5 min cache)
- [ ] Environment-specific API URLs configured
- [ ] TypeScript compilation passes
- [ ] ESLint passes
- [ ] React Query Devtools accessible in dev mode
- [ ] output.md created

---

## Testing

### Manual Testing

```bash
# Start dev server
npm run dev

# Navigate to http://localhost:5173/buy

# Expected:
# - See loading spinner briefly
# - Products load from API
# - If API fails, see error message
# - Check Network tab for API request
# - Verify retry attempts on failure
```

### Test API Endpoint

```bash
# Test Product Lambda API directly
curl https://dev.api.kimmyai.io/v1.0/products

# Expected: JSON response with products array
```

### Test Error Handling

```typescript
// Temporarily modify API URL to test error state
// src/config/api.config.ts
const API_BASE_URLS = {
  development: 'https://invalid-url.example.com', // Force error
  // ...
};

// Expected:
# - Loading spinner
# - 3 retry attempts (check console)
# - Error message displayed
```

### Test Caching

```bash
# 1. Load /buy page (network request visible)
# 2. Navigate away and back within 1 minute
# Expected: No new network request (cached data used)

# 3. Wait > 1 minute, navigate back
# Expected: Background refetch (stale data shown, then updated)
```

---

## Dependencies

**Required Before This Worker**:
- ✅ Worker 2-2 complete (ProductGrid component)
- Product Lambda API deployed and accessible

**Blocks These Workers**:
- Worker 2-4: Styling & Accessibility

---

## Troubleshooting

### API Not Accessible

```bash
# Check if Product Lambda API is deployed
curl https://dev.api.kimmyai.io/v1.0/products

# If not working, verify:
# 1. API Gateway deployed
# 2. Lambda function exists
# 3. CORS configured for frontend domain
```

### CORS Errors

If you see CORS errors in console:

```
Access to XMLHttpRequest at 'https://dev.api.kimmyai.io/v1.0/products'
from origin 'http://localhost:5173' has been blocked by CORS policy
```

**Solution**: Update Product Lambda API Gateway CORS configuration to allow:
- Origin: `http://localhost:5173` (dev), `https://dev.kimmyai.io` (deployed)
- Methods: `GET, OPTIONS`
- Headers: `Content-Type`

---

## Notes

- Verify Product Lambda API is deployed before starting
- Use React Query Devtools to debug query state
- Keep service layer separate from components (good architecture)
- Error handling follows Stage 1 API contract requirements

---

**Created**: 2025-12-30
**Worker**: worker-3-api-integration
**Agent**: Web Developer Agent
**Status**: PENDING
