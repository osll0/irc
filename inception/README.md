_This project has been created as part of the 42 curriculum by jechoi._

# Inception

42Seoul의 Inception 프로젝트 - Docker Compose를 사용한 시스템 관리 인프라 구축

## 📋 프로젝트 개요

Docker를 사용하여 NGINX, WordPress, MariaDB로 구성된 웹 서비스 인프라를 구축하는 프로젝트입니다.

### 주요 특징

- 각 서비스별 독립적인 Docker 컨테이너
- Alpine/Debian 기반 경량 이미지
- TLSv1.2/1.3를 사용한 HTTPS 통신
- Docker Volume을 통한 데이터 영속성
- 환경변수 기반 설정 관리

## 🚀 사용 방법

### 1. 환경변수 설정

`srcs/.env` 파일에서 필요한 환경변수를 설정합니다:

```bash
# 도메인 설정
DOMAIN_NAME=jechoi.42.fr

# MariaDB 설정
MARIADB_ROOT_PASSWORD=your_root_password
MARIADB_DATABASE=wordpress
MARIADB_USER=wpuser
MARIADB_PASSWORD=your_db_password

# WordPress 설정
WORDPRESS_DB_HOST=mariadb:3306
WORDPRESS_DB_NAME=wordpress
WORDPRESS_DB_USER=wpuser
WORDPRESS_DB_PASSWORD=your_db_password
WORDPRESS_ADMIN_USER=admin
WORDPRESS_ADMIN_PASSWORD=your_admin_password
WORDPRESS_ADMIN_EMAIL=admin@example.com
WORDPRESS_TITLE=My Inception Site
```

### 2. 빌드 및 실행

```bash
# 전체 빌드 및 실행 (hosts 자동 설정 포함)
make

# 또는 개별 명령어
make setup      # 디렉토리 생성 및 hosts 설정
make up         # 컨테이너 빌드 및 실행
```

### 3. 접속

브라우저에서 다음 주소로 접속:

```
https://jechoi.42.fr
```

**참고:** 자체 서명 인증서를 사용하므로 브라우저에서 보안 경고가 나타납니다. "고급" → "위험을 감수하고 계속"을 클릭하여 진행하세요.

````

## 🔧 기술 스택

### NGINX

- **베이스 이미지:** Alpine 3.18
- **버전:** nginx 1.24+
- **기능:**
  - HTTPS 통신 (TLSv1.2, TLSv1.3)
  - HTTP/2 지원
  - SSL 자체 서명 인증서 자동 생성
  - WordPress PHP-FPM 연동

### WordPress

- **베이스 이미지:** Alpine 3.18
- **PHP 버전:** 8.1
- **기능:**
  - WP-CLI를 통한 자동 설치
  - PHP-FPM으로 실행
  - MariaDB 연동
  - 메모리 제한: 256MB

### MariaDB

- **베이스 이미지:** Ubuntu 22.04
- **버전:** 10.6.22
- **기능:**
  - 자동 데이터베이스 생성
  - 사용자 권한 관리
  - 외부 접속 허용
  - 데이터 영속성 (Volume)

## 📦 Docker Volume

프로젝트는 호스트 시스템의 다음 경로에 데이터를 저장합니다:

```bash
/home/${USER}/data/
├── mariadb/        # MariaDB 데이터베이스 파일
└── wordpress/      # WordPress 파일
````

## 🔐 보안 고려사항

1. **HTTPS 전용:** HTTP(80) 포트는 사용하지 않음
2. **TLS 1.2/1.3:** 최신 암호화 프로토콜 사용
3. **환경변수:** 민감 정보는 `.env` 파일로 관리
4. **최소 권한:** 각 서비스는 전용 사용자로 실행
5. **숨김 파일 차단:** NGINX에서 `.`로 시작하는 파일 접근 차단

## 🐛 트러블슈팅

### 컨테이너가 재시작을 반복하는 경우

```bash
# 로그 확인
docker compose logs -f [service_name]

# 예: WordPress 로그 확인
docker compose logs -f wordpress
```

### 도메인 접속이 안 되는 경우

```bash
# /etc/hosts 확인
cat /etc/hosts | grep jechoi.42.fr

# 없으면 Makefile의 setup 타겟이 자동으로 추가
make setup
```

### 볼륨 권한 문제

```bash
# 데이터 디렉토리 권한 확인
ls -la /home/$USER/data/

# 필요시 권한 수정
sudo chown -R $USER:$USER /home/$USER/data/
```

### 완전 초기화

```bash
# 모든 컨테이너, 볼륨, 네트워크 삭제
make clean

# 재빌드
make
```

## VM vs Docker

### VM

1. 아키텍처

- 하이퍼바이저 기반
- 하드웨어 에뮬레이션: CPU, 메모리, 디스크, 네트워크 카드 등을 가상으로 생성
- 전체 OS스택: 각 VM이 독립적인 커널, 라이브러리, 바이너리 포함

2. 격리 메커니즘

- 완전한 하드웨어 레벨 격리
- !!각 VM은 독립적인 커널 공간과 사용자 공간 사용!!
- 한 VM의 커널 패닉이 다른 VM에 영향을 주지 않음

3. 리소스 관리

- 각 VM에 고정된 리소스 할당
- Guest OS에 전체 리소스를 독점적으로 관리
- 오버헤드: Guest OS + 하이퍼바이저 레이어

### Docker

1. 아키텍처

- OS레벨 가상화: 호스트 커널을 공유함
- 이미지 레이어 시스템
- 공유 바이너리: 공통 라이브러리와 바이너리를 여러 컨테이너가 공유

2. 격리 메커니즘

- Namespace: 프로세스, 네트워크, 파일시스템, UserID 격리 등
- Cgroups(Control Groups): 리소스 제한 및 모니터링
  - 메모리 제한
  - CPU 사용량 제한
  - 네트워크 대역폭 제어

3. 리소스 관리

- 동적 리소스 공유
- 호스트 커널이 모든 컨테이너의 리소스를 통합 관리
- 오버헤드: Docker데몬만 추가됨

## Secrets vs Environment Variables

### Environment Varialbes

- 일반적으로 설정값 저장 (포트, 호스트명 등)
- 평문으로 저장되어 보안에 취약
- docker-compose.yml이나 .env파일에 노출 가능

### Secrets

- 민감한 정보 저장 (비밀번호, API키, 인증서 등)
- 암호화되어 저장 및 전송!!
- Docker Swarm 또는 외부 secrets 관리 시스템 사용
- 컨테이너 내부에서만 복호화되어 접근 가능

## Docker Network vs Host Network

### Docker Network

- 컨테이너별 독립적인 네트워크 네임스페이스
- 내부 IP할당, 포트 매핑 필요
- 컨테이너 간 격리 및 보안성 향상
- 사용자 정의 네트워크로 컨테이너 간 통신 관리 가능

### Host Network

- 호스트의 네트워크를 직접 사용
- 포트 매핑 불필요, 네트워크 성능 향상
- 네트워크 격리 없음 (보안에 취약)
- 포트 충돌 가능성

## Docker Volumes vs Bind Mounts

### Docker Volumes

- Docker가 관리하는 저장소 (/var/lib/docker/volumes/)
- 컨테이너 간 데이터 공유에 최적화
- 백업, 마이그레이션 용이
- 호스트 파일 시스템과 독립적
- docker volume create 명령으로 생성

### Bind Mounts

- 호스트의 특정 경로를 컨테이너에 직접 마운트
- 호스트 파일 시스템 구조에 의존적
- 개발 환경에서 실시간 코드 수정에 유용
- 호스트 경로에 직접 접근 가능 (/home/user/data:/data)
- 보안상 주의 필요 (호스트 파일 시스템 노출)

## 📚 참고 자료

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress Documentation](https://wordpress.org/documentation/)
- [MariaDB Documentation](https://mariadb.org/documentation/)
- [WP-CLI Documentation](https://wp-cli.org/)

## 👤 작성자

- **42 Intra:** jechoi
- **프로젝트:** Inception

## 📝 라이선스

This project is part of the 42 School curriculum.
