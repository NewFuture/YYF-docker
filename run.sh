#!/bin/sh

set -e

WORK_DIR=${WORK_DIR:-'/yyf'}
MYSQL_DIR=${MYSQL_DIR:-"$WORK_DIR/runtime/mysql"}
MYSQL_USER=${MYSQL_USER:-'root'}
WEB_ROOT=${WEB_ROOT:-"$WORK_DIR/public"}
MYSQL_SCRIPT=${MYSQL_SCRIPT:-"$WORK_DIR/tests/mysql.sql"}

tempSqlFile='/tmp/mysql-init.sql'

# start redis
redis-server &
memcached -u memcached &

#init and start mysql
[ -d "/run/mysqld" ] || mkdir -p /run/mysqld;
chown -R mysql:mysql "$WORK_DIR" /run/mysqld;
if [ -f "$MYSQL_DIR/mysql-bin.index" ];then
    mysqld -u mysql --datadir "$MYSQL_DIR" &
else
    [ -d "$MYSQL_DIR" ] || mkdir -p $MYSQL_DIR;
    mysql_install_db --user=mysql --skip-name-resolve --datadir="$MYSQL_DIR";
    echo -e "DELETE FROM mysql.user;\nFLUSH PRIVILEGES;">"$tempSqlFile";
    if [ $MYSQL_PASSWORD ];then
        echo "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';">>"$tempSqlFile";
    else
        mysqld_safe --skip-grant-tables --skip-networking &
        echo "CREATE USER '$MYSQL_USER'@'%';">>"$tempSqlFile";
    fi;
    echo -e "GRANT ALL ON *.* TO '$MYSQL_USER'@'%';\nFLUSH PRIVILEGES;">>"$tempSqlFile";
    [ -f "$WORK_DIR/tests/yyf.sql" ]&& sed '/^\/\*MYSQL/d;/MYSQL\*\//d' "$WORK_DIR/tests/yyf.sql" >> "$tempSqlFile";
    [ -f $MYSQL_SCRIPT ]&& cat "$MYSQL_SCRIPT">>"$tempSqlFile";
    mysqld -u mysql --datadir "$MYSQL_DIR" --init-file="$tempSqlFile" &
fi;

# sed '/^\/\*SQLITE/d;/SQLITE\*\//d' tests/yyf.sql | sqlite3 runtime/yyf.db;

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
php -S 0.0.0.0:$PORT  $([ -d $WEB_ROOT ]&&echo "-t $WEB_ROOT")
