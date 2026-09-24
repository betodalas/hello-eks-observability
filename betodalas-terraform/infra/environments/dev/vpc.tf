module "vpc" {
  source = "../../modules/vpc"

  name            = "${local.name}-vpc"
  cidr            = var.vpc_cidr
  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  cluster_name    = local.name
}
