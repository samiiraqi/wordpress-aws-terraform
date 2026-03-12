# ALB Security Group
module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress_rules       = ["http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# ECS Security Group
module "ecs_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "${var.project_name}-ecs-sg"
  description = "Security group for ECS instances"
  vpc_id      = var.vpc_id

  ingress_with_source_security_group_id = [
    {
      description              = "HTTP from ALB only"
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      source_security_group_id = module.alb_sg.security_group_id
    }
  ]

  ingress_with_self = [
    {
      description = "NFS for EFS"
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
    }
  ]

  egress_rules = ["all-all"]

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}

# RDS Security Group
module "rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = var.vpc_id

  ingress_with_source_security_group_id = [
    {
      description              = "MySQL from ECS only"
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      source_security_group_id = module.ecs_sg.security_group_id
    }
  ]

  egress_rules = ["all-all"]

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}