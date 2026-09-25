variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "terraform_plan_role_arn" {
  type = string
}

variable "terraform_apply_role_arn" {
  type = string
}

variable "admin_principal_arns" {
  type    = list(string)
  default = []
}

variable "user_principal_arns" {
  type    = map(string)
  default = {}
}

variable "node_groups" {
  type = map(object({
    ami_type       = optional(string, "AL2023_x86_64_STANDARD")
    instance_types = list(string)
    capacity_type  = optional(string, "ON_DEMAND")
    min_size       = number
    desired_size   = number
    max_size       = number
  }))
}

variable "cluster_endpoint_public_access" {
  type = bool
}

variable "cluster_endpoint_private_access" {
  type = bool
}

variable "cluster_endpoint_public_access_cidrs" {
  type = list(string)
}

variable "karpenter_node_role_arn" {
  type    = string
  default = null
}
