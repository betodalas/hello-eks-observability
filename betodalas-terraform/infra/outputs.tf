output "cluster_name" {
  value = module.eks.cluster_name
}

output "region" {
  value = var.region
}

output "configure_kubectl" {
  description = "Comando para configurar o kubectl"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "github_actions_role_arn" {
  description = "Cadastre como secret/variable AWS_ROLE_ARN no GitHub"
  value       = aws_iam_role.github_actions.arn
}

output "grafana_admin_user" {
  value = "admin"
}

output "grafana_admin_password" {
  description = "terraform output -raw grafana_admin_password"
  value       = random_password.grafana_admin.result
  sensitive   = true
}

output "get_public_url" {
  description = "Depois do apply, o endereço público (ALB) aparece aqui (leva 2-3 min):"
  value       = "kubectl get ingress -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}
