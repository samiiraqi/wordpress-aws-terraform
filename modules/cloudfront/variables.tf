variable "project_name" {
  type = string
}

variable "alb_dns_name" {
  type        = string
  description = "DNS name of the ALB to use as CloudFront origin"
}

variable "domain_name" {
  type        = string
  description = "Domain name for the CloudFront distribution"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ARN of ACM certificate in us-east-1 for CloudFront (must be in us-east-1)"
}

variable "web_acl_arn" {
  type        = string
  default     = ""
  description = "ARN of WAFv2 Web ACL (must be CLOUDFRONT scope in us-east-1)"
}
