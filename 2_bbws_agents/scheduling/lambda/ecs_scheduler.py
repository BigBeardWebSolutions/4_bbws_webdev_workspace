"""
ECS Scheduled Stop/Start Lambda Function

Stops or starts all ECS services in a cluster on a schedule.
- Stop: saves current desired_count to DynamoDB, sets to 0
- Start: reads saved count from DynamoDB, restores (defaults to 1)
- Sends SNS summary notification on stop only (morning starts are silent)
"""

import json
import logging
import os
import time
from datetime import datetime, timezone, timedelta

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

DYNAMO_TABLE = os.environ["DYNAMO_TABLE"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
TTL_DAYS = 90

ecs = boto3.client("ecs")
dynamodb = boto3.resource("dynamodb")
sns = boto3.client("sns")
table = dynamodb.Table(DYNAMO_TABLE)

SAST = timezone(timedelta(hours=2))


def handler(event, context):
    """Lambda entry point. Expects event with action, cluster_name, region, service_prefixes."""
    action = event["action"]  # "stop" or "start"
    cluster_name = event["cluster_name"]
    region = event.get("region", os.environ.get("AWS_REGION", "eu-west-1"))
    service_prefixes = event.get("service_prefixes", [])

    logger.info("Action=%s cluster=%s region=%s prefixes=%s",
                action, cluster_name, region, service_prefixes)

    service_arns = list_all_services(cluster_name)
    logger.info("Found %d total services in cluster %s", len(service_arns), cluster_name)

    # Filter by prefix if specified
    if service_prefixes:
        service_arns = filter_services_by_prefix(service_arns, service_prefixes)
        logger.info("Filtered to %d services matching prefixes: %s",
                    len(service_arns), service_prefixes)

    if not service_arns:
        if action == "stop":
            send_notification(action, cluster_name, [], [], "No services found in cluster")
        return {"statusCode": 200, "body": "No services found"}

    succeeded = []
    failed = []

    for arn in service_arns:
        try:
            if action == "stop":
                stop_service(cluster_name, arn)
            elif action == "start":
                start_service(cluster_name, arn)
            else:
                raise ValueError(f"Unknown action: {action}")
            succeeded.append(arn)
        except Exception:
            logger.exception("Failed to %s service %s", action, arn)
            failed.append(arn)

    # Send notifications for both stop and start actions
    send_notification(action, cluster_name, succeeded, failed)

    return {
        "statusCode": 200,
        "body": json.dumps({
            "action": action,
            "cluster": cluster_name,
            "succeeded": len(succeeded),
            "failed": len(failed),
        }),
    }


def list_all_services(cluster_name):
    """List all service ARNs in the cluster, handling pagination."""
    arns = []
    paginator = ecs.get_paginator("list_services")
    for page in paginator.paginate(cluster=cluster_name):
        arns.extend(page.get("serviceArns", []))
    return arns


def filter_services_by_prefix(service_arns, prefixes):
    """Filter service ARNs to only those matching any of the given prefixes.

    Service ARN format: arn:aws:ecs:region:account:service/cluster/service-name
    We extract the service name and check if it starts with any prefix.
    """
    if not prefixes:
        return service_arns

    filtered = []
    for arn in service_arns:
        # Extract service name from ARN (last component after /)
        service_name = arn.split("/")[-1]
        # Check if service name starts with any of the prefixes
        if any(service_name.startswith(prefix) for prefix in prefixes):
            filtered.append(arn)
    return filtered


def stop_service(cluster_name, service_arn):
    """Save current desired_count to DynamoDB, then set to 0."""
    desc = ecs.describe_services(cluster=cluster_name, services=[service_arn])
    service = desc["services"][0]
    current_count = service["desiredCount"]
    service_name = service["serviceName"]

    if current_count == 0:
        logger.info("Service %s already at 0, skipping", service_name)
        return

    # Save state to DynamoDB
    ttl = int(time.time()) + (TTL_DAYS * 86400)
    table.put_item(Item={
        "service_arn": service_arn,
        "cluster_name": cluster_name,
        "service_name": service_name,
        "desired_count": current_count,
        "stopped_at": datetime.now(SAST).isoformat(),
        "ttl": ttl,
    })
    logger.info("Saved state for %s: desired_count=%d", service_name, current_count)

    # Set desired count to 0
    ecs.update_service(
        cluster=cluster_name,
        service=service_arn,
        desiredCount=0,
    )
    logger.info("Stopped service %s (was %d)", service_name, current_count)


def start_service(cluster_name, service_arn):
    """Read saved desired_count from DynamoDB and restore. Defaults to 1."""
    desc = ecs.describe_services(cluster=cluster_name, services=[service_arn])
    service = desc["services"][0]
    service_name = service["serviceName"]

    if service["desiredCount"] > 0:
        logger.info("Service %s already running (count=%d), skipping",
                     service_name, service["desiredCount"])
        return

    # Read saved state
    restore_count = 1
    try:
        response = table.get_item(Key={"service_arn": service_arn})
        if "Item" in response:
            restore_count = int(response["Item"]["desired_count"])
            logger.info("Restoring %s to saved count %d", service_name, restore_count)
        else:
            logger.info("No saved state for %s, defaulting to 1", service_name)
    except ClientError:
        logger.exception("DynamoDB read failed for %s, defaulting to 1", service_name)

    if restore_count < 1:
        restore_count = 1

    ecs.update_service(
        cluster=cluster_name,
        service=service_arn,
        desiredCount=restore_count,
    )
    logger.info("Started service %s with desired_count=%d", service_name, restore_count)


def send_notification(action, cluster_name, succeeded, failed, extra_message=None):
    """Send SNS notification summarizing the action."""
    now_sast = datetime.now(SAST).strftime("%Y-%m-%d %H:%M SAST")
    action_label = "STOPPED" if action == "stop" else "STARTED"

    subject = f"ECS Scheduler: {action_label} {cluster_name} ({len(succeeded)} services)"

    lines = [
        f"ECS Scheduler - {action_label}",
        f"Cluster: {cluster_name}",
        f"Time: {now_sast}",
        f"Succeeded: {len(succeeded)}",
        f"Failed: {len(failed)}",
        "",
    ]

    if extra_message:
        lines.append(extra_message)
        lines.append("")

    if succeeded:
        lines.append("Succeeded:")
        for arn in succeeded:
            name = arn.split("/")[-1]
            lines.append(f"  - {name}")
        lines.append("")

    if failed:
        lines.append("FAILED (requires attention):")
        for arn in failed:
            name = arn.split("/")[-1]
            lines.append(f"  - {name}")
        lines.append("")

    message = "\n".join(lines)

    try:
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject[:100],
            Message=message,
        )
        logger.info("SNS notification sent")
    except ClientError:
        logger.exception("Failed to send SNS notification")
