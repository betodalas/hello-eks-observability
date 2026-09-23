# Cria APENAS o bucket S3 que guardará o state do Terraform da infra principal.
# Este módulo usa state local (é o "ovo e a galinha" do backend remoto).
terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "hello-observability"
}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "tfstate" {
  bucket = "${var.project}-tfstate"

  # Nunca destruir o state por acidente.
  lifecycle {
    prevent_destroy = true
  }
}

# Versionamento: permite recuperar um state anterior se algo der errado.
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "state_bucket" {
  value = aws_s3_bucket.tfstate.id
}
