# 클러스터 정보 출력
output "cluster_name" {
  description = "EKS 클러스터 이름"
  value       = aws_eks_cluster.eks_cluster.name
}

output "cluster_endpoint" {
  description = "EKS 클러스터 엔드포인트"
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_version" {
  description = "EKS 클러스터 Kubernetes 버전"
  value       = aws_eks_cluster.eks_cluster.version
}

output "cluster_arn" {
  description = "EKS 클러스터 ARN"
  value       = aws_eks_cluster.eks_cluster.arn
}

output "cluster_certificate_authority_data" {
  description = "EKS 클러스터 인증서 데이터"
  value       = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "EKS 클러스터 보안 그룹 ID"
  value       = aws_security_group.eks_cluster_sg.id
}

# VPC 정보 출력
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.eks_vpc.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR 블록"
  value       = aws_vpc.eks_vpc.cidr_block
}

output "private_subnet_ids" {
  description = "프라이빗 서브넷 ID 목록"
  value       = aws_subnet.private_subnets[*].id
}

output "public_subnet_ids" {
  description = "퍼블릭 서브넷 ID 목록"
  value       = aws_subnet.public_subnets[*].id
}

# 노드 그룹 정보 출력
output "node_group_arn" {
  description = "EKS 노드 그룹 ARN"
  value       = aws_eks_node_group.eks_node_group.arn
}

output "node_group_status" {
  description = "EKS 노드 그룹 상태"
  value       = aws_eks_node_group.eks_node_group.status
}

output "node_security_group_id" {
  description = "EKS 노드 보안 그룹 ID"
  value       = aws_security_group.eks_node_sg.id
}

# IAM 역할 정보 출력
output "cluster_iam_role_arn" {
  description = "EKS 클러스터 IAM 역할 ARN"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "node_iam_role_arn" {
  description = "EKS 노드 IAM 역할 ARN"
  value       = aws_iam_role.eks_node_role.arn
}

# KMS 키 정보 출력
output "kms_key_id" {
  description = "EKS 암호화용 KMS 키 ID"
  value       = aws_kms_key.eks_kms_key.key_id
}

output "kms_key_arn" {
  description = "EKS 암호화용 KMS 키 ARN"
  value       = aws_kms_key.eks_kms_key.arn
}

# kubectl 설정 명령어 출력
output "kubectl_config_command" {
  description = "kubectl 설정을 위한 AWS CLI 명령어"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.eks_cluster.name}"
}

# 클러스터 접속 정보
output "cluster_access_info" {
  description = "클러스터 접속 정보"
  value = {
    cluster_name = aws_eks_cluster.eks_cluster.name
    region       = var.region
    endpoint     = aws_eks_cluster.eks_cluster.endpoint
    kubectl_command = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.eks_cluster.name}"
  }
}

# SSM을 통한 노드 접속 정보
output "ssm_access_info" {
  description = "SSM을 통한 노드 접속 정보"
  value = {
    ssm_command = "aws ssm start-session --target <instance-id>"
    list_instances_command = "aws ec2 describe-instances --filters 'Name=tag:aws:eks:cluster-name,Values=${aws_eks_cluster.eks_cluster.name}' --query 'Reservations[].Instances[].{InstanceId:InstanceId,State:State.Name,Name:Tags[?Key==`Name`].Value|[0]}' --output table"
    note = "노드 인스턴스 ID를 확인한 후 SSM Session Manager를 통해 접속하세요"
  }
}
