variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

# VPC 변수
variable "vpc_cidr_block" {
  description = "생성할 VPC의 CIDR 블록"
  type        = string
  default     = "10.10.0.0/16"
}

variable "vpc_availability_zones" {
  description = "VPC 서브넷을 생성할 가용 영역 목록"
  type        = list(string)
  # 리전에서 사용 가능한 AZ로 변경할 수 있습니다.
  default     = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
}

variable "vpc_private_subnet_cidrs" {
  description = "생성할 프라이빗 서브넷의 CIDR 블록 목록 (가용 영역 수와 일치해야 함)"
  type        = list(string)
  # 프라이빗 서브넷 CIDR을 /20으로 수정
  default     = ["10.10.0.0/20", "10.10.16.0/20", "10.10.32.0/20"]
}

variable "vpc_public_subnet_cidrs" {
  description = "생성할 퍼블릭 서브넷의 CIDR 블록 목록 (가용 영역 수와 일치해야 함)"
  type        = list(string)
  default     = ["10.10.101.0/24", "10.10.102.0/24", "10.10.103.0/24"]
}

# EKS 클러스터 변수
variable "cluster_name" {
  description = "생성할 EKS 클러스터의 이름"
  type        = string
  default     = "eks-new-vpc-demo"
}

variable "cluster_version" {
  description = "EKS 클러스터의 Kubernetes 버전"
  type        = string
  default     = "1.31"
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
  default     = ["m7i.large"]
}

# 공통 변수
variable "tags" {
  description = "모든 AWS 리소스에 적용할 공통 태그"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "eks-new-vpc-demo"
    Terraform   = "true"
    Owner       = "Jerry"
    Team        = "tech/devops"
  }
} 