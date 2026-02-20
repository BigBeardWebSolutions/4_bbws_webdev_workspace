#!/usr/bin/env python3
"""
S3 Deployment Validation Script - DEV Environment

Validates that all S3 buckets are deployed correctly in DEV environment.

Tests:
- Bucket existence
- Public access blocked (all 4 settings)
- Versioning enabled
- Encryption enabled (SSE-S3 or SSE-KMS)
- Tags applied
- Templates uploaded (if applicable)

Usage:
    python3 validate_s3_dev.py

Exit codes:
    0 - All validations passed
    1 - One or more validations failed
"""

import boto3
import sys
from typing import List, Dict, Any

# Configuration
REGION = 'eu-west-1'
ENVIRONMENT = 'dev'
AWS_ACCOUNT_ID = '536580886816'

# Expected buckets
EXPECTED_BUCKETS = [
    'bbws-templates-dev'
]

# Required tags
REQUIRED_TAGS = [
    'Environment',
    'Project',
    'Owner',
    'CostCenter',
    'ManagedBy',
    'Component',
    'Application'
]

# Expected template files (optional - only if templates should be uploaded during deployment)
EXPECTED_TEMPLATES = [
    'payment_received.html',
    'order_confirmation.html',
    'campaign_notification.html',
    'account_created.html',
    'password_reset.html',
    'email_verification.html',
    'subscription_activated.html',
    'subscription_cancelled.html',
    'trial_expiring.html',
    'invoice_generated.html',
    'support_ticket_created.html',
    'site_provisioned.html'
]


def print_header(message: str):
    """Print formatted header"""
    print(f"\n{'=' * 80}")
    print(f"{message}")
    print(f"{'=' * 80}")


def print_section(message: str):
    """Print formatted section"""
    print(f"\n{'-' * 80}")
    print(f"{message}")
    print(f"{'-' * 80}")


def test_bucket_existence(s3_client, bucket_name: str) -> bool:
    """Test if bucket exists"""
    try:
        s3_client.head_bucket(Bucket=bucket_name)
        print(f"✓ Bucket '{bucket_name}' exists")
        return True
    except s3_client.exceptions.NoSuchBucket:
        print(f"✗ Bucket '{bucket_name}' NOT FOUND")
        return False
    except s3_client.exceptions.ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == '403':
            print(f"✗ Bucket '{bucket_name}' exists but access denied")
        else:
            print(f"✗ Bucket '{bucket_name}' ERROR: {e}")
        return False
    except Exception as e:
        print(f"✗ Bucket '{bucket_name}' ERROR: {e}")
        return False


def test_public_access_blocked(s3_client, bucket_name: str) -> bool:
    """Test that all public access is blocked"""
    try:
        response = s3_client.get_public_access_block(Bucket=bucket_name)
        config = response['PublicAccessBlockConfiguration']

        checks = {
            'BlockPublicAcls': config.get('BlockPublicAcls', False),
            'IgnorePublicAcls': config.get('IgnorePublicAcls', False),
            'BlockPublicPolicy': config.get('BlockPublicPolicy', False),
            'RestrictPublicBuckets': config.get('RestrictPublicBuckets', False)
        }

        if all(checks.values()):
            print(f"✓ Bucket '{bucket_name}' public access: BLOCKED (all 4 settings enabled)")
            return True
        else:
            print(f"✗ Bucket '{bucket_name}' public access NOT fully blocked:")
            for setting, enabled in checks.items():
                status = "✓" if enabled else "✗"
                print(f"    {status} {setting}: {enabled}")
            return False
    except s3_client.exceptions.NoSuchPublicAccessBlockConfiguration:
        print(f"✗ Bucket '{bucket_name}' has NO public access block configuration")
        return False
    except Exception as e:
        print(f"✗ Error checking public access block for '{bucket_name}': {e}")
        return False


def test_versioning(s3_client, bucket_name: str) -> bool:
    """Test that versioning is enabled"""
    try:
        response = s3_client.get_bucket_versioning(Bucket=bucket_name)
        status = response.get('Status', 'Disabled')

        if status == 'Enabled':
            print(f"✓ Bucket '{bucket_name}' versioning: ENABLED")
            return True
        else:
            print(f"✗ Bucket '{bucket_name}' versioning: {status} (expected Enabled)")
            return False
    except Exception as e:
        print(f"✗ Error checking versioning for '{bucket_name}': {e}")
        return False


def test_encryption(s3_client, bucket_name: str) -> bool:
    """Test that encryption is enabled"""
    try:
        response = s3_client.get_bucket_encryption(Bucket=bucket_name)
        rules = response.get('ServerSideEncryptionConfiguration', {}).get('Rules', [])

        if rules:
            algorithm = rules[0]['ApplyServerSideEncryptionByDefault']['SSEAlgorithm']
            print(f"✓ Bucket '{bucket_name}' encryption: ENABLED ({algorithm})")
            return True
        else:
            print(f"✗ Bucket '{bucket_name}' encryption: NO RULES found")
            return False
    except s3_client.exceptions.ServerSideEncryptionConfigurationNotFoundError:
        print(f"✗ Bucket '{bucket_name}' encryption: NOT CONFIGURED")
        return False
    except Exception as e:
        print(f"✗ Error checking encryption for '{bucket_name}': {e}")
        return False


def test_tags(s3_client, bucket_name: str, required_tags: List[str]) -> bool:
    """Test required tags are present"""
    try:
        response = s3_client.get_bucket_tagging(Bucket=bucket_name)
        tags = response.get('TagSet', [])
        tag_dict = {tag['Key']: tag['Value'] for tag in tags}

        missing_tags = [tag for tag in required_tags if tag not in tag_dict]

        if not missing_tags:
            print(f"✓ Bucket '{bucket_name}' has all required tags")
            for key, value in sorted(tag_dict.items()):
                print(f"    {key}: {value}")
            return True
        else:
            print(f"✗ Bucket '{bucket_name}' missing tags: {', '.join(missing_tags)}")
            print(f"  Found tags: {list(tag_dict.keys())}")
            return False
    except s3_client.exceptions.NoSuchTagSet:
        print(f"✗ Bucket '{bucket_name}' has NO tags configured")
        return False
    except Exception as e:
        print(f"✗ Error checking tags for '{bucket_name}': {e}")
        return False


def test_templates(s3_client, bucket_name: str, expected_templates: List[str]) -> bool:
    """Test that templates are uploaded (optional)"""
    try:
        response = s3_client.list_objects_v2(Bucket=bucket_name, Prefix='templates/')

        if 'Contents' not in response:
            print(f"⚠ Bucket '{bucket_name}' has NO templates uploaded (this may be expected if templates are uploaded separately)")
            return True  # Don't fail - templates might be uploaded later

        objects = response['Contents']
        uploaded_files = [obj['Key'].replace('templates/', '') for obj in objects if obj['Key'] != 'templates/']

        missing_templates = set(expected_templates) - set(uploaded_files)

        if not missing_templates:
            print(f"✓ Bucket '{bucket_name}' has all {len(expected_templates)} templates uploaded")
            return True
        else:
            print(f"⚠ Bucket '{bucket_name}' missing templates (may be uploaded later):")
            print(f"  Missing: {', '.join(list(missing_templates)[:5])}" + (" ..." if len(missing_templates) > 5 else ""))
            return True  # Don't fail - templates might be uploaded later
    except Exception as e:
        print(f"⚠ Error checking templates for '{bucket_name}': {e}")
        return True  # Don't fail on this check


def test_bucket_location(s3_client, bucket_name: str, expected_region: str) -> bool:
    """Test bucket is in the correct region"""
    try:
        response = s3_client.get_bucket_location(Bucket=bucket_name)
        location = response['LocationConstraint']

        # us-east-1 returns None
        actual_region = location if location else 'us-east-1'

        if actual_region == expected_region:
            print(f"✓ Bucket '{bucket_name}' region: {actual_region}")
            return True
        else:
            print(f"✗ Bucket '{bucket_name}' region: {actual_region} (expected {expected_region})")
            return False
    except Exception as e:
        print(f"✗ Error checking bucket location for '{bucket_name}': {e}")
        return False


def validate_bucket(s3_client, bucket_name: str) -> bool:
    """Run all validations for a single bucket"""
    print_section(f"VALIDATING BUCKET: {bucket_name}")

    results = []

    # Test 1: Bucket existence
    if not test_bucket_existence(s3_client, bucket_name):
        return False  # If bucket doesn't exist, skip other tests

    # Test 2: Public access blocked
    results.append(test_public_access_blocked(s3_client, bucket_name))

    # Test 3: Versioning enabled
    results.append(test_versioning(s3_client, bucket_name))

    # Test 4: Encryption enabled
    results.append(test_encryption(s3_client, bucket_name))

    # Test 5: Tags
    results.append(test_tags(s3_client, bucket_name, REQUIRED_TAGS))

    # Test 6: Bucket location
    results.append(test_bucket_location(s3_client, bucket_name, REGION))

    # Test 7: Templates (optional - doesn't fail validation)
    test_templates(s3_client, bucket_name, EXPECTED_TEMPLATES)

    # Summary for this bucket
    total_tests = len(results)
    passed_tests = sum(results)

    print(f"\nBucket '{bucket_name}' validation: {passed_tests}/{total_tests} tests passed")

    return all(results)


def main():
    """Main validation function"""
    print_header(f"S3 VALIDATION - {ENVIRONMENT.upper()} ENVIRONMENT")
    print(f"Region: {REGION}")
    print(f"AWS Account: {AWS_ACCOUNT_ID}")
    print(f"Expected Buckets: {len(EXPECTED_BUCKETS)}")

    # Initialize boto3 client
    try:
        s3 = boto3.client('s3', region_name=REGION)

        # Verify AWS account
        sts = boto3.client('sts', region_name=REGION)
        account_id = sts.get_caller_identity()['Account']

        if account_id != AWS_ACCOUNT_ID:
            print(f"\n❌ ERROR: Connected to wrong AWS account!")
            print(f"   Expected: {AWS_ACCOUNT_ID}")
            print(f"   Actual: {account_id}")
            sys.exit(1)

        print(f"✓ Connected to AWS account: {account_id}")

    except Exception as e:
        print(f"\n❌ ERROR: Failed to initialize AWS client: {e}")
        sys.exit(1)

    # Validate each bucket
    all_passed = True
    bucket_results = []

    for bucket_name in EXPECTED_BUCKETS:
        passed = validate_bucket(s3, bucket_name)
        bucket_results.append((bucket_name, passed))
        if not passed:
            all_passed = False

    # Final summary
    print_header("VALIDATION SUMMARY")

    for bucket_name, passed in bucket_results:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status} - {bucket_name}")

    total_buckets = len(bucket_results)
    passed_buckets = sum(1 for _, passed in bucket_results if passed)

    print(f"\nOverall: {passed_buckets}/{total_buckets} buckets validated successfully")

    if all_passed:
        print("\n✅ ALL S3 VALIDATIONS PASSED")
        sys.exit(0)
    else:
        print("\n❌ SOME S3 VALIDATIONS FAILED")
        print("Review the errors above and fix the infrastructure code")
        sys.exit(1)


if __name__ == '__main__':
    main()
