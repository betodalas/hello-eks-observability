# Web ACL do AWS WAFv2 associada ao ALB público criado pelo AWS Load Balancer
# Controller via annotation `alb.ingress.kubernetes.io/wafv2-acl-arn` nos
# Ingress em gitops/apps/*.
#
# Scope REGIONAL (obrigatório para ALB; CLOUDFRONT é só para CloudFront).

resource "aws_wafv2_web_acl" "alb" {
  name        = "${local.name}-alb"
  description = "WAF do ALB publico - aws-load-balancer-controller"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "aws-managed-common-rule-set"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name}-common-rule-set"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "rate-limit"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        # Limite por IP de origem em uma janela deslizante de 5 minutos.
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name}-alb"
    sampled_requests_enabled   = true
  }
}
