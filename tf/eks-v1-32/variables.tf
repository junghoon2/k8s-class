/*
 * 입력 변수 정의 파일
 * 
 * 이 파일은 Terraform 구성에서 사용할 변수들을 정의합니다.
 * 현재는 기본 태그만 정의되어 있으며, 필요에 따라 확장 가능합니다.
 * 
 * 변수 사용 전략:
 * - 환경별 차이가 있는 값들만 변수화
 * - 기본값을 통해 간편한 사용성 제공
 */

# 모든 리소스에 적용할 공통 태그 변수
# 리소스 관리, 비용 추적, 소유권 명시에 활용
variable "tags" {
  description = "A map of tags to add to all resources"  # 모든 리소스에 추가할 태그 맵
  type        = map(string)
  default = {
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
    Terraform   = "true"        # Terraform으로 관리됨을 표시
    Owner       = "Jerry"       # 리소스 소유자
    Team        = "tech/devops" # 담당 팀
  }
} 