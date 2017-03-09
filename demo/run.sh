#!/bin/sh
if [ -f index.php ];then
  php -S 0.0.0.0:$PORT;
elif [ -d public ];then
  php -S 0.0.0.0:$PORT -t public;
else
  tar zxf /yaf/master.tar.gz -C /tmp/ && mv -n /tmp/YYF-master/* ./
  php -S 0.0.0.0:$PORT -t public;
fi;