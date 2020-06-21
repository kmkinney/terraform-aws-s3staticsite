terraform {
  required_version = "0.12.26"
}

provider "aws" {
  version = "~> 2.42"
  region  = "us-west-2"
}

# Note: Typically you would want to use a more human friendly URL for a website,
# probably something like "myapp.byu.edu".
data "aws_route53_zone" "zone" {
  name = "byu-oit-terraform-dev.amazon.byu.edu"
}

module "s3_site" {
  source         = "../../"
  site_url       = "teststatic.byu-oit-terraform-dev.amazon.byu.edu"
  hosted_zone_id = data.aws_route53_zone.zone.id
  s3_bucket_name = "terraform-module-dev-s3staticsite"
  tags = {
    "data-sensitivity" = "confidential"
    "env"              = "dev"
    "repo"             = "https://github.com/byu-oit/terraform-module"
  }
}

output "site_bucket" {
  value = module.s3_site.site_bucket
}

output "cf_distribution" {
  value = module.s3_site.cf_distribution
}

output "dns_record" {
  value = module.s3_site.dns_record
}
