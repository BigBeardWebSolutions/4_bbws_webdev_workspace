# Worker Instructions: Campaign Components

**Worker ID**: worker-3-campaign-components
**Stage**: Stage 3 - Core Components Development
**Project**: project-plan-campaigns-frontend

---

## Task

Validate and enhance the campaign-specific components (CampaignBanner, DiscountSummary) to properly display promotional information, discount details, and campaign validity.

---

## Inputs

**Primary Inputs**:
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/src/components/campaign/` (all files)
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/src/components/campaign/index.ts`

**Supporting Inputs**:
- Campaign types (`src/types/campaign.ts`)
- LLD campaign display requirements
- Stage 1 Gap Analysis output

---

## Deliverables

Create `output.md` documenting:

### 1. CampaignBanner Component

Validate:
- Banner display when campaigns active
- Campaign name/title
- Discount percentage
- Validity dates
- Urgency messaging

### 2. DiscountSummary Component

Validate:
- Original price display
- Discount amount
- Final price
- Savings calculation
- Terms and conditions

### 3. Campaign Display Patterns

Document patterns for:
- Active campaign display
- Expiring soon indicator
- Multiple campaigns handling
- No campaign state

---

## Expected Output Format

```markdown
# Campaign Components Output

## 1. CampaignBanner Component

### Current Implementation
```tsx
interface CampaignBannerProps {
  campaigns: Campaign[];
}

const CampaignBanner: React.FC<CampaignBannerProps> = ({ campaigns }) => {
  if (campaigns.length === 0) return null;

  const activeCampaign = campaigns[0]; // Show first active

  return (
    <div style={bannerStyles}>
      <span>{activeCampaign.name}</span>
      <span>{activeCampaign.discountPercent}% OFF</span>
      <span>Valid until {formatDate(activeCampaign.toDate)}</span>
    </div>
  );
};
```

### Visual Design
- Background: Gradient or accent color
- Text: High contrast for readability
- Icon: Sale/discount icon
- Animation: Subtle attention-grabbing

### Displayed Information
| Element | Source | Example |
|---------|--------|---------|
| Campaign Name | campaign.name | "Summer Sale 2025" |
| Discount | campaign.discountPercent | "20% OFF" |
| End Date | campaign.toDate | "Ends Aug 31" |
| CTA | Link to pricing | "Shop Now" |

### Validation Checklist
- [ ] Shows when campaigns exist
- [ ] Hides when no campaigns
- [ ] Displays correct discount
- [ ] Shows validity period
- [ ] Responsive on mobile
- [ ] Dismissible (optional)

## 2. DiscountSummary Component

### Current Implementation
```tsx
interface DiscountSummaryProps {
  originalPrice: number;
  discountPercent: number;
  finalPrice: number;
  campaignName?: string;
}

const DiscountSummary: React.FC<DiscountSummaryProps> = ({
  originalPrice,
  discountPercent,
  finalPrice,
  campaignName
}) => {
  const savings = originalPrice - finalPrice;

  return (
    <div style={summaryStyles}>
      <div>Original: R{originalPrice}</div>
      <div>Discount: {discountPercent}%</div>
      <div>You Save: R{savings}</div>
      <div>Final Price: R{finalPrice}</div>
    </div>
  );
};
```

### Calculation Logic
```typescript
// Price calculation
const finalPrice = listPrice * (1 - discountPercent / 100);
const savings = listPrice - finalPrice;
```

### Validation Checklist
- [ ] Original price displayed
- [ ] Discount percentage shown
- [ ] Savings calculated correctly
- [ ] Final price highlighted
- [ ] Campaign name referenced
- [ ] Currency formatted correctly

## 3. Campaign Display Patterns

### Pattern: Active Campaign
```tsx
{campaign.isValid && (
  <div className="campaign-active">
    <Badge>{campaign.discountPercent}% OFF</Badge>
    <Text>Offer ends {formatDate(campaign.toDate)}</Text>
  </div>
)}
```

### Pattern: Expiring Soon (< 24 hours)
```tsx
const isExpiringSoon = isWithin24Hours(campaign.toDate);

{isExpiringSoon && (
  <div className="campaign-urgent">
    <Icon type="clock" />
    <Text>Hurry! Offer ends soon</Text>
  </div>
)}
```

### Pattern: Multiple Campaigns
```tsx
// Show best discount for each product
const getBestCampaign = (productId: string, campaigns: Campaign[]): Campaign | null => {
  const applicable = campaigns.filter(c => c.productId === productId && c.isValid);
  return applicable.sort((a, b) => b.discountPercent - a.discountPercent)[0] || null;
};
```

### Pattern: No Campaign
```tsx
{!campaign && (
  <div className="no-campaign">
    <Text>Regular pricing</Text>
  </div>
)}
```

## 4. Enhancement Recommendations

### CampaignBanner
- [ ] Add countdown timer for ending campaigns
- [ ] Support multiple campaigns in carousel
- [ ] Add close/dismiss button
- [ ] Animate on page load

### DiscountSummary
- [ ] Add visual strikethrough for original price
- [ ] Highlight savings with color
- [ ] Add tooltips for T&Cs
- [ ] Format currency with locale

### Accessibility
- [ ] ARIA live region for banner
- [ ] Screen reader friendly prices
- [ ] Color contrast compliance

## 5. Component Exports

### index.ts
```typescript
export { default as CampaignBanner } from './CampaignBanner';
export { default as DiscountSummary } from './DiscountSummary';
// Add any other campaign components
```

## 6. Test Coverage

### Existing Tests
- CampaignBanner.test.tsx: Present/Missing
- DiscountSummary.test.tsx: Present/Missing

### Test Cases Needed
- [ ] Banner shows active campaign
- [ ] Banner hides when no campaigns
- [ ] Discount calculation correct
- [ ] Expiring soon indicator works
```

---

## Success Criteria

- [ ] CampaignBanner component validated
- [ ] DiscountSummary component validated
- [ ] Display patterns documented
- [ ] Calculations verified
- [ ] Edge cases handled
- [ ] Test coverage documented
- [ ] Output.md created with all sections

---

## Execution Steps

1. Read all files in src/components/campaign/
2. Document CampaignBanner implementation
3. Document DiscountSummary implementation
4. Verify calculation logic
5. Document display patterns
6. Review edge case handling
7. Document enhancement recommendations
8. Create output.md with all sections
9. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-18
