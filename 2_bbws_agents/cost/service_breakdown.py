#!/usr/bin/env python3
"""
Detailed Service Usage Breakdown for BBWS Infrastructure
Analyzes usage patterns and costs for each AWS service
"""

import json
import subprocess
from datetime import datetime
from collections import defaultdict

def get_cost_data(profile, env_name):
    """Fetch cost data from AWS Cost Explorer"""
    end_date = "2025-12-21"
    start_date = "2025-12-14"

    cmd = [
        "aws", "ce", "get-cost-and-usage",
        "--time-period", f"Start={start_date},End={end_date}",
        "--granularity", "DAILY",
        "--metrics", "BlendedCost", "UnblendedCost",
        "--group-by", "Type=DIMENSION,Key=SERVICE",
        "--profile", profile,
        "--region", "af-south-1"
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error fetching data for {env_name}: {result.stderr}")
        return None

    return json.loads(result.stdout)

def analyze_service_usage(cost_data, env_name):
    """Analyze service usage with daily trends"""
    if not cost_data:
        return None

    services = defaultdict(lambda: {
        'daily_costs': [],
        'total_cost': 0,
        'days_active': 0,
        'max_daily_cost': 0,
        'min_daily_cost': float('inf'),
        'trend': 'stable'
    })

    for day in cost_data.get("ResultsByTime", []):
        date = day["TimePeriod"]["Start"]

        for group in day.get("Groups", []):
            service = group["Keys"][0]
            cost = float(group["Metrics"]["UnblendedCost"]["Amount"])

            services[service]['daily_costs'].append({
                'date': date,
                'cost': cost
            })
            services[service]['total_cost'] += cost

            if abs(cost) > 0.01:  # Only count days with meaningful cost
                services[service]['days_active'] += 1

            if cost > services[service]['max_daily_cost']:
                services[service]['max_daily_cost'] = cost
            if cost < services[service]['min_daily_cost'] and cost > 0:
                services[service]['min_daily_cost'] = cost

    # Calculate trends
    for service, data in services.items():
        if len(data['daily_costs']) >= 2:
            first_half = sum(d['cost'] for d in data['daily_costs'][:3])
            second_half = sum(d['cost'] for d in data['daily_costs'][-3:])

            if abs(second_half) > abs(first_half) * 1.2:
                data['trend'] = 'increasing'
            elif abs(second_half) < abs(first_half) * 0.8:
                data['trend'] = 'decreasing'
            else:
                data['trend'] = 'stable'

        if data['min_daily_cost'] == float('inf'):
            data['min_daily_cost'] = 0

    return services

def get_all_services(dev_services, sit_services, prod_services):
    """Get unique list of all services across environments"""
    all_services = set()
    if dev_services:
        all_services.update(dev_services.keys())
    if sit_services:
        all_services.update(sit_services.keys())
    if prod_services:
        all_services.update(prod_services.keys())
    return sorted(all_services)

def generate_service_breakdown(dev_services, sit_services, prod_services):
    """Generate detailed service breakdown report"""

    print("=" * 120)
    print("DETAILED SERVICE USAGE BREAKDOWN - 7 DAYS (2025-12-14 to 2025-12-21)")
    print("=" * 120)
    print()

    all_services = get_all_services(dev_services, sit_services, prod_services)

    # Calculate totals for each service across all environments
    service_totals = {}
    for service in all_services:
        dev_cost = dev_services.get(service, {}).get('total_cost', 0) if dev_services else 0
        sit_cost = sit_services.get(service, {}).get('total_cost', 0) if sit_services else 0
        prod_cost = prod_services.get(service, {}).get('total_cost', 0) if prod_services else 0
        total = dev_cost + sit_cost + prod_cost
        service_totals[service] = {
            'dev': dev_cost,
            'sit': sit_cost,
            'prod': prod_cost,
            'total': total
        }

    # Sort services by total cost
    sorted_services = sorted(service_totals.items(), key=lambda x: abs(x[1]['total']), reverse=True)

    # Overall service summary table
    print("SERVICE COST SUMMARY (All Environments)")
    print("-" * 120)
    print(f"{'Service':<50} {'DEV':<15} {'SIT':<15} {'PROD':<15} {'Total':<15}")
    print("-" * 120)

    for service, costs in sorted_services:
        if abs(costs['total']) > 0.01:  # Only show services with meaningful costs
            service_display = service[:48] if len(service) > 48 else service
            print(f"{service_display:<50} ${costs['dev']:>13.2f} ${costs['sit']:>13.2f} "
                  f"${costs['prod']:>13.2f} ${costs['total']:>13.2f}")

    print()
    print()

    # Detailed breakdown for each significant service
    print("=" * 120)
    print("DETAILED SERVICE ANALYSIS")
    print("=" * 120)
    print()

    for service, costs in sorted_services:
        if abs(costs['total']) < 0.01:  # Skip services with negligible costs
            continue

        print("-" * 120)
        print(f"SERVICE: {service}")
        print("-" * 120)
        print()

        # Environment-specific details
        for env_name, env_services in [('DEV', dev_services), ('SIT', sit_services), ('PROD', prod_services)]:
            if not env_services or service not in env_services:
                continue

            data = env_services[service]

            if abs(data['total_cost']) < 0.01:
                continue

            print(f"  {env_name} Environment:")
            print(f"    Total Cost:        ${data['total_cost']:>10.2f}")
            print(f"    Days Active:       {data['days_active']:>10} days")

            if data['days_active'] > 0:
                avg_cost = data['total_cost'] / data['days_active']
                print(f"    Avg Daily Cost:    ${avg_cost:>10.2f}")
                print(f"    Max Daily Cost:    ${data['max_daily_cost']:>10.2f}")
                print(f"    Min Daily Cost:    ${data['min_daily_cost']:>10.2f}")
                print(f"    Cost Trend:        {data['trend']:>10}")

            # Daily breakdown
            print(f"    Daily Breakdown:")
            for day_data in data['daily_costs']:
                if abs(day_data['cost']) > 0.01:
                    print(f"      {day_data['date']}: ${day_data['cost']:>10.2f}")
            print()

        print()

    # Service Categories Analysis
    print()
    print("=" * 120)
    print("SERVICE CATEGORY ANALYSIS")
    print("=" * 120)
    print()

    categories = {
        'Compute': ['Amazon Elastic Compute Cloud - Compute', 'Amazon Elastic Container Service',
                    'EC2 - Other', 'AWS Lambda', 'AWS App Runner'],
        'Storage': ['Amazon Simple Storage Service', 'Amazon Elastic File System',
                   'Amazon EC2 Container Registry (ECR)', 'AWS Backup'],
        'Database': ['Amazon DynamoDB', 'Amazon Relational Database Service'],
        'Networking': ['Amazon Elastic Load Balancing', 'Amazon Virtual Private Cloud',
                      'AWS Data Transfer', 'Amazon CloudFront', 'Amazon Route 53'],
        'Security': ['AWS WAF', 'Amazon GuardDuty', 'Amazon Inspector', 'AWS Security Hub',
                    'AWS Secrets Manager', 'AWS Key Management Service', 'Amazon Detective'],
        'Management': ['AmazonCloudWatch', 'AWS CloudTrail', 'AWS Config', 'AWS Glue',
                      'AWS Cost Explorer'],
        'Domains & DNS': ['Amazon Registrar'],
        'Other': ['Tax', 'Amazon Location Service', 'Amazon Cognito', 'Amazon Simple Notification Service',
                 'Amazon Simple Queue Service', 'Amazon Simple Email Service']
    }

    category_costs = defaultdict(lambda: {'dev': 0, 'sit': 0, 'prod': 0, 'total': 0})

    for service, costs in service_totals.items():
        categorized = False
        for category, services_list in categories.items():
            if service in services_list:
                category_costs[category]['dev'] += costs['dev']
                category_costs[category]['sit'] += costs['sit']
                category_costs[category]['prod'] += costs['prod']
                category_costs[category]['total'] += costs['total']
                categorized = True
                break

        if not categorized:
            category_costs['Uncategorized']['dev'] += costs['dev']
            category_costs['Uncategorized']['sit'] += costs['sit']
            category_costs['Uncategorized']['prod'] += costs['prod']
            category_costs['Uncategorized']['total'] += costs['total']

    print(f"{'Category':<25} {'DEV':<15} {'SIT':<15} {'PROD':<15} {'Total':<15} {'% of Total':<12}")
    print("-" * 120)

    total_all = sum(c['total'] for c in category_costs.values())
    sorted_categories = sorted(category_costs.items(), key=lambda x: abs(x[1]['total']), reverse=True)

    for category, costs in sorted_categories:
        if abs(costs['total']) > 0.01:
            pct = (abs(costs['total']) / abs(total_all) * 100) if total_all != 0 else 0
            print(f"{category:<25} ${costs['dev']:>13.2f} ${costs['sit']:>13.2f} "
                  f"${costs['prod']:>13.2f} ${costs['total']:>13.2f} {pct:>10.1f}%")

    print()
    print("=" * 120)
    print("KEY INSIGHTS")
    print("=" * 120)
    print()

    # Generate insights
    insights = []

    # 1. Highest cost service
    top_service = sorted_services[0]
    insights.append(f"1. Highest Cost Service: {top_service[0]} (${abs(top_service[1]['total']):.2f}, "
                   f"{abs(top_service[1]['total'])/abs(total_all)*100:.1f}% of total)")

    # 2. Services with increasing costs
    increasing_services = []
    for env_name, env_services in [('DEV', dev_services), ('SIT', sit_services), ('PROD', prod_services)]:
        if env_services:
            for service, data in env_services.items():
                if data['trend'] == 'increasing' and abs(data['total_cost']) > 1:
                    increasing_services.append((env_name, service, data['total_cost']))

    if increasing_services:
        insights.append(f"2. Services with Increasing Costs ({len(increasing_services)} found):")
        for env, service, cost in increasing_services[:5]:
            insights.append(f"   - {env}: {service} (${abs(cost):.2f})")
    else:
        insights.append("2. No services showing significant cost increases")

    # 3. Idle or low-usage services
    idle_services = []
    for env_name, env_services in [('DEV', dev_services), ('SIT', sit_services), ('PROD', prod_services)]:
        if env_services:
            for service, data in env_services.items():
                if data['days_active'] < 3 and abs(data['total_cost']) > 0.5:
                    idle_services.append((env_name, service, data['days_active'], data['total_cost']))

    if idle_services:
        insights.append(f"3. Low-Usage Services (Active <3 days, {len(idle_services)} found):")
        for env, service, days, cost in idle_services[:5]:
            insights.append(f"   - {env}: {service} - {days} days active, ${abs(cost):.2f} cost")
    else:
        insights.append("3. All significant services are consistently active")

    # 4. Category distribution
    top_category = sorted_categories[0]
    insights.append(f"4. Dominant Cost Category: {top_category[0]} (${abs(top_category[1]['total']):.2f}, "
                   f"{abs(top_category[1]['total'])/abs(total_all)*100:.1f}% of total)")

    for insight in insights:
        print(insight)

    print()
    print("=" * 120)
    print(f"Report Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 120)

def main():
    """Main execution"""

    print("Analyzing DEV environment services...")
    dev_data = get_cost_data("Tebogo-dev", "DEV")
    dev_services = analyze_service_usage(dev_data, "DEV")

    print("Analyzing SIT environment services...")
    sit_data = get_cost_data("Tebogo-sit", "SIT")
    sit_services = analyze_service_usage(sit_data, "SIT")

    print("Analyzing PROD environment services...")
    prod_data = get_cost_data("Tebogo-prod", "PROD")
    prod_services = analyze_service_usage(prod_data, "PROD")

    print("\nGenerating service breakdown report...\n")
    generate_service_breakdown(dev_services, sit_services, prod_services)

    # Save detailed data
    output_data = {
        "report_date": datetime.now().isoformat(),
        "analysis_period": {
            "start": "2025-12-14",
            "end": "2025-12-21",
            "days": 7
        },
        "service_breakdown": {
            "dev": {k: v for k, v in dev_services.items()} if dev_services else {},
            "sit": {k: v for k, v in sit_services.items()} if sit_services else {},
            "prod": {k: v for k, v in prod_services.items()} if prod_services else {}
        }
    }

    output_file = f"service_breakdown_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(output_file, 'w') as f:
        json.dump(output_data, f, indent=2, default=str)

    print(f"\nDetailed service breakdown saved to: {output_file}")

if __name__ == "__main__":
    main()
