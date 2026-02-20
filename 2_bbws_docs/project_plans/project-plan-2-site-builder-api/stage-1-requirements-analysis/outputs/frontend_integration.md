# Frontend Integration Analysis

**Source Document**: 3.1.1_LLD_Site_Builder_Frontend.md
**Analysis Date**: 2026-01-15
**Purpose**: Extract all API integration points, expected payloads, and response formats required by the Site Builder Frontend

---

## 1. API Endpoints Required by Frontend

### 1.1 Sites Service Endpoints

| Endpoint | Method | Frontend Component | Purpose |
|----------|--------|-------------------|---------|
| `/v1/sites/{tenant_id}/templates` | GET | TemplatesPage, Dashboard | List available templates |
| `/v1/sites/{tenant_id}/generation` | POST | ChatPanel, useChat hook | Start AI generation with SSE streaming |
| `/v1/sites/{tenant_id}/generation/{id}/advisor` | POST | ChatPanel | Get AI advisor feedback on generated content |
| `/v1/sites/{tenant_id}/files` | GET | PreviewPanel, Assets | List uploaded files |
| `/v1/sites/{tenant_id}/files` | POST | AgentPanel, Assets | Upload new files |
| `/v1/sites/{tenant_id}/deployments` | GET | DeploymentHistory | List deployment history |
| `/v1/sites/{tenant_id}/deployments` | POST | DeploymentModal | Create new deployment |
| `/v1/sites/{id}/validate` | GET | DeploymentModal | Run all validations |
| `/v1/sites/{id}/brand-score` | GET | StatusBar, BrandScoreCard | Get brand score |

### 1.2 Agent Service Endpoints

| Endpoint | Method | Frontend Component | Purpose |
|----------|--------|-------------------|---------|
| `/v1/agents/logo` | POST | LogoCreator | Generate logo images |
| `/v1/agents/background` | POST | BackgroundGenerator | Generate background images |
| `/v1/agents/theme` | POST | ThemeSelector | Generate theme suggestions |
| `/v1/agents/layout` | POST | LayoutEditor | Generate layout structures |
| `/v1/agents/blog` | POST | AgentPanel (Blog) | Generate blog content |
| `/v1/agents/newsletter` | POST | AgentPanel (Newsletter) | Generate newsletter content |

---

## 2. Request/Response Interfaces

### 2.1 Project Interface

```typescript
interface Project {
  id: string;
  tenantId: string;
  name: string;
  status: 'draft' | 'staging' | 'production';
  brandScore: number;
  currentVersion: number;
  createdAt: string;
  updatedAt: string;
  deployedUrl?: string;
}
```

### 2.2 Generation Request Interface

```typescript
interface GenerationRequest {
  prompt: string;
  projectId?: string;
  templateId?: string;
  brandAssets?: BrandAssets;
}

interface BrandAssets {
  // Brand-specific assets to include in generation
  logo?: string;
  colors?: string[];
  fonts?: string[];
  images?: string[];
}
```

### 2.3 Generation Response Interface

```typescript
interface GenerationResponse {
  id: string;
  html: string;
  css: string;
  version: number;
  brandScore: number;
  suggestions?: string[];
}
```

### 2.4 Chat Message Interface

```typescript
interface ChatMessage {
  id: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  timestamp: string;
  isStreaming?: boolean;
  metadata?: {
    generationId?: string;
    agentType?: AgentType;
  };
}
```

### 2.5 Agent Request/Response Interfaces

```typescript
type AgentType = 'logo' | 'background' | 'theme' | 'layout' | 'blog' | 'newsletter' | 'outliner';

interface AgentRequest {
  type: AgentType;
  prompt: string;
  options?: Record<string, unknown>;
}

interface AgentResponse {
  type: AgentType;
  results: AgentResult[];
}

interface AgentResult {
  id: string;
  url?: string;       // For image-based agents (logo, background)
  content?: string;   // For text-based agents (blog, newsletter)
  preview?: string;   // Preview data
}
```

### 2.6 Validation Interfaces

```typescript
interface ValidationResult {
  brandScore: number;
  securityPassed: boolean;
  performanceMs: number;
  accessibilityPassed: boolean;
  issues: ValidationIssue[];
}

interface ValidationIssue {
  category: 'brand' | 'security' | 'performance' | 'accessibility';
  severity: 'error' | 'warning' | 'info';
  message: string;
  suggestion?: string;
}
```

### 2.7 Deployment Interface

```typescript
interface Deployment {
  id: string;
  projectId: string;
  environment: 'staging' | 'production';
  status: 'pending' | 'deploying' | 'deployed' | 'failed';
  url?: string;
  createdAt: string;
}

interface DeploymentRequest {
  projectId: string;
  environment: 'staging' | 'production';
  customDomain?: string;
}
```

---

## 3. SSE Streaming Specification

### 3.1 Event Types

| Event | Data Format | Purpose |
|-------|-------------|---------|
| `message` | Plain text chunk | AI response token stream |
| `generation_start` | `{ id: string }` | Indicates generation has started |
| `generation_progress` | `{ progress: number }` | Progress percentage (0-100) |
| `generation_complete` | `GenerationResponse` | Final generated content |
| `error` | `{ code: string, message: string }` | Error during generation |

### 3.2 Chunk Format

The SSE stream delivers content in the following format:

```
event: message
data: <token_chunk>

event: generation_progress
data: {"progress": 45}

event: generation_complete
data: {"id": "gen_123", "html": "...", "css": "...", "version": 1, "brandScore": 8.5}
```

### 3.3 Connection Handling

#### Establishing Connection

```typescript
const response = await fetch(`${API_BASE}/v1/sites/${tenantId}/generation`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${jwt_token}`,
    'X-Tenant-Id': tenantId,
    'Accept': 'text/event-stream'
  },
  body: JSON.stringify({ prompt: content }),
});

const reader = response.body?.getReader();
const decoder = new TextDecoder();
```

#### Reading Stream

```typescript
while (reader) {
  const { done, value } = await reader.read();
  if (done) break;

  const chunk = decoder.decode(value);
  // Process chunk - append to message content
}
```

#### Abort/Cancel Support

```typescript
const abortController = new AbortController();

// To cancel:
abortController.abort();

// In fetch:
fetch(url, {
  signal: abortController.signal,
  // ... other options
});
```

#### Error Recovery

- **Timeout**: Generation requests timeout after 60 seconds
- **Retry Strategy**: On network failure, retry up to 2 times with exponential backoff
- **Graceful Degradation**: If SSE fails, fall back to polling (not recommended)

---

## 4. Authentication Requirements

### 4.1 JWT Token Structure

The frontend expects JWT tokens from AWS Cognito with the following claims:

```typescript
interface JWTPayload {
  sub: string;              // User ID
  email: string;            // User email
  'cognito:groups': string[]; // User groups/roles
  'custom:tenant_id': string; // Tenant identifier
  'custom:org_id': string;    // Organization ID
  exp: number;              // Expiration timestamp
  iat: number;              // Issued at timestamp
}
```

### 4.2 Headers Required

| Header | Value | Required | Description |
|--------|-------|----------|-------------|
| `Authorization` | `Bearer {jwt_token}` | Yes | JWT access token from Cognito |
| `X-Tenant-Id` | Tenant identifier string | Yes | Multi-tenant isolation |
| `Content-Type` | `application/json` | Yes | Request body format |
| `Accept` | `application/json` or `text/event-stream` | Conditional | For SSE endpoints |

### 4.3 Token Refresh Flow

```typescript
// Token refresh is handled automatically by React Query or a custom interceptor
// Tokens should be refreshed before expiry (typically at 75% of lifetime)

interface TokenRefreshConfig {
  refreshThreshold: number;  // milliseconds before expiry to refresh (e.g., 5 minutes)
  onRefreshFailure: () => void;  // Redirect to login
}
```

### 4.4 Tenant Isolation

- All API calls must include `X-Tenant-Id` header
- Backend validates tenant ID against JWT claims
- Users can only access resources within their tenant

---

## 5. Environment Configuration

### 5.1 API Base URLs

| Environment | API Base URL | Region | Use Case |
|-------------|--------------|--------|----------|
| DEV | `https://api.dev.kimmyai.io` | eu-west-1 | Development and local testing |
| SIT | `https://api.sit.kimmyai.io` | eu-west-1 | System integration testing |
| PROD | `https://api.kimmyai.io` | af-south-1 | Production (primary) |
| DR | `https://api.eu.kimmyai.io` | eu-west-1 | Disaster recovery (passive) |

### 5.2 Environment Variables

```typescript
// Expected environment variables in frontend
interface EnvConfig {
  VITE_API_BASE_URL: string;      // API base URL
  VITE_COGNITO_USER_POOL_ID: string;
  VITE_COGNITO_CLIENT_ID: string;
  VITE_COGNITO_DOMAIN: string;
  VITE_ENV: 'DEV' | 'SIT' | 'PROD';
  VITE_ENABLE_MOCK: boolean;      // Enable mock API for development
}
```

### 5.3 Feature Flags by Environment

| Feature | DEV | SIT | PROD |
|---------|-----|-----|------|
| Debug logging | Enabled | Enabled | Disabled |
| Mock API | Available | Disabled | Disabled |
| AI Generation | Enabled | Enabled | Enabled |
| Production Deployment | Enabled | Enabled | Restricted |

---

## 6. Input Validation Rules

### 6.1 Generation Prompt Validation

| Field | Rule | Error Message |
|-------|------|---------------|
| `prompt` | Required, non-empty | "Please enter a description" |
| `prompt` | Min length: 10 characters | "Description too short (min 10 characters)" |
| `prompt` | Max length: 2000 characters | "Description too long (max 2000 characters)" |
| `prompt` | No script injection | "Invalid characters detected" |

### 6.2 Project Name Validation

| Field | Rule | Error Message |
|-------|------|---------------|
| `name` | Required, non-empty | "Project name is required" |
| `name` | Min length: 3 characters | "Name too short" |
| `name` | Max length: 100 characters | "Name too long" |
| `name` | Alphanumeric + spaces + hyphens | "Invalid characters in name" |

### 6.3 Agent Input Validation

| Agent Type | Field | Rule |
|------------|-------|------|
| Logo | `prompt` | Required, 10-500 chars |
| Logo | `style` | Enum: ['modern', 'classic', 'minimal', 'playful'] |
| Logo | `colors` | Array of valid hex codes, max 5 |
| Background | `prompt` | Required, 10-300 chars |
| Theme | `industry` | Optional, from predefined list |
| Layout | `sections` | Array of valid section types |

### 6.4 Deployment Validation

| Check | Threshold | Action if Failed |
|-------|-----------|------------------|
| Brand Score | >= 8.0 for production | Block deployment, show issues |
| Security Scan | Pass required | Block deployment |
| Performance | Load time < 3s | Warning for staging, block for production |
| Accessibility | WCAG 2.1 AA | Warning |

### 6.5 File Upload Validation

| Field | Rule |
|-------|------|
| File size | Max 10MB per file |
| File type (images) | jpg, jpeg, png, gif, svg, webp |
| File type (assets) | css, js (with CSP restrictions) |
| Total storage | Per tenant quota (configurable) |

---

## 7. API Response Codes

### 7.1 Success Codes

| Code | Meaning | Use Case |
|------|---------|----------|
| 200 | OK | Successful GET, PUT requests |
| 201 | Created | Successful POST (new resource) |
| 204 | No Content | Successful DELETE |

### 7.2 Error Codes

| Code | Meaning | Frontend Handling |
|------|---------|-------------------|
| 400 | Bad Request | Show validation errors |
| 401 | Unauthorized | Redirect to login |
| 403 | Forbidden | Show access denied message |
| 404 | Not Found | Show "not found" UI |
| 409 | Conflict | Show conflict resolution UI |
| 429 | Too Many Requests | Show rate limit message, retry after |
| 500 | Server Error | Show generic error, retry option |
| 503 | Service Unavailable | Show maintenance message |

### 7.3 Error Response Format

```typescript
interface ApiError {
  code: string;           // Machine-readable error code
  message: string;        // Human-readable message
  details?: {
    field?: string;       // Field with error (for validation)
    reason?: string;      // Detailed reason
  }[];
  requestId: string;      // For support/debugging
}
```

---

## 8. AI Agent Timeouts and Limits

### 8.1 Timeout Configuration

| Agent | Timeout | Expected Response Time |
|-------|---------|------------------------|
| Site Generator | 60s | < 15s |
| AI Advisor | 30s | < 10s |
| Logo Creator | 30s | < 20s |
| Background Creator | 30s | < 20s |
| Theme Selector | 15s | < 5s |
| Layout Agent | 20s | < 10s |
| Blogger | 45s | < 30s |
| Newsletter | 45s | < 30s |
| Outliner | 15s | < 5s |

### 8.2 Rate Limits

| Operation | Rate Limit | Window |
|-----------|------------|--------|
| Generation requests | 10 per minute | Per user |
| Agent requests | 20 per minute | Per user |
| File uploads | 30 per hour | Per tenant |
| Deployments | 5 per hour | Per tenant |

---

## 9. Frontend Service Layer

### 9.1 API Service Files

| Service File | Endpoints Covered |
|--------------|-------------------|
| `services/siteApi.ts` | Sites CRUD, files |
| `services/generationApi.ts` | Generation, SSE streaming |
| `services/agentApi.ts` | All agent endpoints |
| `services/deploymentApi.ts` | Deployment management |
| `services/validationApi.ts` | Validation, brand score |

### 9.2 React Query Configuration

```typescript
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,   // 5 minutes
      cacheTime: 30 * 60 * 1000,  // 30 minutes
      retry: 2,
      refetchOnWindowFocus: false,
    },
  },
});
```

---

## 10. Summary

### 10.1 Key Integration Points

1. **Generation API** - Core endpoint for AI-powered page generation with SSE streaming
2. **Agent APIs** - Specialized endpoints for logo, background, theme, layout, blog, and newsletter generation
3. **Validation API** - Brand score, security, performance, and accessibility validation
4. **Deployment API** - Multi-environment deployment workflow (staging, production)

### 10.2 Critical Requirements for Backend

1. **SSE Streaming** - Must support Server-Sent Events for real-time generation feedback
2. **Multi-tenant Isolation** - All endpoints must validate and enforce tenant boundaries
3. **JWT Authentication** - Cognito-based JWT with custom claims for tenant/org
4. **Rate Limiting** - Per-user and per-tenant rate limits
5. **Validation Thresholds** - Brand score >= 8.0 for production deployment

### 10.3 API Contract Dependencies

The Site Builder Backend API must implement all endpoints listed in Section 1 with the exact request/response formats defined in Section 2 to ensure seamless frontend integration.

---

**End of Frontend Integration Analysis**
