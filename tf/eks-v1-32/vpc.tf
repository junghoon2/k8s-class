################################################################################
# VPC 모듈 구성
# 
# 3-tier 아키텍처로 구성:
# - Public Subnet: 로드밸런서용 (/24, 각 AZ당 256개 IP)
# - Private Subnet: 워커 노드용 (/20, 각 AZ당 4,096개 IP) 
# - Intra Subnet: 데이터베이스등 격리된 리소스용 (/24)
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  # Private 서브넷: /20 블록으로 노드 확장성 고려 (k=0,1,2 → 0.0/20, 16.0/20, 32.0/20)
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  # Public 서브넷: /24 블록으로 ALB/NLB용 (k+48 → 48.0/24, 49.0/24, 50.0/24)
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  # Intra 서브넷: 인터넷 접근 불가, DB나 캐시용 (k+52 → 52.0/24, 53.0/24, 54.0/24)
  intra_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 52)]

  # NAT 게이트웨이 설정 - 비용 절약을 위해 단일 NAT 사용
  enable_nat_gateway = true
  single_nat_gateway = true  # 프로덕션에서는 가용성을 위해 false 권장

  # EKS 로드밸런서 자동 검색을 위한 서브넷 태깅
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1  # ALB/Classic LB 배치용
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1  # Internal LB 배치용
  }

  # DNS 설정 - EKS에서 필수
  enable_dns_hostnames = true                    # DNS 호스트명 활성화
  enable_dns_support   = true                    # DNS 해석 활성화

  # EKS 클러스터 태그 - AWS Load Balancer Controller가 자동으로 서브넷 발견
  tags = merge(var.tags, {
    "kubernetes.io/cluster/${local.name}" = "shared"
  })

}
