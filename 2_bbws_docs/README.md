# BBWS Documentation

Technical documentation for the BBWS Multi-Tenant WordPress Hosting Platform.

## Overview

This repository contains:
- **HLDs**: High-Level Design documents
- **LLDs**: Low-Level Design documents
- **Training**: User training materials and quizzes
- **Specs**: Requirements and specification documents

## Directory Structure

```
HLDs/
├── BBWS_ECS_WordPress_HLD.md         # ECS WordPress hosting platform
├── BBWS_Admin_App_HLD.md             # Admin application
├── BBWS_Admin_Portal_HLD.md          # Admin portal
├── BBWS_Customer_Portal_Public_HLD.md  # Public customer portal
├── BBWS_Customer_Portal_Private_HLD.md # Private customer portal
├── BBWS_Migration_HLD.md             # Migration strategy
└── BBSW_Site_Builder_HLD.md          # Site builder

LLDs/
├── Tenant_Management_LLD.md          # Tenant management
├── VPC_LLD.md                        # VPC architecture
├── DNS_LLD.md                        # DNS configuration
├── Container_LLD.md                  # Container architecture
├── Cognito_Tenant_Pools_LLD.md       # Cognito setup
├── Content_Management_LLD.md         # Content management
├── Site_Management_LLD.md            # Site management
├── DevOps_Site_Promotion_Multi_ACC_LLD.md  # DevOps processes
├── CPP_Frontend_Architecture_LLD.md  # Customer portal frontend
├── CPP_Auth_Lambda_LLD.md            # Authentication Lambda
├── CPP_Cart_Lambda_LLD.md            # Cart Lambda
├── CPP_Order_Lambda_LLD.md           # Order Lambda
├── CPP_Payment_Lambda_LLD.md         # Payment Lambda
├── CPP_Product_Lambda_LLD.md         # Product Lambda
├── CPP_Contact_Lambda_LLD.md         # Contact Lambda
├── CPP_Marketing_Lambda_LLD.md       # Marketing Lambda
├── CPP_Newsletter_Lambda_LLD.md      # Newsletter Lambda
├── CPP_Invitation_Lambda_LLD.md      # Invitation Lambda
├── CPP_Deployment_Runbook.md         # Deployment procedures
├── CPP_DR_Runbook.md                 # Disaster recovery
├── CPP_Monitoring_Runbook.md         # Monitoring setup
├── CPP_Security_Runbook.md           # Security procedures
└── CPP_Troubleshooting_Runbook.md    # Troubleshooting guide

training/
├── plans/
│   ├── master_plan.md                # Training master plan
│   ├── plan_content_manager.md       # Content manager training plan
│   ├── plan_tenant_admin.md          # Tenant admin training plan
│   └── plan_super_admin.md           # Super admin training plan
├── content_manager/
│   └── quiz_content_manager.md       # Content manager quiz
├── tenant_admin/
│   └── quiz_tenant_admin.md          # Tenant admin quiz
└── super_admin/
    └── quiz_super_admin.md           # Super admin quiz

specs/
├── BBWS_ECS_WordPress_HLD_spec.md    # ECS WordPress spec
├── BBWS_Admin_App_HLD_spec.md        # Admin app spec
├── Migration_HLD_questions.md        # Migration questions
├── Site_Builder_Questions.md         # Site builder questions
└── Page Builder for HLD V1.0.docx.pdf # Page builder PDF
```

## Document Types

### High-Level Designs (HLDs)

System-level architecture documents covering:
- System context and scope
- Architecture patterns and styles
- Component interactions
- AWS service selections
- Non-functional requirements

### Low-Level Designs (LLDs)

Detailed component specifications including:
- API contracts and interfaces
- Database schemas
- Infrastructure configurations
- Security implementations
- Deployment procedures

### Training Materials

User training content:
- Training plans by role
- Knowledge quizzes
- Best practices guides

### Specifications

Requirements and specifications:
- Feature specifications
- Business requirements
- Technical questions and answers

## Related Repositories

- `2_bbws_ecs_terraform` - Infrastructure as Code
- `2_bbws_tenant_provisioner` - Tenant management CLI
- `2_bbws_wordpress_container` - WordPress Docker image
- `2_bbws_ecs_tests` - Integration tests
- `2_bbws_agents` - AI agents and utilities
- `2_bbws_ecs_operations` - Dashboards, alerts, runbooks

## License

Proprietary - Big Beard Web Solutions
