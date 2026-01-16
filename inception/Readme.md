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

## 🏗️ 아키텍처

```
┌─────────────────────────────────────────┐
│          NGINX (Alpine 3.18)            │
│     - Port: 443 (HTTPS only)            │
│     - TLS 1.2/1.3                       │
│     - Reverse Proxy                     │
└──────────────┬──────────────────────────┘
               │ FastCGI
               ▼
┌─────────────────────────────────────────┐
│       WordPress (Alpine 3.18)           │
│     - PHP 8.1 + PHP-FPM                 │
│     - WP-CLI                            │
│     - Port: 9000                        │
└──────────────┬──────────────────────────┘
               │ MySQL Protocol
               ▼
┌─────────────────────────────────────────┐
│       MariaDB (Ubuntu 22.04)            │
│     - Port: 3306                        │
│     - Database: wordpress               │
└─────────────────────────────────────────┘
```

## 📁 프로젝트 구조

```
cin/
├── Makefile                    # 빌드 및 실행 자동화
├── Readme.md                   # 프로젝트 문서
├── secrets/                    # 민감 정보 (git에서 제외)
└── srcs/
    ├── .env                    # 환경변수 설정
    ├── docker-compose.yml      # Docker Compose 설정
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/default.conf
        │   └── tools/ng-docker-entrypoint.sh
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/www.conf
        │   └── tools/wp-docker-entrypoint.sh
        └── mariadb/
            ├── Dockerfile
            ├── conf/50-server.cnf
            └── tools/docker-entrypoint.sh
```

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

### 4. 정리

```bash
# 컨테이너 중지
make down

# 컨테이너 및 볼륨 삭제, hosts 항목 제거
make clean

# 전체 재시작 (clean + all)
make re
```

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
```

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
- **과정:** 42Seoul

## 📝 라이선스

This project is part of the 42 School curriculum.
