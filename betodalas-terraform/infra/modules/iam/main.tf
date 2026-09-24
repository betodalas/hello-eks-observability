variable "users" {
  description = "Usuários IAM a criar. Chaves de acesso não são criadas por este módulo."
  type = map(object({
    path = optional(string, "/")
    tags = optional(map(string), {})
  }))
  default = {}
}

resource "aws_iam_user" "this" {
  for_each = var.users

  name = each.key
  path = each.value.path
  tags = each.value.tags
}

output "user_principal_arns" {
  description = "ARNs dos usuários para uso nas EKS Access Entries."
  value       = { for name, user in aws_iam_user.this : name => user.arn }
}
