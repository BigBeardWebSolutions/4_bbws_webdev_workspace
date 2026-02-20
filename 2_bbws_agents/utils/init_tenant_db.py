#!/usr/bin/env python3
"""
Initialize tenant database for BBWS multi-tenant WordPress platform.
This script is called by Terraform during tenant provisioning.

Usage:
    python3 init_tenant_db.py \
        --tenant-name <name> \
        --environment <env> \
        --secret-arn <arn> \
        --region <region> \
        --profile <profile>
"""

import argparse
import json
import os
import sys
import time
import boto3
from botocore.exceptions import ClientError


def get_secret(secret_id, region, profile=None):
    """Retrieve secret from AWS Secrets Manager."""
    session = boto3.Session(profile_name=profile, region_name=region)
    client = session.client('secretsmanager')

    try:
        response = client.get_secret_value(SecretId=secret_id)
        return json.loads(response['SecretString'])
    except ClientError as e:
        print(f"Error retrieving secret {secret_id}: {e}", file=sys.stderr)
        raise


def run_ecs_task(cluster, task_definition, command, subnets, security_groups, region, profile=None):
    """Run an ECS Fargate task and wait for completion."""
    session = boto3.Session(profile_name=profile, region_name=region)
    ecs = session.client('ecs')
    logs = session.client('logs')

    # Run task
    print(f"Running ECS task {task_definition} on cluster {cluster}...")
    try:
        response = ecs.run_task(
            cluster=cluster,
            taskDefinition=task_definition,
            launchType='FARGATE',
            networkConfiguration={
                'awsvpcConfiguration': {
                    'subnets': subnets,
                    'securityGroups': security_groups,
                    'assignPublicIp': 'DISABLED'
                }
            },
            overrides={
                'containerOverrides': [{
                    'name': 'db-init',
                    'command': command
                }]
            }
        )

        if not response.get('tasks'):
            print("ERROR: No tasks were created", file=sys.stderr)
            return False

        task_arn = response['tasks'][0]['taskArn']
        task_id = task_arn.split('/')[-1]
        print(f"Task started: {task_id}")

        # Wait for task to complete
        print("Waiting for task to complete...")
        waiter = ecs.get_waiter('tasks_stopped')
        waiter.wait(
            cluster=cluster,
            tasks=[task_arn],
            WaiterConfig={'Delay': 5, 'MaxAttempts': 60}
        )

        # Check task exit code
        response = ecs.describe_tasks(cluster=cluster, tasks=[task_arn])
        if response['tasks']:
            task = response['tasks'][0]
            containers = task.get('containers', [])
            if containers:
                exit_code = containers[0].get('exitCode', 1)
                if exit_code != 0:
                    print(f"ERROR: Task exited with code {exit_code}", file=sys.stderr)
                    # Try to get logs
                    try:
                        log_group = f"/ecs/{cluster.split('-')[0]}"
                        log_stream = f"db-init/db-init/{task_id}"
                        print(f"\nTask logs from {log_group}/{log_stream}:")
                        response = logs.get_log_events(
                            logGroupName=log_group,
                            logStreamName=log_stream,
                            startFromHead=True
                        )
                        for event in response.get('events', []):
                            print(event['message'])
                    except Exception as e:
                        print(f"Could not retrieve logs: {e}", file=sys.stderr)
                    return False
                print(f"Task completed successfully (exit code {exit_code})")
                return True

        print("ERROR: Could not determine task status", file=sys.stderr)
        return False

    except ClientError as e:
        print(f"Error running ECS task: {e}", file=sys.stderr)
        return False


def create_database(tenant_name, environment, tenant_secret, master_secret, region, profile):
    """Create database and user for tenant."""

    # Extract database info
    db_name = tenant_secret['database']
    db_user = tenant_secret['username']
    db_pass = tenant_secret['password']
    db_host = tenant_secret['host']

    master_user = master_secret['username']
    master_pass = master_secret['password']

    print(f"\n=== Creating database for tenant '{tenant_name}' in {environment.upper()} ===")
    print(f"Database: {db_name}")
    print(f"User: {db_user}")
    print(f"Host: {db_host}")

    # Get infrastructure details based on environment
    cluster = f"{environment}-cluster"
    task_definition = f"{environment}-db-init"

    # Get VPC subnets and security groups
    session = boto3.Session(profile_name=profile, region_name=region)
    ec2 = session.client('ec2')

    # Find private subnets
    subnets_response = ec2.describe_subnets(
        Filters=[
            {'Name': 'tag:Environment', 'Values': [environment]},
            {'Name': 'tag:Type', 'Values': ['Private']},
            {'Name': 'tag:Name', 'Values': [f'{environment}-private-subnet-*']}
        ]
    )
    subnets = [s['SubnetId'] for s in subnets_response['Subnets']]
    if not subnets:
        print("ERROR: No private subnets found", file=sys.stderr)
        return False

    # Find ECS security group
    sg_response = ec2.describe_security_groups(
        Filters=[
            {'Name': 'tag:Environment', 'Values': [environment]},
            {'Name': 'tag:Name', 'Values': [f'{environment}-ecs-tasks-sg']}
        ]
    )
    security_groups = [sg['GroupId'] for sg in sg_response['SecurityGroups']]
    if not security_groups:
        print("ERROR: No ECS security group found", file=sys.stderr)
        return False

    print(f"Using subnet: {subnets[0]}")
    print(f"Using security group: {security_groups[0]}")

    # Create SQL command
    sql = f"""
CREATE DATABASE IF NOT EXISTS {db_name} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '{db_user}'@'%' IDENTIFIED BY '{db_pass}';
GRANT ALL PRIVILEGES ON {db_name}.* TO '{db_user}'@'%';
FLUSH PRIVILEGES;
SELECT 'Database {db_name} created successfully' AS Status;
"""

    # Build ECS task command
    command = [
        'sh', '-c',
        f"mysql -h {db_host} -u {master_user} -p'{master_pass}' <<'SQL'\n{sql}\nSQL\n"
    ]

    # Run ECS task
    success = run_ecs_task(
        cluster=cluster,
        task_definition=task_definition,
        command=command,
        subnets=[subnets[0]],
        security_groups=[security_groups[0]],
        region=region,
        profile=profile
    )

    if success:
        print(f"\n✓ Database '{db_name}' created successfully!")
        return True
    else:
        print(f"\n✗ Failed to create database '{db_name}'", file=sys.stderr)
        return False


def main():
    parser = argparse.ArgumentParser(description='Initialize tenant database')
    parser.add_argument('--tenant-name', required=True, help='Tenant name')
    parser.add_argument('--environment', required=True, help='Environment (dev/sit/prod)')
    parser.add_argument('--secret-arn', required=True, help='Tenant database secret ARN')
    parser.add_argument('--region', required=True, help='AWS region')
    parser.add_argument('--profile', help='AWS profile name')

    args = parser.parse_args()

    try:
        # Get tenant credentials
        print(f"Retrieving tenant credentials from {args.secret_arn}...")
        tenant_secret = get_secret(args.secret_arn, args.region, args.profile)

        # Get master credentials
        master_secret_id = f"{args.environment}-rds-master-credentials"
        print(f"Retrieving master credentials from {master_secret_id}...")
        master_secret = get_secret(master_secret_id, args.region, args.profile)

        # Create database
        success = create_database(
            tenant_name=args.tenant_name,
            environment=args.environment,
            tenant_secret=tenant_secret,
            master_secret=master_secret,
            region=args.region,
            profile=args.profile
        )

        sys.exit(0 if success else 1)

    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
