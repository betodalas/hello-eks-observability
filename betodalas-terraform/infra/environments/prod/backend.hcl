# Copie para backend.hcl e ajuste o nome do bucket (saída do módulo bootstrap).
bucket       = "hello-observability-tfstate"
key          = "eks/prod/terraform.tfstate"
region       = "us-east-1"
encrypt      = true
use_lockfile = true # lock nativo do S3 (Terraform >= 1.10), sem DynamoDB
