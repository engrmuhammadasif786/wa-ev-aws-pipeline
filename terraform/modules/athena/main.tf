# Athena Workgroup
resource "aws_athena_workgroup" "main" {
  name = "${var.project_name}-workgroup"

  configuration {
    result_configuration {
      output_location = "s3://${var.curated_bucket_name}/athena-query-results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }

    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false # Reduce costs
  }

  tags = var.tags
}

# Athena Named Query (example)
resource "aws_athena_named_query" "ev_by_make" {
  name      = "${var.project_name}-ev-by-make"
  workgroup = aws_athena_workgroup.main.id
  database  = var.database_name
  query     = "SELECT make, COUNT(*) as ev_count FROM ${var.table_name} WHERE make IS NOT NULL AND make != 'Unknown' GROUP BY make ORDER BY ev_count DESC LIMIT 20"
}

resource "aws_athena_named_query" "ev_by_year" {
  name      = "${var.project_name}-ev-by-year"
  workgroup = aws_athena_workgroup.main.id
  database  = var.database_name
  query     = "SELECT model_year, COUNT(*) as ev_count FROM ${var.table_name} WHERE model_year IS NOT NULL GROUP BY model_year ORDER BY model_year ASC"
}
