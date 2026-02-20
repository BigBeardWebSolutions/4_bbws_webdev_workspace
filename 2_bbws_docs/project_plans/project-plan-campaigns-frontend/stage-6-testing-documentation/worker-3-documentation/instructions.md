# Worker Instructions: Documentation

**Worker ID**: worker-3-documentation
**Stage**: Stage 6 - Testing & Documentation
**Project**: project-plan-campaigns-frontend

---

## Task

Create and update documentation including README, code documentation (JSDoc), and usage guides for the Campaigns Frontend application.

---

## Inputs

**Primary Inputs**:
- All source code files
- Existing README.md
- LLD documentation
- All stage outputs

**Supporting Inputs**:
- API documentation from LLD
- Environment configuration

---

## Deliverables

Create `output.md` documenting:

### 1. README Update

Comprehensive README with:
- Project overview
- Setup instructions
- Environment configuration
- Available scripts
- API integration
- Deployment

### 2. JSDoc Comments

Document all exports with:
- Function descriptions
- Parameter types
- Return types
- Usage examples

### 3. Architecture Documentation

Create or update:
- Component hierarchy
- Data flow diagram
- API integration diagram

---

## Expected Output Format

```markdown
# Documentation Output

## 1. README.md Update

### Updated README Structure
```markdown
# Campaigns Frontend

Production-ready React application for displaying pricing plans with promotional campaigns.

## Features

- Pricing page with campaign discounts
- Campaign banner for active promotions
- Checkout flow with PayFast integration
- Responsive design
- TypeScript for type safety

## Tech Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| React | 18.3.1 | UI Framework |
| TypeScript | 5.9.3 | Type Safety |
| Vite | 5.4.10 | Build Tool |
| React Router | 7.12.0 | Routing |
| Vitest | 4.0.16 | Testing |

## Getting Started

### Prerequisites

- Node.js >= 20.0.0
- npm >= 10.0.0

### Installation

```bash
# Clone repository
git clone https://github.com/your-org/2_1_bbws_web_public.git
cd 2_1_bbws_web_public/campaigns

# Install dependencies
npm install
```

### Environment Configuration

Create environment files based on deployment target:

#### .env.development
```env
VITE_API_BASE_URL=https://api.dev.kimmyai.io
VITE_ENVIRONMENT=development
```

#### .env.sit
```env
VITE_API_BASE_URL=https://api.sit.kimmyai.io
VITE_ENVIRONMENT=sit
```

#### .env.production
```env
VITE_API_BASE_URL=https://api.kimmyai.io
VITE_ENVIRONMENT=production
```

### Available Scripts

| Script | Description |
|--------|-------------|
| `npm run dev` | Start development server |
| `npm run build` | Build for production |
| `npm run build:dev` | Build for development |
| `npm run build:sit` | Build for SIT |
| `npm run build:prod` | Build for production |
| `npm run test` | Run tests |
| `npm run test:coverage` | Run tests with coverage |
| `npm run lint` | Lint code |
| `npm run type-check` | TypeScript check |

## Project Structure

```
campaigns/
├── src/
│   ├── components/
│   │   ├── layout/         # PageLayout, Navigation
│   │   ├── pricing/        # PricingPage, PricingCard
│   │   ├── checkout/       # CheckoutPage, CustomerForm
│   │   ├── payment/        # PaymentSuccess, PaymentCancel
│   │   └── campaign/       # CampaignBanner, DiscountSummary
│   ├── services/
│   │   ├── campaignApi.ts  # Campaign API integration
│   │   ├── productApi.ts   # Product API integration
│   │   └── orderApi.ts     # Order API integration
│   ├── types/
│   │   ├── campaign.ts     # Campaign types
│   │   ├── product.ts      # Product types
│   │   └── form.ts         # Form types
│   └── utils/
│       └── validation.ts   # Form validation
├── public/
├── vite.config.ts
├── tsconfig.json
└── package.json
```

## API Integration

### Campaign API

The application integrates with the Campaign API:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| /v1.0/campaigns | GET | List active campaigns |
| /v1.0/campaigns/{code} | GET | Get campaign by code |

### Example Response

```json
{
  "campaigns": [
    {
      "code": "SUMMER2025",
      "name": "Summer Sale",
      "discountPercent": 20,
      "listPrice": 1500,
      "price": 1200,
      "isValid": true
    }
  ]
}
```

## Routes

| Route | Component | Description |
|-------|-----------|-------------|
| `/` | PricingPage | Main pricing display |
| `/checkout` | CheckoutPage | Checkout form |
| `/payment/success` | PaymentSuccess | Payment confirmation |
| `/payment/cancel` | PaymentCancel | Payment cancellation |

## Testing

```bash
# Run all tests
npm run test

# Run with coverage
npm run test:coverage

# Run specific test file
npm run test -- PricingPage.test.tsx
```

## Deployment

### Build for Environment

```bash
# Development
npm run build:dev

# SIT
npm run build:sit

# Production
npm run build:prod
```

### Deploy

1. Build the application
2. Upload `dist/` folder to S3
3. Configure CloudFront distribution
4. Invalidate CloudFront cache

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md)

## License

Proprietary - Big Beard Web Solutions
```

## 2. JSDoc Comments

### Component Documentation
```typescript
/**
 * PricingPage Component
 *
 * Container component that displays pricing plans with campaign discounts.
 * Fetches campaigns from Campaign API and maps them to products.
 *
 * @component
 * @example
 * ```tsx
 * <PricingPage plans={pricingPlans} onSelectPlan={handleSelect} />
 * ```
 */

/**
 * Props for PricingPage component
 */
export interface PricingPageProps {
  /** Array of pricing plans to display */
  plans: PricingPlan[];

  /**
   * Callback when user selects a plan
   * @param plan - Selected pricing plan
   */
  onSelectPlan?: (plan: PricingPlan) => void;
}
```

### Service Documentation
```typescript
/**
 * Campaign API Service
 *
 * Handles all campaign-related API operations including:
 * - Fetching list of campaigns
 * - Getting campaign by code
 * - Caching responses for 5 minutes
 * - Retry logic with exponential backoff
 *
 * @module services/campaignApi
 */

/**
 * Fetch all active campaigns from Campaign API
 *
 * @returns Promise resolving to array of campaigns
 * @example
 * ```typescript
 * const campaigns = await fetchCampaigns();
 * console.log(`Found ${campaigns.length} campaigns`);
 * ```
 */
export const fetchCampaigns = async (): Promise<Campaign[]> => { };

/**
 * Get campaign for a specific product
 *
 * @param productId - Product ID to look up
 * @returns Campaign if found, undefined otherwise
 */
export const getCampaignForProduct = async (
  productId: string
): Promise<Campaign | undefined> => { };
```

### Type Documentation
```typescript
/**
 * Campaign entity representing a promotional offer
 *
 * Campaigns are time-bound discounts that can be applied to products.
 * Status is automatically calculated based on dates.
 */
export interface Campaign {
  /** Unique campaign code (e.g., "SUMMER2025") */
  code: string;

  /** Human-readable campaign name */
  name: string;

  /** Associated product ID */
  productId: string;

  /** Discount percentage (0-100) */
  discountPercent: number;

  /** Original price before discount */
  listPrice: number;

  /** Calculated discounted price */
  price: number;

  /**
   * Campaign status
   * - DRAFT: Not yet started
   * - ACTIVE: Currently valid
   * - EXPIRED: Past end date
   */
  status: CampaignStatus;

  /** Campaign start date (ISO 8601) */
  fromDate: string;

  /** Campaign end date (ISO 8601) */
  toDate: string;

  /** Whether campaign is currently valid for use */
  isValid: boolean;
}
```

## 3. Architecture Documentation

### Component Hierarchy
```
App
├── BrowserRouter
│   └── Routes
│       ├── / (PricingPage)
│       │   └── PageLayout
│       │       ├── Navigation
│       │       └── PricingPage
│       │           ├── CampaignBanner
│       │           └── PricingCard[]
│       │               └── PricingFeature[]
│       │
│       ├── /checkout (CheckoutPage)
│       │   └── PageLayout
│       │       └── CheckoutPage
│       │           ├── OrderSummary
│       │           └── CustomerForm
│       │               └── FormField[]
│       │
│       ├── /payment/success (PaymentSuccess)
│       │   └── PageLayout
│       │       └── PaymentSuccess
│       │
│       └── /payment/cancel (PaymentCancel)
│           └── PageLayout
│               └── PaymentCancel
```

### Data Flow
```
Campaign API                    Product API
     │                               │
     ▼                               ▼
fetchCampaigns()              fetchProducts()
     │                               │
     ▼                               ▼
PricingPage (combines data)
     │
     ├── CampaignBanner (displays active campaigns)
     │
     └── PricingCard[] (displays plan + discount)
             │
             ▼ (user clicks "Buy Now")
     CheckoutPage (receives state: plan + campaign)
             │
             ├── OrderSummary (shows pricing breakdown)
             │
             └── CustomerForm (collects customer info)
                     │
                     ▼ (form submit)
             Order API (creates order)
                     │
                     ▼
             PayFast Redirect
                     │
                     ├── Success → PaymentSuccess
                     │
                     └── Cancel → PaymentCancel
```

## 4. Validation Checklist

- [ ] README.md complete and accurate
- [ ] All components have JSDoc
- [ ] All services have JSDoc
- [ ] All types have JSDoc
- [ ] Architecture diagram created
- [ ] Data flow documented
- [ ] Setup instructions clear
- [ ] Environment config documented
```

---

## Success Criteria

- [ ] README.md updated
- [ ] All exports have JSDoc
- [ ] Architecture documented
- [ ] Data flow documented
- [ ] Setup instructions complete
- [ ] Output.md created with all sections

---

## Execution Steps

1. Review existing README.md
2. Update with current project state
3. Add JSDoc to all components
4. Add JSDoc to all services
5. Add JSDoc to all types
6. Create architecture diagrams
7. Create output.md with all sections
8. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-18
