"""
Lambda handlers for Order service.

This module contains AWS Lambda function handlers.
"""

from src.handlers.order_pdf_creator import lambda_handler

__all__ = ["lambda_handler"]
