variable "users" {
  description = "Usuários IAM a criar. Chaves de acesso não são criadas por este módulo."
  type = map(object({
    path = optional(string, "/")
    tags = optional(map(string), {})
  }))
  default = {}
}
