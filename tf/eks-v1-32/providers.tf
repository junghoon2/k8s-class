terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }

#   backend "s3" {
#     # Terraform 상태 파일을 저장할 S3 버킷 이름입니다.
#     # 이 버킷은 미리 생성되어 있어야 합니다.
#     bucket = "jerry-test-tfstate"  # <<<--- 실제 S3 버킷 이름으로 변경하세요!

#     # 필수: S3 버킷 내에서 상태 파일이 저장될 경로 및 파일 이름입니다.
#     key = "eks-clusters/new-vpc-demo/terraform.tfstate" # <<<--- 환경에 맞게 경로를 수정하세요.

#     # 필수: S3 버킷이 위치한 AWS 리전입니다.
#     region = "ap-northeast-2" # <<<--- 실제 S3 버킷 리전으로 변경하세요.

#     # 권장: 상태 파일 잠금을 위한 DynamoDB 테이블 이름입니다.
#     # 이 테이블은 미리 생성되어 있어야 하며, 파티션 키는 "LockID" (문자열 타입)여야 합니다.
#     dynamodb_table = "your-terraform-lock-table-name" # <<<--- 실제 DynamoDB 테이블 이름으로 변경하세요!

#     # 권장: S3 버킷에 저장되는 상태 파일에 대한 서버 측 암호화를 활성화합니다.
#     encrypt = true
#   }

}

provider "aws" {
  region = var.region
  profile = "playground"

  default_tags {
    tags = merge(var.tags, {
      ManagedBy = "Terraform"
      Project   = var.project_name
    })
  }
}

# Kubernetes Provider Configuration
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}
