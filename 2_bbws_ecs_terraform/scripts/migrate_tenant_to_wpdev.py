#!/usr/bin/env python3
"""
Tenant Migration Script: nip.io → wpdev.kimmyai.io
Migrates WordPress tenants from nip.io wildcard DNS to wpdev.kimmyai.io subdomains.

Usage:
    python3 migrate_tenant_to_wpdev.py --tenant sunsetbistro --priority 31
    python3 migrate_tenant_to_wpdev.py --tenant sunsetbistro --priority 31 --dry-run
    python3 migrate_tenant_to_wpdev.py --tenant sunsetbistro --priority 31 --rollback
"""

import boto3
import json
import argparse
import time
import sys
import subprocess
from datetime import datetime
from typing import Dict, List, Optional, Tuple


class TenantMigrator:
    """Handles migration of a single tenant from nip.io to wpdev.kimmyai.io."""

    def __init__(
        self,
        tenant: str,
        priority: int,
        cluster: str = "dev-cluster",
        region: str = "eu-west-1",
        profile: str = "Tebogo-dev",
        dry_run: bool = False,
        rollback: bool = False
    ):
        """Initialize the migrator with tenant configuration."""
        self.tenant = tenant
        self.priority = priority
        self.cluster = cluster
        self.region = region
        self.profile = profile
        self.dry_run = dry_run
        self.rollback = rollback

        # Tenant name mapping (ALB name -> ECS name)
        # Some tenants have different naming in ALB vs ECS
        self.tenant_name_map = {
            'tenant1': 'tenant-1',
            'tenant2': 'tenant-2'
        }

        # Get ECS tenant name (may differ from ALB tenant name)
        self.ecs_tenant = self.tenant_name_map.get(tenant, tenant)

        # Initialize AWS session and clients
        self.session = boto3.Session(profile_name=profile, region_name=region)
        self.elbv2_client = self.session.client('elbv2')
        self.ecs_client = self.session.client('ecs')

        # Constants
        self.alb_dns = "dev-alb-875048671.eu-west-1.elb.amazonaws.com"
        self.listener_arn = "arn:aws:elasticloadbalancing:eu-west-1:536580886816:listener/app/dev-alb/c64f306951ce5b3e/28e2efebd09d8591"

        # Logging
        self.log_file = f"/tmp/migration_{tenant}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"

    def log(self, message: str, level: str = "INFO"):
        """Log message to console and file."""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[{timestamp}] [{level}] {message}"
        print(log_entry)

        with open(self.log_file, 'a') as f:
            f.write(log_entry + "\n")

    def get_rule_arn_by_priority(self) -> Optional[str]:
        """Get ALB listener rule ARN by priority."""
        self.log(f"Looking up ALB rule with priority {self.priority}")

        try:
            response = self.elbv2_client.describe_rules(ListenerArn=self.listener_arn)

            for rule in response['Rules']:
                if rule['Priority'] == str(self.priority):
                    rule_arn = rule['RuleArn']
                    self.log(f"Found rule ARN: {rule_arn}")
                    return rule_arn

            self.log(f"No rule found with priority {self.priority}", "ERROR")
            return None

        except Exception as e:
            self.log(f"Error getting rule ARN: {str(e)}", "ERROR")
            return None

    def update_alb_rule(self, rule_arn: str) -> bool:
        """Update ALB listener rule to use wpdev.kimmyai.io or rollback to nip.io."""
        if self.rollback:
            # Rollback to nip.io
            host_values = [
                f"{self.tenant}.*.nip.io",
                f"{self.tenant}.localhost",
                f"{self.tenant}.*"
            ]
            self.log(f"ROLLBACK: Reverting ALB rule to nip.io patterns")
        else:
            # Migrate to wpdev.kimmyai.io
            host_values = [f"{self.tenant}.wpdev.kimmyai.io"]
            self.log(f"Updating ALB rule to wpdev.kimmyai.io")

        conditions = [{
            "Field": "host-header",
            "HostHeaderConfig": {
                "Values": host_values
            }
        }]

        if self.dry_run:
            self.log(f"DRY-RUN: Would update rule {rule_arn} with conditions: {json.dumps(conditions, indent=2)}")
            return True

        try:
            self.elbv2_client.modify_rule(
                RuleArn=rule_arn,
                Conditions=conditions
            )
            self.log(f"✅ Successfully updated ALB rule")
            return True

        except Exception as e:
            self.log(f"❌ Error updating ALB rule: {str(e)}", "ERROR")
            return False

    def get_current_task_definition(self) -> Optional[Dict]:
        """Fetch current ECS task definition."""
        task_family = f"dev-{self.ecs_tenant}"
        self.log(f"Fetching task definition: {task_family}")

        try:
            response = self.ecs_client.describe_task_definition(taskDefinition=task_family)
            task_def = response['taskDefinition']

            self.log(f"Current task definition revision: {task_def['revision']}")
            return task_def

        except Exception as e:
            self.log(f"Error fetching task definition: {str(e)}", "ERROR")
            return None

    def update_task_definition(self, task_def: Dict) -> Optional[str]:
        """Update task definition with WordPress config and register new revision."""
        self.log("Updating task definition with WordPress configuration")

        # Remove fields that shouldn't be in registration
        for key in ['taskDefinitionArn', 'revision', 'status', 'requiresAttributes',
                    'compatibilities', 'registeredAt', 'registeredBy']:
            task_def.pop(key, None)

        # WordPress configuration
        if self.rollback:
            # Rollback: Remove WP_HOME and WP_SITEURL, disable FORCE_SSL_ADMIN
            wp_config = """
/* Disable HTTPS redirects for POC */
define('FORCE_SSL_ADMIN', false);
define('FORCE_SSL_LOGIN', false);
$_SERVER['HTTPS'] = 'off';

/* Fix for load balancer */
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}
"""
            self.log("ROLLBACK: Reverting WordPress config to nip.io mode")
        else:
            # Migrate: Add WP_HOME and WP_SITEURL
            wp_config = f"""if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {{
    $_SERVER['HTTPS'] = 'on';
}}
if (isset($_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO']) && $_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO'] === 'https') {{
    $_SERVER['HTTPS'] = 'on';
}}
define('FORCE_SSL_ADMIN', true);
define('WP_HOME', 'https://{self.tenant}.wpdev.kimmyai.io');
define('WP_SITEURL', 'https://{self.tenant}.wpdev.kimmyai.io');"""
            self.log(f"Setting WP_HOME and WP_SITEURL to https://{self.tenant}.wpdev.kimmyai.io")

        # Find and update WORDPRESS_CONFIG_EXTRA
        container_def = task_def['containerDefinitions'][0]

        # Check if WORDPRESS_CONFIG_EXTRA exists
        config_exists = False
        for env_var in container_def.get('environment', []):
            if env_var['name'] == 'WORDPRESS_CONFIG_EXTRA':
                env_var['value'] = wp_config
                config_exists = True
                self.log("Updated existing WORDPRESS_CONFIG_EXTRA")
                break

        # If it doesn't exist, add it
        if not config_exists:
            if 'environment' not in container_def:
                container_def['environment'] = []
            container_def['environment'].append({
                'name': 'WORDPRESS_CONFIG_EXTRA',
                'value': wp_config
            })
            self.log("Added new WORDPRESS_CONFIG_EXTRA")

        if self.dry_run:
            self.log("DRY-RUN: Would register new task definition")
            return f"dev-{self.tenant}:DRY-RUN"

        # Register new task definition
        try:
            response = self.ecs_client.register_task_definition(**task_def)
            new_revision = response['taskDefinition']['revision']
            new_arn = response['taskDefinition']['taskDefinitionArn']

            self.log(f"✅ Registered new task definition: revision {new_revision}")
            return new_arn

        except Exception as e:
            self.log(f"❌ Error registering task definition: {str(e)}", "ERROR")
            return None

    def update_ecs_service(self, task_def_arn: str) -> bool:
        """Update ECS service with new task definition."""
        service_name = f"dev-{self.ecs_tenant}-service"
        self.log(f"Updating ECS service: {service_name}")

        if self.dry_run:
            self.log(f"DRY-RUN: Would update service {service_name} with task definition {task_def_arn}")
            return True

        try:
            # Update service
            self.ecs_client.update_service(
                cluster=self.cluster,
                service=service_name,
                taskDefinition=task_def_arn,
                forceNewDeployment=True
            )
            self.log(f"Service update initiated, waiting for stability...")

            # Wait for service to stabilize
            waiter = self.ecs_client.get_waiter('services_stable')
            waiter.wait(
                cluster=self.cluster,
                services=[service_name],
                WaiterConfig={'Delay': 15, 'MaxAttempts': 40}  # 10 minutes max
            )

            self.log(f"✅ Service is stable")
            return True

        except Exception as e:
            self.log(f"❌ Error updating service: {str(e)}", "ERROR")
            return False

    def test_migration(self) -> Dict[str, bool]:
        """Test the migrated tenant."""
        self.log("Testing migrated tenant...")
        results = {
            'dns': False,
            'cloudfront_https': False,
            'alb_http': False
        }

        domain = f"{self.tenant}.wpdev.kimmyai.io"

        # Test 1: DNS resolution
        try:
            dns_result = subprocess.run(
                ['dig', '+short', domain],
                capture_output=True,
                text=True,
                timeout=10
            )
            if dns_result.stdout.strip():
                self.log(f"✅ DNS resolves: {dns_result.stdout.strip()}")
                results['dns'] = True
            else:
                self.log(f"❌ DNS resolution failed", "ERROR")
        except Exception as e:
            self.log(f"❌ DNS test error: {str(e)}", "ERROR")

        # Test 2: HTTPS via CloudFront (expect 401 with basic auth)
        try:
            https_result = subprocess.run(
                ['curl', '-s', '-o', '/dev/null', '-w', '%{http_code}', f'https://{domain}'],
                capture_output=True,
                text=True,
                timeout=10
            )
            http_code = https_result.stdout.strip()
            if http_code in ['401', '200', '302']:
                self.log(f"✅ HTTPS via CloudFront: HTTP {http_code}")
                results['cloudfront_https'] = True
            else:
                self.log(f"⚠️  HTTPS via CloudFront: HTTP {http_code}", "WARNING")
        except Exception as e:
            self.log(f"❌ HTTPS test error: {str(e)}", "ERROR")

        # Test 3: HTTP via ALB direct (expect 200)
        try:
            alb_result = subprocess.run(
                ['curl', '-s', '-o', '/dev/null', '-w', '%{http_code}',
                 '-H', f'Host: {domain}', f'http://{self.alb_dns}/'],
                capture_output=True,
                text=True,
                timeout=10
            )
            http_code = alb_result.stdout.strip()
            if http_code == '200':
                self.log(f"✅ HTTP via ALB: HTTP {http_code}")
                results['alb_http'] = True
            else:
                self.log(f"⚠️  HTTP via ALB: HTTP {http_code}", "WARNING")
        except Exception as e:
            self.log(f"❌ ALB test error: {str(e)}", "ERROR")

        return results

    def migrate(self) -> bool:
        """Execute full migration workflow."""
        action = "ROLLBACK" if self.rollback else "MIGRATION"
        mode = "DRY-RUN " if self.dry_run else ""

        self.log("=" * 80)
        self.log(f"{mode}{action}: {self.tenant} (Priority {self.priority})")
        self.log("=" * 80)

        # Step 1: Get ALB rule ARN
        rule_arn = self.get_rule_arn_by_priority()
        if not rule_arn:
            self.log(f"❌ {action} FAILED: Could not find ALB rule", "ERROR")
            return False

        # Step 2: Update ALB rule
        if not self.update_alb_rule(rule_arn):
            self.log(f"❌ {action} FAILED: ALB rule update failed", "ERROR")
            return False

        # Step 3: Get current task definition
        task_def = self.get_current_task_definition()
        if not task_def:
            self.log(f"❌ {action} FAILED: Could not fetch task definition", "ERROR")
            return False

        # Step 4: Update and register new task definition
        new_task_def_arn = self.update_task_definition(task_def)
        if not new_task_def_arn:
            self.log(f"❌ {action} FAILED: Task definition registration failed", "ERROR")
            return False

        # Step 5: Update ECS service
        if not self.update_ecs_service(new_task_def_arn):
            self.log(f"❌ {action} FAILED: ECS service update failed", "ERROR")
            return False

        # Step 6: Test migration (skip for dry-run and rollback)
        if not self.dry_run and not self.rollback:
            time.sleep(5)  # Brief pause before testing
            test_results = self.test_migration()

            if all(test_results.values()):
                self.log(f"✅ All tests passed!")
            else:
                self.log(f"⚠️  Some tests failed: {test_results}", "WARNING")

        # Summary
        self.log("=" * 80)
        self.log(f"✅ {action} COMPLETED SUCCESSFULLY")
        self.log(f"Log file: {self.log_file}")
        self.log("=" * 80)

        return True


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Migrate WordPress tenant from nip.io to wpdev.kimmyai.io'
    )
    parser.add_argument('--tenant', required=True, help='Tenant name (e.g., sunsetbistro)')
    parser.add_argument('--priority', required=True, type=int, help='ALB listener rule priority')
    parser.add_argument('--cluster', default='dev-cluster', help='ECS cluster name')
    parser.add_argument('--region', default='eu-west-1', help='AWS region')
    parser.add_argument('--profile', default='Tebogo-dev', help='AWS profile name')
    parser.add_argument('--dry-run', action='store_true', help='Preview changes without applying')
    parser.add_argument('--rollback', action='store_true', help='Rollback to nip.io configuration')

    args = parser.parse_args()

    # Create migrator
    migrator = TenantMigrator(
        tenant=args.tenant,
        priority=args.priority,
        cluster=args.cluster,
        region=args.region,
        profile=args.profile,
        dry_run=args.dry_run,
        rollback=args.rollback
    )

    # Execute migration
    success = migrator.migrate()

    # Exit with appropriate code
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
