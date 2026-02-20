# Worker Instructions: Utils & Validators

**Worker ID**: worker-6-utils-validators
**Stage**: Stage 2 - Lambda Code Development
**Project**: project-plan-campaigns

---

## Task

Create utility classes and validators for the Campaign Lambda service.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.3_LLD_Campaigns_Lambda.md`

**Reference**:
- Section 6: REST API Operations (Response formats)
- Section 5: Data Models (Validation rules)

---

## Deliverables

### 1. Response Builder (src/utils/response_builder.py)

```python
"""Utility for building API Gateway responses."""

import json
from typing import Any, Dict, Optional
from decimal import Decimal


class DecimalEncoder(json.JSONEncoder):
    """Custom JSON encoder for Decimal values."""

    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super().default(obj)


class ResponseBuilder:
    """Builder for API Gateway responses."""

    CORS_HEADERS = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token",
        "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
        "Content-Type": "application/json",
    }

    @classmethod
    def _build_response(
        cls,
        status_code: int,
        body: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Build API Gateway response.

        Args:
            status_code: HTTP status code.
            body: Response body dictionary.

        Returns:
            API Gateway response dictionary.
        """
        response = {
            "statusCode": status_code,
            "headers": cls.CORS_HEADERS,
        }

        if body is not None:
            response["body"] = json.dumps(body, cls=DecimalEncoder)
        else:
            response["body"] = ""

        return response

    @classmethod
    def success(cls, body: Dict[str, Any]) -> Dict[str, Any]:
        """Build 200 OK response.

        Args:
            body: Response body.

        Returns:
            API Gateway response.
        """
        return cls._build_response(200, body)

    @classmethod
    def created(cls, body: Dict[str, Any]) -> Dict[str, Any]:
        """Build 201 Created response.

        Args:
            body: Response body.

        Returns:
            API Gateway response.
        """
        return cls._build_response(201, body)

    @classmethod
    def no_content(cls) -> Dict[str, Any]:
        """Build 204 No Content response.

        Returns:
            API Gateway response.
        """
        return cls._build_response(204)

    @classmethod
    def bad_request(
        cls,
        message: str = "Invalid request",
        details: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Build 400 Bad Request response.

        Args:
            message: Error message.
            details: Additional error details.

        Returns:
            API Gateway response.
        """
        body = {"error": "InvalidRequest", "message": message}
        if details:
            body.update(details)
        return cls._build_response(400, body)

    @classmethod
    def not_found(cls, body: Dict[str, Any]) -> Dict[str, Any]:
        """Build 404 Not Found response.

        Args:
            body: Error body.

        Returns:
            API Gateway response.
        """
        return cls._build_response(404, body)

    @classmethod
    def internal_error(
        cls,
        message: str = "An unexpected error occurred",
    ) -> Dict[str, Any]:
        """Build 500 Internal Server Error response.

        Args:
            message: Error message.

        Returns:
            API Gateway response.
        """
        return cls._build_response(
            500,
            {"error": "InternalServerError", "message": message},
        )

    @classmethod
    def service_unavailable(
        cls,
        message: str = "Service temporarily unavailable",
    ) -> Dict[str, Any]:
        """Build 503 Service Unavailable response.

        Args:
            message: Error message.

        Returns:
            API Gateway response.
        """
        return cls._build_response(
            503,
            {"error": "ServiceUnavailable", "message": message},
        )

    @classmethod
    def error(
        cls,
        status_code: int,
        body: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Build error response with custom status code.

        Args:
            status_code: HTTP status code.
            body: Error body.

        Returns:
            API Gateway response.
        """
        return cls._build_response(status_code, body)
```

### 2. Date Utilities (src/utils/date_utils.py)

```python
"""Utility for date operations."""

from datetime import datetime, timezone
from typing import Optional


class DateUtils:
    """Utilities for date handling."""

    ISO_FORMAT = "%Y-%m-%dT%H:%M:%SZ"

    @classmethod
    def now(cls) -> datetime:
        """Get current UTC datetime.

        Returns:
            Current datetime in UTC.
        """
        return datetime.now(timezone.utc)

    @classmethod
    def now_iso(cls) -> str:
        """Get current UTC datetime as ISO string.

        Returns:
            Current datetime as ISO 8601 string.
        """
        return cls.now().strftime(cls.ISO_FORMAT)

    @classmethod
    def parse_iso(cls, date_string: str) -> datetime:
        """Parse ISO 8601 date string.

        Args:
            date_string: ISO 8601 formatted date string.

        Returns:
            Parsed datetime object.

        Raises:
            ValueError: If date string is invalid.
        """
        # Handle Z suffix
        normalized = date_string.replace("Z", "+00:00")
        return datetime.fromisoformat(normalized)

    @classmethod
    def is_future(cls, date_string: str) -> bool:
        """Check if date is in the future.

        Args:
            date_string: ISO 8601 formatted date string.

        Returns:
            True if date is in the future.
        """
        target = cls.parse_iso(date_string)
        return target > cls.now()

    @classmethod
    def is_past(cls, date_string: str) -> bool:
        """Check if date is in the past.

        Args:
            date_string: ISO 8601 formatted date string.

        Returns:
            True if date is in the past.
        """
        target = cls.parse_iso(date_string)
        return target < cls.now()

    @classmethod
    def is_between(
        cls,
        from_date: str,
        to_date: str,
        check_date: Optional[datetime] = None,
    ) -> bool:
        """Check if date is between two dates.

        Args:
            from_date: Start date (ISO 8601).
            to_date: End date (ISO 8601).
            check_date: Date to check. Defaults to now.

        Returns:
            True if check_date is between from_date and to_date.
        """
        check = check_date or cls.now()
        from_dt = cls.parse_iso(from_date)
        to_dt = cls.parse_iso(to_date)
        return from_dt <= check <= to_dt

    @classmethod
    def format_iso(cls, dt: datetime) -> str:
        """Format datetime as ISO 8601 string.

        Args:
            dt: Datetime object.

        Returns:
            ISO 8601 formatted string.
        """
        return dt.strftime(cls.ISO_FORMAT)
```

### 3. Logger (src/utils/logger.py)

```python
"""Logging utility using AWS Lambda Powertools."""

import os
from aws_lambda_powertools import Logger


def get_logger(name: str = __name__) -> Logger:
    """Get a configured logger instance.

    Args:
        name: Logger name (typically __name__).

    Returns:
        Configured Logger instance.
    """
    log_level = os.environ.get("LOG_LEVEL", "INFO")
    service_name = os.environ.get("SERVICE_NAME", "campaigns-lambda")

    return Logger(
        service=service_name,
        level=log_level,
        correlation_id_path="requestContext.requestId",
    )
```

### 4. Campaign Validator (src/validators/campaign_validator.py)

```python
"""Validator for Campaign data."""

import re
from typing import List, Optional
from decimal import Decimal
from datetime import datetime

from src.utils.date_utils import DateUtils
from src.exceptions.campaign_exceptions import ValidationException


class CampaignValidator:
    """Validator for Campaign business rules."""

    # Validation constants
    CODE_PATTERN = r"^[A-Z0-9_-]+$"
    CODE_MIN_LENGTH = 3
    CODE_MAX_LENGTH = 50
    NAME_MIN_LENGTH = 3
    NAME_MAX_LENGTH = 100
    TERMS_MIN_LENGTH = 10
    TERMS_MAX_LENGTH = 1000
    SPECIAL_CONDITIONS_MAX_LENGTH = 500
    DISCOUNT_MIN = 0
    DISCOUNT_MAX = 100
    PRICE_MIN = Decimal("0.01")
    PRICE_MAX = Decimal("999999.99")

    @classmethod
    def validate_code(cls, code: str) -> List[str]:
        """Validate campaign code.

        Args:
            code: Campaign code.

        Returns:
            List of validation errors (empty if valid).
        """
        errors = []

        if not code:
            errors.append("Campaign code is required")
            return errors

        if len(code) < cls.CODE_MIN_LENGTH:
            errors.append(
                f"Campaign code must be at least {cls.CODE_MIN_LENGTH} characters"
            )

        if len(code) > cls.CODE_MAX_LENGTH:
            errors.append(
                f"Campaign code must be at most {cls.CODE_MAX_LENGTH} characters"
            )

        if not re.match(cls.CODE_PATTERN, code):
            errors.append(
                "Campaign code must contain only uppercase letters, numbers, underscores, and hyphens"
            )

        return errors

    @classmethod
    def validate_name(cls, name: str) -> List[str]:
        """Validate campaign name.

        Args:
            name: Campaign name.

        Returns:
            List of validation errors.
        """
        errors = []

        if not name:
            errors.append("Campaign name is required")
            return errors

        if len(name) < cls.NAME_MIN_LENGTH:
            errors.append(
                f"Campaign name must be at least {cls.NAME_MIN_LENGTH} characters"
            )

        if len(name) > cls.NAME_MAX_LENGTH:
            errors.append(
                f"Campaign name must be at most {cls.NAME_MAX_LENGTH} characters"
            )

        return errors

    @classmethod
    def validate_discount_percent(cls, discount: int) -> List[str]:
        """Validate discount percentage.

        Args:
            discount: Discount percentage.

        Returns:
            List of validation errors.
        """
        errors = []

        if discount < cls.DISCOUNT_MIN:
            errors.append(f"Discount must be at least {cls.DISCOUNT_MIN}%")

        if discount > cls.DISCOUNT_MAX:
            errors.append(f"Discount must be at most {cls.DISCOUNT_MAX}%")

        return errors

    @classmethod
    def validate_price(cls, price: Decimal) -> List[str]:
        """Validate price value.

        Args:
            price: Price value.

        Returns:
            List of validation errors.
        """
        errors = []

        if price < cls.PRICE_MIN:
            errors.append(f"Price must be at least {cls.PRICE_MIN}")

        if price > cls.PRICE_MAX:
            errors.append(f"Price must be at most {cls.PRICE_MAX}")

        return errors

    @classmethod
    def validate_date_range(cls, from_date: str, to_date: str) -> List[str]:
        """Validate date range.

        Args:
            from_date: Start date (ISO 8601).
            to_date: End date (ISO 8601).

        Returns:
            List of validation errors.
        """
        errors = []

        try:
            from_dt = DateUtils.parse_iso(from_date)
        except ValueError:
            errors.append("Invalid from_date format. Use ISO 8601 format.")
            return errors

        try:
            to_dt = DateUtils.parse_iso(to_date)
        except ValueError:
            errors.append("Invalid to_date format. Use ISO 8601 format.")
            return errors

        if to_dt <= from_dt:
            errors.append("to_date must be after from_date")

        return errors

    @classmethod
    def validate_terms_and_conditions(cls, terms: str) -> List[str]:
        """Validate terms and conditions.

        Args:
            terms: Terms and conditions text.

        Returns:
            List of validation errors.
        """
        errors = []

        if not terms:
            errors.append("Terms and conditions are required")
            return errors

        if len(terms) < cls.TERMS_MIN_LENGTH:
            errors.append(
                f"Terms and conditions must be at least {cls.TERMS_MIN_LENGTH} characters"
            )

        if len(terms) > cls.TERMS_MAX_LENGTH:
            errors.append(
                f"Terms and conditions must be at most {cls.TERMS_MAX_LENGTH} characters"
            )

        return errors

    @classmethod
    def validate_create_request(
        cls,
        code: str,
        name: str,
        discount_percent: int,
        list_price: Decimal,
        terms_and_conditions: str,
        from_date: str,
        to_date: str,
    ) -> None:
        """Validate all fields for create request.

        Args:
            code: Campaign code.
            name: Campaign name.
            discount_percent: Discount percentage.
            list_price: List price.
            terms_and_conditions: Terms text.
            from_date: Start date.
            to_date: End date.

        Raises:
            ValidationException: If validation fails.
        """
        all_errors = []

        all_errors.extend(cls.validate_code(code))
        all_errors.extend(cls.validate_name(name))
        all_errors.extend(cls.validate_discount_percent(discount_percent))
        all_errors.extend(cls.validate_price(list_price))
        all_errors.extend(cls.validate_terms_and_conditions(terms_and_conditions))
        all_errors.extend(cls.validate_date_range(from_date, to_date))

        if all_errors:
            raise ValidationException("Validation failed", errors=all_errors)
```

---

## Unit Tests

### tests/unit/utils/test_response_builder.py

```python
"""Unit tests for ResponseBuilder."""

import pytest
import json
from decimal import Decimal

from src.utils.response_builder import ResponseBuilder


class TestResponseBuilder:
    """Tests for ResponseBuilder."""

    def test_success_response(self):
        """Test 200 OK response."""
        response = ResponseBuilder.success({"data": "test"})
        assert response["statusCode"] == 200
        assert "data" in json.loads(response["body"])

    def test_created_response(self):
        """Test 201 Created response."""
        response = ResponseBuilder.created({"id": "123"})
        assert response["statusCode"] == 201

    def test_no_content_response(self):
        """Test 204 No Content response."""
        response = ResponseBuilder.no_content()
        assert response["statusCode"] == 204
        assert response["body"] == ""

    def test_bad_request_response(self):
        """Test 400 Bad Request response."""
        response = ResponseBuilder.bad_request("Invalid input")
        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert body["message"] == "Invalid input"

    def test_not_found_response(self):
        """Test 404 Not Found response."""
        response = ResponseBuilder.not_found({"error": "Not found"})
        assert response["statusCode"] == 404

    def test_cors_headers_included(self):
        """Test CORS headers are included."""
        response = ResponseBuilder.success({"test": True})
        assert "Access-Control-Allow-Origin" in response["headers"]

    def test_decimal_encoding(self):
        """Test Decimal values are encoded correctly."""
        response = ResponseBuilder.success({"price": Decimal("99.99")})
        body = json.loads(response["body"])
        assert body["price"] == 99.99
```

### tests/unit/utils/test_date_utils.py

```python
"""Unit tests for DateUtils."""

import pytest
from datetime import datetime, timezone, timedelta

from src.utils.date_utils import DateUtils


class TestDateUtils:
    """Tests for DateUtils."""

    def test_now_returns_utc(self):
        """Test now returns UTC datetime."""
        result = DateUtils.now()
        assert result.tzinfo == timezone.utc

    def test_parse_iso_with_z_suffix(self):
        """Test parsing ISO date with Z suffix."""
        result = DateUtils.parse_iso("2025-01-15T10:30:00Z")
        assert result.year == 2025
        assert result.month == 1
        assert result.day == 15

    def test_is_future_true(self):
        """Test is_future returns True for future date."""
        future = (datetime.now(timezone.utc) + timedelta(days=30)).isoformat()
        assert DateUtils.is_future(future) is True

    def test_is_future_false(self):
        """Test is_future returns False for past date."""
        past = (datetime.now(timezone.utc) - timedelta(days=30)).isoformat()
        assert DateUtils.is_future(past) is False

    def test_is_between_true(self):
        """Test is_between returns True when date is in range."""
        past = (datetime.now(timezone.utc) - timedelta(days=30)).isoformat()
        future = (datetime.now(timezone.utc) + timedelta(days=30)).isoformat()
        assert DateUtils.is_between(past, future) is True

    def test_is_between_false(self):
        """Test is_between returns False when date is out of range."""
        far_future1 = (datetime.now(timezone.utc) + timedelta(days=30)).isoformat()
        far_future2 = (datetime.now(timezone.utc) + timedelta(days=60)).isoformat()
        assert DateUtils.is_between(far_future1, far_future2) is False
```

---

## Success Criteria

- [ ] ResponseBuilder handles all response types
- [ ] ResponseBuilder encodes Decimal correctly
- [ ] CORS headers included in all responses
- [ ] DateUtils parses ISO dates correctly
- [ ] DateUtils handles timezone (UTC)
- [ ] CampaignValidator validates all fields
- [ ] Logger configured with aws-lambda-powertools
- [ ] All unit tests pass

---

## Execution Steps

1. Write unit tests for utilities (TDD)
2. Create src/utils/response_builder.py
3. Create src/utils/date_utils.py
4. Create src/utils/logger.py
5. Create src/validators/campaign_validator.py
6. Run tests to verify implementation
7. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
