variable "project_name" {
  type = string
}

variable "raw_bucket_arn" {
  type = string
}

variable "curated_bucket_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
