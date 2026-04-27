output "grafana_target_group_arn" {
  value = aws_lb_target_group.grafana.arn
}

output "grafana_security_group_id" {
  value = aws_security_group.grafana.id
}

output "grafana_service_name" {
  value = aws_ecs_service.grafana.name
}

output "grafana_task_role_arn" {
  value = aws_iam_role.grafana_task.arn
}
