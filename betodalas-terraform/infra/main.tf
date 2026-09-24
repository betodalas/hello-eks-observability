data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  name = var.project
  azs  = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Roles criadas no bootstrap para plan e apply do GitHub Actions.
  terraform_plan_role_arn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-terraform-plan"
  terraform_apply_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-terraform-apply"

  tags = {
    Project   = var.project
    ManagedBy = "terraform"
  }
}
