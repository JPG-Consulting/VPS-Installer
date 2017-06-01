#!/bin/bash


# =====================================
#  Apache2
# =====================================
. installer/apache.sh

# ====================================
#  MySQL
# ====================================
. installer/mysql.sh

# ====================================
#  PHP
# ====================================
. installer/php.sh

# ====================================
#  Extra packages bibding them all
# ====================================
if ! is_package_installed php5-mysql; then
  apt-get --yes install php5-mysql
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install php5-mysql."
    exit 1
  fi
fi

service apache2 restart
