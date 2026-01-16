FROM alpine:3.18

RUN apk update && \
	apk add --no-cache nginx openssl && \
	rm -rf /var/cache/apk/*

RUN mkdir -p /etc/nginx/ssl /run/nginx

COPY conf/default.conf /etc/nginx/http.d/default.conf

COPY tools/ng-docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/ng-docker-entrypoint.sh

ENTRYPOINT [ "/usr/local/bin/ng-docker-entrypoint.sh" ]

CMD [ "nginx", "-g", "daemon off;" ]