output "db_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "db_name" {
  value = module.rds.db_instance_name
}

output "db_username" {
  value = module.rds.db_instance_username
}

output "db_secret_arn" {
  value       = aws_secretsmanager_secret.db_password.arn
  description = "ARN of the secret containing DB credentials"
}