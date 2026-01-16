FROM alpine:3.18

RUN apk update && apk add --no-cache \
	php81 \
	php81-fpm \
	php81-common \
	php81-json \
	php81-session \
	php81-mysqli \
	php81-phar \
	php81-mbstring \
	php81-xml \
	php81-gd \
	php81-zip \
	mariadb-client \
	curl

RUN curl -o /usr/local/bin/wp \
	https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x /usr/local/bin/wp

RUN addgroup -S www-data || true && \
	adduser -S -D -H -G www-data www-data || true

RUN mkdir -p /var/www/html \
	&& chown -R www-data:www-data /var/www/html
RUN echo "memory_limit = 256M" >> /etc/php81/php.ini

WORKDIR /var/www/html

COPY ./conf/www.conf /etc/php81/php-fpm.d/www.conf
COPY ./tools/wp-docker-entrypoint.sh /usr/local/bin/wp-docker-entrypoint.sh
COPY ./tools/fewer-wpcom /tmp/fewer-wpcom
RUN chmod +x /usr/local/bin/wp-docker-entrypoint.sh

ENTRYPOINT [ "/usr/local/bin/wp-docker-entrypoint.sh" ]

CMD [ "/usr/sbin/php-fpm81", "-F" ]