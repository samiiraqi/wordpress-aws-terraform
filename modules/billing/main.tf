resource "aws_sns_topic" "billing_alert" {
  name = "${var.project_name}-billing-alert"
}

resource "aws_sns_topic_subscription" "billing_email" {
  topic_arn = aws_sns_topic.billing_alert.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "billing_alarm" {
  alarm_name          = "${var.project_name}-billing-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 86400
  statistic           = "Maximum"
  threshold           = var.billing_threshold
  alarm_description   = "Alert when AWS charges exceed $${var.billing_threshold}"
  alarm_actions       = [aws_sns_topic.billing_alert.arn]

  dimensions = {
    Currency = "USD"
  }
}