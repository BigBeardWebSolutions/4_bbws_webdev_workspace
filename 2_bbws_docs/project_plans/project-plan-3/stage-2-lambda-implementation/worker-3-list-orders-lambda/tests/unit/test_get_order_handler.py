"""
Unit tests for get_order Lambda handler.

Tests the Lambda handler logic with mocked dependencies.
"""
import pytest
import json
from unittest.mock import Mock, patch, MagicMock
from decimal import Decimal

from src.handlers import get_order
from src.models import Order


class TestGetOrderHandler:
    """Test suite for get_order Lambda handler."""

    @patch('src.handlers.get_order.order_dao')
    def test_lambda_handler_success(self, mock_dao, sample_api_gateway_event, sample_order_data):
        """Test successful order retrieval."""
        # Arrange
        mock_order = Order(**sample_order_data)
        mock_dao.get_order.return_value = mock_order

        # Act
        response = get_order.lambda_handler(sample_api_gateway_event, None)

        # Assert
        assert response['statusCode'] == 200
        assert 'Access-Control-Allow-Origin' in response['headers']

        body = json.loads(response['body'])
        assert body['success'] is True
        assert 'data' in body
        assert body['data']['id'] == 'order_aa0e8400-e29b-41d4-a716-446655440005'
        assert body['data']['orderNumber'] == 'ORD-20251215-0001'

        # Verify DAO was called with correct parameters
        mock_dao.get_order.assert_called_once_with(
            'tenant_bb0e8400-e29b-41d4-a716-446655440006',
            'order_aa0e8400-e29b-41d4-a716-446655440005'
        )

    @patch('src.handlers.get_order.order_dao')
    def test_lambda_handler_order_not_found(self, mock_dao, sample_api_gateway_event):
        """Test order not found scenario."""
        # Arrange
        mock_dao.get_order.return_value = None

        # Act
        response = get_order.lambda_handler(sample_api_gateway_event, None)

        # Assert
        assert response['statusCode'] == 404
        body = json.loads(response['body'])
        assert body['error'] == 'Not Found'
        assert 'Order not found' in body['message']

    @patch('src.handlers.get_order.order_dao')
    def test_lambda_handler_missing_order_id(self, mock_dao):
        """Test missing orderId in path parameters."""
        # Arrange
        event = {
            "pathParameters": {},
            "requestContext": {
                "authorizer": {
                    "claims": {"custom:tenantId": "tenant_123"}
                }
            }
        }

        # Act
        response = get_order.lambda_handler(event, None)

        # Assert
        assert response['statusCode'] == 400
        body = json.loads(response['body'])
        assert body['error'] == 'Bad Request'
        assert 'Missing orderId' in body['message']

    @patch('src.handlers.get_order.order_dao')
    def test_lambda_handler_missing_path_parameters(self, mock_dao):
        """Test missing pathParameters in event."""
        # Arrange
        event = {
            "requestContext": {
                "authorizer": {
                    "claims": {"custom:tenantId": "tenant_123"}
                }
            }
        }

        # Act
        response = get_order.lambda_handler(event, None)

        # Assert
        assert response['statusCode'] == 400
        body = json.loads(response['body'])
        assert body['error'] == 'Bad Request'

    @patch('src.handlers.get_order.order_dao')
    def test_lambda_handler_missing_tenant_id(self, mock_dao):
        """Test missing tenantId in JWT claims."""
        # Arrange
        event = {
            "pathParameters": {"orderId": "order_123"},
            "requestContext": {
                "authorizer": {
                    "claims": {}
                }
            }
        }

        # Act
        response = get_order.lambda_handler(event, None)

        # Assert
        assert response['statusCode'] == 401
        body = json.loads(response['body'])
        assert body['error'] == 'Unauthorized'
        assert 'Missing tenant identifier' in body['message']

    @patch('src.handlers.get_order.order_dao')
    def test_lambda_handler_dao_exception(self, mock_dao, sample_api_gateway_event):
        """Test handling of DAO exceptions."""
        # Arrange
        mock_dao.get_order.side_effect = Exception('DynamoDB connection error')

        # Act
        response = get_order.lambda_handler(sample_api_gateway_event, None)

        # Assert
        assert response['statusCode'] == 500
        body = json.loads(response['body'])
        assert body['error'] == 'Internal Server Error'
        assert 'unexpected error' in body['message']

    def test_extract_tenant_id_success(self):
        """Test successful extraction of tenantId from JWT."""
        # Arrange
        event = {
            "requestContext": {
                "authorizer": {
                    "claims": {"custom:tenantId": "tenant_123"}
                }
            }
        }

        # Act
        tenant_id = get_order._extract_tenant_id(event)

        # Assert
        assert tenant_id == 'tenant_123'

    def test_extract_tenant_id_missing_claims(self):
        """Test extraction when claims are missing."""
        # Arrange
        event = {"requestContext": {}}

        # Act
        tenant_id = get_order._extract_tenant_id(event)

        # Assert
        assert tenant_id == ''

    def test_build_response(self):
        """Test _build_response helper function."""
        # Arrange
        body = {'success': True, 'data': {'id': '123'}}

        # Act
        response = get_order._build_response(200, body)

        # Assert
        assert response['statusCode'] == 200
        assert response['headers']['Content-Type'] == 'application/json'
        assert response['headers']['Access-Control-Allow-Origin'] == '*'
        assert json.loads(response['body']) == body

    @patch('src.handlers.get_order.order_dao')
    def test_lambda_handler_cors_headers(self, mock_dao, sample_api_gateway_event, sample_order_data):
        """Test that CORS headers are present in all responses."""
        # Arrange
        mock_order = Order(**sample_order_data)
        mock_dao.get_order.return_value = mock_order

        # Act
        response = get_order.lambda_handler(sample_api_gateway_event, None)

        # Assert
        assert 'Access-Control-Allow-Origin' in response['headers']
        assert 'Access-Control-Allow-Headers' in response['headers']
        assert 'Access-Control-Allow-Methods' in response['headers']
