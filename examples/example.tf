provider "aws" {
  version = "~> 2.42"
  region  = "us-west-2"
}

provider "aws" {
  alias  = "aws_n_va"
  region = "us-east-1"
}

data "aws_route53_zone" "zone" {
  provider = aws.aws_n_va
  name     = "byu-oit-terraform-dev.amazon.byu.edu"
}

module "s3_site" {
  source = "github.com/byu-oit/terraform-aws-s3staticsite?ref=v2.0.0"
  //source         = "../."
  site_url       = "teststatic.byu-oit-terraform-dev.amazon.byu.edu"
  hosted_zone_id = data.aws_route53_zone.zone.id
  s3_bucket_name = "terraform-module-dev-s3staticsite"
  tags = {
    "data-sensitivity" = "confidential"
    "env"              = "dev"
    "repo"             = "https://github.com/byu-oit/terraform-module"
  }
}
