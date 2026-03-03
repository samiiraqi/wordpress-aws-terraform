# WordPress on AWS with Terraform

A production-ready WordPress deployment on AWS, built with Terraform.
This project was built for learning and practicing real-world cloud infrastructure.

## Architecture
```
Internet
    │
    ▼
[ALB - Application Load Balancer]  →  Public Subnets
    │
    ▼
[ECS EC2 - t2.micro]               →  Pseudo-Private Subnets
  ├── Container: nginx              →  Handles HTTP requests
  └── Container: php-fpm           →  Runs WordPress
    │
    ▼
[RDS MySQL 8.0]                    →  Private Subnets
```

## Infrastructure Components

- **VPC** - Isolated network with 3 subnet tiers across 2 Availability Zones
- **ALB** - Application Load Balancer for routing traffic
- **ECS** - EC2 launch type running nginx + php-fpm containers
- **EFS** - Shared file system between nginx and php-fpm containers
- **RDS** - MySQL 8.0 database in private subnets
- **Security Groups** - Strict traffic rules between each layer
- **CloudWatch** - Logging for all containers
- **SNS** - Billing alerts

## Key Design Decisions

**Pseudo-Private Subnets instead of NAT Gateway**
ECS instances have public IPs but are protected by Security Groups.
This avoids the ~$32/month cost of a NAT Gateway while maintaining security.

**nginx + php-fpm separation**
nginx handles static files and proxies PHP requests to php-fpm.
This is the industry standard for running WordPress in containers.

**EFS Shared Storage**
Both nginx and php-fpm need access to WordPress files.
EFS provides a shared filesystem that both containers can mount simultaneously.

## Project Structure
```
wordpress-infra/
├── main.tf
├── variables.tf
├── outputs.tf
└── modules/
    ├── billing/      # CloudWatch billing alarm + SNS
    ├── networking/   # VPC, subnets, route tables
    ├── security/     # Security groups
    ├── database/     # RDS MySQL
    └── compute/      # ECS, ALB, EFS
```

## What I Learned

- How to design multi-tier AWS network architecture
- How to write modular Terraform code
- How to run multi-container applications with ECS
- How to secure infrastructure using Security Groups
- How to share storage between containers using EFS
- How to connect ECS to RDS securely


## Production Improvements

This project was built for learning. In a real production environment I would improve:

- **Database password** - Store in AWS Secrets Manager instead of tfvars file
- **HTTPS** - Add SSL certificate with ACM and redirect HTTP to HTTPS
- **NAT Gateway** - Use real private subnets with NAT Gateway instead of pseudo-private
- **Multi-AZ RDS** - Enable Multi-AZ for high availability
- **Auto Scaling** - Scale ECS tasks based on traffic
- **Terraform State** - Store state in S3 with DynamoDB locking instead of local file


## Author

Sami Iraqi
