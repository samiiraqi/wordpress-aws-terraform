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
