# Cria as roles usadas pelo GitHub Actions para plan e apply.

variable "github_repo" {
  description = "Repositório GitHub no formato owner/repo"
  type        = string
}

variable "github_owner_id" {
  description = "ID numérico do owner no GitHub"
  type        = string
  default     = "1109865"
}

variable "github_repository_id" {
  description = "ID numérico do repositório no GitHub"
  type        = string
  default     = "1384209664"
}

variable "create_github_oidc_provider" {
  description = "Use false se a conta já tiver o OIDC provider do GitHub"
  type        = bool
  default     = true
}

data "aws_caller_identity" "ci" {}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

locals {
  github_oidc_provider_arn = var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : "arn:aws:iam::${data.aws_caller_identity.ci.account_id}:oidc-provider/token.actions.githubusercontent.com"
  state_bucket_arn         = aws_s3_bucket.tfstate.arn
  github_owner             = split("/", var.github_repo)[0]
  github_repository        = split("/", var.github_repo)[1]
  github_oidc_repo         = "repo:${local.github_owner}@${var.github_owner_id}/${local.github_repository}@${var.github_repository_id}"
}

data "aws_iam_policy_document" "terraform_plan_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "${local.github_oidc_repo}:pull_request",
        "repo:${var.github_repo}:pull_request",
      ]
    }
  }
}

data "aws_iam_policy_document" "terraform_apply_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "${local.github_oidc_repo}:environment:production",
        "repo:${var.github_repo}:environment:production",
      ]
    }
  }
}

resource "aws_iam_role" "terraform_plan" {
  name               = "${var.project}-terraform-plan"
  assume_role_policy = data.aws_iam_policy_document.terraform_plan_trust.json
}

resource "aws_iam_role_policy_attachment" "terraform_plan_read_only" {
  role       = aws_iam_role.terraform_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "terraform_plan_state" {
  statement {
    actions = ["s3:GetObject"]
    resources = [
      "${local.state_bucket_arn}/*",
    ]
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [local.state_bucket_arn]
  }

  statement {
    actions   = ["s3:GetBucketLocation", "sts:GetCallerIdentity"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "terraform_plan_state" {
  name   = "${var.project}-terraform-plan-state"
  role   = aws_iam_role.terraform_plan.id
  policy = data.aws_iam_policy_document.terraform_plan_state.json
}

resource "aws_iam_role" "terraform_apply" {
  name               = "${var.project}-terraform-apply"
  assume_role_policy = data.aws_iam_policy_document.terraform_apply_trust.json
}

resource "aws_iam_role_policy_attachment" "terraform_apply_admin" {
  role       = aws_iam_role.terraform_apply.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "terraform_plan_role_arn" {
  description = "Cadastre como AWS_TERRAFORM_PLAN_ROLE_ARN no GitHub"
  value       = aws_iam_role.terraform_plan.arn
}

output "terraform_apply_role_arn" {
  description = "Cadastre como AWS_TERRAFORM_APPLY_ROLE_ARN no GitHub"
  value       = aws_iam_role.terraform_apply.arn
}
