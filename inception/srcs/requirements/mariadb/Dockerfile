FROM debian:12

RUN apt-get update && apt-get install -y \
	mariadb-server \
	mariadb-client \
	gosu \
	&& rm -rf /var/lib/apt/lists/*

# mysql 시스템 유저 확인 (이미 존재하지만 명시적으로 보장)
RUN usermod -d /var/lib/mysql mysql

RUN mkdir -p /var/lib/mysql /run/mysqld \
	&& chown -R mysql:mysql /var/lib/mysql /run/mysqld \
	&& chmod 1777 /run/mysqld

# MariaDB 설정 (외부 접속 허용)
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

COPY tools/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT [ "/usr/local/bin/docker-entrypoint.sh" ]
CMD ["mariadbd"]