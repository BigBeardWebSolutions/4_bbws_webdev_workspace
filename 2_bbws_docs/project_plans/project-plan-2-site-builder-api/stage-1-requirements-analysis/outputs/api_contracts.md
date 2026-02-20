# API Contracts - Site Builder Bedrock Generation API

**Version**: 1.0
**Date**: 2026-01-15
**Author**: Worker 4 - API Contract Consolidation
**Status**: Draft

**Source Documents**:
- HLD Analysis (`hld_analysis.md`)
- BRS Analysis (`brs_analysis.md`)
- Frontend Integration Analysis (`frontend_integration.md`)

---

## Table of Contents

1. [API Overview](#1-api-overview)
2. [Generation API Endpoints](#2-generation-api-endpoints)
3. [Agents API Endpoints](#3-agents-api-endpoints)
4. [Validation API Endpoints](#4-validation-api-endpoints)
5. [Deployment API Endpoints](#5-deployment-api-endpoints)
6. [Templates API Endpoints](#6-templates-api-endpoints)
7. [Analytics API Endpoints](#7-analytics-api-endpoints)
8. [Tenant Management API Endpoints](#8-tenant-management-api-endpoints)
9. [Migration API Endpoints](#9-migration-api-endpoints)
10. [Prompt Management API Endpoints](#10-prompt-management-api-endpoints)
11. [Data Models](#11-data-models)
12. [Error Response Format](#12-error-response-format)
13. [Authentication](#13-authentication)
14. [SSE Streaming Protocol](#14-sse-streaming-protocol)

---

## 1. API Overview

### 1.1 API Summary by Domain

| Domain | Endpoints | Priority | Description |
|--------|-----------|----------|-------------|
| **Generation** | 5 | Critical | AI-powered page generation with streaming |
| **Agents** | 7 | High | Specialized AI agents (logo, background, theme, etc.) |
| **Validation** | 3 | Critical | Brand compliance and security validation |
| **Deployment** | 6 | High | Site staging and production deployment |
| **Templates** | 2 | Critical | Design template management |
| **Analytics** | 2 | High | Component and cost analytics |
| **Tenant Management** | 7 | High | Organisation and user management |
| **Migration** | 3 | Medium | Legacy site migration |
| **Prompts** | 2 | Medium | Prompt library management |
| **Total** | **37** | | |

### 1.2 Base URL Configuration

| Environment | Base URL | Region |
|-------------|----------|--------|
| DEV | `https://api.dev.kimmyai.io` | eu-west-1 |
| SIT | `https://api.sit.kimmyai.io` | eu-west-1 |
| PROD | `https://api.kimmyai.io` | af-south-1 |
| DR | `https://api.eu.kimmyai.io` | eu-west-1 |

### 1.3 API Version

All endpoints use version prefix: `/v1`

---

## 2. Generation API Endpoints

### 2.1 POST `/v1/sites/{tenant_id}/generation`

**Description**: Start AI-powered page generation with SSE streaming response.

**User Stories**: US-001

**AI Agents**: Site Generator Agent, Outliner Agent, Theme Selector Agent, Layout Agent

**Request Headers**:
| Header | Value | Required | Description |
|--------|-------|----------|-------------|
| `Authorization` | `Bearer {jwt_token}` | Yes | JWT access token |
| `X-Tenant-Id` | `{tenant_id}` | Yes | Tenant identifier |
| `Content-Type` | `application/json` | Yes | Request body format |
| `Accept` | `text/event-stream` | Yes | SSE streaming response |

**Request Body Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "prompt": {
      "type": "string",
      "description": "Natural language description of page requirements",
      "minLength": 10,
      "maxLength": 2000
    },
    "template_id": {
      "type": "string",
      "description": "Reference template to use (optional)"
    },
    "brand_assets": {
      "type": "object",
      "properties": {
        "logo_id": { "type": "string" },
        "color_palette_id": { "type": "string" }
      }
    },
    "options": {
      "type": "object",
      "properties": {
        "preview_only": {
          "type": "boolean",
          "description": "Use Claude Haiku for quick preview (cheaper)",
          "default": false
        },
        "sections": {
          "type": "array",
          "items": {
            "type": "string",
            "enum": ["hero", "features", "testimonials", "cta", "footer", "about", "pricing", "faq"]
          },
          "description": "Specific sections to include"
        }
      }
    }
  },
  "required": ["prompt"]
}
```

**Response Schema** (SSE Stream - see Section 14):
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "generation_id": {
      "type": "string",
      "description": "Unique generation job identifier"
    },
    "status": {
      "type": "string",
      "enum": ["in_progress", "completed", "failed"]
    },
    "preview_url": {
      "type": "string",
      "format": "uri",
      "description": "URL to preview generated content"
    },
    "sections": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "section_id": { "type": "string" },
          "type": { "type": "string" },
          "html": { "type": "string" }
        }
      }
    },
    "html": {
      "type": "string",
      "description": "Complete generated HTML"
    },
    "css": {
      "type": "string",
      "description": "Generated CSS styles"
    },
    "brand_score": {
      "type": "number",
      "minimum": 0,
      "maximum": 10,
      "description": "Brand compliance score"
    },
    "version": {
      "type": "integer",
      "description": "Generation version number"
    },
    "created_at": {
      "type": "string",
      "format": "date-time"
    }
  }
}
```

**Error Responses**:
| HTTP Status | Error Code | Description |
|-------------|------------|-------------|
| 400 | GEN-003 | Invalid prompt (content policy violation) |
| 401 | AUTH-001 | Invalid/expired JWT |
| 403 | AUTH-002 | Insufficient permissions |
| 408 | GEN-002 | Request timeout (TTLT exceeded) |
| 422 | GEN-004 | Ambiguous requirements |
| 429 | GEN-006 | Generation quota exceeded |
| 503 | GEN-001 | AI service unavailable |

**Example Request**:
```bash
curl -X POST "https://api.dev.kimmyai.io/v1/sites/tenant_123/generation" \
  -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "X-Tenant-Id: tenant_123" \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{
    "prompt": "Create a professional landing page for a tech startup with a hero section, features grid, and call-to-action",
    "options": {
      "sections": ["hero", "features", "cta"]
    }
  }'
```

**Performance Requirements**:
- TTFT (Time To First Token): < 2 seconds
- TTLT (Time To Last Token): < 60 seconds
- Full generation: 10-15 seconds

---

### 2.2 GET `/v1/sites/{tenant_id}/generation/{generation_id}`

**Description**: Get generation job status and results.

**Request Headers**:
| Header | Value | Required |
|--------|-------|----------|
| `Authorization` | `Bearer {jwt_token}` | Yes |
| `X-Tenant-Id` | `{tenant_id}` | Yes |

**Path Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| `tenant_id` | string | Tenant identifier |
| `generation_id` | string | Generation job identifier |

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "generation_id": { "type": "string" },
    "tenant_id": { "type": "string" },
    "site_id": { "type": "string" },
    "status": {
      "type": "string",
      "enum": ["QUEUED", "PROCESSING", "VALIDATING", "COMPLETED", "FAILED", "TIMEOUT"]
    },
    "prompt": { "type": "string" },
    "refined_prompt": { "type": "string" },
    "agent_states": {
      "type": "object",
      "additionalProperties": {
        "type": "string",
        "enum": ["pending", "running", "completed", "failed"]
      }
    },
    "brand_score": { "type": "number" },
    "security_scan_result": {
      "type": "string",
      "enum": ["PASS", "FAIL", "PENDING"]
    },
    "error_message": { "type": "string" },
    "retry_count": { "type": "integer" },
    "created_at": { "type": "string", "format": "date-time" },
    "started_at": { "type": "string", "format": "date-time" },
    "completed_at": { "type": "string", "format": "date-time" }
  }
}
```

---

### 2.3 POST `/v1/sites/{tenant_id}/generation/{generation_id}/advisor`

**Description**: Get AI advisor feedback for iterative refinement of generated content.

**User Stories**: US-003

**AI Agents**: AI Advisor Agent, Layout Agent

**Request Headers**:
| Header | Value | Required |
|--------|-------|----------|
| `Authorization` | `Bearer {jwt_token}` | Yes |
| `X-Tenant-Id` | `{tenant_id}` | Yes |
| `Content-Type` | `application/json` | Yes |
| `Accept` | `text/event-stream` | Yes |

**Request Body Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "feedback": {
      "type": "string",
      "description": "Natural language feedback for refinement",
      "minLength": 1,
      "maxLength": 1000
    },
    "target_sections": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Specific section IDs to modify (optional)"
    },
    "action": {
      "type": "string",
      "enum": ["refine", "regenerate", "replace"],
      "default": "refine"
    }
  },
  "required": ["feedback"]
}
```

**Response Schema**: Same as generation response (SSE stream)

**Performance Requirements**:
- Response time: < 10 seconds
- Streaming enabled for real-time updates

---

### 2.4 GET `/v1/sites/{tenant_id}/generation/{generation_id}/versions`

**Description**: List version history for a generation.

**User Stories**: US-004

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "generation_id": { "type": "string" },
    "versions": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "version": { "type": "integer" },
          "created_at": { "type": "string", "format": "date-time" },
          "prompt": { "type": "string" },
          "brand_score": { "type": "number" },
          "preview_url": { "type": "string" }
        }
      }
    }
  }
}
```

---

### 2.5 POST `/v1/sites/{tenant_id}/generation/{generation_id}/versions/{version}`

**Description**: Restore a previous version.

**User Stories**: US-004

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "generation_id": { "type": "string" },
    "restored_version": { "type": "integer" },
    "current_version": { "type": "integer" },
    "preview_url": { "type": "string" }
  }
}
```

---

## 3. Agents API Endpoints

### 3.1 POST `/v1/sites/{tenant_id}/agents/logo`

**Description**: Generate professional logo images using Stable Diffusion XL.

**User Stories**: US-011

**AI Model**: Stable Diffusion XL (`stability.stable-diffusion-xl-v1`)

**Request Headers**:
| Header | Value | Required |
|--------|-------|----------|
| `Authorization` | `Bearer {jwt_token}` | Yes |
| `X-Tenant-Id` | `{tenant_id}` | Yes |
| `Content-Type` | `application/json` | Yes |

**Request Body Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "description": {
      "type": "string",
      "description": "Logo requirements description",
      "minLength": 10,
      "maxLength": 500
    },
    "style": {
      "type": "string",
      "enum": ["modern", "classic", "minimal", "playful"],
      "default": "modern"
    },
    "colors": {
      "type": "array",
      "items": {
        "type": "string",
        "pattern": "^#[0-9A-Fa-f]{6}$"
      },
      "maxItems": 5,
      "description": "Hex color codes to use"
    },
    "variations": {
      "type": "integer",
      "minimum": 1,
      "maximum": 8,
      "default": 4
    },
    "dimensions": {
      "type": "string",
      "enum": ["512x512", "768x768", "1024x1024"],
      "default": "1024x1024"
    }
  },
  "required": ["description"]
}
```

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "logo_options": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "logo_id": { "type": "string" },
          "preview_url": { "type": "string", "format": "uri" },
          "formats": {
            "type": "object",
            "properties": {
              "svg": { "type": "string", "format": "uri" },
              "png": { "type": "string", "format": "uri" }
            }
          },
          "brand_score": { "type": "number" }
        }
      }
    },
    "generation_time_ms": { "type": "integer" }
  }
}
```

**Error Responses**:
| HTTP Status | Error Code | Description |
|-------------|------------|-------------|
| 422 | AGT-002 | Image generation blocked (content policy) |
| 503 | AGT-001 | Stable Diffusion unavailable |

**Performance Requirements**:
- Generation time: < 15 seconds
- Timeout: 30 seconds

---

### 3.2 POST `/v1/sites/{tenant_id}/agents/background`

**Description**: Generate background images matching page theme using Stable Diffusion XL.

**User Stories**: US-012

**AI Model**: Stable Diffusion XL (`stability.stable-diffusion-xl-v1`)

**Request Body Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "description": {
      "type": "string",
      "description": "Background image requirements",
      "minLength": 10,
      "maxLength": 300
    },
    "style": {
      "type": "string",
      "enum": ["photographic", "digital-art", "abstract", "gradient"],
      "default": "photographic"
    },
    "dimensions": {
      "type": "string",
      "enum": ["1024x576", "1344x768", "1024x1024", "576x1024", "1024x768"],
      "default": "1344x768"
    },
    "variations": {
      "type": "integer",
      "minimum": 1,
      "maximum": 4,
      "default": 2
    }
  },
  "required": ["description"]
}
```

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "background_options": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "image_id": { "type": "string" },
          "preview_url": { "type": "string", "format": "uri" },
          "full_url": { "type": "string", "format": "uri" },
          "dimensions": { "type": "string" },
          "file_size_kb": { "type": "integer" }
        }
      }
    },
    "generation_time_ms": { "type": "integer" }
  }
}
```

**Performance Requirements**:
- Generation time: < 20 seconds
- Maximum file size: 500KB per image

---

### 3.3 POST `/v1/sites/{tenant_id}/agents/theme`

**Description**: Suggest cohesive color themes for professional design.

**User Stories**: US-013

**AI Model**: Claude Sonnet 4.5 (`anthropic.claude-sonnet-4-5`)

**Request Body Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "industry": {
      "type": "string",
      "description": "Industry or business type"
    },
    "mood": {
      "type": "string",
      "enum": ["professional", "creative", "energetic", "calm", "bold", "elegant"],
      "default": "professional"
    },
    "existing_colors": {
      "type": "array",
      "items": {
        "type": "string",
        "pattern": "^#[0-9A-Fa-f]{6}$"
      },
      "description": "Existing brand colors to complement"
    },
    "variations": {
      "type": "integer",
      "minimum": 1,
      "maximum": 5,
      "default": 3
    }
  }
}
```

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "theme_options": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "theme_id": { "type": "string" },
          "name": { "type": "string" },
          "colors": {
            "type": "object",
            "properties": {
              "primary": { "type": "string" },
              "secondary": { "type": "string" },
              "accent": { "type": "string" },
              "background": { "type": "string" },
              "text": { "type": "string" }
            }
          },
          "contrast_ratios": {
            "type": "object",
            "properties": {
              "primary_on_background": { "type": "number" },
              "text_on_background": { "type": "number" }
            }
          },
          "wcag_compliant": { "type": "boolean" },
          "preview_url": { "type": "string" }
        }
      }
    }
  }
}
```

**Performance Requirements**:
- Response time: < 5 seconds
- WCAG 2.1 AA contrast validation required

---

### 3.4 POST `/v1/sites/{tenant_id}/agents/outline`

**Description**: Propose page structure before full generation.

**User Stories**: US-014

**AI Model**: Claude Sonnet 4.5 (`anthropic.claude-sonnet-4-5`)

**Request Body Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "prompt": {
      "type": "string",
      "description": "Page requirements description",
      "minLength": 10,
      "maxLength": 1000
    },
    "page_type": {
      "type": "string",
      "enum": ["landing", "product", "about", "contact", "blog", "portfolio"],
      "default": "landing"
    }
  },
  "required": ["prompt"]
}
```

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "outline_id": { "type": "string" },
    "sections": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "section_id": { "type": "string" },
          "type": { "type": "string" },
          "title": { "type": "string" },
          "description": { "type": "string" },
          "suggested_components": {
            "type": "array",
            "items": { "type": "string" }
          },
          "order": { "type": "integer" }
        }
      }
    },
    "rationale": { "type": "string" }
  }
}
```

**Performance Requirements**:
- Response time: < 5 seconds

---

### 3.5 POST `/v1/sites/{tenant_id}/agents/layout`

**Description**: Create responsive grid-based page layouts.

**User Stories**: US-023

**AI Model**: Claude Sonnet 4.5 (`anthropic.claude-sonnet-4-5`)

**Request Body Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "sections": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": ["hero", "features", "testimonials", "cta", "footer", "about", "pricing", "faq", "gallery", "team"]
      },
      "minItems": 1
    },
    "grid_type": {
      "type": "string",
      "enum": ["12-column", "fluid", "asymmetric"],
      "default": "12-column"
    },
    "breakpoints": {
      "type": "object",
      "properties": {
        "mobile": { "type": "integer", "default": 768 },
        "tablet": { "type": "integer", "default": 1024 },
        "desktop": { "type": "integer", "default": 1440 }
      }
    }
  },
  "required": ["sections"]
}
```

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "layout_id": { "type": "string" },
    "grid_css": { "type": "string" },
    "sections": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "section_id": { "type": "string" },
          "type": { "type": "string" },
          "grid_placement": {
            "type": "object",
            "properties": {
              "desktop": { "type": "string" },
              "tablet": { "type": "string" },
              "mobile": { "type": "string" }
            }
          }
        }
      }
    },
    "preview_urls": {
      "type": "object",
      "properties": {
        "desktop": { "type": "string" },
        "tablet": { "type": "string" },
        "mobile": { "type": "string" }
      }
    }
  }
}
```

**Performance Requirements**:
- Response time: < 10 seconds
- Mobile experience validation required

---

### 3.6 POST `/v1/sites/{tenant_id}/agents/blog`

**Description**: Generate SEO-optimized blog posts and articles.

**User Stories**: US-022

**AI Model**: Claude Sonnet 4.5 (`anthropic.claude-sonnet-4-5`)

**Request Body Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "topic": {
      "type": "string",
      "description": "Blog post topic or title",
      "minLength": 5,
      "maxLength": 200
    },
    "keywords": {
      "type": "array",
      "items": { "type": "string" },
      "maxItems": 10,
      "description": "SEO keywords to target"
    },
    "tone": {
      "type": "string",
      "enum": ["professional", "casual", "technical", "conversational"],
      "default": "professional"
    },
    "word_count": {
      "type": "integer",
      "minimum": 300,
      "maximum": 3000,
      "default": 800
    },
    "include_cta": {
      "type": "boolean",
      "default": true
    }
  },
  "required": ["topic"]
}
```

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "blog_id": { "type": "string" },
    "title": { "type": "string" },
    "meta_description": {
      "type": "string",
      "maxLength": 160
    },
    "content": {
      "type": "object",
      "properties": {
        "html": { "type": "string" },
        "markdown": { "type": "string" }
      }
    },
    "headings": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "level": { "type": "integer" },
          "text": { "type": "string" }
        }
      }
    },
    "cta": {
      "type": "object",
      "properties": {
        "text": { "type": "string" },
        "html": { "type": "string" }
      }
    },
    "word_count": { "type": "integer" },
    "seo_score": { "type": "number" }
  }
}
```

**Error Responses**:
| HTTP Status | Error Code | Description |
|-------------|------------|-------------|
| 422 | AGT-004 | Blog generation off-topic |

**Performance Requirements**:
- Response time: < 30 seconds
- Timeout: 45 seconds

---

### 3.7 POST `/v1/sites/{tenant_id}/agents/newsletter`

**Description**: Generate email-optimized newsletter templates and content.

**User Stories**: US-024

**AI Model**: Claude Sonnet 4.5 + SES Integration

**Request Body Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "topic": {
      "type": "string",
      "description": "Newsletter topic or theme",
      "minLength": 5,
      "maxLength": 200
    },
    "sections": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": ["header", "featured", "news", "cta", "footer", "social"]
      },
      "default": ["header", "featured", "cta", "footer"]
    },
    "tone": {
      "type": "string",
      "enum": ["professional", "casual", "promotional"],
      "default": "professional"
    },
    "send_test": {
      "type": "boolean",
      "description": "Send test email to user",
      "default": false
    },
    "test_email": {
      "type": "string",
      "format": "email",
      "description": "Email address for test send"
    }
  },
  "required": ["topic"]
}
```

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "newsletter_id": { "type": "string" },
    "subject_line": { "type": "string" },
    "preview_text": { "type": "string" },
    "html": {
      "type": "string",
      "description": "Email-optimized HTML"
    },
    "plain_text": { "type": "string" },
    "email_client_compatibility": {
      "type": "object",
      "properties": {
        "gmail": { "type": "boolean" },
        "outlook": { "type": "boolean" },
        "apple_mail": { "type": "boolean" }
      }
    },
    "test_sent": { "type": "boolean" },
    "preview_url": { "type": "string" }
  }
}
```

**Error Responses**:
| HTTP Status | Error Code | Description |
|-------------|------------|-------------|
| 500 | AGT-003 | Newsletter SES integration failed |

**Performance Requirements**:
- Response time: < 30 seconds
- Timeout: 45 seconds

---

## 4. Validation API Endpoints

### 4.1 POST `/v1/sites/{tenant_id}/generation/{generation_id}/validate/brand`

**Description**: Validate brand compliance and return detailed scoring.

**User Stories**: US-005

**AI Agent**: Design Scorer Agent (Lambda BrandConsistencyScorer)

**AI Model**: Claude Sonnet 4.5 (`anthropic.claude-sonnet-4-5`)

**Request Headers**:
| Header | Value | Required |
|--------|-------|----------|
| `Authorization` | `Bearer {jwt_token}` | Yes |
| `X-Tenant-Id` | `{tenant_id}` | Yes |

**Request Body Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "brand_guidelines_id": {
      "type": "string",
      "description": "Reference to brand guidelines document (optional)"
    }
  }
}
```

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "generation_id": { "type": "string" },
    "brand_score": {
      "type": "number",
      "minimum": 0,
      "maximum": 10
    },
    "status": {
      "type": "string",
      "enum": ["excellent", "acceptable", "needs_work", "rejected"]
    },
    "categories": {
      "type": "object",
      "properties": {
        "color_palette_compliance": {
          "type": "object",
          "properties": {
            "score": { "type": "number", "maximum": 2.0 },
            "feedback": { "type": "string" }
          }
        },
        "typography_compliance": {
          "type": "object",
          "properties": {
            "score": { "type": "number", "maximum": 1.5 },
            "feedback": { "type": "string" }
          }
        },
        "logo_usage": {
          "type": "object",
          "properties": {
            "score": { "type": "number", "maximum": 1.5 },
            "feedback": { "type": "string" }
          }
        },
        "layout_spacing": {
          "type": "object",
          "properties": {
            "score": { "type": "number", "maximum": 1.5 },
            "feedback": { "type": "string" }
          }
        },
        "component_style_consistency": {
          "type": "object",
          "properties": {
            "score": { "type": "number", "maximum": 1.5 },
            "feedback": { "type": "string" }
          }
        },
        "imagery_iconography": {
          "type": "object",
          "properties": {
            "score": { "type": "number", "maximum": 1.0 },
            "feedback": { "type": "string" }
          }
        },
        "content_tone_voice": {
          "type": "object",
          "properties": {
            "score": { "type": "number", "maximum": 1.0 },
            "feedback": { "type": "string" }
          }
        }
      }
    },
    "recommendations": {
      "type": "array",
      "items": { "type": "string" }
    },
    "blocking_issues": {
      "type": "array",
      "items": { "type": "string" }
    },
    "deployment_allowed": { "type": "boolean" }
  }
}
```

**Scoring Thresholds**:
| Score Range | Status | Action |
|-------------|--------|--------|
| 9.0 - 10.0 | Excellent | Auto-approve for deployment |
| 8.0 - 8.9 | Acceptable | Approve with recommendations |
| 6.0 - 7.9 | Needs Work | Block deployment, provide feedback |
| 0.0 - 5.9 | Rejected | Regeneration required |

**Error Responses**:
| HTTP Status | Error Code | Description |
|-------------|------------|-------------|
| 200 (warning) | VAL-004 | Brand guidelines not configured |
| 422 | VAL-001 | Brand score below threshold |

---

### 4.2 POST `/v1/sites/{tenant_id}/generation/{generation_id}/validate/security`

**Description**: Scan generated code for security vulnerabilities.

**User Stories**: US-006

**AI Agent**: Security Validator Agent (Lambda SecurityScanner)

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "generation_id": { "type": "string" },
    "security_status": {
      "type": "string",
      "enum": ["passed", "failed", "warning"]
    },
    "vulnerabilities": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "type": {
            "type": "string",
            "enum": ["xss", "injection", "unsafe_resource", "other"]
          },
          "severity": {
            "type": "string",
            "enum": ["critical", "high", "medium", "low"]
          },
          "location": {
            "type": "string",
            "description": "File/section reference"
          },
          "description": { "type": "string" },
          "remediation": { "type": "string" }
        }
      }
    },
    "blocked_patterns": {
      "type": "array",
      "items": { "type": "string" }
    },
    "audit_id": {
      "type": "string",
      "description": "For compliance tracking"
    }
  }
}
```

**Error Responses**:
| HTTP Status | Error Code | Description |
|-------------|------------|-------------|
| 422 | VAL-002 | Security vulnerability detected |
| 422 | VAL-003 | Inappropriate content generated |

---

### 4.3 POST `/v1/sites/{tenant_id}/generation/{generation_id}/validate/performance`

**Description**: Run performance validation against generated content.

**User Stories**: US-008

**AI Agent**: Website Validator Agent

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "generation_id": { "type": "string" },
    "performance_status": {
      "type": "string",
      "enum": ["passed", "failed", "warning"]
    },
    "metrics": {
      "type": "object",
      "properties": {
        "page_load_time_ms": { "type": "integer" },
        "first_contentful_paint_ms": { "type": "integer" },
        "largest_contentful_paint_ms": { "type": "integer" },
        "first_input_delay_ms": { "type": "integer" },
        "cumulative_layout_shift": { "type": "number" },
        "total_page_size_kb": { "type": "integer" }
      }
    },
    "thresholds": {
      "type": "object",
      "properties": {
        "page_load_time_ms": { "type": "integer", "default": 3000 },
        "largest_contentful_paint_ms": { "type": "integer", "default": 2500 },
        "first_input_delay_ms": { "type": "integer", "default": 100 },
        "cumulative_layout_shift": { "type": "number", "default": 0.1 }
      }
    },
    "recommendations": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "issue": { "type": "string" },
          "impact": { "type": "string", "enum": ["high", "medium", "low"] },
          "suggestion": { "type": "string" }
        }
      }
    },
    "production_ready": { "type": "boolean" }
  }
}
```

**Performance Thresholds**:
| Metric | Threshold | Action if Failed |
|--------|-----------|------------------|
| Page Load Time | < 3000ms | Block for production |
| LCP | < 2500ms | Warning |
| FID | < 100ms | Warning |
| CLS | < 0.1 | Warning |

---

## 5. Deployment API Endpoints

### 5.1 POST `/v1/sites/{tenant_id}/deployments`

**Description**: Create a new deployment to staging or production.

**User Stories**: US-007

**AI Agents**: Site Packager, Site Stager Agent, Site Deployer Agent

**Request Body Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "generation_id": {
      "type": "string",
      "description": "Generation to deploy"
    },
    "environment": {
      "type": "string",
      "enum": ["staging", "production"]
    },
    "custom_domain": {
      "type": "string",
      "description": "Custom domain (optional)"
    },
    "dns_config": {
      "type": "object",
      "properties": {
        "subdomain": { "type": "string" },
        "hosted_zone_id": { "type": "string" }
      }
    }
  },
  "required": ["generation_id", "environment"]
}
```

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "deployment_id": { "type": "string" },
    "status": {
      "type": "string",
      "enum": ["queued", "in_progress", "completed", "failed"]
    },
    "environment": { "type": "string" },
    "url": { "type": "string", "format": "uri" },
    "dns_status": {
      "type": "string",
      "enum": ["pending", "configured", "failed"]
    },
    "version": { "type": "integer" },
    "created_at": { "type": "string", "format": "date-time" },
    "estimated_completion": { "type": "string", "format": "date-time" }
  }
}
```

**Prerequisites for Deployment**:
| Check | Staging | Production |
|-------|---------|------------|
| Brand Score >= 8.0 | Required | Required |
| Security Scan Pass | Required | Required |
| Performance < 3s | Warning | Required |

**Error Responses**:
| HTTP Status | Error Code | Description |
|-------------|------------|-------------|
| 400 | DEP-001 | Prerequisites not met |
| 500 | DEP-002 | S3 deployment failed |
| 500 | DEP-003 | CloudFront invalidation failed |
| 500 | DEP-004 | DNS update failed |
| 202 | DEP-006 | Queue congestion (accepted, delayed) |

---

### 5.2 GET `/v1/sites/{tenant_id}/deployments`

**Description**: List deployment history for tenant.

**Query Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| `environment` | string | Filter by environment |
| `status` | string | Filter by status |
| `limit` | integer | Max results (default 20) |
| `offset` | integer | Pagination offset |

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "deployments": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "deployment_id": { "type": "string" },
          "project_id": { "type": "string" },
          "environment": { "type": "string" },
          "status": { "type": "string" },
          "url": { "type": "string" },
          "version": { "type": "integer" },
          "created_at": { "type": "string", "format": "date-time" }
        }
      }
    },
    "total": { "type": "integer" },
    "limit": { "type": "integer" },
    "offset": { "type": "integer" }
  }
}
```

---

### 5.3 GET `/v1/sites/{tenant_id}/deployments/{deployment_id}`

**Description**: Get deployment status and details.

**Response Schema**: Same as single deployment in list response.

---

### 5.4 POST `/v1/sites/{tenant_id}/deployments/{deployment_id}/performance`

**Description**: Run performance tests on deployed site.

**User Stories**: US-008

**Response Schema**: Same as validation/performance endpoint.

---

### 5.5 GET `/v1/sites/{tenant_id}/dns`

**Description**: Get DNS settings for tenant.

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "tenant_id": { "type": "string" },
    "hosted_zone_id": { "type": "string" },
    "domains": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "domain": { "type": "string" },
          "type": { "type": "string", "enum": ["A", "CNAME", "ALIAS"] },
          "target": { "type": "string" },
          "status": { "type": "string", "enum": ["active", "pending", "failed"] }
        }
      }
    }
  }
}
```

---

### 5.6 PUT `/v1/sites/{tenant_id}/dns`

**Description**: Update DNS settings.

**Authorization**: Admin only

**Request Body Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "domain": {
      "type": "string",
      "description": "Domain to configure"
    },
    "subdomain": {
      "type": "string",
      "description": "Subdomain (optional)"
    },
    "site_id": {
      "type": "string",
      "description": "Site to point to"
    }
  },
  "required": ["domain", "site_id"]
}
```

---

## 6. Templates API Endpoints

### 6.1 GET `/v1/sites/{tenant_id}/templates`

**Description**: List available design templates.

**User Stories**: US-002

**Query Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| `type` | string | Filter by type (landing, blog, newsletter) |
| `brand_compliant` | boolean | Only brand-compliant templates |

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "templates": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "template_id": { "type": "string" },
          "name": { "type": "string" },
          "type": { "type": "string" },
          "description": { "type": "string" },
          "preview_url": { "type": "string", "format": "uri" },
          "thumbnail_url": { "type": "string", "format": "uri" },
          "brand_compliant": { "type": "boolean" },
          "components": {
            "type": "array",
            "items": { "type": "string" }
          }
        }
      }
    },
    "brand_assets": {
      "type": "object",
      "properties": {
        "logo_url": { "type": "string" },
        "color_palette": {
          "type": "object",
          "properties": {
            "primary": { "type": "string" },
            "secondary": { "type": "string" },
            "accent": { "type": "string" }
          }
        },
        "typography": {
          "type": "object",
          "properties": {
            "heading_font": { "type": "string" },
            "body_font": { "type": "string" }
          }
        }
      }
    }
  }
}
```

**Performance Requirements**:
- Response time: < 100ms

---

### 6.2 GET `/v1/sites/{tenant_id}/templates/{template_id}`

**Description**: Get template details.

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "template_id": { "type": "string" },
    "tenant_id": { "type": "string" },
    "category": {
      "type": "string",
      "enum": ["LANDING_PAGE", "BLOG", "NEWSLETTER", "COMPONENT"]
    },
    "name": { "type": "string" },
    "description": { "type": "string" },
    "s3_uri": { "type": "string" },
    "thumbnail_uri": { "type": "string" },
    "components": {
      "type": "array",
      "items": { "type": "string" }
    },
    "brand_compatible": { "type": "boolean" },
    "html": { "type": "string" },
    "css": { "type": "string" },
    "created_at": { "type": "string", "format": "date-time" }
  }
}
```

---

## 7. Analytics API Endpoints

### 7.1 GET `/v1/sites/{tenant_id}/analytics/components`

**Description**: Track which components perform best.

**User Stories**: US-009

**Query Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| `start_date` | string | Start of date range (ISO 8601) |
| `end_date` | string | End of date range (ISO 8601) |
| `metric` | string | Metric type (clicks, conversions, engagement) |

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "tenant_id": { "type": "string" },
    "period": {
      "type": "object",
      "properties": {
        "start": { "type": "string", "format": "date-time" },
        "end": { "type": "string", "format": "date-time" }
      }
    },
    "components": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "component_type": { "type": "string" },
          "usage_count": { "type": "integer" },
          "click_rate": { "type": "number" },
          "conversion_rate": { "type": "number" },
          "engagement_score": { "type": "number" }
        }
      }
    }
  }
}
```

---

### 7.2 GET `/v1/sites/{tenant_id}/analytics/costs`

**Description**: See cost and performance metrics for AI generation.

**User Stories**: US-010

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "tenant_id": { "type": "string" },
    "period": {
      "type": "object",
      "properties": {
        "start": { "type": "string", "format": "date-time" },
        "end": { "type": "string", "format": "date-time" }
      }
    },
    "summary": {
      "type": "object",
      "properties": {
        "total_generations": { "type": "integer" },
        "total_tokens": { "type": "integer" },
        "total_images": { "type": "integer" },
        "estimated_cost_usd": { "type": "number" }
      }
    },
    "by_agent": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "agent_type": { "type": "string" },
          "invocations": { "type": "integer" },
          "tokens_used": { "type": "integer" },
          "cost_usd": { "type": "number" },
          "avg_latency_ms": { "type": "integer" }
        }
      }
    }
  }
}
```

---

## 8. Tenant Management API Endpoints

### 8.1 GET `/v1/tenants/{tenant_id}`

**Description**: Get tenant/organisation details.

**User Stories**: US-015

**Authorization**: Org Admin+

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "tenant_id": { "type": "string" },
    "org_id": { "type": "string" },
    "name": { "type": "string" },
    "destination_email": { "type": "string", "format": "email" },
    "hierarchy": {
      "type": "object",
      "properties": {
        "divisions": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "division_id": { "type": "string" },
              "name": { "type": "string" },
              "groups": { "type": "array" }
            }
          }
        }
      }
    },
    "status": { "type": "string", "enum": ["ACTIVE", "SUSPENDED", "DELETED"] },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  }
}
```

---

### 8.2 PUT `/v1/tenants/{tenant_id}`

**Description**: Update tenant details.

**Authorization**: Admin only

**Request Body Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "name": { "type": "string" },
    "destination_email": { "type": "string", "format": "email" }
  }
}
```

---

### 8.3 POST `/v1/user/registration`

**Description**: Register new user/organisation.

**Authorization**: Public (no auth required)

**Request Body Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "email": {
      "type": "string",
      "format": "email",
      "description": "User email (mandatory)"
    },
    "organization_name": {
      "type": "string",
      "description": "Organisation name (mandatory)"
    },
    "password": {
      "type": "string",
      "minLength": 8
    },
    "destination_email": {
      "type": "string",
      "format": "email",
      "description": "Form submission email (mandatory)"
    }
  },
  "required": ["email", "organization_name", "password", "destination_email"]
}
```

---

### 8.4 POST `/v1/user/invitation`

**Description**: Invite user to organisation.

**User Stories**: US-016

**Authorization**: Admin, Team Lead

**Request Body Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "email": {
      "type": "string",
      "format": "email"
    },
    "team_id": { "type": "string" },
    "role": {
      "type": "string",
      "enum": ["ADMIN", "EDITOR", "VIEWER"]
    }
  },
  "required": ["email", "team_id", "role"]
}
```

---

### 8.5 GET `/v1/tenants/{tenant_id}/teams/{team_id}/members`

**Description**: List team members.

**User Stories**: US-017

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "team_id": { "type": "string" },
    "members": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "user_id": { "type": "string" },
          "email": { "type": "string" },
          "role": { "type": "string" },
          "status": { "type": "string", "enum": ["PENDING", "ACCEPTED", "EXPIRED"] },
          "joined_at": { "type": "string", "format": "date-time" }
        }
      }
    }
  }
}
```

---

### 8.6 POST `/v1/tenants/{tenant_id}/teams/{team_id}/members`

**Description**: Add team member.

**Authorization**: Team Lead+

**Request Body Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "user_id": { "type": "string" },
    "role": { "type": "string", "enum": ["ADMIN", "EDITOR", "VIEWER"] }
  },
  "required": ["user_id", "role"]
}
```

---

### 8.7 GET `/v1/user/{tenant}/teams`

**Description**: Get teams user belongs to.

**User Stories**: US-018

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "user_id": { "type": "string" },
    "teams": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "team_id": { "type": "string" },
          "team_name": { "type": "string" },
          "role": { "type": "string" },
          "joined_at": { "type": "string", "format": "date-time" }
        }
      }
    }
  }
}
```

---

## 9. Migration API Endpoints

### 9.1 POST `/v1/migrations/{tenant_id}`

**Description**: Start legacy site migration.

**User Stories**: US-019, US-020

**Request Body Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "source_type": {
      "type": "string",
      "enum": ["WORDPRESS", "STATIC_HTML", "SQUARESPACE"]
    },
    "source_url": {
      "type": "string",
      "format": "uri"
    },
    "options": {
      "type": "object",
      "properties": {
        "include_images": { "type": "boolean", "default": true },
        "include_styles": { "type": "boolean", "default": true },
        "sanitize_html": { "type": "boolean", "default": true }
      }
    }
  },
  "required": ["source_type", "source_url"]
}
```

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "migration_id": { "type": "string" },
    "status": {
      "type": "string",
      "enum": ["QUEUED", "EXTRACTING", "PROCESSING", "DEPLOYING", "COMPLETED", "FAILED"]
    },
    "created_at": { "type": "string", "format": "date-time" }
  }
}
```

---

### 9.2 GET `/v1/migrations/{tenant_id}`

**Description**: List migrations.

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "migrations": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "migration_id": { "type": "string" },
          "source_type": { "type": "string" },
          "source_url": { "type": "string" },
          "status": { "type": "string" },
          "progress_percentage": { "type": "integer" },
          "created_at": { "type": "string", "format": "date-time" }
        }
      }
    }
  }
}
```

---

### 9.3 GET `/v1/migrations/{tenant_id}/{migration_id}`

**Description**: Get migration status and details.

**User Stories**: US-021

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "migration_id": { "type": "string" },
    "tenant_id": { "type": "string" },
    "source_type": { "type": "string" },
    "source_url": { "type": "string" },
    "status": { "type": "string" },
    "progress_percentage": { "type": "integer", "minimum": 0, "maximum": 100 },
    "extracted_pages": { "type": "integer" },
    "migrated_pages": { "type": "integer" },
    "error_log": {
      "type": "array",
      "items": { "type": "string" }
    },
    "created_at": { "type": "string", "format": "date-time" },
    "completed_at": { "type": "string", "format": "date-time" }
  }
}
```

---

## 10. Prompt Management API Endpoints

### 10.1 GET `/v1/prompts/{tenant_id}`

**Description**: List available prompts.

**Response Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "prompts": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "prompt_id": { "type": "string" },
          "prompt_name": { "type": "string" },
          "category": { "type": "string", "enum": ["SYSTEM", "TEMPLATE", "CUSTOM"] },
          "agent_type": { "type": "string" },
          "version": { "type": "string" }
        }
      }
    }
  }
}
```

---

### 10.2 POST `/v1/prompts/{tenant_id}`

**Description**: Create custom prompt.

**Request Body Schema**:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "prompt_name": { "type": "string" },
    "agent_type": { "type": "string" },
    "prompt_template": {
      "type": "string",
      "description": "Prompt text with {{variable}} placeholders"
    },
    "variables": {
      "type": "array",
      "items": { "type": "string" }
    }
  },
  "required": ["prompt_name", "agent_type", "prompt_template"]
}
```

---

## 11. Data Models

### 11.1 DynamoDB Table Schemas

#### 11.1.1 Tenants Table

```
Table Name: bbws-sitebuilder-tenants-{env}
Capacity Mode: On-Demand
Global Tables: Enabled (af-south-1, eu-west-1)

Primary Key:
  - PK: tenant_id (String)
  - SK: entity_type#entity_id (String)

GSI-1:
  - PK: org_id (String)
  - SK: hierarchy_path (String)

Attributes:
  - tenant_id: String (Unique tenant identifier)
  - org_id: String (Organisation ID)
  - entity_type: String (TENANT | DIVISION | GROUP | TEAM)
  - entity_id: String (Entity unique identifier)
  - name: String (Entity display name)
  - hierarchy_path: String (Full path org/division/group/team)
  - destination_email: String (Form submission email - required)
  - created_at: String (ISO 8601 timestamp)
  - updated_at: String (ISO 8601 timestamp)
  - status: String (ACTIVE | SUSPENDED | DELETED)
```

#### 11.1.2 Users Table

```
Table Name: bbws-sitebuilder-users-{env}
Capacity Mode: On-Demand
Global Tables: Enabled (af-south-1, eu-west-1)

Primary Key:
  - PK: user_id (String)
  - SK: tenant_id#team_id (String)

GSI-1 (Email Lookup):
  - PK: email (String)
  - SK: user_id (String)

GSI-2 (Team Members):
  - PK: tenant_id#team_id (String)
  - SK: user_id (String)

Attributes:
  - user_id: String (Cognito sub)
  - email: String (User email - required/mandatory)
  - tenant_id: String (Associated tenant)
  - team_ids: List<String> (List of team memberships)
  - role: String (ADMIN | EDITOR | VIEWER)
  - cognito_username: String
  - invited_by: String (User ID of inviter)
  - invitation_status: String (PENDING | ACCEPTED | EXPIRED)
  - created_at: String (ISO 8601 timestamp)
  - last_login: String (ISO 8601 timestamp)
```

#### 11.1.3 Sites Table

```
Table Name: bbws-sitebuilder-sites-{env}
Capacity Mode: On-Demand
Global Tables: Enabled (af-south-1, eu-west-1)

Primary Key:
  - PK: tenant_id (String)
  - SK: site_id (String)

GSI-1 (By Status):
  - PK: tenant_id (String)
  - SK: status#created_at (String)

Attributes:
  - tenant_id: String (Owner tenant)
  - site_id: String (Unique site identifier)
  - name: String (Site display name)
  - status: String (DRAFT | STAGING | DEV | SIT | PROD)
  - template_id: String (Base template used)
  - generation_id: String (Associated generation job)
  - version: String (Semantic version)
  - s3_staging_uri: String (Staging bucket path)
  - s3_hosting_uri: String (Production hosting path)
  - cloudfront_distribution_id: String (CDN distribution)
  - domain: String (Custom domain - optional)
  - brand_score: Number (Last validation score 0-10)
  - created_at: String (ISO 8601 timestamp)
  - updated_at: String (ISO 8601 timestamp)
  - created_by: String (User ID)
```

#### 11.1.4 Generation Table (State Management)

```
Table Name: bbws-sitebuilder-generation-{env}
Capacity Mode: On-Demand
Global Tables: Enabled (af-south-1, eu-west-1)

Primary Key:
  - PK: tenant_id (String)
  - SK: generation_id (String)

GSI-1 (Active Jobs):
  - PK: status (String)
  - SK: created_at (String)

Attributes:
  - tenant_id: String (Owner tenant)
  - generation_id: String (Unique job identifier)
  - site_id: String (Target site)
  - status: String (QUEUED | PROCESSING | VALIDATING | COMPLETED | FAILED | TIMEOUT)
  - prompt: String (Original user prompt)
  - refined_prompt: String (AI-processed prompt)
  - agent_states: Map (Map of agent execution states)
  - brand_score: Number (Validation result)
  - security_scan_result: String (PASS | FAIL | PENDING)
  - error_message: String (Failure details if any)
  - retry_count: Number (Number of retries)
  - created_at: String (ISO 8601 timestamp)
  - started_at: String (ISO 8601 timestamp)
  - completed_at: String (ISO 8601 timestamp)
  - ttl: Number (Expiration time for cleanup)
```

#### 11.1.5 Prompts Table

```
Table Name: bbws-sitebuilder-prompts-{env}
Capacity Mode: On-Demand
Global Tables: Enabled (af-south-1, eu-west-1)

Primary Key:
  - PK: tenant_id (String) - SYSTEM for system prompts
  - SK: prompt_id (String)

GSI-1 (System Prompts):
  - PK: category (String)
  - SK: prompt_name (String)

Attributes:
  - tenant_id: String (SYSTEM | tenant_id)
  - prompt_id: String (Unique identifier)
  - prompt_name: String (Human-readable name)
  - category: String (SYSTEM | TEMPLATE | CUSTOM)
  - agent_type: String (Target agent)
  - prompt_template: String (Prompt text with placeholders)
  - variables: List<String> (List of expected variables)
  - version: String (Prompt version)
  - created_at: String (ISO 8601 timestamp)
  - updated_at: String (ISO 8601 timestamp)
```

#### 11.1.6 Migrations Table

```
Table Name: bbws-sitebuilder-migrations-{env}
Capacity Mode: On-Demand
Global Tables: Enabled (af-south-1, eu-west-1)

Primary Key:
  - PK: tenant_id (String)
  - SK: migration_id (String)

Attributes:
  - tenant_id: String (Owner tenant)
  - migration_id: String (Unique job identifier)
  - source_type: String (WORDPRESS | STATIC_HTML | SQUARESPACE)
  - source_url: String (Original site URL)
  - status: String (QUEUED | EXTRACTING | PROCESSING | DEPLOYING | COMPLETED | FAILED)
  - progress_percentage: Number (0-100)
  - extracted_pages: Number (Count of pages found)
  - migrated_pages: Number (Count of pages processed)
  - error_log: List<String> (List of errors)
  - created_at: String (ISO 8601 timestamp)
  - completed_at: String (ISO 8601 timestamp)
```

#### 11.1.7 Templates Table

```
Table Name: bbws-sitebuilder-templates-{env}
Capacity Mode: On-Demand
Global Tables: Enabled (af-south-1, eu-west-1)

Primary Key:
  - PK: category (String)
  - SK: template_id (String)

GSI-1 (By Tenant):
  - PK: tenant_id (String)
  - SK: template_id (String)

Attributes:
  - template_id: String (Unique identifier)
  - tenant_id: String (SYSTEM | tenant_id)
  - category: String (LANDING_PAGE | BLOG | NEWSLETTER | COMPONENT)
  - name: String (Template display name)
  - description: String (Template description)
  - s3_uri: String (Template assets location)
  - thumbnail_uri: String (Preview image)
  - components: List<String> (List of component IDs)
  - brand_compatible: Boolean
  - created_at: String (ISO 8601 timestamp)
```

### 11.2 S3 Object Structures

#### 11.2.1 Design Assets Bucket

```
Bucket Name: bbws-design-assets-{env}-{region}
Public Access: BLOCKED
Versioning: Enabled
Encryption: SSE-S3
CRR: Enabled to eu-west-1

Structure:
  /{tenant_id}/
    /logos/
      /{logo_id}.png
      /{logo_id}.svg
    /backgrounds/
      /{image_id}.png
      /{image_id}.webp
    /brand/
      /colors.json
      /fonts/
        /{font_name}.woff2
      /guidelines.pdf
    /components/
      /{component_id}/
        /index.html
        /styles.css
```

#### 11.2.2 Generated Pages Bucket

```
Bucket Name: bbws-generated-pages-{env}-{region}
Public Access: BLOCKED
Versioning: Enabled
Encryption: SSE-S3
CRR: Enabled to eu-west-1
Lifecycle: Delete after 30 days

Structure:
  /{tenant_id}/
    /{site_id}/
      /{version}/
        /index.html
        /assets/
          /css/
            /main.css
          /js/
            /main.js
          /images/
            /hero.webp
        /manifest.json
```

#### 11.2.3 Site Hosting Bucket

```
Bucket Name: bbws-site-hosting-{env}-{region}
Public Access: BLOCKED (CloudFront OAI only)
Versioning: Enabled
Encryption: SSE-S3

Structure:
  /{tenant_id}/
    /{site_id}/
      /index.html
      /assets/
        /css/
        /js/
        /images/
      /robots.txt
      /sitemap.xml
```

#### 11.2.4 Staging Bucket

```
Bucket Name: bbws-staging-{env}-{region}
Public Access: BLOCKED
Versioning: Disabled
Encryption: SSE-S3
Lifecycle: Delete after 7 days
Access: Pre-signed URLs only

Structure:
  /{tenant_id}/
    /{site_id}/
      /{generation_id}/
        /index.html
        /assets/
```

#### 11.2.5 Prompt Library Bucket

```
Bucket Name: bbws-prompts-{env}-{region}
Public Access: BLOCKED
Versioning: Enabled
Encryption: SSE-S3
CRR: Enabled to eu-west-1

Structure:
  /system/
    /agents/
      /outliner.txt
      /logo-creator.txt
      /theme-selector.txt
      /layout.txt
      /blogger.txt
      /newsletter.txt
      /brand-scorer.txt
      /security-scanner.txt
  /{tenant_id}/
    /custom/
      /{prompt_id}.txt
```

---

## 12. Error Response Format

### 12.1 Standard Error Response Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "code": {
      "type": "string",
      "description": "Machine-readable error code (e.g., GEN-001)"
    },
    "message": {
      "type": "string",
      "description": "Human-readable error message"
    },
    "details": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "field": {
            "type": "string",
            "description": "Field with error (for validation errors)"
          },
          "reason": {
            "type": "string",
            "description": "Detailed reason for error"
          }
        }
      }
    },
    "request_id": {
      "type": "string",
      "description": "Unique request ID for support/debugging"
    },
    "retry_after": {
      "type": "integer",
      "description": "Seconds to wait before retry (for rate limiting)"
    }
  },
  "required": ["code", "message", "request_id"]
}
```

### 12.2 Error Code Categories

#### 12.2.1 Generation Errors (GEN-xxx)

| Code | HTTP Status | Description | Retry |
|------|-------------|-------------|-------|
| GEN-001 | 503 | AI service unavailable (Bedrock) | Yes (exponential backoff) |
| GEN-002 | 408 | Request timeout (TTLT exceeded) | Yes |
| GEN-003 | 400 | Invalid prompt (content policy violation) | No |
| GEN-004 | 422 | Ambiguous requirements | No |
| GEN-005 | 404 | Template not found | No |
| GEN-006 | 429 | Generation quota exceeded | Yes (after cooldown) |

#### 12.2.2 Validation Errors (VAL-xxx)

| Code | HTTP Status | Description | Retry |
|------|-------------|-------------|-------|
| VAL-001 | 422 | Brand score below threshold | No |
| VAL-002 | 422 | Security vulnerability detected | No |
| VAL-003 | 422 | Inappropriate content generated | No |
| VAL-004 | 200 | Brand guidelines not configured (warning) | No |
| VAL-005 | 422 | Accessibility violation (WCAG) | No |

#### 12.2.3 Deployment Errors (DEP-xxx)

| Code | HTTP Status | Description | Retry |
|------|-------------|-------------|-------|
| DEP-001 | 400 | Prerequisites not met | No |
| DEP-002 | 500 | S3 deployment failed | Yes |
| DEP-003 | 500 | CloudFront invalidation failed | Yes |
| DEP-004 | 500 | DNS update failed | Yes |
| DEP-005 | 422 | Performance threshold failed | No |
| DEP-006 | 202 | Queue congestion (accepted, delayed) | Auto |

#### 12.2.4 Agent Errors (AGT-xxx)

| Code | HTTP Status | Description | Retry |
|------|-------------|-------------|-------|
| AGT-001 | 503 | Stable Diffusion unavailable | Yes |
| AGT-002 | 422 | Image generation blocked (content) | No |
| AGT-003 | 500 | Newsletter SES integration failed | Yes |
| AGT-004 | 422 | Blog generation off-topic | No |

#### 12.2.5 Authentication Errors (AUTH-xxx)

| Code | HTTP Status | Description | Retry |
|------|-------------|-------------|-------|
| AUTH-001 | 401 | Invalid/expired JWT | No |
| AUTH-002 | 403 | Insufficient permissions | No |
| AUTH-003 | 404 | Tenant not found | No |
| AUTH-004 | 403 | Cross-tenant access attempt | No |
| AUTH-005 | 400 | Invitation expired | No |

### 12.3 Example Error Response

```json
{
  "code": "GEN-001",
  "message": "AI service temporarily unavailable. Please try again in a few moments.",
  "details": [
    {
      "reason": "Bedrock throttling limit reached"
    }
  ],
  "request_id": "req_abc123def456",
  "retry_after": 30
}
```

---

## 13. Authentication

### 13.1 JWT Token Structure

```json
{
  "sub": "user_id_from_cognito",
  "email": "user@example.com",
  "cognito:groups": ["Admin", "Editor"],
  "custom:tenant_id": "tenant_123",
  "custom:org_id": "org_456",
  "exp": 1736985600,
  "iat": 1736982000,
  "iss": "https://cognito-idp.{region}.amazonaws.com/{user_pool_id}",
  "aud": "client_id"
}
```

### 13.2 Required Headers

| Header | Value | Required | Description |
|--------|-------|----------|-------------|
| `Authorization` | `Bearer {jwt_token}` | Yes | JWT access token from Cognito |
| `X-Tenant-Id` | `{tenant_id}` | Yes | Multi-tenant isolation header |
| `Content-Type` | `application/json` | Yes | Request body format |
| `Accept` | `application/json` or `text/event-stream` | Conditional | Response format |

### 13.3 Tenant Isolation Rules

1. **JWT Validation**: Backend validates `X-Tenant-Id` header against `custom:tenant_id` claim in JWT
2. **Data Partitioning**: All DynamoDB queries include tenant_id in partition key
3. **S3 Prefix**: All S3 objects prefixed with `/{tenant_id}/`
4. **Cross-Tenant Block**: Requests attempting to access other tenant data return 403

### 13.4 Role Hierarchy

| Role | Permissions |
|------|-------------|
| **Admin** | Full CRUD, invite users, manage teams, deploy to production |
| **Team Lead** | CRUD within team, invite to team, deploy to staging |
| **Editor** | Create/edit sites, view team data |
| **Viewer** | Read-only access to team resources |

### 13.5 Token Refresh

- Tokens should be refreshed before expiry (at 75% of lifetime)
- Refresh is handled by Cognito SDK
- On refresh failure, redirect to login

---

## 14. SSE Streaming Protocol

### 14.1 Event Types

| Event | Data Format | Purpose |
|-------|-------------|---------|
| `message` | Plain text chunk | AI response token stream |
| `generation_start` | `{ "id": "string" }` | Generation job started |
| `generation_progress` | `{ "progress": number }` | Progress percentage (0-100) |
| `generation_complete` | `GenerationResponse` | Final generated content |
| `error` | `{ "code": "string", "message": "string" }` | Error during generation |

### 14.2 Stream Format

```
event: generation_start
data: {"id": "gen_abc123"}

event: message
data: Creating hero section...

event: generation_progress
data: {"progress": 25}

event: message
data: <section class="hero">...

event: generation_progress
data: {"progress": 50}

event: message
data: Adding features grid...

event: generation_progress
data: {"progress": 75}

event: generation_complete
data: {"id": "gen_abc123", "html": "<!DOCTYPE html>...", "css": "...", "version": 1, "brandScore": 8.5}
```

### 14.3 Connection Headers

**Request**:
```http
POST /v1/sites/{tenant_id}/generation HTTP/1.1
Host: api.dev.kimmyai.io
Authorization: Bearer {jwt_token}
X-Tenant-Id: {tenant_id}
Content-Type: application/json
Accept: text/event-stream
Cache-Control: no-cache
Connection: keep-alive

{"prompt": "Create a landing page..."}
```

**Response**:
```http
HTTP/1.1 200 OK
Content-Type: text/event-stream
Cache-Control: no-cache
Connection: keep-alive
Transfer-Encoding: chunked
X-Request-Id: req_abc123

event: generation_start
data: {"id": "gen_abc123"}
...
```

### 14.4 Client Implementation (TypeScript)

```typescript
async function streamGeneration(tenantId: string, prompt: string): Promise<void> {
  const abortController = new AbortController();

  const response = await fetch(`${API_BASE}/v1/sites/${tenantId}/generation`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${jwt_token}`,
      'X-Tenant-Id': tenantId,
      'Accept': 'text/event-stream'
    },
    body: JSON.stringify({ prompt }),
    signal: abortController.signal
  });

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }

  const reader = response.body?.getReader();
  const decoder = new TextDecoder();

  while (reader) {
    const { done, value } = await reader.read();
    if (done) break;

    const chunk = decoder.decode(value);
    const lines = chunk.split('\n');

    for (const line of lines) {
      if (line.startsWith('event:')) {
        const eventType = line.slice(7).trim();
        // Handle event type
      } else if (line.startsWith('data:')) {
        const data = line.slice(6);
        // Process data based on event type
      }
    }
  }
}
```

### 14.5 Error Handling

| Scenario | Handling |
|----------|----------|
| Network disconnection | Retry up to 2 times with exponential backoff |
| Timeout (60s) | Abort and show error to user |
| Server error | Parse error event and display message |
| Abort by user | Clean up resources, no retry |

### 14.6 Performance Targets

| Metric | Target |
|--------|--------|
| TTFT (Time To First Token) | < 2 seconds |
| TTLT (Time To Last Token) | < 60 seconds |
| Full generation | 10-15 seconds typical |

---

## 15. Rate Limits

### 15.1 Per-User Limits

| Operation | Rate Limit | Window |
|-----------|------------|--------|
| Generation requests | 10 per minute | Per user |
| Agent requests | 20 per minute | Per user |
| Validation requests | 30 per minute | Per user |
| General API calls | 100 per minute | Per user |

### 15.2 Per-Tenant Limits

| Operation | Rate Limit | Window |
|-----------|------------|--------|
| File uploads | 30 per hour | Per tenant |
| Deployments | 5 per hour | Per tenant |
| Monthly generations | 10,000 | Per tenant |

---

## 16. Summary

### 16.1 API Statistics

| Category | Count |
|----------|-------|
| Generation Endpoints | 5 |
| Agent Endpoints | 7 |
| Validation Endpoints | 3 |
| Deployment Endpoints | 6 |
| Template Endpoints | 2 |
| Analytics Endpoints | 2 |
| Tenant Management Endpoints | 7 |
| Migration Endpoints | 3 |
| Prompt Endpoints | 2 |
| **Total Endpoints** | **37** |

### 16.2 DynamoDB Tables

| Table | Purpose |
|-------|---------|
| Tenants | Organisation hierarchy |
| Users | User profiles and team membership |
| Sites | Site metadata |
| Generation | Generation job state |
| Prompts | Prompt library |
| Migrations | Migration job tracking |
| Templates | Design templates |
| **Total Tables** | **7** |

### 16.3 S3 Buckets

| Bucket | Purpose |
|--------|---------|
| Design Assets | Brand assets, logos, images |
| Generated Pages | Generated HTML/CSS/JS |
| Site Hosting | Production hosting |
| Staging | Preview sites |
| Prompts | System and custom prompts |
| **Total Buckets** | **5** |

---

**End of Document**

---

**Document History**:
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-15 | Worker 4 | Initial comprehensive API contracts |
