#!/bin/sh

set -e

WORK_DIR=${WORK_DIR:-'/yyf'}
MYSQL_DIR=${MYSQL_DIR:-"$WORK_DIR/runtime/mysql"}
MYSQL_USER=${MYSQL_USER:-'root'}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-''}
WEB_ROOT=${WEB_ROOT:-"$WORK_DIR/public"}
MYSQL_SCRIPT=${MYSQL_SCRIPT:-"$WORK_DIR/tests/mysql.sql"}
tempSqlFile='/tmp/mysql-first-time.sql'

# start redis
redis-server &
memcached -u memcached &

#start mysql
[ -d "/run/mysqld" ] || mkdir -p /run/mysqld;
[ -d "$MYSQL_DIR" ] || mkdir -p $MYSQL_DIR;
chown -R mysql:mysql "$WORK_DIR" /run/mysqld
test -f "$MYSQL_DIR/mysql-bin.index" || mysql_install_db --user=mysql --datadir="$MYSQL_DIR"
echo "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';">"$tempSqlFile";
echo "GRANT ALL ON *.* TO '$MYSQL_USER'@'%';">>"$tempSqlFile";
echo 'FLUSH PRIVILEGES ;' >> "$tempSqlFile";
test -f $MYSQL_SCRIPT && echo "source $MYSQL_SCRIPT ;">>"$tempSqlFile";
if [ -f '$WORK_DIR/tests/yyf.sql' ];then
    sed '/^\/\*MYSQL/d;/MYSQL\*\//d' tests/yyf.sql >> "$tempSqlFile";
    # sed '/^\/\*SQLITE/d;/SQLITE\*\//d' tests/yyf.sql | sqlite3 runtime/yyf.db;
fi;
mysqld_safe --skip-grant-tables --skip-networking &
mysqld -u mysql --datadir "$MYSQL_DIR" --init-file="$tempSqlFile" &

# run init script in tests
for file in tests/init.* ;do
    if test -f $file && test -x $file ;then
        $file;
    fi
done;
for file in tests/*.sh; do
    if [ -d $file ] || [ "$file"==="tests/init.sh" ];then
        continue;
    elif test -x $file ;then
        $file;
    else 
        sh "$file";
    fi
done;

# run
php -S 0.0.0.0:$PORT  $([ -d $WEB_ROOT ]&&echo "-t $WEB_ROOT") &
echo php server start
# exec "$@"
