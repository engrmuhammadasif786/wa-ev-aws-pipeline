variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "wa-ev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "raw_bucket_name" {
  description = "S3 bucket for raw data"
  type        = string
  default     = "wa-ev-raw-data"
}

variable "curated_bucket_name" {
  description = "S3 bucket for curated data"
  type        = string
  default     = "wa-ev-curated-data"
}

variable "athena_database" {
  description = "Glue/Athena database name"
  type        = string
  default     = "wa_ev_db"
}

variable "athena_table" {
  description = "Athena table name for curated data"
  type        = string
  default     = "curated_ev_data"
}

variable "schedule_expression" {
  description = "EventBridge schedule expression"
  type        = string
  default     = "cron(0 8 1 * ? *)" # Monthly on 1st at 08:00 UTC
}

variable "github_repository" {
  description = "GitHub immutable OIDC repository subject prefix, excluding the leading repo:"
  type        = string
  default     = "engrmuhammadasif786@84713360/wa-ev-aws-pipeline@1409100059"
}

variable "github_branch" {
  description = "Git branch allowed to assume the GitHub Actions deployment role"
  type        = string
  default     = "main"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "wa-ev-pipeline"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
