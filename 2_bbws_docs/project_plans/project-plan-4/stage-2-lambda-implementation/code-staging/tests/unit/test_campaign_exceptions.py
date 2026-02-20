"""Unit tests for campaign exceptions."""

import pytest

from src.exceptions.campaign_exceptions import (
    BusinessException,
    CampaignNotFoundException,
    DynamoDBException,
    SystemException,
)


class TestBusinessException:
    """Tests for BusinessException."""

    def test_business_exception_default_status_code(self) -> None:
        """Test business exception with default status code."""
        exc = BusinessException("Test error")
        assert exc.message == "Test error"
        assert exc.status_code == 400

    def test_business_exception_custom_status_code(self) -> None:
        """Test business exception with custom status code."""
        exc = BusinessException("Not found", status_code=404)
        assert exc.message == "Not found"
        assert exc.status_code == 404


class TestCampaignNotFoundException:
    """Tests for CampaignNotFoundException."""

    def test_campaign_not_found_exception(self) -> None:
        """Test campaign not found exception."""
        exc = CampaignNotFoundException("SUMMER2025")
        assert exc.code == "SUMMER2025"
        assert "Campaign not found: SUMMER2025" in exc.message
        assert exc.status_code == 404

    def test_campaign_not_found_inherits_business_exception(self) -> None:
        """Test CampaignNotFoundException inherits from BusinessException."""
        exc = CampaignNotFoundException("TEST")
        assert isinstance(exc, BusinessException)


class TestSystemException:
    """Tests for SystemException."""

    def test_system_exception_default_status_code(self) -> None:
        """Test system exception with default status code."""
        exc = SystemException("System error")
        assert exc.message == "System error"
        assert exc.status_code == 500

    def test_system_exception_custom_status_code(self) -> None:
        """Test system exception with custom status code."""
        exc = SystemException("Service unavailable", status_code=503)
        assert exc.message == "Service unavailable"
        assert exc.status_code == 503


class TestDynamoDBException:
    """Tests for DynamoDBException."""

    def test_dynamodb_exception(self) -> None:
        """Test DynamoDB exception."""
        original = Exception("Connection timeout")
        exc = DynamoDBException("Failed to connect", original)

        assert "DynamoDB error: Failed to connect" in exc.message
        assert exc.status_code == 500
        assert exc.original_error == original

    def test_dynamodb_exception_inherits_system_exception(self) -> None:
        """Test DynamoDBException inherits from SystemException."""
        original = Exception("Test")
        exc = DynamoDBException("Test error", original)
        assert isinstance(exc, SystemException)
