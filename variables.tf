variable "aws_region" {
  description = "AWS region to deploy all resources into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "A short name used as a prefix for every resource (e.g. 'monitoring', 'payments')"
  type        = string
  default     = "monitoring"
}

# Networking
variable "vpc_id" {
  description = "VPC ID to deploy into. Leave empty to use the default VPC."
  type        = string
  default     = ""
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to the ECS tasks"
  type        = bool
  default     = true
}

# ECS Task Definition
variable "ecs_task_cpu" {
  description = "CPU units for the Fargate task (e.g. '256' = 0.25 vCPU)"
  type        = string
  default     = "256"
}

variable "ecs_task_memory" {
  description = "Memory (MiB) for the Fargate task (e.g. '512' = 0.5 GB)"
  type        = string
  default     = "512"
}

variable "container_image" {
  description = "Docker image for the container"
  type        = string
  default     = "busybox"
}

variable "container_command" {
  description = "Entrypoint command passed to the container"
  type        = list(string)
  default     = ["sh", "-c", "sleep 65 && exit 1"]
}

variable "container_max_retry_count" {
  description = "Maximum number of restart attempts for the container restart policy"
  type        = number
  default     = 10
}

variable "container_restart_attempt_period" {
  description = "Period (in seconds) between restart attempts"
  type        = number
  default     = 60
}

variable "desired_count" {
  description = "Number of ECS tasks to run in the service"
  type        = number
  default     = 1
}


# CloudWatch Logs
variable "log_retention_days" {
  description = "Number of days to retain CloudWatch log events"
  type        = number
  default     = 7
}

# Alerting — SNS
variable "alert_email" {
  description = "Email address to receive SNS alert notifications"
  type        = string
}

# Alerting — CloudWatch Alarm
variable "alarm_threshold" {
  description = "Number of container restarts that triggers the alarm"
  type        = number
  default     = 3
}

variable "alarm_evaluation_periods" {
  description = "Number of consecutive periods the metric must breach the threshold"
  type        = number
  default     = 1
}

variable "alarm_period" {
  description = "Length of each evaluation period in seconds (default 600 = 10 min)"
  type        = number
  default     = 600
}
