output "alb_sg_id" {
  value = module.alb_sg.security_group_id
}

output "ecs_sg_id" {
  value = module.ecs_sg.security_group_id
}

output "rds_sg_id" {
  value = module.rds_sg.security_group_id
}