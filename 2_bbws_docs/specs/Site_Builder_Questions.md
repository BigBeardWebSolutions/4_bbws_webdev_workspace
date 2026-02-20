# BBWS Site Builder - HLD Clarification Questions

**Document**: Page Builder for HLD V1.0.docx.pdf
**Purpose**: Clarify requirements before creating the formal HLD
**Instructions**: Please provide answers in the "Answer" sections below

---

## Q1: Site Designer vs Page Builder Distinction

The PDF mentions 4 components: Site Migrator, Page/Site Builder, Site Deployer, and **Site Designer**. However, Site Designer ("AI-based, nuanced tasteful website crafter") is not detailed in the component list.

**Question**: Is Site Designer a separate microservice with its own Lambda/API, or is it functionality embedded within the Page Builder component?

**Answer**:
```
It's a separate agentic service consisting of multiple agents. Outliner, Logo Creator, Background Image Creator, Theme Selector,
```

---

## Q2: Disaster Recovery Strategy

The PDF specifies "Backup and restore" DR strategy with "Single region". However, global architecture standards require **multi-site active/active DR** with:
- Primary region: af-south-1 (South Africa)
- Failover region: eu-west-1 (Ireland)
- Hourly DynamoDB backups with cross-region replication
- S3 cross-region replication

**Question**: Should this solution follow the global multi-region active/active DR standard, or is single-region acceptable for this workload?

**Answer**:
```
Multi-region DR CPT and Dublin
```

---

## Q3: Image Generation Capability

The PDF references Claude Sonnet 4.5 for page generation. The aws-ai-website-generator skill mentions **Stable Diffusion XL** for AI image generation.

**Question**: Should the Site Builder include AI image generation capabilities (Stable Diffusion XL via Bedrock), or will it only use pre-existing assets from the design library?

**Answer**:
```
Go for a modular microservices architecture where agents are not combined but standalone.

```

---

## Q4: Multi-Tenant Organisation Hierarchy

Cognito is mentioned for authentication, but tenant management structure is not detailed. Global requirements specify:
- Organisation hierarchy: Division > Group > Team > User
- Users can belong to multiple teams
- Team-based data isolation
- Admin role management with invite capability

**Question**: What is the tenant hierarchy for this solution? Is it Organisation-only, or does it need the full Division/Group/Team/User structure?

**Answer**:
```
Multi-tenant Full Org->Division/Group/Team/User structure
```

---

## Q5: State Management for Long-Running Operations

Global requirements mandate a **state management DynamoDB table** for:
- Site generation tracking
- Transaction state (in-progress, completed, failed)
- Dead letter queue integration
- Exponential backoff retry handling

**Question**: The PDF mentions "DynamoDB - User State" for sessions. Is this the same as state management, or do we need a separate table specifically for tracking generation/deployment workflow states?

**Answer**:
```
Generation table manages state
```

---

## Q6: Environment Promotion Workflow

The PDF mentions DEV, SIT (UAT), and PROD environments. Global requirements specify:
- Fix defects in DEV first
- Promote to SIT for testing
- Promote to PROD after SIT validation
- PROD should be read-only for deployments

**Question**: What triggers promotion between environments? Is it manual approval, automated pipeline, or both? Who has authority to promote to PROD?

**Answer**:
```
Staging is automated by the tool. Dev is manual by developer. SIT is manual by the tester, Prod is manual by business owner.
```

---

## Q7: API and Infrastructure Separation

Global requirements mandate:
- Separate OpenAPI YAML files for each microservice API
- Separate Terraform scripts per microservice (not monolithic)

**Question**: How many distinct microservices/APIs should this solution have? Based on the PDF, I count at least 4 API groups:
1. `/v1/tenants/{tenant_id}` - Customer Management
2. `/v1/prompts/{tenant_id}` - Prompt Management
3. `/v1/sites/{tenant_id}/templates` - Site Management
3. `/v1/sites/{tenant_id}/generation` - Site generation Management
3. `/v1/sites/{tenant_id}/generation/{generation_id}/advisor` - Site generation Management
3. `/v1/sites/{tenant_id}/dns` - Site DNS Management
3. `/v1/sites/{tenant_id}/files` - Site file Management
3. `/v1/sites/{tenant_id}/deployments` - Site deployed versions Management
4. `/v1/migrations/{tenant_id}/` - Migration service
3. `/v1/use/registration` - Registration of users and organisation
3. `/v1/user/forgot/password` - Use password management
3. `/v1/user/{tenant}/` - Use tenant management
3. `/v1/user/invitation` - Invitations to join org, project or just register
3. `/v1/admin/{tenant_id}` - Manage tenants - Back office

Is this correct, or should there be more/fewer?

**Answer**:
```
Ideally all operations should be prefixed by the tenant Id. Except registration and password resets or any action where the tenant is unknowable.
```

---

## Q8: Brand Consistency Scoring

User Story #6 mentions "automatic validation of brand compliance" with minimum 8/10 score.

**Question**: How is brand consistency scored? Is there an existing scoring algorithm, or should the AI model (Claude) evaluate brand compliance? What specific criteria should be checked (colors, fonts, logos, layout patterns)?

**Answer**:
```
Recommend a scoring criteria
```

---

## Q9: Legacy Migration Source Systems

The PDF mentions "Migration of legacy sites from Xneelo to AWS" and converting WordPress to static HTML.

**Question**:
- Are there other source platforms besides WordPress/Xneelo?
- How many legacy sites need migration (rough estimate)?
- Is migration a one-time effort or ongoing capability?

**Answer**:
```
Wordperss and static HTML sources
Maybe other platforms like square space
```

---

## Q10: Cost Estimation Parameters

The PDF has placeholder links for cost estimation. To provide accurate estimates, I need:

**Question**: Please provide the following parameters:
- Expected monthly page generations: 10 000
- Expected concurrent users: 500 users
- Average pages per customer: 5
- Average storage per site (MB): 500 MB
- Expected monthly API calls: 50 calls per 500 users per day

**Answer**:
```
- Expected monthly page generations: 10 000
- Expected concurrent users: 500 users
- Average pages per customer: 5
- Average storage per site (MB): 500 MB
- Expected monthly API calls: 50 calls per 500 users per day

```

---

## Summary of TBCs from PDF (For Reference)

| TBC # | Description | Status |
|-------|-------------|--------|
| TBC2 | NFRs | Pending | 10 ms for non-generative max 1 min Time to Last Token for streaming services
| TBC3 | Solution Criticality | Pending | Business Critical / Business Support 
| TBC4 | Risk Assessment (Business) | Pending | BCP TBC
| TBC5 | RPO | Pending | 1 hour
| TBC6 | RTO | Pending | 1 min
| TBC8 | Risks and mitigation (Sec Team) | Pending |

---

**Next Steps**: Once answers are provided, I will proceed with creating the formal HLD document following the standard structure:
1. Business Purpose
2. Epics, User Stories & Scenarios
3. Component Diagram (4-layer architecture)
4. Component List
5. Cost Estimation
6. Security
7. Appendix A: TBCs
8. Appendix B: Referenced Documents
9. Appendix C: Definition of Terms


