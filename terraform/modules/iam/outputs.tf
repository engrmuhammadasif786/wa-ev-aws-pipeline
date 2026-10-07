output "ecs_execution_role_arn" {
  value = aws_iam_role.ecs_execution.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task.arn
}

output "glue_role_arn" {
  value = aws_iam_role.glue.arn
}

output "step_functions_role_arn" {
  value = aws_iam_role.step_functions.arn
}

output "eventbridge_role_arn" {
  value = aws_iam_role.eventbridge.arn
}
