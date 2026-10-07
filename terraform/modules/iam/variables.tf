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
  description = "GitHub immutable OIDC repository subject prefix, excluding the leading repo:"
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
