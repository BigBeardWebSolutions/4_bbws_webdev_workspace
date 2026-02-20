# DNS-CloudFront Module - Outputs

#------------------------------------------------------------------------------
# DNS Record Information
#------------------------------------------------------------------------------

output "a_record_name" {
  description = "FQDN of the A record"
  value       = aws_route53_record.tenant_a.fqdn
}

output "a_record_id" {
  description = "ID of the A record"
  value       = aws_route53_record.tenant_a.id
}

output "aaaa_record_name" {
  description = "FQDN of the AAAA record (null if not created)"
  value       = var.create_ipv6_record ? aws_route53_record.tenant_aaaa[0].fqdn : null
}

output "aaaa_record_id" {
  description = "ID of the AAAA record (null if not created)"
  value       = var.create_ipv6_record ? aws_route53_record.tenant_aaaa[0].id : null
}

#------------------------------------------------------------------------------
# Tenant Configuration
#------------------------------------------------------------------------------

output "tenant_url" {
  description = "Full HTTPS URL for the tenant"
  value       = "https://${var.domain_name}"
}

output "domain_name" {
  description = "Domain name configured"
  value       = var.domain_name
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain (passthrough)"
  value       = var.cloudfront_domain_name
}
