# KMS 암호화 키 설정
# 베스트 프랙티스: 모든 데이터 암호화 (전송 중, 저장 시)

# EKS 클러스터 암호화 키 - Kubernetes Secrets 암호화
resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key for ${var.cluster_name}"
  deletion_window_in_days = 7       # 실수로 삭제한 경우 복구 가능 기간
  enable_key_rotation     = true    # 연간 자동 키 로테이션 (보안 강화)

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-eks-kms-key"
  })
}

# EKS KMS 키 별칭 - 사용하기 쉬운 이름 부여
resource "aws_kms_alias" "eks" {
  name          = local.kms_key_alias
  target_key_id = aws_kms_key.eks.key_id
}

# EBS 볼륨 암호화 키 - 워커 노드 디스크 암호화
resource "aws_kms_key" "ebs" {
  description             = "EBS encryption key for EKS nodes"
  deletion_window_in_days = 7       # 실수로 삭제한 경우 복구 가능 기간
  enable_key_rotation     = true    # 연간 자동 키 로테이션

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-ebs-kms-key"
  })
}

# EBS KMS 키 별칭
resource "aws_kms_alias" "ebs" {
  name          = "alias/${var.project_name}-${var.environment}-ebs"
  target_key_id = aws_kms_key.ebs.key_id
} 