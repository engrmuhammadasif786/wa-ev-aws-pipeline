variable "project_name" {
  type = string
}

variable "ecs_role_arn" {
  type = string
}

variable "execution_role_arn" {
  type = string
}

variable "raw_bucket_name" {
  type    = string
  default = "wa-ev-raw-data"
}

variable "curated_bucket_name" {
  type    = string
  default = "wa-ev-curated-data"
}

variable "database_name" {
  type    = string
  default = "wa_ev_db"
}

variable "table_name" {
  type    = string
  default = "curated_ev_data"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "tags" {
  type    = map(string)
  default = {}
}
