# 📄 개발자 문서 (Developer Documentation)

이 문서는 Inception 프로젝트를 처음부터 설정하고 관리하는 방법을 설명합니다.

## 📑 목차

1. [환경 설정](#환경-설정)
2. [빌드 및 실행](#빌드-및-실행)
3. [컨테이너 및 볼륨 관리](#컨테이너-및-볼륨-관리)
4. [데이터 영속성](#데이터-영속성)

---

## 환경 설정

### 필수 조건

- Docker Engine (20.10 이상)
- Docker Compose (v2.0 이상)
- Linux/Unix 환경 (macOS, Ubuntu 등)
- sudo 권한 (hosts 파일 수정을 위해)

### 초기 설정 단계

#### 1. 환경변수 파일 설정

`srcs/.env` 파일을 생성하고 다음 내용을 설정합니다:

```bash
# 시스템 설정
USER=your_username                    # 시스템 사용자명
DOMAIN_NAME=your_domain.42.fr        # 도메인 이름

# MariaDB 설정
MARIADB_ROOT_PASSWORD=secure_root_pw  # Root 비밀번호 (강력한 비밀번호 사용)
MARIADB_DATABASE=wordpress            # WordPress 데이터베이스 이름
MARIADB_USER=wpuser                   # WordPress 데이터베이스 사용자
MARIADB_PASSWORD=secure_user_pw       # 사용자 비밀번호
MARIADB_ADMIN_USER=dbmanager          # 관리자 계정
MARIADB_ADMIN_PASSWORD=secure_admin_pw # 관리자 비밀번호

# WordPress 설정
WORDPRESS_DB_HOST=mariadb:3306        # DB 호스트 (서비스명:포트)
WORDPRESS_DB_NAME=wordpress           # MARIADB_DATABASE와 동일
WORDPRESS_DB_USER=wpuser              # MARIADB_USER와 동일
WORDPRESS_DB_PASSWORD=secure_user_pw  # MARIADB_PASSWORD와 동일

WORDPRESS_ADMIN_USER=wpowner          # WordPress 관리자 계정
WORDPRESS_ADMIN_PASSWORD=admin_pw     # 관리자 비밀번호
WORDPRESS_ADMIN_EMAIL=admin@42.fr     # 관리자 이메일

WORDPRESS_USER=your_username          # 일반 사용자 계정
WORDPRESS_USER_PASSWORD=user_pw       # 일반 사용자 비밀번호
WORDPRESS_USER_EMAIL=user@42.fr       # 일반 사용자 이메일

# 사이트 설정
WORDPRESS_TITLE=My Inception Site     # 사이트 제목
```

**중요 사항:**

- `.env` 파일은 Git에 커밋하지 않습니다 (`.gitignore`에 포함되어 있음)
- 모든 비밀번호는 강력한 조합(영문, 숫자, 특수문자)으로 설정하세요
- `MARIADB_*`와 `WORDPRESS_DB_*` 설정이 일치해야 합니다

---

## 빌드 및 실행

### Makefile을 사용한 빌드

프로젝트는 Makefile을 통해 간편하게 관리할 수 있습니다:

```bash
# 전체 빌드 및 실행 (기본 명령)
make

# 또는 개별 명령어
make setup      # 데이터 디렉토리 생성 및 hosts 파일 설정
make up         # 컨테이너 빌드 및 실행
make down       # 컨테이너 중지 (데이터는 보존)
make clean      # 컨테이너, 볼륨, 데이터 모두 삭제
make re         # 전체 재빌드 (clean + all)
```

### Docker Compose 직접 사용

더 세밀한 제어가 필요한 경우:

```bash
# 이미지 빌드
docker compose -f srcs/docker-compose.yml build

# 컨테이너 시작 (백그라운드)
docker compose -f srcs/docker-compose.yml up -d

# 컨테이너 중지
docker compose -f srcs/docker-compose.yml down

# 로그 확인 (실시간)
docker compose -f srcs/docker-compose.yml logs -f

# 특정 서비스만 재빌드 (캐시 사용 안 함)
docker compose -f srcs/docker-compose.yml build --no-cache nginx

# 특정 서비스만 재시작
docker compose -f srcs/docker-compose.yml restart wordpress
```

---

## 컨테이너 및 볼륨 관리

### 주요 컨테이너 명령어

#### 컨테이너 상태 확인

````bash
# 실행 중인 컨테이너 목록
docker ps

# 모든 컨테이너 목록 (중지된 것 포함)
docker ps -a

#### 컨테이너 접속

```bash
# 컨테이너 쉘 접속
docker exec -it mydb /bin/bash       # MariaDB (Ubuntu 기반)
docker exec -it mywp /bin/sh         # WordPress (Alpine 기반)
docker exec -it mynginx /bin/sh      # NGINX (Alpine 기반)

# 단일 명령 실행
docker exec mydb mysql -u root -p${MARIADB_ROOT_PASSWORD} -e "SHOW DATABASES;"
docker exec mywp wp --info --allow-root
docker exec mynginx nginx -t
````

#### 로그 확인

```bash
# 전체 로그 출력
docker logs mydb
docker logs mywp
docker logs mynginx

# 실시간 로그 모니터링
docker logs -f mywp

# 마지막 50줄만 출력
docker logs --tail 50 mynginx

# 타임스탬프 포함
docker logs -t mydb
```

#### 컨테이너 재시작

```bash
# 개별 컨테이너 재시작
docker restart mydb
docker restart mywp
docker restart mynginx

# 모든 서비스 재시작
docker compose -f srcs/docker-compose.yml restart

# 특정 서비스만 재시작
docker compose -f srcs/docker-compose.yml restart wordpress
```

### 볼륨 관리

#### 볼륨 정보 확인

```bash
# Docker 볼륨 목록
docker volume ls

# 볼륨 상세 정보
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_data

# 호스트 시스템에서 데이터 확인
ls -la /home/$USER/data/mariadb/
ls -la /home/$USER/data/wordpress/

# 볼륨 사용량 확인
du -sh /home/$USER/data/mariadb/
du -sh /home/$USER/data/wordpress/
```

#### 볼륨 백업

```bash
# 전체 데이터 백업
tar -czf inception_backup_$(date +%Y%m%d).tar.gz /home/$USER/data/

# 개별 서비스 백업
tar -czf mariadb_backup_$(date +%Y%m%d).tar.gz /home/$USER/data/mariadb/
tar -czf wordpress_backup_$(date +%Y%m%d).tar.gz /home/$USER/data/wordpress/
```

#### 권한 문제 해결

```bash
# 현재 권한 확인
ls -la /home/$USER/data/

# 권한 수정 (필요시)
sudo chown -R $USER:$USER /home/$USER/data/
```

---

## 데이터 영속성

### 데이터 저장 위치

프로젝트는 호스트 시스템의 다음 경로에 데이터를 영구 저장합니다:

```
/home/${USER}/data/
├── mariadb/                # MariaDB 데이터베이스 파일
│   ├── mysql/              # 시스템 데이터베이스
│   ├── performance_schema/ # 성능 모니터링 데이터
│   └── wordpress/          # WordPress 데이터베이스
└── wordpress/              # WordPress 웹 파일
    ├── wp-admin/           # WordPress 관리자 페이지
    ├── wp-content/         # 테마, 플러그인, 업로드 파일
    └── wp-includes/        # WordPress 코어 파일
```

### 볼륨 설정 방식

`docker-compose.yml`에서 bind mount 방식으로 설정:

```yaml
volumes:
  mariadb_data:
    driver: local # 로컬 스토리지 드라이버
    driver_opts:
      type: none # 특정 파일시스템 타입 없음
      o: bind # Bind mount 사용
      device: /home/${USER}/data/mariadb # 실제 호스트 경로

  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${USER}/data/wordpress
```

### 데이터 영속성 작동 방식

1. **MariaDB 데이터**

   - 컨테이너 내부 경로: `/var/lib/mysql`
   - 호스트 시스템 경로: `/home/$USER/data/mariadb`
   - 컨테이너가 삭제되어도 데이터베이스 파일은 호스트에 보존됨

2. **WordPress 파일**

   - 컨테이너 내부 경로: `/var/www/html`
   - 호스트 시스템 경로: `/home/$USER/data/wordpress`
   - 업로드한 이미지, 테마, 플러그인이 모두 보존됨

3. **데이터 보존 시나리오**
   - `make down`: 컨테이너만 중지, 데이터는 보존 ✅
   - `docker compose down`: 컨테이너만 삭제, 데이터는 보존 ✅
   - `docker compose down -v`: 볼륨 삭제, 데이터도 삭제 ❌
   - `make clean`: 볼륨과 데이터 모두 삭제 ❌

### 데이터 복구

```bash
# 백업 파일로부터 복구
tar -xzf inception_backup_20260116.tar.gz -C /

# 또는 개별 서비스 복구
tar -xzf mariadb_backup_20260116.tar.gz -C /home/$USER/data/
```

---

## 🔧 문제 해결

### 컨테이너가 계속 재시작되는 경우

```bash
# 로그 확인
docker logs mywp

# 컨테이너 상태 확인
docker ps -a

# 자세한 정보 확인
docker inspect mywp
```

### NGINX 502 Bad Gateway 오류

```bash
# PHP-FPM 프로세스 확인
docker exec mywp ps aux | grep php-fpm

# NGINX ↔ WordPress 연결 테스트
docker exec mynginx ping wordpress
docker exec mynginx nc -zv wordpress 9000
```

## 📚 추가 자료

- [Docker 공식 문서](https://docs.docker.com/)
- [Docker Compose 문서](https://docs.docker.com/compose/)
- [NGINX 문서](https://nginx.org/en/docs/)
- [WordPress 개발자 문서](https://developer.wordpress.org/)
- [MariaDB 문서](https://mariadb.org/documentation/)

---

**작성자:** jechoi
**프로젝트:** Inception
