"""Custom exceptions for Order Lambda."""


class BusinessException(Exception):
    """Base class for business logic exceptions (4xx errors)."""

    def __init__(self, message: str, error_code: str = "BUSINESS_ERROR"):
        """
        Initialize business exception.

        Args:
            message: Error message
            error_code: Error code for client identification
        """
        super().__init__(message)
        self.message = message
        self.error_code = error_code


class UnexpectedException(Exception):
    """Base class for unexpected system exceptions (5xx errors)."""

    def __init__(self, message: str, cause: Exception = None):
        """
        Initialize unexpected exception.

        Args:
            message: Error message
            cause: Original exception that caused this error
        """
        super().__init__(message)
        self.message = message
        self.cause = cause


class OrderNotFoundException(BusinessException):
    """Order not found exception (404)."""

    def __init__(self, message: str = "Order not found"):
        """Initialize order not found exception."""
        super().__init__(message, "ORDER_NOT_FOUND")


class OptimisticLockException(BusinessException):
    """Optimistic locking failure exception (409 Conflict)."""

    def __init__(self, message: str = "Order was modified by another process"):
        """Initialize optimistic lock exception."""
        super().__init__(message, "OPTIMISTIC_LOCK_FAILURE")


class InvalidOrderStateException(BusinessException):
    """Invalid order state for requested operation (400)."""

    def __init__(self, message: str = "Invalid order state for this operation"):
        """Initialize invalid order state exception."""
        super().__init__(message, "INVALID_ORDER_STATE")


class DatabaseException(UnexpectedException):
    """Database operation failed (500)."""

    def __init__(self, message: str = "Database operation failed", cause: Exception = None):
        """Initialize database exception."""
        super().__init__(message, cause)
