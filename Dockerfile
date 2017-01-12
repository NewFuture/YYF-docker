FROM newfuture/yaf:latest
MAINTAINER New Future <docker@newfuture.cc>

LABEL Name="YYF-docker" Description="mimimal docker image for YYF"

# Environments
ENV PORT=80 \
	TIMEZONE=UTC \
	MAX_UPLOAD=50M 

# instal PHP
RUN	PHP_INI='/etc/php5/php.ini' \
	&& PHP_CONF='/etc/php5/conf.d' \
	&& apk add --no-cache \
	# instal redis and mysql
		redis \
		mariadb \
	# ClEAN
	&& rm -rf /var/cache/apk/* \
		/var/tmp/* \
		/tmp/* \
		/etc/ssl/certs/*.pem \
		/etc/ssl/certs/*.0 \
		/usr/share/ca-certificates/mozilla/* \
		/usr/share/man/* \
		/usr/include/*

WORKDIR /yyf/

EXPOSE $PORT

CMD php -S 0.0.0.0:$PORT $([ ! -f index.php ]&&[ -d public ]&&echo '-t public')
