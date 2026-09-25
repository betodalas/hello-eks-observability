# EKS Observability com Terraform e Argo CD

Este projeto provisiona um EKS econômico e entrega a aplicação pelo GitOps:

- Terraform (via GitHub Actions): faz o bootstrap da infraestrutura AWS — VPC,
  EKS, ECR, OIDC/IRSA. O Argo CD é instalado manualmente no cluster.
- Argo CD (GitOps): a partir do bootstrap manual, gerencia AWS Load Balancer
  Controller, Karpenter, Prometheus, Grafana, Argo CD Image Updater e as
  aplicações em `gitops/apps/`.
- GitHub Actions: builda a aplicação alterada e publica a imagem no ECR com a
  SHA do commit. O Argo CD Image Updater detecta a nova tag e atualiza o
  deploy automaticamente; para aplicações novas, o workflow abre um Pull
  Request com os manifests iniciais.

## Fluxo de entrega

1. **Bootstrap da infraestrutura (Terraform, via GitHub Actions).** O
   workflow [`.github/workflows/terraform.yml`](./.github/workflows/terraform.yml)
   executa o `terraform apply` que provisiona a infraestrutura AWS (VPC, EKS,
   ECR, roles OIDC/IRSA). Nessa etapa o cluster ainda não tem Argo CD nem
   nenhuma ferramenta instalada.
2. **Bootstrap do Argo CD (manual).** A partir de uma máquina com acesso ao
   endpoint do EKS, o Argo CD é instalado manualmente e a Application raiz
   (`gitops/argocd/root-application.yaml`) é criada uma única vez. A partir
   daí o próprio Argo CD assume o ciclo de vida do cluster.
3. **Ferramentas e aplicações via código (GitOps).** Depois do bootstrap, tudo
   que roda no cluster — AWS Load Balancer Controller, Karpenter, Prometheus,
   Grafana, o Argo CD Image Updater e as aplicações em
   [gitops/apps/](./gitops/apps/) — é instalado e atualizado só por manifests
   versionados em [gitops/tools/](./gitops/tools/) e
   [gitops/apps/](./gitops/apps/). Não se aplica nada manualmente com
   `kubectl` depois do passo 2.
4. **Build e entrega de imagem (GitHub Actions).** O workflow
   [`.github/workflows/app.yml`](./.github/workflows/app.yml) builda somente
   as aplicações de [app/](./app/) que mudaram no push e publica a imagem no
   ECR com a SHA do commit.
   - Se a aplicação **já existe** em `gitops/apps/<nome>`, nada mais é feito
     por esse workflow: o **Argo CD Image Updater** identifica a nova tag
     publicada no ECR e atualiza o Kustomize (e o Git, via write-back)
     automaticamente, e o Argo CD reconcilia o deploy.
   - Se a aplicação é **nova**, o workflow gera os manifests iniciais
     (Deployment, Service, Ingress, Kustomization e Application) em
     `gitops/apps/<nome>` e abre um Pull Request para revisão. Depois que o PR
     é mergeado na `main`, o Argo CD cria a Application e, a partir daí, o
     Image Updater assume as próximas atualizações de imagem normalmente.

O ambiente de produção começa com dez `t3.micro`. O Karpenter usa somente
instâncias `t3.micro` Spot e tem limite de 2 vCPUs. Os requests do
Argo, Prometheus e Grafana foram reduzidos para caber no ambiente de
demonstração. Em produção, aumente capacidade e retenção.

## Deploy

1. Configure o backend S3, as roles OIDC do GitHub e as variáveis do ambiente
   em `betodalas-terraform/infra/environments/prod/terraform.tfvars`.
2. Execute:

   ```bash
   terraform -chdir=betodalas-terraform/infra/environments/prod init \
     -backend-config=backend.hcl
   terraform -chdir=betodalas-terraform/infra/environments/prod plan
   terraform -chdir=betodalas-terraform/infra/environments/prod apply
   ```

3. Cadastre `AWS_TERRAFORM_APPLY_ROLE_ARN` como variável do repositório GitHub.
   A role precisa permitir ECR (`GetAuthorizationToken`, push de layers e
   `PutImage`); a role de apply criada pelo bootstrap já possui essa permissão.
4. Faça push de uma alteração em `app/<nome-da-app>/`. O workflow
   `.github/workflows/app.yml` publicará a imagem no ECR; para uma aplicação
   já existente, o Argo CD Image Updater atualiza o deploy automaticamente,
   e para uma aplicação nova o workflow abre um Pull Request com os
   manifests iniciais.

Depois de instalar o Argo CD, substitua os dois placeholders de ARN nos
manifests em `gitops/tools/` pelos outputs Terraform:

```bash
terraform -chdir=betodalas-terraform/infra/environments/prod output \
  load_balancer_controller_role_arn
terraform -chdir=betodalas-terraform/infra/environments/prod output \
  karpenter_controller_role_arn
```

No painel do Argo CD, crie a Application inicial `platform` com:

| Campo | Valor |
| --- | --- |
| Application Name | `platform` |
| Project | `default` |
| Repository URL | `https://github.com/betodalas/hello-eks-observability.git` |
| Revision | `main` |
| Path | `gitops` |
| Cluster URL | `https://kubernetes.default.svc` |
| Namespace | `argocd` |
| Directory Recurse | habilitado |

Essa configuração corresponde a `gitops/argocd/root-application.yaml`. Depois
de salvar, o Argo CD cria e sincroniza automaticamente as Applications
separadas em `tools/` e `apps/`. Não é necessário aplicar manifests das
ferramentas ou da aplicação com `kubectl`.

O Argo CD consulta o repositório periodicamente. Portanto, depois que essa
Application raiz estiver criada, um merge na `main` será reconciliado sem
executar novos comandos de deploy.

## Acesso ao cluster

```bash
aws eks update-kubeconfig --region us-east-1 --name hello-observability-prod
kubectl get applications -n argocd
kubectl get ingress -A
kubectl get nodes
```

O endereço público de uma aplicação é o hostname do respectivo Ingress:

```bash
kubectl get ingress <nome-da-app> -n <nome-da-app> \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Grafana e Argo CD não são expostos publicamente; o acesso é feito via
port-forward:

```bash
kubectl port-forward -n kube-system svc/monitoring-grafana 3000:80
kubectl port-forward -n argocd svc/argocd-server 8080:80
```

A senha inicial do Grafana fica no Secret `monitoring-grafana`. O Argo CD é
acessado em `http://localhost:8080`; obtenha a senha com:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 --decode; echo
```

O endpoint `/metrics` de cada aplicação expõe métricas coletadas pelo
Prometheus e visualizáveis no Grafana.
