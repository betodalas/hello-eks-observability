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
  type    = string
  default = "10.0.0.0/16"
}

variable "az_count" {
  description = "Quantidade de AZs (mínimo 2 exigido pelo EKS e pelo ALB)"
  type        = number
  default     = 2
}

variable "node_instance_types" {
  description = "t3.large comporta o kube-prometheus-stack + app com folga (limite de ~35 pods/nó)"
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 4
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
