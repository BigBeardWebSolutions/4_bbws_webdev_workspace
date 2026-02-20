# Static Site Care Report Implementation Plan

**Created**: 2026-02-02
**Purpose**: Implementation plan for automated Website Care Reports for extraction-based static sites (S3/CloudFront)
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
| CloudFront    |          | S3 Versioning   |          | GA4 API       |
| Metrics       |          | Metrics         |          | (Optional)    |
| - Requests    |          | - Version count |          | - Sessions    |
| - Cache ratio |          | - Storage size  |          | - PageViews   |
| - Errors      |          | - Last update   |          | - Bounce Rate |
+---------------+          +-----------------+          +---------------+
```

---

## Key Differences from ECS WordPress

| Aspect | ECS WordPress | Static Site |
|--------|--------------|-------------|
| Updates | Plugin/Theme updates | No updates (static content) |
| Backups | EFS + RDS snapshots | S3 versioning |
| Performance | Container metrics | CloudFront edge metrics |
| Commerce | WooCommerce API | Form submissions (Main Form Router) |
| CMS Health | WordPress health | N/A |
| Content Changes | WP post tracking | S3 object versioning |

---

## Phase 1: Infrastructure Setup

### 1.1 S3 Bucket Configuration (Already Exists)

Static sites are already deployed to:
- `bigbeard-migrated-site-dev` (dev environment)
- `bigbeard-migrated-site-sit-af-south-1` (SIT environment)
- `bigbeard-migrated-site-prod` (production)

**Enable Versioning (if not already):**
```bash
# Enable versioning for backup tracking
aws s3api put-bucket-versioning \
    --bucket bigbeard-migrated-site-prod \
    --versioning-configuration Status=Enabled \
    --profile prod
```

### 1.2 Site Registry Entry Schema

```json
{
  "site_id": "roedinolte",
  "site_type": "static_site",
  "domain": "roedinolte.co.za",
  "s3_bucket": "bigbeard-migrated-site-prod",
  "s3_prefix": "roedinolte/",
  "cloudfront_distribution_id": "E1ABC123XYZ",
  "cloudfront_domain": "d1abc123.cloudfront.net",
  "ga4_property_id": "properties/123456789",
  "has_forms": true,
  "form_router_enabled": true,
  "ssl_certificate_arn": "arn:aws:acm:us-east-1:...",
  "origin_domain": "roedinolte.co.za",
  "created_at": "2026-01-30T00:00:00Z",
  "last_deployment": "2026-02-01T14:30:00Z"
}
```

---

## Phase 2: Metric Collectors

### 2.1 CloudFront Metrics Collector

```python
# lambda/cloudfront_collector.py
import boto3
from datetime import datetime, timedelta

def get_cloudfront_metrics(distribution_id, start_time, end_time):
    """Collect CloudFront distribution metrics"""
    cloudwatch = boto3.client('cloudwatch')

    metrics = {}

    # Total Requests
    requests = cloudwatch.get_metric_statistics(
        Namespace='AWS/CloudFront',
        MetricName='Requests',
        Dimensions=[
            {'Name': 'DistributionId', 'Value': distribution_id},
            {'Name': 'Region', 'Value': 'Global'}
        ],
        StartTime=start_time,
        EndTime=end_time,
        Period=86400,  # Daily aggregation
        Statistics=['Sum']
    )
    metrics['total_requests'] = sum(dp['Sum'] for dp in requests['Datapoints'])

    # Bytes Downloaded
    bytes_downloaded = cloudwatch.get_metric_statistics(
        Namespace='AWS/CloudFront',
        MetricName='BytesDownloaded',
        Dimensions=[
            {'Name': 'DistributionId', 'Value': distribution_id},
            {'Name': 'Region', 'Value': 'Global'}
        ],
        StartTime=start_time,
        EndTime=end_time,
        Period=86400,
        Statistics=['Sum']
    )
    total_bytes = sum(dp['Sum'] for dp in bytes_downloaded['Datapoints'])
    metrics['bandwidth_gb'] = round(total_bytes / (1024**3), 2)

    # Error Rates
    error_4xx = cloudwatch.get_metric_statistics(
        Namespace='AWS/CloudFront',
        MetricName='4xxErrorRate',
        Dimensions=[
            {'Name': 'DistributionId', 'Value': distribution_id},
            {'Name': 'Region', 'Value': 'Global'}
        ],
        StartTime=start_time,
        EndTime=end_time,
        Period=86400,
        Statistics=['Average']
    )
    metrics['error_rate_4xx'] = calculate_average(error_4xx['Datapoints'])

    error_5xx = cloudwatch.get_metric_statistics(
        Namespace='AWS/CloudFront',
        MetricName='5xxErrorRate',
        Dimensions=[
            {'Name': 'DistributionId', 'Value': distribution_id},
            {'Name': 'Region', 'Value': 'Global'}
        ],
        StartTime=start_time,
        EndTime=end_time,
        Period=86400,
        Statistics=['Average']
    )
    metrics['error_rate_5xx'] = calculate_average(error_5xx['Datapoints'])

    # Cache Hit Ratio
    cache_hit_rate = cloudwatch.get_metric_statistics(
        Namespace='AWS/CloudFront',
        MetricName='CacheHitRate',
        Dimensions=[
            {'Name': 'DistributionId', 'Value': distribution_id},
            {'Name': 'Region', 'Value': 'Global'}
        ],
        StartTime=start_time,
        EndTime=end_time,
        Period=86400,
        Statistics=['Average']
    )
    metrics['cache_hit_ratio'] = round(calculate_average(cache_hit_rate['Datapoints']), 2)

    # Origin Latency
    origin_latency = cloudwatch.get_metric_statistics(
        Namespace='AWS/CloudFront',
        MetricName='OriginLatency',
        Dimensions=[
            {'Name': 'DistributionId', 'Value': distribution_id},
            {'Name': 'Region', 'Value': 'Global'}
        ],
        StartTime=start_time,
        EndTime=end_time,
        Period=86400,
        Statistics=['Average', 'p95']
    )
    metrics['origin_latency_avg_ms'] = round(calculate_average(origin_latency['Datapoints']) * 1000, 2)

    return metrics

def get_cloudfront_distribution_info(distribution_id):
    """Get CloudFront distribution configuration details"""
    cloudfront = boto3.client('cloudfront')

    response = cloudfront.get_distribution(Id=distribution_id)
    config = response['Distribution']['DistributionConfig']

    return {
        "status": response['Distribution']['Status'],
        "domain_name": response['Distribution']['DomainName'],
        "aliases": config.get('Aliases', {}).get('Items', []),
        "enabled": config['Enabled'],
        "price_class": config['PriceClass'],
        "http_version": config['HttpVersion'],
        "origins": [
            {
                "id": origin['Id'],
                "domain": origin['DomainName'],
                "path": origin.get('OriginPath', '')
            }
            for origin in config['Origins']['Items']
        ],
        "default_cache_behavior": {
            "viewer_protocol_policy": config['DefaultCacheBehavior']['ViewerProtocolPolicy'],
            "compress": config['DefaultCacheBehavior'].get('Compress', False)
        }
    }

def calculate_average(datapoints):
    if not datapoints:
        return 0
    return sum(dp.get('Average', 0) for dp in datapoints) / len(datapoints)

def lambda_handler(event, context):
    """Lambda handler for CloudFront metrics collection"""
    distribution_id = event['distribution_id']
    start_time = datetime.fromisoformat(event['start_time'])
    end_time = datetime.fromisoformat(event['end_time'])

    metrics = get_cloudfront_metrics(distribution_id, start_time, end_time)
    distribution_info = get_cloudfront_distribution_info(distribution_id)

    return {
        "distribution_id": distribution_id,
        "metrics": metrics,
        "distribution_info": distribution_info
    }
```

### 2.2 S3 Versioning Collector

```python
# lambda/s3_versioning_collector.py
import boto3
from datetime import datetime, timedelta

def get_s3_versioning_metrics(bucket_name, prefix, start_date, end_date):
    """Collect S3 versioning metrics for backup tracking"""
    s3 = boto3.client('s3')

    # List all object versions
    versions = []
    paginator = s3.get_paginator('list_object_versions')

    for page in paginator.paginate(Bucket=bucket_name, Prefix=prefix):
        for version in page.get('Versions', []):
            versions.append({
                'key': version['Key'],
                'version_id': version['VersionId'],
                'last_modified': version['LastModified'],
                'size': version['Size'],
                'is_latest': version['IsLatest']
            })

    # Filter versions in the reporting period
    start_dt = datetime.strptime(start_date, '%Y-%m-%d').replace(tzinfo=None)
    end_dt = datetime.strptime(end_date, '%Y-%m-%d').replace(tzinfo=None)

    versions_in_period = [
        v for v in versions
        if start_dt <= v['last_modified'].replace(tzinfo=None) <= end_dt
    ]

    # Calculate metrics
    current_versions = [v for v in versions if v['is_latest']]
    total_current_size = sum(v['size'] for v in current_versions)

    return {
        "total_objects": len(current_versions),
        "total_versions": len(versions),
        "versions_in_period": len(versions_in_period),
        "current_size_mb": round(total_current_size / (1024**2), 2),
        "total_versioned_size_mb": round(sum(v['size'] for v in versions) / (1024**2), 2),
        "latest_update": max(v['last_modified'] for v in versions).isoformat() if versions else None,
        "files_modified_in_period": len(set(v['key'] for v in versions_in_period))
    }

def get_s3_storage_metrics(bucket_name, prefix):
    """Get S3 Storage Lens metrics (if configured)"""
    s3control = boto3.client('s3control')
    sts = boto3.client('sts')
    account_id = sts.get_caller_identity()['Account']

    try:
        # Get storage lens dashboard data (requires Storage Lens to be configured)
        # This provides more detailed storage analytics
        return {
            "storage_lens_enabled": True,
            "note": "Check S3 Storage Lens dashboard for detailed metrics"
        }
    except Exception:
        return {
            "storage_lens_enabled": False
        }

def lambda_handler(event, context):
    """Lambda handler for S3 versioning metrics"""
    bucket_name = event['bucket_name']
    prefix = event['prefix']
    start_date = event['start_date']
    end_date = event['end_date']

    versioning_metrics = get_s3_versioning_metrics(bucket_name, prefix, start_date, end_date)
    storage_metrics = get_s3_storage_metrics(bucket_name, prefix)

    return {
        "bucket": bucket_name,
        "prefix": prefix,
        "versioning": versioning_metrics,
        "storage": storage_metrics
    }
```

### 2.3 Form Submissions Collector (Main Form Router Integration)

```python
# lambda/form_submissions_collector.py
import boto3
from datetime import datetime
from boto3.dynamodb.conditions import Key, Attr

def get_form_submissions(site_domain, start_date, end_date):
    """Collect form submission metrics from Main Form Router"""
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('form-submissions')  # Main Form Router table

    # Query form submissions for this site
    response = table.scan(
        FilterExpression=Attr('site_domain').eq(site_domain) &
                         Attr('submitted_at').between(start_date, end_date)
    )

    submissions = response.get('Items', [])

    # Group by form
    forms = {}
    for sub in submissions:
        form_id = sub.get('form_id', 'unknown')
        if form_id not in forms:
            forms[form_id] = {
                'form_id': form_id,
                'form_name': sub.get('form_name', form_id),
                'submissions': 0,
                'successful': 0,
                'failed': 0
            }
        forms[form_id]['submissions'] += 1
        if sub.get('status') == 'success':
            forms[form_id]['successful'] += 1
        else:
            forms[form_id]['failed'] += 1

    total_submissions = len(submissions)
    successful = len([s for s in submissions if s.get('status') == 'success'])

    return {
        "total_submissions": total_submissions,
        "successful_submissions": successful,
        "failed_submissions": total_submissions - successful,
        "success_rate": round((successful / total_submissions * 100), 2) if total_submissions > 0 else 100,
        "forms": list(forms.values()),
        "submissions_by_day": get_submissions_by_day(submissions)
    }

def get_submissions_by_day(submissions):
    """Group submissions by day for charting"""
    by_day = {}
    for sub in submissions:
        day = sub.get('submitted_at', '')[:10]  # YYYY-MM-DD
        by_day[day] = by_day.get(day, 0) + 1
    return [{"date": k, "count": v} for k, v in sorted(by_day.items())]

def lambda_handler(event, context):
    """Lambda handler for form submissions metrics"""
    site_domain = event['site_domain']
    start_date = event['start_date']
    end_date = event['end_date']

    return get_form_submissions(site_domain, start_date, end_date)
```

### 2.4 SSL Certificate Checker (Same as ECS)

```python
# lambda/ssl_collector.py
import boto3
from datetime import datetime

def get_ssl_status(domain, certificate_arn=None):
    """Check ACM certificate status"""
    acm = boto3.client('acm', region_name='us-east-1')

    if certificate_arn:
        # Direct lookup
        cert_details = acm.describe_certificate(CertificateArn=certificate_arn)
        cert = cert_details['Certificate']

        expiry = cert.get('NotAfter')
        days_until_expiry = (expiry - datetime.now(expiry.tzinfo)).days if expiry else None

        return {
            'status': cert['Status'],
            'domain': cert['DomainName'],
            'expiry': expiry.isoformat() if expiry else None,
            'days_until_expiry': days_until_expiry,
            'in_use_by': cert.get('InUseBy', [])
        }

    # Search by domain
    certificates = acm.list_certificates()
    for cert in certificates['CertificateSummaryList']:
        if domain in cert.get('DomainName', '') or \
           domain in str(cert.get('SubjectAlternativeNameSummaries', [])):
            return get_ssl_status(domain, cert['CertificateArn'])

    return {
        'status': 'NOT_FOUND',
        'domain': domain,
        'expiry': None,
        'days_until_expiry': None
    }

def lambda_handler(event, context):
    """Lambda handler for SSL status check"""
    domain = event['domain']
    certificate_arn = event.get('certificate_arn')

    return get_ssl_status(domain, certificate_arn)
```

---

## Phase 3: Static Site Report Aggregator

```python
# lambda/static_site_report_aggregator.py
import boto3
import json
from datetime import datetime, timedelta

def lambda_handler(event, context):
    """Main report generation handler for static sites"""

    site_id = event.get('site_id')
    report_type = event.get('report_type', 'monthly')

    # Calculate date range
    end_date = datetime.now()
    if report_type == 'weekly':
        start_date = end_date - timedelta(days=7)
    else:
        start_date = end_date - timedelta(days=30)

    # Get site configuration
    site_config = get_site_config(site_id)

    if site_config['site_type'] != 'static_site':
        return {"error": "Site type not supported by this handler"}

    # Initialize metrics
    metrics = {
        "site_info": {
            "site_id": site_id,
            "domain": site_config['domain'],
            "type": "Static Site (S3/CloudFront)",
            "cloudfront_domain": site_config.get('cloudfront_domain'),
            "last_deployment": site_config.get('last_deployment')
        },
        "period": {
            "start": start_date.strftime('%Y-%m-%d'),
            "end": end_date.strftime('%Y-%m-%d')
        },
        "generated_at": datetime.now().isoformat()
    }

    # CloudFront metrics
    metrics["cloudfront"] = invoke_collector(
        "cloudfront_collector",
        {
            "distribution_id": site_config['cloudfront_distribution_id'],
            "start_time": start_date.isoformat(),
            "end_time": end_date.isoformat()
        }
    )

    # S3 versioning (backups equivalent)
    metrics["versioning"] = invoke_collector(
        "s3_versioning_collector",
        {
            "bucket_name": site_config['s3_bucket'],
            "prefix": site_config['s3_prefix'],
            "start_date": start_date.strftime('%Y-%m-%d'),
            "end_date": end_date.strftime('%Y-%m-%d')
        }
    )

    # SSL Certificate status
    metrics["ssl"] = invoke_collector(
        "ssl_collector",
        {
            "domain": site_config['domain'],
            "certificate_arn": site_config.get('ssl_certificate_arn')
        }
    )

    # GA4 Analytics (if configured)
    if site_config.get('ga4_property_id'):
        metrics["analytics"] = invoke_collector(
            "ga4_collector",
            {
                "property_id": site_config['ga4_property_id'],
                "start_date": start_date.strftime('%Y-%m-%d'),
                "end_date": end_date.strftime('%Y-%m-%d')
            }
        )

    # Form submissions (if forms are enabled)
    if site_config.get('has_forms') and site_config.get('form_router_enabled'):
        metrics["forms"] = invoke_collector(
            "form_submissions_collector",
            {
                "site_domain": site_config['domain'],
                "start_date": start_date.strftime('%Y-%m-%d'),
                "end_date": end_date.strftime('%Y-%m-%d')
            }
        )

    # Health check status
    metrics["health"] = get_health_status(site_config)

    # Generate and save report
    report_html = generate_static_site_report(metrics)
    report_json = json.dumps(metrics, indent=2, default=str)

    # Save to S3
    s3 = boto3.client('s3')
    bucket = f"bigbeard-care-reports-{get_environment()}"

    s3.put_object(
        Bucket=bucket,
        Key=f"{site_id}/{end_date.strftime('%Y/%m')}/report_{end_date.strftime('%Y%m%d')}.json",
        Body=report_json,
        ContentType='application/json'
    )

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

def get_health_status(site_config):
    """Check site availability"""
    import urllib.request

    try:
        url = f"https://{site_config['domain']}"
        request = urllib.request.Request(url, method='HEAD')
        response = urllib.request.urlopen(request, timeout=10)
        return {
            "status": "healthy",
            "response_code": response.status,
            "response_time_ms": response.headers.get('X-Response-Time', 'N/A')
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "error": str(e)
        }

def generate_static_site_report(metrics):
    """Generate HTML report for static site"""
    template = """
<!DOCTYPE html>
<html>
<head>
    <title>Website Care Report - {domain}</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }}
        .container {{ max-width: 900px; margin: 0 auto; background: white; padding: 40px; border-radius: 8px; }}
        .header {{ background: #00a0d2; color: white; padding: 20px; margin: -40px -40px 40px -40px; border-radius: 8px 8px 0 0; }}
        .section {{ margin: 30px 0; padding: 20px; border: 1px solid #e0e0e0; border-radius: 4px; }}
        .section h2 {{ color: #00a0d2; margin-top: 0; }}
        .metric {{ display: inline-block; margin: 10px 20px 10px 0; }}
        .metric-value {{ font-size: 24px; font-weight: bold; color: #333; }}
        .metric-label {{ font-size: 12px; color: #666; }}
        .status-healthy {{ color: #4CAF50; }}
        .status-warning {{ color: #FF9800; }}
        .status-error {{ color: #f44336; }}
        table {{ width: 100%; border-collapse: collapse; }}
        th, td {{ padding: 10px; text-align: left; border-bottom: 1px solid #e0e0e0; }}
        th {{ background: #f5f5f5; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Website Care Report</h1>
            <p>{domain}</p>
            <p>{period_start} - {period_end}</p>
        </div>

        <div class="section">
            <h2>Site Overview</h2>
            <div class="metric">
                <div class="metric-value">{site_type}</div>
                <div class="metric-label">Site Type</div>
            </div>
            <div class="metric">
                <div class="metric-value {health_class}">{health_status}</div>
                <div class="metric-label">Health Status</div>
            </div>
            <div class="metric">
                <div class="metric-value {ssl_class}">{ssl_days} days</div>
                <div class="metric-label">SSL Expires In</div>
            </div>
        </div>

        <div class="section">
            <h2>Traffic & Performance (CloudFront)</h2>
            <div class="metric">
                <div class="metric-value">{total_requests:,}</div>
                <div class="metric-label">Total Requests</div>
            </div>
            <div class="metric">
                <div class="metric-value">{bandwidth_gb} GB</div>
                <div class="metric-label">Bandwidth</div>
            </div>
            <div class="metric">
                <div class="metric-value">{cache_hit_ratio}%</div>
                <div class="metric-label">Cache Hit Ratio</div>
            </div>
            <div class="metric">
                <div class="metric-value">{error_rate_4xx}%</div>
                <div class="metric-label">4xx Error Rate</div>
            </div>
            <div class="metric">
                <div class="metric-value">{error_rate_5xx}%</div>
                <div class="metric-label">5xx Error Rate</div>
            </div>
        </div>

        <div class="section">
            <h2>Content Versions (Backups)</h2>
            <div class="metric">
                <div class="metric-value">{total_versions}</div>
                <div class="metric-label">Total Versions Available</div>
            </div>
            <div class="metric">
                <div class="metric-value">{versions_in_period}</div>
                <div class="metric-label">Changes This Period</div>
            </div>
            <div class="metric">
                <div class="metric-value">{current_size_mb} MB</div>
                <div class="metric-label">Current Site Size</div>
            </div>
            <div class="metric">
                <div class="metric-value">{latest_update}</div>
                <div class="metric-label">Last Update</div>
            </div>
        </div>

        {analytics_section}

        {forms_section}

        <div class="section">
            <p style="text-align: center; color: #666;">
                Generated: {generated_at}<br>
                BigBeard Web Solutions - Website Care Report
            </p>
        </div>
    </div>
</body>
</html>
    """

    # Prepare template variables
    cf = metrics.get('cloudfront', {}).get('metrics', {})
    versioning = metrics.get('versioning', {}).get('versioning', {})
    ssl = metrics.get('ssl', {})
    health = metrics.get('health', {})

    # Health status class
    health_class = "status-healthy" if health.get('status') == 'healthy' else "status-error"

    # SSL status class
    ssl_days = ssl.get('days_until_expiry', 0) or 0
    ssl_class = "status-healthy" if ssl_days > 30 else ("status-warning" if ssl_days > 7 else "status-error")

    # Analytics section
    analytics_section = ""
    if metrics.get('analytics'):
        analytics = metrics['analytics']
        analytics_section = f"""
        <div class="section">
            <h2>Analytics (Google Analytics)</h2>
            <div class="metric">
                <div class="metric-value">{analytics.get('sessions', 'N/A'):,}</div>
                <div class="metric-label">Sessions</div>
            </div>
            <div class="metric">
                <div class="metric-value">{analytics.get('session_change_percent', 0)}%</div>
                <div class="metric-label">vs Previous Period</div>
            </div>
            <div class="metric">
                <div class="metric-value">{analytics.get('pageviews', 'N/A'):,}</div>
                <div class="metric-label">Page Views</div>
            </div>
            <div class="metric">
                <div class="metric-value">{analytics.get('bounce_rate', 0):.1f}%</div>
                <div class="metric-label">Bounce Rate</div>
            </div>
        </div>
        """

    # Forms section
    forms_section = ""
    if metrics.get('forms'):
        forms = metrics['forms']
        forms_section = f"""
        <div class="section">
            <h2>Form Submissions</h2>
            <div class="metric">
                <div class="metric-value">{forms.get('total_submissions', 0)}</div>
                <div class="metric-label">Total Submissions</div>
            </div>
            <div class="metric">
                <div class="metric-value">{forms.get('successful_submissions', 0)}</div>
                <div class="metric-label">Successful</div>
            </div>
            <div class="metric">
                <div class="metric-value">{forms.get('success_rate', 100)}%</div>
                <div class="metric-label">Success Rate</div>
            </div>
        </div>
        """

    return template.format(
        domain=metrics['site_info']['domain'],
        period_start=metrics['period']['start'],
        period_end=metrics['period']['end'],
        site_type="Static Site",
        health_status=health.get('status', 'Unknown').title(),
        health_class=health_class,
        ssl_days=ssl_days,
        ssl_class=ssl_class,
        total_requests=cf.get('total_requests', 0),
        bandwidth_gb=cf.get('bandwidth_gb', 0),
        cache_hit_ratio=cf.get('cache_hit_ratio', 0),
        error_rate_4xx=cf.get('error_rate_4xx', 0),
        error_rate_5xx=cf.get('error_rate_5xx', 0),
        total_versions=versioning.get('total_versions', 0),
        versions_in_period=versioning.get('versions_in_period', 0),
        current_size_mb=versioning.get('current_size_mb', 0),
        latest_update=versioning.get('latest_update', 'N/A')[:10] if versioning.get('latest_update') else 'N/A',
        analytics_section=analytics_section,
        forms_section=forms_section,
        generated_at=metrics['generated_at'][:19]
    )

def get_site_config(site_id):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(f"bigbeard-site-registry-{get_environment()}")
    response = table.get_item(Key={'site_id': site_id})
    return response.get('Item', {})

def invoke_collector(function_name, payload):
    lambda_client = boto3.client('lambda')
    response = lambda_client.invoke(
        FunctionName=f"bigbeard-{function_name}-{get_environment()}",
        InvocationType='RequestResponse',
        Payload=json.dumps(payload)
    )
    return json.loads(response['Payload'].read())

def send_report_notification(site_config, metrics):
    sns = boto3.client('sns')
    cf = metrics.get('cloudfront', {}).get('metrics', {})

    message = f"""
Static Site Care Report Generated

Site: {site_config['domain']}
Period: {metrics['period']['start']} to {metrics['period']['end']}

CloudFront Metrics:
- Total Requests: {cf.get('total_requests', 0):,}
- Bandwidth: {cf.get('bandwidth_gb', 0)} GB
- Cache Hit Ratio: {cf.get('cache_hit_ratio', 0)}%
- Error Rate: {cf.get('error_rate_4xx', 0) + cf.get('error_rate_5xx', 0):.2f}%

SSL Status: Expires in {metrics.get('ssl', {}).get('days_until_expiry', 'N/A')} days
"""

    if metrics.get('forms'):
        message += f"""
Form Submissions: {metrics['forms'].get('total_submissions', 0)}
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

## Phase 4: Terraform Infrastructure

```hcl
# terraform/static_site_care.tf

# Lambda functions for static site metrics
resource "aws_lambda_function" "cloudfront_collector" {
  function_name = "bigbeard-cloudfront-collector-${var.environment}"
  runtime       = "python3.11"
  handler       = "cloudfront_collector.lambda_handler"
  timeout       = 60
  memory_size   = 256

  role = aws_iam_role.care_report_lambda.arn

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}

resource "aws_lambda_function" "s3_versioning_collector" {
  function_name = "bigbeard-s3-versioning-collector-${var.environment}"
  runtime       = "python3.11"
  handler       = "s3_versioning_collector.lambda_handler"
  timeout       = 120
  memory_size   = 512

  role = aws_iam_role.care_report_lambda.arn

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}

resource "aws_lambda_function" "static_site_report_aggregator" {
  function_name = "bigbeard-static-site-report-aggregator-${var.environment}"
  runtime       = "python3.11"
  handler       = "static_site_report_aggregator.lambda_handler"
  timeout       = 300
  memory_size   = 512

  role = aws_iam_role.care_report_lambda.arn

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}

# IAM Role for static site collectors
resource "aws_iam_role_policy" "static_site_collector_policy" {
  name = "static-site-collector-policy"
  role = aws_iam_role.care_report_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudfront:GetDistribution",
          "cloudfront:ListDistributions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:ListBucketVersions",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::bigbeard-migrated-site-*",
          "arn:aws:s3:::bigbeard-migrated-site-*/*",
          "arn:aws:s3:::bigbeard-care-reports-*",
          "arn:aws:s3:::bigbeard-care-reports-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "acm:ListCertificates",
          "acm:DescribeCertificate"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          "arn:aws:dynamodb:*:*:table/bigbeard-site-registry-*",
          "arn:aws:dynamodb:*:*:table/form-submissions*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = "arn:aws:sns:*:*:bigbeard-care-reports-*"
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "arn:aws:lambda:*:*:function:bigbeard-*-collector-*"
      }
    ]
  })
}
```

---

## Implementation Checklist

| Phase | Task | Status |
|-------|------|--------|
| 1 | Enable S3 versioning on all site buckets | [ ] |
| 1 | Register existing static sites in DynamoDB | [ ] |
| 2 | Deploy CloudFront collector Lambda | [ ] |
| 2 | Deploy S3 versioning collector Lambda | [ ] |
| 2 | Deploy form submissions collector Lambda | [ ] |
| 2 | Deploy SSL collector Lambda | [ ] |
| 3 | Deploy static site report aggregator Lambda | [ ] |
| 3 | Create HTML report template | [ ] |
| 4 | Configure EventBridge schedules | [ ] |
| 4 | Configure SNS notifications | [ ] |
| 5 | Test end-to-end report generation | [ ] |

---

## Comparison: ECS vs Static Site Metrics

| Metric Category | ECS WordPress | Static Site |
|-----------------|---------------|-------------|
| **Platform Info** | WordPress version, plugins | N/A |
| **Updates** | Plugin/theme updates | N/A (content changes via S3) |
| **Backups** | EFS + RDS snapshots | S3 versioning |
| **Performance** | Container CPU/Memory | CloudFront cache ratio |
| **Traffic** | GA4 + ALB metrics | GA4 + CloudFront metrics |
| **Commerce** | WooCommerce API | Form submissions |
| **Security** | WAF + Wordfence | WAF + CloudFront |

---

## Related Documents

- [Website Care Report Metrics](./WEBSITE_CARE_REPORT_METRICS.md)
- [ECS WordPress Care Plan](./ECS_WORDPRESS_CARE_PLAN.md)
