output "billing_sns_topic_arn" {
  value = module.billing.sns_topic_arn
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnet_ids" {
  value = module.networking.public_subnets
}

output "pseudo_private_subnet_ids" {
  value = module.networking.intra_subnets
}

output "private_subnet_ids" {
  value = module.networking.private_subnets
}

output "alb_sg_id" {
  value = module.security.alb_sg_id
}

output "ecs_sg_id" {
  value = module.security.ecs_sg_id
}

output "rds_sg_id" {
  value = module.security.rds_sg_id
}

output "db_endpoint" {
  value = module.database.db_endpoint
}

output "db_name" {
  value = module.database.db_name
}

output "db_username" {
  value     = module.database.db_username
  sensitive = true
}

output "alb_dns_name" {
  value = module.compute.alb_dns_name
}

output "ecs_cluster_name" {
  value = module.compute.ecs_cluster_name
}

output "efs_id" {
  value = module.compute.efs_id
}