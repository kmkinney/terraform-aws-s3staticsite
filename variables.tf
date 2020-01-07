variable "env_tag" {
  type = string
  description = "The environment tag for the resources."
}

variable data_sesitivity_tag {
  type = string
  default = "confidential"
  description = "The data-sensitivity tag for the resources."
}

variable "repo_name" {
  type = string
  description = "The name of the repo containing the site."
}

variable "branch" {
  type = string
  description = "Branch the site will be deployed from."
}

variable "index_doc" {
  type = string
  default = "index.html"
  description = "The index document of the site."
}

variable "origin_path" {
  type = string
  default = ""
  description = "The path to the file in the S3 bucket (no trailing slash)."
}

variable "site_url" {
  type = string
  description = "The URL for the site."
}