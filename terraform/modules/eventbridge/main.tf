resource "aws_scheduler_schedule" "monthly" {
  name = "${var.project_name}-monthly-pipeline"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = var.schedule_expression

  target {
    arn      = var.state_machine_arn
    role_arn = var.schedule_role_arn

    retry_policy {
      maximum_event_age_in_seconds = 3600
      maximum_retry_attempts       = 2
    }
  }
}
