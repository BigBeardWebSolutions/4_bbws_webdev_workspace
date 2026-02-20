#!/bin/bash

################################################################################
# Setup S3 Migration Buckets for Each Environment
################################################################################
#
# Purpose: Create S3 buckets for staging migration artifacts (scripts, files, SQL)
# Benefit: Eliminates ECS exec heredoc issues and enables reliable large file transfers
#
################################################################################

set -e

echo "========================================================================"
echo "  Setting Up S3 Migration Artifact Buckets"
echo "========================================================================"
echo ""

# Environment configurations
declare -A ENV_CONFIG=(
    [dev]="Tebogo-dev eu-west-1 536580886816"
    [sit]="Tebogo-sit eu-west-1 815856636111"
    [prod]="Tebogo-prod af-south-1 093646564004"
)

for env in dev sit prod; do
    read -r profile region account <<< "${ENV_CONFIG[$env]}"

    BUCKET_NAME="bbws-migration-artifacts-${env}"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Environment: ${env}"
    echo "Bucket: ${BUCKET_NAME}"
    echo "Region: ${region}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Check if bucket exists
    if aws s3 ls "s3://${BUCKET_NAME}" --profile "$profile" 2>/dev/null; then
        echo "✅ Bucket already exists: ${BUCKET_NAME}"
    else
        echo "📦 Creating bucket: ${BUCKET_NAME}..."

        if [ "$region" = "us-east-1" ]; then
            # us-east-1 doesn't need LocationConstraint
            aws s3 mb "s3://${BUCKET_NAME}" \
                --profile "$profile" \
                --region "$region"
        else
            aws s3api create-bucket \
                --bucket "${BUCKET_NAME}" \
                --region "${region}" \
                --create-bucket-configuration LocationConstraint="${region}" \
                --profile "$profile"
        fi

        echo "✅ Bucket created: ${BUCKET_NAME}"
    fi

    # Enable versioning for rollback capability
    echo "🔄 Enabling versioning..."
    aws s3api put-bucket-versioning \
        --bucket "${BUCKET_NAME}" \
        --versioning-configuration Status=Enabled \
        --profile "$profile"

    echo "✅ Versioning enabled"

    # Enable encryption
    echo "🔒 Enabling encryption..."
    aws s3api put-bucket-encryption \
        --bucket "${BUCKET_NAME}" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                },
                "BucketKeyEnabled": true
            }]
        }' \
        --profile "$profile"

    echo "✅ Encryption enabled (AES256)"

    # Block public access
    echo "🛡️  Configuring public access block..."
    aws s3api put-public-access-block \
        --bucket "${BUCKET_NAME}" \
        --public-access-block-configuration \
            "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
        --profile "$profile"

    echo "✅ Public access blocked"

    # Create lifecycle policy to clean up old artifacts
    echo "🗑️  Configuring lifecycle policy..."
    aws s3api put-bucket-lifecycle-configuration \
        --bucket "${BUCKET_NAME}" \
        --lifecycle-configuration '{
            "Rules": [{
                "Id": "DeleteOldMigrationArtifacts",
                "Status": "Enabled",
                "Filter": {},
                "Expiration": {
                    "Days": 90
                },
                "NoncurrentVersionExpiration": {
                    "NoncurrentDays": 30
                }
            }]
        }' \
        --profile "$profile"

    echo "✅ Lifecycle policy configured (90-day retention)"

    # Add bucket policy for ECS task role access
    echo "🔑 Configuring bucket policy for ECS tasks..."
    aws s3api put-bucket-policy \
        --bucket "${BUCKET_NAME}" \
        --policy "{
            \"Version\": \"2012-10-17\",
            \"Statement\": [{
                \"Sid\": \"AllowECSTaskAccess\",
                \"Effect\": \"Allow\",
                \"Principal\": {
                    \"AWS\": \"arn:aws:iam::${account}:role/ecsTaskRole\"
                },
                \"Action\": [
                    \"s3:GetObject\",
                    \"s3:ListBucket\"
                ],
                \"Resource\": [
                    \"arn:aws:s3:::${BUCKET_NAME}\",
                    \"arn:aws:s3:::${BUCKET_NAME}/*\"
                ]
            }]
        }" \
        --profile "$profile"

    echo "✅ Bucket policy configured"

    # Create folder structure
    echo "📁 Creating folder structure..."
    for folder in scripts sql mu-plugins files database; do
        aws s3api put-object \
            --bucket "${BUCKET_NAME}" \
            --key "_templates/${folder}/" \
            --profile "$profile" > /dev/null
    done

    echo "✅ Folder structure created"

    # Test access from local machine
    echo "🧪 Testing bucket access..."
    test_file="/tmp/test-${env}.txt"
    echo "Test file for ${env} environment" > "$test_file"

    aws s3 cp "$test_file" "s3://${BUCKET_NAME}/_test/test.txt" --profile "$profile"
    aws s3 rm "s3://${BUCKET_NAME}/_test/test.txt" --profile "$profile"
    rm "$test_file"

    echo "✅ Bucket access verified"
    echo ""
done

echo "========================================================================"
echo "✅ S3 Migration Buckets Setup Complete!"
echo "========================================================================"
echo ""
echo "Buckets Created:"
echo "  • s3://bbws-migration-artifacts-dev (eu-west-1)"
echo "  • s3://bbws-migration-artifacts-sit (eu-west-1)"
echo "  • s3://bbws-migration-artifacts-prod (af-south-1)"
echo ""
echo "Features Enabled:"
echo "  ✅ Versioning (for rollback)"
echo "  ✅ AES256 encryption"
echo "  ✅ Public access blocked"
echo "  ✅ 90-day lifecycle policy"
echo "  ✅ ECS task access policy"
echo ""
echo "Folder Structure:"
echo "  /_templates/scripts/     - Deployment scripts"
echo "  /_templates/sql/         - SQL fix scripts"
echo "  /_templates/mu-plugins/  - WordPress MU-plugins"
echo "  /_templates/files/       - Large file staging"
echo "  /_templates/database/    - Database dumps"
echo ""
echo "Usage in Migration:"
echo "  1. Upload artifacts: aws s3 sync templates/ s3://bbws-migration-artifacts-dev/{tenant}/"
echo "  2. Download in ECS:  aws s3 sync s3://bbws-migration-artifacts-dev/{tenant}/ /tmp/migration/"
echo "  3. Execute scripts:  /tmp/migration/scripts/deploy.sh"
echo ""
echo "Next Steps:"
echo "  1. Update migration scripts to use S3 staging"
echo "  2. Test with next tenant migration"
echo "  3. Monitor CloudWatch for S3 access logs"
echo ""
