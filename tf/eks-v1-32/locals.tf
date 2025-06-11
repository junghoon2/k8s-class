locals {
  # Common tags for all resources
  common_tags = merge(var.tags, {
    Cluster     = var.cluster_name
    Environment = var.environment
    Project     = var.project_name
  })

  # Availability zones for the region
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
  
  # VPC configuration
  vpc_name = "${var.project_name}-${var.environment}-vpc"
  
  # 서브넷 구성 - Private는 /20, Public/Intra는 /24로 설정
  # 베스트 프랙티스: 워커 노드가 배치될 Private 서브넷만 대용량 IP 할당
  # VPC CIDR: 10.10.0.0/16 (65,536개 IP)
  
  # Private 서브넷 (워커 노드용) - /20 (4,094개 IP, 대규모 Pod 지원)
  private_subnets = [
    cidrsubnet(var.vpc_cidr, 4, 1),   # 10.10.16.0/20
    cidrsubnet(var.vpc_cidr, 4, 2),   # 10.10.32.0/20
    cidrsubnet(var.vpc_cidr, 4, 3),   # 10.10.48.0/20
  ]
  
  # Public 서브넷 (ALB, NAT Gateway용) - /24 (254개 IP, 충분함)
  public_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 1),   # 10.10.1.0/24
    cidrsubnet(var.vpc_cidr, 8, 2),   # 10.10.2.0/24
    cidrsubnet(var.vpc_cidr, 8, 3),   # 10.10.3.0/24
  ]
  
  # Intra 서브넷 (DB, 내부 서비스용) - /24 (254개 IP, 충분함)
  intra_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 101), # 10.10.101.0/24
    cidrsubnet(var.vpc_cidr, 8, 102), # 10.10.102.0/24
    cidrsubnet(var.vpc_cidr, 8, 103), # 10.10.103.0/24
  ]

  # KMS key alias
  kms_key_alias = "alias/${var.project_name}-${var.environment}-eks"
  
  # EKS cluster endpoint configuration - Private only for security
  cluster_endpoint_private_access = false
  cluster_endpoint_public_access  = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
} 