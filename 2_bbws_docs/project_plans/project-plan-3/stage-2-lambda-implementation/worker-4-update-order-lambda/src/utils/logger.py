"""Logging configuration for Order Lambda."""

import logging
import os
import sys


def configure_logger(name: str = None) -> logging.Logger:
    """
    Configure structured logging for Lambda.

    Args:
        name: Logger name (defaults to root logger)

    Returns:
        Configured logger instance
    """
    logger = logging.getLogger(name)

    # Get log level from environment (default: INFO)
    log_level = os.environ.get('LOG_LEVEL', 'INFO').upper()
    logger.setLevel(getattr(logging, log_level, logging.INFO))

    # Configure handler if not already configured
    if not logger.handlers:
        handler = logging.StreamHandler(sys.stdout)
        handler.setLevel(logger.level)

        # JSON-like format for CloudWatch
        formatter = logging.Formatter(
            '%(levelname)s %(name)s [%(funcName)s:%(lineno)d] %(message)s'
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)

    return logger
