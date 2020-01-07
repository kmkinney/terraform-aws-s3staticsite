# Terraform AWS S3-hosted Static Site

## Usage
```hcl
module "s3_site" {
  source    = "git@github.com:byu-oit/terraform-aws-s3-site?ref=v1.0.0"
  env_tag   = "dev"
  repo_name = "my-awesome-site"
  branch    = "dev"
  site_url  = "my-site.byu.edu"
}
```

## Inputs
| Name | Type | Description | Default |
| --- | --- | --- | --- |
| evn_tag | string | The environment tag for the resources. |
| data_sensitivity | string | The data-sensitivity tag for the resources. | confidential |
| repo_name | string | The name of the repo containing the site. |
| branch | string | Branch the site will be deployed from. |
| index_doc | string | The index document of the site. | index.html |
| origin_path | string | The path to the file in the S3 bucket (no trailing slash). | *Empty string* |
| site_url | string | The URL for the site. |

## Outputs
| Name | Type | Description |
| --- | --- | --- |
| name_servers | set(string) | The name servers associated with the Route 53 hosted zone for the site. |
| site_bucket | object | The deployment [S3 bucket object](https://www.terraform.io/docs/providers/aws/r/s3_bucket.html#attributes-reference). |
