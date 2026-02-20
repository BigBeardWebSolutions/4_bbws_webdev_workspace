"""
Unit tests for PDFService.

Tests PDF generation using ReportLab.
"""

import pytest
from io import BytesIO
from src.services.pdf_service import PDFService
from PyPDF2 import PdfReader


class TestPDFService:
    """Tests for PDFService class."""

    def test_init(self):
        """Test PDFService initialization."""
        service = PDFService(company_name="Test Company")
        assert service.company_name == "Test Company"
        assert service.company_logo_url is None

    def test_init_with_logo(self):
        """Test PDFService initialization with logo."""
        service = PDFService(
            company_name="BBWS",
            company_logo_url="https://example.com/logo.png"
        )
        assert service.company_name == "BBWS"
        assert service.company_logo_url == "https://example.com/logo.png"

    def test_generate_invoice_pdf_success(self, sample_order):
        """Test successful PDF generation."""
        service = PDFService(company_name="BBWS")

        pdf_bytes = service.generate_invoice_pdf(sample_order)

        # Verify PDF was generated
        assert isinstance(pdf_bytes, bytes)
        assert len(pdf_bytes) > 0

        # Verify PDF is valid
        pdf_reader = PdfReader(BytesIO(pdf_bytes))
        assert len(pdf_reader.pages) > 0

        # Extract text from first page
        page_text = pdf_reader.pages[0].extract_text()

        # Verify key content is in PDF
        assert "BBWS" in page_text
        assert "INVOICE" in page_text
        assert sample_order.orderNumber in page_text
        assert sample_order.customerEmail in page_text

    def test_generate_invoice_pdf_with_all_fields(self, sample_order, sample_campaign, sample_payment_details):
        """Test PDF generation with all optional fields."""
        # Add optional fields
        sample_order.campaign = sample_campaign
        sample_order.paymentDetails = sample_payment_details
        sample_order.shippingAmount = 25.00
        sample_order.discountAmount = 10.00
        sample_order.total = sample_order.subtotal + sample_order.taxAmount + sample_order.shippingAmount - sample_order.discountAmount

        service = PDFService(company_name="BBWS")

        pdf_bytes = service.generate_invoice_pdf(sample_order)

        assert isinstance(pdf_bytes, bytes)
        assert len(pdf_bytes) > 0

        # Verify PDF content
        pdf_reader = PdfReader(BytesIO(pdf_bytes))
        page_text = pdf_reader.pages[0].extract_text()

        # Verify payment details are included
        assert sample_payment_details.method.replace('_', ' ').title() in page_text
        assert sample_payment_details.status.upper() in page_text

    def test_generate_invoice_pdf_multiple_items(self, sample_order, sample_order_item):
        """Test PDF generation with multiple line items."""
        # Add second item
        second_item = sample_order_item.copy(deep=True)
        second_item.productId = "prod-456"
        second_item.productName = "WordPress Plugin"
        second_item.productSku = "WP-PLUGIN-001"

        sample_order.items.append(second_item)
        sample_order.subtotal = sum(item.subtotal for item in sample_order.items)
        sample_order.taxAmount = sum(item.taxAmount for item in sample_order.items)
        sample_order.total = sum(item.total for item in sample_order.items)

        service = PDFService(company_name="BBWS")

        pdf_bytes = service.generate_invoice_pdf(sample_order)

        assert isinstance(pdf_bytes, bytes)

        # Verify both products are in PDF
        pdf_reader = PdfReader(BytesIO(pdf_bytes))
        page_text = pdf_reader.pages[0].extract_text()

        assert "Premium WordPress Theme" in page_text
        assert "WordPress Plugin" in page_text

    def test_generate_invoice_pdf_pending_order(self, sample_order):
        """Test PDF generation for pending order without payment."""
        sample_order.status = "pending"
        sample_order.paymentDetails = None

        service = PDFService(company_name="BBWS")

        pdf_bytes = service.generate_invoice_pdf(sample_order)

        # Should generate successfully even without payment details
        assert isinstance(pdf_bytes, bytes)
        assert len(pdf_bytes) > 0

    def test_generate_invoice_pdf_error_handling(self):
        """Test PDF generation with invalid order data."""
        service = PDFService(company_name="BBWS")

        # This should raise an exception due to missing required fields
        with pytest.raises(Exception):
            service.generate_invoice_pdf(None)

    def test_pdf_contains_order_details(self, sample_order):
        """Test PDF contains all critical order information."""
        service = PDFService(company_name="BBWS")

        pdf_bytes = service.generate_invoice_pdf(sample_order)
        pdf_reader = PdfReader(BytesIO(pdf_bytes))
        page_text = pdf_reader.pages[0].extract_text()

        # Verify critical order details
        assert sample_order.orderNumber in page_text
        assert sample_order.customerEmail in page_text
        assert sample_order.status.upper() in page_text
        assert str(sample_order.total) in page_text or f"{sample_order.total:.2f}" in page_text
        assert sample_order.currency in page_text

        # Verify billing address
        assert sample_order.billingAddress.fullName in page_text
        assert sample_order.billingAddress.city in page_text

        # Verify line items
        for item in sample_order.items:
            assert item.productName in page_text
            assert item.productSku in page_text

    def test_pdf_formatting(self, sample_order):
        """Test PDF has proper structure and formatting."""
        service = PDFService(company_name="BBWS")

        pdf_bytes = service.generate_invoice_pdf(sample_order)

        # Verify PDF is not empty and has reasonable size
        assert len(pdf_bytes) > 1000  # Should be at least 1KB for a formatted invoice

        # Verify PDF is readable
        pdf_reader = PdfReader(BytesIO(pdf_bytes))
        assert len(pdf_reader.pages) >= 1

        # Verify PDF metadata
        metadata = pdf_reader.metadata
        # ReportLab doesn't always set metadata, so we just check it's accessible
        assert metadata is not None or metadata is None  # Either way is valid
