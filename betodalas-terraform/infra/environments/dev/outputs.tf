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

output "waf_web_acl_arn" {
  description = "ARN da Web ACL do WAFv2 a ser referenciada na annotation alb.ingress.kubernetes.io/wafv2-acl-arn dos Ingress."
  value       = aws_wafv2_web_acl.alb.arn
}
