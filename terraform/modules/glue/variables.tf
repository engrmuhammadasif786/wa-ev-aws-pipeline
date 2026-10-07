variable "project_name" {
  type = string
}

variable "database_name" {
  type = string
}

variable "table_name" {
  type = string
}

variable "raw_bucket_name" {
  type = string
}

variable "curated_bucket_name" {
  type = string
}

variable "glue_role_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
