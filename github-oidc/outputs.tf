output "role_arn" {
  description = "ARN of the IAM role for GitHub Actions"
  value       = module.iam_github_oidc_role.arn
}
