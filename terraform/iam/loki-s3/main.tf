resource "aws_iam_policy" "AWSS3EksLokiAccess" {
  name        = "AWSS3EksLokiAccess"
  path        = "/"
  description = "AWSS3EksLokiAccess"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::*",
          "arn:aws:s3:::*/*"
        ]
      },
    ]
  })
}

resource "aws_iam_role" "loki_jerry_test" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/oidc.eks.ap-northeast-2.amazonaws.com/id/${ENDPOINT}"
        },
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "oidc.eks.ap-northeast-2.amazonaws.com/id/${ENDPOINT}:aud" = "sts.amazonaws.com"
            "oidc.eks.ap-northeast-2.amazonaws.com/id/${ENDPOINT}:sub" = "system:serviceaccount:monitoring:loki"
          }
        }
      },
    ]
  })
  description           = "loki role for jerry-test eks"
  force_detach_policies = false
  managed_policy_arns   = ["arn:aws:iam::${ACCOUNT_ID}:policy/AWSS3EksLokiAccess"]
  max_session_duration  = 3600
  name                  = "loki-jerry-test"
  path                  = "/"
}
