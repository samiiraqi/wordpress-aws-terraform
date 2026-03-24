variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = "demo-infra-bucket-156041402173"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "demo"
    Project     = "demo-infra"
    ManagedBy   = "terraform"
    Owner       = "sami"
  }
}
