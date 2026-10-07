variable "project_name" {
  type    = string
  default = "wa-ev"
}

variable "database_name" {
  type = string
}

variable "table_name" {
  type = string
}

variable "curated_bucket_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
