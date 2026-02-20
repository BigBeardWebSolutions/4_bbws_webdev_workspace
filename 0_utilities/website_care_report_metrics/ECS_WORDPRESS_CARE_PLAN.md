# ECS WordPress Care Report Implementation Plan

**Created**: 2026-02-02
**Purpose**: Implementation plan for automated Website Care Reports for ECS-hosted WordPress sites
**Reference**: [Website Care Report Metrics](./WEBSITE_CARE_REPORT_METRICS.md)

---

## Architecture Overview

```
+-------------------+     +-------------------+     +-------------------+
|  EventBridge      |---->|  Report Lambda    |---->|  S3 Reports       |
|  (Weekly/Monthly) |     |  (Aggregator)     |     |  Bucket           |
+-------------------+     +---------+---------+     +-------------------+
                                    |
        +---------------------------+---------------------------+
        |                           |                           |
+-------v-------+          +--------v--------+          +-------v-------+
| ManageWP API  |          | AWS APIs        |          | GA4 API       |
| - Updates     |          | - CloudWatch    |          | - Sessions    |
| - Backups     |          | - ECS           |          | - PageViews   |
| - Site Health |          | - RDS           |          | - Bounce Rate |
+---------------+          | - EFS           |          +---------------+
                           | - AWS Backup    |
                           | - ACM           |
                           +-----------------+
```

---

## Phase 1: Infrastructure Setup

### 1.1 S3 Bucket for Reports

```hcl
# terraform/reports_bucket.tf
resource "aws_s3_bucket" "care_reports" {
  bucket = "bigbeard-care-reports-${var.environment}"

  tags = {
    Name        = "Website Care Reports"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "reports_lifecycle" {
  bucket = aws_s3_bucket.care_reports.id

  rule {
    id     = "archive-old-reports"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}
```

### 1.2 DynamoDB for Site Registry

```hcl
# terraform/site_registry.tf
resource "aws_dynamodb_table" "site_registry" {
  name           = "bigbeard-site-registry-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "site_id"

  attribute {
    name = "site_id"
    type = "S"
  }

  attribute {
    name = "site_type"
    type = "S"
  }

  global_secondary_index {
    name            = "site-type-index"
    hash_key        = "site_type"
    projection_type = "ALL"
  }

  tags = {
    Name = "Site Registry"
  }
}
```

**Site Registry Schema:**
```json
{
  "site_id": "premiumkingseeds",
  "site_type": "ecs_wordpress",
  "domain": "premiumkingseeds.com",
  "ecs_cluster": "prod-cluster",
  "ecs_service": "prod-premiumkingseeds-service",
  "rds_instance": "prod-premiumkingseeds-db",
  "efs_id": "fs-abc123",
  "managewp_site_id": "12345",
  "ga4_property_id": "properties/123456789",
  "woocommerce": true,
  "woocommerce_api_url": "https://premiumkingseeds.com/wp-json/wc/v3",
  "created_at": "2026-01-15T00:00:00Z"
}
```

---

## Phase 2: Metric Collectors

### 2.1 ManageWP Collector Lambda

```python
# lambda/managewp_collector.py
import boto3
import requests
import json
from datetime import datetime, timedelta

def get_managewp_metrics(site_id, api_key, start_date, end_date):
    """Collect metrics from ManageWP API"""
    headers = {"Authorization": f"Bearer {api_key}"}
    base_url = "https://api.managewp.com/v1"

    metrics = {
        "updates": get_updates(base_url, site_id, headers, start_date, end_date),
        "backups": get_backups(base_url, site_id, headers),
        "site_health": get_site_health(base_url, site_id, headers)
    }

    return metrics

def get_updates(base_url, site_id, headers, start_date, end_date):
    """Get plugin/theme/core updates in period"""
    response = requests.get(
        f"{base_url}/sites/{site_id}/updates/history",
        headers=headers,
        params={"from": start_date, "to": end_date}
    )

    if response.status_code == 200:
        data = response.json()
        return {
            "total": len(data.get("updates", [])),
            "plugins": [u for u in data.get("updates", []) if u["type"] == "plugin"],
            "themes": [u for u in data.get("updates", []) if u["type"] == "theme"],
            "core": [u for u in data.get("updates", []) if u["type"] == "core"]
        }
    return {"total": 0, "plugins": [], "themes": [], "core": []}

def get_backups(base_url, site_id, headers):
    """Get backup statistics"""
    response = requests.get(
        f"{base_url}/sites/{site_id}/backups",
        headers=headers
    )

    if response.status_code == 200:
        data = response.json()
        backups = data.get("backups", [])
        return {
            "total_available": len(backups),
            "latest_backup": backups[0] if backups else None,
            "backup_size_mb": sum(b.get("size_mb", 0) for b in backups)
        }
    return {"total_available": 0, "latest_backup": None, "backup_size_mb": 0}

def get_site_health(base_url, site_id, headers):
    """Get WordPress site health info"""
    response = requests.get(
        f"{base_url}/sites/{site_id}/info",
        headers=headers
    )

    if response.status_code == 200:
        data = response.json()
        return {
            "wordpress_version": data.get("wp_version"),
            "php_version": data.get("php_version"),
            "active_theme": data.get("theme"),
            "active_plugins": data.get("plugins_count"),
            "published_posts": data.get("posts_count"),
            "approved_comments": data.get("comments_count")
        }
    return {}
```

### 2.2 AWS Infrastructure Collector Lambda

```python
# lambda/aws_collector.py
import boto3
from datetime import datetime, timedelta

def get_ecs_metrics(cluster_name, service_name, start_time, end_time):
    """Collect ECS container metrics"""
    cloudwatch = boto3.client('cloudwatch')

    metrics = {}

    # CPU Utilization
    cpu_response = cloudwatch.get_metric_statistics(
        Namespace='AWS/ECS',
        MetricName='CPUUtilization',
        Dimensions=[
            {'Name': 'ClusterName', 'Value': cluster_name},
            {'Name': 'ServiceName', 'Value': service_name}
        ],
        StartTime=start_time,
        EndTime=end_time,
        Period=3600,
        Statistics=['Average', 'Maximum']
    )
    metrics['cpu'] = {
        'average': calculate_average(cpu_response['Datapoints'], 'Average'),
        'peak': calculate_max(cpu_response['Datapoints'], 'Maximum')
    }

    # Memory Utilization
    memory_response = cloudwatch.get_metric_statistics(
        Namespace='AWS/ECS',
        MetricName='MemoryUtilization',
        Dimensions=[
            {'Name': 'ClusterName', 'Value': cluster_name},
            {'Name': 'ServiceName', 'Value': service_name}
        ],
        StartTime=start_time,
        EndTime=end_time,
        Period=3600,
        Statistics=['Average', 'Maximum']
    )
    metrics['memory'] = {
        'average': calculate_average(memory_response['Datapoints'], 'Average'),
        'peak': calculate_max(memory_response['Datapoints'], 'Maximum')
    }

    return metrics

def get_rds_metrics(db_instance_id, start_time, end_time):
    """Collect RDS database metrics"""
    cloudwatch = boto3.client('cloudwatch')

    metrics = {}

    # Database connections
    connections = cloudwatch.get_metric_statistics(
        Namespace='AWS/RDS',
        MetricName='DatabaseConnections',
        Dimensions=[{'Name': 'DBInstanceIdentifier', 'Value': db_instance_id}],
        StartTime=start_time,
        EndTime=end_time,
        Period=3600,
        Statistics=['Average', 'Maximum']
    )
    metrics['connections'] = {
        'average': calculate_average(connections['Datapoints'], 'Average'),
        'peak': calculate_max(connections['Datapoints'], 'Maximum')
    }

    # CPU Utilization
    cpu = cloudwatch.get_metric_statistics(
        Namespace='AWS/RDS',
        MetricName='CPUUtilization',
        Dimensions=[{'Name': 'DBInstanceIdentifier', 'Value': db_instance_id}],
        StartTime=start_time,
        EndTime=end_time,
        Period=3600,
        Statistics=['Average', 'Maximum']
    )
    metrics['cpu'] = {
        'average': calculate_average(cpu['Datapoints'], 'Average'),
        'peak': calculate_max(cpu['Datapoints'], 'Maximum')
    }

    return metrics

def get_backup_metrics(efs_id, rds_instance_id):
    """Collect AWS Backup metrics"""
    backup = boto3.client('backup')

    # Get EFS backups
    efs_backups = backup.list_recovery_points_by_resource(
        ResourceArn=f"arn:aws:elasticfilesystem:*:*:file-system/{efs_id}"
    )

    # Get RDS backups
    rds = boto3.client('rds')
    rds_snapshots = rds.describe_db_snapshots(
        DBInstanceIdentifier=rds_instance_id
    )

    return {
        'efs_backups': len(efs_backups.get('RecoveryPoints', [])),
        'rds_snapshots': len(rds_snapshots.get('DBSnapshots', [])),
        'latest_efs_backup': efs_backups['RecoveryPoints'][0] if efs_backups.get('RecoveryPoints') else None,
        'latest_rds_snapshot': rds_snapshots['DBSnapshots'][0] if rds_snapshots.get('DBSnapshots') else None
    }

def get_ssl_status(domain):
    """Check ACM certificate status"""
    acm = boto3.client('acm', region_name='us-east-1')

    certificates = acm.list_certificates()
    for cert in certificates['CertificateSummaryList']:
        if domain in cert.get('DomainName', '') or domain in str(cert.get('SubjectAlternativeNameSummaries', [])):
            cert_details = acm.describe_certificate(CertificateArn=cert['CertificateArn'])
            return {
                'status': cert_details['Certificate']['Status'],
                'expiry': cert_details['Certificate'].get('NotAfter'),
                'days_until_expiry': (cert_details['Certificate'].get('NotAfter') - datetime.now()).days if cert_details['Certificate'].get('NotAfter') else None
            }
    return {'status': 'NOT_FOUND', 'expiry': None, 'days_until_expiry': None}

def calculate_average(datapoints, stat_name):
    if not datapoints:
        return 0
    return sum(dp[stat_name] for dp in datapoints) / len(datapoints)

def calculate_max(datapoints, stat_name):
    if not datapoints:
        return 0
    return max(dp[stat_name] for dp in datapoints)
```

### 2.3 WooCommerce Collector Lambda

```python
# lambda/woocommerce_collector.py
import requests
from datetime import datetime, timedelta
import base64

def get_woocommerce_metrics(api_url, consumer_key, consumer_secret, start_date, end_date):
    """Collect WooCommerce sales metrics"""
    auth = (consumer_key, consumer_secret)

    # Get orders in period
    orders_response = requests.get(
        f"{api_url}/orders",
        auth=auth,
        params={
            "after": f"{start_date}T00:00:00",
            "before": f"{end_date}T23:59:59",
            "per_page": 100,
            "status": "completed,processing,on-hold"
        }
    )

    orders = orders_response.json() if orders_response.status_code == 200 else []

    # Calculate metrics
    gross_sales = sum(float(o.get('total', 0)) for o in orders)
    refunds = sum(float(o.get('total_refunded', 0)) for o in orders if o.get('status') == 'refunded')
    shipping = sum(float(o.get('shipping_total', 0)) for o in orders)
    discounts = sum(float(o.get('discount_total', 0)) for o in orders)

    # Get items sold
    items_sold = sum(
        sum(int(item.get('quantity', 0)) for item in o.get('line_items', []))
        for o in orders
    )

    # Get new customers in period
    customers_response = requests.get(
        f"{api_url}/customers",
        auth=auth,
        params={
            "after": f"{start_date}T00:00:00",
            "before": f"{end_date}T23:59:59",
            "per_page": 100
        }
    )
    new_customers = len(customers_response.json()) if customers_response.status_code == 200 else 0

    # Get top products
    top_products = get_top_products(orders)

    # Get top categories
    top_categories = get_top_categories(api_url, auth, orders)

    return {
        "gross_sales": gross_sales,
        "net_sales": gross_sales - refunds - discounts,
        "refunds": refunds,
        "refund_count": len([o for o in orders if o.get('status') == 'refunded']),
        "coupons_used": discounts,
        "shipping_revenue": shipping,
        "orders_total": len(orders),
        "items_sold": items_sold,
        "new_signups": new_customers,
        "top_products": top_products[:5],
        "top_categories": top_categories[:5]
    }

def get_top_products(orders):
    """Calculate top selling products"""
    product_sales = {}
    product_revenue = {}

    for order in orders:
        for item in order.get('line_items', []):
            product_name = item.get('name', 'Unknown')
            quantity = int(item.get('quantity', 0))
            total = float(item.get('total', 0))

            product_sales[product_name] = product_sales.get(product_name, 0) + quantity
            product_revenue[product_name] = product_revenue.get(product_name, 0) + total

    # Sort by quantity sold
    sorted_products = sorted(product_sales.items(), key=lambda x: x[1], reverse=True)

    return [
        {"name": name, "sold": qty, "revenue": product_revenue.get(name, 0)}
        for name, qty in sorted_products
    ]

def get_top_categories(api_url, auth, orders):
    """Calculate top categories by revenue"""
    # Get all products with their categories
    products_response = requests.get(f"{api_url}/products", auth=auth, params={"per_page": 100})
    products = products_response.json() if products_response.status_code == 200 else []

    # Map product IDs to categories
    product_categories = {}
    for product in products:
        for category in product.get('categories', []):
            product_categories[product['id']] = category.get('name', 'Uncategorized')

    # Calculate category revenue
    category_revenue = {}
    for order in orders:
        for item in order.get('line_items', []):
            product_id = item.get('product_id')
            category = product_categories.get(product_id, 'Uncategorized')
            revenue = float(item.get('total', 0))
            category_revenue[category] = category_revenue.get(category, 0) + revenue

    sorted_categories = sorted(category_revenue.items(), key=lambda x: x[1], reverse=True)
    return [{"name": name, "revenue": revenue} for name, revenue in sorted_categories]
```

### 2.4 GA4 Analytics Collector

```python
# lambda/ga4_collector.py
from google.analytics.data_v1beta import BetaAnalyticsDataClient
from google.analytics.data_v1beta.types import (
    DateRange, Dimension, Metric, RunReportRequest
)
import json

def get_ga4_metrics(property_id, start_date, end_date, credentials_secret_name):
    """Collect Google Analytics 4 metrics"""
    # Get credentials from Secrets Manager
    credentials = get_credentials(credentials_secret_name)

    client = BetaAnalyticsDataClient.from_service_account_info(credentials)

    # Basic metrics request
    request = RunReportRequest(
        property=f"properties/{property_id}",
        date_ranges=[DateRange(start_date=start_date, end_date=end_date)],
        metrics=[
            Metric(name="sessions"),
            Metric(name="totalUsers"),
            Metric(name="screenPageViews"),
            Metric(name="bounceRate"),
            Metric(name="averageSessionDuration")
        ]
    )

    response = client.run_report(request)

    current_metrics = {}
    if response.rows:
        row = response.rows[0]
        current_metrics = {
            "sessions": int(row.metric_values[0].value),
            "users": int(row.metric_values[1].value),
            "pageviews": int(row.metric_values[2].value),
            "bounce_rate": float(row.metric_values[3].value),
            "avg_session_duration": float(row.metric_values[4].value)
        }

    # Get previous period for comparison
    previous_metrics = get_previous_period_metrics(client, property_id, start_date, end_date)

    # Calculate change percentages
    session_change = calculate_change(
        current_metrics.get('sessions', 0),
        previous_metrics.get('sessions', 0)
    )

    # Get top pages
    top_pages = get_top_pages(client, property_id, start_date, end_date)

    # Get geographic data
    geo_data = get_geographic_data(client, property_id, start_date, end_date)

    return {
        **current_metrics,
        "session_change_percent": session_change,
        "previous_sessions": previous_metrics.get('sessions', 0),
        "top_pages": top_pages,
        "geographic_distribution": geo_data
    }

def calculate_change(current, previous):
    if previous == 0:
        return 100 if current > 0 else 0
    return round(((current - previous) / previous) * 100, 1)

def get_top_pages(client, property_id, start_date, end_date):
    """Get top 10 pages by pageviews"""
    request = RunReportRequest(
        property=f"properties/{property_id}",
        date_ranges=[DateRange(start_date=start_date, end_date=end_date)],
        dimensions=[Dimension(name="pagePath")],
        metrics=[Metric(name="screenPageViews")],
        limit=10
    )

    response = client.run_report(request)

    return [
        {"page": row.dimension_values[0].value, "views": int(row.metric_values[0].value)}
        for row in response.rows
    ]

def get_geographic_data(client, property_id, start_date, end_date):
    """Get sessions by country"""
    request = RunReportRequest(
        property=f"properties/{property_id}",
        date_ranges=[DateRange(start_date=start_date, end_date=end_date)],
        dimensions=[Dimension(name="country")],
        metrics=[Metric(name="sessions")],
        limit=10
    )

    response = client.run_report(request)

    return [
        {"country": row.dimension_values[0].value, "sessions": int(row.metric_values[0].value)}
        for row in response.rows
    ]

def get_credentials(secret_name):
    """Retrieve GA4 credentials from Secrets Manager"""
    import boto3

    secrets = boto3.client('secretsmanager')
    response = secrets.get_secret_value(SecretId=secret_name)
    return json.loads(response['SecretString'])
```

---

## Phase 3: Report Aggregator Lambda

```python
# lambda/report_aggregator.py
import boto3
import json
from datetime import datetime, timedelta
from jinja2 import Template

def lambda_handler(event, context):
    """Main report generation handler"""

    # Get report parameters
    site_id = event.get('site_id')
    report_type = event.get('report_type', 'monthly')  # weekly or monthly

    # Calculate date range
    end_date = datetime.now()
    if report_type == 'weekly':
        start_date = end_date - timedelta(days=7)
    else:
        start_date = end_date - timedelta(days=30)

    # Get site configuration from DynamoDB
    site_config = get_site_config(site_id)

    if site_config['site_type'] != 'ecs_wordpress':
        return {"error": "Site type not supported by this handler"}

    # Collect all metrics
    metrics = {
        "site_info": site_config,
        "period": {
            "start": start_date.strftime('%Y-%m-%d'),
            "end": end_date.strftime('%Y-%m-%d')
        },
        "generated_at": datetime.now().isoformat()
    }

    # ManageWP metrics (updates, backups, site health)
    metrics["managewp"] = invoke_collector(
        "managewp_collector",
        {
            "site_id": site_config['managewp_site_id'],
            "start_date": start_date.strftime('%Y-%m-%d'),
            "end_date": end_date.strftime('%Y-%m-%d')
        }
    )

    # AWS Infrastructure metrics
    metrics["infrastructure"] = invoke_collector(
        "aws_collector",
        {
            "cluster_name": site_config['ecs_cluster'],
            "service_name": site_config['ecs_service'],
            "rds_instance_id": site_config['rds_instance'],
            "efs_id": site_config['efs_id'],
            "domain": site_config['domain'],
            "start_time": start_date.isoformat(),
            "end_time": end_date.isoformat()
        }
    )

    # GA4 Analytics
    if site_config.get('ga4_property_id'):
        metrics["analytics"] = invoke_collector(
            "ga4_collector",
            {
                "property_id": site_config['ga4_property_id'],
                "start_date": start_date.strftime('%Y-%m-%d'),
                "end_date": end_date.strftime('%Y-%m-%d')
            }
        )

    # WooCommerce metrics (if applicable)
    if site_config.get('woocommerce'):
        metrics["woocommerce"] = invoke_collector(
            "woocommerce_collector",
            {
                "api_url": site_config['woocommerce_api_url'],
                "start_date": start_date.strftime('%Y-%m-%d'),
                "end_date": end_date.strftime('%Y-%m-%d')
            }
        )

    # Generate report
    report_html = generate_html_report(metrics)
    report_json = json.dumps(metrics, indent=2, default=str)

    # Save to S3
    s3 = boto3.client('s3')
    bucket = f"bigbeard-care-reports-{get_environment()}"

    # Save JSON
    s3.put_object(
        Bucket=bucket,
        Key=f"{site_id}/{end_date.strftime('%Y/%m')}/report_{end_date.strftime('%Y%m%d')}.json",
        Body=report_json,
        ContentType='application/json'
    )

    # Save HTML
    s3.put_object(
        Bucket=bucket,
        Key=f"{site_id}/{end_date.strftime('%Y/%m')}/report_{end_date.strftime('%Y%m%d')}.html",
        Body=report_html,
        ContentType='text/html'
    )

    # Send notification
    send_report_notification(site_config, metrics)

    return {
        "status": "success",
        "site_id": site_id,
        "report_path": f"s3://{bucket}/{site_id}/{end_date.strftime('%Y/%m')}/report_{end_date.strftime('%Y%m%d')}.html"
    }

def get_site_config(site_id):
    """Get site configuration from DynamoDB"""
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(f"bigbeard-site-registry-{get_environment()}")
    response = table.get_item(Key={'site_id': site_id})
    return response.get('Item', {})

def invoke_collector(function_name, payload):
    """Invoke a collector Lambda function"""
    lambda_client = boto3.client('lambda')
    response = lambda_client.invoke(
        FunctionName=f"bigbeard-{function_name}-{get_environment()}",
        InvocationType='RequestResponse',
        Payload=json.dumps(payload)
    )
    return json.loads(response['Payload'].read())

def generate_html_report(metrics):
    """Generate HTML report from template"""
    template = get_report_template()
    return template.render(**metrics)

def send_report_notification(site_config, metrics):
    """Send SNS notification with report summary"""
    sns = boto3.client('sns')

    message = f"""
Website Care Report Generated

Site: {site_config['domain']}
Period: {metrics['period']['start']} to {metrics['period']['end']}

Summary:
- Updates Performed: {metrics.get('managewp', {}).get('updates', {}).get('total', 'N/A')}
- Backups Available: {metrics.get('managewp', {}).get('backups', {}).get('total_available', 'N/A')}
- Sessions: {metrics.get('analytics', {}).get('sessions', 'N/A')} ({metrics.get('analytics', {}).get('session_change_percent', 0)}% change)
"""

    if metrics.get('woocommerce'):
        message += f"""
WooCommerce:
- Gross Sales: R{metrics['woocommerce'].get('gross_sales', 0):,.2f}
- Orders: {metrics['woocommerce'].get('orders_total', 0)}
"""

    sns.publish(
        TopicArn=f"arn:aws:sns:{get_region()}:{get_account_id()}:bigbeard-care-reports-{get_environment()}",
        Message=message,
        Subject=f"Care Report: {site_config['domain']}"
    )

def get_environment():
    import os
    return os.environ.get('ENVIRONMENT', 'dev')

def get_region():
    import os
    return os.environ.get('AWS_REGION', 'af-south-1')

def get_account_id():
    sts = boto3.client('sts')
    return sts.get_caller_identity()['Account']
```

---

## Phase 4: EventBridge Scheduling

```hcl
# terraform/eventbridge.tf

# Weekly report schedule (every Monday at 6 AM)
resource "aws_cloudwatch_event_rule" "weekly_report" {
  name                = "bigbeard-weekly-care-report-${var.environment}"
  description         = "Trigger weekly care reports"
  schedule_expression = "cron(0 6 ? * MON *)"
}

resource "aws_cloudwatch_event_target" "weekly_report_target" {
  rule = aws_cloudwatch_event_rule.weekly_report.name
  arn  = aws_lambda_function.report_scheduler.arn

  input = jsonencode({
    report_type = "weekly"
    site_type   = "ecs_wordpress"
  })
}

# Monthly report schedule (1st of each month at 6 AM)
resource "aws_cloudwatch_event_rule" "monthly_report" {
  name                = "bigbeard-monthly-care-report-${var.environment}"
  description         = "Trigger monthly care reports"
  schedule_expression = "cron(0 6 1 * ? *)"
}

resource "aws_cloudwatch_event_target" "monthly_report_target" {
  rule = aws_cloudwatch_event_rule.monthly_report.name
  arn  = aws_lambda_function.report_scheduler.arn

  input = jsonencode({
    report_type = "monthly"
    site_type   = "ecs_wordpress"
  })
}

# Report scheduler Lambda (triggers individual site reports)
resource "aws_lambda_function" "report_scheduler" {
  function_name = "bigbeard-report-scheduler-${var.environment}"
  runtime       = "python3.11"
  handler       = "scheduler.lambda_handler"
  timeout       = 300

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}
```

---

## Phase 5: CloudWatch Dashboard

```hcl
# terraform/dashboard.tf
resource "aws_cloudwatch_dashboard" "ecs_wordpress_overview" {
  dashboard_name = "BigBeard-ECS-WordPress-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "ECS CPU Utilization"
          region  = var.aws_region
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name]
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "ECS Memory Utilization"
          region  = var.aws_region
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.ecs_cluster_name]
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "RDS CPU Utilization"
          region  = var.aws_region
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_id]
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "RDS Database Connections"
          region  = var.aws_region
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.rds_instance_id]
          ]
          period = 300
          stat   = "Average"
        }
      }
    ]
  })
}
```

---

## Implementation Checklist

| Phase | Task | Status |
|-------|------|--------|
| 1 | Create S3 bucket for reports | [ ] |
| 1 | Create DynamoDB site registry | [ ] |
| 1 | Register existing ECS WordPress sites | [ ] |
| 2 | Deploy ManageWP collector Lambda | [ ] |
| 2 | Deploy AWS collector Lambda | [ ] |
| 2 | Deploy WooCommerce collector Lambda | [ ] |
| 2 | Deploy GA4 collector Lambda | [ ] |
| 3 | Deploy report aggregator Lambda | [ ] |
| 3 | Create HTML report template | [ ] |
| 4 | Configure EventBridge schedules | [ ] |
| 4 | Configure SNS notifications | [ ] |
| 5 | Create CloudWatch dashboard | [ ] |
| 5 | Test end-to-end report generation | [ ] |

---

## Related Documents

- [Website Care Report Metrics](./WEBSITE_CARE_REPORT_METRICS.md)
- [Static Site Care Plan](./STATIC_SITE_CARE_PLAN.md)
