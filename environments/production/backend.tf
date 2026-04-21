terraform {
  required_version = ">= 1.0"
  backend "s3" {
    bucket         = "wordpress-terraform-state-156041402173"
    key            = "wordpress/production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "wordpress-terraform-lock"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-east-1:156041402173:key/70f62206-c0c0-49d2-8e96-80965542e33f"
  }
}
