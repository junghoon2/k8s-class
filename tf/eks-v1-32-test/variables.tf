# EKS 클러스터 기본 설정 변수
variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
  default     = "test-eks-cluster"
}

variable "cluster_version" {
  description = "EKS 클러스터 Kubernetes 버전"
  type        = string
  default     = "1.32"
}

variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

# VPC 네트워크 설정 변수
variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.101.0.0/16"
}

variable "availability_zones" {
  description = "사용할 가용 영역 목록"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
}

variable "private_subnet_cidrs" {
  description = "프라이빗 서브넷 CIDR 블록 목록 (/20)"
  type        = list(string)
  default     = ["10.101.0.0/20", "10.101.16.0/20", "10.101.32.0/20"]
}

variable "public_subnet_cidrs" {
  description = "퍼블릭 서브넷 CIDR 블록 목록 (/24)"
  type        = list(string)
  default     = ["10.101.240.0/24", "10.101.241.0/24", "10.101.242.0/24"]
}

# EKS 클러스터 엔드포인트 접근 설정
variable "cluster_endpoint_config" {
  description = "클러스터 엔드포인트 접근 설정"
  type = object({
    private_access      = bool
    public_access       = bool
    public_access_cidrs = list(string)
  })
  default = {
    private_access      = true
    public_access       = true
    public_access_cidrs = ["0.0.0.0/0"] # 개발환경용 - 프로덕션에서는 특정 IP로 제한 필요
  }
}

# 로깅 설정 변수
variable "enable_cluster_logging" {
  description = "EKS 클러스터 로깅 활성화 여부"
  type        = bool
  default     = false # 개발환경용 - 프로덕션에서는 true 권장
}

variable "cluster_enabled_log_types" {
  description = "활성화할 클러스터 로그 타입"
  type        = list(string)
  default     = ["audit", "api", "authenticator", "controllerManager", "scheduler"]
}

# 노드 그룹 설정 변수
variable "node_group_config" {
  description = "매니지드 노드 그룹 설정"
  type = object({
    instance_types = list(string)
    ami_type      = string
    capacity_type = string
    disk_size     = number
    desired_size  = number
    max_size      = number
    min_size      = number
  })
  default = {
    instance_types = ["t4g.large"] # ARM64 인스턴스
    ami_type      = "BOTTLEROCKET_ARM_64"
    capacity_type = "ON_DEMAND"
    disk_size     = 50
    desired_size  = 2
    max_size      = 5
    min_size      = 2
  }
}

# 태그 설정
variable "common_tags" {
  description = "모든 리소스에 적용할 공통 태그"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "test-eks-cluster"
    ManagedBy   = "terraform"
    Team        = "DevSecOps"
    Owner       = "jerry"
  }
}

# 관리자 권한 설정
variable "enable_cluster_creator_admin_permissions" {
  description = "클러스터 생성자에게 관리자 권한 부여"
  type        = bool
  default     = true
}
