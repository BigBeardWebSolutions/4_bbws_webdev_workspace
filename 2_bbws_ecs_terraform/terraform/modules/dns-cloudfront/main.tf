# DNS-CloudFront Module - Main Resources
# Creates Route53 DNS records pointing to CloudFront distribution

#------------------------------------------------------------------------------
# Route53 A Record - Points to CloudFront Distribution
#------------------------------------------------------------------------------

resource "aws_route53_record" "tenant_a" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}

#------------------------------------------------------------------------------
# Route53 AAAA Record (IPv6) - Points to CloudFront Distribution (Optional)
#------------------------------------------------------------------------------

resource "aws_route53_record" "tenant_aaaa" {
  count = var.create_ipv6_record ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}
