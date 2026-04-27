variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "alb_sg_id" {
  type        = string
  description = "ALB security group ID - Grafana only accepts traffic from ALB"
}

variable "alb_https_listener_arn" {
  type        = string
  description = "ARN of the ALB HTTPS listener to attach the /grafana/* rule"
}

variable "ecs_cluster_id" {
  type        = string
  description = "ECS cluster ID to run Grafana service on"
}

variable "ecs_capacity_provider" {
  type        = string
  description = "ECS capacity provider name for the cluster"
}

variable "aws_region" {
  type        = string
  description = "AWS region used for CloudWatch datasource and log configuration"
}
