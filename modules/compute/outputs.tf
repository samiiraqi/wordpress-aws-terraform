output "alb_dns_name" {
  value = module.alb.lb_dns_name
}

output "alb_zone_id" {
  value = module.alb.lb_zone_id
}

output "alb_arn" {
  value = module.alb.lb_arn
}

output "alb_target_group_arn" {
  value = module.alb.target_group_arns[0]
}

output "ecs_cluster_name" {
  value = module.ecs_cluster.cluster_name
}

output "alb_arn_suffix" {
  value = module.alb.lb_arn_suffix
}

output "ecs_cluster_id" {
  value = module.ecs_cluster.cluster_id
}

output "ecs_capacity_provider" {
  value = aws_ecs_capacity_provider.main.name
}
