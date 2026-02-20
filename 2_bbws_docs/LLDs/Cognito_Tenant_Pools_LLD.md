# Cognito Tenant Pools - Low-Level Design

**Version**: 1.0
**Author**: Agentic Architect
**Date**: 2025-12-13
**Status**: Draft for Review
**Parent HLD**: [BBWS ECS WordPress HLD](../BBWS_ECS_WordPress_HLD.md)

---

## Document History

| Version | Date | Changes | Owner |
|---------|------|---------|-------|
| 1.0 | 2025-12-13 | Initial LLD for per-tenant Cognito User Pools with WordPress integration | Agentic Architect |

---

## 1. Introduction

### 1.1 Purpose

This LLD provides implementation details for per-tenant AWS Cognito User Pools integrated with WordPress via OAuth plugins.

### 1.2 Parent HLD Reference

Based on [Cognito Multi-Tenant Investigation](../investigation/poc/docs/cognito_multi_tenant_investigation.md) and User Stories US-005 through US-010 from the [BBWS ECS WordPress HLD](../BBWS_ECS_WordPress_HLD.md).

### 1.3 Component Overview

Cognito Tenant Pools provide:
- Dedicated User Pool per tenant for complete isolation
- Username/password authentication
- Optional OIDC federation (Google, Azure AD)
- Group-based RBAC (Admin, Operator, Viewer)
- WordPress integration via MiniOrange plugin
- MFA support (TOTP)

### 1.4 Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| Identity Provider | AWS Cognito User Pool | User authentication |
| WordPress Plugin | MiniOrange AWS Cognito Login | OAuth integration |
| OIDC Providers | Google, Azure AD (optional) | Federated login |
| Automation | Python + Boto3 | User Pool provisioning |
| Secrets | AWS Secrets Manager | App Client credentials |

### 1.5 Architecture Decision

**Per-Tenant User Pool** (not shared pool with groups)

| Aspect | Shared Pool | Dedicated Pool (Chosen) |
|--------|-------------|------------------------|
| Isolation | Logical (groups) | Physical (separate pools) |
| Security | Medium | High |
| Tenant Autonomy | Limited | Full |
| Compliance | Shared data plane | Complete separation |

---

## 2. High Level Epic Overview

| User Story ID | User Story | Test Scenario(s) |
|---------------|------------|------------------|
| US-005 | As a DevOps Engineer, I want to configure Cognito User Pool so that platform users can authenticate securely | GIVEN tenant-id WHEN provision_cognito.py executes THEN User Pool created AND App Client configured AND Domain registered |
| US-006 | As an Admin, I want to invite users to the platform so that team members can access tenant management | GIVEN User Pool WHEN invite_user.py executes THEN user created with temp password AND invitation email sent |
| US-007 | As a User, I want to register via invitation so that I can access the platform | GIVEN invitation link WHEN user completes registration THEN password set AND email verified |
| US-008 | As a User, I want to login with MFA so that my account is secure | GIVEN WordPress login page WHEN click "Login with Cognito" THEN redirect to Cognito Hosted UI AND MFA challenge AND login to WordPress |
| US-009 | As a User, I want to reset my password so that I can recover account access | GIVEN forgot password link WHEN user enters email THEN verification code sent AND password reset |
| US-010 | As an Admin, I want to assign roles to users so that access is controlled | GIVEN user-id WHEN assign role THEN Cognito group membership updated |

---

## 3. Component Diagram

### 3.1 Per-Tenant Cognito Architecture

```mermaid
graph TB
    subgraph "Tenant-1: ACME Corp"
        UP1["User Pool: bbws-tenant-1-user-pool"]
        AC1["App Client: tenant-1-wordpress-client"]
        DOM1["Domain: bbws-tenant-1-dev.auth.af-south-1.amazoncognito.com"]
        IDP1["OIDC Provider: Google (optional)"]
        G1["Cognito Groups: Admin, Operator, Viewer"]
    end

    subgraph "Tenant-2: Widget Inc"
        UP2["User Pool: bbws-tenant-2-user-pool"]
        AC2["App Client: tenant-2-wordpress-client"]
        DOM2["Domain: bbws-tenant-2-dev.auth.af-south-1.amazoncognito.com"]
        IDP2["OIDC Provider: Azure AD (optional)"]
        G2["Cognito Groups: Admin, Operator, Viewer"]
    end

    WP1["WordPress Tenant-1<br/>banana.wpdev.kimmyai.io<br/>Plugin: MiniOrange Cognito"]
    WP2["WordPress Tenant-2<br/>orange.wpdev.kimmyai.io<br/>Plugin: MiniOrange Cognito"]

    UP1 --> AC1
    AC1 --> DOM1
    UP1 --> IDP1
    UP1 --> G1
    DOM1 --> WP1

    UP2 --> AC2
    AC2 --> DOM2
    UP2 --> IDP2
    UP2 --> G2
    DOM2 --> WP2
```

### 3.2 Class Diagram

```mermaid
classDiagram
    class CognitoService {
        -CognitoClient client
        -SecretsManagerClient secretsClient
        -ValidationService validator
        +CognitoService(client, secretsClient, validator)
        +createUserPool(tenantId String, config UserPoolConfig) UserPool
        +createAppClient(userPoolId String, config AppClientConfig) AppClient
        +createDomain(userPoolId String, domainPrefix String) Domain
        +addIdentityProvider(userPoolId String, provider OIDCProvider) void
        +createUser(userPoolId String, email String, role String) User
        +assignUserToGroup(userPoolId String, username String, group String) void
        -storeClientSecret(tenantId String, clientId String, secret String) void
    }

    class UserPoolConfig {
        +String poolName
        +PasswordPolicy passwordPolicy
        +MfaConfiguration mfaConfig
        +List~String~ autoVerifiedAttributes
        +List~CustomAttribute~ customAttributes
        +validate() Boolean
    }

    class PasswordPolicy {
        +int minimumLength
        +Boolean requireUppercase
        +Boolean requireLowercase
        +Boolean requireNumbers
        +Boolean requireSymbols
        +int temporaryPasswordValidityDays
    }

    class MfaConfiguration {
        <<enumeration>>
        OFF
        OPTIONAL
        ON
    }

    class AppClientConfig {
        +String clientName
        +Boolean generateSecret
        +int refreshTokenValidity
        +int accessTokenValidity
        +int idTokenValidity
        +List~String~ allowedOAuthFlows
        +List~String~ allowedOAuthScopes
        +List~String~ callbackURLs
        +List~String~ logoutURLs
    }

    class UserPool {
        +String id
        +String name
        +String arn
        +String domain
        +PasswordPolicy passwordPolicy
        +MfaConfiguration mfaConfiguration
        +String creationDate
    }

    class AppClient {
        +String clientId
        +String clientSecret
        +String userPoolId
        +List~String~ callbackURLs
        +List~String~ logoutURLs
    }

    class Domain {
        +String domainPrefix
        +String domainUrl
        +String userPoolId
    }

    class OIDCProvider {
        +String providerName
        +String providerType
        +String clientId
        +String clientSecret
        +String authorizeScopes
        +Map~String,String~ attributeMapping
    }

    class User {
        +String username
        +String email
        +UserStatus status
        +Boolean emailVerified
        +Boolean mfaEnabled
        +List~String~ groups
    }

    class UserStatus {
        <<enumeration>>
        FORCE_CHANGE_PASSWORD
        CONFIRMED
        UNCONFIRMED
        RESET_REQUIRED
    }

    CognitoService --> UserPoolConfig : uses
    CognitoService --> AppClientConfig : uses
    CognitoService --> UserPool : creates
    CognitoService --> AppClient : creates
    CognitoService --> Domain : creates
    CognitoService --> User : manages

    UserPoolConfig --> PasswordPolicy : contains
    UserPoolConfig --> MfaConfiguration : has
    User --> UserStatus : has
```

---

## 4. Cognito Configuration Details

### 4.1 User Pool Settings

```json
{
  "PoolName": "bbws-tenant-1-user-pool",
  "Policies": {
    "PasswordPolicy": {
      "MinimumLength": 8,
      "RequireLowercase": true,
      "RequireUppercase": true,
      "RequireNumbers": true,
      "RequireSymbols": true,
      "TemporaryPasswordValidityDays": 7
    }
  },
  "AutoVerifiedAttributes": ["email"],
  "UsernameAttributes": ["email"],
  "MfaConfiguration": "OPTIONAL",
  "Schema": [
    {
      "Name": "email",
      "AttributeDataType": "String",
      "Required": true,
      "Mutable": true
    },
    {
      "Name": "name",
      "AttributeDataType": "String",
      "Required": false,
      "Mutable": true
    },
    {
      "Name": "tenant_id",
      "AttributeDataType": "String",
      "Required": false,
      "Mutable": false,
      "DeveloperOnlyAttribute": false
    }
  ],
  "AccountRecoverySetting": {
    "RecoveryMechanisms": [
      {
        "Priority": 1,
        "Name": "verified_email"
      }
    ]
  }
}
```

### 4.2 App Client Settings

```json
{
  "ClientName": "tenant-1-wordpress-client",
  "UserPoolId": "af-south-1_XXXXXXXXX",
  "GenerateSecret": true,
  "RefreshTokenValidity": 30,
  "AccessTokenValidity": 1,
  "IdTokenValidity": 1,
  "TokenValidityUnits": {
    "AccessToken": "hours",
    "IdToken": "hours",
    "RefreshToken": "days"
  },
  "ExplicitAuthFlows": [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ],
  "AllowedOAuthFlows": ["code"],
  "AllowedOAuthFlowsUserPoolClient": true,
  "AllowedOAuthScopes": ["openid", "email", "profile"],
  "CallbackURLs": [
    "https://banana.wpdev.kimmyai.io/wp-login.php",
    "https://banana.wpdev.kimmyai.io/wp-admin/admin-ajax.php"
  ],
  "LogoutURLs": [
    "https://banana.wpdev.kimmyai.io/",
    "https://banana.wpdev.kimmyai.io/wp-login.php?loggedout=true"
  ],
  "SupportedIdentityProviders": ["COGNITO"],
  "PreventUserExistenceErrors": "ENABLED"
}
```

### 4.3 Cognito Groups (RBAC)

| Group Name | Description | Permissions |
|------------|-------------|-------------|
| Admin | Full administrative access | Create/delete users, manage WordPress plugins, modify content |
| Operator | Operational access | Manage content, view users, update plugins |
| Viewer | Read-only access | View content, view analytics |

### 4.4 OAuth 2.0 Endpoints

| Endpoint | URL Pattern |
|----------|-------------|
| Authorization | `https://{domain-prefix}.auth.{region}.amazoncognito.com/oauth2/authorize` |
| Token | `https://{domain-prefix}.auth.{region}.amazoncognito.com/oauth2/token` |
| UserInfo | `https://{domain-prefix}.auth.{region}.amazoncognito.com/oauth2/userInfo` |
| Logout | `https://{domain-prefix}.auth.{region}.amazoncognito.com/logout` |
| JWKS | `https://cognito-idp.{region}.amazonaws.com/{user-pool-id}/.well-known/jwks.json` |

**Example for tenant-1:**
```
Authorization: https://bbws-tenant-1-dev.auth.af-south-1.amazoncognito.com/oauth2/authorize
Token:         https://bbws-tenant-1-dev.auth.af-south-1.amazoncognito.com/oauth2/token
UserInfo:      https://bbws-tenant-1-dev.auth.af-south-1.amazoncognito.com/oauth2/userInfo
```

---

## 5. Sequence Diagram

### 5.1 Provision Cognito User Pool Sequence

```mermaid
sequenceDiagram
    participant Operator
    participant CLI
    participant CognitoService
    participant Cognito
    participant SecretsManager
    participant AuditLogger

    Operator->>CLI: provision_cognito.py --tenant-id tenant-1 --domain banana.wpdev.kimmyai.io

    rect rgb(240, 240, 255)
        Note over CognitoService: try block - Cognito Provisioning

        CLI->>CognitoService: createUserPool(tenantId, config)

        CognitoService->>Cognito: CreateUserPool(PoolName="bbws-tenant-1-user-pool", PasswordPolicy, MFA)
        Cognito-->>CognitoService: UserPoolId, Arn

        CognitoService->>Cognito: CreateUserPoolDomain(DomainPrefix="bbws-tenant-1-dev", UserPoolId)
        Cognito-->>CognitoService: DomainUrl

        CognitoService->>Cognito: CreateUserPoolClient(ClientName="tenant-1-wordpress-client", GenerateSecret=true)
        Cognito-->>CognitoService: ClientId, ClientSecret

        CognitoService->>SecretsManager: CreateSecret(Name="bbws/dev/tenant-1/cognito", SecretString=json)
        SecretsManager-->>CognitoService: SecretArn

        CognitoService->>Cognito: CreateGroup(GroupName="Admin", UserPoolId)
        Cognito-->>CognitoService: success

        CognitoService->>Cognito: CreateGroup(GroupName="Operator", UserPoolId)
        Cognito-->>CognitoService: success

        CognitoService->>Cognito: CreateGroup(GroupName="Viewer", UserPoolId)
        Cognito-->>CognitoService: success

        CognitoService->>AuditLogger: logEvent(COGNITO_POOL_CREATED, tenantId)
        AuditLogger-->>CognitoService: void

        CognitoService-->>CLI: UserPool(id, domain, clientId, secretArn)
    end

    alt BusinessException
        Note over CognitoService: catch BusinessException
        CognitoService-->>CLI: 400 Bad Request (InvalidPasswordPolicyException)
        CognitoService-->>CLI: 409 Conflict (DomainAlreadyExistsException)
    end

    alt UnexpectedException
        Note over CognitoService: catch UnexpectedException
        CognitoService->>CognitoService: logger.error(exception)
        CognitoService->>CognitoService: rollbackUserPool()
        CognitoService-->>CLI: 500 Internal Server Error (CognitoException)
        CognitoService-->>CLI: 503 Service Unavailable (AWSServiceException)
    end

    CLI-->>Operator: User Pool created: bbws-tenant-1-user-pool
    CLI-->>Operator: WordPress config: UserPoolId, ClientId, Domain
```

### 5.2 WordPress Login with Cognito Sequence

```mermaid
sequenceDiagram
    participant User
    participant Browser
    participant WordPress
    participant CognitoHostedUI
    participant UserPool

    User->>Browser: Navigate to banana.wpdev.kimmyai.io/wp-login.php

    rect rgb(240, 240, 255)
        Note over WordPress: try block - OAuth Login Flow

        Browser->>WordPress: GET /wp-login.php
        WordPress-->>Browser: Login page with "Login with Cognito" button

        User->>Browser: Click "Login with Cognito"

        Browser->>WordPress: POST /wp-login.php?action=cognito_login
        WordPress->>WordPress: Generate OAuth state, nonce
        WordPress-->>Browser: Redirect to Cognito Hosted UI

        Browser->>CognitoHostedUI: GET /oauth2/authorize?client_id=xxx&response_type=code&redirect_uri=xxx
        CognitoHostedUI-->>Browser: Cognito login form

        User->>Browser: Enter email and password
        Browser->>CognitoHostedUI: POST /login (credentials)

        CognitoHostedUI->>UserPool: AuthenticateUser(email, password)
        UserPool-->>CognitoHostedUI: Authentication success

        alt MFA Enabled
            CognitoHostedUI-->>Browser: MFA challenge page
            User->>Browser: Enter TOTP code
            Browser->>CognitoHostedUI: POST /mfa (code)
            CognitoHostedUI->>UserPool: VerifyMFA(code)
            UserPool-->>CognitoHostedUI: MFA success
        end

        CognitoHostedUI-->>Browser: Redirect to callback with authorization code
        Browser->>WordPress: GET /wp-admin/admin-ajax.php?code=AUTH_CODE&state=xxx

        WordPress->>CognitoHostedUI: POST /oauth2/token (code, client_id, client_secret)
        CognitoHostedUI->>UserPool: ExchangeCodeForTokens(code)
        UserPool-->>CognitoHostedUI: ID token, Access token, Refresh token
        CognitoHostedUI-->>WordPress: Tokens

        WordPress->>WordPress: ValidateIDToken(signature, expiry)
        WordPress->>WordPress: ExtractUserInfo(email, name, groups)

        WordPress->>WordPress: CreateOrUpdateWPUser(email, name, role_from_groups)
        WordPress->>WordPress: CreateWPSession(user_id)

        WordPress-->>Browser: Set-Cookie: wordpress_logged_in_xxx
        WordPress-->>Browser: Redirect to /wp-admin/

        Browser->>WordPress: GET /wp-admin/
        WordPress-->>Browser: WordPress dashboard
    end

    alt BusinessException
        Note over WordPress: catch BusinessException
        WordPress-->>Browser: 401 Unauthorized (InvalidCredentialsException)
        WordPress-->>Browser: 403 Forbidden (UserNotInGroupException)
    end

    alt UnexpectedException
        Note over WordPress: catch UnexpectedException
        WordPress->>WordPress: logger.error(exception)
        WordPress-->>Browser: 500 Internal Server Error (TokenExchangeException)
        WordPress-->>Browser: 503 Service Unavailable (CognitoServiceException)
    end

    User->>Browser: Successfully logged into WordPress
```

---

## 6. WordPress Plugin Configuration

### 6.1 MiniOrange Plugin Settings

**Plugin Name**: AWS Cognito Login
**WordPress.org URL**: https://wordpress.org/plugins/login-with-cognito/

**Configuration Steps**:
1. Install plugin via WordPress admin
2. Navigate to Settings → miniOrange AWS Cognito
3. Configure OAuth settings:

```
User Pool ID:          af-south-1_XXXXXXXXX
App Client ID:         xxxxxxxxxxxxxxxxxxxxxxxxxx
App Client Secret:     [From Secrets Manager: bbws/dev/tenant-1/cognito]
Region:                af-south-1
Domain:                bbws-tenant-1-dev

Authorization URL:     https://bbws-tenant-1-dev.auth.af-south-1.amazoncognito.com/oauth2/authorize
Token URL:             https://bbws-tenant-1-dev.auth.af-south-1.amazoncognito.com/oauth2/token
UserInfo URL:          https://bbws-tenant-1-dev.auth.af-south-1.amazoncognito.com/oauth2/userInfo

Callback URL:          https://banana.wpdev.kimmyai.io/wp-admin/admin-ajax.php
Logout URL:            https://banana.wpdev.kimmyai.io/
```

### 6.2 Attribute Mapping

| Cognito Attribute | WordPress Field | Mapping |
|-------------------|-----------------|---------|
| email | user_email | Direct |
| name | display_name | Direct |
| cognito:groups | wp_role | Admin → administrator, Operator → editor, Viewer → subscriber |
| custom:tenant_id | user_meta | Stored in wp_usermeta |

---

## 7. Non-Functional Requirements

### 7.1 Performance

| Metric | Target | Measurement |
|--------|--------|-------------|
| User Pool creation time | < 30 seconds | CLI execution time |
| Login redirect latency | < 1 second | User experience |
| Token exchange time | < 500ms | OAuth flow duration |
| MFA verification time | < 200ms | TOTP validation |

### 7.2 Security

| Aspect | Implementation |
|--------|----------------|
| Password Policy | Min 8 chars, uppercase, lowercase, numbers, symbols |
| MFA | Optional TOTP (recommended for Admin/Operator) |
| Token Expiry | Access: 1 hour, ID: 1 hour, Refresh: 30 days |
| Client Secret | Stored in Secrets Manager, never exposed to browser |

### 7.3 Cost

| Component | Users | Monthly Cost | Notes |
|-----------|-------|--------------|-------|
| Cognito User Pool | < 50,000 MAU | $0 | Free tier |
| Secrets Manager | 1 secret/tenant | ~$0.40/tenant | App client secret |
| **Total per tenant** | | **~$0.40/month** | Scales with MAU after free tier |

---

## 8. Troubleshooting Playbook

### 8.1 User Cannot Login

**Symptom**: Login redirect fails or loops

**Diagnosis**:
```bash
# Check User Pool status
aws cognito-idp describe-user-pool \
  --user-pool-id af-south-1_XXXXXXXXX \
  --profile Tebogo-dev

# Check callback URL configured
aws cognito-idp describe-user-pool-client \
  --user-pool-id af-south-1_XXXXXXXXX \
  --client-id xxxxxxxxx \
  --profile Tebogo-dev
```

**Resolution**:
- Verify callback URL in App Client matches WordPress URL
- Check App Client has `code` OAuth flow enabled
- Ensure WordPress plugin has correct Client ID/Secret

### 8.2 Token Exchange Fails

**Symptom**: Error after Cognito redirect

**Diagnosis**:
- Check WordPress error logs for OAuth errors
- Verify Client Secret matches Secrets Manager value
- Test token endpoint with curl

**Resolution**:
- Rotate Client Secret if compromised
- Update WordPress plugin with new secret
- Verify token endpoint URL format

---

## 9. References

| Ref ID | Document | Type |
|--------|----------|------|
| REF-COG-001 | [BBWS ECS WordPress HLD](../BBWS_ECS_WordPress_HLD.md) | Parent HLD |
| REF-COG-002 | [Cognito Multi-Tenant Investigation](../investigation/poc/docs/cognito_multi_tenant_investigation.md) | Investigation |
| REF-COG-003 | [Cognito User Pools Developer Guide](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools.html) | AWS Documentation |
| REF-COG-004 | [OAuth 2.0 Specification](https://oauth.net/2/) | Standard |

---

**END OF DOCUMENT**
