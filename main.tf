resource "aws_route53_record" "static_IPv4" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.static.domain_name
    zone_id                = aws_cloudfront_distribution.static.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "static_IPv6" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "AAAA"
  alias {
    name                   = aws_cloudfront_distribution.static.domain_name
    zone_id                = aws_cloudfront_distribution.static.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_s3_bucket" "static" {
  bucket_prefix = "${var.domain_name}-static-"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_acm_certificate" "static" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "static_validation" {
  name    = tolist(aws_acm_certificate.static.domain_validation_options).0.resource_record_name
  type    = tolist(aws_acm_certificate.static.domain_validation_options).0.resource_record_type
  zone_id = var.zone_id
  records = [tolist(aws_acm_certificate.static.domain_validation_options).0.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "static" {
  certificate_arn         = aws_acm_certificate.static.arn
  validation_record_fqdns = [aws_route53_record.static_validation.fqdn]

}

resource "aws_cloudfront_distribution" "static" {
  origin {
    domain_name = aws_s3_bucket.static.website_endpoint
    origin_id   = "s3bucket"

    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port              = "80"
      https_port             = "443"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_100"

  aliases = [var.domain_name]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    compress         = true
    target_origin_id = "s3bucket"
    default_ttl      = 300
    max_ttl          = 31536000
    min_ttl          = 0

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.static.id
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }

  logging_config {
    include_cookies = false
    bucket          = var.logging_bucket
    prefix          = var.logging_prefix
  }
}
