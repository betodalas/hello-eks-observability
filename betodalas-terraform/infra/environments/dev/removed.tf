# Retira o ownership dos recursos Kubernetes gerenciados anteriormente pelo
# Terraform sem destruí-los. O Argo CD passa a gerenciar esses recursos.
removed {
  from = helm_release.aws_lb_controller

  lifecycle {
    destroy = false
  }
}

removed {
  from = helm_release.kube_prometheus_stack

  lifecycle {
    destroy = false
  }
}

removed {
  from = random_password.grafana_admin

  lifecycle {
    destroy = false
  }
}
