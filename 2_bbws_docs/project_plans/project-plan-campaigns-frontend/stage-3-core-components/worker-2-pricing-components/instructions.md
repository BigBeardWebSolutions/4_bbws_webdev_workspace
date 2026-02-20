# Worker Instructions: Pricing Components

**Worker ID**: worker-2-pricing-components
**Stage**: Stage 3 - Core Components Development
**Project**: project-plan-campaigns-frontend

---

## Task

Validate and enhance the pricing components (PricingPage, PricingCard, PricingFeature) to properly display pricing plans with campaign discounts and provide clear call-to-action buttons.

---

## Inputs

**Primary Inputs**:
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/src/components/pricing/PricingPage.tsx`
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/src/components/pricing/PricingCard.tsx`
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/src/components/pricing/PricingFeature.tsx`

**Supporting Inputs**:
- Campaign types (`src/types/campaign.ts`)
- Product types (`src/types/product.ts`)
- Stage 1 Gap Analysis output

---

## Deliverables

Create `output.md` documenting:

### 1. PricingPage Component

Validate:
- Campaign data fetching
- Loading states
- Error handling
- Card grid layout
- Campaign banner integration

### 2. PricingCard Component

Validate:
- Plan display
- Campaign discount display
- Price calculation
- "Most Popular" badge
- CTA button behavior

### 3. PricingFeature Component

Validate:
- Feature list rendering
- Check mark styling
- Alignment

### 4. Price Display Logic

Document:
- Original price (strikethrough when discounted)
- Discounted price (highlighted)
- Discount percentage badge
- Savings display

---

## Expected Output Format

```markdown
# Pricing Components Output

## 1. PricingPage Component

### Current Implementation
```tsx
const PricingPage: React.FC<PricingPageProps> = ({ plans, onSelectPlan }) => {
  const [campaigns, setCampaigns] = useState<Campaign[]>([]);
  const [isLoadingCampaigns, setIsLoadingCampaigns] = useState(true);

  useEffect(() => {
    // Fetch campaigns
  }, []);

  return (
    <div>
      <CampaignBanner campaigns={campaigns} />
      <Header />
      <PricingCards />
    </div>
  );
};
```

### Props Interface
```tsx
interface PricingPageProps {
  plans: PricingPlan[];
  onSelectPlan?: (plan: PricingPlan) => void;
}
```

### Campaign Integration
- Fetches campaigns on mount
- Maps campaigns to products by productId
- Passes campaign to each PricingCard

### Validation Checklist
- [ ] Campaigns fetched correctly
- [ ] Loading state displayed
- [ ] Error handled gracefully
- [ ] Cards display in grid
- [ ] Navigation to checkout works

## 2. PricingCard Component

### Current Implementation
```tsx
interface PricingCardProps {
  plan: PricingPlan;
  campaign?: Campaign;
  isHovered: boolean;
  onHover: () => void;
  onLeave: () => void;
  onBuyClick: () => void;
}

const PricingCard: React.FC<PricingCardProps> = ({
  plan,
  campaign,
  isHovered,
  onHover,
  onLeave,
  onBuyClick
}) => {
  // Render card
};
```

### Price Display Logic
```tsx
// When campaign is active
const hasDiscount = campaign && campaign.isValid;
const displayPrice = hasDiscount ? campaign.price : plan.priceNumeric;
const originalPrice = hasDiscount ? plan.priceNumeric : null;
```

### Validation Checklist
- [ ] Plan name displayed
- [ ] Price displayed correctly
- [ ] Discount shown when campaign active
- [ ] Original price strikethrough
- [ ] "Most Popular" badge on correct plan
- [ ] CTA button works
- [ ] Hover state applied

### Visual Elements
| Element | With Campaign | Without Campaign |
|---------|---------------|------------------|
| Original Price | Strikethrough | Hidden |
| Current Price | Campaign price | List price |
| Discount Badge | "20% OFF" | Hidden |
| Savings | "Save R300" | Hidden |

## 3. PricingFeature Component

### Current Implementation
```tsx
interface PricingFeatureProps {
  feature: string;
}

const PricingFeature: React.FC<PricingFeatureProps> = ({ feature }) => {
  return (
    <div style={featureStyles}>
      <CheckIcon />
      <span>{feature}</span>
    </div>
  );
};
```

### Validation Checklist
- [ ] Check icon displayed
- [ ] Feature text readable
- [ ] Proper spacing
- [ ] Accessible

## 4. Enhancement Recommendations

### Price Display
- [ ] Animate price changes
- [ ] Add currency formatting
- [ ] Show "from" for variable pricing

### Campaign Display
- [ ] Add countdown timer for expiring campaigns
- [ ] Show campaign end date
- [ ] Add terms and conditions link

### Accessibility
- [ ] Announce discount to screen readers
- [ ] Focus management on hover

## 5. Test Coverage

### Existing Tests
- PricingPage.test.tsx: Present/Missing
- PricingCard.test.tsx: Present/Missing
- PricingFeature.test.tsx: Present/Missing

### Test Cases Needed
- [ ] PricingPage shows loading state
- [ ] PricingPage displays campaigns
- [ ] PricingCard shows discount correctly
- [ ] PricingCard calculates savings
```

---

## Success Criteria

- [ ] PricingPage component validated
- [ ] PricingCard component validated
- [ ] PricingFeature component validated
- [ ] Campaign discount display verified
- [ ] Price calculation logic correct
- [ ] Test coverage documented
- [ ] Output.md created with all sections

---

## Execution Steps

1. Read PricingPage.tsx
2. Document campaign fetching logic
3. Read PricingCard.tsx
4. Document price display logic
5. Read PricingFeature.tsx
6. Review existing tests
7. Document enhancement recommendations
8. Create output.md with all sections
9. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-18
