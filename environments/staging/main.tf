terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

import {
  to = module.dns_and_ssl.aws_acm_certificate.this
  id = "arn:aws:acm:us-east-1:156041402173:certificate/59a08c3f-b47e-4dd9-8f8e-027c74b137ff"
}

import {
  to = module.monitoring.aws_guardduty_detector.main
  id = "eecd7d139f4050d633d44f79d911cc66"
}

import {
  to = module.monitoring.aws_securityhub_account.main
  id = "156041402173"
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "billing" {
  source = "../../modules/billing"
  providers = {
    aws = aws.us_east_1
  }
  project_name      = var.project_name
  alert_email       = var.alert_email
  billing_threshold = 1
}

module "networking" {
  source                     = "terraform-aws-modules/vpc/aws"
  version                    = "5.21.0"
  name                       = "${var.project_name}-vpc"
  cidr                       = "10.0.0.0/16"
  azs                        = ["us-east-1a", "us-east-1b"]
  public_subnets             = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets            = ["10.0.21.0/24", "10.0.22.0/24"]
  enable_dns_hostnames       = true
  enable_dns_support         = true
  enable_nat_gateway         = false
  manage_default_network_acl = false
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

module "security" {
  source       = "../../modules/security"
  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
}

module "database" {
  source             = "../../modules/database"
  project_name       = var.project_name
  private_subnet_ids = module.networking.private_subnets
  rds_sg_id          = module.security.rds_sg_id
  db_instance_class  = var.db_instance_class
}

module "compute" {
  source            = "../../modules/compute"
  project_name      = var.project_name
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnets
  ecs_sg_id         = module.security.ecs_sg_id
  alb_sg_id         = module.security.alb_sg_id
  db_endpoint       = module.database.db_endpoint
  db_name           = module.database.db_name
  db_username       = module.database.db_username
  db_secret_arn     = module.database.db_secret_arn
  sns_topic_arn     = module.billing.sns_topic_arn
  instance_type     = var.instance_type
}

module "grafana" {
  source                 = "../../modules/grafana"
  project_name           = var.project_name
  vpc_id                 = module.networking.vpc_id
  alb_sg_id              = module.security.alb_sg_id
  alb_https_listener_arn = module.dns_and_ssl.https_listener_arn
  ecs_cluster_id         = module.compute.ecs_cluster_id
  ecs_capacity_provider  = module.compute.ecs_capacity_provider
  aws_region             = var.aws_region
  domain_name            = "staging.mywebsitehosting.net"
}

module "monitoring" {
  source           = "../../modules/monitoring"
  project_name     = var.project_name
  vpc_id           = module.networking.vpc_id
  aws_account_id   = "156041402173"
  aws_region       = var.aws_region
  alb_arn          = module.compute.alb_arn
  ecs_cluster_name = "${var.project_name}-cluster"
  ecs_service_name = "${var.project_name}-service"
  db_identifier    = "${var.project_name}-db"
}

module "waf" {
  source       = "../../modules/waf"
  project_name = var.project_name
  alb_arn      = module.compute.alb_arn
}

module "waf_cloudfront" {
  source = "../../modules/waf-cloudfront"
  providers = {
    aws = aws.us_east_1
  }
  project_name = var.project_name
}

module "cloudfront" {
  source              = "../../modules/cloudfront"
  project_name        = var.project_name
  alb_dns_name        = module.compute.alb_dns_name
  domain_name         = "staging.mywebsitehosting.net"
  acm_certificate_arn = module.dns_and_ssl.certificate_arn
  web_acl_arn         = module.waf_cloudfront.web_acl_arn
}

module "dns_and_ssl" {
  source           = "../../modules/dns_and_ssl"
  project_name     = var.project_name
  domain_name      = "staging.mywebsitehosting.net"
  hosted_zone_id   = "Z1000332DD65SQUMW9GP"
  alb_dns_name     = module.compute.alb_dns_name
  alb_zone_id      = module.compute.alb_zone_id
  alb_arn          = module.compute.alb_arn
  target_group_arn = module.compute.alb_target_group_arn
  vpc_id           = module.networking.vpc_id
  providers = {
    aws = aws.us_east_1
  }
}
