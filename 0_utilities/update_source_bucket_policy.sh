#!/bin/bash

################################################################################
# Update Source Bucket Policy for Cross-Account Tag Reading
#
# Purpose: Add permissions to bigbeard-migrated-site-dev bucket to allow
#          prod account (093646564004) to read object tags during s3 sync
#
# IMPORTANT: This script must be run in the SOURCE account (536580886816)
#            using appropriate credentials/profile
#
# Usage: ./update_source_bucket_policy.sh [aws-profile-for-dev-account]
################################################################################

set -euo pipefail

BUCKET_NAME="bigbeard-migrated-site-dev"
PROD_ACCOUNT="093646564004"
AWS_PROFILE="${1:-default}"  # Use first argument or 'default'

echo "================================================================================"
echo "Source Bucket Policy Update for Cross-Account Tagging"
echo "================================================================================"
echo "Bucket: ${BUCKET_NAME}"
echo "Allowing Account: ${PROD_ACCOUNT}"
echo "AWS Profile: ${AWS_PROFILE}"
echo ""

# Verify we're in the right account
CURRENT_ACCOUNT=$(aws sts get-caller-identity --profile "${AWS_PROFILE}" --query 'Account' --output text)
echo "Current AWS Account: ${CURRENT_ACCOUNT}"

if [[ "${CURRENT_ACCOUNT}" != "536580886816" ]]; then
    echo "ERROR: This script must be run in the SOURCE account (536580886816)"
    echo "Current account: ${CURRENT_ACCOUNT}"
    exit 1
fi

echo "✓ Confirmed: Running in correct source account"
echo ""

# Get current bucket policy
echo "Fetching current bucket policy..."
CURRENT_POLICY=$(aws s3api get-bucket-policy \
    --bucket "${BUCKET_NAME}" \
    --profile "${AWS_PROFILE}" \
    --query 'Policy' \
    --output text 2>/dev/null || echo "{\"Version\":\"2012-10-17\",\"Statement\":[]}")

echo "✓ Current policy retrieved"
echo ""

# Create the new statement to add
NEW_STATEMENT='{
  "Sid": "AllowProdAccountTaggingRead",
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::'${PROD_ACCOUNT}':root"
  },
  "Action": [
    "s3:GetObjectTagging",
    "s3:GetObjectVersionTagging"
  ],
  "Resource": "arn:aws:s3:::'${BUCKET_NAME}/*"
}'

echo "New policy statement to add:"
echo "${NEW_STATEMENT}" | jq '.'
echo ""

# Merge policies using jq
echo "Merging new statement with existing policy..."
UPDATED_POLICY=$(echo "${CURRENT_POLICY}" | jq --argjson new "${NEW_STATEMENT}" '
  .Statement += [$new] |
  .Statement |= unique_by(.Sid)
')

echo "✓ Policy merged"
echo ""

# Display the updated policy
echo "Updated bucket policy:"
echo "${UPDATED_POLICY}" | jq '.'
echo ""

# Prompt for confirmation
read -p "Apply this policy to bucket ${BUCKET_NAME}? (yes/no): " CONFIRM

if [[ "${CONFIRM}" != "yes" ]]; then
    echo "Aborted by user"
    exit 0
fi

# Apply the updated policy
echo ""
echo "Applying updated policy..."
echo "${UPDATED_POLICY}" | aws s3api put-bucket-policy \
    --bucket "${BUCKET_NAME}" \
    --profile "${AWS_PROFILE}" \
    --policy file:///dev/stdin

echo "✓ Bucket policy updated successfully"
echo ""
echo "The prod account (${PROD_ACCOUNT}) can now read object tags from ${BUCKET_NAME}"
echo "You can now retry the s3 sync operations"
