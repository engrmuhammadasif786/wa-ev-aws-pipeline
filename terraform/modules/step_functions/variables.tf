variable "project_name" {
  type = string
}

variable "curated_bucket_name" {
  type = string
}

variable "ecs_cluster_arn" {
  type = string
}

variable "ingestion_ecs_task_definition" {
  type = string
}

variable "transform_ecs_task_definition" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

# variable "glue_job_name" {
#   type = string
# }

variable "raw_bucket_name" {
  type = string
}

variable "state_machine_role_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
