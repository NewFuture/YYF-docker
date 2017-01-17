FROM newfuture/yaf:latest
MAINTAINER New Future <docker@newfuture.cc>
LABEL Name="YYF-docker" Description="mimimal docker image for YYF"

# Environments
ENV PORT=80 \
	TIMEZONE=UTC \
	MAX_UPLOAD=50M \
	WORK_DIR=/yyf/

# instal
RUN apk add --update\
	redis \
	memcached \
	mariadb

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

COPY ./run.sh /run.sh

CMD /run.sh
