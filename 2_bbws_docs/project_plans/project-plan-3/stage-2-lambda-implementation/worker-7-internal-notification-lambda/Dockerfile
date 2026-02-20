# Lambda Docker image for OrderInternalNotificationSender
# Base: AWS Lambda Python 3.12 (arm64)

FROM public.ecr.aws/lambda/python:3.12

# Set working directory
WORKDIR ${LAMBDA_TASK_ROOT}

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY src/ ${LAMBDA_TASK_ROOT}/src/

# Set Lambda handler
CMD ["src.handlers.order_internal_notification_sender.lambda_handler"]
