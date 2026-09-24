output "user_principal_arns" {
  description = "ARNs dos usuários para uso nas EKS Access Entries."
  value       = { for name, user in aws_iam_user.this : name => user.arn }
}
