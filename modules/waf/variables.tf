variable "project_name" {
  type = string
}

variable "alb_arn" {
  type        = string
  description = "ARN of the ALB to associate the WAF with"
}
