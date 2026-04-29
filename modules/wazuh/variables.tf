variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_id" {
  type        = string
  description = "Public subnet ID to deploy the Wazuh instance in"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to access Wazuh dashboard (port 443) and API (port 55000)"
}

variable "cloudtrail_bucket" {
  type        = string
  description = "S3 bucket name for CloudTrail logs"
}

variable "waf_logs_bucket" {
  type        = string
  description = "S3 bucket name for WAF logs"
  default     = ""
}

variable "alb_logs_bucket" {
  type        = string
  description = "S3 bucket name for ALB access logs"
  default     = ""
}
