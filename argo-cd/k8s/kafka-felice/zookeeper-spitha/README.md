# ZooKeeper 설치 heml chart
본 chart는 SPITHA 배포판 ZooKeeper 설치를 위한 helm 차트이다. helm 3.x에서 테스트 되었다.

### Chart.yaml
- appVersion
  zookeeper 버전
  
### values.yaml
다음을 참고하여 차트의 values.yml에 필요한 설정을 한다.
- replicaCount
  설치할 주키퍼 서버 노드 수를 입력한다. 3 혹은 5가 적당하고, 7 이상은 사실상 필요 없다. 반드시 홀수 개로 입력한다. 테스트를 위해 1도 가능하다.
- image
  pod 이미지 관련 설정
  - registry
    이미지 레지스트리를 입력한다. 이미지 이름 바로 앞까지 경로를 입력한다.
  - pullPolicy
    이미지 풀링 정책
- imagePullSecrets: []
  컨테이너 이미지를 가져올 때 credential이 필요하다면 `[]` 부분을 삭제하고 array 형태로 secret 이름을 입력한다.
- nameOverride
  helm 설치 시 suffix로 추가 된다.
- configs
  zookeeper에 대한 설정
  - volume
    퍼시스턴트 볼륨 크기
- resources
  리소스 요청 및 제한

## 설치
다음의 예와 같은 명령으로 차트를 이용하여 주키퍼 서비스를 설치할 수 있다.
```
helm install zookeeper ./
```

## 제거
다음의 예와 같은 명령으로 설치된 서비스를 제거할 수 있다.
```
helm delete zookeeper
```