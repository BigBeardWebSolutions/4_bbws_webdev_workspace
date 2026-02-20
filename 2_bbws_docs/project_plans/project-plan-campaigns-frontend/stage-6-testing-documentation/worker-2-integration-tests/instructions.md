# Worker Instructions: Integration Tests

**Worker ID**: worker-2-integration-tests
**Stage**: Stage 6 - Testing & Documentation
**Project**: project-plan-campaigns-frontend

---

## Task

Create integration tests that validate complete user flows through the application, including pricing page navigation, checkout process, and payment handling.

---

## Inputs

**Primary Inputs**:
- All completed components and services
- Existing integration tests (`src/test/integration/`)
- Stage 5 outputs (checkout flow)

**Testing Tools**:
- Vitest
- React Testing Library
- Mock Service Worker (optional)

---

## Deliverables

Create `output.md` documenting:

### 1. User Flow Tests

Test complete user journeys:
- Browse pricing -> Select plan -> Checkout
- Apply campaign discount -> Verify total
- Complete checkout -> Payment redirect

### 2. API Integration Tests

Test frontend-to-API integration:
- Campaign API fetch
- Order creation
- Error scenarios

### 3. Navigation Tests

Test route transitions:
- Pricing to Checkout
- Checkout to Payment
- Payment back to Pricing

---

## Expected Output Format

```markdown
# Integration Tests Output

## 1. User Flow Tests

### userFlows.test.tsx
```typescript
import { describe, it, expect, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router-dom';
import App from '../../App';

describe('User Flows', () => {
  describe('Pricing to Checkout Flow', () => {
    it('allows user to select plan and proceed to checkout', async () => {
      const user = userEvent.setup();

      render(
        <MemoryRouter initialEntries={['/']}>
          <App />
        </MemoryRouter>
      );

      // Wait for pricing page to load
      await waitFor(() => {
        expect(screen.getByText('Transparent Pricing')).toBeInTheDocument();
      });

      // Find and click "Buy Now" on Professional plan
      const buyButtons = screen.getAllByRole('button', { name: /buy now/i });
      const professionalButton = buyButtons[2]; // Assuming third plan
      await user.click(professionalButton);

      // Verify checkout page loaded
      await waitFor(() => {
        expect(screen.getByText('Order Summary')).toBeInTheDocument();
      });
    });
  });

  describe('Campaign Discount Flow', () => {
    it('applies campaign discount correctly', async () => {
      // Mock campaign API
      vi.mocked(fetchCampaigns).mockResolvedValue([{
        code: 'TEST20',
        productId: 'PROD-002',
        discountPercent: 20,
        listPrice: 1500,
        price: 1200,
        isValid: true
      }]);

      render(
        <MemoryRouter initialEntries={['/']}>
          <App />
        </MemoryRouter>
      );

      // Wait for campaigns to load
      await waitFor(() => {
        expect(screen.getByTestId('campaign-banner')).toBeInTheDocument();
      });

      // Verify discounted price shown
      expect(screen.getByText('R1,200')).toBeInTheDocument();
      expect(screen.getByText('20% OFF')).toBeInTheDocument();
    });
  });

  describe('Checkout Form Flow', () => {
    it('validates form and submits order', async () => {
      const user = userEvent.setup();

      // Start at checkout with plan selected
      render(
        <MemoryRouter
          initialEntries={[{
            pathname: '/checkout',
            state: { selectedPlan: mockPlan, campaign: mockCampaign }
          }]}
        >
          <App />
        </MemoryRouter>
      );

      // Fill form
      await user.type(screen.getByLabelText(/first name/i), 'John');
      await user.type(screen.getByLabelText(/last name/i), 'Doe');
      await user.type(screen.getByLabelText(/email/i), 'john@example.com');
      await user.type(screen.getByLabelText(/phone/i), '0821234567');

      // Submit
      await user.click(screen.getByRole('button', { name: /continue/i }));

      // Verify submission
      await waitFor(() => {
        expect(orderApi.createOrder).toHaveBeenCalled();
      });
    });

    it('shows validation errors for invalid input', async () => {
      const user = userEvent.setup();

      render(
        <MemoryRouter
          initialEntries={[{
            pathname: '/checkout',
            state: { selectedPlan: mockPlan }
          }]}
        >
          <App />
        </MemoryRouter>
      );

      // Submit empty form
      await user.click(screen.getByRole('button', { name: /continue/i }));

      // Verify error messages
      expect(screen.getByText(/first name/i)).toBeInTheDocument();
    });
  });
});
```

## 2. API Integration Tests

### campaignIntegration.test.ts
```typescript
describe('Campaign API Integration', () => {
  it('fetches and displays campaigns', async () => {
    // Setup mock server or API
    server.use(
      http.get('*/v1.0/campaigns', () => {
        return HttpResponse.json({
          campaigns: [mockCampaign],
          count: 1
        });
      })
    );

    render(<App />);

    await waitFor(() => {
      expect(screen.getByText(mockCampaign.name)).toBeInTheDocument();
    });
  });

  it('handles API failure gracefully', async () => {
    server.use(
      http.get('*/v1.0/campaigns', () => {
        return new HttpResponse(null, { status: 500 });
      })
    );

    render(<App />);

    // Should show pricing without campaigns
    await waitFor(() => {
      expect(screen.getByText('Transparent Pricing')).toBeInTheDocument();
    });

    // No campaign banner
    expect(screen.queryByTestId('campaign-banner')).not.toBeInTheDocument();
  });
});
```

## 3. Navigation Tests

### navigation.test.tsx
```typescript
describe('Navigation', () => {
  it('navigates from pricing to checkout', async () => {
    const user = userEvent.setup();

    render(
      <MemoryRouter>
        <App />
      </MemoryRouter>
    );

    // Click buy button
    await user.click(screen.getAllByRole('button', { name: /buy/i })[0]);

    // Verify URL changed
    expect(window.location.pathname).toBe('/checkout');
  });

  it('redirects to home if checkout accessed directly', async () => {
    render(
      <MemoryRouter initialEntries={['/checkout']}>
        <App />
      </MemoryRouter>
    );

    // Should redirect to pricing
    await waitFor(() => {
      expect(screen.getByText('Transparent Pricing')).toBeInTheDocument();
    });
  });

  it('handles payment success return', async () => {
    render(
      <MemoryRouter initialEntries={['/payment/success?m_payment_id=123']}>
        <App />
      </MemoryRouter>
    );

    expect(screen.getByText(/payment successful/i)).toBeInTheDocument();
  });

  it('handles payment cancel return', async () => {
    render(
      <MemoryRouter initialEntries={['/payment/cancel']}>
        <App />
      </MemoryRouter>
    );

    expect(screen.getByText(/payment cancelled/i)).toBeInTheDocument();
  });
});
```

## 4. Error Handling Tests

### errorHandling.test.tsx
```typescript
describe('Error Handling', () => {
  it('shows error message on order creation failure', async () => {
    vi.mocked(orderApi.createOrder).mockRejectedValue(
      new Error('Order creation failed')
    );

    const user = userEvent.setup();

    render(
      <MemoryRouter initialEntries={[{
        pathname: '/checkout',
        state: { selectedPlan: mockPlan }
      }]}>
        <App />
      </MemoryRouter>
    );

    // Fill and submit form
    await fillCheckoutForm(user);
    await user.click(screen.getByRole('button', { name: /continue/i }));

    // Verify error shown
    await waitFor(() => {
      expect(screen.getByRole('alert')).toBeInTheDocument();
    });
  });

  it('allows retry after error', async () => {
    // First call fails, second succeeds
    vi.mocked(orderApi.createOrder)
      .mockRejectedValueOnce(new Error('Fail'))
      .mockResolvedValue({ orderId: '123', paymentUrl: 'https://...' });

    // Test retry behavior
  });
});
```

## 5. Test Setup

### test/setup.ts
```typescript
import { afterEach, beforeAll, afterAll } from 'vitest';
import { cleanup } from '@testing-library/react';
import '@testing-library/jest-dom/vitest';

// Clean up after each test
afterEach(() => {
  cleanup();
});

// Setup mock server if using MSW
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

## 6. Test Data Helpers

### test/helpers.ts
```typescript
export const fillCheckoutForm = async (user: UserEvent) => {
  await user.type(screen.getByLabelText(/first name/i), 'John');
  await user.type(screen.getByLabelText(/last name/i), 'Doe');
  await user.type(screen.getByLabelText(/email/i), 'john@test.com');
  await user.type(screen.getByLabelText(/phone/i), '0821234567');
};

export const mockPlan: PricingPlan = { ... };
export const mockCampaign: Campaign = { ... };
```

## 7. Validation Checklist

- [ ] Pricing to checkout flow tested
- [ ] Campaign discount flow tested
- [ ] Form submission flow tested
- [ ] API integration tested
- [ ] Navigation tested
- [ ] Error handling tested
- [ ] All tests passing
```

---

## Success Criteria

- [ ] User flows tested end-to-end
- [ ] API integration validated
- [ ] Navigation works correctly
- [ ] Error handling covered
- [ ] All tests passing
- [ ] Output.md created with all sections

---

## Execution Steps

1. Review existing integration tests
2. Create user flow tests
3. Create API integration tests
4. Create navigation tests
5. Create error handling tests
6. Verify all tests pass
7. Create output.md with all sections
8. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-18
