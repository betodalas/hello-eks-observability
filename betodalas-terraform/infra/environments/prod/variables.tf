variable "region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Prefixo usado no nome dos recursos"
  type        = string
  default     = "hello-observability"
}

variable "terraform_role_project" {
  description = "Prefixo do projeto usado nos nomes das roles OIDC criadas pelo bootstrap."
  type        = string
  default     = "hello-observability"
}

variable "github_repo" {
  description = "Repositório GitHub no formato owner/repo (confiança OIDC da role de deploy da app)"
  type        = string
}

variable "admin_principal_arns" {
  description = <<-EOT
    ARNs opcionais de usuários/roles IAM que terão acesso admin ao cluster
    (kubectl), além das roles do pipeline.
    Ex.: ["arn:aws:iam::123456789012:user/roberto"]
    (SSO: use o ARN da role AWSReservedSSO_*, sem o /aws-reserved/... e sem o nome da sessão)
  EOT
  type        = list(string)
  default     = []
}

variable "iam_users" {
  description = "Usuários IAM a criar e autorizar como administradores do cluster. Não cria chaves de acesso."
  type = map(object({
    path = optional(string, "/")
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "kubernetes_version" {
  description = "Versão do Kubernetes no EKS (confira as que estão em suporte padrão)"
  type        = string
  default     = "1.35"
}

variable "vpc_cidr" {
  description = "Bloco CIDR geral da VPC."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr deve ser um bloco CIDR IPv4 válido."
  }
}

variable "availability_zones" {
  description = "AZs usadas pela VPC. A ordem define a correspondência com as subnets."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "Informe pelo menos duas Availability Zones."
  }
}

variable "private_subnets" {
  description = "Uma subnet privada por Availability Zone, na mesma ordem de availability_zones."
  type        = list(string)
  default     = ["10.20.0.0/20", "10.20.16.0/20"]

  validation {
    condition = length(var.private_subnets) == length(var.availability_zones) && alltrue([
      for cidr in var.private_subnets : can(cidrhost(cidr, 0))
    ])
    error_message = "private_subnets deve ter um CIDR IPv4 válido por Availability Zone."
  }
}

variable "public_subnets" {
  description = "Uma subnet pública por Availability Zone, na mesma ordem de availability_zones."
  type        = list(string)
  default     = ["10.20.100.0/24", "10.20.101.0/24"]

  validation {
    condition = length(var.public_subnets) == length(var.availability_zones) && alltrue([
      for cidr in var.public_subnets : can(cidrhost(cidr, 0))
    ])
    error_message = "public_subnets deve ter um CIDR IPv4 válido por Availability Zone."
  }
}

variable "node_groups" {
  description = "Managed node groups do EKS. A configuração default é econômica para contas Free Tier."
  type = map(object({
    ami_type       = optional(string, "AL2023_x86_64_STANDARD")
    instance_types = list(string)
    capacity_type  = optional(string, "ON_DEMAND")
    min_size       = number
    desired_size   = number
    max_size       = number
  }))
  default = {
    default = {
      instance_types = ["t3.micro"]
      min_size       = 1
      desired_size   = 1
      max_size       = 1
    }
  }

  validation {
    condition = alltrue([
      for group in values(var.node_groups) :
      length(group.instance_types) > 0 &&
      group.min_size >= 0 &&
      group.min_size <= group.desired_size &&
      group.desired_size <= group.max_size
    ])
    error_message = "Cada node group precisa de instance_types e tamanhos min <= desired <= max."
  }
}

variable "cluster_endpoint_public_access" {
  description = "Habilita acesso público ao endpoint do Kubernetes."
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Habilita acesso privado ao endpoint do Kubernetes dentro da VPC."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs autorizados a acessar publicamente o endpoint do EKS."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for cidr in var.cluster_endpoint_public_access_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Todos os CIDRs do endpoint público devem ser válidos."
  }
}
