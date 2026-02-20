# Stage F4: Frontend Tests

**Parent Plan**: [React App SDLC](./main-plan.md)
**Stage**: F4 of 6
**Status**: PENDING
**Last Updated**: 2026-01-01

---

## Objective

Create comprehensive test suites for the React application including unit tests, component tests, and integration tests with mock API.

---

## Agent & Skill Assignment

| Role | Agent | Skill |
|------|-------|-------|
| **Primary** | SDET_Engineer_Agent | `website_testing.skill.md` |
| **Support** | Web_Developer_Agent | `react_landing_page.skill.md` |

---

## Workers

| # | Worker | Task | Status | Output |
|---|--------|------|--------|--------|
| 1 | worker-1-test-setup | Configure testing framework | PENDING | Test configuration |
| 2 | worker-2-unit-tests | Write unit tests for utilities/hooks | PENDING | `src/__tests__/unit/` |
| 3 | worker-3-component-tests | Write component tests | PENDING | `src/__tests__/components/` |
| 4 | worker-4-integration-tests | Write integration tests | PENDING | `src/__tests__/integration/` |

---

## Worker Instructions

### Worker 1: Test Setup

**Objective**: Configure testing framework and tooling

**Testing Stack**:
| Tool | Purpose |
|------|---------|
| Vitest | Test runner (Vite compatible) |
| React Testing Library | Component testing |
| MSW | API mocking |
| @testing-library/user-event | User interaction simulation |

**Configuration Files**:
```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/setupTests.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      thresholds: {
        statements: 70,
        branches: 70,
        functions: 70,
        lines: 70,
      },
    },
  },
});
```

```typescript
// src/setupTests.ts
import '@testing-library/jest-dom';
import { server } from './mocks/server';

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

**Quality Criteria**:
- [ ] Vitest configured and running
- [ ] MSW integrated for API mocking
- [ ] Coverage thresholds set (70%)
- [ ] CI/CD integration ready

---

### Worker 2: Unit Tests

**Objective**: Write unit tests for utilities and hooks

**Test Coverage**:
| Category | Examples |
|----------|----------|
| Utilities | formatDate, formatCurrency, validation |
| Hooks | useProducts, useAuth, useForm |
| Services | API service methods |
| Store | Zustand store actions |

**Unit Test Pattern**:
```typescript
// src/__tests__/unit/hooks/useProducts.test.ts
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useProducts } from '@/hooks/useProducts';

describe('useProducts', () => {
  const wrapper = ({ children }) => (
    <QueryClientProvider client={new QueryClient()}>
      {children}
    </QueryClientProvider>
  );

  it('should fetch products successfully', async () => {
    const { result } = renderHook(() => useProducts(), { wrapper });

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true);
    });

    expect(result.current.data.products).toHaveLength(3);
  });

  it('should handle loading state', () => {
    const { result } = renderHook(() => useProducts(), { wrapper });
    expect(result.current.isLoading).toBe(true);
  });
});
```

**Quality Criteria**:
- [ ] All utility functions tested
- [ ] All custom hooks tested
- [ ] Edge cases covered
- [ ] 80%+ coverage on utils/hooks

---

### Worker 3: Component Tests

**Objective**: Write component tests for all UI components

**Test Coverage**:
| Component | Tests |
|-----------|-------|
| Button | Variants, click handler, disabled state |
| Input | Value change, error display, label |
| Card | Content rendering, actions |
| Modal | Open/close, backdrop click |
| Table | Data rendering, pagination, sorting |

**Component Test Pattern**:
```typescript
// src/__tests__/components/Button.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from '@/components/Button';

describe('Button', () => {
  it('renders children correctly', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByText('Click me')).toBeInTheDocument();
  });

  it('calls onClick when clicked', () => {
    const handleClick = vi.fn();
    render(<Button onClick={handleClick}>Click me</Button>);

    fireEvent.click(screen.getByRole('button'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('is disabled when disabled prop is true', () => {
    render(<Button disabled>Click me</Button>);
    expect(screen.getByRole('button')).toBeDisabled();
  });

  it('applies correct variant styles', () => {
    render(<Button variant="primary">Primary</Button>);
    expect(screen.getByRole('button')).toHaveClass('btn-primary');
  });
});
```

**Quality Criteria**:
- [ ] All components have tests
- [ ] Props variations tested
- [ ] Accessibility tested
- [ ] 70%+ component coverage

---

### Worker 4: Integration Tests

**Objective**: Write integration tests for complete user flows

**User Flows to Test**:
| Flow | Description |
|------|-------------|
| Product List | Load, filter, paginate products |
| Create Product | Fill form, submit, success message |
| Edit Product | Load product, edit, save |
| Delete Product | Confirm dialog, delete, redirect |
| Navigation | Route transitions, breadcrumbs |

**Integration Test Pattern**:
```typescript
// src/__tests__/integration/ProductList.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router-dom';
import { App } from '@/App';

describe('Product List Integration', () => {
  it('loads and displays products', async () => {
    render(
      <MemoryRouter initialEntries={['/products']}>
        <App />
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(screen.getByText('Product 1')).toBeInTheDocument();
      expect(screen.getByText('Product 2')).toBeInTheDocument();
    });
  });

  it('navigates to product detail on click', async () => {
    const user = userEvent.setup();
    render(
      <MemoryRouter initialEntries={['/products']}>
        <App />
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(screen.getByText('Product 1')).toBeInTheDocument();
    });

    await user.click(screen.getByText('Product 1'));

    await waitFor(() => {
      expect(screen.getByText('Product Details')).toBeInTheDocument();
    });
  });

  it('creates a new product successfully', async () => {
    const user = userEvent.setup();
    render(
      <MemoryRouter initialEntries={['/products/new']}>
        <App />
      </MemoryRouter>
    );

    await user.type(screen.getByLabelText('Name'), 'New Product');
    await user.type(screen.getByLabelText('Price'), '99.99');
    await user.click(screen.getByRole('button', { name: 'Create' }));

    await waitFor(() => {
      expect(screen.getByText('Product created successfully')).toBeInTheDocument();
    });
  });
});
```

**Quality Criteria**:
- [ ] All critical user flows tested
- [ ] Success and error paths covered
- [ ] Async operations properly awaited
- [ ] Tests are stable (no flaky tests)

---

## Stage Outputs

| Output | Description | Location |
|--------|-------------|----------|
| Test configuration | Vitest setup | `vitest.config.ts` |
| Unit tests | Utils/hooks tests | `src/__tests__/unit/` |
| Component tests | UI component tests | `src/__tests__/components/` |
| Integration tests | User flow tests | `src/__tests__/integration/` |

---

## Approval Gate F1

**Location**: After this stage
**Approvers**: Tech Lead, UX Lead
**Criteria**:
- [ ] Test coverage >= 70%
- [ ] All tests passing
- [ ] No accessibility issues
- [ ] Performance metrics met

---

## Success Criteria

- [ ] All 4 workers completed
- [ ] Test coverage >= 70%
- [ ] All tests passing in CI
- [ ] No flaky tests
- [ ] Gate F1 approval obtained

---

## Dependencies

**Depends On**: Stage F3 (React + Mock API)
**Blocks**: Stage F5 (API Integration)

---

## Estimated Duration

| Activity | Agentic | Manual |
|----------|---------|--------|
| Test setup | 15 min | 1 hour |
| Unit tests | 30 min | 3 hours |
| Component tests | 40 min | 4 hours |
| Integration tests | 30 min | 3 hours |
| **Total** | **2 hours** | **11 hours** |

---

**Navigation**: [<- Stage F3](./stage-f3-react-mock-api.md) | [Main Plan](./main-plan.md) | [Stage F5 ->](./stage-f5-api-integration.md)
