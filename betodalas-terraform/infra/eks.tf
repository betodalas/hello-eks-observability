locals {
  cluster_admin_policy = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.37"

  cluster_name    = local.name
  cluster_version = var.kubernetes_version

  # Endpoint público para o Terraform/kubectl/CI conseguirem falar com o cluster.
  # (Em produção: restringir por CIDR ou usar apenas endpoint privado + VPN/bastion.)
  cluster_endpoint_public_access = true

  # DESLIGADO de propósito: o "criador" mudaria conforme quem roda o terraform
  # (CI ou sua máquina). Os acessos são declarados explicitamente abaixo.
  enable_cluster_creator_admin_permissions = false

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets # nós SEMPRE em subnets privadas

  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    eks-pod-identity-agent = {}
    vpc-cni = {
      before_compute = true
    }
  }

  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"

      min_size     = var.node_min_size
      desired_size = var.node_desired_size
      max_size     = var.node_max_size
    }
  }

  # EKS Access Entries (substitui o ConfigMap aws-auth)
  access_entries = merge(
    {
      # Role do Terraform no GitHub Actions: precisa para os providers helm/kubernetes
      terraform_ci = {
        principal_arn = local.terraform_ci_role_arn
        policy_associations = {
          admin = {
            policy_arn   = local.cluster_admin_policy
            access_scope = { type = "cluster" }
          }
        }
      }

      # Role de deploy da aplicação (helm upgrade no pipeline da app)
      # Admin por simplicidade; em produção restrinja ao namespace da app.
      github_deploy = {
        principal_arn = aws_iam_role.github_actions.arn
        policy_associations = {
          admin = {
            policy_arn   = local.cluster_admin_policy
            access_scope = { type = "cluster" }
          }
        }
      }
    },
    # Você (e quem mais estiver na lista) para usar o kubectl
    {
      for i, arn in var.admin_principal_arns : "admin-${i}" => {
        principal_arn = arn
        policy_associations = {
          admin = {
            policy_arn   = local.cluster_admin_policy
            access_scope = { type = "cluster" }
          }
        }
      }
    }
  )
}
