FROM newfuture/yaf:latest
MAINTAINER New Future <docker@newfuture.cc>
LABEL Name="YYF-docker" Description="docker image for YYF"

# Environments
ENV PORT=80 \
	TIMEZONE=UTC \
	MAX_UPLOAD=50M \
	WORK_DIR=/yyf/

#dev environment
RUN echo "yaf.environ=dev">"/etc/php*/conf.d/*.yaf.ini" \
	&& CHANGE_INI(){ \
	if [ $(cat "$1" | grep -c "^\s*$2") -eq 0 ] ; then \
		echo "$2=$3" >> "$1"; \
	else \ 
		sed -i.bak -e "s/^\s*$2.*$/$2=$3/" "$1";\
	fi;	}\
	&& PHP_INI=$(php --ini|grep -oPm1  "/.*php\.ini$") \
	&& CHANGE_INI $PHP_INI display_errors 1 \
	&& CHANGE_INI $PHP_INI display_startup_errors 1 \
	&& CHANGE_INI $PHP_INI log_errors 1 \
	&& CHANGE_INI $PHP_INI assert.active 1 \
	&& CHANGE_INI $PHP_INI zend.assertions 1

# instal
RUN apk add --update
RUN apk add --no-cache redis memcached
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

COPY ./run.sh /run.sh

CMD /run.sh
