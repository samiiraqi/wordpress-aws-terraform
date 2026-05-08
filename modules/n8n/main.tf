data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_security_group" "n8n" {
  name        = "${var.project_name}-n8n-sg"
  description = "n8n instance - webhook and UI on port 5678"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5678
    to_port     = 5678
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "n8n web UI and webhook"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-n8n-sg"
  }
}

resource "aws_iam_role" "n8n" {
  name = "${var.project_name}-n8n-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "n8n_ssm" {
  role       = aws_iam_role.n8n.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "n8n_readonly" {
  name = "${var.project_name}-n8n-readonly-policy"
  role = aws_iam_role.n8n.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecs:Describe*",
        "cloudwatch:Get*",
        "cloudwatch:List*",
        "cloudwatch:Describe*",
        "rds:Describe*",
        "elasticloadbalancing:Describe*",
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "n8n" {
  name = "${var.project_name}-n8n-profile"
  role = aws_iam_role.n8n.name
}

resource "aws_instance" "n8n" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.n8n.id]
  iam_instance_profile        = aws_iam_instance_profile.n8n.name
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install docker -y
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ec2-user

    mkdir -p /opt/n8n/data

    echo '${base64encode(file("${path.module}/workflow.json"))}' | base64 -d > /opt/n8n/workflow.json

    docker run -d \
      --name n8n \
      --restart unless-stopped \
      --user root \
      -p 5678:5678 \
      -e N8N_HOST=0.0.0.0 \
      -e N8N_PORT=5678 \
      -e N8N_PROTOCOL=http \
      -e N8N_SECURE_COOKIE=false \
      -v /opt/n8n/data:/home/node/.n8n \
      n8nio/n8n

    for i in $(seq 1 30); do
      if curl -sf http://localhost:5678/healthz >/dev/null 2>&1; then
        echo "n8n is healthy"
        break
      fi
      echo "Waiting for n8n ($i/30)..."
      sleep 10
    done

    docker cp /opt/n8n/workflow.json n8n:/tmp/workflow.json
    docker exec n8n n8n import:workflow --input=/tmp/workflow.json
  EOF

  tags = {
    Name = "${var.project_name}-n8n"
  }
}

resource "aws_eip" "n8n" {
  instance = aws_instance.n8n.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-n8n-eip"
  }
}
