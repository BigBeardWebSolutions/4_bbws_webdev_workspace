"""
PDFService - Service for generating PDF invoices using ReportLab.

Creates professional PDF invoices with order details, line items, and totals.
"""

import logging
from io import BytesIO
from datetime import datetime
from typing import Optional
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, Image
from reportlab.pdfgen import canvas
from src.models.order import Order

logger = logging.getLogger(__name__)


class PDFService:
    """
    Service for generating PDF invoices using ReportLab.

    Creates professional PDF invoices with:
    - Company branding and logo
    - Order information (number, date, status)
    - Customer details
    - Itemized line items table
    - Financial totals (subtotal, tax, shipping, discount, total)
    - Payment status
    """

    def __init__(self, company_name: str = "BBWS", company_logo_url: Optional[str] = None):
        """
        Initialize PDFService.

        Args:
            company_name: Company name for invoice header
            company_logo_url: URL to company logo (optional)
        """
        self.company_name = company_name
        self.company_logo_url = company_logo_url

    def generate_invoice_pdf(self, order: Order) -> bytes:
        """
        Generate PDF invoice for an order.

        Args:
            order: Order object with complete order data

        Returns:
            PDF file as bytes

        Raises:
            Exception: If PDF generation fails
        """
        try:
            logger.info(f"Generating PDF invoice for order: {order.orderNumber}")

            # Create BytesIO buffer for PDF
            buffer = BytesIO()

            # Create PDF document
            doc = SimpleDocTemplate(
                buffer,
                pagesize=A4,
                rightMargin=20 * mm,
                leftMargin=20 * mm,
                topMargin=20 * mm,
                bottomMargin=20 * mm
            )

            # Build PDF content
            story = []
            styles = getSampleStyleSheet()

            # Header with company name
            header_style = ParagraphStyle(
                'CustomHeader',
                parent=styles['Heading1'],
                fontSize=24,
                textColor=colors.HexColor('#1a1a1a'),
                spaceAfter=6 * mm
            )
            story.append(Paragraph(self.company_name, header_style))
            story.append(Spacer(1, 3 * mm))

            # Invoice title
            title_style = ParagraphStyle(
                'InvoiceTitle',
                parent=styles['Heading2'],
                fontSize=18,
                textColor=colors.HexColor('#333333')
            )
            story.append(Paragraph("ORDER INVOICE", title_style))
            story.append(Spacer(1, 6 * mm))

            # Order information section
            order_info_data = [
                ['Order Number:', order.orderNumber],
                ['Order Date:', order.dateCreated.strftime('%Y-%m-%d %H:%M:%S UTC')],
                ['Order Status:', order.status.upper()],
                ['Order ID:', order.id],
            ]

            order_info_table = Table(order_info_data, colWidths=[45 * mm, 75 * mm])
            order_info_table.setStyle(TableStyle([
                ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
                ('FONTNAME', (1, 0), (1, -1), 'Helvetica'),
                ('FONTSIZE', (0, 0), (-1, -1), 10),
                ('TEXTCOLOR', (0, 0), (0, -1), colors.HexColor('#555555')),
                ('ALIGN', (0, 0), (0, -1), 'RIGHT'),
                ('ALIGN', (1, 0), (1, -1), 'LEFT'),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
            ]))
            story.append(order_info_table)
            story.append(Spacer(1, 8 * mm))

            # Customer information section
            story.append(Paragraph("<b>Customer Information</b>", styles['Heading3']))
            story.append(Spacer(1, 3 * mm))

            customer_info_data = [
                ['Name:', order.customerName or 'N/A'],
                ['Email:', order.customerEmail],
            ]

            if order.billingAddress:
                addr = order.billingAddress
                address_lines = [addr.addressLine1]
                if addr.addressLine2:
                    address_lines.append(addr.addressLine2)
                address_lines.append(f"{addr.city}, {addr.stateProvince} {addr.postalCode}")
                address_lines.append(addr.country)
                customer_info_data.append(['Billing Address:', '<br/>'.join(address_lines)])

            customer_info_table = Table(customer_info_data, colWidths=[45 * mm, 120 * mm])
            customer_info_table.setStyle(TableStyle([
                ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
                ('FONTNAME', (1, 0), (1, -1), 'Helvetica'),
                ('FONTSIZE', (0, 0), (-1, -1), 9),
                ('TEXTCOLOR', (0, 0), (0, -1), colors.HexColor('#555555')),
                ('ALIGN', (0, 0), (0, -1), 'RIGHT'),
                ('ALIGN', (1, 0), (1, -1), 'LEFT'),
                ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
            ]))
            story.append(customer_info_table)
            story.append(Spacer(1, 8 * mm))

            # Order items section
            story.append(Paragraph("<b>Order Items</b>", styles['Heading3']))
            story.append(Spacer(1, 3 * mm))

            # Build items table
            items_data = [['Product', 'SKU', 'Qty', 'Unit Price', 'Subtotal', 'Tax', 'Total']]

            for item in order.items:
                items_data.append([
                    Paragraph(item.productName, styles['Normal']),
                    item.productSku,
                    str(item.quantity),
                    f"{order.currency} {item.unitPrice:.2f}",
                    f"{order.currency} {item.subtotal:.2f}",
                    f"{order.currency} {item.taxAmount:.2f}",
                    f"{order.currency} {item.total:.2f}",
                ])

            items_table = Table(
                items_data,
                colWidths=[60 * mm, 30 * mm, 15 * mm, 25 * mm, 25 * mm, 20 * mm, 25 * mm]
            )
            items_table.setStyle(TableStyle([
                # Header row
                ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#f0f0f0')),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, 0), 9),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.HexColor('#333333')),
                ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 6),

                # Data rows
                ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
                ('FONTSIZE', (0, 1), (-1, -1), 8),
                ('ALIGN', (0, 1), (0, -1), 'LEFT'),
                ('ALIGN', (1, 1), (-1, -1), 'CENTER'),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),

                # Grid
                ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
                ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f9f9f9')]),
            ]))
            story.append(items_table)
            story.append(Spacer(1, 8 * mm))

            # Totals section
            totals_data = [
                ['Subtotal:', f"{order.currency} {order.subtotal:.2f}"],
            ]

            if order.discountAmount > 0:
                totals_data.append(['Discount:', f"- {order.currency} {order.discountAmount:.2f}"])

            totals_data.append(['Tax:', f"{order.currency} {order.taxAmount:.2f}"])

            if order.shippingAmount > 0:
                totals_data.append(['Shipping:', f"{order.currency} {order.shippingAmount:.2f}"])

            totals_data.append(['TOTAL:', f"{order.currency} {order.total:.2f}"])

            totals_table = Table(totals_data, colWidths=[120 * mm, 50 * mm])
            totals_table.setStyle(TableStyle([
                ('FONTNAME', (0, 0), (0, -2), 'Helvetica'),
                ('FONTNAME', (0, -1), (-1, -1), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, -2), 10),
                ('FONTSIZE', (0, -1), (-1, -1), 12),
                ('ALIGN', (0, 0), (0, -1), 'RIGHT'),
                ('ALIGN', (1, 0), (1, -1), 'RIGHT'),
                ('TEXTCOLOR', (0, -1), (-1, -1), colors.HexColor('#1a1a1a')),
                ('LINEABOVE', (0, -1), (-1, -1), 2, colors.HexColor('#333333')),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
            ]))
            story.append(totals_table)
            story.append(Spacer(1, 8 * mm))

            # Payment information
            if order.paymentDetails:
                story.append(Paragraph("<b>Payment Information</b>", styles['Heading3']))
                story.append(Spacer(1, 3 * mm))

                payment_data = [
                    ['Payment Method:', order.paymentDetails.method.replace('_', ' ').title()],
                    ['Payment Status:', order.paymentDetails.status.upper()],
                ]

                if order.paymentDetails.transactionId:
                    payment_data.append(['Transaction ID:', order.paymentDetails.transactionId])

                if order.paymentDetails.paidAt:
                    payment_data.append([
                        'Paid At:',
                        order.paymentDetails.paidAt.strftime('%Y-%m-%d %H:%M:%S UTC')
                    ])

                payment_table = Table(payment_data, colWidths=[45 * mm, 120 * mm])
                payment_table.setStyle(TableStyle([
                    ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
                    ('FONTNAME', (1, 0), (1, -1), 'Helvetica'),
                    ('FONTSIZE', (0, 0), (-1, -1), 9),
                    ('ALIGN', (0, 0), (0, -1), 'RIGHT'),
                    ('ALIGN', (1, 0), (1, -1), 'LEFT'),
                    ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
                ]))
                story.append(payment_table)
                story.append(Spacer(1, 8 * mm))

            # Footer
            footer_style = ParagraphStyle(
                'Footer',
                parent=styles['Normal'],
                fontSize=8,
                textColor=colors.HexColor('#888888'),
                alignment=1  # Center alignment
            )
            story.append(Spacer(1, 10 * mm))
            story.append(Paragraph(
                "Thank you for your business!<br/>This is a computer-generated invoice.",
                footer_style
            ))

            # Build PDF
            doc.build(story)

            # Get PDF bytes
            pdf_bytes = buffer.getvalue()
            buffer.close()

            logger.info(f"PDF generated successfully: {len(pdf_bytes)} bytes")
            return pdf_bytes

        except Exception as e:
            logger.error(f"Error generating PDF: {str(e)}", exc_info=True)
            raise
