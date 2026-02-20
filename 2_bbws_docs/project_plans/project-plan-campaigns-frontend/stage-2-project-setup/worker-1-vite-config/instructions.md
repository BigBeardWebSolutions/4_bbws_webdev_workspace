# Worker Instructions: Vite Configuration

**Worker ID**: worker-1-vite-config
**Stage**: Stage 2 - Project Setup & Configuration
**Project**: project-plan-campaigns-frontend

---

## Task

Validate and enhance the Vite configuration to support multi-environment builds (dev/sit/prod), proper base paths, and environment variable handling.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/vite.config.ts`

**Supporting Inputs**:
- Stage 1 Gap Analysis output
- Environment variable files (`.env.*` if present)
- Package.json build scripts

---

## Deliverables

Create `output.md` documenting:

### 1. Current Configuration Analysis

Review current vite.config.ts and document:
- Build options
- Plugin configuration
- Environment handling
- Base path configuration

### 2. Required Configuration

Based on requirements:
- Environment-specific API base URLs
- Proper base path for deployment
- Build optimization settings
- Development server settings

### 3. Environment Variables

Document required environment variables:
- `VITE_API_BASE_URL`
- `VITE_API_KEY`
- Other necessary variables

### 4. Configuration Updates

If updates needed, document:
- Changes to vite.config.ts
- New environment files
- Updated build scripts

---

## Expected Output Format

```markdown
# Vite Configuration Output

## 1. Current Configuration Analysis

### vite.config.ts
```typescript
// Current configuration
export default defineConfig({
  plugins: [react()],
  base: '/buy/',
  // ...
})
```

### Current Settings
- Base path: `/buy/`
- Plugins: React
- Mode handling: Yes/No

## 2. Required Configuration

### Environment URLs
| Environment | Base URL |
|-------------|----------|
| development | https://api.dev.kimmyai.io |
| sit | https://api.sit.kimmyai.io |
| production | https://api.kimmyai.io |

### Required Settings
- Base path: `/buy/` (confirmed)
- Build output: `dist/`
- Source maps: dev only
- Minification: production only

## 3. Environment Variables

### Required Variables
| Variable | Description | Example |
|----------|-------------|---------|
| VITE_API_BASE_URL | API base URL | https://api.dev.kimmyai.io |
| VITE_PRODUCT_API_KEY | Product API key | xxxxxx |
| VITE_ENVIRONMENT | Current environment | dev |

### Environment Files
- `.env.development` - Development settings
- `.env.sit` - SIT settings
- `.env.production` - Production settings

## 4. Configuration Updates

### Changes Required
- [ ] Add environment detection
- [ ] Configure source maps by mode
- [ ] Add build optimization

### Updated vite.config.ts
```typescript
import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');

  return {
    plugins: [react()],
    base: '/buy/',
    build: {
      sourcemap: mode !== 'production',
      minify: mode === 'production' ? 'terser' : false,
    },
    define: {
      __APP_ENV__: JSON.stringify(env.VITE_ENVIRONMENT),
    },
  };
});
```

## 5. Validation Checklist

- [ ] Dev build works: npm run build:dev
- [ ] SIT build works: npm run build:sit
- [ ] Prod build works: npm run build:prod
- [ ] Environment variables load correctly
- [ ] Base path correct for deployment
```

---

## Success Criteria

- [ ] Current config analyzed
- [ ] All environments supported (dev/sit/prod)
- [ ] Environment variables documented
- [ ] Configuration validated or updated
- [ ] All build scripts work
- [ ] Output.md created with all sections

---

## Execution Steps

1. Read current vite.config.ts
2. Check for .env files
3. Review package.json build scripts
4. Verify environment variable usage
5. Test build commands (if possible)
6. Document required changes
7. Create output.md with all sections
8. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-18
