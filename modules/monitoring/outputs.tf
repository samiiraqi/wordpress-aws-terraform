output "cloudtrail_arn" {
  value = aws_cloudtrail.main.arn
}

output "cloudtrail_s3_bucket" {
  value = aws_s3_bucket.cloudtrail.id
}

output "vpc_flow_logs_log_group" {
  value = aws_cloudwatch_log_group.vpc_flow_logs.name
}

output "guardduty_detector_id" {
  value = aws_guardduty_detector.main.id
}

output "securityhub_id" {
  value = aws_securityhub_account.main.id
}
