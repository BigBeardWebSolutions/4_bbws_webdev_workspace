# Worker 4-1: Build & Test Workflow

## Worker Identity
- **Worker ID**: 4-1
- **Worker Name**: Build & Test Workflow Developer
- **Stage**: 4 - CI/CD Pipeline Development
- **Dependencies**: Stage 2 complete (React application)

## Objective

Create a comprehensive GitHub Actions workflow for Continuous Integration of the React application. This workflow will automatically run linting, testing, and building on every pull request and push to the main branch.

## Deliverables

1. `.github/workflows/build-test.yml` in 2_1_bbws_web_public repository
2. Workflow configuration with proper caching and optimization
3. Status badge for README (optional)

## Technical Specifications

### Workflow Features

**Triggers**:
- Pull requests targeting main/master branch
- Pushes to main/master branch
- Manual workflow dispatch for testing

**Jobs**:
1. **Lint**: ESLint code quality checks
2. **Test**: Jest unit tests with coverage reporting
3. **Build**: Production build validation

**Optimizations**:
- npm dependency caching for faster builds
- Parallel job execution where possible
- Skip CI on documentation-only changes
- Build artifact preservation

### Workflow File Structure

```yaml
name: Build and Test
on:
  pull_request:
    branches: [main, master]
  push:
    branches: [main, master]
  workflow_dispatch:

jobs:
  lint:
    # Linting job
  test:
    # Testing job
  build:
    # Build job
```

### Environment Variables

**Node.js Version**: 18.x (matches deployment environment)

**NPM Configuration**:
- Use npm ci for clean installs
- Cache ~/.npm directory
- Set NODE_ENV=production for builds

### Required Steps

**Lint Job**:
1. Checkout repository
2. Setup Node.js 18.x
3. Restore npm cache
4. Install dependencies (npm ci)
5. Run ESLint (npm run lint)

**Test Job**:
1. Checkout repository
2. Setup Node.js 18.x
3. Restore npm cache
4. Install dependencies (npm ci)
5. Run tests with coverage (npm test -- --coverage)
6. Upload coverage report (optional: to Codecov or similar)

**Build Job**:
1. Checkout repository
2. Setup Node.js 18.x
3. Restore npm cache
4. Install dependencies (npm ci)
5. Build production bundle (npm run build)
6. Upload build artifact (dist/ directory)
7. Display build size summary

### Success Criteria

- Lint job fails if ESLint errors found
- Test job fails if any test fails or coverage below threshold
- Build job fails if build errors occur
- All jobs complete in < 5 minutes (with caching)
- Build artifact available for download

### Error Handling

- Workflow fails fast on first error
- Clear error messages in job logs
- Annotations for ESLint errors in PR
- Test failure details visible in summary

## Implementation Steps

### Step 1: Create Workflow Directory

Create `.github/workflows/` directory in 2_1_bbws_web_public repository.

### Step 2: Create Workflow File

Create `build-test.yml` with complete CI configuration.

### Step 3: Configure Caching

Implement npm dependency caching using `actions/cache@v3`:
```yaml
- uses: actions/cache@v3
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-
```

### Step 4: Add Status Checks

Configure required status checks in repository settings:
- lint
- test
- build

### Step 5: Test Workflow

Create a test PR to verify workflow execution.

## Validation Checklist

- [ ] Workflow file created in `.github/workflows/build-test.yml`
- [ ] Workflow triggers on PR and push events
- [ ] Lint job runs successfully
- [ ] Test job runs successfully with coverage
- [ ] Build job produces artifact
- [ ] npm caching works (second run faster)
- [ ] Workflow fails appropriately on errors
- [ ] PR shows status checks
- [ ] Build completes in < 5 minutes

## Example Workflow Output

**Successful Run**:
```
✅ Lint (30s)
✅ Test (45s)
✅ Build (60s)

Total time: 2m 15s
```

**Failed Run** (lint error):
```
❌ Lint (25s)
  Error: 'useState' is not defined (react/jsx-no-undef)
  File: src/components/ProductCard.tsx:15:10
⏭️ Test (skipped)
⏭️ Build (skipped)
```

## Best Practices

1. **Use specific action versions**: `actions/checkout@v4`, not `@latest`
2. **Cache dependencies**: Significantly speeds up builds
3. **Run jobs in parallel**: Unless dependencies exist
4. **Use matrix strategy**: For testing multiple Node versions (if needed)
5. **Add workflow status badge**: In README.md
6. **Set timeout limits**: Prevent runaway jobs
7. **Use concurrency groups**: Prevent concurrent runs on same PR

## Integration Points

### With Stage 2 (Frontend):
- Uses package.json scripts created in Stage 2
- Runs tests written in Stage 2
- Builds React app created in Stage 2

### With Worker 4-3 (Application Deployment):
- Build artifacts can be reused for deployment
- Same Node.js version for consistency
- Validates code before deployment

## Security Considerations

- No secrets required for this workflow (public operations)
- Read-only token for checkout (default)
- No write access to repository needed
- Safe to run on forked PRs

## Troubleshooting Guide

**Issue**: Cache not restoring
- **Solution**: Check cache key includes package-lock.json hash

**Issue**: Tests failing in CI but pass locally
- **Solution**: Check Node version matches (18.x), check environment variables

**Issue**: Build timing out
- **Solution**: Increase timeout-minutes, check for infinite loops

**Issue**: ESLint annotations not showing in PR
- **Solution**: Use ESLint action with GitHub annotations formatter

## Future Enhancements

- Add Codecov integration for coverage reporting
- Add build size tracking and reporting
- Add Lighthouse CI for performance testing
- Add dependency vulnerability scanning
- Add automatic PR comments with build stats

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [actions/checkout](https://github.com/actions/checkout)
- [actions/setup-node](https://github.com/actions/setup-node)
- [actions/cache](https://github.com/actions/cache)
- [Workflow syntax reference](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)

## Completion Criteria

This worker is complete when:
1. Workflow file created and committed
2. Test PR created and workflow runs successfully
3. All validation checklist items checked
4. Workflow documented in repository README
