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
  type = string
}

variable "n8n_webhook_url" {
  type        = string
  description = "n8n webhook URL to receive SNS notifications"
}

variable "aws_region" {
  type = string
}

variable "alb_arn" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "db_identifier" {
  type = string
}
