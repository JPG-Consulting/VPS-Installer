#!/bin/bash

function phpmyadmin_install {
  if ! is_package_installed mcrypt; then
    apt-get install -y mcrypt
  fi

  debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
  debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
  debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQL_ROOT_PASSWD"
  debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $MYSQL_ROOT_PASSWD"
  debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $MYSQL_ROOT_PASSWD"

  apt-get install -y phpmyadmin
}