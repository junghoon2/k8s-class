# module "eks_blueprints_addons" {
#   source = "aws-ia/eks-blueprints-addons/aws"
#   version = "~> 1.0" #ensure to update this to the latest/desired version

#   cluster_name      = module.eks.cluster_name
#   cluster_endpoint  = module.eks.cluster_endpoint
#   cluster_version   = module.eks.cluster_version
#   oidc_provider_arn = module.eks.oidc_provider_arn

#   eks_addons = {
#     # aws-ebs-csi-driver = {
#     #   most_recent = true
#     # }
#     coredns = {
#       most_recent = true
#     }
#     vpc-cni = {
#       most_recent = true
#     }
#     kube-proxy = {
#       most_recent = true
#     }
#   }

#   enable_aws_load_balancer_controller    = true
# #   enable_cluster_proportional_autoscaler = true
# #   enable_karpenter                       = true
# #   enable_kube_prometheus_stack           = true
# #   enable_metrics_server                  = true
# #   enable_external_dns                    = true
# #   enable_cert_manager                    = true
# #   cert_manager_route53_hosted_zone_arns  = ["arn:aws:route53:::hostedzone/XXXXXXXXXXXXX"]

#   tags = local.tags
# }


# ################################################################################
# # AWS Load Balancer Controller
# ################################################################################

# locals {
#   aws_load_balancer_controller_service_account = try(var.aws_load_balancer_controller.service_account_name, "aws-load-balancer-controller-sa")
#   aws_load_balancer_controller_namespace       = try(var.aws_load_balancer_controller.namespace, "kube-system")
# }

# # https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/docs/install/iam_policy.json
# data "aws_iam_policy_document" "aws_load_balancer_controller" {
#   count = var.enable_aws_load_balancer_controller ? 1 : 0

#   statement {
#     actions   = ["iam:CreateServiceLinkedRole"]
#     resources = ["*"]

#     condition {
#       test     = "StringEquals"
#       variable = "iam:AWSServiceName"
#       values   = ["elasticloadbalancing.${local.dns_suffix}"]
#     }
#   }

#   statement {
#     actions = [
#       "ec2:DescribeAccountAttributes",
#       "ec2:DescribeAddresses",
#       "ec2:DescribeAvailabilityZones",
#       "ec2:DescribeInternetGateways",
#       "ec2:DescribeVpcs",
#       "ec2:DescribeVpcPeeringConnections",
#       "ec2:DescribeSubnets",
#       "ec2:DescribeSecurityGroups",
#       "ec2:DescribeInstances",
#       "ec2:DescribeNetworkInterfaces",
#       "ec2:DescribeTags",
#       "ec2:GetCoipPoolUsage",
#       "ec2:DescribeCoipPools",
#       "elasticloadbalancing:DescribeLoadBalancers",
#       "elasticloadbalancing:DescribeLoadBalancerAttributes",
#       "elasticloadbalancing:DescribeListeners",
#       "elasticloadbalancing:DescribeListenerCertificates",
#       "elasticloadbalancing:DescribeSSLPolicies",
#       "elasticloadbalancing:DescribeRules",
#       "elasticloadbalancing:DescribeTargetGroups",
#       "elasticloadbalancing:DescribeTargetGroupAttributes",
#       "elasticloadbalancing:DescribeTargetHealth",
#       "elasticloadbalancing:DescribeTags",
#     ]
#     resources = ["*"]
#   }

#   statement {
#     actions = [
#       "cognito-idp:DescribeUserPoolClient",
#       "acm:ListCertificates",
#       "acm:DescribeCertificate",
#       "iam:ListServerCertificates",
#       "iam:GetServerCertificate",
#       "waf-regional:GetWebACL",
#       "waf-regional:GetWebACLForResource",
#       "waf-regional:AssociateWebACL",
#       "waf-regional:DisassociateWebACL",
#       "wafv2:GetWebACL",
#       "wafv2:GetWebACLForResource",
#       "wafv2:AssociateWebACL",
#       "wafv2:DisassociateWebACL",
#       "shield:GetSubscriptionState",
#       "shield:DescribeProtection",
#       "shield:CreateProtection",
#       "shield:DeleteProtection",
#     ]
#     resources = ["*"]
#   }

#   statement {
#     actions = [
#       "ec2:AuthorizeSecurityGroupIngress",
#       "ec2:RevokeSecurityGroupIngress",
#     ]
#     resources = ["*"]
#   }

#   statement {
#     actions   = ["ec2:CreateSecurityGroup"]
#     resources = ["*"]
#   }

#   statement {
#     actions   = ["ec2:CreateTags"]
#     resources = ["arn:${local.partition}:ec2:*:*:security-group/*", ]

#     condition {
#       test     = "StringEquals"
#       variable = "ec2:CreateAction"
#       values   = ["CreateSecurityGroup"]
#     }

#     condition {
#       test     = "Null"
#       variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
#       values   = ["false"]
#     }
#   }

#   statement {
#     actions = [
#       "ec2:CreateTags",
#       "ec2:DeleteTags",
#     ]
#     resources = ["arn:${local.partition}:ec2:*:*:security-group/*"]

#     condition {
#       test     = "Null"
#       variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
#       values   = ["true"]
#     }

#     condition {
#       test     = "Null"
#       variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
#       values   = ["false"]
#     }
#   }

#   statement {
#     actions = [
#       "ec2:AuthorizeSecurityGroupIngress",
#       "ec2:RevokeSecurityGroupIngress",
#       "ec2:DeleteSecurityGroup",
#     ]
#     resources = ["*"]

#     condition {
#       test     = "Null"
#       variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
#       values   = ["false"]
#     }
#   }

#   statement {
#     actions = [
#       "elasticloadbalancing:CreateLoadBalancer",
#       "elasticloadbalancing:CreateTargetGroup",
#     ]
#     resources = ["*"]

#     condition {
#       test     = "Null"
#       variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
#       values   = ["false"]
#     }
#   }

#   statement {
#     actions = [
#       "elasticloadbalancing:CreateListener",
#       "elasticloadbalancing:DeleteListener",
#       "elasticloadbalancing:CreateRule",
#       "elasticloadbalancing:DeleteRule",
#     ]
#     resources = ["*"]
#   }

#   statement {
#     actions = [
#       "elasticloadbalancing:AddTags",
#       "elasticloadbalancing:RemoveTags",
#     ]
#     resources = [
#       "arn:${local.partition}:elasticloadbalancing:*:*:targetgroup/*/*",
#       "arn:${local.partition}:elasticloadbalancing:*:*:loadbalancer/net/*/*",
#       "arn:${local.partition}:elasticloadbalancing:*:*:loadbalancer/app/*/*"
#     ]

#     condition {
#       test     = "Null"
#       variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
#       values   = ["true"]
#     }

#     condition {
#       test     = "Null"
#       variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
#       values   = ["false"]
#     }
#   }

#   statement {
#     actions = [
#       "elasticloadbalancing:AddTags",
#       "elasticloadbalancing:RemoveTags",
#     ]
#     resources = [
#       "arn:${local.partition}:elasticloadbalancing:*:*:listener/net/*/*/*",
#       "arn:${local.partition}:elasticloadbalancing:*:*:listener/app/*/*/*",
#       "arn:${local.partition}:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
#       "arn:${local.partition}:elasticloadbalancing:*:*:listener-rule/app/*/*/*",
#     ]
#   }

#   statement {
#     actions = [
#       "elasticloadbalancing:ModifyLoadBalancerAttributes",
#       "elasticloadbalancing:SetIpAddressType",
#       "elasticloadbalancing:SetSecurityGroups",
#       "elasticloadbalancing:SetSubnets",
#       "elasticloadbalancing:DeleteLoadBalancer",
#       "elasticloadbalancing:ModifyTargetGroup",
#       "elasticloadbalancing:ModifyTargetGroupAttributes",
#       "elasticloadbalancing:DeleteTargetGroup",
#     ]
#     resources = ["*"]

#     condition {
#       test     = "Null"
#       variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
#       values   = ["false"]
#     }
#   }

#   statement {
#     actions = ["elasticloadbalancing:AddTags"]
#     resources = [
#       "arn:${local.partition}:elasticloadbalancing:*:*:targetgroup/*/*",
#       "arn:${local.partition}:elasticloadbalancing:*:*:loadbalancer/net/*/*",
#       "arn:${local.partition}:elasticloadbalancing:*:*:loadbalancer/app/*/*",
#     ]

#     condition {
#       test     = "StringEquals"
#       variable = "elasticloadbalancing:CreateAction"
#       values = [
#         "CreateTargetGroup",
#         "CreateLoadBalancer",
#       ]
#     }

#     condition {
#       test     = "Null"
#       variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
#       values   = ["false"]
#     }
#   }

#   statement {
#     actions = [
#       "elasticloadbalancing:RegisterTargets",
#       "elasticloadbalancing:DeregisterTargets",
#     ]
#     resources = ["arn:${local.partition}:elasticloadbalancing:*:*:targetgroup/*/*"]
#   }

#   statement {
#     actions = [
#       "elasticloadbalancing:SetWebAcl",
#       "elasticloadbalancing:ModifyListener",
#       "elasticloadbalancing:AddListenerCertificates",
#       "elasticloadbalancing:RemoveListenerCertificates",
#       "elasticloadbalancing:ModifyRule",
#     ]
#     resources = ["*"]
#   }
# }

# module "aws_load_balancer_controller" {
#   source  = "aws-ia/eks-blueprints-addon/aws"
#   version = "1.1.0"

#   create = var.enable_aws_load_balancer_controller

#   # Disable helm release
#   create_release = var.create_kubernetes_resources

#   # https://github.com/aws/eks-charts/blob/master/stable/aws-load-balancer-controller/Chart.yaml
#   name        = try(var.aws_load_balancer_controller.name, "aws-load-balancer-controller")
#   description = try(var.aws_load_balancer_controller.description, "A Helm chart to deploy aws-load-balancer-controller for ingress resources")
#   namespace   = local.aws_load_balancer_controller_namespace
#   # namespace creation is false here as kube-system already exists by default
#   create_namespace = try(var.aws_load_balancer_controller.create_namespace, false)
#   chart            = try(var.aws_load_balancer_controller.chart, "aws-load-balancer-controller")
#   chart_version    = try(var.aws_load_balancer_controller.chart_version, "1.6.0")
#   repository       = try(var.aws_load_balancer_controller.repository, "https://aws.github.io/eks-charts")
#   values           = try(var.aws_load_balancer_controller.values, [])

#   timeout                    = try(var.aws_load_balancer_controller.timeout, null)
#   repository_key_file        = try(var.aws_load_balancer_controller.repository_key_file, null)
#   repository_cert_file       = try(var.aws_load_balancer_controller.repository_cert_file, null)
#   repository_ca_file         = try(var.aws_load_balancer_controller.repository_ca_file, null)
#   repository_username        = try(var.aws_load_balancer_controller.repository_username, null)
#   repository_password        = try(var.aws_load_balancer_controller.repository_password, null)
#   devel                      = try(var.aws_load_balancer_controller.devel, null)
#   verify                     = try(var.aws_load_balancer_controller.verify, null)
#   keyring                    = try(var.aws_load_balancer_controller.keyring, null)
#   disable_webhooks           = try(var.aws_load_balancer_controller.disable_webhooks, null)
#   reuse_values               = try(var.aws_load_balancer_controller.reuse_values, null)
#   reset_values               = try(var.aws_load_balancer_controller.reset_values, null)
#   force_update               = try(var.aws_load_balancer_controller.force_update, null)
#   recreate_pods              = try(var.aws_load_balancer_controller.recreate_pods, null)
#   cleanup_on_fail            = try(var.aws_load_balancer_controller.cleanup_on_fail, null)
#   max_history                = try(var.aws_load_balancer_controller.max_history, null)
#   atomic                     = try(var.aws_load_balancer_controller.atomic, null)
#   skip_crds                  = try(var.aws_load_balancer_controller.skip_crds, null)
#   render_subchart_notes      = try(var.aws_load_balancer_controller.render_subchart_notes, null)
#   disable_openapi_validation = try(var.aws_load_balancer_controller.disable_openapi_validation, null)
#   wait                       = try(var.aws_load_balancer_controller.wait, false)
#   wait_for_jobs              = try(var.aws_load_balancer_controller.wait_for_jobs, null)
#   dependency_update          = try(var.aws_load_balancer_controller.dependency_update, null)
#   replace                    = try(var.aws_load_balancer_controller.replace, null)
#   lint                       = try(var.aws_load_balancer_controller.lint, null)

#   postrender = try(var.aws_load_balancer_controller.postrender, [])
#   set = concat([
#     {
#       name  = "serviceAccount.name"
#       value = local.aws_load_balancer_controller_service_account
#       }, {
#       name  = "clusterName"
#       value = local.cluster_name
#     }],
#     try(var.aws_load_balancer_controller.set, [])
#   )
#   set_sensitive = try(var.aws_load_balancer_controller.set_sensitive, [])

#   # IAM role for service account (IRSA)
#   create_role                   = try(var.aws_load_balancer_controller.create_role, true)
#   set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
#   role_name                     = try(var.aws_load_balancer_controller.role_name, "alb-controller")
#   role_name_use_prefix          = try(var.aws_load_balancer_controller.role_name_use_prefix, true)
#   role_path                     = try(var.aws_load_balancer_controller.role_path, "/")
#   role_permissions_boundary_arn = lookup(var.aws_load_balancer_controller, "role_permissions_boundary_arn", null)
#   role_description              = try(var.aws_load_balancer_controller.role_description, "IRSA for aws-load-balancer-controller project")
#   role_policies                 = lookup(var.aws_load_balancer_controller, "role_policies", {})

#   source_policy_documents = compact(concat(
#     data.aws_iam_policy_document.aws_load_balancer_controller[*].json,
#     lookup(var.aws_load_balancer_controller, "source_policy_documents", [])
#   ))
#   override_policy_documents = lookup(var.aws_load_balancer_controller, "override_policy_documents", [])
#   policy_statements         = lookup(var.aws_load_balancer_controller, "policy_statements", [])
#   policy_name               = try(var.aws_load_balancer_controller.policy_name, null)
#   policy_name_use_prefix    = try(var.aws_load_balancer_controller.policy_name_use_prefix, true)
#   policy_path               = try(var.aws_load_balancer_controller.policy_path, null)
#   policy_description        = try(var.aws_load_balancer_controller.policy_description, "IAM Policy for AWS Load Balancer Controller")

#   oidc_providers = {
#     this = {
#       provider_arn = local.oidc_provider_arn
#       # namespace is inherited from chart
#       service_account = local.aws_load_balancer_controller_service_account
#     }
#   }

#   tags = var.tags
# }
