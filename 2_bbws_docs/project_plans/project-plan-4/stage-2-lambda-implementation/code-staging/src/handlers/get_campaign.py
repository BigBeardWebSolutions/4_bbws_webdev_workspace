"""Lambda handler for GET /v1.0/campaigns/{code}."""

import json
import logging
import os
from typing import Any, Dict

from src.exceptions.campaign_exceptions import BusinessException, SystemException
from src.models.campaign import CampaignResponse
from src.repositories.campaign_repository import CampaignRepository
from src.services.campaign_service import CampaignService

# Configure logging
LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO")
logging.basicConfig(level=LOG_LEVEL)
logger = logging.getLogger(__name__)


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for getting campaign by code.

    Args:
        event: API Gateway event
        context: Lambda context

    Returns:
        API Gateway response
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")

        # Extract path parameters
        code = _extract_path_param(event, "code")
        logger.info(f"Processing campaign request for code: {code}")

        # Initialize dependencies
        repository = CampaignRepository()
        service = CampaignService(repository)

        # Get campaign
        campaign = service.get_campaign(code)

        # Build response
        campaign_response = CampaignResponse.from_campaign(campaign)

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
            },
            "body": campaign_response.model_dump_json(by_alias=True),
        }

    except BusinessException as e:
        logger.warning(f"Business exception: {e.message}")
        return {
            "statusCode": e.status_code,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
            },
            "body": json.dumps({"message": e.message}),
        }

    except SystemException as e:
        logger.error(f"System exception: {e.message}")
        return {
            "statusCode": e.status_code,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
            },
            "body": json.dumps({"message": "Internal server error"}),
        }

    except Exception as e:
        logger.error(f"Unexpected exception: {str(e)}", exc_info=True)
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
            },
            "body": json.dumps({"message": "Internal server error"}),
        }


def _extract_path_param(event: Dict[str, Any], param_name: str) -> str:
    """
    Extract path parameter from event.

    Args:
        event: API Gateway event
        param_name: Parameter name

    Returns:
        Parameter value

    Raises:
        ValueError: If parameter is missing
    """
    path_params = event.get("pathParameters", {})
    if not path_params or param_name not in path_params:
        raise ValueError(f"Missing required path parameter: {param_name}")

    return path_params[param_name]
