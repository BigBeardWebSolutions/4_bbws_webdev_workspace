# Worker Instructions: Existing Code Audit

**Worker ID**: worker-2-existing-code-audit
**Stage**: Stage 1 - Requirements Validation
**Project**: project-plan-campaigns-frontend

---

## Task

Audit the existing campaigns frontend codebase to catalog all components, services, types, and configurations. Assess code quality, patterns, and completeness.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/`

**Key Files to Analyze**:
- `src/components/` - All React components
- `src/services/` - API services
- `src/types/` - TypeScript type definitions
- `src/utils/` - Utility functions
- `package.json` - Dependencies
- `vite.config.ts` - Build configuration
- `tsconfig.json` - TypeScript configuration

---

## Deliverables

Create `output.md` with the following sections:

### 1. Project Structure

Document complete file structure with purpose of each file/folder.

### 2. Components Catalog

For each component:
- File location
- Purpose
- Props interface
- Dependencies
- Test coverage

### 3. Services Catalog

For each service:
- File location
- Functions exported
- API endpoints used
- Error handling approach
- Caching strategy

### 4. Type Definitions

For each type file:
- Types and interfaces defined
- Usage across codebase

### 5. Configuration Analysis

Document:
- Vite configuration
- TypeScript settings
- Environment variables
- Build scripts

### 6. Code Quality Assessment

Assess:
- TypeScript usage
- Component patterns
- Code organization
- Test coverage
- Accessibility considerations

---

## Expected Output Format

```markdown
# Existing Code Audit Output

## 1. Project Structure

```
campaigns/
├── src/
│   ├── components/
│   │   ├── layout/
│   │   │   ├── PageLayout.tsx
│   │   │   └── Navigation.tsx
│   │   ├── pricing/
│   │   │   ├── PricingPage.tsx
│   │   │   ├── PricingCard.tsx
│   │   │   └── PricingFeature.tsx
│   │   ├── checkout/
│   │   │   ├── CheckoutPage.tsx
│   │   │   ├── CustomerForm.tsx
│   │   │   ├── OrderSummary.tsx
│   │   │   └── FormField.tsx
│   │   ├── payment/
│   │   │   ├── PaymentSuccess.tsx
│   │   │   └── PaymentCancel.tsx
│   │   └── campaign/
│   │       ├── CampaignBanner.tsx (if exists)
│   │       └── DiscountSummary.tsx
│   ├── services/
│   │   ├── productApi.ts
│   │   ├── campaignApi.ts (if exists)
│   │   ├── orderApi.ts
│   │   └── payfastService.ts
│   ├── types/
│   │   ├── campaign.ts
│   │   ├── product.ts
│   │   ├── form.ts
│   │   └── api.ts
│   └── utils/
│       └── validation.ts
├── package.json
├── vite.config.ts
├── tsconfig.json
└── vitest.config.ts
```

## 2. Components Catalog

### PageLayout.tsx
- **Location**: src/components/layout/PageLayout.tsx
- **Purpose**: Main page wrapper with navigation
- **Props**: `children`, `showBackButton`
- **Dependencies**: Navigation component
- **Test Coverage**: Yes (PageLayout.test.tsx)

(Continue for each component...)

## 3. Services Catalog

### productApi.ts
- **Location**: src/services/productApi.ts
- **Functions**: fetchProducts, getProductById, clearCache, checkApiHealth
- **API Endpoint**: GET /v1.0/products
- **Error Handling**: Retry with exponential backoff, fallback to local data
- **Caching**: 5-minute in-memory cache

(Continue for each service...)

## 4. Type Definitions

### campaign.ts
- Campaign interface
- CampaignStatus type
- CampaignListResponse interface
- CampaignResponse interface
- AppliedCampaign interface
- PlanWithCampaign interface

## 5. Configuration Analysis

### Vite Configuration
- Mode: development/sit/production
- Base path: /buy/
- Plugins: React

### TypeScript Configuration
- Strict mode: Enabled
- Target: ES2020
- Module: ESNext

### Build Scripts
- dev: vite
- build:dev: vite build --mode development
- build:sit: vite build --mode sit
- build:prod: vite build --mode production

## 6. Code Quality Assessment

- TypeScript: Fully typed, strict mode enabled
- Component Pattern: Functional components with hooks
- Styling: Inline styles (no CSS framework)
- Test Coverage: Partial (needs improvement)
- Accessibility: Some ARIA attributes present
```

---

## Success Criteria

- [ ] Complete project structure documented
- [ ] All components cataloged with details
- [ ] All services cataloged with details
- [ ] All types documented
- [ ] Configuration analyzed
- [ ] Code quality assessed
- [ ] Output.md created with all sections

---

## Execution Steps

1. Read package.json for dependencies
2. Catalog all files in src/components/
3. Read each component and document props/purpose
4. Catalog all files in src/services/
5. Read each service and document functions/patterns
6. Catalog all files in src/types/
7. Analyze vite.config.ts and tsconfig.json
8. Review existing test files
9. Assess overall code quality
10. Create output.md with all sections
11. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-18
