module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.21"

  name = "${local.name}-vpc"
  cidr = var.vpc_cidr
  azs  = local.azs

  # Privadas /20 (nós e pods) e públicas /24 (ALB e NAT)
  private_subnets = [for i, _ in local.azs : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnets  = [for i, _ in local.azs : cidrsubnet(var.vpc_cidr, 8, i + 48)]

  enable_nat_gateway   = true
  single_nat_gateway   = true # 1 NAT só = mais barato (em produção: 1 por AZ)
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags que o AWS Load Balancer Controller usa para descobrir as subnets
  public_subnet_tags = {
    "kubernetes.io/role/elb"              = 1
    "kubernetes.io/cluster/${local.name}" = "shared"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"     = 1
    "kubernetes.io/cluster/${local.name}" = "shared"
  }
}
