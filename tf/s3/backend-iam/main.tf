provider "aws"{
 region = "ap-northeast-2"
 profile = "jerry-test"
  default_tags {
    tags = {
      Service           = "levvels"
      Team              = "tech/devops"
      Terraformed       = "true"
    }
  }
}

resource "aws_s3_bucket" "tfstate"{
 bucket = "iam-tfstate"
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
 name= "TerraformStateLock-loki-s3"
 hash_key = "LockID"
 billing_mode = "PAY_PER_REQUEST"

 attribute{
  name = "LockID"
  type = "S"
 }
}
