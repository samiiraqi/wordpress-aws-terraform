terraform {
  backend "s3" {
    bucket         = "wordpress-terraform-state-156041402173"
    key            = "demo-infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "wordpress-terraform-locks"
    encrypt        = true
  }
}
