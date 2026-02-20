# Worker Instructions: Checkout Page

**Worker ID**: worker-1-checkout-page
**Stage**: Stage 5 - Checkout Flow
**Project**: project-plan-campaigns-frontend

---

## Task

Validate and enhance the CheckoutPage component to properly display selected plan with campaign discount, collect customer information, and initiate the PayFast payment flow.

---

## Inputs

**Primary Inputs**:
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/src/components/checkout/CheckoutPage.tsx`
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/src/components/checkout/OrderSummary.tsx`
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/src/components/checkout/CustomerForm.tsx`

**Supporting Inputs**:
- Stage 4 outputs (API integration)
- PayFast service (`src/services/payfastService.ts`)
- Form types (`src/types/form.ts`)

---

## Deliverables

Create `output.md` documenting:

### 1. CheckoutPage Component

Validate:
- Route state handling (selectedPlan, campaign)
- Order summary display
- Customer form integration
- PayFast submission

### 2. OrderSummary Component

Validate:
- Plan details display
- Campaign discount display
- Price breakdown
- Total calculation

### 3. Form Submission Flow

Document:
- Form validation
- Order API call
- PayFast redirect
- Error handling

---

## Expected Output Format

```markdown
# Checkout Page Output

## 1. CheckoutPage Component

### Current Implementation
```tsx
const CheckoutPage: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const { selectedPlan, campaign } = location.state || {};

  // Redirect if no plan selected
  if (!selectedPlan) {
    return <Navigate to="/" replace />;
  }

  const handleSubmit = async (customerData: CustomerFormData) => {
    // 1. Create order via Order API
    // 2. Get PayFast redirect URL
    // 3. Redirect to PayFast
  };

  return (
    <div style={pageStyles}>
      <OrderSummary plan={selectedPlan} campaign={campaign} />
      <CustomerForm onSubmit={handleSubmit} />
    </div>
  );
};
```

### Route State Handling
```typescript
interface CheckoutState {
  selectedPlan: PricingPlan;
  campaign?: Campaign;
}

// Access via useLocation
const { state } = useLocation() as { state: CheckoutState | undefined };
```

### Validation Checklist
- [ ] Handles missing plan (redirect to /)
- [ ] Displays order summary
- [ ] Shows customer form
- [ ] Handles form submission
- [ ] Shows loading state
- [ ] Handles errors

## 2. OrderSummary Component

### Current Implementation
```tsx
interface OrderSummaryProps {
  plan: PricingPlan;
  campaign?: Campaign;
}

const OrderSummary: React.FC<OrderSummaryProps> = ({ plan, campaign }) => {
  const hasDiscount = campaign && campaign.isValid;
  const originalPrice = plan.priceNumeric;
  const finalPrice = hasDiscount ? campaign.price : originalPrice;
  const savings = hasDiscount ? originalPrice - finalPrice : 0;

  return (
    <div style={summaryStyles}>
      <h2>Order Summary</h2>

      <div className="plan-details">
        <h3>{plan.name}</h3>
        <p>{plan.description}</p>
      </div>

      <div className="price-breakdown">
        {hasDiscount && (
          <>
            <div>Original Price: <s>R{originalPrice}</s></div>
            <div>Discount ({campaign.discountPercent}%): -R{savings}</div>
          </>
        )}
        <div className="total">Total: R{finalPrice}</div>
      </div>

      {campaign && (
        <div className="campaign-info">
          <p>Campaign: {campaign.name}</p>
          <p>Code: {campaign.code}</p>
        </div>
      )}
    </div>
  );
};
```

### Price Display
| Scenario | Display |
|----------|---------|
| No campaign | Plan price only |
| With campaign | Original (strikethrough), discount, final |

### Validation Checklist
- [ ] Shows plan name
- [ ] Shows plan features
- [ ] Shows original price
- [ ] Shows discount (if campaign)
- [ ] Calculates savings
- [ ] Shows final price

## 3. Form Submission Flow

### Flow Diagram
```
CustomerForm.onSubmit(data)
    |
    v
CheckoutPage.handleSubmit(data)
    |
    +-- Create order (Order API)
    |
    +-- Get PayFast URL
    |
    v
Redirect to PayFast
```

### Order Creation
```typescript
const handleSubmit = async (customerData: CustomerFormData) => {
  setIsSubmitting(true);
  setError(null);

  try {
    // 1. Create order
    const order = await orderApi.createOrder({
      planId: selectedPlan.id,
      campaignCode: campaign?.code,
      customer: customerData
    });

    // 2. Redirect to PayFast
    window.location.href = order.paymentUrl;
  } catch (err) {
    setError('Failed to create order. Please try again.');
    setIsSubmitting(false);
  }
};
```

### Error Handling
- Form validation errors: Display inline
- Order API errors: Display banner
- Network errors: Allow retry

## 4. Enhancement Recommendations

### User Experience
- [ ] Show loading skeleton during API calls
- [ ] Confirm before leaving page
- [ ] Save form data in sessionStorage

### Campaign Display
- [ ] Show campaign expiry warning
- [ ] Display terms and conditions link
- [ ] Show savings prominently

### Accessibility
- [ ] Focus management on error
- [ ] ARIA announcements for price changes
- [ ] Form field descriptions

## 5. Test Cases

### Existing Tests
- CheckoutPage.test.tsx: Present/Missing
- OrderSummary.test.tsx: Present/Missing

### Required Tests
- [ ] Redirects when no plan
- [ ] Shows plan details
- [ ] Applies campaign discount
- [ ] Calculates total correctly
- [ ] Submits form successfully
- [ ] Handles submission error
```

---

## Success Criteria

- [ ] CheckoutPage handles route state
- [ ] OrderSummary shows correct prices
- [ ] Campaign discount applied correctly
- [ ] Form submission works
- [ ] Error handling complete
- [ ] Output.md created with all sections

---

## Execution Steps

1. Read CheckoutPage.tsx
2. Document route state handling
3. Read OrderSummary.tsx
4. Document price calculation
5. Read CustomerForm.tsx
6. Document form submission flow
7. Review error handling
8. Create output.md with all sections
9. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-18
