# Terraform EKS 클러스터 (신규 VPC 생성) 구성

이 Terraform 코드는 AWS 환경에 새로운 VPC(Virtual Private Cloud)를 생성하고, 그 안에 EKS(Elastic Kubernetes Service) 클러스터 및 관리형 노드 그룹을 구성합니다.

## 주요 특징

- **신규 VPC 생성**: EKS 클러스터를 위한 새로운 VPC, 서브넷, NAT 게이트웨이 등 네트워크 인프라를 자동으로 생성합니다.
- **Terraform 모듈 사용**: 검증된 `terraform-aws-modules/vpc/aws` 및 `terraform-aws-modules/eks/aws` 모듈을 사용하여 VPC와 EKS 클러스터 인프라를 효율적으로 관리합니다.
- **관리형 노드 그룹**: EKS 관리형 노드 그룹을 사용하여 워커 노드를 구성합니다.
- **상세한 주석**: 코드 이해를 돕기 위해 한글 주석이 포함되어 있습니다.

## 사전 요구 사항

- AWS 계정 및 IAM 사용자 (적절한 권한 포함)
- AWS CLI 설치 및 구성 (`aws configure`)
- Terraform v1.0 이상 설치
- kubectl 설치 (클러스터 상호작용용)

## 설정 및 배포 방법

1.  **저장소 복제 (선택 사항)**

    ```bash
    git clone <repository-url>
    cd <repository-directory>
    ```

2.  **변수 파일 검토 (선택 사항)**: `terraform.tfvars` 또는 `variables.tf` 파일을 검토하여 기본 VPC 설정(CIDR, 가용 영역 등)이나 EKS 클러스터/노드 그룹 설정을 필요에 따라 수정합니다. 기본값으로도 기본적인 클러스터 생성이 가능합니다.

    ```hcl
    # terraform.tfvars (예시)
    # cluster_name = "my-custom-eks-cluster"
    # vpc_cidr_block = "10.2.0.0/16"
    # eks_node_group_instance_types = ["m5.large"]
    # ... 기타 필요한 변수 수정 ...
    ```

3.  **Terraform 초기화**: 필요한 프로바이더와 모듈을 다운로드합니다.

    ```bash
    terraform init
    ```

4.  **실행 계획 검토**: Terraform이 어떤 리소스를 생성/수정/삭제할지 확인합니다.

    ```bash
    terraform plan
    ```

5.  **인프라 생성**: 계획을 승인하고 AWS에 리소스를 생성합니다.

    ```bash
    terraform apply
    ```

    `yes`를 입력하여 진행합니다. VPC 및 EKS 클러스터 생성에 시간이 다소 소요될 수 있습니다.

6.  **kubeconfig 설정**: 생성된 EKS 클러스터에 `kubectl`로 접근할 수 있도록 kubeconfig 파일을 업데이트합니다. Terraform 출력값을 사용하거나 직접 명령어를 실행합니다.

    ```bash
    # Terraform 출력값 확인
    terraform output configure_kubectl

    # 위 명령어 복사 및 실행 (예시)
    # 출력된 명령어 예시: aws eks update-kubeconfig --name my-new-vpc-eks-cluster --region ap-northeast-2
    $(terraform output -raw configure_kubectl)
    ```

7.  **클러스터 확인**:
    - 클러스터 노드 확인 (관리형 노드 그룹 확인)
      ```bash
      kubectl get nodes
      ```
    - 클러스터 정보 확인
      ```bash
      kubectl cluster-info
      ```

## 인프라 삭제

생성된 모든 AWS 리소스(EKS 클러스터, 노드 그룹, VPC, 서브넷 등)를 삭제하려면 다음 명령어를 사용합니다.

```bash
terraform destroy
```

`yes`를 입력하여 진행합니다.

## 추가 정보

- 프로덕션 환경에서는 보안 그룹 규칙, IAM 권한, 로깅, 모니터링 등을 더 강화해야 합니다.
- 생성되는 VPC의 세부 설정(서브넷 크기, NAT 게이트웨이 구성 등)은 `variables.tf` 및 `main.tf`의 `module.vpc` 블록에서 조정할 수 있습니다.
- 클러스터 오토스케일링이 필요한 경우, Kubernetes Cluster Autoscaler와 같은 도구를 별도로 설치 및 구성해야 합니다.
