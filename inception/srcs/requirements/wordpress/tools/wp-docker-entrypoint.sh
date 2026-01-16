#!/bin/sh
set -e

WP_PATH="/var/www/html"

echo "=== WordPress Initialization Script ==="

if [ -z "$WORDPRESS_DB_HOST" ] || [ -z "$WORDPRESS_DB_NAME" ] || [ -z "$WORDPRESS_DB_USER" ] || [ -z "$WORDPRESS_DB_PASSWORD" ] || [ -z "$DOMAIN_NAME" ] || [ -z "$WORDPRESS_TITLE" ] || [ -z "$WORDPRESS_ADMIN_USER" ]; then
	echo "Inception: Required environment variables are not set."
	exit 1
fi

echo "Inception: Waiting for MariaDB to be ready..."
until mysqladmin ping \
		-h"${WORDPRESS_DB_HOST%%:*}" \
		-P"${WORDPRESS_DB_HOST##*:}" \
		-u"$WORDPRESS_DB_USER" \
		-p"$WORDPRESS_DB_PASSWORD" \
		--silent; do
	sleep 1
done
echo "Inception: MariaDB is ready."

if [ ! -f "$WP_PATH/wp-config.php" ]; then
	echo "Inception: WordPress not configured. Installing..."

	wp core download --path="$WP_PATH" --allow-root

	wp config create \
		--path="$WP_PATH" \
		--dbname="$WORDPRESS_DB_NAME" \
		--dbuser="$WORDPRESS_DB_USER" \
		--dbpass="$WORDPRESS_DB_PASSWORD" \
		--dbhost="$WORDPRESS_DB_HOST" \
		--skip-check \
		--allow-root
	
	wp core install \
		--path="$WP_PATH" \
		--url="https://$DOMAIN_NAME" \
		--title="$WORDPRESS_TITLE" \
		--admin_user="$WORDPRESS_ADMIN_USER" \
		--admin_password="$WORDPRESS_ADMIN_PASSWORD" \
		--admin_email="$WORDPRESS_ADMIN_EMAIL" \
		--skip-email \
		--allow-root

	# Create additional user if specified
	if [ -n "$WORDPRESS_USER" ] && [ -n "$WORDPRESS_USER_PASSWORD" ] && [ -n "$WORDPRESS_USER_EMAIL" ]; then
		echo "Inception: Creating additional user..."
		wp user create "$WORDPRESS_USER" "$WORDPRESS_USER_EMAIL" \
			--role=editor \
			--user_pass="$WORDPRESS_USER_PASSWORD" \
			--path="$WP_PATH" \
			--allow-root
	fi

	# Copy fewer-wpcom theme if exists
	if [ -d "/tmp/fewer-wpcom" ]; then
		echo "Inception: Installing fewer-wpcom theme..."
		cp -r /tmp/fewer-wpcom "$WP_PATH/wp-content/themes/"
		wp theme activate fewer-wpcom --path="$WP_PATH" --allow-root
	fi

	chown -R www-data:www-data "$WP_PATH"

	echo "Inception: WordPress installation completed."
else
	echo "Inception: WordPress already installed. Skipping setup."
fi

exec "$@"