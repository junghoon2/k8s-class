# VPC Endpoints용 보안 그룹
# 베스트 프랙티스: 최소 권한 원칙 - VPC 내부에서만 HTTPS 접근 허용
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.cluster_name}-vpc-endpoints-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for VPC endpoints"

  # VPC 내부에서만 HTTPS 포트로 접근 허용
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]  # VPC CIDR 범위에서만 접근 허용
  }

  # 모든 아웃바운드 트래픽 허용 (VPC Endpoint는 AWS 서비스로만 통신)
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-vpc-endpoints-sg"
  })
}

# EKS 클러스터 추가 보안 그룹
# 베스트 프랙티스: 노드 간 통신 및 NodePort 서비스 지원
resource "aws_security_group" "additional_sg" {
  name_prefix = "${var.cluster_name}-additional-"
  vpc_id      = module.vpc.vpc_id
  description = "EKS cluster additional security group"

  # 같은 보안 그룹 내 노드 간 모든 통신 허용
  # EKS 노드 간 내부 통신을 위해 필요
  ingress {
    description = "Node to node all ports/protocols"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true  # 같은 보안 그룹 내에서만 통신 허용
  }

  # NodePort 서비스 포트 범위 허용
  # Kubernetes NodePort 서비스 (30000-32767) 접근용
  ingress {
    description = "Node port services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]  # VPC 내부에서만 접근 허용
  }

  # 모든 아웃바운드 트래픽 허용
  # 노드가 인터넷 및 AWS 서비스에 접근하기 위해 필요
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-additional-sg"
  })
}

# Security Group for Node Groups
resource "aws_security_group" "node_group_sg" {
  name_prefix = "${var.cluster_name}-node-group-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for EKS node groups"

  ingress {
    description = "Self"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description = "Cluster API to node groups"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [module.eks.cluster_primary_security_group_id]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-node-group-sg"
  })
} 