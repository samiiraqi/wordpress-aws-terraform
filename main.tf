terraform {
  backend "s3" {
    bucket         = "wordpress-terraform-state-156041402173"
    key            = "wordpress/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "wordpress-terraform-lock"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-east-1:156041402173:key/70f62206-c0c0-49d2-8e96-80965542e33f"
  }

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

module "kms_secretsmanager" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  description             = "KMS key for Secrets Manager"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  aliases                 = ["${var.project_name}-secretsmanager"]

  tags = {
    Name = "${var.project_name}-secretsmanager-key"
  }
}

module "kms_rds" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  description             = "KMS key for RDS"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  aliases                 = ["${var.project_name}-rds"]

  tags = {
    Name = "${var.project_name}-rds-key"
  }
}

module "networking" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.21.0/24", "10.0.22.0/24"]
  intra_subnets   = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = false

  tags = {
    Name = "${var.project_name}-vpc"
  }
}
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = module.networking.vpc_id
  service_name        = "com.amazonaws.us-east-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.networking.intra_subnets
  security_group_ids  = [module.security.ecs_sg_id]
  private_dns_enabled = true
  tags = { Name = "${var.project_name}-ecr-api" }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = module.networking.vpc_id
  service_name        = "com.amazonaws.us-east-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.networking.intra_subnets
  security_group_ids  = [module.security.ecs_sg_id]
  private_dns_enabled = true
  tags = { Name = "${var.project_name}-ecr-dkr" }
}

resource "aws_vpc_endpoint" "ecs" {
  vpc_id              = module.networking.vpc_id
  service_name        = "com.amazonaws.us-east-1.ecs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.networking.intra_subnets
  security_group_ids  = [module.security.ecs_sg_id]
  private_dns_enabled = true
  tags = { Name = "${var.project_name}-ecs" }
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = module.networking.vpc_id
  service_name        = "com.amazonaws.us-east-1.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.networking.intra_subnets
  security_group_ids  = [module.security.ecs_sg_id]
  private_dns_enabled = true
  tags = { Name = "${var.project_name}-secretsmanager" }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = module.networking.vpc_id
  service_name        = "com.amazonaws.us-east-1.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.networking.intra_subnets
  security_group_ids  = [module.security.ecs_sg_id]
  private_dns_enabled = true
  tags = { Name = "${var.project_name}-logs" }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.networking.vpc_id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.networking.intra_route_table_ids
  tags = { Name = "${var.project_name}-s3" }
}

module "security" {
  source       = "./modules/security"
  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
}

module "database" {
  source                     = "./modules/database"
  project_name               = var.project_name
  private_subnet_ids         = module.networking.private_subnets
  rds_sg_id                  = module.security.rds_sg_id
  kms_secretsmanager_key_arn = module.kms_secretsmanager.key_arn
  kms_rds_key_arn            = module.kms_rds.key_arn
}

module "compute" {
  source                    = "./modules/compute"
  project_name              = var.project_name
  vpc_id                    = module.networking.vpc_id
  intra_subnet_ids = module.networking.intra_subnets
  public_subnet_ids         = module.networking.public_subnets
  ecs_sg_id                 = module.security.ecs_sg_id
  alb_sg_id                 = module.security.alb_sg_id
  db_endpoint               = module.database.db_endpoint
  db_name                   = module.database.db_name
  db_username               = module.database.db_username
  db_secret_arn             = module.database.db_secret_arn
  sns_topic_arn             = module.billing.sns_topic_arn
}
