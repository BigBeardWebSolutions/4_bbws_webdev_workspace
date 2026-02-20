# Stage W2: AI Site Generation

**Parent Plan**: [BBWS SDLC Main Plan](./main-plan.md)
**Stage**: W2 of W4 (WordPress Track)
**Status**: PENDING
**Last Updated**: 2026-01-01

---

## Objective

Use AWS Bedrock (Claude Sonnet 3.5 + Stable Diffusion XL) to generate complete website content including text and images, then build static sites from WordPress templates.

---

## Agent & Skill Assignment

| Role | Agent | Skill |
|------|-------|-------|
| **Primary** | AI_Website_Generator | `aws-ai-website-generator.skill.md` |
| **Support** | Web_Developer_Agent | `bedrock_integration.skill.md` |

---

## Workers

| # | Worker | Task | Status | Output |
|---|--------|------|--------|--------|
| 1 | worker-1-content-generation | Generate site content with Claude | PENDING | Content JSON |
| 2 | worker-2-image-generation | Generate images with Stable Diffusion | PENDING | Image assets |
| 3 | worker-3-static-build | Build static site from templates | PENDING | `dist/` |
| 4 | worker-4-tenant-association | Associate site with tenant | PENDING | Site metadata |

---

## Worker Instructions

### Worker 1: Content Generation with Claude

**Objective**: Generate website content using Claude Sonnet 3.5

**AWS Bedrock Integration**:
```python
import boto3
import json

bedrock = boto3.client('bedrock-runtime', region_name='eu-west-1')

def generate_site_content(business_info: dict) -> dict:
    """Generate website content using Claude."""
    prompt = f"""
    Generate professional website content for a business with the following details:
    - Business Name: {business_info['name']}
    - Industry: {business_info['industry']}
    - Services: {business_info['services']}
    - Target Audience: {business_info['target_audience']}
    - Tone: {business_info['tone']}

    Generate content for these sections:
    1. Hero section (headline, subheadline, CTA)
    2. About section (3 paragraphs)
    3. Services section (3-5 service descriptions)
    4. Testimonials (3 customer quotes)
    5. Contact section (intro text)
    6. Footer (tagline)

    Return as JSON with clear structure.
    """

    response = bedrock.invoke_model(
        modelId='anthropic.claude-3-5-sonnet-20241022-v2:0',
        body=json.dumps({
            'anthropic_version': 'bedrock-2023-05-31',
            'max_tokens': 4096,
            'messages': [
                {'role': 'user', 'content': prompt}
            ]
        })
    )

    return json.loads(response['body'].read())
```

**Content Schema**:
```json
{
  "hero": {
    "title": "Transform Your Business",
    "subtitle": "Professional solutions for modern enterprises",
    "cta_text": "Get Started",
    "cta_link": "#contact"
  },
  "about": {
    "title": "About Us",
    "paragraphs": ["...", "...", "..."]
  },
  "services": [
    {
      "title": "Service Name",
      "description": "Service description",
      "icon": "chart-line"
    }
  ],
  "testimonials": [
    {
      "quote": "...",
      "author": "John Doe",
      "company": "Acme Inc"
    }
  ],
  "contact": {
    "title": "Get in Touch",
    "intro": "..."
  }
}
```

**Quality Criteria**:
- [ ] Content generated successfully
- [ ] JSON schema validated
- [ ] Content appropriate for industry
- [ ] No placeholder text remaining

---

### Worker 2: Image Generation with Stable Diffusion

**Objective**: Generate site images using Stable Diffusion XL

**AWS Bedrock Image Generation**:
```python
def generate_image(prompt: str, style: str = "professional") -> bytes:
    """Generate image using Stable Diffusion XL."""
    full_prompt = f"{prompt}, {style} photography, high quality, modern"

    response = bedrock.invoke_model(
        modelId='stability.stable-diffusion-xl-v1',
        body=json.dumps({
            'text_prompts': [
                {'text': full_prompt, 'weight': 1.0}
            ],
            'cfg_scale': 7,
            'steps': 50,
            'width': 1024,
            'height': 1024,
            'seed': 42
        })
    )

    result = json.loads(response['body'].read())
    return base64.b64decode(result['artifacts'][0]['base64'])
```

**Images to Generate**:
| Image | Prompt Template | Size |
|-------|-----------------|------|
| Hero Background | `{industry} business hero image, modern office` | 1920x1080 |
| Service Icons | `{service} icon, minimalist, professional` | 512x512 |
| Team Photos | `professional business portrait, diverse` | 800x800 |
| Gallery | `{industry} workplace, modern design` | 1200x800 |

**Quality Criteria**:
- [ ] Hero image generated
- [ ] Service icons created
- [ ] Images optimized for web
- [ ] Consistent style across images

---

### Worker 3: Static Site Build

**Objective**: Compile templates with content into static HTML

**Build Process**:
```python
def build_static_site(template_dir: str, content: dict, output_dir: str):
    """Build static site from templates and content."""
    # Load templates
    env = Environment(loader=FileSystemLoader(template_dir))

    # Render each page
    pages = ['index', 'about', 'services', 'contact']
    for page in pages:
        template = env.get_template(f'{page}.html')
        html = template.render(**content)

        # Write to output
        with open(f'{output_dir}/{page}.html', 'w') as f:
            f.write(html)

    # Copy assets
    shutil.copytree(f'{template_dir}/assets', f'{output_dir}/assets')

    # Minify CSS/JS
    minify_assets(output_dir)
```

**Output Structure**:
```
dist/
├── index.html
├── about.html
├── services.html
├── contact.html
├── assets/
│   ├── css/
│   │   └── styles.min.css
│   ├── js/
│   │   └── main.min.js
│   └── images/
│       ├── hero.webp
│       └── ...
└── sitemap.xml
```

**Quality Criteria**:
- [ ] All pages generated
- [ ] Assets optimized
- [ ] Valid HTML5
- [ ] SEO metadata included

---

### Worker 4: Tenant Association

**Objective**: Associate generated site with tenant in DynamoDB

**Site Metadata**:
```python
def register_site(tenant_id: str, site_info: dict) -> dict:
    """Register generated site with tenant."""
    site = {
        'PK': f'TENANT#{tenant_id}',
        'SK': f'SITE#{site_info["site_id"]}',
        'site_id': site_info['site_id'],
        'site_name': site_info['name'],
        'domain': site_info['domain'],
        'status': 'generated',
        'generation_date': datetime.utcnow().isoformat(),
        's3_bucket': site_info['s3_bucket'],
        's3_prefix': site_info['s3_prefix'],
        'cloudfront_distribution': site_info['cloudfront_id'],
        'template_version': site_info['template_version'],
        'content_hash': site_info['content_hash']
    }

    table.put_item(Item=site)
    return site
```

**Quality Criteria**:
- [ ] Site registered in DynamoDB
- [ ] Tenant association correct
- [ ] Metadata complete
- [ ] Site ready for deployment

---

## Stage Outputs

| Output | Description | Location |
|--------|-------------|----------|
| Content JSON | AI-generated content | `generated/content.json` |
| Images | AI-generated images | `generated/images/` |
| Static site | Built HTML/CSS/JS | `dist/` |
| Metadata | Site registration | DynamoDB |

---

## Success Criteria

- [ ] All 4 workers completed
- [ ] Content generated by Claude
- [ ] Images generated by Stable Diffusion
- [ ] Static site builds successfully
- [ ] Site registered with tenant

---

## Dependencies

**Depends On**: Stage W1 (Theme Development)
**Blocks**: Stage W3 (WordPress Deployment)

**External Dependencies**:
- AWS Bedrock (Claude Sonnet 3.5)
- AWS Bedrock (Stable Diffusion XL)
- DynamoDB table

---

## Estimated Duration

| Activity | Agentic | Manual |
|----------|---------|--------|
| Content generation | 10 min | 2 hours |
| Image generation | 15 min | 4 hours |
| Static build | 5 min | 1 hour |
| Tenant association | 5 min | 30 min |
| **Total** | **35 min** | **7.5 hours** |

---

**Navigation**: [<- Stage W1](./stage-w1-theme-dev.md) | [Main Plan](./main-plan.md) | [Stage W3 ->](./stage-w3-deployment.md)
