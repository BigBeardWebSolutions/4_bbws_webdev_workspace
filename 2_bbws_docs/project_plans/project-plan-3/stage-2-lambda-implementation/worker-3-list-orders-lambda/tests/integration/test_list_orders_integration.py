"""
Integration tests for list_orders Lambda handler.

Tests the complete request/response flow with realistic API Gateway events.
"""
import pytest
import json
from unittest.mock import Mock, patch
from decimal import Decimal

from src.handlers.list_orders import lambda_handler


class TestListOrdersIntegration:
    """Integration test suite for list_orders Lambda handler."""

    def test_list_orders_api_gateway_event(self, sample_order_data):
        """Test list_orders with realistic API Gateway event."""
        # Arrange
        from src.models import Order
        orders = [Order(**sample_order_data)]
        mock_dao_result = {
            'items': orders,
            'startAt': None,
            'moreAvailable': False
        }

        api_event = {
            "resource": "/v1.0/tenants/{tenantId}/orders",
            "path": "/v1.0/tenants/tenant_bb0e8400-e29b-41d4-a716-446655440006/orders",
            "httpMethod": "GET",
            "pathParameters": {
                "tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006"
            },
            "queryStringParameters": None,
            "headers": {
                "Accept": "application/json",
                "User-Agent": "curl/7.64.1"
            }
        }

        with patch('src.handlers.list_orders.order_dao') as mock_dao:
            mock_dao.find_by_tenant_id.return_value = mock_dao_result

            # Act
            response = lambda_handler(api_event, None)

        # Assert
        assert response['statusCode'] == 200
        assert 'headers' in response
        assert 'body' in response

        body = json.loads(response['body'])
        assert body['success'] is True
        assert 'data' in body
        assert 'items' in body['data']
        assert len(body['data']['items']) == 1

    def test_list_orders_with_pagination_api_event(self, sample_order_data):
        """Test list_orders with pagination parameters in realistic event."""
        # Arrange
        from src.models import Order

        # Create multiple orders
        order1 = sample_order_data.copy()
        order2 = sample_order_data.copy()
        order2['id'] = 'order_bb0e8400-e29b-41d4-a716-446655440010'
        order2['orderNumber'] = 'ORD-20251215-0002'

        orders = [Order(**order1), Order(**order2)]

        next_token = json.dumps({
            'PK': {'S': 'TENANT#tenant_bb0e8400-e29b-41d4-a716-446655440006'},
            'SK': {'S': 'ORDER#order_cc0e8400-e29b-41d4-a716-446655440015'}
        })

        mock_dao_result = {
            'items': orders,
            'startAt': next_token,
            'moreAvailable': True
        }

        api_event = {
            "resource": "/v1.0/tenants/{tenantId}/orders",
            "path": "/v1.0/tenants/tenant_bb0e8400-e29b-41d4-a716-446655440006/orders",
            "httpMethod": "GET",
            "pathParameters": {
                "tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006"
            },
            "queryStringParameters": {
                "pageSize": "2",
                "startAt": None
            },
            "headers": {
                "Accept": "application/json"
            }
        }

        with patch('src.handlers.list_orders.order_dao') as mock_dao:
            mock_dao.find_by_tenant_id.return_value = mock_dao_result

            # Act
            response = lambda_handler(api_event, None)

        # Assert
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['success'] is True
        assert len(body['data']['items']) == 2
        assert body['data']['moreAvailable'] is True
        assert body['data']['startAt'] is not None

        # Verify pagination token is valid JSON
        next_token_parsed = json.loads(body['data']['startAt'])
        assert 'PK' in next_token_parsed
        assert 'SK' in next_token_parsed

    def test_list_orders_continuation_flow(self, sample_order_data):
        """Test list_orders pagination continuation flow."""
        # Arrange
        from src.models import Order

        # First page request
        first_api_event = {
            "pathParameters": {
                "tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006"
            },
            "queryStringParameters": {
                "pageSize": "1"
            }
        }

        first_page_token = json.dumps({
            'PK': {'S': 'TENANT#tenant_bb0e8400-e29b-41d4-a716-446655440006'},
            'SK': {'S': 'ORDER#order_bb0e8400-e29b-41d4-a716-446655440010'}
        })

        orders = [Order(**sample_order_data)]
        first_page_result = {
            'items': orders,
            'startAt': first_page_token,
            'moreAvailable': True
        }

        with patch('src.handlers.list_orders.order_dao') as mock_dao:
            mock_dao.find_by_tenant_id.return_value = first_page_result

            # Act: Get first page
            response1 = lambda_handler(first_api_event, None)

        # Assert: First page has continuation token
        assert response1['statusCode'] == 200
        body1 = json.loads(response1['body'])
        assert body1['data']['moreAvailable'] is True
        continuation_token = body1['data']['startAt']

        # Second page request with continuation token
        second_api_event = {
            "pathParameters": {
                "tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006"
            },
            "queryStringParameters": {
                "pageSize": "1",
                "startAt": continuation_token
            }
        }

        second_page_result = {
            'items': orders,
            'startAt': None,
            'moreAvailable': False
        }

        with patch('src.handlers.list_orders.order_dao') as mock_dao:
            mock_dao.find_by_tenant_id.return_value = second_page_result

            # Act: Get second page
            response2 = lambda_handler(second_api_event, None)

        # Assert: Second page has no more items
        assert response2['statusCode'] == 200
        body2 = json.loads(response2['body'])
        assert body2['data']['moreAvailable'] is False
        assert body2['data']['startAt'] is None

    def test_list_orders_error_response_format(self):
        """Test error response follows API contract."""
        # Arrange
        error_event = {
            "pathParameters": {},
            "queryStringParameters": None
        }

        # Act
        response = lambda_handler(error_event, None)

        # Assert: Error response format
        assert response['statusCode'] == 400
        assert response['headers']['Content-Type'] == 'application/json'

        body = json.loads(response['body'])
        assert 'error' in body
        assert 'message' in body
        assert body['success'] is not True  # Should not have success:true on error

    def test_list_orders_response_structure(self, sample_order_data):
        """Test response structure matches API contract."""
        # Arrange
        from src.models import Order
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

        # Assert: Response structure
        assert response['statusCode'] == 200
        assert 'body' in response
        assert 'headers' in response

        body = json.loads(response['body'])
        # Response must have success, data
        assert 'success' in body
        assert 'data' in body

        # Data must have items, startAt, moreAvailable
        data = body['data']
        assert 'items' in data
        assert 'startAt' in data
        assert 'moreAvailable' in data

        # Each item must be a complete Order object
        assert isinstance(data['items'], list)
        if len(data['items']) > 0:
            item = data['items'][0]
            assert 'id' in item
            assert 'orderNumber' in item
            assert 'tenantId' in item
            assert 'status' in item
            assert 'total' in item

    def test_list_orders_large_page_size_rejected(self):
        """Test that oversized page requests are rejected."""
        # Arrange
        event = {
            "pathParameters": {
                "tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006"
            },
            "queryStringParameters": {
                "pageSize": "1000"
            }
        }

        # Act
        response = lambda_handler(event, None)

        # Assert: Should reject with 400
        assert response['statusCode'] == 400
        body = json.loads(response['body'])
        assert 'pageSize' in body['message']

    def test_list_orders_default_page_size_used(self, sample_order_data):
        """Test that default page size is used when not specified."""
        # Arrange
        from src.models import Order
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

        # Verify DAO was called with default page size (50)
        mock_dao.find_by_tenant_id.assert_called_once()
        call_args = mock_dao.find_by_tenant_id.call_args[0]
        assert call_args[1] == 50  # page_size parameter
