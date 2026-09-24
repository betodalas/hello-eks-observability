# Rede: a ordem das listas corresponde às Availability Zones.
github_repo = "betodalas/hello-eks-observability"

availability_zones = ["us-east-1a", "us-east-1b"]
vpc_cidr           = "10.20.0.0/16"
private_subnets    = ["10.20.0.0/20", "10.20.16.0/20"]
public_subnets     = ["10.20.100.0/24", "10.20.101.0/24"]
