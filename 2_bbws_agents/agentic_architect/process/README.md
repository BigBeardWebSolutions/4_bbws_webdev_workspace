# BBWS SDLC Process Library

**Version**: 3.0
**Last Updated**: 2026-01-01

---

## Overview

This folder contains the BBWS Software Development Life Cycle (SDLC) process definitions and project-type templates for building various types of applications.

## Master Process

The master SDLC process is defined in:

**[bbws-sdlc-v1/main-plan.md](./bbws-sdlc-v1/main-plan.md)**

This includes 23 stages across 4 parallel tracks:
- **Backend Track** (10 stages): API/Lambda development
- **Frontend Track** (6 stages): React applications
- **WordPress Track** (4 stages): AI-generated sites
- **Tenant Track** (3 stages): Multi-tenant management

---

## Project-Type Processes

Choose the appropriate process based on your project type:

| Project Type | Folder | Stages Used | Duration (Agentic) |
|--------------|--------|-------------|-------------------|
| API Service | [api-service/](./api-service/) | 1-10 | 8 hours |
| React App | [react-app/](./react-app/) | 1-3, F1-F6 | 5 hours |
| WordPress Site | [wordpress-site/](./wordpress-site/) | 1, W1-W4 | 3 hours |
| Landing Page | [landing-page/](./landing-page/) | F1-F3, F6 | 2 hours |
| Newsletter | [newsletter/](./newsletter/) | 4-8, F1, F3, F6 | 6 hours |
| Blog | [blog/](./blog/) | 1-9, F1-F6 | 10 hours |

---

## Quick Start

### 1. Select Project Type
Choose from the process types above based on your project requirements.

### 2. Copy Process Plan
```bash
# For API service
cp -r bbws-sdlc-v1/ my-project-plan/
# Remove irrelevant stages based on project type
```

### 3. Initialize State Files
```bash
cd my-project-plan/
for stage in stage-*.md; do
  touch "${stage%.md}.state.PENDING"
done
```

### 4. Start PM Orchestration
The Project Manager (PM) will read the main-plan.md and orchestrate execution.

---

## Process Structure

```
process/
├── README.md                    # This file
├── bbws-sdlc-v1/               # Master SDLC definition
│   ├── main-plan.md            # Master orchestration plan
│   ├── process-definition.md   # Machine-readable definition
│   ├── stage-1-requirements.md # Backend stages
│   ├── stage-2-hld.md
│   ├── ...
│   ├── stage-f1-ui-ux-design.md # Frontend stages
│   ├── ...
│   ├── stage-w1-theme-dev.md   # WordPress stages
│   ├── ...
│   └── stage-t1-tenant-api.md  # Tenant stages
├── api-service/                # API service template
│   └── README.md
├── react-app/                  # React app template
│   └── README.md
├── wordpress-site/             # WordPress site template
│   └── README.md
├── landing-page/               # Landing page template
│   └── README.md
├── newsletter/                 # Newsletter template
│   └── README.md
└── blog/                       # Blog template
    └── README.md
```

---

## Process Statistics

| Metric | Value |
|--------|-------|
| Total Stages | 23 |
| Total Workers | 74 |
| Approval Gates | 8 |
| Agentic Automation | 85% |
| Parallel Tracks | 4 |

---

## Related Documents

- **Agents**: `../agentic_architect/`
- **Skills**: `../content/skills/`
- **Templates**: `../content/templates/`

---

**Maintained by**: Process Designer Agent
