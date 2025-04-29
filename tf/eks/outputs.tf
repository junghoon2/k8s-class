# VPC Outputs
output "vpc_id" {
  description = "생성된 VPC의 ID"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "생성된 프라이빗 서브넷 ID 목록"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "생성된 퍼블릭 서브넷 ID 목록"
  value       = module.vpc.public_subnets
}

# EKS Cluster Outputs
output "cluster_endpoint" {
  description = "EKS 클러스터의 API 서버 엔드포인트"
  value       = module.eks.cluster_endpoint
}

output "cluster_id" {
  description = "EKS 클러스터의 ID"
  value       = module.eks.cluster_id
}

output "cluster_name" {
  description = "EKS 클러스터의 이름"
  value       = module.eks.cluster_name
}

output "cluster_oidc_issuer_url" {
  description = "EKS 클러스터의 OIDC 발급자 URL (IRSA에 사용)"
  value       = module.eks.cluster_oidc_issuer_url
}

output "cluster_certificate_authority_data" {
  description = "EKS 클러스터의 인증 기관(CA) 데이터 (base64 인코딩)"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true # 민감한 정보이므로 출력 시 숨김 처리될 수 있음
}

output "eks_managed_node_group_main_iam_role_arn" {
  description = "EKS 관리형 노드 그룹 'main'의 IAM 역할 ARN"
  value       = module.eks.eks_managed_node_groups["main"].iam_role_arn
}

output "configure_kubectl" {
  description = "kubectl을 EKS 클러스터에 연결하기 위한 명령어"
  value = format("aws eks update-kubeconfig --name %s --region %s", module.eks.cluster_name, var.region)
} 