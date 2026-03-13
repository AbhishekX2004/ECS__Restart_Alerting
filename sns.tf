resource "aws_sns_topic" "ecs_alerts" {
  name = "${var.project_name}-ecs-restart-alerts"
}

resource "aws_sns_topic_subscription" "ecs_alerts_email" {
  topic_arn = aws_sns_topic.ecs_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
