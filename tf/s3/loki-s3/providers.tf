provider "aws" {
  region = local.region
  profile = "jerry-test"

  # 자동으로 공통 태그를 추가한다.
  default_tags {
    tags = {
      Service      = "SNS-Test"
      Organization = "tech"
      Team         = "tech/devops"
      Resource     = "s3"
      Env          = "test"
      Terraformed  = "true"
    }
  }
}

terraform {
  required_version = ">= 1.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.57"
    }
  }

  backend "s3" {
    bucket         = "jerry-test-tfstate"
    key            = "s3/loki-jerry-dev.tfstate"
    region         = "ap-northeast-2"
    profile        = "jerry-test"
    dynamodb_table = "TerraformStateLock"
  }
}

locals {
  region          = "ap-northeast-2"
}
