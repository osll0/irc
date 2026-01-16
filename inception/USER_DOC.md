# 📄 사용자 문서 (User Documentation)

이 문서는 Inception 프로젝트의 서비스를 이해하고 사용하는 방법을 설명합니다.

## 📑 목차

1. [제공되는 서비스](#제공되는-서비스)
2. [프로젝트 시작 및 종료](#프로젝트-시작-및-종료)
3. [웹사이트 및 관리자 페이지 접속](#웹사이트-및-관리자-페이지-접속)
4. [인증 정보 관리](#인증-정보-관리)
5. [서비스 상태 확인](#서비스-상태-확인)

---

## 제공되는 서비스

Inception 스택은 다음 세 가지 핵심 서비스를 제공합니다:

### 1. NGINX 웹 서버

- **역할**: 웹 요청 처리 및 HTTPS 암호화 통신 담당
- **포트**: 443 (HTTPS 전용)
- **주요 기능**:
  - TLS 1.2/1.3 암호화 통신
  - HTTP/2 지원
  - WordPress로 요청 전달 (리버스 프록시)
  - 정적 파일 서빙

### 2. WordPress

- **역할**: 웹사이트 콘텐츠 관리 시스템 (CMS)
- **인터페이스**: 웹 기반 관리자 패널
- **주요 기능**:
  - 게시글 및 페이지 작성/편집
  - 테마 및 플러그인 설치
  - 미디어(이미지, 동영상) 관리
  - 사용자 계정 관리
  - 사이트 설정 관리

### 3. MariaDB 데이터베이스

- **역할**: WordPress의 모든 데이터 저장
- **저장 데이터**:
  - 게시글 및 페이지 내용
  - 사용자 정보
  - 사이트 설정
  - 플러그인 및 테마 설정
- **주요 기능**:
  - 영구 데이터 저장
  - 데이터 백업 및 복구
  - 사용자 권한 관리

### 서비스 간 관계

```
사용자 (브라우저)
    ↓ HTTPS (포트 443)
NGINX 웹 서버
    ↓ FastCGI (포트 9000)
WordPress (PHP-FPM)
    ↓ MySQL (포트 3306)
MariaDB 데이터베이스
```

---

## 프로젝트 시작 및 종료

### 프로젝트 시작하기

터미널에서 프로젝트 디렉토리로 이동 후 다음 명령어를 실행합니다:

```bash
make
```

이 명령어는 자동으로 다음 작업을 수행합니다:

1. 데이터 저장 디렉토리 생성 (`/home/$USER/data/mariadb`, `/home/$USER/data/wordpress`)
2. 도메인을 `/etc/hosts` 파일에 추가 (sudo 비밀번호 입력 필요)
3. Docker 이미지 빌드
4. 컨테이너 시작 (MariaDB → WordPress → NGINX 순서)

### 프로젝트 종료하기

모든 서비스를 중지하려면:

```bash
make down
```

**중요:** `make down`은 컨테이너만 중지하며, **데이터는 보존**됩니다.

### 프로젝트 재시작하기

서비스를 재시작하려면:

```bash
make down && make up
```

### 완전히 초기화하기

모든 데이터를 삭제하고 새로 시작하려면:

```bash
make re
```

**⚠️ 경고:** `make clean`, `make re`은 데이터베이스와 WordPress 파일을 **모두 삭제**합니다.

---

## 웹사이트 및 관리자 페이지 접속

### 웹사이트 접속하기

1. **브라우저를 열고** 설정한 도메인으로 접속합니다 (기본값: `https://jechoi.42.fr`)

2. **SSL 보안 경고 처리**:

   - 자체 서명 인증서를 사용하므로 보안 경고가 나타납니다
   - **Chrome/Edge**: "고급" → "jechoi.42.fr(으)로 이동"
   - **Firefox**: "고급" → "위험을 감수하고 계속"
   - **Safari**: "세부 정보 보기" → "웹 사이트 방문"

3. **WordPress 홈페이지가 표시됩니다**

### WordPress 관리자 페이지 접속하기

1. **관리자 페이지 URL**:

   ```
   https://jechoi.42.fr/wp-admin
   ```

2. **로그인 정보 입력**:

   - 사용자명: `.env` 파일의 `WORDPRESS_ADMIN_USER` 값 (기본: `wpowner`)
   - 비밀번호: `.env` 파일의 `WORDPRESS_ADMIN_PASSWORD` 값

3. **관리자 패널 주요 메뉴**:
   - **대시보드**: 사이트 통계 및 개요
   - **글**: 블로그 게시글 작성/관리
   - **미디어**: 이미지 및 파일 업로드/관리
   - **페이지**: 정적 페이지 작성 (예: About, Contact)
   - **외관**: 테마 변경 및 디자인 커스터마이징
   - **플러그인**: 기능 확장을 위한 플러그인 설치
   - **사용자**: 사용자 계정 관리
   - **설정**: 사이트 전반 설정

---

## 인증 정보 관리

### 인증 정보 저장 위치

모든 계정 정보는 `srcs/.env` 파일에 저장되어 있습니다.

**보안 중요:** 이 파일은 민감한 정보를 포함하므로 Git에 커밋되지 않습니다.

### 현재 인증 정보 확인하기

```bash
cat srcs/.env
```

### 생성되는 계정

시스템은 WordPress에 두 개의 계정을 자동으로 생성합니다:

#### 1. 관리자 계정 (Administrator)

- **사용자명**: `WORDPRESS_ADMIN_USER` (예: `wpowner`)
- **비밀번호**: `WORDPRESS_ADMIN_PASSWORD`
- **이메일**: `WORDPRESS_ADMIN_EMAIL`
- **권한**: 모든 관리 권한 (사이트 전체 제어)

#### 2. 일반 사용자 계정 (Author)

- **사용자명**: `WORDPRESS_USER` (예: 시스템 사용자명)
- **비밀번호**: `WORDPRESS_USER_PASSWORD`
- **이메일**: `WORDPRESS_USER_EMAIL`
- **권한**: 작성자 권한 (게시글 작성 및 발행 가능)

### 비밀번호 변경하기

#### 방법 1: WordPress 관리자 패널에서 변경 (권장)

1. 관리자로 로그인
2. **사용자** → **모든 사용자** 메뉴로 이동
3. 수정할 사용자 클릭
4. **계정 관리** 섹션으로 스크롤
5. **새 비밀번호 생성** 클릭 또는 직접 입력
6. **사용자 업데이트** 클릭

#### 방법 2: 명령어로 비밀번호 재설정

```bash
# 관리자 비밀번호 변경
docker exec mywp wp user update wpowner --user_pass=새비밀번호 --allow-root

# 일반 사용자 비밀번호 변경
docker exec mywp wp user update 사용자명 --user_pass=새비밀번호 --allow-root
```

#### 방법 3: .env 파일 수정 (새 설치 시에만 유효)

**주의:** 이 방법은 초기 설치 시에만 적용됩니다. 이미 설치된 경우 방법 1 또는 2를 사용하세요.

1. `.env` 파일 편집:

   ```bash
   nano srcs/.env
   ```

2. 비밀번호 변수 수정:

   ```bash
   WORDPRESS_ADMIN_PASSWORD=새로운_관리자_비밀번호
   WORDPRESS_USER_PASSWORD=새로운_사용자_비밀번호
   ```

3. 완전 재구축:
   ```bash
   make clean
   make
   ```

### 데이터베이스 접속 정보

일반 사용자는 데이터베이스에 직접 접속할 필요가 없습니다. 개발자나 관리자가 필요한 경우:

- **Root 계정**: `root` / `MARIADB_ROOT_PASSWORD`
- **WordPress 계정**: `MARIADB_USER` / `MARIADB_PASSWORD`
- **관리자 계정**: `MARIADB_ADMIN_USER` / `MARIADB_ADMIN_PASSWORD`

**데이터베이스 접속 방법:**

```bash
docker exec -it mydb mysql -u root -p
# MARIADB_ROOT_PASSWORD 입력
```

---

## 서비스 상태 확인

### 빠른 상태 확인

모든 컨테이너가 실행 중인지 확인:

```bash
docker ps
```

**정상 출력 예시:**

```
CONTAINER ID   IMAGE              STATUS          PORTS                  NAMES
abc123def456   srcs-nginx         Up 2 minutes    0.0.0.0:443->443/tcp   mynginx
def456ghi789   srcs-wordpress     Up 2 minutes    9000/tcp               mywp
ghi789jkl012   srcs-mariadb       Up 2 minutes    3306/tcp               mydb
```

**확인 사항:**

- 세 개의 컨테이너가 모두 표시됨 (`mynginx`, `mywp`, `mydb`)
- STATUS가 "Up"으로 표시 ("Restarting"이 아님)
- 포트 매핑이 올바름 (NGINX만 443 포트 노출)

### 개별 서비스 확인

#### NGINX 확인

```bash
# NGINX 로그 확인
docker logs mynginx

# NGINX 설정 검증
docker exec mynginx nginx -t
```

**정상 출력:**

```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

#### WordPress 확인

```bash
# WordPress 로그 확인
docker logs mywp

# PHP-FPM 프로세스 확인
docker exec mywp ps aux | grep php-fpm
```

**정상 출력:** 여러 개의 php-fpm 프로세스가 실행 중

#### MariaDB 확인

```bash
# MariaDB 로그 확인
docker logs mydb

# 데이터베이스 연결 테스트
docker exec mydb mysql -u root -p${MARIADB_ROOT_PASSWORD} -e "SHOW DATABASES;"
```

**정상 출력:** `wordpress` 데이터베이스가 목록에 표시됨

### 웹사이트 접속 테스트

```bash
# HTTPS 연결 테스트 (자체 서명 인증서 무시)
curl -k https://jechoi.42.fr

# WordPress 응답 확인
curl -k https://jechoi.42.fr/wp-admin/
```

**정상 출력:** HTML 코드가 반환됨

---

## 🔧 일반적인 문제 해결

### 문제 1: 웹사이트에 접속할 수 없음

**증상:** 브라우저에서 "사이트에 연결할 수 없음" 오류

**해결 방법:**

1. `/etc/hosts`에 도메인이 추가되었는지 확인:

   ```bash
   cat /etc/hosts | grep jechoi.42.fr
   ```

   없으면 다시 설정:

   ```bash
   make setup
   ```

2. 컨테이너가 실행 중인지 확인:

   ```bash
   docker ps
   ```

3. 포트 443이 열려있는지 확인:
   ```bash
   sudo netstat -tlnp | grep 443
   ```

### 문제 2: "데이터베이스 연결 오류" 표시

**증상:** WordPress에서 "Error Establishing Database Connection" 오류

**해결 방법:**

1. MariaDB 컨테이너 실행 확인:

   ```bash
   docker ps | grep mydb
   ```

2. MariaDB 로그 확인:

   ```bash
   docker logs mydb
   ```

3. 서비스 재시작:
   ```bash
   make down && make up
   ```

### 문제 3: 컨테이너가 계속 재시작됨

**증상:** `docker ps`에서 STATUS가 "Restarting" 표시

**해결 방법:**

1. 로그에서 오류 확인:

   ```bash
   docker logs mydb
   docker logs mywp
   docker logs mynginx
   ```

2. 데이터 디렉토리 권한 확인:

   ```bash
   ls -la /home/$USER/data/
   ```

   권한 수정:

   ```bash
   sudo chown -R $USER:$USER /home/$USER/data/
   ```

3. 완전 재구축:
   ```bash
   make clean
   make
   ```

### 문제 4: 관리자 비밀번호를 잊어버림

**해결 방법:**

명령어로 비밀번호 재설정:

```bash
docker exec mywp wp user update wpowner --user_pass=새비밀번호 --allow-root
```

### 문제 5: "Permission Denied" 오류

**증상:** 파일 접근 권한 오류

**해결 방법:**

```bash
# 데이터 디렉토리 소유권 수정
sudo chown -R $USER:$USER /home/$USER/data/

# 권한 확인
ls -la /home/$USER/data/
```

---

## 📚 유용한 명령어 모음

### 로그 확인

```bash
# 모든 서비스 로그 확인
docker compose -f srcs/docker-compose.yml logs

# 실시간 로그 모니터링
docker compose -f srcs/docker-compose.yml logs -f

# 특정 서비스 로그만 확인
docker logs mynginx
docker logs mywp
docker logs mydb

# 최근 50줄만 확인
docker logs --tail 50 mynginx
```

### 데이터 백업

```bash
# 데이터베이스 백업
docker exec mydb mysqldump -u root -p${MARIADB_ROOT_PASSWORD} wordpress > backup_$(date +%Y%m%d).sql

# WordPress 파일 백업
tar -czf wordpress_backup_$(date +%Y%m%d).tar.gz /home/$USER/data/wordpress/

# MariaDB 데이터 디렉토리 백업
tar -czf mariadb_backup_$(date +%Y%m%d).tar.gz /home/$USER/data/mariadb/
```

### 데이터 복구

```bash
# 데이터베이스 복구
docker exec -i mydb mysql -u root -p${MARIADB_ROOT_PASSWORD} wordpress < backup_20260116.sql

# WordPress 파일 복구
make down
rm -rf /home/$USER/data/wordpress/*
tar -xzf wordpress_backup_20260116.tar.gz -C /
make up
```

---

## 🆘 추가 도움말

- 프로젝트 개요: [README.md](README.md)
- 개발자 기술 문서: [DEV_DOC.md](DEV_DOC.md)
- 로그 확인: `docker logs <컨테이너명>`
- 전체 상태 확인: `docker compose -f srcs/docker-compose.yml ps -a`

---

**작성자:** jechoi
**프로젝트:** Inception
