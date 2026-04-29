variable "project_name" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}

variable "alb_dns_name" {
  type = string
}

variable "alb_zone_id" {
  type = string
}

variable "alb_arn" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "existing_certificate_arn" {
  type        = string
  default     = ""
  description = "ARN of an existing ACM certificate to use instead of creating a new one"
}
