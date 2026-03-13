output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.main.name
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.main.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for restart alerts"
  value       = aws_sns_topic.ecs_alerts.arn
}

output "cloudwatch_alarm_name" {
  description = "Name of the CloudWatch alarm monitoring container restarts"
  value       = aws_cloudwatch_metric_alarm.high_container_restarts.alarm_name
}
