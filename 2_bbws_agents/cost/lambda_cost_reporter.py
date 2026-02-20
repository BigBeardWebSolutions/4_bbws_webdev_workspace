"""
AWS Lambda Function: Automated Cost Reporter
Generates daily/weekly cost reports and sends them via SNS/Email

Environment Variables Required:
- SNS_TOPIC_ARN: ARN of SNS topic for notifications
- REPORT_TYPE: 'daily' or 'weekly'
- DEV_ACCOUNT_ROLE_ARN: Role ARN for DEV account
- SIT_ACCOUNT_ROLE_ARN: Role ARN for SIT account
- PROD_ACCOUNT_ROLE_ARN: Role ARN for PROD account
"""

import json
import boto3
import os
from datetime import datetime, timedelta
from collections import defaultdict
from decimal import Decimal

# Initialize AWS clients
ce_client = boto3.client('ce', region_name='us-east-1')  # Cost Explorer is only in us-east-1
sns_client = boto3.client('sns')
sts_client = boto3.client('sts')


class DecimalEncoder(json.JSONEncoder):
    """Custom JSON encoder for Decimal objects"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)


def assume_role(role_arn):
    """Assume role in another account"""
    response = sts_client.assume_role(
        RoleArn=role_arn,
        RoleSessionName='CostReporterSession'
    )
    credentials = response['Credentials']
    return boto3.client(
        'ce',
        region_name='us-east-1',
        aws_access_key_id=credentials['AccessKeyId'],
        aws_secret_access_key=credentials['SecretAccessKey'],
        aws_session_token=credentials['SessionToken']
    )


def get_date_range(report_type):
    """Calculate date range based on report type"""
    end_date = datetime.now().date()

    if report_type == 'weekly':
        start_date = end_date - timedelta(days=7)
        period_label = "Last 7 Days"
    elif report_type == 'monthly':
        # Get first day of current month
        first_day_current_month = end_date.replace(day=1)
        # Get first day of previous month
        if first_day_current_month.month == 1:
            start_date = first_day_current_month.replace(year=first_day_current_month.year - 1, month=12)
        else:
            start_date = first_day_current_month.replace(month=first_day_current_month.month - 1)
        period_label = f"Last Month ({start_date.strftime('%B %Y')})"
    else:
        # Default to weekly
        start_date = end_date - timedelta(days=7)
        period_label = "Last 7 Days"

    return start_date.strftime('%Y-%m-%d'), end_date.strftime('%Y-%m-%d'), period_label


def get_cost_data(ce_client, start_date, end_date):
    """Fetch cost data from AWS Cost Explorer"""
    try:
        response = ce_client.get_cost_and_usage(
            TimePeriod={
                'Start': start_date,
                'End': end_date
            },
            Granularity='DAILY',
            Metrics=['UnblendedCost'],
            GroupBy=[
                {'Type': 'DIMENSION', 'Key': 'SERVICE'}
            ]
        )
        return response
    except Exception as e:
        print(f"Error fetching cost data: {str(e)}")
        return None


def analyze_costs(cost_data, env_name):
    """Analyze cost data for an environment"""
    if not cost_data:
        return None

    service_totals = defaultdict(float)
    daily_totals = []
    total_cost = 0

    for day in cost_data.get('ResultsByTime', []):
        date = day['TimePeriod']['Start']
        day_total = 0

        for group in day.get('Groups', []):
            service = group['Keys'][0]
            cost = float(group['Metrics']['UnblendedCost']['Amount'])
            service_totals[service] += cost
            day_total += cost

        daily_totals.append({'date': date, 'cost': day_total})
        total_cost += day_total

    # Get top 5 services
    top_services = sorted(
        service_totals.items(),
        key=lambda x: abs(x[1]),
        reverse=True
    )[:5]

    return {
        'environment': env_name,
        'total_cost': total_cost,
        'daily_totals': daily_totals,
        'top_services': top_services,
        'service_count': len(service_totals)
    }


def generate_html_report(dev_data, sit_data, prod_data, period_label, start_date, end_date):
    """Generate HTML email report"""

    total_all_envs = 0
    if dev_data:
        total_all_envs += dev_data['total_cost']
    if sit_data:
        total_all_envs += sit_data['total_cost']
    if prod_data:
        total_all_envs += prod_data['total_cost']

    # Calculate percentages
    dev_pct = (dev_data['total_cost'] / total_all_envs * 100) if dev_data and total_all_envs > 0 else 0
    sit_pct = (sit_data['total_cost'] / total_all_envs * 100) if sit_data and total_all_envs > 0 else 0
    prod_pct = (prod_data['total_cost'] / total_all_envs * 100) if prod_data and total_all_envs > 0 else 0

    # Check for anomalies
    alerts = []
    if dev_data and prod_data and dev_data['total_cost'] > prod_data['total_cost']:
        alerts.append("⚠️ DEV environment costs exceed PROD costs")
    if total_all_envs > 100:  # Arbitrary threshold
        alerts.append(f"⚠️ High spending detected: ${total_all_envs:.2f}")

    html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {{
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                line-height: 1.6;
                color: #333;
                max-width: 900px;
                margin: 0 auto;
                padding: 20px;
                background-color: #f5f5f5;
            }}
            .header {{
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 30px;
                border-radius: 10px;
                margin-bottom: 30px;
                text-align: center;
            }}
            .header h1 {{
                margin: 0;
                font-size: 28px;
            }}
            .header p {{
                margin: 10px 0 0 0;
                font-size: 16px;
                opacity: 0.9;
            }}
            .summary {{
                background: white;
                padding: 25px;
                border-radius: 10px;
                margin-bottom: 20px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }}
            .summary h2 {{
                margin-top: 0;
                color: #667eea;
                border-bottom: 2px solid #667eea;
                padding-bottom: 10px;
            }}
            .env-card {{
                background: white;
                padding: 20px;
                border-radius: 10px;
                margin-bottom: 20px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }}
            .env-card h3 {{
                margin-top: 0;
                color: #555;
            }}
            .env-card.dev {{
                border-left: 4px solid #3498db;
            }}
            .env-card.sit {{
                border-left: 4px solid #f39c12;
            }}
            .env-card.prod {{
                border-left: 4px solid #e74c3c;
            }}
            table {{
                width: 100%;
                border-collapse: collapse;
                margin-top: 15px;
            }}
            th, td {{
                padding: 12px;
                text-align: left;
                border-bottom: 1px solid #ddd;
            }}
            th {{
                background-color: #f8f9fa;
                font-weight: 600;
                color: #555;
            }}
            tr:hover {{
                background-color: #f8f9fa;
            }}
            .cost {{
                font-weight: bold;
                color: #667eea;
            }}
            .alert {{
                background-color: #fff3cd;
                border-left: 4px solid #ffc107;
                padding: 15px;
                margin-bottom: 20px;
                border-radius: 5px;
            }}
            .alert-icon {{
                font-size: 20px;
                margin-right: 10px;
            }}
            .footer {{
                text-align: center;
                color: #777;
                font-size: 12px;
                margin-top: 30px;
                padding-top: 20px;
                border-top: 1px solid #ddd;
            }}
            .metric {{
                display: inline-block;
                margin: 10px 20px;
                text-align: center;
            }}
            .metric-value {{
                font-size: 32px;
                font-weight: bold;
                color: #667eea;
            }}
            .metric-label {{
                font-size: 14px;
                color: #777;
                text-transform: uppercase;
            }}
            .progress-bar {{
                width: 100%;
                height: 20px;
                background-color: #e0e0e0;
                border-radius: 10px;
                overflow: hidden;
                margin: 10px 0;
            }}
            .progress-fill {{
                height: 100%;
                background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
                text-align: center;
                color: white;
                font-size: 12px;
                line-height: 20px;
            }}
        </style>
    </head>
    <body>
        <div class="header">
            <h1>AWS Cost Report</h1>
            <p>{period_label}: {start_date} to {end_date}</p>
        </div>

        {''.join([f'<div class="alert"><span class="alert-icon">⚠️</span>{alert}</div>' for alert in alerts])}

        <div class="summary">
            <h2>Summary</h2>
            <div style="text-align: center;">
                <div class="metric">
                    <div class="metric-value">${total_all_envs:.2f}</div>
                    <div class="metric-label">Total Cost</div>
                </div>
                <div class="metric">
                    <div class="metric-value">{len([d for d in [dev_data, sit_data, prod_data] if d])}</div>
                    <div class="metric-label">Environments</div>
                </div>
            </div>

            <table>
                <tr>
                    <th>Environment</th>
                    <th>Cost</th>
                    <th>% of Total</th>
                    <th>Distribution</th>
                </tr>
                <tr>
                    <td>DEV</td>
                    <td class="cost">${(dev_data['total_cost'] if dev_data else 0):.2f}</td>
                    <td>{dev_pct:.1f}%</td>
                    <td>
                        <div class="progress-bar">
                            <div class="progress-fill" style="width: {dev_pct}%">{dev_pct:.0f}%</div>
                        </div>
                    </td>
                </tr>
                <tr>
                    <td>SIT</td>
                    <td class="cost">${(sit_data['total_cost'] if sit_data else 0):.2f}</td>
                    <td>{sit_pct:.1f}%</td>
                    <td>
                        <div class="progress-bar">
                            <div class="progress-fill" style="width: {sit_pct}%">{sit_pct:.0f}%</div>
                        </div>
                    </td>
                </tr>
                <tr>
                    <td>PROD</td>
                    <td class="cost">${(prod_data['total_cost'] if prod_data else 0):.2f}</td>
                    <td>{prod_pct:.1f}%</td>
                    <td>
                        <div class="progress-bar">
                            <div class="progress-fill" style="width: {prod_pct}%">{prod_pct:.0f}%</div>
                        </div>
                    </td>
                </tr>
            </table>
        </div>
    """

    # Add environment details
    for env_data, env_class in [(dev_data, 'dev'), (sit_data, 'sit'), (prod_data, 'prod')]:
        if not env_data:
            continue

        html += f"""
        <div class="env-card {env_class}">
            <h3>{env_data['environment']} Environment</h3>
            <p><strong>Total Cost:</strong> <span class="cost">${env_data['total_cost']:.2f}</span></p>
            <p><strong>Services Used:</strong> {env_data['service_count']}</p>

            <h4>Top 5 Services by Cost</h4>
            <table>
                <tr>
                    <th>Service</th>
                    <th>Cost</th>
                </tr>
        """

        for service, cost in env_data['top_services']:
            html += f"""
                <tr>
                    <td>{service}</td>
                    <td class="cost">${abs(cost):.2f}</td>
                </tr>
            """

        html += """
            </table>
        </div>
        """

    html += f"""
        <div class="footer">
            <p>Generated by BBWS Cost Reporter on {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}</p>
            <p>This is an automated report. For detailed analysis, check the AWS Cost Explorer console.</p>
        </div>
    </body>
    </html>
    """

    return html


def generate_text_report(dev_data, sit_data, prod_data, period_label, start_date, end_date):
    """Generate plain text email report"""

    total_all_envs = 0
    if dev_data:
        total_all_envs += dev_data['total_cost']
    if sit_data:
        total_all_envs += sit_data['total_cost']
    if prod_data:
        total_all_envs += prod_data['total_cost']

    text = f"""
AWS COST REPORT
{period_label}: {start_date} to {end_date}
{'=' * 80}

SUMMARY
{'-' * 80}
Total Cost (All Environments): ${total_all_envs:.2f}

Environment Breakdown:
  DEV:  ${(dev_data['total_cost'] if dev_data else 0):.2f} ({(dev_data['total_cost']/total_all_envs*100 if dev_data and total_all_envs > 0 else 0):.1f}%)
  SIT:  ${(sit_data['total_cost'] if sit_data else 0):.2f} ({(sit_data['total_cost']/total_all_envs*100 if sit_data and total_all_envs > 0 else 0):.1f}%)
  PROD: ${(prod_data['total_cost'] if prod_data else 0):.2f} ({(prod_data['total_cost']/total_all_envs*100 if prod_data and total_all_envs > 0 else 0):.1f}%)

"""

    # Add alerts
    if dev_data and prod_data and dev_data['total_cost'] > prod_data['total_cost']:
        text += "\n⚠️ ALERT: DEV environment costs exceed PROD costs\n"

    # Add environment details
    for env_data in [dev_data, sit_data, prod_data]:
        if not env_data:
            continue

        text += f"""
{'-' * 80}
{env_data['environment']} ENVIRONMENT
{'-' * 80}
Total Cost: ${env_data['total_cost']:.2f}
Services Used: {env_data['service_count']}

Top 5 Services:
"""
        for i, (service, cost) in enumerate(env_data['top_services'], 1):
            text += f"  {i}. {service}: ${abs(cost):.2f}\n"

    text += f"""
{'-' * 80}
Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}
This is an automated report from BBWS Cost Reporter
{'-' * 80}
"""

    return text


def lambda_handler(event, context):
    """Main Lambda handler"""

    try:
        # Get configuration from environment variables
        sns_topic_arn = os.environ.get('SNS_TOPIC_ARN')
        report_type = os.environ.get('REPORT_TYPE', 'daily')

        # Get account role ARNs (if cross-account access is needed)
        dev_role_arn = os.environ.get('DEV_ACCOUNT_ROLE_ARN')
        sit_role_arn = os.environ.get('SIT_ACCOUNT_ROLE_ARN')
        prod_role_arn = os.environ.get('PROD_ACCOUNT_ROLE_ARN')

        # Get date range
        start_date, end_date, period_label = get_date_range(report_type)

        print(f"Generating {report_type} cost report for {start_date} to {end_date}")

        # Fetch cost data for each environment
        # Assuming this Lambda runs in an account with access to all three accounts
        # Or it assumes roles to access each account

        dev_data = None
        sit_data = None
        prod_data = None

        # If running in same account, use default client
        # If cross-account, assume roles
        if dev_role_arn:
            dev_ce_client = assume_role(dev_role_arn)
            dev_cost_data = get_cost_data(dev_ce_client, start_date, end_date)
            dev_data = analyze_costs(dev_cost_data, 'DEV')

        if sit_role_arn:
            sit_ce_client = assume_role(sit_role_arn)
            sit_cost_data = get_cost_data(sit_ce_client, start_date, end_date)
            sit_data = analyze_costs(sit_cost_data, 'SIT')

        if prod_role_arn:
            prod_ce_client = assume_role(prod_role_arn)
            prod_cost_data = get_cost_data(prod_ce_client, start_date, end_date)
            prod_data = analyze_costs(prod_cost_data, 'PROD')

        # If no role ARNs provided, assume running in management account with access to all
        if not dev_role_arn and not sit_role_arn and not prod_role_arn:
            # This would require Cost Explorer consolidated billing
            cost_data = get_cost_data(ce_client, start_date, end_date)
            # You'd need to filter by account ID to separate environments
            # For now, treating as single account
            dev_data = analyze_costs(cost_data, 'ALL')

        # Generate reports
        html_body = generate_html_report(dev_data, sit_data, prod_data, period_label, start_date, end_date)
        text_body = generate_text_report(dev_data, sit_data, prod_data, period_label, start_date, end_date)

        # Send via SNS
        if sns_topic_arn:
            subject = f"AWS Cost Report - {period_label} ({datetime.now().strftime('%Y-%m-%d')})"

            sns_client.publish(
                TopicArn=sns_topic_arn,
                Subject=subject,
                Message=text_body,
                MessageAttributes={
                    'email_html': {
                        'DataType': 'String',
                        'StringValue': html_body
                    }
                }
            )

            print(f"Report sent to SNS topic: {sns_topic_arn}")

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Cost report generated successfully',
                'period': period_label,
                'total_cost': dev_data['total_cost'] if dev_data else 0
            }, cls=DecimalEncoder)
        }

    except Exception as e:
        print(f"Error generating cost report: {str(e)}")
        raise
