# BP-005: User Authentication Process

**Version:** 1.0
**Effective Date:** 2026-01-18
**Process Owner:** Security Team
**Last Review:** 2026-01-18

---

## 1. Process Overview

### 1.1 Purpose
This document describes the authentication process for users accessing the Site Builder application. It covers login, token management, session handling, and multi-tenant access control.

### 1.2 Scope
- User login via Cognito
- JWT token issuance and validation
- Session management
- Role-based access control (RBAC)
- Tenant isolation

### 1.3 Authentication Methods
| Method | Availability | Use Case |
|--------|-------------|----------|
| Email/Password | All users | Primary login |
| Google OAuth | All users | Social login |
| Microsoft OAuth | Enterprise | Corporate SSO |
| SAML | Enterprise | Corporate SSO |

---

## 2. Process Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│                    USER AUTHENTICATION PROCESS                            │
│                              BP-005                                       │
└──────────────────────────────────────────────────────────────────────────┘

    ┌─────────────┐
    │   START     │
    │  User       │
    │  Accesses   │
    │  /page_builder│
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐
    │  Check      │
    │  Session    │
    │  Token      │
    └──────┬──────┘
           │
     ┌─────┴─────┐
     │           │
     ▼           ▼
┌─────────┐ ┌─────────────┐
│ TOKEN   │ │ NO TOKEN/   │
│ VALID   │ │ EXPIRED     │
└────┬────┘ └──────┬──────┘
     │             │
     │             ▼
     │      ┌─────────────┐
     │      │  Redirect   │
     │      │  to Login   │
     │      │  Page       │
     │      └──────┬──────┘
     │             │
     │             ▼
     │      ┌─────────────┐
     │      │  User       │
     │      │  Enters     │
     │      │  Credentials│
     │      └──────┬──────┘
     │             │
     │             ▼
     │      ┌─────────────┐     ┌─────────────────────────────────┐
     │      │  Authenticate│     │ Cognito Validation:             │
     │      │  with        │────▶│ • Check username/password       │
     │      │  Cognito     │     │ • Verify MFA (if enabled)       │
     │      │              │     │ • Check account status          │
     │      └──────┬──────┘     └─────────────────────────────────┘
     │             │
     │       ┌─────┴─────┐
     │       │           │
     │       ▼           ▼
     │  ┌─────────┐ ┌─────────┐
     │  │ SUCCESS │ │ FAILED  │
     │  └────┬────┘ └────┬────┘
     │       │           │
     │       │           ▼
     │       │    ┌─────────────┐
     │       │    │  Show Error │
     │       │    │  Increment  │
     │       │    │  Fail Count │
     │       │    └──────┬──────┘
     │       │           │
     │       │     ┌─────┴─────┐
     │       │     │           │
     │       │     ▼           ▼
     │       │ ┌────────┐ ┌─────────┐
     │       │ │< 5 Fails│ │>= 5 Fails│
     │       │ │Retry   │ │Lock Acct│
     │       │ └────────┘ └─────────┘
     │       │
     │       ▼
     │ ┌─────────────┐     ┌─────────────────────────────────┐
     │ │  Issue      │     │ JWT Contains:                   │
     │ │  JWT        │────▶│ • sub (user_id)                 │
     │ │  Tokens     │     │ • email                         │
     │ │             │     │ • custom:tenant_id              │
     │ │             │     │ • custom:roles                  │
     │ │             │     │ • exp (expiry)                  │
     │ └──────┬──────┘     └─────────────────────────────────┘
     │        │
     └────────┤
              │
              ▼
       ┌─────────────┐
       │  Store      │
       │  Tokens     │
       │  (Memory/   │
       │  httpOnly)  │
       └──────┬──────┘
              │
              ▼
       ┌─────────────┐
       │  Load       │
       │  Tenant     │
       │  Context    │
       └──────┬──────┘
              │
              ▼
       ┌─────────────┐
       │  Redirect   │
       │  to         │
       │  Dashboard  │
       └──────┬──────┘
              │
              ▼
       ┌─────────────┐
       │    END      │
       │  User       │
       │  Logged In  │
       └─────────────┘
```

---

## 3. JWT Token Structure

### 3.1 Access Token Claims
```json
{
  "sub": "12345678-1234-1234-1234-123456789012",
  "iss": "https://cognito-idp.eu-west-1.amazonaws.com/eu-west-1_xxxxx",
  "client_id": "1234567890abcdef",
  "origin_jti": "unique-token-id",
  "event_id": "event-id",
  "token_use": "access",
  "scope": "openid email profile",
  "auth_time": 1705580400,
  "exp": 1705584000,
  "iat": 1705580400,
  "jti": "jwt-id",
  "username": "user@example.com",
  "custom:tenant_id": "ten_abc123",
  "custom:roles": "tenant_admin,content_editor"
}
```

### 3.2 Token Lifetimes
| Token Type | Lifetime | Refresh |
|------------|----------|---------|
| Access Token | 1 hour | Via refresh token |
| ID Token | 1 hour | Via refresh token |
| Refresh Token | 30 days | Re-authenticate |

---

## 4. Role-Based Access Control

### 4.1 Roles
| Role | Description | Permissions |
|------|-------------|-------------|
| `tenant_admin` | Full tenant access | Create, edit, deploy, manage users |
| `content_editor` | Content management | Create, edit sites |
| `viewer` | Read-only | View sites and analytics |
| `partner_admin` | Partner portal access | Manage sub-tenants, branding |

### 4.2 Permission Matrix
| Action | tenant_admin | content_editor | viewer |
|--------|--------------|----------------|--------|
| View dashboard | ✅ | ✅ | ✅ |
| Create site | ✅ | ✅ | ❌ |
| Edit site | ✅ | ✅ | ❌ |
| Deploy to staging | ✅ | ✅ | ❌ |
| Deploy to production | ✅ | ❌ | ❌ |
| Manage users | ✅ | ❌ | ❌ |
| View billing | ✅ | ❌ | ❌ |
| Configure custom domain | ✅ | ❌ | ❌ |

---

## 5. Session Management

### 5.1 Session Rules
| Rule | Value |
|------|-------|
| Idle timeout | 30 minutes |
| Absolute timeout | 8 hours |
| Concurrent sessions | 3 maximum |
| Remember me | 30 days (optional) |

### 5.2 Session Handling
```
ON each API request:
    1. Extract JWT from Authorization header
    2. Validate JWT signature with Cognito public key
    3. Check token expiry
    4. IF expired AND refresh token available:
         - Request new access token
         - Continue with new token
    5. IF expired AND no refresh token:
         - Return 401 Unauthorized
         - Redirect to login

ON logout:
    1. Revoke refresh token in Cognito
    2. Clear local token storage
    3. Redirect to login page
```

---

## 6. Multi-Tenant Isolation

### 6.1 Tenant Context
```
Every authenticated request includes:
- tenant_id from JWT claims
- Used to scope all database queries
- Prevents cross-tenant data access

Example API Query:
  GET /sites
  → DynamoDB query: PK = "TENANT#{tenant_id}"

Example S3 Access:
  GET /assets/logo.png
  → s3://bucket/{tenant_id}/assets/logo.png
```

### 6.2 API Gateway Authorization
```yaml
# API Gateway JWT Authorizer configuration
AuthorizationType: JWT
Authorizer:
  Type: JWT
  IdentitySource: "$request.header.Authorization"
  JwtConfiguration:
    Audience:
      - !Ref CognitoAppClientId
    Issuer: !Sub "https://cognito-idp.${AWS::Region}.amazonaws.com/${CognitoUserPoolId}"
```

---

## 7. Password Policy

### 7.1 Requirements
| Requirement | Value |
|-------------|-------|
| Minimum length | 12 characters |
| Uppercase required | Yes |
| Lowercase required | Yes |
| Numbers required | Yes |
| Special characters required | Yes |
| Password history | Last 5 passwords |
| Expiry | 90 days (Enterprise only) |

### 7.2 Account Lockout
| Condition | Action |
|-----------|--------|
| 5 failed attempts | Lock for 15 minutes |
| 10 failed attempts | Lock for 1 hour |
| 15 failed attempts | Lock until admin reset |

---

## 8. First-Time Login Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    FIRST-TIME LOGIN FLOW                         │
└─────────────────────────────────────────────────────────────────┘

  After Purchase → Cognito User Created with FORCE_CHANGE_PASSWORD

  1. User receives email with temporary password
  2. User clicks login link
  3. User enters temporary password
  4. System prompts for new password
  5. User sets new password (meeting policy)
  6. System updates Cognito user status to CONFIRMED
  7. User redirected to dashboard with onboarding tour
```

---

## 9. Error Handling

| Error | Message | Action |
|-------|---------|--------|
| Invalid credentials | "Incorrect email or password" | Log attempt, increment counter |
| Account locked | "Account temporarily locked" | Show unlock time |
| Token expired | "Session expired" | Redirect to login |
| Invalid token | "Invalid session" | Clear tokens, redirect to login |
| MFA required | "Enter verification code" | Show MFA input |

---

## 10. Security Logging

### 10.1 Events Logged
| Event | Severity | Data Captured |
|-------|----------|---------------|
| Login success | INFO | user_id, tenant_id, IP, timestamp |
| Login failure | WARNING | email, IP, timestamp, reason |
| Logout | INFO | user_id, session_duration |
| Password change | INFO | user_id, timestamp |
| Account locked | WARNING | email, IP, attempt_count |
| Token refresh | DEBUG | user_id, old_token_exp, new_token_exp |

### 10.2 Retention
- Authentication logs: 90 days
- Security events: 1 year
- Compliance audit: 7 years

---

## 11. Related Documents

| Document | Type | Location |
|----------|------|----------|
| RB-005 | Runbook | /runbooks/RB-005_Authentication_Issues.md |
| SOP-005 | SOP | /SOPs/SOP-005_User_Access_Management.md |

---

## 12. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-18 | Security Team | Initial version |
