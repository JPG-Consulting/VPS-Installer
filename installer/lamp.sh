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


service apache2 restart
