locals {
  ws           = terraform.workspace
  bucket_name  = "${var.app_name}-${local.ws}-static"
  s3_origin_id = "${var.app_name}-${terraform.workspace}-s3-origin"
  # avoid duplicate records for acm_cert
  validation_options_raw = aws_acm_certificate.this.domain_validation_options
  validation_options_hash = {
    for option in local.validation_options_raw :
    option["resource_record_name"] => {
      resource_record_type  = option["resource_record_type"]
      resource_record_value = option["resource_record_value"]
    }...
  }
  validation_options = [
    for key in keys(local.validation_options_hash) :
    {
      resource_record_name  = key
      resource_record_type  = lookup(lookup(local.validation_options_hash, key)[0], "resource_record_type")
      resource_record_value = lookup(lookup(local.validation_options_hash, key)[0], "resource_record_value")
    }
  ]
}
# S3 Bucket
resource "aws_s3_bucket" "this" {
  bucket = local.bucket_name
  acl    = "private"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = [
      "https://${local.ws}.${var.hosted_domain}",
    ]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json
}

data "aws_iam_policy_document" "this" {
  statement {
    sid    = ""
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        aws_cloudfront_origin_access_identity.this.iam_arn
      ]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.this.arn}/*"
    ]
  }
}

# Cloudfront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "this" {
  comment = var.asset_domain
}

# Cloudfront Distribution
resource "aws_cloudfront_distribution" "this" {
  aliases = [var.asset_domain]

  origin {
    domain_name = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.asset_domain
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  price_class = "PriceClass_200"

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.acm_cert.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1"
  }
}

# ACM
resource "aws_acm_certificate" "this" {
  provider    = aws
  domain_name = var.hosted_domain

  subject_alternative_names = [
    "*.${var.hosted_domain}",
  ]
  validation_method = "DNS"
}

# Route53 Hosted Zone
data "aws_route53_zone" "this" {
  name         = var.hosted_domain
  private_zone = false
}

# Route53 Record
resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.asset_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "acm_cert" {
  zone_id = data.aws_route53_zone.this.id
  ttl     = 60

  name    = tolist(local.validation_options)[0].resource_record_name
  type    = tolist(local.validation_options)[0].resource_record_type
  records = [tolist(local.validation_options)[0].resource_record_value]
}

resource "aws_acm_certificate_validation" "acm_cert" {
  certificate_arn = aws_acm_certificate.this.arn
  # validation_record_fqdns = [for record in aws_route53_record.acm_cert : record.fqdn]
  validation_record_fqdns = [aws_route53_record.acm_cert.fqdn]
}