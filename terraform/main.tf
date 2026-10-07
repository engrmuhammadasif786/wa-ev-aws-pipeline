provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# ---------------------------------------------------------------------------
# S3 Buckets (Data Lake)
# ---------------------------------------------------------------------------
module "s3" {
  source = "./modules/s3"

  raw_bucket_name     = var.raw_bucket_name
  curated_bucket_name = var.curated_bucket_name
  tags                = var.tags
}

# ---------------------------------------------------------------------------
# IAM Roles
# ---------------------------------------------------------------------------
module "iam" {
  source = "./modules/iam"

  project_name        = var.project_name
  raw_bucket_arn      = module.s3.raw_bucket_arn
  curated_bucket_arn  = module.s3.curated_bucket_arn
  github_repository   = var.github_repository
  github_branch       = var.github_branch
  tags                = var.tags
}

# ---------------------------------------------------------------------------
# Glue Catalog & Job
# ---------------------------------------------------------------------------
module "glue" {
  source = "./modules/glue"

  project_name        = var.project_name
  database_name       = var.athena_database
  table_name          = var.athena_table
  raw_bucket_name     = module.s3.raw_bucket_name
  curated_bucket_name = module.s3.curated_bucket_name
  glue_role_arn       = module.iam.glue_role_arn
  tags                = var.tags
}

# ---------------------------------------------------------------------------
# Athena
# ---------------------------------------------------------------------------
module "athena" {
  source = "./modules/athena"

  database_name       = var.athena_database
  table_name          = var.athena_table
  curated_bucket_name = module.s3.curated_bucket_name
  tags                = var.tags
}

# ---------------------------------------------------------------------------
# ECS (Fargate Spot)
# ---------------------------------------------------------------------------
module "ecs" {
  source = "./modules/ecs"

  project_name    = var.project_name
  ecs_role_arn    = module.iam.ecs_task_role_arn
  execution_role_arn = module.iam.ecs_execution_role_arn
  tags            = var.tags
}

# ---------------------------------------------------------------------------
# Step Functions
# ---------------------------------------------------------------------------
module "step_functions" {
  source = "./modules/step_functions"

  project_name        = var.project_name
  ecs_cluster_arn     = module.ecs.cluster_arn
  ingestion_ecs_task_definition = module.ecs.ingestion_task_definition_arn
  transform_ecs_task_definition = module.ecs.transform_task_definition_arn
  subnet_ids          = data.aws_subnets.default.ids
  security_group_id   = aws_security_group.ecs_tasks.id
  raw_bucket_name     = module.s3.raw_bucket_name
  curated_bucket_name     = module.s3.curated_bucket_name
  state_machine_role_arn = module.iam.step_functions_role_arn
  tags                = var.tags
}

# ---------------------------------------------------------------------------
# EventBridge Scheduler
# ---------------------------------------------------------------------------
module "eventbridge" {
  source = "./modules/eventbridge"

  project_name        = var.project_name
  schedule_expression = var.schedule_expression
  state_machine_arn   = module.step_functions.state_machine_arn
  schedule_role_arn   = module.iam.eventbridge_role_arn
  tags                = var.tags
}

# ---------------------------------------------------------------------------
# Default VPC & Security Group
# ---------------------------------------------------------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.project_name}-ecs-"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-ecs-tasks"
  })
}
