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

data "aws_iam_account_alias" "current" {}
data "aws_acm_certificate" "nva_account_cert" {
  provider = aws.aws_n_va
  domain   = "${data.aws_iam_account_alias.current.account_alias}.amazon.byu.edu"
}

locals {
  tags = {
    env              = var.env_tag
    data-sensitivity = var.data_sensitivity_tag
    repo             = "https://github.com/byu-oit/${var.repo_name}"
  }
}

//TODO: Always creates cert, which seems problematic/unncessary if we are trying to use an existing certification sometimes
resource "aws_acm_certificate" "cert" {
  provider          = aws.aws_n_va
  domain_name       = var.site_url
  validation_method = "DNS"

  tags = local.tags
}

resource "aws_cloudfront_distribution" "cdn" {
  price_class = "PriceClass_100"
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

  comment             = "CDN for ${var.repo_name}"
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = var.index_doc
  //TODO: Does it actually work with no site url? Or did this only work for the submodule?
  //TODO: Repo Name might not be what we want here
  aliases = var.site_url != "" ? [var.site_url] : ["${var.repo_name}.${data.aws_iam_account_alias.current.account_alias}.amazon.byu.edu"]

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
    acm_certificate_arn      = var.site_url == "" ? data.aws_acm_certificate.nva_account_cert.arn : aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  wait_for_deployment = var.wait_for_deployment

  tags = local.tags
}

//TODO: How did it work if the site_url could be an empty string?
resource "aws_route53_zone" "main" {
  name = var.site_url

  tags = local.tags
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
  bucket = "${var.repo_name}-${var.branch}-s3staticsite"

  website {
    index_document = var.index_doc
    error_document = var.error_doc
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [
      lifecycle_rule
    ]
  }
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

  lifecycle {
    ignore_changes = [
      //TODO: What is ACS updating? Is it actually divvy cloud and should we be matching what they are changing it to?
      policy # The policy will get updated by ACS, so we need to ignore it after its created
    ]
  }
}
