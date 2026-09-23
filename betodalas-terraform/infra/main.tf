data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  name = var.project
  azs  = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Role criada no bootstrap; é ela que roda o terraform no GitHub Actions.
  terraform_ci_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-terraform-ci"

  tags = {
    Project   = var.project
    ManagedBy = "terraform"
  }
}
