"""Custom exceptions for the Marketing Lambda."""


class BusinessException(Exception):
    """Base class for business logic exceptions (4xx errors)."""

    def __init__(self, message: str, status_code: int = 400) -> None:
        """Initialize business exception."""
        super().__init__(message)
        self.message = message
        self.status_code = status_code


class CampaignNotFoundException(BusinessException):
    """Raised when a campaign is not found."""

    def __init__(self, code: str) -> None:
        """Initialize campaign not found exception."""
        super().__init__(f"Campaign not found: {code}", status_code=404)
        self.code = code


class SystemException(Exception):
    """Base class for system exceptions (5xx errors)."""

    def __init__(self, message: str, status_code: int = 500) -> None:
        """Initialize system exception."""
        super().__init__(message)
        self.message = message
        self.status_code = status_code


class DynamoDBException(SystemException):
    """Raised when DynamoDB operations fail."""

    def __init__(self, message: str, original_error: Exception) -> None:
        """Initialize DynamoDB exception."""
        super().__init__(f"DynamoDB error: {message}", status_code=500)
        self.original_error = original_error
