# Website Care Report Metrics

**Created**: 2026-02-02
**Purpose**: Define standardized metrics for Website Care Reports across ECS WordPress and Static Site deployments
**Reference**: BigBeard Website Care Report (premiumkingseeds.com)

---

## Overview

This document maps metrics from the BigBeard Website Care Report to AWS infrastructure for two deployment types:
1. **ECS WordPress Sites** - Containerized WordPress on ECS with EFS/RDS
2. **Static Sites** - Extracted HTML sites on S3/CloudFront

---

## Metric Categories

### 1. Site Information

| Metric | WordPress Report | ECS WordPress | Static Site | Data Source |
|--------|-----------------|---------------|-------------|-------------|
| Website URL | premiumkingseeds.com | Same | Same | Configuration |
| IP Address | 197.221.12.211 | ECS Task ENI / ALB DNS | CloudFront Edge IP | AWS API |
| Platform Version | WordPress 6.9 | WordPress version | N/A (Static HTML) | WP-CLI / Metadata |
| Theme | Hello Elementor Child | Same | N/A | WP-CLI |
| Active Plugins | 23 | Same | N/A | WP-CLI |

---

### 2. Updates (ECS WordPress Only)

| Metric | Description | Data Source | Collection Method |
|--------|-------------|-------------|-------------------|
| Total Updates | Count of updates performed | ManageWP API | API call |
| Plugin Updates | Plugin version changes | ManageWP / WP-CLI | Scheduled job |
| Theme Updates | Theme version changes | ManageWP / WP-CLI | Scheduled job |
| Core Updates | WordPress core updates | ManageWP / WP-CLI | Scheduled job |

**Sample Data Structure:**
```json
{
  "period": "2026-01-01 to 2026-01-31",
  "total_updates": 23,
  "plugins": [
    {"name": "Site Kit by Google", "from": "1.170.0", "to": "1.171.0", "date": "2026-01-30"}
  ]
}
```

---

### 3. Backups

#### ECS WordPress Backups

| Metric | Description | Data Source |
|--------|-------------|-------------|
| EFS Snapshots | File system backup count | AWS Backup |
| RDS Snapshots | Database backup count | RDS API |
| Total Size | Combined backup size (GB) | CloudWatch |
| Latest Backup | Most recent backup timestamp | AWS Backup |
| Retention | Days backups are retained | AWS Backup Policy |

#### Static Site Backups

| Metric | Description | Data Source |
|--------|-------------|-------------|
| S3 Versions | Version count for site files | S3 API |
| Version Size | Total versioned storage | S3 Storage Lens |
| Latest Version | Most recent file update | S3 API |

---

### 4. Analytics (Both Deployment Types)

| Metric | Description | ECS Source | Static Source |
|--------|-------------|------------|---------------|
| Sessions | Total visitor sessions | GA4 / Site Kit | GA4 / CloudFront |
| Session Change % | Period-over-period change | GA4 API | GA4 API |
| Page Views | Total page views | GA4 | GA4 / CloudFront |
| Unique Visitors | Distinct users | GA4 | GA4 |
| Bounce Rate | Single-page sessions % | GA4 | GA4 |
| Avg Session Duration | Time on site | GA4 | GA4 |
| Top Pages | Most visited pages | GA4 | GA4 / CloudFront Logs |
| Geographic Distribution | Visitor locations | GA4 | CloudFront |

**CloudFront-Specific Metrics (Static Sites):**

| Metric | Description | Data Source |
|--------|-------------|-------------|
| Request Count | Total HTTP requests | CloudFront Metrics |
| Cache Hit Ratio | % served from cache | CloudFront Metrics |
| Error Rate (4xx/5xx) | HTTP error percentage | CloudFront Metrics |
| Bandwidth | Data transfer (GB) | CloudFront Metrics |
| Origin Latency | Response time from S3 | CloudFront Metrics |

---

### 5. E-Commerce (WooCommerce - ECS WordPress)

| Metric | Description | Data Source |
|--------|-------------|-------------|
| Gross Sales | Total revenue before deductions | WooCommerce REST API |
| Net Sales | Revenue after refunds/discounts | WooCommerce REST API |
| Refunds | Refund amount and count | WooCommerce REST API |
| Coupons Used | Discount value applied | WooCommerce REST API |
| Shipping Revenue | Shipping charges collected | WooCommerce REST API |
| Orders | Total order count | WooCommerce REST API |
| Items Sold | Product units sold | WooCommerce REST API |
| New Signups | Customer registrations | WooCommerce REST API |
| Top Products | Best-selling items | WooCommerce REST API |
| Top Categories | Revenue by category | WooCommerce REST API |

---

### 6. Performance Metrics

#### ECS WordPress Performance

| Metric | Description | Data Source |
|--------|-------------|-------------|
| Container CPU | CPU utilization % | CloudWatch ECS |
| Container Memory | Memory utilization % | CloudWatch ECS |
| Task Count | Running task instances | ECS API |
| ALB Response Time | Load balancer latency | CloudWatch ALB |
| RDS Connections | Database connections | CloudWatch RDS |
| RDS CPU | Database CPU % | CloudWatch RDS |
| EFS Throughput | File system I/O | CloudWatch EFS |

#### Static Site Performance

| Metric | Description | Data Source |
|--------|-------------|-------------|
| Cache Hit Ratio | CloudFront cache efficiency | CloudFront Metrics |
| TTFB | Time to first byte | Real User Monitoring |
| Error Rate | 4xx/5xx responses | CloudFront Metrics |
| Edge Locations | Geographic distribution | CloudFront |

---

### 7. Security Metrics

| Metric | ECS WordPress | Static Site | Data Source |
|--------|---------------|-------------|-------------|
| SSL Certificate Status | ACM certificate validity | ACM certificate validity | ACM API |
| SSL Expiry | Days until expiration | Days until expiration | ACM API |
| WAF Blocks | Blocked malicious requests | Blocked requests | WAF Logs |
| Failed Logins | Authentication failures | N/A | WordPress logs |
| Security Scans | Vulnerability scan results | N/A | Wordfence/Sucuri |

---

### 8. Availability Metrics

| Metric | Description | Data Source |
|--------|-------------|-------------|
| Uptime % | Availability percentage | Route53 Health Checks |
| Downtime Events | Outage count and duration | CloudWatch Alarms |
| Health Check Status | Current health state | Route53 / ALB |

---

## Report Generation Architecture

```
                                  +------------------+
                                  |  Report Lambda   |
                                  |  (Aggregator)    |
                                  +--------+---------+
                                           |
              +----------------------------+----------------------------+
              |                            |                            |
    +---------v---------+        +---------v---------+        +---------v---------+
    |  ECS Metrics      |        |  Static Metrics   |        |  Common Metrics   |
    |  Collector        |        |  Collector        |        |  Collector        |
    +---------+---------+        +---------+---------+        +---------+---------+
              |                            |                            |
    +---------v---------+        +---------v---------+        +---------v---------+
    | - ManageWP API    |        | - CloudFront API  |        | - GA4 API         |
    | - WP-CLI via SSM  |        | - S3 API          |        | - Route53 API     |
    | - RDS Metrics     |        | - CloudWatch      |        | - ACM API         |
    | - EFS Metrics     |        |                   |        | - WAF Logs        |
    | - WooCommerce API |        |                   |        |                   |
    +-------------------+        +-------------------+        +-------------------+
```

---

## Unified Report Template

```markdown
# Website Care Report: {site_name}
**Period**: {start_date} to {end_date}
**Generated**: {generation_timestamp}

## Site Overview
- **URL**: {url}
- **Type**: {ECS WordPress | Static Site}
- **Region**: {aws_region}

## Health Summary
| Metric | Status | Value |
|--------|--------|-------|
| Uptime | {status_icon} | {uptime_percent}% |
| SSL Certificate | {status_icon} | Expires {ssl_expiry} |
| Last Backup | {status_icon} | {backup_timestamp} |

## Updates (WordPress Only)
- Total Updates: {update_count}
- Plugin Updates: {plugin_count}
- Last Update: {last_update_date}

## Backups
- Backups Created: {backup_count}
- Total Available: {total_backups}
- Size: {backup_size_gb} GB

## Analytics
- Sessions: {sessions} ({session_change}% vs previous)
- Page Views: {pageviews}
- Bounce Rate: {bounce_rate}%

## Performance
- Response Time: {response_time_ms}ms
- Cache Hit Ratio: {cache_hit_ratio}%
- Error Rate: {error_rate}%

## Commerce (WooCommerce Only)
- Gross Sales: R{gross_sales}
- Net Sales: R{net_sales}
- Orders: {order_count}
```

---

## Implementation Priority

| Phase | Metrics | Effort | Value |
|-------|---------|--------|-------|
| 1 | Uptime, SSL, Backups | Low | High |
| 2 | Analytics (GA4/CloudFront) | Medium | High |
| 3 | Performance metrics | Medium | Medium |
| 4 | WooCommerce integration | High | High (e-commerce sites) |
| 5 | Automated PDF generation | Medium | High |

---

## Related Documents

- [ECS WordPress Care Plan](./ECS_WORDPRESS_CARE_PLAN.md)
- [Static Site Care Plan](./STATIC_SITE_CARE_PLAN.md)
