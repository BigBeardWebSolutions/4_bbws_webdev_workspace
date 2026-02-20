#!/bin/bash
# Script to generate worker instructions.md files
# Usage: ./create_worker_instructions.sh

WORKERS=(
  "stage-1-requirements-analysis/worker-2-requirements-validation"
  "stage-1-requirements-analysis/worker-3-naming-convention-analysis"
  "stage-1-requirements-analysis/worker-4-environment-configuration-analysis"
  "stage-2-lld-document-creation/worker-1-lld-structure-introduction"
  "stage-2-lld-document-creation/worker-2-dynamodb-design-section"
  "stage-2-lld-document-creation/worker-3-s3-design-section"
  "stage-2-lld-document-creation/worker-5-terraform-design-section"
  "stage-2-lld-document-creation/worker-6-cicd-pipeline-design-section"
  "stage-3-infrastructure-code/worker-1-dynamodb-json-schemas"
  "stage-3-infrastructure-code/worker-2-terraform-dynamodb-module"
  "stage-3-infrastructure-code/worker-3-terraform-s3-module"
  "stage-3-infrastructure-code/worker-4-html-email-templates"
  "stage-3-infrastructure-code/worker-5-environment-configurations"
  "stage-3-infrastructure-code/worker-6-validation-scripts"
  "stage-4-cicd-pipeline/worker-1-validation-workflows"
  "stage-4-cicd-pipeline/worker-2-terraform-plan-workflow"
  "stage-4-cicd-pipeline/worker-3-deployment-workflows"
  "stage-4-cicd-pipeline/worker-4-rollback-workflow"
  "stage-4-cicd-pipeline/worker-5-test-scripts"
  "stage-5-documentation-runbooks/worker-1-deployment-runbook"
  "stage-5-documentation-runbooks/worker-2-promotion-runbook"
  "stage-5-documentation-runbooks/worker-3-troubleshooting-runbook"
  "stage-5-documentation-runbooks/worker-4-rollback-runbook"
)

echo "Worker instructions script created."
echo "Total workers to generate: ${#WORKERS[@]}"
