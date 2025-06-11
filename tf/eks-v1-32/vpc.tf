# VPC 모듈 - 네트워크 기반 인프라 구성
# 베스트 프랙티스: Multi-AZ 고가용성, VPC Flow Logs, 적절한 서브넷 분리
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.vpc_name
  cidr = var.vpc_cidr

  azs                = local.azs                 # 3개 가용영역 사용
  private_subnets    = local.private_subnets     # 워커 노드용 프라이빗 서브넷
  public_subnets     = local.public_subnets      # 로드밸런서용 퍼블릭 서브넷
  intra_subnets      = local.intra_subnets       # 컨트롤 플레인용 격리된 서브넷

  # NAT Gateway 설정 - 프라이빗 서브넷의 인터넷 접근을 위함
  enable_nat_gateway   = var.enable_nat_gateway
  # 모든 가용 영역에 NAT 게이트웨이를 만들지 않고, 비용 효율성을 위해 단일 NAT 게이트웨이를 사용하도록 설정합니다.
  single_nat_gateway = true
#   single_nat_gateway   = false                   # Multi-AZ 고가용성을 위해 각 AZ마다 NAT Gateway 생성
  
  # DNS 설정 - EKS에서 필수
  enable_dns_hostnames = true                    # DNS 호스트명 활성화
  enable_dns_support   = true                    # DNS 해석 활성화

  # VPC Flow Logs - 보안 모니터링 및 트러블슈팅용
  # 베스트 프랙티스: 모든 네트워크 트래픽 로깅으로 보안 감시
#   enable_flow_log                      = true
#   create_flow_log_cloudwatch_iam_role  = true
#   create_flow_log_cloudwatch_log_group = true
#   flow_log_cloudwatch_log_group_retention_in_days = 30  # 비용 고려한 보관 기간

  # VPC Endpoints 설정 - AWS 서비스와의 프라이빗 통신
  # 주석 처리된 S3, DynamoDB는 필요시 활성화 (추가 비용 발생)
  # enable_s3_endpoint       = true
  # enable_dynamodb_endpoint = true
  
  # 퍼블릭 서브넷 태그 - ALB(Application Load Balancer) 배치용
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  # 프라이빗 서브넷 태그 - NLB(Network Load Balancer) 배치용
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  # EKS 클러스터 태그 - AWS Load Balancer Controller가 자동으로 서브넷 발견
  tags = merge(local.common_tags, {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

# 추가 VPC Endpoints - 보안 강화를 위한 프라이빗 통신
# 베스트 프랙티스: 모든 AWS 서비스 통신을 VPC 내부로 제한하여 보안 강화

# ECR API 엔드포인트 - 컨테이너 이미지 메타데이터 API 접근
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  
  private_dns_enabled = true  # 프라이빗 DNS 활성화로 기존 API 호출 변경 없이 사용
  
  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-ecr-api-endpoint"
  })
}

# ECR Docker 엔드포인트 - 컨테이너 이미지 다운로드
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  
  private_dns_enabled = true
  
  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-ecr-dkr-endpoint"
  })
}

# EC2 엔드포인트 - 인스턴스 메타데이터 및 관리 API
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  
  private_dns_enabled = true
  
  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-ec2-endpoint"
  })
}

# CloudWatch Logs 엔드포인트 - 로그 전송용
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  
  private_dns_enabled = true
  
  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-logs-endpoint"
  })
}

# STS 엔드포인트 - IAM 토큰 서비스 (IRSA에 필수)
resource "aws_vpc_endpoint" "sts" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  
  private_dns_enabled = true
  
  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-sts-endpoint"
  })
} 