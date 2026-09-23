# Criado UMA vez, manualmente. Independente do main.tf.
# O nome da role precisa bater com infra/main.tf (${var.project}-terraform-ci, default hello-observability).

variable "github_repo" {
  description = "Repositório GitHub no formato owner/repo (respeite maiúsculas/minúsculas)"
  type        = string
}

variable "create_github_oidc_provider" {
  description = "Use false se a conta já tem o OIDC provider do GitHub (só pode existir um por conta)"
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
}

data "aws_iam_policy_document" "terraform_ci_trust" {
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
        "repo:${var.github_repo}:pull_request",
        "repo:${var.github_repo}:environment:production",
      ]
    }
  }
}

resource "aws_iam_role" "terraform_ci" {
  name               = "hello-observability-terraform-ci"
  assume_role_policy = data.aws_iam_policy_document.terraform_ci_trust.json
}

resource "aws_iam_role_policy_attachment" "terraform_ci_admin" {
  role       = aws_iam_role.terraform_ci.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "terraform_ci_role_arn" {
  description = "Cadastre como variable AWS_TERRAFORM_ROLE_ARN no GitHub"
  value       = aws_iam_role.terraform_ci.arn
}
