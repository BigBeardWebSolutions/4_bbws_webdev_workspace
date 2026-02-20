#!/usr/bin/env python3
"""
DynamoDB Deployment Validation Script - DEV Environment

Validates that all DynamoDB tables are deployed correctly in DEV environment.

Tests:
- Table existence
- Table status (ACTIVE)
- Primary key configuration (PK, SK)
- Global Secondary Indexes (GSIs)
- Point-in-Time Recovery (PITR) enabled
- Streams enabled
- Tags applied
- ON_DEMAND billing mode

Usage:
    python3 validate_dynamodb_dev.py

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

# Expected tables
EXPECTED_TABLES = [
    {
        'name': 'tenants',
        'pk': 'PK',
        'sk': 'SK',
        'gsis': ['EmailIndex', 'TenantStatusIndex', 'ActiveIndex']
    },
    {
        'name': 'products',
        'pk': 'PK',
        'sk': 'SK',
        'gsis': ['ProductActiveIndex', 'ActiveIndex']
    },
    {
        'name': 'campaigns',
        'pk': 'PK',
        'sk': 'SK',
        'gsis': ['CampaignActiveIndex', 'CampaignProductIndex', 'ActiveIndex']
    }
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


def test_table_existence(dynamodb_client, table_name: str) -> bool:
    """Test if table exists"""
    try:
        response = dynamodb_client.describe_table(TableName=table_name)
        print(f"✓ Table '{table_name}' exists")
        return True
    except dynamodb_client.exceptions.ResourceNotFoundException:
        print(f"✗ Table '{table_name}' NOT FOUND")
        return False
    except Exception as e:
        print(f"✗ Table '{table_name}' ERROR: {e}")
        return False


def test_table_status(dynamodb_client, table_name: str) -> bool:
    """Test if table is ACTIVE"""
    try:
        response = dynamodb_client.describe_table(TableName=table_name)
        status = response['Table']['TableStatus']

        if status == 'ACTIVE':
            print(f"✓ Table '{table_name}' status: {status}")
            return True
        else:
            print(f"✗ Table '{table_name}' status: {status} (expected ACTIVE)")
            return False
    except Exception as e:
        print(f"✗ Error checking status for '{table_name}': {e}")
        return False


def test_primary_key(dynamodb_client, table_name: str, expected_pk: str, expected_sk: str) -> bool:
    """Test primary key configuration"""
    try:
        response = dynamodb_client.describe_table(TableName=table_name)
        key_schema = response['Table']['KeySchema']

        pk_found = False
        sk_found = False

        for key in key_schema:
            if key['KeyType'] == 'HASH' and key['AttributeName'] == expected_pk:
                pk_found = True
            if key['KeyType'] == 'RANGE' and key['AttributeName'] == expected_sk:
                sk_found = True

        if pk_found and sk_found:
            print(f"✓ Table '{table_name}' has correct primary key (PK: {expected_pk}, SK: {expected_sk})")
            return True
        else:
            print(f"✗ Table '{table_name}' primary key mismatch")
            print(f"  Expected PK: {expected_pk}, SK: {expected_sk}")
            print(f"  Found: {key_schema}")
            return False
    except Exception as e:
        print(f"✗ Error checking primary key for '{table_name}': {e}")
        return False


def test_gsis(dynamodb_client, table_name: str, expected_gsis: List[str]) -> bool:
    """Test Global Secondary Indexes"""
    try:
        response = dynamodb_client.describe_table(TableName=table_name)
        gsis = response['Table'].get('GlobalSecondaryIndexes', [])

        actual_gsi_names = [gsi['IndexName'] for gsi in gsis]

        missing_gsis = set(expected_gsis) - set(actual_gsi_names)
        extra_gsis = set(actual_gsi_names) - set(expected_gsis)

        if not missing_gsis and not extra_gsis:
            print(f"✓ Table '{table_name}' has correct GSIs: {', '.join(expected_gsis)}")
            return True
        else:
            print(f"✗ Table '{table_name}' GSI mismatch")
            if missing_gsis:
                print(f"  Missing GSIs: {', '.join(missing_gsis)}")
            if extra_gsis:
                print(f"  Extra GSIs: {', '.join(extra_gsis)}")
            print(f"  Found GSIs: {', '.join(actual_gsi_names)}")
            return False
    except Exception as e:
        print(f"✗ Error checking GSIs for '{table_name}': {e}")
        return False


def test_pitr(dynamodb_client, table_name: str) -> bool:
    """Test Point-in-Time Recovery enabled"""
    try:
        response = dynamodb_client.describe_continuous_backups(TableName=table_name)
        pitr_status = response['ContinuousBackupsDescription']['PointInTimeRecoveryDescription']['PointInTimeRecoveryStatus']

        if pitr_status == 'ENABLED':
            print(f"✓ Table '{table_name}' PITR: {pitr_status}")
            return True
        else:
            print(f"✗ Table '{table_name}' PITR: {pitr_status} (expected ENABLED)")
            return False
    except Exception as e:
        print(f"✗ Error checking PITR for '{table_name}': {e}")
        return False


def test_streams(dynamodb_client, table_name: str) -> bool:
    """Test DynamoDB Streams enabled"""
    try:
        response = dynamodb_client.describe_table(TableName=table_name)
        stream_spec = response['Table'].get('StreamSpecification', {})

        stream_enabled = stream_spec.get('StreamEnabled', False)
        stream_view_type = stream_spec.get('StreamViewType', '')

        if stream_enabled and stream_view_type == 'NEW_AND_OLD_IMAGES':
            print(f"✓ Table '{table_name}' Streams: ENABLED ({stream_view_type})")
            return True
        else:
            print(f"✗ Table '{table_name}' Streams: {'ENABLED' if stream_enabled else 'DISABLED'}")
            if stream_enabled:
                print(f"  Stream view type: {stream_view_type} (expected NEW_AND_OLD_IMAGES)")
            return False
    except Exception as e:
        print(f"✗ Error checking streams for '{table_name}': {e}")
        return False


def test_billing_mode(dynamodb_client, table_name: str) -> bool:
    """Test ON_DEMAND billing mode"""
    try:
        response = dynamodb_client.describe_table(TableName=table_name)
        billing_mode = response['Table'].get('BillingModeSummary', {}).get('BillingMode', 'PROVISIONED')

        if billing_mode == 'PAY_PER_REQUEST':
            print(f"✓ Table '{table_name}' billing mode: ON_DEMAND")
            return True
        else:
            print(f"✗ Table '{table_name}' billing mode: {billing_mode} (expected PAY_PER_REQUEST)")
            return False
    except Exception as e:
        print(f"✗ Error checking billing mode for '{table_name}': {e}")
        return False


def test_tags(dynamodb_client, table_name: str, required_tags: List[str]) -> bool:
    """Test required tags are present"""
    try:
        response = dynamodb_client.describe_table(TableName=table_name)
        table_arn = response['Table']['TableArn']

        tags_response = dynamodb_client.list_tags_of_resource(ResourceArn=table_arn)
        tags = tags_response.get('Tags', [])
        tag_dict = {tag['Key']: tag['Value'] for tag in tags}

        missing_tags = [tag for tag in required_tags if tag not in tag_dict]

        if not missing_tags:
            print(f"✓ Table '{table_name}' has all required tags")
            for key, value in sorted(tag_dict.items()):
                print(f"    {key}: {value}")
            return True
        else:
            print(f"✗ Table '{table_name}' missing tags: {', '.join(missing_tags)}")
            print(f"  Found tags: {list(tag_dict.keys())}")
            return False
    except Exception as e:
        print(f"✗ Error checking tags for '{table_name}': {e}")
        return False


def validate_table(dynamodb_client, table_config: Dict[str, Any]) -> bool:
    """Run all validations for a single table"""
    table_name = table_config['name']

    print_section(f"VALIDATING TABLE: {table_name}")

    results = []

    # Test 1: Table existence
    if not test_table_existence(dynamodb_client, table_name):
        return False  # If table doesn't exist, skip other tests

    # Test 2: Table status
    results.append(test_table_status(dynamodb_client, table_name))

    # Test 3: Primary key
    results.append(test_primary_key(dynamodb_client, table_name, table_config['pk'], table_config['sk']))

    # Test 4: GSIs
    results.append(test_gsis(dynamodb_client, table_name, table_config['gsis']))

    # Test 5: PITR
    results.append(test_pitr(dynamodb_client, table_name))

    # Test 6: Streams
    results.append(test_streams(dynamodb_client, table_name))

    # Test 7: Billing mode
    results.append(test_billing_mode(dynamodb_client, table_name))

    # Test 8: Tags
    results.append(test_tags(dynamodb_client, table_name, REQUIRED_TAGS))

    # Summary for this table
    total_tests = len(results)
    passed_tests = sum(results)

    print(f"\nTable '{table_name}' validation: {passed_tests}/{total_tests} tests passed")

    return all(results)


def main():
    """Main validation function"""
    print_header(f"DYNAMODB VALIDATION - {ENVIRONMENT.upper()} ENVIRONMENT")
    print(f"Region: {REGION}")
    print(f"AWS Account: {AWS_ACCOUNT_ID}")
    print(f"Expected Tables: {len(EXPECTED_TABLES)}")

    # Initialize boto3 client
    try:
        dynamodb = boto3.client('dynamodb', region_name=REGION)

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

    # Validate each table
    all_passed = True
    table_results = []

    for table_config in EXPECTED_TABLES:
        passed = validate_table(dynamodb, table_config)
        table_results.append((table_config['name'], passed))
        if not passed:
            all_passed = False

    # Final summary
    print_header("VALIDATION SUMMARY")

    for table_name, passed in table_results:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status} - {table_name}")

    total_tables = len(table_results)
    passed_tables = sum(1 for _, passed in table_results if passed)

    print(f"\nOverall: {passed_tables}/{total_tables} tables validated successfully")

    if all_passed:
        print("\n✅ ALL DYNAMODB VALIDATIONS PASSED")
        sys.exit(0)
    else:
        print("\n❌ SOME DYNAMODB VALIDATIONS FAILED")
        print("Review the errors above and fix the infrastructure code")
        sys.exit(1)


if __name__ == '__main__':
    main()
