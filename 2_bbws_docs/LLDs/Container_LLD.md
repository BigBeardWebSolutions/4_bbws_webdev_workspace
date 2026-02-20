# Container Management - Low-Level Design

**Version**: 1.0
**Author**: Agentic Architect
**Date**: 2025-12-13
**Status**: Draft for Review
**Parent HLD**: [BBWS ECS WordPress HLD](../BBWS_ECS_WordPress_HLD.md)

---

## Document History

| Version | Date | Changes | Owner |
|---------|------|---------|-------|
| 1.0 | 2025-12-13 | Initial LLD for ECS Fargate container management | Agentic Architect |

---

## 1. Introduction

### 1.1 Purpose

This LLD provides implementation details for ECS Fargate cluster management, task definitions, container services, and ECR image registry for multi-tenant WordPress hosting.

### 1.2 Parent HLD Reference

Based on Section 4.3 (Layer 3: Compute) and User Stories US-002, US-012, US-013, US-025, US-026 from the [BBWS ECS WordPress HLD](../BBWS_ECS_WordPress_HLD.md).

### 1.3 Component Overview

Container Management provides:
- Shared ECS Fargate cluster for all tenants
- Per-tenant ECS services with auto-scaling
- WordPress task definitions with environment variables
- ECR repository for WordPress base images
- Service discovery integration
- Container health checks and monitoring

### 1.4 Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| Container Orchestration | AWS ECS Fargate | Serverless container hosting |
| Container Registry | Amazon ECR | WordPress image storage |
| Base Image | wordpress:latest | Official WordPress image |
| Task CPU | 512 (.5 vCPU) | Per-tenant task resources |
| Task Memory | 1024 MB (1 GB) | Per-tenant task resources |

---

## 2. High Level Epic Overview

| User Story ID | User Story | Test Scenario(s) |
|---------------|------------|------------------|
| US-002 | As a DevOps Engineer, I want to deploy a shared ECS Fargate cluster so that I can host multiple tenant containers | GIVEN AWS account WHEN terraform apply executes THEN ECS cluster created AND capacity provider configured |
| US-012 | As a Platform Operator, I want to provision WordPress for tenant so ECS service is deployed | GIVEN tenant-id WHEN provision executes THEN task definition created AND ECS service deployed AND 2 tasks running |
| US-025 | As a Platform Operator, I want to update WordPress core so sites have latest security patches | GIVEN new WordPress image WHEN update executes THEN ECR image pushed AND task definition updated AND rolling deployment starts |

---

## 3. Component Diagram

### 3.1 ECS Cluster Architecture

```mermaid
graph TB
    subgraph "ECS Cluster: bbws-cluster"
        subgraph "Service: tenant-1-wordpress"
            T1A["Task: tenant-1-task-1<br/>Container: wordpress<br/>CPU: 512, Mem: 1024<br/>AZ: af-south-1a"]
            T1B["Task: tenant-1-task-2<br/>Container: wordpress<br/>CPU: 512, Mem: 1024<br/>AZ: af-south-1b"]
        end

        subgraph "Service: tenant-2-wordpress"
            T2A["Task: tenant-2-task-1<br/>Container: wordpress<br/>CPU: 512, Mem: 1024<br/>AZ: af-south-1a"]
            T2B["Task: tenant-2-task-2<br/>Container: wordpress<br/>CPU: 512, Mem: 1024<br/>AZ: af-south-1b"]
        end
    end

    ECR["ECR Repository<br/>bbws-wordpress<br/>Image: latest"]
    ALB["Application Load Balancer"]
    RDS["RDS MySQL"]
    EFS["EFS Shared Filesystem"]
    Secrets["Secrets Manager"]

    ECR -.->|Pull Image| T1A
    ECR -.->|Pull Image| T1B
    ECR -.->|Pull Image| T2A
    ECR -.->|Pull Image| T2B

    ALB -->|/tenant-1/*| T1A
    ALB -->|/tenant-1/*| T1B
    ALB -->|/tenant-2/*| T2A
    ALB -->|/tenant-2/*| T2B

    T1A -->|MySQL| RDS
    T1B -->|MySQL| RDS
    T2A -->|MySQL| RDS
    T2B -->|MySQL| RDS

    T1A -->|NFS| EFS
    T1B -->|NFS| EFS
    T2A -->|NFS| EFS
    T2B -->|NFS| EFS

    T1A -.->|Get DB Creds| Secrets
    T1B -.->|Get DB Creds| Secrets
    T2A -.->|Get DB Creds| Secrets
    T2B -.->|Get DB Creds| Secrets
```

### 3.2 Class Diagram

```mermaid
classDiagram
    class ContainerService {
        -ECSClient ecsClient
        -ECRClient ecrClient
        -SecretsManagerClient secretsClient
        +ContainerService(ecsClient, ecrClient, secretsClient)
        +createCluster(clusterName String) Cluster
        +createTaskDefinition(config TaskDefConfig) TaskDefinition
        +createService(config ServiceConfig) Service
        +updateService(serviceName String, taskDefArn String) Service
        +scaleService(serviceName String, desiredCount int) void
        +deployNewImage(imageTag String) void
        -registerTaskDefinition(config TaskDefConfig) String
    }

    class Cluster {
        +String clusterName
        +String clusterArn
        +String status
        +List~String~ capacityProviders
        +ClusterSettings settings
    }

    class TaskDefinition {
        +String family
        +String taskRoleArn
        +String executionRoleArn
        +String networkMode
        +List~ContainerDefinition~ containers
        +String cpu
        +String memory
        +List~Volume~ volumes
        +RequiresCompatibilities requiresCompatibilities
    }

    class RequiresCompatibilities {
        <<enumeration>>
        EC2
        FARGATE
    }

    class ContainerDefinition {
        +String name
        +String image
        +int cpu
        +int memory
        +List~PortMapping~ portMappings
        +List~EnvironmentVariable~ environment
        +List~Secret~ secrets
        +List~MountPoint~ mountPoints
        +HealthCheck healthCheck
        +LogConfiguration logConfiguration
    }

    class PortMapping {
        +int containerPort
        +int hostPort
        +String protocol
    }

    class EnvironmentVariable {
        +String name
        +String value
    }

    class Secret {
        +String name
        +String valueFrom
    }

    class MountPoint {
        +String sourceVolume
        +String containerPath
        +Boolean readOnly
    }

    class Volume {
        +String name
        +EFSVolumeConfiguration efsVolumeConfiguration
    }

    class EFSVolumeConfiguration {
        +String fileSystemId
        +String rootDirectory
        +String transitEncryption
        +AuthorizationConfig authorizationConfig
    }

    class Service {
        +String serviceName
        +String serviceArn
        +String clusterArn
        +String taskDefinition
        +int desiredCount
        +String launchType
        +NetworkConfiguration networkConfiguration
        +List~LoadBalancer~ loadBalancers
        +ServiceRegistryConfig serviceRegistries
        +AutoScalingConfig autoScaling
    }

    class NetworkConfiguration {
        +AwsvpcConfiguration awsvpcConfiguration
    }

    class AwsvpcConfiguration {
        +List~String~ subnets
        +List~String~ securityGroups
        +String assignPublicIp
    }

    class LoadBalancer {
        +String targetGroupArn
        +String containerName
        +int containerPort
    }

    class HealthCheck {
        +List~String~ command
        +int interval
        +int timeout
        +int retries
        +int startPeriod
    }

    ContainerService --> Cluster : creates
    ContainerService --> TaskDefinition : creates
    ContainerService --> Service : creates
    TaskDefinition --> RequiresCompatibilities : specifies
    TaskDefinition "1" *-- "*" ContainerDefinition : contains
    TaskDefinition "1" *-- "*" Volume : contains
    ContainerDefinition "1" *-- "*" PortMapping : contains
    ContainerDefinition "1" *-- "*" EnvironmentVariable : contains
    ContainerDefinition "1" *-- "*" Secret : contains
    ContainerDefinition "1" *-- "*" MountPoint : contains
    ContainerDefinition --> HealthCheck : has
    Volume --> EFSVolumeConfiguration : uses
    Service --> NetworkConfiguration : has
    Service "1" *-- "*" LoadBalancer : contains
    NetworkConfiguration --> AwsvpcConfiguration : contains
```

---

## 4. Container Configuration Details

### 4.1 ECS Cluster Configuration

```json
{
  "clusterName": "bbws-cluster",
  "capacityProviders": ["FARGATE", "FARGATE_SPOT"],
  "defaultCapacityProviderStrategy": [
    {
      "capacityProvider": "FARGATE",
      "weight": 1,
      "base": 2
    },
    {
      "capacityProvider": "FARGATE_SPOT",
      "weight": 4,
      "base": 0
    }
  ],
  "settings": [
    {
      "name": "containerInsights",
      "value": "enabled"
    }
  ],
  "tags": [
    {"key": "bbws:component", "value": "ecs"},
    {"key": "bbws:environment", "value": "dev"}
  ]
}
```

### 4.2 Task Definition (Per-Tenant)

```json
{
  "family": "tenant-1-wordpress",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "taskRoleArn": "arn:aws:iam::536580886816:role/ecsTaskRole",
  "executionRoleArn": "arn:aws:iam::536580886816:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "wordpress",
      "image": "536580886816.dkr.ecr.af-south-1.amazonaws.com/bbws-wordpress:latest",
      "cpu": 512,
      "memory": 1024,
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {"name": "WORDPRESS_DB_HOST", "value": "bbws-db.cluster-xxx.af-south-1.rds.amazonaws.com"},
        {"name": "WORDPRESS_DB_NAME", "value": "tenant_1_db"},
        {"name": "WORDPRESS_TABLE_PREFIX", "value": "wp_"},
        {"name": "WORDPRESS_CONFIG_EXTRA", "value": "define('WP_HOME', 'https://banana.wpdev.kimmyai.io');\ndefine('WP_SITEURL', 'https://banana.wpdev.kimmyai.io');"}
      ],
      "secrets": [
        {
          "name": "WORDPRESS_DB_USER",
          "valueFrom": "arn:aws:secretsmanager:af-south-1:536580886816:secret:bbws/dev/tenant-1/db:username::"
        },
        {
          "name": "WORDPRESS_DB_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:af-south-1:536580886816:secret:bbws/dev/tenant-1/db:password::"
        }
      ],
      "mountPoints": [
        {
          "sourceVolume": "wp-content",
          "containerPath": "/var/www/html/wp-content",
          "readOnly": false
        }
      ],
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost/ || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      },
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/bbws-cluster",
          "awslogs-region": "af-south-1",
          "awslogs-stream-prefix": "tenant-1"
        }
      }
    }
  ],
  "volumes": [
    {
      "name": "wp-content",
      "efsVolumeConfiguration": {
        "fileSystemId": "fs-0123456789abcdef",
        "rootDirectory": "/",
        "transitEncryption": "ENABLED",
        "authorizationConfig": {
          "accessPointId": "fsap-tenant1-xxx",
          "iam": "ENABLED"
        }
      }
    }
  ],
  "tags": [
    {"key": "bbws:tenant-id", "value": "tenant-1"},
    {"key": "bbws:environment", "value": "dev"}
  ]
}
```

### 4.3 ECS Service Configuration

```json
{
  "serviceName": "tenant-1-wordpress",
  "cluster": "bbws-cluster",
  "taskDefinition": "tenant-1-wordpress:1",
  "desiredCount": 2,
  "launchType": "FARGATE",
  "platformVersion": "1.4.0",
  "networkConfiguration": {
    "awsvpcConfiguration": {
      "subnets": [
        "subnet-private-a-xxx",
        "subnet-private-b-xxx"
      ],
      "securityGroups": ["sg-ecs-xxx"],
      "assignPublicIp": "DISABLED"
    }
  },
  "loadBalancers": [
    {
      "targetGroupArn": "arn:aws:elasticloadbalancing:af-south-1:536580886816:targetgroup/tenant-1-tg/xxx",
      "containerName": "wordpress",
      "containerPort": 80
    }
  ],
  "healthCheckGracePeriodSeconds": 60,
  "deploymentConfiguration": {
    "maximumPercent": 200,
    "minimumHealthyPercent": 100,
    "deploymentCircuitBreaker": {
      "enable": true,
      "rollback": true
    }
  },
  "tags": [
    {"key": "bbws:tenant-id", "value": "tenant-1"},
    {"key": "bbws:environment", "value": "dev"}
  ]
}
```

### 4.4 Auto-Scaling Configuration

```json
{
  "ServiceNamespace": "ecs",
  "ResourceId": "service/bbws-cluster/tenant-1-wordpress",
  "ScalableDimension": "ecs:service:DesiredCount",
  "MinCapacity": 2,
  "MaxCapacity": 10,
  "TargetTrackingScalingPolicies": [
    {
      "PolicyName": "tenant-1-cpu-scaling",
      "TargetTrackingScalingPolicyConfiguration": {
        "PredefinedMetricSpecification": {
          "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
        },
        "TargetValue": 70.0,
        "ScaleInCooldown": 300,
        "ScaleOutCooldown": 60
      }
    },
    {
      "PolicyName": "tenant-1-memory-scaling",
      "TargetTrackingScalingPolicyConfiguration": {
        "PredefinedMetricSpecification": {
          "PredefinedMetricType": "ECSServiceAverageMemoryUtilization"
        },
        "TargetValue": 80.0,
        "ScaleInCooldown": 300,
        "ScaleOutCooldown": 60
      }
    }
  ]
}
```

---

## 5. Sequence Diagram

### 5.1 Deploy WordPress Container Sequence

```mermaid
sequenceDiagram
    participant Operator
    participant CLI
    participant ContainerService
    participant ECR
    participant ECS
    participant SecretsManager
    participant CloudWatch

    Operator->>CLI: deploy_wordpress_container --tenant-id tenant-1

    rect rgb(240, 240, 255)
        Note over ContainerService: try block - Container Deployment

        CLI->>ContainerService: createService(tenantId, config)

        ContainerService->>ECR: DescribeImages(repository="bbws-wordpress", tag="latest")
        ECR-->>ContainerService: imageDigest, imagePushedAt

        ContainerService->>SecretsManager: GetSecretValue(secretId="bbws/dev/tenant-1/db")
        SecretsManager-->>ContainerService: username, password

        ContainerService->>ContainerService: buildTaskDefinition(tenantId, imageDigest, dbHost, efsAccessPoint)

        ContainerService->>ECS: RegisterTaskDefinition(taskDef)
        ECS-->>ContainerService: taskDefinitionArn, revision

        ContainerService->>ECS: CreateService(serviceName="tenant-1-wordpress", taskDef, desiredCount=2)
        ECS-->>ContainerService: serviceArn

        ContainerService->>ECS: WaitForServiceStable(serviceName, timeout=600s)

        loop Check Service Status (every 15s)
            ECS->>ECS: DescribeServices(serviceName)
            ECS-->>ContainerService: runningCount, desiredCount

            alt runningCount == desiredCount
                ECS-->>ContainerService: Service stable
            end
        end

        ContainerService->>ECS: RegisterScalableTarget(service, min=2, max=10)
        ECS-->>ContainerService: scalableTargetArn

        ContainerService->>ECS: PutScalingPolicy(targetCPU=70%, targetMemory=80%)
        ECS-->>ContainerService: policyArn

        ContainerService->>CloudWatch: PutMetricAlarm(serviceName, CPUUtilization>90%)
        CloudWatch-->>ContainerService: alarmArn

        ContainerService-->>CLI: Service(serviceArn, taskDefArn, runningCount=2)
    end

    alt BusinessException
        Note over ContainerService: catch BusinessException
        ContainerService-->>CLI: 400 Bad Request (InvalidImageException)
        ContainerService-->>CLI: 409 Conflict (ServiceAlreadyExistsException)
    end

    alt UnexpectedException
        Note over ContainerService: catch UnexpectedException
        ContainerService->>ContainerService: logger.error(exception)
        ContainerService->>ECS: DeleteService(serviceName, force=true)
        ContainerService-->>CLI: 500 Internal Server Error (ECSException)
        ContainerService-->>CLI: 504 Gateway Timeout (ServiceStableTimeoutException)
    end

    CLI-->>Operator: WordPress container deployed: 2 tasks running
```

---

## 6. Non-Functional Requirements

### 6.1 Performance

| Metric | Target | Measurement |
|--------|--------|-------------|
| Container startup time | < 60 seconds | ECS task launch duration |
| Image pull time | < 30 seconds | ECR image download |
| Health check interval | 30 seconds | Container health status |
| Service stabilization | < 5 minutes | ECS service deployment |

### 6.2 Scalability

| Aspect | Configuration | Strategy |
|--------|---------------|----------|
| Min tasks per tenant | 2 | High availability across 2 AZs |
| Max tasks per tenant | 10 | Auto-scaling based on CPU/Memory |
| Cluster capacity | 100 tasks | Support 10 tenants × 10 tasks |
| Scale-out trigger | CPU > 70% or Memory > 80% | CloudWatch alarms |
| Scale-in cooldown | 300 seconds | Prevent flapping |

### 6.3 Cost

| Component | Monthly Cost (per tenant) | Notes |
|-----------|---------------------------|-------|
| Fargate vCPU | ~$14.77 | 0.5 vCPU × 2 tasks × $0.04856/hour × 730 hours |
| Fargate Memory | ~$3.25 | 1 GB × 2 tasks × $0.00532/GB-hour × 730 hours |
| ECR Storage | ~$0.50 | 5 GB shared across tenants |
| CloudWatch Logs | ~$2 | Log ingestion and storage |
| **Total Container Cost** | **~$21/tenant/month** | Base 2 tasks, scales with load |

---

## 7. Troubleshooting Playbook

### 7.1 Container Won't Start

**Symptom**: ECS tasks stuck in PENDING or immediately fail

**Diagnosis**:
```bash
# Check service events
aws ecs describe-services \
  --cluster bbws-cluster \
  --services tenant-1-wordpress \
  --profile Tebogo-dev

# Check task stopped reason
aws ecs describe-tasks \
  --cluster bbws-cluster \
  --tasks <task-id> \
  --profile Tebogo-dev

# Check CloudWatch logs
aws logs tail /ecs/bbws-cluster --follow --profile Tebogo-dev
```

**Resolution**:
- Image pull error: Verify ECR repository permissions
- Secret not found: Check Secrets Manager ARN
- Health check failing: Increase startPeriod to 120s
- EFS mount error: Verify EFS access point and IAM permissions

### 7.2 High CPU/Memory Usage

**Symptom**: Tasks consuming > 90% CPU or memory

**Diagnosis**:
```bash
# Check CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=tenant-1-wordpress \
  --start-time 2025-12-13T00:00:00Z \
  --end-time 2025-12-13T23:59:59Z \
  --period 300 \
  --statistics Average \
  --profile Tebogo-dev
```

**Resolution**:
- Increase task CPU/memory allocation
- Enable auto-scaling if not already enabled
- Optimize WordPress plugins and themes
- Enable PHP OpCache in container

---

## 8. References

| Ref ID | Document | Type |
|--------|----------|------|
| REF-CON-001 | [BBWS ECS WordPress HLD](../BBWS_ECS_WordPress_HLD.md) | Parent HLD |
| REF-CON-002 | [ECS Fargate User Guide](https://docs.aws.amazon.com/AmazonECS/latest/userguide/what-is-fargate.html) | AWS Documentation |
| REF-CON-003 | [ECR User Guide](https://docs.aws.amazon.com/AmazonECR/latest/userguide/) | AWS Documentation |

---

**END OF DOCUMENT**
