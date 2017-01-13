FROM newfuture/yaf:latest
MAINTAINER New Future <docker@newfuture.cc>

LABEL Name="YYF-docker" Description="docker image for YYF"

# Environments
ENV PORT=80 \
	TIMEZONE=UTC \
	MAX_UPLOAD=50M \
	WORK_DIR=/yyf

# instal PHP
RUN apk add --no-cache --update redis memcached 
RUN apk add --no-cache sqlite
RUN apk add --no-cache mariadb mariadb-client

# ClEAN
RUN rm -rf /var/cache/apk/* \
	/var/tmp/* \
	/tmp/* \
	/etc/ssl/certs/*.pem \
	/etc/ssl/certs/*.0 \
	/usr/share/ca-certificates/mozilla/* \
	/usr/share/man/* \
	/usr/include/*

WORKDIR $WORK_DIR

# COPY ./run.sh /run.sh

# CMD php
