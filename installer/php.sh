#!/bin/bash

if ! is_package_installed php5; then
  apt-get --yes install php5
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install PHP5."
    exit 1
  fi
fi

# Should be tested
# /etc/php5/apache2/php.ini, /etc/php5/cgi/php.ini, /etc/php5/cli/php.ini
if [ -f /etc/php5/apache2/php.ini ]; then
  sed -i 's/expose_php = On/expose_php = Off/g' /etc/php5/apache2/php.ini
  sed -i 's/mail.add_x_header = On/mail.add_x_header = Off/g' /etc/php5/apache2/php.ini
  sed -i 's/date.timezone = .*/date.timezone = "Europe\/Madrid"/g' /etc/php5/apache2/php.ini
fi

if [ -f /etc/php5/cgi/php.ini ]; then
  sed -i 's/expose_php = On/expose_php = Off/g' /etc/php5/cgi/php.ini
  sed -i 's/mail.add_x_header = On/mail.add_x_header = Off/g' /etc/php5/cgi/php.ini
  sed -i 's/date.timezone = .*/date.timezone = "Europe\/Madrid"/g' /etc/php5/cgi/php.ini
fi

if [ -f /etc/php5/cli/php.ini ]; then
  sed -i 's/expose_php = On/expose_php = Off/g' /etc/php5/cli/php.ini
  sed -i 's/mail.add_x_header = On/mail.add_x_header = Off/g' /etc/php5/cli/php.ini
  sed -i 's/date.timezone = .*/date.timezone = "Europe\/Madrid"/g' /etc/php5/cli/php.ini
fi

if [ -f /etc/php5/fpm/php.ini ]; then
  sed -i 's/expose_php = On/expose_php = Off/g' /etc/php5/fpm/php.ini
  sed -i 's/mail.add_x_header = On/mail.add_x_header = Off/g' /etc/php5/fpm/php.ini
  sed -i 's/date.timezone = .*/date.timezone = "Europe\/Madrid"/g' /etc/php5/fpm/php.ini
fi

