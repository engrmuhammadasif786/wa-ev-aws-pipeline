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
        }
        Next = "PipelineSuccess"
      }
      PipelineSuccess = {
        Type = "Succeed"
      }
      PipelineFailed = {
        Type  = "Fail"
        Cause = "Ingestion task did not complete successfully"
      }
    }
  })

  tags = var.tags
}
