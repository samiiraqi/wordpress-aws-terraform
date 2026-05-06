output "instance_id" {
  value = aws_instance.n8n.id
}

output "public_ip" {
  value = aws_instance.n8n.public_ip
}

output "webhook_url" {
  description = "Base webhook URL for SNS/alerts integration - configure matching webhook in n8n UI"
  value       = "http://${aws_instance.n8n.public_ip}:5678/webhook/sns-alerts"
}

output "n8n_url" {
  description = "n8n UI URL"
  value       = "http://${aws_instance.n8n.public_ip}:5678"
}

output "sg_id" {
  value = aws_security_group.n8n.id
}
