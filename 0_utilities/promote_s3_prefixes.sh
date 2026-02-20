#!/bin/bash

################################################################################
# S3 Cross-Account Prefix Promotion Script
#
# Purpose: Sync specific S3 prefixes from dev bucket (eu-west-1) to prod bucket
#          (af-south-1) across AWS accounts, ensuring exact mirror.
#
# Source:      bigbeard-migrated-site-dev (536580886816, eu-west-1)
# Destination: bigbeard-migrated-site-prod-af-south-1 (093646564004, af-south-1)
# Profile:     prod
#
# Features:
# - DRY_RUN mode for safe testing
# - Prefix existence validation
# - Copy/override files with timestamp preservation (no deletions)
# - Handles folder names with spaces
# - Comprehensive error handling and logging
#
# Usage: ./promote_s3_prefixes.sh
################################################################################

set -euo pipefail  # Exit on error, undefined vars, pipe failures

################################################################################
# CONFIGURATION
################################################################################

# DRY_RUN: Set to "true" for dry run, "false" for actual execution
DRY_RUN="false"

# AWS Configuration
AWS_PROFILE="prod"
SOURCE_BUCKET="bigbeard-migrated-site-dev"
SOURCE_ACCOUNT="536580886816"
SOURCE_REGION="eu-west-1"
DEST_BUCKET="bigbeard-migrated-site-prod-af-south-1"
DEST_ACCOUNT="093646564004"
DEST_REGION="af-south-1"

# Prefixes to promote (exact names as they appear in S3)
PREFIXES=(
    "amandakatzart"
    "bigbeard"
    "competencesa"
    "deborahatkins"
    "furnell"
    "swimforrivers"
    "aftsarepository"
)

# Counters for summary
SUCCESS_COUNT=0
FAILURE_COUNT=0
SKIPPED_COUNT=0

################################################################################
# FUNCTIONS
################################################################################

# Print log message with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Print error message to stderr
error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
}

# Print section header
print_header() {
    echo ""
    echo "================================================================================"
    echo "$*"
    echo "================================================================================"
}

# Check if prefix exists in source bucket (has objects)
# Args: $1 = prefix name
# Returns: 0 if exists, 1 if not
check_prefix_exists() {
    local prefix="$1"
    local s3_path="s3://${SOURCE_BUCKET}/${prefix}/"

    log "Checking if prefix exists: ${prefix}"

    # Use aws s3 ls to check for objects under the prefix
    # Check if command returns any output
    local result
    result=$(aws s3 ls "${s3_path}" \
        --profile "${AWS_PROFILE}" \
        --region "${SOURCE_REGION}" 2>&1 | head -1)

    if [[ -n "${result}" ]]; then
        log "✓ Prefix exists and contains objects: ${prefix}"
        return 0
    else
        log "✗ Prefix does not exist or is empty: ${prefix}"
        return 1
    fi
}

# Sync a single prefix from source to destination
# Args: $1 = prefix name
# Returns: 0 on success, 1 on failure
sync_prefix() {
    local prefix="$1"
    local source_path="s3://${SOURCE_BUCKET}/${prefix}/"
    local dest_path="s3://${DEST_BUCKET}/${prefix}/"

    log "Starting sync for prefix: ${prefix}"
    log "  Source: ${source_path} (${SOURCE_REGION})"
    log "  Destination: ${dest_path} (${DEST_REGION})"

    # Build AWS CLI command
    local aws_cmd=(
        aws s3 sync
        "${source_path}"
        "${dest_path}"
        --profile "${AWS_PROFILE}"
        --source-region "${SOURCE_REGION}"
        --region "${DEST_REGION}"
        --exact-timestamps
        --no-follow-symlinks
    )

    # Add dryrun flag if enabled
    if [[ "${DRY_RUN}" == "true" ]]; then
        aws_cmd+=(--dryrun)
        log "  Mode: DRY RUN (no changes will be made)"
    else
        log "  Mode: LIVE (changes will be made)"
    fi

    # Execute sync command
    log "  Executing: ${aws_cmd[*]}"

    if "${aws_cmd[@]}"; then
        log "✓ Successfully synced prefix: ${prefix}"
        return 0
    else
        error "Failed to sync prefix: ${prefix}"
        return 1
    fi
}

################################################################################
# MAIN EXECUTION
################################################################################

print_header "S3 Cross-Account Prefix Promotion"

# Display configuration
log "Configuration:"
log "  DRY_RUN: ${DRY_RUN}"
log "  AWS Profile: ${AWS_PROFILE}"
log "  Source Bucket: ${SOURCE_BUCKET} (Account: ${SOURCE_ACCOUNT}, Region: ${SOURCE_REGION})"
log "  Destination Bucket: ${DEST_BUCKET} (Account: ${DEST_ACCOUNT}, Region: ${DEST_REGION})"
log "  Prefixes to sync: ${#PREFIXES[@]}"

if [[ "${DRY_RUN}" == "true" ]]; then
    print_header "⚠️  DRY RUN MODE - No changes will be made ⚠️"
fi

# Validate AWS CLI and credentials
log "Validating AWS CLI and credentials..."
if ! aws --version &>/dev/null; then
    error "AWS CLI not found. Please install AWS CLI v2."
    exit 1
fi

if ! aws sts get-caller-identity --profile "${AWS_PROFILE}" &>/dev/null; then
    error "Unable to authenticate with AWS profile: ${AWS_PROFILE}"
    error "Please ensure profile is configured and credentials are valid."
    exit 1
fi

CALLER_IDENTITY=$(aws sts get-caller-identity --profile "${AWS_PROFILE}" --query 'Account' --output text)
log "✓ Authenticated as account: ${CALLER_IDENTITY}"

# Process each prefix
print_header "Processing Prefixes"

for prefix in "${PREFIXES[@]}"; do
    echo ""
    log "=========================================="
    log "Processing prefix: ${prefix}"
    log "=========================================="

    # Check if prefix exists in source
    if ! check_prefix_exists "${prefix}"; then
        log "⊘ Skipping prefix (does not exist or is empty): ${prefix}"
        ((SKIPPED_COUNT++))
        continue
    fi

    # Sync the prefix
    if sync_prefix "${prefix}"; then
        ((SUCCESS_COUNT++))
    else
        ((FAILURE_COUNT++))
    fi
done

# Print summary
print_header "Summary"
log "Total prefixes processed: ${#PREFIXES[@]}"
log "  Successful syncs: ${SUCCESS_COUNT}"
log "  Failed syncs: ${FAILURE_COUNT}"
log "  Skipped (not found/empty): ${SKIPPED_COUNT}"

if [[ "${DRY_RUN}" == "true" ]]; then
    echo ""
    log "⚠️  This was a DRY RUN - no actual changes were made"
    log "⚠️  Set DRY_RUN=\"false\" in the script to perform actual sync"
fi

# Exit with appropriate code
if [[ ${FAILURE_COUNT} -gt 0 ]]; then
    error "Script completed with ${FAILURE_COUNT} failure(s)"
    exit 1
else
    log "✓ Script completed successfully"
    exit 0
fi
