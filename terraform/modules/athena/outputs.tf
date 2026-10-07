output "workgroup_name" {
  value = aws_athena_workgroup.main.name
}

output "database_name" {
  value = var.database_name
}
