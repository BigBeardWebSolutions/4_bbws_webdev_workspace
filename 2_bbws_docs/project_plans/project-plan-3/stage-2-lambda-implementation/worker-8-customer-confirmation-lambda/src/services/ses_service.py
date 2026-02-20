"""SES Service for email sending."""

import os
import logging
from typing import Optional
import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)


class SESService:
    """
    Service for sending emails via Amazon SES.

    Handles email composition and delivery with proper error handling.
    """

    def __init__(self):
        """Initialize SESService with SES client."""
        self.ses_client = boto3.client('ses')
        self.from_email = os.environ.get('SES_FROM_EMAIL', 'noreply@kimmyai.io')
        self.default_to_email = os.environ.get('INTERNAL_NOTIFICATION_EMAIL', 'internal@kimmyai.io')
        logger.info(f"SESService initialized with from_email: {self.from_email}")

    def send_email(
        self,
        to_email: Optional[str],
        subject: str,
        html_body: Optional[str] = None,
        text_body: Optional[str] = None,
        reply_to: Optional[str] = None
    ) -> str:
        """
        Send email via SES.

        Args:
            to_email: Recipient email address (uses default if None or empty)
            subject: Email subject line
            html_body: HTML email body (optional)
            text_body: Plain text email body (optional)
            reply_to: Reply-To email address (optional)

        Returns:
            SES Message ID

        Raises:
            ValueError: If neither html_body nor text_body is provided
            Exception: If SES send operation fails
        """
        if not html_body and not text_body:
            raise ValueError("Either html_body or text_body must be provided")

        # Use default internal email if to_email is None or empty
        recipient = to_email if to_email else self.default_to_email

        try:
            logger.info(f"Sending email to {recipient}: {subject}")

            # Build message body
            body = {}
            if html_body:
                body['Html'] = {
                    'Data': html_body,
                    'Charset': 'UTF-8'
                }
            if text_body:
                body['Text'] = {
                    'Data': text_body,
                    'Charset': 'UTF-8'
                }

            # Build SES request parameters
            ses_params = {
                'Source': self.from_email,
                'Destination': {
                    'ToAddresses': [recipient]
                },
                'Message': {
                    'Subject': {
                        'Data': subject,
                        'Charset': 'UTF-8'
                    },
                    'Body': body
                }
            }

            # Add reply-to if specified
            if reply_to:
                ses_params['ReplyToAddresses'] = [reply_to]
                logger.info(f"Reply-To address set: {reply_to}")

            response = self.ses_client.send_email(**ses_params)

            message_id = response['MessageId']
            logger.info(f"Email sent successfully: MessageId={message_id}")
            return message_id

        except ClientError as e:
            error_code = e.response['Error']['Code']
            error_message = e.response['Error']['Message']
            logger.error(f"SES ClientError: {error_code} - {error_message}")
            raise Exception(f"Failed to send email: {error_message}")

        except Exception as e:
            logger.error(f"Unexpected error sending email: {str(e)}")
            raise
