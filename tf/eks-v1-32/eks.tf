# EKS 클러스터 메인 설정
# 베스트 프랙티스: Private API Endpoint, 완전 암호화, 모든 로그 활성화
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # 네트워킹 설정
  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets        # 워커 노드는 프라이빗 서브넷에 배치
  control_plane_subnet_ids       = module.vpc.intra_subnets         # 컨트롤 플레인은 더욱 격리된 intra 서브넷 사용
  
  # 클러스터 엔드포인트 설정 - 보안을 위해 Private만 활성화
  # 주의: 이 설정으로 인해 VPC 외부에서는 클러스터 접근 불가 (VPN/Bastion 필요)
  cluster_endpoint_private_access = local.cluster_endpoint_private_access
  cluster_endpoint_public_access  = local.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = local.cluster_endpoint_public_access_cidrs

  # 보안 그룹 설정
  cluster_additional_security_group_ids = [aws_security_group.additional_sg.id]
  
  # 암호화 설정 - Kubernetes Secrets를 KMS로 암호화
  # 베스트 프랙티스: 모든 민감 데이터는 암호화하여 저장
  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }

  # 로깅 설정 - 모든 컨트롤 플레인 로그 활성화
  # 베스트 프랙티스: 보안 감사와 트러블슈팅을 위해 모든 로그 활성화
#   cluster_enabled_log_types = [
#     "api",                    # API 서버 로그
#     "audit",                  # Kubernetes 감사 로그 (보안상 중요)
#     "authenticator",          # 인증 로그
#     "controllerManager",      # 컨트롤러 매니저 로그
#     "scheduler"               # 스케줄러 로그
#   ]

  # 로깅 설정 - 모든 컨트롤 플레인 로그 비활성화
  cluster_enabled_log_types = []

  cloudwatch_log_group_retention_in_days = 90  # 로그 보관 기간 (비용 고려)

  # IRSA(IAM Roles for Service Accounts) 활성화
  # Pod Identity를 위한 필수 설정
  enable_irsa = var.enable_irsa

  # 클러스터 접근 권한 관리
  # 클러스터 생성자에게 관리자 권한 자동 부여
  enable_cluster_creator_admin_permissions = true
  
  # 클러스터 생성자가 자동으로 관리자 권한을 가지므로 추가 access_entries 불필요

  # --------------------------------------------------------------------------
  # EKS 관리형 노드 그룹 (Managed Node Group) 설정
  # --------------------------------------------------------------------------
  # EKS에서 관리하는 워커 노드 그룹을 정의합니다.
  # 노드의 프로비저닝, 업데이트, 종료 등을 AWS가 관리해 운영 부담을 줄여줍니다.
  eks_managed_node_groups = {
    # 노드 그룹의 논리적인 이름 (여기서는 'main'으로 지정)
    main = {
      # 오토스케일링 설정: 최소, 최대, 원하는 노드 수를 지정합니다.
      min_size     = var.eks_node_group_min_size
      max_size     = var.eks_node_group_max_size
      desired_size = var.eks_node_group_desired_size

      # 노드 그룹에서 사용할 AMI 유형입니다. (예: AL2_x86_64, BOTTLEROCKET_x86_64)
      ami_type       = "AL2023_x86_64_STANDARD"  # x86 기반으로 변경
      # 노드 그룹에서 사용할 EC2 인스턴스 유형 목록입니다.
      instance_types = var.eks_node_group_instance_types
      # 인스턴스 구매 옵션입니다. 'ON_DEMAND' 또는 'SPOT'을 사용할 수 있습니다.
      capacity_type  = "ON_DEMAND"
      # 노드 그룹의 인스턴스가 배치될 서브넷 ID 목록입니다. EKS 클러스터와 동일한 프라이빗 서브넷을 사용합니다.
      subnet_ids     = module.vpc.private_subnets

      # 블록 디바이스 매핑 - 단순화된 EBS 설정 (암호화 제거)
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            delete_on_termination = true
          }
        }
      }

      # Bottlerocket AMI 사용 시 추가 설정 예시 (선택 사항)
      # Ref https://bottlerocket.dev/en/os/1.19.x/api/settings/
      # bootstrap_extra_args = <<-EOT
      #   # 관리 컨테이너(SSH 접근) 비활성화
      #   [settings.host-containers.admin]
      #   enabled = false

      #   # 제어 컨테이너(SSM 접근) 활성화 (기본값)
      #   [settings.host-containers.control]
      #   enabled = true

      #   # 커널 보안 설정 예시
      #   [settings.kernel]
      #   lockdown = "integrity"
      # EOT
    }
  }

  # --------------------------------------------------------------------------
  # Fargate 프로필 설정
  # --------------------------------------------------------------------------
  # Karpenter 파드를 위한 Fargate 프로필을 정의합니다.
  # 서버리스 컨테이너 실행 환경을 제공하여 노드 관리 부담을 없앱니다.
  fargate_profiles = {
    karpenter = {
      name = "karpenter"
      # Fargate 프로필이 사용할 서브넷 ID 목록 (프라이빗 서브넷 사용)
      subnet_ids = module.vpc.private_subnets
      
      # Karpenter 파드를 식별하기 위한 셀렉터 설정
      selectors = [
        {
          # kube-system 네임스페이스에서 app=karpenter 레이블이 있는 파드 대상
          namespace = "kube-system"
          labels = {
            app = "karpenter"
          }
        }
      ]
      
      # Fargate 파드 실행 역할에 추가할 정책 (선택 사항)
      # 이 실행 역할은 Fargate에서 실행되는 Karpenter 파드에 권한을 부여합니다.
      timeouts = {
        create = "20m"  # 생성 시간 타임아웃
        delete = "20m"  # 삭제 시간 타임아웃
      }
      
      # Fargate 프로필에 적용할 태그
      tags = merge(
        var.tags,
        {
          "Name" = "${var.cluster_name}-fargate-karpenter"
          "Purpose" = "Karpenter Controller"
        }
      )
    }
  }

  tags = local.common_tags
}

# EKS 애드온 설정
# 베스트 프랙티스: AWS 관리형 애드온 사용으로 자동 업데이트 및 보안 패치 적용

# VPC CNI 애드온 - Pod 네트워킹 담당
resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "vpc-cni"
  service_account_role_arn = module.vpc_cni_irsa.iam_role_arn  # IRSA로 권한 부여

  depends_on = [module.eks.eks_managed_node_groups]

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-vpc-cni-addon"
  })
}

# CoreDNS 애드온 - 클러스터 내부 DNS 해석
resource "aws_eks_addon" "coredns" {
  cluster_name      = module.eks.cluster_name
  addon_name        = "coredns"

  depends_on = [module.eks.eks_managed_node_groups]

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-coredns-addon"
  })
}

# Kube-proxy 애드온 - 서비스 로드밸런싱 담당
resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = module.eks.cluster_name
  addon_name        = "kube-proxy"

  depends_on = [module.eks.eks_managed_node_groups]

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-kube-proxy-addon"
  })
}

# EBS CSI 드라이버 - 영구 볼륨 스토리지 지원
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"

  service_account_role_arn = module.ebs_csi_irsa.iam_role_arn  # EBS 관리 권한 부여

  depends_on = [module.eks.eks_managed_node_groups]

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-ebs-csi-addon"
  })
}

# EFS CSI 드라이버 - 공유 파일 시스템 지원
resource "aws_eks_addon" "efs_csi_driver" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-efs-csi-driver"

  service_account_role_arn = module.efs_csi_irsa.iam_role_arn  # EFS 관리 권한 부여

  depends_on = [module.eks.eks_managed_node_groups]

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-efs-csi-addon"
  })
} 

# EKS Pod Identity를 위한 에이전트 Add-on (최신 버전 EKS에서 IRSA 대체)
# resource "aws_eks_addon" "pod_identity_agent" {
#   cluster_name             = module.eks.cluster_name
#   addon_name               = "pod-identity-agent"

#   depends_on = [module.eks.eks_managed_node_groups]

#   tags = merge(local.common_tags, {
#     Name = "${var.cluster_name}-pod-identity-agent-addon"
#   })
# }
