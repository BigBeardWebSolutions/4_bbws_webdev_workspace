"""S3 Service for email template retrieval and presigned URL generation."""

import os
import logging
from typing import Optional
import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)


class S3Service:
    """
    Service for S3 operations including template retrieval and presigned URL generation.

    Handles template fetching, presigned URL creation with proper error handling and fallback mechanisms.
    """

    def __init__(self):
        """Initialize S3Service with S3 client."""
        self.s3_client = boto3.client('s3')
        self.bucket_name = os.environ.get('EMAIL_TEMPLATE_BUCKET', 'bbws-email-templates-dev')
        logger.info(f"S3Service initialized with bucket: {self.bucket_name}")

    def get_template(self, template_key: str) -> Optional[str]:
        """
        Retrieve email template from S3.

        Args:
            template_key: S3 key for the template (e.g., 'internal/order_notification.html')

        Returns:
            Template content as string, or None if not found

        Raises:
            Exception: If S3 operation fails (except NotFound/AccessDenied)
        """
        try:
            logger.info(f"Retrieving template from S3: bucket={self.bucket_name}, key={template_key}")

            response = self.s3_client.get_object(
                Bucket=self.bucket_name,
                Key=template_key
            )

            template_content = response['Body'].read().decode('utf-8')
            logger.info(f"Successfully retrieved template: {template_key} ({len(template_content)} bytes)")
            return template_content

        except ClientError as e:
            error_code = e.response['Error']['Code']
            error_message = e.response['Error']['Message']

            if error_code in ['NoSuchKey', 'AccessDenied']:
                logger.warning(f"Template not found or access denied: {template_key} - {error_code}")
                return None
            else:
                logger.error(f"S3 ClientError: {error_code} - {error_message}")
                raise Exception(f"Failed to retrieve template from S3: {error_message}")

        except UnicodeDecodeError as e:
            logger.error(f"Failed to decode template {template_key}: {str(e)}")
            raise Exception(f"Template decoding error: {str(e)}")

        except Exception as e:
            logger.error(f"Unexpected error retrieving template {template_key}: {str(e)}")
            raise

    def generate_presigned_url(
        self,
        bucket_name: str,
        object_key: str,
        expiration_seconds: int = 604800
    ) -> str:
        """
        Generate a presigned S3 URL for accessing an object.

        Args:
            bucket_name: S3 bucket name
            object_key: S3 object key (path)
            expiration_seconds: URL expiration time in seconds (default 7 days = 604800)

        Returns:
            Presigned S3 URL

        Raises:
            Exception: If presigned URL generation fails
        """
        try:
            logger.info(f"Generating presigned URL: bucket={bucket_name}, key={object_key}, expiration={expiration_seconds}s")

            presigned_url = self.s3_client.generate_presigned_url(
                'get_object',
                Params={
                    'Bucket': bucket_name,
                    'Key': object_key
                },
                ExpiresIn=expiration_seconds
            )

            logger.info(f"Presigned URL generated successfully for {object_key}")
            return presigned_url

        except ClientError as e:
            error_code = e.response['Error']['Code']
            error_message = e.response['Error']['Message']
            logger.error(f"S3 ClientError: {error_code} - {error_message}")
            raise Exception(f"Failed to generate presigned URL: {error_message}")

        except Exception as e:
            logger.error(f"Unexpected error generating presigned URL: {str(e)}")
            raise
