output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = local.ecs_cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = local.ecs_service_name
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = var.use_existing_service ? "existing" : aws_ecs_task_definition.main[0].arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for restart alerts"
  value       = aws_sns_topic.ecs_alerts.arn
}

output "cloudwatch_alarm_name" {
  description = "Name of the CloudWatch alarm monitoring container restarts"
  value       = aws_cloudwatch_metric_alarm.high_container_restarts.alarm_name
}
