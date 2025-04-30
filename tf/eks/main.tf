# ==========================================================================
# Terraform Backend Configuration (S3)
# ==========================================================================
# Terraform 상태 파일을 S3 버킷에 저장하고, DynamoDB를 사용하여 상태 잠금을 관리합니다.
# 이를 통해 여러 사용자가 협업하거나 CI/CD 환경에서 안전하게 Terraform을 실행할 수 있습니다.
# terraform {
#   backend "s3" {
#     # 필수: Terraform 상태 파일을 저장할 S3 버킷 이름입니다.
#     # 이 버킷은 미리 생성되어 있어야 합니다.
#     bucket = "jerry-test-tfstate"  # <<<--- 실제 S3 버킷 이름으로 변경하세요!

#     # 필수: S3 버킷 내에서 상태 파일이 저장될 경로 및 파일 이름입니다.
#     key = "eks-clusters/new-vpc-demo/terraform.tfstate" # <<<--- 환경에 맞게 경로를 수정하세요.

#     # 필수: S3 버킷이 위치한 AWS 리전입니다.
#     region = "ap-northeast-2" # <<<--- 실제 S3 버킷 리전으로 변경하세요.

#     # 권장: 상태 파일 잠금을 위한 DynamoDB 테이블 이름입니다.
#     # 이 테이블은 미리 생성되어 있어야 하며, 파티션 키는 "LockID" (문자열 타입)여야 합니다.
#     dynamodb_table = "your-terraform-lock-table-name" # <<<--- 실제 DynamoDB 테이블 이름으로 변경하세요!

#     # 권장: S3 버킷에 저장되는 상태 파일에 대한 서버 측 암호화를 활성화합니다.
#     encrypt = true
#   }
# }

# ==========================================================================
# AWS Provider Configuration
# ==========================================================================
# Terraform이 AWS와 상호작용하기 위한 기본 설정을 정의합니다.
# 사용할 AWS 리전(region)을 지정합니다.
provider "aws" {
  region = var.region
  profile = "playground"
}

# ==========================================================================
# VPC (Virtual Private Cloud) Module
# ==========================================================================
# EKS 클러스터를 위한 네트워크 환경(VPC, 서브넷 등)을 생성합니다.
# Terraform AWS VPC 모듈을 사용하여 표준적이고 재사용 가능한 방식으로 VPC를 구성합니다.
# 모듈 소스: https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  # 모듈 버전을 지정하여 예상치 못한 변경을 방지합니다.
  version = "~> 5.0"

  # 생성될 VPC의 이름입니다. 클러스터 이름과 연관지어 관리 편의성을 높입니다.
  name = "${var.cluster_name}-vpc"
  # VPC에서 사용할 기본 IP 주소 범위(CIDR 블록)입니다.
  cidr = var.vpc_cidr_block

  # VPC 내에서 사용할 AWS 가용 영역(Availability Zones) 목록입니다.
  # 여러 가용 영역에 서브넷을 분산시켜 고가용성을 확보합니다.
  azs             = var.vpc_availability_zones
  # 각 가용 영역에 생성될 프라이빗 서브넷의 CIDR 블록 목록입니다.
  # 프라이빗 서브넷은 외부에서 직접 접근할 수 없으며, 워커 노드 등 내부 리소스를 배치합니다.
  private_subnets = var.vpc_private_subnet_cidrs
  # 각 가용 영역에 생성될 퍼블릭 서브넷의 CIDR 블록 목록입니다.
  # 퍼블릭 서브넷은 인터넷 게이트웨이를 통해 외부와 직접 통신이 가능하며, 로드 밸런서 등을 배치합니다.
  public_subnets  = var.vpc_public_subnet_cidrs

  # --------------------------------------------------------------------------
  # VPC 모듈 상세 설정
  # --------------------------------------------------------------------------
  # 프라이빗 서브넷의 인스턴스가 외부 인터넷으로 아웃바운드 통신을 할 수 있도록 NAT 게이트웨이를 활성화합니다.
  enable_nat_gateway = true
  # 모든 가용 영역에 NAT 게이트웨이를 만들지 않고, 비용 효율성을 위해 단일 NAT 게이트웨이를 사용하도록 설정합니다.
  single_nat_gateway = true
  # VPC 내 인스턴스에 퍼블릭 DNS 호스트 이름을 자동으로 할당하도록 설정합니다.
  enable_dns_hostnames = true

  # --------------------------------------------------------------------------
  # EKS 연동 및 서브넷 이름 지정을 위한 태그 설정
  # --------------------------------------------------------------------------
  # EKS 클러스터가 서브넷을 인식하고 로드 밸런서(ELB) 등을 자동으로 프로비저닝할 수 있도록
  # 필수 태그들을 퍼블릭 서브넷과 프라이빗 서브넷에 각각 추가합니다.
  # 또한, 'Name' 태그를 추가하여 각 서브넷에 명시적인 이름을 부여합니다. (모듈이 자동으로 AZ 접미사를 추가합니다)
  public_subnet_tags = merge(
    {
      # 클러스터 오토스케일러나 로드 밸런서 컨트롤러 등이 이 태그를 사용하여 서브넷을 식별합니다.
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      # 이 태그는 AWS 로드 밸런서 컨트롤러가 외부 로드 밸런서(ALB/NLB)를 배치할 퍼블릭 서브넷을 식별하는 데 사용됩니다.
      "kubernetes.io/role/elb"                  = "1"
    },
    {
      # 퍼블릭 서브넷 이름 지정
      Name = "${var.cluster_name}-public"
    }
  )

  private_subnet_tags = merge(
    {
      # 클러스터 오토스케일러나 로드 밸런서 컨트롤러 등이 이 태그를 사용하여 서브넷을 식별합니다.
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      # 이 태그는 AWS 로드 밸런서 컨트롤러가 내부 로드 밸런서를 배치할 프라이빗 서브넷을 식별하는 데 사용됩니다.
      "kubernetes.io/role/internal-elb"         = "1"
    },
    {
      # 프라이빗 서브넷 이름 지정
      Name = "${var.cluster_name}-private"
    }
  )

  # VPC 및 관련 리소스(서브넷, 라우팅 테이블 등)에 적용될 공통 태그입니다.
  # 기존의 공통 태그(var.tags)와 VPC 특정 태그를 병합하여 적용합니다.
  tags = merge(
    var.tags,
    { Name = "${var.cluster_name}-vpc" }
  )
}

# ==========================================================================
# EKS (Elastic Kubernetes Service) Cluster Module
# ==========================================================================
# AWS EKS 클러스터와 관련 리소스(관리형 노드 그룹 등)를 생성합니다.
# Terraform AWS EKS 모듈을 사용하여 복잡한 EKS 구성을 단순화합니다.
# 모듈 소스: https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  # 모듈 버전을 지정하여 예상치 못한 변경을 방지합니다.
  version = "~> 20.0"

  # --------------------------------------------------------------------------
  # 클러스터 기본 정보
  # --------------------------------------------------------------------------
  # 생성될 EKS 클러스터의 고유한 이름입니다.
  cluster_name    = var.cluster_name
  # 클러스터에서 사용할 Kubernetes 버전입니다.
  cluster_version = var.cluster_version

  # Give the Terraform identity admin access to the cluster
  # which will allow resources to be deployed into the cluster
  enable_cluster_creator_admin_permissions = true

  # --------------------------------------------------------------------------
  # API 서버 엔드포인트 접근 제어
  # --------------------------------------------------------------------------
  # true로 설정하면 인터넷에서 Kubernetes API 서버 엔드포인트에 접근할 수 있습니다.
  # false로 설정하면 VPC 내부에서만 접근 가능합니다 (프라이빗 엔드포인트).
  # 보안 요구 사항에 따라 신중하게 결정해야 합니다.
  # 현재는 테스트 환경이므로 true로 설정
  # 프로덕션 환경에서는 false로 설정하고, VPN 사용하는 것을 권장합니다.
  cluster_endpoint_public_access = true
  # public_access_cidrs = ["0.0.0.0/0"] # 필요시 특정 IP 대역만 접근 허용하도록 설정

  # EKS Addons
  # 관리형 EKS 애드온을 정의합니다. 빈 객체({})는 기본 설정을 사용함을 의미합니다.
  cluster_addons = {
    coredns                = {} # 클러스터 DNS 확인을 위한 CoreDNS
    eks-pod-identity-agent = {} # EKS Pod Identity를 위한 에이전트 (최신 버전 EKS에서 IRSA 대체)
    kube-proxy             = {} # 네트워크 프록시 및 서비스 로드 밸런싱
    vpc-cni                = {} # AWS VPC 네트워킹 통합
    aws-ebs-csi-driver     = {} # EBS 볼륨을 PV로 사용하기 위한 CSI 드라이버
  }

  # --------------------------------------------------------------------------
  # 클러스터 네트워크 설정
  # --------------------------------------------------------------------------
  # 클러스터를 배포할 VPC의 ID입니다. 위에서 생성한 VPC 모듈의 출력값을 사용합니다.
  vpc_id                   = module.vpc.vpc_id
  # 클러스터 워커 노드 및 Kubernetes 리소스(Pod 등)가 배치될 서브넷 목록입니다.
  # 일반적으로 보안을 위해 프라이빗 서브넷을 사용합니다.
  subnet_ids               = module.vpc.private_subnets
  # Kubernetes 컨트롤 플레인(마스터 노드) ENI가 배치될 서브넷 목록입니다.
  # 컨트롤 플레인 또한 프라이빗 서브넷에 두어 보안을 강화합니다.
  control_plane_subnet_ids = module.vpc.private_subnets

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
      ami_type       = "BOTTLEROCKET_x86_64"
      # 노드 그룹에서 사용할 EC2 인스턴스 유형 목록입니다.
      instance_types = var.eks_node_group_instance_types
      # 인스턴스 구매 옵션입니다. 'ON_DEMAND' 또는 'SPOT'을 사용할 수 있습니다.
      capacity_type  = "ON_DEMAND"
      # 노드 그룹의 인스턴스가 배치될 서브넷 ID 목록입니다. EKS 클러스터와 동일한 프라이빗 서브넷을 사용합니다.
      subnet_ids     = module.vpc.private_subnets

      # 노드의 루트 볼륨 크기 (GiB)
      disk_size = 50

      # Bottlerocket AMI 사용 시 추가 설정 예시 (선택 사항)
      # Ref https://bottlerocket.dev/en/os/1.19.x/api/settings/
      bootstrap_extra_args = <<-EOT
        # 관리 컨테이너(SSH 접근) 비활성화
        [settings.host-containers.admin]
        enabled = false

        # 제어 컨테이너(SSM 접근) 활성화 (기본값)
        [settings.host-containers.control]
        enabled = true

        # 커널 보안 설정 예시
        [settings.kernel]
        lockdown = "integrity"
      EOT
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

  # --------------------------------------------------------------------------
  # 기타 설정
  # --------------------------------------------------------------------------
  # EKS 클러스터 및 관련 리소스에 적용될 공통 태그입니다.
  tags = var.tags

  # --------------------------------------------------------------------------
  # 의존성 설정
  # --------------------------------------------------------------------------
  # VPC 및 관련 네트워크 리소스 생성이 완료된 후에 EKS 클러스터 생성을 시작하도록 명시적인 의존성을 설정합니다.
  depends_on = [module.vpc]
}

