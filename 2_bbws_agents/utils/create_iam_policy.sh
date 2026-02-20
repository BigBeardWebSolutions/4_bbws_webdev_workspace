#!/bin/bash
# Create IAM policy for tenant secret access
# Usage: ./create_iam_policy.sh <tenant_name> <environment> [secret_arn]

set -e

TENANT=$1
ENV=$2
SECRET_ARN=$3

if [[ -z "$TENANT" || -z "$ENV" ]]; then
  echo "Usage: $0 <tenant_name> <environment> [secret_arn]"
  echo "Example: $0 myclient sit"
  echo "Example: $0 myclient sit arn:aws:secretsmanager:..."
  exit 1
fi

case $ENV in
  dev)
    PROFILE="Tebogo-dev"
    REGION="eu-west-1"
    ;;
  sit)
    PROFILE="Tebogo-sit"
    REGION="eu-west-1"
    ;;
  prod)
    PROFILE="Tebogo-prod"
    REGION="af-south-1"
    ;;
  *)
    echo "Error: Invalid environment '$ENV'"
    exit 1
    ;;
esac

echo "Creating IAM policy for ${TENANT} secret access..."

# Get secret ARN if not provided
if [[ -z "$SECRET_ARN" ]]; then
  echo "Retrieving secret ARN..."
  SECRET_ARN=$(aws secretsmanager describe-secret \
    --secret-id ${ENV}-${TENANT}-db-credentials \
    --region $REGION \
    --profile $PROFILE \
    --query 'ARN' \
    --output text)

  if [[ -z "$SECRET_ARN" ]]; then
    echo "Error: Could not find secret ${ENV}-${TENANT}-db-credentials"
    exit 1
  fi
fi

echo "Secret ARN: $SECRET_ARN"

# Create policy document
POLICY_FILE="/tmp/${TENANT}-${ENV}-secrets-policy.json"
cat > $POLICY_FILE <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ],
    "Resource": [
      "${SECRET_ARN}",
      "${SECRET_ARN}*"
    ]
  }]
}
EOF

echo "Policy document created: $POLICY_FILE"

# Apply policy to task execution role
ROLE_NAME="${ENV}-ecs-task-execution-role"
POLICY_NAME="${ENV}-ecs-secrets-access-${TENANT}"

echo "Attaching policy to role: $ROLE_NAME"

aws iam put-role-policy \
  --role-name $ROLE_NAME \
  --policy-name $POLICY_NAME \
  --policy-document file://$POLICY_FILE \
  --profile $PROFILE \
  || {
    echo "Error: Failed to attach policy to role"
    echo "Role: $ROLE_NAME"
    echo "Policy: $POLICY_NAME"
    exit 1
  }

echo ""
echo "✅ IAM policy created and attached!"
echo "   Role: $ROLE_NAME"
echo "   Policy: $POLICY_NAME"
echo "   Secret: ${ENV}-${TENANT}-db-credentials"
echo ""
echo "The ECS task execution role can now access the database credentials."
