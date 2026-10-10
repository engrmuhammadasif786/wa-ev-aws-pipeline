# ECS Cluster (no persistent services, only task runs)
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled" # Keep costs low; enable for debugging if needed
  }

  tags = var.tags
}

# Ingestion Task Definition (Fargate Spot)
resource "aws_ecs_task_definition" "ingestion" {
  family                   = "${var.project_name}-ingestion"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # 0.25 vCPU
  memory                   = "512" # 0.5 GB
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.ecs_role_arn

  container_definitions = jsonencode([
    {
      name      = "ingestion"
      image     = "${aws_ecr_repository.main.repository_url}:latest"
      essential = true
      command = [
        "python",
        "/opt/airflow/src/ingestion/fetch_ev_data.py",
        "--bucket",
        "${var.raw_bucket_name}",
      ]
      environment = [
        { name = "AWS_DEFAULT_REGION", value = var.aws_region },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ingestion"
        }
      }
    }
  ])

  tags = var.tags
}

# Transformation Task Definition (Fargate Spot)
resource "aws_ecs_task_definition" "transform" {
  family                   = "${var.project_name}-transform"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # 0.25 vCPU
  memory                   = "512" # 0.5 GB
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.ecs_role_arn

  container_definitions = jsonencode([
    {
      name      = "transform"
      image     = "${aws_ecr_repository.main.repository_url}:latest"
      essential = true
      command = [
        "python",
        "/opt/airflow/src/transform/glue_ev_transform.py",
        "--raw-path",
        "s3://${var.raw_bucket_name}/",
        "--curated-path",
        "s3://${var.curated_bucket_name}/",
        "--database",
        "${var.database_name}",
        "--table",
        "${var.table_name}",
      ]
      environment = [
        { name = "AWS_DEFAULT_REGION", value = var.aws_region },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "transform"
        }
      }
    }
  ])

  tags = var.tags
}

# ECR Repository
resource "aws_ecr_repository" "main" {
  name                 = var.project_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false # Disable to reduce build time/cost for course project
  }

  force_delete = true # Allow terraform destroy to clean up

  tags = var.tags
}

# CloudWatch Log Group for ECS tasks
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 1 # Minimize log storage costs

  tags = var.tags
}
