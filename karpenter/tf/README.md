# Karpenter IAM Terraform 구성

이 Terraform 구성은 Amazon EKS 클러스터에서 Karpenter를 사용하기 위한 필수 IAM 역할과 정책을 생성합니다.

## 개요

Karpenter는 Kubernetes 클러스터의 노드 자동 스케일링을 담당하는 오픈소스 프로젝트입니다. 이 구성은 다음과 같은 리소스를 생성합니다:

### 생성되는 리소스

1. **Karpenter 컨트롤러 IAM 역할**

   - IRSA(IAM Roles for Service Accounts)를 통해 Karpenter 파드가 사용
   - EC2 인스턴스 생성, 삭제, 관리 권한
   - SQS 큐 접근 권한 (인터럽션 처리용)

2. **Karpenter 노드 인스턴스 프로파일**

   - Karpenter가 생성하는 EC2 인스턴스가 사용
   - EKS 워커 노드 필수 권한들

3. **SQS 큐 및 EventBridge 규칙**
   - EC2 인스턴스 인터럽션 이벤트 처리용

## 사전 요구사항

- EKS 클러스터가 이미 존재해야 함
- EKS 클러스터에 OIDC 프로바이더가 설정되어 있어야 함
- Terraform >= 1.0
- AWS Provider >= 4.0

## 사용법

### 1. 변수 설정

`terraform.tfvars` 파일을 생성하여 변수를 설정하거나, 기본값을 사용할 수 있습니다:

```hcl
cluster_name         = "test-eks-cluster"
karpenter_namespace  = "karpenter"
```

### 2. Terraform 초기화 및 적용

```bash
# Terraform 초기화
terraform init

# 계획 확인
terraform plan

# 적용
terraform apply
```

## 주요 구성 요소

### Karpenter 컨트롤러 권한

- **EC2 관리**: 인스턴스 생성, 삭제, 태그 관리
- **런치 템플릿**: 생성, 삭제, 사용
- **네트워킹**: 서브넷, 보안 그룹 조회
- **가격 정보**: EC2 인스턴스 가격 조회
- **인터럽션 처리**: SQS 큐를 통한 스팟 인스턴스 인터럽션 처리

### 보안 고려사항

- 모든 권한은 최소 권한 원칙에 따라 설정
- 리소스별 태그 기반 접근 제어 적용
- 특정 클러스터와 리전으로 권한 범위 제한

## 출력값

- `karpenter_controller_role_arn`: Karpenter 컨트롤러 IAM 역할 ARN
- `karpenter_node_instance_profile_name`: 노드 인스턴스 프로파일 이름
- `karpenter_interruption_queue_name`: 인터럽션 처리용 SQS 큐 이름

## 문제 해결

### 일반적인 문제들

1. **OIDC 프로바이더 오류**

   ```
   Error: error reading EKS Cluster: cluster not found
   ```

   - EKS 클러스터 이름이 올바른지 확인
   - 클러스터가 존재하고 접근 가능한지 확인

2. **권한 부족 오류**

   - Terraform을 실행하는 사용자/역할에 IAM 관리 권한이 있는지 확인
   - EKS 클러스터 조회 권한이 있는지 확인

3. **Karpenter 파드 시작 실패**
   - ServiceAccount 어노테이션이 올바른지 확인
   - IRSA 설정이 정상적으로 되었는지 확인

## 참고 자료

- [Karpenter 공식 문서](https://karpenter.sh/)
- [AWS EKS 사용자 가이드](https://docs.aws.amazon.com/eks/latest/userguide/)
- [IRSA 설정 가이드](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)

## 라이선스

이 코드는 MIT 라이선스 하에 제공됩니다.
