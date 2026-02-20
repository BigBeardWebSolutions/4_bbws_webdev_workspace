#!/usr/bin/env python3
"""
Tenant Migration Utility with Rollback Support

A general-purpose utility for migrating WordPress tenants between configurations
with automatic rollback capability on failure.

Usage:
    # Migrate single tenant
    python tenant_migration.py migrate --tenant goldencrust --from-config old.json --to-config new.json

    # Migrate multiple tenants
    python tenant_migration.py migrate-batch --tenants tenant1,tenant2,tenant3 --from-config old.json --to-config new.json

    # Rollback a migration
    python tenant_migration.py rollback --tenant goldencrust --migration-id abc123

    # Dry run mode
    python tenant_migration.py migrate --tenant goldencrust --from-config old.json --to-config new.json --dry-run

Features:
    - Multi-step migration with validation
    - Automatic rollback on failure
    - State tracking and logging
    - Dry-run mode for testing
    - Batch migration support
    - Environment-agnostic (dev/sit/prod)

Author: Big Beard Web Solutions
"""

import argparse
import boto3
import json
import logging
import sys
import time
import uuid
from datetime import datetime
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, asdict
from enum import Enum


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s: %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)


class MigrationStatus(Enum):
    """Migration status states"""
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"
    ROLLED_BACK = "rolled_back"


class MigrationStep(Enum):
    """Migration steps"""
    VALIDATION = "validation"
    BACKUP = "backup"
    ALB_UPDATE = "alb_update"
    TASK_DEFINITION_UPDATE = "task_definition_update"
    SERVICE_UPDATE = "service_update"
    DNS_UPDATE = "dns_update"
    VERIFICATION = "verification"


@dataclass
class MigrationConfig:
    """Migration configuration"""
    # ALB Configuration
    alb_listener_arn: Optional[str] = None
    alb_rule_priority: Optional[int] = None
    old_host_header: Optional[str] = None
    new_host_header: Optional[str] = None

    # ECS Configuration
    cluster: Optional[str] = None
    service_prefix: Optional[str] = None

    # Task Definition Updates
    task_definition_updates: Optional[Dict] = None

    # DNS Configuration
    route53_zone_id: Optional[str] = None
    old_dns_record: Optional[str] = None
    new_dns_record: Optional[str] = None
    dns_target: Optional[str] = None

    # WordPress Configuration
    wordpress_config_updates: Optional[Dict] = None

    # Environment
    region: str = "eu-west-1"
    aws_profile: Optional[str] = None


@dataclass
class MigrationState:
    """Migration state tracking"""
    migration_id: str
    tenant: str
    status: MigrationStatus
    started_at: str
    completed_at: Optional[str] = None
    steps_completed: List[str] = None
    rollback_data: Dict = None
    error_message: Optional[str] = None

    def __post_init__(self):
        if self.steps_completed is None:
            self.steps_completed = []
        if self.rollback_data is None:
            self.rollback_data = {}


class TenantMigrator:
    """Handles tenant migration with rollback support"""

    def __init__(self, tenant: str, from_config: MigrationConfig, to_config: MigrationConfig,
                 dry_run: bool = False, migration_id: Optional[str] = None):
        self.tenant = tenant
        self.from_config = from_config
        self.to_config = to_config
        self.dry_run = dry_run

        # Generate or use provided migration ID
        self.migration_id = migration_id or f"migration-{tenant}-{uuid.uuid4().hex[:8]}"

        # Initialize AWS clients
        session = boto3.Session(
            profile_name=to_config.aws_profile,
            region_name=to_config.region
        )
        self.ecs_client = session.client('ecs')
        self.elbv2_client = session.client('elbv2')
        self.route53_client = session.client('route53')

        # Initialize state
        self.state = MigrationState(
            migration_id=self.migration_id,
            tenant=tenant,
            status=MigrationStatus.PENDING,
            started_at=datetime.utcnow().isoformat()
        )

        # Tenant name mapping for ECS vs ALB naming differences
        self.tenant_name_map = {
            'tenant1': 'tenant-1',
            'tenant2': 'tenant-2'
        }
        self.ecs_tenant = self.tenant_name_map.get(tenant, tenant)

    def migrate(self) -> Tuple[bool, MigrationState]:
        """
        Execute migration with automatic rollback on failure.

        Returns:
            Tuple of (success, state)
        """
        logger.info(f"{'[DRY RUN] ' if self.dry_run else ''}Starting migration for tenant: {self.tenant}")
        logger.info(f"Migration ID: {self.migration_id}")

        try:
            self.state.status = MigrationStatus.IN_PROGRESS
            self._save_state()

            # Execute migration steps
            steps = [
                (MigrationStep.VALIDATION, self._validate_prerequisites),
                (MigrationStep.BACKUP, self._backup_current_state),
                (MigrationStep.ALB_UPDATE, self._update_alb_listener_rule),
                (MigrationStep.TASK_DEFINITION_UPDATE, self._update_task_definition),
                (MigrationStep.SERVICE_UPDATE, self._update_ecs_service),
                (MigrationStep.DNS_UPDATE, self._update_dns_record),
                (MigrationStep.VERIFICATION, self._verify_migration),
            ]

            for step, func in steps:
                logger.info(f"{'[DRY RUN] ' if self.dry_run else ''}Executing step: {step.value}")
                success = func()

                if not success:
                    raise Exception(f"Step {step.value} failed")

                self.state.steps_completed.append(step.value)
                self._save_state()

            # Migration successful
            self.state.status = MigrationStatus.COMPLETED
            self.state.completed_at = datetime.utcnow().isoformat()
            self._save_state()

            logger.info(f"✅ Migration completed successfully for tenant: {self.tenant}")
            return True, self.state

        except Exception as e:
            logger.error(f"❌ Migration failed: {str(e)}")
            self.state.status = MigrationStatus.FAILED
            self.state.error_message = str(e)
            self._save_state()

            # Attempt rollback
            if not self.dry_run:
                logger.warning("Initiating automatic rollback...")
                self.rollback()

            return False, self.state

    def rollback(self) -> bool:
        """
        Rollback migration to previous state.

        Returns:
            True if rollback successful, False otherwise
        """
        logger.info(f"{'[DRY RUN] ' if self.dry_run else ''}Starting rollback for tenant: {self.tenant}")
        logger.info(f"Migration ID: {self.migration_id}")

        try:
            # Rollback in reverse order of completed steps
            for step in reversed(self.state.steps_completed):
                logger.info(f"{'[DRY RUN] ' if self.dry_run else ''}Rolling back step: {step}")

                if step == MigrationStep.DNS_UPDATE.value:
                    self._rollback_dns_record()
                elif step == MigrationStep.SERVICE_UPDATE.value:
                    self._rollback_ecs_service()
                elif step == MigrationStep.TASK_DEFINITION_UPDATE.value:
                    self._rollback_task_definition()
                elif step == MigrationStep.ALB_UPDATE.value:
                    self._rollback_alb_listener_rule()

            self.state.status = MigrationStatus.ROLLED_BACK
            self.state.completed_at = datetime.utcnow().isoformat()
            self._save_state()

            logger.info(f"✅ Rollback completed successfully for tenant: {self.tenant}")
            return True

        except Exception as e:
            logger.error(f"❌ Rollback failed: {str(e)}")
            logger.error("Manual intervention required!")
            return False

    def _validate_prerequisites(self) -> bool:
        """Validate that all required resources exist"""
        logger.info("Validating prerequisites...")

        try:
            # Validate ECS service exists
            if self.to_config.cluster and self.to_config.service_prefix:
                service_name = f"{self.to_config.service_prefix}-{self.ecs_tenant}-service"

                if not self.dry_run:
                    response = self.ecs_client.describe_services(
                        cluster=self.to_config.cluster,
                        services=[service_name]
                    )

                    if not response['services'] or response['services'][0]['status'] != 'ACTIVE':
                        logger.error(f"Service {service_name} not found or not active")
                        return False

            # Validate ALB listener exists
            if self.to_config.alb_listener_arn:
                if not self.dry_run:
                    self.elbv2_client.describe_listeners(
                        ListenerArns=[self.to_config.alb_listener_arn]
                    )

            # Validate Route53 zone exists
            if self.to_config.route53_zone_id:
                if not self.dry_run:
                    self.route53_client.get_hosted_zone(
                        Id=self.to_config.route53_zone_id
                    )

            logger.info("✅ All prerequisites validated")
            return True

        except Exception as e:
            logger.error(f"Prerequisite validation failed: {str(e)}")
            return False

    def _backup_current_state(self) -> bool:
        """Backup current configuration for rollback"""
        logger.info("Backing up current state...")

        try:
            # Backup ALB listener rule
            if self.to_config.alb_listener_arn and not self.dry_run:
                response = self.elbv2_client.describe_rules(
                    ListenerArn=self.to_config.alb_listener_arn
                )

                # Find rule for this tenant
                for rule in response['Rules']:
                    if rule.get('Priority') and str(rule['Priority']) == str(self.to_config.alb_rule_priority):
                        self.state.rollback_data['alb_rule'] = {
                            'RuleArn': rule['RuleArn'],
                            'Conditions': rule['Conditions'],
                            'Actions': rule['Actions']
                        }
                        break

            # Backup ECS service
            if self.to_config.cluster and self.to_config.service_prefix and not self.dry_run:
                service_name = f"{self.to_config.service_prefix}-{self.ecs_tenant}-service"
                response = self.ecs_client.describe_services(
                    cluster=self.to_config.cluster,
                    services=[service_name]
                )

                if response['services']:
                    service = response['services'][0]
                    self.state.rollback_data['ecs_service'] = {
                        'taskDefinition': service['taskDefinition']
                    }

            # Backup DNS record
            if self.to_config.route53_zone_id and self.from_config.old_dns_record and not self.dry_run:
                response = self.route53_client.list_resource_record_sets(
                    HostedZoneId=self.to_config.route53_zone_id,
                    StartRecordName=self.from_config.old_dns_record,
                    MaxItems='1'
                )

                if response['ResourceRecordSets']:
                    self.state.rollback_data['dns_record'] = response['ResourceRecordSets'][0]

            logger.info("✅ Current state backed up")
            return True

        except Exception as e:
            logger.error(f"Backup failed: {str(e)}")
            return False

    def _update_alb_listener_rule(self) -> bool:
        """Update ALB listener rule with new host header"""
        if not self.to_config.new_host_header:
            logger.info("Skipping ALB update (no new host header specified)")
            return True

        logger.info(f"Updating ALB listener rule: {self.from_config.old_host_header} → {self.to_config.new_host_header}")

        if self.dry_run:
            logger.info("[DRY RUN] Would update ALB listener rule")
            return True

        try:
            response = self.elbv2_client.describe_rules(
                ListenerArn=self.to_config.alb_listener_arn
            )

            rule_arn = None
            for rule in response['Rules']:
                if rule.get('Priority') and str(rule['Priority']) == str(self.to_config.alb_rule_priority):
                    rule_arn = rule['RuleArn']
                    break

            if not rule_arn:
                logger.error(f"Rule with priority {self.to_config.alb_rule_priority} not found")
                return False

            # Update rule condition
            self.elbv2_client.modify_rule(
                RuleArn=rule_arn,
                Conditions=[{
                    'Field': 'host-header',
                    'HostHeaderConfig': {
                        'Values': [self.to_config.new_host_header]
                    }
                }]
            )

            logger.info("✅ ALB listener rule updated")
            return True

        except Exception as e:
            logger.error(f"ALB update failed: {str(e)}")
            return False

    def _update_task_definition(self) -> bool:
        """Update ECS task definition with new configuration"""
        if not self.to_config.task_definition_updates:
            logger.info("Skipping task definition update (no updates specified)")
            return True

        logger.info("Updating task definition...")

        if self.dry_run:
            logger.info("[DRY RUN] Would update task definition")
            return True

        try:
            service_name = f"{self.to_config.service_prefix}-{self.ecs_tenant}-service"

            # Get current task definition
            service_response = self.ecs_client.describe_services(
                cluster=self.to_config.cluster,
                services=[service_name]
            )

            current_task_def_arn = service_response['services'][0]['taskDefinition']

            task_def_response = self.ecs_client.describe_task_definition(
                taskDefinition=current_task_def_arn
            )

            task_def = task_def_response['taskDefinition']

            # Apply updates to task definition
            new_task_def = {
                'family': task_def['family'],
                'taskRoleArn': task_def.get('taskRoleArn'),
                'executionRoleArn': task_def.get('executionRoleArn'),
                'networkMode': task_def['networkMode'],
                'containerDefinitions': task_def['containerDefinitions'],
                'volumes': task_def.get('volumes', []),
                'requiresCompatibilities': task_def['requiresCompatibilities'],
                'cpu': task_def['cpu'],
                'memory': task_def['memory']
            }

            # Update container environment variables
            for update_key, update_value in self.to_config.task_definition_updates.items():
                for container in new_task_def['containerDefinitions']:
                    for env_var in container.get('environment', []):
                        if env_var['name'] == update_key:
                            env_var['value'] = update_value

            # Register new task definition
            response = self.ecs_client.register_task_definition(**new_task_def)
            new_task_def_arn = response['taskDefinition']['taskDefinitionArn']

            self.state.rollback_data['new_task_definition'] = new_task_def_arn

            logger.info(f"✅ Task definition updated: {new_task_def_arn}")
            return True

        except Exception as e:
            logger.error(f"Task definition update failed: {str(e)}")
            return False

    def _update_ecs_service(self) -> bool:
        """Update ECS service to use new task definition"""
        logger.info("Updating ECS service...")

        if self.dry_run:
            logger.info("[DRY RUN] Would update ECS service")
            return True

        try:
            service_name = f"{self.to_config.service_prefix}-{self.ecs_tenant}-service"

            # Get new task definition ARN
            new_task_def_arn = self.state.rollback_data.get('new_task_definition')

            if new_task_def_arn:
                # Update service with new task definition
                self.ecs_client.update_service(
                    cluster=self.to_config.cluster,
                    service=service_name,
                    taskDefinition=new_task_def_arn,
                    forceNewDeployment=True
                )
            else:
                # Just force new deployment
                self.ecs_client.update_service(
                    cluster=self.to_config.cluster,
                    service=service_name,
                    forceNewDeployment=True
                )

            logger.info("✅ ECS service updated")

            # Wait for service to stabilize (optional, can be long)
            logger.info("Waiting for service to stabilize (this may take a few minutes)...")
            waiter = self.ecs_client.get_waiter('services_stable')

            try:
                waiter.wait(
                    cluster=self.to_config.cluster,
                    services=[service_name],
                    WaiterConfig={'Delay': 15, 'MaxAttempts': 40}
                )
                logger.info("✅ Service stabilized")
            except Exception as e:
                logger.warning(f"Service did not stabilize within timeout: {str(e)}")
                logger.warning("Service may still be deploying, check manually")

            return True

        except Exception as e:
            logger.error(f"ECS service update failed: {str(e)}")
            return False

    def _update_dns_record(self) -> bool:
        """Update Route53 DNS record"""
        if not self.to_config.new_dns_record:
            logger.info("Skipping DNS update (no new DNS record specified)")
            return True

        logger.info(f"Updating DNS record: {self.from_config.old_dns_record} → {self.to_config.new_dns_record}")

        if self.dry_run:
            logger.info("[DRY RUN] Would update DNS record")
            return True

        try:
            # Delete old record if it exists
            if self.from_config.old_dns_record:
                try:
                    old_record = self.state.rollback_data.get('dns_record')
                    if old_record:
                        self.route53_client.change_resource_record_sets(
                            HostedZoneId=self.to_config.route53_zone_id,
                            ChangeBatch={
                                'Changes': [{
                                    'Action': 'DELETE',
                                    'ResourceRecordSet': old_record
                                }]
                            }
                        )
                        logger.info(f"Deleted old DNS record: {self.from_config.old_dns_record}")
                except Exception as e:
                    logger.warning(f"Could not delete old DNS record: {str(e)}")

            # Create new record
            self.route53_client.change_resource_record_sets(
                HostedZoneId=self.to_config.route53_zone_id,
                ChangeBatch={
                    'Changes': [{
                        'Action': 'UPSERT',
                        'ResourceRecordSet': {
                            'Name': self.to_config.new_dns_record,
                            'Type': 'A',
                            'AliasTarget': {
                                'HostedZoneId': 'Z2FDTNDATAQYW2',  # CloudFront zone ID
                                'DNSName': self.to_config.dns_target,
                                'EvaluateTargetHealth': False
                            }
                        }
                    }]
                }
            )

            logger.info("✅ DNS record updated")
            return True

        except Exception as e:
            logger.error(f"DNS update failed: {str(e)}")
            return False

    def _verify_migration(self) -> bool:
        """Verify migration was successful"""
        logger.info("Verifying migration...")

        if self.dry_run:
            logger.info("[DRY RUN] Would verify migration")
            return True

        try:
            # Verify ECS service is running
            service_name = f"{self.to_config.service_prefix}-{self.ecs_tenant}-service"
            response = self.ecs_client.describe_services(
                cluster=self.to_config.cluster,
                services=[service_name]
            )

            if not response['services']:
                logger.error("Service not found")
                return False

            service = response['services'][0]
            running_count = service['runningCount']
            desired_count = service['desiredCount']

            if running_count != desired_count:
                logger.warning(f"Service not fully healthy: {running_count}/{desired_count} tasks running")
            else:
                logger.info(f"✅ Service healthy: {running_count}/{desired_count} tasks running")

            # Verify ALB targets are healthy
            if self.to_config.alb_listener_arn:
                response = self.elbv2_client.describe_rules(
                    ListenerArn=self.to_config.alb_listener_arn
                )

                for rule in response['Rules']:
                    if rule.get('Priority') and str(rule['Priority']) == str(self.to_config.alb_rule_priority):
                        for action in rule['Actions']:
                            if action['Type'] == 'forward':
                                target_group_arn = action['TargetGroupArn']

                                health_response = self.elbv2_client.describe_target_health(
                                    TargetGroupArn=target_group_arn
                                )

                                healthy_targets = sum(1 for t in health_response['TargetHealthDescriptions']
                                                     if t['TargetHealth']['State'] == 'healthy')
                                total_targets = len(health_response['TargetHealthDescriptions'])

                                logger.info(f"ALB target health: {healthy_targets}/{total_targets} healthy")
                        break

            logger.info("✅ Migration verification complete")
            return True

        except Exception as e:
            logger.error(f"Verification failed: {str(e)}")
            return False

    def _rollback_alb_listener_rule(self):
        """Rollback ALB listener rule"""
        logger.info("Rolling back ALB listener rule...")

        if self.dry_run:
            logger.info("[DRY RUN] Would rollback ALB listener rule")
            return

        try:
            rule_data = self.state.rollback_data.get('alb_rule')
            if rule_data:
                self.elbv2_client.modify_rule(
                    RuleArn=rule_data['RuleArn'],
                    Conditions=rule_data['Conditions']
                )
                logger.info("✅ ALB listener rule rolled back")
        except Exception as e:
            logger.error(f"ALB rollback failed: {str(e)}")

    def _rollback_task_definition(self):
        """Rollback task definition (no action needed, old version still exists)"""
        logger.info("Task definition rollback not needed (old version preserved)")

    def _rollback_ecs_service(self):
        """Rollback ECS service to previous task definition"""
        logger.info("Rolling back ECS service...")

        if self.dry_run:
            logger.info("[DRY RUN] Would rollback ECS service")
            return

        try:
            service_data = self.state.rollback_data.get('ecs_service')
            if service_data:
                service_name = f"{self.to_config.service_prefix}-{self.ecs_tenant}-service"

                self.ecs_client.update_service(
                    cluster=self.to_config.cluster,
                    service=service_name,
                    taskDefinition=service_data['taskDefinition'],
                    forceNewDeployment=True
                )
                logger.info("✅ ECS service rolled back")
        except Exception as e:
            logger.error(f"ECS service rollback failed: {str(e)}")

    def _rollback_dns_record(self):
        """Rollback DNS record"""
        logger.info("Rolling back DNS record...")

        if self.dry_run:
            logger.info("[DRY RUN] Would rollback DNS record")
            return

        try:
            # Delete new record
            if self.to_config.new_dns_record:
                self.route53_client.change_resource_record_sets(
                    HostedZoneId=self.to_config.route53_zone_id,
                    ChangeBatch={
                        'Changes': [{
                            'Action': 'DELETE',
                            'ResourceRecordSet': {
                                'Name': self.to_config.new_dns_record,
                                'Type': 'A',
                                'AliasTarget': {
                                    'HostedZoneId': 'Z2FDTNDATAQYW2',
                                    'DNSName': self.to_config.dns_target,
                                    'EvaluateTargetHealth': False
                                }
                            }
                        }]
                    }
                )

            # Restore old record
            old_record = self.state.rollback_data.get('dns_record')
            if old_record:
                self.route53_client.change_resource_record_sets(
                    HostedZoneId=self.to_config.route53_zone_id,
                    ChangeBatch={
                        'Changes': [{
                            'Action': 'UPSERT',
                            'ResourceRecordSet': old_record
                        }]
                    }
                )

            logger.info("✅ DNS record rolled back")
        except Exception as e:
            logger.error(f"DNS rollback failed: {str(e)}")

    def _save_state(self):
        """Save migration state to file"""
        state_file = f"/tmp/{self.migration_id}.json"

        try:
            with open(state_file, 'w') as f:
                state_dict = asdict(self.state)
                state_dict['status'] = self.state.status.value
                json.dump(state_dict, f, indent=2)

            logger.debug(f"State saved to {state_file}")
        except Exception as e:
            logger.warning(f"Could not save state: {str(e)}")


def load_config(config_file: str) -> MigrationConfig:
    """Load migration configuration from JSON file"""
    try:
        with open(config_file, 'r') as f:
            config_data = json.load(f)
        return MigrationConfig(**config_data)
    except Exception as e:
        logger.error(f"Failed to load config from {config_file}: {str(e)}")
        sys.exit(1)


def load_state(migration_id: str) -> Optional[MigrationState]:
    """Load migration state from file"""
    state_file = f"/tmp/{migration_id}.json"

    try:
        with open(state_file, 'r') as f:
            state_data = json.load(f)

        state_data['status'] = MigrationStatus(state_data['status'])
        return MigrationState(**state_data)
    except FileNotFoundError:
        logger.error(f"Migration state not found: {migration_id}")
        return None
    except Exception as e:
        logger.error(f"Failed to load state: {str(e)}")
        return None


def main():
    parser = argparse.ArgumentParser(
        description='Tenant Migration Utility with Rollback Support',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Migrate single tenant
  python tenant_migration.py migrate --tenant goldencrust \\
      --from-config old.json --to-config new.json

  # Migrate with dry-run
  python tenant_migration.py migrate --tenant goldencrust \\
      --from-config old.json --to-config new.json --dry-run

  # Rollback migration
  python tenant_migration.py rollback --migration-id migration-goldencrust-abc12345

  # Migrate multiple tenants
  python tenant_migration.py migrate-batch \\
      --tenants tenant1,tenant2,tenant3 \\
      --from-config old.json --to-config new.json
        """
    )

    subparsers = parser.add_subparsers(dest='command', help='Command to execute')

    # Migrate command
    migrate_parser = subparsers.add_parser('migrate', help='Migrate a single tenant')
    migrate_parser.add_argument('--tenant', required=True, help='Tenant name')
    migrate_parser.add_argument('--from-config', required=True, help='Source configuration JSON file')
    migrate_parser.add_argument('--to-config', required=True, help='Target configuration JSON file')
    migrate_parser.add_argument('--dry-run', action='store_true', help='Perform dry run without making changes')

    # Migrate batch command
    batch_parser = subparsers.add_parser('migrate-batch', help='Migrate multiple tenants')
    batch_parser.add_argument('--tenants', required=True, help='Comma-separated list of tenant names')
    batch_parser.add_argument('--from-config', required=True, help='Source configuration JSON file')
    batch_parser.add_argument('--to-config', required=True, help='Target configuration JSON file')
    batch_parser.add_argument('--dry-run', action='store_true', help='Perform dry run without making changes')

    # Rollback command
    rollback_parser = subparsers.add_parser('rollback', help='Rollback a migration')
    rollback_parser.add_argument('--migration-id', required=True, help='Migration ID to rollback')

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    if args.command == 'migrate':
        # Load configurations
        from_config = load_config(args.from_config)
        to_config = load_config(args.to_config)

        # Execute migration
        migrator = TenantMigrator(args.tenant, from_config, to_config, args.dry_run)
        success, state = migrator.migrate()

        if success:
            logger.info(f"Migration successful! Migration ID: {state.migration_id}")
            sys.exit(0)
        else:
            logger.error(f"Migration failed! Migration ID: {state.migration_id}")
            sys.exit(1)

    elif args.command == 'migrate-batch':
        # Load configurations
        from_config = load_config(args.from_config)
        to_config = load_config(args.to_config)

        # Parse tenant list
        tenants = [t.strip() for t in args.tenants.split(',')]

        logger.info(f"Migrating {len(tenants)} tenants: {', '.join(tenants)}")

        results = []
        for tenant in tenants:
            logger.info(f"\n{'='*60}")
            logger.info(f"Migrating tenant: {tenant}")
            logger.info(f"{'='*60}\n")

            migrator = TenantMigrator(tenant, from_config, to_config, args.dry_run)
            success, state = migrator.migrate()

            results.append({
                'tenant': tenant,
                'success': success,
                'migration_id': state.migration_id
            })

        # Summary
        logger.info(f"\n{'='*60}")
        logger.info("MIGRATION BATCH SUMMARY")
        logger.info(f"{'='*60}\n")

        successful = sum(1 for r in results if r['success'])
        failed = len(results) - successful

        logger.info(f"Total: {len(results)} tenants")
        logger.info(f"Successful: {successful}")
        logger.info(f"Failed: {failed}")

        for result in results:
            status = "✅ SUCCESS" if result['success'] else "❌ FAILED"
            logger.info(f"{result['tenant']}: {status} (ID: {result['migration_id']})")

        sys.exit(0 if failed == 0 else 1)

    elif args.command == 'rollback':
        # Load state
        state = load_state(args.migration_id)

        if not state:
            logger.error("Cannot rollback: migration state not found")
            sys.exit(1)

        # Load configurations (from state rollback data)
        # Note: For full rollback, you'd need to save configs in state
        logger.warning("Rollback requires original configuration files")
        logger.warning("This is a simplified rollback based on saved state")

        # Create minimal config for rollback
        to_config = MigrationConfig()

        migrator = TenantMigrator(state.tenant, to_config, to_config, migration_id=args.migration_id)
        migrator.state = state

        success = migrator.rollback()

        if success:
            logger.info("Rollback successful!")
            sys.exit(0)
        else:
            logger.error("Rollback failed!")
            sys.exit(1)


if __name__ == '__main__':
    main()
