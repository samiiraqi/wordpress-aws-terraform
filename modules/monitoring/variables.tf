variable "project_name" {
  type = string
}

variable "alb_arn_suffix" {
  type        = string
  description = "ALB ARN suffix for CloudWatch metrics"
}

variable "sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for alarms"
}
