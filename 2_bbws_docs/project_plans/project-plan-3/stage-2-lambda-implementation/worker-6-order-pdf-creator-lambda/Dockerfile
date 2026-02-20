# Dockerfile for OrderPDFCreator Lambda Function
# Uses AWS Lambda Python 3.12 base image with arm64 architecture

FROM public.ecr.aws/lambda/python:3.12

# Set working directory
WORKDIR ${LAMBDA_TASK_ROOT}

# Copy requirements file
COPY requirements.txt ${LAMBDA_TASK_ROOT}/

# Install production dependencies only
# Filter out test dependencies
RUN grep -v "pytest\|moto\|PyPDF2" requirements.txt > requirements-prod.txt && \
    pip install --no-cache-dir -r requirements-prod.txt && \
    rm requirements-prod.txt

# Copy source code
COPY src/ ${LAMBDA_TASK_ROOT}/src/

# Set Lambda handler
# This will be overridden in Terraform for this specific function
CMD ["src.handlers.order_pdf_creator.lambda_handler"]
