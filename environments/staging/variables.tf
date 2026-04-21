variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "wordpress-staging"
}

variable "alert_email" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}
