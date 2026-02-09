terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ecommerce-platform"
      ManagedBy   = "terraform"
      Environment = "shared"
      Owner       = "Rares"
    }
  }
}

variable "aws_region" {
  description = "AWS region for state resources"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "ecommerce"
}

# ---- S3 bucket for TF state ----
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "${var.project_name}-tfstate-${data.aws_caller_identity.current.account_id}"
  force_destroy = false
  tags = {
    Purpose = "Terraform remote state storage"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---- DynamoDB table for state locking ----

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.project_name}-tfstate-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Purpose = "Terraform state locking"
  }
}

# ---- Data sources ----
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ---- Outputs ----
output "state_bucket_name" {
  description = "S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of state bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "aws_region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}