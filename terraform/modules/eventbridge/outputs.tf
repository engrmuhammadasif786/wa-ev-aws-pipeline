output "schedule_arn" {
  value = aws_scheduler_schedule.monthly.arn
}

output "schedule_name" {
  value = aws_scheduler_schedule.monthly.name
}
