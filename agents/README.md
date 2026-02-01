# Web Development Team - Agent Library

This folder contains AI agents and skills for the web development team. These agents help with UI/UX design, development, and testing workflows.

---

## Quick Reference

| Category | Agent/Skill | Purpose |
|----------|-------------|---------|
| **UI/UX** | UI_Tester_Agent.md | Frontend validation, API testing, diagnostics |
| **UI/UX** | ui_ux_designer.skill.md | Design research, user-centered design |
| **Dev** | DevOps_Agent.md | CI/CD, Terraform, AWS deployment |
| **Dev** | Web_Developer_Agent.md | Full-stack web development |
| **Dev** | wordpress_developer.skill.md | WordPress custom development |
| **Dev** | static_site_developer.skill.md | Jamstack, static sites |
| **Dev** | spa_developer.skill.md | React/Vue SPA development |
| **Test** | SDET_Engineer_Agent.md | Test automation, BDD/TDD |
| **Test** | website_testing.skill.md | QA, link validation, performance |
| **Test** | ui_tester_agent_spec.md | UI testing specification |

---

## Folder Structure

```
agents/
├── README.md                          # This file
├── ui_ux/                            # UI/UX Design Agents
│   ├── UI_Tester_Agent.md            # Frontend validation agent
│   └── ui_ux_designer.skill.md       # UI/UX design skill
├── developer/                        # Developer Agents
│   ├── DevOps_Agent.md               # CI/CD and deployment
│   ├── Web_Developer_Agent.md        # Full-stack web development
│   ├── wordpress_developer.skill.md  # WordPress development
│   ├── static_site_developer.skill.md # Static site development
│   └── spa_developer.skill.md        # SPA development
├── testing/                          # Testing Agents
│   ├── SDET_Engineer_Agent.md        # Test automation
│   ├── website_testing.skill.md      # Website QA testing
│   └── ui_tester_agent_spec.md       # UI testing spec
└── skills/                           # Shared Skills
    ├── web_design_fundamentals.skill.md
    ├── html_landing_page.skill.md
    └── react_landing_page.skill.md
```

---

## UI/UX Agents

### UI Tester Agent (`ui_ux/UI_Tester_Agent.md`)

Automated UI testing for frontend applications.

**Capabilities:**
- Frontend configuration validation
- API endpoint and environment variable verification
- API connectivity testing (CORS, authentication)
- Frontend asset verification (JavaScript bundle analysis)
- Environment comparison (local vs deployed)
- Diagnostic reporting with root cause analysis

**Usage:**
```
Load this agent when you need to:
- Validate frontend deployments
- Debug API connectivity issues
- Compare local and deployed environments
- Generate diagnostic reports
```

### UI/UX Designer Skill (`ui_ux/ui_ux_designer.skill.md`)

Design research and user-centered design guidance.

**Capabilities:**
- Design research methodologies
- User journey mapping
- Wireframing guidance
- Accessibility best practices
- Design system principles

---

## Developer Agents

### DevOps Agent (`developer/DevOps_Agent.md`)

Full CI/CD and deployment automation (16 skills).

**Capabilities:**
- GitHub repository management
- GitHub Actions pipeline creation
- Terraform infrastructure management
- AWS deployment orchestration (DEV → SIT → PROD)
- Security scanning
- Release management

**Key Commands:**
```bash
# Deploy to sandbox
export AWS_PROFILE=sandbox
terraform plan -var-file="environments/sandbox/sandbox.tfvars"
terraform apply -var-file="environments/sandbox/sandbox.tfvars"
```

### Web Developer Agent (`developer/Web_Developer_Agent.md`)

Full-stack web development expertise.

**Capabilities:**
- Frontend development (HTML, CSS, JavaScript)
- React/Vue component development
- API integration
- Responsive design implementation

### WordPress Developer Skill (`developer/wordpress_developer.skill.md`)

Advanced WordPress custom development.

**Capabilities:**
- Custom theme development
- Plugin development and customization
- WP REST API integration
- Block editor (Gutenberg) development
- WP-CLI operations

### Static Site Developer Skill (`developer/static_site_developer.skill.md`)

Modern static site development (Jamstack).

**Capabilities:**
- Static site generators (11ty, Hugo, Jekyll)
- Headless CMS integration
- Build optimization
- CDN deployment

### SPA Developer Skill (`developer/spa_developer.skill.md`)

Single-page application development.

**Capabilities:**
- React/Vue application architecture
- State management (Redux, Vuex)
- Client-side routing
- API integration patterns

---

## Testing Agents

### SDET Engineer Agent (`testing/SDET_Engineer_Agent.md`)

Test automation and quality engineering.

**Capabilities:**
- BDD test development (Cucumber/Gherkin)
- TDD workflows
- Integration testing
- E2E testing
- Test infrastructure setup

### Website Testing Skill (`testing/website_testing.skill.md`)

Comprehensive website QA testing.

**Capabilities:**
- Link validation (broken links, redirects)
- Cross-browser testing
- Responsive design testing
- Performance testing (Core Web Vitals)
- Accessibility testing (WCAG)
- SEO validation

### UI Tester Agent Spec (`testing/ui_tester_agent_spec.md`)

Detailed specification for UI testing automation.

---

## Shared Skills

### Web Design Fundamentals (`skills/web_design_fundamentals.skill.md`)
Core web design principles and best practices.

### HTML Landing Page (`skills/html_landing_page.skill.md`)
Static HTML landing page development.

### React Landing Page (`skills/react_landing_page.skill.md`)
React-based landing page development.

---

## How to Use Agents

### 1. Load Agent into Context

When working with Claude Code, reference the agent file:

```
Please read and apply the agent definition from:
agents/developer/DevOps_Agent.md
```

### 2. Combine Multiple Skills

For complex tasks, combine relevant skills:

```
For this WordPress site with custom React components:
1. Load agents/developer/wordpress_developer.skill.md
2. Load agents/developer/spa_developer.skill.md
3. Load agents/testing/website_testing.skill.md
```

### 3. Use for Specific Workflows

| Workflow | Agents to Load |
|----------|----------------|
| New WordPress site | wordpress_developer.skill.md, website_testing.skill.md |
| React SPA | spa_developer.skill.md, SDET_Engineer_Agent.md |
| Static landing page | static_site_developer.skill.md, html_landing_page.skill.md |
| Deployment | DevOps_Agent.md |
| UI validation | UI_Tester_Agent.md, ui_tester_agent_spec.md |

---

## Environment Configuration

All agents work with the sandbox environment:

| Setting | Value |
|---------|-------|
| AWS Profile | `sandbox` |
| Account ID | `417589271098` |
| Region | `eu-west-1` |
| S3 Bucket | `bigbeard-migrated-site-sandbox` |

```bash
# Set environment
export AWS_PROFILE=sandbox

# Verify
aws sts get-caller-identity --profile sandbox
```

---

## Source Repository

These agents are sourced from `2_bbws_agents/`:
- `2_bbws_agents/content/` - Content and WordPress agents
- `2_bbws_agents/devops/` - DevOps agents
- `2_bbws_agents/agentic_architect/` - Architect and developer agents

For updates, sync from the source repository.
