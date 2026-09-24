# kube-prometheus-stack = Prometheus + Alertmanager + Grafana + node-exporter
# + kube-state-metrics + regras/dashboards prontos para Kubernetes.

resource "random_password" "grafana_admin" {
  length  = 20
  special = false
}

resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.prometheus_stack_chart_version
  namespace        = "monitoring"
  create_namespace = true

  timeout = 900
  wait    = true

  values = [yamlencode({
    # Prometheus enxerga ServiceMonitors/PodMonitors/Rules de QUALQUER namespace
    # (sem isso ele só pega os que têm o label release=kube-prometheus-stack).
    prometheus = {
      prometheusSpec = {
        serviceMonitorSelectorNilUsesHelmValues = false
        podMonitorSelectorNilUsesHelmValues     = false
        ruleSelectorNilUsesHelmValues           = false
        retention                               = "3d"
        resources = {
          requests = { cpu = "200m", memory = "512Mi" }
          limits   = { memory = "1Gi" }
        }
        # Sem PVC de propósito (evita precisar do EBS CSI driver nesta demo).
        # Consequência: métricas somem se o pod do Prometheus for recriado.
      }
    }

    alertmanager = {
      alertmanagerSpec = {
        resources = {
          requests = { cpu = "10m", memory = "32Mi" }
        }
      }
    }

    grafana = {
      adminPassword = random_password.grafana_admin.result

      # Carrega automaticamente ConfigMaps com o label grafana_dashboard=1
      # de TODOS os namespaces (é assim que o dashboard da app vai subir pronto).
      sidecar = {
        dashboards = {
          enabled         = true
          label           = "grafana_dashboard"
          labelValue      = "1"
          searchNamespace = "ALL"
        }
      }

      # Grafana servido em /grafana para dividir o MESMO ALB com a aplicação (1 ALB só = mais barato).
      "grafana.ini" = {
        server = {
          root_url            = "%(protocol)s://%(domain)s/grafana/"
          serve_from_sub_path = true
        }
      }

      ingress = {
        enabled          = true
        ingressClassName = "alb"
        path             = "/grafana"
        pathType         = "Prefix"
        annotations = {
          "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
          "alb.ingress.kubernetes.io/target-type"      = "ip"
          "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTP\":80}]"
          "alb.ingress.kubernetes.io/healthcheck-path" = "/grafana/api/health"
          "alb.ingress.kubernetes.io/group.name"       = "public"
          "alb.ingress.kubernetes.io/group.order"      = "10"
        }
      }
    }

    # No EKS o control plane é gerenciado pela AWS: esses alvos não são acessíveis
    # e só gerariam alertas falsos.
    kubeEtcd              = { enabled = false }
    kubeControllerManager = { enabled = false }
    kubeScheduler         = { enabled = false }
    kubeProxy             = { enabled = false }
    defaultRules = {
      rules = {
        etcd                  = false
        kubeControllerManager = false
        kubeSchedulerAlerting = false
        kubeProxy             = false
      }
    }
  })]

  # O webhook do LB Controller precisa estar de pé antes de criar o Ingress do Grafana.
  depends_on = [helm_release.aws_lb_controller]
}
