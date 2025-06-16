/*
 * EKS 클러스터 구성을 위한 메인 파일
 * 
 * 이 파일은 다음 리소스들을 정의합니다:
 * - AWS Provider 설정
 * - VPC 및 서브넷 구성 (Public, Private, Intra)
 * - 가용 영역(AZ) 자동 선택
 * 
 * Author: Jerry
 * Purpose: EKS v1.32 클러스터 구축을 위한 인프라 기반 설정
 */

# AWS 프로바이더 설정 - 리전은 로컬 변수에서 참조
provider "aws" {
  region = local.region
  profile = "playground"

  default_tags {
    tags = var.tags
  }

}

# 사용 가능한 가용 영역 데이터 소스 - 로컬 존은 제외
# opt-in-not-required: 기본적으로 활성화된 AZ만 선택 (로컬 존 제외)
data "aws_availability_zones" "available" {
  # Exclude local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# 로컬 변수 정의 - 환경 전반에서 사용되는 공통 설정
locals {
  name   = "eks-test"              # 리소스 명명 규칙의 기준이 되는 이름
  region = "ap-northeast-2"        # 서울 리전 사용

  vpc_cidr = "10.101.0.0/16"       # VPC CIDR 블록 (65,536개 IP)
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)  # 첫 3개 AZ 사용

  # EKS cluster endpoint configuration - Private only for security
  cluster_endpoint_private_access = false
  cluster_endpoint_public_access  = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  # 모든 리소스에 적용할 공통 태그
  tags = {
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
    Terraform   = "true"
    Owner       = "Jerry"
    Team        = "tech/devops"
  }
}
