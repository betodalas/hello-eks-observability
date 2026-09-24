# Development environment. Keep these values compatible with the original infra state.
project     = "hello-observability"
github_repo = "betodalas/hello-eks-observability"

availability_zones = ["us-east-1a", "us-east-1b"]
vpc_cidr           = "10.20.0.0/16"
private_subnets    = ["10.20.0.0/20", "10.20.16.0/20"]
public_subnets     = ["10.20.100.0/24", "10.20.101.0/24"]

cluster_endpoint_public_access       = true
cluster_endpoint_private_access      = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

admin_principal_arns = [
  "arn:aws:iam::207131866724:user/terraform"
]

node_groups = {
  default = {
    instance_types = ["t3.micro"]
    min_size       = 4
    desired_size   = 4
    max_size       = 4
  }
}
