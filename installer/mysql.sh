#!/bin/bash
#
# used globals:
#
#MYSQL_ROOT_PASSWD='PASSWORD'
#

function mysql_install {
  apt-get --yes install mysql-server
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install mysql-server."
    exit 1
  fi
}

function mysql_harden {
  service mysql stop
  mysqld_safe --skip-grant-tables &

  i="0"
  while [ $i -lt 10 ]; do
    sleep 1
    if [ -e /var/run/mysqld/mysqld.sock ]; then
      break
    fi
    i=$[$i+1]
  done

  mysql << _EOF_
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.db WHERE Db LIKE 'test%';
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
DROP DATABASE IF EXISTS test;
FLUSH PRIVILEGES;
_EOF_
  if [ $? -ne 0 ]; then
    echo "WARNING: Failed to secure MySQL"
  fi

  # MySQL .7.5 and earlier:
  mysql << _EOF_
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$MYSQL_ROOT_PASSWD');
_EOF_

  killall -9 mysqld_safe mysqld
  service mysql stop
  service mysql start
}
