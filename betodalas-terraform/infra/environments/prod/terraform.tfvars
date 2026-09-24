# Production environment. Restrict the public endpoint and use dedicated names/state.
project     = "hello-observability-prod"
github_repo = "betodalas/hello-eks-observability"

availability_zones = ["us-east-1a", "us-east-1b"]
vpc_cidr           = "10.30.0.0/16"
private_subnets    = ["10.30.0.0/20", "10.30.16.0/20"]
public_subnets     = ["10.30.100.0/24", "10.30.101.0/24"]

cluster_endpoint_public_access       = false
cluster_endpoint_private_access      = true
cluster_endpoint_public_access_cidrs = []

node_groups = {
  default = {
    instance_types = ["t3.large"]
    min_size       = 2
    desired_size   = 2
    max_size       = 4
  }
}
