"""Unit tests for update_order Lambda handler."""

import json
from unittest.mock import MagicMock, patch

import pytest

from src.models.order import OrderStatus
from src.utils.exceptions import (
    OrderNotFoundException,
    OptimisticLockException,
    InvalidOrderStateException
)


class TestUpdateOrderHandler:
    """Tests for update_order Lambda handler."""

    @patch('src.handlers.update_order.order_service')
    def test_handler_success(self, mock_service, api_gateway_event, lambda_context, sample_order):
        """Test successful order update."""
        updated_order = sample_order.copy(deep=True)
        updated_order.status = OrderStatus.PAID
        mock_service.update_order.return_value = updated_order

        from src.handlers.update_order import lambda_handler

        response = lambda_handler(api_gateway_event, lambda_context)

        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['success'] is True
        assert body['data']['status'] == 'paid'

    @patch('src.handlers.update_order.order_service')
    def test_handler_missing_order_id(self, mock_service, lambda_context):
        """Test handler with missing orderId."""
        event = {
            'pathParameters': {},
            'body': '{"status": "paid"}',
            'requestContext': {
                'authorizer': {
                    'claims': {
                        'custom:tenantId': 'tenant-123',
                        'email': 'user@example.com'
                    }
                }
            }
        }

        from src.handlers.update_order import lambda_handler

        response = lambda_handler(event, lambda_context)

        assert response['statusCode'] == 400
        body = json.loads(response['body'])
        assert body['success'] is False
        assert 'orderId' in body['message'].lower()

    @patch('src.handlers.update_order.order_service')
    def test_handler_missing_tenant_id(self, mock_service, lambda_context):
        """Test handler with missing tenantId in JWT."""
        event = {
            'pathParameters': {'orderId': 'order-123'},
            'body': '{"status": "paid"}',
            'requestContext': {
                'authorizer': {
                    'claims': {
                        'email': 'user@example.com'
                    }
                }
            }
        }

        from src.handlers.update_order import lambda_handler

        response = lambda_handler(event, lambda_context)

        assert response['statusCode'] == 403
        body = json.loads(response['body'])
        assert body['success'] is False

    @patch('src.handlers.update_order.order_service')
    def test_handler_invalid_json(self, mock_service, lambda_context):
        """Test handler with invalid JSON body."""
        event = {
            'pathParameters': {'orderId': 'order-123'},
            'body': 'invalid json',
            'requestContext': {
                'authorizer': {
                    'claims': {
                        'custom:tenantId': 'tenant-123',
                        'email': 'user@example.com'
                    }
                }
            }
        }

        from src.handlers.update_order import lambda_handler

        response = lambda_handler(event, lambda_context)

        assert response['statusCode'] == 400

    @patch('src.handlers.update_order.order_service')
    def test_handler_order_not_found(self, mock_service, api_gateway_event, lambda_context):
        """Test handler when order not found."""
        mock_service.update_order.side_effect = OrderNotFoundException("Order not found")

        from src.handlers.update_order import lambda_handler

        response = lambda_handler(api_gateway_event, lambda_context)

        assert response['statusCode'] == 404
        body = json.loads(response['body'])
        assert body['success'] is False
        assert 'not found' in body['message'].lower()

    @patch('src.handlers.update_order.order_service')
    def test_handler_optimistic_lock_failure(self, mock_service, api_gateway_event, lambda_context):
        """Test handler when optimistic lock fails."""
        mock_service.update_order.side_effect = OptimisticLockException(
            "Order was modified by another process"
        )

        from src.handlers.update_order import lambda_handler

        response = lambda_handler(api_gateway_event, lambda_context)

        assert response['statusCode'] == 409
        body = json.loads(response['body'])
        assert body['success'] is False
        assert 'modified' in body['message'].lower()

    @patch('src.handlers.update_order.order_service')
    def test_handler_invalid_order_state(self, mock_service, api_gateway_event, lambda_context):
        """Test handler when order is in invalid state."""
        mock_service.update_order.side_effect = InvalidOrderStateException(
            "Cannot update order in completed state"
        )

        from src.handlers.update_order import lambda_handler

        response = lambda_handler(api_gateway_event, lambda_context)

        assert response['statusCode'] == 400
        body = json.loads(response['body'])
        assert body['success'] is False
        assert 'completed' in body['message'].lower()

    @patch('src.handlers.update_order.order_service')
    def test_handler_internal_error(self, mock_service, api_gateway_event, lambda_context):
        """Test handler when internal error occurs."""
        mock_service.update_order.side_effect = Exception("Database connection failed")

        from src.handlers.update_order import lambda_handler

        response = lambda_handler(api_gateway_event, lambda_context)

        assert response['statusCode'] == 500
        body = json.loads(response['body'])
        assert body['success'] is False
        assert body['error'] == 'Internal Server Error'

    @patch('src.handlers.update_order.order_service')
    def test_handler_cors_headers(self, mock_service, api_gateway_event, lambda_context, sample_order):
        """Test handler includes CORS headers."""
        mock_service.update_order.return_value = sample_order

        from src.handlers.update_order import lambda_handler

        response = lambda_handler(api_gateway_event, lambda_context)

        assert 'Access-Control-Allow-Origin' in response['headers']
        assert response['headers']['Access-Control-Allow-Origin'] == '*'

    @patch('src.handlers.update_order.order_service')
    def test_handler_extracts_user_email(self, mock_service, api_gateway_event, lambda_context, sample_order):
        """Test handler extracts user email from JWT."""
        mock_service.update_order.return_value = sample_order

        from src.handlers.update_order import lambda_handler

        lambda_handler(api_gateway_event, lambda_context)

        # Verify update_order was called with correct updated_by
        call_args = mock_service.update_order.call_args
        assert call_args[1]['updated_by'] == 'user@example.com'

    @patch('src.handlers.update_order.order_service')
    def test_handler_empty_body(self, mock_service, lambda_context):
        """Test handler with empty request body."""
        event = {
            'pathParameters': {'orderId': 'order-123'},
            'body': '{}',
            'requestContext': {
                'authorizer': {
                    'claims': {
                        'custom:tenantId': 'tenant-123',
                        'email': 'user@example.com'
                    }
                }
            }
        }

        mock_service.update_order.side_effect = InvalidOrderStateException("No updates provided")

        from src.handlers.update_order import lambda_handler

        response = lambda_handler(event, lambda_context)

        assert response['statusCode'] == 400
