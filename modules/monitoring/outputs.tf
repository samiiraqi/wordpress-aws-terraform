output "dashboard_url" {
  value       = "https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=${var.project_name}-dashboard"
  description = "CloudWatch Dashboard URL"
}
