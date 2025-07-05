# AWS 프로바이더 설정 - 서울 리전 사용
provider "aws" {
  region  = "ap-northeast-2"
  profile = "playground"

  default_tags {
    tags = var.tags
  }
}

# 모든 리소스에 적용할 공통 태그 변수
# 리소스 관리, 비용 추적, 소유권 명시에 활용
variable "tags" {
  description = "A map of tags to add to all resources"  # 모든 리소스에 추가할 태그 맵
  type        = map(string)
  default = {
    Terraform   = "true"        # Terraform으로 관리됨을 표시
    Owner       = "Jerry"       # 리소스 소유자
    Team        = "tech/devops" # 담당 팀
  }
} 

# 변수 정의
variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
  default     = "test-eks-cluster"
}

variable "karpenter_namespace" {
  description = "Karpenter 네임스페이스"
  type        = string
  default     = "karpenter"
}

# 데이터 소스
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# EKS 클러스터 정보 조회 (OIDC 프로바이더 정보 필요)
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

# Karpenter 컨트롤러 IAM 역할
resource "aws_iam_role" "karpenter_controller" {
  name = "KarpenterController-${var.cluster_name}"

  # IRSA(IAM Roles for Service Accounts)를 위한 신뢰 정책
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:${var.karpenter_namespace}:karpenter"
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "KarpenterController-${var.cluster_name}"
  }
}

# Karpenter 컨트롤러 IAM 정책
resource "aws_iam_policy" "karpenter_controller" {
  name        = "KarpenterControllerPolicy-${var.cluster_name}"
  description = "Karpenter 컨트롤러를 위한 IAM 정책"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # EC2 인스턴스 생성 권한 (특정 리소스에 대해서만)
        Sid    = "AllowScopedEC2InstanceAccessActions"
        Effect = "Allow"
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.id}::image/*",
          "arn:aws:ec2:${data.aws_region.current.id}::snapshot/*",
          "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:security-group/*",
          "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:subnet/*"
        ]
        Action = [
          "ec2:RunInstances",
          "ec2:CreateFleet"
        ]
      },
      {
        # 런치 템플릿 사용 권한 (클러스터 태그가 있는 것만)
        Sid    = "AllowScopedEC2LaunchTemplateAccessActions"
        Effect = "Allow"
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:launch-template/*"
        ]
        Action = [
          "ec2:RunInstances",
          "ec2:CreateFleet"
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
          }
        }
      },
      {
        # EC2 인스턴스 관련 작업 권한 (태그 조건부)
        Sid    = "AllowScopedEC2InstanceActionsWithTags"
        Effect = "Allow"
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:fleet/*",
          "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:volume/*",
          "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:network-interface/*",
          "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:launch-template/*",
          "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:spot-instances-request/*"
        ]
        Action = [
          "ec2:RunInstances",
          "ec2:CreateFleet",
          "ec2:CreateLaunchTemplate"
        ]
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "${data.aws_region.current.id}"
          }
        }
      },
      {
        # 리소스 생성 시 태그 추가 권한
        Sid    = "AllowScopedResourceCreationTagging"
        Effect = "Allow"
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:fleet/*",
          "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:volume/*",
          "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:network-interface/*",
          "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:launch-template/*",
          "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:spot-instances-request/*"
        ]
        Action = "ec2:CreateTags"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "${data.aws_region.current.id}"
            "ec2:CreateAction" = [
              "RunInstances",
              "CreateFleet",
              "CreateLaunchTemplate"
            ]
          }
        }
      },
      {
        # 기존 리소스 태그 수정 권한 (클러스터 소유 리소스만)
        Sid    = "AllowScopedResourceTagging"
        Effect = "Allow"
        Resource = "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:instance/*"
        Action = "ec2:CreateTags"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
          }
        }
      },
      {
        # 리소스 삭제 권한 (클러스터 소유 리소스만)
        Sid    = "AllowScopedDeletion"
        Effect = "Allow"
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:launch-template/*"
        ]
        Action = [
          "ec2:TerminateInstances",
          "ec2:DeleteLaunchTemplate"
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
          }
        }
      },
      {
        # EC2 리소스 조회 권한 (리전 제한)
        Sid    = "AllowRegionalReadActions"
        Effect = "Allow"
        Resource = "*"
        Action = [
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeSubnets"
        ]
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "${data.aws_region.current.id}"
          }
        }
      },
      {
        # SSM 파라미터 읽기 권한 (AWS 서비스 파라미터만)
        Sid    = "AllowSSMReadActions"
        Effect = "Allow"
        Resource = "arn:aws:ssm:${data.aws_region.current.id}::parameter/aws/service/*"
        Action = [
          "ssm:GetParameter"
        ]
      },
      {
        # 가격 정보 조회 권한
        Sid    = "AllowPricingReadActions"
        Effect = "Allow"
        Resource = "*"
        Action = "pricing:GetProducts"
      },
      {
        # SQS 큐 작업 권한 (인터럽션 처리용)
        Sid    = "AllowInterruptionQueueActions"
        Effect = "Allow"
        Resource = "arn:aws:sqs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:Karpenter-${var.cluster_name}"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage"
        ]
      },
      {
        # 인스턴스 프로파일 역할 전달 권한
        Sid    = "AllowPassingInstanceRole"
        Effect = "Allow"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/KarpenterNodeInstanceProfile-${var.cluster_name}"
        Action = "iam:PassRole"
      },
      {
        # 인스턴스 프로파일 생성 권한
        Sid    = "AllowScopedInstanceProfileCreationActions"
        Effect = "Allow"
        Resource = "*"
        Action = [
          "iam:CreateInstanceProfile"
        ]
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "${data.aws_region.current.id}"
          }
        }
      },
      {
        # 인스턴스 프로파일 태그 권한
        Sid    = "AllowScopedInstanceProfileTagActions"
        Effect = "Allow"
        Resource = "*"
        Action = [
          "iam:TagInstanceProfile"
        ]
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "${data.aws_region.current.id}"
          }
        }
      },
      {
        # 인스턴스 프로파일 관리 권한 (클러스터 소유만)
        Sid    = "AllowScopedInstanceProfileActions"
        Effect = "Allow"
        Resource = "*"
        Action = [
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile"
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
            "aws:RequestedRegion" = "${data.aws_region.current.id}"
          }
        }
      },
      {
        # 인스턴스 프로파일 조회 권한
        Sid    = "AllowInstanceProfileReadActions"
        Effect = "Allow"
        Resource = "*"
        Action = "iam:GetInstanceProfile"
      },
      {
        # EKS 클러스터 정보 조회 권한
        Sid    = "AllowAPIServerEndpointDiscovery"
        Effect = "Allow"
        Resource = "arn:aws:eks:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"
        Action = "eks:DescribeCluster"
      }
    ]
  })
}

# Karpenter 컨트롤러 역할에 정책 연결
resource "aws_iam_role_policy_attachment" "karpenter_controller" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller.arn
}

# Karpenter 노드 인스턴스 프로파일 역할
resource "aws_iam_role" "karpenter_node_instance_profile" {
  name = "KarpenterNodeInstanceProfile-${var.cluster_name}"

  # EC2 서비스가 이 역할을 사용할 수 있도록 하는 신뢰 정책
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "KarpenterNodeInstanceProfile-${var.cluster_name}"
  }
}

# Karpenter 노드 역할에 AWS 관리형 정책 연결
# EKS 워커 노드 정책
resource "aws_iam_role_policy_attachment" "karpenter_node_worker_node_policy" {
  role       = aws_iam_role.karpenter_node_instance_profile.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# EKS CNI 정책
resource "aws_iam_role_policy_attachment" "karpenter_node_cni_policy" {
  role       = aws_iam_role.karpenter_node_instance_profile.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# ECR 읽기 전용 정책
resource "aws_iam_role_policy_attachment" "karpenter_node_registry_policy" {
  role       = aws_iam_role.karpenter_node_instance_profile.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# SSM 관리형 인스턴스 코어 정책
resource "aws_iam_role_policy_attachment" "karpenter_node_ssm_policy" {
  role       = aws_iam_role.karpenter_node_instance_profile.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Karpenter 노드용 인스턴스 프로파일 생성
resource "aws_iam_instance_profile" "karpenter_node_instance_profile" {
  name = "KarpenterNodeInstanceProfile-${var.cluster_name}"
  role = aws_iam_role.karpenter_node_instance_profile.name

  tags = {
    Name = "KarpenterNodeInstanceProfile-${var.cluster_name}"
  }
}

# Karpenter 인터럽션 처리를 위한 SQS 큐
resource "aws_sqs_queue" "karpenter" {
  name                      = "Karpenter-${var.cluster_name}"
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true

  tags = {
    Name = "Karpenter-${var.cluster_name}"
  }
}

# EC2 인터럽션 이벤트를 위한 EventBridge 규칙
resource "aws_cloudwatch_event_rule" "karpenter_interruption" {
  name        = "KarpenterInterruption-${var.cluster_name}"
  description = "Karpenter 인터럽션 처리"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
    detail = {
      state = ["shutting-down", "terminated"]
    }
  })
}

# EventBridge 규칙의 타겟으로 SQS 큐 설정
resource "aws_cloudwatch_event_target" "karpenter_interruption" {
  rule      = aws_cloudwatch_event_rule.karpenter_interruption.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter.arn
}

# EventBridge가 SQS 큐에 메시지를 보낼 수 있도록 하는 큐 정책
resource "aws_sqs_queue_policy" "karpenter" {
  queue_url = aws_sqs_queue.karpenter.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgeToSendMessage"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.karpenter.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.karpenter_interruption.arn
          }
        }
      }
    ]
  })
}

# 출력값
output "karpenter_controller_role_arn" {
  description = "Karpenter 컨트롤러 IAM 역할 ARN"
  value       = aws_iam_role.karpenter_controller.arn
}

output "karpenter_node_instance_profile_name" {
  description = "Karpenter 노드 인스턴스 프로파일 이름"
  value       = aws_iam_instance_profile.karpenter_node_instance_profile.name
}

output "karpenter_interruption_queue_name" {
  description = "Karpenter 인터럽션 SQS 큐 이름"
  value       = aws_sqs_queue.karpenter.name
}
