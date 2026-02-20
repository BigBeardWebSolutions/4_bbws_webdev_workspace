# Worker 4 Output: Environment Promotion Workflows

**Worker ID**: worker-4-environment-promotion-workflow
**Status**: COMPLETE
**Completed**: 2026-01-25

---

## Deliverables

### 1. promote-to-sit.yml

```yaml
# .github/workflows/promote-to-sit.yml
name: Promote to SIT

on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version tag (e.g., v1.0.0)'
        required: true
        type: string
      skip_tests:
        description: 'Skip DEV tests before promotion'
        required: false
        type: boolean
        default: false

permissions:
  id-token: write
  contents: write
  pull-requests: write

env:
  PYTHON_VERSION: '3.12'
  DEV_ACCOUNT_ID: '536580886816'
  SIT_ACCOUNT_ID: '815856636111'
  AWS_REGION: 'eu-west-1'

jobs:
  validate-version:
    name: Validate Version
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.validate.outputs.version }}
      release_branch: ${{ steps.validate.outputs.release_branch }}
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Validate Version Format
        id: validate
        run: |
          VERSION="${{ github.event.inputs.version }}"

          # Validate semver format
          if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$ ]]; then
            echo "Error: Invalid version format. Expected vX.Y.Z or vX.Y.Z-suffix"
            exit 1
          fi

          # Check if version tag already exists
          if git rev-parse "$VERSION" >/dev/null 2>&1; then
            echo "Error: Version $VERSION already exists"
            exit 1
          fi

          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "release_branch=release/$VERSION" >> $GITHUB_OUTPUT
          echo "Version validated: $VERSION"

  run-dev-tests:
    name: Run DEV Tests
    runs-on: ubuntu-latest
    needs: validate-version
    if: ${{ github.event.inputs.skip_tests != 'true' }}
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'

      - name: Install Dependencies
        run: |
          pip install -r requirements.txt
          pip install -r requirements-dev.txt

      - name: Configure AWS Credentials (DEV)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ env.DEV_ACCOUNT_ID }}:role/bbws-access-dev-github-actions-role
          aws-region: ${{ env.AWS_REGION }}

      - name: Run Full Test Suite in DEV
        env:
          TEST_ENVIRONMENT: dev
        run: |
          pytest tests/unit/ tests/integration/ tests/contract/ \
            -v \
            --junitxml=dev-test-results.xml \
            -n auto

      - name: Upload Test Results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: dev-test-results
          path: dev-test-results.xml

  create-release-branch:
    name: Create Release Branch
    runs-on: ubuntu-latest
    needs: [validate-version, run-dev-tests]
    if: always() && (needs.run-dev-tests.result == 'success' || needs.run-dev-tests.result == 'skipped')
    outputs:
      branch_created: ${{ steps.create-branch.outputs.created }}
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Configure Git
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"

      - name: Create Release Branch
        id: create-branch
        run: |
          RELEASE_BRANCH="${{ needs.validate-version.outputs.release_branch }}"

          # Create release branch from develop
          git checkout develop
          git pull origin develop
          git checkout -b "$RELEASE_BRANCH"

          # Push release branch
          git push origin "$RELEASE_BRANCH"

          echo "created=true" >> $GITHUB_OUTPUT
          echo "Created release branch: $RELEASE_BRANCH"

  deploy-to-sit:
    name: Deploy to SIT
    runs-on: ubuntu-latest
    needs: [validate-version, create-release-branch]
    environment: sit
    steps:
      - name: Checkout Release Branch
        uses: actions/checkout@v4
        with:
          ref: ${{ needs.validate-version.outputs.release_branch }}

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Configure AWS Credentials (SIT)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ env.SIT_ACCOUNT_ID }}:role/bbws-access-sit-github-actions-role
          aws-region: ${{ env.AWS_REGION }}

      - name: Build Lambda Packages
        run: |
          chmod +x scripts/build-lambdas.sh
          ./scripts/build-lambdas.sh

      - name: Deploy Infrastructure (Terraform)
        run: |
          cd terraform
          terraform init \
            -backend-config="bucket=bbws-access-sit-terraform-state" \
            -backend-config="key=access-management/terraform.tfstate" \
            -backend-config="region=${{ env.AWS_REGION }}"

          terraform apply \
            -var-file="environments/sit.tfvars" \
            -auto-approve

      - name: Deploy Lambda Functions
        run: |
          chmod +x scripts/deploy-lambdas.sh
          ./scripts/deploy-lambdas.sh sit ${{ needs.validate-version.outputs.version }}

      - name: Update Aliases
        run: |
          chmod +x scripts/update-aliases.sh
          ./scripts/update-aliases.sh sit live

  run-sit-tests:
    name: Run SIT Integration Tests
    runs-on: ubuntu-latest
    needs: [validate-version, deploy-to-sit]
    environment: sit
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4
        with:
          ref: ${{ needs.validate-version.outputs.release_branch }}

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'

      - name: Install Dependencies
        run: |
          pip install -r requirements.txt
          pip install -r requirements-dev.txt

      - name: Configure AWS Credentials (SIT)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ env.SIT_ACCOUNT_ID }}:role/bbws-access-sit-github-actions-role
          aws-region: ${{ env.AWS_REGION }}

      - name: Run Integration Tests
        env:
          TEST_ENVIRONMENT: sit
        run: |
          pytest tests/integration/ tests/authorization/ \
            -v \
            --junitxml=sit-test-results.xml \
            -n 4

      - name: Upload Test Results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: sit-test-results
          path: sit-test-results.xml

  create-draft-release:
    name: Create Draft Release
    runs-on: ubuntu-latest
    needs: [validate-version, run-sit-tests]
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4
        with:
          ref: ${{ needs.validate-version.outputs.release_branch }}
          fetch-depth: 0

      - name: Generate Changelog
        id: changelog
        run: |
          # Get commits since last tag
          LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

          echo "## What's Changed" > changelog.md
          echo "" >> changelog.md

          if [ -n "$LAST_TAG" ]; then
            git log --pretty=format:"- %s (%h)" $LAST_TAG..HEAD >> changelog.md
          else
            git log --pretty=format:"- %s (%h)" --max-count=50 >> changelog.md
          fi

          echo "" >> changelog.md
          echo "" >> changelog.md
          echo "**Full Changelog**: https://github.com/${{ github.repository }}/compare/$LAST_TAG...${{ needs.validate-version.outputs.version }}" >> changelog.md

      - name: Create Draft Release
        uses: softprops/action-gh-release@v1
        with:
          tag_name: ${{ needs.validate-version.outputs.version }}
          name: Release ${{ needs.validate-version.outputs.version }}
          body_path: changelog.md
          draft: true
          prerelease: false
          target_commitish: ${{ needs.validate-version.outputs.release_branch }}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  notify:
    name: Send Notifications
    runs-on: ubuntu-latest
    needs: [validate-version, run-sit-tests, create-draft-release]
    if: always()
    steps:
      - name: Notify Slack - Success
        if: needs.run-sit-tests.result == 'success'
        uses: slackapi/slack-github-action@v1.25.0
        with:
          payload: |
            {
              "text": ":rocket: SIT Promotion Successful",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*SIT Promotion Successful* :white_check_mark:\n\n*Version:* `${{ needs.validate-version.outputs.version }}`\n*Branch:* `${{ needs.validate-version.outputs.release_branch }}`\n*Actor:* `${{ github.actor }}`\n\nReady for UAT testing. Run `promote-to-prod` workflow when ready."
                  }
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
          SLACK_WEBHOOK_TYPE: INCOMING_WEBHOOK

      - name: Notify Slack - Failure
        if: needs.run-sit-tests.result == 'failure'
        uses: slackapi/slack-github-action@v1.25.0
        with:
          payload: |
            {
              "text": ":x: SIT Promotion Failed",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*SIT Promotion Failed* :x:\n\n*Version:* `${{ needs.validate-version.outputs.version }}`\n*Actor:* `${{ github.actor }}`\n*Run:* <${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}|View Details>"
                  }
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
          SLACK_WEBHOOK_TYPE: INCOMING_WEBHOOK

      - name: Generate Summary
        if: always()
        run: |
          echo "## Promotion to SIT Summary" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Property | Value |" >> $GITHUB_STEP_SUMMARY
          echo "|----------|-------|" >> $GITHUB_STEP_SUMMARY
          echo "| Version | ${{ needs.validate-version.outputs.version }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Release Branch | ${{ needs.validate-version.outputs.release_branch }} |" >> $GITHUB_STEP_SUMMARY
          echo "| SIT Tests | ${{ needs.run-sit-tests.result }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Draft Release | ${{ needs.create-draft-release.result }} |" >> $GITHUB_STEP_SUMMARY
```

---

### 2. promote-to-prod.yml

```yaml
# .github/workflows/promote-to-prod.yml
name: Promote to PROD

on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version tag to promote (e.g., v1.0.0)'
        required: true
        type: string
      release_notes:
        description: 'Additional release notes'
        required: false
        type: string
      skip_canary:
        description: 'Skip canary deployment'
        required: false
        type: boolean
        default: false

permissions:
  id-token: write
  contents: write
  pull-requests: write

env:
  PYTHON_VERSION: '3.12'
  SIT_ACCOUNT_ID: '815856636111'
  PROD_ACCOUNT_ID: '093646564004'
  PROD_REGION: 'af-south-1'
  SIT_REGION: 'eu-west-1'

jobs:
  validate-release:
    name: Validate Release
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.validate.outputs.version }}
      release_branch: ${{ steps.validate.outputs.release_branch }}
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Validate Release Exists
        id: validate
        run: |
          VERSION="${{ github.event.inputs.version }}"
          RELEASE_BRANCH="release/$VERSION"

          # Check release branch exists
          if ! git ls-remote --heads origin "$RELEASE_BRANCH" | grep -q "$RELEASE_BRANCH"; then
            echo "Error: Release branch $RELEASE_BRANCH does not exist"
            echo "Please run 'promote-to-sit' workflow first"
            exit 1
          fi

          # Check draft release exists
          RELEASE_EXISTS=$(gh release view "$VERSION" --json isDraft -q '.isDraft' 2>/dev/null || echo "none")
          if [ "$RELEASE_EXISTS" == "none" ]; then
            echo "Error: Draft release for $VERSION does not exist"
            exit 1
          fi

          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "release_branch=$RELEASE_BRANCH" >> $GITHUB_OUTPUT
          echo "Release validated: $VERSION"
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  verify-sit-deployment:
    name: Verify SIT Deployment
    runs-on: ubuntu-latest
    needs: validate-release
    steps:
      - name: Checkout Release Branch
        uses: actions/checkout@v4
        with:
          ref: ${{ needs.validate-release.outputs.release_branch }}

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'

      - name: Install Dependencies
        run: pip install -r requirements-dev.txt

      - name: Configure AWS Credentials (SIT)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ env.SIT_ACCOUNT_ID }}:role/bbws-access-sit-github-actions-role
          aws-region: ${{ env.SIT_REGION }}

      - name: Verify SIT Health
        env:
          TEST_ENVIRONMENT: sit
        run: |
          pytest tests/smoke/ \
            -v \
            --junitxml=sit-verification.xml

  request-approval:
    name: Request PROD Approval
    runs-on: ubuntu-latest
    needs: [validate-release, verify-sit-deployment]
    environment: prod
    steps:
      - name: Approval Checkpoint
        run: |
          echo "PROD deployment approved by environment protection rules"
          echo "Version: ${{ needs.validate-release.outputs.version }}"
          echo "Approved by: ${{ github.actor }}"

  merge-to-main:
    name: Merge to Main
    runs-on: ubuntu-latest
    needs: [validate-release, request-approval]
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Configure Git
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"

      - name: Merge Release to Main
        run: |
          RELEASE_BRANCH="${{ needs.validate-release.outputs.release_branch }}"
          VERSION="${{ needs.validate-release.outputs.version }}"

          git fetch origin main "$RELEASE_BRANCH"
          git checkout main
          git merge "origin/$RELEASE_BRANCH" --no-ff -m "Merge $RELEASE_BRANCH into main for $VERSION"
          git push origin main

          # Create version tag
          git tag -a "$VERSION" -m "Release $VERSION"
          git push origin "$VERSION"

  deploy-to-prod:
    name: Deploy to PROD
    runs-on: ubuntu-latest
    needs: [validate-release, merge-to-main]
    environment: prod
    steps:
      - name: Checkout Main
        uses: actions/checkout@v4
        with:
          ref: main

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Configure AWS Credentials (PROD)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ env.PROD_ACCOUNT_ID }}:role/bbws-access-prod-github-actions-role
          aws-region: ${{ env.PROD_REGION }}

      - name: Build Lambda Packages
        run: |
          chmod +x scripts/build-lambdas.sh
          ./scripts/build-lambdas.sh

      - name: Deploy Infrastructure (Terraform)
        run: |
          cd terraform
          terraform init \
            -backend-config="bucket=bbws-access-prod-terraform-state" \
            -backend-config="key=access-management/terraform.tfstate" \
            -backend-config="region=${{ env.PROD_REGION }}"

          terraform apply \
            -var-file="environments/prod.tfvars" \
            -auto-approve

      - name: Deploy Lambda Functions
        run: |
          chmod +x scripts/deploy-lambdas.sh
          ./scripts/deploy-lambdas.sh prod ${{ needs.validate-release.outputs.version }}

      - name: Canary Deployment (10%)
        if: ${{ github.event.inputs.skip_canary != 'true' }}
        run: |
          chmod +x scripts/canary-deploy.sh
          ./scripts/canary-deploy.sh prod 10

          echo "Waiting 5 minutes for canary metrics..."
          sleep 300

          chmod +x scripts/evaluate-canary.sh
          ./scripts/evaluate-canary.sh prod

      - name: Full Traffic Shift
        run: |
          chmod +x scripts/update-aliases.sh
          ./scripts/update-aliases.sh prod live

      - name: Record Deployment
        run: |
          aws ssm put-parameter \
            --name "/bbws-access/prod/deployed-version" \
            --value "${{ needs.validate-release.outputs.version }}" \
            --type String \
            --overwrite

          aws ssm put-parameter \
            --name "/bbws-access/prod/deployed-at" \
            --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            --type String \
            --overwrite

  run-prod-smoke-tests:
    name: Run PROD Smoke Tests
    runs-on: ubuntu-latest
    needs: [validate-release, deploy-to-prod]
    environment: prod
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4
        with:
          ref: main

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'

      - name: Install Dependencies
        run: pip install -r requirements-dev.txt

      - name: Configure AWS Credentials (PROD)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ env.PROD_ACCOUNT_ID }}:role/bbws-access-prod-github-actions-role
          aws-region: ${{ env.PROD_REGION }}

      - name: Run Smoke Tests
        env:
          TEST_ENVIRONMENT: prod
        run: |
          pytest tests/smoke/ \
            -v \
            --junitxml=prod-smoke-results.xml

      - name: Upload Results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: prod-smoke-results
          path: prod-smoke-results.xml

  finalize-release:
    name: Finalize Release
    runs-on: ubuntu-latest
    needs: [validate-release, run-prod-smoke-tests]
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Publish Release
        run: |
          VERSION="${{ needs.validate-release.outputs.version }}"

          # Update release notes if provided
          if [ -n "${{ github.event.inputs.release_notes }}" ]; then
            CURRENT_BODY=$(gh release view "$VERSION" --json body -q '.body')
            NEW_BODY="$CURRENT_BODY

          ## Additional Notes
          ${{ github.event.inputs.release_notes }}"

            gh release edit "$VERSION" --notes "$NEW_BODY"
          fi

          # Publish the release (remove draft status)
          gh release edit "$VERSION" --draft=false
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  notify:
    name: Send Notifications
    runs-on: ubuntu-latest
    needs: [validate-release, run-prod-smoke-tests, finalize-release]
    if: always()
    steps:
      - name: Notify Slack - Success
        if: needs.run-prod-smoke-tests.result == 'success'
        uses: slackapi/slack-github-action@v1.25.0
        with:
          payload: |
            {
              "text": ":tada: PROD Deployment Successful",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*PROD Deployment Successful* :tada:\n\n*Version:* `${{ needs.validate-release.outputs.version }}`\n*Region:* `af-south-1`\n*Deployed By:* `${{ github.actor }}`\n*Release:* <https://github.com/${{ github.repository }}/releases/tag/${{ needs.validate-release.outputs.version }}|View Release>"
                  }
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
          SLACK_WEBHOOK_TYPE: INCOMING_WEBHOOK

      - name: Notify Slack - Failure
        if: needs.run-prod-smoke-tests.result == 'failure'
        uses: slackapi/slack-github-action@v1.25.0
        with:
          payload: |
            {
              "text": ":rotating_light: PROD Deployment Failed - ROLLBACK MAY BE REQUIRED",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*PROD Deployment Failed* :rotating_light:\n\n*Version:* `${{ needs.validate-release.outputs.version }}`\n*Region:* `af-south-1`\n*Action Required:* Review logs and consider rollback\n*Run:* <${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}|View Details>"
                  }
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
          SLACK_WEBHOOK_TYPE: INCOMING_WEBHOOK

      - name: Generate Summary
        if: always()
        run: |
          echo "## Promotion to PROD Summary" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Property | Value |" >> $GITHUB_STEP_SUMMARY
          echo "|----------|-------|" >> $GITHUB_STEP_SUMMARY
          echo "| Version | ${{ needs.validate-release.outputs.version }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Region | af-south-1 |" >> $GITHUB_STEP_SUMMARY
          echo "| Smoke Tests | ${{ needs.run-prod-smoke-tests.result }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Release Published | ${{ needs.finalize-release.result }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Deployed By | ${{ github.actor }} |" >> $GITHUB_STEP_SUMMARY
```

---

### 3. Version Management Script

```bash
#!/bin/bash
# scripts/version-manager.sh
# Semantic version management utilities

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="$SCRIPT_DIR/../VERSION"

get_current_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        echo "0.0.0"
    fi
}

bump_version() {
    local current=$1
    local bump_type=$2

    IFS='.' read -r major minor patch <<< "${current#v}"

    case $bump_type in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            echo "Invalid bump type: $bump_type"
            exit 1
            ;;
    esac

    echo "v$major.$minor.$patch"
}

save_version() {
    local version=$1
    echo "$version" > "$VERSION_FILE"
    echo "Version saved: $version"
}

# Main
case "${1:-}" in
    current)
        get_current_version
        ;;
    bump)
        current=$(get_current_version)
        new_version=$(bump_version "$current" "${2:-patch}")
        echo "$new_version"
        ;;
    save)
        save_version "$2"
        ;;
    *)
        echo "Usage: $0 {current|bump [major|minor|patch]|save <version>}"
        exit 1
        ;;
esac
```

---

## Promotion Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     PROMOTION WORKFLOW                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  DEV (develop branch)                                           │
│       │                                                         │
│       ▼                                                         │
│  ┌─────────────────┐                                           │
│  │ Run DEV Tests   │                                           │
│  └────────┬────────┘                                           │
│           │ Pass                                                │
│           ▼                                                     │
│  ┌─────────────────┐     promote-to-sit.yml                    │
│  │ Create Release  │◄────────────────────────                  │
│  │ Branch          │     (manual trigger)                      │
│  └────────┬────────┘                                           │
│           │                                                     │
│           ▼                                                     │
│  SIT (release/vX.Y.Z branch)                                    │
│       │                                                         │
│       ▼                                                         │
│  ┌─────────────────┐                                           │
│  │ Deploy to SIT   │                                           │
│  └────────┬────────┘                                           │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────┐                                           │
│  │ Run SIT Tests   │                                           │
│  └────────┬────────┘                                           │
│           │ Pass                                                │
│           ▼                                                     │
│  ┌─────────────────┐                                           │
│  │ Create Draft    │                                           │
│  │ Release         │                                           │
│  └────────┬────────┘                                           │
│           │                                                     │
│           │ UAT Testing (manual)                                │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────┐     promote-to-prod.yml                   │
│  │ Request PROD    │◄────────────────────────                  │
│  │ Approval        │     (manual trigger)                      │
│  └────────┬────────┘                                           │
│           │ Approved (environment protection)                   │
│           ▼                                                     │
│  ┌─────────────────┐                                           │
│  │ Merge to Main   │                                           │
│  │ + Create Tag    │                                           │
│  └────────┬────────┘                                           │
│           │                                                     │
│           ▼                                                     │
│  PROD (main branch)                                             │
│       │                                                         │
│       ▼                                                         │
│  ┌─────────────────┐                                           │
│  │ Canary Deploy   │─────┐                                     │
│  │ (10% traffic)   │     │ 5 min                               │
│  └────────┬────────┘     │                                     │
│           │◄─────────────┘                                     │
│           ▼ Healthy                                             │
│  ┌─────────────────┐                                           │
│  │ Full Deploy     │                                           │
│  │ (100% traffic)  │                                           │
│  └────────┬────────┘                                           │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────┐                                           │
│  │ Smoke Tests     │                                           │
│  └────────┬────────┘                                           │
│           │ Pass                                                │
│           ▼                                                     │
│  ┌─────────────────┐                                           │
│  │ Publish Release │                                           │
│  │ + Notify Team   │                                           │
│  └─────────────────┘                                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Success Criteria Checklist

- [x] Manual promotion trigger works
- [x] Version tag validation
- [x] Release branch creation
- [x] SIT deployment automated
- [x] PROD requires approval (environment protection)
- [x] GitHub releases created (draft → published)
- [x] Team notifications sent (Slack)
- [x] Canary deployment for PROD
- [x] Semantic versioning support

---

**Completed By**: Worker 4
**Date**: 2026-01-25
