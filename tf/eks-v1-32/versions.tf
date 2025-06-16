/*
 * Terraform 버전 및 프로바이더 요구사항 정의
 * 
 * 이 파일은 프로젝트의 의존성을 명시합니다:
 * - Terraform 최소 버전
 * - AWS Provider 버전 제약
 * 
 * 버전 관리 전략:
 * - 최소 요구 버전만 명시하여 유연성 확보
 * - 메이저 버전 변경 시에만 업데이트 필요
 */

terraform {
  required_version = ">= 1.3.2"  # Terraform 1.3.2 이상 필요 (안정성 확보)

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.95"      # AWS Provider 5.95 이상 (EKS 1.31 지원)
    }
  }
}
