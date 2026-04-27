# --- Security Group ---

resource "aws_security_group" "grafana" {
  name        = "${var.project_name}-grafana-sg"
  description = "Allow traffic from ALB to Grafana"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-grafana-sg"
  }
}

# --- IAM Role for Grafana task (CloudWatch read access) ---

resource "aws_iam_role" "grafana_task" {
  name = "${var.project_name}-grafana-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "grafana_cloudwatch" {
  name = "${var.project_name}-grafana-cloudwatch-policy"
  role = aws_iam_role.grafana_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "cloudwatch:DescribeAlarmsForMetric",
        "cloudwatch:DescribeAlarmHistory",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:ListMetrics",
        "cloudwatch:GetMetricData",
        "cloudwatch:GetInsightRuleReport",
        "logs:DescribeLogGroups",
        "logs:GetLogGroupFields",
        "logs:StartQuery",
        "logs:StopQuery",
        "logs:GetQueryResults",
        "logs:GetLogEvents",
        "ec2:DescribeTags",
        "ec2:DescribeInstances",
        "ec2:DescribeRegions",
        "tag:GetResources"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role" "grafana_execution" {
  name = "${var.project_name}-grafana-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "grafana_execution" {
  role       = aws_iam_role.grafana_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- CloudWatch Log Group ---

resource "aws_cloudwatch_log_group" "grafana" {
  name              = "/ecs/${var.project_name}-grafana"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-grafana-logs"
  }
}

# --- ECS Task Definition ---

resource "aws_ecs_task_definition" "grafana" {
  family             = "${var.project_name}-grafana"
  network_mode       = "bridge"
  task_role_arn      = aws_iam_role.grafana_task.arn
  execution_role_arn = aws_iam_role.grafana_execution.arn

  container_definitions = jsonencode([{
    name      = "grafana"
    image     = "grafana/grafana:latest"
    essential = true
    memory    = 512

    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
      protocol      = "tcp"
    }]

    environment = [
      { name = "GF_SERVER_ROOT_URL", value = "%(protocol)s://%(domain)s/grafana/" },
      { name = "GF_SERVER_SERVE_FROM_SUB_PATH", value = "true" },
      { name = "GF_AUTH_ANONYMOUS_ENABLED", value = "false" },
      { name = "GF_AWS_DEFAULT_REGION", value = var.aws_region },
      { name = "GF_DATASOURCES_DEFAULT_TYPE", value = "cloudwatch" },
      { name = "GF_DATASOURCES_DEFAULT_ACCESS", value = "proxy" },
      { name = "GF_DATASOURCES_DEFAULT_IS_DEFAULT", value = "true" }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.project_name}-grafana"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "grafana"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:3000/api/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 30
    }
  }])
}

# --- ALB Target Group ---

resource "aws_lb_target_group" "grafana" {
  name        = "${var.project_name}-grafana-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/grafana/api/health"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.project_name}-grafana-tg"
  }
}

# --- ALB Listener Rule ---

resource "aws_lb_listener_rule" "grafana" {
  listener_arn = var.alb_https_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }

  condition {
    path_pattern {
      values = ["/grafana", "/grafana/*"]
    }
  }
}

# --- ECS Service ---

resource "aws_ecs_service" "grafana" {
  name            = "${var.project_name}-grafana"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = var.ecs_capacity_provider
    weight            = 1
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana.arn
    container_name   = "grafana"
    container_port   = 3000
  }

  tags = {
    Name = "${var.project_name}-grafana"
  }
}
