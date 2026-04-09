terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "iam_github_oidc_provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"
  version = "~> 5.0"
}

data "aws_iam_policy_document" "github_actions" {
  statement {
    sid    = "S3StateAccess"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::wordpress-terraform-state-156041402173",
      "arn:aws:s3:::wordpress-terraform-state-156041402173/*"
    ]
  }

  statement {
    sid    = "DynamoDBLockAccess"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      "arn:aws:dynamodb:us-east-1:156041402173:table/wordpress-terraform-locks"
    ]
  }

  statement {
    sid    = "KMSAccess"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = [
      "arn:aws:kms:us-east-1:156041402173:key/70f62206-c0c0-49d2-8e96-80965542e33f"
    ]
  }

  statement {
    sid    = "S3DemoAccess"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::demo-infra-bucket-156041402173",
      "arn:aws:s3:::demo-infra-bucket-156041402173/*"
    ]
  }

  statement {
    sid    = "ECRAccess"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECRRepositoryAccess"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]
    resources = [
      "arn:aws:ecr:us-east-1:156041402173:repository/wordpress-php-fpm",
      "arn:aws:ecr:us-east-1:156041402173:repository/wordpress-nginx"
    ]
  }
}

resource "aws_iam_policy" "github_actions" {
  name        = "github-actions-terraform-policy"
  description = "Minimal permissions for GitHub Actions Terraform"
  policy      = data.aws_iam_policy_document.github_actions.json
}

module "iam_github_oidc_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "~> 5.0"

  name = "github-actions-oidc-role"

  subjects = [
    "repo:samiiraqi/wordpress-aws-terraform:*"
  ]

  policies = {
    GitHubActionsPolicy = aws_iam_policy.github_actions.arn
  }
}
