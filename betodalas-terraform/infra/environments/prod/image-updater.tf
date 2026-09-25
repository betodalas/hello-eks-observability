# Permissões AWS para o ArgoCD Image Updater ler tags/imagens do ECR.
#
# O chart e o ServiceAccount são instalados pelo Argo CD. O Terraform cria
# somente a role IAM que o updater usará via IRSA para autenticar no ECR.

module "image_updater_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.52"

  role_name = "${local.name}-image-updater"

  role_policy_arns = {
    ecr_read_only = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["argocd:argocd-image-updater"]
    }
  }
}
