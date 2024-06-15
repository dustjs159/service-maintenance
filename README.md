Service Maintenance
======================
서비스 점검을 위해 외부의 트래픽을 차단 및 점검 완료 후 서비스 재개를 위한 스크립트.
* Bash Shell Script로 작성
* Version : `aws-cli/2.13.13`

### 스크립트 동작 원리
* 서비스 차단 ( `SERVICE_MAINTENANCE = "on"` )
    * CloudFront Origin Path가 `/maintenance` 로 변경됨
    * ALB Response가 `503` 반환 및 `Service Maintenance...` 텍스트 출력 되도록 변경됨
* 서비스 오픈 ( `SERVICE_MAINTENANCE = "off"` )
    * 원상 복구

### 필요한 권한
* Jenkins 인스턴스의 Role에 아래 권한 부여
    * CloudFront 
        * `GetDistribution`
        * `UpdateDistribution`
    * ALB
        * `ModifyRule`

### 유의 사항
* CloudFront의 Distribution ID 혹은 ALB, Targetgroup이 변경될 경우, Jenkins의 String Parameter를 변경해줘야 함.