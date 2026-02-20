# Worker Instructions: Payment Pages

**Worker ID**: worker-2-payment-pages
**Stage**: Stage 5 - Checkout Flow
**Project**: project-plan-campaigns-frontend

---

## Task

Validate and enhance the PaymentSuccess and PaymentCancel pages to properly handle PayFast callback responses, display appropriate messages, and guide users on next steps.

---

## Inputs

**Primary Inputs**:
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/src/components/payment/PaymentSuccess.tsx`
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/src/components/payment/PaymentCancel.tsx`

**Supporting Inputs**:
- PayFast integration documentation
- Stage 4 outputs

---

## Deliverables

Create `output.md` documenting:

### 1. PaymentSuccess Component

Validate:
- Query parameter handling
- Success message display
- Order details display
- Next steps guidance

### 2. PaymentCancel Component

Validate:
- Query parameter handling
- Cancellation message
- Retry option
- Return to pricing

### 3. PayFast Callback Handling

Document:
- Expected query parameters
- Validation approach
- Error scenarios

---

## Expected Output Format

```markdown
# Payment Pages Output

## 1. PaymentSuccess Component

### Current Implementation
```tsx
const PaymentSuccess: React.FC = () => {
  const [searchParams] = useSearchParams();
  const orderId = searchParams.get('m_payment_id');
  const pfPaymentId = searchParams.get('pf_payment_id');

  return (
    <div style={pageStyles}>
      <SuccessIcon />
      <h1>Payment Successful!</h1>
      <p>Thank you for your purchase.</p>

      {orderId && (
        <div className="order-details">
          <p>Order ID: {orderId}</p>
          <p>Payment Reference: {pfPaymentId}</p>
        </div>
      )}

      <div className="next-steps">
        <h2>What's Next?</h2>
        <ul>
          <li>You'll receive a confirmation email shortly</li>
          <li>Our team will be in touch within 24 hours</li>
          <li>Your service will be activated within 48 hours</li>
        </ul>
      </div>

      <button onClick={() => navigate('/')}>
        Return to Home
      </button>
    </div>
  );
};
```

### PayFast Success Parameters
| Parameter | Description | Example |
|-----------|-------------|---------|
| m_payment_id | Order/payment ID | ORD-12345 |
| pf_payment_id | PayFast reference | 12345678 |
| payment_status | Status | COMPLETE |
| amount_gross | Total paid | 1500.00 |

### Validation Checklist
- [ ] Displays success message
- [ ] Shows order reference
- [ ] Shows payment reference
- [ ] Provides next steps
- [ ] Return button works
- [ ] Handles missing params

## 2. PaymentCancel Component

### Current Implementation
```tsx
const PaymentCancel: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div style={pageStyles}>
      <CancelIcon />
      <h1>Payment Cancelled</h1>
      <p>Your payment was not completed.</p>

      <div className="options">
        <p>Don't worry - no charges were made to your account.</p>

        <button onClick={() => navigate(-1)}>
          Try Again
        </button>

        <button onClick={() => navigate('/')}>
          Browse Plans
        </button>
      </div>

      <div className="help">
        <p>Need help? <a href="mailto:support@bigbeard.co.za">Contact Support</a></p>
      </div>
    </div>
  );
};
```

### Validation Checklist
- [ ] Displays cancel message
- [ ] Reassures no charge
- [ ] Offers retry option
- [ ] Offers return to pricing
- [ ] Provides support contact
- [ ] Back button works

## 3. PayFast Callback Handling

### Expected Query Parameters

#### Success Callback
```
/payment/success?
  m_payment_id=ORD-12345&
  pf_payment_id=12345678&
  payment_status=COMPLETE&
  amount_gross=1500.00
```

#### Cancel Callback
```
/payment/cancel?
  m_payment_id=ORD-12345
```

### Validation Approach
```typescript
const validatePaymentCallback = (params: URLSearchParams): boolean => {
  const orderId = params.get('m_payment_id');
  const status = params.get('payment_status');

  // Basic validation
  if (!orderId) return false;

  // For success page, verify status
  if (status && status !== 'COMPLETE') {
    console.warn('Unexpected payment status:', status);
  }

  return true;
};
```

## 4. UI Design

### Success Page Layout
```
+----------------------------------+
|           [Check Icon]           |
|      Payment Successful!         |
|  Thank you for your purchase.    |
|                                  |
|  Order ID: ORD-12345            |
|  Reference: 12345678            |
|                                  |
|  +---------------------------+  |
|  |     What's Next?          |  |
|  | - Confirmation email      |  |
|  | - Team contact (24h)      |  |
|  | - Service activation (48h)|  |
|  +---------------------------+  |
|                                  |
|    [Return to Home Button]       |
+----------------------------------+
```

### Cancel Page Layout
```
+----------------------------------+
|           [X Icon]               |
|       Payment Cancelled          |
|  Your payment was not completed. |
|                                  |
|  No charges were made.           |
|                                  |
|    [Try Again] [Browse Plans]    |
|                                  |
|  Need help? Contact Support      |
+----------------------------------+
```

## 5. Enhancement Recommendations

### Success Page
- [ ] Display purchased plan details
- [ ] Show estimated activation date
- [ ] Add print/save receipt option
- [ ] Share on social media option

### Cancel Page
- [ ] Remember form data for retry
- [ ] Offer alternative payment methods
- [ ] Show contact support chat

### General
- [ ] Add animation on load
- [ ] Confetti on success (optional)
- [ ] Auto-redirect after timeout

## 6. Test Cases

### PaymentSuccess Tests
- [ ] Renders success message
- [ ] Displays order ID from params
- [ ] Displays payment reference
- [ ] Return button navigates home
- [ ] Handles missing parameters

### PaymentCancel Tests
- [ ] Renders cancel message
- [ ] Try Again button works
- [ ] Browse Plans navigates home
- [ ] Support link works
```

---

## Success Criteria

- [ ] PaymentSuccess displays correct info
- [ ] PaymentCancel provides clear options
- [ ] Query parameters handled
- [ ] Navigation works correctly
- [ ] Error scenarios handled
- [ ] Output.md created with all sections

---

## Execution Steps

1. Read PaymentSuccess.tsx
2. Document query parameter handling
3. Read PaymentCancel.tsx
4. Document user options
5. Review PayFast documentation
6. Document callback handling
7. Create output.md with all sections
8. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-18
