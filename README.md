# Terraform AWS S3-hosted Static Site

This Terraform module deploys an S3-hosted static site with HTTPS enabled.

## Resources

- S3 bucket to deploy files.
- CloudFront distribution fronting the bucket to provide an SSL connection.
- Route 53 hosted zone for the BYU subdomain with records to the CloudFront distribution
- ACM certificate for the URL

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

**Note**: Using this module will require you to run `terraform apply` twice. The first time it will create the Route 53 hosted zone and certificate in ACM and then it will fail because it AWS can't validate the certificate. You need to contact the network team to setup a record in QIP for your desired subdomain name pointing to the name servers of the hosted zone created by Terraform (you can find that information in the Route 53 console). After AWS has validated the certificate (you can find that information in the ACM console), run `terraform apply` again and it should succeed.

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
