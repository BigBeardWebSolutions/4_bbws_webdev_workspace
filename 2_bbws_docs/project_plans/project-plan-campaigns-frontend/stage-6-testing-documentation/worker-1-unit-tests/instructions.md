# Worker Instructions: Unit Tests

**Worker ID**: worker-1-unit-tests
**Stage**: Stage 6 - Testing & Documentation
**Project**: project-plan-campaigns-frontend

---

## Task

Create comprehensive unit tests for all React components and services to achieve 80%+ code coverage. Tests should cover rendering, user interactions, and edge cases.

---

## Inputs

**Primary Inputs**:
- All component files in `src/components/`
- All service files in `src/services/`
- Existing test files (`*.test.tsx`)

**Testing Tools**:
- Vitest
- React Testing Library
- Vitest Coverage (v8)

---

## Deliverables

Create `output.md` documenting:

### 1. Test Coverage Report

Document current coverage and gaps.

### 2. Component Tests

For each component:
- Rendering tests
- Interaction tests
- Edge case tests

### 3. Service Tests

For each service:
- Function tests
- Error handling tests
- Cache tests

### 4. Test Patterns

Document testing patterns used:
- Mocking strategies
- Async testing
- State testing

---

## Expected Output Format

```markdown
# Unit Tests Output

## 1. Test Coverage Report

### Current Coverage
| Category | Coverage | Target |
|----------|----------|--------|
| Statements | XX% | 80% |
| Branches | XX% | 75% |
| Functions | XX% | 80% |
| Lines | XX% | 80% |

### Uncovered Files
- [ ] File1.tsx - needs tests
- [ ] File2.ts - needs tests

## 2. Component Tests

### PricingPage.test.tsx
```typescript
import { describe, it, expect, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import PricingPage from './PricingPage';
import { mockPlans } from '../../test/mocks';

// Mock campaign API
vi.mock('../../services/campaignApi', () => ({
  fetchCampaigns: vi.fn().mockResolvedValue([]),
  getCampaignsByProduct: vi.fn().mockResolvedValue(new Map())
}));

describe('PricingPage', () => {
  it('renders pricing header', () => {
    render(
      <MemoryRouter>
        <PricingPage plans={mockPlans} />
      </MemoryRouter>
    );

    expect(screen.getByText('Transparent Pricing')).toBeInTheDocument();
  });

  it('displays all pricing plans', () => {
    render(
      <MemoryRouter>
        <PricingPage plans={mockPlans} />
      </MemoryRouter>
    );

    expect(screen.getByText('Entry')).toBeInTheDocument();
    expect(screen.getByText('Basic')).toBeInTheDocument();
    expect(screen.getByText('Professional')).toBeInTheDocument();
  });

  it('shows campaign banner when campaigns exist', async () => {
    vi.mocked(fetchCampaigns).mockResolvedValue([mockCampaign]);

    render(
      <MemoryRouter>
        <PricingPage plans={mockPlans} />
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(screen.getByTestId('campaign-banner')).toBeInTheDocument();
    });
  });

  it('handles campaign fetch error gracefully', async () => {
    vi.mocked(fetchCampaigns).mockRejectedValue(new Error('API Error'));

    render(
      <MemoryRouter>
        <PricingPage plans={mockPlans} />
      </MemoryRouter>
    );

    // Should still render pricing without campaigns
    expect(screen.getByText('Transparent Pricing')).toBeInTheDocument();
  });
});
```

### PricingCard.test.tsx
```typescript
describe('PricingCard', () => {
  it('renders plan name and price', () => { });
  it('shows discount when campaign active', () => { });
  it('calculates savings correctly', () => { });
  it('calls onBuyClick when button clicked', () => { });
  it('applies hover styles', () => { });
});
```

### CheckoutPage.test.tsx
```typescript
describe('CheckoutPage', () => {
  it('redirects to home if no plan selected', () => { });
  it('displays order summary', () => { });
  it('renders customer form', () => { });
  it('shows loading state during submit', () => { });
  it('handles submission error', () => { });
});
```

### FormField.test.tsx
```typescript
describe('FormField', () => {
  it('renders label and input', () => { });
  it('associates label with input', () => { });
  it('shows required indicator', () => { });
  it('displays error message', () => { });
  it('applies error styling', () => { });
});
```

## 3. Service Tests

### campaignApi.test.ts
```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { fetchCampaigns, getCampaignByCode, clearCampaignCache } from './campaignApi';

describe('campaignApi', () => {
  beforeEach(() => {
    clearCampaignCache();
    vi.resetAllMocks();
  });

  describe('fetchCampaigns', () => {
    it('fetches campaigns from API', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ campaigns: [mockCampaign], count: 1 })
      });

      const campaigns = await fetchCampaigns();

      expect(campaigns).toHaveLength(1);
      expect(campaigns[0].code).toBe('TEST');
    });

    it('returns cached campaigns on subsequent calls', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ campaigns: [mockCampaign], count: 1 })
      });

      await fetchCampaigns();
      await fetchCampaigns();

      expect(fetch).toHaveBeenCalledTimes(1);
    });

    it('returns empty array on API error', async () => {
      global.fetch = vi.fn().mockRejectedValue(new Error('Network error'));

      const campaigns = await fetchCampaigns();

      expect(campaigns).toEqual([]);
    });

    it('retries on failure', async () => {
      global.fetch = vi.fn()
        .mockRejectedValueOnce(new Error('Fail 1'))
        .mockResolvedValue({
          ok: true,
          json: () => Promise.resolve({ campaigns: [], count: 0 })
        });

      await fetchCampaigns();

      expect(fetch).toHaveBeenCalledTimes(2);
    });
  });

  describe('getCampaignByCode', () => {
    it('returns campaign matching code', async () => { });
    it('returns null for unknown code', async () => { });
  });
});
```

## 4. Test Patterns

### Mocking API Calls
```typescript
// Mock entire module
vi.mock('../../services/campaignApi');

// Mock specific implementation
vi.mocked(fetchCampaigns).mockResolvedValue([mockCampaign]);

// Mock fetch globally
global.fetch = vi.fn().mockResolvedValue({
  ok: true,
  json: () => Promise.resolve(mockData)
});
```

### Testing Async Operations
```typescript
it('handles async operation', async () => {
  render(<Component />);

  await waitFor(() => {
    expect(screen.getByText('Loaded')).toBeInTheDocument();
  });
});
```

### Testing User Interactions
```typescript
it('handles click', async () => {
  const user = userEvent.setup();
  render(<Button onClick={handleClick} />);

  await user.click(screen.getByRole('button'));

  expect(handleClick).toHaveBeenCalled();
});
```

## 5. Mock Data

### test/mocks.ts
```typescript
export const mockPlans: PricingPlan[] = [
  {
    id: 'PROD-001',
    name: 'Entry',
    price: 'R95',
    priceNumeric: 95,
    // ...
  }
];

export const mockCampaign: Campaign = {
  code: 'TEST',
  name: 'Test Campaign',
  productId: 'PROD-001',
  discountPercent: 20,
  listPrice: 100,
  price: 80,
  status: 'ACTIVE',
  fromDate: '2025-01-01',
  toDate: '2025-12-31',
  isValid: true
};
```

## 6. Test Commands

```bash
# Run all tests
npm run test

# Run with coverage
npm run test:coverage

# Run specific file
npm run test -- PricingPage.test.tsx

# Watch mode
npm run test -- --watch
```

## 7. Validation Checklist

- [ ] All components have tests
- [ ] All services have tests
- [ ] Coverage >= 80%
- [ ] Error cases covered
- [ ] Edge cases tested
- [ ] Mocks documented
```

---

## Success Criteria

- [ ] All components tested
- [ ] All services tested
- [ ] 80%+ code coverage
- [ ] Error handling tested
- [ ] Mock data created
- [ ] Output.md created with all sections

---

## Execution Steps

1. Run current test coverage
2. Identify untested components
3. Create component tests
4. Create service tests
5. Create mock data
6. Verify coverage target
7. Create output.md with all sections
8. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-18
