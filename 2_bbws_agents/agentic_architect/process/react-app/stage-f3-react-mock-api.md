# Stage F3: React Implementation with Mock API

**Parent Plan**: [React App SDLC](./main-plan.md)
**Stage**: F3 of 6
**Status**: PENDING
**Last Updated**: 2026-01-01

---

## Objective

Implement the React application with mock API data, enabling frontend development to proceed in parallel with backend API development.

---

## Agent & Skill Assignment

| Role | Agent | Skill |
|------|-------|-------|
| **Primary** | Web_Developer_Agent | `react_landing_page.skill.md` |
| **Secondary** | Web_Developer_Agent | `spa_developer.skill.md` |

---

## Workers

| # | Worker | Task | Status | Output |
|---|--------|------|--------|--------|
| 1 | worker-1-project-setup | Initialize React project with tooling | PENDING | Project structure |
| 2 | worker-2-mock-api | Create mock API with realistic data | PENDING | `src/mocks/` |
| 3 | worker-3-components | Implement reusable components | PENDING | `src/components/` |
| 4 | worker-4-pages | Build application pages | PENDING | `src/pages/` |
| 5 | worker-5-state-management | Implement state management | PENDING | `src/store/` |

---

## Worker Instructions

### Worker 1: Project Setup

**Objective**: Initialize React project with modern tooling

**Technology Stack**:
| Tool | Purpose |
|------|---------|
| Vite | Build tool |
| React 18 | UI framework |
| TypeScript | Type safety |
| React Router | Navigation |
| TailwindCSS | Styling |
| Axios | HTTP client |

**Project Structure**:
```
{fe-repo}/
├── src/
│   ├── components/     # Reusable components
│   ├── pages/          # Page components
│   ├── mocks/          # Mock API data
│   ├── hooks/          # Custom hooks
│   ├── services/       # API services
│   ├── store/          # State management
│   ├── types/          # TypeScript types
│   └── utils/          # Utility functions
├── public/
├── tests/
├── package.json
├── tsconfig.json
├── vite.config.ts
└── tailwind.config.js
```

**Quality Criteria**:
- [ ] Project builds successfully
- [ ] TypeScript configured strictly
- [ ] ESLint and Prettier configured
- [ ] Development server runs

---

### Worker 2: Mock API Implementation

**Objective**: Create mock API that mirrors real API contracts

**Skill Reference**: Use LLD API contracts from Stage 3

**Mock API Structure**:
```typescript
// src/mocks/handlers.ts
import { rest } from 'msw';

export const handlers = [
  // GET /products
  rest.get('/api/v1.0/products', (req, res, ctx) => {
    return res(ctx.json({ products: mockProducts }));
  }),

  // GET /products/:id
  rest.get('/api/v1.0/products/:id', (req, res, ctx) => {
    const { id } = req.params;
    return res(ctx.json(findProduct(id)));
  }),

  // POST /products
  rest.post('/api/v1.0/products', async (req, res, ctx) => {
    const body = await req.json();
    return res(ctx.status(201), ctx.json(createProduct(body)));
  }),

  // PUT /products/:id
  rest.put('/api/v1.0/products/:id', async (req, res, ctx) => {
    const { id } = req.params;
    const body = await req.json();
    return res(ctx.json(updateProduct(id, body)));
  }),

  // DELETE /products/:id
  rest.delete('/api/v1.0/products/:id', (req, res, ctx) => {
    return res(ctx.status(204));
  }),
];
```

**Mock Data Files**:
```
src/mocks/
├── handlers.ts          # MSW request handlers
├── browser.ts           # Browser worker setup
├── data/
│   ├── products.json    # Mock product data
│   ├── users.json       # Mock user data
│   └── tenants.json     # Mock tenant data
└── utils.ts             # Mock utility functions
```

**Quality Criteria**:
- [ ] All CRUD endpoints mocked
- [ ] Response formats match API spec
- [ ] Realistic delay simulation (100-500ms)
- [ ] Error scenarios mockable

---

### Worker 3: Component Library

**Objective**: Implement reusable component library from design system

**Components to Build**:
| Component | Props | Description |
|-----------|-------|-------------|
| Button | variant, size, disabled | Primary action button |
| Input | type, error, label | Form input field |
| Card | title, children | Content container |
| Modal | open, onClose, title | Overlay dialog |
| Table | columns, data, pagination | Data table |
| Alert | type, message | Notification |
| Spinner | size | Loading indicator |
| Badge | variant, children | Status badge |

**Component Structure**:
```typescript
// src/components/Button/Button.tsx
interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  onClick?: () => void;
  children: React.ReactNode;
}

export const Button: React.FC<ButtonProps> = ({
  variant = 'primary',
  size = 'md',
  disabled = false,
  onClick,
  children,
}) => {
  // Implementation
};
```

**Quality Criteria**:
- [ ] All design system components implemented
- [ ] Components match Figma designs
- [ ] Props documented with TypeScript
- [ ] Accessibility attributes included

---

### Worker 4: Application Pages

**Objective**: Build all application pages using components

**Pages to Implement**:
| Page | Route | Description |
|------|-------|-------------|
| Dashboard | `/` | Main overview |
| ProductList | `/products` | Product listing |
| ProductDetail | `/products/:id` | Single product view |
| ProductForm | `/products/new`, `/products/:id/edit` | Create/edit product |
| Settings | `/settings` | User settings |
| Login | `/login` | Authentication |

**Page Structure**:
```
src/pages/
├── Dashboard/
│   ├── Dashboard.tsx
│   └── index.ts
├── Products/
│   ├── ProductList.tsx
│   ├── ProductDetail.tsx
│   ├── ProductForm.tsx
│   └── index.ts
├── Settings/
│   └── Settings.tsx
└── Auth/
    ├── Login.tsx
    └── index.ts
```

**Quality Criteria**:
- [ ] All pages functional with mock data
- [ ] Routing configured
- [ ] Loading states implemented
- [ ] Error handling in place

---

### Worker 5: State Management

**Objective**: Implement application state management

**State Management Options**:
- React Query (for server state)
- Zustand (for client state)

**Implementation Pattern**:
```typescript
// src/store/productStore.ts
import { create } from 'zustand';

interface ProductStore {
  selectedProduct: Product | null;
  setSelectedProduct: (product: Product | null) => void;
}

export const useProductStore = create<ProductStore>((set) => ({
  selectedProduct: null,
  setSelectedProduct: (product) => set({ selectedProduct: product }),
}));

// src/hooks/useProducts.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

export const useProducts = () => {
  return useQuery({
    queryKey: ['products'],
    queryFn: productService.list,
  });
};

export const useCreateProduct = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: productService.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
    },
  });
};
```

**Quality Criteria**:
- [ ] Server state managed with React Query
- [ ] Client state minimal and focused
- [ ] Optimistic updates implemented
- [ ] Cache invalidation working

---

## Stage Outputs

| Output | Description | Location |
|--------|-------------|----------|
| Project setup | Configured React project | Repository root |
| Mock API | MSW handlers with data | `src/mocks/` |
| Components | Reusable component library | `src/components/` |
| Pages | Application pages | `src/pages/` |
| State | State management | `src/store/`, `src/hooks/` |

---

## Success Criteria

- [ ] All 5 workers completed
- [ ] Application runs with mock API
- [ ] All CRUD operations functional
- [ ] Components match designs
- [ ] TypeScript compiles without errors

---

## Dependencies

**Depends On**: Stage F2 (Prototype), Stage 3 (LLD for API contracts)
**Blocks**: Stage F4 (Frontend Tests)

---

## Estimated Duration

| Activity | Agentic | Manual |
|----------|---------|--------|
| Project setup | 15 min | 1 hour |
| Mock API | 30 min | 3 hours |
| Components | 45 min | 6 hours |
| Pages | 45 min | 6 hours |
| State management | 20 min | 2 hours |
| **Total** | **2.5 hours** | **18 hours** |

---

**Navigation**: [<- Stage F2](./stage-f2-prototype.md) | [Main Plan](./main-plan.md) | [Stage F4 ->](./stage-f4-frontend-tests.md)
