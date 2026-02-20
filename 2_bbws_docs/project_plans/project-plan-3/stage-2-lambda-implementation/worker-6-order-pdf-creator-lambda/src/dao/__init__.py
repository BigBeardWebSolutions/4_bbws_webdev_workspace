"""
Data Access Objects for Order Lambda.

This module provides database access layer for DynamoDB operations.
"""

from src.dao.order_dao import OrderDAO

__all__ = ["OrderDAO"]
