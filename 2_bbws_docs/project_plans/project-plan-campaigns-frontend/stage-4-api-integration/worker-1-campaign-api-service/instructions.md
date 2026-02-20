# Worker Instructions: Campaign API Service

**Worker ID**: worker-1-campaign-api-service
**Stage**: Stage 4 - API Integration
**Project**: project-plan-campaigns-frontend

---

## Task

Implement or validate the Campaign API service following the LLD specifications. The service should fetch campaigns with retry logic, caching, and fallback to mock data.

---

## Inputs

**Primary Inputs**:
- LLD API specifications from Stage 1 worker-1 output
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/src/services/` (existing services)

**Reference Implementation**:
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/src/services/productApi.ts`

**LLD Reference**:
- Section 6: REST API Operations
- Section 8.1: Performance Targets (<300ms p95)

---

## Deliverables

Create `output.md` documenting:

### 1. API Service Implementation

Document the campaignApi.ts service with:
- Environment configuration
- Fetch functions
- Caching strategy
- Retry logic
- Error handling

### 2. Endpoint Implementations

#### GET /v1.0/campaigns
- Function: `fetchCampaigns()`
- Returns: `Promise<Campaign[]>`
- Caching: 5-minute TTL

#### GET /v1.0/campaigns/{code}
- Function: `getCampaignByCode(code: string)`
- Returns: `Promise<Campaign | null>`
- Error handling: Return null on 404

### 3. Configuration

Document:
- API base URL per environment
- Timeout settings
- Retry count
- Cache duration

### 4. Helper Functions

- `getCampaignsByProduct()` - Map campaigns to product IDs
- `clearCampaignCache()` - Cache invalidation
- `checkCampaignApiHealth()` - Health check

---

## Expected Output Format

```markdown
# Campaign API Service Output

## 1. API Service Implementation

### campaignApi.ts
```typescript
/**
 * Campaign API Service
 *
 * Handles campaign fetching from Campaign API with:
 * - Environment-based endpoint configuration
 * - In-memory caching (5-minute TTL)
 * - Retry logic with exponential backoff
 * - Fallback to empty array on error
 */

import type { Campaign, CampaignListResponse, CampaignResponse } from '../types';
import { config, debugLog } from '../config';

// API Configuration
interface CampaignApiConfig {
  baseUrl: string;
  timeout: number;
  retries: number;
  cacheTimeout: number;
}

const getApiConfig = (): CampaignApiConfig => ({
  baseUrl: config.api.baseUrl,
  timeout: config.api.timeout,
  retries: config.api.retries,
  cacheTimeout: 5 * 60 * 1000 // 5 minutes
});

// Cache
let cachedCampaigns: Campaign[] | null = null;
let cacheTimestamp: number = 0;

const isCacheValid = (): boolean => {
  if (!cachedCampaigns) return false;
  const config = getApiConfig();
  return Date.now() - cacheTimestamp < config.cacheTimeout;
};

export const clearCampaignCache = (): void => {
  cachedCampaigns = null;
  cacheTimestamp = 0;
};

// Retry helper
const sleep = (ms: number): Promise<void> =>
  new Promise(resolve => setTimeout(resolve, ms));

const getRetryDelay = (attempt: number): number =>
  1000 * Math.pow(2, attempt); // 1s, 2s, 4s...

// Fetch campaigns from API
const fetchFromApi = async (): Promise<Campaign[]> => {
  const config = getApiConfig();
  let lastError: Error | unknown;

  for (let attempt = 0; attempt <= config.retries; attempt++) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), config.timeout);

      const url = `${config.baseUrl}/v1.0/campaigns`;
      debugLog('Fetching campaigns from:', url);

      const response = await fetch(url, {
        method: 'GET',
        headers: { Accept: 'application/json' },
        signal: controller.signal
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        throw new Error(`Campaign API returned ${response.status}`);
      }

      const data: CampaignListResponse = await response.json();

      if (!data.campaigns || !Array.isArray(data.campaigns)) {
        throw new Error('Invalid response format');
      }

      return data.campaigns;
    } catch (error) {
      lastError = error;
      if (attempt < config.retries) {
        await sleep(getRetryDelay(attempt));
      }
    }
  }

  throw lastError;
};

// Public API

export const fetchCampaigns = async (): Promise<Campaign[]> => {
  if (isCacheValid() && cachedCampaigns) {
    return cachedCampaigns;
  }

  try {
    const campaigns = await fetchFromApi();
    cachedCampaigns = campaigns;
    cacheTimestamp = Date.now();
    return campaigns;
  } catch (error) {
    console.warn('Campaign fetch failed:', error);
    return []; // Graceful degradation
  }
};

export const getCampaignByCode = async (code: string): Promise<Campaign | null> => {
  const campaigns = await fetchCampaigns();
  return campaigns.find(c => c.code === code) || null;
};

export const getCampaignsByProduct = async (): Promise<Map<string, Campaign>> => {
  const campaigns = await fetchCampaigns();
  const map = new Map<string, Campaign>();

  campaigns.forEach(campaign => {
    if (campaign.isValid) {
      map.set(campaign.productId, campaign);
    }
  });

  return map;
};

export const checkCampaignApiHealth = async (): Promise<boolean> => {
  try {
    await fetchFromApi();
    return true;
  } catch {
    return false;
  }
};
```

## 2. Endpoint Implementations

### fetchCampaigns()
- **Endpoint**: GET /v1.0/campaigns
- **Returns**: Promise<Campaign[]>
- **Cache**: 5-minute TTL
- **Error**: Returns empty array

### getCampaignByCode(code)
- **Endpoint**: Uses cached data from fetchCampaigns
- **Returns**: Promise<Campaign | null>
- **Error**: Returns null

### getCampaignsByProduct()
- **Returns**: Map<productId, Campaign>
- **Filter**: Only valid campaigns

## 3. Configuration

### Environment URLs
| Mode | Base URL |
|------|----------|
| development | https://api.dev.kimmyai.io |
| sit | https://api.sit.kimmyai.io |
| production | https://api.kimmyai.io |

### Settings
| Setting | Value |
|---------|-------|
| Timeout | 10000ms |
| Retries | 3 |
| Cache TTL | 300000ms (5 min) |

## 4. Integration Points

### With PricingPage
```tsx
const [campaigns, setCampaigns] = useState<Campaign[]>([]);

useEffect(() => {
  fetchCampaigns().then(setCampaigns);
}, []);
```

### With PricingCard
```tsx
const campaign = campaignsByProduct.get(plan.productId);
```

## 5. Validation Checklist

- [ ] Fetches from correct endpoint
- [ ] Caches responses
- [ ] Retries on failure
- [ ] Returns empty array on error
- [ ] Maps campaigns to products
- [ ] Cache can be cleared
```

---

## Success Criteria

- [ ] API service implemented/validated
- [ ] All functions documented
- [ ] Retry logic implemented
- [ ] Caching working
- [ ] Error handling graceful
- [ ] Integration points documented
- [ ] Output.md created with all sections

---

## Execution Steps

1. Check if campaignApi.ts exists
2. Review existing implementation
3. Compare with productApi.ts patterns
4. Validate endpoint implementations
5. Document caching strategy
6. Document error handling
7. Create output.md with all sections
8. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-18
