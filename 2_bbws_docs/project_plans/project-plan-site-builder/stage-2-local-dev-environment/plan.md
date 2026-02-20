# Stage 2: Local Development Environment

**Stage**: 2
**Name**: Local Development Environment Setup
**Status**: PENDING
**Workers**: 5
**Dependencies**: Stage 1 (Requirements Validation)

---

## Objective

Set up a complete local development stack that enables testing of all user journeys without requiring AWS credentials or infrastructure. This enables rapid development iteration and CI testing without cloud costs.

---

## Workers

| Worker | Task | Outputs |
|--------|------|---------|
| worker-1-localstack-setup | Configure LocalStack for DynamoDB and S3 | docker-compose.localstack.yml, init scripts |
| worker-2-sam-local-config | SAM Local configuration for Lambda | template.yaml, samconfig.toml |
| worker-3-msw-handlers | Mock Service Worker for frontend | handlers.ts, fixtures/ |
| worker-4-agent-mock-service | Agent response mock server with SSE | Express server, agent fixtures |
| worker-5-docker-compose | Full stack orchestration | docker-compose.yml, start/stop scripts |

---

## Deliverables

### Directory Structure

```
local-dev/
├── docker-compose.yml           # Full stack orchestration
├── docker-compose.localstack.yml # LocalStack services
├── localstack/
│   ├── init-dynamodb.sh         # Create tables on startup
│   └── init-s3.sh               # Create buckets on startup
├── sam/
│   ├── template.yaml            # SAM template for local
│   └── samconfig.toml           # SAM configuration
├── mocks/
│   ├── msw/
│   │   ├── handlers.ts          # MSW request handlers
│   │   ├── browser.ts           # Browser setup
│   │   └── fixtures/            # JSON response fixtures
│   └── agents/
│       ├── server.ts            # Express mock server
│       ├── sse-stream.ts        # SSE streaming helper
│       └── fixtures/
│           ├── site-generator.json
│           ├── outliner.json
│           ├── theme-selector.json
│           ├── layout.json
│           ├── logo-creator.json
│           ├── background-image.json
│           ├── blogger.json
│           └── validator.json
└── scripts/
    ├── start-local.sh           # Start all local services
    ├── stop-local.sh            # Stop all local services
    └── seed-data.sh             # Seed test data
```

---

## Success Criteria

- [ ] `docker-compose up` starts full local stack in < 30 seconds
- [ ] LocalStack DynamoDB creates all 6 tables automatically
- [ ] LocalStack S3 creates all required buckets automatically
- [ ] SAM Local starts API Gateway on localhost:3001
- [ ] MSW intercepts all frontend API calls
- [ ] Agent mock server streams SSE responses
- [ ] Seed script populates test data
- [ ] All services accessible without AWS credentials

---

## Approval Gate

**Gate 2**: Local Environment Working
- **Approvers**: Tech Lead
- **Criteria**: Full local stack starts and serves requests
- **Artifact**: Demo of local stack running all services

---

## Notes

- LocalStack Community Edition is sufficient for DynamoDB and S3
- Agent mock server should simulate realistic response delays
- SSE streaming must match AgentCore's streaming format
- All fixtures should be based on expected agent response schemas
