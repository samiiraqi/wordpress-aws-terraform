
variable "project_name" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "rds_sg_id" {
  type = string
}

variable "db_name" {
  type    = string
  default = "wordpress"
}

variable "db_username" {
  type    = string
  default = "wordpress_user"
}
variable "kms_secretsmanager_key_arn" {
  type = string
}

variable "kms_rds_key_arn" {
  type = string
}
