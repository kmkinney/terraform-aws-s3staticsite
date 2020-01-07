terraform {
  required_version = ">= 0.12.16"
  required_providers {
    aws = ">= 2.42"
  }
}

provider "aws" {
  alias = "aws_n_va"
  region = "us-east-1"
}

module "cf_dist" {
  source             = "git@github.com:byu-oit/terraform-aws-cloudfront-dist?ref=v1.0.0"
  env_tag            = var.env_tag
  origin_domain_name = aws_s3_bucket.website.bucket_domain_name
  origin_id          = aws_s3_bucket.website.bucket
  repo_name          = var.repo_name
  origin_protocol_policy = "http-only"
  origin_path = var.origin_path
  index_doc = var.index_doc
  cname = var.site_url
  cname_ssl_cert_arn = aws_acm_certificate.cert.arn
  allowed_method = ["GET", "HEAD"]
}

module "hosted_zone" {
  source            = "git@github.com:byu-oit/terraform-aws-custom-url.git?ref=v1.0.0"
  env_tag           = var.env_tag
  data_sensitivity_tag = var.data_sesitivity_tag
  repo_name = var.repo_name
  url = var.site_url
  alias_domain_name = module.cf_dist.domain_name
  alias_zone_id     = module.cf_dist.hosted_zone_id
}

resource "aws_acm_certificate" "cert" {
  provider = aws.aws_n_va
  domain_name = var.site_url
  validation_method = "DNS"
}

// TODO: Add cert validation

resource "aws_s3_bucket" "website" {
  bucket = "${var.repo_name}-${var.branch}-s3staticsite"

  website {
    index_document = var.index_doc
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
}
