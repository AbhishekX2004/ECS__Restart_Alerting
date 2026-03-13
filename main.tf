variable "aws_region" {
  default = "us-east-1"
}

variable "alert_email" {
  description = "Email address to receive SNS alerts"
  type        = string
  default     = "abhishekverma5216@gmail.com" 
}

provider "aws" {
  region = var.aws_region
}

# --- 1. ECS Cluster with Container Insights ---
resource "aws_ecs_cluster" "monitoring_cluster" {
  name = "monitoring-test-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# --- 2. IAM Role for ECS Task Execution ---
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-role-crashing-test"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- 3. CloudWatch Log Group ---
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/crashing-task"
  retention_in_days = 7
}

# --- 4. Task Definition with Restart Policy ---
resource "aws_ecs_task_definition" "crashing_task" {
  family                   = "crashing-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # 0.25 vCPU
  memory                   = "512" # 0.5 GB
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "busybox-crasher"
      image     = "busybox"
      command   = ["sh", "-c", "sleep 65 && exit 1"]
      essential = true
      
      # The exact Restart Policy we configured
      restartPolicy = {
        enabled                 = true
        maximumRetryCount       = 10
        restartAttemptPeriod    = 60
      }
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# --- 5. Networking Data Sources (Uses Default VPC) ---
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- 6. ECS Service ---
resource "aws_ecs_service" "crashing_service" {
  name            = "crashing-service"
  cluster         = aws_ecs_cluster.monitoring_cluster.id
  task_definition = aws_ecs_task_definition.crashing_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    assign_public_ip = true
  }
}

# --- 7. SNS Topic & Subscription ---
resource "aws_sns_topic" "ecs_alerts" {
  name = "ecs-restart-alerts"
}

resource "aws_sns_topic_subscription" "ecs_alerts_email" {
  topic_arn = aws_sns_topic.ecs_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# --- 8. CloudWatch Alarm ---
resource "aws_cloudwatch_metric_alarm" "high_container_restarts" {
  alarm_name          = "High-ECS-Task-Restarts-crashing-service"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "RestartCount"
  namespace           = "ECS/ContainerInsights"
  period              = 600
  statistic           = "Sum"
  threshold           = 3
  alarm_description   = "Triggers when ECS containers restart >2 times in 10 mins."
  alarm_actions       = [aws_sns_topic.ecs_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.monitoring_cluster.name
    ServiceName = aws_ecs_service.crashing_service.name
  }
}