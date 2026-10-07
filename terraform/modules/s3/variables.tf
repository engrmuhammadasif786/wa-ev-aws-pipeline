variable "raw_bucket_name" {
  type = string
}

variable "curated_bucket_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
