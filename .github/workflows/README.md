# Deploy do Terraform

O workflow `terraform.yml` usa OIDC para autenticar o GitHub Actions na AWS,
sem armazenar access keys no GitHub.

## Preparação única

1. Execute o Terraform em `betodalas-terraform/bootstrap/` localmente, com credenciais AWS
   administrativas. Esse passo cria o bucket S3 do state e a role
   `hello-observability-terraform-ci`.
2. No GitHub, crie o Environment `production` e, de preferência, habilite
   aprovação obrigatória para o job de `apply`.
3. Cadastre estas **Variables** no repositório:

   - `AWS_REGION`: `us-east-1`
   - `AWS_TERRAFORM_ROLE_ARN`: ARN emitido por
     `terraform -chdir=betodalas-terraform/bootstrap output -raw terraform_ci_role_arn`
   - `TF_STATE_BUCKET`: nome do bucket criado pelo bootstrap
   - `TF_STATE_KEY`: `eks/terraform.tfstate`

O O repositório usado no bootstrap deve ser exatamente o repositório que contém
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
`admin_principal_arns` e `create_github_oidc_provider`.
