# EKS 클러스터 Terraform 배포 가이드

이 프로젝트는 AWS EKS(Elastic Kubernetes Service) 클러스터를 Terraform을 사용하여 배포하는 코드입니다.

## 📋 주요 특징

- **최신 EKS 버전**: Kubernetes 1.32 지원
- **전용 VPC**: 클러스터 전용 VPC 구성으로 네트워크 격리
- **보안 강화**: 최소 권한 원칙을 적용한 보안 그룹 및 IAM 역할
- **매니지드 노드 그룹**: AWS 관리형 노드 그룹 사용
- **Bottlerocket AMI**: 컨테이너 최적화된 ARM64 AMI 사용
- **암호화**: KMS를 통한 시크릿 암호화
- **모니터링**: CloudWatch 로깅 지원 (선택적)

## 🏗️ 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                        VPC (10.101.0.0/16)                 │
├─────────────────────────────────────────────────────────────┤
│  Public Subnets (/24)          │  Private Subnets (/20)    │
│  ┌─────────────────────┐       │  ┌─────────────────────┐   │
│  │   NAT Gateway       │       │  │   EKS Nodes         │   │
│  │   Internet Gateway  │       │  │   (Bottlerocket)    │   │
│  └─────────────────────┘       │  └─────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                    │
            ┌───────────────┐
            │ EKS Control   │
            │ Plane         │
            │ (AWS Managed) │
            └───────────────┘
```

## 📁 파일 구조

```
.
├── main.tf              # 메인 리소스 정의 (EKS 클러스터, 노드 그룹)
├── variables.tf         # 변수 정의
├── terraform.tfvars.example  # 변수 예시 파일
├── vpc.tf              # VPC 및 네트워킹 리소스
├── security-groups.tf  # 보안 그룹 정의
├── iam.tf              # IAM 역할 및 정책
├── outputs.tf          # 출력 값 정의
└── README.md           # 이 파일
```

## 🚀 배포 방법

### 1. 사전 요구사항

- AWS CLI 설치 및 구성
- Terraform >= 1.0 설치
- kubectl 설치 (클러스터 관리용)

### 2. 변수 설정

```bash
# 예시 파일을 복사하여 실제 변수 파일 생성
cp terraform.tfvars.example terraform.tfvars

# terraform.tfvars 파일을 편집하여 실제 값으로 수정
vi terraform.tfvars
```

### 3. Terraform 초기화 및 배포

```bash
# Terraform 초기화
terraform init

# 배포 계획 확인
terraform plan

# 리소스 배포
terraform apply
```

### 4. kubectl 설정

```bash
# EKS 클러스터에 kubectl 연결
aws eks update-kubeconfig --region ap-northeast-2 --name your-cluster-name

# 클러스터 상태 확인
kubectl get nodes
kubectl get pods --all-namespaces
```

## ⚙️ 주요 설정 옵션

### 네트워크 설정
- **VPC CIDR**: `10.101.0.0/16`
- **Private Subnets**: `/20` 서브넷 (노드 배치용)
- **Public Subnets**: `/24` 서브넷 (NAT Gateway용)

### 보안 설정
- **엔드포인트 접근**: Public + Private (개발환경용)
- **보안 그룹**: 최소 권한 원칙 적용
- **암호화**: KMS를 통한 시크릿 암호화

### 노드 그룹 설정
- **AMI 타입**: `BOTTLEROCKET_ARM_64`
- **인스턴스 타입**: `t4g.medium`, `t4g.large`
- **스케일링**: 최소 1, 최대 10, 희망 2

## 🔧 커스터마이징

### 보안 강화 (프로덕션 환경)

```hcl
# terraform.tfvars에서 다음 설정 변경
cluster_endpoint_config = {
  private_access      = true
  public_access       = false  # 또는 특정 IP만 허용
  public_access_cidrs = ["YOUR_OFFICE_IP/32"]
}

enable_cluster_logging = true
```

### 노드 그룹 스케일링 조정

```hcl
node_group_config = {
  instance_types = ["t4g.large", "t4g.xlarge"]
  desired_size   = 3
  max_size       = 20
  min_size       = 2
}
```

## 📊 모니터링 및 로깅

### CloudWatch 로깅 활성화

```hcl
enable_cluster_logging = true
cluster_enabled_log_types = ["audit", "api", "authenticator", "controllerManager", "scheduler"]
```

### Container Insights 활성화

```bash
# CloudWatch Container Insights 설치
curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml | sed "s/{{cluster_name}}/your-cluster-name/;s/{{region_name}}/ap-northeast-2/" | kubectl apply -f -
```

## 🔒 보안 고려사항

### 개발 환경
- EKS 엔드포인트 Public 접근 허용 (편의성)
- SSM을 통한 노드 접근만 허용 (SSH 키 없음)
- 로깅 비활성화 (비용 절약)

### 프로덕션 환경 권장사항
- EKS 엔드포인트 Private 전용 또는 IP 제한
- SSM Session Manager를 통한 보안 접근 유지
- 모든 로깅 활성화
- VPC Flow Logs 활성화
- AWS Config 및 CloudTrail 설정

## 🖥️ 노드 접속 방법

이 클러스터는 보안을 위해 SSH 키 접근을 제거하고 AWS Systems Manager Session Manager만을 통한 접속을 허용합니다.

### SSM을 통한 노드 접속

```bash
# 1. 노드 인스턴스 ID 확인
aws ec2 describe-instances \
  --filters "Name=tag:aws:eks:cluster-name,Values=your-cluster-name" \
  --query 'Reservations[].Instances[].{InstanceId:InstanceId,State:State.Name,Name:Tags[?Key==`Name`].Value|[0]}' \
  --output table

# 2. SSM Session Manager를 통한 접속
aws ssm start-session --target i-1234567890abcdef0

# 3. 노드에서 컨테이너 디버깅 (필요시)
sudo bottlerocket-admin enter-admin-container
```

### SSM 접속의 장점
- **보안**: SSH 키 관리 불필요, 22번 포트 열지 않음
- **감사**: 모든 세션이 CloudTrail에 기록됨
- **권한 관리**: IAM을 통한 세밀한 접근 제어
- **편의성**: AWS CLI만으로 접속 가능

## 🧹 리소스 정리

```bash
# 모든 리소스 삭제
terraform destroy

# 특정 리소스만 삭제
terraform destroy -target=aws_eks_node_group.eks_node_group
```

## 📝 주요 출력 값

배포 완료 후 다음 정보들이 출력됩니다:

- **클러스터 엔드포인트**: API 서버 접근 URL
- **kubectl 설정 명령어**: 클러스터 연결용 명령어
- **VPC 및 서브넷 ID**: 네트워크 리소스 정보
- **보안 그룹 ID**: 보안 설정 정보
- **SSM 접속 정보**: 노드 접근용 SSM 명령어

## 🆘 문제 해결

### 일반적인 문제들

1. **권한 부족 오류**
   ```bash
   # AWS 자격 증명 확인
   aws sts get-caller-identity
   ```

2. **노드가 클러스터에 조인되지 않음**
   ```bash
   # 노드 그룹 상태 확인
   aws eks describe-nodegroup --cluster-name your-cluster-name --nodegroup-name your-nodegroup-name
   ```

3. **kubectl 연결 실패**
   ```bash
   # kubeconfig 업데이트
   aws eks update-kubeconfig --region ap-northeast-2 --name your-cluster-name --profile your-profile
   ```

## 📚 참고 자료

- [AWS EKS 사용자 가이드](https://docs.aws.amazon.com/eks/latest/userguide/)
- [AWS EKS 베스트 프랙티스](https://docs.aws.amazon.com/eks/latest/best-practices/)
- [Terraform AWS Provider 문서](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes 공식 문서](https://kubernetes.io/docs/)

## 🏷️ 태그 및 버전

- **Terraform**: >= 1.0
- **AWS Provider**: ~> 5.0
- **Kubernetes**: 1.32
- **환경**: 개발/테스트용

---

**주의**: 이 설정은 개발 환경용으로 구성되었습니다. 프로덕션 환경에서는 보안 설정을 강화해야 합니다.
