variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-prod-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.32"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "devops-test"
}

variable "enable_nat_gateway" {
  description = "Should be true to provision NAT Gateways for each of your private networks"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Should be true to create a new VPN Gateway resource and attach it to the VPC"
  type        = bool
  default     = false
}

# EKS 관리형 노드 그룹 변수
variable "eks_node_group_min_size" {
  description = "EKS 관리형 노드 그룹의 최소 노드 수"
  type        = number
  default     = 1
}

variable "eks_node_group_max_size" {
  description = "EKS 관리형 노드 그룹의 최대 노드 수"
  type        = number
  default     = 3
}

variable "eks_node_group_desired_size" {
  description = "EKS 관리형 노드 그룹의 원하는 노드 수"
  type        = number
  default     = 1
}

variable "eks_node_group_instance_types" {
  description = "EKS 관리형 노드 그룹에서 사용할 인스턴스 유형 목록"
  type        = list(string)
  default     = ["m6i.large", "m5.large", "m5a.large", "m6a.large"]  # x86 기반 안정적인 타입들
}

variable "enable_irsa" {
  description = "Whether to create OpenID Connect Provider for EKS to enable IRSA"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Owner       = "Jerry"
    Team        = "tech/devops"
  }
} 