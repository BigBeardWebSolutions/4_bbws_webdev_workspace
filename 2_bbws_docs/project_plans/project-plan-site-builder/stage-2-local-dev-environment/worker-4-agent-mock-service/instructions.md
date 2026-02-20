# Worker 4: Agent Mock Service

**Worker**: worker-4-agent-mock-service
**Stage**: Stage 2 - Local Development Environment
**Status**: PENDING

---

## Task Description

Create an Express.js mock server that simulates AWS Bedrock AgentCore responses. The server must support Server-Sent Events (SSE) streaming to match the real AgentCore behavior, with JSON fixtures for each of the 7 AI agents.

---

## Inputs

| Input | Location | Purpose |
|-------|----------|---------|
| Agent Definitions | `3.1.2_LLD_Site_Builder_Generation_API.md` Section 5 | Agent types and responses |
| SSE Format | HLD v3 Section 3.4 | Streaming response format |

---

## Deliverables

### 1. Express Mock Server

**File**: `local-dev/mocks/agents/server.ts`

```typescript
import express from 'express';
import cors from 'cors';
import { streamAgentResponse } from './sse-stream';
import * as fixtures from './fixtures';

const app = express();
const PORT = 3002;

app.use(cors({ origin: 'http://localhost:5173' }));
app.use(express.json());

// Agent invocation endpoint
app.post('/v1/agents/:agentType/invoke', async (req, res) => {
  const { agentType } = req.params;
  const { prompt, context, tenantId } = req.body;

  console.log(`[Agent Mock] Invoking ${agentType} for tenant ${tenantId}`);

  // Set SSE headers
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.setHeader('X-Correlation-ID', `mock-${Date.now()}`);

  try {
    const fixture = fixtures[agentType as keyof typeof fixtures];
    if (!fixture) {
      res.write(`event: error\ndata: {"error": "Unknown agent type: ${agentType}"}\n\n`);
      res.end();
      return;
    }

    await streamAgentResponse(res, fixture, agentType);
  } catch (error) {
    res.write(`event: error\ndata: {"error": "${error}"}\n\n`);
    res.end();
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', agents: Object.keys(fixtures) });
});

app.listen(PORT, () => {
  console.log(`[Agent Mock] Server running on http://localhost:${PORT}`);
  console.log(`[Agent Mock] Available agents: ${Object.keys(fixtures).join(', ')}`);
});
```

### 2. SSE Streaming Helper

**File**: `local-dev/mocks/agents/sse-stream.ts`

```typescript
import { Response } from 'express';

interface AgentFixture {
  thinking: string[];
  response: any;
  delayMs?: number;
}

export async function streamAgentResponse(
  res: Response,
  fixture: AgentFixture,
  agentType: string
): Promise<void> {
  const delay = fixture.delayMs || 100;

  // Stream "thinking" events
  for (const thought of fixture.thinking) {
    res.write(`event: thinking\ndata: ${JSON.stringify({ agent: agentType, thought })}\n\n`);
    await sleep(delay);
  }

  // Stream "progress" events
  res.write(`event: progress\ndata: ${JSON.stringify({ agent: agentType, progress: 50 })}\n\n`);
  await sleep(delay);

  res.write(`event: progress\ndata: ${JSON.stringify({ agent: agentType, progress: 100 })}\n\n`);
  await sleep(delay);

  // Stream final response
  res.write(`event: response\ndata: ${JSON.stringify(fixture.response)}\n\n`);

  // End stream
  res.write(`event: done\ndata: ${JSON.stringify({ agent: agentType, success: true })}\n\n`);
  res.end();
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

### 3. Agent Fixtures

**File**: `local-dev/mocks/agents/fixtures/site-generator.json`

```json
{
  "thinking": [
    "Analyzing prompt for landing page requirements...",
    "Identifying target audience and goals...",
    "Coordinating with specialist agents...",
    "Assembling final page structure..."
  ],
  "response": {
    "pageStructure": {
      "sections": [
        { "type": "hero", "headline": "Transform Your Business Today", "subheadline": "AI-powered solutions for modern enterprises" },
        { "type": "features", "items": ["Fast", "Secure", "Scalable"] },
        { "type": "testimonials", "count": 3 },
        { "type": "cta", "text": "Get Started Free" }
      ]
    },
    "suggestedTheme": "modern-tech",
    "metadata": {
      "generationId": "gen-mock-001",
      "agentVersion": "1.0.0"
    }
  },
  "delayMs": 150
}
```

**File**: `local-dev/mocks/agents/fixtures/outliner.json`

```json
{
  "thinking": [
    "Parsing page requirements...",
    "Determining optimal section order...",
    "Calculating content hierarchy..."
  ],
  "response": {
    "outline": {
      "title": "Landing Page Outline",
      "sections": [
        { "id": "hero", "name": "Hero Section", "order": 1 },
        { "id": "problem", "name": "Problem Statement", "order": 2 },
        { "id": "solution", "name": "Our Solution", "order": 3 },
        { "id": "features", "name": "Key Features", "order": 4 },
        { "id": "testimonials", "name": "Customer Testimonials", "order": 5 },
        { "id": "pricing", "name": "Pricing Plans", "order": 6 },
        { "id": "cta", "name": "Call to Action", "order": 7 }
      ]
    }
  },
  "delayMs": 100
}
```

**File**: `local-dev/mocks/agents/fixtures/theme-selector.json`

```json
{
  "thinking": [
    "Analyzing brand guidelines...",
    "Selecting color palette...",
    "Determining typography..."
  ],
  "response": {
    "theme": {
      "name": "Modern Professional",
      "colors": {
        "primary": "#2563EB",
        "secondary": "#1E40AF",
        "accent": "#3B82F6",
        "background": "#FFFFFF",
        "text": "#1F2937"
      },
      "typography": {
        "headingFont": "Inter",
        "bodyFont": "Open Sans",
        "fontSize": { "base": "16px", "h1": "48px", "h2": "36px" }
      }
    }
  },
  "delayMs": 80
}
```

**File**: `local-dev/mocks/agents/fixtures/logo-creator.json`

```json
{
  "thinking": [
    "Generating logo concepts...",
    "Applying brand colors...",
    "Rendering final logo..."
  ],
  "response": {
    "logo": {
      "url": "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCI+PC9zdmc+",
      "format": "svg",
      "variations": [
        { "type": "full", "width": 200, "height": 50 },
        { "type": "icon", "width": 50, "height": 50 }
      ]
    }
  },
  "delayMs": 500
}
```

**File**: `local-dev/mocks/agents/fixtures/validator.json`

```json
{
  "thinking": [
    "Checking brand compliance...",
    "Validating accessibility...",
    "Scanning for security issues..."
  ],
  "response": {
    "validation": {
      "brandScore": 8.5,
      "passed": true,
      "checks": [
        { "name": "Color Contrast", "status": "pass", "score": 9.0 },
        { "name": "Typography Consistency", "status": "pass", "score": 8.0 },
        { "name": "Logo Placement", "status": "pass", "score": 8.5 },
        { "name": "CTA Visibility", "status": "pass", "score": 9.0 },
        { "name": "Mobile Responsiveness", "status": "pass", "score": 8.0 }
      ],
      "recommendations": [
        "Consider increasing heading font size for better hierarchy"
      ]
    }
  },
  "delayMs": 200
}
```

### 4. Fixtures Index

**File**: `local-dev/mocks/agents/fixtures/index.ts`

```typescript
import siteGenerator from './site-generator.json';
import outliner from './outliner.json';
import themeSelector from './theme-selector.json';
import layout from './layout.json';
import logoCreator from './logo-creator.json';
import backgroundImage from './background-image.json';
import blogger from './blogger.json';
import validator from './validator.json';

export {
  siteGenerator,
  outliner,
  themeSelector,
  layout,
  logoCreator,
  backgroundImage,
  blogger,
  validator
};
```

---

## Expected Output Format

**File**: `local-dev/mocks/agents/output.md`

```markdown
# Agent Mock Service Output

## Server Configuration
- Port: 3002
- CORS Origin: http://localhost:5173
- SSE Streaming: Enabled

## Available Agents
- [x] site-generator (orchestrator)
- [x] outliner
- [x] theme-selector
- [x] layout
- [x] logo-creator
- [x] background-image
- [x] blogger
- [x] validator

## Test Commands
\`\`\`bash
# Health check
curl http://localhost:3002/health

# Test agent invocation
curl -X POST http://localhost:3002/v1/agents/site-generator/invoke \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Create a landing page", "tenantId": "test-tenant"}'
\`\`\`
```

---

## Success Criteria

- [ ] Server starts on port 3002
- [ ] All 8 agents have fixtures
- [ ] SSE streaming works correctly
- [ ] Events follow: thinking → progress → response → done
- [ ] CORS configured for frontend
- [ ] Configurable delays simulate real latency
- [ ] Health endpoint returns agent list

---

## Execution Steps

1. Create `local-dev/mocks/agents/` directory
2. Initialize npm package: `npm init -y`
3. Install dependencies: `npm install express cors typescript ts-node @types/express @types/cors`
4. Write `server.ts` with SSE support
5. Write `sse-stream.ts` helper
6. Create fixture JSON files for all 8 agents
7. Write `fixtures/index.ts` to export all
8. Add start script to package.json
9. Test with curl commands
10. Update work.state to COMPLETE
