# Blog Platform SDLC Process

**Process Type**: Blog/Content Management System
**Parent Process**: [BBWS SDLC v1](../bbws-sdlc-v1/main-plan.md)

---

## Overview

This process is for creating blog platforms with content management, commenting, and SEO optimization.

## Applicable Stages

### Backend (Content API)
| Stage | Name | Required |
|-------|------|----------|
| 1 | Requirements | Yes |
| 2 | HLD | Yes |
| 3 | LLD | Yes |
| 4 | API Tests | Yes |
| 5 | API Implementation | Yes |
| 7-9 | Infrastructure | Yes |

### Frontend (Blog UI)
| Stage | Name | Required |
|-------|------|----------|
| F1 | UI/UX Design | Yes |
| F2 | Prototype | Yes |
| F3 | React Implementation | Yes |
| F4 | Testing | Yes |
| F5 | API Integration | Yes |
| F6 | Deployment | Yes |

## Technology Stack

- **Content API**: Lambda + DynamoDB
- **Frontend**: React/Next.js
- **Search**: OpenSearch (optional)
- **CDN**: CloudFront
- **Images**: S3

## Components

### Content API
```
GET  /posts                 # List posts
GET  /posts/{slug}          # Get post by slug
POST /posts                 # Create post (admin)
PUT  /posts/{id}            # Update post (admin)
DELETE /posts/{id}          # Delete post (admin)
GET  /posts/{id}/comments   # Get comments
POST /posts/{id}/comments   # Add comment
```

### Categories & Tags
```
GET  /categories            # List categories
GET  /tags                  # List tags
GET  /posts?category={id}   # Filter by category
GET  /posts?tag={id}        # Filter by tag
```

## Project Template

```
blog_platform/
├── api/
│   ├── src/
│   │   ├── handlers/
│   │   ├── services/
│   │   └── models/
│   └── terraform/
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   └── hooks/
│   └── terraform/
└── CLAUDE.md
```

## Blog Post Schema

```python
class BlogPost(BaseModel):
    post_id: str
    slug: str
    title: str
    content: str  # Markdown
    excerpt: str
    author_id: str
    category_id: str
    tags: List[str]
    status: str  # draft, published, archived
    published_at: Optional[datetime]
    seo_title: Optional[str]
    seo_description: Optional[str]
    featured_image: Optional[str]
```

## SEO Requirements

- [ ] Meta tags for all pages
- [ ] Open Graph tags
- [ ] Twitter cards
- [ ] Structured data (JSON-LD)
- [ ] Sitemap.xml
- [ ] robots.txt
- [ ] Canonical URLs

## Estimated Duration

| Mode | Duration |
|------|----------|
| Agentic | 10 hours |
| Manual | 40 hours |

## Examples

- Company Blog
- Technical Documentation
- News Portal
- Knowledge Base

---

**Quick Start**: Use full API stages + full Frontend stages.
