"""Email Service for internal notification composition and sending."""

import os
import logging
from typing import Optional
from datetime import datetime
from jinja2 import Template, TemplateError

from src.models import Order
from src.services.s3_service import S3Service
from src.services.ses_service import SESService

logger = logging.getLogger(__name__)


class EmailService:
    """
    Service for composing and sending internal order notification emails.

    Handles template retrieval, rendering, and email delivery with fallback mechanisms.
    """

    def __init__(self):
        """Initialize EmailService with dependencies."""
        self.s3_service = S3Service()
        self.ses_service = SESService()
        self.template_key = 'internal/order_notification.html'
        self.admin_portal_url = os.environ.get(
            'ADMIN_PORTAL_URL',
            'https://admin.kimmyai.io'
        )
        logger.info("EmailService initialized")

    def send_internal_notification(self, order: Order) -> str:
        """
        Send internal notification email about new order.

        Args:
            order: Order object containing order details

        Returns:
            SES Message ID

        Raises:
            Exception: If email sending fails
        """
        try:
            logger.info(f"Preparing internal notification for order: {order.order_id}")

            # Retrieve template from S3
            template_html = self.s3_service.get_template(self.template_key)

            if template_html:
                # Render HTML template
                html_body = self.render_template(template_html, order)
                text_body = None
                logger.info("Using HTML template from S3")
            else:
                # Fallback to plain text email
                logger.warning(f"Template not found: {self.template_key}, using fallback plain text")
                html_body = None
                text_body = self._create_fallback_email(order)

            # Send email
            subject = f"New Order Received: {order.order_number}"
            message_id = self.ses_service.send_email(
                to_email=None,  # Uses default internal email
                subject=subject,
                html_body=html_body,
                text_body=text_body
            )

            logger.info(f"Internal notification sent successfully: MessageId={message_id}")
            return message_id

        except Exception as e:
            logger.error(f"Failed to send internal notification for order {order.order_id}: {str(e)}")
            raise

    def render_template(self, template_html: str, order: Order) -> str:
        """
        Render email template with order data using Jinja2.

        Args:
            template_html: HTML template string
            order: Order object for template context

        Returns:
            Rendered HTML string

        Raises:
            Exception: If template rendering fails
        """
        try:
            context = self._get_template_context(order)
            template = Template(template_html)
            rendered = template.render(**context)
            logger.debug(f"Template rendered successfully for order: {order.order_id}")
            return rendered

        except TemplateError as e:
            logger.error(f"Jinja2 template error: {str(e)}")
            raise Exception(f"Failed to render template: {str(e)}")

        except Exception as e:
            logger.error(f"Unexpected error rendering template: {str(e)}")
            raise Exception(f"Failed to render template: {str(e)}")

    def _get_template_context(self, order: Order) -> dict:
        """
        Build template context from order object.

        Args:
            order: Order object

        Returns:
            Dictionary with template variables
        """
        order_details_url = f"{self.admin_portal_url}/tenants/{order.tenant_id}/orders/{order.order_id}"

        return {
            'orderNumber': order.order_number,
            'customerEmail': order.customer_email,
            'customerName': order.customer_name,
            'total': order.total,
            'orderDate': order.created_at.strftime('%Y-%m-%d %H:%M:%S') if isinstance(order.created_at, datetime) else str(order.created_at),
            'itemCount': len(order.items),
            'orderDetailsUrl': order_details_url,
            'orderStatus': order.order_status,
            'paymentStatus': order.payment_status,
            'tenantId': order.tenant_id,
            'orderId': order.order_id
        }

    def _create_fallback_email(self, order: Order) -> str:
        """
        Create plain text fallback email when template is not available.

        Args:
            order: Order object

        Returns:
            Plain text email body
        """
        order_date = order.created_at.strftime('%Y-%m-%d %H:%M:%S') if isinstance(order.created_at, datetime) else str(order.created_at)
        order_details_url = f"{self.admin_portal_url}/tenants/{order.tenant_id}/orders/{order.order_id}"

        return f"""
New Order Received

Order Number: {order.order_number}
Order ID: {order.order_id}
Tenant ID: {order.tenant_id}

Customer Information:
- Name: {order.customer_name}
- Email: {order.customer_email}

Order Details:
- Items: {len(order.items)}
- Total Amount: R{order.total:.2f}
- Order Status: {order.order_status}
- Payment Status: {order.payment_status}
- Order Date: {order_date}

View Full Order Details:
{order_details_url}

---
This is an automated notification from the BBWS Order System.
        """.strip()
