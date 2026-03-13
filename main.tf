# ECS Cluster (Container Insights enabled for monitoring)
resource "aws_ecs_cluster" "main" {
  count = var.use_existing_cluster ? 0 : 1
  name  = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

locals {
  ecs_cluster_id   = var.use_existing_cluster ? data.aws_ecs_cluster.existing[0].id : aws_ecs_cluster.main[0].id
  ecs_cluster_name = var.use_existing_cluster ? data.aws_ecs_cluster.existing[0].cluster_name : aws_ecs_cluster.main[0].name
  ecs_service_name = var.use_existing_service ? data.aws_ecs_service.existing[0].service_name : aws_ecs_service.main[0].name
}

# IAM Role — ECS Task Execution
resource "aws_iam_role" "ecs_execution_role" {
  count = var.use_existing_service ? 0 : 1
  name  = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  count      = var.use_existing_service ? 0 : 1
  role       = aws_iam_role.ecs_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_logs" {
  count             = var.use_existing_service ? 0 : 1
  name              = "/ecs/${var.project_name}-task"
  retention_in_days = var.log_retention_days
}

# Fargate Task Definition (with container restart policy)
resource "aws_ecs_task_definition" "main" {
  count                    = var.use_existing_service ? 0 : 1
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role[0].arn

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-container"
      image     = var.container_image
      command   = var.container_command
      essential = true

      # Container-level restart policy
      restartPolicy = {
        enabled              = true
        maximumRetryCount    = var.container_max_retry_count
        restartAttemptPeriod = var.container_restart_attempt_period
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs[0].name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "main" {
  count           = var.use_existing_service ? 0 : 1
  name            = "${var.project_name}-service"
  cluster         = local.ecs_cluster_id
  task_definition = aws_ecs_task_definition.main[0].arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.selected.ids
    assign_public_ip = var.assign_public_ip
  }
}