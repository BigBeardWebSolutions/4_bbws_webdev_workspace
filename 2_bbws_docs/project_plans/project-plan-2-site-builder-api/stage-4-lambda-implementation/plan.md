# Stage 4: Lambda Implementation

**Stage ID**: stage-4-lambda-implementation
**Parent Project**: Site Builder Bedrock Generation API (project-plan-2)
**Status**: PENDING
**Created**: 2026-01-15

---

## Stage Overview

**Objective**: Implement all Lambda functions in Python 3.12 following TDD, OOP principles, and AWS best practices.

**Dependencies**: Stage 3 complete

**Deliverables**:
1. Lambda function code (Python 3.12)
2. Bedrock integration code (Claude Sonnet 4.5, Stable Diffusion XL)
3. Unit tests with pytest
4. SSE streaming implementation

**Expected Duration**:
- Agentic: 2-3 hours
- Manual: 7-10 days

---

## Workers

| Worker | Name | Status | Description |
|--------|------|--------|-------------|
| 1 | Page Generator | PENDING | Page generation Lambda with Claude Sonnet 4.5 |
| 2 | Streaming Handler | PENDING | SSE streaming handler for real-time generation |
| 3 | Logo Creator | PENDING | Logo generation Lambda with Stable Diffusion XL |
| 4 | Background Creator | PENDING | Background image generation Lambda |
| 5 | Theme Selector | PENDING | Theme suggestion Lambda with Claude |
| 6 | Layout Agent | PENDING | Layout generation Lambda with Claude |
| 7 | Brand Validator | PENDING | Brand validation and scoring Lambda |
| 8 | Generation State | PENDING | Generation state management DynamoDB handler |

---

## Worker Definitions

### Worker 1: Page Generator

**Objective**: Implement the page generation Lambda function using Claude Sonnet 4.5 with streaming support.

**Input Files**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Bedrock_Generation_API.md`
- `openapi/generation-api.yaml`
- `tests/test_cases.md`
- `tests/fixtures/mock_bedrock_responses.py`

**Tasks**:
1. Create Lambda handler (`src/lambdas/page_generator/handler.py`)
2. Implement PageGenerator class with OOP principles
3. Integrate with Bedrock Claude Sonnet 4.5
4. Implement prompt construction with brand assets
5. Implement HTML validation
6. Write unit tests with moto/pytest
7. Document environment variables required

**Output Requirements**:
- Create: `src/lambdas/page_generator/`
  - `__init__.py`
  - `handler.py` - Lambda handler function
  - `generator.py` - PageGenerator class
  - `prompts.py` - Prompt templates
  - `requirements.txt`
- Create: `tests/unit/test_page_generator.py`

**Code Structure**:
```python
# generator.py
from abc import ABC, abstractmethod
from pydantic import BaseModel
from typing import AsyncGenerator
import boto3

class GeneratorBase(ABC):
    """Abstract base class for generators."""

    @abstractmethod
    async def generate(self, request: GenerationRequest) -> AsyncGenerator[str, None]:
        pass

class PageGenerator(GeneratorBase):
    """Page generator using Claude Sonnet 4.5."""

    def __init__(self, bedrock_client: BedrockClient):
        self.bedrock = bedrock_client
        self.model_id = "anthropic.claude-sonnet-4-5-20241022-v2:0"

    async def generate(self, request: GenerationRequest) -> AsyncGenerator[str, None]:
        """Generate page HTML with streaming."""
        prompt = self._construct_prompt(request)
        async for chunk in self.bedrock.invoke_with_streaming(
            model_id=self.model_id,
            prompt=prompt
        ):
            yield chunk
```

**Success Criteria**:
- Lambda handler functional
- PageGenerator class uses OOP principles
- Bedrock integration working
- Unit tests passing (80%+ coverage)
- No hardcoded credentials

---

### Worker 2: Streaming Handler

**Objective**: Implement SSE streaming handler for Lambda Response Streaming, enabling real-time page generation feedback.

**Input Files**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Bedrock_Generation_API.md`
- `openapi/generation-api.yaml`
- `src/lambdas/page_generator/generator.py`

**Tasks**:
1. Implement Lambda Response Streaming wrapper
2. Create SSE event formatter
3. Implement progress tracking
4. Implement error streaming
5. Implement completion event
6. Write unit tests

**Output Requirements**:
- Create: `src/lambdas/page_generator/streaming.py`
- Update: `src/lambdas/page_generator/handler.py`
- Create: `tests/unit/test_streaming.py`

**Code Structure**:
```python
# streaming.py
from typing import AsyncGenerator

class SSEFormatter:
    """Format responses as Server-Sent Events."""

    @staticmethod
    def progress(percent: int, message: str) -> str:
        return f'data: {{"type": "progress", "progress": {percent}, "message": "{message}"}}\n\n'

    @staticmethod
    def chunk(content: str) -> str:
        return f'data: {{"type": "chunk", "content": "{content}"}}\n\n'

    @staticmethod
    def complete(generation_id: str, brand_score: float) -> str:
        return f'data: {{"type": "complete", "generationId": "{generation_id}", "brandScore": {brand_score}}}\n\n'

    @staticmethod
    def error(code: str, message: str) -> str:
        return f'data: {{"type": "error", "code": "{code}", "message": "{message}"}}\n\n'

async def stream_response(generator: PageGenerator, request: GenerationRequest) -> AsyncGenerator[str, None]:
    """Stream page generation response."""
    yield SSEFormatter.progress(0, "Starting generation...")

    buffer = []
    async for chunk in generator.generate(request):
        buffer.append(chunk)
        yield SSEFormatter.chunk(chunk)

    yield SSEFormatter.complete(request.id, calculate_brand_score(buffer))
```

**Success Criteria**:
- SSE formatting correct
- Progress events emitted
- Chunks streamed in real-time
- Error handling implemented
- Unit tests passing

---

### Worker 3: Logo Creator

**Objective**: Implement logo generation Lambda function using Stable Diffusion XL via Bedrock.

**Input Files**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Bedrock_Generation_API.md`
- `openapi/agents-api.yaml`
- `tests/fixtures/mock_bedrock_responses.py`

**Tasks**:
1. Create Lambda handler (`src/lambdas/logo_creator/handler.py`)
2. Implement LogoCreator class
3. Integrate with Bedrock Stable Diffusion XL
4. Implement image processing (resize, format)
5. Implement S3 upload for generated logos
6. Generate 4 variations per request
7. Write unit tests

**Output Requirements**:
- Create: `src/lambdas/logo_creator/`
  - `__init__.py`
  - `handler.py`
  - `creator.py`
  - `requirements.txt`
- Create: `tests/unit/test_logo_creator.py`

**Code Structure**:
```python
# creator.py
from typing import List
from pydantic import BaseModel

class LogoRequest(BaseModel):
    prompt: str
    style: str = "modern"
    colors: List[str] = []
    count: int = 4

class LogoResult(BaseModel):
    id: str
    url: str
    preview: str  # base64 thumbnail

class LogoCreator:
    """Logo creator using Stable Diffusion XL."""

    def __init__(self, bedrock_client: BedrockClient, s3_client: S3Client):
        self.bedrock = bedrock_client
        self.s3 = s3_client
        self.model_id = "stability.stable-diffusion-xl-v1"

    async def create(self, request: LogoRequest, tenant_id: str) -> List[LogoResult]:
        """Generate logos and upload to S3."""
        results = []
        for i in range(request.count):
            image_data = await self.bedrock.invoke_image(
                model_id=self.model_id,
                prompt=self._enhance_prompt(request.prompt, request.style, i)
            )
            url = await self.s3.upload_image(
                image_data=image_data,
                path=f"{tenant_id}/images/logos/{request.id}_{i}.png"
            )
            results.append(LogoResult(
                id=f"logo-{i}",
                url=url,
                preview=self._create_thumbnail(image_data)
            ))
        return results
```

**Success Criteria**:
- Lambda handler functional
- SD XL integration working
- 4 variations generated
- Images uploaded to S3
- Pre-signed URLs returned
- Unit tests passing

---

### Worker 4: Background Creator

**Objective**: Implement background image generation Lambda function using Stable Diffusion XL.

**Input Files**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Bedrock_Generation_API.md`
- `openapi/agents-api.yaml`
- `src/lambdas/logo_creator/creator.py` (reference)

**Tasks**:
1. Create Lambda handler
2. Implement BackgroundCreator class (extends AgentBase)
3. Implement aspect ratio handling (16:9, 4:3, 1:1)
4. Implement S3 upload
5. Write unit tests

**Output Requirements**:
- Create: `src/lambdas/background_creator/`
  - `__init__.py`
  - `handler.py`
  - `creator.py`
  - `requirements.txt`
- Create: `tests/unit/test_background_creator.py`

**Success Criteria**:
- Lambda handler functional
- Multiple aspect ratios supported
- Images uploaded to S3
- Unit tests passing

---

### Worker 5: Theme Selector

**Objective**: Implement theme suggestion Lambda function using Claude Sonnet 4.5.

**Input Files**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Bedrock_Generation_API.md`
- `openapi/agents-api.yaml`

**Tasks**:
1. Create Lambda handler
2. Implement ThemeSelector class
3. Define theme schema (colors, fonts, spacing)
4. Generate 3 theme variations
5. Validate color contrast ratios
6. Write unit tests

**Output Requirements**:
- Create: `src/lambdas/theme_selector/`
  - `__init__.py`
  - `handler.py`
  - `selector.py`
  - `requirements.txt`
- Create: `tests/unit/test_theme_selector.py`

**Code Structure**:
```python
# selector.py
class Theme(BaseModel):
    id: str
    name: str
    primaryColor: str
    secondaryColor: str
    accentColor: str
    fontFamily: str
    fontSizes: Dict[str, str]
    spacing: Dict[str, str]

class ThemeSelector:
    """Theme selector using Claude."""

    async def suggest(self, context: str, brand_colors: List[str]) -> List[Theme]:
        """Suggest 3 cohesive themes."""
        prompt = self._construct_prompt(context, brand_colors)
        response = await self.bedrock.invoke(prompt)
        themes = self._parse_themes(response)
        return [t for t in themes if self._validate_contrast(t)]
```

**Success Criteria**:
- 3 theme variations generated
- Color contrast validated (4.5:1 minimum)
- Font specifications included
- Unit tests passing

---

### Worker 6: Layout Agent

**Objective**: Implement layout generation Lambda function using Claude Sonnet 4.5.

**Input Files**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Bedrock_Generation_API.md`
- `openapi/agents-api.yaml`

**Tasks**:
1. Create Lambda handler
2. Implement LayoutAgent class
3. Define layout schema (grid, sections, components)
4. Generate responsive layout specifications
5. Validate layout structure
6. Write unit tests

**Output Requirements**:
- Create: `src/lambdas/layout_agent/`
  - `__init__.py`
  - `handler.py`
  - `agent.py`
  - `requirements.txt`
- Create: `tests/unit/test_layout_agent.py`

**Success Criteria**:
- Layout schema defined
- Responsive breakpoints included
- Section ordering logical
- Unit tests passing

---

### Worker 7: Brand Validator

**Objective**: Implement brand validation and scoring Lambda function with 8/10 minimum threshold.

**Input Files**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Bedrock_Generation_API.md`
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/3.0_BBSW_Site_Builder_HLD.md` (Appendix D)
- `openapi/validation-api.yaml`

**Tasks**:
1. Create Lambda handler
2. Implement BrandValidator class
3. Implement scoring algorithm (7 categories from HLD)
4. Integrate Claude for subjective evaluation
5. Implement threshold enforcement (8/10)
6. Generate actionable feedback
7. Write unit tests

**Output Requirements**:
- Create: `src/lambdas/brand_validator/`
  - `__init__.py`
  - `handler.py`
  - `validator.py`
  - `scorer.py`
  - `requirements.txt`
- Create: `tests/unit/test_brand_validator.py`

**Code Structure**:
```python
# scorer.py
from enum import Enum

class ScoringCategory(Enum):
    COLOR_PALETTE = "color_palette"  # Max: 2.0
    TYPOGRAPHY = "typography"  # Max: 1.5
    LOGO_USAGE = "logo_usage"  # Max: 1.5
    LAYOUT_SPACING = "layout_spacing"  # Max: 1.5
    COMPONENT_STYLE = "component_style"  # Max: 1.5
    IMAGERY = "imagery"  # Max: 1.0
    CONTENT_TONE = "content_tone"  # Max: 1.0
    # Total: 10.0

class BrandScorer:
    """Brand consistency scorer."""

    MINIMUM_THRESHOLD = 8.0

    async def score(self, html: str, brand_assets: BrandAssets) -> ValidationResult:
        """Calculate brand consistency score."""
        scores = {}
        issues = []

        # Rule-based scoring
        scores[ScoringCategory.COLOR_PALETTE] = self._score_colors(html, brand_assets)
        scores[ScoringCategory.TYPOGRAPHY] = self._score_typography(html, brand_assets)
        scores[ScoringCategory.LOGO_USAGE] = self._score_logo(html, brand_assets)
        scores[ScoringCategory.LAYOUT_SPACING] = self._score_layout(html)
        scores[ScoringCategory.COMPONENT_STYLE] = self._score_components(html)

        # AI-powered scoring (Claude)
        scores[ScoringCategory.IMAGERY] = await self._score_imagery_ai(html)
        scores[ScoringCategory.CONTENT_TONE] = await self._score_tone_ai(html, brand_assets)

        total = sum(scores.values())

        return ValidationResult(
            brandScore=total,
            categoryScores=scores,
            issues=issues,
            passesThreshold=total >= self.MINIMUM_THRESHOLD
        )
```

**Success Criteria**:
- All 7 scoring categories implemented
- 8/10 threshold enforced
- Actionable feedback generated
- Hybrid rule-based + AI scoring
- Unit tests passing

---

### Worker 8: Generation State

**Objective**: Implement generation state management Lambda for DynamoDB operations.

**Input Files**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Bedrock_Generation_API.md`

**Tasks**:
1. Create Lambda handler
2. Implement GenerationStateManager class
3. Implement state transitions (PENDING, IN_PROGRESS, COMPLETE, FAILED)
4. Implement version tracking
5. Implement DynamoDB operations (create, update, query)
6. Write unit tests with moto

**Output Requirements**:
- Create: `src/lambdas/generation_state/`
  - `__init__.py`
  - `handler.py`
  - `state_manager.py`
  - `requirements.txt`
- Create: `tests/unit/test_generation_state.py`

**Code Structure**:
```python
# state_manager.py
from enum import Enum
import boto3

class GenerationStatus(Enum):
    PENDING = "PENDING"
    IN_PROGRESS = "IN_PROGRESS"
    COMPLETE = "COMPLETE"
    FAILED = "FAILED"

class GenerationStateManager:
    """Manage generation state in DynamoDB."""

    def __init__(self, table_name: str):
        self.dynamodb = boto3.resource('dynamodb')
        self.table = self.dynamodb.Table(table_name)

    async def create(self, tenant_id: str, generation_id: str, request: dict) -> dict:
        """Create new generation record."""
        item = {
            'tenant_id': tenant_id,
            'generation_id': generation_id,
            'status': GenerationStatus.PENDING.value,
            'version': 1,
            'request': request,
            'created_at': datetime.utcnow().isoformat()
        }
        self.table.put_item(Item=item)
        return item

    async def update_status(self, tenant_id: str, generation_id: str,
                           status: GenerationStatus, result: dict = None) -> dict:
        """Update generation status."""
        update_expr = "SET #status = :status, updated_at = :updated"
        expr_values = {
            ':status': status.value,
            ':updated': datetime.utcnow().isoformat()
        }
        if result and status == GenerationStatus.COMPLETE:
            update_expr += ", result = :result"
            expr_values[':result'] = result

        return self.table.update_item(
            Key={'tenant_id': tenant_id, 'generation_id': generation_id},
            UpdateExpression=update_expr,
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues=expr_values,
            ReturnValues='ALL_NEW'
        )
```

**Success Criteria**:
- State transitions working
- Version tracking implemented
- DynamoDB operations functional
- Unit tests passing with moto

---

## Shared Code

### Worker Dependency: Shared Module

All workers depend on the shared module created first:

**Output Requirements**:
- Create: `src/shared/`
  - `__init__.py`
  - `bedrock_client.py` - Bedrock API wrapper
  - `dynamodb_client.py` - DynamoDB operations
  - `s3_client.py` - S3 operations
  - `models.py` - Pydantic data models
  - `utils.py` - Shared utilities

---

## Stage Completion Criteria

The stage is considered **COMPLETE** when:

1. All 8 workers have completed their outputs
2. All Lambda functions implemented and tested
3. Shared module created
4. Unit test coverage >= 80%
5. All tests passing

---

## Approval Gate (Gate 3)

**After this stage**: Gate 3 approval required

**Approvers**:
- Tech Lead
- Developer Lead

**Approval Criteria**:
- Code follows OOP principles
- Unit tests comprehensive
- Coverage >= 80%
- No hardcoded credentials
- Pydantic models for all data

---

**Stage Owner**: Agentic Project Manager
**Created**: 2026-01-15
**Next Action**: Wait for Stage 3 completion
