resource "aws_cloudwatch_metric_alarm" "high_container_restarts" {
  alarm_name          = "${var.project_name}-high-ecs-task-restarts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "RestartCount"
  namespace           = "ECS/ContainerInsights"
  period              = var.alarm_period
  statistic           = "Sum"
  threshold           = var.alarm_threshold
  alarm_description   = "Triggers when ECS container restarts >= ${var.alarm_threshold} in ${var.alarm_period / 60} min."
  alarm_actions       = [aws_sns_topic.ecs_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }
}
