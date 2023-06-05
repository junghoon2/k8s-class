# felice 설치 heml chart
본 chart는 SPITHA 배보폰 카프카 설치를 위한 helm 차트이다. helm 3.x에서 테스트 되었다.

## 설치 전 준비 사항
### Kafka Cluster 구성
펠리체는 카프카 클러스터를 관리하기위한 도구이므로 먼저 카프카서비스를 반드시 준비해야 한다.

### Chart.yaml
- appVersion
  애플리케이션 버전

### values.yaml
다음을 참고하여 차트의 values.yml에 필요한 설정을 한다.
- image
  pod 이미지 관련 설정
  - registry
    이미지 레지스트리를 입력한다. 이미지 이름 바로 앞까지 경로를 입력한다(마지막 `/` 생략).
  - pullPolicy
    이미지 풀링 정책
  - serverVersion
    api 서버 애플리케이션 버전
  - clientVersion
    web ui 버전
  - monitorVersion
    매트릭 수집 애플리케이션 버전
- imagePullSecrets: []
  컨테이너 이미지를 가져올 때 credential이 필요하다면 `[]` 부분을 삭제하고 array 형태로 secret 이름을 입력한다.
- nameOverride
  helm 설치 시 suffix로 추가 된다.
- configs
  felice에 대한 설정
  - admin
    UI 초기 관리자 계정에 대한 설정
    - id
      초기 관리자 아이디
    - password
      초기 관리자 패스워드. 최초 로그인 시 반드시 변경해야 함
  - volume
    퍼시스턴트 볼륨에 대한 설정
    - tsdb
      모니터링 메트릭 데이터를 저장할 tsdb 스토리지
    - rulesdir
      알람 룰을 저장할 스토리지
    - datadir
      내부 데이터베이스 데이터 보관 스토리지
- monitoringClusters  
  모니터링 대상 클러스터 배열을 입력.  
  서버를 찾는 방법의 예; `{{ zookeeper.hostPrefix }}-0.{{ zookeeper.hostPrefix }}-hs.{{ zookeeper.domainSuffix }}:2181`.  
  `{{ zooekeeper.servers }}` 만큼 반복
  - `name`
    펠리체에 등록할 클러스터 이름
  - zookeeper
    클러스터에 연결된 zookeeper 정보
    - domainSuffix
      다른 네임스페이스에 설치한 경우 `namespace.svc.cluster.local` 형식으로 입력
    - hostPrefix
      주키퍼 스테이트풀셋에 포함된 pod에서 순번을 제외한 prefix 부분. 보통 [helm release name]-[nameOverride] 형태. 참고: [Helm 용어집](https://helm.sh/ko/docs/glossary/)
    - servers
      설치된 zookeeper의 replica 수
    - clientPort
      zookeeper 서비스 포트
  - kafka
    클러스터에 연결된 kafka 정보
    - domainSuffix
      다른 네임스페이스에 설치한 경우 `namespace.svc.cluster.local` 형식으로 입력
    - hostPrefix
      주키퍼 스테이트풀셋에 포함된 pod에서 순번을 제외한 prefix 부분. 보통 [helm release name]-[nameOverride] 형태. 참고: [Helm 용어집](https://helm.sh/ko/docs/glossary/)
    - servers
      설치된 kafka의 replica 수
    - clientPort
      kafka 서비스 포트
- resources
  리소스 요청 및 제한

## 설치
다음의 예와 같은 명령으로 차트를 이용하여 펠리체 서비스를 설치할 수 있다.
```
helm install spitha-felice ./
```

## 제거
다음의 예와 같은 명령으로 설치된 서비스를 제거할 수 있다.
```
helm delete spitha-felice
```