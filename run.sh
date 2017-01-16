#!/bin/sh

set -e

WORK_DIR=${WORK_DIR:-'/yyf/'}
MYSQL_DIR=${MYSQL_DIR:-"${WORK_DIR}runtime/mysql"}
MYSQL_USER=${MYSQL_USER:-'root'}
MYSQL_SCRIPT=${MYSQL_SCRIPT:-"${WORK_DIR}tests/mysql.sql"}
SQLITE_FILE=${SQLITE_FILE:-"${WORK_DIR}runtime/yyf.db"}

WEB_ROOT=${WEB_ROOT:-"${WORK_DIR}public"}
tempSqlFile='/tmp/mysql-init.sql'

# start redis
redis-server &
memcached -u memcached &

#init and start mysql
[ -d "/run/mysqld" ] || mkdir -p /run/mysqld;
[ -d "$MYSQL_DIR" ] || mkdir -p $MYSQL_DIR;
chown -R mysql:mysql "$MYSQL_DIR" /run/mysqld;
if ! [ -f "$MYSQL_DIR/mysql-bin.index" ] ;then
    mysql_install_db --user=mysql --skip-name-resolve --datadir="$MYSQL_DIR";
fi
echo -e "DELETE FROM mysql.user;\nFLUSH PRIVILEGES;">"$tempSqlFile";
if [ $MYSQL_PASSWORD ];then
    echo "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';">>"$tempSqlFile";
else
    echo "CREATE USER '$MYSQL_USER'@'%';">>"$tempSqlFile";
fi;
echo -e "GRANT ALL ON *.* TO '$MYSQL_USER'@'%';\nFLUSH PRIVILEGES;">>"$tempSqlFile";
mysqld -u mysql --datadir "$MYSQL_DIR" --init-file="$tempSqlFile" &

# init SQLITE
if [ -f "$SQLITE_FILE" ];then #文件不存在在自动初始化
    if [ $SQLITE_SCRIPT ]; then
        cat "$SQLITE_SCRIPT" | sqlite3 $SQLITE_FILE;
    elif [ -f "$DEMO_SQL" ]; then
        sed '/^\/\*SQLITE/d;/SQLITE\*\//d' "$DEMO_SQL" | sqlite3 $SQLITE_FILE;
    fi
fi;

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
