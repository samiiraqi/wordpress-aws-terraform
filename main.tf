terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "billing" {
  source = "./modules/billing"
  providers = {
    aws = aws.us_east_1
  }

  project_name      = var.project_name
  alert_email       = var.alert_email
  billing_threshold = 1
}

module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
}
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
}
module "database" {
  source = "./modules/database"

  project_name       = var.project_name
  private_subnet_ids = module.networking.private_subnet_ids
  rds_sg_id          = module.security.rds_sg_id
  db_password        = var.db_password
}
module "compute" {
  source = "./modules/compute"

  project_name              = var.project_name
  vpc_id                    = module.networking.vpc_id
  pseudo_private_subnet_ids = module.networking.pseudo_private_subnet_ids
  public_subnet_ids         = module.networking.public_subnet_ids
  ecs_sg_id                 = module.security.ecs_sg_id
  alb_sg_id                 = module.security.alb_sg_id
  db_endpoint               = module.database.db_endpoint
  db_name                   = module.database.db_name
  db_username               = module.database.db_username
  db_password               = var.db_password
  sns_topic_arn             = module.billing.sns_topic_arn
}
module "monitoring" {
  source         = "./modules/monitoring"
  project_name   = var.project_name
  alb_arn_suffix = module.compute.alb_arn_suffix
  sns_topic_arn  = module.billing.sns_topic_arn
}