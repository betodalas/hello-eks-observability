module "eks" {
  source = "../../modules/eks"

  cluster_name                         = local.name
  cluster_version                      = var.kubernetes_version
  vpc_id                               = module.vpc.vpc_id
  private_subnet_ids                   = module.vpc.private_subnets
  terraform_plan_role_arn              = local.terraform_plan_role_arn
  terraform_apply_role_arn             = local.terraform_apply_role_arn
  admin_principal_arns                 = var.admin_principal_arns
  user_principal_arns                  = module.iam.user_principal_arns
  node_groups                          = var.node_groups
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  karpenter_node_role_arn              = aws_iam_role.karpenter_node.arn
}
