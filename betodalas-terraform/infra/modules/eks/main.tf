locals {
  cluster_admin_policy = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  admin_access = {
    for key, arn in merge(
      { for i, value in var.admin_principal_arns : "admin-${i}" => value },
      var.user_principal_arns
      ) : key => {
      principal_arn = arn
      policy_associations = {
        admin = {
          policy_arn   = local.cluster_admin_policy
          access_scope = { type = "cluster" }
        }
      }
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.37"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access           = var.cluster_endpoint_public_access
  cluster_endpoint_private_access          = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  enable_cluster_creator_admin_permissions = false

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  eks_managed_node_groups = var.node_groups

  access_entries = merge(
    {
      terraform_plan = {
        principal_arn = var.terraform_plan_role_arn
        policy_associations = {
          admin = {
            policy_arn   = local.cluster_admin_policy
            access_scope = { type = "cluster" }
          }
        }
      }
      terraform_apply = {
        principal_arn = var.terraform_apply_role_arn
        policy_associations = {
          admin = {
            policy_arn   = local.cluster_admin_policy
            access_scope = { type = "cluster" }
          }
        }
      }
    },
    local.admin_access
  )
}
