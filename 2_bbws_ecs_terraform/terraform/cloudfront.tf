# CloudFront Module for POC1 - ECS Fargate Multi-Tenant WordPress
# Provides CDN, HTTPS, and Basic Auth protection for non-production environments

#------------------------------------------------------------------------------
# AWS Provider for us-east-1 (Required for ACM certificates used by CloudFront)
#------------------------------------------------------------------------------

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  dynamic "assume_role" {
    for_each = var.assume_role_arn != "" ? [1] : []
    content {
      role_arn     = var.assume_role_arn
      session_name = "terraform-${var.environment}-cloudfront"
    }
  }

  default_tags {
    tags = {
      Project     = "BBWS-ECS-WordPress"
      Environment = var.environment
      ManagedBy   = "Terraform"
      AccountId   = var.aws_account_id
    }
  }
}

#------------------------------------------------------------------------------
# Local Variables
#------------------------------------------------------------------------------

locals {
  # Determine CloudFront domain based on environment
  cloudfront_domain = var.environment == "prod" ? "*.wp.kimmyai.io" : "*.wp${var.environment}.kimmyai.io"

  # Base64 encoded credentials for basic auth
  # Format: username:password -> base64
  basic_auth_credentials = base64encode("${var.cloudfront_basic_auth_username}:${var.cloudfront_basic_auth_password}")

  # Enable basic auth for non-production environments by default
  enable_basic_auth = var.cloudfront_enable_basic_auth
}

#------------------------------------------------------------------------------
# ACM Certificate for CloudFront (must be in us-east-1)
#------------------------------------------------------------------------------

resource "aws_acm_certificate" "cloudfront" {
  provider = aws.us_east_1
  count    = var.cloudfront_enabled ? 1 : 0

  domain_name       = local.cloudfront_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.environment}-cloudfront-cert"
    Environment = var.environment
  }
}

# Output the DNS validation records (to be created in Route53)
output "cloudfront_certificate_validation_records" {
  description = "DNS validation records for CloudFront certificate"
  value = var.cloudfront_enabled ? [
    for dvo in aws_acm_certificate.cloudfront[0].domain_validation_options : {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      value  = dvo.resource_record_value
    }
  ] : []
}

#------------------------------------------------------------------------------
# CloudFront Function for Basic Auth
#------------------------------------------------------------------------------

resource "aws_cloudfront_function" "basic_auth" {
  provider = aws.us_east_1
  count    = var.cloudfront_enabled && local.enable_basic_auth ? 1 : 0

  name    = "wp${var.environment}-basic-auth"
  runtime = "cloudfront-js-2.0"
  comment = "Basic auth for wp${var.environment}.kimmyai.io"
  publish = true

  code = <<-EOF
    function handler(event) {
        var request = event.request;
        var headers = request.headers;

        var authString = "Basic ${local.basic_auth_credentials}";

        if (typeof headers.authorization === "undefined" || headers.authorization.value !== authString) {
            return {
                statusCode: 401,
                statusDescription: "Unauthorized",
                headers: {
                    "www-authenticate": { value: "Basic realm=\"BBWS WordPress ${upper(var.environment)}\"" }
                }
            };
        }

        return request;
    }
  EOF
}

#------------------------------------------------------------------------------
# CloudFront Distribution
#------------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "main" {
  count = var.cloudfront_enabled ? 1 : 0

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${upper(var.environment)} WordPress Multi-Tenant Distribution"
  default_root_object = ""
  price_class         = var.cloudfront_price_class
  http_version        = "http2"

  aliases = [local.cloudfront_domain]

  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = "${var.environment}-alb-origin"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_read_timeout      = 60
      origin_keepalive_timeout = 60
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.environment}-alb-origin"

    # Use managed cache policy - CachingDisabled for WordPress
    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    # Use managed origin request policy - AllViewer
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # Attach basic auth function for non-production environments
    dynamic "function_association" {
      for_each = local.enable_basic_auth ? [1] : []
      content {
        event_type   = "viewer-request"
        function_arn = aws_cloudfront_function.basic_auth[0].arn
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.cloudfront[0].arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  tags = {
    Name        = "${var.environment}-cloudfront"
    Environment = var.environment
  }

  depends_on = [aws_acm_certificate.cloudfront]
}

#------------------------------------------------------------------------------
# CloudFront Outputs
#------------------------------------------------------------------------------

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = var.cloudfront_enabled ? aws_cloudfront_distribution.main[0].id : null
}

output "cloudfront_distribution_domain" {
  description = "CloudFront distribution domain name"
  value       = var.cloudfront_enabled ? aws_cloudfront_distribution.main[0].domain_name : null
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = var.cloudfront_enabled ? aws_cloudfront_distribution.main[0].arn : null
}

output "cloudfront_tenant_url_format" {
  description = "URL format for accessing tenants via CloudFront"
  value       = var.cloudfront_enabled ? "https://{tenant}.wp${var.environment}.kimmyai.io" : null
}
