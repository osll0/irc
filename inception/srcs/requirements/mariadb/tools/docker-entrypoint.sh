#!/bin/bash
set -e

echo "=== MariaDB Initialization Script ==="

if [ -z "$MARIADB_ROOT_PASSWORD" ] || [ -z "$MARIADB_DATABASE" ] || [ -z "$MARIADB_USER" ] || [ -z "$MARIADB_PASSWORD" ]; then
	echo "Error: Required environment variables are not set."
	exit 1
fi

DATADIR="/var/lib/mysql"
SOCKET="/run/mysqld/mysqld.sock"

if [ ! -d "$DATADIR/mysql" ]; then
	echo "Inception: Initializing MariaDB system tables..."
	mariadb-install-db --user=mysql --datadir="$DATADIR"
fi

# 임시 서버 실행
gosu mysql mariadbd --skip-networking --socket=/run/mysqld/mysqld.sock &
pid="$!"

echo "Inception: Waiting for MariaDB to start..."
for i in $(seq 30); do
	mysqladmin --socket=/run/mysqld/mysqld.sock ping 2>/dev/null && break
	sleep 1
done

# DB와 사용자가 초기화되었는지 확인
if [ ! -d "$DATADIR/$MARIADB_DATABASE" ]; then
	echo "Inception: Creating database and user..."

	mariadb --socket=/run/mysqld/mysqld.sock <<-EOF
			CREATE DATABASE IF NOT EXISTS $MARIADB_DATABASE;
			CREATE USER IF NOT EXISTS '$MARIADB_USER'@'%' IDENTIFIED BY '$MARIADB_PASSWORD';
			GRANT ALL PRIVILEGES ON $MARIADB_DATABASE.* TO '$MARIADB_USER'@'%';
			ALTER USER 'root'@'localhost' IDENTIFIED BY '$MARIADB_ROOT_PASSWORD';
			FLUSH PRIVILEGES;
	EOF
else
	echo "Inception: Database already exists. Skipping initializing..."
fi
	
kill "$pid"
wait "$pid"
	
echo "Inception: Initialization complete!"

# 쉘 스트립트가 사라지고 mariadbd가 pid1이 됨
exec gosu mysql "$@"