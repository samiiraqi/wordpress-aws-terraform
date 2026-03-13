
# ECR Repository for custom WordPress image
resource "aws_ecr_repository" "wordpress" {
  name                 = "${var.project_name}-php-fpm"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-php-fpm"
  }
}
# Build and push Docker image to ECR automatically
resource "null_resource" "docker_build_push" {
  triggers = {
    dockerfile = filemd5("${path.module}/../../docker/Dockerfile")
  }

  provisioner "local-exec" {
    command = <<-EOF
      aws ecr get-login-password --region us-east-1 | \
        docker login --username AWS --password-stdin \
        ${aws_ecr_repository.wordpress.repository_url}
      
      docker buildx build \
        --platform linux/amd64 \
        --push \
        -t ${aws_ecr_repository.wordpress.repository_url}:latest \
        ${path.module}/../../docker/
    EOF
  }

  depends_on = [aws_ecr_repository.wordpress]
}
# ECR Repository for custom nginx image
resource "aws_ecr_repository" "nginx" {
  name                 = "${var.project_name}-nginx"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Name = "${var.project_name}-nginx"
  }
}

# Build and push nginx Docker image to ECR
resource "null_resource" "docker_build_push_nginx" {
  triggers = {
    dockerfile = filemd5("${path.module}/../../docker/nginx/Dockerfile")
  }
  provisioner "local-exec" {
    command = <<-EOF
      aws ecr get-login-password --region us-east-1 | \
        docker login --username AWS --password-stdin \
        ${aws_ecr_repository.nginx.repository_url}
      
      docker buildx build \
        --platform linux/amd64 \
        --push \
        -t ${aws_ecr_repository.nginx.repository_url}:latest \
        ${path.module}/../../docker/nginx/
    EOF
  }
  depends_on = [aws_ecr_repository.nginx]
}

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.2.2"

  cluster_name = "${var.project_name}-cluster"

  cluster_settings = {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.project_name}-ecs-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_ecr" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.project_name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_ecr" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy" "ecs_secrets" {
  name = "${var.project_name}-ecs-secrets"
  role = aws_iam_role.ecs_task_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = [var.db_secret_arn]
    }]
  })
}


resource "aws_cloudwatch_log_group" "wordpress" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
  tags = { Name = "${var.project_name}-logs" }
}

resource "aws_ecs_task_definition" "wordpress" {
  family             = "${var.project_name}-task"
  network_mode       = "bridge"
  task_role_arn      = aws_iam_role.ecs_task_execution_role.arn
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

 volume {
  name = "wordpress-data"
}

  container_definitions = jsonencode([
    {
      name      = "php-fpm"
      image = "${aws_ecr_repository.wordpress.repository_url}:latest"
      
      essential = true
      memory    = 256

      environment = [
  { name = "WORDPRESS_DB_HOST", value = split(":", var.db_endpoint)[0] },
  { name = "WORDPRESS_DB_NAME", value = var.db_name },
  { name = "WORDPRESS_DB_USER", value = var.db_username }
]

secrets = [
  {
    name      = "WORDPRESS_DB_PASSWORD"
    valueFrom = "${var.db_secret_arn}:password::"
  }
]

      healthCheck = {
        command     = ["CMD-SHELL", "php-fpm -t || exit 1"]
        interval    = 10
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }

      mountPoints = [{ sourceVolume = "wordpress-data", containerPath = "/var/www/html", readOnly = false }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "php-fpm"
        }
      }
    },
    {
      name      = "nginx"
      image     = "${aws_ecr_repository.nginx.repository_url}:latest"
      essential = true
      memory    = 128
      links     = ["php-fpm"]



      
      portMappings = [{ containerPort = 80, hostPort = 80, protocol = "tcp" }]

      mountPoints = [{ sourceVolume = "wordpress-data", containerPath = "/var/www/html", readOnly = true }]

      dependsOn = [
        {
          containerName = "php-fpm"
          condition     = "HEALTHY"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "nginx"
        }
      }
    }
  ])
}


module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "8.7.0"

  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  vpc_id             = var.vpc_id
  subnets            = var.public_subnet_ids
  security_groups    = [var.alb_sg_id]

  target_groups = [
    {
      name             = "${var.project_name}-tg"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"

      health_check = {
        enabled             = true
        healthy_threshold   = 2
        unhealthy_threshold = 3
        timeout             = 5
        interval            = 30
        path                = "/"
        matcher             = "200,301,302"
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Name = "${var.project_name}-alb"
  }
}


data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.project_name}-ecs-"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = "t2.micro"

  iam_instance_profile { name = aws_iam_instance_profile.ecs_instance_profile.name }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.ecs_sg_id]
  }

  user_data = base64encode("#!/bin/bash\necho ECS_CLUSTER=${module.ecs_cluster.cluster_name} >> /etc/ecs/ecs.config\n")

  tag_specifications {
    resource_type = "instance"
    tags = { Name = "${var.project_name}-ecs-instance" }
  }
}

resource "aws_autoscaling_group" "ecs" {
  name                = "${var.project_name}-ecs-asg"
  desired_capacity    = 1
  min_size            = 1
  max_size            = 1
  vpc_zone_identifier = var.public_subnet_ids

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}



resource "aws_ecs_capacity_provider" "main" {
  name = "${var.project_name}-cp"
  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs.arn
    managed_scaling {
      status          = "ENABLED"
      target_capacity = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = module.ecs_cluster.cluster_name
  capacity_providers = [aws_ecs_capacity_provider.main.name]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 1
  }
}

resource "aws_ecs_service" "wordpress" {
  name                              = "${var.project_name}-service"
  cluster                           = module.ecs_cluster.cluster_id
  task_definition                   = aws_ecs_task_definition.wordpress.arn
  desired_count                     = 1
  enable_execute_command  = true
  health_check_grace_period_seconds = 120

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 1
  }

  load_balancer {
    target_group_arn = module.alb.target_group_arns[0]
    container_name   = "nginx"
    container_port   = 80
  }
depends_on = [
  module.alb,
  aws_iam_role_policy_attachment.ecs_task_execution_role,
  null_resource.docker_build_push,
  null_resource.docker_build_push_nginx
]
}





