#!/bin/bash

if ! is_package_installed mysql-server; then
  apt-get --yes install mysql-server
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install mysql-server."
    exit 1
  fi
fi

SQL="DELETE FROM mysql.db WHERE Db LIKE 'test%';
FLUSH PRIVILEGES;
DROP DATABASE IF EXISTS test;"

mysql -uroot -p --protocol=tcp -e "${SQL}"
if [ $? -ne 0 ]; then
  echo "WARNING: Failed to secure MySQL"
fi
