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
2. No GitHub, crie o Environment `production` e habilite aprovação obrigatória
   para o job de `apply`, adicionando somente `@betodalas` como required
   reviewer.
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

## Proteção da branch `main`

O arquivo `.github/CODEOWNERS` define `@betodalas` como o code owner de todo o
repositório. Para tornar essa aprovação obrigatória antes de qualquer merge,
configure em **Settings > Branches > Add branch protection rule** para `main`:

- exigir um Pull Request antes do merge;
- exigir pelo menos 1 aprovação;
- exigir aprovação de um Code Owner;
- exigir que os checks do workflow `Terraform / Terraform plan` passem;
- exigir branch atualizada antes do merge;
- bloquear force push e exclusão da branch;
- adicionar `Repository administrators` à bypass list para permitir que você
  faça merge do próprio PR sem aprovação.

No Environment `production`, em **Settings > Environments**, configure
`@betodalas` como o único required reviewer. Assim, o merge só ocorre depois
da sua aprovação do PR e o `apply` só ocorre depois de uma aprovação separada
do deployment. A aprovação do PR não substitui a aprovação do Environment.

## Fluxo

- Pull requests executam `fmt`, `validate` e `plan` em `betodalas-terraform/infra`;
  o resultado é publicado
  em um comentário atualizável no próprio PR.
- Pushes em `main` executam `plan` e depois aguardam a aprovação obrigatória do
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

O perfil padrão dos nós é `t3.micro` com um único nó para permitir o bootstrap
em contas com restrição Free Tier. Esse tamanho não é suficiente para garantir
a execução do kube-prometheus-stack e da aplicação. Em uma conta sem essa
restrição, substitua o bloco `node_groups` no `terraform.tfvars`, por exemplo:

```hcl
node_groups = {
  default = {
    instance_types = ["t3.large"]
    min_size       = 2
    desired_size   = 2
    max_size       = 4
  }
}
```

## Organização do Terraform

Os recursos da infraestrutura ficam separados em módulos locais dentro de
`betodalas-terraform/infra/modules/`:

- `vpc`: rede, subnets e NAT Gateway;
- `eks`: cluster, node groups e EKS Access Entries. As permissões do cluster
  ficam junto do cluster porque dependem da API do EKS;
- `iam`: criação opcional de usuários IAM. Usuários declarados em `iam_users`
  recebem uma Access Entry administrativa no EKS, mas o módulo não cria chaves
  de acesso.

### Rede VPC

O plano de endereçamento fica explícito em
`betodalas-terraform/infra/terraform.tfvars`. A ordem das listas é importante:
o primeiro item pertence à primeira AZ, o segundo à segunda AZ e assim por
diante.

```hcl
availability_zones = ["us-east-1a", "us-east-1b"]
vpc_cidr           = "10.20.0.0/16"
private_subnets    = ["10.20.0.0/20", "10.20.16.0/20"]
public_subnets     = ["10.20.100.0/24", "10.20.101.0/24"]
```

Ao adicionar uma AZ, adicione também uma subnet privada e uma pública. As
listas precisam ter a mesma quantidade de itens e não podem sobrepor outras
redes usadas pela organização. Alterar esses CIDRs depois que a VPC existir
normalmente exige recriar a rede e os recursos dependentes.

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

O endpoint público do EKS fica habilitado por padrão para permitir o uso do
Terraform e do `kubectl` fora da VPC. O acesso privado também fica habilitado.
Em produção, troque `cluster_endpoint_public_access_cidrs` pelo seu IP ou por
uma rede corporativa; evite manter `0.0.0.0/0`:

```hcl
cluster_endpoint_public_access_cidrs = ["203.0.113.10/32"]
```

O `node_groups.default` é mantido com a mesma chave para preservar o endereço
do node group no state durante a reorganização dos módulos. Para adicionar
capacidade, crie outra chave sem renomear a existente.

As variáveis, outputs e recursos de cada módulo ficam em arquivos separados
(`variables.tf`, `outputs.tf` e `main.tf`). Como a migração do state será
manual, execute os comandos abaixo localmente, com o backend configurado, antes
de rodar o pipeline:

```bash
terraform -chdir=betodalas-terraform/infra state mv \
  'module.vpc' 'module.vpc.module.vpc'

terraform -chdir=betodalas-terraform/infra state mv \
  'module.eks' 'module.eks.module.eks'
```

Depois, execute `terraform plan` localmente e confirme que não existem
operações `destroy` ou `create` para a VPC e o EKS. O state remoto deve estar
salvo e desbloqueado antes do primeiro `plan` do pipeline.
