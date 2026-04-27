variable "project_name" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for flow logs"
}

variable "aws_account_id" {
  type        = string
  description = "AWS account ID used for CloudTrail S3 bucket policy"
}

variable "aws_region" {
  type        = string
  description = "AWS region used for Security Hub standards ARNs"
}

variable "alb_arn" {
  type        = string
  description = "Full ARN of the ALB for CloudWatch metrics"
}

variable "ecs_cluster_name" {
  type        = string
  description = "ECS cluster name for CloudWatch metrics"
}

variable "ecs_service_name" {
  type        = string
  description = "ECS service name for CloudWatch metrics"
}

variable "db_identifier" {
  type        = string
  description = "RDS DB instance identifier for CloudWatch metrics"
}
