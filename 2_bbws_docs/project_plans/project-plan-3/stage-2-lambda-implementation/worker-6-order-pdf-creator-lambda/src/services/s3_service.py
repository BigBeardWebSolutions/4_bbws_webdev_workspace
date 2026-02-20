"""
S3Service - Service for Amazon S3 operations.

Handles PDF upload to S3 with proper configuration.
"""

import logging
from typing import BinaryIO

logger = logging.getLogger(__name__)


class S3Service:
    """
    Service for Amazon S3 operations.

    Handles uploading PDF invoices to S3 with proper encryption and metadata.

    Attributes:
        s3_client: Boto3 S3 client
        bucket_name: S3 bucket name for orders
    """

    def __init__(self, s3_client, bucket_name: str):
        """
        Initialize S3Service.

        Args:
            s3_client: Boto3 S3 client
            bucket_name: S3 bucket name
        """
        self.s3_client = s3_client
        self.bucket_name = bucket_name

    def upload_pdf(
        self,
        file_data: bytes,
        tenant_id: str,
        order_id: str
    ) -> str:
        """
        Upload PDF invoice to S3.

        S3 key format: {tenantId}/orders/order_{orderId}.pdf
        Example: tenant-123/orders/order_550e8400-e29b-41d4-a716-446655440000.pdf

        Args:
            file_data: PDF file binary data
            tenant_id: Tenant identifier
            order_id: Order identifier

        Returns:
            S3 URL to uploaded PDF

        Raises:
            Exception: If S3 upload fails
        """
        try:
            # Build S3 key
            s3_key = f"{tenant_id}/orders/order_{order_id}.pdf"

            logger.info(f"Uploading PDF to S3: bucket={self.bucket_name}, key={s3_key}")

            # Upload to S3 with proper configuration
            self.s3_client.put_object(
                Bucket=self.bucket_name,
                Key=s3_key,
                Body=file_data,
                ContentType='application/pdf',
                ServerSideEncryption='AES256',  # SSE-S3 encryption
                Metadata={
                    'tenant-id': tenant_id,
                    'order-id': order_id,
                    'document-type': 'invoice'
                }
            )

            # Build S3 URL
            s3_url = f"https://{self.bucket_name}.s3.amazonaws.com/{s3_key}"

            logger.info(f"PDF uploaded successfully: {s3_url}")
            return s3_url

        except Exception as e:
            logger.error(f"Error uploading PDF to S3: {str(e)}", exc_info=True)
            raise

    def get_pdf_url(self, tenant_id: str, order_id: str) -> str:
        """
        Get S3 URL for order PDF.

        Args:
            tenant_id: Tenant identifier
            order_id: Order identifier

        Returns:
            S3 URL to PDF
        """
        s3_key = f"{tenant_id}/orders/order_{order_id}.pdf"
        return f"https://{self.bucket_name}.s3.amazonaws.com/{s3_key}"

    def check_pdf_exists(self, tenant_id: str, order_id: str) -> bool:
        """
        Check if PDF exists in S3.

        Args:
            tenant_id: Tenant identifier
            order_id: Order identifier

        Returns:
            True if PDF exists, False otherwise
        """
        try:
            s3_key = f"{tenant_id}/orders/order_{order_id}.pdf"
            self.s3_client.head_object(Bucket=self.bucket_name, Key=s3_key)
            return True
        except self.s3_client.exceptions.NoSuchKey:
            return False
        except Exception as e:
            logger.error(f"Error checking PDF existence: {str(e)}")
            return False
