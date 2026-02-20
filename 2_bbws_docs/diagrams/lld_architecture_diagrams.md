# LLD Architecture Diagrams

**Version**: 1.0
**Created**: 2026-01-25
**Worker**: 6-8 (Stage 6 - Project Plan 5 LLD Implementation)
**Purpose**: Comprehensive architecture diagrams for all LLD components

---

## Table of Contents

1. [Component Diagram](#1-component-diagram)
2. [Deployment Diagram](#2-deployment-diagram)
3. [Sequence Diagrams](#3-sequence-diagrams)
4. [Data Flow Diagram](#4-data-flow-diagram)
5. [Event Flow Diagram](#5-event-flow-diagram)

---

## 1. Component Diagram

### 1.1 Full System Component Diagram

This diagram shows all services and their interactions across the BBWS platform.

```mermaid
graph TB
    subgraph "Client Layer"
        CPP[Customer Portal Public<br/>React Frontend]
        CPPrivate[Customer Portal Private<br/>React Frontend]
        AdminPortal[Admin Portal<br/>React Frontend]
        AdminApp[Admin App<br/>Mobile]
    end

    subgraph "API Layer"
        APIGW[API Gateway<br/>REST APIs]
        Authorizer[Cognito Authorizer<br/>JWT Validation]
    end

    subgraph "Tenant Management Service"
        TenantLambda[Tenant Lambda<br/>2_bbws_tenant_lambda]
        subgraph "Tenant Handlers"
            TC[tenant-create]
            TG[tenant-get]
            TL[tenant-list]
            TU[tenant-update]
            TD[tenant-delete]
            TP[tenant-park]
            TUP[tenant-unpark]
        end
    end

    subgraph "Site Management Service"
        SiteLambda[Site Management Lambda<br/>2_bbws_wordpress_site_management_lambda]
        subgraph "Sites Service"
            SC[site-create]
            SG[site-get]
            SL[site-list]
            SU[site-update]
            SD[site-delete]
            SProm[site-promote]
        end
        subgraph "Templates Service"
            TempL[template-list]
            TempA[template-apply]
        end
        subgraph "Plugins Service"
            PlugL[plugin-list]
            PlugI[plugin-install]
            PlugU[plugin-uninstall]
        end
        subgraph "Async Processor"
            SQSConsumer[SQS Consumer<br/>Site Creator]
        end
    end

    subgraph "Instance Management Service"
        InstanceLambda[Instance Lambda<br/>2_bbws_tenants_instances_lambda]
        subgraph "Instance Handlers"
            IC[instance-create]
            IG[instance-get]
            IL[instance-list]
            IU[instance-update]
            IDel[instance-delete]
            IScale[instance-scale]
            IStatus[instance-status]
        end
        subgraph "Helper Classes"
            ECSHelper[ECS_Helper]
            TFHelper[TF_Helper]
            GitHelper[Git_Helper]
            GHActionsHelper[GH_Actions_Helper]
        end
    end

    subgraph "Event Handler Service"
        EventHandler[Event Handler Lambda<br/>2_bbws_tenants_event_handler]
        StateSync[synchronise-tenant-state]
    end

    subgraph "Data Layer"
        DDBTenants[(DynamoDB<br/>bbws-tenants)]
        DDBSites[(DynamoDB<br/>sites)]
        DDBInstances[(DynamoDB<br/>tenant-resources)]
    end

    subgraph "Message Layer"
        SQSCreate[SQS<br/>Site Creation Queue]
        SQSDLQ[SQS<br/>Dead Letter Queue]
        SNS[SNS<br/>Notifications]
        EventBridge[EventBridge<br/>Event Bus]
    end

    subgraph "Infrastructure Layer"
        ECS[ECS Cluster<br/>Fargate Tasks]
        ALB[Application<br/>Load Balancer]
        EFS[EFS<br/>WordPress Content]
        RDS[(RDS MySQL<br/>WordPress DB)]
    end

    subgraph "Identity Layer"
        Cognito[Cognito<br/>User Pools]
        SecretsManager[Secrets Manager<br/>Credentials]
    end

    subgraph "External - GitOps"
        GitHub[GitHub<br/>Terraform Repos]
        GHActions[GitHub Actions<br/>Terraform Apply]
    end

    %% Client to API
    CPP --> APIGW
    CPPrivate --> APIGW
    AdminPortal --> APIGW
    AdminApp --> APIGW

    %% API to Auth
    APIGW --> Authorizer
    Authorizer --> Cognito

    %% API to Lambdas
    APIGW --> TenantLambda
    APIGW --> SiteLambda
    APIGW --> InstanceLambda

    %% Tenant Lambda flows
    TenantLambda --> DDBTenants
    TenantLambda --> EventBridge
    TenantLambda --> SNS
    TenantLambda --> Cognito

    %% Site Lambda flows
    SiteLambda --> DDBSites
    SiteLambda --> SQSCreate
    SiteLambda --> ALB
    SiteLambda --> SecretsManager
    SQSCreate --> SQSConsumer
    SQSConsumer --> ALB
    SQSConsumer --> DDBSites
    SQSConsumer --> SNS
    SQSCreate -.-> SQSDLQ

    %% Instance Lambda flows
    InstanceLambda --> DDBInstances
    InstanceLambda --> ECSHelper
    InstanceLambda --> TFHelper
    TFHelper --> GitHelper
    GitHelper --> GitHub
    GHActionsHelper --> GHActions
    GHActions --> ECS
    ECSHelper --> ECS

    %% Event Handler flows
    ECS --> EventBridge
    EventBridge --> EventHandler
    EventHandler --> DDBInstances

    %% Infrastructure
    ALB --> ECS
    ECS --> EFS
    ECS --> RDS
```

### 1.2 Tenant Lambda Service Components

```mermaid
classDiagram
    direction TB

    class TenantHandler {
        <<Handler>>
        -TenantService service
        -RequestValidator validator
        +handle(event, context) APIResponse
    }

    class TenantService {
        <<Service>>
        -TenantDao dao
        -CognitoService cognito
        -EventPublisher events
        -AuditLogger audit
        +createTenant(request) Tenant
        +getTenant(tenantId) Tenant
        +listTenants(query) PaginatedResponse
        +updateTenant(tenantId, request) Tenant
        +deleteTenant(tenantId, force) void
        +parkTenant(tenantId, reason) Tenant
        +unparkTenant(tenantId) Tenant
    }

    class TenantDao {
        <<Repository>>
        -DynamoDBTable table
        +create(tenant) Tenant
        +getById(tenantId) Tenant
        +getByOrgName(name) Tenant
        +update(tenant) Tenant
        +updateStatus(tenantId, status) void
        +query(params) PaginatedResult
    }

    class UserAssignmentService {
        <<Service>>
        +assignUser(tenantId, request) UserAssignment
        +listUsers(tenantId, query) PaginatedResponse
        +removeUser(tenantId, userId) void
        +getUserTenants(userId) list
    }

    class HierarchyService {
        <<Service>>
        +createHierarchy(tenantId, request) Hierarchy
        +updateHierarchy(tenantId, request) Hierarchy
        +deleteHierarchy(tenantId) void
    }

    class CognitoService {
        <<Client>>
        +getUserByEmail(email) CognitoUser
        +updateUserAttributes(userId, attrs) void
        +addUserToGroup(userId, group) void
        +removeUserFromGroup(userId, group) void
    }

    class EventPublisher {
        <<Client>>
        -EventBridgeClient client
        +publish(eventType, detail) void
    }

    TenantHandler --> TenantService
    TenantHandler --> UserAssignmentService
    TenantHandler --> HierarchyService
    TenantService --> TenantDao
    TenantService --> CognitoService
    TenantService --> EventPublisher
    UserAssignmentService --> TenantDao
    UserAssignmentService --> CognitoService
    HierarchyService --> TenantDao
```

### 1.3 Site Management Service Components

```mermaid
classDiagram
    direction TB

    class SiteHandler {
        <<Handler>>
        -SiteService service
        +handle(event, context) APIResponse
    }

    class SiteService {
        <<Service>>
        -SiteDAO dao
        -WordPressClient wpClient
        -NotificationService notify
        +createSite(tenantId, request) Site
        +getSite(tenantId, siteId) Site
        +listSites(tenantId) PaginatedResponse
        +updateSite(tenantId, siteId, request) Site
        +deleteSite(tenantId, siteId) void
        +cloneSite(tenantId, siteId, request) Site
        +promoteSite(tenantId, siteId, targetEnv) Site
    }

    class TemplateService {
        <<Service>>
        -TemplateDAO dao
        -WordPressClient wpClient
        +listTemplates(category) PaginatedResponse
        +getTemplate(templateId) Template
        +applyTemplate(tenantId, siteId, templateId) Site
        +previewTemplate(templateId) PreviewResponse
    }

    class PluginService {
        <<Service>>
        -PluginDAO dao
        -WordPressClient wpClient
        -SecurityScanner scanner
        +listMarketplace(category) PaginatedResponse
        +installPlugin(tenantId, siteId, pluginId) InstalledPlugin
        +uninstallPlugin(tenantId, siteId, pluginId) void
        +configurePlugin(tenantId, siteId, pluginId, config) InstalledPlugin
    }

    class WordPressClient {
        <<Client>>
        -tenantId string
        -albDns string
        +createSite(name, slug) dict
        +getSite(siteId) dict
        +installPlugin(slug) dict
        +activateTheme(themeSlug) dict
    }

    class SQSConsumer {
        <<Consumer>>
        -SiteService service
        -WordPressClient wpClient
        +processSiteCreation(record) void
        +processSiteUpdate(record) void
        +processSiteDeletion(record) void
    }

    SiteHandler --> SiteService
    SiteHandler --> TemplateService
    SiteHandler --> PluginService
    SiteService --> WordPressClient
    TemplateService --> WordPressClient
    PluginService --> WordPressClient
    SQSConsumer --> SiteService
    SQSConsumer --> WordPressClient
```

### 1.4 Instance Management Service Components

```mermaid
classDiagram
    direction TB

    class InstanceHandler {
        <<Handler>>
        -ECS_Helper ecsHelper
        -TF_Helper tfHelper
        -Git_Helper gitHelper
        -GH_Actions_Helper ghHelper
        +handle(event, context) APIResponse
    }

    class ECS_Helper {
        <<Helper>>
        -boto3_client ecsClient
        +listServices(cluster) list
        +describeService(cluster, serviceName) dict
        +getServiceStatus(cluster, serviceName) dict
        +scaleService(cluster, serviceName, desiredCount) dict
        +stopService(cluster, serviceName) dict
        +startService(cluster, serviceName, desiredCount) dict
    }

    class TF_Helper {
        <<Helper>>
        -jinja2_env env
        +generateTenantConfig(tenantId, config) string
        +generateVariables(tenantId, config) string
        +generateOutputs(tenantId) string
        +generateTfvars(tenantId, config) string
    }

    class Git_Helper {
        <<Helper>>
        -workspacePath string
        -repoUrl string
        +cloneRepo() string
        +addFiles(files) void
        +commit(message) string
        +push() void
        +cleanup() void
    }

    class GH_Actions_Helper {
        <<Helper>>
        -githubToken string
        -repoOwner string
        -repoName string
        +triggerWorkflow(workflowId, inputs) dict
        +getWorkflowStatus(runId) dict
        +waitForCompletion(runId, timeout) dict
    }

    class StateSync_Handler {
        <<Handler - EventBridge>>
        -DynamoDB_Client db
        +handleECSEvent(event) void
        +extractTenantFromTags(tags) dict
        +mapEventToStatus(eventType) string
        +updateDynamoDB(tenantId, status) void
    }

    InstanceHandler --> ECS_Helper
    InstanceHandler --> TF_Helper
    InstanceHandler --> Git_Helper
    InstanceHandler --> GH_Actions_Helper
    TF_Helper --> Git_Helper
    Git_Helper --> GH_Actions_Helper
```

---

## 2. Deployment Diagram

### 2.1 Multi-Environment AWS Infrastructure

```mermaid
graph TB
    subgraph "DEV Environment"
        subgraph "AWS Account: 536580886816"
            subgraph "Region: af-south-1"
                subgraph "VPC - DEV"
                    subgraph "Public Subnets"
                        ALB_DEV[ALB<br/>bbws-alb-dev]
                        NAT_DEV[NAT Gateway]
                    end
                    subgraph "Private Subnets - AZ1"
                        ECS_DEV_AZ1[ECS Tasks<br/>Tenant Services]
                        Lambda_DEV_AZ1[Lambda Functions<br/>VPC Connected]
                    end
                    subgraph "Private Subnets - AZ2"
                        ECS_DEV_AZ2[ECS Tasks<br/>Tenant Services]
                        Lambda_DEV_AZ2[Lambda Functions<br/>VPC Connected]
                    end
                    subgraph "Data Subnets"
                        RDS_DEV[(RDS MySQL<br/>Multi-AZ)]
                        EFS_DEV[(EFS<br/>WordPress Content)]
                    end
                end
                APIGW_DEV[API Gateway]
                DDB_DEV[(DynamoDB<br/>On-Demand)]
                Cognito_DEV[Cognito<br/>User Pool]
                S3_DEV[(S3 Buckets<br/>No Public Access)]
                EventBridge_DEV[EventBridge]
                SQS_DEV[SQS Queues]
            end
        end
    end

    subgraph "SIT Environment"
        subgraph "AWS Account: 815856636111"
            subgraph "Region: af-south-1"
                subgraph "VPC - SIT"
                    subgraph "Public Subnets SIT"
                        ALB_SIT[ALB<br/>bbws-alb-sit]
                        NAT_SIT[NAT Gateway]
                    end
                    subgraph "Private Subnets SIT - AZ1"
                        ECS_SIT_AZ1[ECS Tasks]
                        Lambda_SIT_AZ1[Lambda Functions]
                    end
                    subgraph "Private Subnets SIT - AZ2"
                        ECS_SIT_AZ2[ECS Tasks]
                        Lambda_SIT_AZ2[Lambda Functions]
                    end
                    subgraph "Data Subnets SIT"
                        RDS_SIT[(RDS MySQL<br/>Multi-AZ)]
                        EFS_SIT[(EFS)]
                    end
                end
                APIGW_SIT[API Gateway]
                DDB_SIT[(DynamoDB)]
                Cognito_SIT[Cognito]
                S3_SIT[(S3 Buckets)]
                EventBridge_SIT[EventBridge]
                SQS_SIT[SQS Queues]
            end
        end
    end

    subgraph "PROD Environment"
        subgraph "AWS Account: 093646564004"
            subgraph "Primary Region: af-south-1"
                subgraph "VPC - PROD Primary"
                    subgraph "Public Subnets PROD"
                        ALB_PROD[ALB<br/>bbws-alb-prod]
                        NAT_PROD[NAT Gateway]
                    end
                    subgraph "Private Subnets PROD - AZ1"
                        ECS_PROD_AZ1[ECS Tasks]
                        Lambda_PROD_AZ1[Lambda Functions]
                    end
                    subgraph "Private Subnets PROD - AZ2"
                        ECS_PROD_AZ2[ECS Tasks]
                        Lambda_PROD_AZ2[Lambda Functions]
                    end
                    subgraph "Private Subnets PROD - AZ3"
                        ECS_PROD_AZ3[ECS Tasks]
                        Lambda_PROD_AZ3[Lambda Functions]
                    end
                    subgraph "Data Subnets PROD"
                        RDS_PROD[(RDS MySQL<br/>Multi-AZ)]
                        EFS_PROD[(EFS)]
                    end
                end
                APIGW_PROD[API Gateway]
                DDB_PROD[(DynamoDB<br/>Global Tables)]
                Cognito_PROD[Cognito]
                S3_PROD[(S3 Buckets<br/>Cross-Region Replication)]
                Route53[Route 53<br/>Health Checks]
                CloudFront[CloudFront<br/>CDN]
            end

            subgraph "DR Region: eu-west-1"
                subgraph "VPC - PROD DR"
                    ALB_DR[ALB<br/>bbws-alb-dr]
                    ECS_DR[ECS Tasks<br/>Standby]
                end
                DDB_DR[(DynamoDB<br/>Global Tables Replica)]
                S3_DR[(S3 Buckets<br/>Replicated)]
            end
        end
    end

    %% Cross-region replication
    DDB_PROD -.->|Global Tables| DDB_DR
    S3_PROD -.->|Cross-Region Replication| S3_DR
    Route53 --> ALB_PROD
    Route53 -.->|Failover| ALB_DR
```

### 2.2 Per-Environment Lambda Deployment

```mermaid
graph TB
    subgraph "Lambda Functions per Environment"
        subgraph "Tenant Lambda Stack"
            TL1[tenant-create-lambda]
            TL2[tenant-get-lambda]
            TL3[tenant-list-lambda]
            TL4[tenant-update-lambda]
            TL5[tenant-delete-lambda]
            TL6[tenant-park-lambda]
            TL7[tenant-unpark-lambda]
            TL8[tenant-status-lambda]
        end

        subgraph "Site Management Lambda Stack"
            SL1[site-create-lambda]
            SL2[site-get-lambda]
            SL3[site-list-lambda]
            SL4[site-update-lambda]
            SL5[site-delete-lambda]
            SL6[site-clone-lambda]
            SL7[site-promote-lambda]
            SL8[site-health-lambda]
            SL9[template-list-lambda]
            SL10[template-apply-lambda]
            SL11[plugin-list-lambda]
            SL12[plugin-install-lambda]
            SL13[sqs-site-creator-lambda]
        end

        subgraph "Instance Lambda Stack"
            IL1[instance-create-lambda]
            IL2[instance-get-lambda]
            IL3[instance-list-lambda]
            IL4[instance-update-lambda]
            IL5[instance-delete-lambda]
            IL6[instance-status-get-lambda]
            IL7[instance-status-update-lambda]
            IL8[instance-size-update-lambda]
        end

        subgraph "Event Handler Lambda Stack"
            EL1[synchronise-tenant-state-lambda]
        end
    end

    subgraph "Lambda Configuration"
        Runtime[Python 3.12]
        Arch[Architecture: arm64]
        Framework[AWS Lambda Powertools]
        VPC[VPC Connected]
    end

    subgraph "Lambda Layers"
        Layer1[powertools-layer]
        Layer2[boto3-layer]
        Layer3[common-utils-layer]
    end
```

---

## 3. Sequence Diagrams

### 3.1 Tenant Creation Flow

```mermaid
sequenceDiagram
    participant Client
    participant APIGW as API Gateway
    participant Auth as Cognito Authorizer
    participant Lambda as Tenant Create Lambda
    participant Validator as RequestValidator
    participant Service as TenantService
    participant DAO as TenantDao
    participant DDB as DynamoDB
    participant EB as EventBridge
    participant Audit as AuditLogger

    Client->>APIGW: POST /v1.0/tenants
    Note over APIGW: {organizationName, contactEmail, environment}

    APIGW->>Auth: Validate JWT
    Auth-->>APIGW: Valid (role=Operator)

    APIGW->>Lambda: Invoke handler

    Lambda->>Validator: Validate request body
    Validator-->>Lambda: Valid

    Lambda->>Service: createTenant(request)

    Service->>DAO: getByOrgName(name)
    DAO->>DDB: Query GSI1 (ORG#name)
    DDB-->>DAO: Not found
    DAO-->>Service: None

    Service->>Service: Generate tenantId (UUID)

    Service->>DAO: create(tenant)
    DAO->>DDB: PutItem (PK=TENANT#id, SK=METADATA)
    DDB-->>DAO: Success
    DAO-->>Service: Tenant

    Service->>Audit: logEvent(TENANT_CREATED)
    Audit->>DDB: PutItem (SK=EVENT#timestamp)

    Service->>EB: publish(TENANT_CREATED, tenant)
    EB-->>Service: Published

    Service-->>Lambda: TenantResponse
    Lambda-->>APIGW: 201 Created + body
    APIGW-->>Client: Response with tenantId and HATEOAS links
```

### 3.2 Site Creation (Async) Flow - API to SQS to WordPress

```mermaid
sequenceDiagram
    participant Client
    participant APIGW as API Gateway
    participant Lambda as Site Create Lambda
    participant DDB as DynamoDB
    participant SQS as Site Creation Queue
    participant Consumer as SQS Consumer Lambda
    participant Secrets as Secrets Manager
    participant ALB as Internal ALB
    participant WP as WordPress ECS
    participant SNS as SNS
    participant DLQ as Dead Letter Queue

    %% API Phase
    rect rgb(230, 245, 255)
        Note over Client,SQS: Phase 1: API Request (Synchronous)
        Client->>APIGW: POST /v1.0/tenants/{id}/sites
        Note over APIGW: {siteName, subdomain, templateId}

        APIGW->>Lambda: Invoke handler
        Lambda->>Lambda: Validate request
        Lambda->>Lambda: Check site quota
        Lambda->>Lambda: Validate subdomain unique

        Lambda->>DDB: Create site (status=PROVISIONING)
        DDB-->>Lambda: Site created

        Lambda->>SQS: SendMessage(SiteCreationRequest)
        SQS-->>Lambda: MessageId

        Lambda-->>APIGW: 202 Accepted
        APIGW-->>Client: {siteId, status: PROVISIONING}
    end

    %% Async Phase
    rect rgb(255, 245, 230)
        Note over SQS,WP: Phase 2: Async Processing
        SQS->>Consumer: Receive message

        Consumer->>Secrets: Get WP Application Password
        Secrets-->>Consumer: Credentials

        Consumer->>ALB: POST /wp-json/wp/v2/sites
        Note over ALB: X-Tenant-Id header
        ALB->>WP: Route to tenant container
        WP-->>ALB: Site created (wp_site_id)
        ALB-->>Consumer: 201 Created

        opt Template Specified
            Consumer->>ALB: Install theme
            Consumer->>ALB: Import content
            Consumer->>ALB: Install plugins
        end

        Consumer->>DDB: Update status=ACTIVE
        DDB-->>Consumer: Updated

        Consumer->>SNS: Publish(SiteCreationComplete)
        SNS-->>Consumer: Published

        Consumer->>SQS: DeleteMessage
    end

    %% Error Handling
    rect rgb(255, 230, 230)
        Note over SQS,DLQ: Error Handling
        alt Processing Failure
            Consumer->>DDB: Update status=FAILED
            Consumer->>SNS: Publish(SiteCreationFailed)
            SQS->>DLQ: Move after 3 retries
        end
    end
```

### 3.3 Instance Provisioning (GitOps) Flow

```mermaid
sequenceDiagram
    participant Client
    participant APIGW as API Gateway
    participant Lambda as Instance Create Lambda
    participant DDB as DynamoDB
    participant TF as TF_Helper
    participant Git as Git_Helper
    participant GitHub as GitHub Repo
    participant GHA as GitHub Actions
    participant TFApply as Terraform Apply
    participant ECS as ECS Cluster
    participant EB as EventBridge
    participant StateHandler as State Sync Lambda

    %% API Phase
    rect rgb(230, 245, 255)
        Note over Client,DDB: Phase 1: API Request
        Client->>APIGW: POST /v1.0/tenants/{id}/instances
        Note over APIGW: {organizationName, contactEmail, tier}

        APIGW->>Lambda: Invoke handler
        Lambda->>Lambda: Validate request

        Lambda->>DDB: Create instance (state=PENDING_PROVISIONING)
        DDB-->>Lambda: Instance created

        Lambda-->>APIGW: 202 Accepted
        APIGW-->>Client: {instanceId, status: PENDING_PROVISIONING}
    end

    %% GitOps Phase
    rect rgb(245, 255, 230)
        Note over Lambda,GitHub: Phase 2: GitOps - File Generation
        Lambda->>DDB: Update state=COMMITTING

        Lambda->>TF: generateTenantConfig(tenantId, config)
        TF-->>Lambda: main.tf content

        Lambda->>TF: generateVariables(tenantId)
        TF-->>Lambda: variables.tf content

        Lambda->>TF: generateTfvars(tenantId, config)
        TF-->>Lambda: terraform.tfvars content

        Lambda->>Git: cloneRepo()
        Git-->>Lambda: Workspace path

        Lambda->>Git: addFiles([main.tf, variables.tf, tfvars])
        Lambda->>Git: commit("Add tenant {tenantId}")
        Lambda->>Git: push()
        Git-->>Lambda: Commit SHA

        Lambda->>DDB: Update state=WORKFLOW_QUEUED, commitSha
    end

    %% GitHub Actions Phase
    rect rgb(255, 245, 230)
        Note over Lambda,TFApply: Phase 3: Terraform Execution
        Lambda->>GHA: triggerWorkflow(deploy-tenant-{id}.yml, action=apply)
        GHA-->>Lambda: workflowRunId

        Lambda->>DDB: Update workflowRunId, state=WORKFLOW_RUNNING
        Lambda-->>Client: Async completion

        GHA->>TFApply: terraform init
        GHA->>TFApply: terraform plan
        GHA->>TFApply: terraform apply -auto-approve

        TFApply->>ECS: Create ECS Service (tagged)
        Note over ECS: Tags: bbws:tenant-id, bbws:environment
        TFApply->>ECS: Create Target Group
        TFApply->>ECS: Create Listener Rule
        TFApply->>ECS: Create EFS Access Point
    end

    %% Event-Driven State Sync
    rect rgb(255, 230, 245)
        Note over ECS,DDB: Phase 4: Event-Driven State Sync
        ECS->>EB: Emit SERVICE_STEADY_STATE
        Note over EB: Event includes service tags

        EB->>StateHandler: Route event

        StateHandler->>StateHandler: Extract bbws:tenant-id from tags
        StateHandler->>StateHandler: Map event to status

        StateHandler->>DDB: Update state=ACTIVE
        DDB-->>StateHandler: Updated
    end
```

### 3.4 Event-Driven State Synchronization

```mermaid
sequenceDiagram
    participant ECS as ECS Service
    participant EB as EventBridge
    participant Rule as EB Rule
    participant Handler as State Sync Lambda
    participant DDB as DynamoDB
    participant CW as CloudWatch

    ECS->>EB: ECS Service Action Event
    Note over EB: detail-type: ECS Service Action<br/>eventName: SERVICE_STEADY_STATE

    EB->>Rule: Match pattern
    Note over Rule: source: aws.ecs<br/>clusterArn: bbws-cluster-{env}

    Rule->>Handler: Invoke with event

    Handler->>Handler: Extract tags from event.detail.tags[]

    alt Tags contain bbws:tenant-id
        Handler->>Handler: tenantId = tags['bbws:tenant-id']
        Handler->>Handler: Validate bbws:environment matches

        Handler->>Handler: Map event to status
        Note over Handler: SERVICE_STEADY_STATE -> ACTIVE<br/>DEPLOYMENT_FAILED -> FAILED<br/>SERVICE_DESIRED_COUNT_UPDATED -> SCALING

        Handler->>DDB: UpdateItem
        Note over DDB: PK=TENANT#{tenantId}<br/>SK=INSTANCE<br/>provisioningState={status}

        DDB-->>Handler: Success

        Handler->>CW: Log success

    else No bbws:tenant-id tag
        Handler->>CW: Log "Ignoring: not a managed tenant"
    end
```

---

## 4. Data Flow Diagram

### 4.1 DynamoDB Single-Table Design - Access Patterns

```mermaid
graph TB
    subgraph "DynamoDB Table: bbws-tenants"
        subgraph "Primary Key Structure"
            PK["PK (Partition Key)"]
            SK["SK (Sort Key)"]
        end

        subgraph "Entity Patterns"
            E1["TENANT#{tenantId} | METADATA<br/>Tenant core data"]
            E2["TENANT#{tenantId} | USER#{userId}<br/>User assignments"]
            E3["TENANT#{tenantId} | HIERARCHY#{div}#{grp}#{team}<br/>Org structure"]
            E4["TENANT#{tenantId} | EVENT#{timestamp}#{id}<br/>Audit trail"]
        end

        subgraph "GSI1: Organization & User Lookups"
            GSI1PK["GSI1PK"]
            GSI1SK["GSI1SK"]
            G1A["ORG#{organizationName} | TENANT#{tenantId}<br/>Lookup tenant by org name"]
            G1B["USER#{userId} | TENANT#{tenantId}<br/>Find user's tenants"]
        end

        subgraph "GSI2: Status & Environment Queries"
            GSI2PK["GSI2PK"]
            GSI2SK["GSI2SK"]
            G2A["STATUS#{status} | {updatedAt}#{tenantId}<br/>Filter by status, sorted by time"]
            G2B["ENV#{environment} | {createdAt}#{tenantId}<br/>Filter by environment"]
        end
    end

    subgraph "Access Pattern Examples"
        AP1["1. Get tenant by ID<br/>PK=TENANT#{id}, SK=METADATA"]
        AP2["2. Get tenant by org name<br/>GSI1: GSI1PK=ORG#{name}"]
        AP3["3. List tenants by status<br/>GSI2: GSI2PK=STATUS#{status}"]
        AP4["4. Get user's tenants<br/>GSI1: GSI1PK=USER#{userId}"]
        AP5["5. List users in tenant<br/>PK=TENANT#{id}, SK begins_with USER#"]
        AP6["6. Get tenant audit events<br/>PK=TENANT#{id}, SK begins_with EVENT#"]
    end
```

### 4.2 Sites Table Access Patterns

```mermaid
graph TB
    subgraph "DynamoDB Table: sites"
        subgraph "Entity Patterns"
            S1["TENANT#{tenantId} | SITE#{siteId}<br/>Site metadata"]
            S2["TEMPLATE | TEMPLATE#{templateId}<br/>Template catalog"]
            S3["PLUGIN | PLUGIN#{pluginId}<br/>Plugin marketplace"]
            S4["SITE#{siteId} | PLUGIN#{pluginId}<br/>Installed plugins"]
            S5["SITE#{siteId} | BACKUP#{backupId}<br/>Backup records"]
            S6["TENANT#{tenantId} | OP#{operationId}<br/>Async operations"]
        end

        subgraph "GSI Structure"
            G1["GSI1: OPERATION#{opId}<br/>Direct operation lookup"]
            G2["GSI2: TENANT#{id}#STATUS | {status}#{createdAt}<br/>Operations by status"]
            G3["GSI3: STATUS#{status} | {updatedAt}#{siteId}<br/>Sites by status"]
            G4["GSI4: SUBDOMAIN#{subdomain} | SITE#{siteId}<br/>Subdomain uniqueness"]
            G5["GSI5: ENV#{environment} | {createdAt}#{siteId}<br/>Sites by environment"]
        end
    end

    subgraph "Access Patterns"
        AP1["1. List sites for tenant<br/>PK=TENANT#{id}, SK begins_with SITE#"]
        AP2["2. Check subdomain exists<br/>GSI4: GSI4PK=SUBDOMAIN#{subdomain}"]
        AP3["3. List sites by status<br/>GSI3: GSI3PK=STATUS#{status}"]
        AP4["4. Get operation status<br/>GSI1: GSI1PK=OPERATION#{opId}"]
        AP5["5. List installed plugins<br/>PK=SITE#{id}, SK begins_with PLUGIN#"]
    end
```

### 4.3 Instance Resources Table Access Patterns

```mermaid
graph TB
    subgraph "DynamoDB Table: tenant-resources"
        subgraph "Entity Patterns"
            I1["TENANT#{tenantId} | INSTANCE<br/>Instance metadata & state"]
            I2["TENANT#{tenantId}#INSTANCE | RESOURCE#{type}<br/>AWS resource ARNs"]
        end

        subgraph "Instance Attributes"
            A1["provisioningState: ACTIVE/SUSPENDED/FAILED"]
            A2["ecsServiceArn: ECS service ARN"]
            A3["efsAccessPointId: EFS AP ID"]
            A4["albTargetGroupArn: ALB TG ARN"]
            A5["cognitoUserPoolId: Cognito pool ID"]
            A6["workflowRunId: GitHub Actions run ID"]
            A7["lastEcsEvent: Last event type"]
            A8["desiredCount: ECS task count"]
        end

        subgraph "GSI: State Queries"
            G1["GSI1: TENANT#{id}#STATE | {state}#{updatedAt}<br/>List by provisioning state"]
        end
    end

    subgraph "Access Patterns"
        AP1["1. Get instance by tenant<br/>PK=TENANT#{id}, SK=INSTANCE"]
        AP2["2. List instances by state<br/>GSI1: Query by state"]
        AP3["3. Get resource ARNs<br/>PK=TENANT#{id}#INSTANCE, SK begins_with RESOURCE#"]
    end
```

---

## 5. Event Flow Diagram

### 5.1 EventBridge Event Routing

```mermaid
graph TB
    subgraph "Event Sources"
        TenantLambda[Tenant Lambda<br/>TENANT_CREATED<br/>TENANT_PARKED<br/>TENANT_UNPARKED]
        SiteLambda[Site Management Lambda<br/>SITE_CREATED<br/>SITE_DELETED]
        ECS[ECS Cluster<br/>SERVICE_STEADY_STATE<br/>DEPLOYMENT_FAILED<br/>TASK_STATE_CHANGE]
        PayFast[PayFast ITN<br/>ORDER_CREATED]
    end

    subgraph "EventBridge"
        EB[EventBridge<br/>bbws-events-{env}]

        subgraph "Rules"
            R1[tenant-lifecycle-rule<br/>source: bbws.tenant-management]
            R2[site-lifecycle-rule<br/>source: bbws.site-management]
            R3[ecs-state-sync-rule<br/>source: aws.ecs]
            R4[order-events-rule<br/>source: bbws.payment]
        end
    end

    subgraph "Event Targets"
        subgraph "Tenant Events"
            WPInstanceLambda[WP Instance Lambda<br/>Handle park/unpark]
        end

        subgraph "Site Events"
            NotifyLambda[Notification Lambda]
        end

        subgraph "ECS Events"
            StateSyncLambda[State Sync Lambda<br/>Update DynamoDB]
        end

        subgraph "Order Events (SNS Fan-Out)"
            SNSTopic[SNS Topic<br/>bbws-order-events]
            Q1[SQS: order-record]
            Q2[SQS: order-pdf]
            Q3[SQS: internal-notify]
            Q4[SQS: customer-notify]
            L1[OrderCreatorRecord]
            L2[OrderPDFCreator]
            L3[InternalNotificationSender]
            L4[CustomerConfirmationSender]
        end
    end

    subgraph "Data Stores"
        DDB[(DynamoDB)]
        S3[(S3 Bucket)]
        SES[SES Email]
    end

    %% Event flow
    TenantLambda --> EB
    SiteLambda --> EB
    ECS --> EB
    PayFast --> EB

    EB --> R1
    EB --> R2
    EB --> R3
    EB --> R4

    R1 --> WPInstanceLambda
    R2 --> NotifyLambda
    R3 --> StateSyncLambda
    R4 --> SNSTopic

    SNSTopic --> Q1
    SNSTopic --> Q2
    SNSTopic --> Q3
    SNSTopic --> Q4

    Q1 --> L1
    Q2 --> L2
    Q3 --> L3
    Q4 --> L4

    WPInstanceLambda --> DDB
    StateSyncLambda --> DDB
    L1 --> DDB
    L2 --> S3
    L3 --> SES
    L4 --> SES
```

### 5.2 ECS State Change Events

```mermaid
graph LR
    subgraph "ECS Cluster"
        Service[ECS Service<br/>tenant-{id}-wordpress]
        Task1[Task 1]
        Task2[Task 2]
    end

    subgraph "Events Emitted"
        E1[SERVICE_STEADY_STATE<br/>Service stabilized]
        E2[SERVICE_TASK_START_IMPAIRED<br/>Tasks failing]
        E3[SERVICE_DESIRED_COUNT_UPDATED<br/>Scale operation]
        E4[DEPLOYMENT_COMPLETED<br/>Deploy finished]
        E5[DEPLOYMENT_FAILED<br/>Deploy failed]
        E6[DEPLOYMENT_IN_PROGRESS<br/>Deploying]
        E7[TASK_STOPPED<br/>Task terminated]
        E8[TASK_RUNNING<br/>Task started]
    end

    subgraph "State Mapping"
        S1[ACTIVE]
        S2[FAILED]
        S3[SCALING]
        S4[PROVISIONING]
        S5[Log Only]
    end

    Service --> E1
    Service --> E2
    Service --> E3
    Service --> E4
    Service --> E5
    Service --> E6
    Task1 --> E7
    Task2 --> E8

    E1 --> S1
    E2 --> S2
    E3 --> S3
    E4 --> S1
    E5 --> S2
    E6 --> S4
    E7 --> S5
    E8 --> S5
```

### 5.3 Order Processing Event Flow (SNS Fan-Out)

```mermaid
graph TB
    subgraph "Payment Processing"
        ITN[PayFast ITN Handler]
    end

    subgraph "Event Distribution"
        SNS{{SNS Topic<br/>bbws-order-events}}
    end

    subgraph "Message Queues with DLQ"
        Q1[(order-record)]
        Q2[(order-pdf)]
        Q3[(internal-notify)]
        Q4[(customer-notify)]
        DLQ1[(order-record-dlq)]
        DLQ2[(order-pdf-dlq)]
        DLQ3[(internal-notify-dlq)]
        DLQ4[(customer-notify-dlq)]
    end

    subgraph "Lambda Functions"
        L1[OrderCreatorRecord<br/>Batch: 10<br/>Concurrency: 5]
        L2[OrderPDFCreator<br/>Batch: 5<br/>Concurrency: 10]
        L3[InternalNotificationSender<br/>Batch: 10<br/>Concurrency: 5]
        L4[CustomerConfirmationSender<br/>Batch: 10<br/>Concurrency: 5]
    end

    subgraph "Target Services"
        DB[(DynamoDB<br/>Orders Table)]
        S3[(S3 Bucket<br/>PDF Storage)]
        SES1[SES<br/>Internal Emails]
        SES2[SES<br/>Customer Emails]
    end

    ITN -->|Publish ORDER_CREATED| SNS
    SNS -->|Fan-Out| Q1
    SNS -->|Fan-Out| Q2
    SNS -->|Fan-Out| Q3
    SNS -->|Fan-Out| Q4

    Q1 -->|Trigger| L1
    Q2 -->|Trigger| L2
    Q3 -->|Trigger| L3
    Q4 -->|Trigger| L4

    Q1 -.->|After 3 failures| DLQ1
    Q2 -.->|After 3 failures| DLQ2
    Q3 -.->|After 3 failures| DLQ3
    Q4 -.->|After 3 failures| DLQ4

    L1 --> DB
    L2 --> S3
    L3 --> SES1
    L4 --> SES2

    style SNS fill:#FF9900,color:#000
    style Q1 fill:#FF4F8B,color:#fff
    style Q2 fill:#FF4F8B,color:#fff
    style Q3 fill:#FF4F8B,color:#fff
    style Q4 fill:#FF4F8B,color:#fff
```

---

## Appendix: Repository Mapping

| Repository | Service | Lambda Functions |
|------------|---------|------------------|
| `2_bbws_tenant_lambda` | Tenant Management | 8 functions (CRUD, park/unpark, status) |
| `2_bbws_wordpress_site_management_lambda` | Site Management | 11+ functions (sites, templates, plugins) |
| `2_bbws_tenants_instances_lambda` | Instance Management | 8 functions (CRUD, status, scale) |
| `2_bbws_tenants_event_handler` | Event Handler | 1 function (state sync) |
| `2_bbws_tenants_instances_dev` | GitOps - DEV | Terraform configs + GitHub Actions |
| `2_bbws_tenants_instances_sit` | GitOps - SIT | Terraform configs + GitHub Actions |
| `2_bbws_tenants_instances_prod` | GitOps - PROD | Terraform configs + GitHub Actions |

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-25 | Worker 6-8 | Initial version - All architecture diagrams |

---

**End of Document**
