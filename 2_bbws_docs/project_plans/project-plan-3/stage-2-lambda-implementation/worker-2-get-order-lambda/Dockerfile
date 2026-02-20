# Lambda Docker image for get_order function
# Uses AWS Lambda Python 3.12 base image with arm64 architecture

FROM public.ecr.aws/lambda/python:3.12

# Copy requirements file
COPY requirements.txt ${LAMBDA_TASK_ROOT}/

# Install Python dependencies
# Exclude dev dependencies (pytest, moto, etc.)
RUN pip install --no-cache-dir boto3==1.34.0 botocore==1.34.0 pydantic==1.10.18 email-validator==2.1.0 python-dateutil==2.8.2

# Copy source code
COPY src/ ${LAMBDA_TASK_ROOT}/src/

# Set the CMD to the Lambda handler
CMD ["src.handlers.get_order.lambda_handler"]
