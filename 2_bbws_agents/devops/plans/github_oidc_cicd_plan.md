# Plan: Create GitHub OIDC Setup and Multi-Service Deployment Skill

## Overview
Create a comprehensive DevOps Engineer skill that codifies the knowledge from today's session on setting up GitHub Actions with AWS OIDC authentication, configuring CI/CD pipelines, and deploying infrastructure (S3, Lambda, ECS, CloudFront, Route53) to AWS.

## User Requirements
- Setup GitHub OIDC authentication with AWS
- Configure GitHub Actions pipelines
- Verify resources are created in target AWS accounts
- Support deployment of: S3, Lambda, ECS hosted services, CloudFront, Route53 (equal depth for all)
- Learn from this troubleshooting session (OIDC trust policy, IAM permissions, Terraform backend)
- Make it thorough and production-ready
- **Validation approach**: Before/after AWS service queries, compare diff with Terraform output (no scripts)
- **Environment awareness**: 3 environments (dev/sit/prod) with promotion workflow
- **Region mapping**: DEV/SIT=eu-west-1, PROD=af-south-1 (integrate with aws_region_specification.skill.md)
- **Focus**: Initial setup only (no team member onboarding section)

## Session Learnings to Capture

### 1. OIDC Setup Issues Encountered
- **Trust Policy Organization Name**: Must match GitHub organization exactly (BigBeardWebSolutions, not tsekatm)
- **GitHub Secret Configuration**: AWS_ROLE_DEV must contain IAM role ARN
- **Trust Policy Scope**: Allow multiple repositories via array or wildcard pattern
- **Backend State Management**: S3 bucket and DynamoDB table permissions required

### 2. IAM Permission Requirements
- **S3 Backend Access**: ListBucket on bucket + GetObject/PutObject/DeleteObject on objects
- **DynamoDB State Lock**: GetItem, PutItem, DeleteItem, DescribeTable
- **Resource-Specific Permissions**: DynamoDB tables, Lambda functions, ECS services, etc.
- **Common Mistake**: Hardcoded resource ARNs that don't match actual resource names

### 3. Terraform Backend Configuration
- **Parameterization**: Remove hardcoded backend config from main.tf
- **Workflow Override**: Use -backend-config flags in GitHub Actions
- **Multi-Environment**: Different backends for dev/sit/prod
- **Key Lesson**: backend "s3" {} with runtime parameters > hardcoded values

### 4. Workflow Patterns
- **OIDC Permissions Block**: id-token: write, contents: read
- **Region Selection**: Environment-specific (eu-west-1 for dev/sit, af-south-1 for prod)
- **Validation Steps**: Post-deployment resource verification
- **Error Handling**: Clear error messages for debugging

## Skill File Location
**Path**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_agents/devops/skills/github_oidc_cicd.skill.md`

**Rationale**: Place alongside existing DevOps skills:
- aws_region_specification.skill.md
- multi_repo_tbt_init.skill.md
- wordpress_container_troubleshooting.skill.md

## Skill Structure (Following Established Pattern)

### Header Section
```markdown
# GitHub OIDC and CI/CD Pipeline Setup Skill

**Version**: 1.0
**Created**: 2025-12-26
**Type**: Infrastructure / DevOps / CI/CD
**Purpose**: Setup GitHub Actions with AWS OIDC authentication and deploy infrastructure
```

### Main Sections

1. **Purpose**
   - Clear problem statement
   - When to use this skill
   - What problems it solves

2. **Prerequisites**
   - AWS account access with IAM permissions
   - GitHub repository access
   - Terraform knowledge
   - GitHub CLI (gh) installed

3. **Phase 1: OIDC Provider Setup**
   - Check if OIDC provider exists
   - Create OIDC provider if needed
   - Verify provider configuration
   - Commands and validation steps

4. **Phase 2: IAM Role Creation**
   - Create GitHub Actions role
   - Configure trust policy (with organization name pattern matching)
   - Attach permissions policy
   - Common trust policy patterns (single repo, multi-repo, wildcard)
   - Example trust policies for different scenarios

5. **Phase 3: IAM Permissions Policy**
   - Service-specific permissions (S3, Lambda, ECS, CloudFront, Route53, DynamoDB)
   - Terraform state backend permissions (S3 + DynamoDB)
   - Principle of least privilege
   - Example policies for each service type
   - Common mistakes to avoid (wrong resource ARNs, missing actions)

6. **Phase 4: GitHub Secrets Configuration**
   - Set AWS_ROLE_ARN (or AWS_ROLE_DEV/SIT/PROD)
   - Using gh CLI for secrets
   - Verify secrets are set
   - Multi-environment secret patterns

7. **Phase 5: GitHub Actions Workflow**
   - OIDC permissions block (id-token: write)
   - aws-actions/configure-aws-credentials@v4 usage
   - Environment-specific configuration
   - Terraform backend parameterization
   - Example workflows for each service:
     - DynamoDB deployment
     - S3 bucket creation
     - Lambda function deployment
     - ECS service deployment
     - CloudFront distribution
     - Route53 DNS records

8. **Phase 6: Terraform Backend Configuration**
   - Remove hardcoded backend configs
   - Use backend "s3" {} pattern
   - Provide config via -backend-config flags
   - Multi-environment backend strategy
   - Example configurations

9. **Phase 7: Post-Deployment Validation (AWS Query-Based)**
   - Pre-deployment resource snapshot (aws list commands)
   - Post-deployment resource snapshot (aws list commands)
   - Compare diff between snapshots
   - Validate against Terraform output
   - Service-specific validation queries:
     - DynamoDB: `aws dynamodb list-tables` before/after
     - S3: `aws s3 ls` before/after
     - Lambda: `aws lambda list-functions` before/after
     - ECS: `aws ecs list-services --cluster CLUSTER` before/after
     - CloudFront: `aws cloudfront list-distributions` before/after
     - Route53: `aws route53 list-hosted-zones` and `list-resource-record-sets` before/after
   - Terraform output comparison strategy
   - No script execution - pure AWS CLI queries

10. **Troubleshooting Guide**
    - Error: "Not authorized to perform sts:AssumeRoleWithWebIdentity"
      - Solution: Check trust policy organization name
      - Solution: Verify GitHub secret is set
      - Solution: Check repository name matches pattern

    - Error: "Failed to get existing workspaces" (Terraform S3 backend)
      - Solution: Add s3:ListBucket permission
      - Solution: Verify bucket name in permissions policy

    - Error: "AccessDenied" on DynamoDB state lock
      - Solution: Add DynamoDB permissions for state table
      - Solution: Verify table name matches

    - Error: Terraform init fails with backend config
      - Solution: Remove hardcoded backend from main.tf
      - Solution: Use -backend-config flags in workflow

11. **Helper Scripts and Commands**
    - Check OIDC provider: `aws iam list-open-id-connect-providers`
    - Get role trust policy: `aws iam get-role --role-name ROLE_NAME`
    - Update trust policy: `aws iam update-assume-role-policy`
    - Create IAM policy version: `aws iam create-policy-version`
    - Set GitHub secrets: `gh secret set SECRET_NAME`
    - List GitHub secrets: `gh secret list`
    - Run workflow: `gh workflow run WORKFLOW_NAME`
    - Watch workflow: `gh run watch RUN_ID`

12. **Service-Specific Deployment Patterns**

    **DynamoDB:**
    - Table creation with on-demand billing
    - Point-in-time recovery
    - Streams for replication
    - Global secondary indexes
    - Validation script example

    **S3:**
    - Bucket creation with encryption
    - Versioning and lifecycle policies
    - Public access block configuration
    - Cross-region replication
    - CloudFront integration

    **Lambda:**
    - Function deployment
    - IAM role for Lambda
    - Environment variables
    - VPC configuration
    - Layers and dependencies

    **ECS:**
    - Task definition creation
    - Service deployment
    - Load balancer integration
    - Auto-scaling configuration
    - Service discovery

    **CloudFront:**
    - Distribution creation
    - Origin configuration (S3, ALB)
    - Custom domains and certificates
    - Cache behaviors
    - WAF integration

    **Route53:**
    - Hosted zone management
    - Record set creation
    - Health checks
    - Failover routing
    - Alias records

13. **Multi-Environment Strategy & Promotion Workflow**
    - **Three Environments**:
      - DEV (536580886816, eu-west-1): Development and testing
      - SIT (815856636111, eu-west-1): Staging/integration testing
      - PROD (093646564004, af-south-1): Production with DR in eu-west-1

    - **Promotion Workflow** (CRITICAL):
      - Fix defects in DEV → Test in DEV → Promote to SIT
      - Test in SIT → Promote to PROD
      - NEVER deploy directly to PROD without SIT validation
      - PROD is read-only for validation

    - **Region Mapping** (from aws_region_specification.skill.md):
      - DEV: eu-west-1 (Ireland)
      - SIT: eu-west-1 (Ireland)
      - PROD Primary: af-south-1 (Cape Town)
      - PROD DR: eu-west-1 (Ireland, passive standby)

    - **Workflow Parameterization**:
      - Single workflow with environment input parameter
      - Automatic region selection based on environment
      - Environment-specific IAM role secrets (AWS_ROLE_DEV, AWS_ROLE_SIT, AWS_ROLE_PROD)
      - Backend state isolation per environment

    - **Example Workflow Structure**:
      ```yaml
      on:
        workflow_dispatch:
          inputs:
            environment:
              type: choice
              options: [dev, sit, prod]

      jobs:
        deploy:
          steps:
            - name: Set region
              run: |
                case ${{ inputs.environment }} in
                  dev|sit) echo "region=eu-west-1" ;;
                  prod) echo "region=af-south-1" ;;
                esac
      ```

14. **Security Best Practices**
    - Principle of least privilege
    - Separate IAM roles per environment
    - Audit GitHub Actions logs
    - Secret rotation procedures
    - Trust policy scoping (specific repos vs wildcards)

15. **Integration Examples**
    - Complete workflow examples
    - Python boto3 validation scripts
    - Bash deployment scripts
    - Terraform module references

16. **Quick Reference Card**
    ```
    GITHUB OIDC SETUP CHECKLIST
    ☐ 1. Create/verify OIDC provider in AWS
    ☐ 2. Create IAM role with trust policy
    ☐ 3. Attach permissions policy to role
    ☐ 4. Set GitHub secret AWS_ROLE_*
    ☐ 5. Configure workflow OIDC permissions
    ☐ 6. Parameterize Terraform backend
    ☐ 7. Test workflow deployment
    ☐ 8. Verify resources created
    ```

17. **Related Skills**
    - **aws_region_specification.skill.md**: Environment-region mapping
    - **HLD_LLD_Naming_Convention.skill.md**: Infrastructure naming
    - **Development_Best_Practices.skill.md**: Code quality standards

18. **Common Patterns (Copy-Paste Ready)**
    - Trust policy templates (single repo, multi-repo, wildcard)
    - Permissions policy templates (per service)
    - GitHub Actions workflow templates (per service)
    - Terraform backend configurations
    - Validation scripts

19. **Decision Trees**
    - When to use single IAM role vs multiple roles?
    - When to use wildcard in trust policy vs explicit repos?
    - When to separate workflows vs parameterize?
    - When to use manual approval gates?

20. **Version History**
    - v1.0 (2025-12-26): Initial skill created from OIDC troubleshooting session

## Key Learnings from Session to Emphasize

### Critical Success Factors
1. **Organization Name Matching**: Trust policy MUST match GitHub organization exactly
2. **Backend Permissions**: S3 ListBucket + object permissions + DynamoDB permissions
3. **Parameterization**: Never hardcode backend config in main.tf
4. **Resource ARN Accuracy**: IAM policies must reference actual resource names, not assumed names

### Common Pitfalls to Highlight
1. Wrong organization name in trust policy (tsekatm vs BigBeardWebSolutions)
2. Missing s3:ListBucket permission (only having object permissions)
3. Hardcoded backend config conflicting with workflow parameters
4. Mismatched resource names in IAM policy (2-1-bbws-tf-terraform-state-dev vs bbws-terraform-state-dev)

### Debugging Workflow to Document
1. Check OIDC provider exists
2. Verify GitHub secret is set
3. Check trust policy allows repository
4. Verify IAM permissions match actual resource names
5. Review GitHub Actions logs for specific error
6. Test with minimal permissions, then expand
7. Validate resources created post-deployment

## Files to Create

### Primary Skill File
**Path**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_agents/devops/skills/github_oidc_cicd.skill.md`
**Size Estimate**: ~1500-2000 lines (comprehensive like aws_region_specification.skill.md)

### Plan Document
**Path**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_agents/devops/plans/github_oidc_cicd_plan.md`
**Content**: Copy of this plan document for reference and documentation

### Supporting Files (Optional, Can Be Embedded)
None - all content will be self-contained in the skill file following the pattern of existing skills.

## Implementation Notes

### Style Guidelines
- Follow existing DevOps skill format (see aws_region_specification.skill.md)
- Use code blocks for all commands and configurations
- Include "wrong ❌ vs correct ✅" examples
- Provide copy-paste ready templates
- Use tables for structured data
- Include ASCII diagrams where helpful
- Add validation checkpoints throughout

### Content Depth
- Be thorough: This session revealed multiple layers of configuration
- Be practical: Include actual commands run in this session
- Be preventive: Highlight every mistake we encountered
- Be complete: Cover all services mentioned (S3, Lambda, ECS, CloudFront, Route53)

### Quality Criteria
- [ ] Covers full OIDC setup from scratch
- [ ] Addresses all errors encountered in session
- [ ] Provides service-specific deployment patterns
- [ ] Includes validation and troubleshooting
- [ ] Has copy-paste ready templates
- [ ] Integrates with existing skills (aws_region_specification)
- [ ] Follows established skill structure and style

## Next Steps After Plan Approval

1. Create the skill file at specified path
2. Populate with structured content following plan
3. Review for completeness and accuracy
4. Test examples for copy-paste readiness
5. Cross-reference with related skills
6. Add to DevOps Agent skill inventory

---

## Key Enhancements Based on User Feedback

1. **Equal Service Coverage**: All five services (S3, Lambda, ECS, CloudFront, Route53) receive comprehensive deployment patterns and examples

2. **Query-Based Validation**: No script execution - pure AWS CLI queries before/after deployment with diff comparison to Terraform outputs

3. **Environment-Aware Design**:
   - Full integration with 3-environment strategy (DEV→SIT→PROD)
   - Promotion workflow enforcement
   - Region mapping per environment (aws_region_specification.skill.md integration)

4. **Setup-Focused**: No team member onboarding section - pure DevOps engineer initial setup and configuration

## Success Criteria

The skill will be considered complete when it:
- [ ] Provides end-to-end OIDC setup from scratch
- [ ] Includes deployment patterns for all 5 AWS services (equal depth)
- [ ] Uses only AWS CLI queries for validation (no scripts)
- [ ] Integrates 3-environment promotion workflow (DEV→SIT→PROD)
- [ ] Maps regions correctly per environment (eu-west-1 for DEV/SIT, af-south-1 for PROD)
- [ ] Addresses all errors encountered in today's session
- [ ] Provides copy-paste ready templates
- [ ] Follows established skill structure and style
- [ ] Cross-references aws_region_specification.skill.md

---

**Plan Status**: Ready for review and implementation
**Estimated Implementation Time**: 60-75 minutes (comprehensive documentation with equal service depth)
**Complexity**: Medium-High (extensive content, clear structure, query-based validation approach)
