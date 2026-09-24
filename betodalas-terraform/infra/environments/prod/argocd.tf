locals {
  gitops_repository = "https://github.com/${var.github_repo}.git"

  argocd_applications = [
    {
      name      = "aws-load-balancer-controller"
      namespace = "argocd"
      path      = null
      chart     = "aws-load-balancer-controller"
      repoURL   = "https://aws.github.io/eks-charts"
      version   = "1.11.0"
      values = {
        clusterName = module.eks.cluster_name
        serviceAccount = {
          create = true
          name   = "aws-load-balancer-controller"
          annotations = {
            "eks.amazonaws.com/role-arn" = module.lb_controller_irsa.iam_role_arn
          }
        }
        replicaCount = 1
        resources = {
          requests = { cpu = "20m", memory = "64Mi" }
          limits   = { cpu = "100m", memory = "128Mi" }
        }
      }
    },
    {
      name      = "karpenter"
      namespace = "argocd"
      path      = null
      chart     = "karpenter"
      repoURL   = "oci://public.ecr.aws/karpenter"
      version   = "1.5.0"
      values = {
        settings = {
          clusterName = module.eks.cluster_name
        }
        serviceAccount = {
          annotations = {
            "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter_controller.arn
          }
        }
        controller = {
          resources = {
            requests = { cpu = "20m", memory = "64Mi" }
            limits   = { cpu = "100m", memory = "128Mi" }
          }
        }
      }
    },
    {
      name      = "karpenter-nodepool"
      namespace = "argocd"
      path      = "gitops/platform/karpenter-nodepool"
      chart     = null
      repoURL   = null
      version   = null
      values    = null
    },
    {
      name      = "monitoring"
      namespace = "argocd"
      path      = null
      chart     = "kube-prometheus-stack"
      repoURL   = "https://prometheus-community.github.io/helm-charts"
      version   = "70.4.2"
      values = {
        grafana = {
          enabled = true
          resources = {
            requests = { cpu = "20m", memory = "64Mi" }
            limits   = { cpu = "100m", memory = "128Mi" }
          }
          service = { type = "ClusterIP" }
        }
        prometheus = {
          prometheusSpec = {
            retention = "2h"
            resources = {
              requests = { cpu = "30m", memory = "128Mi" }
              limits   = { cpu = "150m", memory = "256Mi" }
            }
          }
        }
        alertmanager          = { enabled = false }
        kubeControllerManager = { enabled = false }
        kubeScheduler         = { enabled = false }
        kubeEtcd              = { enabled = false }
        kubeProxy             = { enabled = false }
      }
    },
    {
      name      = "hello-app"
      namespace = "argocd"
      path      = "gitops/apps/hello-app"
      chart     = null
      repoURL   = null
      version   = null
      values    = null
    }
  ]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.9.0"

  values = [yamlencode({
    global = {
      domain = "argocd.local"
    }
    controller = {
      resources = {
        requests = { cpu = "50m", memory = "128Mi" }
        limits   = { cpu = "200m", memory = "256Mi" }
      }
    }
    repoServer = {
      resources = {
        requests = { cpu = "50m", memory = "128Mi" }
        limits   = { cpu = "200m", memory = "256Mi" }
      }
    }
    server = {
      resources = {
        requests = { cpu = "50m", memory = "64Mi" }
        limits   = { cpu = "100m", memory = "128Mi" }
      }
    }
    applicationSet = {
      resources = {
        requests = { cpu = "20m", memory = "32Mi" }
        limits   = { cpu = "100m", memory = "64Mi" }
      }
    }
    redis = {
      resources = {
        requests = { cpu = "20m", memory = "32Mi" }
        limits   = { cpu = "100m", memory = "64Mi" }
      }
    }
    configs = {
      params = {
        "server.insecure" = true
      }
    }
    extraObjects = [
      for app in local.argocd_applications : {
        apiVersion = "argoproj.io/v1alpha1"
        kind       = "Application"
        metadata = {
          name      = app.name
          namespace = app.namespace
        }
        spec = {
          project = "default"
          source = app.chart != null ? {
            repoURL        = app.repoURL
            chart          = app.chart
            targetRevision = app.version
            path           = null
            helm = {
              values = yamlencode(app.values)
            }
            } : {
            repoURL        = local.gitops_repository
            targetRevision = var.gitops_revision
            path           = app.path
            chart          = null
            helm           = null
          }
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = app.name == "hello-app" ? "hello-app" : "kube-system"
          }
          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
            syncOptions = ["CreateNamespace=true"]
          }
        }
      }
    ]
  })]

  depends_on = [module.eks]
}
