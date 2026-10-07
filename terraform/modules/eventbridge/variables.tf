variable "project_name" {
  type = string
}

variable "schedule_expression" {
  type = string
}

variable "state_machine_arn" {
  type = string
}

variable "schedule_role_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
