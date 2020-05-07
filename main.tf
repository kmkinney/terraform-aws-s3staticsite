terraform {
  required_version = ">= 0.12.16"
  required_providers {
    aws = ">= 2.42"
  }
}

provider "aws" {
  alias  = "aws_n_va"
  region = "us-east-1"
}


//Always create a certificate. It may takes several hours
resource "aws_acm_certificate" "cert" {
  provider          = aws.aws_n_va
  domain_name       = var.site_url
  validation_method = "DNS"
  tags              = var.tags
}

resource "aws_cloudfront_distribution" "cdn" {
  price_class = var.cloudfront_price_class
  origin {
    domain_name = aws_s3_bucket.website.website_endpoint
    origin_id   = aws_s3_bucket.website.bucket
    origin_path = var.origin_path

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2", "TLSv1.1", "TLSv1"]
    }
  }

  comment             = "CDN for ${var.site_url}"
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = var.index_doc
  aliases             = [var.site_url]

  default_cache_behavior {
    target_origin_id = aws_s3_bucket.website.bucket
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]

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
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  wait_for_deployment = var.wait_for_deployment
  tags                = var.tags
}

resource "aws_route53_zone" "main" {
  name = var.site_url
  tags = var.tags
}

resource "aws_route53_record" "cert_validation" {
  name    = aws_acm_certificate.cert.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.cert.domain_validation_options[0].resource_record_type
  zone_id = aws_route53_zone.main.zone_id
  records = [aws_acm_certificate.cert.domain_validation_options[0].resource_record_value]
  ttl     = 60
}

resource "aws_route53_record" "custom-url-a" {
  name    = var.site_url
  type    = "A"
  zone_id = aws_route53_zone.main.zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
  }
}

resource "aws_route53_record" "custom-url-4a" {
  name    = var.site_url
  type    = "AAAA"
  zone_id = aws_route53_zone.main.zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
  }
}

resource "aws_s3_bucket" "website" {
  bucket = var.s3_bucket_name

  website {
    index_document = var.index_doc
    error_document = var.error_doc
  }

  lifecycle_rule {
    enabled                                = true
    abort_incomplete_multipart_upload_days = 10
    id                                     = "AutoAbortFailedMultipartUpload"
  }

  tags = var.tags
}

data "aws_iam_policy_document" "static_website" {
  statement {
    sid       = "1"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website.arn}/*"]

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
  }
}

resource "aws_s3_bucket_policy" "static_website_read" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.static_website.json
}
