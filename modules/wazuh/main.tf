data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# --- Security Group ---

resource "aws_security_group" "wazuh" {
  name        = "${var.project_name}-wazuh-sg"
  description = "Wazuh SIEM security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS dashboard"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description = "Agent communication"
    from_port   = 1514
    to_port     = 1514
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    description = "Agent enrollment"
    from_port   = 1515
    to_port     = 1515
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    description = "Wazuh API"
    from_port   = 55000
    to_port     = 55000
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-wazuh-sg"
  }
}

# --- IAM Role ---

resource "aws_iam_role" "wazuh" {
  name = "${var.project_name}-wazuh-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project_name}-wazuh-role"
  }
}

resource "aws_iam_role_policy" "wazuh" {
  name = "${var.project_name}-wazuh-policy"
  role = aws_iam_role.wazuh.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3LogsRead"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Resource = [
          "arn:aws:s3:::${var.cloudtrail_bucket}",
          "arn:aws:s3:::${var.cloudtrail_bucket}/*",
          "arn:aws:s3:::${var.waf_logs_bucket}",
          "arn:aws:s3:::${var.waf_logs_bucket}/*",
          "arn:aws:s3:::${var.alb_logs_bucket}",
          "arn:aws:s3:::${var.alb_logs_bucket}/*",
        ]
      },
      {
        Sid    = "CloudWatchLogsRead"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
        ]
        Resource = ["arn:aws:logs:*:*:log-group:*"]
      },
      {
        Sid    = "GuardDutyRead"
        Effect = "Allow"
        Action = [
          "guardduty:GetDetector",
          "guardduty:GetFindings",
          "guardduty:ListDetectors",
          "guardduty:ListFindings",
        ]
        Resource = ["*"]
      },
      {
        Sid    = "SecurityHubRead"
        Effect = "Allow"
        Action = [
          "securityhub:GetFindings",
          "securityhub:ListFindingAggregators",
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "wazuh" {
  name = "${var.project_name}-wazuh-profile"
  role = aws_iam_role.wazuh.name
}

# --- EC2 Instance ---

resource "aws_instance" "wazuh" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.medium"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.wazuh.id]
  iam_instance_profile   = aws_iam_instance_profile.wazuh.name
  key_name               = "my keypair"

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-EOF
    #!/bin/bash
    set -x
    exec > /var/log/wazuh-install.log 2>&1

    sleep 30

    # Install Wazuh Manager
    rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH || true

    cat > /etc/yum.repos.d/wazuh.repo << 'REPO'
    [wazuh]
    gpgcheck=1
    gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
    enabled=1
    name=EL-$releasever - Wazuh
    baseurl=https://packages.wazuh.com/4.x/yum/
    protect=1
    REPO

    yum install -y wazuh-manager || true

    systemctl daemon-reload || true
    systemctl enable wazuh-manager || true
    systemctl start wazuh-manager || true
  EOF

  tags = {
    Name = "${var.project_name}-wazuh"
  }
}

# --- Elastic IP ---

resource "aws_eip" "wazuh" {
  instance = aws_instance.wazuh.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-wazuh-eip"
  }
}
