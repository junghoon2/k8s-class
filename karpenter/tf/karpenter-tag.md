카펜터 노드가 사용할 Private Subnet과 Security Group에 카펜터 태그를 추가하는 테라폼 코드를 생성해줘

참조 : https://karpenter.sh/docs/getting-started/migrating-from-cas/#add-tags-to-subnets-and-security-groups

- 환경변수
  - KARPENTER_NAMESPACE=kube-system
  - CLUSTER_NAME=test-eks-cluster
