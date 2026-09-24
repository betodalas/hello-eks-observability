module "vpc" {
  source = "./modules/vpc"

  name         = "${local.name}-vpc"
  cidr         = var.vpc_cidr
  azs          = local.azs
  cluster_name = local.name
}
