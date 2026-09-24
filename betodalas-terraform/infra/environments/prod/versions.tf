terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37"
    }
  }

  # Configuração parcial: os valores vêm de -backend-config
  # (localmente: backend.hcl; no GitHub Actions: variables do repositório)
  backend "s3" {}
}
