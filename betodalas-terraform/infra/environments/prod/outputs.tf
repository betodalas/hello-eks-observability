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

output "load_balancer_controller_role_arn" {
  description = "Role IAM usada pelo AWS Load Balancer Controller via IRSA."
  value       = module.lb_controller_irsa.iam_role_arn
}

output "karpenter_controller_role_arn" {
  description = "Role IAM usada pelo Karpenter via IRSA."
  value       = aws_iam_role.karpenter_controller.arn
}

output "karpenter_instance_profile_name" {
  description = "Instance profile usado pelo Karpenter para os nós provisionados."
  value       = aws_iam_instance_profile.karpenter.name
}
