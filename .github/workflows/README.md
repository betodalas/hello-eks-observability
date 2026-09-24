# Deploy do Terraform

A infraestrutura tem dois roots independentes:

```text
betodalas-terraform/infra/
├── modules/{vpc,eks,iam}/       # módulos compartilhados
└── environments/
    ├── dev/                     # state eks/dev/terraform.tfstate
    └── prod/                    # state eks/prod/terraform.tfstate
```

Cada ambiente contém `main.tf`, `providers.tf`, `versions.tf`, `variables.tf`,
`outputs.tf`, `backend.hcl` e `terraform.tfvars`. O root `infra/` não contém
configuração Terraform ativa; `bootstrap/` permanece separado e inalterado.

## Comandos locais

Depois de executar o bootstrap e preencher o bucket no `backend.hcl`:

```bash
terraform -chdir=betodalas-terraform/infra/environments/dev init -backend-config=backend.hcl
terraform -chdir=betodalas-terraform/infra/environments/dev validate
terraform -chdir=betodalas-terraform/infra/environments/dev plan

terraform -chdir=betodalas-terraform/infra/environments/prod init -backend-config=backend.hcl
terraform -chdir=betodalas-terraform/infra/environments/prod validate
terraform -chdir=betodalas-terraform/infra/environments/prod plan
```

Para uma validação sem AWS e sem backend remoto (usada também para smoke tests):

```bash
terraform -chdir=betodalas-terraform/infra/environments/dev init -backend=false
terraform -chdir=betodalas-terraform/infra/environments/dev validate
terraform -chdir=betodalas-terraform/infra/environments/prod init -backend=false
terraform -chdir=betodalas-terraform/infra/environments/prod validate
```

O bucket e `use_lockfile = true` permanecem em cada `backend.hcl`. Configure a
mesma variável `TF_STATE_BUCKET` usada pelo bootstrap no GitHub. As roles do
workflow continuam usando o prefixo `hello-observability` criado pelo
bootstrap; o `project` de produção pode ser diferente porque
`terraform_role_project` controla essa referência. O workflow faz plan de dev
e prod em Pull Requests, aplica dev em pushes para a branch `dev` e aplica prod
em pushes para `main`. Cada apply usa o diretório e o state do próprio
ambiente. O apply de prod é protegido pelo Environment `production` e seus
required reviewers; o apply de dev usa o Environment `development`.

## Fronteira entre Terraform e Argo CD

O Terraform deste repositório é responsável somente pela infraestrutura AWS e
pela configuração base do EKS:

- VPC, subnets, NAT Gateway e security groups;
- cluster EKS e managed node groups;
- EKS managed add-ons;
- IAM, OIDC, Access Entries e roles usadas por controllers;
- repositório ECR e recursos necessários para o bootstrap.

O Terraform não instala mais charts nem recursos de workload no Kubernetes.
Os providers `helm` e `kubernetes` não fazem parte dos roots de ambiente.

O Argo CD deve ser o único responsável pelo estado dentro do cluster,
instalando via Helm e reconciliando:

- AWS Load Balancer Controller;
- Karpenter;
- Prometheus, Grafana e Alertmanager;
- dashboards, regras e monitores;
- aplicações, Services e Ingresses.

As roles IAM necessárias aos controllers continuam sendo criadas pelo
Terraform. Por exemplo, `load_balancer_controller_role_arn` é exposto como
output para ser usado na configuração do ServiceAccount gerenciado pelo Argo
CD. Assim, cada recurso tem um único owner e Terraform e Argo CD não disputam
o mesmo estado.

O Argo CD e seu repositório GitOps são uma camada separada deste root
Terraform. O workflow deste arquivo continua validando e aplicando apenas a
infraestrutura; a reconciliação dos workloads deve ocorrer no pipeline do
repositório GitOps.

## Migração do state existente

Não há `moved` blocks e nenhum state foi movido automaticamente. O state do
antigo root `infra/` deve ser copiado explicitamente para dev
(`eks/dev/terraform.tfstate`), pois `environments/dev` preserva o projeto e os
nomes originais. Faça essa operação uma única vez, com o state desbloqueado,
antes do primeiro plan remoto:

```bash
# Execute enquanto o antigo root ainda estiver disponível (por exemplo, em um
# worktree da revisão anterior), usando seu backend antigo.
terraform -chdir=betodalas-terraform/infra state pull > betodalas-terraform/infra/infra-state-backup.json

# Inicialize o novo root sem migrar automaticamente o backend e publique o
# backup no novo objeto S3. O backend.hcl de dev contém key = eks/dev/terraform.tfstate.
terraform -chdir=betodalas-terraform/infra/environments/dev init -backend-config=backend.hcl
terraform -chdir=betodalas-terraform/infra/environments/dev state push ../../infra-state-backup.json
terraform -chdir=betodalas-terraform/infra/environments/dev plan
```

Se o arquivo foi salvo em outro diretório, ajuste o caminho do `state push`.
Confirme o backup e o plan antes de remover o state antigo. Não execute esses
comandos no CI e não use `terraform state mv` para alterar endereços: os
endereços dos módulos foram preservados.

Para prod, o `terraform.tfvars` usa CIDRs, capacidade e prefixo próprios; revise
esses valores antes do primeiro apply. Mantenha as chaves de `node_groups`
(como `default`) para preservar endereços de recursos quando um ambiente já
existir.
