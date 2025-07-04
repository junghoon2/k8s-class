최신 테라폼 eks 모듈을 이용해줘.
별도 전용 vpc에 설치해줘.
테라폼 변수는 local 이 아니라 variable 을 사용해줘.
tfvars.example 변수도 만들어줘.
vpc는 /16 CIDR 이고 IP 대역은 10.101.0.0 이야.
private subnet은 /20 이고 public은 /24로 구성해줘.
필요한 포트만 열고 소스 IP 제한하여 최소한의 Security Group을 사용하도록 해줘.
EBS 볼륨 암호화 활성화 및 Secrets 암호화 설정해줘.
매니지드 노드 그룹을 사용하고
eks 엔드포인트는 일단 외부 Public IP 대역에서 접속 가능하도록 설정해줘.
실행하는 계정에 관리자 권한을 아래와 같이 추가해줘.
'enable_cluster_creator_admin_permissions = true'
AMI는 BOTTLEROCKET_ARM_64 사용해줘.
로그 파일은 개발 환경이라 일단 disable 해줘. 변수로 설정할 수 있게 해줘.
코드에 한글 주석을 추가해줘.
readme 파일도 만들어줘.
