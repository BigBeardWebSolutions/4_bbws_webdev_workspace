# Authentication Guide

**Version**: 1.0
**Last Updated**: 2026-01-25

---

## Overview

BBWS APIs use AWS Cognito for authentication. All API requests require a valid JWT (JSON Web Token) obtained through Cognito authentication.

### Authentication Flow

```
┌──────────┐    ┌───────────┐    ┌──────────┐    ┌──────────┐
│  Client  │───>│  Cognito  │───>│   JWT    │───>│  BBWS    │
│          │<───│           │<───│  Token   │<───│   API    │
└──────────┘    └───────────┘    └──────────┘    └──────────┘
     │                                                  │
     │  1. Authenticate with username/password          │
     │  2. Receive access_token, refresh_token          │
     │  3. Include token in API requests                │
     │  4. Token validated by API Gateway               │
```

---

## Cognito Configuration

### User Pool Settings

| Setting | Value |
|---------|-------|
| User Pool | `bbws-customer-portal-{env}` |
| App Client | `bbws-portal-client-{env}` |
| Region | `af-south-1` (DEV/SIT/PROD) |
| Auth Flows | USER_PASSWORD_AUTH, REFRESH_TOKEN_AUTH |

### Environment-Specific Configuration

| Environment | Cognito Domain |
|-------------|----------------|
| DEV | `bbws-dev.auth.af-south-1.amazoncognito.com` |
| SIT | `bbws-sit.auth.af-south-1.amazoncognito.com` |
| PROD | `bbws.auth.af-south-1.amazoncognito.com` |

---

## JWT Token Format

### Access Token Structure

The access token is a JWT containing the following claims:

```json
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",
  "iss": "https://cognito-idp.af-south-1.amazonaws.com/af-south-1_xxxxxxxx",
  "client_id": "xxxxxxxxxxxxxxxxxxxxxxxxxx",
  "origin_jti": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "event_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "token_use": "access",
  "scope": "openid email profile",
  "auth_time": 1737810600,
  "exp": 1737814200,
  "iat": 1737810600,
  "jti": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "username": "user@example.com"
}
```

### ID Token Structure

The ID token contains user attributes:

```json
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "email_verified": true,
  "cognito:username": "user@example.com",
  "cognito:groups": ["Admins", "tenant-123-admins"],
  "custom:customerId": "customer-uuid",
  "custom:tenantIds": "tenant-1,tenant-2",
  "given_name": "John",
  "family_name": "Doe",
  "aud": "client-id",
  "token_use": "id",
  "auth_time": 1737810600,
  "exp": 1737814200,
  "iat": 1737810600
}
```

### Token Lifetimes

| Token Type | Lifetime | Refresh |
|------------|----------|---------|
| Access Token | 1 hour | Use refresh token |
| ID Token | 1 hour | Use refresh token |
| Refresh Token | 30 days | Re-authenticate |

---

## Authentication Methods

### Method 1: User Password Authentication

For server-to-server or CLI applications:

```bash
curl -X POST https://cognito-idp.af-south-1.amazonaws.com/ \
  -H "Content-Type: application/x-amz-json-1.1" \
  -H "X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth" \
  -d '{
    "AuthFlow": "USER_PASSWORD_AUTH",
    "ClientId": "YOUR_CLIENT_ID",
    "AuthParameters": {
      "USERNAME": "user@example.com",
      "PASSWORD": "your-password"
    }
  }'
```

**Response:**

```json
{
  "AuthenticationResult": {
    "AccessToken": "eyJraWQiOiJ...",
    "ExpiresIn": 3600,
    "IdToken": "eyJraWQiOiJ...",
    "RefreshToken": "eyJjdHkiOiJ...",
    "TokenType": "Bearer"
  }
}
```

### Method 2: OAuth 2.0 Authorization Code Flow

For web applications with user interaction:

**Step 1: Redirect to Cognito Login**

```
https://bbws-dev.auth.af-south-1.amazoncognito.com/oauth2/authorize?
  client_id=YOUR_CLIENT_ID&
  response_type=code&
  scope=openid+email+profile&
  redirect_uri=https://your-app.com/callback
```

**Step 2: Exchange Code for Tokens**

```bash
curl -X POST https://bbws-dev.auth.af-south-1.amazoncognito.com/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "code=AUTHORIZATION_CODE" \
  -d "redirect_uri=https://your-app.com/callback"
```

---

## Token Refresh

When the access token expires, use the refresh token to obtain a new access token:

```bash
curl -X POST https://cognito-idp.af-south-1.amazonaws.com/ \
  -H "Content-Type: application/x-amz-json-1.1" \
  -H "X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth" \
  -d '{
    "AuthFlow": "REFRESH_TOKEN_AUTH",
    "ClientId": "YOUR_CLIENT_ID",
    "AuthParameters": {
      "REFRESH_TOKEN": "your-refresh-token"
    }
  }'
```

**Response:**

```json
{
  "AuthenticationResult": {
    "AccessToken": "eyJraWQiOiJ...",
    "ExpiresIn": 3600,
    "IdToken": "eyJraWQiOiJ...",
    "TokenType": "Bearer"
  }
}
```

Note: The refresh token is not returned on refresh - continue using the original refresh token.

---

## Using Tokens in API Requests

### Authorization Header

Include the access token in the `Authorization` header:

```bash
curl -X GET https://api-dev.bigbeardweb.solutions/v1.0/tenants \
  -H "Authorization: Bearer eyJraWQiOiJ..."
```

### Request Headers

| Header | Required | Description |
|--------|----------|-------------|
| `Authorization` | Yes | `Bearer {access_token}` |
| `Content-Type` | Yes | `application/json` for POST/PUT |
| `Accept` | No | `application/json` |
| `X-Request-ID` | No | Correlation ID for tracing |

---

## Code Examples

### Python Authentication

```python
import boto3
import requests
from typing import Optional
from datetime import datetime, timedelta


class CognitoAuthenticator:
    """AWS Cognito authentication client."""

    def __init__(
        self,
        user_pool_id: str,
        client_id: str,
        region: str = "af-south-1"
    ):
        self.user_pool_id = user_pool_id
        self.client_id = client_id
        self.region = region
        self.cognito_client = boto3.client(
            "cognito-idp",
            region_name=region
        )
        self._tokens: Optional[dict] = None
        self._token_expiry: Optional[datetime] = None

    def authenticate(self, username: str, password: str) -> dict:
        """
        Authenticate user with username and password.

        Args:
            username: User email or username
            password: User password

        Returns:
            Authentication result with tokens
        """
        response = self.cognito_client.initiate_auth(
            AuthFlow="USER_PASSWORD_AUTH",
            ClientId=self.client_id,
            AuthParameters={
                "USERNAME": username,
                "PASSWORD": password
            }
        )

        self._tokens = response["AuthenticationResult"]
        self._token_expiry = datetime.utcnow() + timedelta(
            seconds=self._tokens["ExpiresIn"]
        )

        return self._tokens

    def refresh_tokens(self) -> dict:
        """
        Refresh access token using refresh token.

        Returns:
            New authentication result
        """
        if not self._tokens or "RefreshToken" not in self._tokens:
            raise ValueError("No refresh token available. Please authenticate first.")

        response = self.cognito_client.initiate_auth(
            AuthFlow="REFRESH_TOKEN_AUTH",
            ClientId=self.client_id,
            AuthParameters={
                "REFRESH_TOKEN": self._tokens["RefreshToken"]
            }
        )

        # Keep the refresh token (not returned on refresh)
        refresh_token = self._tokens["RefreshToken"]
        self._tokens = response["AuthenticationResult"]
        self._tokens["RefreshToken"] = refresh_token
        self._token_expiry = datetime.utcnow() + timedelta(
            seconds=self._tokens["ExpiresIn"]
        )

        return self._tokens

    def get_access_token(self) -> str:
        """
        Get valid access token, refreshing if necessary.

        Returns:
            Valid access token
        """
        if not self._tokens:
            raise ValueError("Not authenticated. Call authenticate() first.")

        # Refresh if token expires in less than 5 minutes
        if self._token_expiry and datetime.utcnow() >= self._token_expiry - timedelta(minutes=5):
            self.refresh_tokens()

        return self._tokens["AccessToken"]

    @property
    def is_authenticated(self) -> bool:
        """Check if user is authenticated."""
        return self._tokens is not None


class BBWSApiClient:
    """BBWS API client with automatic token management."""

    def __init__(
        self,
        base_url: str,
        authenticator: CognitoAuthenticator
    ):
        self.base_url = base_url.rstrip("/")
        self.authenticator = authenticator

    def _get_headers(self) -> dict:
        """Get request headers with valid auth token."""
        return {
            "Authorization": f"Bearer {self.authenticator.get_access_token()}",
            "Content-Type": "application/json"
        }

    def get(self, path: str, params: dict = None) -> dict:
        """Make authenticated GET request."""
        response = requests.get(
            f"{self.base_url}{path}",
            headers=self._get_headers(),
            params=params
        )
        response.raise_for_status()
        return response.json()

    def post(self, path: str, data: dict) -> dict:
        """Make authenticated POST request."""
        response = requests.post(
            f"{self.base_url}{path}",
            headers=self._get_headers(),
            json=data
        )
        response.raise_for_status()
        return response.json()

    def put(self, path: str, data: dict) -> dict:
        """Make authenticated PUT request."""
        response = requests.put(
            f"{self.base_url}{path}",
            headers=self._get_headers(),
            json=data
        )
        response.raise_for_status()
        return response.json()

    def delete(self, path: str) -> dict:
        """Make authenticated DELETE request."""
        response = requests.delete(
            f"{self.base_url}{path}",
            headers=self._get_headers()
        )
        response.raise_for_status()
        return response.json() if response.text else {}


# Usage Example
if __name__ == "__main__":
    # Initialize authenticator
    auth = CognitoAuthenticator(
        user_pool_id="af-south-1_xxxxxxxx",
        client_id="your-client-id",
        region="af-south-1"
    )

    # Authenticate
    tokens = auth.authenticate("user@example.com", "your-password")
    print(f"Authenticated. Token expires in {tokens['ExpiresIn']} seconds")

    # Initialize API client
    api = BBWSApiClient(
        base_url="https://api-dev.bigbeardweb.solutions/v1.0",
        authenticator=auth
    )

    # Make API calls (token auto-refreshes when needed)
    tenants = api.get("/tenants")
    print(f"Found {len(tenants['items'])} tenants")

    # Create a tenant
    new_tenant = api.post("/tenants", {
        "organizationName": "My Company",
        "contactEmail": "admin@mycompany.com",
        "environment": "dev"
    })
    print(f"Created tenant: {new_tenant['tenantId']}")
```

### JavaScript/TypeScript Authentication

```typescript
interface CognitoTokens {
  AccessToken: string;
  IdToken: string;
  RefreshToken?: string;
  ExpiresIn: number;
  TokenType: string;
}

interface CognitoConfig {
  userPoolId: string;
  clientId: string;
  region: string;
}

class CognitoAuthenticator {
  private tokens: CognitoTokens | null = null;
  private tokenExpiry: Date | null = null;
  private config: CognitoConfig;

  constructor(config: CognitoConfig) {
    this.config = config;
  }

  async authenticate(username: string, password: string): Promise<CognitoTokens> {
    const response = await fetch(
      `https://cognito-idp.${this.config.region}.amazonaws.com/`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-amz-json-1.1',
          'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth'
        },
        body: JSON.stringify({
          AuthFlow: 'USER_PASSWORD_AUTH',
          ClientId: this.config.clientId,
          AuthParameters: {
            USERNAME: username,
            PASSWORD: password
          }
        })
      }
    );

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || 'Authentication failed');
    }

    const data = await response.json();
    this.tokens = data.AuthenticationResult;
    this.tokenExpiry = new Date(Date.now() + (this.tokens!.ExpiresIn * 1000));

    return this.tokens!;
  }

  async refreshTokens(): Promise<CognitoTokens> {
    if (!this.tokens?.RefreshToken) {
      throw new Error('No refresh token available');
    }

    const response = await fetch(
      `https://cognito-idp.${this.config.region}.amazonaws.com/`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-amz-json-1.1',
          'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth'
        },
        body: JSON.stringify({
          AuthFlow: 'REFRESH_TOKEN_AUTH',
          ClientId: this.config.clientId,
          AuthParameters: {
            REFRESH_TOKEN: this.tokens.RefreshToken
          }
        })
      }
    );

    if (!response.ok) {
      throw new Error('Token refresh failed');
    }

    const data = await response.json();
    const refreshToken = this.tokens.RefreshToken;
    this.tokens = data.AuthenticationResult;
    this.tokens!.RefreshToken = refreshToken;
    this.tokenExpiry = new Date(Date.now() + (this.tokens!.ExpiresIn * 1000));

    return this.tokens!;
  }

  async getAccessToken(): Promise<string> {
    if (!this.tokens) {
      throw new Error('Not authenticated');
    }

    // Refresh if token expires in less than 5 minutes
    const fiveMinutesFromNow = new Date(Date.now() + 5 * 60 * 1000);
    if (this.tokenExpiry && this.tokenExpiry < fiveMinutesFromNow) {
      await this.refreshTokens();
    }

    return this.tokens.AccessToken;
  }

  get isAuthenticated(): boolean {
    return this.tokens !== null;
  }
}

class BBWSApiClient {
  private baseUrl: string;
  private authenticator: CognitoAuthenticator;

  constructor(baseUrl: string, authenticator: CognitoAuthenticator) {
    this.baseUrl = baseUrl.replace(/\/$/, '');
    this.authenticator = authenticator;
  }

  private async getHeaders(): Promise<HeadersInit> {
    return {
      'Authorization': `Bearer ${await this.authenticator.getAccessToken()}`,
      'Content-Type': 'application/json'
    };
  }

  async get<T>(path: string, params?: Record<string, string>): Promise<T> {
    const url = new URL(`${this.baseUrl}${path}`);
    if (params) {
      Object.entries(params).forEach(([key, value]) => {
        url.searchParams.append(key, value);
      });
    }

    const response = await fetch(url.toString(), {
      headers: await this.getHeaders()
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.status}`);
    }

    return response.json();
  }

  async post<T>(path: string, data: Record<string, unknown>): Promise<T> {
    const response = await fetch(`${this.baseUrl}${path}`, {
      method: 'POST',
      headers: await this.getHeaders(),
      body: JSON.stringify(data)
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.status}`);
    }

    return response.json();
  }

  async put<T>(path: string, data: Record<string, unknown>): Promise<T> {
    const response = await fetch(`${this.baseUrl}${path}`, {
      method: 'PUT',
      headers: await this.getHeaders(),
      body: JSON.stringify(data)
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.status}`);
    }

    return response.json();
  }

  async delete<T>(path: string): Promise<T | null> {
    const response = await fetch(`${this.baseUrl}${path}`, {
      method: 'DELETE',
      headers: await this.getHeaders()
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.status}`);
    }

    const text = await response.text();
    return text ? JSON.parse(text) : null;
  }
}

// Usage Example
async function main() {
  // Initialize authenticator
  const auth = new CognitoAuthenticator({
    userPoolId: 'af-south-1_xxxxxxxx',
    clientId: 'your-client-id',
    region: 'af-south-1'
  });

  // Authenticate
  const tokens = await auth.authenticate('user@example.com', 'your-password');
  console.log(`Authenticated. Token expires in ${tokens.ExpiresIn} seconds`);

  // Initialize API client
  const api = new BBWSApiClient(
    'https://api-dev.bigbeardweb.solutions/v1.0',
    auth
  );

  // Make API calls
  const tenants = await api.get<{ items: any[] }>('/tenants');
  console.log(`Found ${tenants.items.length} tenants`);

  // Create a tenant
  const newTenant = await api.post('/tenants', {
    organizationName: 'My Company',
    contactEmail: 'admin@mycompany.com',
    environment: 'dev'
  });
  console.log(`Created tenant: ${newTenant.tenantId}`);
}

main().catch(console.error);
```

---

## Password Policy

BBWS enforces the following password requirements:

| Requirement | Value |
|-------------|-------|
| Minimum length | 8 characters |
| Require uppercase | Yes |
| Require lowercase | Yes |
| Require numbers | Yes |
| Require symbols | Yes |
| Temporary password validity | 7 days |

---

## Security Best Practices

### Token Storage

- **Never store tokens in localStorage** for web applications (XSS vulnerable)
- Use **httpOnly cookies** for web applications
- Use **secure storage** (Keychain/Keystore) for mobile apps
- **Never log tokens** or include them in error messages

### Token Transmission

- Always use **HTTPS**
- Include tokens only in the **Authorization header**
- Never include tokens in URLs (query parameters)

### Token Lifecycle

- Implement **automatic token refresh** before expiry
- Handle **401 Unauthorized** responses by refreshing tokens
- Implement **logout** by clearing local tokens and calling Cognito sign-out

---

## Error Responses

### Authentication Errors

| Error | HTTP Status | Description | Resolution |
|-------|-------------|-------------|------------|
| `NotAuthorizedException` | 401 | Invalid credentials | Check username/password |
| `UserNotFoundException` | 401 | User does not exist | Check username |
| `UserNotConfirmedException` | 403 | Email not verified | Verify email first |
| `PasswordResetRequiredException` | 403 | Password reset required | Reset password |
| `InvalidParameterException` | 400 | Invalid request | Check request format |

### Token Errors

| Error | HTTP Status | Description | Resolution |
|-------|-------------|-------------|------------|
| Token expired | 401 | Access token expired | Refresh token |
| Token invalid | 401 | Token malformed or tampered | Re-authenticate |
| Token revoked | 401 | Token has been revoked | Re-authenticate |

---

## Related Documentation

- [Getting Started](./getting-started.md)
- [Error Handling](./error-handling.md)
- [Tenant API Guide](./tenant-api-guide.md)
- [AWS Cognito Documentation](https://docs.aws.amazon.com/cognito/)

---

**End of Document**
