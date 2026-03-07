
# ECR Repository for custom WordPress image
resource "aws_ecr_repository" "wordpress" {
  name                 = "${var.project_name}-php-fpm"
  image_tag_mutability = "MUTABLE"

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

# EFS - Shared storage between nginx and php-fpm
resource "aws_efs_file_system" "wordpress" {
  creation_token = "${var.project_name}-efs"
  encrypted      = true

  tags = {
    Name = "${var.project_name}-efs"
  }
}

resource "aws_efs_mount_target" "wordpress" {
  count           = length(var.pseudo_private_subnet_ids)
  file_system_id  = aws_efs_file_system.wordpress.id
  subnet_id       = var.pseudo_private_subnet_ids[count.index]
  security_groups = [var.ecs_sg_id]
}

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
  tags = { Name = "${var.project_name}-cluster" }
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
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.wordpress.id
      root_directory = "/"
    }
  }

  container_definitions = jsonencode([
    {
      name      = "php-fpm"
      image = "${aws_ecr_repository.wordpress.repository_url}:latest"
      
      essential = true
      memory    = 256

      environment = [
        { name = "WORDPRESS_DB_HOST",     value = var.db_endpoint },
        { name = "WORDPRESS_DB_NAME",     value = var.db_name },
        { name = "WORDPRESS_DB_USER",     value = var.db_username },
        { name = "WORDPRESS_DB_PASSWORD", value = var.db_password }
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
      image     = "nginx:alpine"
      essential = true
      memory    = 128
      links     = ["php-fpm"]

      entryPoint = ["/bin/sh", "-c"]
      command    = ["printf 'server {\\n  listen 80;\\n  root /var/www/html;\\n  index index.php;\\n  location / { try_files $uri $uri/ /index.php?$args; }\\n  location ~ \\.php$ { fastcgi_pass php-fpm:9000; fastcgi_index index.php; include fastcgi_params; fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; }\\n}\\n' > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]

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

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids
  tags = { Name = "${var.project_name}-alb" }
}

resource "aws_lb_target_group" "wordpress" {
  name        = "${var.project_name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200,301,302"
  }
  tags = { Name = "${var.project_name}-tg" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress.arn
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

  user_data = base64encode("#!/bin/bash\necho ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config\n")

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
  vpc_zone_identifier = var.pseudo_private_subnet_ids

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
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.main.name]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 1
  }
}

resource "aws_ecs_service" "wordpress" {
  name                              = "${var.project_name}-service"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.wordpress.arn
  desired_count                     = 1
  health_check_grace_period_seconds = 120

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 1
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.wordpress.arn
    container_name   = "nginx"
    container_port   = 80
  }
depends_on = [
  aws_lb_listener.http,
  aws_iam_role_policy_attachment.ecs_task_execution_role,
  null_resource.docker_build_push
]
}
