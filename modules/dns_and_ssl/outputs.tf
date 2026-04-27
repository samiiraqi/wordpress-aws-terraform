output "certificate_arn" {
  value = aws_acm_certificate.this.arn
}

output "domain_name" {
  value = var.domain_name
}

output "https_listener_arn" {
  value = aws_lb_listener.https.arn
}
