provider "aws" {
  region = local.region
  # shared_config_files=["~/.aws/config"] # Or $HOME/.aws/config
  # shared_credentials_files = ["~/.aws/credentials"] # Or $HOME/.aws/credentials
  profile = "jerry-test"

  default_tags {
    tags = {
      Service     = "MyService"
      Team        = "tech/devops"
      Terraformed = "true"
    }
  }
}

locals {
  name   = "jerry-test"
  region = "ap-northeast-2"
}
