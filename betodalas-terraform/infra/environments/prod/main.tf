data "aws_caller_identity" "current" {}

locals {
  name = var.project

  # Roles criadas no bootstrap para plan e apply do GitHub Actions.
  terraform_plan_role_arn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.terraform_role_project}-terraform-plan"
  terraform_apply_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.terraform_role_project}-terraform-apply"

  tags = {
    Project   = var.project
    ManagedBy = "terraforme"
  }
}
