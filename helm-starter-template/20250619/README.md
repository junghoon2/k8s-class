# Helm Starter Template

이 저장소는 production-ready Kubernetes 애플리케이션을 위한 Helm chart starter template입니다.

## 🚀 특징

### Security Best Practices

- **Security Context**: 비권한 사용자로 실행 (runAsNonRoot: true)
- **Read-only Root Filesystem**: 컨테이너 보안 강화
- **Capabilities Drop**: 모든 Linux capabilities 제거
- **NetworkPolicy**: 네트워크 격리 및 보안
- **ServiceAccount**: 최소 권한 원칙 적용

### High Availability & Scalability

- **Multi-replica Deployment**: 기본 3개 replica
- **HorizontalPodAutoscaler**: CPU/Memory 기반 자동 스케일링
- **PodDisruptionBudget**: 업데이트 시 가용성 보장
- **Rolling Update Strategy**: 무중단 배포

### Observability

- **Probes**: Liveness, Readiness, Startup probes 구성
- **Resource Limits**: 리소스 제한 및 요청 설정
- **Configurable Logging**: 환경별 로그 레벨 설정

### Production Features

- **Ingress**: SSL/TLS 자동 설정 및 cert-manager 통합
- **ConfigMap/Secret**: 설정 및 시크릿 관리
- **Volume Mounts**: emptyDir 및 persistent volume 지원
- **RBAC**: Role-based Access Control 지원

## 📁 구조

```
.
├── Chart.yaml                 # Chart metadata
├── values.yaml               # Default configuration values
├── .helmignore               # Files to ignore during packaging
├── README.md                 # This file
└── templates/
    ├── _helpers.tpl          # Template helpers
    ├── deployment.yaml       # Main application deployment
    ├── service.yaml          # Service definition
    ├── serviceaccount.yaml   # ServiceAccount
    ├── configmap.yaml        # Configuration data
    ├── secret.yaml           # Secret data
    ├── ingress.yaml          # Ingress configuration
    ├── hpa.yaml             # HorizontalPodAutoscaler
    ├── pdb.yaml             # PodDisruptionBudget
    ├── rbac.yaml            # RBAC resources
    ├── networkpolicy.yaml   # Network security policies
    └── NOTES.txt            # Post-install instructions
```

## 🛠 사용법

### 1. 차트 설치

```bash
# 기본 설정으로 설치
helm install my-app .

# 커스텀 values 파일로 설치
helm install my-app . -f values-production.yaml

# 특정 namespace에 설치
helm install my-app . --namespace my-namespace --create-namespace
```

### 2. 차트 업그레이드

```bash
helm upgrade my-app . -f values-production.yaml
```

### 3. 차트 제거

```bash
helm uninstall my-app
```

## ⚙️ 주요 설정

### 이미지 설정

```yaml
image:
  registry: docker.io
  repository: my-app
  tag: "1.0.0"
  pullPolicy: IfNotPresent
```

### 리소스 설정

```yaml
deployment:
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 100m
      memory: 128Mi
```

### 보안 설정

```yaml
deployment:
  securityContext:
    runAsNonRoot: true
    runAsUser: 65534
    fsGroup: 65534

  containerSecurityContext:
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    capabilities:
      drop:
        - ALL
```

### HPA 설정

```yaml
hpa:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80
```

### PVC (Persistent Volume) 설정

영구 스토리지가 필요한 애플리케이션을 위한 PVC 설정:

```yaml
persistence:
  enabled: true
  volumes:
    # 데이터 저장용 PVC
    - name: data
      size: 10Gi
      accessModes:
        - ReadWriteOnce
      storageClass: "gp3" # AWS EKS 기본 StorageClass
      mountPath: /data

    # 로그 저장용 PVC
    - name: logs
      size: 5Gi
      accessModes:
        - ReadWriteOnce
      storageClass: "gp3"
      mountPath: /var/log/app

    # 공유 스토리지 (EFS)
    - name: shared
      size: 1Gi
      accessModes:
        - ReadWriteMany
      storageClass: "efs"
      mountPath: /shared
```

**사용 예제:**

```bash
# PVC 포함한 배포
helm install my-app . -f examples/values-with-pvc.yaml

# PVC 상태 확인
kubectl get pvc

# Pod의 볼륨 마운트 확인
kubectl describe pod <pod-name>
```

### Ingress 설정

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: my-app.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: my-app-tls
      hosts:
        - my-app.example.com
```

## 🔧 커스터마이징

### 환경별 Values 파일 예제

#### `values-dev.yaml`

```yaml
deployment:
  replicaCount: 1
  resources:
    requests:
      cpu: 50m
      memory: 64Mi

ingress:
  enabled: false

hpa:
  enabled: false
```

#### `values-prod.yaml`

```yaml
deployment:
  replicaCount: 5
  resources:
    limits:
      cpu: 1000m
      memory: 1Gi
    requests:
      cpu: 500m
      memory: 512Mi

hpa:
  enabled: true
  minReplicas: 5
  maxReplicas: 20

networkPolicy:
  enabled: true
```

## 🧪 테스트

### Template 렌더링 테스트

```bash
# 모든 템플릿 렌더링
helm template my-app .

# 특정 템플릿만 렌더링
helm template my-app . -s templates/deployment.yaml

# 값 검증
helm template my-app . --debug
```

### Dry-run 설치

```bash
helm install my-app . --dry-run --debug
```

## 📝 Best Practices 체크리스트

- ✅ Security context 설정
- ✅ Resource limits/requests 정의
- ✅ Liveness/Readiness probes 구성
- ✅ Rolling update strategy 설정
- ✅ PodDisruptionBudget 구성
- ✅ HPA 설정 (프로덕션 환경)
- ✅ NetworkPolicy 구성 (보안 요구사항)
- ✅ RBAC 최소 권한 원칙
- ✅ ConfigMap/Secret 분리
- ✅ Ingress TLS 설정
- ✅ 적절한 라벨링 및 어노테이션

## 🤝 기여

이 템플릿을 개선하고 싶다면:

1. Fork this repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

---

💡 **Tip**: 이 템플릿은 운영 환경에서 검증된 best practice를 기반으로 제작되었습니다.
