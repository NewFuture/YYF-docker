#!/bin/sh

set -e

#项目目录
WORK_DIR=${WORK_DIR:-'/yyf/'}
#数据库目录
MYSQL_DIR=${MYSQL_DIR:-"${WORK_DIR}runtime/mysql"}
#MYSQL_初始化脚本
MYSQL_SCRIPT=${MYSQL_SCRIPT:-"${WORK_DIR}tests/mysql.sql"}
#SQLite数据库存放位置
SQLITE_FILE=${SQLITE_FILE:-"${WORK_DIR}runtime/yyf.db"}
DEMO_SQL=${WORK_DIR}tests/yyf.sql

WEB_ROOT=${WEB_ROOT:-"${WORK_DIR}public"}
PORT=${PORT:-80}

tempSqlFile='/tmp/mysql-init.sql'

# start redis
redis-server &
memcached -u memcached &

#init and start mysql
[ -d "/run/mysqld" ] || mkdir -p /run/mysqld;
[ -d "$MYSQL_DIR" ] || mkdir -p $MYSQL_DIR;
chown -R mysql:mysql "$MYSQL_DIR" /run/mysqld;

[ -f "$MYSQL_DIR/mysql-bin.index" ] || MYSQL_FIRST_RUN=true
if [ $MYSQL_FIRST_RUN ] || [ $MYSQL_ACCOUNT ];then
    MYSQL_ACCOUNT=${MYSQL_ACCOUNT:-'root'}
    [ $MYSQL_PASSWORD ]&&IDENTIFIED_BY="IDENTIFIED BY '$MYSQL_PASSWORD'"
    mysql_install_db --user=mysql --skip-name-resolve --datadir="$MYSQL_DIR";
    echo -e "DROP DATABASE IF EXISTS test;\nDROP USER IF EXISTS '$MYSQL_ACCOUNT';\nFLUSH PRIVILEGES;">"$tempSqlFile";
    echo "CREATE USER '$MYSQL_ACCOUNT'@'%' ${IDENTIFIED_BY};">>"$tempSqlFile";
    echo -e "GRANT ALL ON *.* TO '$MYSQL_ACCOUNT'@'%';\nFLUSH PRIVILEGES;">>"$tempSqlFile";
    MYSQL_PARAM="--init-file=$tempSqlFile"
fi;
mysqld -u mysql --datadir "$MYSQL_DIR" $MYSQL_PARAM &
#MYSQL 账号
MYSQL_ACCOUNT=${MYSQL_ACCOUNT:-'root'};
# waiting for mysqld
while [ ! -S "/run/mysqld/mysqld.sock" ];do
    sleep 0.5;
done
echo 'MariaDB (MySQL) is runing';
if [ $MYSQL_FIRST_RUN ];then
    echo "import database"
    [ $MYSQL_PASSWORD ]&& RUN_PASSWORD="-p$MYSQL_PASSWORD"
    [ -f "$DEMO_SQL" ]&& sed '/^\/\*MYSQL/d;/MYSQL\*\//d' "$DEMO_SQL"|mysql -u$MYSQL_ACCOUNT $RUN_PASSWORD;
    [ -f $MYSQL_SCRIPT ]&& mysql -u$MYSQL_ACCOUNT $RUN_PASSWORD mysql < $MYSQL_SCRIPT
fi;

# 初始化SQLite数据库
if [ -f "$SQLITE_FILE" ];then #文件不存在在自动初始化
    if [ $SQLITE_SCRIPT ]; then
        cat "$SQLITE_SCRIPT" | sqlite3 "$SQLITE_FILE";
    elif [ -f "${WORK_DIR}tests/yyf.sql" ]; then
        sed '/^\/\*SQLITE/d;/SQLITE\*\//d' "${WORK_DIR}tests/yyf.sql" | sqlite3 "$SQLITE_FILE";
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

# run php server
php -S 0.0.0.0:$PORT $([ -d $WEB_ROOT ]&&echo "-t $WEB_ROOT")
