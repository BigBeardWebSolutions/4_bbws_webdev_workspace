"""Email Service for customer confirmation and internal notification composition and sending."""

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
    Service for composing and sending order notification emails.

    Handles template retrieval, rendering, and email delivery with fallback mechanisms.
    Supports both internal notifications and customer confirmations.
    """

    def __init__(self):
        """Initialize EmailService with dependencies."""
        self.s3_service = S3Service()
        self.ses_service = SESService()
        self.internal_template_key = 'internal/order_notification.html'
        self.customer_template_key = 'customer/order_confirmation.html'
        self.admin_portal_url = os.environ.get(
            'ADMIN_PORTAL_URL',
            'https://admin.kimmyai.io'
        )
        self.customer_portal_url = os.environ.get(
            'CUSTOMER_PORTAL_URL',
            'https://customer.kimmyai.io'
        )
        self.invoice_bucket = os.environ.get(
            'INVOICE_BUCKET',
            'bbws-invoices-dev'
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
            template_html = self.s3_service.get_template(self.internal_template_key)

            if template_html:
                # Render HTML template
                html_body = self.render_template(template_html, order, email_type='internal')
                text_body = None
                logger.info("Using HTML template from S3")
            else:
                # Fallback to plain text email
                logger.warning(f"Template not found: {self.internal_template_key}, using fallback plain text")
                html_body = None
                text_body = self._create_fallback_internal_email(order)

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

    def send_customer_confirmation(self, order: Order) -> str:
        """
        Send customer confirmation email with presigned invoice URL.

        Args:
            order: Order object containing order details

        Returns:
            SES Message ID

        Raises:
            Exception: If email sending fails
        """
        try:
            logger.info(f"Preparing customer confirmation for order: {order.order_id}")

            # Retrieve template from S3
            template_html = self.s3_service.get_template(self.customer_template_key)

            if template_html:
                # Render HTML template with customer context and presigned URL
                html_body = self.render_template(template_html, order, email_type='customer')
                text_body = None
                logger.info("Using HTML template from S3")
            else:
                # Fallback to plain text email
                logger.warning(f"Template not found: {self.customer_template_key}, using fallback plain text")
                html_body = None
                text_body = self._create_fallback_customer_email(order)

            # Send email to customer
            subject = f"Order Confirmation - #{order.order_number}"
            message_id = self.ses_service.send_email(
                to_email=order.customer_email,
                subject=subject,
                html_body=html_body,
                text_body=text_body,
                reply_to='support@kimmyai.io'
            )

            logger.info(f"Customer confirmation sent successfully to {order.customer_email}: MessageId={message_id}")
            return message_id

        except Exception as e:
            logger.error(f"Failed to send customer confirmation for order {order.order_id}: {str(e)}")
            raise

    def render_template(self, template_html: str, order: Order, email_type: str = 'internal') -> str:
        """
        Render email template with order data using Jinja2.

        Args:
            template_html: HTML template string
            order: Order object for template context
            email_type: Type of email ('internal' or 'customer')

        Returns:
            Rendered HTML string

        Raises:
            Exception: If template rendering fails
        """
        try:
            context = self._get_template_context(order, email_type=email_type)
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

    def _get_template_context(self, order: Order, email_type: str = 'internal') -> dict:
        """
        Build template context from order object.

        Args:
            order: Order object
            email_type: Type of email ('internal' or 'customer')

        Returns:
            Dictionary with template variables
        """
        order_date = order.created_at.strftime('%Y-%m-%d %H:%M:%S') if isinstance(order.created_at, datetime) else str(order.created_at)

        # Base context
        context = {
            'orderNumber': order.order_number,
            'customerEmail': order.customer_email,
            'customerName': order.customer_name,
            'total': f"{order.total:.2f}",
            'subtotal': f"{order.subtotal:.2f}",
            'tax': f"{order.tax:.2f}",
            'shipping': f"{order.shipping:.2f}",
            'discount': f"{order.discount:.2f}",
            'orderDate': order_date,
            'itemCount': len(order.items),
            'orderStatus': order.order_status,
            'paymentStatus': order.payment_status,
            'tenantId': order.tenant_id,
            'orderId': order.order_id
        }

        # Add items list
        context['items'] = [
            {
                'itemId': item.item_id,
                'quantity': item.quantity,
                'unitPrice': f"{item.unit_price:.2f}",
                'subtotal': f"{item.subtotal:.2f}",
                'campaignName': item.campaign.campaign_name if item.campaign else 'Custom Item'
            }
            for item in order.items
        ]

        # Add billing address
        if order.billing_address:
            context['billingAddress'] = {
                'street': order.billing_address.street,
                'city': order.billing_address.city,
                'postalCode': order.billing_address.postal_code,
                'country': order.billing_address.country
            }

        # Add shipping address if different
        if order.shipping_address:
            context['shippingAddress'] = {
                'street': order.shipping_address.street,
                'city': order.shipping_address.city,
                'postalCode': order.shipping_address.postal_code,
                'country': order.shipping_address.country
            }

        # Email type specific context
        if email_type == 'internal':
            order_details_url = f"{self.admin_portal_url}/tenants/{order.tenant_id}/orders/{order.order_id}"
            context['orderDetailsUrl'] = order_details_url

        elif email_type == 'customer':
            # Generate presigned URL for invoice PDF (7-day expiration)
            pdf_presigned_url = self.generate_pdf_presigned_url(order.order_id)
            context['pdfPresignedUrl'] = pdf_presigned_url
            context['pdfDownloadUrl'] = pdf_presigned_url

            # Add campaign details if present
            campaign_details = self._extract_campaign_details(order)
            if campaign_details:
                context['campaign'] = campaign_details

            # Add support contact info
            context['supportEmail'] = 'support@kimmyai.io'
            context['customerPortalUrl'] = f"{self.customer_portal_url}/orders/{order.order_id}"

        return context

    def generate_pdf_presigned_url(self, order_id: str, expiration_seconds: int = 604800) -> str:
        """
        Generate presigned S3 URL for order invoice PDF.

        Args:
            order_id: Order ID for the PDF
            expiration_seconds: URL expiration time in seconds (default 7 days = 604800)

        Returns:
            Presigned S3 URL for the invoice PDF

        Raises:
            Exception: If presigned URL generation fails
        """
        try:
            # S3 key pattern: invoices/{order_id}/{order_id}.pdf
            s3_key = f"invoices/{order_id}/{order_id}.pdf"
            logger.info(f"Generating presigned URL for invoice: {s3_key} (expires in {expiration_seconds}s)")

            presigned_url = self.s3_service.generate_presigned_url(
                bucket_name=self.invoice_bucket,
                object_key=s3_key,
                expiration_seconds=expiration_seconds
            )

            logger.info(f"Presigned URL generated successfully for order {order_id}")
            return presigned_url

        except Exception as e:
            logger.error(f"Failed to generate presigned URL for order {order_id}: {str(e)}")
            raise

    def _extract_campaign_details(self, order: Order) -> Optional[dict]:
        """
        Extract campaign information from order items.

        Args:
            order: Order object

        Returns:
            Campaign details dict if present, None otherwise
        """
        try:
            # Extract first campaign found in items
            for item in order.items:
                if item.campaign:
                    return {
                        'campaignId': item.campaign.campaign_id,
                        'campaignName': item.campaign.campaign_name,
                        'code': item.campaign.code if hasattr(item.campaign, 'code') else None,
                        'discount': item.campaign.discount if hasattr(item.campaign, 'discount') else None
                    }
            return None
        except Exception as e:
            logger.warning(f"Failed to extract campaign details: {str(e)}")
            return None

    def _create_fallback_internal_email(self, order: Order) -> str:
        """
        Create plain text fallback email when internal template is not available.

        Args:
            order: Order object

        Returns:
            Plain text email body
        """
        order_date = order.created_at.strftime('%Y-%m-%d %H:%M:%S') if isinstance(order.created_at, datetime) else str(order.created_at)
        order_details_url = f"{self.admin_portal_url}/tenants/{order.tenant_id}/orders/{order.order_id}"

        items_text = "\n".join([
            f"  - {item.campaign.campaign_name if item.campaign else 'Item'} (Qty: {item.quantity}, Price: R{item.subtotal:.2f})"
            for item in order.items
        ])

        return f"""
New Order Received

Order Number: {order.order_number}
Order ID: {order.order_id}
Tenant ID: {order.tenant_id}

Customer Information:
- Name: {order.customer_name}
- Email: {order.customer_email}
- Phone: {order.customer_phone or 'Not provided'}

Order Details:
- Order Date: {order_date}
- Order Status: {order.order_status}
- Payment Status: {order.payment_status}

Items:
{items_text}

Pricing:
- Subtotal: R{order.subtotal:.2f}
- Tax: R{order.tax:.2f}
- Shipping: R{order.shipping:.2f}
- Discount: R{order.discount:.2f}
- Total: R{order.total:.2f}

View Full Order Details:
{order_details_url}

---
This is an automated notification from the BBWS Order System.
        """.strip()

    def _create_fallback_customer_email(self, order: Order) -> str:
        """
        Create plain text fallback email for customer confirmation.

        Args:
            order: Order object

        Returns:
            Plain text email body
        """
        order_date = order.created_at.strftime('%Y-%m-%d %H:%M:%S') if isinstance(order.created_at, datetime) else str(order.created_at)

        items_text = "\n".join([
            f"  - {item.campaign.campaign_name if item.campaign else 'Item'} (Qty: {item.quantity}, Price: R{item.subtotal:.2f})"
            for item in order.items
        ])

        campaign_text = ""
        campaign_details = self._extract_campaign_details(order)
        if campaign_details:
            campaign_text = f"\nSpecial Offer Applied: {campaign_details.get('campaignName', 'Campaign')}"
            if campaign_details.get('discount'):
                campaign_text += f" - Discount: R{campaign_details['discount']:.2f}"

        return f"""
Thank you for your order!

Order Confirmation

Order Number: {order.order_number}
Order Date: {order_date}

Customer Information:
- Name: {order.customer_name}
- Email: {order.customer_email}

Items Ordered:
{items_text}

Order Summary:
- Subtotal: R{order.subtotal:.2f}
- Tax: R{order.tax:.2f}
- Shipping: R{order.shipping:.2f}
- Discount: -R{order.discount:.2f}
- Total: R{order.total:.2f}{campaign_text}

Billing Address:
{order.billing_address.street if order.billing_address else 'Address not provided'}
{order.billing_address.city if order.billing_address else ''}, {order.billing_address.postal_code if order.billing_address else ''}
{order.billing_address.country if order.billing_address else ''}

If you have any questions, please contact our support team at support@kimmyai.io

---
Thank you for your business!
BBWS Order System
        """.strip()
