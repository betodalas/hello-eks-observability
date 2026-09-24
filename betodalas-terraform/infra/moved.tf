# Preserve resources created before the local wrapper modules were introduced.
# Terraform moves the complete child module state without recreating AWS resources.
moved {
  from = module.vpc
  to   = module.vpc.module.vpc
}

moved {
  from = module.eks
  to   = module.eks.module.eks
}
