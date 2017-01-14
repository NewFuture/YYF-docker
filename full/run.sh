#!/bin/sh

set -e

#项目目录
WORK_DIR=${WORK_DIR:-'/yyf/'}
#数据库目录
MYSQL_DIR=${MYSQL_DIR:-"${WORK_DIR}runtime/mysql"}
#MYSQL 账号
MYSQL_ACCOUNT=${MYSQL_ACCOUNT:-'root'}
#MYSQL_初始化脚本
MYSQL_SCRIPT=${MYSQL_SCRIPT:-"${WORK_DIR}tests/mysql.sql"}
#SQLite数据库存放位置
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
if [ -f "$MYSQL_DIR/mysql-bin.index" ];then
    mysqld -u mysql --datadir "$MYSQL_DIR" &
else   
    mysql_install_db --user=mysql --skip-name-resolve --datadir="$MYSQL_DIR";
    echo -e "DELETE FROM mysql.user;\nFLUSH PRIVILEGES;">"$tempSqlFile";
    if [ $MYSQL_PASSWORD ];then
        #MYSQL 账号
        echo "CREATE USER '$MYSQL_ACCOUNT'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';">>"$tempSqlFile";
    #MYSQL_初始化脚本
    else
        #SQLite数据库存放位置
        mysqld_safe --skip-grant-tables --skip-networking &
        #MYSQL 账号
        echo "CREATE USER '$MYSQL_ACCOUNT'@'%';">>"$tempSqlFile";
    #MYSQL_初始化脚本
    fi;
    #SQLite数据库存放位置
    #MYSQL 账号
    echo -e "GRANT ALL ON *.* TO '$MYSQL_ACCOUNT'@'%';\nFLUSH PRIVILEGES;">>"$tempSqlFile";
    #MYSQL_初始化脚本
    [ -f "${WORK_DIR}tests/yyf.sql" ]&& sed '/^\/\*MYSQL/d;/MYSQL\*\//d' "${WORK_DIR}tests/yyf.sql" >> "$tempSqlFile";
    #SQLite数据库存放位置
    [ -f $MYSQL_SCRIPT ]&& cat "$MYSQL_SCRIPT">>"$tempSqlFile";
    mysqld -u mysql --datadir "$MYSQL_DIR" --init-file="$tempSqlFile" &
fi;

# 初始化SQLite数据库
if [ -f "$SQLITE_FILE" ];then #文件不存在在自动初始化
    if [ $SQLITE_SCRIPT ]; then
        cat "$SQLITE_SCRIPT" | sqlite3 $SQLITE_FILE;
    elif [ -f "${WORK_DIR}tests/yyf.sql" ]; then
        sed '/^\/\*SQLITE/d;/SQLITE\*\//d' "${WORK_DIR}tests/yyf.sql" | sqlite3 $SQLITE_FILE;
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
