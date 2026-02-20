# Stage F5: API Integration

**Parent Plan**: [React App SDLC](./main-plan.md)
**Stage**: F5 of 6
**Status**: PENDING
**Last Updated**: 2026-01-01

---

## Objective

Replace mock API with real backend API integration, ensuring the React application works correctly with deployed Lambda functions.

---

## Agent & Skill Assignment

| Role | Agent | Skill |
|------|-------|-------|
| **Primary** | Web_Developer_Agent | `react_landing_page.skill.md` |
| **Support** | Python_AWS_Developer_Agent | `AWS_Python_Dev.skill.md` |

---

## Workers

| # | Worker | Task | Status | Output |
|---|--------|------|--------|--------|
| 1 | worker-1-api-client | Configure API client for real endpoints | PENDING | `src/services/` |
| 2 | worker-2-env-config | Set up environment-specific configuration | PENDING | Environment files |
| 3 | worker-3-integration-tests | Write API integration tests | PENDING | `tests/integration/` |

---

## Worker Instructions

### Worker 1: API Client Configuration

**Objective**: Update API services to connect to real endpoints

**API Client Pattern**:
```typescript
// src/services/api.ts
import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add API key for authenticated requests
api.interceptors.request.use((config) => {
  const apiKey = import.meta.env.VITE_API_KEY;
  if (apiKey) {
    config.headers['x-api-key'] = apiKey;
  }
  return config;
});

// Handle errors globally
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Handle unauthorized
    }
    return Promise.reject(error);
  }
);

export { api };
```

```typescript
// src/services/productService.ts
import { api } from './api';
import { Product, CreateProductRequest, UpdateProductRequest } from '@/types';

export const productService = {
  list: async () => {
    const response = await api.get<{ products: Product[] }>('/v1.0/products');
    return response.data;
  },

  get: async (id: string) => {
    const response = await api.get<Product>(`/v1.0/products/${id}`);
    return response.data;
  },

  create: async (data: CreateProductRequest) => {
    const response = await api.post<Product>('/v1.0/products', data);
    return response.data;
  },

  update: async (id: string, data: UpdateProductRequest) => {
    const response = await api.put<Product>(`/v1.0/products/${id}`, data);
    return response.data;
  },

  delete: async (id: string) => {
    await api.delete(`/v1.0/products/${id}`);
  },
};
```

**Quality Criteria**:
- [ ] API client connects to real endpoints
- [ ] Error handling implemented
- [ ] Request/response interceptors configured
- [ ] TypeScript types match API contracts

---

### Worker 2: Environment Configuration

**Objective**: Configure environment-specific settings

**Environment Files**:
```bash
# .env.development
VITE_API_BASE_URL=https://api.dev.kimmyai.io
VITE_API_KEY=dev-api-key
VITE_ENVIRONMENT=development

# .env.staging (SIT)
VITE_API_BASE_URL=https://api.sit.kimmyai.io
VITE_API_KEY=sit-api-key
VITE_ENVIRONMENT=staging

# .env.production
VITE_API_BASE_URL=https://api.kimmyai.io
VITE_API_KEY=prod-api-key
VITE_ENVIRONMENT=production
```

**Environment Config**:
```typescript
// src/config/environment.ts
export const config = {
  apiBaseUrl: import.meta.env.VITE_API_BASE_URL,
  apiKey: import.meta.env.VITE_API_KEY,
  environment: import.meta.env.VITE_ENVIRONMENT as 'development' | 'staging' | 'production',
  isDevelopment: import.meta.env.VITE_ENVIRONMENT === 'development',
  isProduction: import.meta.env.VITE_ENVIRONMENT === 'production',
};
```

**Build Scripts**:
```json
{
  "scripts": {
    "dev": "vite",
    "build:dev": "vite build --mode development",
    "build:sit": "vite build --mode staging",
    "build:prod": "vite build --mode production"
  }
}
```

**Quality Criteria**:
- [ ] Environment files created
- [ ] Build scripts for each environment
- [ ] Secrets not committed to git
- [ ] Configuration validated at startup

---

### Worker 3: API Integration Tests

**Objective**: Write tests against real API (DEV environment)

**Integration Test Setup**:
```typescript
// tests/integration/setup.ts
import { config } from '@/config/environment';

export const integrationConfig = {
  baseUrl: config.apiBaseUrl,
  apiKey: config.apiKey,
  timeout: 10000,
};
```

```typescript
// tests/integration/products.test.ts
import { productService } from '@/services/productService';

describe('Product API Integration', () => {
  let testProductId: string;

  it('should list products', async () => {
    const result = await productService.list();
    expect(result.products).toBeDefined();
    expect(Array.isArray(result.products)).toBe(true);
  });

  it('should create a product', async () => {
    const newProduct = {
      name: `Test Product ${Date.now()}`,
      price: 99.99,
      description: 'Integration test product',
    };

    const result = await productService.create(newProduct);
    expect(result.product_id).toBeDefined();
    testProductId = result.product_id;
  });

  it('should get a product by id', async () => {
    const result = await productService.get(testProductId);
    expect(result.product_id).toBe(testProductId);
  });

  it('should update a product', async () => {
    const updates = { price: 149.99 };
    const result = await productService.update(testProductId, updates);
    expect(result.price).toBe(149.99);
  });

  it('should delete a product', async () => {
    await expect(productService.delete(testProductId)).resolves.not.toThrow();
  });

  it('should handle 404 errors', async () => {
    await expect(productService.get('non-existent-id')).rejects.toThrow();
  });
});
```

**Quality Criteria**:
- [ ] All CRUD operations tested against real API
- [ ] Error scenarios tested
- [ ] Test data cleanup implemented
- [ ] Tests run against DEV environment only

---

## Stage Outputs

| Output | Description | Location |
|--------|-------------|----------|
| API client | Configured axios instance | `src/services/api.ts` |
| Services | API service methods | `src/services/` |
| Environment config | Environment files | `.env.*` |
| Integration tests | API integration tests | `tests/integration/` |

---

## Approval Gate F2

**Location**: After this stage
**Approvers**: Tech Lead, QA Lead
**Criteria**:
- [ ] API integration working in DEV
- [ ] All integration tests passing
- [ ] Error handling verified
- [ ] Performance acceptable (< 3s response)

---

## Success Criteria

- [ ] All 3 workers completed
- [ ] Frontend works with real API
- [ ] All CRUD operations functional
- [ ] Integration tests passing
- [ ] Gate F2 approval obtained

---

## Dependencies

**Depends On**:
- Stage F4 (Frontend Tests)
- Stage 10 (Backend Deploy & Test) - API must be deployed
**Blocks**: Stage F6 (Frontend Deploy)

---

## Estimated Duration

| Activity | Agentic | Manual |
|----------|---------|--------|
| API client | 20 min | 2 hours |
| Environment config | 15 min | 1 hour |
| Integration tests | 30 min | 3 hours |
| **Total** | **1 hour** | **6 hours** |

---

**Navigation**: [<- Stage F4](./stage-f4-frontend-tests.md) | [Main Plan](./main-plan.md) | [Stage F6 ->](./stage-f6-frontend-deploy.md)
