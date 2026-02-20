# React Application SDLC Process

**Process Type**: Frontend React Application
**Version**: 1.0
**Status**: Standalone Process

---

## Overview

This is a **standalone SDLC process** for developing React single-page applications. It covers the complete lifecycle from UI/UX design through deployment.

## Process Files

| File | Description |
|------|-------------|
| [main-plan.md](./main-plan.md) | Master orchestration plan |
| [process-definition.md](./process-definition.md) | Machine-readable process definition |

## Stages

| # | Stage | Description | Workers |
|---|-------|-------------|---------|
| F1 | [UI/UX Design](./stage-f1-ui-ux-design.md) | User research, wireframes, design system | 4 |
| F2 | [Prototype](./stage-f2-prototype.md) | Interactive Figma prototypes | 3 |
| F3 | [React + Mock API](./stage-f3-react-mock-api.md) | Component implementation with MSW | 5 |
| F4 | [Frontend Tests](./stage-f4-frontend-tests.md) | Unit, component, integration tests | 4 |
| F5 | [API Integration](./stage-f5-api-integration.md) | Connect to real backend API | 3 |
| F6 | [Deploy](./stage-f6-frontend-deploy.md) | S3/CloudFront deployment | 3 |

**Total**: 6 stages, 22 workers, 2 approval gates

## Technology Stack

| Category | Technology |
|----------|------------|
| Framework | React 18 with TypeScript |
| Build Tool | Vite |
| Styling | TailwindCSS |
| State | React Query + Zustand |
| Mock API | MSW (Mock Service Worker) |
| Testing | Vitest + React Testing Library |
| Hosting | S3 + CloudFront |
| CI/CD | GitHub Actions with OIDC |

## Estimated Duration

| Mode | Duration |
|------|----------|
| Agentic | 9.5 hours |
| Manual | 66 hours |

## Quick Start

```bash
# 1. Create new React project
APP_NAME="MyApp"
mkdir ${APP_NAME}_react && cd ${APP_NAME}_react

# 2. Copy process files
mkdir -p .claude/plans
cp -r path/to/process/react-app/*.md .claude/plans/

# 3. Initialize state files
cd .claude/plans
for stage in stage-f*.md; do
  touch "${stage%.md}.state.PENDING"
done

# 4. Start PM orchestration
# PM reads main-plan.md and executes stages
```

## Approval Gates

| Gate | After Stage | Approvers |
|------|-------------|-----------|
| F1 | F4 (Tests) | Tech Lead, UX Lead |
| F2 | F5 (Integration) | Tech Lead, QA Lead |

## Environment Configuration

| Environment | Domain Pattern |
|-------------|----------------|
| DEV | `{app}.dev.kimmyai.io` |
| SIT | `{app}.sit.kimmyai.io` |
| PROD | `{app}.kimmyai.io` |

---

**Start Here**: [main-plan.md](./main-plan.md)
