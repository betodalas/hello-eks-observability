terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }
  }

  # Configuração parcial: os valores vêm de -backend-config
  # (localmente: backend.hcl; no GitHub Actions: variables do repositório)
  backend "s3" {}
}
