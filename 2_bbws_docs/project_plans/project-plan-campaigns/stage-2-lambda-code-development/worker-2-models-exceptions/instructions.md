# Worker Instructions: Models & Exceptions

**Worker ID**: worker-2-models-exceptions
**Stage**: Stage 2 - Lambda Code Development
**Project**: project-plan-campaigns

---

## Task

Create Pydantic models and custom exceptions as defined in the LLD.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.3_LLD_Campaigns_Lambda.md`

**Reference**:
- Section 5.2: Pydantic Models
- Section 3: Component Diagram (exceptions)

---

## Deliverables

### 1. Pydantic Models (src/models/campaign.py)

```python
"""Pydantic models for Campaign entity."""

from pydantic import BaseModel, Field, field_validator, ConfigDict
from decimal import Decimal
from enum import Enum
from typing import Optional, List
from datetime import datetime


class CampaignStatus(str, Enum):
    """Campaign status enumeration."""
    DRAFT = "DRAFT"
    ACTIVE = "ACTIVE"
    EXPIRED = "EXPIRED"


class Campaign(BaseModel):
    """Campaign entity with date-based status validation."""
    model_config = ConfigDict(populate_by_name=True)

    code: str
    name: str
    product_id: str = Field(..., alias="productId")
    discount_percent: int = Field(..., alias="discountPercent", ge=0, le=100)
    list_price: Decimal = Field(..., alias="listPrice", gt=0)
    price: Decimal = Field(..., gt=0)
    terms_and_conditions: str = Field(..., alias="termsAndConditions")
    status: CampaignStatus
    from_date: str = Field(..., alias="fromDate")
    to_date: str = Field(..., alias="toDate")
    special_conditions: Optional[str] = Field(None, alias="specialConditions")
    date_created: datetime = Field(..., alias="dateCreated")
    date_last_updated: datetime = Field(..., alias="dateLastUpdated")
    last_updated_by: str = Field(..., alias="lastUpdatedBy")
    active: bool = True


class CampaignResponse(BaseModel):
    """Campaign response with validity flag."""
    model_config = ConfigDict(populate_by_name=True)

    code: str
    name: str
    product_id: str = Field(..., alias="productId")
    discount_percent: int = Field(..., alias="discountPercent")
    list_price: Decimal = Field(..., alias="listPrice")
    price: Decimal
    terms_and_conditions: str = Field(..., alias="termsAndConditions")
    status: CampaignStatus
    from_date: str = Field(..., alias="fromDate")
    to_date: str = Field(..., alias="toDate")
    special_conditions: Optional[str] = Field(None, alias="specialConditions")
    is_valid: bool = Field(..., alias="isValid")


class CampaignListResponse(BaseModel):
    """List response with campaign count."""
    model_config = ConfigDict(populate_by_name=True)

    campaigns: List[CampaignResponse]
    count: int


class CreateCampaignRequest(BaseModel):
    """Request to create new campaign."""
    model_config = ConfigDict(populate_by_name=True)

    code: str = Field(..., min_length=3, max_length=50, pattern=r"^[A-Z0-9_-]+$")
    name: str = Field(..., min_length=3, max_length=100)
    product_id: str = Field(..., alias="productId")
    discount_percent: int = Field(..., alias="discountPercent", ge=0, le=100)
    list_price: Decimal = Field(..., alias="listPrice", gt=0)
    terms_and_conditions: str = Field(
        ..., alias="termsAndConditions", min_length=10, max_length=1000
    )
    from_date: str = Field(..., alias="fromDate")
    to_date: str = Field(..., alias="toDate")
    special_conditions: Optional[str] = Field(
        None, alias="specialConditions", max_length=500
    )

    @field_validator("to_date")
    @classmethod
    def validate_date_range(cls, v: str, info) -> str:
        """Validate that to_date is after from_date."""
        from_date_value = info.data.get("from_date")
        if from_date_value:
            from_dt = datetime.fromisoformat(from_date_value.replace("Z", "+00:00"))
            to_dt = datetime.fromisoformat(v.replace("Z", "+00:00"))
            if to_dt <= from_dt:
                raise ValueError("to_date must be after from_date")
        return v

    @field_validator("code")
    @classmethod
    def validate_code_uppercase(cls, v: str) -> str:
        """Ensure code is uppercase."""
        return v.upper()


class UpdateCampaignRequest(BaseModel):
    """Request to update existing campaign."""
    model_config = ConfigDict(populate_by_name=True)

    name: Optional[str] = Field(None, min_length=3, max_length=100)
    product_id: Optional[str] = Field(None, alias="productId")
    discount_percent: Optional[int] = Field(None, alias="discountPercent", ge=0, le=100)
    list_price: Optional[Decimal] = Field(None, alias="listPrice", gt=0)
    terms_and_conditions: Optional[str] = Field(
        None, alias="termsAndConditions", min_length=10, max_length=1000
    )
    from_date: Optional[str] = Field(None, alias="fromDate")
    to_date: Optional[str] = Field(None, alias="toDate")
    special_conditions: Optional[str] = Field(
        None, alias="specialConditions", max_length=500
    )
    status: Optional[CampaignStatus] = None
    active: Optional[bool] = None

    def has_updates(self) -> bool:
        """Check if any field has a value to update."""
        return any(
            getattr(self, field) is not None
            for field in self.model_fields.keys()
        )
```

### 2. Custom Exceptions (src/exceptions/campaign_exceptions.py)

```python
"""Custom exceptions for Campaign service."""

from typing import Optional, List


class CampaignBaseException(Exception):
    """Base exception for Campaign service."""

    def __init__(
        self,
        message: str,
        status_code: int = 500,
        error_code: Optional[str] = None,
    ):
        self.message = message
        self.status_code = status_code
        self.error_code = error_code or self.__class__.__name__
        super().__init__(self.message)

    def to_dict(self) -> dict:
        """Convert exception to dictionary for API response."""
        return {
            "error": self.error_code,
            "message": self.message,
        }


class CampaignNotFoundException(CampaignBaseException):
    """Raised when a campaign is not found."""

    def __init__(self, code: str):
        super().__init__(
            message=f"Campaign with code {code} does not exist or is inactive",
            status_code=404,
            error_code="CampaignNotFound",
        )
        self.code = code


class ValidationException(CampaignBaseException):
    """Raised when validation fails."""

    def __init__(self, message: str, errors: Optional[List[str]] = None):
        super().__init__(
            message=message,
            status_code=400,
            error_code="ValidationError",
        )
        self.errors = errors or []

    def to_dict(self) -> dict:
        """Convert exception to dictionary with validation errors."""
        result = super().to_dict()
        if self.errors:
            result["errors"] = self.errors
        return result


class DuplicateCampaignException(CampaignBaseException):
    """Raised when attempting to create a campaign with existing code."""

    def __init__(self, code: str):
        super().__init__(
            message=f"Campaign code {code} already exists",
            status_code=400,
            error_code="DuplicateCampaign",
        )
        self.code = code


class DatabaseException(CampaignBaseException):
    """Raised when a database operation fails."""

    def __init__(self, message: str, original_error: Optional[Exception] = None):
        super().__init__(
            message=message,
            status_code=500,
            error_code="DatabaseError",
        )
        self.original_error = original_error


class InvalidRequestException(CampaignBaseException):
    """Raised when the request is malformed."""

    def __init__(self, message: str):
        super().__init__(
            message=message,
            status_code=400,
            error_code="InvalidRequest",
        )


class ServiceUnavailableException(CampaignBaseException):
    """Raised when a dependent service is unavailable."""

    def __init__(self, message: str = "Service temporarily unavailable"):
        super().__init__(
            message=message,
            status_code=503,
            error_code="ServiceUnavailable",
        )
```

---

## Unit Tests (TDD Approach)

Create tests BEFORE implementation:

### tests/unit/models/test_campaign.py

```python
"""Unit tests for Campaign models."""

import pytest
from decimal import Decimal
from datetime import datetime, timezone
from pydantic import ValidationError

from src.models.campaign import (
    Campaign,
    CampaignStatus,
    CampaignResponse,
    CreateCampaignRequest,
    UpdateCampaignRequest,
)


class TestCampaignStatus:
    """Tests for CampaignStatus enum."""

    def test_status_values(self):
        """Test that all expected status values exist."""
        assert CampaignStatus.DRAFT == "DRAFT"
        assert CampaignStatus.ACTIVE == "ACTIVE"
        assert CampaignStatus.EXPIRED == "EXPIRED"


class TestCreateCampaignRequest:
    """Tests for CreateCampaignRequest model."""

    def test_valid_request(self, sample_campaign_data):
        """Test creating a valid request."""
        request = CreateCampaignRequest(**sample_campaign_data)
        assert request.code == "SUMMER2025"
        assert request.discount_percent == 20

    def test_code_uppercase_validation(self):
        """Test that code is converted to uppercase."""
        data = {
            "code": "summer2025",
            "name": "Summer Sale",
            "productId": "PROD-001",
            "discountPercent": 10,
            "listPrice": Decimal("100.00"),
            "termsAndConditions": "Valid for new customers only.",
            "fromDate": "2025-06-01T00:00:00Z",
            "toDate": "2025-08-31T23:59:59Z",
        }
        request = CreateCampaignRequest(**data)
        assert request.code == "SUMMER2025"

    def test_invalid_discount_percent_over_100(self):
        """Test that discount over 100 is rejected."""
        data = {
            "code": "TEST2025",
            "name": "Test Sale",
            "productId": "PROD-001",
            "discountPercent": 150,  # Invalid
            "listPrice": Decimal("100.00"),
            "termsAndConditions": "Valid terms.",
            "fromDate": "2025-06-01T00:00:00Z",
            "toDate": "2025-08-31T23:59:59Z",
        }
        with pytest.raises(ValidationError):
            CreateCampaignRequest(**data)

    def test_invalid_date_range(self):
        """Test that to_date before from_date is rejected."""
        data = {
            "code": "TEST2025",
            "name": "Test Sale",
            "productId": "PROD-001",
            "discountPercent": 10,
            "listPrice": Decimal("100.00"),
            "termsAndConditions": "Valid terms.",
            "fromDate": "2025-08-31T00:00:00Z",
            "toDate": "2025-06-01T23:59:59Z",  # Before from_date
        }
        with pytest.raises(ValidationError):
            CreateCampaignRequest(**data)


class TestUpdateCampaignRequest:
    """Tests for UpdateCampaignRequest model."""

    def test_partial_update(self):
        """Test that partial updates are valid."""
        request = UpdateCampaignRequest(discount_percent=25)
        assert request.discount_percent == 25
        assert request.name is None

    def test_has_updates_true(self):
        """Test has_updates returns True when fields are set."""
        request = UpdateCampaignRequest(name="New Name")
        assert request.has_updates() is True

    def test_has_updates_false(self):
        """Test has_updates returns False when no fields set."""
        request = UpdateCampaignRequest()
        assert request.has_updates() is False
```

### tests/unit/exceptions/test_campaign_exceptions.py

```python
"""Unit tests for Campaign exceptions."""

import pytest

from src.exceptions.campaign_exceptions import (
    CampaignNotFoundException,
    ValidationException,
    DuplicateCampaignException,
    DatabaseException,
)


class TestCampaignNotFoundException:
    """Tests for CampaignNotFoundException."""

    def test_exception_message(self):
        """Test exception message format."""
        exc = CampaignNotFoundException("SUMMER2025")
        assert "SUMMER2025" in exc.message
        assert exc.status_code == 404

    def test_to_dict(self):
        """Test exception to_dict method."""
        exc = CampaignNotFoundException("SUMMER2025")
        result = exc.to_dict()
        assert result["error"] == "CampaignNotFound"
        assert "SUMMER2025" in result["message"]


class TestValidationException:
    """Tests for ValidationException."""

    def test_with_errors_list(self):
        """Test exception with validation errors list."""
        errors = ["Field1 is required", "Field2 must be positive"]
        exc = ValidationException("Validation failed", errors=errors)
        assert exc.status_code == 400
        assert len(exc.errors) == 2

    def test_to_dict_with_errors(self):
        """Test to_dict includes errors list."""
        errors = ["Error 1", "Error 2"]
        exc = ValidationException("Validation failed", errors=errors)
        result = exc.to_dict()
        assert "errors" in result
        assert result["errors"] == errors


class TestDuplicateCampaignException:
    """Tests for DuplicateCampaignException."""

    def test_exception_message(self):
        """Test exception message format."""
        exc = DuplicateCampaignException("SUMMER2025")
        assert "SUMMER2025" in exc.message
        assert "already exists" in exc.message
        assert exc.status_code == 400
```

---

## Success Criteria

- [ ] CampaignStatus enum with DRAFT, ACTIVE, EXPIRED
- [ ] Campaign model with all fields from LLD
- [ ] CampaignResponse model with isValid field
- [ ] CreateCampaignRequest with validation
- [ ] UpdateCampaignRequest with partial update support
- [ ] All custom exceptions implemented
- [ ] Unit tests pass for all models
- [ ] Unit tests pass for all exceptions

---

## Execution Steps

1. Write unit tests for models (TDD)
2. Create src/models/campaign.py
3. Write unit tests for exceptions (TDD)
4. Create src/exceptions/campaign_exceptions.py
5. Run tests to verify implementation
6. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
