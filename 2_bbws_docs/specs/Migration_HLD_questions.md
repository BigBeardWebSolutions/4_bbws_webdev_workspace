# BBWS Site Migration HLD - Clarifying Questions

## Project Overview
Based on the requirements, this solution will migrate websites from Xneelo to AWS using a multi-component approach:
- **SiteMigrator**: Python utility to pull website from live URL
- **SiteCleaner**: Python utility to fix WordPress URLs and hardcoded paths
- **SiteDeployer**: Deploy cleaned sites to S3 + CloudFront
- **CertificateManager**: ACM certificate management for prod/pre-prod
- **CloudFrontManager**: Configure CloudFront with S3 origin
- **FormSubmissionHandler**: Universal Lambda for form submissions

I need clarification on the following areas to create a comprehensive HLD:

---

## 1. Business Context Questions

### 1.1 Business Problem and Stakeholders
- **Q1.1**: What is the primary business problem this migration solves? (e.g., cost reduction, performance improvement, scalability)
  - **Answer:** Cost performance, scale and operations by simplifying arch

- **Q1.2**: Who are the key stakeholders for this project? (e.g., BBWS management, customers, development team, operations)
  - **Answer:** Architect, Exec Sponsor, Sales Lead

- **Q1.3**: What are the expected business outcomes? (e.g., reduce hosting costs by X%, improve site performance, enable scaling)
  - **Answer:** Reduce time to market from days to minutes and allows self wervice

- **Q1.4**: How many websites need to be migrated initially, and what is the expected growth?
  - **Answer:** 40

### 1.2 Timeline and Scope
- **Q1.5**: What is the project timeline? (e.g., MVP in 3 months, full rollout in 6 months)
  - **Answer:** 3 Months for everything

- **Q1.6**: Is this migration for BBWS's own sites, customer sites, or both?
  - **Answer:** Custoemrs

- **Q1.7**: What is explicitly OUT OF SCOPE for this HLD? (e.g., email hosting, database migration, application rewrites)
  - **Answer:** Email Hosting, Database Migration, Application Migration

- **Q1.8**: Are there any budget constraints for AWS infrastructure?
  - **Answer:** This should be done ideally by one developer

### 1.3 Success Criteria
- **Q1.9**: How will success be measured? (e.g., X sites migrated, Y% cost savings, Z% performance improvement)
  - **Answer:** Number of site

- **Q1.10**: What happens to the Xneelo hosting after migration? (immediate decommission, parallel running, gradual cutover)
  - **Answer:** Parallel run and gradual switchover

---

## 2. Technical Details Questions (Essential 10)

- **Q2.1**: How does SiteMigrator authenticate to pull sites from Xneelo, and what types of sites are being migrated? (FTP/SFTP/HTTP, static HTML/WordPress/mixed)
  - **Answer:** Using a config file

- **Q2.2**: Where should the migration utilities run? (local machine, EC2, Lambda, ECS)
  - **Answer:** local

- **Q2.3**: What specific WordPress quirks need fixing by SiteCleaner? (absolute URLs, hardcoded paths, database refs, etc.)
  - **Answer:** absolute pathing and expecting WP plugins

- **Q2.4**: How should S3 bucket organization work? (one bucket per site, all sites in folders, versioning enabled?)
  - **Answer:** folder per site

- **Q2.5**: Should the solution support rollback and automated deployment?
  - **Answer:** yes

- **Q2.6**: Who owns domains, where is DNS hosted, and should certificate creation be automated? (BBWS/customers, Xneelo DNS, ACM automation)
  - **Answer:** BBWS on XNeelo

- **Q2.7**: What CloudFront caching strategy and security features are needed? (OAC/OAI, caching rules, HTTP→HTTPS redirects)
  - **Answer:** CF protected by basic auth in pre-prod.

- **Q2.8**: What form submission requirements exist? (form types, email service, storage duration, spam protection)
  - **Answer:** The forms are specific to each site

- **Q2.9**: Should the migration workflow be orchestrated end-to-end? (Step Functions or manual execution per component)
  - **Answer:** no it's manual

- **Q2.10**: What error handling and monitoring strategy? (retry logic, CloudWatch dashboards, SNS alerts)
  - **Answer:** local write to file.

---

## 3. Security & Compliance Questions

### 3.1 Authentication and Authorization
- **Q3.1**: Who should have access to run migration utilities? (BBWS admins only, customers, both)
- **Answer:** devs
- **Q3.2**: Should access be via AWS Console, CLI, or custom web interface?
- **Answer:** Console
- **Q3.3**: What IAM strategy? (role-based access, user-based, federated identity)
- **Answer:** Role based
- **Q3.4**: Should MFA (Multi-Factor Authentication) be required for production operations?
- **Answer:** No

### 3.2 Data Protection
- **Q3.5**: Should S3 buckets use encryption at rest? (SSE-S3, SSE-KMS, other)
- **Answer:** SSE-S3
- **Q3.6**: Are there GDPR or data privacy requirements? (customer data in forms, analytics data)
**Answer:** yes
- **Q3.7**: Should S3 bucket access logs be enabled for audit trails?
**Answer:** yes
- **Q3.8**: Should versioning and MFA Delete be enabled on S3 buckets?
**Answer:** yes

### 3.3 Network Security
- **Q3.9**: Should CloudFront use AWS WAF for DDoS/bot protection?
**Answer:** yes
- **Q3.10**: Should there be rate limiting on form submissions?
**Answer:** yes
- **Q3.11**: Are there IP whitelisting or geo-blocking requirements?
**Answer:** no

### 3.4 Secrets Management
- **Q3.12**: Where should credentials be stored? (AWS Secrets Manager, Parameter Store, other)
**Answer:** AWS secrets manager
- **Q3.13**: What credentials need management? (Xneelo FTP, email SMTP, API keys)
**Answer:** API keys

### 3.5 Compliance and Audit
- **Q3.14**: Are there compliance requirements? (PCI-DSS for payment forms, HIPAA, SOC 2)
- **Q3.15**: Should all actions be logged to CloudTrail?
- **Q3.16**: Are there audit retention requirements? (logs kept for X months/years)

---

## 4. Non-Functional Requirements (NFRs)

### 4.1 Performance Requirements
- **Q4.1**: What is the expected response time for static site pages? (e.g., < 500ms for first byte)
- **Q4.2**: What is the expected response time for form submissions? (e.g., < 2 seconds)
- **Q4.3**: How many concurrent users per site? (e.g., 100, 1000, 10000)
- **Q4.4**: What is the expected data transfer volume per month? (e.g., 100GB, 1TB)

### 4.2 Scalability Requirements
- **Q4.5**: How many sites should the solution support? (10 sites, 100 sites, 1000+ sites)
- **Q4.6**: Should the solution auto-scale based on traffic?
- **Q4.7**: Are there expected traffic spikes? (seasonal, marketing campaigns)

### 4.3 Availability and Reliability
- **Q4.8**: What is the required uptime SLA? (99%, 99.9%, 99.99%)
- **Q4.9**: What is the acceptable Recovery Time Objective (RTO)? (minutes, hours, days)
- **Q4.10**: What is the acceptable Recovery Point Objective (RPO)? (zero data loss, 1 hour, 24 hours)
- **Q4.11**: Should the solution be multi-region for disaster recovery?

### 4.4 Operational Requirements
- **Q4.12**: What monitoring/alerting is needed? (CloudWatch dashboards, SNS alerts, PagerDuty integration)
- **Q4.13**: Who will be on-call for production issues? (BBWS DevOps, AWS Support, third-party)
- **Q4.14**: Should there be automated backups? (daily, weekly, retention period)
- **Q4.15**: Are there maintenance windows for updates/migrations?

### 4.5 Cost Constraints
- **Q4.16**: What is the monthly AWS budget? (hard limit, soft limit, no limit)
- **Q4.17**: Should cost optimization be prioritized over performance/features?
- **Q4.18**: Are there specific services that should be avoided due to cost? (e.g., NAT Gateway, CloudFront in certain regions)

### 4.6 Environment Strategy
- **Q4.19**: What environments are needed? (dev, qa, uat, preprod, prod)
- **Q4.20**: Should environments be in separate AWS accounts or same account?
- **Q4.21**: Should non-prod environments auto-shutdown to save costs?

---

## 5. Additional Questions

### 5.1 Dependencies and Integrations
- **Q5.1**: Are there external systems this solution integrates with? (CRM, analytics, payment gateways)
- **Q5.2**: Should migrated sites integrate with existing BBWS services?
- **Q5.3**: Are there third-party tools/services to consider? (CDN providers, monitoring tools, backup services)

### 5.2 Testing and Validation
- **Q5.4**: How should migrated sites be validated? (automated testing, manual QA, customer approval)
- **Q5.5**: Should there be A/B testing (compare Xneelo vs AWS performance)?
- **Q5.6**: What is the rollback strategy if migration fails?

### 5.3 Documentation and Training
- **Q5.7**: Who needs training on this solution? (BBWS team, customers)
- **Q5.8**: What documentation is needed? (runbooks, user guides, API docs)

### 5.4 Future Considerations
- **Q5.9**: Are there plans to extend this solution? (support other platforms beyond Xneelo, add CMS features)
- **Q5.10**: Should the architecture support future migration to containers/serverless frameworks?

---

## Response Instructions

Please answer the questions by:
1. Providing answers directly in this file (under each question), OR
2. Creating a separate answers file, OR
3. Discussing via our conversation

For questions that are TBC (To Be Confirmed), please note them as such, and they will be tracked in the HLD's TBC appendix.

**Priority questions** (please answer these at minimum):
- Q1.1, Q1.4, Q1.5, Q1.6 (Business context)
- Q2.1, Q2.2, Q2.11, Q2.13 (Technical core)
- Q2.24, Q2.26, Q2.27 (Form handler)
- Q3.5, Q3.9, Q3.12 (Security essentials)
- Q4.8, Q4.9, Q4.10, Q4.16 (NFR critical items)
