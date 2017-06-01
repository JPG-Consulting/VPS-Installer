#!/bin/bash

apt-get --yes install php5 php-pear php5-mysql

# Should be tested
#sed -i -e "s/^expose_php[[:space:]]*=.*/expose_php = Off/" /etc/php.ini
sed -i 's/expose_php = On/expose_php = Off/g' /etc/php.ini
#sed -e 's/expose_php = On/expose_php = Off/g' /etc/php/5.6/fpm/php.ini
