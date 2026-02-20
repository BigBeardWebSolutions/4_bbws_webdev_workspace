# Worker Instructions: Lambda Handlers

**Worker ID**: worker-5-lambda-handlers
**Stage**: Stage 2 - Lambda Code Development
**Project**: project-plan-campaigns

---

## Task

Create the 5 Lambda handler functions for the Campaign API endpoints.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.3_LLD_Campaigns_Lambda.md`

**Reference**:
- Section 4: Sequence Diagrams
- Section 6: REST API Operations

---

## Deliverables

### 1. List Campaigns Handler (src/handlers/list_campaigns.py)

```python
"""Handler for GET /v1.0/campaigns endpoint."""

import json
from typing import Any, Dict

from aws_lambda_powertools import Logger, Tracer

from src.services.campaign_service import CampaignService
from src.models.campaign import CampaignStatus
from src.exceptions.campaign_exceptions import CampaignBaseException
from src.utils.response_builder import ResponseBuilder

logger = Logger()
tracer = Tracer()


@tracer.capture_lambda_handler
@logger.inject_lambda_context
def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Lambda handler for listing campaigns.

    Args:
        event: API Gateway event.
        context: Lambda context.

    Returns:
        API Gateway response with campaigns list.
    """
    logger.info("Handling list campaigns request")

    try:
        # Parse query parameters
        query_params = event.get("queryStringParameters") or {}
        status_filter = query_params.get("status")

        # Convert status string to enum if provided
        campaign_status = None
        if status_filter:
            try:
                campaign_status = CampaignStatus(status_filter.upper())
            except ValueError:
                return ResponseBuilder.bad_request(
                    f"Invalid status: {status_filter}. Valid values: DRAFT, ACTIVE, EXPIRED"
                )

        # Get campaigns from service
        service = CampaignService()
        result = service.list_campaigns(status_filter=campaign_status)

        # Build response
        response_body = {
            "campaigns": [
                campaign.model_dump(by_alias=True, exclude_none=True)
                for campaign in result.campaigns
            ],
            "count": result.count,
        }

        return ResponseBuilder.success(response_body)

    except CampaignBaseException as e:
        logger.warning(f"Business error: {e.message}")
        return ResponseBuilder.error(e.status_code, e.to_dict())

    except Exception as e:
        logger.exception(f"Unexpected error: {str(e)}")
        return ResponseBuilder.internal_error()
```

### 2. Get Campaign Handler (src/handlers/get_campaign.py)

```python
"""Handler for GET /v1.0/campaigns/{code} endpoint."""

import json
from typing import Any, Dict

from aws_lambda_powertools import Logger, Tracer

from src.services.campaign_service import CampaignService
from src.exceptions.campaign_exceptions import (
    CampaignBaseException,
    CampaignNotFoundException,
)
from src.utils.response_builder import ResponseBuilder

logger = Logger()
tracer = Tracer()


@tracer.capture_lambda_handler
@logger.inject_lambda_context
def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Lambda handler for getting a campaign by code.

    Args:
        event: API Gateway event.
        context: Lambda context.

    Returns:
        API Gateway response with campaign details.
    """
    logger.info("Handling get campaign request")

    try:
        # Extract path parameters
        path_params = event.get("pathParameters") or {}
        code = path_params.get("code")

        if not code:
            return ResponseBuilder.bad_request("Campaign code is required")

        # Get campaign from service
        service = CampaignService()
        campaign = service.get_campaign(code)

        # Build response
        response_body = {
            "campaign": campaign.model_dump(by_alias=True, exclude_none=True)
        }

        return ResponseBuilder.success(response_body)

    except CampaignNotFoundException as e:
        logger.info(f"Campaign not found: {e.code}")
        return ResponseBuilder.not_found(e.to_dict())

    except CampaignBaseException as e:
        logger.warning(f"Business error: {e.message}")
        return ResponseBuilder.error(e.status_code, e.to_dict())

    except Exception as e:
        logger.exception(f"Unexpected error: {str(e)}")
        return ResponseBuilder.internal_error()
```

### 3. Create Campaign Handler (src/handlers/create_campaign.py)

```python
"""Handler for POST /v1.0/campaigns endpoint."""

import json
from typing import Any, Dict
from decimal import Decimal

from aws_lambda_powertools import Logger, Tracer
from pydantic import ValidationError

from src.services.campaign_service import CampaignService
from src.models.campaign import CreateCampaignRequest
from src.exceptions.campaign_exceptions import (
    CampaignBaseException,
    DuplicateCampaignException,
)
from src.utils.response_builder import ResponseBuilder

logger = Logger()
tracer = Tracer()


def parse_decimal(obj):
    """Custom JSON decoder for Decimal values."""
    if isinstance(obj, float):
        return Decimal(str(obj))
    return obj


@tracer.capture_lambda_handler
@logger.inject_lambda_context
def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Lambda handler for creating a campaign.

    Args:
        event: API Gateway event.
        context: Lambda context.

    Returns:
        API Gateway response with created campaign.
    """
    logger.info("Handling create campaign request")

    try:
        # Parse request body
        body = event.get("body")
        if not body:
            return ResponseBuilder.bad_request("Request body is required")

        try:
            if isinstance(body, str):
                body_data = json.loads(body, parse_float=Decimal)
            else:
                body_data = body
        except json.JSONDecodeError:
            return ResponseBuilder.bad_request("Invalid JSON in request body")

        # Validate request using Pydantic model
        try:
            request = CreateCampaignRequest(**body_data)
        except ValidationError as e:
            errors = [
                f"{err['loc'][0]}: {err['msg']}"
                for err in e.errors()
            ]
            return ResponseBuilder.bad_request(
                "Validation failed",
                {"errors": errors}
            )

        # Create campaign via service
        service = CampaignService()
        campaign = service.create_campaign(request)

        # Build response
        response_body = {
            "campaign": campaign.model_dump(by_alias=True, exclude_none=True)
        }

        return ResponseBuilder.created(response_body)

    except DuplicateCampaignException as e:
        logger.info(f"Duplicate campaign: {e.code}")
        return ResponseBuilder.bad_request(e.to_dict())

    except CampaignBaseException as e:
        logger.warning(f"Business error: {e.message}")
        return ResponseBuilder.error(e.status_code, e.to_dict())

    except Exception as e:
        logger.exception(f"Unexpected error: {str(e)}")
        return ResponseBuilder.internal_error()
```

### 4. Update Campaign Handler (src/handlers/update_campaign.py)

```python
"""Handler for PUT /v1.0/campaigns/{code} endpoint."""

import json
from typing import Any, Dict
from decimal import Decimal

from aws_lambda_powertools import Logger, Tracer
from pydantic import ValidationError

from src.services.campaign_service import CampaignService
from src.models.campaign import UpdateCampaignRequest
from src.exceptions.campaign_exceptions import (
    CampaignBaseException,
    CampaignNotFoundException,
    ValidationException,
)
from src.utils.response_builder import ResponseBuilder

logger = Logger()
tracer = Tracer()


@tracer.capture_lambda_handler
@logger.inject_lambda_context
def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Lambda handler for updating a campaign.

    Args:
        event: API Gateway event.
        context: Lambda context.

    Returns:
        API Gateway response with updated campaign.
    """
    logger.info("Handling update campaign request")

    try:
        # Extract path parameters
        path_params = event.get("pathParameters") or {}
        code = path_params.get("code")

        if not code:
            return ResponseBuilder.bad_request("Campaign code is required")

        # Parse request body
        body = event.get("body")
        if not body:
            return ResponseBuilder.bad_request("Request body is required")

        try:
            if isinstance(body, str):
                body_data = json.loads(body, parse_float=Decimal)
            else:
                body_data = body
        except json.JSONDecodeError:
            return ResponseBuilder.bad_request("Invalid JSON in request body")

        # Validate request using Pydantic model
        try:
            request = UpdateCampaignRequest(**body_data)
        except ValidationError as e:
            errors = [
                f"{err['loc'][0]}: {err['msg']}"
                for err in e.errors()
            ]
            return ResponseBuilder.bad_request(
                "Validation failed",
                {"errors": errors}
            )

        # Update campaign via service
        service = CampaignService()
        campaign = service.update_campaign(code, request)

        # Build response
        response_body = {
            "campaign": campaign.model_dump(by_alias=True, exclude_none=True)
        }

        return ResponseBuilder.success(response_body)

    except CampaignNotFoundException as e:
        logger.info(f"Campaign not found: {e.code}")
        return ResponseBuilder.not_found(e.to_dict())

    except ValidationException as e:
        logger.info(f"Validation error: {e.message}")
        return ResponseBuilder.bad_request(e.to_dict())

    except CampaignBaseException as e:
        logger.warning(f"Business error: {e.message}")
        return ResponseBuilder.error(e.status_code, e.to_dict())

    except Exception as e:
        logger.exception(f"Unexpected error: {str(e)}")
        return ResponseBuilder.internal_error()
```

### 5. Delete Campaign Handler (src/handlers/delete_campaign.py)

```python
"""Handler for DELETE /v1.0/campaigns/{code} endpoint."""

from typing import Any, Dict

from aws_lambda_powertools import Logger, Tracer

from src.services.campaign_service import CampaignService
from src.exceptions.campaign_exceptions import (
    CampaignBaseException,
    CampaignNotFoundException,
)
from src.utils.response_builder import ResponseBuilder

logger = Logger()
tracer = Tracer()


@tracer.capture_lambda_handler
@logger.inject_lambda_context
def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Lambda handler for deleting a campaign (soft delete).

    Args:
        event: API Gateway event.
        context: Lambda context.

    Returns:
        API Gateway response (204 No Content on success).
    """
    logger.info("Handling delete campaign request")

    try:
        # Extract path parameters
        path_params = event.get("pathParameters") or {}
        code = path_params.get("code")

        if not code:
            return ResponseBuilder.bad_request("Campaign code is required")

        # Delete campaign via service
        service = CampaignService()
        service.delete_campaign(code)

        # Return 204 No Content
        return ResponseBuilder.no_content()

    except CampaignNotFoundException as e:
        logger.info(f"Campaign not found: {e.code}")
        return ResponseBuilder.not_found(e.to_dict())

    except CampaignBaseException as e:
        logger.warning(f"Business error: {e.message}")
        return ResponseBuilder.error(e.status_code, e.to_dict())

    except Exception as e:
        logger.exception(f"Unexpected error: {str(e)}")
        return ResponseBuilder.internal_error()
```

---

## Unit Tests (TDD Approach)

### tests/unit/handlers/test_list_campaigns.py

```python
"""Unit tests for list_campaigns handler."""

import pytest
import json
from unittest.mock import patch, MagicMock
from decimal import Decimal

from src.handlers.list_campaigns import handler


class TestListCampaignsHandler:
    """Tests for list_campaigns handler."""

    @patch("src.handlers.list_campaigns.CampaignService")
    def test_list_campaigns_success(self, mock_service_class, api_gateway_event, lambda_context):
        """Test successful campaign listing."""
        mock_service = MagicMock()
        mock_service.list_campaigns.return_value = MagicMock(
            campaigns=[],
            count=0,
        )
        mock_service_class.return_value = mock_service

        response = handler(api_gateway_event, lambda_context)

        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert "campaigns" in body
        assert body["count"] == 0

    @patch("src.handlers.list_campaigns.CampaignService")
    def test_list_campaigns_with_status_filter(self, mock_service_class, api_gateway_event, lambda_context):
        """Test campaign listing with status filter."""
        api_gateway_event["queryStringParameters"] = {"status": "ACTIVE"}

        mock_service = MagicMock()
        mock_service.list_campaigns.return_value = MagicMock(
            campaigns=[],
            count=0,
        )
        mock_service_class.return_value = mock_service

        response = handler(api_gateway_event, lambda_context)

        assert response["statusCode"] == 200

    def test_list_campaigns_invalid_status(self, api_gateway_event, lambda_context):
        """Test campaign listing with invalid status filter."""
        api_gateway_event["queryStringParameters"] = {"status": "INVALID"}

        response = handler(api_gateway_event, lambda_context)

        assert response["statusCode"] == 400
```

### tests/unit/handlers/test_get_campaign.py

```python
"""Unit tests for get_campaign handler."""

import pytest
import json
from unittest.mock import patch, MagicMock

from src.handlers.get_campaign import handler
from src.exceptions.campaign_exceptions import CampaignNotFoundException


class TestGetCampaignHandler:
    """Tests for get_campaign handler."""

    @patch("src.handlers.get_campaign.CampaignService")
    def test_get_campaign_success(self, mock_service_class, api_gateway_event, lambda_context):
        """Test successful campaign retrieval."""
        api_gateway_event["pathParameters"] = {"code": "SUMMER2025"}

        mock_campaign = MagicMock()
        mock_campaign.model_dump.return_value = {"code": "SUMMER2025"}

        mock_service = MagicMock()
        mock_service.get_campaign.return_value = mock_campaign
        mock_service_class.return_value = mock_service

        response = handler(api_gateway_event, lambda_context)

        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert "campaign" in body

    @patch("src.handlers.get_campaign.CampaignService")
    def test_get_campaign_not_found(self, mock_service_class, api_gateway_event, lambda_context):
        """Test campaign not found."""
        api_gateway_event["pathParameters"] = {"code": "NONEXISTENT"}

        mock_service = MagicMock()
        mock_service.get_campaign.side_effect = CampaignNotFoundException("NONEXISTENT")
        mock_service_class.return_value = mock_service

        response = handler(api_gateway_event, lambda_context)

        assert response["statusCode"] == 404

    def test_get_campaign_missing_code(self, api_gateway_event, lambda_context):
        """Test missing campaign code."""
        api_gateway_event["pathParameters"] = None

        response = handler(api_gateway_event, lambda_context)

        assert response["statusCode"] == 400
```

---

## Success Criteria

- [ ] All 5 handlers implemented
- [ ] Proper error handling in each handler
- [ ] Request body parsing with JSON
- [ ] Path parameter extraction
- [ ] Query parameter handling
- [ ] ResponseBuilder used for all responses
- [ ] Logging with aws-lambda-powertools
- [ ] All unit tests pass

---

## Execution Steps

1. Write unit tests for handlers (TDD)
2. Create list_campaigns.py handler
3. Create get_campaign.py handler
4. Create create_campaign.py handler
5. Create update_campaign.py handler
6. Create delete_campaign.py handler
7. Run tests to verify implementation
8. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
