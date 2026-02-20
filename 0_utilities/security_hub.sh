#!/bin/bash
# ------------------------------------------------------------------
# Script: securityhub_hri_report_oneline.sh
# Purpose: Generate and analyze HIGH/CRITICAL Security Hub findings
# Region: eu-west-1
# ------------------------------------------------------------------

REGION="eu-west-1"

# 1. List all active findings
echo "Listing all ACTIVE findings..."
aws securityhub get-findings --filters '{"RecordState":[{"Value":"ACTIVE","Comparison":"EQUALS"}]}' --region $REGION

# 2. List only HIGH and CRITICAL (active) findings
echo "Listing only HIGH and CRITICAL ACTIVE findings..."
aws securityhub get-findings --filters '{"SeverityLabel":[{"Value":"HIGH","Comparison":"EQUALS"},{"Value":"CRITICAL","Comparison":"EQUALS"}],"RecordState":[{"Value":"ACTIVE","Comparison":"EQUALS"}]}' --region $REGION

# 3. Count remaining HIGH/CRITICAL (active) findings
echo "Counting HIGH and CRITICAL ACTIVE findings..."
aws securityhub get-findings --filters '{"SeverityLabel":[{"Value":"HIGH","Comparison":"EQUALS"},{"Value":"CRITICAL","Comparison":"EQUALS"}],"RecordState":[{"Value":"ACTIVE","Comparison":"EQUALS"}]}' --region $REGION --query 'length(Findings)'

# 4. Count resolved (archived) HIGH/CRITICAL findings
echo "Counting HIGH and CRITICAL RESOLVED (ARCHIVED) findings..."
aws securityhub get-findings --filters '{"SeverityLabel":[{"Value":"HIGH","Comparison":"EQUALS"},{"Value":"CRITICAL","Comparison":"EQUALS"}],"RecordState":[{"Value":"ARCHIVED","Comparison":"EQUALS"}]}' --region $REGION --query 'length(Findings)'

# 5. Export HIGH/CRITICAL active findings to JSON file
echo "Exporting HIGH/CRITICAL ACTIVE findings to hri_report.json..."
aws securityhub get-findings --filters '{"SeverityLabel":[{"Value":"HIGH","Comparison":"EQUALS"},{"Value":"CRITICAL","Comparison":"EQUALS"}],"RecordState":[{"Value":"ACTIVE","Comparison":"EQUALS"}]}' --region $REGION --output json > hri_report.json

# 6. List all AWS services (ProductName) that have HIGH/CRITICAL active findings
echo "Listing all AWS services with HIGH/CRITICAL ACTIVE findings..."
aws securityhub get-findings --filters '{"SeverityLabel":[{"Value":"HIGH","Comparison":"EQUALS"},{"Value":"CRITICAL","Comparison":"EQUALS"}],"RecordState":[{"Value":"ACTIVE","Comparison":"EQUALS"}]}' --region $REGION --query 'Findings[].ProductName' --output text | tr '\t' '\n' | sort | uniq

# 7. List affected resource types for HIGH/CRITICAL active findings
echo "Listing affected AWS resource types for HIGH/CRITICAL ACTIVE findings..."
aws securityhub get-findings --filters '{"SeverityLabel":[{"Value":"HIGH","Comparison":"EQUALS"},{"Value":"CRITICAL","Comparison":"EQUALS"}],"RecordState":[{"Value":"ACTIVE","Comparison":"EQUALS"}]}' --region $REGION --query 'Findings[].Resources[].Type' --output text | tr '\t' '\n' | sort | uniq

echo "-----------------------------------------------------------"
echo "Script completed. Reports and counts generated successfully."