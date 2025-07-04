# EKS 클러스터 보안 그룹
resource "aws_security_group" "eks_cluster_sg" {
  name_prefix = "${var.cluster_name}-cluster-sg"
  vpc_id      = aws_vpc.eks_vpc.id
  description = "EKS cluster security group"

  # HTTPS 트래픽 허용 (API 서버 접근용)
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.cluster_endpoint_config.public_access ? var.cluster_endpoint_config.public_access_cidrs : []
  }

  # 모든 아웃바운드 트래픽 허용
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-cluster-sg"
  })
}

# EKS 노드 그룹 보안 그룹
resource "aws_security_group" "eks_node_sg" {
  name_prefix = "${var.cluster_name}-node-sg"
  vpc_id      = aws_vpc.eks_vpc.id
  description = "EKS node group security group"

  # 노드 간 통신 허용
  ingress {
    description = "Node to node communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # 클러스터에서 노드로의 통신 허용
  ingress {
    description     = "Cluster to node communication"
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster_sg.id]
  }

  # HTTPS 통신 허용 (노드에서 클러스터로)
  ingress {
    description     = "Node to cluster API"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster_sg.id]
  }

  # SSH 접근 제거 - SSM을 통한 접근만 허용

  # 모든 아웃바운드 트래픽 허용
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-node-sg"
  })
}

# 추가 보안 그룹 규칙 - 클러스터에서 노드로의 HTTPS 통신
resource "aws_security_group_rule" "cluster_to_node_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_node_sg.id
  security_group_id        = aws_security_group.eks_cluster_sg.id
  description              = "Allow nodes to communicate with cluster API"
}
