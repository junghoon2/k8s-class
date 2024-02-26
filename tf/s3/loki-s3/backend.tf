terraform {
  required_version = "~> 1.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "loki-s3-tfstate"
    key            = "loki-s3.tfstate"
    encrypt        = true
    region         = "ap-northeast-2"
    profile        = "jerry-test"
    dynamodb_table = "TerraformStateLock-loki-s3"
  }
}
