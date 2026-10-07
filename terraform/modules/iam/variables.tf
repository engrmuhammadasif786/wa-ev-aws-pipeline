variable "project_name" {
  type = string
}

variable "raw_bucket_arn" {
  type = string
}

variable "curated_bucket_arn" {
  type = string
}

variable "github_repository" {
  description = "GitHub repository allowed to deploy through OIDC, in owner/repository format"
  type        = string
}

variable "github_branch" {
  description = "Git branch allowed to assume the GitHub Actions deployment role"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
