# WordPress on AWS — Terraform

WordPress deployment on AWS using Terraform.

## Architecture

```
Internet → ALB → ECS (nginx + php-fpm) → RDS MySQL
```

- **VPC** — 3-tier subnets: public (ALB), intra (ECS), private (RDS)
- **ECS EC2** — t2.micro, two containers sharing a Docker volume
- **RDS MySQL 8.0** — db.t3.micro in private subnets
- **Secrets Manager** — auto-generated DB password
- **VPC Endpoints** — private communication with AWS services (no NAT Gateway)
- **Billing alerts** — SNS email notification on charges

## Usage

### 1. Bootstrap (one-time)
```bash
cd bootstrap
terraform init && terraform apply
```

### 2. Deploy
```bash
cd ..
terraform init && terraform apply# WordPress on AWS — Terraform

WordPress deployment on AWS using Terraform.

## Architecture

```
Internet → ALB → ECS (nginx + php-fpm) → RDS MySQL
```

- **VPC** — 3-tier subnets: public (ALB), intra (ECS), private (RDS)
- **ECS EC2** — t2.micro, two containers sharing a Docker volume
- **RDS MySQL 8.0** — db.t3.micro in private subnets
- **Secrets Manager** — auto-generated DB password
- **VPC Endpoints** — private communication with AWS services (no NAT Gateway)
- **Billing alerts** — SNS email notification on charges

## Usage

### 1. Bootstrap (one-time)
```bash
cd bootstrap
terraform init && terraform apply
```

### 2. Deploy
```bash
cd ..
terraform init && terraform apply
```

### 3. Open WordPress
```
http://<alb_dns_name>
```

### 4. Destroy when done
```bash
terraform destroy
```

## Notes

- Docker images are built and pushed to ECR automatically during `terraform apply`
- Destroy resources after testing to avoid charges (ALB ~$16/month, VPC Endpoints ~$7/each)
```

### 3. Open WordPress
```
http://<alb_dns_name>
```

### 4. Destroy when done
```bash
terraform destroy
```

## Notes

- Docker images are built and pushed to ECR automatically during `terraform apply`
- Destroy resources after testing to avoid charges (ALB ~$16/month, VPC Endpoints ~$7/each)