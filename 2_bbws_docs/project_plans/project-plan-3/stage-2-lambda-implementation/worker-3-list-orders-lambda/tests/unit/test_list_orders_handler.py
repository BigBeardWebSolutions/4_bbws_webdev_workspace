"""
Unit tests for list_orders Lambda handler.

Tests the handler with mocked OrderDAO and various pagination scenarios.
"""
import pytest
import json
from unittest.mock import Mock, patch
from decimal import Decimal

from src.handlers.list_orders import lambda_handler
from src.models import Order


class TestListOrdersHandler:
    """Test suite for list_orders Lambda handler."""

    def test_list_orders_success_first_page(self, sample_order_data):
        """Test successful order listing on first page."""
        # Arrange
        orders = [Order(**sample_order_data)]
        mock_dao_result = {
            'items': orders,
            'startAt': None,
            'moreAvailable': False
        }

        event = {
            "pathParameters": {
                "tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006"
            },
            "queryStringParameters": None
        }

        with patch('src.handlers.list_orders.order_dao') as mock_dao:
            mock_dao.find_by_tenant_id.return_value = mock_dao_result

            # Act
            response = lambda_handler(event, None)

        # Assert
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['success'] is True
        assert len(body['data']['items']) == 1
        assert body['data']['items'][0]['id'] == 'order_aa0e8400-e29b-41d4-a716-446655440005'
        assert body['data']['moreAvailable'] is False
        assert body['data']['startAt'] is None

        # Verify DAO call
        mock_dao.find_by_tenant_id.assert_called_once_with(
            'tenant_bb0e8400-e29b-41d4-a716-446655440006',
            50,
            None
        )

    def test_list_orders_with_custom_page_size(self, sample_order_data):
        """Test order listing with custom page size."""
        # Arrange
        orders = [Order(**sample_order_data)]
        mock_dao_result = {
            'items': orders,
            'startAt': None,
            'moreAvailable': False
        }

        event = {
            "pathParameters": {
                "tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006"
            },
            "queryStringParameters": {
                "pageSize": "25"
            }
        }

        with patch('src.handlers.list_orders.order_dao') as mock_dao:
            mock_dao.find_by_tenant_id.return_value = mock_dao_result

            # Act
            response = lambda_handler(event, None)

        # Assert
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['success'] is True

        # Verify DAO called with custom page size
        mock_dao.find_by_tenant_id.assert_called_once_with(
            'tenant_bb0e8400-e29b-41d4-a716-446655440006',
            25,
            None
        )

    def test_list_orders_with_pagination_continuation(self, sample_order_data):
        """Test order listing with pagination continuation token."""
        # Arrange
        orders = [Order(**sample_order_data)]
        next_token = json.dumps({
            'PK': {'S': 'TENANT#tenant_bb0e8400-e29b-41d4-a716-446655440006'},
            'SK': {'S': 'ORDER#order_bb0e8400-e29b-41d4-a716-446655440010'}
        })

        mock_dao_result = {
            'items': orders,
            'startAt': next_token,
            'moreAvailable': True
        }

        event = {
            "pathParameters": {
                "tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006"
            },
            "queryStringParameters": {
                "startAt": next_token
            }
        }

        with patch('src.handlers.list_orders.order_dao') as mock_dao:
            mock_dao.find_by_tenant_id.return_value = mock_dao_result

            # Act
            response = lambda_handler(event, None)

        # Assert
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['success'] is True
        assert body['data']['moreAvailable'] is True
        assert body['data']['startAt'] is not None

        # Verify DAO called with start_at token
        mock_dao.find_by_tenant_id.assert_called_once_with(
            'tenant_bb0e8400-e29b-41d4-a716-446655440006',
            50,
            next_token
        )

    def test_list_orders_empty_result(self):
        """Test order listing returns empty list."""
        # Arrange
        mock_dao_result = {
            'items': [],
            'startAt': None,
            'moreAvailable': False
        }

        event = {
            "pathParameters": {
                "tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006"
            },
            "queryStringParameters": None
        }

        with patch('src.handlers.list_orders.order_dao') as mock_dao:
            mock_dao.find_by_tenant_id.return_value = mock_dao_result

            # Act
            response = lambda_handler(event, None)

        # Assert
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['success'] is True
        assert len(body['data']['items']) == 0
        assert body['data']['moreAvailable'] is False

    def test_list_orders_missing_tenant_id(self):
        """Test error when tenantId is missing."""
        # Arrange
        event = {
            "pathParameters": {},
            "queryStringParameters": None
        }

        # Act
        response = lambda_handler(event, None)

        # Assert
        assert response['statusCode'] == 400
        body = json.loads(response['body'])
        assert body['error'] == 'Bad Request'
        assert 'tenantId' in body['message']

    def test_list_orders_invalid_page_size_negative(self):
        """Test error when pageSize is negative."""
        # Arrange
        event = {
            "pathParameters": {
                "tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006"
            },
            "queryStringParameters": {
                "pageSize": "-5"
            }
        }

        # Act
        response = lambda_handler(event, None)

        # Assert
        assert response['statusCode'] == 400
        body = json.loads(response['body'])
        assert body['error'] == 'Bad Request'
        assert 'pageSize must be between 1 and 100' in body['message']

    def test_list_orders_invalid_page_size_exceeds_max(self):
        """Test error when pageSize exceeds maximum."""
        # Arrange
        event = {
            "pathParameters": {
                "tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006"
            },
            "queryStringParameters": {
                "pageSize": "150"
            }
        }

        # Act
        response = lambda_handler(event, None)

        # Assert
        assert response['statusCode'] == 400
        body = json.loads(response['body'])
        assert body['error'] == 'Bad Request'
        assert 'pageSize must be between 1 and 100' in body['message']

    def test_list_orders_invalid_page_size_format(self):
        """Test error when pageSize is not an integer."""
        # Arrange
        event = {
            "pathParameters": {
                "tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006"
            },
            "queryStringParameters": {
                "pageSize": "abc"
            }
        }

        # Act
        response = lambda_handler(event, None)

        # Assert
        assert response['statusCode'] == 400
        body = json.loads(response['body'])
        assert body['error'] == 'Bad Request'
        assert 'pageSize must be an integer' in body['message']

    def test_list_orders_dao_error(self):
        """Test error handling when DAO raises exception."""
        # Arrange
        event = {
            "pathParameters": {
                "tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006"
            },
            "queryStringParameters": None
        }

        with patch('src.handlers.list_orders.order_dao') as mock_dao:
            mock_dao.find_by_tenant_id.side_effect = Exception('DynamoDB error')

            # Act
            response = lambda_handler(event, None)

        # Assert
        assert response['statusCode'] == 500
        body = json.loads(response['body'])
        assert body['error'] == 'Internal Server Error'

    def test_list_orders_missing_path_parameters(self):
        """Test error when pathParameters is missing."""
        # Arrange
        event = {
            "queryStringParameters": None
        }

        # Act
        response = lambda_handler(event, None)

        # Assert
        assert response['statusCode'] == 400
        body = json.loads(response['body'])
        assert body['error'] == 'Bad Request'
        assert 'path parameters' in body['message']

    def test_list_orders_response_headers(self):
        """Test that response includes proper CORS headers."""
        # Arrange
        mock_dao_result = {
            'items': [],
            'startAt': None,
            'moreAvailable': False
        }

        event = {
            "pathParameters": {
                "tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006"
            },
            "queryStringParameters": None
        }

        with patch('src.handlers.list_orders.order_dao') as mock_dao:
            mock_dao.find_by_tenant_id.return_value = mock_dao_result

            # Act
            response = lambda_handler(event, None)

        # Assert
        assert 'headers' in response
        assert response['headers']['Content-Type'] == 'application/json'
        assert response['headers']['Access-Control-Allow-Origin'] == '*'
        assert 'Access-Control-Allow-Methods' in response['headers']

    def test_list_orders_max_page_size(self, sample_order_data):
        """Test order listing with maximum allowed page size."""
        # Arrange
        orders = [Order(**sample_order_data)]
        mock_dao_result = {
            'items': orders,
            'startAt': None,
            'moreAvailable': False
        }

        event = {
            "pathParameters": {
                "tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006"
            },
            "queryStringParameters": {
                "pageSize": "100"
            }
        }

        with patch('src.handlers.list_orders.order_dao') as mock_dao:
            mock_dao.find_by_tenant_id.return_value = mock_dao_result

            # Act
            response = lambda_handler(event, None)

        # Assert
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['success'] is True

        # Verify DAO called with max page size
        mock_dao.find_by_tenant_id.assert_called_once_with(
            'tenant_bb0e8400-e29b-41d4-a716-446655440006',
            100,
            None
        )
