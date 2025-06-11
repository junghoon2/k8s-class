data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

# EKS 클러스터 액세스를 위한 현재 사용자 정보
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

# EKS 최적화된 AMI 정보
data "aws_ami" "eks_default" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.cluster_version}-v*"]
  }
}

# KMS 키 사용을 위한 현재 리전 정보
data "aws_region" "current" {} 