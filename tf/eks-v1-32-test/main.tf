# Terraform 및 Provider 설정
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
  }
}

# AWS Provider 설정
provider "aws" {
  region = var.region
  profile = "playground"

  default_tags {
    tags = var.common_tags
  }
}

# 현재 AWS 계정 정보 가져오기
data "aws_caller_identity" "current" {}

# EKS 클러스터 생성
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.eks_cluster_role.arn

  # VPC 설정
  vpc_config {
    subnet_ids              = concat(aws_subnet.private_subnets[*].id, aws_subnet.public_subnets[*].id)
    endpoint_private_access = var.cluster_endpoint_config.private_access
    endpoint_public_access  = var.cluster_endpoint_config.public_access
    public_access_cidrs     = var.cluster_endpoint_config.public_access_cidrs
    security_group_ids      = [aws_security_group.eks_cluster_sg.id]
  }

  # 로깅 설정
  enabled_cluster_log_types = var.enable_cluster_logging ? var.cluster_enabled_log_types : []

  # 암호화 설정
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks_kms_key.arn
    }
    resources = ["secrets"]
  }

  # 접근 설정
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  }

  tags = merge(var.common_tags, {
    Name = var.cluster_name
  })

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_cloudwatch_log_group.eks_cluster_logs
  ]
}

# CloudWatch 로그 그룹 (로깅 활성화시에만)
resource "aws_cloudwatch_log_group" "eks_cluster_logs" {
  count = var.enable_cluster_logging ? 1 : 0
  
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7 # 개발환경용 짧은 보존 기간

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-logs"
  })
}

# KMS 키 생성 (암호화용)
resource "aws_kms_key" "eks_kms_key" {
  description             = "EKS cluster ${var.cluster_name} encryption key"
  deletion_window_in_days = 7 # 개발환경용 짧은 삭제 대기 기간

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-kms-key"
  })
}

# KMS 키 별칭
resource "aws_kms_alias" "eks_kms_alias" {
  name          = "alias/${var.cluster_name}-eks-key"
  target_key_id = aws_kms_key.eks_kms_key.key_id
}

# EKS 매니지드 노드 그룹 생성
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.private_subnets[*].id

  # 인스턴스 설정
  instance_types = var.node_group_config.instance_types
  ami_type       = var.node_group_config.ami_type
  capacity_type  = var.node_group_config.capacity_type
  disk_size      = var.node_group_config.disk_size

  # 스케일링 설정
  scaling_config {
    desired_size = var.node_group_config.desired_size
    max_size     = var.node_group_config.max_size
    min_size     = var.node_group_config.min_size
  }

  # 업데이트 설정
  update_config {
    max_unavailable_percentage = 25
  }

  # 원격 접근 설정 제거 - SSM을 통한 접근만 허용

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-node-group"
  })

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]

  # 노드 그룹 생성 시 인스턴스 교체 방지
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# Kubernetes Provider 설정
provider "kubernetes" {
  host                   = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks_cluster.name, "--region", var.region]
  }
}
