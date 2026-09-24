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

variable "node_instance_types" {
  type = list(string)
}

variable "node_min_size" {
  type = number
}

variable "node_desired_size" {
  type = number
}

variable "node_max_size" {
  type = number
}
