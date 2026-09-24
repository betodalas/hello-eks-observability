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
    condition     = length(var.private_subnets) == length(var.availability_zones)
    error_message = "private_subnets deve ter a mesma quantidade de itens que availability_zones."
  }
}

variable "public_subnets" {
  description = "Uma subnet pública por Availability Zone, na mesma ordem de availability_zones."
  type        = list(string)
  default     = ["10.20.100.0/24", "10.20.101.0/24"]

  validation {
    condition     = length(var.public_subnets) == length(var.availability_zones)
    error_message = "public_subnets deve ter a mesma quantidade de itens que availability_zones."
  }
}

variable "node_instance_types" {
  description = "Tipo de instância dos nós. t3.micro é o perfil de bootstrap para contas Free Tier; use instâncias maiores em produção."
  type        = list(string)
  default     = ["t3.micro"]
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_desired_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 1
}

variable "lb_controller_chart_version" {
  description = "Versão do chart aws-load-balancer-controller"
  type        = string
  default     = "1.13.0"
}

variable "prometheus_stack_chart_version" {
  description = "Versão do chart kube-prometheus-stack (confira a mais recente com: helm search repo prometheus-community/kube-prometheus-stack)"
  type        = string
  default     = "75.15.1"
}
