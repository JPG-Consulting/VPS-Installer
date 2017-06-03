#!/bin/bash

if ! is_package_installed mysql-server; then
  apt-get --yes install mysql-server
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install mysql-server."
    exit 1
  fi
fi

service mysql stop
mysqld_safe --skip-grant-tables &

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

service mysql stop
service mysql start
