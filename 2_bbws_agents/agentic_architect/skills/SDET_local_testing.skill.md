# SDET Local Testing Skill - Local-First Development

**Version**: 1.0
**Created**: 2026-01-16
**Type**: Test Automation - Local Development
**Markers**: `@pytest.mark.local`, `@pytest.mark.integration_local`

---

## Purpose

Enable comprehensive local testing of full-stack applications before any AWS deployment. This skill covers LocalStack, SAM Local, MSW (Mock Service Worker), and agent mocking for testing user journeys without cloud infrastructure.

---

## When to Use

- Developing frontend with mocked backend APIs
- Testing Lambda functions locally with LocalStack
- Mocking AI agent responses for SSE streaming
- Running E2E tests without AWS credentials
- CI/CD pipelines that need to run without cloud access
- Rapid iteration during development

---

## Local Development Stack

| Component | Tool | Purpose |
|-----------|------|---------|
| DynamoDB | LocalStack | Database emulation |
| S3 | LocalStack | Storage emulation |
| Lambda | SAM Local | Function execution |
| API Gateway | SAM Local | API routing |
| Cognito | Mock JWT | Authentication |
| AgentCore | Express Mock | AI agent responses |
| Frontend API | MSW | Browser API mocking |

---

## 1. LocalStack Setup

### docker-compose.localstack.yml

```yaml
version: '3.8'

services:
  localstack:
    image: localstack/localstack:latest
    container_name: bbws-localstack
    ports:
      - "4566:4566"
    environment:
      - SERVICES=dynamodb,s3,sqs,sns
      - DEBUG=1
      - DATA_DIR=/var/lib/localstack/data
    volumes:
      - "./localstack/init:/etc/localstack/init/ready.d"
      - "localstack-data:/var/lib/localstack"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4566/_localstack/health"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  localstack-data:
```

### LocalStack Fixtures (conftest.py)

```python
import pytest
import boto3
import os

@pytest.fixture(scope="session")
def localstack_endpoint():
    """Return LocalStack endpoint URL."""
    return os.getenv('LOCALSTACK_ENDPOINT', 'http://localhost:4566')

@pytest.fixture(scope="session")
def localstack_dynamodb(localstack_endpoint):
    """Create DynamoDB client for LocalStack."""
    return boto3.resource(
        'dynamodb',
        endpoint_url=localstack_endpoint,
        region_name='af-south-1',
        aws_access_key_id='testing',
        aws_secret_access_key='testing'
    )

@pytest.fixture(scope="session")
def localstack_s3(localstack_endpoint):
    """Create S3 client for LocalStack."""
    return boto3.client(
        's3',
        endpoint_url=localstack_endpoint,
        region_name='af-south-1',
        aws_access_key_id='testing',
        aws_secret_access_key='testing'
    )

@pytest.fixture(scope="function")
def test_table(localstack_dynamodb):
    """Create and cleanup test DynamoDB table."""
    table = localstack_dynamodb.create_table(
        TableName='test-table',
        KeySchema=[
            {'AttributeName': 'PK', 'KeyType': 'HASH'},
            {'AttributeName': 'SK', 'KeyType': 'RANGE'}
        ],
        AttributeDefinitions=[
            {'AttributeName': 'PK', 'AttributeType': 'S'},
            {'AttributeName': 'SK', 'AttributeType': 'S'}
        ],
        BillingMode='PAY_PER_REQUEST'
    )
    table.wait_until_exists()
    yield table
    table.delete()
```

---

## 2. SAM Local Configuration

### samconfig.toml (Local)

```toml
[local]
[local.local_start_api.parameters]
port = 3001
host = "127.0.0.1"
env_vars = "envs/local.json"
docker_network = "bbws-network"
warm_containers = "EAGER"

[local.local_invoke.parameters]
env_vars = "envs/local.json"
docker_network = "bbws-network"
```

### envs/local.json

```json
{
  "Parameters": {
    "DYNAMODB_ENDPOINT": "http://localstack:4566",
    "S3_ENDPOINT": "http://localstack:4566",
    "AWS_REGION": "af-south-1",
    "ENVIRONMENT": "local",
    "AGENT_MOCK_ENDPOINT": "http://agent-mock:3002"
  }
}
```

### Running SAM Local

```bash
# Start API Gateway locally
sam local start-api --port 3001 --env-vars envs/local.json

# Invoke single function
sam local invoke CreateSiteFunction --event events/create-site.json

# Start with hot reload
sam local start-api --port 3001 --warm-containers EAGER
```

---

## 3. MSW (Mock Service Worker) for Frontend

### src/mocks/handlers.ts

```typescript
import { http, HttpResponse, delay } from 'msw';

const API_BASE = 'http://localhost:3001/v1';

export const handlers = [
  // Sites API
  http.get(`${API_BASE}/tenants/:tenantId/sites`, async () => {
    await delay(100);
    return HttpResponse.json({
      sites: [
        {
          siteId: 'site-001',
          name: 'Summer Sale Landing Page',
          status: 'draft',
          createdAt: '2026-01-15T10:00:00Z',
          _links: {
            self: { href: '/v1/tenants/tenant-001/sites/site-001' },
            edit: { href: '/v1/tenants/tenant-001/sites/site-001', method: 'PUT' }
          }
        }
      ],
      _links: {
        self: { href: '/v1/tenants/tenant-001/sites' },
        create: { href: '/v1/tenants/tenant-001/sites', method: 'POST' }
      }
    });
  }),

  // Generation API (SSE)
  http.post(`${API_BASE}/tenants/:tenantId/generations`, async () => {
    const encoder = new TextEncoder();
    const stream = new ReadableStream({
      async start(controller) {
        const events = [
          { event: 'thinking', data: { agent: 'site-generator', thought: 'Analyzing prompt...' } },
          { event: 'progress', data: { agent: 'site-generator', progress: 25 } },
          { event: 'thinking', data: { agent: 'outliner', thought: 'Creating structure...' } },
          { event: 'progress', data: { agent: 'site-generator', progress: 50 } },
          { event: 'thinking', data: { agent: 'theme-selector', thought: 'Selecting theme...' } },
          { event: 'progress', data: { agent: 'site-generator', progress: 75 } },
          { event: 'response', data: { html: '<div>Generated Content</div>', brandScore: 8.5 } },
          { event: 'done', data: { success: true } }
        ];

        for (const evt of events) {
          await new Promise(r => setTimeout(r, 200));
          controller.enqueue(encoder.encode(`event: ${evt.event}\ndata: ${JSON.stringify(evt.data)}\n\n`));
        }
        controller.close();
      }
    });

    return new HttpResponse(stream, {
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive'
      }
    });
  }),

  // Deployment API
  http.post(`${API_BASE}/tenants/:tenantId/deployments`, async ({ request }) => {
    await delay(500);
    const body = await request.json();
    return HttpResponse.json({
      deploymentId: 'dep-001',
      siteId: body.siteId,
      environment: body.environment,
      status: 'completed',
      url: `https://test-site.sites.dev.kimmyai.io`,
      _links: {
        self: { href: '/v1/tenants/tenant-001/deployments/dep-001' },
        site: { href: '/v1/tenants/tenant-001/sites/site-001' }
      }
    }, { status: 201 });
  }),

  // Validation API
  http.post(`${API_BASE}/sites/:siteId/validate`, async () => {
    await delay(300);
    return HttpResponse.json({
      brandScore: 8.5,
      passed: true,
      checks: [
        { name: 'Color Contrast', status: 'pass', score: 9.0 },
        { name: 'Typography', status: 'pass', score: 8.0 },
        { name: 'Logo Placement', status: 'pass', score: 8.5 },
        { name: 'CTA Visibility', status: 'pass', score: 9.0 },
        { name: 'Mobile Responsive', status: 'pass', score: 8.0 }
      ],
      recommendations: []
    });
  })
];
```

### src/mocks/browser.ts

```typescript
import { setupWorker } from 'msw/browser';
import { handlers } from './handlers';

export const worker = setupWorker(...handlers);
```

### main.tsx (Development Setup)

```typescript
async function enableMocking() {
  if (import.meta.env.DEV) {
    const { worker } = await import('./mocks/browser');
    return worker.start({
      onUnhandledRequest: 'bypass',
    });
  }
}

enableMocking().then(() => {
  ReactDOM.createRoot(document.getElementById('root')!).render(
    <React.StrictMode>
      <App />
    </React.StrictMode>
  );
});
```

---

## 4. Agent Mock Server

### agent-mock/server.ts

```typescript
import express from 'express';
import cors from 'cors';

const app = express();
const PORT = 3002;

app.use(cors({ origin: '*' }));
app.use(express.json());

interface AgentFixture {
  thinking: string[];
  response: any;
  delayMs: number;
}

const fixtures: Record<string, AgentFixture> = {
  'site-generator': {
    thinking: [
      'Analyzing prompt requirements...',
      'Coordinating with specialist agents...',
      'Assembling page structure...'
    ],
    response: {
      html: '<section class="hero">...</section>',
      structure: { sections: ['hero', 'features', 'cta'] },
      metadata: { generationId: 'gen-mock-001' }
    },
    delayMs: 150
  },
  'outliner': {
    thinking: ['Parsing requirements...', 'Creating outline...'],
    response: {
      outline: {
        sections: [
          { id: 'hero', name: 'Hero Section', order: 1 },
          { id: 'features', name: 'Features', order: 2 },
          { id: 'cta', name: 'Call to Action', order: 3 }
        ]
      }
    },
    delayMs: 100
  },
  'theme-selector': {
    thinking: ['Analyzing brand...', 'Selecting colors...'],
    response: {
      theme: {
        colors: { primary: '#2563EB', secondary: '#1E40AF' },
        typography: { heading: 'Inter', body: 'Open Sans' }
      }
    },
    delayMs: 80
  },
  'validator': {
    thinking: ['Checking compliance...', 'Validating accessibility...'],
    response: {
      validation: {
        brandScore: 8.5,
        passed: true,
        checks: [
          { name: 'Color Contrast', status: 'pass', score: 9.0 }
        ]
      }
    },
    delayMs: 200
  }
};

// SSE Agent Invocation
app.post('/v1/agents/:agentType/invoke', async (req, res) => {
  const { agentType } = req.params;
  const fixture = fixtures[agentType];

  if (!fixture) {
    return res.status(404).json({ error: `Unknown agent: ${agentType}` });
  }

  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');

  // Stream thinking events
  for (const thought of fixture.thinking) {
    res.write(`event: thinking\ndata: ${JSON.stringify({ agent: agentType, thought })}\n\n`);
    await new Promise(r => setTimeout(r, fixture.delayMs));
  }

  // Stream progress
  res.write(`event: progress\ndata: ${JSON.stringify({ agent: agentType, progress: 100 })}\n\n`);
  await new Promise(r => setTimeout(r, fixture.delayMs));

  // Stream response
  res.write(`event: response\ndata: ${JSON.stringify(fixture.response)}\n\n`);
  res.write(`event: done\ndata: ${JSON.stringify({ success: true })}\n\n`);
  res.end();
});

app.get('/health', (_, res) => {
  res.json({ status: 'healthy', agents: Object.keys(fixtures) });
});

app.listen(PORT, () => console.log(`Agent Mock Server on http://localhost:${PORT}`));
```

---

## 5. Full Stack Docker Compose

### docker-compose.yml

```yaml
version: '3.8'

services:
  localstack:
    image: localstack/localstack:latest
    container_name: bbws-localstack
    ports:
      - "4566:4566"
    environment:
      - SERVICES=dynamodb,s3
    volumes:
      - "./localstack/init:/etc/localstack/init/ready.d"
    networks:
      - bbws-network

  agent-mock:
    build: ./agent-mock
    container_name: bbws-agent-mock
    ports:
      - "3002:3002"
    networks:
      - bbws-network

  api:
    build: ./api
    container_name: bbws-api
    ports:
      - "3001:3001"
    environment:
      - DYNAMODB_ENDPOINT=http://localstack:4566
      - S3_ENDPOINT=http://localstack:4566
      - AGENT_ENDPOINT=http://agent-mock:3002
    depends_on:
      - localstack
      - agent-mock
    networks:
      - bbws-network

  frontend:
    build: ./frontend
    container_name: bbws-frontend
    ports:
      - "5173:5173"
    environment:
      - VITE_API_URL=http://localhost:3001
      - VITE_ENABLE_MSW=false
    depends_on:
      - api
    networks:
      - bbws-network

networks:
  bbws-network:
    driver: bridge
```

---

## 6. Local Integration Tests

### tests/local/test_user_journeys.py

```python
import pytest
import requests

@pytest.mark.local
class TestMarketingUserJourney:
    """Test Marketing User journey locally."""

    def test_create_page_journey(self, local_api_url):
        """Test complete page creation flow."""
        # Step 1: Create site
        create_response = requests.post(
            f"{local_api_url}/v1/tenants/test-tenant/sites",
            json={"name": "Test Page", "prompt": "Create a landing page"}
        )
        assert create_response.status_code == 201
        site_id = create_response.json()["siteId"]

        # Step 2: Generate content (SSE)
        gen_response = requests.post(
            f"{local_api_url}/v1/tenants/test-tenant/generations",
            json={"siteId": site_id, "prompt": "Modern tech landing page"},
            stream=True
        )
        assert gen_response.status_code == 200

        events = []
        for line in gen_response.iter_lines():
            if line:
                events.append(line.decode())

        assert any('done' in e for e in events)

        # Step 3: Validate
        validate_response = requests.post(
            f"{local_api_url}/v1/sites/{site_id}/validate"
        )
        assert validate_response.status_code == 200
        assert validate_response.json()["brandScore"] >= 8.0

        # Step 4: Deploy to staging
        deploy_response = requests.post(
            f"{local_api_url}/v1/tenants/test-tenant/deployments",
            json={"siteId": site_id, "environment": "staging"}
        )
        assert deploy_response.status_code == 201
        assert "url" in deploy_response.json()


@pytest.fixture
def local_api_url():
    return "http://localhost:3001"
```

---

## 7. Running Local Tests

```bash
# Start local stack
docker-compose up -d

# Wait for services
sleep 10

# Run local unit tests
pytest tests/unit/ -v

# Run local integration tests
pytest tests/local/ -m local -v

# Run E2E with Playwright
npx playwright test --project=local

# Run all local tests
npm run test:local
```

---

## 8. CI/CD Configuration (No AWS)

### .github/workflows/local-tests.yml

```yaml
name: Local Tests

on: [push, pull_request]

jobs:
  local-tests:
    runs-on: ubuntu-latest

    services:
      localstack:
        image: localstack/localstack:latest
        ports:
          - 4566:4566
        env:
          SERVICES: dynamodb,s3

    steps:
      - uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install dependencies
        run: pip install -r requirements-dev.txt

      - name: Run unit tests
        run: pytest tests/unit/ -v

      - name: Run local integration tests
        run: pytest tests/local/ -m local -v
        env:
          LOCALSTACK_ENDPOINT: http://localhost:4566

      - name: Start agent mock
        run: |
          cd agent-mock && npm install && npm start &
          sleep 5

      - name: Run E2E tests
        run: npx playwright test --project=local
```

---

## Best Practices

| Practice | Description |
|----------|-------------|
| **Parity** | Keep local fixtures in sync with real API responses |
| **Isolation** | Each test should be independent |
| **Speed** | Local tests should be fast (< 100ms per test) |
| **Coverage** | Test all user journeys locally before AWS |
| **CI Integration** | All local tests must pass in CI without AWS |
| **Fixture Updates** | Update mock fixtures when real APIs change |

---

## Version History

- **v1.0** (2026-01-16): Initial local testing skill for Site Builder project
