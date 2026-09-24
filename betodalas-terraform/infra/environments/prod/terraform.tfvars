# Production environment. Restrict the public EKS endpoint to the known office/home IP,
# while keeping the application publicly reachable through the ALB/Ingress.
project     = "hello-observability-prod"
github_repo = "betodalas/hello-eks-observability"

admin_principal_arns = [
  "arn:aws:iam::207131866724:user/terraform",
]

availability_zones = ["us-east-1a", "us-east-1b"]
vpc_cidr           = "10.30.0.0/16"
private_subnets    = ["10.30.0.0/20", "10.30.16.0/20"]
public_subnets     = ["10.30.100.0/24", "10.30.101.0/24"]

cluster_endpoint_public_access       = true
cluster_endpoint_private_access      = true
cluster_endpoint_public_access_cidrs = ["179.159.253.66/32"]

node_groups = {
  default = {
    instance_types = ["t3.micro"]
    min_size       = 6
    desired_size   = 6
    max_size       = 6
  }
}
