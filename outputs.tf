output "name_servers" {
  value = aws_route53_zone.main.name_servers
}

output "site_bucket" {
  value = aws_s3_bucket.website
}
