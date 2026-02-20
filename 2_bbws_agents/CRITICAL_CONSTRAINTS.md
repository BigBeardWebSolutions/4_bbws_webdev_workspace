# CRITICAL CONSTRAINTS - DO NOT VIOLATE

## DNS and Domain Management

### ❌ NEVER TOUCH bigbeard.co.za
- **DO NOT** modify any DNS records in bigbeard.co.za hosted zone
- **DO NOT** create subdomains under bigbeard.co.za
- **DO NOT** reference bigbeard.co.za for customer-facing services
- **DO NOT** add any records to the bigbeard.co.za Route 53 hosted zone (Z06283104TVJMJ1VNAOS)

### ✅ Approved Domain Patterns
- **DEV**: *.wpdev.kimmyai.io
- **SIT**: *.wpsit.kimmyai.io
- **PROD (Internal)**: *.wp.kimmyai.io
- **PROD (Customer-facing)**: [tenant].co.za (separate domain per tenant)

## Date Created
2025-12-19

## Reason
User explicitly stated: "never touch bigbeard.co.za"
