output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  value = aws_ecs_cluster.main.arn
}

output "ingestion_task_definition_arn" {
  value = aws_ecs_task_definition.ingestion.arn
}

output "transform_task_definition_arn" {
  value = aws_ecs_task_definition.transform.arn
}

output "ecr_repository_url" {
  value = aws_ecr_repository.main.repository_url
}
