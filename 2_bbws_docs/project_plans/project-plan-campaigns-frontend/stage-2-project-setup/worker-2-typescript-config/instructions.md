# Worker Instructions: TypeScript Configuration

**Worker ID**: worker-2-typescript-config
**Stage**: Stage 2 - Project Setup & Configuration
**Project**: project-plan-campaigns-frontend

---

## Task

Validate and enhance TypeScript configuration for strict type safety, proper module resolution, and path aliases to support maintainable code.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public/campaigns/tsconfig.json`

**Supporting Inputs**:
- Stage 1 Gap Analysis output
- Source code structure in `src/`
- Type definition files in `src/types/`

---

## Deliverables

Create `output.md` documenting:

### 1. Current Configuration Analysis

Review current tsconfig.json and document:
- Compiler options
- Include/exclude patterns
- Module resolution
- Strict mode settings

### 2. Required Configuration

Based on requirements:
- Strict mode enabled
- Path aliases for clean imports
- Proper module resolution
- JSX configuration for React

### 3. Path Aliases

Document recommended path aliases:
- `@components/*` -> `src/components/*`
- `@services/*` -> `src/services/*`
- `@types/*` -> `src/types/*`
- `@utils/*` -> `src/utils/*`

### 4. Configuration Updates

If updates needed, document:
- Changes to tsconfig.json
- Vite path alias sync (if needed)

---

## Expected Output Format

```markdown
# TypeScript Configuration Output

## 1. Current Configuration Analysis

### tsconfig.json
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "strict": true,
    ...
  }
}
```

### Current Settings
| Setting | Value | Assessment |
|---------|-------|------------|
| strict | true | Good |
| noImplicitAny | true | Good |
| module | ESNext | Good |
| target | ES2020 | Good |

## 2. Required Configuration

### Compiler Options Required
- strict: true (for type safety)
- noImplicitAny: true
- strictNullChecks: true
- noUnusedLocals: true
- noUnusedParameters: true
- esModuleInterop: true
- skipLibCheck: true

### Module Settings
- moduleResolution: "bundler"
- resolveJsonModule: true
- isolatedModules: true

### JSX Settings
- jsx: "react-jsx"

## 3. Path Aliases

### Recommended Aliases
| Alias | Path | Usage Example |
|-------|------|---------------|
| @/* | src/* | import { X } from '@/types' |
| @components/* | src/components/* | import X from '@components/layout/PageLayout' |
| @services/* | src/services/* | import { fetchProducts } from '@services/productApi' |
| @types/* | src/types/* | import type { Campaign } from '@types/campaign' |
| @utils/* | src/utils/* | import { validate } from '@utils/validation' |

### tsconfig.json paths
```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@components/*": ["src/components/*"],
      "@services/*": ["src/services/*"],
      "@types/*": ["src/types/*"],
      "@utils/*": ["src/utils/*"]
    }
  }
}
```

## 4. Configuration Updates

### Changes Required
- [ ] Add path aliases
- [ ] Ensure strict settings
- [ ] Add noUnused* settings

### Updated tsconfig.json
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"]
    }
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

## 5. Vite Path Sync

If path aliases added, sync with vite.config.ts:
```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
```

## 6. Validation Checklist

- [ ] npm run type-check passes
- [ ] No implicit any errors
- [ ] Path aliases resolve correctly
- [ ] IDE autocomplete works
```

---

## Success Criteria

- [ ] Current config analyzed
- [ ] Strict mode confirmed/enabled
- [ ] Path aliases configured (if recommended)
- [ ] Module resolution validated
- [ ] Type checking passes
- [ ] Output.md created with all sections

---

## Execution Steps

1. Read current tsconfig.json
2. Verify strict mode settings
3. Check module resolution configuration
4. Review path alias needs
5. Test type checking (npm run type-check)
6. Document required changes
7. Create output.md with all sections
8. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-18
