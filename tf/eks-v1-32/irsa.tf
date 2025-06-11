# IRSA (IAM Roles for Service Accounts) 설정
# 베스트 프랙티스: Pod Identity를 통한 세밀한 권한 제어, 최소 권한 원칙 적용

# VPC CNI용 IRSA - Pod 네트워킹 관리 권한
module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-vpc-cni-irsa"

  attach_vpc_cni_policy = true  # VPC CNI 관리 권한 부여
  vpc_cni_enable_ipv4   = true  # IPv4 지원 활성화

  # OIDC Provider와 Service Account 연결
  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]  # aws-node DaemonSet과 연결
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-vpc-cni-irsa"
  })
}

# IRSA for EBS CSI Driver
module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-ebs-csi-irsa"

  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-ebs-csi-irsa"
  })
}

# IRSA for EFS CSI Driver
module "efs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-efs-csi-irsa"

  attach_efs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-efs-csi-irsa"
  })
}

# AWS Load Balancer Controller용 IRSA - ALB/NLB 관리 권한
module "aws_load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true  # ALB/NLB 생성/관리 권한

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-aws-load-balancer-controller-irsa"
  })
}

# IRSA for External DNS
module "external_dns_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-external-dns"

  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/*"]

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-external-dns-irsa"
  })
}

# IRSA for Karpenter - 노드 자동 스케일링 및 프로비저닝 권한
module "karpenter_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-karpenter"

  attach_karpenter_controller_policy = true  # Karpenter가 EC2 인스턴스를 관리할 수 있는 권한
  karpenter_controller_cluster_name  = module.eks.cluster_name
  karpenter_controller_node_iam_role_arns = [module.eks.eks_managed_node_groups["main"].iam_role_arn]

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:karpenter"]
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-karpenter-irsa"
  })
}

# 참고: Pod Identity Agent는 IRSA가 필요하지 않습니다.
# Pod Identity는 IRSA의 개선된 버전으로, 더 간단하고 보안이 강화된 방식입니다.
# eks.tf의 aws_eks_addon.pod_identity_agent만으로 충분합니다.

