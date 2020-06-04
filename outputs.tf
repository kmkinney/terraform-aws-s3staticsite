output "site_bucket" {
  value = aws_s3_bucket.website
}

output "cf_distribution" {
  value = aws_cloudfront_distribution.cdn
}
