# Worker Instructions: Error Handling

**Worker ID**: worker-3-error-handling
**Stage**: Stage 4 - API Integration
**Project**: project-plan-campaigns-frontend

---

## Task

Implement comprehensive error handling for the Campaign API integration including network errors, timeout handling, graceful degradation, and mock data fallback for development.

---

## Inputs

**Primary Inputs**:
- Worker 1 output (Campaign API Service)
- Existing error handling patterns in `productApi.ts`

**Supporting Inputs**:
- LLD Section 8: NFRs (error handling requirements)
- Stage 1 Gap Analysis output

---

## Deliverables

Create `output.md` documenting:

### 1. Error Categories

Document error types to handle:
- Network errors (no connectivity)
- Timeout errors
- HTTP errors (4xx, 5xx)
- Parse errors (invalid JSON)

### 2. Error Handling Strategy

For each error type:
- Detection method
- User message
- Recovery action
- Logging

### 3. Graceful Degradation

Document fallback behavior:
- API unavailable -> Show pricing without discounts
- Partial failure -> Show available data
- Timeout -> Retry with user feedback

### 4. Mock Data Fallback

Create mock campaign data for:
- Development testing
- API unavailability
- Demo purposes

---

## Expected Output Format

```markdown
# Error Handling Output

## 1. Error Categories

### Network Errors
- **Cause**: No internet connection
- **Detection**: fetch throws TypeError
- **User Message**: "Unable to load promotions. Showing regular pricing."
- **Recovery**: Show pricing without discounts

### Timeout Errors
- **Cause**: API too slow (>10s)
- **Detection**: AbortController signal
- **User Message**: "Loading promotions..."
- **Recovery**: Retry up to 3 times

### HTTP 4xx Errors
- **Cause**: Client errors
- **Detection**: response.status >= 400 && < 500
- **Specific Handling**:
  - 404: Campaign not found
  - 400: Invalid request

### HTTP 5xx Errors
- **Cause**: Server errors
- **Detection**: response.status >= 500
- **User Message**: "Promotion service temporarily unavailable"
- **Recovery**: Retry with exponential backoff

### Parse Errors
- **Cause**: Invalid JSON response
- **Detection**: JSON.parse throws SyntaxError
- **User Message**: None (silent failure)
- **Recovery**: Return empty/default data

## 2. Error Handling Strategy

### Error Handler Utility
```typescript
// utils/errorHandler.ts

export interface ApiErrorResult {
  type: 'network' | 'timeout' | 'http' | 'parse' | 'unknown';
  message: string;
  statusCode?: number;
  shouldRetry: boolean;
}

export const classifyError = (error: unknown): ApiErrorResult => {
  if (error instanceof TypeError) {
    return {
      type: 'network',
      message: 'Network error - unable to connect',
      shouldRetry: true
    };
  }

  if (error instanceof DOMException && error.name === 'AbortError') {
    return {
      type: 'timeout',
      message: 'Request timed out',
      shouldRetry: true
    };
  }

  if (error instanceof SyntaxError) {
    return {
      type: 'parse',
      message: 'Invalid response format',
      shouldRetry: false
    };
  }

  return {
    type: 'unknown',
    message: error instanceof Error ? error.message : 'Unknown error',
    shouldRetry: false
  };
};
```

### HTTP Error Handler
```typescript
export const handleHttpError = (status: number, body?: string): never => {
  const errorMap: Record<number, string> = {
    400: 'Invalid request',
    401: 'Unauthorized',
    403: 'Forbidden',
    404: 'Campaign not found',
    500: 'Server error',
    502: 'Service unavailable',
    503: 'Service temporarily unavailable'
  };

  throw new Error(errorMap[status] || `HTTP error ${status}`);
};
```

## 3. Graceful Degradation

### PricingPage Fallback
```tsx
const PricingPage: React.FC = () => {
  const [campaigns, setCampaigns] = useState<Campaign[]>([]);
  const [loadError, setLoadError] = useState<string | null>(null);

  useEffect(() => {
    fetchCampaigns()
      .then(setCampaigns)
      .catch(error => {
        console.error('Campaign fetch failed:', error);
        setLoadError('Promotions unavailable');
        setCampaigns([]); // Show pricing without discounts
      });
  }, []);

  return (
    <>
      {loadError && (
        <InfoBanner message="Current promotions unavailable. Showing regular pricing." />
      )}
      <PricingCards plans={plans} campaigns={campaigns} />
    </>
  );
};
```

### Retry with User Feedback
```tsx
const [retryCount, setRetryCount] = useState(0);
const [isRetrying, setIsRetrying] = useState(false);

const handleRetry = async () => {
  if (retryCount >= 3) {
    setLoadError('Unable to load promotions after multiple attempts');
    return;
  }

  setIsRetrying(true);
  try {
    const data = await fetchCampaigns();
    setCampaigns(data);
    setLoadError(null);
  } catch {
    setRetryCount(prev => prev + 1);
  } finally {
    setIsRetrying(false);
  }
};
```

## 4. Mock Data Fallback

### Mock Campaign Data
```typescript
// data/mockCampaigns.ts

export const mockCampaigns: Campaign[] = [
  {
    code: 'MOCK-DISCOUNT',
    name: 'Development Test Campaign',
    productId: 'PROD-002',
    discountPercent: 15,
    listPrice: 1500,
    price: 1275,
    status: 'ACTIVE',
    fromDate: '2025-01-01T00:00:00Z',
    toDate: '2025-12-31T23:59:59Z',
    isValid: true
  }
];

export const useMockCampaigns = import.meta.env.DEV;
```

### Fallback in Service
```typescript
// In campaignApi.ts

import { mockCampaigns, useMockCampaigns } from '../data/mockCampaigns';

export const fetchCampaigns = async (): Promise<Campaign[]> => {
  // Use mock data in development if API fails
  if (useMockCampaigns) {
    try {
      return await fetchFromApi();
    } catch {
      console.warn('Using mock campaign data');
      return mockCampaigns;
    }
  }

  // Production: graceful degradation
  try {
    return await fetchFromApi();
  } catch {
    return []; // No discounts shown
  }
};
```

## 5. Logging Strategy

### Error Logging
```typescript
const logError = (context: string, error: unknown): void => {
  const errorInfo = classifyError(error);

  console.error(`[Campaign API] ${context}`, {
    type: errorInfo.type,
    message: errorInfo.message,
    timestamp: new Date().toISOString()
  });

  // Future: Send to monitoring service
  // sendToMonitoring({ context, ...errorInfo });
};
```

## 6. Validation Checklist

- [ ] Network errors handled
- [ ] Timeout errors handled
- [ ] HTTP errors handled
- [ ] Parse errors handled
- [ ] User feedback provided
- [ ] Graceful degradation works
- [ ] Mock data available
- [ ] Logging implemented
```

---

## Success Criteria

- [ ] All error types handled
- [ ] User-friendly error messages
- [ ] Graceful degradation works
- [ ] Mock data fallback available
- [ ] Logging strategy documented
- [ ] Output.md created with all sections

---

## Execution Steps

1. Review existing error handling in productApi.ts
2. Document error categories
3. Design error handling strategy
4. Create graceful degradation plan
5. Design mock data fallback
6. Document logging approach
7. Create output.md with all sections
8. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-18
