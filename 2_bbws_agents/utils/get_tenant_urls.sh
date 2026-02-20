#!/bin/bash
# Get access URLs for all DEV tenants
# Usage: ./get_tenant_urls.sh [environment]
# Default environment: dev

set -e

ENVIRONMENT="${1:-dev}"
export AWS_PROFILE=Tebogo-${ENVIRONMENT}

# Environment configuration
case $ENVIRONMENT in
  dev)
    CLUSTER="dev-cluster"
    REGION="eu-west-1"
    DOMAIN_SUFFIX="wpdev.kimmyai.io"
    ;;
  sit)
    CLUSTER="sit-cluster"
    REGION="eu-west-1"
    DOMAIN_SUFFIX="wpsit.kimmyai.io"
    ;;
  prod)
    CLUSTER="prod-cluster"
    REGION="af-south-1"
    DOMAIN_SUFFIX="wp.kimmyai.io"
    ;;
  *)
    echo "Invalid environment: $ENVIRONMENT"
    echo "Usage: $0 [dev|sit|prod]"
    exit 1
    ;;
esac

echo "=== ${ENVIRONMENT^^} TENANT ACCESS URLS ==="
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo "Cluster: $CLUSTER"
echo ""

# List all tenant services
echo "=== ACTIVE TENANTS ==="
SERVICES=$(aws ecs list-services --cluster $CLUSTER --region $REGION --query 'serviceArns' --output text | tr '\t' '\n' | grep -oE 'dev-[^/]+' | sed 's/dev-//' | sed 's/-service$//' | sort)

if [ -z "$SERVICES" ]; then
  echo "No services found in cluster $CLUSTER"
  exit 1
fi

echo ""
echo "=== TENANT URLS ==="
for tenant in $SERVICES; do
  # Convert tenant-1 to tenant1 for domain
  domain_tenant=$(echo $tenant | sed 's/-//')

  echo "[$tenant]"
  echo "  WordPress: https://${domain_tenant}.${DOMAIN_SUFFIX}"
  echo "  Admin:     https://${domain_tenant}.${DOMAIN_SUFFIX}/wp-admin"

  # Get service status
  status=$(aws ecs describe-services \
    --cluster $CLUSTER \
    --services dev-${tenant}-service \
    --region $REGION \
    --query 'services[0].{running:runningCount,desired:desiredCount}' \
    --output text 2>/dev/null || echo "0 0")

  running=$(echo $status | awk '{print $1}')
  desired=$(echo $status | awk '{print $2}')

  if [ "$running" = "$desired" ] && [ "$running" != "0" ]; then
    echo "  Status:    ✅ ACTIVE ($running/$desired tasks)"
  else
    echo "  Status:    ⚠️  UNHEALTHY ($running/$desired tasks)"
  fi
  echo ""
done

echo "=== INFRASTRUCTURE ==="
echo "CloudFront: All sites accessible via HTTPS with Basic Auth"
echo "Direct ALB: Use curl with Host header for testing"
echo ""

echo "=== TESTING COMMANDS ==="
echo "# Test via CloudFront (HTTPS):"
echo "curl https://tenant1.${DOMAIN_SUFFIX}"
echo ""
echo "# Test via ALB directly (HTTP):"
echo 'curl -H "Host: tenant1.'${DOMAIN_SUFFIX}'" http://$(aws elbv2 describe-load-balancers --region '${REGION}' --query "LoadBalancers[?contains(LoadBalancerName, '\''dev-alb'\'')].DNSName" --output text)/'
echo ""
