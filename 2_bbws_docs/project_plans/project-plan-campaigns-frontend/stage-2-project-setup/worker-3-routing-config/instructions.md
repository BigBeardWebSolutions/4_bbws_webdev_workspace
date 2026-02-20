# Worker Instructions: Routing Configuration

**Worker ID**: worker-3-routing-config
**Stage**: Stage 2 - Project Setup & Configuration
**Project**: project-plan-campaigns-frontend

---

## Task

Configure React Router DOM for all required routes including the main pricing page, checkout flow, and payment result pages. Ensure proper route guards and navigation handling.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/src/main.tsx` (or main.jsx)
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/src/App.tsx` (if exists)

**Supporting Inputs**:
- Stage 1 Gap Analysis output
- LLD route requirements
- Existing component structure

---

## Deliverables

Create `output.md` documenting:

### 1. Current Routing Analysis

Review current routing setup and document:
- Router type (BrowserRouter, HashRouter)
- Current routes defined
- Route parameters
- Navigation components

### 2. Required Routes

Based on LLD requirements:
| Route | Component | Purpose |
|-------|-----------|---------|
| `/` | PricingPage | Main pricing with campaigns |
| `/checkout` | CheckoutPage | Checkout form |
| `/payment/success` | PaymentSuccess | Success confirmation |
| `/payment/cancel` | PaymentCancel | Cancellation handling |

### 3. Route Configuration

Document complete routing setup:
- Route definitions
- Layout wrapping
- Error boundaries
- 404 handling

### 4. Navigation Flow

Document navigation between pages:
- Pricing -> Checkout (with state)
- Checkout -> PayFast -> Success/Cancel
- Success/Cancel -> Back to Pricing

---

## Expected Output Format

```markdown
# Routing Configuration Output

## 1. Current Routing Analysis

### Current Setup
- Router: BrowserRouter with basename="/buy"
- Location: main.tsx / App.tsx

### Current Routes
| Path | Component | Status |
|------|-----------|--------|
| / | PricingPage | Present |
| /checkout | CheckoutPage | Present/Missing |
| /payment/success | PaymentSuccess | Present/Missing |
| /payment/cancel | PaymentCancel | Present/Missing |

## 2. Required Routes

### Route Definitions
| Route | Component | State Required | Auth |
|-------|-----------|----------------|------|
| / | PricingPage | None | Public |
| /checkout | CheckoutPage | selectedPlan, campaign | Public |
| /payment/success | PaymentSuccess | orderId | Public |
| /payment/cancel | PaymentCancel | orderId | Public |

### Route Parameters
- `/checkout`: Receives state via `navigate('/checkout', { state: {...} })`
- `/payment/success`: May receive query params from PayFast
- `/payment/cancel`: May receive query params from PayFast

## 3. Route Configuration

### App.tsx / main.tsx Configuration
```tsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import PageLayout from './components/layout/PageLayout';
import PricingPage from './components/pricing/PricingPage';
import CheckoutPage from './components/checkout/CheckoutPage';
import PaymentSuccess from './components/payment/PaymentSuccess';
import PaymentCancel from './components/payment/PaymentCancel';
import { pricingPlans } from './data/products';

function App() {
  return (
    <BrowserRouter basename="/buy">
      <Routes>
        <Route
          path="/"
          element={
            <PageLayout showBackButton={false}>
              <PricingPage plans={pricingPlans} />
            </PageLayout>
          }
        />
        <Route
          path="/checkout"
          element={
            <PageLayout showBackButton={true}>
              <CheckoutPage />
            </PageLayout>
          }
        />
        <Route
          path="/payment/success"
          element={
            <PageLayout showBackButton={false}>
              <PaymentSuccess />
            </PageLayout>
          }
        />
        <Route
          path="/payment/cancel"
          element={
            <PageLayout showBackButton={true}>
              <PaymentCancel />
            </PageLayout>
          }
        />
        {/* 404 fallback */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
```

### Error Boundary
```tsx
<ErrorBoundary fallback={<ErrorPage />}>
  <Routes>
    ...
  </Routes>
</ErrorBoundary>
```

## 4. Navigation Flow

### Flow Diagram
```
PricingPage
    |
    | (click "Buy Now" with plan + campaign)
    v
CheckoutPage
    |
    | (submit form -> redirect to PayFast)
    v
PayFast Gateway
    |
    +---> payment/success (payment completed)
    |
    +---> payment/cancel (payment cancelled)
    |
    v
Back to PricingPage
```

### State Passing
```tsx
// PricingPage to CheckoutPage
navigate('/checkout', {
  state: {
    selectedPlan: plan,
    campaign: campaign
  }
});

// CheckoutPage access state
const location = useLocation();
const { selectedPlan, campaign } = location.state || {};

// Redirect if no plan selected
if (!selectedPlan) {
  return <Navigate to="/" replace />;
}
```

## 5. Route Guards

### CheckoutPage Guard
- If no `selectedPlan` in state, redirect to `/`
- Display loading state while fetching products

### Payment Pages
- Handle query params from PayFast
- Display appropriate message based on status

## 6. Validation Checklist

- [ ] All routes defined
- [ ] BrowserRouter with correct basename
- [ ] State passing works
- [ ] 404 fallback to home
- [ ] Navigation works correctly
- [ ] Back button behavior correct
```

---

## Success Criteria

- [ ] All required routes configured
- [ ] Route state passing validated
- [ ] Navigation flow documented
- [ ] Error handling defined
- [ ] 404 fallback implemented
- [ ] Output.md created with all sections

---

## Execution Steps

1. Read current routing setup (main.tsx/App.tsx)
2. Catalog existing routes
3. Compare with required routes
4. Document route configuration
5. Define navigation flow
6. Document route guards needed
7. Create output.md with all sections
8. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-18
