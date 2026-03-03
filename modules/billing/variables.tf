terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

variable "project_name" {
  type = string
}

variable "alert_email" {
  type        = string
  description = "Email address for billing alerts"
}

variable "billing_threshold" {
  type        = number
  default     = 1
  description = "Cost threshold in USD"
}
