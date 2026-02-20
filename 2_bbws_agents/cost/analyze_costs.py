#!/usr/bin/env python3
"""
7-Day Cost Analysis Script for BBWS Multi-Environment Infrastructure
Analyzes costs across DEV, SIT, and PROD environments
"""

import json
import subprocess
from datetime import datetime, timedelta
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

def analyze_environment_costs(cost_data, env_name):
    """Analyze costs for a single environment"""
    if not cost_data:
        return None

    service_totals = defaultdict(float)
    daily_totals = []

    for day in cost_data.get("ResultsByTime", []):
        period = day["TimePeriod"]["Start"]
        day_total = 0

        for group in day.get("Groups", []):
            service = group["Keys"][0]
            cost = float(group["Metrics"]["UnblendedCost"]["Amount"])
            service_totals[service] += cost
            day_total += cost

        daily_totals.append({
            "date": period,
            "cost": day_total
        })

    # Calculate total cost
    total_cost = sum(service_totals.values())

    # Get top 10 services by cost
    top_services = sorted(service_totals.items(), key=lambda x: abs(x[1]), reverse=True)[:10]

    return {
        "environment": env_name,
        "total_cost": total_cost,
        "daily_costs": daily_totals,
        "top_services": top_services,
        "service_totals": dict(service_totals)
    }

def generate_report(dev_analysis, sit_analysis, prod_analysis):
    """Generate comprehensive cost report"""

    print("=" * 80)
    print("AWS COST ANALYSIS REPORT - 7 DAYS (2025-12-14 to 2025-12-21)")
    print("=" * 80)
    print()

    # Summary Table
    print("ENVIRONMENT SUMMARY")
    print("-" * 80)
    print(f"{'Environment':<15} {'Total Cost (USD)':<20} {'Avg Daily Cost (USD)':<20}")
    print("-" * 80)

    environments = []
    for analysis in [dev_analysis, sit_analysis, prod_analysis]:
        if analysis:
            env_name = analysis["environment"]
            total = analysis["total_cost"]
            avg_daily = total / 7
            print(f"{env_name:<15} ${total:>18.2f} ${avg_daily:>18.2f}")
            environments.append(analysis)

    # Grand total
    grand_total = sum(env["total_cost"] for env in environments)
    print("-" * 80)
    print(f"{'TOTAL':<15} ${grand_total:>18.2f} ${grand_total/7:>18.2f}")
    print()

    # Detailed breakdown by environment
    for analysis in environments:
        if not analysis:
            continue

        env_name = analysis["environment"]
        print()
        print("=" * 80)
        print(f"{env_name} ENVIRONMENT - DETAILED BREAKDOWN")
        print("=" * 80)
        print()

        # Daily costs
        print("Daily Cost Trend:")
        print("-" * 80)
        print(f"{'Date':<15} {'Cost (USD)':<20}")
        print("-" * 80)
        for day in analysis["daily_costs"]:
            print(f"{day['date']:<15} ${day['cost']:>18.2f}")
        print()

        # Top services
        print("Top 10 Services by Cost:")
        print("-" * 80)
        print(f"{'Service':<50} {'Cost (USD)':<20} {'% of Total':<15}")
        print("-" * 80)

        total = analysis["total_cost"]
        for service, cost in analysis["top_services"]:
            percentage = (cost / total * 100) if total != 0 else 0
            # Clean up service names for better readability
            service_display = service[:48] if len(service) > 48 else service
            print(f"{service_display:<50} ${cost:>18.2f} {percentage:>13.1f}%")
        print()

    # Cross-environment comparison
    print()
    print("=" * 80)
    print("CROSS-ENVIRONMENT SERVICE COMPARISON (Top Services)")
    print("=" * 80)
    print()

    # Collect all unique services across environments
    all_services = set()
    for analysis in environments:
        if analysis:
            all_services.update(analysis["service_totals"].keys())

    # Get top services by combined cost
    service_env_costs = defaultdict(lambda: {"DEV": 0, "SIT": 0, "PROD": 0, "TOTAL": 0})

    for analysis in environments:
        if analysis:
            env_name = analysis["environment"]
            for service, cost in analysis["service_totals"].items():
                service_env_costs[service][env_name] = cost
                service_env_costs[service]["TOTAL"] += cost

    # Sort by total cost
    sorted_services = sorted(service_env_costs.items(), key=lambda x: abs(x[1]["TOTAL"]), reverse=True)[:15]

    print(f"{'Service':<40} {'DEV (USD)':<15} {'SIT (USD)':<15} {'PROD (USD)':<15} {'Total (USD)':<15}")
    print("-" * 100)

    for service, costs in sorted_services:
        service_display = service[:38] if len(service) > 38 else service
        print(f"{service_display:<40} ${costs['DEV']:>13.2f} ${costs['SIT']:>13.2f} ${costs['PROD']:>13.2f} ${costs['TOTAL']:>13.2f}")

    print()
    print("=" * 80)
    print("COST INSIGHTS")
    print("=" * 80)
    print()

    # Generate insights
    if dev_analysis and sit_analysis and prod_analysis:
        dev_total = dev_analysis["total_cost"]
        sit_total = sit_analysis["total_cost"]
        prod_total = prod_analysis["total_cost"]

        print(f"1. Environment Distribution:")
        print(f"   - DEV:  ${dev_total:>10.2f} ({dev_total/grand_total*100:>5.1f}% of total)")
        print(f"   - SIT:  ${sit_total:>10.2f} ({sit_total/grand_total*100:>5.1f}% of total)")
        print(f"   - PROD: ${prod_total:>10.2f} ({prod_total/grand_total*100:>5.1f}% of total)")
        print()

        # Identify cost anomalies
        if dev_total > prod_total:
            print(f"2. ⚠️  ALERT: DEV environment costs (${dev_total:.2f}) exceed PROD costs (${prod_total:.2f})")
            print(f"   Consider reviewing DEV resource usage and cleanup unused resources.")
        else:
            print(f"2. ✓ PROD environment has higher costs than DEV, which is expected.")
        print()

        # Identify top cost drivers
        print("3. Top Cost Drivers Across All Environments:")
        for i, (service, costs) in enumerate(sorted_services[:5], 1):
            print(f"   {i}. {service}: ${costs['TOTAL']:.2f}")
        print()

    print("=" * 80)
    print("Report generated on:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    print("=" * 80)

def main():
    """Main execution function"""

    print("Fetching cost data for DEV environment...")
    dev_data = get_cost_data("Tebogo-dev", "DEV")
    dev_analysis = analyze_environment_costs(dev_data, "DEV")

    print("Fetching cost data for SIT environment...")
    sit_data = get_cost_data("Tebogo-sit", "SIT")
    sit_analysis = analyze_environment_costs(sit_data, "SIT")

    print("Fetching cost data for PROD environment...")
    prod_data = get_cost_data("Tebogo-prod", "PROD")
    prod_analysis = analyze_environment_costs(prod_data, "PROD")

    print("\nGenerating comprehensive report...\n")
    generate_report(dev_analysis, sit_analysis, prod_analysis)

    # Save detailed data to JSON
    output_data = {
        "report_date": datetime.now().isoformat(),
        "analysis_period": {
            "start": "2025-12-14",
            "end": "2025-12-21",
            "days": 7
        },
        "environments": {
            "dev": dev_analysis,
            "sit": sit_analysis,
            "prod": prod_analysis
        }
    }

    output_file = f"cost_analysis_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(output_file, 'w') as f:
        json.dump(output_data, f, indent=2)

    print(f"\nDetailed analysis saved to: {output_file}")

if __name__ == "__main__":
    main()
