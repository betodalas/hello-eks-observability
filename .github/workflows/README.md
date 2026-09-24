# Deploy do Terraform

O workflow `terraform.yml` usa OIDC para autenticar o GitHub Actions na AWS,
sem armazenar access keys no GitHub.

## Preparação única

1. Execute o Terraform em `betodalas-terraform/bootstrap/` localmente, com credenciais AWS
   administrativas. Esse passo cria o bucket S3 do state e a role
   `hello-observability-terraform-plan` e
   `hello-observability-terraform-apply`.
   Para o OIDC deste repositório, informe também os IDs numéricos:

   ```bash
   terraform -chdir=betodalas-terraform/bootstrap apply \
     -var='github_repo=betodalas/hello-eks-observability' \
     -var='github_owner_id=1109865' \
     -var='github_repository_id=1384209664'
   ```
2. No GitHub, crie o Environment `production` e, de preferência, habilite
   aprovação obrigatória para o job de `apply`.
3. Em **Repository variables** (não dentro do Environment), cadastre:

   - `AWS_TERRAFORM_PLAN_ROLE_ARN`: ARN emitido por
     `terraform -chdir=betodalas-terraform/bootstrap output -raw terraform_plan_role_arn`
   - `TF_STATE_BUCKET`: nome do bucket criado pelo bootstrap
   - `TF_STATE_KEY`: `eks/terraform.tfstate`

   O job de `plan` precisa dessas variables em um Pull Request. Ele não usa
   o Environment `production`, pois sua role OIDC aceita somente o subject
   `pull_request`.
4. Em **Environment variables** do Environment `production`, cadastre:

   - `AWS_TERRAFORM_APPLY_ROLE_ARN`: ARN emitido por
     `terraform -chdir=betodalas-terraform/bootstrap output -raw terraform_apply_role_arn`

O repositório usado no bootstrap deve ser exatamente o repositório que contém
este workflow. O valor é validado pela trust policy do OIDC.

## Fluxo

- Pull requests executam `fmt`, `validate` e `plan` em `betodalas-terraform/infra`;
  o resultado é publicado
  em um comentário atualizável no próprio PR.
- Pushes em `main` executam `plan` e depois aguardam a aprovação manual do
  Environment `production` antes de executar `apply`.
- O `apply` só pode assumir a role através do Environment `production`; a
  aprovação do comentário do plan, por si só, não concede acesso à AWS.

Ao abrir ou atualizar um PR, aguarde o job de plan terminar e confira o
comentário `Terraform plan` antes de fazer o merge.
- O state é armazenado no S3 e usa o lock nativo (`use_lockfile`), disponível
  no Terraform 1.10 ou posterior.

Antes do primeiro `apply`, confira também os valores de
`betodalas-terraform/infra/terraform.tfvars`, especialmente `github_repo`,
e `admin_principal_arns`. Essa última é opcional: quando não informada, somente
as roles do pipeline têm acesso administrativo ao cluster.

## Organização do Terraform

Os recursos da infraestrutura ficam separados em módulos locais dentro de
`betodalas-terraform/infra/modules/`:

- `vpc`: rede, subnets e NAT Gateway;
- `eks`: cluster, node groups e EKS Access Entries. As permissões do cluster
  ficam junto do cluster porque dependem da API do EKS;
- `iam`: criação opcional de usuários IAM. Usuários declarados em `iam_users`
  recebem uma Access Entry administrativa no EKS, mas o módulo não cria chaves
  de acesso.

Para criar um usuário IAM e permitir seu acesso administrativo ao cluster,
adicione-o em `betodalas-terraform/infra/terraform.tfvars`:

```hcl
iam_users = {
  roberto = {
    tags = {
      Owner = "roberto"
    }
  }
}
```

Para usuários ou roles que já existem, continue usando `admin_principal_arns`.
