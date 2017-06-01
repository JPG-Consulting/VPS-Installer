#!/bin/bash

if ! is_package_installed apache2; then
  apt-get --yes install apache2
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install apache2."
    exit 1
  fi
fi

sed -i 's/^ServerSignature On/ServerSignature Off/g' /etc/apache2/conf.d/security
sed -i 's/^ServerTokens \(OS\|Full\|Minimal\|Minor\|Major\)/ServerTokens Prod/g' /etc/apache2/conf.d/security

## Write protect Apache, Php, Mysql configuration files
chattr +i /etc/apache2/apache2.conf
