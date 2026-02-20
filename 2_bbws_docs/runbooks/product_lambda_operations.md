# Product Lambda Operations Runbook

**Service**: Product Lambda API
**Last Updated**: 2025-12-29

---

## Daily Operations

### Monitor Service Health
```bash
# Check Lambda metrics (last hour)
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=bbws-product-list-dev \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum

# Check API Gateway requests
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name Count \
  --dimensions Name=ApiName,Value=bbws-product-api-dev \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

---

## Common Tasks

### View Recent Logs
```bash
# Tail Lambda logs
aws logs tail /aws/lambda/bbws-product-list-dev --follow

# Filter for errors
aws logs tail /aws/lambda/bbws-product-list-dev --filter-pattern "ERROR"

# Get logs for specific time range
aws logs filter-log-events \
  --log-group-name /aws/lambda/bbws-product-list-dev \
  --start-time $(date -u -v-1H +%s)000 \
  --filter-pattern "ERROR"
```

### Test API Endpoints
```bash
API_URL="https://YOUR_API_ID.execute-api.eu-west-1.amazonaws.com/v1/v1.0/products"

# List products
curl -X GET $API_URL

# Get specific product
curl -X GET $API_URL/PROD-ABC123

# Create product (example)
curl -X POST $API_URL \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Product",
    "description": "Test description",
    "price": "99.99",
    "currency": "ZAR",
    "period": "monthly",
    "features": ["Feature 1"]
  }'
```

### Update Lambda Environment Variables
```bash
# Update LOG_LEVEL
aws lambda update-function-configuration \
  --function-name bbws-product-list-dev \
  --environment Variables="{DYNAMODB_TABLE=products-dev,ENVIRONMENT=dev,LOG_LEVEL=DEBUG}"
```

### Manually Invoke Lambda
```bash
# Create test event
cat > event.json <<EOF
{
  "httpMethod": "GET",
  "path": "/v1.0/products",
  "headers": {"Accept": "application/json"}
}
EOF

# Invoke function
aws lambda invoke \
  --function-name bbws-product-list-dev \
  --payload file://event.json \
  response.json

# View response
cat response.json | jq .
```

---

## Monitoring & Alerts

### CloudWatch Alarms
- `bbws-product-list-errors-dev` - Lambda errors > 5 in 5 min
- `bbws-product-list-duration-dev` - Duration > 25s
- `bbws-product-list-throttles-dev` - Throttles > 5
- `bbws-product-api-5xx-errors-dev` - API 5xx > 10 in 5 min
- `bbws-product-api-latency-dev` - Latency > 5s

### Check Alarm Status
```bash
aws cloudwatch describe-alarms \
  --alarm-names \
    bbws-product-list-errors-dev \
    bbws-product-api-5xx-errors-dev
```

---

## Performance Tuning

### Increase Lambda Memory
```bash
aws lambda update-function-configuration \
  --function-name bbws-product-list-dev \
  --memory-size 512
```

### Adjust Lambda Timeout
```bash
aws lambda update-function-configuration \
  --function-name bbws-product-list-dev \
  --timeout 60
```

---

## Data Operations

### Query DynamoDB Table
```bash
# List all products
aws dynamodb scan \
  --table-name products-dev \
  --filter-expression "begins_with(PK, :pk)" \
  --expression-attribute-values '{":pk":{"S":"PRODUCT#"}}'

# Get specific product
aws dynamodb get-item \
  --table-name products-dev \
  --key '{"PK":{"S":"PRODUCT#PROD-ABC123"},"SK":{"S":"METADATA"}}'

# Query active products via GSI
aws dynamodb query \
  --table-name products-dev \
  --index-name ActiveProductsIndex \
  --key-condition-expression "active = :true" \
  --expression-attribute-values '{":true":{"S":"true"}}'
```

---

## Security Operations

### Rotate Credentials
```bash
# Update Lambda execution role (if needed)
aws iam update-assume-role-policy \
  --role-name bbws-product-lambda-execution-dev \
  --policy-document file://trust-policy.json
```

### Review IAM Permissions
```bash
# Get role policy
aws iam get-role-policy \
  --role-name bbws-product-lambda-execution-dev \
  --policy-name dynamodb-access
```

---

## Troubleshooting

### High Error Rate
1. Check CloudWatch logs for error patterns
2. Verify DynamoDB table accessibility
3. Check IAM role permissions
4. Review recent deployments

### High Latency
1. Check Lambda duration metrics
2. Review DynamoDB performance metrics
3. Consider increasing Lambda memory
4. Check for cold starts

### Throttling Issues
1. Check Lambda concurrent executions
2. Review account-level Lambda limits
3. Consider reserved concurrency
4. Check DynamoDB throttling

---

**Related**: `product_lambda_deployment.md`, `product_lambda_disaster_recovery.md`
