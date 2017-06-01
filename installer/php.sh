#!/bin/bash

apt-get --yes install php5 php-pear php5-mysql

# Should be tested
# /etc/php5/apache2/php.ini, /etc/php5/cgi/php.ini, /etc/php5/cli/php.ini
sed -i 's/expose_php = On/expose_php = Off/g' /etc/php5/apache2/php.ini
