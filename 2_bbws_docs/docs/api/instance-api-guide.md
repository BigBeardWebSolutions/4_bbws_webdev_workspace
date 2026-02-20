# Instance API Guide

**Version**: 1.0
**Last Updated**: 2026-01-25
**LLD Reference**: [2.7_LLD_WordPress_Instance_Management](../../LLDs/2.7_LLD_WordPress_Instance_Management.md)

---

## Overview

The Instance API manages WordPress infrastructure instances - the physical AWS resources (ECS, EFS, RDS, ALB, Cognito) that run WordPress sites. Each tenant has one instance that hosts their sites.

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Instance** | Complete WordPress environment (ECS Service + supporting resources) |
| **GitOps** | Infrastructure mutations use Terraform via GitHub Actions |
| **Direct Operations** | Status queries and scaling use direct ECS API |
| **State Sync** | ECS events automatically sync to DynamoDB via EventBridge |

---

## Base URL

```
https://api-{env}.bigbeardweb.solutions/v1.0/tenants/{tenantId}/instances
```

---

## Authentication

All endpoints require a valid JWT token:

```
Authorization: Bearer {access_token}
```

See [Authentication Guide](./authentication.md) for details.

---

## Operation Classification

Operations are classified by their execution mechanism:

| Operation | Method | Mechanism | Latency | Reversible |
|-----------|--------|-----------|---------|------------|
| List Instances | GET | Direct ECS API | ~200ms | N/A |
| Get Instance | GET | Direct ECS API | ~150ms | N/A |
| Get Status | GET | Direct ECS API | ~150ms | N/A |
| Create Instance | POST | GitOps (Terraform) | 2-5 min | Yes |
| Update Instance | PUT | GitOps (Terraform) | 2-3 min | Yes |
| Delete Instance | DELETE | GitOps (Terraform) | 2-3 min | Yes |
| Scale Instance | PUT /size | Direct ECS API | 5-30 sec | Yes |
| Stop/Start | PUT /status | Direct ECS API | 5-30 sec | Yes |

---

## GitOps Workflow

Infrastructure mutations (Create/Update/Delete) use a GitOps approach:

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│   API    │───>│  Lambda  │───>│   Git    │───>│  GitHub  │
│ Gateway  │    │          │    │  Commit  │    │ Actions  │
└──────────┘    └──────────┘    └──────────┘    └────┬─────┘
                                                     │
     202 Accepted + requestId                        │
     ┌──────────────────────────────────────────────┘
     │
     ▼
┌──────────┐    ┌──────────┐    ┌──────────┐
│Terraform │───>│   AWS    │───>│ Event    │───> DynamoDB
│  Apply   │    │ Resources│    │ Bridge   │    State Update
└──────────┘    └──────────┘    └──────────┘
```

### GitOps Benefits

1. **Audit Trail**: All changes tracked in Git history
2. **Reproducibility**: Infrastructure as code
3. **Rollback**: Easy revert via git revert
4. **Review**: Pull request workflow for changes

---

## Instance States

```
PENDING_PROVISIONING ────> COMMITTING ────> WORKFLOW_QUEUED
         │                                        │
         │                                        ▼
         │                               WORKFLOW_RUNNING ────> PROVISIONING
         │                                        │                  │
         │                                        ▼                  ▼
         │                               WORKFLOW_FAILED         ACTIVE
         │                                                          │
         ▼                                                          │
      FAILED                                                        │
                                    ┌───────────────────────────────┤
                                    │           │                   │
                                    ▼           ▼                   ▼
                               SUSPENDING   SCALING          DEPROVISIONING
                                    │           │                   │
                                    ▼           │                   ▼
                               SUSPENDED ───────┴────────> DEPROVISIONED
                                    │
                                    ▼
                               RESUMING ────────────────────> ACTIVE
```

| State | Description |
|-------|-------------|
| PENDING_PROVISIONING | Awaiting provisioning start |
| COMMITTING | Lambda committing Terraform files to Git |
| WORKFLOW_QUEUED | GitHub workflow queued |
| WORKFLOW_RUNNING | GitHub workflow executing |
| PROVISIONING | Terraform apply in progress |
| ACTIVE | Running normally |
| SCALING | Changing task count |
| SUSPENDING | Scaling to 0 |
| SUSPENDED | Scaled to 0, not running |
| RESUMING | Scaling back up |
| DEPROVISIONING | Terraform destroy in progress |
| DEPROVISIONED | All resources removed |
| FAILED | Error occurred |
| WORKFLOW_FAILED | GitHub workflow failed |

---

## API Endpoints

### Instance Operations

| Method | Path | Description | Mechanism |
|--------|------|-------------|-----------|
| GET | `/tenants/{tenantId}/instances` | List instances | Direct ECS |
| POST | `/tenants/{tenantId}/instances` | Create instance | GitOps |
| GET | `/tenants/{tenantId}/instances/{instanceId}` | Get instance | Direct ECS |
| PUT | `/tenants/{tenantId}/instances/{instanceId}` | Update instance | GitOps |
| DELETE | `/tenants/{tenantId}/instances/{instanceId}` | Delete instance | GitOps |

### Status Operations

| Method | Path | Description | Mechanism |
|--------|------|-------------|-----------|
| GET | `/tenants/{tenantId}/instances/{instanceId}/status` | Get status | Direct ECS |
| PUT | `/tenants/{tenantId}/instances/{instanceId}/status` | Stop/Start | Direct ECS |

### Size Operations

| Method | Path | Description | Mechanism |
|--------|------|-------------|-----------|
| PUT | `/tenants/{tenantId}/instances/{instanceId}/size` | Scale | Direct ECS |

---

## Endpoint Details

### Create Instance (GitOps)

Provisions all AWS resources for a new WordPress instance.

**Request:**

```http
POST /v1.0/tenants/tenant-123/instances
Authorization: Bearer {token}
Content-Type: application/json

{
  "organizationName": "Acme Corporation",
  "contactEmail": "admin@acme.com",
  "tier": "PROFESSIONAL",
  "configuration": {
    "desiredCount": 2,
    "wordpressVersion": "latest"
  }
}
```

**Request Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| organizationName | string | Yes | Organization display name |
| contactEmail | string | Yes | Admin contact email |
| tier | string | Yes | STANDARD, PROFESSIONAL, ENTERPRISE |
| configuration.desiredCount | integer | No | Initial ECS task count (default: 2) |
| configuration.wordpressVersion | string | No | WordPress version (default: latest) |
| opportunityId | string | No | ACE opportunity ID for cost tracking |

**Response (202 Accepted):**

```json
{
  "requestId": "req-550e8400-e29b-41d4-a716-446655440000",
  "instanceId": "inst-123e4567",
  "tenantId": "tenant-123",
  "status": "PENDING_PROVISIONING",
  "message": "Instance provisioning initiated via GitOps workflow",
  "estimatedCompletionMinutes": 5,
  "workflowUrl": "https://github.com/org/2_bbws_tenants_instances_dev/actions/runs/12345",
  "_links": {
    "self": { "href": "/v1.0/tenants/tenant-123/instances/inst-123e4567" },
    "status": { "href": "/v1.0/tenants/tenant-123/instances/inst-123e4567/status" },
    "collection": { "href": "/v1.0/tenants/tenant-123/instances" }
  }
}
```

---

### Get Instance Status

Returns current instance status from ECS.

**Request:**

```http
GET /v1.0/tenants/tenant-123/instances/inst-123e4567/status
Authorization: Bearer {token}
```

**Response (200 OK):**

```json
{
  "instanceId": "inst-123e4567",
  "tenantId": "tenant-123",
  "status": "ACTIVE",
  "desiredCount": 2,
  "runningCount": 2,
  "pendingCount": 0,
  "deploymentStatus": "COMPLETED",
  "healthStatus": "HEALTHY",
  "tasks": [
    {
      "taskId": "task-abc123",
      "status": "RUNNING",
      "healthStatus": "HEALTHY",
      "startedAt": "2026-01-25T10:30:00Z",
      "cpu": "512",
      "memory": "1024"
    },
    {
      "taskId": "task-def456",
      "status": "RUNNING",
      "healthStatus": "HEALTHY",
      "startedAt": "2026-01-25T10:30:05Z",
      "cpu": "512",
      "memory": "1024"
    }
  ],
  "lastUpdated": "2026-01-25T14:30:00Z",
  "_links": {
    "instance": { "href": "/v1.0/tenants/tenant-123/instances/inst-123e4567" },
    "scale": { "href": "/v1.0/tenants/tenant-123/instances/inst-123e4567/size" },
    "stop": { "href": "/v1.0/tenants/tenant-123/instances/inst-123e4567/status" }
  }
}
```

---

### Scale Instance

Scales the ECS service task count.

**Request:**

```http
PUT /v1.0/tenants/tenant-123/instances/inst-123e4567/size
Authorization: Bearer {token}
Content-Type: application/json

{
  "desiredCount": 4
}
```

**Request Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| desiredCount | integer | Yes | Target task count (2-10) |

**Response (200 OK):**

```json
{
  "instanceId": "inst-123e4567",
  "status": "SCALING",
  "previousCount": 2,
  "desiredCount": 4,
  "message": "Scale operation initiated. Tasks will stabilize within 5 minutes.",
  "_links": {
    "status": { "href": "/v1.0/tenants/tenant-123/instances/inst-123e4567/status" }
  }
}
```

---

### Stop/Start Instance

Suspends or resumes an instance by scaling to 0 or restoring previous count.

**Stop Request:**

```http
PUT /v1.0/tenants/tenant-123/instances/inst-123e4567/status
Authorization: Bearer {token}
Content-Type: application/json

{
  "action": "stop"
}
```

**Response (200 OK):**

```json
{
  "instanceId": "inst-123e4567",
  "status": "SUSPENDING",
  "action": "stop",
  "message": "Instance is being suspended. Tasks will drain within 2 minutes.",
  "_links": {
    "status": { "href": "/v1.0/tenants/tenant-123/instances/inst-123e4567/status" },
    "start": { "href": "/v1.0/tenants/tenant-123/instances/inst-123e4567/status" }
  }
}
```

**Start Request:**

```http
PUT /v1.0/tenants/tenant-123/instances/inst-123e4567/status
Authorization: Bearer {token}
Content-Type: application/json

{
  "action": "start"
}
```

**Response (200 OK):**

```json
{
  "instanceId": "inst-123e4567",
  "status": "RESUMING",
  "action": "start",
  "desiredCount": 2,
  "message": "Instance is being resumed. Full functionality within 5 minutes.",
  "_links": {
    "status": { "href": "/v1.0/tenants/tenant-123/instances/inst-123e4567/status" }
  }
}
```

---

### Delete Instance (GitOps)

Deprovisions all AWS resources for an instance.

**Request:**

```http
DELETE /v1.0/tenants/tenant-123/instances/inst-123e4567
Authorization: Bearer {token}
```

**Response (202 Accepted):**

```json
{
  "requestId": "req-delete-12345",
  "instanceId": "inst-123e4567",
  "status": "PENDING_DEPROVISIONING",
  "message": "Instance deprovisioning initiated via GitOps workflow",
  "workflowUrl": "https://github.com/org/2_bbws_tenants_instances_dev/actions/runs/67890",
  "dataRetentionDays": 30,
  "_links": {
    "status": { "href": "/v1.0/tenants/tenant-123/instances/inst-123e4567/status" }
  }
}
```

---

### Get Instance Details

Returns full instance configuration and resource ARNs.

**Request:**

```http
GET /v1.0/tenants/tenant-123/instances/inst-123e4567
Authorization: Bearer {token}
```

**Response (200 OK):**

```json
{
  "instanceId": "inst-123e4567",
  "tenantId": "tenant-123",
  "organizationName": "Acme Corporation",
  "provisioningState": "ACTIVE",
  "tier": "PROFESSIONAL",
  "configuration": {
    "desiredCount": 2,
    "wordpressVersion": "6.4.2",
    "phpVersion": "8.2"
  },
  "resources": {
    "ecsServiceArn": "arn:aws:ecs:af-south-1:536580886816:service/bbws-cluster-dev/tenant-123-wordpress",
    "ecsTaskDefinitionArn": "arn:aws:ecs:af-south-1:536580886816:task-definition/tenant-123-wordpress:5",
    "efsAccessPointId": "fsap-0abc123def456789",
    "efsAccessPointArn": "arn:aws:elasticfilesystem:af-south-1:536580886816:access-point/fsap-0abc123def456789",
    "albTargetGroupArn": "arn:aws:elasticloadbalancing:af-south-1:536580886816:targetgroup/tenant-123-tg/abc123",
    "albListenerRuleArn": "arn:aws:elasticloadbalancing:af-south-1:536580886816:listener-rule/app/bbws-alb-dev/abc/123/456",
    "cognitoUserPoolId": "af-south-1_abc123",
    "cognitoAppClientId": "abc123def456"
  },
  "domain": "tenant-123.bigbeardweb.solutions",
  "endpoint": "https://tenant-123.bigbeardweb.solutions",
  "gitOps": {
    "repository": "2_bbws_tenants_instances_dev",
    "lastCommitSha": "abc123def456789",
    "terraformStateKey": "tenants/tenant-123/terraform.tfstate",
    "lastWorkflowRunId": "12345678"
  },
  "tags": {
    "bbws:tenant-id": "tenant-123",
    "bbws:project": "BBWS-Phase-2.1-ECS",
    "bbws:cost-center": "BBWS-AWS",
    "bbws:environment": "dev",
    "bbws:component": "wordpress"
  },
  "createdAt": "2026-01-20T10:00:00Z",
  "updatedAt": "2026-01-25T14:30:00Z",
  "_links": {
    "self": { "href": "/v1.0/tenants/tenant-123/instances/inst-123e4567" },
    "tenant": { "href": "/v1.0/tenants/tenant-123" },
    "status": { "href": "/v1.0/tenants/tenant-123/instances/inst-123e4567/status" },
    "size": { "href": "/v1.0/tenants/tenant-123/instances/inst-123e4567/size" },
    "logs": { "href": "/v1.0/tenants/tenant-123/instances/inst-123e4567/logs" }
  }
}
```

---

## Status Monitoring

### Python Example

```python
import requests
import time
from typing import Optional

class InstanceManager:
    """Manage WordPress instances via BBWS API."""

    def __init__(self, base_url: str, token: str):
        self.base_url = base_url.rstrip("/")
        self.headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }

    def create_instance(
        self,
        tenant_id: str,
        organization_name: str,
        contact_email: str,
        tier: str = "PROFESSIONAL",
        desired_count: int = 2
    ) -> dict:
        """Create a new instance via GitOps workflow."""
        response = requests.post(
            f"{self.base_url}/tenants/{tenant_id}/instances",
            headers=self.headers,
            json={
                "organizationName": organization_name,
                "contactEmail": contact_email,
                "tier": tier,
                "configuration": {
                    "desiredCount": desired_count
                }
            }
        )
        response.raise_for_status()
        return response.json()

    def wait_for_active(
        self,
        tenant_id: str,
        instance_id: str,
        timeout_seconds: int = 600,
        poll_interval: int = 30
    ) -> dict:
        """Wait for instance to reach ACTIVE state."""
        start_time = time.time()

        while True:
            elapsed = time.time() - start_time
            if elapsed > timeout_seconds:
                raise TimeoutError(f"Instance did not become active within {timeout_seconds}s")

            status = self.get_status(tenant_id, instance_id)
            state = status.get("status") or status.get("provisioningState")

            print(f"Instance state: {state}")

            if state == "ACTIVE":
                return status

            if state in ["FAILED", "WORKFLOW_FAILED"]:
                raise Exception(f"Instance provisioning failed: {state}")

            time.sleep(poll_interval)

    def get_status(self, tenant_id: str, instance_id: str) -> dict:
        """Get current instance status."""
        response = requests.get(
            f"{self.base_url}/tenants/{tenant_id}/instances/{instance_id}/status",
            headers=self.headers
        )
        response.raise_for_status()
        return response.json()

    def scale(self, tenant_id: str, instance_id: str, desired_count: int) -> dict:
        """Scale instance to specified task count."""
        if not 2 <= desired_count <= 10:
            raise ValueError("desiredCount must be between 2 and 10")

        response = requests.put(
            f"{self.base_url}/tenants/{tenant_id}/instances/{instance_id}/size",
            headers=self.headers,
            json={"desiredCount": desired_count}
        )
        response.raise_for_status()
        return response.json()

    def stop(self, tenant_id: str, instance_id: str) -> dict:
        """Stop (suspend) an instance."""
        response = requests.put(
            f"{self.base_url}/tenants/{tenant_id}/instances/{instance_id}/status",
            headers=self.headers,
            json={"action": "stop"}
        )
        response.raise_for_status()
        return response.json()

    def start(self, tenant_id: str, instance_id: str) -> dict:
        """Start (resume) an instance."""
        response = requests.put(
            f"{self.base_url}/tenants/{tenant_id}/instances/{instance_id}/status",
            headers=self.headers,
            json={"action": "start"}
        )
        response.raise_for_status()
        return response.json()


# Usage Example
if __name__ == "__main__":
    manager = InstanceManager(
        base_url="https://api-dev.bigbeardweb.solutions/v1.0",
        token="your-access-token"
    )

    # Create instance
    result = manager.create_instance(
        tenant_id="tenant-123",
        organization_name="Acme Corp",
        contact_email="admin@acme.com",
        tier="PROFESSIONAL"
    )
    instance_id = result["instanceId"]
    print(f"Created instance: {instance_id}")
    print(f"Workflow: {result.get('workflowUrl')}")

    # Wait for provisioning
    status = manager.wait_for_active("tenant-123", instance_id)
    print(f"Instance is active with {status['runningCount']} tasks")

    # Scale up for high traffic
    scale_result = manager.scale("tenant-123", instance_id, desired_count=4)
    print(f"Scaling to {scale_result['desiredCount']} tasks")

    # Stop instance (cost savings)
    stop_result = manager.stop("tenant-123", instance_id)
    print(f"Instance stopping: {stop_result['status']}")
```

### JavaScript Example

```typescript
interface InstanceCreationResult {
  requestId: string;
  instanceId: string;
  status: string;
  workflowUrl?: string;
}

interface InstanceStatus {
  instanceId: string;
  status: string;
  desiredCount: number;
  runningCount: number;
}

class InstanceManager {
  private baseUrl: string;
  private headers: HeadersInit;

  constructor(baseUrl: string, token: string) {
    this.baseUrl = baseUrl.replace(/\/$/, '');
    this.headers = {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    };
  }

  async createInstance(
    tenantId: string,
    organizationName: string,
    contactEmail: string,
    tier: string = 'PROFESSIONAL',
    desiredCount: number = 2
  ): Promise<InstanceCreationResult> {
    const response = await fetch(`${this.baseUrl}/tenants/${tenantId}/instances`, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify({
        organizationName,
        contactEmail,
        tier,
        configuration: { desiredCount }
      })
    });

    if (!response.ok) {
      throw new Error(`Failed to create instance: ${response.status}`);
    }

    return response.json();
  }

  async getStatus(tenantId: string, instanceId: string): Promise<InstanceStatus> {
    const response = await fetch(
      `${this.baseUrl}/tenants/${tenantId}/instances/${instanceId}/status`,
      { headers: this.headers }
    );

    if (!response.ok) {
      throw new Error(`Failed to get status: ${response.status}`);
    }

    return response.json();
  }

  async waitForActive(
    tenantId: string,
    instanceId: string,
    timeoutSeconds: number = 600,
    pollIntervalMs: number = 30000
  ): Promise<InstanceStatus> {
    const startTime = Date.now();

    while (true) {
      const elapsed = (Date.now() - startTime) / 1000;
      if (elapsed > timeoutSeconds) {
        throw new Error(`Instance did not become active within ${timeoutSeconds}s`);
      }

      const status = await this.getStatus(tenantId, instanceId);
      console.log(`Instance state: ${status.status}`);

      if (status.status === 'ACTIVE') {
        return status;
      }

      if (['FAILED', 'WORKFLOW_FAILED'].includes(status.status)) {
        throw new Error(`Instance provisioning failed: ${status.status}`);
      }

      await new Promise(resolve => setTimeout(resolve, pollIntervalMs));
    }
  }

  async scale(tenantId: string, instanceId: string, desiredCount: number): Promise<Record<string, unknown>> {
    if (desiredCount < 2 || desiredCount > 10) {
      throw new Error('desiredCount must be between 2 and 10');
    }

    const response = await fetch(
      `${this.baseUrl}/tenants/${tenantId}/instances/${instanceId}/size`,
      {
        method: 'PUT',
        headers: this.headers,
        body: JSON.stringify({ desiredCount })
      }
    );

    if (!response.ok) {
      throw new Error(`Failed to scale: ${response.status}`);
    }

    return response.json();
  }

  async stop(tenantId: string, instanceId: string): Promise<Record<string, unknown>> {
    const response = await fetch(
      `${this.baseUrl}/tenants/${tenantId}/instances/${instanceId}/status`,
      {
        method: 'PUT',
        headers: this.headers,
        body: JSON.stringify({ action: 'stop' })
      }
    );

    if (!response.ok) {
      throw new Error(`Failed to stop: ${response.status}`);
    }

    return response.json();
  }

  async start(tenantId: string, instanceId: string): Promise<Record<string, unknown>> {
    const response = await fetch(
      `${this.baseUrl}/tenants/${tenantId}/instances/${instanceId}/status`,
      {
        method: 'PUT',
        headers: this.headers,
        body: JSON.stringify({ action: 'start' })
      }
    );

    if (!response.ok) {
      throw new Error(`Failed to start: ${response.status}`);
    }

    return response.json();
  }
}

// Usage
async function main() {
  const manager = new InstanceManager(
    'https://api-dev.bigbeardweb.solutions/v1.0',
    'your-access-token'
  );

  // Create instance
  const result = await manager.createInstance(
    'tenant-123',
    'Acme Corp',
    'admin@acme.com',
    'PROFESSIONAL'
  );
  console.log(`Created instance: ${result.instanceId}`);
  console.log(`Workflow: ${result.workflowUrl}`);

  // Wait for provisioning
  const status = await manager.waitForActive('tenant-123', result.instanceId);
  console.log(`Instance active with ${status.runningCount} tasks`);

  // Scale up
  await manager.scale('tenant-123', result.instanceId, 4);
  console.log('Scaling to 4 tasks');
}

main().catch(console.error);
```

---

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| VALIDATION_ERROR | 400 | Request validation failed |
| UNAUTHORIZED | 401 | Invalid or missing token |
| FORBIDDEN | 403 | Insufficient permissions |
| INSTANCE_NOT_FOUND | 404 | Instance does not exist |
| INVALID_STATUS_TRANSITION | 422 | Invalid state change |
| SCALE_LIMIT_EXCEEDED | 422 | Task count out of range (2-10) |
| GIT_COMMIT_FAILED | 500 | Failed to commit to Git |
| WORKFLOW_TRIGGER_FAILED | 500 | Failed to trigger GitHub workflow |
| TERRAFORM_APPLY_FAILED | 500 | Terraform apply failed |

---

## Related Documentation

- [Getting Started](./getting-started.md)
- [Authentication](./authentication.md)
- [Tenant API Guide](./tenant-api-guide.md)
- [Site API Guide](./site-api-guide.md)
- [Error Handling](./error-handling.md)

---

**End of Document**
