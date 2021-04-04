output "cloud_front_destribution_domain_name" {
  value = aws_cloudfront_distribution.this.domain_name
}

output "zone_name_servers" {
  value = data.aws_route53_zone.this.name_servers
}

output "hosted_zone_id" {
  value = data.aws_route53_zone.this.id
}

output "certificate_arn" {
  value = aws_acm_certificate.this.arn
}