/*
 * 출력 변수 정의 파일
 * 
 * 이 파일은 Terraform 적용 후 반환될 중요한 값들을 정의합니다.
 * 다른 Terraform 모듈에서 참조하거나, CI/CD 파이프라인에서 활용할 수 있습니다.
 * 
 * 출력 구성:
 * - VPC 및 네트워킹 정보
 * - EKS 클러스터 접속 정보
 * - IRSA 구성을 위한 OIDC 정보
 * - kubectl 설정 명령어
 * 
 * 사용 예시:
 * terraform output cluster_endpoint
 * terraform output -raw configure_kubectl | bash
 */

################################################################################
# VPC Outputs
################################################################################

output "vpc_id" {
  description = "ID of the VPC where the cluster security group will be provisioned"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "intra_subnets" {
  description = "List of IDs of intra subnets"
  value       = module.vpc.intra_subnets
}

################################################################################
# EKS Cluster Outputs
################################################################################

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks_al2023.cluster_arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks_al2023.cluster_certificate_authority_data
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = module.eks_al2023.cluster_endpoint
}

output "cluster_id" {
  description = "The ID of the EKS cluster. Note: currently a value is returned only for local EKS clusters created on Outposts"
  value       = module.eks_al2023.cluster_id
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks_al2023.cluster_name
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks_al2023.cluster_oidc_issuer_url
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = module.eks_al2023.cluster_version
}

output "cluster_platform_version" {
  description = "Platform version for the EKS cluster"
  value       = module.eks_al2023.cluster_platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = module.eks_al2023.cluster_status
}

output "cluster_primary_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster"
  value       = module.eks_al2023.cluster_primary_security_group_id
}

################################################################################
# EKS Node Group Outputs
################################################################################

output "eks_managed_node_groups" {
  description = "Map of attribute maps for all EKS managed node groups created"
  value       = module.eks_al2023.eks_managed_node_groups
}

output "eks_managed_node_groups_autoscaling_group_names" {
  description = "List of the autoscaling group names created by EKS managed node groups"
  value       = module.eks_al2023.eks_managed_node_groups_autoscaling_group_names
}

################################################################################
# OIDC Provider Outputs
################################################################################

output "oidc_provider" {
  description = "The OpenID Connect identity provider (issuer URL without leading `https://`)"
  value       = module.eks_al2023.oidc_provider
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if enabled_irsa = true"
  value       = module.eks_al2023.oidc_provider_arn
}

################################################################################
# Fargate Profile Outputs
################################################################################

# output "fargate_profile_id" {
#   description = "Fargate profile information"
#   value       = module.fargate_profile.fargate_profile_id
# }

# output "iam_role_name" {
#   description = "IAM role name"
#   value       = module.fargate_profile.iam_role_name
# }

################################################################################
# Additional Outputs
################################################################################

output "region" {
  description = "AWS region"
  value       = local.region
}

output "azs" {
  description = "A list of availability zones specified as argument to this module"
  value       = local.azs
}

################################################################################
# kubectl config command
################################################################################

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${local.region} update-kubeconfig --name ${module.eks_al2023.cluster_name}"
}
