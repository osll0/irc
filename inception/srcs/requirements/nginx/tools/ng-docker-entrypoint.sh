#!/bin/sh
set -e

echo "=== Nginx Script ==="

if [ ! -f /etc/nginx/ssl/nginx.crt ]; then
	echo "Inception: Generating SSL certificate..."
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout /etc/nginx/ssl/nginx.key \
		-out /etc/nginx/ssl/nginx.crt \
		-subj "/C=KR/ST=Seoul/L=Seoul/O=42Seoul/OU=Inception/CN=${DOMAIN_NAME:-localhost}"
	echo "Inception: SSL certificate generated!"
else
	echo "Inception: SSL certificate already exists"
fi

chmod 600 /etc/nginx/ssl/nginx.key
chmod 644 /etc/nginx/ssl/nginx.crt

if [ -n "${DOMAIN_NAME}" ]; then
	echo "Inception: Setting domain name to ${DOMAIN_NAME}..."
	sed -i "s/server_name localhost;/server_name ${DOMAIN_NAME};/g" /etc/nginx/http.d/default.conf
fi

echo "Inception: Testing NGINX configuration..."
nginx -t
echo "Inception: NGINX setup complete!"

exec "$@"