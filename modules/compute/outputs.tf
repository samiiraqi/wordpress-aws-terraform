output "alb_dns_name" {
  value = module.alb.lb_dns_name
}

output "ecs_cluster_name" {
  value = module.ecs_cluster.cluster_name
}

output "alb_arn_suffix" {
  value = module.alb.lb_arn_suffix
}
