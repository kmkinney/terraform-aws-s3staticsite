provider "aws" {
  version = "~> 2.42"
  region  = "us-west-2"
}

module "s3_site" {
  source    = "github.com/byu-oit/terraform-aws-s3staticsite?ref=v1.1.0"
  env_tag   = "dev"
  repo_name = "terraform-module"
  branch    = "dev"
  site_url  = "terraform-module.byu.edu"
}
