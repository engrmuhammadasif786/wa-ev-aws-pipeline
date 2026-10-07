output "raw_bucket" {
  description = "S3 bucket for raw data"
  value       = module.s3.raw_bucket_name
}

output "curated_bucket" {
  description = "S3 bucket for curated data"
  value       = module.s3.curated_bucket_name
}

output "athena_database" {
  description = "Athena database name"
  value       = module.athena.database_name
}

output "athena_workgroup" {
  description = "Athena workgroup name"
  value       = module.athena.workgroup_name
}

# output "glue_job_name" {
#   description = "Glue transformation job name"
#   value       = module.glue.glue_job_name
# }

output "step_functions_arn" {
  description = "Step Functions state machine ARN"
  value       = module.step_functions.state_machine_arn
}

output "eventbridge_schedule_arn" {
  description = "EventBridge schedule ARN"
  value       = module.eventbridge.schedule_arn
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "github_actions_role_arn" {
  description = "Role ARN to set as the GitHub Actions AWS_ROLE_ARN repository secret"
  value       = module.iam.github_actions_role_arn
}
