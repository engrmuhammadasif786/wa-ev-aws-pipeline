resource "aws_sfn_state_machine" "pipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = var.state_machine_role_arn

  definition = jsonencode({
    Comment = "Washington EV Data Pipeline"
    StartAt = "IngestEVData"
    States = {
      IngestEVData = {
        Type     = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        Parameters = {
          Cluster        = var.ecs_cluster_arn
          TaskDefinition = var.ingestion_ecs_task_definition
          LaunchType     = "FARGATE"
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets        = var.subnet_ids
              SecurityGroups = [var.security_group_id]
              AssignPublicIp = "ENABLED"
            }
          }
          Overrides = {
            ContainerOverrides = [
              {
                Name = "ingestion"
                Command = [
                  "python",
                  "s3://${var.raw_bucket_name}/ingestion/fetch_ev_data.py",
                  "--bucket",
                  var.raw_bucket_name,
                ]
              }
            ]
          }
        }
        Next = "CheckIngestionResult"
      }
      CheckIngestionResult = {
        Type = "Choice"
        Choices = [
          {
            Variable     = "$.tasks[0].lastStatus"
            StringEquals = "STOPPED"
            Next         = "RunECSTrasform"
          }
        ]
        Default = "PipelineFailed"
      }
      RunECSTrasform = {
        Type     = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        Parameters = {
          Cluster        = var.ecs_cluster_arn
          TaskDefinition = var.transform_ecs_task_definition
          LaunchType     = "FARGATE"
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets        = var.subnet_ids
              SecurityGroups = [var.security_group_id]
              AssignPublicIp = "ENABLED"
            }
          }
          Overrides = {
            ContainerOverrides = [
              {
                Name = "trasform"
                Command = [
                  "python",
                  "s3://${var.raw_bucket_name}/transform/glue_ev_transform.py",
                  "--bucket",
                  var.raw_bucket_name,
                ]
              }
            ]
          }
        }
        Next = "PipelineSuccess"
      }
      PipelineSuccess = {
        Type = "Succeed"
      }
      PipelineFailed = {
        Type = "Fail"
        Cause = "Ingestion task did not complete successfully"
      }
    }
  })

  tags = var.tags
}
