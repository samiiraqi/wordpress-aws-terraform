output "instance_id" {
  value = aws_instance.wazuh.id
}

output "public_ip" {
  value = aws_eip.wazuh.public_ip
}

output "security_group_id" {
  value = aws_security_group.wazuh.id
}

output "iam_role_arn" {
  value = aws_iam_role.wazuh.arn
}

output "dashboard_url" {
  value = "https://${aws_eip.wazuh.public_ip}"
}
