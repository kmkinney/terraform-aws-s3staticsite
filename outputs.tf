output "name_servers" {
  value = module.hosted_zone.hosted_zone.name_servers
}

output "site_bucket" {
  value = aws_s3_bucket.website
}