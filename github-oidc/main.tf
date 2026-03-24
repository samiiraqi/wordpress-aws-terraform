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
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
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
    sid    = "S3BucketManagement"
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:PutBucketVersioning",
      "s3:PutBucketTagging",
      "s3:GetBucketVersioning",
      "s3:GetBucketTagging",
      "s3:GetBucketLocation",
      "s3:PutBucketPublicAccessBlock",
      "s3:GetBucketPublicAccessBlock"
    ]
    resources = [
      "arn:aws:s3:::demo-infra-bucket-156041402173"
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
