provider "aws" {
  version = "~> 2.42"
  region  = "us-west-2"
}

module "s3_site" {
  //  source    = "github.com/byu-oit/terraform-aws-s3staticsite?ref=v2.0.0"
  source = "../."
  //  env_tag   = "dev"
  //  repo_name = "terraform-module"
  //  branch    = "dev"
  site_url       = "teststatic.byu-oit-terraform-dev.amazon.byu.edu"
  s3_bucket_name = "terraform-module-dev-s3staticsite"
  tags = {
    "data-sensitivity" = "confidential"
    "env"              = "dev"
    "repo"             = "https://github.com/byu-oit/terraform-module"
  }
}
