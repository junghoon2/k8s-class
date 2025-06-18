/*
 * EKS 클러스터 정의 파일 (Amazon Linux 2023 기반)
 * 
 * 이 파일은 다음을 구성합니다:
 * - EKS 클러스터 (v1.32)
 * - Managed Node Group (AL2023 AMI)
 * - 필수 EKS Add-ons
 * - 커스텀 nodeadm 설정
 * 
 * AL2023의 장점:
 * - 향상된 보안 및 성능
 * - 최신 커널 및 라이브러리
 * - 더 나은 컨테이너 런타임 최적화
 */

module "eks_al2023" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  # 클러스터 기본 설정
  cluster_name    = "${local.name}"  # eks-test-al2023
  cluster_version = "1.32"                  # 최신 안정 버전 사용

  # EKS 애드온 구성 - 클러스터 필수 구성 요소들
  # 모든 애드온을 최신 버전으로 자동 관리
  cluster_addons = {
    coredns                = {}  # DNS 서비스 (Pod간 서비스 디스커버리)
    eks-pod-identity-agent = {}  # Pod Identity를 통한 IAM 역할 연결
    kube-proxy             = {}  # 네트워크 프록시 (Service 구현)
    vpc-cni                = {}  # AWS VPC CNI (Pod 네트워킹)
  }

  # 네트워크 구성 - VPC 모듈에서 생성된 리소스 참조
  vpc_id     = module.vpc.vpc_id         # VPC ID
  subnet_ids = module.vpc.private_subnets # Private 서브넷에만 배치 (보안)

  # 클러스터 엔드포인트 설정 - 보안을 위해 Private만 활성화
  # 주의: 이 설정으로 인해 VPC 외부에서는 클러스터 접근 불가 (VPN/Bastion 필요)
  cluster_endpoint_private_access = local.cluster_endpoint_private_access
  cluster_endpoint_public_access  = local.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = local.cluster_endpoint_public_access_cidrs

  # Terraform identity에 클러스터 관리자 권한 부여
  enable_cluster_creator_admin_permissions = true

  # Managed Node Group 구성
  # EKS가 자동으로 관리하는 워커 노드들
  eks_managed_node_groups = {
    initial = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      instance_types = ["m7i.large"]             # 범용 인스턴스 타입 (2vCPU, 8GB RAM)
      ami_type       = "AL2023_x86_64_STANDARD"  # Amazon Linux 2023 AMI 사용

      # Auto Scaling 설정
      min_size = 2    # 최소 노드 수 (가용성 보장)
      max_size = 5    # 최대 노드 수 (비용 제어)
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = 2  # 초기 노드 수 (이후 ASG가 관리)

      # nodeadm을 통한 고급 노드 설정
      # This is not required - demonstrates how to pass additional configuration to nodeadm
      # Ref https://awslabs.github.io/amazon-eks-ami/nodeadm/doc/api/
      cloudinit_pre_nodeadm = [
        {
          content_type = "application/node.eks.aws"
          content      = <<-EOT
            ---
            # nodeadm 설정: AL2023의 새로운 노드 초기화 방식
            apiVersion: node.eks.aws/v1alpha1
            kind: NodeConfig
            spec:
              kubelet:
                config:
                  # 우아한 종료를 위한 Grace Period (기본 30초에서 단축)
                  shutdownGracePeriod: 30s
                  featureGates:
                    # 클라우드 자격 증명 비활성화 (Pod Identity 사용)
                    DisableKubeletCloudCredentialProviders: true
          EOT
        }
      ]
    }
  }

  # 공통 태그 적용
  tags = var.tags
}

# module "fargate_profile" {
#   source = "terraform-aws-modules/eks/aws//modules/fargate-profile"

#   name         = "karpenter-fargate"
#   cluster_name = module.eks_al2023.cluster_name

#   subnet_ids = module.vpc.private_subnets
#   selectors = [{
#     namespace = "karpenter"
#   }]

#   tags = var.tags
# }