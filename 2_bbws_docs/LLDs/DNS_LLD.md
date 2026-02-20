# DNS Management - Low-Level Design

**Version**: 1.0
**Author**: Agentic Architect
**Date**: 2025-12-13
**Status**: Draft for Review
**Parent HLD**: [BBWS ECS WordPress HLD](../BBWS_ECS_WordPress_HLD.md)

---

## Document History

| Version | Date | Changes | Owner |
|---------|------|---------|-------|
| 1.0 | 2025-12-13 | Initial LLD for DNS management across multi-account environments | Agentic Architect |

---

## 1. Introduction

### 1.1 Purpose

This LLD provides implementation details for DNS management across three AWS accounts (DEV, SIT, PROD) with delegation from production to lower environments.

### 1.2 Parent HLD Reference

This LLD details DNS components from Section 4.2 (Layer 2: Edge/Network) and User Stories US-015, US-027, US-028 of the [BBWS ECS WordPress HLD](../BBWS_ECS_WordPress_HLD.md).

### 1.3 Component Overview

DNS Management provides:
- Multi-account DNS architecture with delegation
- Per-tenant subdomain creation and management
- Health check-based failover routing
- SSL certificate management via ACM
- Disaster recovery DNS repointing

### 1.4 Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| DNS Service | Amazon Route 53 | DNS hosting and routing |
| SSL Certificates | AWS Certificate Manager (ACM) | SSL/TLS certificates |
| Health Checks | Route 53 Health Checks | Endpoint monitoring |
| Infrastructure | Terraform | DNS record provisioning |

### 1.5 DNS Domain Structure

| Account | Hosted Zone | Domain Pattern | Example |
|---------|-------------|----------------|---------|
| PROD | kimmyai.io | wp.kimmyai.io | wp.kimmyai.io |
| DEV | wpdev.kimmyai.io | {tenant}.wpdev.kimmyai.io | banana.wpdev.kimmyai.io |
| SIT | wpsit.kimmyai.io | {tenant}.wpsit.kimmyai.io | banana.wpsit.kimmyai.io |

---

## 2. High Level Epic Overview

| User Story ID | User Story | Test Scenario(s) |
|---------------|------------|------------------|
| US-015 | As a Platform Operator, I want to configure DNS for a tenant so that their site is accessible via domain | GIVEN tenant-id "banana" WHEN I provision DNS THEN Route53 record created for banana.wpdev.kimmyai.io AND health check configured AND SSL certificate issued |
| US-027 | As a Platform Operator, I want to execute DR failover so that service continues during regional outage | GIVEN primary region failure WHEN I execute failover THEN DNS points to eu-west-1 ALB AND health checks validate DR endpoint |
| US-028 | As a Platform Operator, I want to failback to primary region so that normal operations resume | GIVEN DR active WHEN primary region recovered THEN DNS repoints to af-south-1 ALB AND health checks validate primary endpoint |

---

## 3. Component Diagram (DNS Architecture)

### 3.1 Multi-Account DNS Delegation

```mermaid
graph TB
    subgraph "PROD Account (536580886816)"
        ProdZone["Hosted Zone: kimmyai.io"]
        ProdRecord["A Record: wp.kimmyai.io → ALB"]
        DevNS["NS Record: wpdev.kimmyai.io → DEV NS servers"]
        SitNS["NS Record: wpsit.kimmyai.io → SIT NS servers"]
    end

    subgraph "DEV Account (123456789012)"
        DevZone["Hosted Zone: wpdev.kimmyai.io"]
        DevTenant1["A Record: banana.wpdev.kimmyai.io → DEV ALB"]
        DevTenant2["A Record: orange.wpdev.kimmyai.io → DEV ALB"]
        DevHealth["Health Check: DEV ALB"]
    end

    subgraph "SIT Account (234567890123)"
        SitZone["Hosted Zone: wpsit.kimmyai.io"]
        SitTenant1["A Record: banana.wpsit.kimmyai.io → SIT ALB"]
        SitTenant2["A Record: orange.wpsit.kimmyai.io → SIT ALB"]
        SitHealth["Health Check: SIT ALB"]
    end

    Internet["Internet DNS Query"]

    Internet -->|1. Query kimmyai.io| ProdZone
    ProdZone -->|2. Delegate wpdev subdomain| DevZone
    ProdZone -->|2. Delegate wpsit subdomain| SitZone

    DevZone --> DevTenant1
    DevZone --> DevTenant2
    DevHealth -.->|Monitor| DevTenant1

    SitZone --> SitTenant1
    SitZone --> SitTenant2
    SitHealth -.->|Monitor| SitTenant1
```

### 3.2 Class Diagram

```mermaid
classDiagram
    class DNSService {
        -Route53Client client
        -ACMClient acmClient
        -ValidationService validator
        -AuditLogger auditLogger
        +DNSService(client, acmClient, validator, logger)
        +createTenantDNS(tenantId String, albDNS String) DNSRecord
        +createHealthCheck(endpoint String) HealthCheck
        +requestCertificate(domain String) Certificate
        +initiateGoLive(tenantId String, customDomain String) GoLiveResult
        +failoverToDR(domain String, drALB String) void
        +failbackToPrimary(domain String, primaryALB String) void
        -validateDomain(domain String) Boolean
        -validateDomainOwnership(customDomain String) Boolean
    }

    class Organization {
        +String organizationId
        +String organizationName
        +String primaryContactEmail
        +List~Tenant~ tenants
        +addTenant(tenant Tenant) void
        +removeTenant(tenantId String) void
        +getTenantByDomain(domain String) Tenant
    }

    class Tenant {
        +String tenantId
        +String organizationId
        +String devDomain
        +String customDomain
        +TenantStatus status
        +DateTime goLiveDate
        +String certificateArn
        +getAdminUrl() String
        +getSiteUrl() String
        +isLive() Boolean
    }

    class TenantStatus {
        <<enumeration>>
        REQUESTED
        DEV_ASSIGNED
        IN_DEVELOPMENT
        READY_FOR_GOLIVE
        PENDING_DNS
        DNS_VALIDATED
        CERT_PENDING
        CERT_ISSUED
        LIVE
    }

    class DNSRecord {
        +String recordName
        +String recordType
        +String recordValue
        +int ttl
        +RoutingPolicy policy
        +String healthCheckId
        +validate() Boolean
    }

    class RoutingPolicy {
        <<enumeration>>
        SIMPLE
        WEIGHTED
        FAILOVER
        GEOLOCATION
    }

    class HealthCheck {
        +String id
        +String endpoint
        +String protocol
        +int port
        +String path
        +int interval
        +int failureThreshold
        +HealthCheckStatus status
        +getStatus() HealthCheckStatus
    }

    class HealthCheckStatus {
        <<enumeration>>
        HEALTHY
        UNHEALTHY
        UNKNOWN
    }

    class Certificate {
        +String arn
        +String domain
        +List~String~ subjectAlternativeNames
        +CertificateStatus status
        +String validationMethod
        +isValidated() Boolean
    }

    class CertificateStatus {
        <<enumeration>>
        PENDING_VALIDATION
        ISSUED
        INACTIVE
        EXPIRED
        VALIDATION_TIMED_OUT
        REVOKED
        FAILED
    }

    class GoLiveResult {
        +String tenantId
        +String customDomain
        +String certificateArn
        +String hostedZoneId
        +Boolean success
        +List~String~ validationRecords
    }

    Organization "1" *-- "*" Tenant : contains
    Tenant --> TenantStatus : has
    Tenant --> Certificate : uses
    DNSService --> DNSRecord : creates
    DNSService --> HealthCheck : creates
    DNSService --> Certificate : requests
    DNSService --> Tenant : manages
    DNSService --> GoLiveResult : returns
    DNSRecord --> RoutingPolicy : uses
    HealthCheck --> HealthCheckStatus : has
    Certificate --> CertificateStatus : has
```

---

## 4. DNS Configuration Details

### 4.1 Hosted Zone Setup

#### PROD Account Hosted Zone

```
Domain: kimmyai.io
Zone ID: Z1234567890ABC
Name Servers:
  - ns-1234.awsdns-12.org
  - ns-5678.awsdns-34.com
  - ns-9012.awsdns-56.net
  - ns-3456.awsdns-78.co.uk
```

**Records:**
```
wp.kimmyai.io         A   ALIAS   prod-alb-123456789.af-south-1.elb.amazonaws.com
wpdev.kimmyai.io      NS  ns-dev1.awsdns-12.org, ns-dev2.awsdns-34.com
wpsit.kimmyai.io      NS  ns-sit1.awsdns-56.org, ns-sit2.awsdns-78.com
```

#### DEV Account Hosted Zone

```
Domain: wpdev.kimmyai.io
Zone ID: Z2345678901BCD
Delegation: From PROD kimmyai.io
```

**Records:**
```
banana.wpdev.kimmyai.io    A   ALIAS   dev-alb-987654321.af-south-1.elb.amazonaws.com
orange.wpdev.kimmyai.io    A   ALIAS   dev-alb-987654321.af-south-1.elb.amazonaws.com
```

#### SIT Account Hosted Zone

```
Domain: wpsit.kimmyai.io
Zone ID: Z3456789012CDE
Delegation: From PROD kimmyai.io
```

**Records:**
```
banana.wpsit.kimmyai.io    A   ALIAS   sit-alb-111222333.af-south-1.elb.amazonaws.com
orange.wpsit.kimmyai.io    A   ALIAS   sit-alb-111222333.af-south-1.elb.amazonaws.com
```

### 4.2 Health Check Configuration

```json
{
  "Type": "HTTPS",
  "ResourcePath": "/health",
  "FullyQualifiedDomainName": "banana.wpdev.kimmyai.io",
  "Port": 443,
  "RequestInterval": 30,
  "FailureThreshold": 3,
  "MeasureLatency": true,
  "EnableSNI": true,
  "Regions": ["af-south-1", "eu-west-1", "us-east-1"]
}
```

### 4.3 ACM Certificate Request

```json
{
  "DomainName": "*.wpdev.kimmyai.io",
  "SubjectAlternativeNames": [
    "wpdev.kimmyai.io",
    "*.wpdev.kimmyai.io"
  ],
  "ValidationMethod": "DNS",
  "Tags": [
    {"Key": "bbws:environment", "Value": "dev"},
    {"Key": "bbws:component", "Value": "dns"}
  ]
}
```

---

## 5. Domain Lifecycle Scenarios

This section clarifies the customer journey from development through production, including multi-tenant organizations.

### 5.1 Scenario Overview

| Phase | Domain Pattern | Example | wp-admin Access |
|-------|---------------|---------|-----------------|
| Development | {tenant}.wpdev.kimmyai.io | banana.wpdev.kimmyai.io | banana.wpdev.kimmyai.io/wp-admin |
| Go Live | {custom-domain}.{tld} | banana.co.za | banana.co.za/wp-admin |
| Multi-Tenant Org | Multiple custom domains | banana.co.za, orange.co.za | {domain}/wp-admin per site |

### 5.2 Scenario 1: Single Tenant Development to Go-Live

**Customer Journey**: Customer purchases banana.co.za and wants a WordPress site.

#### Phase 1: Development Assignment

```
Customer Request: "I want a WordPress site for banana.co.za"
↓
System Assigns: banana.wpdev.kimmyai.io (DEV environment)
↓
Customer Access:
  - Site: https://banana.wpdev.kimmyai.io
  - Admin: https://banana.wpdev.kimmyai.io/wp-admin
```

**DNS Records Created (DEV Account)**:
```
banana.wpdev.kimmyai.io    A   ALIAS   dev-alb-xxx.af-south-1.elb.amazonaws.com
```

**ACM Certificate (DEV)**:
```
Domain: banana.wpdev.kimmyai.io
SAN: *.wpdev.kimmyai.io (wildcard covers all tenants)
```

#### Phase 2: Site Development & Testing

During development, the customer:
- Accesses `https://banana.wpdev.kimmyai.io/wp-admin` to build content
- Tests site functionality at `https://banana.wpdev.kimmyai.io`
- Site is NOT publicly accessible on banana.co.za yet

#### Phase 3: Go Live (Custom Domain Activation)

When the site is ready for production:

```
Trigger: Customer approves go-live
↓
DNS Changes Required:
1. Customer updates their registrar (e.g., Domains.co.za, GoDaddy)
   - banana.co.za → CNAME to wp.kimmyai.io OR
   - banana.co.za → A record to PROD ALB IP
2. PROD hosted zone gets new record:
   - banana.co.za    A   ALIAS   prod-alb-xxx.af-south-1.elb.amazonaws.com
3. ACM issues certificate for banana.co.za
↓
Post Go-Live Access:
  - Site: https://banana.co.za
  - Admin: https://banana.co.za/wp-admin
```

**PROD Account DNS Records After Go-Live**:
```
kimmyai.io zone:
  wp.kimmyai.io              A   ALIAS   prod-alb-xxx.af-south-1.elb.amazonaws.com
  wpdev.kimmyai.io           NS  [DEV name servers]
  wpsit.kimmyai.io           NS  [SIT name servers]

banana.co.za zone (new hosted zone):
  banana.co.za               A   ALIAS   prod-alb-xxx.af-south-1.elb.amazonaws.com
  www.banana.co.za           A   ALIAS   prod-alb-xxx.af-south-1.elb.amazonaws.com
```

**ACM Certificate (PROD)**:
```
Domain: banana.co.za
SAN: www.banana.co.za, banana.co.za
ValidationMethod: DNS (customer adds CNAME to their registrar)
```

### 5.3 Scenario 2: Single Tenant Becomes Multi-Tenant Organization

**Customer Journey**: Same customer (banana.co.za) now purchases orange.co.za.

#### Before: Single Tenant

```
Customer: Big Beard Web Solutions
├── Site: banana.co.za
└── Admin: banana.co.za/wp-admin
```

#### After: Multi-Tenant Organization

```
Organization: Big Beard Web Solutions
├── Tenant 1: banana.co.za
│   ├── Site: https://banana.co.za
│   └── Admin: https://banana.co.za/wp-admin
│
└── Tenant 2: orange.co.za
    ├── Development: https://orange.wpdev.kimmyai.io
    ├── Dev Admin: https://orange.wpdev.kimmyai.io/wp-admin
    └── (After Go-Live)
        ├── Site: https://orange.co.za
        └── Admin: https://orange.co.za/wp-admin
```

#### Organization Data Model

```json
{
  "organizationId": "org-bigbeard-001",
  "organizationName": "Big Beard Web Solutions",
  "tenants": [
    {
      "tenantId": "banana",
      "customDomain": "banana.co.za",
      "devDomain": "banana.wpdev.kimmyai.io",
      "status": "LIVE",
      "goLiveDate": "2025-06-15"
    },
    {
      "tenantId": "orange",
      "customDomain": "orange.co.za",
      "devDomain": "orange.wpdev.kimmyai.io",
      "status": "DEVELOPMENT",
      "goLiveDate": null
    }
  ],
  "primaryContactEmail": "admin@bigbeard.co.za"
}
```

#### DNS Records for Multi-Tenant Organization

**DEV Account (wpdev.kimmyai.io zone)**:
```
banana.wpdev.kimmyai.io    A   ALIAS   dev-alb-xxx.elb.amazonaws.com
orange.wpdev.kimmyai.io    A   ALIAS   dev-alb-xxx.elb.amazonaws.com
```

**PROD Account (after both sites go live)**:
```
kimmyai.io zone:
  wp.kimmyai.io              A   ALIAS   prod-alb-xxx.elb.amazonaws.com
  wpdev.kimmyai.io           NS  [DEV name servers]
  wpsit.kimmyai.io           NS  [SIT name servers]

banana.co.za zone:
  banana.co.za               A   ALIAS   prod-alb-xxx.elb.amazonaws.com
  www.banana.co.za           A   ALIAS   prod-alb-xxx.elb.amazonaws.com

orange.co.za zone:
  orange.co.za               A   ALIAS   prod-alb-xxx.elb.amazonaws.com
  www.orange.co.za           A   ALIAS   prod-alb-xxx.elb.amazonaws.com
```

### 5.4 Domain State Machine

```mermaid
stateDiagram-v2
    [*] --> REQUESTED: Customer purchases domain
    REQUESTED --> DEV_ASSIGNED: Assign {tenant}.wpdev.kimmyai.io
    DEV_ASSIGNED --> IN_DEVELOPMENT: Customer starts building site
    IN_DEVELOPMENT --> READY_FOR_GOLIVE: Customer approves content
    READY_FOR_GOLIVE --> PENDING_DNS: Initiate go-live
    PENDING_DNS --> DNS_VALIDATED: Customer updates registrar DNS
    DNS_VALIDATED --> CERT_PENDING: ACM certificate requested
    CERT_PENDING --> CERT_ISSUED: DNS validation complete
    CERT_ISSUED --> LIVE: Custom domain active
    LIVE --> [*]

    note right of DEV_ASSIGNED
        Access: {tenant}.wpdev.kimmyai.io/wp-admin
    end note

    note right of LIVE
        Access: {custom-domain}/wp-admin
    end note
```

### 5.5 ALB Routing Configuration

The ALB uses host-based routing to direct traffic to the correct tenant:

```
ALB Listener Rules (PROD):
┌─────────────────────────────────────────────────────────────┐
│ Priority │ Condition                    │ Action            │
├─────────────────────────────────────────────────────────────┤
│ 1        │ Host: banana.co.za           │ → ECS banana task │
│ 2        │ Host: www.banana.co.za       │ → ECS banana task │
│ 3        │ Host: orange.co.za           │ → ECS orange task │
│ 4        │ Host: www.orange.co.za       │ → ECS orange task │
│ Default  │ *                            │ → 404 page        │
└─────────────────────────────────────────────────────────────┘

ALB Listener Rules (DEV):
┌─────────────────────────────────────────────────────────────┐
│ Priority │ Condition                    │ Action            │
├─────────────────────────────────────────────────────────────┤
│ 1        │ Host: banana.wpdev.kimmyai.io│ → ECS banana task │
│ 2        │ Host: orange.wpdev.kimmyai.io│ → ECS orange task │
│ Default  │ *                            │ → 404 page        │
└─────────────────────────────────────────────────────────────┘
```

### 5.6 WordPress Configuration by Environment

**DEV Environment** (`wp-config.php` or environment variables):
```php
// Tenant: banana in DEV
define('WP_HOME', 'https://banana.wpdev.kimmyai.io');
define('WP_SITEURL', 'https://banana.wpdev.kimmyai.io');
```

**PROD Environment** (after go-live):
```php
// Tenant: banana in PROD
define('WP_HOME', 'https://banana.co.za');
define('WP_SITEURL', 'https://banana.co.za');
```

### 5.7 Customer DNS Requirements (Go-Live Checklist)

When a customer is ready to go live with their custom domain, they must:

| Step | Action | Who | Example |
|------|--------|-----|---------|
| 1 | Verify domain ownership | Customer | Prove ownership of banana.co.za |
| 2 | Add CNAME for ACM validation | Customer | _abc123.banana.co.za → _xyz.acm-validations.aws |
| 3 | Wait for certificate issuance | System | ~5-30 minutes |
| 4 | Update domain A record | Customer | banana.co.za → [PROD ALB IP] or CNAME to wp.kimmyai.io |
| 5 | Add www redirect | Customer | www.banana.co.za → banana.co.za |
| 6 | Test site access | Customer + Platform | https://banana.co.za loads correctly |
| 7 | Test wp-admin access | Customer | https://banana.co.za/wp-admin works |

---

## 6. Sequence Diagrams

### 6.1 Create Tenant DNS Sequence

```mermaid
sequenceDiagram
    participant Operator
    participant CLI
    participant DNSService
    participant Route53
    participant ACM
    participant AuditLogger

    Operator->>CLI: create_tenant_dns --tenant-id banana --env dev

    rect rgb(240, 240, 255)
        Note over DNSService: try block - DNS Provisioning

        CLI->>DNSService: createTenantDNS(tenantId="banana", albDNS="dev-alb-xxx.elb.amazonaws.com")

        DNSService->>DNSService: validateDomain("banana.wpdev.kimmyai.io")

        DNSService->>Route53: ListHostedZonesByName(name="wpdev.kimmyai.io")
        Route53-->>DNSService: hostedZoneId

        DNSService->>ACM: RequestCertificate(domain="banana.wpdev.kimmyai.io")
        ACM-->>DNSService: certificateArn, validationRecords

        DNSService->>Route53: ChangeResourceRecordSets(hostedZoneId, validationRecords)
        Route53-->>DNSService: changeId

        DNSService->>ACM: WaitForCertificateValidation(certificateArn, timeout=300s)
        ACM-->>DNSService: status=ISSUED

        DNSService->>Route53: CreateHealthCheck(domain="banana.wpdev.kimmyai.io", path="/health")
        Route53-->>DNSService: healthCheckId

        DNSService->>Route53: ChangeResourceRecordSets(hostedZoneId, A record ALIAS to ALB, healthCheckId)
        Route53-->>DNSService: changeId

        DNSService->>Route53: WaitForRecordSetChange(changeId, timeout=60s)
        Route53-->>DNSService: status=INSYNC

        DNSService->>AuditLogger: logEvent(DNS_CREATED, tenantId="banana")
        AuditLogger-->>DNSService: void

        DNSService-->>CLI: DNSRecord(name="banana.wpdev.kimmyai.io", certificateArn, healthCheckId)
    end

    alt BusinessException
        Note over DNSService: catch BusinessException
        DNSService-->>CLI: 400 Bad Request (InvalidDomainException)
        DNSService-->>CLI: 409 Conflict (DomainAlreadyExistsException)
        DNSService-->>CLI: 422 Unprocessable Entity (CertificateValidationFailedException)
    end

    alt UnexpectedException
        Note over DNSService: catch UnexpectedException
        DNSService->>DNSService: logger.error(exception)
        DNSService->>DNSService: rollbackDNSChanges()
        DNSService-->>CLI: 500 Internal Server Error (Route53Exception)
        DNSService-->>CLI: 503 Service Unavailable (ACMServiceException)
        DNSService-->>CLI: 504 Gateway Timeout (TimeoutException)
    end

    CLI-->>Operator: DNS created: banana.wpdev.kimmyai.io
```

### 6.2 Custom Domain Go-Live Sequence

```mermaid
sequenceDiagram
    participant Customer
    participant AdminApp
    participant DNSService
    participant Route53
    participant ACM
    participant ALB
    participant WordPress

    Customer->>AdminApp: Request go-live for banana.co.za

    rect rgb(240, 240, 255)
        Note over DNSService: try block - Go-Live Process

        AdminApp->>DNSService: initiateGoLive(tenantId="banana", customDomain="banana.co.za")

        DNSService->>DNSService: validateDomainOwnership("banana.co.za")

        DNSService->>Route53: CreateHostedZone(domain="banana.co.za")
        Route53-->>DNSService: hostedZoneId, nameServers

        DNSService->>ACM: RequestCertificate(domain="banana.co.za", san=["www.banana.co.za"])
        ACM-->>DNSService: certificateArn, validationRecords

        DNSService-->>AdminApp: PendingValidation(validationRecords)
        AdminApp-->>Customer: Please add these DNS records to your registrar

        Note over Customer: Customer adds CNAME to registrar

        Customer->>AdminApp: I've added the DNS records

        AdminApp->>DNSService: checkCertificateStatus(certificateArn)
        DNSService->>ACM: DescribeCertificate(certificateArn)
        ACM-->>DNSService: status=ISSUED

        DNSService->>Route53: CreateAliasRecord(banana.co.za → PROD ALB)
        Route53-->>DNSService: changeId

        DNSService->>Route53: CreateAliasRecord(www.banana.co.za → PROD ALB)
        Route53-->>DNSService: changeId

        DNSService->>ALB: CreateListenerRule(host=banana.co.za, target=banana-tg)
        ALB-->>DNSService: ruleArn

        DNSService->>WordPress: updateSiteUrl(newUrl="https://banana.co.za")
        WordPress-->>DNSService: success

        DNSService-->>AdminApp: GoLiveComplete(domain=banana.co.za)
        AdminApp-->>Customer: Your site is now live at https://banana.co.za
    end

    alt BusinessException
        Note over DNSService: catch BusinessException
        DNSService-->>AdminApp: 400 Bad Request (InvalidDomainException)
        DNSService-->>AdminApp: 409 Conflict (DomainAlreadyInUseException)
        DNSService-->>AdminApp: 422 Unprocessable Entity (CertificateValidationFailedException)
    end

    alt UnexpectedException
        Note over DNSService: catch UnexpectedException
        DNSService->>DNSService: logger.error(exception)
        DNSService->>DNSService: rollbackGoLiveChanges()
        DNSService-->>AdminApp: 500 Internal Server Error
    end
```

### 6.3 DR Failover Sequence

```mermaid
sequenceDiagram
    participant Operator
    participant CLI
    participant DNSService
    participant Route53
    participant HealthCheck
    participant AuditLogger

    Operator->>CLI: failover_to_dr --domain banana.wpdev.kimmyai.io --dr-alb dr-alb-xxx.eu-west-1.elb.amazonaws.com

    rect rgb(240, 240, 255)
        Note over DNSService: try block - DR Failover

        CLI->>DNSService: failoverToDR(domain, drALB)

        DNSService->>HealthCheck: GetHealthCheckStatus(primaryHealthCheckId)
        HealthCheck-->>DNSService: status=UNHEALTHY

        DNSService->>Route53: ChangeResourceRecordSets(Update A record to DR ALB)
        Route53-->>DNSService: changeId

        DNSService->>Route53: WaitForRecordSetChange(changeId, timeout=60s)
        Route53-->>DNSService: status=INSYNC

        DNSService->>HealthCheck: GetHealthCheckStatus(drHealthCheckId)
        HealthCheck-->>DNSService: status=HEALTHY

        DNSService->>AuditLogger: logEvent(DR_FAILOVER_EXECUTED, domain)
        AuditLogger-->>DNSService: void

        DNSService-->>CLI: Failover complete
    end

    alt BusinessException
        Note over DNSService: catch BusinessException
        DNSService-->>CLI: 400 Bad Request (InvalidDRConfigException)
        DNSService-->>CLI: 409 Conflict (PrimaryStillHealthyException)
    end

    alt UnexpectedException
        Note over DNSService: catch UnexpectedException
        DNSService->>DNSService: logger.error(exception)
        DNSService-->>CLI: 500 Internal Server Error (Route53Exception)
        DNSService-->>CLI: 504 Gateway Timeout (TimeoutException)
    end

    CLI-->>Operator: Failover successful, DNS now points to DR
```

---

## 7. Non-Functional Requirements

### 7.1 Performance

| Metric | Target | Measurement |
|--------|--------|-------------|
| DNS propagation time | < 60 seconds | Route53 change status |
| DNS query latency | < 50ms (p99) | Route53 query metrics |
| Certificate issuance time | < 5 minutes | ACM validation duration |
| Health check interval | 30 seconds | Route53 health check config |
| Failover time (RTO) | < 5 minutes | Manual DNS update + propagation |

### 7.2 Availability

| Aspect | Target | Implementation |
|--------|--------|----------------|
| Route53 availability | 100% | AWS SLA |
| DNS query success rate | 99.99% | Route53 anycast network |
| Health check monitoring | 24/7 | Multiple AWS regions |

### 7.3 Cost

| Component | Monthly Cost | Notes |
|-----------|--------------|-------|
| Hosted Zones (3x) | $1.50 | $0.50/zone |
| DNS Queries | ~$0.80 | First 1B queries: $0.40/million |
| Health Checks (10x) | $5.00 | $0.50/health check |
| ACM Certificates | $0 | Free for public certificates |
| **Total DNS** | **~$7.30/month** | Shared across tenants |

---

## 8. Security

### 8.1 DNSSEC

| Aspect | Implementation |
|--------|----------------|
| DNSSEC Status | Not enabled (Phase 2) |
| Reason | ACM validation requires unsigned zones |
| Future Plan | Enable after certificate provisioning automation |

### 8.2 Access Control

| Resource | Access Method | Authentication |
|----------|---------------|----------------|
| Hosted Zones | AWS Console, CLI, Terraform | IAM credentials, MFA for PROD |
| DNS Record Changes | Terraform | Peer-reviewed PRs |
| Health Checks | Route53 API | IAM roles |

---

## 9. Troubleshooting Playbook

### 9.1 DNS Not Resolving

**Symptom**: Domain doesn't resolve

**Diagnosis**:
```bash
# Test DNS resolution
dig banana.wpdev.kimmyai.io +short

# Check Route53 record
aws route53 list-resource-record-sets \
  --hosted-zone-id Z2345678901BCD \
  --query "ResourceRecordSets[?Name=='banana.wpdev.kimmyai.io.']" \
  --profile Tebogo-dev

# Check delegation from PROD
dig NS wpdev.kimmyai.io +short
```

**Resolution**:
- Verify NS records in PROD zone point to DEV name servers
- Check A record exists in DEV zone
- Wait 60s for DNS propagation

### 9.2 Certificate Validation Stuck

**Symptom**: ACM certificate pending validation

**Diagnosis**:
```bash
# Check certificate status
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:af-south-1:xxx:certificate/yyy \
  --profile Tebogo-dev

# Check validation DNS record
aws route53 list-resource-record-sets \
  --hosted-zone-id Z2345678901BCD \
  --query "ResourceRecordSets[?Type=='CNAME']" \
  --profile Tebogo-dev
```

**Resolution**:
- Verify CNAME validation record exists
- Check CNAME value matches ACM requirement
- Wait up to 30 minutes for validation

---

## 10. References

| Ref ID | Document | Type |
|--------|----------|------|
| REF-DNS-001 | [BBWS ECS WordPress HLD](../BBWS_ECS_WordPress_HLD.md) | Parent HLD |
| REF-DNS-002 | [Route53 Developer Guide](https://docs.aws.amazon.com/route53/) | AWS Documentation |
| REF-DNS-003 | [ACM User Guide](https://docs.aws.amazon.com/acm/) | AWS Documentation |

---

**END OF DOCUMENT**
