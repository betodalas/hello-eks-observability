module "eks" {
  source = "./modules/eks"

  cluster_name             = local.name
  cluster_version          = var.kubernetes_version
  vpc_id                   = module.vpc.vpc_id
  private_subnet_ids       = module.vpc.private_subnets
  terraform_plan_role_arn  = local.terraform_plan_role_arn
  terraform_apply_role_arn = local.terraform_apply_role_arn
  admin_principal_arns     = var.admin_principal_arns
  user_principal_arns      = module.iam.user_principal_arns
  node_instance_types      = var.node_instance_types
  node_min_size            = var.node_min_size
  node_desired_size        = var.node_desired_size
  node_max_size            = var.node_max_size
}
