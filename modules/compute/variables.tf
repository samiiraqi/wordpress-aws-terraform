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

variable "vpc_id" {
  type = string
}

variable "pseudo_private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "ecs_sg_id" {
  type = string
}

variable "alb_sg_id" {
  type = string
}

variable "db_endpoint" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}
variable "sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for notifications"
}