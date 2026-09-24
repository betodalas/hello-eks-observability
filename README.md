# EKS Observability com Terraform e Argo CD

Este projeto provisiona um EKS econômico e entrega a aplicação pelo GitOps:

- Terraform: VPC, EKS, ECR, OIDC/IRSA, AWS Load Balancer Controller e
  Karpenter. O Argo CD é instalado manualmente no cluster.
- Argo CD: AWS Load Balancer Controller, Karpenter, Prometheus, Grafana e
  `hello-app`.
- GitHub Actions: publica a imagem no ECR com a SHA do commit e atualiza o tag
  no Kustomize para o Argo CD reconciliar.

## Fluxo de entrega

O `terraform apply` cria somente a infraestrutura AWS. Depois, o Argo CD é
instalado manualmente a partir de uma máquina com acesso ao endpoint do EKS e
as Applications são aplicadas pelos manifests em
[gitops/tools/](./gitops/tools/) e [gitops/apps/](./gitops/apps/). O workflow
de aplicação constrói [app/](./app/), publica no ECR e altera
`gitops/apps/hello-app/kustomization.yaml`; essa alteração dispara a
reconciliação automática do Argo CD.

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
4. Faça push de uma alteração em `app/`. O workflow `.github/workflows/app.yml`
   publicará a imagem e fará o commit do novo SHA no diretório GitOps.

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

## Acesso para a apresentação

```bash
aws eks update-kubeconfig --region us-east-1 --name hello-observability-prod
kubectl get applications -n argocd
kubectl get ingress -n hello-app
kubectl get nodes
```

O endereço público da aplicação é o hostname do Ingress:

```bash
kubectl get ingress hello-app -n hello-app \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Para acessar Grafana e Argo localmente sem expor serviços administrativos:

```bash
kubectl port-forward -n kube-system svc/monitoring-grafana 3000:80
kubectl port-forward -n argocd svc/argocd-server 8080:80
```

A senha inicial do Grafana fica no Secret `monitoring-grafana`. O Argo CD pode
ser acessado em `http://localhost:8080`; obtenha a senha com:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 --decode; echo
```

O endpoint `/metrics` da aplicação expõe `hello_app_requests_total`, permitindo
demonstrar a coleta pelo Prometheus.
